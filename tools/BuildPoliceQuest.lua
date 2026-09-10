-- Adds actors, props, and editable checkpoints to the inspected police station.
local Players = game:GetService("Players")

local function part(parent, name, size, cf, color)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Color = color or Color3.fromRGB(43, 62, 83)
	object.Material = Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.Parent = parent

	return object
end

local function label(object, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 38)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.MaxDistance = 28
	gui.Parent = object

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundColor3 = Color3.fromRGB(252, 250, 255)
	title.BackgroundTransparency = 0.05
	title.TextColor3 = Color3.fromRGB(32, 27, 38)
	title.Font = Enum.Font.Arcade
	title.TextSize = 17
	title.Text = text
	title.Parent = gui
end

local function actor(parent, name, cf, shirt, skin)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = skin
	description.LeftArmColor = skin
	description.RightArmColor = skin
	description.TorsoColor = shirt
	description.LeftLegColor = Color3.fromRGB(41, 48, 57)
	description.RightLegColor = description.LeftLegColor

	local model =
		Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	model.Name = name
	model.PrimaryPart = model.HumanoidRootPart
	model.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanCollide = false
			object.CanTouch = false
		end
	end

	model.HumanoidRootPart.Anchored = true
	model:PivotTo(cf)
	model.Parent = parent

	return model
end

return function()
	assert(workspace:FindFirstChild("PoliceStation"), "The police station is missing")
	assert(not workspace:FindFirstChild("PoliceQuest"), "PoliceQuest already exists")

	local stage = Instance.new("Model")
	stage.Name = "PoliceQuest"
	stage.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = stage

	local transforms = {
		Arrival = CFrame.lookAt(Vector3.new(282, 9.8, -238), Vector3.new(300, 9.8, -238)),
		SuspectEntry = CFrame.lookAt(Vector3.new(286, 9.8, -238), Vector3.new(302, 9.8, -238)),
		EntryEnd = CFrame.lookAt(Vector3.new(302, 9.8, -238), Vector3.new(307, 9.8, -238)),
		PlayerEntryEnd = CFrame.lookAt(Vector3.new(297, 9.8, -238), Vector3.new(307, 9.8, -238)),
		EntryCamera = CFrame.lookAt(Vector3.new(280, 15, -248), Vector3.new(293, 10, -238)),
		LobbyWalk = CFrame.new(326, 9.8, -238),
		LobbyTurn = CFrame.new(326, 9.8, -242),
		BookingTurn = CFrame.new(338, 9.8, -242),
		BookingExit = CFrame.new(338, 9.8, -294),
		CellHallSouth = CFrame.new(368, 9.8, -294),
		CellHallCorner = CFrame.new(368, 9.8, -276),
		CellHallNorth = CFrame.new(376, 9.8, -268),
		Search = CFrame.lookAt(Vector3.new(338, 9.8, -286), Vector3.new(338, 9.8, -280)),
		SearchArrival = CFrame.lookAt(Vector3.new(338, 9.8, -281), Vector3.new(338, 9.8, -286)),
		SearchCamera = CFrame.lookAt(Vector3.new(338, 11, -276.5), Vector3.new(338, 9.9, -286)),
		Fingerprint = CFrame.lookAt(Vector3.new(335.5, 9.8, -296), Vector3.new(332, 9.8, -296)),
		FingerprintArrival = CFrame.lookAt(
			Vector3.new(333, 9.8, -291),
			Vector3.new(335.5, 9.8, -296)
		),
		FingerprintCamera = CFrame.lookAt(
			Vector3.new(331.5, 14, -292),
			Vector3.new(334.5, 10.6, -296)
		),
		Mugshot = CFrame.lookAt(Vector3.new(342.8, 9.8, -306.7), Vector3.new(336, 9.8, -306.7)),
		MugshotArrival = CFrame.lookAt(
			Vector3.new(336, 9.8, -305),
			Vector3.new(342.8, 9.8, -306.7)
		),
		MugshotCamera = CFrame.lookAt(
			Vector3.new(339, 11.8, -306.7),
			Vector3.new(342.8, 11.4, -306.7)
		),
		CellOutside = CFrame.lookAt(Vector3.new(376, 9.8, -265), Vector3.new(376, 9.8, -254)),
		CellInside = CFrame.lookAt(Vector3.new(376, 9.8, -254), Vector3.new(376, 9.8, -265)),
		CellArrival = CFrame.lookAt(Vector3.new(380, 9.8, -265), Vector3.new(376, 9.8, -259)),
	}

	for name, cf in transforms do
		local marker = part(markers, name, Vector3.one, cf)
		marker.Transparency = 1
		marker.CanQuery = false
	end

	local suspect = actor(
		stage,
		"Suspect",
		transforms.SuspectEntry,
		Color3.fromRGB(160, 92, 55),
		Color3.fromRGB(201, 158, 119)
	)

	for _, handName in { "RightHand", "LeftHand" } do
		local hand = suspect[handName]
		local cuff = part(
			suspect,
			handName .. "Cuff",
			Vector3.new(0.7, 0.22, 0.65),
			hand.CFrame,
			Color3.fromRGB(153, 164, 178)
		)
		cuff.Material = Enum.Material.Metal
		cuff.Anchored = false
		cuff.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = cuff
		weld.Parent = cuff
	end

	local leo = actor(
		stage,
		"Leo",
		CFrame.lookAt(Vector3.new(331, 9.8, -283), transforms.Search.Position),
		Color3.fromRGB(34, 57, 85),
		Color3.fromRGB(224, 172, 133)
	)
	label(leo.Head, "OFFICER LEO")

	local badge = part(
		leo,
		"Badge",
		Vector3.new(0.3, 0.4, 0.1),
		leo.UpperTorso.CFrame * CFrame.new(-0.4, 0.25, -0.55),
		Color3.fromRGB(226, 188, 83)
	)
	badge.Anchored = false
	badge.Massless = true

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = leo.UpperTorso
	weld.Part1 = badge
	weld.Parent = badge

	local chain = Instance.new("Beam")
	local a = Instance.new("Attachment")
	a.Parent = suspect.RightHandCuff

	local b = Instance.new("Attachment")
	b.Parent = suspect.LeftHandCuff
	chain.Attachment0 = a
	chain.Attachment1 = b
	chain.Width0 = 0.08
	chain.Width1 = 0.08
	chain.FaceCamera = true
	chain.Color = ColorSequence.new(Color3.fromRGB(150, 161, 174))
	chain.Parent = suspect

	local stations = Instance.new("Folder")
	stations.Name = "Stations"
	stations.Parent = stage

	for name, data in
		{
			Search = { Vector3.new(338, 10, -286), "Search inventory" },
			Fingerprint = { Vector3.new(333.4, 10, -296), "Fingerprint scanner" },
			Mugshot = { Vector3.new(337, 10, -305.5), "Mugshot camera" },
			Cell = { Vector3.new(379, 10, -263), "Holding cell" },
		}
	do
		local station = part(stations, name, Vector3.new(0.6, 0.3, 0.6), CFrame.new(data[1]))
		station.Transparency = name == "Fingerprint" and 0 or 1
		label(station, data[2])

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Interact"
		prompt.ActionText = data[2]
		prompt.ObjectText = "POLICE BOOKING"
		prompt.RequiresLineOfSight = false
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 8
		prompt.Enabled = false
		prompt.Parent = station
	end

	local scanner =
		part(stage, "Scanner", Vector3.new(1.4, 0.22, 1.6), CFrame.new(333.4, 10.05, -296))
	local glass = part(
		stage,
		"ScannerGlass",
		Vector3.new(0.9, 0.04, 1.1),
		scanner.CFrame * CFrame.new(0, 0.13, 0),
		Color3.fromRGB(79, 205, 177)
	)
	glass.Material = Enum.Material.Neon

	local reference = Instance.new("ObjectValue")
	reference.Name = "CellDoor"
	reference.Value = workspace.PoliceStation.Interactables.Doors.Door52
	reference.Parent = stage
	stage.Parent = workspace
	require(game.ServerScriptService.PoliceProps).Install(stage)
	require(game.ReplicatedStorage.Modules.PoliceEvidence).Install(stage)

	return stage
end
