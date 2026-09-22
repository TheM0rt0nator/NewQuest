local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local SecretQuestAccess = require(Knit.Shared.SecretQuestAccess)

local SecretQuest = {}
SecretQuest.__index = SecretQuest

function SecretQuest.new(state)
	local self = setmetatable({
		Janitor = Janitor.new(),
		State = state,
		OriginalPrompts = {},
	}, SecretQuest)
	self.Janitor:Add(
		CollectionService:GetInstanceAddedSignal("InteractionPrompt"):Connect(function()
			self:Refresh()
		end),
		"Disconnect"
	)
	self.Janitor:Add(
		CollectionService:GetInstanceRemovedSignal("InteractionPrompt"):Connect(function(prompt)
			self:RestorePrompt(prompt)
			self:Refresh()
		end),
		"Disconnect"
	)
	self:Refresh()
	return self
end

function SecretQuest:RestorePrompt(prompt)
	local original = self.OriginalPrompts[prompt]
	if original then
		prompt.Enabled = original.Enabled
		prompt.ActionText = original.ActionText
		self.OriginalPrompts[prompt] = nil
	end
end

function SecretQuest:Refresh()
	local available = SecretQuestAccess.IsAvailable(Knit.Player)
	local collected = self.State.Collected or {}
	for _, prompt in CollectionService:GetTagged("InteractionPrompt") do
		if not prompt:IsA("ProximityPrompt") or not prompt:IsDescendantOf(workspace) then
			continue
		end

		if not self.OriginalPrompts[prompt] then
			self.OriginalPrompts[prompt] = {
				Enabled = prompt.Enabled,
				ActionText = prompt.ActionText,
			}
		end

		prompt.ActionText = ""
		local itemId = prompt:GetAttribute("InteractionKey")
		if itemId then
			prompt.Enabled = available and self.State.Id == 1 and not collected[itemId]
		else
			prompt.Enabled = available
		end
	end

	Knit.GetController("QuestController"):SetObjectiveMarkers({}, "SecretQuest")
end

function SecretQuest:StateSet(state)
	self.State = state
	self:Refresh()
end

function SecretQuest:Destroy()
	self.Janitor:Destroy()
	for prompt in self.OriginalPrompts do
		self:RestorePrompt(prompt)
	end

	Knit.GetController("QuestController"):SetObjectiveMarkers({}, "SecretQuest")
end

return SecretQuest
