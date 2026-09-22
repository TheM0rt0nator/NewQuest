local Config = require(script.Parent.Config)

if game.PlaceId ~= Config.PlaceId then
	return
end

local Service = require(script.Parent.Service)
Service.Start()
