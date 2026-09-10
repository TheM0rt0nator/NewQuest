-- Run once in Edit mode. Adds quest props to the existing hospital bed bay.
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Modules.DoctorQuestConfig)

local function part(parent, name, size, cf, color)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Color = color or Color3.fromRGB(227, 235, 239)
	object.Material = Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.Parent = parent

	return object
end

local function marker(parent, name, cf)
	local object = part(parent, name, Vector3.one, cf)
	object.Transparency = 1
	object.CanQuery = false

	return object
end

local function screen(parent, size)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = size
	gui.LightInfluence = 0
	gui.ZOffset = 1
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(14, 30, 43)
	label.TextColor3 = Color3.fromRGB(128, 231, 199)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 46
	label.TextWrapped = true
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = label

	return label
end

return function()
	assert(not workspace:FindFirstChild("DoctorQuest"), "DoctorQuest already exists")

	local hospital = workspace:FindFirstChild("Hospital")
	assert(hospital, "The existing Hospital model is required")

	local bed

	for _, object in hospital:GetDescendants() do
		if
			object.Name == "HospitalBed"
			and (object:GetPivot().Position - Vector3.new(541, 20, 465)).Magnitude < 8
		then
			bed = object
			break
		end
	end

	assert(bed, "The selected hospital bed could not be found")

	local stage = Instance.new("Model")
	stage.Name = "DoctorQuest"
	stage.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local bedReference = Instance.new("ObjectValue")
	bedReference.Name = "HospitalBed"
	bedReference.Value = bed
	bedReference.Parent = stage

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = stage
	marker(
		markers,
		"Arrival",
		CFrame.lookAt(Vector3.new(540.5, 20.4, 469), Vector3.new(540.5, 20.4, 465))
	)
	marker(markers, "Wide", CFrame.lookAt(Vector3.new(532.5, 25.5, 471), Vector3.new(541, 21, 465)))
	marker(
		markers,
		"Patient",
		CFrame.lookAt(Vector3.new(540, 25, 469), Vector3.new(543, 21.3, 465))
	)
	marker(
		markers,
		"Treatment",
		CFrame.lookAt(Vector3.new(540.5, 20.4, 469), Vector3.new(540.5, 20.4, 465))
	)

	local treatment = marker(stage, "TreatmentPoint", CFrame.new(541, 21.8, 465))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Treat"
	prompt.ActionText = "Treat patient"
	prompt.ObjectText = "Patient"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = treatment

	local description = Instance.new("HumanoidDescription")
	description.HeadColor = Color3.fromRGB(204, 159, 120)
	description.LeftArmColor = description.HeadColor
	description.RightArmColor = description.HeadColor
	description.TorsoColor = Color3.fromRGB(144, 198, 207)
	description.LeftLegColor = description.TorsoColor
	description.RightLegColor = description.TorsoColor

	local patient =
		Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	patient.Name = "Patient"
	patient.PrimaryPart = patient.HumanoidRootPart
	patient.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	patient.HumanoidRootPart.Anchored = true
	patient:PivotTo(
		CFrame.fromMatrix(
			Vector3.new(541.3, 21.05, 464.8),
			Vector3.new(0, 0, -1),
			Vector3.xAxis,
			Vector3.new(0, -1, 0)
		)
	)

	for _, object in patient:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
		end
	end

	patient.Parent = stage
	part(
		stage,
		"SurgicalDrape",
		Vector3.new(3.9, 0.12, 3.7),
		CFrame.new(538.9, 21.65, 464.8),
		Color3.fromRGB(89, 167, 178)
	)

	local monitorPosition = Vector3.new(543.8466, 22.6098, 459.8916)
	local normal = Vector3.new(-0.89254, 0.17365, 0.41619)
	local monitor = part(
		stage,
		"Monitor",
		Vector3.new(1.69, 1.36, 0.035),
		CFrame.lookAt(monitorPosition + normal * 0.04, monitorPosition + normal)
	)
	screen(monitor, Vector2.new(360, 290)).Text = "PATIENT\n♥  72\nSTABLE"

	local sound = Instance.new("Sound")
	sound.Name = "Beep"
	sound.SoundId = Config.BeepSoundId
	sound.Volume = 0.55
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = 45
	sound.Parent = monitor

	local supplies = Instance.new("Folder")
	supplies.Name = "Supplies"
	supplies.Parent = stage

	for index, taskId in Config.TaskIds do
		local definition = Config.Tasks[taskId]
		local station = Instance.new("Model")
		station.Name = taskId

		local x = 534.2 + ((index - 1) % 3) * 4
		local z = index <= 3 and 457.7 or 471.9
		local tray = part(station, "Tray", Vector3.new(2.7, 0.15, 1.6), CFrame.new(x, 20.5, z))
		part(station, "Stand", Vector3.new(0.15, 3, 0.15), CFrame.new(x, 18.95, z))
		part(station, "Base", Vector3.new(2.1, 0.15, 1.3), CFrame.new(x, 17.5, z))

		local prop = Instance.new("Model")
		prop.Name = "Item"
		prop.Parent = station

		local size = Vector3.new(0.65, 0.9, 0.45)

		if taskId == "Scalpel" or taskId == "Injection" then
			size = Vector3.new(1.25, 0.18, 0.22)
		elseif taskId == "Shock" then
			size = Vector3.new(0.65, 0.25, 0.9)
		end

		local handle =
			part(prop, "Handle", size, CFrame.new(x, 20.65 + size.Y / 2, z), definition.Color)
		prop.PrimaryPart = handle

		if taskId == "Medicine" then
			part(prop, "Cap", Vector3.new(0.68, 0.2, 0.48), handle.CFrame * CFrame.new(0, 0.5, 0))
		elseif taskId == "Shock" then
			part(
				prop,
				"SecondPaddle",
				size,
				handle.CFrame * CFrame.new(0.9, 0, 0),
				definition.Color
			)
		elseif taskId == "Scalpel" or taskId == "Injection" then
			part(prop, "Tip", Vector3.new(0.5, 0.06, 0.1), handle.CFrame * CFrame.new(0.8, 0, 0))
		else
			part(
				prop,
				"Label",
				Vector3.new(0.43, 0.33, 0.04),
				handle.CFrame * CFrame.new(0, 0, -0.24)
			)
		end

		local labelGui = Instance.new("BillboardGui")
		labelGui.Name = "Label"
		labelGui.Size = UDim2.fromOffset(130, 30)
		labelGui.StudsOffset = Vector3.new(0, 1.8, 0)
		labelGui.MaxDistance = 35
		labelGui.Parent = tray

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(14, 30, 43)
		label.BackgroundTransparency = 0.15
		label.TextColor3 = definition.Color
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 16
		label.Text = definition.Label
		label.Parent = labelGui

		local pickup = prompt:Clone()
		pickup.Name = "PickUp"
		pickup.ActionText = "Pick up"
		pickup.ObjectText = definition.Label
		pickup.MaxActivationDistance = 4.5
		pickup.HoldDuration = 0.6
		pickup.Parent = tray
		station.Parent = supplies
	end

	require(game.ServerScriptService.DoctorProps).Polish(stage)
	stage.Parent = workspace

	return stage
end
