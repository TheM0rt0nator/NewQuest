local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Bindings = require(script.Parent.SecretQuestBindings)
local SecretQuestAccess = require(script.Parent.SecretQuestAccess)
local SecretQuestRelease = require(script.Parent.SecretQuestRelease)

local SecretQuestEntrance = {}
local connections = {}
local playerConnections = {}
local unregister = {}
local started = false

function SecretQuestEntrance.Start(questService)
	if started or not SecretQuestAccess.IsEntrance() then
		return
	end

	started = true
	local interactions = Knit.GetService("NearbyInteractionService")
	for _, binding in Bindings.GetEntries() do
		table.insert(
			unregister,
			interactions:Register({
				Distance = 8,
				GetPosition = binding.GetPosition,
				IsAvailable = function(player)
					if not SecretQuestAccess.IsAvailable(player) then
						return false
					end

					if not binding.ItemId then
						return true
					end

					local quests = questService.PlayerQuests[player]
					local quest = quests and quests.SecretQuest
					return quest ~= nil
						and not quest.Destroyed
						and quest.State.Id == 1
						and not quest.State.Collected[binding.ItemId]
				end,
				Activate = function(player, stillValid)
					local quests = questService.PlayerQuests[player]
					local quest = quests and quests.SecretQuest
					if binding.ItemId then
						if quest then
							quest:Collect(binding.ItemId, stillValid)
						end

						return
					end

					if not quest then
						local request = questService:GiveQuest(player, "SecretQuest", stillValid)
						if request then
							request:await()
						end

						quests = questService.PlayerQuests[player]
						quest = quests and quests.SecretQuest
					end

					if quest and stillValid() then
						quest:InteractWithTree(stillValid)
					end
				end,
			})
		)
	end

	local function watchPlayer(player)
		if playerConnections[player] then
			return
		end

		playerConnections[player] = player
			:GetAttributeChangedSignal("AnniversaryQuestComplete")
			:Connect(function()
				if SecretQuestAccess.IsAvailable(player) then
					questService:ResumeSecretQuest(player)
				end
			end)
	end

	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	table.insert(connections, Players.PlayerAdded:Connect(watchPlayer))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			if playerConnections[player] then
				playerConnections[player]:Disconnect()
				playerConnections[player] = nil
			end
		end)
	)

	SecretQuestRelease.Start(function()
		for _, player in Players:GetPlayers() do
			if SecretQuestAccess.IsAvailable(player) then
				questService:ResumeSecretQuest(player)
			end
		end
	end)
end

function SecretQuestEntrance.Destroy()
	started = false
	SecretQuestRelease.Destroy()
	for _, remove in unregister do
		remove()
	end

	for _, connection in playerConnections do
		connection:Disconnect()
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	table.clear(unregister)
	table.clear(playerConnections)
	table.clear(connections)
end

return SecretQuestEntrance
