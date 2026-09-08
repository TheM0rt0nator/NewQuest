-- Client-side sequence runner. Play yields and returns Completed, Cancelled, Failed, or Busy.
local Players = game:GetService("Players")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CinematicBars = require(script.CinematicBars)

local Cutscene = {}
Cutscene.__index = Cutscene
Cutscene.Steps = require(script.Steps)

local Context = {}
Context.__index = Context

local activeContext -- One camera owner across all runner instances.

function Context:Check()
	if self.Cancelled or self.Closed then
		error("Cutscene cancelled", 0)
	end
end

-- Cleanup functions must not yield. Register before changing state.
function Context:Defer(callback)
	assert(not self.Closed, "Cutscene context is closed")

	local pending = true

	local function release()
		if pending then
			pending = false
			callback()
		end
	end

	table.insert(self.Cleanups, release)

	return release
end

function Context:Set(instance, property, value)
	self:Check()

	local previous = instance[property]
	self:Defer(function()
		instance[property] = previous
	end)

	instance[property] = value
end

function Context:Wait(seconds)
	assert(
		type(seconds) == "number" and seconds >= 0 and seconds < math.huge,
		"Invalid wait duration"
	)

	local deadline = os.clock() + seconds
	self:Check()

	while os.clock() < deadline do
		RunService.Heartbeat:Wait()
		self:Check()
	end
end

-- Bridges callback APIs. start(done, context) must return a non-yielding cleanup function.
-- done(errorMessage?) may be called once; late callbacks are ignored.
function Context:Await(start, timeout)
	self:Check()
	timeout = timeout or 30
	assert(timeout > 0 and timeout < math.huge, "Invalid callback timeout")

	local accepting, finished, failure = true, false, nil
	local stop
	local release = self:Defer(function()
		accepting = false

		if stop then
			stop()
		end
	end)

	stop = start(function(message)
		if accepting and not self.Cancelled and not finished then
			finished, failure = true, message
		end
	end, self)

	assert(type(stop) == "function", "Async adapters must return a cleanup function")

	local deadline = os.clock() + timeout

	while not finished do
		self:Check()
		assert(os.clock() < deadline, "Cutscene callback timed out")
		RunService.Heartbeat:Wait()
	end

	self:Check()
	release()

	if failure then
		error(tostring(failure), 0)
	end
end

function Context:Tween(instance, tweenInfo, properties)
	self:Check()
	assert(tweenInfo.RepeatCount >= 0, "Infinite cutscene tweens are not supported")

	local tween = TweenService:Create(instance, tweenInfo, properties)
	local duration = (tweenInfo.Time * (tweenInfo.Reverses and 2 or 1) + tweenInfo.DelayTime)
		* (tweenInfo.RepeatCount + 1)
	self:Await(function(done)
		local connection = tween.Completed:Connect(function(state)
			done(state ~= Enum.PlaybackState.Completed and "Cutscene tween interrupted" or nil)
		end)

		tween:Play()

		return function()
			connection:Disconnect()
			tween:Cancel()
			tween:Destroy()
		end
	end, duration + 5)
end

function Context:Resolve(value)
	self:Check()

	if type(value) == "function" then
		value = value(self)
	end

	self:Check()
	assert(value ~= nil, "Cutscene reference is missing (check streaming and scene setup)")

	return value
end

function Context:GetCFrame(target)
	target = self:Resolve(target)

	if type(target) == "string" then
		local markers = self:Resolve(self.Scene.Markers)
		local name = target
		target = markers:FindFirstChild(name, true)
		assert(target, "Missing cutscene marker: " .. name)
	end

	if typeof(target) == "CFrame" then
		return target
	end

	assert(
		typeof(target) == "Instance",
		"Expected a CFrame, marker name, Attachment, BasePart, or Model"
	)

	if target:IsA("Attachment") then
		return target.WorldCFrame
	end

	if target:IsA("BasePart") then
		return target.CFrame
	end

	if target:IsA("Model") then
		return target:GetPivot()
	end

	error("Unsupported cutscene marker: " .. target.ClassName)
end

local function setup(context, options)
	local camera = workspace.CurrentCamera
	assert(camera, "CurrentCamera is unavailable")
	context.Camera = camera

	-- Registered first, so camera restoration happens after bars/tweens are destroyed.
	local cameraType, subject = camera.CameraType, camera.CameraSubject
	local cframe, focus, fov = camera.CFrame, camera.Focus, camera.FieldOfView

	local function restoreCamera()
		if context.CameraReturned then
			return
		end

		context.CameraReturned = true

		local character = context.Player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		camera.FieldOfView = fov

		if context.Scene.ReturnToPlayer and humanoid and root then
			-- Cut directly to the player at their current location, not the saved shot.
			local target = root.Position + Vector3.new(0, 2, 0)
			local position = root.CFrame:PointToWorldSpace(Vector3.new(0, 4, 10))
			camera.CFrame = CFrame.lookAt(position, target)
			camera.Focus = CFrame.new(target)
			camera.CameraSubject = humanoid
			camera.CameraType = Enum.CameraType.Custom

			return
		end

		camera.CFrame = cframe
		camera.Focus = focus
		camera.CameraSubject = (subject and subject.Parent and subject) or humanoid
		camera.CameraType = cameraType
	end

	context.ReturnCamera = restoreCamera
	context:Defer(restoreCamera)
	camera.CameraType = Enum.CameraType.Scriptable

	local function cancelForCharacter()
		context.Cancelled, context.Reason = true, "Character changed"
	end

	for _, signal in { context.Player.CharacterRemoving, context.Player.CharacterAdded } do
		local connection = signal:Connect(cancelForCharacter)
		context:Defer(function()
			connection:Disconnect()
		end)
	end

	local humanoid = context.Player.Character
		and context.Player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local connection = humanoid.Died:Connect(cancelForCharacter)
		context:Defer(function()
			connection:Disconnect()
		end)

		if humanoid.Health <= 0 then
			cancelForCharacter()
		end
	end

	local cameraChanged = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		context.Cancelled, context.Reason = true, "Camera replaced"
	end)

	context:Defer(function()
		cameraChanged:Disconnect()
	end)

	if options.Setup then
		options.Setup(context)
	end

	context:Check()

	if context.Scene.Bars ~= false then
		local config = table.clone(context.Scene.Bars or {})

		-- The runner owns FOV, avoiding competing bar and camera tweens.
		config.fovEffect = false
		context.Bars = CinematicBars.new(config)
		context:Defer(function()
			context.Bars:Destroy()
		end)

		context.Bars:Show()
		context:Wait(context.Bars.config.animationTime)
	end
end

function Cutscene.new(options)
	assert(RunService:IsClient(), "Cutscene must be used on the client")

	return setmetatable({ Options = options or {}, Destroyed = false }, Cutscene)
end

function Cutscene:IsPlaying()
	return self.Context ~= nil
end

function Cutscene:Cancel(reason)
	if not self.Context then
		return false
	end

	self.Context.Cancelled = true
	self.Context.Reason = reason or "Cancelled"

	return true
end

function Cutscene:Play(scene, data)
	if self.Destroyed then
		return "Failed", "Cutscene runner was destroyed"
	end

	if activeContext then
		return "Busy", "Another cutscene is playing"
	end

	if type(scene) ~= "table" or type(scene.Steps) ~= "table" then
		return "Failed", "A scene must contain a Steps array"
	end

	local context = setmetatable({
		Scene = scene,
		Data = data or {},
		Player = Players.LocalPlayer,
		Adapters = self.Options.Adapters or {},
		Cleanups = {},
		Cancelled = false,
	}, Context)
	self.Context, activeContext = context, context

	local ok, failure = xpcall(function()
		-- Validate before taking over the camera or player.
		for index, step in ipairs(scene.Steps) do
			assert(type(step) == "function", "Invalid cutscene step " .. index)
		end

		if scene.Validate then
			scene.Validate(context)
		end

		context:Check()
		setup(context, self.Options)

		for _, step in ipairs(scene.Steps) do
			context:Check()
			step(context)
			context:Check()
		end

		if scene.ReturnToPlayer then
			context.ReturnCamera()
		end

		if context.Bars then
			context.Bars:Hide()
			context:Wait(context.Bars.config.animationTime)
		end
	end, debug.traceback)

	context.Closed = true

	local cleanupErrors = {}

	for index = #context.Cleanups, 1, -1 do
		local cleaned, message = xpcall(context.Cleanups[index], debug.traceback)

		if not cleaned then
			table.insert(cleanupErrors, tostring(message))
		end
	end

	self.Context, activeContext = nil, nil

	if #cleanupErrors > 0 then
		return "Failed",
			(not ok and tostring(failure) .. "\n" or "") .. table.concat(cleanupErrors, "\n")
	end

	if context.Cancelled then
		return "Cancelled", context.Reason
	end

	if not ok then
		return "Failed", failure
	end

	return "Completed"
end

function Cutscene:Destroy()
	self.Destroyed = true
	self:Cancel("Destroyed")
end

return Cutscene
