local RunService = game:GetService("RunService")

local Config = require(script.Parent.SecretQuestConfig)

local SecretQuestAccess = {}

function SecretQuestAccess.IsEntrance()
	return game.PlaceId == Config.EntrancePlaceId or game.PlaceId == Config.TestEntrancePlaceId
end

function SecretQuestAccess.IsTesting()
	return SecretQuestAccess.IsEntrance()
		and (RunService:IsStudio() or game.PlaceId == Config.TestEntrancePlaceId)
end

function SecretQuestAccess.IsAvailable(player)
	return SecretQuestAccess.IsEntrance()
		and (
			SecretQuestAccess.IsTesting()
			or player:GetAttribute("AnniversaryQuestComplete") == true
		)
end

return SecretQuestAccess
