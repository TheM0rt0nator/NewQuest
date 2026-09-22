local ServerStorage = game:GetService("ServerStorage")

local Config = require(script.Parent.SecretQuestConfig)

local SecretQuestCarry = {}
SecretQuestCarry.__index = SecretQuestCarry

local BODY_PARTS = {
	UpperTorso = true,
	Torso = true,
	RightHand = true,
	["Right Arm"] = true,
	LeftHand = true,
	["Left Arm"] = true,
}

local function getMount(character, itemId)
	if itemId == "SunsetShirt" then
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		if torso then
			return torso, CFrame.new(0, 0, torso.Size.Z / 2 + 0.12) * CFrame.Angles(0, math.pi, 0)
		end
	else
		local right = itemId == "Smoothie"
		local hand = character:FindFirstChild(right and "RightHand" or "LeftHand")
		local arm = hand or character:FindFirstChild(right and "Right Arm" or "Left Arm")
		if arm then
			local height = hand and 0 or -arm.Size.Y / 2 + 0.2
			return arm, CFrame.new(0, height, -arm.Size.Z / 2 - 0.2)
		end
	end

	return nil
end

function SecretQuestCarry.new(player, state)
	local self = setmetatable({ Player = player, State = state, Carried = {} }, SecretQuestCarry)
	self.CharacterAdded = player.CharacterAdded:Connect(function(character)
		self:BindCharacter(character)
	end)
	self.CharacterRemoving = player.CharacterRemoving:Connect(function(character)
		if self.Character == character then
			self:ClearCharacter()
		end
	end)
	if player.Character then
		self:BindCharacter(player.Character)
	end

	return self
end

function SecretQuestCarry:ClearCharacter()
	if self.ChildAdded then
		self.ChildAdded:Disconnect()
		self.ChildAdded = nil
	end

	if self.ChildRemoved then
		self.ChildRemoved:Disconnect()
		self.ChildRemoved = nil
	end

	if self.Folder then
		self.Folder:Destroy()
		self.Folder = nil
	end

	table.clear(self.Carried)
	self.Character = nil
end

function SecretQuestCarry:BindCharacter(character)
	self:ClearCharacter()
	self.Character = character
	self.ChildAdded = character.ChildAdded:Connect(function(child)
		if BODY_PARTS[child.Name] then
			self:Refresh()
		end
	end)
	self.ChildRemoved = character.ChildRemoved:Connect(function(child)
		if BODY_PARTS[child.Name] then
			if self.Folder then
				self.Folder:Destroy()
				self.Folder = nil
				table.clear(self.Carried)
			end

			self:Refresh()
		end
	end)
	self:Refresh()
end

function SecretQuestCarry:Refresh()
	local character = self.Character
	local templates = ServerStorage:FindFirstChild("SecretQuestItems")
	if not character or not templates then
		return
	end

	for _, item in Config.Items do
		local itemId = item.Id
		if not self.State.Collected[itemId] or self.Carried[itemId] then
			continue
		end

		local target, offset = getMount(character, item.Key)
		local template = templates:FindFirstChild(item.Key)
		if not target or not template then
			continue
		end

		if not self.Folder then
			self.Folder = Instance.new("Folder")
			self.Folder.Name = "Folder"
			self.Folder.Parent = character
		end

		local model = template:Clone()
		model:PivotTo(target.CFrame * offset)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = target
				weld.Part1 = part
				weld.Parent = part
			end
		end

		model.Name = "Model"
		self.Carried[itemId] = model
		model.Parent = self.Folder
		-- Parenting a clothing mannequin can reset its torso's collision.
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Massless = true
			end
		end
	end
end

function SecretQuestCarry:SetState(state)
	self.State = state
	self:Refresh()
end

function SecretQuestCarry:Destroy()
	self.CharacterAdded:Disconnect()
	self.CharacterRemoving:Disconnect()
	self:ClearCharacter()
end

return SecretQuestCarry
