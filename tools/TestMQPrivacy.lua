local bindings = require(server.SecretQuestBindings)
assert(references.TreeModel.Value.ModelStreamingMode == Enum.ModelStreamingMode.Atomic)
assert(bindings.Get(bindings.TreePrompt).Anchor == references.Tree.Value)
assert(bindings.Get(Instance.new("ProximityPrompt")) == nil)
for _, object in map:GetDescendants() do
	assert(not object.Name:match("ClassicTree") and not object.Name:match("SecretQuest"))
	for key in object:GetAttributes() do
		assert(not key:match("^Secret"), "Exposed map metadata: " .. key)
	end
end

for _, item in config.Items do
	local anchor = references[item.Key].Value
	local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
	assert(bindings.Get(prompt).ItemId == item.Id)
	assert(prompt:GetAttribute("InteractionKey") == item.Id)
end

source(
	server,
	"TestKnit",
	[[
local data = { Quests = { SecretQuest = { Active = true } } }
local events = {}
local function signal()
	return { Fire = function(_, ...)
		table.insert(events, { ... })
	end }
end
local services = {
	PlayerService = {
		Client = { SendNotification = signal() },
		GetPlayerData = function()
			return { await = function()
				return true, data
			end }
		end,
	},
	QuestService = { Client = { QuestReceived = signal(), QuestUpdated = signal() } },
}
return {
	Data = data,
	Events = events,
	GetService = function(name)
		return services[name]
	end,
}
]]
)
local knit = require(server.TestKnit)
local Quest = require(server.Quests.SecretQuest)
local added = Instance.new("BindableEvent")
local removing = Instance.new("BindableEvent")
local player = {
	Parent = game.Players,
	Name = "PrivacyTest",
	UserId = -1,
	CharacterAdded = added.Event,
	CharacterRemoving = removing.Event,
	GetAttribute = function()
		return false
	end,
}
local saved = { Active = true, State = { Collected = { SunsetShirt = true } } }
config.MigrateState(saved.State)
assert(saved.State.Collected.SunsetShirt == nil)
assert(saved.State.Collected[config.Items[1].Id])
local quest = Quest.new(player, saved)
knit.Data.Quests.SecretQuest = saved
assert(quest.State.Progress == 1 and quest.State.Id == 1)
assert(saved.State == quest.State)
assert(not quest:Collect("SunsetShirt"))
assert(not quest:Collect("fabricated-id"))
assert(not quest:Collect(config.Items[1].Id))
assert(quest:Collect(config.Items[2].Id))
assert(quest.State.Id == 1 and quest.State.Progress == 2)
assert(quest:Collect(config.Items[3].Id))
assert(quest.State.Id == 2 and quest.State.Progress == 3)
assert(not quest:Collect(config.Items[3].Id))
quest:Travel(bindings.TreePrompt)
assert(quest.NextTeleportAttempt == nil, "Travel accepted missing character")
quest:Destroy()
added:Destroy()
removing:Destroy()
local public = require(shared.Configs.Quests).SecretQuest
assert(public.Items == nil and public.DestinationPlaceId == nil)
assert(public.EntrancePlaceId == nil and public.TestEntrancePlaceId == nil)
review:SetAttribute("ValidationPassed", true)
return "MQ private-copy validation passed: saved progress, collection, bindings and metadata. "
	.. review.Name
