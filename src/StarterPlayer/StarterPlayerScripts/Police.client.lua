local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Modules.PoliceQuestConfig)
local Cutscene = require(ReplicatedStorage.Modules.Cutscene)
local Manager = require(ReplicatedStorage.Modules.CutsceneManager)
local DreamTransition = require(ReplicatedStorage.Modules.DreamTransition)
local QuestUI = require(ReplicatedStorage.Modules.QuestUI)
local PoliceSearch = require(ReplicatedStorage.Modules.PoliceSearch)

local player = Players.LocalPlayer
local stage = workspace:WaitForChild("PoliceQuest")
local remote = ReplicatedStorage:WaitForChild("PoliceAction")
local busy = false
local errorUntil = 0
local closePanel
local refreshPresentation

local function setBusy(value)
	busy = value

	if refreshPresentation then
		refreshPresentation()
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "PoliceBooking"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 115
gui.Parent = player:WaitForChild("PlayerGui")

local text = QuestUI.Label
local button = QuestUI.Button

local hint = text(gui, "Hint", "", UDim2.fromScale(0.24, 0.85), UDim2.fromScale(0.52, 0.1))
hint.Visible = false

local retry = button(
	gui,
	"Retry",
	"Retry police entrance",
	UDim2.fromScale(0.37, 0.76),
	UDim2.fromScale(0.26, 0.07)
)
retry.Visible = false

local function invoke(action, value)
	local ok, success, reason = pcall(remote.InvokeServer, remote, action, value)

	if not ok then
		return false, tostring(success)
	end

	return success, reason
end

local function controls(enabled)
	if enabled then
		ContextActionService:UnbindAction("PoliceBookingMovement")
	else
		ContextActionService:BindActionAtPriority(
			"PoliceBookingMovement",

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
	end
end

local function showError(reason)
	if reason and (string.find(reason, "\n", 1, true) or #reason > 180) then
		warn("[PoliceQuest]", reason)
		reason = "That action did not finish. Please try again."
	end

	errorUntil = os.clock() + 4
	hint.Text = reason or "Please try again"
	hint.Visible = true

	local expires = errorUntil
	task.delay(4, function()
		if errorUntil == expires then
			refreshPresentation()
		end
	end)
end

local function intro()
	if busy or player:GetAttribute("QuestState") ~= 8 then
		return
	end

	setBusy(true)
	retry.Text = "Retry police entrance"
	retry.Visible = false

	local deadline = os.clock() + 30

	while os.clock() < deadline do
		local character = player.Character
		local chapter = player.PlayerGui:FindFirstChild("ClassroomChapter")

		if
			character
			and character:GetAttribute("QuestResumeState") == 8
			and not player:GetAttribute("PoliceMoving")
			and not Manager.IsPlaying()
			and chapter
			and (not chapter:FindFirstChild("Loading") or not chapter.Loading.Visible)
		then
			break
		end

		task.wait(0.1)
	end

	local started = false
	local animate
	local animateEnabled
	local dream
	controls(false)

	local ok, status, reason = xpcall(function()
		local character = player.Character
		animate = character:FindFirstChild("Animate")

		if animate then
			animateEnabled = animate.Enabled
			animate.Enabled = false
		end

		-- The entrance owns locomotion until the server finishes the walk.
		for _, track in character.Humanoid.Animator:GetPlayingAnimationTracks() do
			track:Stop(0.2)
		end

		dream = DreamTransition.Take(player.PlayerGui)
		dream:Cover(function()
			assert(
				player.Character == character and character.Humanoid.Health > 0,
				"Character changed"
			)
		end)

		player:RequestStreamAroundAsync(stage.Markers.Arrival.Position, 10)

		local why
		started, why = invoke("BeginIntro")
		assert(started, why)

		return Manager.Play({
			Id = "PoliceIntro",
			Markers = stage.Markers,
			Steps = {
				Cutscene.Steps.Camera("EntryCamera", 0, 60),
				Cutscene.Steps.Call(function(context)
					dream:Reveal(function()
						context:Check()
					end)

					dream = nil
				end),

				Cutscene.Steps.Call(function()
					local walked, problem = invoke("Enter")

					if animate and animate.Parent then
						animate.Enabled = animateEnabled
					end

					assert(walked, problem or "The entrance walk did not finish")
				end),

				Cutscene.Steps.Dialog({
					{
						speaker = "LEO",
						text = "Welcome to your police shift! Bring the suspect to booking. We'll search their belongings, scan fingerprints, and take a mugshot.",
					},
				}),
			},
		})
	end, debug.traceback)

	if dream then
		dream:Destroy()
	end

	if animate and animate.Parent then
		animate.Enabled = animateEnabled
	end

	if started then
		if ok and (status == "Completed" or status == "Cancelled" and reason == "Skipped") then
			local finished, problem = invoke("FinishIntro")

			if not finished then
				ok = false
				reason = problem or "The entrance walk is not complete"
			end
		end

		invoke("Cancel")
	end

	controls(true)
	setBusy(false)

	if not ok or status == "Failed" then
		showError(reason or status)
		retry.Visible = player:GetAttribute("QuestState") == 8
	end
end

local function departure()
	if busy or player:GetAttribute("QuestState") ~= 15 then
		return
	end

	setBusy(true)
	controls(false)

	local dream
	local character = player.Character

	local function check()
		assert(player.Character == character and character.Humanoid.Health > 0, "Character changed")
	end

	local ok, reason = xpcall(function()
		local ready, problem = invoke("BeginDeparture")
		assert(ready, problem)
		hint.Text = "LEO\nGreat work! Your next shift is aboard a Berry Avenue flight."
		hint.Visible = true

		local deadline = os.clock() + Config.DepartureDelay

		repeat
			check()
			task.wait(0.1)
		until os.clock() >= deadline
		dream = DreamTransition.Take(player.PlayerGui)
		dream:Cover(check)
		DreamTransition.HandOff(dream)

		local finished, failure = invoke("FinishDeparture")
		assert(finished, failure or "Could not begin your flight")
		dream = nil
	end, debug.traceback)

	if dream then
		dream:Destroy()
	end

	invoke("Cancel")
	controls(true)
	setBusy(false)

	if not ok then
		showError(reason)
		retry.Text = "Continue to your flight"
		retry.Visible = player:GetAttribute("QuestState") == 15
	end
end

local function panel(state)
	if busy then
		return
	end

	local success, reason = invoke("Begin")

	if not success then
		showError(reason)

		return
	end

	setBusy(true)
	controls(false)

	local hiddenParts = {}
	local hiddenLabels = {}

	for _, object in stage:GetDescendants() do
		if object:IsA("BillboardGui") then
			hiddenLabels[object] = object.Enabled
			object.Enabled = false
		end
	end

	for _, object in player.Character:GetDescendants() do
		if object:IsA("BasePart") then
			hiddenParts[object] = object.LocalTransparencyModifier
			object.LocalTransparencyModifier = 1
		end
	end

	local chapterGui = player.PlayerGui:FindFirstChild("ClassroomChapter")
	local chapterEnabled = chapterGui and chapterGui.Enabled

	if chapterGui then
		chapterGui.Enabled = false
	end

	local camera = workspace.CurrentCamera
	local oldType, oldSubject, oldFov, oldCFrame =
		camera.CameraType, camera.CameraSubject, camera.FieldOfView, camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame =
		stage.Markers[state == 9 and "SearchCamera" or state == 10 and "FingerprintCamera" or "MugshotCamera"].CFrame
	camera.FieldOfView = state == 9 and 50 or state == 11 and 60 or 48

	local root = Instance.new("Frame")
	root.Name = "Panel"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui

	local title = state == 9 and "SEARCH & INVENTORY"
		or state == 10 and "FINGERPRINT SCAN"
		or "MUGSHOT"
	text(root, "Title", title, UDim2.fromScale(0.3, 0.07), UDim2.fromScale(0.4, 0.07))

	local progress =
		text(root, "Progress", "", UDim2.fromScale(0.36, 0.15), UDim2.fromScale(0.28, 0.065))
	progress.BackgroundColor3 = QuestUI.Accent

	local function updateProgress()
		progress.Text = state == 9
				and string.format(
					"%d / 6 ITEMS COLLECTED",
					player:GetAttribute("QuestProgress") or 0
				)
			or state == 10 and "BOOKING  /  2 OF 4"
			or "BOOKING  /  3 OF 4"
	end

	updateProgress()

	local instruction = text(
		root,
		"Instruction",
		state == 9 and "Drag the items off the suspect to confiscate them."
			or state == 10 and "Press Scan to record the suspect's fingerprints."
			or "Frame the suspect and take their booking photo.",
		UDim2.fromScale(0.24, 0.83),
		UDim2.fromScale(0.52, 0.11)
	)

	local connections =
		{ player:GetAttributeChangedSignal("QuestProgress"):Connect(updateProgress) }
	local closed = false
	local processing = false
	local stopSearch
	closePanel = function()
		if closed then
			return
		end

		closed = true

		if stopSearch then
			stopSearch()
		end

		for _, connection in connections do
			connection:Disconnect()
		end

		root:Destroy()

		for object, enabled in hiddenLabels do
			if object.Parent then
				object.Enabled = enabled
			end
		end

		for object, transparency in hiddenParts do
			if object.Parent then
				object.LocalTransparencyModifier = transparency
			end
		end

		if chapterGui then
			chapterGui.Enabled = chapterEnabled
		end

		camera.CameraType = oldType
		camera.CameraSubject = oldSubject
		camera.FieldOfView = oldFov
		camera.CFrame = oldCFrame
		controls(true)
		setBusy(false)
		closePanel = nil
		task.spawn(invoke, "Cancel")
	end

	local close =
		button(root, "Close", "Close", UDim2.fromScale(0.76, 0.07), UDim2.fromScale(0.12, 0.095))
	table.insert(
		connections,
		close.Activated:Connect(function()
			if closePanel then
				closePanel()
			end
		end)
	)

	if state == 9 then
		stopSearch = PoliceSearch.Start(player, stage, invoke, instruction)
	else
		local action = button(
			root,
			"Action",
			state == 10 and "Scan fingerprints" or "Take photo",
			UDim2.fromScale(0.36, 0.68),
			UDim2.fromScale(0.28, 0.09)
		)
		table.insert(
			connections,
			action.Activated:Connect(function()
				if processing then
					return
				end

				processing = true
				action.Text = state == 10 and "Scanning..." or "Saving photo..."

				if state == 11 then
					local flash = Instance.new("Frame")
					flash.Size = UDim2.fromScale(1, 1)
					flash.BackgroundColor3 = Color3.new(1, 1, 1)
					flash.ZIndex = 10
					flash.Parent = root
					TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
						:Play()
				end

				local completed, problem = invoke(state == 10 and "Scan" or "Photo")
				processing = false

				if not completed and not closed then
					instruction.Text = problem or "Please try again"
				end
			end)
		)
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player or not prompt:IsDescendantOf(stage.Stations) then
		return
	end

	local state = player:GetAttribute("QuestState")

	if state >= 9 and state <= 11 then
		panel(state)
	elseif state >= 12 and state <= 14 then
		local ok, reason = invoke("Cell")

		if not ok then
			showError(reason)
		end
	end
end)

player:GetAttributeChangedSignal("QuestState"):Connect(function()
	if closePanel then
		closePanel()
	end

	if player:GetAttribute("QuestState") == 8 then
		task.spawn(intro)
	elseif player:GetAttribute("QuestState") == 15 then
		task.spawn(departure)
	end
end)

player.CharacterRemoving:Connect(function()
	if closePanel then
		closePanel()
	end
end)

local function resume()
	if player:GetAttribute("QuestState") == 15 then
		departure()
	else
		intro()
	end
end

player.CharacterAdded:Connect(function()
	task.defer(resume)
end)

retry.Activated:Connect(resume)

local highlight = Instance.new("Highlight")
highlight.FillTransparency = 0.85
highlight.OutlineColor = QuestUI.Accent
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Parent = stage
refreshPresentation = function()
	local state = player:GetAttribute("QuestState") or 0
	local eligible = player:GetAttribute("QuestDataReady") == true
		and player:GetAttribute("PoliceQuestEligible") == true
	if not eligible or state < 8 or state > 15 then
		highlight.Enabled = false
		highlight.Adornee = nil
		hint.Visible = false
		retry.Visible = false
		errorUntil = 0

		return
	end

	highlight.Enabled = eligible and state >= 9 and state < 15 and not busy

	local names = {
		[9] = "Search",
		[10] = "Fingerprint",
		[11] = "Mugshot",
		[12] = "Cell",
		[13] = "Cell",
		[14] = "Cell",
	}
	highlight.Adornee = player:GetAttribute("PoliceMoving") and stage.Suspect
		or stage.Stations:FindFirstChild(names[state] or "")
	if os.clock() < errorUntil then
		hint.Visible = true
	elseif not busy and eligible and state >= 9 and state < 15 then
		hint.Visible = true
		hint.Text = player:GetAttribute("PoliceRouteError")
				and "The suspect's route is blocked. Rejoin to resume this checkpoint."
			or player:GetAttribute("PoliceMoving") and "Follow the suspect to the next booking checkpoint."
			or "LEO: " .. (player:GetAttribute("QuestObjective") or "")
	elseif not retry.Visible and not (busy and state == 15) then
		hint.Visible = false
	end
end

local poseConnection
local poseJoints = {}
local poseCharacter
local diedConnection
local childConnection

local function stopPose()
	if poseConnection then
		poseConnection:Disconnect()
		poseConnection = nil
	end

	for joint in poseJoints do
		if joint.Parent then
			joint.Transform = CFrame.identity
		end
	end

	table.clear(poseJoints)
end

local function refreshStage()
	refreshPresentation()

	local state = player:GetAttribute("QuestState") or 0
	local humanoid = poseCharacter and poseCharacter:FindFirstChildOfClass("Humanoid")
	local active = player:GetAttribute("QuestDataReady") == true
		and player:GetAttribute("PoliceQuestEligible") == true
		and state >= 8
		and state <= 15
		and humanoid ~= nil
		and humanoid.Health > 0

	if not active then
		stopPose()

		return
	end

	if poseConnection then
		return
	end

	for _, name in { "RightShoulder", "LeftShoulder" } do
		local joint = stage.Suspect:FindFirstChild(name, true)

		if joint then
			poseJoints[joint] =
				CFrame.Angles(math.rad(55), 0, math.rad(name == "RightShoulder" and -30 or 30))
		end
	end

	poseConnection = RunService.PreSimulation:Connect(function()
		for joint, transform in poseJoints do
			joint.Transform = transform
		end
	end)
end

local function bindPoseCharacter(character)
	stopPose()

	if diedConnection then
		diedConnection:Disconnect()
		diedConnection = nil
	end

	if childConnection then
		childConnection:Disconnect()
		childConnection = nil
	end

	poseCharacter = character

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if character and not humanoid then
		childConnection = character.ChildAdded:Connect(function(child)
			if child:IsA("Humanoid") then
				bindPoseCharacter(character)
			end
		end)
	elseif humanoid then
		diedConnection = humanoid.Died:Connect(refreshStage)
	end

	refreshStage()
end

for _, attribute in { "QuestState", "QuestDataReady", "PoliceQuestEligible" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshStage)
end

for _, attribute in { "PoliceMoving", "PoliceRouteError", "QuestObjective" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshPresentation)
end

retry:GetPropertyChangedSignal("Visible"):Connect(refreshPresentation)
player.CharacterAdded:Connect(bindPoseCharacter)
player.CharacterRemoving:Connect(function()
	bindPoseCharacter(nil)
end)

bindPoseCharacter(player.Character)

-- Wake when the profile is ready rather than polling throughout loading.
player:GetAttributeChangedSignal("QuestDataReady"):Connect(function()
	if player:GetAttribute("QuestDataReady") then
		task.defer(resume)
	end
end)

if player:GetAttribute("QuestDataReady") then
	task.defer(resume)
end
