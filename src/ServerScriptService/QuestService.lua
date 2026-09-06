-- Uses the same ProfileStore envelope, store name, and keys as Berry Avenue.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.ServerPackages.ProfileStore)
local QuestConfig = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local DoctorConfig = require(ReplicatedStorage.Modules.DoctorQuestConfig)

local QUEST_NAME = QuestConfig.Name
local OBJECTIVES = QuestConfig.Objectives

local function nextStateId(currentState)
	if
		currentState == QuestConfig.States.DoctorComplete
		and not QuestConfig.EnablePoliceClassroom
	then
		return QuestConfig.States.ClassroomFinale
	end
	return currentState + 1
end

local QuestService = {}
local profiles = {}
local stateChanged = Instance.new("BindableEvent")
QuestService.StateChanged = stateChanged.Event
local playerStore = ProfileStore.New("PlayerData_LIVE", { Quests = {} })

if RunService:IsStudio() then
	playerStore = playerStore.Mock
end

local function copy(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}
	for key, child in value do
		result[key] = copy(child)
	end
	return result
end

local function prepareQuest(data)
	-- Preserve the full Berry Avenue profile and all unrelated quests.
	data.Quests = data.Quests or {}
	local quest = data.Quests[QUEST_NAME]
	if not quest then
		quest = {
			Active = true,
			Completed = false,
			State = { Id = 2, Type = "Event", DisplayName = "Continue the anniversary adventure" },
		}
		data.Quests[QUEST_NAME] = quest
	end

	if not quest.Completed and quest.State and quest.State.Id == 1 then
		quest.State = { Id = 2, Type = "Event", DisplayName = "Continue the anniversary adventure" }
	end

	-- The entrance owns the outer state; this place owns its chapter checkpoints.
	if not quest.Destination then
		quest.Destination = {
			Version = 1,
			State = table.clone(OBJECTIVES[quest.Completed and 2 or 1]),
		}
	end

	local destination = quest.Destination
	assert(destination.Version == 1, "Unsupported anniversary chapter version")
	assert(type(destination.State) == "table", "Invalid anniversary chapter state")
	assert(OBJECTIVES[destination.State.Id], "Unknown anniversary chapter objective")
	if
		destination.State.Id == QuestConfig.States.PoliceClassroom
		and not QuestConfig.EnablePoliceClassroom
	then
		destination.State = table.clone(OBJECTIVES[QuestConfig.States.ClassroomFinale])
	end
	-- Keep completed care tasks when resuming an older randomized doctor run.
	local doctor = destination.Doctor
	if doctor and (destination.State.Id == 2 or destination.State.Id == 3) then
		local shockIndex = table.find(doctor.Order, DoctorConfig.FinalTaskId)
		if shockIndex and shockIndex ~= #doctor.Order then
			local progress = destination.State.Progress
			local heldTask = doctor.Carrying and doctor.Order[progress + 1]
			table.remove(doctor.Order, shockIndex)
			table.insert(doctor.Order, DoctorConfig.FinalTaskId)
			if shockIndex <= progress then
				-- A previously used Shock must be performed again as the final treatment.
				destination.State.Progress = progress - 1
			end
			doctor.Carrying = heldTask == doctor.Order[destination.State.Progress + 1]
		end
	end
	return quest
end

local function replicate(player)
	local quest = profiles[player].Data.Quests[QUEST_NAME]
	local state = quest.Destination.State
	player:SetAttribute("QuestState", state.Id)
	player:SetAttribute("QuestProgress", state.Progress)
	player:SetAttribute("QuestObjective", OBJECTIVES[state.Id].Description)
	player:SetAttribute("QuestStateKey", OBJECTIVES[state.Id].Key)
	player:SetAttribute("QuestCompleted", quest.Completed == true)
	player:SetAttribute("ClassroomIntroEligible", QuestService:IsClassroomIntroStep(player))
	player:SetAttribute(
		"DoctorQuestEligible",
		QuestService:IsActiveStep(player, state.Id) and state.Id >= 2 and state.Id <= 4
	)
	local doctor = quest.Destination.Doctor
	player:SetAttribute("DoctorTask", doctor and doctor.Order[state.Progress + 1] or nil)
	player:SetAttribute("DoctorCarrying", doctor and doctor.Carrying == true or false)
end

function QuestService:IsActiveStep(player, expectedState)
	local profile = profiles[player]
	local quest = profile and profile.Data.Quests[QUEST_NAME]
	return profile ~= nil
		and profile:IsActive()
		and quest ~= nil
		and quest.Active == true
		and quest.Completed ~= true
		and quest.State ~= nil
		and quest.State.Id == QuestConfig.AdventureStateId
		and quest.Destination.State.Id == expectedState
end

function QuestService:IsClassroomIntroStep(player)
	return self:IsActiveStep(player, QuestConfig.States.ClassroomIntro)
end

function QuestService:GetObjective(player)
	local profile = profiles[player]
	local quest = profile and profile.Data.Quests[QUEST_NAME]
	return quest and table.clone(OBJECTIVES[quest.Destination.State.Id]) or nil
end

function QuestService:LoadPlayer(player)
	if profiles[player] then
		return true
	end

	local profile = playerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		if player.Parent == Players then
			player:Kick("Your quest data could not load. Please rejoin to try again.")
		end
		return false
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	local ok, reason = pcall(prepareQuest, profile.Data)
	if not ok or player.Parent ~= Players then
		profile:EndSession()
		if not ok then
			warn("[QuestService]", reason)
			player:Kick("Your quest data needs attention. Please try again later.")
		end
		return false
	end

	profiles[player] = profile
	profile.OnSessionEnd:Connect(function()
		if profiles[player] == profile then
			profiles[player] = nil
			player:SetAttribute("QuestDataReady", false)
			player:SetAttribute("ClassroomIntroEligible", false)
			player:SetAttribute("DoctorQuestEligible", false)
			if player.Parent == Players then
				player:Kick("Your data session ended. Please rejoin.")
			end
		end
	end)
	profile.OnAfterSave:Connect(function()
		if profiles[player] == profile then
			player:SetAttribute(
				"QuestSaveStatus",
				RunService:IsStudio() and "Studio session" or "Saved"
			)
		end
	end)

	replicate(player)
	player:SetAttribute("QuestSaveStatus", RunService:IsStudio() and "Studio session" or "Loaded")
	player:SetAttribute("QuestDataReady", true)
	return true
end

function QuestService:GetQuestData(player, questName)
	local profile = profiles[player]
	return profile and copy(profile.Data.Quests[questName]) or nil
end

function QuestService:GetCurrentQuest(player)
	return QUEST_NAME, self:GetQuestData(player, QUEST_NAME)
end

function QuestService:SetState(player, questName, newState)
	if questName ~= QUEST_NAME then
		return false
	end
	local profile = profiles[player]
	local quest = profile and profile.Data.Quests[questName]
	if not profile or not quest or not self:IsActiveStep(player, quest.Destination.State.Id) then
		return false
	end
	if not OBJECTIVES[newState] or newState ~= nextStateId(quest.Destination.State.Id) then
		return false
	end

	quest.Destination.State = table.clone(OBJECTIVES[newState])
	replicate(player)
	stateChanged:Fire(player, newState)
	player:SetAttribute("QuestSaveStatus", RunService:IsStudio() and "Studio session" or "Saving")
	profile:Save()
	return true
end

function QuestService:UpdateProgress(player, questName, newProgress)
	if questName ~= QUEST_NAME then
		return false
	end
	local profile = profiles[player]
	local quest = profile and profile.Data.Quests[questName]
	if not profile or not quest or not self:IsActiveStep(player, quest.Destination.State.Id) then
		return false
	end
	local state = quest.Destination.State
	if type(newProgress) ~= "number" or newProgress ~= newProgress then
		return false
	end
	if newProgress % 1 ~= 0 or newProgress < state.Progress or newProgress > state.Goal then
		return false
	end

	state.Progress = newProgress
	local nextState = nextStateId(state.Id)
	if newProgress == state.Goal and OBJECTIVES[nextState] then
		return self:SetState(player, questName, nextState)
	end
	replicate(player)
	profile:Save()
	return true
end

-- Use an expected state for asynchronous gameplay events so duplicate or late
-- callbacks cannot accidentally complete the following objective.
function QuestService:CompleteObjective(player, questName, expectedState)
	local quest = self:GetQuestData(player, questName)
	if not quest or not quest.Destination or quest.Destination.State.Id ~= expectedState then
		return false
	end
	return self:UpdateProgress(player, questName, quest.Destination.State.Goal)
end

function QuestService:RemovePlayer(player)
	local profile = profiles[player]
	profiles[player] = nil
	if profile then
		profile:EndSession()
	end
end

function QuestService:CompleteFinale(player)
	if not self:IsActiveStep(player, QuestConfig.States.ClassroomFinale) then
		return false
	end
	local profile = profiles[player]
	local quest = profile.Data.Quests[QUEST_NAME]
	quest.Destination.State = table.clone(OBJECTIVES[QuestConfig.States.QuestComplete])
	quest.Completed = true
	quest.Active = false
	replicate(player)
	stateChanged:Fire(player, QuestConfig.States.QuestComplete)
	profile:Save()
	return true
end

function QuestService:WaitForCompletionSave(player)
	local profile = profiles[player]
	if not profile then
		return false
	end
	local deadline = os.clock() + 25
	repeat
		local saved = profile.LastSavedData.Quests
		local quest = saved and saved[QUEST_NAME]
		if
			quest and quest.Completed and quest.Destination
			and quest.Destination.State.Id == QuestConfig.States.QuestComplete
		then
			return true
		end
		if profiles[player] ~= profile or not profile:IsActive() then
			return false
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return false
end

-- The shuffled order and held item live in the shared profile alongside the checkpoint.
function QuestService:PrepareDoctorRun(player)
	if
		not self:IsActiveStep(player, QuestConfig.States.DoctorIntro)
		and not self:IsActiveStep(player, QuestConfig.States.DoctorTasks)
	then
		return false
	end
	local profile = profiles[player]
	local destination = profile.Data.Quests[QUEST_NAME].Destination
	if not destination.Doctor then
		local order = table.clone(DoctorConfig.TaskIds)
		local random = Random.new()
		-- Shuffle the first five supplies, leaving Shock last for the red monitor.
		for index = #order - 1, 2, -1 do
			local other = random:NextInteger(1, index)
			order[index], order[other] = order[other], order[index]
		end
		destination.Doctor = { Order = order, Carrying = false }
		profile:Save()
	end
	replicate(player)
	return true
end

function QuestService:PickUpDoctorItem(player, taskId)
	if not self:IsActiveStep(player, QuestConfig.States.DoctorTasks) then
		return false
	end
	local profile = profiles[player]
	local destination = profile.Data.Quests[QUEST_NAME].Destination
	local doctor = destination.Doctor
	if not doctor or doctor.Carrying or doctor.Order[destination.State.Progress + 1] ~= taskId then
		return false
	end
	doctor.Carrying = true
	replicate(player)
	profile:Save()
	return true
end

function QuestService:CompleteDoctorTask(player, taskId, expectedProgress)
	if not self:IsActiveStep(player, QuestConfig.States.DoctorTasks) then
		return false
	end
	local destination = profiles[player].Data.Quests[QUEST_NAME].Destination
	local doctor = destination.Doctor
	local progress = destination.State.Progress
	if
		not doctor
		or not doctor.Carrying
		or progress ~= expectedProgress
		or doctor.Order[progress + 1] ~= taskId
	then
		return false
	end
	doctor.Carrying = false
	return self:UpdateProgress(player, QUEST_NAME, progress + 1)
end

return QuestService
