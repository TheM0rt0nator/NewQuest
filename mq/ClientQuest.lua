local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SecretQuest = {}
SecretQuest.__index = SecretQuest

function SecretQuest.new(state)
	local self = setmetatable({}, SecretQuest)
	self:StateSet(state)
	return self
end

function SecretQuest:StateSet(state)
	self.State = state
	Knit.GetController("QuestController"):SetObjectiveMarkers({}, "SecretQuest")
end

function SecretQuest:Destroy()
	Knit.GetController("QuestController"):SetObjectiveMarkers({}, "SecretQuest")
end

return SecretQuest
