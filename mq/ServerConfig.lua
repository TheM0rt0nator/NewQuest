local ReplicatedStorage = game:GetService("ReplicatedStorage")

local presentation = require(ReplicatedStorage.SharedModules.Configs.Quests).SecretQuest

local Config = {
	DisplayName = presentation.DisplayName,
	Description = presentation.Description,
	Objectives = presentation.Objectives,
	EntrancePlaceId = 8481844229,
	TestEntrancePlaceId = 99606216494108,
	DestinationPlaceId = 78518778092310,
	Items = {
		{ Id = "e67a20c3", Key = "SunsetShirt", DisplayName = "Sunset shirt" },
		{ Id = "b8f314d9", Key = "Smoothie", DisplayName = "smoothie" },
		{ Id = "c52d7a06", Key = "NailPolish", DisplayName = "nail polish" },
	},
}

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
