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
highlight.Parent = stage

local nextBeat = 0
local lastBeat = 0
local currentState
local gestureJoints = {}

-- Both AnimationConstraint and Motor6D rigs expose Transform. Apply after Animator evaluation.
RunService.PreSimulation:Connect(function()
	local character = player.Character
	local treating = player:GetAttribute("DoctorTreating") == true
	if not treating or not character then
		for _, joint in gestureJoints do
			if joint.Parent then
				joint.Transform = CFrame.identity
			end
		end
		table.clear(gestureJoints)
		return
	end
	if #gestureJoints == 0 then
		for _, name in { "RightShoulder", "LeftShoulder", "Right Shoulder", "Left Shoulder" } do
			local joint = character:FindFirstChild(name, true)
			if joint and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
				table.insert(gestureJoints, joint)
			end
		end
	end
	local wave = math.sin(os.clock() * 3) * 12
	for _, joint in gestureJoints do
		if joint.Parent then
			local twist = player:GetAttribute("DoctorTask") == "Bandage" and wave or 0
			joint.Transform = CFrame.Angles(math.rad(65 + wave), 0, math.rad(twist))
		end
	end
end)

RunService.Heartbeat:Connect(function()
	local state = player:GetAttribute("QuestState")
	local active = player:GetAttribute("DoctorQuestEligible") == true
	if state ~= currentState then
		currentState = state
		nextBeat = 0
	end
	if not active then
		beep:Stop()
		highlight.Enabled = false
		return
	end
	local progress = state == 4 and 6 or player:GetAttribute("QuestProgress") or 0
	local stable = state == 4
	local warning = not stable and progress / #Config.TaskIds >= Config.WarningFraction
	local interval = Config.NormalBeatInterval
		+ (stable and 0 or progress * Config.BeatIntervalIncrease)
	local now = os.clock()
	if now >= nextBeat then
		beep:Play()
		lastBeat = now
		nextBeat = now + interval
	end
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
	local taskId = player:GetAttribute("DoctorTask")
	highlight.Enabled = state == 3 and not player:GetAttribute("DoctorBusy")
	highlight.Adornee = player:GetAttribute("DoctorCarrying") and stage.Patient
		or stage.Supplies:FindFirstChild(taskId or "")
	highlight.FillColor = color
	highlight.OutlineColor = color
end)
