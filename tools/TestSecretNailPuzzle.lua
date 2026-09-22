-- Run in Secret's Studio datamodel after installing the quest modules.
assert(game.PlaceId == 78518778092310, "Run only in Secret")
assert(game:GetService("RunService"):IsStudio(), "Run only in Studio")

local HttpService = game:GetService("HttpService")
local Config = require(game.ServerScriptService.SecretQuest.Config)
local Progress = require(game.ServerScriptService.SecretQuest.Progress)
local code = Config.NailCode
local WRONG_COLOUR = "Institutional white"
local cases = 0

local function checkSequence(name, inputs, solveAt, data)
	data = data or Progress.New()
	data.Stage = 3

	for index, colour in inputs do
		local changed, solved = Progress.Apply(data, "Colour", "Polish:" .. colour)
		assert(changed, name .. ": input was rejected")
		assert(solved == (index == solveAt), name .. ": incorrect completion at input " .. index)
		assert(#data.Values.Code <= #code, name .. ": input history grew without a bound")
		assert(not data.Values.CodeRejected, name .. ": obsolete rejection state remains")
	end

	cases += 1
	return data
end

-- The correct sequence must work at every offset across the old batch boundary.
for wrongCount = 0, 11 do
	local inputs = {}

	for _ = 1, wrongCount do
		table.insert(inputs, WRONG_COLOUR)
	end

	for _, colour in code do
		table.insert(inputs, colour)
	end

	checkSequence("Wrong prefix of " .. wrongCount, inputs, #inputs)
end

checkSequence("Restart within a partial attempt", {
	code[1],
	code[2],
	code[3],
	code[1],
	code[2],
	code[3],
	code[4],
	code[5],
}, 8)

local interrupted = checkSequence("Interrupted sequence must not solve", {
	code[1],
	code[2],
	WRONG_COLOUR,
	code[3],
	code[4],
	code[5],
}, nil)
checkSequence("Recover from interrupted sequence", code, #code, interrupted)

local saved = Progress.New()
saved.Values = { Code = { WRONG_COLOUR }, CodeRejected = true }
saved = checkSequence("Resume old saved input", { code[1], code[2] }, nil, saved)
saved = HttpService:JSONDecode(HttpService:JSONEncode(saved))
checkSequence("Complete across save and reload", { code[3], code[4], code[5] }, 3, saved)

return "Passed " .. cases .. " nail puzzle regression cases."
