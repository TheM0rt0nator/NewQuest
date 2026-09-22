-- roblox services

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- knit

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerService

local Promise = require(ReplicatedStorage.Packages.Promise)
local AnniversaryRelease = require(script.AnniversaryRelease)
local SecretQuestEntrance = require(script.SecretQuestEntrance)
local SecretQuestAccess = require(script.SecretQuestAccess)

local QuestService = Knit.CreateService({
	Name = "QuestService",

	Client = {
		QuestReceived = Knit.CreateSignal(),
		QuestUpdated = Knit.CreateSignal(),
	},

	PlayerQuests = {},
})

-- constants

local QUESTS = script.Quests
local QUEST_CONFIG = require(Knit.Shared.Configs.Quests)

-- quests that are no longer available and should be removed from player data
local EXPIRED_QUESTS = {
	"AcaiBowlQuest",
	"SeoulDanceQuest",
}

local AUTO_GIVE_QUESTS = { "AnniversaryQuest" }
local RESET_ANNIVERSARY_QUEST = (game.GameId == 3613283495 and game.PlaceId == 9748069783)
	or (game.GameId == 10765832624 and game.PlaceId == 99606216494108) -- BA staging 1 and MQ

-- variables

-- internal methods

local ANNIVERSARY_BADGE_ID = 4082518353991699
local anniversaryBadgeChecks = {}
local anniversaryReadyPlayers = {}
local preparedSecretQuestSessions = {}

function QuestService:PrepareSecretQuestSession(player, data)
	local secret = data.Quests and data.Quests.SecretQuest
	if secret then
		require(script.SecretQuestConfig).MigrateState(secret.State)
	end

	if preparedSecretQuestSessions[player] then
		return
	end

	preparedSecretQuestSessions[player] = true
	if SecretQuestAccess.IsTesting() and data.Quests then
		data.Quests.SecretQuest = nil
	end
end

function QuestService:CheckAnniversaryCompletion(player)
	if player.Parent ~= Players then
		return nil
	end

	if player:GetAttribute("AnniversaryQuestComplete") == true then
		return true
	end

	local cached = anniversaryBadgeChecks[player]
	if cached and (cached.Pending or os.clock() < cached.ExpiresAt) then
		return cached.Owned
	end

	local check = { Pending = true, ExpiresAt = 0 }
	anniversaryBadgeChecks[player] = check
	local success, owned = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, ANNIVERSARY_BADGE_ID)
	end)

	if player.Parent ~= Players or anniversaryBadgeChecks[player] ~= check then
		return nil
	end

	check.Pending = false
	if success then
		check.Owned = owned
		player:SetAttribute("AnniversaryQuestComplete", owned)
	else
		warn("[AnniversaryQuest] Could not check completion badge:", owned)
	end

	check.ExpiresAt = os.clock() + (success and 30 or 3)
	return check.Owned
end

function QuestService.AwardCompletionBadge(player, badgeId)
	return Promise.new(function(resolve, reject)
		local success, err = pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)
		end)

		if not success then
			warn("Error awarding badge: " .. err)
			reject(err)
		else
			resolve()
		end
	end)
end

function QuestService:GiveQuest(player, questName)
	if questName == "SecretQuest" and not SecretQuestAccess.IsAvailable(player) then
		return nil
	end

	if questName == "AnniversaryQuest" and not AnniversaryRelease.IsOpen(player) then
		return false
	end

	local quest = QUESTS:FindFirstChild(questName)
	if not quest then
		warn("Quest with name " .. questName .. " not found")
		return
	end

	quest = require(quest)

	return PlayerService:GetPlayerData(player):andThen(function(data)
		if player.Parent ~= Players then
			return
		end

		self:PrepareSecretQuestSession(player, data)

		if questName == "AnniversaryQuest" and not AnniversaryRelease.IsOpen(player) then
			return
		end

		if not data.Quests then
			data.Quests = {}
		end

		if data.Quests[questName] then
			warn("Player already has quest with name " .. questName)
			return
		end

		if not self.PlayerQuests[player] then
			self.PlayerQuests[player] = {}
		end

		self.PlayerQuests[player][questName] = quest.new(player, data.Quests[questName])
		self.PlayerQuests[player][questName]:StateSet(
			self.PlayerQuests[player][questName].State,
			true
		)

		data.Quests[questName] = {
			State = self.PlayerQuests[player][questName].State,
			Active = true,
		}

		self.Client.QuestReceived:Fire(
			player,
			questName,
			self.PlayerQuests[player][questName].State
		)
	end)
end

function QuestService:CheckBadge(player, questName)
	local config = QUEST_CONFIG[questName]
	if not config or not config.CompletionBadgeId then
		return
	end

	local function checkHasBadge()
		return Promise.new(function(resolve, reject)
			local success, hasBadge = pcall(function()
				return BadgeService:UserHasBadgeAsync(player.UserId, config.CompletionBadgeId)
			end)

			if not success then
				warn("Error checking if player has badge: " .. hasBadge)
				reject()
			else
				resolve(hasBadge)
			end
		end)
	end

	Promise.retryWithDelay(checkHasBadge, 10, 1)
		:andThen(function(hasBadge)
			if not hasBadge then
				Promise.retryWithDelay(
					QuestService.AwardCompletionBadge,
					10,
					1,
					player,
					config.CompletionBadgeId
				)
			end
		end)
		:catch(function(err)
			warn("Error checking if player has badge: " .. err)
		end)
end

function QuestService:SetupPlayersQuests(player)
	task.spawn(function()
		self:CheckAnniversaryCompletion(player)
	end)

	PlayerService:GetPlayerData(player):andThen(function(data)
		if player.Parent ~= Players then
			return
		end

		self:PrepareSecretQuestSession(player, data)

		if not data.Quests then
			data.Quests = {}
		end

		local quests = data.Quests

		if RESET_ANNIVERSARY_QUEST then
			-- Start fresh on every staging join, including previously completed quests.
			quests.AnniversaryQuest = nil
		end

		if not self.PlayerQuests[player] then
			self.PlayerQuests[player] = {}
		end

		for questName, questData in quests do
			if questName == "SecretQuest" and not SecretQuestAccess.IsAvailable(player) then
				continue
			end

			if questName == "AnniversaryQuest" and not AnniversaryRelease.IsOpen(player) then
				continue
			end

			if self.PlayerQuests[player][questName] then
				continue
			end

			if table.find(EXPIRED_QUESTS, questName) then
				data.Quests[questName] = nil
				continue
			end

			if not questData.State or questData.Completed then
				if questData.Completed then
					self:CheckBadge(player, questName)
				end

				continue
			end

			local quest = QUESTS:FindFirstChild(questName)
			if not quest then
				warn("Quest with name " .. questName .. " not found")
				continue
			end

			quest = require(quest)
			if not quest.new then
				return
			end

			self.PlayerQuests[player][questName] = quest.new(player, questData)

			for _, questObj in self.PlayerQuests[player] do
				questObj:StateSet(questObj.State, true)
			end
		end

		for _, questName in AUTO_GIVE_QUESTS do
			if quests[questName] then
				continue
			end

			self:GiveQuest(player, questName)
		end

		anniversaryReadyPlayers[player] = true
		if AnniversaryRelease.IsOpen(player) then
			self:ActivateAnniversaryQuest(player)
		end
	end)
end

function QuestService:SetState(player, questName, newState)
	if questName == "AnniversaryQuest" and not AnniversaryRelease.IsOpen(player) then
		return
	end

	if not self.PlayerQuests[player] then
		warn("Player " .. player.Name .. " has no quests")
		return
	end

	local quest = self.PlayerQuests[player][questName]
	if not quest then
		warn("Quest with name " .. questName .. " not found")
		return
	end

	quest:SetState(newState)
	self.Client.QuestUpdated:Fire(player, questName, quest.State)

	PlayerService:GetPlayerData(player):andThen(function(data)
		if not data.Quests or not data.Quests[questName] then
			return
		end

		data.Quests[questName].State = table.clone(quest.State)
	end)
end

function QuestService:UpdateProgress(player, questName, newProgress, disableSave, listVal)
	if questName == "AnniversaryQuest" and not AnniversaryRelease.IsOpen(player) then
		return false
	end

	if not self.PlayerQuests[player] then
		warn("Player " .. player.Name .. " has no quests")
		return
	end

	if listVal then
		local _, alreadyDone = PlayerService:GetPlayerData(player)
			:andThen(function(data)
				if
					not data.Quests
					or not data.Quests[questName]
					or not data.Quests[questName].State.List
				then
					return false
				end

				if table.find(data.Quests[questName].State.List, listVal) then
					return true
				end

				return false
			end)
			:await()

		if alreadyDone then
			return
		end
	end

	local quest = self.PlayerQuests[player][questName]
	if not quest then
		warn("Quest with name " .. questName .. " not found")
		return
	end

	quest:UpdateProgress(newProgress)

	if newProgress >= quest.State.Goal then
		self:SetState(player, questName, quest.State.Id + 1)
	end

	if not disableSave then
		PlayerService:GetPlayerData(player)
			:andThen(function(data)
				if not data.Quests or not data.Quests[questName] then
					return
				end

				data.Quests[questName].State = quest.State
				if listVal then
					if not data.Quests[questName].State.List then
						data.Quests[questName].State.List = {}
					end

					table.insert(data.Quests[questName].State.List, listVal)
				end
			end)
			:await()
	end

	self.Client.QuestUpdated:Fire(player, questName, quest.State)

	return true
end

function QuestService:GetCurrentQuest(player)
	local _, questName, questData = PlayerService:GetPlayerData(player)
		:andThen(function(data)
			self:PrepareSecretQuestSession(player, data)
			if not data.Quests then
				return
			end

			for questName, questData in data.Quests do
				local available = questName ~= "AnniversaryQuest"
					or AnniversaryRelease.IsOpen(player)
				available = available
					and (questName ~= "SecretQuest" or SecretQuestAccess.IsAvailable(player))
				if questData.Active and available then
					return questName, questData
				end
			end
		end)
		:await()

	return questName, questData
end

function QuestService:GetActiveQuests(player)
	local success, quests = PlayerService:GetPlayerData(player)
		:andThen(function(data)
			self:PrepareSecretQuestSession(player, data)
			local active = {}
			for questName, questData in data.Quests or {} do
				local available = questName ~= "AnniversaryQuest"
					or AnniversaryRelease.IsOpen(player)
				available = available
					and (questName ~= "SecretQuest" or SecretQuestAccess.IsAvailable(player))
				if
					questData.Active
					and questData.State
					and not questData.Completed
					and available
				then
					active[questName] = questData
				end
			end

			return active
		end)
		:await()
	return success and quests or {}
end

function QuestService:GetQuestData(player, questName)
	if questName == "SecretQuest" and not SecretQuestAccess.IsAvailable(player) then
		return nil
	end

	local _, questData = PlayerService:GetPlayerData(player)
		:andThen(function(data)
			self:PrepareSecretQuestSession(player, data)
			if not data.Quests then
				return
			end

			return data.Quests[questName]
		end)
		:await()

	return questData
end

function QuestService:ReportLocation(player, questName, locationKey, entered)
	if questName == "AnniversaryQuest" and not AnniversaryRelease.IsOpen(player) then
		return
	end

	if not self.PlayerQuests[player] then
		return
	end

	local quest = self.PlayerQuests[player][questName]
	if not quest or not quest.OnLocationChange then
		return
	end

	quest:OnLocationChange(locationKey, entered)
end

function QuestService:CompleteCurrentQuest(player, selectedQuestName)
	local _, didComplete = PlayerService:GetPlayerData(player)
		:andThen(function(data)
			if not data.Quests then
				return
			end

			local _didComplete = false
			for questName, questData in data.Quests do
				-- The secret badge is awarded only by the future classic-map exit.
				if questName == "SecretQuest" or questName ~= selectedQuestName then
					continue
				end

				if questName == "AnniversaryQuest" and not AnniversaryRelease.IsOpen(player) then
					continue
				end

				local config = QUEST_CONFIG[questName]

				if
					not config
					or not questData.Active
					or not questData.State
					or questData.State.Id ~= #config.Objectives
				then
					continue
				end

				data.Quests[questName].Active = false
				data.Quests[questName].State = nil
				data.Quests[questName].Completed = true
				_didComplete = true
				if questName == "AnniversaryQuest" then
					player:SetAttribute("AnniversaryQuestComplete", true)
				end

				if config.CompletionBadgeId then
					Promise.retryWithDelay(
						QuestService.AwardCompletionBadge,
						10,
						1,
						player,
						config.CompletionBadgeId
					)
				end
			end

			return _didComplete
		end)
		:await()

	return didComplete
end

-- client methods

function QuestService.Client:TeleportToAnniversaryGuide(player)
	if not AnniversaryRelease.IsOpen(player) then
		return false, "The anniversary quest is not open yet."
	end

	local complete = self.Server:CheckAnniversaryCompletion(player)
	if complete == true then
		return false, "Quest already complete"
	elseif complete == nil then
		return false, "Could not check quest completion yet. Please try again."
	end

	local quests = self.Server.PlayerQuests[player]
	local quest = quests and quests.AnniversaryQuest
	if not quest then
		return false, "The anniversary quest is not available."
	end

	return quest:TeleportToGuide()
end

function QuestService.Client:GiveQuest(player, questName)
	if questName == "SecretQuest" then
		return false
	end

	return self.Server:GiveQuest(player, questName)
end

function QuestService.Client:GetActiveQuests(player)
	return self.Server:GetActiveQuests(player)
end

function QuestService.Client:GetCurrentQuest(player)
	return self.Server:GetCurrentQuest(player)
end

function QuestService.Client:GetQuestData(player, questName)
	return self.Server:GetQuestData(player, questName)
end

function QuestService.Client:CompleteCurrentQuest(player, questName)
	return self.Server:CompleteCurrentQuest(player, questName)
end

function QuestService.Client:ReportLocation(player, questName, locationKey, entered)
	return self.Server:ReportLocation(player, questName, locationKey, entered)
end

-- knit initialising functions

function QuestService:ResumeSecretQuest(player)
	PlayerService:GetPlayerData(player)
		:andThen(function(data)
			if player.Parent ~= Players or not SecretQuestAccess.IsAvailable(player) then
				return
			end

			self:PrepareSecretQuestSession(player, data)

			local quests = self.PlayerQuests[player]
			if quests and quests.SecretQuest then
				return
			end

			local saved = data.Quests and data.Quests.SecretQuest
			if not saved or not saved.Active or not saved.State or saved.Completed then
				return
			end

			quests = quests or {}
			self.PlayerQuests[player] = quests
			local quest = require(QUESTS.SecretQuest).new(player, saved)
			quests.SecretQuest = quest
			quest:StateSet(quest.State, true)
			self.Client.QuestReceived:Fire(player, "SecretQuest", quest.State)
		end)
		:catch(warn)
end

function QuestService:ActivateAnniversaryQuest(player)
	PlayerService:GetPlayerData(player)
		:andThen(function(data)
			if player.Parent ~= Players or not AnniversaryRelease.IsOpen(player) then
				return
			end

			local quests = self.PlayerQuests[player]
			if quests and quests.AnniversaryQuest then
				return
			end

			local savedQuest = data.Quests and data.Quests.AnniversaryQuest
			if not savedQuest then
				self:GiveQuest(player, "AnniversaryQuest")
				return
			end

			if savedQuest.Completed or not savedQuest.State then
				return
			end

			quests = quests or {}
			self.PlayerQuests[player] = quests
			local quest = require(QUESTS.AnniversaryQuest).new(player, savedQuest)
			quests.AnniversaryQuest = quest
			quest:StateSet(quest.State, true)
			self.Client.QuestReceived:Fire(player, "AnniversaryQuest", quest.State)
		end)
		:catch(warn)
end

function QuestService:KnitStart()
	PlayerService = Knit.GetService("PlayerService")
	SecretQuestEntrance.Start(self)
	game:BindToClose(SecretQuestEntrance.Destroy)
	AnniversaryRelease.Start(function()
		for _, player in Players:GetPlayers() do
			if anniversaryReadyPlayers[player] then
				self:ActivateAnniversaryQuest(player)
			end
		end
	end)
	game:BindToClose(AnniversaryRelease.Destroy)

	for _, player in Players:GetPlayers() do
		self:SetupPlayersQuests(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayersQuests(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		preparedSecretQuestSessions[player] = nil
		anniversaryBadgeChecks[player] = nil
		anniversaryReadyPlayers[player] = nil

		if not self.PlayerQuests[player] then
			return
		end

		for _, quest in self.PlayerQuests[player] do
			quest:Destroy()
		end

		self.PlayerQuests[player] = nil
	end)
end

function QuestService:KnitInit() end

return QuestService
