local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Modules.DoctorQuestConfig)

local player = Players.LocalPlayer
local stage = workspace:WaitForChild("DoctorQuest")
local monitor = stage.Monitor
local label = monitor.Display.Text
local beep = monitor.Beep

local highlight = Instance.new("Highlight")
highlight.Name = "DoctorObjective"
highlight.FillTransparency = 0.8
highlight.OutlineTransparency = 0.1
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = stage

local monitorConnection
local gestureConnection
local diedConnection
local childConnection
local character
local humanoid
local nextBeat = 0
local lastBeat = 0
local nextPaint = 0
local currentState
local gestureJoints = {}

local function stopGesture()
	if gestureConnection then
		gestureConnection:Disconnect()
		gestureConnection = nil
	end

	for _, joint in gestureJoints do
		if joint.Parent then
			joint.Transform = CFrame.identity
		end
	end

	table.clear(gestureJoints)
end

local function stopMonitor()
	if monitorConnection then
		monitorConnection:Disconnect()
		monitorConnection = nil
	end

	beep:Stop()
	highlight.Enabled = false
	highlight.Adornee = nil
	monitor:SetAttribute("WarningActive", false)
	nextBeat = 0
	nextPaint = 0
end

local function animateGesture()
	local wave = math.sin(os.clock() * 3) * 12
	local twist = player:GetAttribute("DoctorTask") == "Bandage" and wave or 0

	for _, joint in gestureJoints do
		if joint.Parent then
			joint.Transform = CFrame.Angles(math.rad(65 + wave), 0, math.rad(twist))
		end
	end
end

local function updateMonitor()
	local state = player:GetAttribute("QuestState")
	local progress = state == 4 and 6 or player:GetAttribute("QuestProgress") or 0
	local stable = state == 4
	local warning = state == 3 and player:GetAttribute("DoctorTask") == Config.FinalTaskId
	local interval = Config.NormalBeatInterval
		+ (stable and 0 or progress * Config.BeatIntervalIncrease)
	local now = os.clock()

	if now >= nextBeat then
		beep:Play()
		lastBeat = now
		nextBeat = now + interval
	end

	-- The pulse display needs only 20 updates per second, while this chapter is active.
	if now < nextPaint then
		return
	end

	nextPaint = now + 0.05

	local color = warning and Color3.fromRGB(255, 82, 89) or Color3.fromRGB(113, 239, 187)
	label.TextColor3 = color
	label.BackgroundColor3 = warning
			and math.floor(now * 3) % 2 == 0
			and Color3.fromRGB(100, 16, 28)
		or Color3.fromRGB(10, 26, 36)
	label.Text = string.format(
		"%s\n%s  %d\n%s",
		stable and "RECOVERED" or "PATIENT",
		now - lastBeat < 0.22 and "♥" or "♡",
		math.floor(60 / interval + 0.5),
		warning and "LOW HEART RATE" or stable and "STABLE" or "MONITORING"
	)
	monitor:SetAttribute("WarningActive", warning)
	monitor:SetAttribute("BeatInterval", interval)
end

local function refresh()
	local state = player:GetAttribute("QuestState") or 0
	local active = player:GetAttribute("QuestDataReady") == true
		and player:GetAttribute("DoctorQuestEligible") == true
		and state >= 2
		and state <= 4
		and character ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0

	if not active then
		stopMonitor()
		stopGesture()

		return
	end

	if state ~= currentState then
		currentState = state
		nextBeat = 0
	end

	nextPaint = 0

	if not monitorConnection then
		monitorConnection = RunService.Heartbeat:Connect(updateMonitor)
	end

	updateMonitor()

	local warning = state == 3 and player:GetAttribute("DoctorTask") == Config.FinalTaskId
	local color = warning and Color3.fromRGB(255, 82, 89) or Color3.fromRGB(113, 239, 187)
	highlight.Enabled = state == 3 and not player:GetAttribute("DoctorBusy")
	highlight.Adornee = player:GetAttribute("DoctorCarrying") and stage.Patient
		or stage.Supplies:FindFirstChild(player:GetAttribute("DoctorTask") or "")
	highlight.FillColor = color
	highlight.OutlineColor = color

	if state ~= 3 or not player:GetAttribute("DoctorTreating") then
		stopGesture()

		return
	end

	if gestureConnection then
		return
	end

	for _, name in { "RightShoulder", "LeftShoulder", "Right Shoulder", "Left Shoulder" } do
		local joint = character:FindFirstChild(name, true)

		if joint and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
			table.insert(gestureJoints, joint)
		end
	end

	-- Apply the treatment pose after Animator evaluation, only during treatment.
	gestureConnection = RunService.PreSimulation:Connect(animateGesture)
end

local function bindCharacter(newCharacter)
	stopMonitor()
	stopGesture()

	if diedConnection then
		diedConnection:Disconnect()
		diedConnection = nil
	end

	if childConnection then
		childConnection:Disconnect()
		childConnection = nil
	end

	character = newCharacter
	humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if character and not humanoid then
		childConnection = character.ChildAdded:Connect(function(child)
			if child:IsA("Humanoid") then
				bindCharacter(character)
			end
		end)
	elseif humanoid then
		diedConnection = humanoid.Died:Connect(refresh)
	end

	refresh()
end

for _, attribute in
	{
		"QuestState",
		"QuestDataReady",
		"DoctorQuestEligible",
		"DoctorTreating",
		"DoctorTask",
		"DoctorBusy",
		"DoctorCarrying",
		"QuestProgress",
	}
do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function()
	bindCharacter(nil)
end)

bindCharacter(player.Character)
