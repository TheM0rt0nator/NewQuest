local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage.Modules.FlightQuestConfig)
local DreamTransition = require(ReplicatedStorage.Modules.DreamTransition)
local QuestUI = require(ReplicatedStorage.Modules.QuestUI)

local player = Players.LocalPlayer
local stage = workspace:WaitForChild("FlightQuest")
local remote = ReplicatedStorage:WaitForChild("FlightAction")
local gui = Instance.new("ScreenGui")
gui.Name = "FlightCabin"
gui.ResetOnSpawn = false
gui.DisplayOrder = 116
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local hint = QuestUI.Label(
	gui, "Hint", "", UDim2.fromScale(0.2, 0.8), UDim2.fromScale(0.6, 0.15)
)
local retry = QuestUI.Button(
	gui, "Retry", "Continue flight", UDim2.fromScale(0.37, 0.67), UDim2.fromScale(0.26, 0.1)
)
retry.Visible = false

local highlight = Instance.new("Highlight")
highlight.FillTransparency = 0.85
highlight.OutlineColor = QuestUI.Accent
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = stage

local busy = false
local menu
local errorUntil = 0
local sequenceVersion = 0
local refresh
local resume

local function invoke(action, value)
	local ok, success, reason = pcall(remote.InvokeServer, remote, action, value)

	if not ok then
		return false, "The cabin action could not finish. Please try again."
	end

	return success, reason
end

local function showError(reason)
	errorUntil = os.clock() + 4
	hint.Text = reason or "Please try again."
	hint.Visible = true

	local expires = errorUntil
	task.delay(4, function()
		if expires == errorUntil then
			refresh()
		end
	end)
end

local function closeMenu()
	if menu then
		menu:Destroy()
		menu = nil
	end
end

local function openMenu()
	if busy or menu then
		return
	end

	menu = Instance.new("Frame")
	menu.Name = "MealMenu"
	menu.Size = UDim2.fromScale(0.68, 0.42)
	menu.Position = UDim2.fromScale(0.16, 0.25)
	menu.BackgroundColor3 = QuestUI.Paper
	menu.Parent = gui
	QuestUI.Label(menu, "Title", "GALLEY • CHOOSE A MEAL", UDim2.fromScale(0.05, 0.04),
		UDim2.fromScale(0.9, 0.24))

	for index, meal in Config.Meals do
		local button = QuestUI.Button(
			menu, meal, meal, UDim2.fromScale(0.04 + (index - 1) * 0.32, 0.36),
			UDim2.fromScale(0.28, 0.3)
		)
		button.Activated:Connect(function()
			local ok, reason = invoke("Pickup", meal)

			if ok then
				closeMenu()
				refresh()
			else
				showError(reason)
			end
		end)
	end

	local close = QuestUI.Button(menu, "Close", "Close", UDim2.fromScale(0.36, 0.74),
		UDim2.fromScale(0.28, 0.22))
	close.Activated:Connect(closeMenu)
end

local function scene(state)
	if busy then
		return
	end

	busy = true
	retry.Visible = false
	closeMenu()
	highlight.Enabled = false
	sequenceVersion += 1

	local version = sequenceVersion
	local character = player.Character
	local camera = workspace.CurrentCamera
	local originalType, originalFrame, originalFov =
		camera.CameraType, camera.CFrame, camera.FieldOfView
	local dream
	local engine
	local joints = {}
	local hiddenParts = {}
	local started = false
	local animate = character and character:FindFirstChild("Animate")
	local animateEnabled = animate and animate.Enabled
	local restoredControls = false
	ContextActionService:BindActionAtPriority(
		"FlightSequenceMovement",
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 5,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.Space,
		Enum.KeyCode.Thumbstick1,
		Enum.KeyCode.ButtonA,
		table.unpack(Enum.PlayerActions:GetEnumItems())
	)

	if animate then
		animate.Enabled = false
	end

	local function restoreControls()
		if restoredControls then
			return
		end

		restoredControls = true

		if animate and animate.Parent then
			animate.Enabled = animateEnabled
		end

		ContextActionService:UnbindAction("FlightSequenceMovement")
	end

	local function check()
		assert(
			version == sequenceVersion and player.Character == character
				and character.Humanoid.Health > 0 and workspace.CurrentCamera == camera,
			"Scene cancelled"
		)
	end

	local ok, reason = xpcall(function()
		check()

		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				hiddenParts[part] = part.LocalTransparencyModifier
				part.LocalTransparencyModifier = 1
			end
		end

		for _, track in character.Humanoid.Animator:GetPlayingAnimationTracks() do
			track:Stop(0.15)
		end

		if state == 16 then
			dream = DreamTransition.Take(player.PlayerGui)
			dream:Cover(check)
			player:RequestStreamAroundAsync(stage.Markers.Arrival.Position, 10)
		end

		local problem
		started, problem = invoke("BeginScene")
		assert(started, problem)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 64
		camera.CFrame = stage.Markers.CabinFront.CFrame

		if dream then
			dream:Reveal(check)
			dream = nil
		end

		if state == 19 then
			engine = stage.TakeoffEngine:Clone()
			engine.Parent = SoundService
			engine:Play()
		end

		if state == 16 then
			for _, model in stage.Passengers:GetChildren() do
				local joint = model:FindFirstChild("Neck", true)

				if joint then
					joints[joint] = true
				end
			end
		end

		local start = os.clock()
		local duration = Config.SceneDurations[state]

		repeat
			check()

			local elapsed = os.clock() - start
			local progress = math.clamp(elapsed / duration, 0, 1)

			if state == 16 then
				local first = progress < 0.5 and stage.Markers.CabinFront
					or stage.Markers.CabinMiddle
				local last = progress < 0.5 and stage.Markers.CabinMiddle or stage.Markers.CabinRear
				local alpha = progress < 0.5 and progress * 2 or (progress - 0.5) * 2
				camera.CFrame = first.CFrame:Lerp(last.CFrame, alpha)
				hint.Text = progress < 0.5
					and "BERRY AVENUE AIRWAYS\nPassengers are settling in for their flight."
					or "Your final shift: cabin crew!\nStart the safety announcement at the galley."

				for joint in joints do
					joint.Transform = CFrame.Angles(0, math.sin(elapsed * 1.3) * 0.2, 0)
				end
			elseif state == 17 then
				local pages = {
					"Welcome aboard Berry Avenue Airways! Please take your seats.",
					"Fasten your seatbelt low across your lap and keep the aisle clear.",
					"Stow your bags, raise your tray table, and follow the crew's instructions.",
					"Thank you! One passenger still needs help with their seatbelt: Ben.",
				}
				hint.Text = "SAFETY ANNOUNCEMENT\n"
					.. pages[math.min(4, math.floor(progress * 4) + 1)]
			elseif state == 19 then
				local strength = math.sin(progress * math.pi)
				camera.CFrame = stage.Markers.TakeoffCamera.CFrame
					* CFrame.new(math.sin(elapsed * 22) * strength * 0.035,
						math.sin(elapsed * 29) * strength * 0.035, 0)
					* CFrame.Angles(math.rad(-5 * math.sin(progress * math.pi / 2)), 0, 0)
				camera.FieldOfView = 64 + math.sin(progress * math.pi) * 5
				hint.Text = progress < 0.4 and "CAPTAIN\nCabin crew, prepare for takeoff."
					or progress < 0.8 and "TAKEOFF\nKeep your seatbelt fastened as we climb."
					or "CRUISING ALTITUDE\nThe seatbelt sign is off. Time for cabin service!"
			else
				hint.Text = "CABIN SERVICE COMPLETE\n"
					.. "Every passenger has their meal. Wonderful work!"
			end

			hint.Visible = true
			RunService.PreSimulation:Wait()
		until elapsed >= duration

		if state == 21 then
			dream = DreamTransition.Take(player.PlayerGui)
			dream:Cover(check)
			DreamTransition.HandOff(dream)
			camera.CameraType = originalType
			camera.CFrame = originalFrame
			camera.FieldOfView = originalFov
			restoreControls()
		end

		local finished, failure = invoke("FinishScene")
		assert(finished, failure)
		dream = nil
	end, debug.traceback)

	for joint in joints do
		if joint.Parent then
			joint.Transform = CFrame.identity
		end
	end

	for part, transparency in hiddenParts do
		if part.Parent then
			part.LocalTransparencyModifier = transparency
		end
	end

	if engine then
		engine:Destroy()
	end

	if dream then
		dream:Destroy()
	end

	if state ~= 21 or not ok then
		camera.CameraType = originalType
		camera.CFrame = originalFrame
		camera.FieldOfView = originalFov

		if ok and (state == 16 or state == 19) and character.Parent then
			local position = character.HumanoidRootPart.Position
			camera.CFrame = CFrame.lookAt(position + Vector3.new(-6, 3, 0),
				position + Vector3.new(0, 1, 0))
		end
	end

	restoreControls()

	if started and not ok then
		invoke("Cancel")
	end

	busy = false
	refresh()

	if not ok and character and player.Character == character and character.Humanoid.Health > 0 then
		warn("[FlightQuest]", reason)
		showError("The cabin sequence was interrupted. Try again.")
		retry.Visible = player:GetAttribute("QuestState") == state
	end
end

refresh = function()
	local state = player:GetAttribute("QuestState") or 0
	local active = player:GetAttribute("QuestDataReady") == true and state >= 16 and state <= 21
	hint.Visible = active
	highlight.Enabled = active and not busy

	if not active or busy then
		return
	end

	local passenger = Config.Passengers[(player:GetAttribute("QuestProgress") or 0) + 1]
	local meal = player:GetAttribute("FlightMeal")
	highlight.Adornee = state == 17 and stage.Galley
		or state == 18 and stage.Passengers[Config.SeatbeltPassenger]
		or state == 19 and stage.SeatTarget
		or state == 20 and meal and passenger and stage.Passengers[passenger.Name]
		or state == 20 and stage.Galley or nil

	if os.clock() < errorUntil then
		return
	end

	hint.Text = state == 20 and passenger
		and string.format("%d / 6 SERVED • %s wants %s\n%s",
			player:GetAttribute("QuestProgress") or 0, passenger.Name, passenger.Meal,
			meal and "Carrying: " .. meal or "Choose the correct meal at the galley.")
		or player:GetAttribute("QuestObjective") or ""
end

resume = function()
	local state = player:GetAttribute("QuestState")

	if busy or not player:GetAttribute("QuestDataReady") or (state ~= 16 and state ~= 21) then
		return
	end

	local character = player.Character
	local deadline = os.clock() + 20

	while character and player.Character == character
		and character:GetAttribute("QuestResumeStage") ~= "FlightQuest" and os.clock() < deadline
	do
		task.wait(0.1)
	end

	if character and player.Character == character
		and player:GetAttribute("QuestState") == state
	then
		scene(state)
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player or not prompt:IsDescendantOf(stage) or busy then
		return
	end

	local state = player:GetAttribute("QuestState")

	if state == 17 or state == 19 then
		scene(state)
	elseif state == 18 then
		local ok, reason = invoke("Seatbelt")

		if not ok then
			showError(reason)
		end
	elseif state == 20 then
		if prompt.Parent == stage.Galley then
			openMenu()
		else
			local ok, reason = invoke("Serve", prompt.Parent.Parent.Name)

			if not ok then
				showError(reason)
			end
		end
	end
end)

for _, attribute in { "QuestState", "QuestProgress", "FlightMeal", "QuestDataReady" } do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		refresh()

		if attribute == "QuestState" or attribute == "QuestDataReady" then
			closeMenu()
			task.defer(resume)
		end
	end)
end

player.CharacterRemoving:Connect(function()
	sequenceVersion += 1
	closeMenu()
	retry.Visible = false
	hint.Visible = false
	highlight.Enabled = false
end)
player.CharacterAdded:Connect(function()
	task.spawn(function()
		while busy do
			task.wait(0.1)
		end

		resume()
		refresh()
	end)
end)
retry.Activated:Connect(function()
	scene(player:GetAttribute("QuestState"))
end)
refresh()
task.defer(resume)
