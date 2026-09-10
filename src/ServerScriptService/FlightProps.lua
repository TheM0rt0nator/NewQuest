local FlightProps = {}

local NAVY = Color3.fromRGB(35, 53, 73)
local SILVER = Color3.fromRGB(187, 196, 202)
local RUBBER = Color3.fromRGB(32, 35, 39)
local BELT = Color3.fromRGB(42, 49, 59)

local function part(parent, name, size, cf, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent

	return object
end

function FlightProps.BuildTrolley(stage)
	if stage:FindFirstChild("FoodTrolley") then
		return
	end

	local origin = stage.Galley.CFrame * CFrame.Angles(0, math.rad(-90), 0)
	local trolley = Instance.new("Model")
	trolley.Name = "FoodTrolley"
	trolley:SetAttribute("PartsVersion", 1)

	local function add(name, size, offset, color, material)
		return part(trolley, name, size, origin * offset, color, material)
	end

	local body = add("Cabinet", Vector3.new(2.34, 2.24, 1.46), CFrame.new(0, -0.2, 0), NAVY)
	trolley.PrimaryPart = body
	add("BaseBumper", Vector3.new(2.5, 0.16, 1.6), CFrame.new(0, -1.38, 0), RUBBER)

	for _, x in { -1.18, 1.18 } do
		for _, z in { -0.71, 0.71 } do
			add("CornerTrim", Vector3.new(0.07, 2.28, 0.07), CFrame.new(x, -0.2, z),
				SILVER, Enum.Material.Metal)
		end
	end

	for index = 1, 3 do
		local y = 0.45 - (index - 1) * 0.65
		add("Drawer" .. index, Vector3.new(2.13, 0.58, 0.055), CFrame.new(0, y, -0.756),
			Color3.fromRGB(60, 76, 92))
		add("DrawerHandle" .. index, Vector3.new(0.65, 0.08, 0.09),
			CFrame.new(0, y + 0.16, -0.83), SILVER, Enum.Material.Metal)
		add("DrawerLabel" .. index, Vector3.new(0.22, 0.09, 0.02),
			CFrame.new(0.77, y + 0.15, -0.8), Color3.fromRGB(227, 228, 215))
	end

	for _, x in { -0.91, 0.91 } do
		for _, z in { -0.53, 0.53 } do
			add("CasterFork", Vector3.new(0.12, 0.28, 0.3), CFrame.new(x, -1.56, z),
				SILVER, Enum.Material.Metal)
			local wheel = add("Wheel", Vector3.new(0.19, 0.56, 0.56),
				CFrame.new(x, -1.79, z), RUBBER)
			wheel.Shape = Enum.PartType.Cylinder
			local hub = add("WheelHub", Vector3.new(0.2, 0.22, 0.22),
				CFrame.new(x, -1.79, z), SILVER, Enum.Material.Metal)
			hub.Shape = Enum.PartType.Cylinder
		end
	end

	for _, x in { -1.1, 1.1 } do
		add("HandlePost", Vector3.new(0.08, 0.42, 0.08), CFrame.new(x, 1.08, 0.7),
			SILVER, Enum.Material.Metal)
		add("TraySideRail", Vector3.new(0.06, 0.16, 1.42), CFrame.new(x, 1.07, 0),
			SILVER, Enum.Material.Metal)
	end

	add("PushHandle", Vector3.new(2.24, 0.12, 0.12), CFrame.new(0, 1.28, 0.7), RUBBER)
	add("TrayBackRail", Vector3.new(2.24, 0.16, 0.06), CFrame.new(0, 1.07, 0.7),
		SILVER, Enum.Material.Metal)

	local plaque = add("AirlinePlaque", Vector3.new(1.55, 0.48, 0.035),
		CFrame.new(0, 0.18, 0.75) * CFrame.Angles(0, math.pi, 0), NAVY)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Branding"
	gui.CanvasSize = Vector2.new(620, 192)
	gui.LightInfluence = 0
	gui.Parent = plaque

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BERRY AVENUE\nAIRWAYS"
	label.TextColor3 = Color3.fromRGB(236, 229, 207)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 46
	label.Parent = gui

	stage.ServiceTray.Size = Vector3.new(2.4, 0.12, 1.5)
	stage.ServiceTray.CFrame = origin * CFrame.new(0, 0.98, 0)
	stage.ServiceTray.Color = SILVER
	stage.ServiceTray.Material = Enum.Material.Metal
	stage.Galley.Transparency = 1
	stage.Galley.CanCollide = false
	stage.Galley.CanQuery = false
	trolley.Parent = stage
end

function FlightProps.BuildMealDisplay(stage, createMeal)
	if stage.FoodTrolley:FindFirstChild("DisplayMeals") then
		return
	end

	local display = Instance.new("Folder")
	display.Name = "DisplayMeals"

	for index, name in { "Sandwich", "Salad", "Pasta" } do
		local meal = createMeal(name)
		meal:ScaleTo(meal:GetScale() * 0.55)
		meal:PivotTo(stage.ServiceTray.CFrame * CFrame.new((index - 2) * 0.76, 0.07, 0))
		meal.Parent = display
	end

	display.Parent = stage.FoodTrolley
end

function FlightProps.BuildSeatbelt(passenger)
	local existing = passenger:FindFirstChild("Seatbelt")

	if existing and existing:IsA("Model") then
		return
	end

	local torso = passenger.LowerTorso
	local belt = Instance.new("Model")
	belt.Name = "Seatbelt"
	local fastened = Instance.new("Folder")
	fastened.Name = "Fastened"
	fastened.Parent = belt
	local loose = Instance.new("Folder")
	loose.Name = "Unfastened"
	loose.Parent = belt

	local function add(parent, name, size, cf, color, material)
		local object = part(parent, name, size, torso.CFrame * cf, color, material)
		object.Anchored = false
		object.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = object
		weld.Parent = object

		return object
	end

	local halfWidth = torso.Size.X / 2
	local front = -torso.Size.Z / 2 - 0.5
	-- The seated thighs rise above the lower torso's centre. Lay the belt on
	-- their upper surface instead of passing it vertically through the legs.
	local lapHeight = math.max(passenger.LeftUpperLeg.Size.Z, passenger.RightUpperLeg.Size.Z) * 0.44

	for _, side in { -1, 1 } do
		add(fastened, "LapStrap", Vector3.new(halfWidth - 0.12, 0.055, 0.2),
			CFrame.new(side * (halfWidth + 0.12) / 2, lapHeight, front), BELT, Enum.Material.Fabric)
		local anchor = Vector3.new(side * (halfWidth + 0.06), 0.08, front + 0.65)
		local lapEdge = Vector3.new(side * (halfWidth + 0.06), lapHeight, front)
		add(belt, "SideStrap", Vector3.new(0.2, 0.055, (anchor - lapEdge).Magnitude),
			CFrame.lookAt((anchor + lapEdge) / 2, lapEdge), BELT, Enum.Material.Fabric)
		local looseFrame = CFrame.new(side * (halfWidth - 0.19), lapHeight, front - 0.12)
			* CFrame.Angles(0, math.rad(side * 45), 0)
		add(loose, "LooseStrap", Vector3.new(0.67, 0.055, 0.2), looseFrame, BELT,
			Enum.Material.Fabric)
		add(loose, side == -1 and "Buckle" or "Tongue", Vector3.new(0.22, 0.08, 0.25),
			looseFrame * CFrame.new(-side * 0.31, 0.03, 0), SILVER, Enum.Material.Metal)
	end

	add(fastened, "Buckle", Vector3.new(0.36, 0.11, 0.27),
		CFrame.new(0, lapHeight + 0.025, front), SILVER, Enum.Material.Metal)
	add(fastened, "LiftLatch", Vector3.new(0.23, 0.025, 0.16),
		CFrame.new(0, lapHeight + 0.09, front), Color3.fromRGB(222, 226, 228), Enum.Material.Metal)
	add(fastened, "LatchSlot", Vector3.new(0.13, 0.01, 0.024),
		CFrame.new(0, lapHeight + 0.11, front - 0.05), RUBBER)

	if existing then
		existing:Destroy()
	end

	belt.Parent = passenger
	FlightProps.SetSeatbelt(passenger, true)
end

function FlightProps.SetSeatbelt(passenger, fastened)
	local belt = passenger.Seatbelt

	for _, folder in { belt.Fastened, belt.Unfastened } do
		local visible = (folder.Name == "Fastened") == fastened

		for _, object in folder:GetChildren() do
			if object:IsA("BasePart") then
				object.Transparency = visible and 0 or 1
			end
		end
	end

	belt:SetAttribute("Fastened", fastened)
end

return FlightProps
