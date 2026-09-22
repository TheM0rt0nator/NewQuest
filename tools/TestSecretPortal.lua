-- Execute in Secret Studio. Uses the portal functions verbatim with fake services.
assert(game.PlaceId == 78518778092310, "Run only in Secret")
assert(game:GetService("RunService"):IsStudio(), "Run only in Studio")

local source = game.ServerScriptService.SecretQuest.Service.Source
local first = assert(source:find("local function cancelReturnTask()", 1, true))
local last = assert(source:find("function Service.Interact", first, true))
local module = Instance.new("ModuleScript")
module.Name = "SecretPortalTestFixture"
module.Source = [=[
return function(context)
	local BadgeService = context.BadgeService
	local TeleportService = context.TeleportService
	local RunService = {
		IsStudio = function()
			return false
		end,
	}
	local Config = { CompletionBadgeId = 4162590358506538, ReturnPlaceId = 8481844229 }
	local CelebrationConfig = { CompletionCelebrationDuration = 0.05 }
	local os = {
		clock = function()
			return context.Now
		end,
	}
	local owner = context.Player
	local profile = context.Profile
	local root = { Portal = {} }
	local started = true
	local pendingReturn = false
	local returnGeneration = 0
	local returnTask
	local celebrated = false
	local lastReturn = 0
	local function nearby()
		return context.Nearby
	end
]=] .. source:sub(first, last - 1) .. [=[
	return {
		Enter = function()
			returnHome(context.Player)
		end,
		Finish = function()
			finishReturn(context.Player, context.Profile, returnGeneration)
		end,
		Cancel = function()
			started = false
			cancelReturnTask()
			returnGeneration += 1
		end,
	}
end
]=]
module.Parent = game.ServerScriptService
local makePortal = require(module)
local cases = 0

local function fixture()
	local player = Instance.new("Folder")
	local context = {
		Player = player,
		Now = 100,
		Nearby = true,
		Owned = false,
		AwardFails = false,
		TeleportFails = false,
		AwardCalls = 0,
		TeleportCalls = 0,
		Active = true,
	}
	context.Profile = {
		Data = { Completed = true },
		LastSavedData = { Completed = true },
		Save = function() end,
		IsActive = function()
			return context.Active
		end,
	}
	context.BadgeService = {
		UserHasBadgeAsync = function()
			return context.Owned
		end,
		AwardBadgeAsync = function()
			assert(player:GetAttribute("SecretCelebrationStartedAt") == nil)
			context.AwardCalls += 1

			if context.AwardFails then
				error("Simulated badge outage")
			end

			context.Owned = true
			return true
		end,
	}
	context.TeleportService = {
		TeleportAsync = function()
			context.TeleportCalls += 1

			if context.TeleportFails then
				error("Simulated teleport outage")
			end
		end,
	}
	-- Folder stands in for player attributes; no external service receives it.
	local proxy = setmetatable({ UserId = 1 }, {
		__index = function(_, key)
			return function(_, ...)
				return player[key](player, ...)
			end
		end,
	})
	context.Player = proxy
	local portal = makePortal(context)
	return context, portal, player
end

local function run(name, callback)
	local context, portal, attributes = fixture()
	local ok, problem = pcall(callback, context, portal, attributes)
	portal.Cancel()
	attributes:Destroy()
	assert(ok, name .. ": " .. tostring(problem))
	cases += 1
end

run("Badge outage is retryable without celebrating", function(context, portal, player)
	context.AwardFails = true
	portal.Enter()
	assert(player:GetAttribute("SecretReturnStatus") == "Failed")
	assert(player:GetAttribute("SecretCelebrationStartedAt") == nil)
	assert(context.TeleportCalls == 0)
	context.AwardFails = false
	context.Now += 4
	portal.Enter()
	assert(player:GetAttribute("SecretReturnStatus") == "Celebrating")
	assert(player:GetAttribute("SecretBadgeStatus") == "Confirmed")
end)

run("Already owned badge and duplicate portal entry", function(context, portal, player)
	context.Owned = true
	portal.Enter()
	local startedAt = player:GetAttribute("SecretCelebrationStartedAt")
	assert(startedAt ~= nil)
	portal.Enter()
	assert(player:GetAttribute("SecretCelebrationStartedAt") == startedAt)
	assert(context.AwardCalls == 0 and context.TeleportCalls == 0)
	portal.Finish()
	assert(context.TeleportCalls == 1)
end)

run("Teleport retry does not replay completion", function(context, portal, player)
	context.TeleportFails = true
	portal.Enter()
	portal.Finish()
	assert(player:GetAttribute("SecretReturnStatus") == "Failed")
	context.TeleportFails = false
	context.Now += 4
	portal.Enter()
	assert(player:GetAttribute("SecretReturnStatus") == "Teleporting")
	assert(player:GetAttribute("SecretCelebrationStartedAt") == nil)
	assert(context.AwardCalls == 1 and context.TeleportCalls == 2)
end)

run("Incomplete quest cannot claim badge", function(context, portal, player)
	context.Profile.Data.Completed = false
	portal.Enter()
	assert(context.AwardCalls == 0)
	assert(player:GetAttribute("SecretReturnStatus") == nil)
end)

run("Departed player cannot teleport", function(context, portal)
	portal.Enter()
	context.Active = false
	portal.Finish()
	assert(context.TeleportCalls == 0)
end)

run("Missing client acknowledgement has a bounded fallback", function(context, portal, player)
	portal.Enter()
	task.wait(5.3)
	assert(context.TeleportCalls == 1)
	assert(player:GetAttribute("SecretReturnStatus") == "Teleporting")
end)

module:Destroy()
return "Passed " .. cases .. " portal failure/retry cases with fake badge and teleport services."
