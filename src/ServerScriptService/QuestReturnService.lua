local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local BadgeService = require(script.Parent.BadgeService)
local QuestService = require(script.Parent.QuestService)

local QuestReturnService = {}
local pending = {}
local lastAttempt = {}
local celebrationStarted = {}
local celebrated = {}

local function finishReturn(player)
	if RunService:IsStudio() then
		pending[player] = nil
		player:SetAttribute("QuestReturnStatus", "StudioComplete")

		return
	end

	player:SetAttribute("QuestReturnStatus", "Teleporting")

	local ok, reason = pcall(function()
		TeleportService:TeleportAsync(Config.ReturnPlaceId, { player })
	end)

	if not ok then
		pending[player] = nil
		player:SetAttribute("QuestReturnStatus", "Failed")
		warn("[QuestReturn]", reason)
	end
end

function QuestReturnService.Return(player, action)
	if action == "CelebrationFinished" then
		local started = celebrationStarted[player]

		if
			pending[player]
			and started
			and os.clock() - started >= Config.CompletionCelebrationDuration
		then
			celebrationStarted[player] = nil
			celebrated[player] = true
			finishReturn(player)
		end

		return
	end

	local quest = QuestService:GetQuestData(player, Config.Name)

	if
		not quest
		or not quest.Completed
		or not quest.Destination
		or quest.Destination.State.Id ~= Config.States.QuestComplete
		or pending[player]
	then
		return
	end

	if os.clock() - (lastAttempt[player] or -math.huge) < 3 then
		return
	end

	lastAttempt[player] = os.clock()
	pending[player] = true
	player:SetAttribute("QuestBadgeStatus", nil)
	player:SetAttribute("QuestReturnStatus", "Saving")

	if not QuestService:WaitForCompletionSave(player) then
		pending[player] = nil
		player:SetAttribute("QuestReturnStatus", "Failed")

		return
	end

	if player.Parent ~= Players then
		pending[player] = nil

		return
	end

	-- Keep the player here until the saved completion reward is confirmed.
	-- Returning completed players use this same path to recover a missed award.
	player:SetAttribute("QuestReturnStatus", "AwardingBadge")

	local awarded, badgeStatus = BadgeService.Award(player, Config.CompletionBadgeId)
	player:SetAttribute("QuestBadgeStatus", badgeStatus)

	if player.Parent ~= Players then
		pending[player] = nil

		return
	end

	if not awarded then
		pending[player] = nil
		player:SetAttribute("QuestReturnStatus", "Failed")

		return
	end

	if not celebrated[player] then
		celebrationStarted[player] = os.clock()
		player:SetAttribute("QuestReturnStatus", "Celebrating")

		return
	end

	finishReturn(player)
end

TeleportService.TeleportInitFailed:Connect(function(player, _, message, placeId)
	if placeId == Config.ReturnPlaceId and pending[player] then
		pending[player] = nil
		player:SetAttribute("QuestReturnStatus", "Failed")
		warn("[QuestReturn]", message)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	pending[player] = nil
	lastAttempt[player] = nil
	celebrationStarted[player] = nil
	celebrated[player] = nil
end)

return QuestReturnService
