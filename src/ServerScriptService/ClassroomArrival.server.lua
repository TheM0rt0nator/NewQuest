-- Single-player classroom placement and validated introduction checkpoints.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClassroomSitting = require(script.Parent.ClassroomSitting)
local ChapterPlacement = require(script.Parent.ChapterPlacement)
local QuestService = require(script.Parent.QuestService)
local QuestReturnService = require(script.Parent.QuestReturnService)

local beginSeating = ReplicatedStorage:WaitForChild("BeginClassroomSeating")
local endSeating = ReplicatedStorage:WaitForChild("EndClassroomSeating")
local sessions = {}

local stage = workspace:WaitForChild("ClassroomIntro", 15)

if not stage then
	warn("ClassroomIntro is missing. Install the classroom set in Studio first.")

	return
end

for _, actor in stage.Actors:GetChildren() do
	if actor:GetAttribute("ClassroomSeat") then
		ClassroomSitting.Play(actor.Humanoid)
	end
end

local function releaseSeat(player, outcome)
	local session = sessions[player]

	if not session or session.releasing then
		return
	end

	if session.finished and outcome then
		return
	end

	session.releasing = true

	if session.leftSeat then
		session.leftSeat:Disconnect()
	end

	if session.timeout then
		task.cancel(session.timeout)
	end

	session.died:Disconnect()

	if session.sitTrack then
		session.sitTrack:Stop(0)
		session.sitTrack:Destroy()
	end

	local canAdvance = (outcome == "Completed" or outcome == "Skipped")
		and player.Character == session.character
		and session.humanoid.Health > 0
		and session.humanoid.SeatPart == session.seat
	-- Remove the physical joint before moving the character out of the chair.
	session.seat.Disabled = true

	local weld = session.seat:FindFirstChild("SeatWeld")

	if weld then
		weld:Destroy()
	end

	session.seat:Destroy()

	if player.Character == session.character and session.root.Parent then
		local ownsPhysics = session.root:CanSetNetworkOwnership()

		if ownsPhysics then
			session.root:SetNetworkOwner(nil)
		end

		local seatedEnabled = session.humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)
		session.humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		session.humanoid.Sit = false
		session.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

		-- Let the seat state and assembly update before the checkpoint teleports us.
		local detachDeadline = os.clock() + 2

		repeat
			RunService.Heartbeat:Wait()
		until not session.humanoid.SeatPart or os.clock() >= detachDeadline
		canAdvance = canAdvance and session.humanoid.SeatPart == nil

		if player.Character ~= session.character or not session.root.Parent then
			sessions[player] = nil

			return
		end

		session.humanoid.WalkSpeed = session.walkSpeed
		session.humanoid.JumpPower = session.jumpPower
		session.humanoid.JumpHeight = session.jumpHeight
		session.humanoid.AutoRotate = session.autoRotate

		if not session.finished then
			session.character:PivotTo(session.originalCFrame)
		end

		session.root.AssemblyLinearVelocity = Vector3.zero
		session.root.AssemblyAngularVelocity = Vector3.zero
		sessions[player] = nil

		if canAdvance and session.humanoid.Health > 0 then
			if session.questState == 6 then
				if QuestService:CompleteFinale(player) then
					task.spawn(QuestReturnService.Return, player)
				end
			else
				QuestService:CompleteObjective(player, "AnniversaryQuest", session.questState)
			end
		end

		RunService.Heartbeat:Wait()

		if session.humanoid.Parent then
			session.humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, seatedEnabled)
		end

		if ownsPhysics and session.root.Parent and session.root:CanSetNetworkOwnership() then
			session.root:SetNetworkOwnershipAuto()
		end
	end

	sessions[player] = nil
end

beginSeating.OnServerInvoke = function(player)
	local retained = sessions[player]

	if
		retained
		and retained.finished
		and not retained.releasing
		and QuestService:IsActiveStep(player, 6)
		and player.Character == retained.character
		and retained.humanoid.Health > 0
		and retained.humanoid.SeatPart == retained.seat
	then
		-- Continue the finale in the exact seat used for the return classroom scene.
		retained.finished = false
		retained.questState = 6
		retained.leftSeat:Disconnect()
		retained.leftSeat = nil
		retained.humanoid.WalkSpeed = 0
		retained.humanoid.JumpPower = 0
		retained.humanoid.JumpHeight = 0
		retained.humanoid.AutoRotate = false
		retained.timeout = task.delay(180, function()
			if sessions[player] == retained then
				retained.timeout = nil
				releaseSeat(player)
			end
		end)

		return retained.seat.Name
	end

	if sessions[player] then
		return nil, "You are already seated for this scene"
	end

	if not player:GetAttribute("QuestDataReady") then
		return nil, "Quest data is still loading"
	end

	local questState = player:GetAttribute("QuestState")

	if
		not QuestService:IsClassroomIntroStep(player)
		and not QuestService:IsActiveStep(player, 4)
		and not QuestService:IsActiveStep(player, 5)
		and not QuestService:IsActiveStep(player, 6)
	then
		return nil, "The classroom introduction is not the current quest step"
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, "Character is not ready"
	end

	if player:GetAttribute("DoctorBusy") then
		return nil, "The last treatment is still finishing"
	end

	if questState == 4 then
		if not QuestService:CompleteObjective(player, "AnniversaryQuest", 4) then
			return nil, "Could not begin the next classroom scene"
		end

		questState = player:GetAttribute("QuestState")
	end

	ChapterPlacement.Release(character)

	local seat = Instance.new("Seat")
	seat.Name = "ClassroomStudentSeat_" .. player.UserId
	seat.Size = Vector3.new(1.7, 0.2, 1)
	seat.CFrame = stage.Markers.PlayerSeat.CFrame
	seat.Anchored = true
	seat.Transparency = 1
	seat.CanCollide = false
	seat.CanQuery = false
	seat.Parent = stage

	local session = {
		questState = questState,
		character = character,
		humanoid = humanoid,
		root = root,
		originalCFrame = stage.Markers.Arrival.CFrame,
		seat = seat,
		walkSpeed = humanoid.WalkSpeed,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
		autoRotate = humanoid.AutoRotate,
	}
	sessions[player] = session
	session.died = humanoid.Died:Connect(function()
		releaseSeat(player)
	end)

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	root.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
	seat:Sit(humanoid)

	local animated, track = pcall(ClassroomSitting.Play, humanoid)

	if not animated then
		releaseSeat(player)

		return nil, tostring(track)
	end

	session.sitTrack = track
	character:SetAttribute("QuestResumeStage", stage.Name)
	character:SetAttribute("QuestResumeState", questState)

	-- Release abandoned sessions even if the client disconnects mid-cutscene.
	session.timeout = task.delay(180, function()
		if sessions[player] == session then
			session.timeout = nil
			releaseSeat(player)
		end
	end)

	return seat.Name
end

endSeating.OnServerEvent:Connect(releaseSeat)
ReplicatedStorage:WaitForChild("ReturnToBerryAvenue").OnServerEvent
	:Connect(QuestReturnService.Return)
Players.PlayerRemoving:Connect(function(player)
	releaseSeat(player)
	QuestService:RemovePlayer(player)
end)

local function placeCharacter(character)
	local player = Players:GetPlayerFromCharacter(character)

	if not player then
		return
	end

	local deadline = os.clock() + 135

	while not player:GetAttribute("QuestDataReady") do
		if player.Character ~= character or not character.Parent or os.clock() >= deadline then
			return
		end

		task.wait(0.05)
	end

	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)

	if not root or not humanoid or not character.Parent or player.Character ~= character then
		return
	end

	local objective = QuestService:GetObjective(player)
	local resumeStage = objective
		and workspace:FindFirstChild(objective.ResumeStage or "ClassroomIntro")
	local marker = resumeStage and resumeStage.Markers:FindFirstChild(objective.ResumeMarker)

	if not marker then
		warn("No resume marker is configured for the player's quest state")

		return
	end

	-- Checkpoints inside the same chapter should not teleport the player again.
	if character:GetAttribute("QuestResumeStage") ~= resumeStage.Name then
		if objective.Cutscene then
			ChapterPlacement.Hold(character, marker.CFrame)
		else
			character:PivotTo(marker.CFrame)
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end

	character:SetAttribute("QuestResumeStage", resumeStage.Name)
	character:SetAttribute("QuestResumeState", objective.Id)
	character:SetAttribute("ClassroomReady", true)
end

QuestService.StateChanged:Connect(function(player)
	if player.Character and not sessions[player] then
		placeCharacter(player.Character)
	end
end)

local function connectPlayer(player)
	task.spawn(QuestService.LoadPlayer, QuestService, player)
	player.CharacterRemoving:Connect(function(character)
		releaseSeat(player)
		ChapterPlacement.Release(character)
	end)

	player.CharacterAdded:Connect(placeCharacter)

	if player.Character then
		task.spawn(placeCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(connectPlayer)

for _, player in Players:GetPlayers() do
	connectPlayer(player)
end
