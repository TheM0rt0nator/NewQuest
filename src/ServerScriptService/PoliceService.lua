local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local QuestService = require(script.Parent.QuestService)
local ChapterPlacement = require(script.Parent.ChapterPlacement)
local QuestConfig = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local Config = require(ReplicatedStorage.Modules.PoliceQuestConfig)
local PoliceEvidence = require(ReplicatedStorage.Modules.PoliceEvidence)

local PoliceService = {}
local stage
local session
local routeVersion = 0
local doorClosed
local doorBusy = false
local originalDoorPrompts = {}
local actorParts = {}
local collisionConnection

local ACTOR_COLLISION_GROUP = "PoliceQuestActors"

local stationForState = {
	[9] = "Search",
	[10] = "Fingerprint",
	[11] = "Mugshot",
	[12] = "Cell",
	[13] = "Cell",
	[14] = "Cell",
}

local markerForState = {
	[8] = "SuspectEntry",
	[9] = "Search",
	[10] = "Fingerprint",
	[11] = "Mugshot",
	[12] = "CellOutside",
	[13] = "CellOutside",
	[14] = "CellInside",
	[15] = "CellInside",
}

local function active(player, state)
	return QuestService:IsActiveStep(player, state)
end

local function near(player, position, distance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return root
		and humanoid
		and humanoid.Health > 0
		and (root.Position - position).Magnitude <= distance
end

local function updateActorCollisions(player)
	local state = player and player:GetAttribute("QuestState") or 0
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local enabled = player ~= nil
		and player.Parent == Players
		and player:GetAttribute("QuestDataReady") == true
		and player:GetAttribute("PoliceQuestEligible") == true
		and state >= 8
		and state <= 15
		and humanoid ~= nil
		and humanoid.Health > 0

	if enabled then
		if not collisionConnection then
			-- Humanoids may re-enable torso collisions during animation and walking.
			collisionConnection = RunService.Stepped:Connect(function()
				for _, part in actorParts do
					part.CanCollide = false
				end
			end)
		end
	elseif collisionConnection then
		collisionConnection:Disconnect()
		collisionConnection = nil
	end
end

local function refresh(player)
	updateActorCollisions(player)
	PoliceEvidence.Refresh(stage, player)

	local state = player:GetAttribute("QuestState")

	for prompt, enabled in originalDoorPrompts do
		prompt.Enabled = enabled and not (state and state >= 8 and state <= 15)
	end

	for _, station in stage.Stations:GetChildren() do
		station.Interact.Enabled = active(player, state)
			and stationForState[state] == station.Name
			and not player:GetAttribute("PoliceMoving")
			and not session
			and not doorBusy
	end

	stage.Stations.Cell.Interact.ActionText = state == 12 and "Open cell door"
		or state == 13 and "Escort into cell"
		or "Close cell door"
end

local function release(player)
	if not session or session.player ~= player then
		return
	end

	local previous = session
	session = nil

	for part, group in previous.collisionGroups do
		if part.Parent then
			part.CollisionGroup = group
		end
	end

	if previous.root.Parent then
		previous.root.Anchored = previous.anchored

		if not previous.root.Anchored then
			previous.root:SetNetworkOwnershipAuto()
		end
	end

	if previous.humanoid.Parent then
		previous.humanoid.WalkSpeed = previous.speed
		previous.humanoid.JumpPower = previous.jumpPower
		previous.humanoid.JumpHeight = previous.jumpHeight
	end

	player:SetAttribute("PoliceBusy", false)
	refresh(player)
end

local function lock(player, state)
	ChapterPlacement.Release(player.Character)

	local character = player.Character
	session = {
		player = player,
		state = state,
		character = character,
		root = character.HumanoidRootPart,
		humanoid = character.Humanoid,
		anchored = character.HumanoidRootPart.Anchored,
		speed = character.Humanoid.WalkSpeed,
		jumpPower = character.Humanoid.JumpPower,
		jumpHeight = character.Humanoid.JumpHeight,
		collisionGroups = {},
	}

	if state == 8 then
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				session.collisionGroups[part] = part.CollisionGroup
				part.CollisionGroup = ACTOR_COLLISION_GROUP
			end
		end
	end

	session.root.Anchored = true
	session.humanoid.WalkSpeed = 0
	session.humanoid.JumpPower = 0
	session.humanoid.JumpHeight = 0
	player:SetAttribute("PoliceBusy", true)
	refresh(player)

	local captured = session
	task.delay(180, function()
		if session == captured then
			release(player)
		end
	end)

	return captured
end

local function moveModel(model, destination, duration)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()

	local connection = value.Changed:Connect(function(cf)
		model:PivotTo(cf)
	end)

	local tween = TweenService:Create(value, TweenInfo.new(duration), { Value = destination })
	tween:Play()
	tween.Completed:Wait()
	connection:Disconnect()
	value:Destroy()
end

local function setCell(open, animate)
	local door = stage.CellDoor.Value
	local destination = open and doorClosed * CFrame.Angles(0, math.rad(-85), 0) or doorClosed

	if animate then
		moveModel(door, destination, 0.8)
	else
		door:PivotTo(destination)
	end

	door:SetAttribute("IsOpen", open)
end

local function walk(model, marker, valid, via)
	local humanoid = model.Humanoid
	local root = model.HumanoidRootPart
	local points = {}

	for _, name in via or {} do
		table.insert(points, stage.Markers[name])
	end

	table.insert(points, marker)
	root.Anchored = false
	root:SetNetworkOwner(nil)
	humanoid.WalkSpeed = Config.WalkSpeed

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://913402848"

	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Movement
	track.Looped = true
	track:Play(0.2, 1, Config.WalkSpeed / 8)

	local ok, reason = xpcall(function()
		for index, point in points do
			assert(valid() and humanoid.Health > 0, "Walk cancelled")

			local destination = point.Position
			local deadline = os.clock() + 8
			humanoid:MoveTo(destination)

			-- Change direction before stopping at a corridor corner.
			local tolerance = index == #points and 1.1 or 1.2

			while ((root.Position - destination) * Vector3.new(1, 0, 1)).Magnitude > tolerance do
				assert(valid() and humanoid.Health > 0, "Walk cancelled")
				assert(os.clock() < deadline, "Could not reach " .. point.Name)

				RunService.Heartbeat:Wait()
			end
		end
	end, debug.traceback)

	track:Stop(0.2)
	track:Destroy()
	animation:Destroy()
	humanoid:Move(Vector3.zero)
	humanoid.WalkSpeed = 0
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	if ok and valid() then
		-- Turn in place at the destination; never snap the NPC's position.
		local facing = CFrame.new(root.Position) * marker.CFrame.Rotation
		local turn = TweenService:Create(root, TweenInfo.new(0.2), { CFrame = facing })
		turn:Play()
		turn.Completed:Wait()
	end

	assert(ok, reason)
end

local function route(player, restore)
	if typeof(player) ~= "Instance" then
		return
	end

	routeVersion += 1

	local version = routeVersion
	local state = player:GetAttribute("QuestState")
	local markerName = markerForState[state]

	if not markerName or not active(player, state) then
		release(player)
		stage.Suspect.Humanoid:Move(Vector3.zero)
		stage.Suspect.HumanoidRootPart.Anchored = true
		refresh(player)

		return
	end

	release(player)
	setCell(state == 13 or state == 14, false)

	local marker = stage.Markers[markerName]
	player:SetAttribute("PoliceMoving", true)
	refresh(player)

	local ok, reason = xpcall(function()
		if restore or state == 8 then
			stage.Suspect:PivotTo(marker.CFrame)
		else
			walk(stage.Suspect, marker, function()
				return version == routeVersion
					and player.Parent == Players
					and active(player, state)
			end, Config.Routes[state])
		end
	end, debug.traceback)

	if version == routeVersion then
		stage.Suspect.HumanoidRootPart.Anchored = true
		player:SetAttribute("PoliceMoving", false)

		if ok then
			player:SetAttribute("PoliceRouteError", nil)
		else
			player:SetAttribute("PoliceRouteError", tostring(reason))
		end

		refresh(player)

		if not ok then
			warn("[PoliceQuest]", reason)
		end
	end
end

function PoliceService.Action(player, action, value)
	local state = player:GetAttribute("QuestState")

	if action == "Cancel" then
		release(player)

		return true
	end

	if not active(player, state) or not markerForState[state] then
		return false, "This is not the current quest step"
	end

	if action == "BeginDeparture" and state == 15 then
		if session or not near(player, stage.Markers.CellArrival.Position, 20) then
			return false, "The police shift is not ready to finish"
		end

		lock(player, state)

		return true
	elseif action == "FinishDeparture" and state == 15 then
		if not session or session.player ~= player or session.state ~= 15 then
			return false
		end

		release(player)

		return QuestService:CompleteObjective(player, QuestConfig.Name, 15)
	end

	if action == "BeginIntro" then
		if state ~= 8 or session or not near(player, stage.Markers.Arrival.Position, 50) then
			return false, "The police introduction is not ready"
		end

		lock(player, state)
		player.Character:PivotTo(stage.Markers.Arrival.CFrame)
		stage.Suspect:PivotTo(stage.Markers.SuspectEntry.CFrame)
		stage.Suspect.HumanoidRootPart.Anchored = true

		return true
	elseif action == "Enter" then
		if not session or session.player ~= player or session.state ~= 8 or session.entered then
			return false
		end

		local current = session
		current.entered = true
		current.root.Anchored = false

		local npcFinished = false
		local npcOk, npcReason
		task.spawn(function()
			npcOk, npcReason = pcall(walk, stage.Suspect, stage.Markers.EntryEnd, function()
				return session == current
			end)

			npcFinished = true
		end)

		local ok, reason = pcall(walk, player.Character, stage.Markers.PlayerEntryEnd, function()
			return session == current
		end)

		while not npcFinished and session == current do
			task.wait(0.05)
		end

		if session == current then
			stage.Suspect.HumanoidRootPart.Anchored = true
			current.root.Anchored = true
			current.finished = ok and npcOk
		end

		return ok and npcOk, reason or npcReason
	elseif action == "FinishIntro" then
		if
			not session
			or session.player ~= player
			or session.state ~= 8
			or not session.finished
		then
			return false
		end

		release(player)

		return QuestService:CompleteObjective(player, QuestConfig.Name, 8)
	end

	if player:GetAttribute("PoliceMoving") or player:GetAttribute("PoliceRouteError") then
		return false, "Wait for the suspect to reach the checkpoint"
	end

	local stationName = stationForState[state]

	if
		not stationName
		or not near(player, stage.Stations[stationName].Position, Config.InteractionDistance)
	then
		return false, "Move closer to the booking station"
	end

	if action == "Begin" and state >= 9 and state <= 11 then
		if session then
			return false
		end

		lock(player, state)

		return true
	elseif action == "Confiscate" then
		if not session or session.player ~= player or session.state ~= 9 or state ~= 9 then
			return false
		end

		local removed, reason = QuestService:ConfiscatePoliceItem(player, value)
		refresh(player)

		return removed, reason
	elseif action == "Scan" or action == "Photo" then
		if
			not session
			or session.player ~= player
			or session.state ~= state
			or session.processing
			or state ~= (action == "Scan" and 10 or 11)
		then
			return false
		end

		local current = session
		current.processing = true
		task.wait(action == "Scan" and Config.ScanDuration or Config.PhotoDuration)

		if session ~= current or current.humanoid.Health <= 0 then
			return false
		end

		release(player)

		return QuestService:CompleteObjective(player, QuestConfig.Name, state)
	elseif action == "Cell" and state >= 12 and state <= 14 then
		if doorBusy then
			return false
		end

		if state == 14 and player.Character.HumanoidRootPart.Position.Z > -261 then
			return false, "Step outside the cell before closing the door"
		end

		doorBusy = true
		refresh(player)

		local ok, reason = pcall(function()
			if state == 13 then
				player:SetAttribute("PoliceMoving", true)

				local version = routeVersion
				local character = player.Character
				walk(stage.Suspect, stage.Markers.CellInside, function()
					return active(player, 13)
						and version == routeVersion
						and player.Character == character
						and character.Humanoid.Health > 0
				end)

				stage.Suspect.HumanoidRootPart.Anchored = true
			else
				setCell(state == 12, true)
			end
		end)

		stage.Suspect.HumanoidRootPart.Anchored = true
		doorBusy = false
		player:SetAttribute("PoliceMoving", false)

		if ok then
			QuestService:CompleteObjective(player, QuestConfig.Name, state)
		end

		refresh(player)

		return ok, reason
	end

	return false, "That action is not available"
end

function PoliceService.Start()
	stage = workspace:WaitForChild("PoliceQuest", 15)
	assert(stage, "Install the police quest checkpoints first")
	PoliceEvidence.Install(stage)

	if not PhysicsService:IsCollisionGroupRegistered(ACTOR_COLLISION_GROUP) then
		PhysicsService:RegisterCollisionGroup(ACTOR_COLLISION_GROUP)
	end

	PhysicsService:CollisionGroupSetCollidable(ACTOR_COLLISION_GROUP, ACTOR_COLLISION_GROUP, false)

	for _, part in stage.Suspect:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = ACTOR_COLLISION_GROUP
		end
	end

	for _, actor in { stage.Suspect, stage.Leo } do
		for _, stateType in
			{
				Enum.HumanoidStateType.FallingDown,
				Enum.HumanoidStateType.Ragdoll,
				Enum.HumanoidStateType.Seated,
			}
		do
			actor.Humanoid:SetStateEnabled(stateType, false)
		end

		for _, part in actor:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CanTouch = false

				if part.Parent ~= actor then
					part.Massless = true
				end

				table.insert(actorParts, part)
			end
		end
	end

	doorClosed = stage.CellDoor.Value:GetPivot()

	for _, object in stage.CellDoor.Value:GetDescendants() do
		if object:IsA("ProximityPrompt") then
			originalDoorPrompts[object] = object.Enabled
		end
	end

	local doors = workspace.PoliceStation.Interactables.Doors

	-- Open only the doors on the booking route at runtime. Edit-mode map stays intact.
	for _, name in { "Door4", "Door7", "Door37", "Door38" } do
		local door = doors[name]
		door:PivotTo(door:GetPivot() * CFrame.Angles(0, math.rad(90), 0))
	end

	for _, side in doors.AutoDoor1.Doors:GetChildren() do
		side:PivotTo(side:GetPivot() + Vector3.new(0, 0, side.Name == "Left" and -4 or 4))
	end

	ReplicatedStorage.PoliceAction.OnServerInvoke = PoliceService.Action

	local function changed(player)
		if typeof(player) ~= "Instance" then
			return
		end

		task.spawn(route, player, false)
	end

	QuestService.StateChanged:Connect(changed)

	local function connect(player)
		refresh(player)
		player:GetAttributeChangedSignal("QuestDataReady"):Connect(function()
			if player:GetAttribute("QuestDataReady") then
				task.spawn(route, player, true)
			else
				release(player)
				refresh(player)
			end
		end)

		local readyConnection

		player.CharacterRemoving:Connect(function()
			routeVersion += 1
			release(player)
			updateActorCollisions(nil)

			if readyConnection then
				readyConnection:Disconnect()
				readyConnection = nil
			end
		end)

		local function characterAdded(character)
			local humanoid = character:WaitForChild("Humanoid", 10)

			if humanoid then
				humanoid.Died:Connect(function()
					routeVersion += 1
					release(player)
					updateActorCollisions(nil)
				end)
			end

			if player.Character ~= character or not character.Parent then
				return
			end

			local function restoreWhenReady()
				if character:GetAttribute("ClassroomReady") and player.Character == character then
					if readyConnection then
						readyConnection:Disconnect()
						readyConnection = nil
					end

					task.spawn(route, player, true)
				end
			end

			readyConnection =
				character:GetAttributeChangedSignal("ClassroomReady"):Connect(restoreWhenReady)
			restoreWhenReady()
		end

		player.CharacterAdded:Connect(characterAdded)

		if player.Character then
			task.spawn(characterAdded, player.Character)
		end

		if player:GetAttribute("QuestDataReady") then
			changed(player)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		routeVersion += 1
		release(player)
		updateActorCollisions(nil)
	end)

	Players.PlayerAdded:Connect(connect)

	for _, player in Players:GetPlayers() do
		connect(player)
	end
end

return PoliceService
