local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestService = require(script.Parent.QuestService)
local ChapterPlacement = require(script.Parent.ChapterPlacement)
local QuestConfig = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local Config = require(ReplicatedStorage.Modules.DoctorQuestConfig)
local DoctorProps = require(script.Parent.DoctorProps)

local DoctorService = {}
local stage
local sessions = {}
local heldItems = {}

local function nearby(player, position, distance)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	return humanoid
		and humanoid.Health > 0
		and root
		and (root.Position - position).Magnitude <= distance
end

local function removeHeldItem(player)
	if heldItems[player] then
		heldItems[player]:Destroy()
		heldItems[player] = nil
	end
end

local function showHeldItem(player)
	removeHeldItem(player)

	if
		not QuestService:IsActiveStep(player, QuestConfig.States.DoctorTasks)
		or not player:GetAttribute("DoctorCarrying")
	then
		return
	end

	local character = player.Character
	local hand = character
		and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	local supply = stage.Supplies:FindFirstChild(player:GetAttribute("DoctorTask") or "")

	if not hand or not supply then
		return
	end

	local item = supply.Item:Clone()
	item.Name = "DoctorHeldItem"
	item:PivotTo(hand.CFrame * CFrame.new(0, -0.3, -0.35))

	for _, part in item:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.Massless = true

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hand
			weld.Part1 = part
			weld.Parent = part
		end
	end

	item.Parent = character
	heldItems[player] = item
end

local function refresh(player)
	local active = QuestService:IsActiveStep(player, QuestConfig.States.DoctorTasks)
	local taskId = player:GetAttribute("DoctorTask")
	local carrying = player:GetAttribute("DoctorCarrying") == true
	local busy = sessions[player] ~= nil

	for _, supply in stage.Supplies:GetChildren() do
		supply.Tray.PickUp.Enabled = active and not busy and not carrying and taskId == supply.Name
	end

	local prompt = stage.TreatmentPoint.Treat
	prompt.Enabled = active and carrying and not busy
	prompt.ActionText = Config.Tasks[taskId] and Config.Tasks[taskId].Action or "Treat patient"
end

local function release(player)
	local session = sessions[player]

	if not session then
		return
	end

	sessions[player] = nil

	if session.root.Parent then
		session.root.Anchored = session.anchored
	end

	if session.humanoid.Parent then
		session.humanoid.WalkSpeed = session.walkSpeed
		session.humanoid.JumpPower = session.jumpPower
		session.humanoid.JumpHeight = session.jumpHeight
		session.humanoid.AutoRotate = session.autoRotate
	end

	player:SetAttribute("DoctorBusy", false)
	player:SetAttribute("DoctorTreating", false)
	refresh(player)
end

local function lock(player, kind)
	local character = player.Character
	local humanoid = character.Humanoid
	local root = character.HumanoidRootPart
	local session = {
		kind = kind,
		character = character,
		humanoid = humanoid,
		root = root,
		anchored = root.Anchored,
		walkSpeed = humanoid.WalkSpeed,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
		autoRotate = humanoid.AutoRotate,
	}
	sessions[player] = session
	root.Anchored = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	player:SetAttribute("DoctorBusy", true)
	player:SetAttribute("DoctorTreating", kind == "Treatment")
	refresh(player)

	return session
end

function DoctorService.BeginIntro(player)
	if
		sessions[player]
		or not QuestService:IsActiveStep(player, QuestConfig.States.DoctorIntro)
		or not nearby(player, stage.Markers.Arrival.Position, 12)
	then
		return false
	end

	QuestService:PrepareDoctorRun(player)
	ChapterPlacement.Release(player.Character)

	local session = lock(player, "Intro")
	task.delay(45, function()
		if sessions[player] == session then
			release(player)
		end
	end)

	return true
end

function DoctorService.EndIntro(player, outcome)
	local session = sessions[player]

	if not session or session.kind ~= "Intro" then
		return false
	end

	local success = (outcome == "Completed" or outcome == "Skipped")
		and player.Character == session.character
		and session.humanoid.Health > 0
	release(player)

	if success then
		QuestService:CompleteObjective(player, QuestConfig.Name, QuestConfig.States.DoctorIntro)
		refresh(player)
	end

	return success
end

function DoctorService.PickUp(player, taskId)
	local supply = stage.Supplies:FindFirstChild(taskId)

	if sessions[player] or not supply or not nearby(player, supply.Tray.Position, 6) then
		return false
	end

	if not QuestService:PickUpDoctorItem(player, taskId) then
		return false
	end

	showHeldItem(player)
	refresh(player)

	return true
end

function DoctorService.Treat(player)
	if
		sessions[player]
		or not QuestService:IsActiveStep(player, QuestConfig.States.DoctorTasks)
		or not player:GetAttribute("DoctorCarrying")
		or not nearby(player, stage.TreatmentPoint.Position, 7)
	then
		return false
	end

	local taskId = player:GetAttribute("DoctorTask")
	local progress = player:GetAttribute("QuestProgress")
	local session = lock(player, "Treatment")
	player.Character:PivotTo(stage.Markers.Treatment.CFrame)

	local ok, reason = xpcall(function()
		local start = os.clock()

		while os.clock() - start < Config.TreatmentDuration do
			if sessions[player] ~= session or session.humanoid.Health <= 0 then
				return
			end

			task.wait(0.15)
		end

		if sessions[player] == session and session.humanoid.Health > 0 then
			removeHeldItem(player)
			QuestService:CompleteDoctorTask(player, taskId, progress)
		end
	end, debug.traceback)

	if sessions[player] == session then
		release(player)
		showHeldItem(player)
	end

	if not ok then
		warn("[DoctorQuest]", reason)
	end

	return ok
end

function DoctorService.Start()
	stage = workspace:WaitForChild("DoctorQuest", 15)
	assert(stage, "Install the doctor room props first")
	DoctorProps.Polish(stage)
	ReplicatedStorage.BeginDoctorIntro.OnServerInvoke = DoctorService.BeginIntro
	ReplicatedStorage.EndDoctorIntro.OnServerEvent:Connect(DoctorService.EndIntro)

	for _, supply in stage.Supplies:GetChildren() do
		supply.Tray.PickUp.Triggered:Connect(function(player)
			DoctorService.PickUp(player, supply.Name)
		end)
	end

	stage.TreatmentPoint.Treat.Triggered:Connect(DoctorService.Treat)

	local function resume(player)
		QuestService:PrepareDoctorRun(player)
		showHeldItem(player)
		refresh(player)
	end

	local function connect(player)
		player:GetAttributeChangedSignal("QuestDataReady"):Connect(function()
			if player:GetAttribute("QuestDataReady") then
				resume(player)
			end
		end)

		player.CharacterRemoving:Connect(function()
			release(player)
			removeHeldItem(player)
		end)

		local function characterAdded(character)
			local humanoid = character:WaitForChild("Humanoid", 10)

			if humanoid then
				humanoid.Died:Connect(function()
					release(player)
					removeHeldItem(player)
				end)
			end

			character:WaitForChild("RightHand", 10)

			if player.Character == character and player:GetAttribute("QuestDataReady") then
				resume(player)
			end
		end

		player.CharacterAdded:Connect(characterAdded)

		if player.Character then
			task.spawn(characterAdded, player.Character)
		end

		if player:GetAttribute("QuestDataReady") then
			resume(player)
		end
	end

	QuestService.StateChanged:Connect(resume)
	Players.PlayerAdded:Connect(connect)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
		removeHeldItem(player)
	end)

	for _, player in Players:GetPlayers() do
		connect(player)
	end
end

return DoctorService
