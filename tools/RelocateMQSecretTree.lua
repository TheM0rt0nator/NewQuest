assert(game.PlaceId == 99606216494108, "Run only in the MQ place")
assert(not game:GetService("RunService"):IsRunning(), "Stop the playtest first")

local references = game.ServerStorage:WaitForChild("SecretQuestBindings")
local tree = references.TreeModel.Value
local trunk = references.Trunk.Value
local trigger = references.Tree.Value
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { tree, trigger }
params.RespectCanCollide = true
local ground = workspace:Raycast(Vector3.new(-1205, 200, 2105), Vector3.new(0, -250, 0), params)
assert(ground and ground.Normal.Y > 0.9, "Expected accessible campsite ground")

if references.TreeModel:GetAttribute("SecretTreeOriginalPivot") == nil then
	references.TreeModel:SetAttribute("SecretTreeOriginalPivot", tree:GetPivot())
	references.Tree:SetAttribute("SecretTreeOriginalCFrame", trigger.CFrame)
end

if references.TreeModel:GetAttribute("SecretTreeBeforeConcealmentPivot") == nil then
	references.TreeModel:SetAttribute("SecretTreeBeforeConcealmentPivot", tree:GetPivot())
	references.Tree:SetAttribute("SecretTreeBeforeConcealmentCFrame", trigger.CFrame)
end

local offset = Vector3.new(
	ground.Position.X - trunk.Position.X,
	ground.Position.Y - (trunk.Position.Y - trunk.Size.Y / 2),
	ground.Position.Z - trunk.Position.Z
)
tree:PivotTo(tree:GetPivot() + offset)
trigger.CFrame = trunk.CFrame * CFrame.new(0, -trunk.Size.Y / 2 + 3, 0)
trigger:FindFirstChildOfClass("ProximityPrompt").MaxActivationDistance = 8
references.TreeModel:SetAttribute(
	"SecretTreeLocation",
	"Behind the rocky grove on the far side of the campsite lake"
)

return "Moved the classic tree and its activation trigger behind the campsite's rocky grove."
