-- Manual Studio-only tests. Uses ProfileStore.Mock, never live player records.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.ServerPackages.ProfileStore)
local QuestService = require(script.Parent.QuestService)

return function()
	assert(RunService:IsStudio(), "Quest tests may only run in Studio")
	local attributes = {}
	local player = { UserId = 987654321, Parent = Players }
	function player:SetAttribute(name, value)
		attributes[name] = value
	end
	function player:Kick(reason)
		error(reason)
	end

	local mockStore = ProfileStore.New("PlayerData_LIVE", {}).Mock
	local key = "Player_" .. player.UserId
	local seed = mockStore:StartSessionAsync(key)
	assert(seed, "Could not prepare mock profile")
	seed.Data = {
		Wallet = { Coins = 321 },
		Quests = {
			RoseQuest = { Completed = true },
			AnniversaryQuest = { Active = true, State = { Id = 1 } },
		},
	}
	seed:EndSession()

	local ok, reason = xpcall(function()
		assert(QuestService:LoadPlayer(player), "Could not load mock profile")
		local quest = QuestService:GetQuestData(player, "AnniversaryQuest")
		assert(quest.State.Id == 2, "Arrival did not retain Berry Avenue's adventure state")
		assert(quest.Destination.State.Id == 1, "New chapter did not start at its first objective")
		assert(QuestService:IsClassroomIntroStep(player), "The intro step was not eligible")
		assert(
			QuestService:GetObjective(player).ResumeMarker == "Arrival",
			"Wrong intro resume location"
		)
		assert(
			not QuestService:SetState(player, "AnniversaryQuest", 99),
			"Unknown objective accepted"
		)
		assert(not QuestService:UpdateProgress(player, "AnniversaryQuest", 0 / 0), "NaN accepted")
		assert(
			not QuestService:UpdateProgress(player, "AnniversaryQuest", -1),
			"Negative progress accepted"
		)
		assert(
			QuestService:UpdateProgress(player, "AnniversaryQuest", 1),
			"Objective did not advance"
		)
		quest = QuestService:GetQuestData(player, "AnniversaryQuest")
		assert(not QuestService:IsClassroomIntroStep(player), "A later step allowed the intro")
		assert(
			not QuestService:CompleteObjective(player, "AnniversaryQuest", 1),
			"Duplicate completion was accepted"
		)
		assert(QuestService:GetObjective(player).Key == "YourFuture", "Wrong next stage")
		assert(
			QuestService:GetObjective(player).ResumeMarker == "YourFutureArrival",
			"Wrong next-stage resume location"
		)
		assert(
			quest.Destination.State.Id == 2 and not quest.Completed,
			"Intro completed the whole quest"
		)
		assert(not QuestService:SetState(player, "AnniversaryQuest", 1), "Progress moved backwards")
		quest.Destination.State.Id = 99
		assert(attributes.QuestState == 2, "Checkpoint was not replicated")
		assert(
			QuestService:GetQuestData(player, "AnniversaryQuest").Destination.State.Id == 2,
			"Mutable data escaped"
		)

		QuestService:RemovePlayer(player)
		assert(QuestService:LoadPlayer(player), "Mock profile did not reopen")
		assert(
			QuestService:GetQuestData(player, "AnniversaryQuest").Destination.State.Id == 2,
			"Checkpoint was not saved"
		)
		QuestService:RemovePlayer(player)

		local saved = mockStore:StartSessionAsync(key)
		assert(saved, "Could not verify mock profile")
		local preserved = saved.Data.Wallet.Coins == 321 and saved.Data.Quests.RoseQuest.Completed
		saved:EndSession()
		assert(preserved, "Unrelated Berry Avenue profile data changed")
	end, debug.traceback)

	QuestService:RemovePlayer(player)
	assert(ok, reason)
	print("QuestService tests passed: checkpoint, mock reload, and profile preservation")
end
