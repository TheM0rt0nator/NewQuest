-- roblox services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- knit

local Knit = require(ReplicatedStorage.Packages.Knit)

local QuestService

local QuestController = Knit.CreateController({
	Name = "QuestController",
	Quests = {},
	QuestStates = {},
	QuestMarkers = {},
	ObjectiveMarkersEnabled = false,
	ObjectiveBeam = nil,
	ObjectiveBeamAttachment0 = nil,
	ObjectiveBeamAttachment1 = nil,
	ObjectiveBeamTarget = nil,
	ObjectiveBeamUpdateConnection = nil,
})

-- constants

local QUESTS = script.Quests
local QUEST_CONFIG = require(Knit.Shared.Configs.Quests)
local PLAYER_GUI = Knit.Player:WaitForChild("PlayerGui")
local BILLBOARDS = PLAYER_GUI:WaitForChild("Billboards")
local OBJECTIVE_MARKERS = BILLBOARDS:WaitForChild("ObjectiveMarkers")
local OBJECTIVE_BEAM_TEXTURE = "rbxassetid://92012760795352"
local OBJECTIVE_BEAM_WIDTH = 0.75
local OBJECTIVE_BEAM_TEXTURE_SPEED = 1.5

local function getPrimaryObjectiveAdornee()
	for _, marker in OBJECTIVE_MARKERS:GetChildren() do
		if marker.Enabled and marker.Adornee then
			return marker.Adornee
		end
	end

	return nil
end

-- methods

function QuestController:GetQuestNames()
	local names = {}
	for name in self.QuestStates do
		table.insert(names, name)
	end

	table.sort(names)
	return names
end

function QuestController:SelectQuest(questName)
	local state = self.QuestStates[questName]
	if not state then
		return
	end

	self.SelectedQuestName = questName
	self:_RenderObjectiveMarkers()
	Knit.ScreenController:GetScreen("Quest"):SetupQuestUI(questName, state)
end

function QuestController:SetupQuest(questName, state, questData, preserveSelection)
	if not state or (questData and questData.Completed) then
		return
	end

	local module = QUESTS:FindFirstChild(questName)
	if not module or not QUEST_CONFIG[questName] then
		return
	end

	self.QuestStates[questName] = state
	local existing = self.Quests[questName]
	if existing then
		existing:StateSet(state)
	else
		self.Quests[questName] = require(module).new(state)
	end

	if not preserveSelection or not self.SelectedQuestName then
		self:SelectQuest(questName)
	else
		Knit.ScreenController:GetScreen("Quest"):RefreshQuestSwitcher()
	end
end

function QuestController:RemoveQuest(questName)
	local quest = self.Quests[questName]
	if quest then
		quest:Destroy()
	end

	self.Quests[questName] = nil
	self.QuestStates[questName] = nil
	self.QuestMarkers[questName] = nil
	local names = self:GetQuestNames()
	if #names > 0 then
		self:SelectQuest(names[1])
	else
		self.SelectedQuestName = nil
		self:_RenderObjectiveMarkers()
	end
end

function QuestController:_DestroyObjectiveBeam()
	if self.ObjectiveBeamUpdateConnection then
		self.ObjectiveBeamUpdateConnection:Disconnect()
		self.ObjectiveBeamUpdateConnection = nil
	end

	if self.ObjectiveBeam then
		self.ObjectiveBeam:Destroy()
		self.ObjectiveBeam = nil
	end

	if self.ObjectiveBeamAttachment0 then
		self.ObjectiveBeamAttachment0:Destroy()
		self.ObjectiveBeamAttachment0 = nil
	end

	if self.ObjectiveBeamAttachment1 then
		self.ObjectiveBeamAttachment1:Destroy()
		self.ObjectiveBeamAttachment1 = nil
	end

	self.ObjectiveBeamTarget = nil
end

function QuestController:_RefreshObjectiveBeam()
	local target = self.ObjectiveMarkersEnabled and getPrimaryObjectiveAdornee() or nil
	local character = Knit.Player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not target or not hrp or not target:IsA("BasePart") then
		self:_DestroyObjectiveBeam()
		return
	end

	if self.ObjectiveBeam and self.ObjectiveBeamTarget == target then
		return
	end

	self:_DestroyObjectiveBeam()
	self.ObjectiveBeamTarget = target

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "ObjectiveBeamAttachment0"
	attachment0.Parent = hrp

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "ObjectiveBeamAttachment1"
	attachment1.Parent = target

	local beam = Instance.new("Beam")
	beam.Name = "ObjectiveDirectionBeam"
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.FaceCamera = true
	beam.Width0 = OBJECTIVE_BEAM_WIDTH
	beam.Width1 = OBJECTIVE_BEAM_WIDTH
	beam.Texture = OBJECTIVE_BEAM_TEXTURE
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 2
	beam.TextureSpeed = OBJECTIVE_BEAM_TEXTURE_SPEED
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new(0.1)
	beam.Parent = hrp

	self.ObjectiveBeamAttachment0 = attachment0
	self.ObjectiveBeamAttachment1 = attachment1
	self.ObjectiveBeam = beam

	self.ObjectiveBeamUpdateConnection = target.AncestryChanged:Connect(function()
		if not target:IsDescendantOf(workspace) then
			self:_DestroyObjectiveBeam()
		end
	end)
end

function QuestController:QuestUpdated(questName, state)
	if not self.Quests[questName] then
		self:SetupQuest(questName, state, nil, true)
		return
	end

	self.QuestStates[questName] = state
	self.Quests[questName]:StateSet(state)
	if self.SelectedQuestName == questName then
		Knit.ScreenController:GetScreen("Quest"):SetupQuestUI(questName, state)
	end
end

function QuestController:SetObjectiveMarkers(adornees, questName)
	questName = questName or self.SelectedQuestName
	if not questName then
		return
	end

	self.QuestMarkers[questName] = adornees
	if questName == self.SelectedQuestName then
		self:_RenderObjectiveMarkers()
	end
end

function QuestController:_RenderObjectiveMarkers()
	OBJECTIVE_MARKERS:ClearAllChildren()
	for _, adornee in self.QuestMarkers[self.SelectedQuestName] or {} do
		if not adornee:IsDescendantOf(workspace) then
			continue
		end

		local marker = BILLBOARDS.ObjectiveTemplate:Clone()
		marker.Enabled = self.ObjectiveMarkersEnabled
		marker.Adornee = adornee
		marker.Parent = OBJECTIVE_MARKERS
	end

	self:_RefreshObjectiveBeam()
end

function QuestController:ToggleObjectiveMarkers(enabled)
	if
		self.SelectedQuestName == "AnniversaryQuest"
		and Knit.Player:GetAttribute("AnniversaryQuestComplete") == true
	then
		enabled = false
	end

	self.ObjectiveMarkersEnabled = enabled
	for _, marker in OBJECTIVE_MARKERS:GetChildren() do
		marker.Enabled = enabled
	end

	self:_RefreshObjectiveBeam()
end

function QuestController:RemoveObjectiveMarker(adornee)
	for _, marker in OBJECTIVE_MARKERS:GetChildren() do
		if marker.Adornee ~= adornee then
			continue
		end

		marker:Destroy()
		break
	end

	self:_RefreshObjectiveBeam()
end

-- default

function QuestController:KnitStart()
	QuestService = Knit.GetService("QuestService")

	-- Subscribe before loading saved quests so new quest events cannot be missed.
	QuestService.QuestReceived:Connect(function(questName, state)
		self:SetupQuest(questName, state)
	end)

	QuestService.QuestUpdated:Connect(function(questName, state)
		self:QuestUpdated(questName, state)
	end)

	local success, activeQuests = QuestService:GetActiveQuests():await()
	if success then
		local names = {}
		for questName in activeQuests do
			table.insert(names, questName)
		end

		table.sort(names)
		for _, questName in names do
			if not self.QuestStates[questName] then
				local data = activeQuests[questName]
				self:SetupQuest(questName, data.State, data, true)
			end
		end
	end

	Knit.Player.CharacterAdded:Connect(function()
		self:_RefreshObjectiveBeam()
	end)
end

function QuestController:KnitInit() end

return QuestController
