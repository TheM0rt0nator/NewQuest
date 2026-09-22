-- Matches MQ QuestController's ObjectiveTemplate and direction beam.
local ObjectiveMarkers = {}
ObjectiveMarkers.__index = ObjectiveMarkers

function ObjectiveMarkers.new(parent)
	local marker = Instance.new("BillboardGui")
	marker.Name = "ObjectiveTemplate"
	marker.Size = UDim2.new(0.1, 50, 0.1, 50)
	marker.StudsOffset = Vector3.new(0, 1.5, 0)
	marker.AlwaysOnTop = true
	marker.Enabled = false
	marker.Parent = parent

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = "rbxassetid://16669020928"
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = marker

	return setmetatable({ Marker = marker, Enabled = false }, ObjectiveMarkers)
end

function ObjectiveMarkers:ClearBeam()
	if self.Beam then
		self.Beam:Destroy()
		self.Attachment0:Destroy()
		self.Attachment1:Destroy()
		self.Beam = nil
		self.Attachment0 = nil
		self.Attachment1 = nil
	end
end

function ObjectiveMarkers:Refresh()
	local target = self.Target
	local character = self.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
	local active = self.Enabled
		and target
		and target:IsDescendantOf(workspace)
		and characterRoot
		and humanoid
		and humanoid.Health > 0
	self.Marker.Enabled = active and true or false
	self.Marker.Adornee = target

	if not active then
		self:ClearBeam()
		return
	end

	if
		self.Beam
		and self.Attachment0.Parent == characterRoot
		and self.Attachment1.Parent == target
	then
		return
	end

	self:ClearBeam()
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "ObjectiveBeamAttachment0"
	attachment0.Parent = characterRoot

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "ObjectiveBeamAttachment1"
	attachment1.Parent = target

	local beam = Instance.new("Beam")
	beam.Name = "ObjectiveDirectionBeam"
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.FaceCamera = true
	beam.Width0 = 0.75
	beam.Width1 = 0.75
	beam.Texture = "rbxassetid://92012760795352"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 2
	beam.TextureSpeed = 1.5
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new(0.1)
	beam.Parent = characterRoot
	self.Beam = beam
	self.Attachment0 = attachment0
	self.Attachment1 = attachment1
end

function ObjectiveMarkers:SetTarget(target)
	if self.Target == target then
		return
	end

	if self.TargetConnection then
		self.TargetConnection:Disconnect()
		self.TargetConnection = nil
	end

	self.Target = target

	if target then
		self.TargetConnection = target.AncestryChanged:Connect(function()
			self:Refresh()
		end)
	end

	self:Refresh()
end

function ObjectiveMarkers:SetCharacter(character)
	for _, connection in self.CharacterConnections or {} do
		connection:Disconnect()
	end

	self.CharacterConnections = {}
	self.Character = character
	self.Humanoid = nil

	local function refreshCharacter()
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid and humanoid ~= self.Humanoid then
			self.Humanoid = humanoid
			table.insert(
				self.CharacterConnections,
				humanoid.Died:Connect(function()
					self:Refresh()
				end)
			)
		end

		self:Refresh()
	end

	if character then
		table.insert(self.CharacterConnections, character.ChildAdded:Connect(refreshCharacter))
		table.insert(self.CharacterConnections, character.ChildRemoved:Connect(refreshCharacter))
		refreshCharacter()
	else
		self:Refresh()
	end
end

function ObjectiveMarkers:SetEnabled(enabled)
	self.Enabled = enabled
	self:Refresh()
end

function ObjectiveMarkers:Destroy()
	self:SetEnabled(false)
	self:SetTarget(nil)
	self:SetCharacter(nil)
	self.Marker:Destroy()
end

return ObjectiveMarkers
