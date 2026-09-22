local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local Config = require(script.Parent.Config)
local CelebrationConfig = require(ReplicatedStorage.SecretQuest.AnniversaryQuestConfig)
local ProfileStore = require(ServerScriptService.SecretQuestPackages.ProfileStore)
local Progress = require(script.Parent.Progress)
local Smoothie = require(script.Parent.Smoothie)
local VipShirt = require(script.Parent.VipShirt)
local World = require(script.Parent.World)

local Service = {}
local resetProgressOnJoin = game.PlaceId == Config.TestPlaceId
local useMockStore = RunService:IsStudio() or resetProgressOnJoin
local store = ProfileStore.New(Config.StoreName, Progress.New())

if useMockStore then
	store = store.Mock
end

local connections = {}
local sessionConnections = {}
local characterConnections = {}
local interactions = {}
local smoothie
local busy = false
local operationGeneration = 0
local profile
local owner
local root
local started = false
local generation = 0
local pendingReturn = false
local lastAction = 0
local lastReturn = 0
local vipCloseTask
local returnGeneration = 0
local returnTask
local celebrated = false
local celebrationFinished = ReplicatedStorage.SecretQuest:WaitForChild("CelebrationFinished")

local function connect(signal, callback, list)
	local connection = signal:Connect(callback)
	table.insert(list or connections, connection)

	return connection
end

local function disconnect(list)
	for _, connection in list do
		connection:Disconnect()
	end

	table.clear(list)
end

local function render(message)
	if not owner or not profile then
		return
	end

	local data = profile.Data
	World.Render(root, data)
	smoothie:Render(data, owner.Character)
end

local function closeVipDoor()
	if vipCloseTask then
		task.cancel(vipCloseTask)
		vipCloseTask = nil
	end

	if root then
		World.SetVipDoorOpen(root, false)
	end
end

local function cancelActivity()
	operationGeneration += 1
	busy = false
	closeVipDoor()

	if smoothie then
		smoothie:Cancel()
	end
end

local function nearby(player, object)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local characterRoot = character and character:FindFirstChild("HumanoidRootPart")

	return player == owner
		and profile ~= nil
		and profile:IsActive()
		and humanoid ~= nil
		and humanoid.Health > 0
		and characterRoot ~= nil
		and (characterRoot.Position - object.Position).Magnitude <= 12
end

local function touchVipDoor(hit)
	local character = owner and owner.Character

	if not started or not character or not hit:IsDescendantOf(character) then
		return
	end

	local gate = root.Stages[1].Gate

	if root.VipOpen or not nearby(owner, gate) then
		return
	end

	if not VipShirt.IsWearing(character) then
		return
	end

	World.SetVipDoorOpen(root, true)
	vipCloseTask = task.delay(2, function()
		vipCloseTask = nil
		closeVipDoor()
	end)

	if profile.Data.Stage == 1 then
		local nextData = table.clone(profile.Data)
		Progress.Advance(nextData, #Config.Stages)
		profile.Data = nextData
		profile:Save()
		render("The VIP door recognizes your shirt. Sunset Clothing is now open.")
	end
end

local function cancelReturnTask()
	if returnTask then
		task.cancel(returnTask)
		returnTask = nil
	end
end

local function returnFailed(player, message)
	if owner == player then
		cancelReturnTask()
		returnGeneration += 1
		pendingReturn = false
		player:SetAttribute("SecretCelebrationStartedAt", nil)
		player:SetAttribute("SecretReturnStatus", "Failed")
		player:SetAttribute("SecretReturnMessage", message .. " Use the portal to retry.")
	end
end

local function currentReturn(player, currentProfile, attempt)
	return started
		and owner == player
		and profile == currentProfile
		and currentProfile ~= nil
		and currentProfile:IsActive()
		and returnGeneration == attempt
		and pendingReturn
end

local function finishReturn(player, currentProfile, attempt)
	if not currentReturn(player, currentProfile, attempt) then
		return
	end

	cancelReturnTask()
	celebrated = true
	player:SetAttribute("SecretCelebrationStartedAt", nil)

	if RunService:IsStudio() then
		player:SetAttribute("SecretReturnStatus", "StudioComplete")
		player:SetAttribute(
			"SecretReturnMessage",
			"Quest complete! Studio preview: badge and teleport simulated."
		)
		pendingReturn = false
		return
	end

	player:SetAttribute("SecretReturnStatus", "Teleporting")
	player:SetAttribute("SecretReturnMessage", "Secret badge claimed! Returning to Berry Avenue...")
	local teleported = pcall(function()
		TeleportService:TeleportAsync(Config.ReturnPlaceId, { player })
	end)

	if not teleported and currentReturn(player, currentProfile, attempt) then
		returnFailed(player, "Teleport failed.")
	end
end

local function returnHome(player)
	if not nearby(player, root.Portal) or not profile.Data.Completed or pendingReturn then
		return
	end

	if os.clock() - lastReturn < 3 then
		return
	end

	lastReturn = os.clock()
	pendingReturn = true
	returnGeneration += 1
	local attempt = returnGeneration
	local currentProfile = profile
	player:SetAttribute("SecretReturnStatus", "Saving")
	player:SetAttribute("SecretReturnMessage", "Saving your completed quest...")
	currentProfile:Save()
	local deadline = os.clock() + 25

	-- Poll only during this bounded save confirmation, never while idle.
	while not currentProfile.LastSavedData.Completed do
		if not currentReturn(player, currentProfile, attempt) then
			return
		end

		if os.clock() >= deadline then
			returnFailed(player, "Saving took too long.")
			return
		end

		task.wait(0.2)
	end

	if not currentReturn(player, currentProfile, attempt) then
		return
	end

	if RunService:IsStudio() then
		player:SetAttribute("SecretBadgeStatus", "StudioSimulated")
	else
		if Config.CompletionBadgeId <= 0 then
			returnFailed(player, "The secret badge has not been configured yet.")
			return
		end

		player:SetAttribute("SecretReturnStatus", "AwardingBadge")
		player:SetAttribute("SecretReturnMessage", "Claiming your secret badge...")
		local awarded, result = pcall(function()
			if BadgeService:UserHasBadgeAsync(player.UserId, Config.CompletionBadgeId) then
				return true
			end

			return BadgeService:AwardBadgeAsync(player.UserId, Config.CompletionBadgeId)
		end)

		if not currentReturn(player, currentProfile, attempt) then
			return
		end

		if not awarded or not result then
			returnFailed(player, "The badge could not be awarded.")
			return
		end

		player:SetAttribute("SecretBadgeStatus", "Confirmed")
	end

	if celebrated then
		finishReturn(player, currentProfile, attempt)
		return
	end

	player:SetAttribute("SecretReturnMessage", "")
	player:SetAttribute("SecretReturnStatus", "Celebrating")
	player:SetAttribute("SecretCelebrationStartedAt", workspace:GetServerTimeNow())
	-- A missing client acknowledgement must not strand an awarded player.
	returnTask = task.delay(CelebrationConfig.CompletionCelebrationDuration + 5, function()
		returnTask = nil
		finishReturn(player, currentProfile, attempt)
	end)
end

function Service.Interact(player, object)
	if not started or not root or not interactions[object] or busy then
		return false
	end

	if object == root.Portal then
		returnHome(player)
		return true
	end

	if not nearby(player, object) or os.clock() - lastAction < 0.2 then
		return false
	end

	local data = profile.Data
	local binding = interactions[object]
	local action = binding.Action

	if binding.Stage ~= data.Stage or not action or data.Completed then
		return false
	end

	lastAction = os.clock()
	local stage = Config.Stages[data.Stage]
	local nextData = table.clone(data)
	nextData.Values = table.clone(data.Values)

	if data.Values.Ingredients then
		nextData.Values.Ingredients = table.clone(data.Values.Ingredients)
	end

	if data.Values.Code then
		nextData.Values.Code = table.clone(data.Values.Code)
	end

	local changed, solved, message = Progress.Apply(nextData, stage.Kind, action)

	if not changed then
		return false
	end

	if stage.Kind == "Smoothie" and (action == "Deposit" or action == "Blend") then
		local currentProfile = profile
		local character = player.Character
		local currentOperation = operationGeneration
		busy = true

		for _, binding in interactions do
			binding.Prompt.Enabled = false
		end

		local ok, finished = pcall(function()
			if action == "Deposit" then
				return smoothie:Deposit(data.Values.Held)
			end

			return smoothie:Blend(data.Values.Ingredients, solved)
		end)

		if currentOperation ~= operationGeneration or profile ~= currentProfile then
			return false
		end

		busy = false

		if
			not ok
			or not finished
			or character ~= player.Character
			or character.Humanoid.Health <= 0
		then
			cancelActivity()
			render("Try that again.")
			return false
		end
	end

	if solved then
		Progress.Advance(nextData, #Config.Stages)
		local nextStage = Config.Stages[nextData.Stage]
		message = nextStage and (stage.Name .. " complete! " .. nextStage.Name .. " is now open.")
			or "All four puzzles complete! The return portal is open at spawn."
	end

	profile.Data = nextData
	profile:Save()
	render(message)

	return true
end

local function characterAdded(character)
	local characterRoot = character:WaitForChild("HumanoidRootPart", 10)

	if not characterRoot or not owner or owner.Character ~= character or not profile then
		return
	end

	character:PivotTo(Config.Spawn)
	disconnect(characterConnections)
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		connect(humanoid.Died, function()
			cancelActivity()
			render()
		end, characterConnections)
	end

	smoothie:Render(profile.Data, character)
end

local function releasePlayer(player)
	if owner ~= player then
		return
	end

	disconnect(sessionConnections)
	disconnect(characterConnections)
	cancelActivity()
	cancelReturnTask()
	returnGeneration += 1
	celebrated = false
	player:SetAttribute("SecretCelebrationStartedAt", nil)
	local previous = profile
	profile = nil
	owner = nil
	pendingReturn = false
	lastAction = 0
	lastReturn = 0

	if previous then
		previous:EndSession()
	end

	World.Render(root, Progress.New())
	smoothie:Render(Progress.New())
end

local function addPlayer(player)
	if owner then
		if owner ~= player then
			player:Kick("This quest is a single-player adventure. Please join a fresh server.")
		end

		return
	end

	owner = player
	local currentGeneration = generation
	local loaded = store:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return not started
				or generation ~= currentGeneration
				or owner ~= player
				or player.Parent ~= Players
		end,
	})

	if not loaded then
		if owner == player and generation == currentGeneration then
			owner = nil
			player:Kick("Your secret quest could not load. Please rejoin.")
		end

		return
	end

	if
		not started
		or generation ~= currentGeneration
		or owner ~= player
		or player.Parent ~= Players
	then
		loaded:EndSession()
		return
	end

	loaded:AddUserId(player.UserId)

	if resetProgressOnJoin then
		loaded.Data = Progress.New()
	end

	loaded:Reconcile()
	local data = loaded.Data
	Progress.Migrate(data)

	if
		data.Version ~= 3
		or type(data.Stage) ~= "number"
		or data.Stage % 1 ~= 0
		or data.Stage < 1
		or data.Stage > #Config.Stages + 1
		or type(data.Values) ~= "table"
	then
		loaded:EndSession()
		owner = nil
		player:Kick("This quest save needs a newer version. Please rejoin later.")
		return
	end

	data.Completed = data.Stage > #Config.Stages
	profile = loaded
	player:SetAttribute("SecretSaveMode", useMockStore and "ProfileStore.Mock" or "Live")
	player:SetAttribute("SecretResetOnJoin", resetProgressOnJoin)
	connect(loaded.OnSessionEnd, function()
		if profile == loaded then
			releasePlayer(player)
			player:Kick("Your quest session ended. Please rejoin to continue.")
		end
	end, sessionConnections)
	connect(player.CharacterAdded, characterAdded, sessionConnections)
	connect(player.CharacterRemoving, function()
		cancelActivity()
		disconnect(characterConnections)
	end, sessionConnections)
	player:SetAttribute("SecretReturnMessage", "")
	player:SetAttribute("SecretReturnStatus", nil)
	player:SetAttribute("SecretBadgeStatus", nil)
	player:SetAttribute("SecretCelebrationStartedAt", nil)
	render()
	player:SetAttribute("SecretReady", true)

	if player.Character then
		task.spawn(characterAdded, player.Character)
	end
end

function Service.Start()
	if started then
		return
	end

	started = true
	generation += 1
	root = World.Build()
	World.SetVipDoorOpen(root, false)
	smoothie = Smoothie.new(root.Stages[4])
	World.Render(root, Progress.New())
	smoothie:Render(Progress.New())
	interactions = World.Interactions(root)

	for object, binding in interactions do
		connect(binding.Prompt.Triggered, function(player)
			Service.Interact(player, object)
		end)
		local click = binding.Click

		if click then
			connect(click.MouseClick, function(player)
				Service.Interact(player, object)
			end)
		end
	end

	connect(root.Stages[1].Gate.Touched, touchVipDoor)
	connect(celebrationFinished.OnServerEvent, function(player, startedAt)
		local expected = player:GetAttribute("SecretCelebrationStartedAt")

		if
			player == owner
			and pendingReturn
			and type(expected) == "number"
			and startedAt == expected
			and player:GetAttribute("SecretReturnStatus") == "Celebrating"
			and workspace:GetServerTimeNow() - expected
				>= CelebrationConfig.CompletionCelebrationDuration
		then
			finishReturn(player, profile, returnGeneration)
		end
	end)
	connect(root.Portal.Touched, function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)

		if player then
			returnHome(player)
		end
	end)
	connect(TeleportService.TeleportInitFailed, function(player, _, _, placeId)
		if placeId == Config.ReturnPlaceId and owner == player and pendingReturn then
			returnFailed(player, "Teleport failed.")
		end
	end)
	connect(Players.PlayerAdded, addPlayer)
	connect(Players.PlayerRemoving, releasePlayer)

	for _, player in Players:GetPlayers() do
		task.spawn(addPlayer, player)
	end
end

function Service.GetState(player)
	if player == owner and profile then
		return profile.Data
	end

	return nil
end

function Service.Stop()
	if not started then
		return
	end

	started = false
	generation += 1
	disconnect(connections)
	cancelActivity()

	if owner then
		releasePlayer(owner)
	end

	World.Hide(root)
end

return Service
