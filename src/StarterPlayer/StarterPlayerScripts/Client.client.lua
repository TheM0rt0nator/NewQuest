local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassroomIntro = require(ReplicatedStorage.Cutscenes.ClassroomIntro)
local ClassroomFinale = require(ReplicatedStorage.Cutscenes.ClassroomFinale)
local DoctorIntro = require(ReplicatedStorage.Cutscenes.DoctorIntro)
local FlightClassroom = require(ReplicatedStorage.Cutscenes.FlightClassroom)
local PoliceClassroom = require(ReplicatedStorage.Cutscenes.PoliceClassroom)
local DoctorConfig = require(ReplicatedStorage.Modules.DoctorQuestConfig)
local QuestConfig = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local CutsceneManager = require(ReplicatedStorage.Modules.CutsceneManager)
local DreamTransition = require(ReplicatedStorage.Modules.DreamTransition)
local QuestUI = require(ReplicatedStorage.Modules.QuestUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local beginSeating = ReplicatedStorage:WaitForChild("BeginClassroomSeating")
local endSeating = ReplicatedStorage:WaitForChild("EndClassroomSeating")
local beginDoctorIntro = ReplicatedStorage:WaitForChild("BeginDoctorIntro")
local endDoctorIntro = ReplicatedStorage:WaitForChild("EndDoctorIntro")
local returnToBerryAvenue = ReplicatedStorage:WaitForChild("ReturnToBerryAvenue")
local busy = false
local introCharacter
local doctorIntroFinishedCharacter
local policeIntroFinishedCharacter
local flightClassroomFinishedCharacter
local finaleFinishedCharacter

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
QuestUI.Style(retry, true)

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
QuestUI.Style(objectiveLabel)
retry.Position = UDim2.new(0, 24, 0.08, 98)

local function updateObjective()
	objectiveLabel.Text = "ANNIVERSARY QUEST\n" .. (player:GetAttribute("QuestObjective") or "")

	local returnStatus = player:GetAttribute("QuestReturnStatus")

	if returnStatus == "Teleporting" then
		objectiveLabel.Text = "QUEST COMPLETE\nReturning to Berry Avenue..."
	elseif returnStatus == "AwardingBadge" then
		objectiveLabel.Text = "QUEST COMPLETE\nCollecting your completion badge..."
	elseif returnStatus == "Failed" then
		objectiveLabel.Text = player:GetAttribute("QuestBadgeStatus") == "Failed"
				and "QUEST COMPLETE\nCouldn't award your badge. Please try again."
			or "QUEST COMPLETE\nCouldn't return to Berry Avenue. Please try again."
	end

	local taskId = player:GetAttribute("DoctorTask")

	if player:GetAttribute("QuestState") == 3 and DoctorConfig.Tasks[taskId] then
		objectiveLabel.Text = string.format(
			"PATIENT CARE  •  %d / 6\n%s %s",
			player:GetAttribute("QuestProgress") or 0,
			player:GetAttribute("DoctorBusy") and "Using"
				or player:GetAttribute("DoctorCarrying") and "Return with"
				or "Collect",
			DoctorConfig.Tasks[taskId].Label
		)
	end

	local state = player:GetAttribute("QuestState") or 0
	objectiveLabel.Visible = not busy
		and player:GetAttribute("QuestDataReady") == true
		and not (state >= 8 and state <= 21)
end

player:GetAttributeChangedSignal("QuestObjective"):Connect(updateObjective)
player:GetAttributeChangedSignal("QuestReturnStatus"):Connect(function()
	retry.Text = "Return to Berry Avenue"
	retry.Visible = player:GetAttribute("QuestReturnStatus") == "Failed"
	updateObjective()
end)

for _, attribute in { "DoctorTask", "DoctorCarrying", "DoctorBusy", "QuestProgress" } do
	player:GetAttributeChangedSignal(attribute):Connect(updateObjective)
end

local function playIntro()
	if busy or CutsceneManager.IsPlaying() then
		return
	end

	-- Completion reaches the server asynchronously; do not replay during that gap.
	local startingState = player:GetAttribute("QuestState")

	if
		player.Character
		and (
			startingState == 2 and doctorIntroFinishedCharacter == player.Character
			or (startingState == 4 or startingState == 5) and policeIntroFinishedCharacter == player.Character
			or startingState == QuestConfig.States.FlightClassroom
				and flightClassroomFinishedCharacter == player.Character
			or startingState == 6 and finaleFinishedCharacter == player.Character
		)
	then
		return
	end

	busy = true
	objectiveLabel.Visible = false
	retry.Visible = false
	setControlsEnabled(false)

	local seatingRequested = false
	local doctorRequested = false
	local policeRequested = false
	local flightRequested = false
	local finaleRequested = false
	local dream
	local humanoid
	local jumpingEnabled
	local ok, status, reason = xpcall(function()
		local character = player.Character or player.CharacterAdded:Wait()
		introCharacter = character

		local function checkCharacter()
			assert(
				character == player.Character and character.Parent,
				"Character changed during loading"
			)

			local currentHumanoid = character:FindFirstChildOfClass("Humanoid")
			assert(not currentHumanoid or currentHumanoid.Health > 0, "Character died")
		end

		local function coverDream(check, returningToReality)
			if not dream then
				dream = DreamTransition.Take(playerGui)
				dream:Cover(check or checkCharacter, returningToReality)
			end
		end

		local function playDoctor()
			if (player:GetAttribute("QuestState") or 0) > 2 then
				return "Resumed"
			end

			coverDream()
			retry.Text = "Retry patient introduction"

			local doctorStage = workspace:WaitForChild("DoctorQuest", 15)
			assert(doctorStage, "DoctorQuest is missing")

			if workspace.StreamingEnabled then
				player:RequestStreamAroundAsync(doctorStage.Markers.Arrival.Position, 10)
			end

			local arrivalDeadline = os.clock() + 15

			repeat
				checkCharacter()

				-- A queued request can outlive the introduction checkpoint.
				if (player:GetAttribute("QuestState") or 0) > 2 then
					return "Resumed"
				end

				assert(os.clock() < arrivalDeadline, "Could not arrive beside the hospital bed")

				local root = character:FindFirstChild("HumanoidRootPart")
				local student = character:FindFirstChildOfClass("Humanoid")

				if
					player:GetAttribute("QuestState") == 2
					and player:GetAttribute("DoctorQuestEligible")
					and character:GetAttribute("QuestResumeState") == 2
					and student
					and not student.Sit
					and not student.SeatPart
					and root
					and (root.Position - doctorStage.Markers.Arrival.Position).Magnitude < 12
				then
					break
				end

				task.wait(0.05)
			until false
			doctorRequested = beginDoctorIntro:InvokeServer()
			assert(doctorRequested, "Could not prepare the patient introduction")

			return CutsceneManager.Play(DoctorIntro(doctorStage, function(context)
				dream:Reveal(function()
					context:Check()
				end)

				dream = nil
			end))
		end

		local deadline = os.clock() + 135

		while not player:GetAttribute("QuestDataReady") do
			checkCharacter()
			assert(os.clock() < deadline, "Quest data is not ready")
			task.wait(0.05)
		end

		while
			not character:GetAttribute("ClassroomReady")
			or character:GetAttribute("QuestResumeState") ~= player:GetAttribute("QuestState")
		do
			checkCharacter()
			assert(os.clock() < deadline, "The classroom is not ready")
			task.wait(0.05)
		end

		if
			player:GetAttribute("QuestState") == 2 and player:GetAttribute("DoctorQuestEligible")
		then
			return playDoctor()
		end

		local questState = player:GetAttribute("QuestState")

		if player:GetAttribute("QuestCompleted") then
			returnToBerryAvenue:FireServer()

			return "Resumed"
		end

		local returningToClassroom = questState == 4
		policeRequested = QuestConfig.EnablePoliceClassroom and (questState == 4 or questState == 5)
		flightRequested = questState == QuestConfig.States.FlightClassroom
		finaleRequested = questState == 6
			or returningToClassroom and not QuestConfig.EnablePoliceClassroom
		if
			not policeRequested
			and not flightRequested
			and not finaleRequested
			and player:GetAttribute("ClassroomIntroEligible") ~= true
		then
			return "Resumed"
		end

		if policeRequested or returningToClassroom then
			retry.Text = "Retry Leo's classroom scene"

			-- Finish the treatment before requesting the next checkpoint under the veil.
			deadline = os.clock() + 15

			while player:GetAttribute("DoctorBusy") do
				checkCharacter()
				assert(os.clock() < deadline, "The last treatment is still finishing")
				task.wait(0.05)
			end

			coverDream(nil, true)
		end

		if finaleRequested then
			retry.Text = "Retry class dismissal"
			coverDream(nil, true)
		end

		if flightRequested then
			retry.Text = "Retry Amira's classroom scene"
			coverDream(nil, true)
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
		if finaleRequested then
			return CutsceneManager.Play(
				ClassroomFinale(stage, function(context)
					if dream then
						dream:Reveal(function()
							context:Check()
						end)

						dream = nil
					end
				end),

				{ StudentSeat = seat }
			)
		end

		if policeRequested or flightRequested then
			local classroomScene = flightRequested and FlightClassroom or PoliceClassroom
			local classroomStatus, classroomReason = CutsceneManager.Play(
				classroomScene(stage, function(context)
					dream:Reveal(function()
						context:Check()
					end)

					dream = nil
				end, function(context)
					coverDream(function()
						context:Check()
					end)
				end),

				{ StudentSeat = seat }
			)

			if
				classroomStatus == "Completed"
				or classroomStatus == "Cancelled" and classroomReason == "Skipped"
			then
				-- A skip can interrupt the cover animation before it becomes opaque.
				if dream and classroomStatus == "Cancelled" then
					dream:Destroy()
					dream = nil
				end

				coverDream()
				DreamTransition.HandOff(dream)
				dream = nil
			end

			return classroomStatus, classroomReason
		end

		local classroomStatus, classroomReason = CutsceneManager.Play(
			ClassroomIntro(stage, function(context)
				assert(humanoid.SeatPart == seat and humanoid.Sit, "Student left the seat")

				if dream then
					dream:Reveal(function()
						context:Check()
					end)

					dream = nil
				end
			end, function(context)
				coverDream(function()
					context:Check()
				end)
			end),

			{ StudentSeat = seat }
		)

		if
			classroomStatus == "Completed"
			or classroomStatus == "Cancelled" and classroomReason == "Skipped"
		then
			-- Keep the veil and movement lock through seat release and server placement.
			-- Skipping during the effect may have interrupted its first animation.
			if dream and classroomStatus == "Cancelled" then
				dream:Destroy()
				dream = nil
			end

			coverDream()
			endSeating:FireServer(classroomStatus == "Completed" and "Completed" or "Skipped")
			seatingRequested = false

			return playDoctor()
		end

		return classroomStatus, classroomReason
	end, debug.traceback)

	if not ok then
		reason = status
		status = "Failed"
	end

	if dream then
		dream:Destroy()
	end

	if seatingRequested then
		local outcome = status == "Completed" and "Completed" or "Cancelled"

		if status == "Cancelled" and reason == "Skipped" then
			outcome = "Skipped"
		end

		if policeRequested and (outcome == "Completed" or outcome == "Skipped") then
			policeIntroFinishedCharacter = introCharacter
		end

		if flightRequested and (outcome == "Completed" or outcome == "Skipped") then
			flightClassroomFinishedCharacter = introCharacter
		end

		if finaleRequested and (outcome == "Completed" or outcome == "Skipped") then
			finaleFinishedCharacter = introCharacter
		end

		endSeating:FireServer(outcome)
	end

	if doctorRequested then
		local outcome = status == "Completed" and "Completed" or "Cancelled"

		if status == "Cancelled" and reason == "Skipped" then
			outcome = "Skipped"
		end

		if outcome == "Completed" or outcome == "Skipped" then
			doctorIntroFinishedCharacter = introCharacter
		end

		endDoctorIntro:FireServer(outcome)
	end

	if humanoid and humanoid.Parent and jumpingEnabled ~= nil then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpingEnabled)
	end

	setControlsEnabled(true)
	busy = false
	updateObjective()
	gui:SetAttribute("LastStatus", status)
	gui:SetAttribute("LastReason", reason)
	retry.Visible = (
		player:GetAttribute("ClassroomIntroEligible") == true
		or player:GetAttribute("QuestState") == 2 and player:GetAttribute("DoctorQuestEligible")
		or player:GetAttribute("QuestState") == 4
		or player:GetAttribute("QuestState") == 5
		or player:GetAttribute("QuestState") == 6
		or player:GetAttribute("QuestState") == QuestConfig.States.FlightClassroom
	) and (status == "Failed" or status == "Cancelled")

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

player:GetAttributeChangedSignal("QuestState"):Connect(function()
	local state = player:GetAttribute("QuestState")

	if
		(
			state == 2
			or state == 4
			or state == 5
			or state == 6
			or state == QuestConfig.States.FlightClassroom
		)
		and not busy
	then
		task.spawn(function()
			while busy do
				task.wait()
			end

			if player:GetAttribute("QuestState") == state then
				playIntro()
			end
		end)
	else
		retry.Visible = false
	end
end)

retry.Activated:Connect(function()
	if player:GetAttribute("QuestCompleted") then
		returnToBerryAvenue:FireServer()
	else
		playIntro()
	end
end)

player.CharacterAdded:Connect(function(character)
	task.defer(function()
		while busy do
			task.wait()
		end

		-- Initial startup may already have handled this same CharacterAdded event.
		if player.Character == character and introCharacter ~= character then
			playIntro()
		end
	end)
end)

task.spawn(playIntro)
