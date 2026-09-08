local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChapterPlacement = require(script.Parent.ChapterPlacement)
local ClassroomSitting = require(script.Parent.ClassroomSitting)
local Config = require(ReplicatedStorage.Modules.FlightQuestConfig)
local FlightMeals = require(ReplicatedStorage.Modules.FlightMeals)
local QuestConfig = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local QuestService = require(script.Parent.QuestService)

local FlightService = {}
local stage
local session
local carrying
local heldTray
local passengerTracks = {}
local delivered = {}

local function clearMeal(player)
	carrying = nil

	if heldTray then
		heldTray:Destroy()
		heldTray = nil
	end

	player:SetAttribute("FlightMeal", nil)
end

local function release(player)
	if not session or session.player ~= player then
		return
	end

	local previous = session
	session = nil

	if previous.track then
		previous.track:Stop(0.1)
		previous.track:Destroy()
	end

	if previous.seat then
		local weld = previous.seat:FindFirstChild("SeatWeld")

		if weld and weld.Part1 and weld.Part1:IsDescendantOf(previous.character) then
			weld:Destroy()
		end

		previous.seat.Disabled = previous.seatDisabled
		previous.humanoid.Sit = false
	end

	if previous.root.Parent then
		previous.root.Anchored = previous.anchored

		if previous.seat then
			previous.character:PivotTo(stage.Markers.Arrival.CFrame)
		end
	end

	if previous.humanoid.Parent then
		previous.humanoid.WalkSpeed = previous.speed
		previous.humanoid.JumpPower = previous.jumpPower
		previous.humanoid.JumpHeight = previous.jumpHeight
	end

	player:SetAttribute("FlightBusy", false)
end

local function near(player, object)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	return root and humanoid and humanoid.Health > 0
		and (root.Position - object.Position).Magnitude <= Config.InteractionDistance
end

local function refresh(player)
	local state = player:GetAttribute("QuestState") or 0
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local active = state >= 16 and state <= 21 and humanoid ~= nil and humanoid.Health > 0
		and QuestService:IsActiveStep(player, state)
	local progress = player:GetAttribute("QuestProgress") or 0

	stage.Galley.Interact.Enabled = active and not session and (state == 17 or state == 20)
	stage.Galley.Interact.ActionText = state == 17 and "Start announcement" or "Choose a meal"
	stage.SeatTarget.Interact.Enabled = active and not session and state == 19
	stage.Galley.Label.Enabled = active and (state == 17 or state == 20)
	stage.SeatTarget.Label.Enabled = active and state == 19

	for index, passenger in Config.Passengers do
		local model = stage.Passengers[passenger.Name]
		local checkBelt = state == 18 and passenger.Name == Config.SeatbeltPassenger
		local serve = state == 20 and index == progress + 1
		model.HumanoidRootPart.Interact.Enabled = active and not session and (checkBelt or serve)
		model.HumanoidRootPart.Interact.ActionText = checkBelt and "Fasten seatbelt" or "Serve meal"
		model.HumanoidRootPart.Interact.HoldDuration = checkBelt and 2 or 0.5
		model.Head.Label.Enabled = active and (checkBelt or serve)
		model.Head.Label.Text.Text = checkBelt and passenger.Name .. "\nSeatbelt unfastened"
			or passenger.Name .. "\n" .. passenger.Meal .. ", please!"
		model.Seatbelt.Transparency = passenger.Name == Config.SeatbeltPassenger and state <= 18
			and 1 or 0

		local served = state == 20 and index <= progress or state == 21

		if active and served and not delivered[model] then
			local meal = FlightMeals.Create(passenger.Meal)
			meal:PivotTo(model.HumanoidRootPart.CFrame * CFrame.new(0, -0.2, -1.4))
			meal.Parent = stage
			delivered[model] = meal
		elseif (not active or not served) and delivered[model] then
			delivered[model]:Destroy()
			delivered[model] = nil
		end

		if active and not passengerTracks[model] then
			passengerTracks[model] = ClassroomSitting.Play(model.Humanoid)
		elseif not active and passengerTracks[model] then
			passengerTracks[model]:Stop(0)
			passengerTracks[model]:Destroy()
			passengerTracks[model] = nil
		end
	end
end

local function beginScene(player, state)
	local target = state == 17 and stage.Galley
		or state == 19 and stage.SeatTarget or stage.Markers.Arrival

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if session or not Config.SceneDurations[state] or not humanoid or humanoid.Health <= 0
		or state ~= 21 and not near(player, target)
	then
		return false, "Move to the highlighted cabin checkpoint."
	end

	ChapterPlacement.Release(player.Character)

	local root = character.HumanoidRootPart
	local current = {
		player = player,
		state = state,
		character = character,
		humanoid = humanoid,
		root = root,
		anchored = root.Anchored,
		speed = humanoid.WalkSpeed,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
		started = os.clock(),
	}
	session = current
	humanoid:Move(Vector3.zero)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0

	if state == 19 then
		local seat = stage.HostessSeat.Value
		current.seat = seat
		current.seatDisabled = seat.Disabled
		seat.Disabled = false
		root.Anchored = false
		character:PivotTo(seat.CFrame * CFrame.new(0, 2, 0))
		seat:Sit(humanoid)
		current.track = ClassroomSitting.Play(humanoid)
	else
		root.Anchored = true
	end

	player:SetAttribute("FlightBusy", true)
	refresh(player)

	task.delay(Config.SceneDurations[state] + 30, function()
		if session == current then
			release(player)
			refresh(player)
		end
	end)

	return true
end

function FlightService.Action(player, action, value)
	local state = player:GetAttribute("QuestState") or 0

	if action == "Cancel" then
		release(player)
		refresh(player)

		return true
	end

	if state < 16 or state > 21 or not QuestService:IsActiveStep(player, state) then
		return false, "This is not the current quest step."
	end

	if action == "BeginScene" then
		return beginScene(player, state)
	elseif action == "FinishScene" then
		if not session or session.player ~= player or session.state ~= state
			or session.character ~= player.Character or session.humanoid.Health <= 0
			or os.clock() - session.started < Config.SceneDurations[state]
		then
			return false, "The cabin sequence is not finished yet."
		end

		if state == 19 and session.humanoid.SeatPart ~= session.seat then
			return false, "Stay seated until the captain turns off the seatbelt sign."
		end

		release(player)

		return QuestService:CompleteObjective(player, QuestConfig.Name, state)
	end

	if session then
		return false, "Finish the current cabin sequence first."
	end

	if action == "Seatbelt" and state == 18 then
		local passenger = stage.Passengers[Config.SeatbeltPassenger]

		if not near(player, passenger.HumanoidRootPart) then
			return false, "Move closer to Ben's seat."
		end

		return QuestService:CompleteObjective(player, QuestConfig.Name, state)
	elseif action == "Pickup" and state == 20 then
		if not table.find(Config.Meals, value) or not near(player, stage.Galley) then
			return false, "Choose a meal at the galley."
		end

		clearMeal(player)
		carrying = value
		player:SetAttribute("FlightMeal", value)

		local hand = player.Character:FindFirstChild("RightHand")

		if hand then
			local tray = FlightMeals.Create(value)
			tray.Name = "FlightMealTray"
			tray:PivotTo(hand.CFrame * CFrame.new(0, -0.3, 0))
			tray.Parent = player.Character

			for _, part in tray:GetChildren() do
				part.Anchored = false

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = hand
				weld.Part1 = part
				weld.Parent = part
			end

			heldTray = tray
		end

		return true
	elseif action == "Serve" and state == 20 then
		local progress = player:GetAttribute("QuestProgress") or 0
		local passenger = Config.Passengers[progress + 1]

		if not passenger or value ~= passenger.Name
			or not near(player, stage.Passengers[passenger.Name].HumanoidRootPart)
		then
			return false, "Serve the passenger with the highlighted order."
		end

		if carrying ~= passenger.Meal then
			return false, passenger.Name .. " ordered " .. passenger.Meal .. ". Check the galley."
		end

		clearMeal(player)

		local success = QuestService:UpdateProgress(player, QuestConfig.Name, progress + 1)
		refresh(player)

		return success
	end

	return false, "That cabin action is not available."
end

function FlightService.Start()
	stage = workspace:WaitForChild("FlightQuest")

	for index, meal in Config.Meals do
		local sample = FlightMeals.Create(meal)
		sample:ScaleTo(0.55)
		sample:PivotTo(stage.Galley.CFrame * CFrame.new((index - 2) * 0.85, 1.45, 0))
		sample.Parent = stage
	end

	local remote = ReplicatedStorage:FindFirstChild("FlightAction")

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "FlightAction"
		remote.Parent = ReplicatedStorage
	end

	remote.OnServerInvoke = FlightService.Action
	QuestService.StateChanged:Connect(function(player)
		if typeof(player) ~= "Instance" then
			return
		end

		release(player)
		clearMeal(player)
		refresh(player)
	end)

	local function connect(player)
		player:GetAttributeChangedSignal("QuestDataReady"):Connect(function()
			refresh(player)
		end)
		player.CharacterRemoving:Connect(function()
			release(player)
			clearMeal(player)
		end)

		local function characterAdded(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				release(player)
				clearMeal(player)
				refresh(player)
			end)
			refresh(player)
		end

		player.CharacterAdded:Connect(characterAdded)

		if player.Character then
			task.spawn(characterAdded, player.Character)
		end
	end

	Players.PlayerAdded:Connect(connect)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
		clearMeal(player)
	end)

	for _, player in Players:GetPlayers() do
		connect(player)
	end
end

return FlightService
