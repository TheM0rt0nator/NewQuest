-- Adds quest actors and interactions to the existing cabin without moving the plane.
local Config = require(game.ReplicatedStorage.Modules.FlightQuestConfig)
local FlightMeals = require(game.ReplicatedStorage.Modules.FlightMeals)
local FlightProps = require(game.ServerScriptService.FlightProps)

local function part(parent, name, size, cf, color)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Color = color or Color3.fromRGB(222, 210, 241)
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.Parent = parent

	return object
end

local function prompt(object, action, label)
	local interact = Instance.new("ProximityPrompt")
	interact.Name = "Interact"
	interact.ActionText = action
	interact.ObjectText = label
	interact.HoldDuration = 0.5
	interact.MaxActivationDistance = 9
	interact.RequiresLineOfSight = false
	interact.Enabled = false
	interact.Parent = object
end

local function label(object, content)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(180, 42)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 22
	gui.Parent = object

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(252, 250, 255)
	text.TextColor3 = Color3.fromRGB(32, 27, 38)
	text.Font = Enum.Font.Arcade
	text.TextScaled = true
	text.TextWrapped = true
	text.Text = content
	text.Parent = gui
end

return function()
	assert(not workspace:FindFirstChild("FlightQuest"), "FlightQuest already exists")

	local plane = workspace:WaitForChild("PlaneInter")
	local seats = plane.Interactables.Seats
	local stage = Instance.new("Model")
	stage.Name = "FlightQuest"
	stage.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = stage

	local transforms = {
		Arrival = CFrame.lookAt(Vector3.new(525, 25, -895), Vector3.new(545, 25, -895)),
		CabinFront = CFrame.lookAt(Vector3.new(525, 27, -895), Vector3.new(545, 25, -895)),
		CabinMiddle = CFrame.lookAt(Vector3.new(537, 27, -895), Vector3.new(547, 25, -890)),
		CabinRear = CFrame.lookAt(Vector3.new(555, 27, -895), Vector3.new(545, 25, -900)),
		TakeoffCamera = CFrame.lookAt(Vector3.new(526, 27, -895), Vector3.new(551, 25, -895)),
	}

	for name, cf in transforms do
		local marker = part(markers, name, Vector3.one, cf)
		marker.Transparency = 1
		marker.CanQuery = false
	end

	local passengers = Instance.new("Folder")
	passengers.Name = "Passengers"
	passengers.Parent = stage

	for index, passenger in Config.Passengers do
		local model = workspace.ClassroomIntro.Actors[passenger.Name]:Clone()
		model.Name = passenger.Name
		model:SetAttribute("ClassroomSeat", nil)
		model:SetAttribute("PassengerIndex", index)
		model:SetAttribute("Meal", passenger.Meal)

		for _, object in model:GetDescendants() do
			if object:IsA("LuaSourceContainer") or object:IsA("BillboardGui") then
				object:Destroy()
			elseif object:IsA("BasePart") then
				object.CanCollide = false
				object.CanTouch = false
				object.Massless = object.Name ~= "HumanoidRootPart"
				object.Anchored = object.Name == "HumanoidRootPart"
			end
		end

		model.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		model:PivotTo(seats[passenger.Seat].CFrame * CFrame.new(0, 1.6, 0))
		model.Parent = passengers

		FlightProps.BuildSeatbelt(model)

		prompt(model.HumanoidRootPart, "Serve meal", passenger.Name)
		label(model.Head, passenger.Name)
	end

	local galley = part(
		stage,
		"Galley",
		Vector3.new(2.4, 2.4, 1.5),
		CFrame.new(522.5, 24, -896),
		Color3.fromRGB(54, 64, 83)
	)
	label(galley, "CABIN CREW\nGalley")
	prompt(galley, "Start announcement", "Cabin intercom")

	local top = part(
		stage, "ServiceTray", Vector3.new(2.7, 0.15, 1.8), galley.CFrame * CFrame.new(0, 1.3, 0)
	)
	top.Material = Enum.Material.Metal

	local seat = Instance.new("ObjectValue")
	seat.Name = "HostessSeat"
	seat.Value = seats.AirHostesssSeat1
	seat.Parent = stage

	local seatTarget = part(stage, "SeatTarget", Vector3.one, seat.Value.CFrame)
	seatTarget.Transparency = 1
	seatTarget.CanQuery = false
	prompt(seatTarget, "Sit for takeoff", "Hostess seat")
	label(seatTarget, "CREW SEAT")

	local engine = Instance.new("Sound")
	engine.Name = "TakeoffEngine"
	engine.SoundId = "rbxassetid://16880017184"
	engine.Volume = 0.45
	engine.Parent = stage

	FlightProps.BuildTrolley(stage)
	FlightProps.BuildMealDisplay(stage, FlightMeals.Create)

	stage.Parent = workspace

	return stage
end
