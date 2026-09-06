local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassroomIntro = require(ReplicatedStorage.Cutscenes.ClassroomIntro)
local CutsceneManager = require(ReplicatedStorage.Modules.CutsceneManager)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local beginSeating = ReplicatedStorage:WaitForChild("BeginClassroomSeating")
local endSeating = ReplicatedStorage:WaitForChild("EndClassroomSeating")
local busy = false

local function setControlsEnabled(enabled)
	local action = "ClassroomIntroMovement"
	if enabled then
		ContextActionService:UnbindAction(action)
		return
	end

	ContextActionService:BindActionAtPriority(
		action,
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 2,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.Up,
		Enum.KeyCode.Down,
		Enum.KeyCode.Left,
		Enum.KeyCode.Right,
		Enum.KeyCode.Space,
		Enum.KeyCode.Thumbstick1,
		Enum.KeyCode.ButtonA,
		table.unpack(Enum.PlayerActions:GetEnumItems())
	)
end

local gui = Instance.new("ScreenGui")
gui.Name = "ClassroomChapter"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ScreenInsets = Enum.ScreenInsets.None
gui.DisplayOrder = 110
gui.Parent = playerGui

local loading = Instance.new("TextLabel")
loading.Name = "Loading"
loading.Size = UDim2.fromScale(1, 1)
loading.BackgroundColor3 = Color3.fromRGB(22, 29, 40)
loading.TextColor3 = Color3.fromRGB(235, 204, 140)
loading.Font = Enum.Font.GothamMedium
loading.TextSize = 24
loading.Text = "CHAPTER ONE\nWhen I grow up..."
loading.Visible = true
loading.Parent = gui

local retry = Instance.new("TextButton")
retry.Name = "Retry"
retry.Position = UDim2.new(0, 24, 0.08, 16)
retry.Size = UDim2.fromOffset(230, 44)
retry.BackgroundColor3 = Color3.fromRGB(22, 29, 40)
retry.TextColor3 = Color3.fromRGB(235, 204, 140)
retry.Font = Enum.Font.GothamMedium
retry.TextSize = 15
retry.Text = "Retry classroom intro"
retry.Visible = false
retry.Parent = gui

local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.Name = "Objective"
objectiveLabel.Position = UDim2.new(0, 24, 0.08, 16)
objectiveLabel.Size = UDim2.fromOffset(390, 70)
objectiveLabel.BackgroundColor3 = Color3.fromRGB(22, 29, 40)
objectiveLabel.BackgroundTransparency = 0.15
objectiveLabel.TextColor3 = Color3.fromRGB(235, 204, 140)
objectiveLabel.Font = Enum.Font.GothamMedium
objectiveLabel.TextSize = 18
objectiveLabel.TextWrapped = true
objectiveLabel.Visible = false
objectiveLabel.Parent = gui
retry.Position = UDim2.new(0, 24, 0.08, 98)

local function updateObjective()
	objectiveLabel.Text = "ANNIVERSARY QUEST\n" .. (player:GetAttribute("QuestObjective") or "")
	objectiveLabel.Visible = not busy and player:GetAttribute("QuestDataReady") == true
end

player:GetAttributeChangedSignal("QuestObjective"):Connect(updateObjective)

local function playIntro()
	if busy or CutsceneManager.IsPlaying() then
		return
	end

	busy = true
	objectiveLabel.Visible = false
	retry.Visible = false
	loading.Visible = true
	setControlsEnabled(false)

	local seatingRequested = false
	local humanoid
	local jumpingEnabled
	local ok, status, reason = xpcall(function()
		local character = player.Character or player.CharacterAdded:Wait()
		local function checkCharacter()
			assert(
				character == player.Character and character.Parent,
				"Character changed during loading"
			)
		end

		local deadline = os.clock() + 135
		while not player:GetAttribute("QuestDataReady") do
			checkCharacter()
			assert(os.clock() < deadline, "Quest data is not ready")
			task.wait(0.05)
		end
		while not character:GetAttribute("ClassroomReady") do
			checkCharacter()
			assert(os.clock() < deadline, "The classroom is not ready")
			task.wait(0.05)
		end
		if player:GetAttribute("ClassroomIntroEligible") ~= true then
			return "Resumed"
		end

		humanoid = character:FindFirstChildOfClass("Humanoid")
		assert(humanoid and humanoid.Health > 0, "The student character is not ready")
		jumpingEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid.Jump = false

		local stage = workspace:WaitForChild("ClassroomIntro", 15)
		assert(stage, "ClassroomIntro is missing")
		seatingRequested = true
		local seatName, seatReason = beginSeating:InvokeServer()
		assert(seatName, seatReason or "Could not prepare the classroom seat")

		local seat
		deadline = os.clock() + 8
		repeat
			checkCharacter()
			assert(humanoid.Health > 0, "Character died during seating")
			assert(os.clock() < deadline, "The classroom seat is not ready")
			seat = stage:FindFirstChild(seatName)
			task.wait(0.05)
		until seat and humanoid.SeatPart == seat

		if workspace.StreamingEnabled then
			player:RequestStreamAroundAsync(stage.Markers.Arrival.Position, 10)
		end
		checkCharacter()

		-- Reveal only after the runner owns the camera and the opening shot is set.
		return CutsceneManager.Play(
			ClassroomIntro(stage, function()
				assert(humanoid.SeatPart == seat and humanoid.Sit, "Student left the seat")
				loading.Visible = false
			end),
			{ StudentSeat = seat }
		)
	end, debug.traceback)

	if not ok then
		reason = status
		status = "Failed"
	end
	if seatingRequested then
		local outcome = status == "Completed" and "Completed" or "Cancelled"
		if status == "Cancelled" and reason == "Skipped" then
			outcome = "Skipped"
		end
		endSeating:FireServer(outcome)
	end
	if humanoid and humanoid.Parent and jumpingEnabled ~= nil then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpingEnabled)
	end

	setControlsEnabled(true)
	loading.Visible = false
	busy = false
	updateObjective()
	gui:SetAttribute("LastStatus", status)
	gui:SetAttribute("LastReason", reason)
	retry.Visible = player:GetAttribute("ClassroomIntroEligible") == true
		and (status == "Failed" or status == "Cancelled")

	if status == "Failed" then
		warn("[ClassroomIntro]", reason)
	else
		print("[ClassroomIntro]", status, reason or "")
	end
end

player:GetAttributeChangedSignal("ClassroomIntroEligible"):Connect(function()
	if player:GetAttribute("ClassroomIntroEligible") ~= true then
		retry.Visible = false
	end
end)

retry.Activated:Connect(playIntro)
player.CharacterAdded:Connect(function()
	task.defer(playIntro)
end)
task.spawn(playIntro)
