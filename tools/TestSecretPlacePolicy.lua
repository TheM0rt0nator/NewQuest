-- Checks the real configuration and policy branches without accessing live data.
assert(game:GetService("RunService"):IsStudio(), "Run only in Studio")

local server = game.ServerScriptService.SecretQuest
local fixture = Instance.new("Folder")
fixture.Name = "SecretPlacePolicyTest"
fixture.Parent = game.ServerStorage

local function module(name, source)
	local object = Instance.new("ModuleScript")
	object.Name = name
	object.Source = source
	object.Parent = fixture
	return object
end

local success, result = pcall(function()
	local serviceSource = server.Service.Source
	local first = assert(serviceSource:find("local resetProgressOnJoin =", 1, true))
	local last = assert(serviceSource:find("local connections =", first, true))
	local selection = serviceSource:sub(first, last - 1)
	local resetFirst = assert(serviceSource:find("\tif resetProgressOnJoin then", 1, true))
	local resetLast = assert(serviceSource:find("\tloaded:Reconcile()", resetFirst, true))
	local reset = serviceSource:sub(resetFirst, resetLast - 1)
	local count = 0

	for _, placeId in { 93796111143212, 78518778092310 } do
		local prefix = "local game = { PlaceId = " .. placeId .. " }\n"
		local configModule = module("Config" .. placeId, prefix .. server.Config.Source)
		local config = require(configModule)
		local testing = placeId == 78518778092310
		assert(config.CompletionBadgeId == (testing and 4162590358506538 or 2308865322054249))

		for _, studio in { false, true } do
			local code = prefix
				.. 'local Config = require(script.Parent["'
				.. configModule.Name
				.. '"])\n'
				.. "local RunService = { IsStudio = function() return "
				.. tostring(studio)
				.. " end }\n"
				.. [[
local mock = {}
local ProfileStore = { New = function() return { Mock = mock } end }
local Progress = { New = function() return { Stage = 1, Values = {}, Completed = false } end }
]]
				.. selection
				.. [[
return function(initialData)
	local loaded = { Data = initialData }
]]
				.. reset
				.. [[
	return { Reset = resetProgressOnJoin, Mock = store == mock, Data = loaded.Data }
end
]]
			local apply = require(module("Policy" .. count, code))
			for _, initialData in
				{
					{ Stage = 3, Values = { Code = { "Cyan" } }, Completed = false },
					{ Stage = 5, Values = {}, Completed = true },
				}
			do
				local policy = apply(initialData)
				assert(policy.Reset == testing)
				assert(policy.Mock == (studio or testing))
				if testing then
					assert(policy.Data.Stage == 1 and not policy.Data.Completed)
				else
					assert(policy.Data == initialData, "Production progress was replaced")
				end
				count += 1
			end
		end
	end

	for _, placeId in { 93796111143212, 78518778092310, 123 } do
		for _, entry in
			{
				{ Script = server.Bootstrap, Config = server.Config },
				{
					Script = game.StarterPlayer.StarterPlayerScripts.SecretQuest,
					Config = game.ReplicatedStorage.SecretQuest.Config,
				},
			}
		do
			local prefix = "local game = { PlaceId = " .. placeId .. " }\n"
			local configModule = module("GateConfig" .. count, prefix .. entry.Config.Source)
			local source = entry.Script.Source
			local gateFirst = assert(source:find("if game.PlaceId", 1, true))
			local gateLast = assert(source:find("\nend", gateFirst, true))
			local code = prefix
				.. 'local Config = require(script.Parent["'
				.. configModule.Name
				.. '"])\n'
				.. "local function allowed()\n"
				.. source:sub(gateFirst, gateLast + 3)
				.. "\nreturn true\nend\nreturn allowed() == true"
			local enabled = require(module("Gate" .. count, code))
			assert(enabled == (placeId ~= 123), "Incorrect client/server place gate")
			count += 1
		end
	end

	return "Passed " .. count .. " production/test policy and entry-point checks."
end)

fixture:Destroy()
assert(success, result)
return result
