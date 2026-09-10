local ServerStorage = game:GetService("ServerStorage")

local DoctorProps = {}
local METAL = Color3.fromRGB(190, 201, 207)
local WHITE = Color3.fromRGB(236, 241, 238)
local TEAL = Color3.fromRGB(73, 156, 169)
local DARK = Color3.fromRGB(43, 53, 61)

local function part(parent, name, size, cf, color, material, shape)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.Shape = shape or Enum.PartType.Block
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Massless = true
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent

	return object
end

local function createItem(taskId)
	local template = ServerStorage.DoctorToolTemplates:FindFirstChild(taskId)

	if template then
		local item = template:Clone()
		item.Name = "Item"

		return item
	end

	local item = Instance.new("Model")
	item.Name = "Item"

	local function add(name, size, cf, color, material, shape)
		return part(item, name, size, cf, color, material, shape)
	end

	if taskId == "Scalpel" then
		item.PrimaryPart = add("Handle", Vector3.new(1.15, 0.1, 0.19), CFrame.new(), METAL,
			Enum.Material.Metal)
		add("Blade", Vector3.new(0.55, 0.035, 0.16), CFrame.new(0.8, 0, 0), WHITE,
			Enum.Material.Metal)
		local tip = Instance.new("WedgePart")
		tip.Name = "BladeTip"
		tip.Size = Vector3.new(0.035, 0.16, 0.25)
		tip.CFrame = CFrame.new(1.2, 0, 0) * CFrame.Angles(0, math.pi / 2, math.pi / 2)
		tip.Color = WHITE
		tip.Material = Enum.Material.Metal
		tip.Anchored = true
		tip.CanCollide = false
		tip.CanTouch = false
		tip.CanQuery = false
		tip.Massless = true
		tip.Parent = item

		for index = 1, 7 do
			add("GripGroove", Vector3.new(0.025, 0.012, 0.16),
				CFrame.new(-0.45 + index * 0.1, 0.055, 0), DARK)
		end
	elseif taskId == "Injection" then
		local barrel = add("Handle", Vector3.new(0.95, 0.25, 0.25), CFrame.new(), WHITE,
			Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		barrel.Transparency = 0.35
		item.PrimaryPart = barrel
		add("Medicine", Vector3.new(0.62, 0.16, 0.16), CFrame.new(0.12, 0, 0), TEAL,
			Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("Plunger", Vector3.new(0.45, 0.07, 0.07), CFrame.new(-0.66, 0, 0), METAL,
			Enum.Material.Metal, Enum.PartType.Cylinder)
		add("ThumbPad", Vector3.new(0.07, 0.3, 0.3), CFrame.new(-0.91, 0, 0), TEAL,
			Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("FingerFlange", Vector3.new(0.06, 0.12, 0.45), CFrame.new(-0.47, 0, 0), WHITE)
		add("NeedleHub", Vector3.new(0.19, 0.14, 0.14), CFrame.new(0.55, 0, 0), TEAL,
			Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("Needle", Vector3.new(0.5, 0.025, 0.025), CFrame.new(0.88, 0, 0), METAL,
			Enum.Material.Metal, Enum.PartType.Cylinder)

		for index = 1, 6 do
			add("Graduation", Vector3.new(0.02, 0.015, index % 2 == 0 and 0.13 or 0.08),
				CFrame.new(-0.35 + index * 0.1, 0.127, 0), DARK)
		end
	elseif taskId == "BloodBag" then
		item.PrimaryPart = add("Handle", Vector3.new(0.88, 0.16, 1.25), CFrame.new(), WHITE)
		add("BloodReservoir", Vector3.new(0.75, 0.08, 0.94), CFrame.new(0, 0.1, 0.06),
			Color3.fromRGB(145, 39, 58))
		add("Label", Vector3.new(0.48, 0.015, 0.52), CFrame.new(0, 0.15, 0), WHITE)
		add("LabelStripe", Vector3.new(0.4, 0.01, 0.07), CFrame.new(0, 0.165, -0.13), TEAL)

		for index = 1, 8 do
			add("Barcode", Vector3.new(0.015, 0.01, 0.12),
				CFrame.new(-0.15 + index * 0.035, 0.165, 0.12), DARK)
		end

		for _, x in { -0.2, 0.2 } do
			add("Port", Vector3.new(0.22, 0.12, 0.12),
				CFrame.new(x, 0, 0.7) * CFrame.Angles(0, math.pi / 2, 0), TEAL,
				Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
	else
		error("Unknown doctor supply: " .. taskId)
	end

	return item
end

function DoctorProps.Polish(stage)
	local board = stage:FindFirstChild("TaskBoard")

	if board then
		board:Destroy()
	end

	for _, station in stage.Supplies:GetChildren() do
		if station:GetAttribute("PropsVersion") == 1 then
			continue
		end

		local tray = station.Tray
		local origin = tray.CFrame
		tray.Material = Enum.Material.Metal
		tray.Color = METAL
		tray.Reflectance = 0.12
		tray.Size = Vector3.new(2.7, 0.1, 1.6)
		station.Stand:Destroy()
		station.Base:Destroy()
		station.Item:Destroy()
		local frame = Instance.new("Model")
		frame.Name = "TrayStand"
		frame.Parent = station

		local function add(name, size, offset, color, material, shape)
			return part(frame, name, size, origin * offset, color, material, shape)
		end

		for _, x in { -1.31, 1.31 } do
			add("TrayRim", Vector3.new(0.08, 0.16, 1.6), CFrame.new(x, 0.09, 0),
				METAL, Enum.Material.Metal)
		end

		for _, z in { -0.76, 0.76 } do
			add("TrayRim", Vector3.new(2.54, 0.16, 0.08), CFrame.new(0, 0.09, z),
				METAL, Enum.Material.Metal)
		end

		add("SterileLiner", Vector3.new(2.25, 0.012, 1.2), CFrame.new(0, 0.057, 0),
			Color3.fromRGB(182, 216, 218), Enum.Material.Fabric)
		add("UpperColumn", Vector3.new(1.5, 0.13, 0.13),
			CFrame.new(0, -0.8, 0) * CFrame.Angles(0, 0, math.pi / 2), METAL,
			Enum.Material.Metal, Enum.PartType.Cylinder)
		add("LowerColumn", Vector3.new(1.35, 0.22, 0.22),
			CFrame.new(0, -2.05, 0) * CFrame.Angles(0, 0, math.pi / 2), METAL,
			Enum.Material.Metal, Enum.PartType.Cylinder)
		add("HeightClamp", Vector3.new(0.17, 0.34, 0.34),
			CFrame.new(0, -1.48, 0) * CFrame.Angles(0, 0, math.pi / 2), DARK,
			Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("ClampKnob", Vector3.new(0.14, 0.18, 0.18), CFrame.new(0.23, -1.48, 0), DARK)
		add("CrossBase", Vector3.new(2.2, 0.12, 0.22), CFrame.new(0, -2.7, 0),
			METAL, Enum.Material.Metal)

		for _, x in { -0.98, 0.98 } do
			add("BaseLeg", Vector3.new(0.16, 0.12, 1.22), CFrame.new(x, -2.7, 0),
				METAL, Enum.Material.Metal)

			for _, z in { -0.51, 0.51 } do
				add("Caster", Vector3.new(0.13, 0.32, 0.32), CFrame.new(x, -2.94, z),
					DARK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
				add("WheelFork", Vector3.new(0.09, 0.18, 0.13), CFrame.new(x, -2.82, z),
					METAL, Enum.Material.Metal)
			end
		end

		local item = createItem(station.Name)
		item:PivotTo(CFrame.new())

		if station.Name == "Medicine" or station.Name == "Bandage" then
			item:PivotTo(CFrame.Angles(0, 0, math.pi / 2))
		end

		local minimum = Vector3.new(math.huge, math.huge, math.huge)
		local maximum = -minimum

		for _, object in item:GetDescendants() do
			if object:IsA("BasePart") then
				for _, x in { -0.5, 0.5 } do
					for _, y in { -0.5, 0.5 } do
						for _, z in { -0.5, 0.5 } do
							local corner = object.CFrame * (object.Size * Vector3.new(x, y, z))
							minimum = minimum:Min(corner)
							maximum = maximum:Max(corner)
						end
					end
				end
			end
		end

		local center = (minimum + maximum) / 2
		local offset = Vector3.new(-center.X, -minimum.Y + 0.08, -center.Z)
		item:PivotTo(origin * CFrame.new(offset) * item:GetPivot())
		item.Parent = station
		station:SetAttribute("PropsVersion", 1)
	end
end

return DoctorProps
