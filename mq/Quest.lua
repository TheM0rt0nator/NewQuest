local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(script.Parent.Parent.SecretQuestConfig)
local SafeTeleport = require(Knit.Modules.SafeTeleport)
local SecretQuestCarry = require(script.Parent.Parent.SecretQuestCarry)
local SecretQuestAccess = require(script.Parent.Parent.SecretQuestAccess)

local Bindings = require(script.Parent.Parent.SecretQuestBindings)

local SecretQuest = {}
SecretQuest.__index = SecretQuest

function SecretQuest.new(player, data)
	local savedState = data and data.State
	local collected = {}
	for _, item in Config.Items do
		if
			savedState
			and savedState.Collected
			and (savedState.Collected[item.Id] == true or savedState.Collected[item.Key] == true)
		then
			collected[item.Id] = true
		end
	end

	local progress = 0
	for _ in collected do
		progress += 1
	end

	local id = progress == #Config.Items and 2 or 1
	local state = table.clone(Config.Objectives[id])
	state.Id = id
	state.Progress = progress
	state.Collected = collected
	if data then
		data.State = state
	end

	local self = setmetatable({ Player = player, State = state, Config = Config }, SecretQuest)
	self.Carry = SecretQuestCarry.new(player, state)
	return self
end

function SecretQuest:StateSet(state)
	self.State = state
	self.Carry:SetState(state)
end

function SecretQuest:SetState(id)
	local state = table.clone(assert(Config.Objectives[id], "Unknown secret quest objective"))
	state.Id = id
	state.Collected = table.clone(self.State.Collected)
	state.Progress = self.State.Progress
	self:StateSet(state)
end

function SecretQuest:Notify(message)
	if self.Player.Parent == Players then
		Knit.GetService("PlayerService").Client.SendNotification:Fire(self.Player, "Small", message)
	end
end

function SecretQuest:Collect(itemId)
	if not SecretQuestAccess.IsAvailable(self.Player) then
		return false
	end

	if self.Destroyed or self.State.Id ~= 1 or self.State.Collected[itemId] then
		return false
	end

	local itemConfig
	for _, item in Config.Items do
		if item.Id == itemId then
			itemConfig = item
			break
		end
	end

	if not itemConfig then
		return false
	end

	-- The caller holds the per-player interaction lock while data loads.
	local success, data = Knit.GetService("PlayerService"):GetPlayerData(self.Player):await()
	if not success or self.Destroyed or self.Player.Parent ~= Players then
		return false
	end

	local savedQuest = data.Quests and data.Quests.SecretQuest
	if not savedQuest or not savedQuest.Active then
		return false
	end

	self.State.Collected[itemId] = true
	self.State.Progress += 1
	if self.State.Progress == #Config.Items then
		self:SetState(2)
	end

	savedQuest.State = self.State
	self.Carry:SetState(self.State)
	Knit.GetService("QuestService").Client.QuestUpdated:Fire(self.Player, "SecretQuest", self.State)
	self:Notify("Collected " .. itemConfig.DisplayName .. "!")
	return true
end

function SecretQuest:ReleaseTeleport(attempt, message)
	if self.TeleportAttempt ~= attempt then
		return
	end

	self.TeleportAttempt = nil
	if attempt.Connection then
		attempt.Connection:Disconnect()
	end

	if attempt.Timeout then
		task.cancel(attempt.Timeout)
	end

	attempt.Options:Destroy()
	if message and not self.Destroyed then
		self:Notify(message)
	end
end

function SecretQuest:Travel(prompt)
	if
		self.Destroyed
		or self.State.Id ~= 2
		or self.TeleportAttempt
		or os.clock() < (self.NextTeleportAttempt or 0)
		or not SecretQuestAccess.IsAvailable(self.Player)
	then
		return
	end

	for _, item in Config.Items do
		if self.State.Collected[item.Id] ~= true then
			return
		end
	end

	local tree = Bindings.Tree
	local treePrompt = Bindings.TreePrompt
	local player = self.Player
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if
		not treePrompt
		or prompt ~= treePrompt
		or not prompt.Enabled
		or player.Parent ~= Players
		or not root
		or not humanoid
		or humanoid.Health <= 0
		or (root.Position - tree.Position).Magnitude > prompt.MaxActivationDistance + 2
	then
		return
	end

	self.NextTeleportAttempt = os.clock() + 3
	local placeId = Config.DestinationPlaceId
	if RunService:IsStudio() then
		print(
			("[SecretQuest] Studio preview: %s would teleport to place %d."):format(
				player.Name,
				placeId
			)
		)
		self:Notify("Items delivered! Test travel to classic Berry Avenue in the Roblox app.")
		return
	end

	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	local attempt = { Id = HttpService:GenerateGUID(false), Options = options }
	options:SetTeleportData({
		QuestId = "SecretQuest",
		SourcePlaceId = game.PlaceId,
		SecretQuestAttemptId = attempt.Id,
		ItemsDelivered = true,
	})
	self.TeleportAttempt = attempt
	attempt.Connection = TeleportService.TeleportInitFailed:Connect(
		function(failedPlayer, _result, message, failedPlaceId, failedOptions)
			if failedPlayer ~= player or failedPlaceId ~= placeId or not failedOptions then
				return
			end

			local data = failedOptions:GetTeleportData()
			if type(data) ~= "table" or data.SecretQuestAttemptId ~= attempt.Id then
				return
			end

			warn("[SecretQuest] Teleport failed:", message)
			self:ReleaseTeleport(
				attempt,
				"Could not travel. Your items are safe; try the tree again."
			)
		end
	)
	self:Notify("Items delivered! Travelling to classic Berry Avenue...")
	local success = SafeTeleport(placeId, { player }, options)
	if not success then
		self:ReleaseTeleport(attempt, "Could not travel. Your items are safe; try the tree again.")
	elseif self.TeleportAttempt == attempt then
		attempt.Timeout = task.delay(45, function()
			attempt.Timeout = nil
			self:ReleaseTeleport(attempt, "Travel timed out. Please try the tree again.")
		end)
	end
end

function SecretQuest:InteractWithTree(prompt)
	local service = Knit.GetService("QuestService")
	service.Client.QuestReceived:Fire(self.Player, "SecretQuest", self.State)
	if self.State.Id == 2 then
		self:Travel(prompt)
	end
end

function SecretQuest:Destroy()
	self.Destroyed = true
	self.Carry:Destroy()
	if self.TeleportAttempt then
		self:ReleaseTeleport(self.TeleportAttempt)
	end
end

return SecretQuest
