local Props = require(script.Parent.Props)
local PrivateState = require(script.Parent.PrivateState)

local Clues = {}
local GLOW = Color3.fromRGB(255, 224, 119)
local HATS = {
	Headstack = {
		Mesh = 1072753,
		Texture = 1072754,
		Scale = 1,
		Offset = CFrame.new(0, 0.9, 0),
	},
	Fedora = {
		Mesh = 1029012,
		Texture = 6858319566,
		Scale = 1.1,
		Offset = CFrame.new(0, 0.5, -0.05),
	},
	ClassicBucket = {
		CatalogId = 17521787511,
		Mesh = 17517175653,
		Texture = 17517186420,
		Scale = 1,
		Offset = CFrame.new(0, 0.5, 0),
	},
}

local function noob(parent, name, cf, hatName)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local yellow = Color3.fromRGB(245, 205, 48)
	local blue = Color3.fromRGB(13, 105, 172)
	local green = Color3.fromRGB(164, 189, 71)
	Props.Part(model, "Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, 3, 0), blue)

	for _, side in { -1, 1 } do
		Props.Part(model, "Arm", Vector3.new(1, 2, 1), cf * CFrame.new(side * 1.5, 3, 0), yellow)
		Props.Part(model, "Leg", Vector3.new(1, 2, 1), cf * CFrame.new(side * 0.5, 1, 0), green)
	end

	local head = Props.Part(model, "Head", Vector3.new(2, 1, 1), cf * CFrame.new(0, 4.5, 0), yellow)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	local hat = HATS[hatName]

	if not hat then
		return
	end

	local handle = Props.Part(
		model,
		hatName,
		Vector3.new(1, 1, 1),
		head.CFrame * hat.Offset,
		Color3.new(1, 1, 1)
	)
	local hatMesh = Instance.new("SpecialMesh")
	hatMesh.MeshType = Enum.MeshType.FileMesh
	hatMesh.MeshId = "rbxassetid://" .. hat.Mesh
	hatMesh.TextureId = "rbxassetid://" .. hat.Texture
	hatMesh.Scale = Vector3.one * hat.Scale
	hatMesh.Parent = handle
end

function Clues.SetupVip(parent, gate)
	noob(
		parent,
		"HeadstackNoob",
		CFrame.new(-825, 315.5, 128) * CFrame.Angles(0, -0.4, 0),
		"Headstack"
	)
	noob(parent, "FedoraNoob", CFrame.new(-807, 315.5, 127) * CFrame.Angles(0, 0.6, 0), "Fedora")
	noob(
		parent,
		"ClassicEventNoob",
		CFrame.new(-819, 315.5, 124) * CFrame.Angles(0, -0.1, 0),
		"ClassicBucket"
	)

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "VipLabel" .. face.Name
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 60
		gui.Parent = gate

		gui.LightInfluence = 0
		local symbol = Instance.new("Frame")
		symbol.Name = "ProhibitionSymbol"
		symbol.AnchorPoint = Vector2.new(0.5, 0.5)
		symbol.Position = UDim2.fromScale(0.5, 0.5)
		symbol.Size = UDim2.fromScale(0.42, 0.42)
		symbol.BackgroundTransparency = 1
		symbol.Parent = gui
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = symbol
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = symbol
		local outline = Instance.new("UIStroke")
		outline.Color = Color3.fromRGB(220, 38, 38)
		outline.Thickness = 18
		outline.Parent = symbol
		local slash = Instance.new("Frame")
		slash.Name = "Slash"
		slash.AnchorPoint = Vector2.new(0.5, 0.5)
		slash.Position = UDim2.fromScale(0.5, 0.5)
		slash.Size = UDim2.fromScale(1, 0.075)
		slash.Rotation = 45
		slash.BorderSizePixel = 0
		slash.BackgroundColor3 = outline.Color
		slash.Parent = symbol
	end
end

function Clues.SetupStreetNoobs(parent)
	local crowd = Instance.new("Model")
	crowd.Name = "StreetNoobs"
	crowd.Parent = parent
	local placements = {
		{ "WindowShopper", Vector3.new(-866, 316, 126), "Fedora", 2.8 },
		{ "BeachVisitor", Vector3.new(-705, 316, 20), "Headstack", 0.8 },
		{ "CrossroadsVisitor", Vector3.new(-745, 315.5, 100), "Fedora", -1.2 },
		{ "SmoothieVisitor", Vector3.new(-699, 315.5, 123), "Headstack", -1.8 },
		{ "BakeryVisitor", Vector3.new(-594, 315.5, 128), "Fedora", 0.5 },
	}

	for _, placement in placements do
		noob(
			crowd,
			placement[1],
			CFrame.new(placement[2]) * CFrame.Angles(0, placement[4], 0),
			placement[3]
		)
	end
end

function Clues.SetupSigns(parent, building)
	local state = { Lamps = {}, Trims = {}, Originals = {} }
	local signs = Instance.new("Folder")
	signs.Name = "SignClues"
	signs.Parent = parent

	for _, gui in building:GetDescendants() do
		if not gui:IsA("SurfaceGui") or not gui:FindFirstChildWhichIsA("TextLabel", true) then
			continue
		end

		local sign = gui.Parent

		if not sign:IsA("BasePart") then
			continue
		end

		table.insert(state.Originals, {
			Gui = gui,
			Brightness = PrivateState.Remember(gui, "SecretOriginalBrightness", gui.Brightness),
			LightInfluence = PrivateState.Remember(
				gui,
				"SecretOriginalLightInfluence",
				gui.LightInfluence
			),
		})
		local cf = sign.CFrame * CFrame.new(0, 0, -sign.Size.Z / 2 - 0.04)

		for _, side in { -1, 1 } do
			local horizontal = Props.Part(
				signs,
				"GlowTrim",
				Vector3.new(sign.Size.X + 0.3, 0.18, 0.08),
				cf * CFrame.new(0, side * sign.Size.Y / 2, 0),
				GLOW
			)
			local vertical = Props.Part(
				signs,
				"GlowTrim",
				Vector3.new(0.18, sign.Size.Y, 0.08),
				cf * CFrame.new(side * sign.Size.X / 2, 0, 0),
				GLOW
			)
			table.insert(state.Trims, horizontal)
			table.insert(state.Trims, vertical)
		end

		local lamp = Props.Part(signs, "SignLamp", Vector3.new(0.2, 0.2, 0.2), cf)
		lamp.Transparency = 1
		lamp.CanQuery = false
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Front
		light.Color = GLOW
		light.Brightness = 2
		light.Range = 20
		light.Angle = 120
		light.Parent = lamp
		table.insert(state.Lamps, light)
	end

	return state
end

function Clues.HideCounterPolishes(parent)
	local decorations = {}

	for _, object in workspace:GetDescendants() do
		if not object:IsA("BasePart") then
			continue
		end

		local position = object.Position
		local onCounter = math.abs(position.Y - 320.25) < 0.05
		local blueBottle = math.abs(position.X + 762.25) < 0.05
			and (math.abs(position.Z - 177.25) < 0.05 or math.abs(position.Z - 162.25) < 0.05)
		local pinkBottle = math.abs(position.X + 762.75) < 0.05
			and (math.abs(position.Z - 176.75) < 0.05 or math.abs(position.Z - 161.75) < 0.05)

		if
			onCounter
			and (blueBottle or pinkBottle)
			and (object.Size - Vector3.new(0.5, 0.5, 0.5)).Magnitude < 0.05
		then
			decorations[object.Parent] = true
		end
	end

	for model in decorations do
		for _, part in model:GetChildren() do
			if not part:IsA("BasePart") then
				continue
			end

			for _, property in { "Transparency", "CanCollide", "CanTouch", "CanQuery" } do
				local attribute = "SecretPolishOriginal" .. property
				PrivateState.Remember(part, attribute, part[property])
			end

			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
end

function Clues.RestoreVisuals(root)
	for _, reference in root:GetDescendants() do
		if
			reference:IsA("ObjectValue")
			and reference.Name == "OriginalSignGui"
			and reference.Value
		then
			local gui = reference.Value
			gui.Brightness = gui:GetAttribute("SecretOriginalBrightness")
			gui.LightInfluence = gui:GetAttribute("SecretOriginalLightInfluence")
		elseif
			reference:IsA("ObjectValue")
			and reference.Name == "OriginalCounterPolish"
			and reference.Value
		then
			local part = reference.Value

			for _, property in { "Transparency", "CanCollide", "CanTouch", "CanQuery" } do
				part[property] = part:GetAttribute("SecretPolishOriginal" .. property)
			end
		end
	end
end

function Clues.RenderSigns(signs, active)
	if signs.Active == active then
		return
	end

	signs.Active = active

	for _, trim in signs.Trims do
		trim.Material = Enum.Material.Neon
		trim.Transparency = active and 0 or 1
		trim.CanQuery = false
	end

	for _, light in signs.Lamps do
		light.Enabled = active
	end

	for _, original in signs.Originals do
		original.Gui.Brightness = active and 3 or original.Brightness
		original.Gui.LightInfluence = active and 0 or original.LightInfluence
	end
end

return Clues
