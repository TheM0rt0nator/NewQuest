param([switch]$Stage)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine(@'
assert(game.PlaceId == 99606216494108, "Install only in MQ")
assert(not game:GetService("RunService"):IsRunning(), "Stop the playtest first")
local storage = game.ServerStorage
local map = workspace
local shared = game.ReplicatedStorage.SharedModules
local server = game.ServerScriptService.Services.QuestService
local controller = game.StarterPlayer.StarterPlayerScripts.Controllers.QuestController
local function folder(parent, name)
	local object = Instance.new("Folder")
	object.Name = name
	object.Parent = parent
	return object
end
local function source(parent, name, code)
	local module = parent:FindFirstChild(name)
	if not module then
		module = Instance.new("ModuleScript")
		module.Name = name
		module.Parent = parent
	end
	module.Source = code
	return module
end
'@)
if ($Stage) {
    [void]$builder.AppendLine(@'
local review = folder(storage, "MQPrivacyReview_" .. os.time())
storage = folder(review, "Assets")
map = folder(review, "Map")
workspace.ClassicTree:Clone().Parent = map
workspace.SecretQuestStuff:Clone().Parent = map
shared = folder(review, "Shared")
folder(shared, "Configs")
server = folder(review, "Server")
folder(server, "Quests")
controller = folder(review, "Controller")
folder(controller, "Quests")
'@)
} else {
    [void]$builder.AppendLine(@'
local backup = folder(storage, "MQPrivacyBackup_" .. os.time())
local snapshot = folder(backup, "Objects")
for _, object in {
	shared.Configs.Quests, shared.SecretQuestAccess, server, controller,
	map:FindFirstChild("ClassicTree"), map:FindFirstChild("SecretQuestStuff"),
} do
	local copy = object:Clone()
	copy.Parent = snapshot
	local reference = Instance.new("ObjectValue")
	reference.Name = "OriginalParent"
	reference.Value = object.Parent
	reference.Parent = copy
end
'@)
}
$sources = @(
    @{ Path = 'mq/QuestConfig.lua'; Parent = 'shared.Configs'; Name = 'Quests' },
    @{ Path = 'mq/ClientAccess.lua'; Parent = 'shared'; Name = 'SecretQuestAccess' },
    @{ Path = 'mq/ServerConfig.lua'; Parent = 'server'; Name = 'SecretQuestConfig' },
    @{ Path = 'mq/ServerAccess.lua'; Parent = 'server'; Name = 'SecretQuestAccess' },
    @{ Path = 'mq/Bindings.lua'; Parent = 'server'; Name = 'SecretQuestBindings' },
    @{ Path = 'mq/Carry.lua'; Parent = 'server'; Name = 'SecretQuestCarry' },
    @{ Path = 'mq/Entrance.lua'; Parent = 'server'; Name = 'SecretQuestEntrance' },
    @{ Path = 'mq/Quest.lua'; Parent = 'server.Quests'; Name = 'SecretQuest' },
    @{ Path = 'mq/ClientQuest.lua'; Parent = 'controller.Quests'; Name = 'SecretQuest' },
    @{ Path = 'tools/MQPrivacyScene.lua'; Parent = 'server'; Name = 'PrivacySceneMigration' }
)
foreach ($entry in $sources) {
    $code = [System.IO.File]::ReadAllText((Join-Path $projectRoot $entry.Path))
    if ($Stage) {
        if ($entry.Path -eq 'mq/ServerConfig.lua') {
            $code = $code.Replace('require(ReplicatedStorage.SharedModules.Configs.Quests)', 'require(script.Parent.Parent.Shared.Configs.Quests)')
        }
        if ($entry.Path -eq 'mq/Bindings.lua') {
            $code = $code.Replace('game:GetService("ServerStorage")', 'script.Parent.Parent.Assets')
        }
        if ($entry.Path -eq 'mq/Quest.lua') {
            $code = $code.Replace('require(ReplicatedStorage.Packages.Knit)', 'require(script.Parent.Parent.TestKnit)')
            $code = $code.Replace('require(Knit.Modules.SafeTeleport)', 'function() error("No test teleports") end')
        }
    }
    [void]$builder.AppendLine(('source({0}, "{1}", [====[' -f $entry.Parent, $entry.Name))
    [void]$builder.AppendLine($code)
    [void]$builder.AppendLine(']====])')
}
if (-not $Stage) {
    foreach ($entry in @(@{ Path = 'mq/Service.lua'; Target = 'server' }, @{ Path = 'mq/ClientController.lua'; Target = 'controller' })) {
        [void]$builder.AppendLine(('{0}.Source = [====[' -f $entry.Target))
        [void]$builder.AppendLine([System.IO.File]::ReadAllText((Join-Path $projectRoot $entry.Path)))
        [void]$builder.AppendLine(']====]')
    }
}
[void]$builder.AppendLine(@'
local config = require(server.SecretQuestConfig)
local references = require(server.PrivacySceneMigration)(map, storage, config)
'@)
if ($Stage) {
    [void]$builder.AppendLine([System.IO.File]::ReadAllText((Join-Path $projectRoot 'tools/TestMQPrivacy.lua')))
} else {
    [void]$builder.AppendLine('return "MQ privacy update installed. Backup: " .. backup.Name .. "; no place published."')
}
$name = if ($Stage) { 'StageMQPrivacy.lua' } else { 'InstallMQPrivacy.lua' }
$outputPath = Join-Path $projectRoot "build/$name"
[System.IO.File]::WriteAllText($outputPath, $builder.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Output $outputPath
