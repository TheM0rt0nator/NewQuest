local Config = require(script.Parent.Config)
local Props = require(script.Parent.Props)

local PolishSymbols = {}
local displayedSymbols = setmetatable({}, { __mode = "k" })
local PATTERNS = {
	Star = { "0001000", "0001000", "1111111", "0111110", "0011100", "0110110", "1100011" },
	Heart = { "0110110", "1111111", "1111111", "1111111", "0111110", "0011100", "0001000" },
	Triangle = { "0001000", "0001000", "0011100", "0011100", "0111110", "0111110", "1111111" },
	Circle = { "0011100", "0111110", "1111111", "1111111", "1111111", "0111110", "0011100" },
	Cross = { "1100011", "1110111", "0111110", "0011100", "0111110", "1110111", "1100011" },
	Square = { "1111111", "1111111", "1111111", "1111111", "1111111", "1111111", "1111111" },
}

function PolishSymbols.NameForColour(colour)
	local name = Config.NailSymbols[colour]
	assert(name, "Missing polish symbol: " .. colour)
	return name
end

function PolishSymbols.Set(part, colour, faces)
	local symbol = colour and PolishSymbols.NameForColour(colour) or ""

	if displayedSymbols[part] == symbol then
		return
	end

	displayedSymbols[part] = symbol

	for _, child in part:GetChildren() do
		if child:IsA("SurfaceGui") then
			child:Destroy()
		end
	end

	if symbol == "" then
		return
	end

	for _, face in faces do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "SurfaceGui"
		gui.Face = face
		gui.CanvasSize = Vector2.new(112, 112)
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.LightInfluence = 0
		gui.MaxDistance = 40
		gui.Parent = part

		local label = Instance.new("Frame")
		label.Name = "Frame"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(0.62, 0.62)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Parent = gui
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = label

		-- Static pixel shapes remain readable without a font or image asset.
		for row, pattern in PATTERNS[symbol] do
			local position = 1

			while position <= #pattern do
				local first, last = string.find(pattern, "1+", position)

				if not first then
					break
				end

				local pixels = Instance.new("Frame")
				pixels.Position = UDim2.fromScale((first + 0.5) / 10, (row + 0.5) / 10)
				pixels.Size = UDim2.fromScale((last - first + 1) / 10, 0.1)
				pixels.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
				pixels.BorderSizePixel = 0
				pixels.Parent = label
				position = last + 1
			end
		end
	end
end

function PolishSymbols.Bottle(parent, name, position, colour)
	-- Original bottle parts are rotated sideways; keep their labels upright.
	-- The visible mesh is 0.4 studs wide; leave 0.001 per face to avoid flicker.
	local anchor = Props.Part(parent, name, Vector3.new(0.402, 0.402, 0.402), CFrame.new(position))
	anchor.Transparency = 1
	anchor.CanQuery = false
	PolishSymbols.Set(anchor, colour, {
		Enum.NormalId.Front,
		Enum.NormalId.Back,
		Enum.NormalId.Left,
		Enum.NormalId.Right,
	})
	return anchor
end

return PolishSymbols
