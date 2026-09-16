local DoctorStaging = {}

local FLOOR_Y = 17.2
local TREATMENT_STEP_HEIGHT = 1.8
local DRIP_STEP_HEIGHT = 2
local TREATMENT_POSITION = Vector3.new(540.7, FLOOR_Y, 468.7)
local DRIP_POSITION = Vector3.new(542.4, FLOOR_Y, 471.2)
local DRIP_TARGET = Vector3.new(544.6, FLOOR_Y, 469.6)

local function createPart(parent, name, size, cframe, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function createStep(stage, name, position, target, height)
	local existing = stage:FindFirstChild(name)
	local facing = CFrame.lookAt(position, Vector3.new(target.X, position.Y, target.Z))

	if existing then
		existing.Platform.CFrame = facing * CFrame.new(0, height - 0.1, 0)
		existing.Base.Size = Vector3.new(2.6, height - 0.2, 1.8)
		existing.Base.CFrame = facing * CFrame.new(0, (height - 0.2) / 2, 0)

		return existing
	end

	local model = Instance.new("Model")
	model.Name = name
	local top = createPart(
		model,
		"Platform",
		Vector3.new(2.8, 0.2, 2),
		facing * CFrame.new(0, height - 0.1, 0),
		Color3.fromRGB(65, 86, 94)
	)
	top.Material = Enum.Material.Rubber
	model.PrimaryPart = top

	local body = createPart(
		model,
		"Base",
		Vector3.new(2.6, height - 0.2, 1.8),
		facing * CFrame.new(0, (height - 0.2) / 2, 0),
		Color3.fromRGB(202, 213, 216)
	)
	body.Material = Enum.Material.Metal

	local lower = createPart(
		model,
		"LowerStep",
		Vector3.new(2.8, 1, 0.85),
		facing * CFrame.new(0, 0.5, 1.35),
		Color3.fromRGB(202, 213, 216)
	)
	lower.Material = Enum.Material.Metal

	local tread = createPart(
		model,
		"LowerTread",
		Vector3.new(2.8, 0.08, 0.85),
		facing * CFrame.new(0, 1.04, 1.35),
		top.Color
	)
	tread.Material = Enum.Material.Rubber

	model.Parent = stage

	return model
end

function DoctorStaging.Install(stage)
	createStep(
		stage,
		"TreatmentStep",
		TREATMENT_POSITION,
		Vector3.new(540.7, FLOOR_Y, 465),
		TREATMENT_STEP_HEIGHT
	)
	createStep(stage, "DripStep", DRIP_POSITION, DRIP_TARGET, DRIP_STEP_HEIGHT)

	local marker = stage.Markers:FindFirstChild("DripTreatment")

	if not marker then
		marker = stage.Markers.Treatment:Clone()
		marker.Name = "DripTreatment"
		marker.Parent = stage.Markers
	end

	local treatment = stage.TreatmentStep.Platform
	local drip = stage.DripStep.Platform
	stage.Markers.Treatment.CFrame = treatment.CFrame * CFrame.new(0, 0.1, 0)
	marker.CFrame = drip.CFrame * CFrame.new(0, 0.1, 0)
end

function DoctorStaging.GetTreatmentCFrame(stage, humanoid, taskId)
	local marker = taskId == "BloodBag" and stage.Markers.DripTreatment or stage.Markers.Treatment
	local root = humanoid.RootPart
	local height = humanoid.HipHeight + root.Size.Y / 2

	return marker.CFrame * CFrame.new(0, height, 0)
end

return DoctorStaging
