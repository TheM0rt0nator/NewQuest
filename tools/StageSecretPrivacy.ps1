$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine(@'
assert(game.PlaceId == 78518778092310, "Validate only in Secret")
assert(not game:GetService("RunService"):IsRunning(), "Validate in Edit")
local review = Instance.new("Folder")
review.Name = "SecretQuestPrivacyReview_" .. os.time()
review.Parent = game.ServerStorage
local modules = Instance.new("Folder")
modules.Name = "Modules"
modules.Parent = review
local map = Instance.new("Model")
map.Name = "Map"
map.Parent = review
for _, name in { "Assets", "Records" } do
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = review
end
local buildings = Instance.new("Folder")
buildings.Name = "Buildings"
buildings.Parent = map
for _, name in { "BeachsideBoutique", "SunsetClothing", "NailSalon", "JuiceAndSmoothie" } do
	workspace.Buildings[name]:Clone().Parent = buildings
end
local copied = {}
for _, reference in workspace.SecretQuest:GetDescendants() do
	if reference:IsA("ObjectValue") and reference.Value then
		local object = reference.Value
		if reference.Name:match("^Mannequin") or reference.Name:match("^PolishBottle")
			or reference.Name == "OriginalCounterPolish" then
			local model = object:IsA("Model") and object or object.Parent
			if not copied[model] then
				local clone = model:Clone()
				for _, child in clone:GetDescendants() do
					if child:IsA("ProximityPrompt") or child:IsA("ClickDetector") then
						child:Destroy()
					end
				end
				clone.Parent = map
				copied[model] = true
			end
		end
	end
end
local function addModule(name, code)
	local module = Instance.new("ModuleScript")
	module.Name = name
	module.Source = code
	module.Parent = modules
end
'@)
foreach ($name in @('Config', 'PrivateState', 'Props', 'Clues', 'PolishSymbols', 'Progress', 'Smoothie', 'World')) {
    $code = [System.IO.File]::ReadAllText((Join-Path $projectRoot "secret/server/$name.lua"))
    if ($name -eq 'World') {
        $code = $code.Replace('local ServerStorage = game:GetService("ServerStorage")', 'local ServerStorage = script.Parent.Parent.Assets')
        $code = $code.Replace('local RunService = game:GetService("RunService")', 'local RunService = { IsRunning = function() return true end }')
    }
    if ($name -eq 'PrivateState') {
        $code = $code.Replace('local ServerStorage = game:GetService("ServerStorage")', 'local ServerStorage = script.Parent.Parent.Records')
    }
    $code = "local workspace = script.Parent.Parent.Map`n" + $code
    [void]$builder.AppendLine(('addModule("{0}", [====[' -f $name))
    [void]$builder.AppendLine($code)
    [void]$builder.AppendLine(']====])')
}
[void]$builder.AppendLine(@'
local World = require(modules.World)
local Props = require(modules.Props)
local Progress = require(modules.Progress)
local Smoothie = require(modules.Smoothie)
local world = World.Build()
local smoothie = Smoothie.new(world.Stages[4])
for stage = 1, 5 do
	local data = Progress.New()
	data.Stage = stage
	data.Completed = stage == 5
	World.Render(world, data)
	smoothie:Render(data)
	for index, record in world.Stages do
		assert(record.Model:IsDescendantOf(map) == (index <= stage), "Premature stage replication")
	end
	assert(world.Portal:IsDescendantOf(map) == data.Completed, "Premature portal replication")
	for object, binding in Props.Interactions() do
		assert(object:GetAttribute("Stage") == nil and object:GetAttribute("Action") == nil)
		assert(binding.Prompt:IsDescendantOf(map) == (binding.Stage == stage))
	end
end
for _, object in world.Container:GetDescendants() do
	assert(next(object:GetAttributes()) == nil, "Generated metadata still exposed")
	assert(not object.Name:match("ColourClue") and not object.Name:match("Strawberry"))
end
World.Hide(world)
assert(not world.Container:IsDescendantOf(map))
review:SetAttribute("ValidationPassed", true)
return "Private-copy validation passed for all five stages, prompt gating, metadata removal and portal gating. " .. review.Name
'@)
$output = Join-Path $projectRoot 'build/StageSecretPrivacy.lua'
[System.IO.File]::WriteAllText($output, $builder.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Output $output
