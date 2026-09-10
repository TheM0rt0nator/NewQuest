local PoliceProps = {}
local METAL = Color3.fromRGB(173, 188, 200)
local DARK = Color3.fromRGB(32, 43, 55)
local GREEN = Color3.fromRGB(67, 205, 176)

local function part(parent, name, size, cf, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Color = color
	object.Material = material or Enum.Material.Metal
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

local function weld(object, body)
	object.Anchored = false
	local joint = Instance.new("WeldConstraint")
	joint.Part0 = body
	joint.Part1 = object
	joint.Parent = object
end

function PoliceProps.Install(stage)
	if stage:GetAttribute("PropsVersion") == 1 then
		return
	end

	local suspect = stage.Suspect

	for _, object in suspect:GetChildren() do
		if object.Name == "RightHandCuff" or object.Name == "LeftHandCuff" or object:IsA("Beam") then
			object:Destroy()
		end
	end

	-- The MQ tool is a single rigid pair. Individual wearable bands fit this rig's
	-- wider wrists while keeping the established cuff pose and walk animation.
	local cuffs = Instance.new("Model")
	cuffs.Name = "Handcuffs"
	cuffs.Parent = suspect
	local chainEnds = {}

	for _, side in { "Right", "Left" } do
		local hand = suspect[side .. "Hand"]
		local origin = hand.CFrame * CFrame.new(0, hand.Size.Y / 2, 0)
		local radiusX = hand.Size.X / 2 + 0.055
		local radiusZ = hand.Size.Z / 2 + 0.055

		for index = 1, 20 do
			local angle = index * math.pi / 10
			local nextAngle = (index + 1) * math.pi / 10
			local a = Vector3.new(math.cos(angle) * radiusX, 0, math.sin(angle) * radiusZ)
			local b = Vector3.new(math.cos(nextAngle) * radiusX, 0, math.sin(nextAngle) * radiusZ)
			local band = part(cuffs, side .. "Band", Vector3.new(0.08, 0.15, (b - a).Magnitude),
				origin * CFrame.lookAt((a + b) / 2, b), METAL)
			weld(band, hand)
		end

		local lock = part(cuffs, side .. "Lock", Vector3.new(0.25, 0.2, 0.22),
			origin * CFrame.new(0, 0, -radiusZ), METAL)
		weld(lock, hand)
		local slot = part(cuffs, "Keyhole", Vector3.new(0.045, 0.075, 0.012),
			lock.CFrame * CFrame.new(0, 0, -0.115), DARK)
		weld(slot, hand)
		local posed = suspect.UpperTorso.CFrame

		for _, name in { "Shoulder", "Elbow", "Wrist" } do
			local joint = suspect:FindFirstChild(side .. name, true)
			local c0 = joint:IsA("Motor6D") and joint.C0 or joint.Attachment0.CFrame
			local c1 = joint:IsA("Motor6D") and joint.C1 or joint.Attachment1.CFrame
			local transform = name == "Shoulder"
				and CFrame.Angles(math.rad(55), 0, math.rad(side == "Right" and -30 or 30))
				or CFrame.identity
			posed = posed * c0 * transform * c1:Inverse()
		end

		chainEnds[side] = posed * Vector3.new(0, hand.Size.Y / 2, -radiusZ - 0.13)
	end

	local chainFrame = CFrame.lookAt(chainEnds.Left, chainEnds.Right)
	local distance = (chainEnds.Left - chainEnds.Right).Magnitude
	local links = math.max(3, math.ceil(distance / 0.18))

	for index = 0, links - 1 do
		local center = chainFrame * CFrame.new(0, 0, -distance * (index + 0.5) / links)
		center *= CFrame.Angles(0, 0, index % 2 * math.pi / 2)

		for segment = 0, 11 do
			local a = segment * math.pi / 6
			local b = (segment + 1) * math.pi / 6
			local p0 = Vector3.new(math.cos(a) * 0.065, 0, math.sin(a) * 0.13)
			local p1 = Vector3.new(math.cos(b) * 0.065, 0, math.sin(b) * 0.13)
			local link = part(cuffs, "ChainLink", Vector3.new(0.035, 0.035, (p1 - p0).Magnitude),
				center * CFrame.lookAt((p0 + p1) / 2, p1), METAL)
			weld(link, suspect.UpperTorso)
		end
	end

	local scanner = stage.Scanner
	local origin = scanner.CFrame
	scanner.Size = Vector3.new(1.7, 0.3, 1.9)
	scanner.Color = DARK
	scanner.Material = Enum.Material.SmoothPlastic
	stage.Stations.Fingerprint.Transparency = 1
	local housing = Instance.new("Model")
	housing.Name = "ScannerDetails"
	housing.Parent = stage

	local function add(name, size, cf, color, material)
		return part(housing, name, size, origin * cf, color, material)
	end

	add("EquipmentShelf", Vector3.new(3.8, 0.1, 2.05), CFrame.new(-0.9, -0.2, 0), DARK)
	add("Pedestal", Vector3.new(0.22, 3.02, 0.22), CFrame.new(-0.9, -1.76, 0), METAL)
	add("PedestalBase", Vector3.new(2.7, 0.11, 1.65), CFrame.new(-0.9, -3.32, 0), DARK)

	add("LowerTrim", Vector3.new(1.73, 0.06, 1.93), CFrame.new(0, -0.13, 0), METAL)
	add("GlassBezel", Vector3.new(1.17, 0.045, 1.2), CFrame.new(0, 0.17, 0.18), METAL)
	stage.ScannerGlass.Size = Vector3.new(1.02, 0.025, 1.05)
	stage.ScannerGlass.CFrame = origin * CFrame.new(0, 0.2, 0.18)
	stage.ScannerGlass.Color = Color3.fromRGB(24, 86, 86)
	stage.ScannerGlass.Material = Enum.Material.Glass
	stage.ScannerGlass.Transparency = 0.1

	-- Raised fingerprint ridges form a readable graphic without a new texture asset.
	for ring = 1, 5 do
		for index = 0, 15 do
			local angle = index * math.pi / 10
			local nextAngle = (index + 1) * math.pi / 10
			local a = Vector3.new(math.cos(angle) * ring * 0.075, 0.218,
				0.18 + math.sin(angle) * ring * 0.085)
			local b = Vector3.new(math.cos(nextAngle) * ring * 0.075, 0.218,
				0.18 + math.sin(nextAngle) * ring * 0.085)
			add("PrintRidge", Vector3.new(0.012, 0.007, (b - a).Magnitude),
				CFrame.lookAt((a + b) / 2, b), GREEN, Enum.Material.Neon)
		end
	end

	add("StatusPanel", Vector3.new(1.2, 0.04, 0.24), CFrame.new(0, 0.17, -0.66),
		Color3.fromRGB(12, 24, 32), Enum.Material.SmoothPlastic)
	add("ReadyLight", Vector3.new(0.16, 0.018, 0.07), CFrame.new(-0.4, 0.2, -0.66),
		GREEN, Enum.Material.Neon)
	for index = 1, 3 do
		add("StatusBar", Vector3.new(0.12, 0.018, 0.035),
			CFrame.new(-0.1 + index * 0.17, 0.2, -0.66), METAL)
	end

	for _, x in { -0.72, 0.72 } do
		for _, z in { -0.81, 0.81 } do
			local screw = add("CaseScrew", Vector3.new(0.035, 0.055, 0.055),
				CFrame.new(x, 0.166, z) * CFrame.Angles(0, 0, math.pi / 2), METAL)
			screw.Shape = Enum.PartType.Cylinder
		end
	end

	local spare = game.ServerStorage.PolicePropTemplates.Cuffs:Clone()
	spare.Name = "BookingCuffs"
	spare:ScaleTo(0.7)
	spare:PivotTo(origin * CFrame.new(-1.75, -0.05, 0) * CFrame.Angles(math.pi / 2, 0, 0))
	spare.Parent = housing
	stage:SetAttribute("PropsVersion", 1)
end

return PoliceProps
