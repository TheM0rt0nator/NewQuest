local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SecretQuestAccess = require(script.Parent.SecretQuestAccess)

local Bindings = require(script.Parent.SecretQuestBindings)

local SecretQuestEntrance = {}
local connections = {}
local busyPlayers = {}
local nextInteractions = {}
local playerConnections = {}

local function canInteract(player, prompt)
	local binding = Bindings.Get(prompt)
	if
		not SecretQuestAccess.IsAvailable(player)
		or not binding
		or not prompt.Enabled
		or prompt.Parent ~= binding.Anchor
	then
		return false
	end

	local anchor = prompt.Parent
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return player.Parent == Players
		and anchor
		and anchor:IsA("BasePart")
		and root
		and humanoid
		and humanoid.Health > 0
		and (root.Position - anchor.Position).Magnitude <= prompt.MaxActivationDistance + 2
end

function SecretQuestEntrance.Start(questService)
	if #connections > 0 or not SecretQuestAccess.IsEntrance() then
		return
	end

	local trunk = Bindings.Trunk
	local anchor = Bindings.Tree
	if trunk and trunk:IsA("BasePart") and anchor and anchor:IsA("BasePart") then
		local function alignTreePrompt()
			anchor.CFrame = trunk.CFrame * CFrame.new(0, -trunk.Size.Y / 2 + 3, 0)
		end

		alignTreePrompt()
		table.insert(connections, trunk:GetPropertyChangedSignal("CFrame"):Connect(alignTreePrompt))
		table.insert(connections, trunk:GetPropertyChangedSignal("Size"):Connect(alignTreePrompt))
	end

	local function watchPlayer(player)
		player:SetAttribute("SecretQuestAvailable", SecretQuestAccess.IsAvailable(player))
		playerConnections[player] = player
			:GetAttributeChangedSignal("AnniversaryQuestComplete")
			:Connect(function()
				player:SetAttribute("SecretQuestAvailable", SecretQuestAccess.IsAvailable(player))
				if SecretQuestAccess.IsAvailable(player) then
					questService:ResumeSecretQuest(player)
				end
			end)
	end

	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	table.insert(connections, Players.PlayerAdded:Connect(watchPlayer))

	table.insert(
		connections,
		ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
			if
				not Bindings.Get(prompt)
				or busyPlayers[player]
				or os.clock() < (nextInteractions[player] or 0)
				or not canInteract(player, prompt)
			then
				return
			end

			busyPlayers[player] = true
			nextInteractions[player] = os.clock() + 0.5
			local success, err = pcall(function()
				local quests = questService.PlayerQuests[player]
				local quest = quests and quests.SecretQuest
				local itemId = Bindings.Get(prompt).ItemId
				if itemId then
					if quest then
						quest:Collect(itemId)
					end
					return
				end

				if not quest then
					local request = questService:GiveQuest(player, "SecretQuest")
					if request then
						request:await()
					end

					quests = questService.PlayerQuests[player]
					quest = quests and quests.SecretQuest
				end

				if quest and canInteract(player, prompt) then
					quest:InteractWithTree(prompt)
				end
			end)
			busyPlayers[player] = nil
			if not success then
				warn("[SecretQuest] Interaction failed:", err)
			end
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			if playerConnections[player] then
				playerConnections[player]:Disconnect()
				playerConnections[player] = nil
			end

			busyPlayers[player] = nil
			nextInteractions[player] = nil
		end)
	)
end

function SecretQuestEntrance.Destroy()
	for _, connection in playerConnections do
		connection:Disconnect()
	end

	table.clear(playerConnections)
	for _, connection in connections do
		connection:Disconnect()
	end

	table.clear(connections)
	table.clear(busyPlayers)
	table.clear(nextInteractions)
end

return SecretQuestEntrance
