local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local QuestService = require(script.Parent.QuestService)

local QuestReturnService = {}
local pending = {}
local lastAttempt = {}

function QuestReturnService.Return(player)
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

	if RunService:IsStudio() then
		player:SetAttribute("QuestReturnStatus", "StudioComplete")

		return
	end

	if os.clock() - (lastAttempt[player] or -math.huge) < 3 then
		return
	end

	lastAttempt[player] = os.clock()
	pending[player] = true
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
end)

return QuestReturnService
