local Config = require(script.Parent.Config)

local VipShirt = {}

function VipShirt.IsWearing(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local graphic = character and character:FindFirstChildOfClass("ShirtGraphic")

	if not humanoid or humanoid.Health <= 0 or not graphic then
		return false
	end

	local graphicId = tonumber(graphic.Graphic:match("%d+"))

	if graphicId ~= Config.VipGraphicId then
		return false
	end

	local description = humanoid:GetAppliedDescription()
	local isWearing = description.GraphicTShirt == Config.VipTShirtId
	description:Destroy()
	return isWearing
end

return VipShirt
