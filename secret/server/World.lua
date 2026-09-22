local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(script.Parent.Config)
local Clues = require(script.Parent.Clues)
local PolishSymbols = require(script.Parent.PolishSymbols)
local Props = require(script.Parent.Props)
local PrivateState = require(script.Parent.PrivateState)

local World = {}
local currentWorld

local function findMannequins()
	local models = {}

	for _, model in workspace:GetChildren() do
		local torso = model:IsA("Model") and model:FindFirstChild("Torso")

		if
			torso
			and torso.Position.X > -890
			and torso.Position.X < -860
			and math.abs(torso.Position.Z - 153.5) < 0.2
		then
			table.insert(models, model)
		end
	end

	table.sort(models, function(a, b)
		return a.Torso.Position.X < b.Torso.Position.X
	end)

	assert(#models == Config.MannequinCount, "Expected the four original shop-window mannequins")
	return models
end

local function setupMannequins(parent, state)
	state.Mannequins = {}
	for index, model in findMannequins() do
		local original = PrivateState.Remember(model, "SecretOriginalPivot", model:GetPivot())
		local rest = CFrame.new(original.Position)
		model:SetAttribute("SecretRest", nil)
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		state.Mannequins[index] = { Model = model, Rest = rest }

		for _, object in model:GetDescendants() do
			if object:IsA("BasePart") then
				object.Anchored = true
			end
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.RequiresNeck = false
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end

		local head = model:FindFirstChild("Head")

		if not head then
			head = Props.Part(
				model,
				"Head",
				Vector3.new(2, 1, 1),
				model.Torso.CFrame * CFrame.new(0, 1.5, 0),
				model.Torso.Color
			)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = head
			local face = Instance.new("Decal")
			face.Name = "face"
			face.Face = Enum.NormalId.Front
			face.Texture = "rbxasset://textures/face.png"
			face.Parent = head
		end

		Props.Prompt(model.Torso, "Turn", "Window mannequin", tostring(index), 2)

		-- A sun motif on the front of each plinth hints at the shared direction.
		local sun = Props.Part(
			parent,
			"SunMedallion",
			Vector3.new(0.75, 0.75, 0.12),
			CFrame.new(original.Position.X, 317.5, 151.45),
			Props.Colours.Yellow,
			Enum.PartType.Ball
		)
		sun.CanQuery = false
	end
end

local function setupSmoothie(parent, origin, state)
	state.Ingredients = {}
	local counter = Props.Part(
		parent,
		"Counter",
		Vector3.new(20, 0.5, 4.5),
		origin * CFrame.new(0, 2.5, 0),
		Color3.fromRGB(225, 211, 184)
	)
	counter.CanCollide = true

	for _, x in { -8, 8 } do
		local leg = Props.Part(
			parent,
			"CounterLeg",
			Vector3.new(0.6, 2.5, 3.5),
			origin * CFrame.new(x, 1.25, 0),
			Color3.fromRGB(163, 144, 117)
		)
		leg.CanCollide = true
	end

	for index, name in Config.SmoothieIngredients do
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local cf = origin * CFrame.new(-8 + column * 2.6, 2.85, (row - 0.5) * 2.2)
		Props.Cylinder(parent, "IngredientTray", 1.9, 0.15, cf, Color3.fromRGB(244, 240, 225))
		local ingredient = Props.Ingredient(parent, name, cf, 0.8)
		local bounds, size = ingredient:GetBoundingBox()
		local bottom = bounds.Position.Y - size.Y / 2
		ingredient:PivotTo(ingredient:GetPivot() + Vector3.new(0, cf.Y + 0.075 - bottom, 0))
		Props.Prompt(ingredient.PrimaryPart, "Pick up", name, "Pick:" .. name, 4)
		state.Ingredients[name] = ingredient
	end

	local blender = Props.Blender(parent, origin * CFrame.new(5, 3.2, 0))
	state.Blender = { Model = blender }

	for _, object in blender:GetChildren() do
		state.Blender[object.Name] = object
	end
	Props.Prompt(blender.Centre, "Add ingredient", "Blender jug", "Deposit", 4)
	local blend = Props.Part(
		parent,
		"BlendButton",
		Vector3.new(0.6, 0.4, 0.3),
		origin * CFrame.new(4.4, 3.15, -1.5),
		Props.Colours.Green
	)
	Props.Prompt(blend, "Blend", "Blender", "Blend", 4)
	local reset = Props.Part(
		parent,
		"ResetButton",
		Vector3.new(0.6, 0.4, 0.3),
		origin * CFrame.new(5.6, 3.15, -1.5),
		Props.Colours.Strawberry
	)
	Props.Prompt(reset, "Empty jug", "Blender", "Reset", 4)
	Props.Interaction(reset).Prompt.KeyboardKeyCode = Enum.KeyCode.R
	Props.Interaction(reset).Prompt.GamepadKeyCode = Enum.KeyCode.ButtonY

	state.BlendButton = blend
	state.ResetButton = reset

	-- Matching cups make the small forward offset the selection clue.
	local samples = {
		{ Name = "Berry", Colour = Props.Colours.Blueberry, Fruits = { "Blueberry", "Banana" } },
		{ Name = "Banana", Colour = Props.Colours.Banana, Fruits = { "Banana", "Pineapple" } },
		{ Name = "Strawberry", Colour = Props.Colours.Pink, Fruits = { "Strawberry", "Banana" } },
		{
			Name = "MixedBerry",
			Colour = Props.Colours.Strawberry,
			Fruits = { "Strawberry", "Blueberry" },
		},
		{ Name = "Orange", Colour = Props.Colours.Orange, Fruits = { "Orange", "Banana" } },
		{ Name = "Kiwi", Colour = Props.Colours.Kiwi, Fruits = { "Kiwi", "Pineapple" } },
		{
			Name = "Pineapple",
			Colour = Props.Colours.Pineapple,
			Fruits = { "Pineapple", "Orange" },
		},
		{
			Name = "Chocolate",
			Colour = Props.Colours.Chocolate,
			Fruits = { "Chocolate", "Banana" },
		},
	}
	local display = Instance.new("Model")
	display.Name = "SampleSmoothies"
	display.Parent = parent

	for index, recipe in samples do
		local sample = Instance.new("Model")
		sample.Name = recipe.Name
		sample.Parent = display
		local forwardOffset = recipe.Name == "Strawberry" and -0.6 or 0
		local cf = Config.SmoothieSample * CFrame.new((index - 4.5) * 1.6, 0, forwardOffset)
		local drink =
			Props.Cylinder(sample, "Drink", 0.9, 1.5, cf * CFrame.new(0, 0.75, 0), recipe.Colour)
		drink.Material = Enum.Material.SmoothPlastic
		Props.Cylinder(sample, "Cream", 0.85, 0.12, cf * CFrame.new(0, 1.53, 0), Props.Colours.Milk)
		Props.Part(
			sample,
			"Straw",
			Vector3.new(0.07, 0.65, 0.07),
			cf * CFrame.new(-0.2, 1.7, 0.1) * CFrame.Angles(0, 0, math.rad(12)),
			Color3.fromRGB(247, 239, 220)
		)

		for fruitIndex, fruit in recipe.Fruits do
			local garnish = Props.Ingredient(
				sample,
				fruit,
				cf * CFrame.new((fruitIndex - 1.5) * 0.55, 1.55, -0.05),
				0.24
			)
			garnish.Name = "Garnish" .. fruitIndex
		end
	end
end

local function findShelfPolishes()
	local bottles = {}

	for _, model in workspace:GetChildren() do
		if not model:IsA("Model") then
			continue
		end

		for _, part in model:GetChildren() do
			if
				part:IsA("BasePart")
				and math.abs(part.Position.X + 777.5) < 0.2
				and math.abs(part.Position.Y - 321.75) < 3
				and math.abs(part.Position.Z - 175.25) < 5
				and (part.Size - Vector3.new(0.5, 0.5, 0.5)).Magnitude < 0.1
				and part.BrickColor.Name ~= "Black"
			then
				table.insert(bottles, part)
			end
		end
	end

	table.sort(bottles, function(a, b)
		if math.abs(a.Position.Y - b.Position.Y) > 0.1 then
			return a.Position.Y < b.Position.Y
		end

		return a.Position.Z < b.Position.Z
	end)

	assert(#bottles == 15, "Expected the nail salon's fifteen original shelf polishes")
	return bottles
end

local function setupPolish(parent, state)
	state.CodeLights = {}
	Clues.HideCounterPolishes(parent)

	for index, bottle in findShelfPolishes() do
		local model = bottle.Parent
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		local action = "Polish:" .. bottle.BrickColor.Name
		local symbol = PolishSymbols.NameForColour(bottle.BrickColor.Name)
		Props.Prompt(bottle, "Choose polish", "Nail polish - " .. symbol, action, 3)
		PolishSymbols.Bottle(parent, "ShelfLabel" .. index, bottle.Position, bottle.BrickColor.Name)
		local binding = Props.Interaction(bottle)
		binding.Click = Instance.new("ClickDetector")
		binding.Click.MaxActivationDistance = 10
		binding.Click.Parent = state.Storage
		binding.ClickParent = model
	end

	-- Read these separate bottles left to right while facing in from the door.
	local bottles = findShelfPolishes()

	for index, colour in Config.NailCode do
		local template

		for _, bottle in bottles do
			if bottle.BrickColor.Name == colour then
				template = bottle
				break
			end
		end

		assert(template, "Missing a shelf polish for the colour clue: " .. colour)
		local clue = template.Parent:Clone()
		clue.Name = "Model"

		for _, object in clue:GetDescendants() do
			if object:IsA("ProximityPrompt") or object:IsA("ClickDetector") then
				object:Destroy()
			elseif object:IsA("BasePart") then
				object:SetAttribute("Action", nil)
				object:SetAttribute("Stage", nil)
				object.CanTouch = false
				object.CanCollide = false
			end
		end

		local target = CFrame.new(Config.NailCluePositions[index] + Vector3.new(0, 0.25, 0))
			* template.CFrame.Rotation
		local pivotOffset = template.CFrame:ToObjectSpace(template.Parent:GetPivot())
		clue:PivotTo(target * pivotOffset)
		clue.Parent = parent
		PolishSymbols.Bottle(parent, "ClueLabel" .. index, target.Position, colour)
	end

	-- Five lights record the input without revealing which prefixes are right.
	Props.Part(
		parent,
		"CodeDisplay",
		Vector3.new(3.2, 0.2, 0.65),
		CFrame.new(-777, 318.45, 175.25) * CFrame.Angles(0, -math.pi / 2, 0),
		Color3.fromRGB(35, 33, 39)
	)

	for index = 1, #Config.NailCode do
		state.CodeLights[index] = Props.Part(
			parent,
			"CodeLight" .. index,
			Vector3.new(0.1, 0.3, 0.4),
			CFrame.new(-776.64, 318.48, 175.25 + (3 - index) * 0.55),
			Color3.fromRGB(50, 50, 50)
		)
	end
end

local function removeOldScene()
	local existing = workspace:FindFirstChild("SecretQuest")

	if not existing then
		return
	end

	Clues.RestoreVisuals(existing)

	for _, reference in existing:GetDescendants() do
		if not reference:IsA("ObjectValue") or not reference.Value then
			continue
		end

		local object = reference.Value

		if reference.Name == "OriginalDoor" then
			object.CanCollide = object:GetAttribute("SecretOriginalCanCollide") == true
		elseif reference.Name:match("^Mannequin") or reference.Name:match("^PolishBottle") then
			local model = object:IsA("Model") and object or object.Parent

			for _, child in model:GetDescendants() do
				if child.Name == "SecretQuestPrompt" or child.Name == "SecretQuestClick" then
					child:Destroy()
				end
			end
		end
	end

	existing:Destroy()
end

function World.Build()
	if currentWorld and currentWorld.Storage.Parent then
		return currentWorld
	end

	removeOldScene()
	for _, object in workspace:GetDescendants() do
		for _, key in
			{ "SecretOriginalAnchored", "SecretOriginalDisabled", "SecretOriginalEnabled" }
		do
			local previous = object:GetAttribute(key)
			if previous ~= nil then
				PrivateState.Remember(object, key, previous)
			end
		end
	end

	local previous = ServerStorage:FindFirstChild("SecretQuestAssets")

	if previous then
		previous:Destroy()
	end

	local storage = Instance.new("Folder")
	storage.Name = "SecretQuestAssets"
	storage.Parent = ServerStorage
	local root = Instance.new("Model")
	root.Name = "Model"
	root.Parent = storage
	local prompts = Instance.new("Folder")
	prompts.Name = "Interactions"
	prompts.Parent = storage
	Props.Begin(prompts)
	local world = { Storage = storage, Container = root, Stages = {}, VipOpen = false }

	for index, config in Config.Stages do
		local model = Instance.new("Model")
		model.Name = "Model"
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model.Parent = storage
		local stage = { Model = model, Doors = {}, Storage = prompts }
		world.Stages[index] = stage
		local gate = Props.Part(
			root,
			"Part",
			Vector3.new(config.GateWidth, 10, 0.35),
			config.Gate,
			Props.Colours.Yellow
		)
		gate.Transparency = 0.55
		gate.CanCollide = true
		stage.Gate = gate
		stage.Signs = Clues.SetupSigns(model, workspace.Buildings[config.Key])

		for _, original in workspace.Buildings[config.Key]:GetDescendants() do
			if original:IsA("BasePart") and (original.Position - gate.Position).Magnitude < 3 then
				PrivateState.Remember(original, "SecretOriginalCanCollide", original.CanCollide)
				table.insert(stage.Doors, original)
			end
		end

		if config.Kind == "VIP" then
			gate.CanTouch = true
			Clues.SetupVip(model, gate)
		elseif config.Kind == "Mannequins" then
			setupMannequins(model, stage)
		elseif config.Kind == "Colour" then
			setupPolish(model, stage)
		elseif config.Kind == "Smoothie" then
			setupSmoothie(model, config.Origin, stage)
		end

		PrivateState.Anonymize(model)
	end

	Clues.SetupStreetNoobs(root)
	local portalModel = Instance.new("Model")
	portalModel.Parent = storage
	portalModel.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	world.PortalModel = portalModel
	local portal =
		Props.Part(portalModel, "Part", Vector3.new(9, 12, 1), Config.Portal, Props.Colours.Blue)
	portal.CanTouch = true
	portal.Material = Enum.Material.Neon
	Props.Prompt(portal, "Return", "Berry Avenue", "Return", 5)
	world.Portal = portal

	for _, x in { -5.5, 5.5 } do
		Props.Part(
			portalModel,
			"Part",
			Vector3.new(2, 13, 2),
			Config.Portal * CFrame.new(x, 0, 0),
			Props.Colours.Yellow
		)
	end

	Props.Part(
		portalModel,
		"Part",
		Vector3.new(13, 2, 2),
		Config.Portal * CFrame.new(0, 7, 0),
		Props.Colours.Yellow
	)
	PrivateState.Anonymize(portalModel)
	PrivateState.Anonymize(root)
	currentWorld = world
	return world
end

function World.Interactions()
	return Props.Interactions()
end

function World.Current()
	return currentWorld
end

local function setGateOpen(stage, isOpen, isVip)
	stage.Gate.CanCollide = not isOpen
	stage.Gate.Transparency = isOpen and (isVip and 0.75 or 1) or 0.55

	for _, door in stage.Doors do
		door.CanCollide = not isOpen
	end
end

function World.SetVipDoorOpen(world, isOpen)
	world.VipOpen = isOpen
	setGateOpen(world.Stages[1], isOpen, true)
end

function World.Render(world, data)
	local running = RunService:IsRunning()
	world.Container.Parent = running and workspace or world.Storage

	for index, stage in world.Stages do
		local unlocked = running and index <= data.Stage
		stage.Model.Parent = unlocked and world.Container or world.Storage
		Clues.RenderSigns(stage.Signs, running and index == data.Stage)
		setGateOpen(
			stage,
			index == 1 and world.VipOpen or index > 1 and index <= data.Stage,
			index == 1
		)
	end

	for object, binding in Props.Interactions() do
		Props.SetInteractionActive(object, running and binding.Stage == data.Stage)
	end

	for index, light in world.Stages[3].CodeLights do
		local colour = data.Stage > 3 and Config.NailCode[index]
			or data.Stage == 3 and data.Values.Code and data.Values.Code[index]
		light.Color = colour and BrickColor.new(colour).Color or Color3.fromRGB(50, 50, 50)
		light.Material = colour and Enum.Material.Neon or Enum.Material.SmoothPlastic
		PolishSymbols.Set(light, colour, { Enum.NormalId.Right })
	end

	for index, mannequin in world.Stages[2].Mannequins do
		local initial = Config.MannequinInitialTurns[index]
		local turns = data.Stage > 2 and 0
			or data.Stage == 2 and (data.Values[tostring(index)] or initial)
			or initial
		mannequin.Model:PivotTo(mannequin.Rest * CFrame.Angles(0, turns * math.pi / 2, 0))
	end

	world.PortalModel.Parent = running and data.Completed and world.Container or world.Storage
	world.Portal.Transparency = 0.25
end

function World.Hide(world)
	world.Container.Parent = world.Storage

	for _, stage in world.Stages do
		Clues.RenderSigns(stage.Signs, false)
	end

	for object in Props.Interactions() do
		Props.SetInteractionActive(object, false)
	end
end

return World
