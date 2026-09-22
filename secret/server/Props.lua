local ServerStorage = game:GetService("ServerStorage")

local PrivateState = require(script.Parent.PrivateState)

local Props = {}
local interactions = {}
local promptStorage

function Props.Begin(storage)
	table.clear(interactions)
	promptStorage = storage
end

function Props.Interactions()
	return interactions
end

function Props.Interaction(part)
	return interactions[part]
end

function Props.SetInteractionActive(part, active)
	local binding = interactions[part]
	binding.Prompt.Enabled = active
	binding.Prompt.Parent = active and part or promptStorage

	if binding.Click then
		binding.Click.Parent = active and binding.ClickParent or promptStorage
	end
end

Props.Colours = {
	Strawberry = Color3.fromRGB(224, 58, 79),
	Banana = Color3.fromRGB(255, 217, 78),
	Milk = Color3.fromRGB(249, 246, 224),
	Blueberry = Color3.fromRGB(81, 75, 170),
	Orange = Color3.fromRGB(245, 137, 39),
	Kiwi = Color3.fromRGB(130, 184, 66),
	Pineapple = Color3.fromRGB(235, 183, 46),
	Chocolate = Color3.fromRGB(106, 63, 43),
	Pink = Color3.fromRGB(247, 139, 177),
	Blue = Color3.fromRGB(66, 154, 224),
	Yellow = Color3.fromRGB(252, 212, 83),
	Green = Color3.fromRGB(88, 180, 127),
}

function Props.Part(parent, name, size, cf, colour, shape)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Color = colour or Color3.fromRGB(243, 235, 219)
	object.Shape = shape or Enum.PartType.Block
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent

	return object
end

function Props.Cylinder(parent, name, diameter, height, cf, colour)
	return Props.Part(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		cf * CFrame.Angles(0, 0, math.pi / 2),
		colour,
		Enum.PartType.Cylinder
	)
end

function Props.Prompt(part, text, objectText, action, stageIndex)
	part:SetAttribute("Action", nil)
	part:SetAttribute("Stage", nil)
	local previous = part:FindFirstChild("SecretQuestPrompt")

	if previous then
		previous:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ProximityPrompt"
	prompt.ActionText = text
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.15
	prompt.Enabled = false
	prompt.Parent = promptStorage or ServerStorage
	interactions[part] = { Prompt = prompt, Action = action, Stage = stageIndex }

	return prompt
end

function Props.Ingredient(parent, ingredient, cf, scale)
	local model = Instance.new("Model")
	model.Name = ingredient
	model.Parent = parent
	local handle = Props.Part(model, "Handle", Vector3.new(0.2, 0.2, 0.2), cf)
	handle.Transparency = 1
	model.PrimaryPart = handle

	if ingredient == "Strawberry" then
		Props.Part(
			model,
			"Berry",
			Vector3.new(1.2, 1.2, 1.1),
			cf,
			Props.Colours.Strawberry,
			Enum.PartType.Ball
		)
		Props.Part(
			model,
			"Tip",
			Vector3.new(0.8, 0.8, 0.75),
			cf * CFrame.new(0, -0.45, 0),
			Props.Colours.Strawberry,
			Enum.PartType.Ball
		)

		for index = 1, 5 do
			local angle = index * math.pi * 2 / 5
			Props.Part(
				model,
				"Leaf",
				Vector3.new(0.22, 0.12, 0.75),
				cf
					* CFrame.new(0, 0.6, 0)
					* CFrame.Angles(0, angle, math.rad(12))
					* CFrame.new(0, 0, 0.2),
				Props.Colours.Green
			)
		end

		for index = 1, 12 do
			local angle = index * math.pi * 2 / 6
			local y = index <= 6 and 0.18 or -0.25
			Props.Part(
				model,
				"Seed",
				Vector3.new(0.07, 0.12, 0.045),
				cf
					* CFrame.new(math.sin(angle) * 0.53, y, math.cos(angle) * 0.5)
					* CFrame.Angles(0, angle, 0),
				Props.Colours.Banana
			)
		end
	elseif ingredient == "Banana" then
		for index = 1, 6 do
			local angle = math.rad(-65 + (index - 1) * 26)
			Props.Part(
				model,
				"Fruit",
				Vector3.new(0.48, 0.52, 0.48),
				cf * CFrame.new(math.sin(angle) * 0.85, -math.cos(angle) * 0.85 + 0.45, 0),
				Props.Colours.Banana,
				Enum.PartType.Ball
			)
		end

		for _, x in { -0.9, 0.9 } do
			Props.Part(
				model,
				"Stem",
				Vector3.new(0.16, 0.3, 0.2),
				cf * CFrame.new(x, 0.24, 0),
				Color3.fromRGB(103, 73, 39)
			)
		end
	elseif ingredient == "Blueberry" then
		for index = 1, 5 do
			local angle = index * math.pi * 2 / 5
			local offset =
				Vector3.new(math.sin(angle) * 0.35, (index % 2) * 0.3, math.cos(angle) * 0.35)
			Props.Part(
				model,
				"Berry",
				Vector3.new(0.65, 0.65, 0.65),
				cf * CFrame.new(offset),
				Props.Colours.Blueberry,
				Enum.PartType.Ball
			)
		end
	elseif ingredient == "Orange" then
		Props.Part(
			model,
			"Peel",
			Vector3.new(1.25, 1.2, 1.25),
			cf,
			Props.Colours.Orange,
			Enum.PartType.Ball
		)
		Props.Part(
			model,
			"Stem",
			Vector3.new(0.14, 0.18, 0.14),
			cf * CFrame.new(0, 0.62, 0),
			Color3.fromRGB(103, 73, 39)
		)
		Props.Part(
			model,
			"Leaf",
			Vector3.new(0.55, 0.08, 0.25),
			cf * CFrame.new(0.25, 0.63, 0) * CFrame.Angles(0, 0, -0.2),
			Props.Colours.Green
		)
	elseif ingredient == "Kiwi" then
		Props.Cylinder(model, "Skin", 1.25, 0.7, cf, Color3.fromRGB(137, 100, 59))
		Props.Cylinder(model, "Fruit", 1.1, 0.04, cf * CFrame.new(0, 0.37, 0), Props.Colours.Kiwi)
		Props.Cylinder(
			model,
			"Centre",
			0.35,
			0.045,
			cf * CFrame.new(0, 0.395, 0),
			Props.Colours.Milk
		)

		for index = 1, 10 do
			local angle = index * math.pi * 2 / 10
			Props.Part(
				model,
				"Seed",
				Vector3.new(0.07, 0.03, 0.12),
				cf
					* CFrame.new(math.sin(angle) * 0.35, 0.405, math.cos(angle) * 0.35)
					* CFrame.Angles(0, angle, 0),
				Color3.fromRGB(35, 30, 23)
			)
		end
	elseif ingredient == "Pineapple" then
		Props.Part(
			model,
			"Fruit",
			Vector3.new(1.05, 1.45, 1.05),
			cf,
			Props.Colours.Pineapple,
			Enum.PartType.Ball
		)

		for row = 1, 3 do
			for index = 1, 6 do
				local angle = (index + row * 0.5) * math.pi / 3
				Props.Part(
					model,
					"Rind",
					Vector3.new(0.2, 0.24, 0.06),
					cf
						* CFrame.new(
							math.sin(angle) * 0.48,
							(row - 2) * 0.32,
							math.cos(angle) * 0.48
						)
						* CFrame.Angles(0, angle, math.pi / 4),
					Color3.fromRGB(169, 129, 43)
				)
			end
		end

		for index = 1, 6 do
			Props.Part(
				model,
				"CrownLeaf",
				Vector3.new(0.2, 0.95, 0.12),
				cf
					* CFrame.Angles(0, index * math.pi / 3, 0)
					* CFrame.new(0, 0.92, 0.15)
					* CFrame.Angles(0.35, 0, 0),
				Props.Colours.Green
			)
		end
	elseif ingredient == "Chocolate" then
		Props.Part(model, "Bar", Vector3.new(0.95, 0.15, 1.35), cf, Props.Colours.Chocolate)

		for row = 1, 3 do
			for column = 1, 2 do
				Props.Part(
					model,
					"Square",
					Vector3.new(0.42, 0.18, 0.38),
					cf * CFrame.new((column - 1.5) * 0.46, 0.13, (row - 2) * 0.44),
					Props.Colours.Chocolate
				)
			end
		end
	elseif ingredient == "Milk" then
		Props.Part(model, "Carton", Vector3.new(0.85, 1.3, 0.85), cf, Props.Colours.Milk)
		Props.Part(model, "Band", Vector3.new(0.87, 0.35, 0.87), cf, Color3.fromRGB(131, 199, 223))
		Props.Part(
			model,
			"Fold",
			Vector3.new(0.8, 0.4, 0.6),
			cf * CFrame.new(0, 0.78, 0),
			Props.Colours.Milk
		)
		Props.Cylinder(
			model,
			"Cap",
			0.25,
			0.1,
			cf * CFrame.new(0.18, 1.02, 0),
			Color3.fromRGB(73, 141, 190)
		)
	else
		error("Unknown smoothie ingredient: " .. ingredient)
	end

	model:ScaleTo(scale or 1)
	PrivateState.Anonymize(model)
	return model
end

function Props.MixtureColour(ingredients)
	local total = Vector3.zero

	for _, ingredient in ingredients do
		local colour = Props.Colours[ingredient]
		total += Vector3.new(colour.R, colour.G, colour.B)
	end

	local average = total / math.max(#ingredients, 1)
	return Color3.new(average.X, average.Y, average.Z)
end

function Props.Blender(parent, cf)
	local model = Instance.new("Model")
	model.Name = "Blender"
	model.Parent = parent
	local base =
		Props.Part(model, "Base", Vector3.new(3, 1, 2.8), cf, Color3.fromRGB(184, 203, 204))
	base.Material = Enum.Material.Metal
	Props.Cylinder(
		model,
		"JugBase",
		2.4,
		0.22,
		cf * CFrame.new(0, 0.65, 0),
		Color3.fromRGB(72, 84, 91)
	)

	-- Transparent plastic keeps the mixture visible through the jug panels.
	for _, x in { -1.15, 1.15 } do
		local glass = Props.Part(
			model,
			"Glass",
			Vector3.new(0.08, 2.7, 2.3),
			cf * CFrame.new(x, 2.1, 0),
			Color3.fromRGB(197, 230, 239)
		)
		glass.Material = Enum.Material.SmoothPlastic
		glass.Transparency = 0.72
	end

	for _, z in { -1.15, 1.15 } do
		local glass = Props.Part(
			model,
			"Glass",
			Vector3.new(2.3, 2.7, 0.08),
			cf * CFrame.new(0, 2.1, z),
			Color3.fromRGB(197, 230, 239)
		)
		glass.Material = Enum.Material.SmoothPlastic
		glass.Transparency = 0.72
	end

	Props.Part(
		model,
		"HandleSide",
		Vector3.new(0.2, 1.7, 0.25),
		cf * CFrame.new(1.85, 2.1, 0),
		Color3.fromRGB(72, 84, 91)
	)

	for _, y in { 1.25, 2.95 } do
		Props.Part(
			model,
			"HandleBridge",
			Vector3.new(0.8, 0.2, 0.25),
			cf * CFrame.new(1.5, y, 0),
			Color3.fromRGB(72, 84, 91)
		)
	end

	local lid = Props.Part(
		model,
		"Lid",
		Vector3.new(2.6, 0.25, 2.6),
		cf * CFrame.new(3, 0, 0),
		Color3.fromRGB(72, 84, 91)
	)
	local centre = Props.Part(model, "Centre", Vector3.new(0.2, 0.2, 0.2), cf * CFrame.new(0, 2, 0))
	centre.Transparency = 1

	local blade = Props.Part(
		model,
		"Blade",
		Vector3.new(1.7, 0.12, 0.3),
		cf * CFrame.new(0, 0.85, 0),
		Color3.fromRGB(210, 218, 224)
	)
	blade.Material = Enum.Material.Metal
	local liquid =
		Props.Cylinder(model, "Liquid", 2.1, 1.7, cf * CFrame.new(0, 1.65, 0), Props.Colours.Pink)
	liquid.Transparency = 1

	local contents = Instance.new("Model")
	contents.Name = "Contents"
	contents.Parent = model
	local effects = Instance.new("Folder")
	effects.Name = "Effects"
	effects.Parent = model

	return model
end

return Props
