-- Executes the real bootstrap with fake players, time and scheduling.
assert(game:GetService("RunService"):IsStudio(), "Run only in Studio")

local server = game.ServerScriptService.SecretQuest
local configModule = server.Config:Clone()
configModule.Parent = game.ServerStorage
local config = require(configModule)
configModule:Destroy()
assert(config.OpensAt == DateTime.fromUniversalTime(2026, 9, 23, 19, 0, 0).UnixTimestamp)

local fixture = Instance.new("ModuleScript")
fixture.Name = "SecretReleaseTestFixture"
fixture.Source = [[
return function(context)
	local game = context.Game
	local script = context.Script
	local require = context.Require
	local task = context.Task
	local os = { time = function() return context.Now end }
]] .. server.Bootstrap.Source .. "\nend"
fixture.Parent = game.ServerStorage
local run = require(fixture)

local function signal()
	local listeners = {}
	return {
		Connect = function(_, callback)
			local connection = { Connected = true }
			function connection:Disconnect()
				self.Connected = false
			end

			table.insert(listeners, { Connection = connection, Callback = callback })
			return connection
		end,
		Fire = function(_, ...)
			for _, listener in listeners do
				if listener.Connection.Connected then
					listener.Callback(...)
				end
			end
		end,
	}
end

local function context(placeId, now)
	local state = { Now = now, Starts = 0, ServiceLoads = 0, Kicks = 0, Tasks = {} }
	local player = {
		Kick = function(_, message)
			assert(message == "This quest opens on 23 September at 8pm ET. Please rejoin then.")
			state.Kicks += 1
		end,
	}
	local players = {
		PlayerAdded = signal(),
		GetPlayers = function()
			return { player }
		end,
	}
	state.Player = player
	state.Players = players
	state.Game = {
		PlaceId = placeId,
		GetService = function(_, name)
			assert(name == "Players")
			return players
		end,
	}
	state.Script = { Parent = { Config = {}, Service = {} }, Destroying = signal() }
	state.Require = function(object)
		if object == state.Script.Parent.Config then
			return config
		end

		assert(object == state.Script.Parent.Service)
		state.ServiceLoads += 1
		return {
			Start = function()
				state.Starts += 1
			end,
		}
	end
	state.Task = {
		delay = function(seconds, callback)
			local pending = { Delay = seconds, Callback = callback }
			table.insert(state.Tasks, pending)
			return pending
		end,
		cancel = function(pending)
			pending.Cancelled = true
		end,
	}
	return state
end

local success, result = pcall(function()
	local early = context(config.PlaceId, config.OpensAt - 60)
	run(early)
	assert(early.Starts == 0 and early.ServiceLoads == 0 and early.Kicks == 1)
	assert(#early.Tasks == 1 and early.Tasks[1].Delay == 60)
	early.Players.PlayerAdded:Fire(early.Player)
	assert(early.Kicks == 2)
	-- If a callback runs early, recheck the server clock and wait again.
	early.Now = config.OpensAt - 1
	early.Tasks[1].Callback()
	assert(early.Starts == 0 and early.Tasks[2].Delay == 1)
	early.Now = config.OpensAt
	early.Players.PlayerAdded:Fire(early.Player)
	assert(early.Kicks == 2, "Arrival at release was rejected")
	early.Tasks[2].Callback()
	assert(early.Starts == 1 and early.ServiceLoads == 1)
	early.Players.PlayerAdded:Fire(early.Player)
	assert(early.Kicks == 2)

	for _, now in { config.OpensAt, config.OpensAt + 1, config.OpensAt + 86400 } do
		local released = context(config.PlaceId, now)
		run(released)
		assert(released.Starts == 1 and released.Kicks == 0 and #released.Tasks == 0)
	end

	local testing = context(config.TestPlaceId, config.OpensAt - 86400)
	run(testing)
	assert(testing.Starts == 1 and testing.Kicks == 0 and #testing.Tasks == 0)
	local unsupported = context(123, config.OpensAt + 1)
	run(unsupported)
	assert(unsupported.Starts == 0 and unsupported.ServiceLoads == 0)

	local cancelled = context(config.PlaceId, config.OpensAt - 60)
	run(cancelled)
	cancelled.Script.Destroying:Fire()
	assert(cancelled.Tasks[1].Cancelled)
	cancelled.Players.PlayerAdded:Fire(cancelled.Player)
	assert(cancelled.Kicks == 1)
	cancelled.Now = config.OpensAt
	cancelled.Tasks[1].Callback()
	assert(cancelled.Starts == 0)
	return "Passed release boundary, early arrivals, automatic opening, test bypass and cleanup checks."
end)

fixture:Destroy()
assert(success, result)
return result
