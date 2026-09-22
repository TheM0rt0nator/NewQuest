local ServerStorage = game:GetService("ServerStorage")

local Config = require(script.Parent.SecretQuestConfig)

local Bindings = {}
local references = ServerStorage:WaitForChild("SecretQuestBindings")
local prompts = {}

for _, item in Config.Items do
	local anchor = references[item.Key].Value
	local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
	prompts[prompt] = { Anchor = anchor, ItemId = item.Id }
end

local tree = references.Tree.Value
Bindings.Tree = tree
Bindings.Trunk = references.Trunk.Value
Bindings.TreePrompt = tree:FindFirstChildOfClass("ProximityPrompt")
prompts[Bindings.TreePrompt] = { Anchor = tree }

function Bindings.Get(prompt)
	return prompts[prompt]
end

return Bindings
