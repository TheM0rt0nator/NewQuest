local SecretQuestAccess = {}

function SecretQuestAccess.IsAvailable(player)
	return player:GetAttribute("SecretQuestAvailable") == true
end

return SecretQuestAccess
