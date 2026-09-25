$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $projectRoot 'build/InstallSecretQuest.lua'
$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine(@'
assert(
	game.PlaceId == 78518778092310 or game.PlaceId == 93796111143212,
	"Install only in a Secret quest destination"
)
assert(not game:GetService("RunService"):IsRunning(), "Stop the playtest first")

local backup = Instance.new("Folder")
backup.Name = "SecretQuestPrivacyBackup_" .. os.time()
backup.Parent = game.ServerStorage
for _, object in {
	game.ServerScriptService:FindFirstChild("SecretQuest"),
	game.ReplicatedStorage:FindFirstChild("SecretQuest"),
	game.StarterPlayer.StarterPlayerScripts:FindFirstChild("SecretQuest"),
	workspace:FindFirstChild("SecretQuest"),
	game.ServerStorage:FindFirstChild("SecretQuestAssets"),
	game.ServerStorage:FindFirstChild("SecretQuestOriginals"),
} do
	local copy = object:Clone()
	copy.Parent = backup
	local reference = Instance.new("ObjectValue")
	reference.Name = "OriginalParent"
	reference.Value = object.Parent
	reference.Parent = copy
end
local mapState = Instance.new("Folder")
mapState.Name = "MapState"
mapState.Parent = backup
for _, object in workspace:GetDescendants() do
	local attributes = object:GetAttributes()
	local record
	for key, value in attributes do
		if key:match("^Secret") then
			if not record then
				record = Instance.new("ObjectValue")
				record.Name = object.ClassName
				record.Value = object
				record.Parent = mapState
			end
			record:SetAttribute(key, value)
		end
	end
end

local function folder(parent, name)
	local object = parent:FindFirstChild(name)

	if not object then
		object = Instance.new("Folder")
		object.Name = name
		object.Parent = parent
	end

	return object
end

local shared = folder(game.ReplicatedStorage, "SecretQuest")
local celebrationFinished = shared:FindFirstChild("CelebrationFinished")

if not celebrationFinished then
	celebrationFinished = Instance.new("RemoteEvent")
	celebrationFinished.Name = "CelebrationFinished"
	celebrationFinished.Parent = shared
end

local server = folder(game.ServerScriptService, "SecretQuest")
local packages = folder(game.ServerScriptService, "SecretQuestPackages")
local playerScripts = game.StarterPlayer.StarterPlayerScripts

for _, name in { "QuestView", "ObjectiveMarkers" } do
	local unused = shared:FindFirstChild(name)

	if unused then
		unused:Destroy()
	end
end

local function source(parent, name, className, code)
	local previous = parent:FindFirstChild(name)

	if previous and previous.ClassName == className and previous.Source == code then
		return previous
	end

	if previous then
		previous:Destroy()
	end

	local object = Instance.new(className)
	object.Name = name
	object.Source = code

	if object:IsA("BaseScript") then
		object.Disabled = true
	end

	object.Parent = parent
	return object
end
'@)

$sources = @(
    @{ Path = 'secret/shared/Config.lua'; Parent = 'shared'; Name = 'Config'; Class = 'ModuleScript' },
    @{ Path = 'secret/shared/AnniversaryQuestConfig.lua'; Parent = 'shared'; Name = 'AnniversaryQuestConfig'; Class = 'ModuleScript' },
    @{ Path = 'src/ReplicatedStorage/Modules/QuestCelebration.lua'; Parent = 'shared'; Name = 'QuestCelebration'; Class = 'ModuleScript' },
    @{ Path = 'src/ReplicatedStorage/Modules/QuestUI.lua'; Parent = 'shared'; Name = 'QuestUI'; Class = 'ModuleScript' },
    @{ Path = 'src/ReplicatedStorage/Modules/QuestUISound.lua'; Parent = 'shared'; Name = 'QuestUISound'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/Progress.lua'; Parent = 'server'; Name = 'Progress'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/Config.lua'; Parent = 'server'; Name = 'Config'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/PrivateState.lua'; Parent = 'server'; Name = 'PrivateState'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/Props.lua'; Parent = 'server'; Name = 'Props'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/PolishSymbols.lua'; Parent = 'server'; Name = 'PolishSymbols'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/Clues.lua'; Parent = 'server'; Name = 'Clues'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/VipShirt.lua'; Parent = 'server'; Name = 'VipShirt'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/Smoothie.lua'; Parent = 'server'; Name = 'Smoothie'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/World.lua'; Parent = 'server'; Name = 'World'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/Service.lua'; Parent = 'server'; Name = 'Service'; Class = 'ModuleScript' },
    @{ Path = 'secret/server/Bootstrap.server.lua'; Parent = 'server'; Name = 'Bootstrap'; Class = 'Script' },
    @{ Path = 'secret/client/SecretQuest.client.lua'; Parent = 'playerScripts'; Name = 'SecretQuest'; Class = 'LocalScript' },
    @{ Path = 'ServerPackages/ProfileStore.luau'; Parent = 'packages'; Name = 'ProfileStore'; Class = 'ModuleScript' }
)

foreach ($entry in $sources) {
    $code = [System.IO.File]::ReadAllText((Join-Path $projectRoot $entry.Path))
    $delimiter = '===='
    while ($code.Contains("]$delimiter]")) {
        $delimiter += '='
    }
    [void]$builder.AppendLine(('source({0}, "{1}", "{2}", [{3}[' -f $entry.Parent, $entry.Name, $entry.Class, $delimiter))
    [void]$builder.AppendLine($code)
    [void]$builder.AppendLine("]$delimiter])")
}

[void]$builder.AppendLine(@'
local root = require(server.World).Build()
require(server.World).Render(root, require(server.Progress).New())
server.Bootstrap.Disabled = false
playerScripts.SecretQuest.Disabled = false
game.ReplicatedStorage:SetAttribute("QuestMode", "Secret")
return "Secret quest updated. Backup: " .. backup.Name .. "; no place published."
'@)

[System.IO.File]::WriteAllText($outputPath, $builder.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Output $outputPath
