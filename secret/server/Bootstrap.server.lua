local Config = require(script.Parent.Config)

if game.PlaceId ~= Config.PlaceId and game.PlaceId ~= Config.TestPlaceId then
	return
end

local Players = game:GetService("Players")
local releaseTask
local joinConnection
local destroyConnection
local stopped = false

local function startWhenReleased()
	releaseTask = nil
	if stopped then
		return
	end

	local remaining = Config.OpensAt - os.time()
	if game.PlaceId == Config.PlaceId and remaining > 0 then
		releaseTask = task.delay(remaining, startWhenReleased)
		return
	end

	if joinConnection then
		joinConnection:Disconnect()
		joinConnection = nil
	end

	if destroyConnection then
		destroyConnection:Disconnect()
		destroyConnection = nil
	end

	local Service = require(script.Parent.Service)
	Service.Start()
end

if game.PlaceId == Config.PlaceId and os.time() < Config.OpensAt then
	local function rejectEarlyArrival(player)
		if os.time() < Config.OpensAt then
			player:Kick("This quest opens on 23 September at 8pm ET. Please rejoin then.")
		end
	end

	joinConnection = Players.PlayerAdded:Connect(rejectEarlyArrival)
	destroyConnection = script.Destroying:Connect(function()
		stopped = true
		joinConnection:Disconnect()
		if releaseTask then
			task.cancel(releaseTask)
			releaseTask = nil
		end
	end)
	for _, player in Players:GetPlayers() do
		rejectEarlyArrival(player)
	end
end

startWhenReleased()
