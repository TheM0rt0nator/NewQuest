-- Run from a temporary server Script in a fresh Secret Studio playtest.
assert(game.PlaceId == 78518778092310, "Run only in Secret")
assert(game:GetService("RunService"):IsStudio(), "Run only in Studio")

local Players = game:GetService("Players")
local Config = require(game.ServerScriptService.SecretQuest.Config)
local Progress = require(game.ServerScriptService.SecretQuest.Progress)
local Service = require(game.ServerScriptService.SecretQuest.Service)
local player = Players:GetPlayers()[1]
local World = require(game.ServerScriptService.SecretQuest.World)
local Props = require(game.ServerScriptService.SecretQuest.Props)
local root = World.Current()

local function waitFor(predicate, message, timeout)
	local deadline = os.clock() + (timeout or 10)

	while not predicate() do
		assert(os.clock() < deadline, message)
		task.wait(0.1)
	end
end

waitFor(function()
	return player:GetAttribute("SecretReady")
end, "Quest did not load")
assert(player:GetAttribute("SecretSaveMode") == "ProfileStore.Mock", "Must use mock data")
assert(Service.GetState(player).Stage == 1, "Start a fresh playtest")
assert(root.Stages[1].Model:IsDescendantOf(workspace))
for index = 2, 4 do
	assert(not root.Stages[index].Model:IsDescendantOf(workspace), "Future puzzle replicated")
end
assert(not root.Portal:IsDescendantOf(workspace), "Portal replicated too early")
for object, binding in Props.Interactions() do
	assert(object:GetAttribute("Action") == nil and object:GetAttribute("Stage") == nil)
	assert(binding.Prompt:IsDescendantOf(workspace) == (binding.Stage == 1))
end

local character = player.Character
local function interact(object)
	character:PivotTo(object.CFrame + Vector3.new(0, 2, 3))
	task.wait(0.3)
	return Service.Interact(player, object)
end

interact(root.Portal)
assert(player:GetAttribute("SecretReturnStatus") == nil, "Unfinished quest entered portal")

local description = character.Humanoid:GetAppliedDescription()
description.GraphicTShirt = Config.VipTShirtId
character.Humanoid:ApplyDescriptionAsync(description)
description:Destroy()
character:PivotTo(root.Stages[1].Gate.CFrame)
waitFor(function()
	return Service.GetState(player).Stage == 2
end, "Equipped VIP shirt did not open the door")

for index, initial in Config.MannequinInitialTurns do
	for _ = 1, 4 - initial do
		assert(interact(root.Stages[2].Mannequins[index].Model.Torso))
	end
end

assert(Service.GetState(player).Stage == 3, "Mannequins did not complete")
local bottles = {}

for object, binding in Props.Interactions() do
	if binding.Stage == 3 then
		bottles[object.BrickColor.Name] = object
	end
end

for _ = 1, 3 do
	assert(interact(bottles["Institutional white"]))
end

for _, colour in Config.NailCode do
	assert(interact(bottles[colour]))
end

assert(Service.GetState(player).Stage == 4, "Nail sequence failed after wrong inputs")
local stage = root.Stages[4]

for _, ingredient in { "Orange", "Kiwi", "Pineapple", "Chocolate" } do
	assert(interact(stage.Ingredients[ingredient].PrimaryPart))
	local held
	for _, child in character:GetChildren() do
		if
			child:IsA("Model")
			and child.PrimaryPart
			and child.PrimaryPart:FindFirstChild("HandGrip")
		then
			held = child
		end
	end
	assert(held and Service.GetState(player).Values.Held == ingredient, "Missing held ingredient")
	assert(held.PrimaryPart.HandGrip.Part0:IsDescendantOf(character), "Ingredient is not attached")
	assert(not held.PrimaryPart.Anchored, "Held ingredient must move with the hand")
	assert(interact(stage.Blender.Centre))
	assert(#stage.Blender.Contents:GetChildren() > 0, "Missing visible jug ingredient")
	assert(interact(stage.ResetButton))
end

-- Exhaust all three-ingredient combinations: only the intended recipe succeeds.
local combinations = 0
local solutions = 0

for first = 1, #Config.SmoothieIngredients - 2 do
	for second = first + 1, #Config.SmoothieIngredients - 1 do
		for third = second + 1, #Config.SmoothieIngredients do
			local data = Progress.New()
			data.Stage = 4

			for _, index in { first, second, third } do
				assert(
					Progress.Apply(data, "Smoothie", "Pick:" .. Config.SmoothieIngredients[index])
				)
				assert(Progress.Apply(data, "Smoothie", "Deposit"))
			end

			local changed, solved = Progress.Apply(data, "Smoothie", "Blend")
			assert(changed)
			combinations += 1

			if solved then
				solutions += 1
			end
		end
	end
end

assert(combinations == 56 and solutions == 1, "Incorrect smoothie solution space")

for _, ingredient in Config.SmoothieRecipe do
	assert(interact(stage.Ingredients[ingredient].PrimaryPart))
	assert(interact(stage.Blender.Centre))
end

assert(interact(stage.BlendButton))
assert(Service.GetState(player).Completed, "Final blend did not complete")
assert(Props.Interaction(root.Portal).Prompt.Enabled, "Portal did not open")
task.wait(1)
assert(
	player:GetAttribute("SecretCelebrationStartedAt") == nil,
	"Completion appeared before portal"
)
assert(player:GetAttribute("SecretBadgeStatus") == nil, "Badge attempted before portal")
assert(not player.PlayerGui:FindFirstChild("QuestCelebration"), "Premature completion GUI")

interact(root.Portal)
waitFor(function()
	return player:GetAttribute("SecretReturnStatus") == "Celebrating"
end, "Portal did not start celebration", 30)
assert(player:GetAttribute("SecretBadgeStatus") == "StudioSimulated", "Badge was not checked first")
local startedAt = player:GetAttribute("SecretCelebrationStartedAt")
Service.Interact(player, root.Portal)
assert(
	player:GetAttribute("SecretCelebrationStartedAt") == startedAt,
	"Duplicate portal restarted UI"
)
task.wait(2)
assert(player:GetAttribute("SecretReturnStatus") == "Celebrating", "Early client ack skipped UI")
waitFor(function()
	return player:GetAttribute("SecretReturnStatus") == "StudioComplete"
end, "Celebration did not finish and return", 15)
assert(
	player:GetAttribute("SecretCelebrationStartedAt") == nil,
	"Celebration state was not cleared"
)

workspace:SetAttribute(
	"SecretFeedbackTestResult",
	"Passed: full quest, 56 recipes, new fruit, portal timing"
)
print(workspace:GetAttribute("SecretFeedbackTestResult"))
