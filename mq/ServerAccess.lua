local Config = require(script.Parent.SecretQuestConfig)

local SecretQuestAccess = {}

function SecretQuestAccess.IsEntrance()
	return game.PlaceId == Config.EntrancePlaceId or game.PlaceId == Config.TestEntrancePlaceId
end

function SecretQuestAccess.IsTesting()
	-- Only MQ bypasses release/prerequisites and resets progress on join.
	-- Main keeps production behavior even when opened in Studio.
	return game.PlaceId == Config.TestEntrancePlaceId
end

function SecretQuestAccess.IsReleased()
	return SecretQuestAccess.IsEntrance()
		and (SecretQuestAccess.IsTesting() or os.time() >= Config.OpensAt)
end

function SecretQuestAccess.IsAvailable(player)
	return SecretQuestAccess.IsReleased()
		and (
			SecretQuestAccess.IsTesting()
			or player:GetAttribute("AnniversaryQuestComplete") == true
		)
end

return SecretQuestAccess
