-- Run in Studio Edit mode to rebuild only the quest's classroom cast and markers.
local Players = game:GetService("Players")

local STAGE_NAME = "ClassroomIntro"
local SKIN = Color3.fromRGB(224, 172, 133)

local function detail(parent, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = parent.CFrame * offset
	part.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parent
	weld.Part1 = part
	weld.Parent = part

	return part
end

local function marker(parent, name, transform)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.one
	part.CFrame = transform
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent

	return part
end

local function build()
	assert(not workspace:FindFirstChild(STAGE_NAME), "ClassroomIntro already exists")

	local seats = workspace.HighSchool.Interactables.Seats.History
	local description = Instance.new("HumanoidDescription")
	local template =
		Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6)
	local studentTemplate =
		Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()

	local stage = Instance.new("Model")
	stage.Name = STAGE_NAME
	stage.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local actors = Instance.new("Folder")
	actors.Name = "Actors"
	actors.Parent = stage

	local cast = {
		{ name = "MsTaylor", seat = false, skin = SKIN, hair = Color3.fromRGB(74, 44, 32) },
		{
			name = "Maya",
			seat = "Seat2",
			skin = Color3.fromRGB(153, 103, 74),
			hair = Color3.fromRGB(38, 28, 24),
		},
		{ name = "Leo", seat = "Seat7", skin = SKIN, hair = Color3.fromRGB(102, 65, 37) },
		{
			name = "Amira",
			seat = "Seat5",
			skin = Color3.fromRGB(190, 137, 96),
			hair = Color3.fromRGB(30, 24, 23),
		},
		{
			name = "Ben",
			seat = "Seat10",
			skin = Color3.fromRGB(241, 199, 164),
			hair = Color3.fromRGB(185, 133, 60),
		},
		{
			name = "Sofia",
			seat = "Seat3",
			skin = Color3.fromRGB(200, 153, 113),
			hair = Color3.fromRGB(58, 36, 27),
		},
		{
			name = "Noah",
			seat = "Seat11",
			skin = Color3.fromRGB(122, 82, 60),
			hair = Color3.fromRGB(28, 24, 22),
		},
	}

	for _, student in cast do
		local rig = (student.seat and studentTemplate or template):Clone()
		rig.Name = student.name

		local humanoid = rig.Humanoid
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.AutoRotate = false

		local root = rig.HumanoidRootPart
		rig.PrimaryPart = root
		root.Anchored = true

		for _, instance in rig:GetDescendants() do
			if instance:IsA("BasePart") then
				instance.CanCollide = false
				instance.CanTouch = false
				instance.CanQuery = false
			elseif instance:IsA("BaseScript") then
				instance:Destroy()
			end
		end

		local colors = rig:FindFirstChildOfClass("BodyColors")
		colors.HeadColor3 = student.skin
		colors.LeftArmColor3 = Color3.fromRGB(61, 78, 103)
		colors.RightArmColor3 = colors.LeftArmColor3
		colors.TorsoColor3 = student.seat and colors.LeftArmColor3 or Color3.fromRGB(103, 91, 118)
		colors.LeftLegColor3 = Color3.fromRGB(39, 43, 53)
		colors.RightLegColor3 = colors.LeftLegColor3

		local torso = rig:FindFirstChild("UpperTorso") or rig.Torso

		if student.seat then
			rig:SetAttribute("ClassroomSeat", student.seat)
			rig:PivotTo(seats[student.seat].CFrame * CFrame.new(0, -0.2, 0))
		else
			rig:PivotTo(CFrame.lookAt(Vector3.new(-535, 16.4, -473), Vector3.new(-552, 16.4, -480)))
		end

		detail(
			torso,
			"Collar",
			Vector3.new(0.85, 0.35, 0.08),
			CFrame.new(0, 0.78, -0.53),
			Color3.fromRGB(239, 234, 219)
		)
		detail(
			torso,
			"Tie",
			Vector3.new(0.2, 0.85, 0.1),
			CFrame.new(0, 0.2, -0.55),
			Color3.fromRGB(188, 151, 75)
		)
		detail(rig.Head, "Hair", Vector3.new(2.02, 0.5, 1.05), CFrame.new(0, 0.48, 0), student.hair)

		if student.name == "Maya" or student.name == "Sofia" or not student.seat then
			detail(
				rig.Head,
				"HairBack",
				Vector3.new(1.9, 1.3, 0.38),
				CFrame.new(0, -0.05, 0.48),
				student.hair
			)
		end

		rig.Parent = actors
	end

	template:Destroy()
	studentTemplate:Destroy()

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = stage
	marker(
		markers,
		"YourFutureArrival",
		CFrame.lookAt(Vector3.new(-549, 18, -481), Vector3.new(-535, 18, -473))
	)
	marker(markers, "PlayerSeat", seats.Seat6.CFrame * CFrame.new(0, -1.5, 0))
	marker(
		markers,
		"Arrival",
		CFrame.lookAt(Vector3.new(-551, 18, -481), Vector3.new(-531, 18, -481))
	)
	marker(markers, "Wide", CFrame.lookAt(Vector3.new(-565, 22, -499), Vector3.new(-543, 18, -481)))
	marker(
		markers,
		"Teacher",
		CFrame.lookAt(Vector3.new(-543, 19.5, -478), Vector3.new(-535, 18.3, -473))
	)
	marker(
		markers,
		"Maya",
		CFrame.lookAt(Vector3.new(-539, 17.9, -481), Vector3.new(-544.66, 17.3, -477.2))
	)
	marker(
		markers,
		"Leo",
		CFrame.lookAt(Vector3.new(-547, 17.9, -483), Vector3.new(-552.65, 17.3, -487.2))
	)
	marker(
		markers,
		"Amira",
		CFrame.lookAt(Vector3.new(-547, 17.9, -474), Vector3.new(-552.65, 17.3, -471.1))
	)
	marker(
		markers,
		"Player",
		CFrame.lookAt(Vector3.new(-545.5, 18, -479.8), Vector3.new(-552.65, 17.2, -477.2))
	)

	stage.Parent = workspace

	return stage
end

return build
