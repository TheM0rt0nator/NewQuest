-- Single-player classroom placement and validated introduction checkpoints.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassroomSitting = require(script.Parent.ClassroomSitting)
local QuestService = require(script.Parent.QuestService)

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
	if not session then
		return
	end

	sessions[player] = nil
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
	session.seat:Destroy()
	if player.Character == session.character and session.root.Parent then
		session.humanoid.Sit = false
		session.humanoid.WalkSpeed = session.walkSpeed
		session.humanoid.JumpPower = session.jumpPower
		session.humanoid.JumpHeight = session.jumpHeight
		session.humanoid.AutoRotate = session.autoRotate
		session.root.CFrame = session.originalCFrame
		session.root.AssemblyLinearVelocity = Vector3.zero
		session.root.AssemblyAngularVelocity = Vector3.zero
	end
	if canAdvance and player:GetAttribute("QuestState") == 1 then
		QuestService:CompleteObjective(player, "AnniversaryQuest", 1)
	end
end

beginSeating.OnServerInvoke = function(player)
	if sessions[player] then
		return nil, "You are already seated for this scene"
	end
	if not player:GetAttribute("QuestDataReady") then
		return nil, "Quest data is still loading"
	end
	if not QuestService:IsClassroomIntroStep(player) then
		return nil, "The classroom introduction is not the current quest step"
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, "Character is not ready"
	end

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
		character = character,
		humanoid = humanoid,
		root = root,
		originalCFrame = root.CFrame,
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
	character:PivotTo(marker.CFrame)
	root.AssemblyLinearVelocity = Vector3.zero
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
	player.CharacterRemoving:Connect(function()
		releaseSeat(player)
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
