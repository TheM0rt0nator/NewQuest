local ReplicatedStorage = game:GetService("ReplicatedStorage")

local presentation = require(ReplicatedStorage.SharedModules.Configs.Quests).SecretQuest

local Config = {
	DisplayName = presentation.DisplayName,
	Description = presentation.Description,
	Objectives = { presentation.Objectives[1], presentation.Objectives[1] },
	EntrancePlaceId = 8481844229,
	TestEntrancePlaceId = 99606216494108,
	-- 23 September 2026 at 20:00 BST (19:00 UTC).
	OpensAt = 1790190000,
	DestinationPlaceId = 93796111143212,
	TestDestinationPlaceId = 78518778092310,
	Items = {
		{ Id = "e67a20c3", Key = "SunsetShirt", DisplayName = "Sunset shirt" },
		{ Id = "b8f314d9", Key = "Smoothie", DisplayName = "smoothie" },
		{ Id = "c52d7a06", Key = "NailPolish", DisplayName = "nail polish" },
	},
}

function Config.GetDestinationPlaceId()
	if game.PlaceId == Config.TestEntrancePlaceId then
		return Config.TestDestinationPlaceId
	elseif game.PlaceId == Config.EntrancePlaceId then
		return Config.DestinationPlaceId
	end

	return nil
end

function Config.MigrateState(state)
	if not state or not state.Collected then
		return
	end

	local collected = {}
	for _, item in Config.Items do
		if state.Collected[item.Id] == true or state.Collected[item.Key] == true then
			collected[item.Id] = true
		end
	end

	state.Collected = collected
end

return Config
