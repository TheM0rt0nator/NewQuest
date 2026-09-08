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

	function player:GetAttribute(name)
		return attributes[name]
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
			QuestService:GetObjective(player).ResumeStage == "DoctorQuest",
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

		assert(QuestService:PrepareDoctorRun(player), "Doctor order was not prepared")

		local order = QuestService:GetQuestData(player, "AnniversaryQuest").Destination.Doctor.Order
		local seen = {}

		for _, taskId in order do
			assert(not seen[taskId], "Doctor task appeared twice")
			seen[taskId] = true
		end

		assert(#order == 6, "Doctor task order is incomplete")
		assert(not QuestService:PickUpDoctorItem(player, order[1]), "Pickup allowed during intro")
		assert(
			QuestService:CompleteObjective(player, "AnniversaryQuest", 2),
			"Doctor intro did not finish"
		)
		assert(not QuestService:PickUpDoctorItem(player, order[2]), "Wrong item accepted")
		assert(QuestService:PickUpDoctorItem(player, order[1]), "Correct item rejected")
		assert(not QuestService:PickUpDoctorItem(player, order[1]), "Duplicate pickup accepted")
		QuestService:RemovePlayer(player)
		assert(QuestService:LoadPlayer(player), "Doctor checkpoint did not reopen")

		local restored = QuestService:GetQuestData(player, "AnniversaryQuest").Destination.Doctor
		assert(restored.Carrying and restored.Order[1] == order[1], "Held item or order was lost")

		for index, taskId in order do
			if index > 1 then
				assert(QuestService:PickUpDoctorItem(player, taskId), "Next pickup failed")
			end

			assert(
				not QuestService:CompleteDoctorTask(player, taskId, index),
				"Stale progress accepted"
			)
			assert(
				QuestService:CompleteDoctorTask(player, taskId, index - 1),
				"Treatment did not save"
			)
			assert(
				not QuestService:CompleteDoctorTask(player, taskId, index - 1),
				"Duplicate treatment accepted"
			)
		end

		assert(attributes.QuestState == 4, "Doctor shift did not finish")
		assert(
			not QuestService:PickUpDoctorItem(player, order[1]),
			"Completed shift allowed a pickup"
		)
		QuestService:RemovePlayer(player)
		assert(QuestService:LoadPlayer(player), "Completed shift did not reopen")
		assert(attributes.QuestState == 4, "Completed shift replayed after reload")
		assert(QuestService:CompleteObjective(player, "AnniversaryQuest", 4), "Leo did not unlock")
		assert(attributes.QuestState == 5, "Leo's existing checkpoint changed")
		assert(
			QuestService:CompleteObjective(player, "AnniversaryQuest", 5),
			"Police job did not unlock"
		)
		assert(attributes.QuestState == 8, "Police job collided with existing finale IDs")
		assert(
			not QuestService:ConfiscatePoliceItem(player, "Phone"),
			"Search allowed during entrance"
		)
		assert(
			QuestService:CompleteObjective(player, "AnniversaryQuest", 8),
			"Police entrance failed"
		)
		assert(not QuestService:ConfiscatePoliceItem(player, "Unknown"), "Unknown item accepted")
		assert(QuestService:ConfiscatePoliceItem(player, "Phone"), "Item confiscation failed")
		assert(not QuestService:ConfiscatePoliceItem(player, "Phone"), "Duplicate item accepted")
		QuestService:RemovePlayer(player)
		assert(QuestService:LoadPlayer(player), "Police checkpoint did not reload")
		assert(
			attributes.QuestState == 9 and attributes.QuestProgress == 1,
			"Search progress was lost"
		)
		assert(attributes.PoliceConfiscated_Phone, "Confiscated item returned")

		for _, id in { "Wallet", "Keys", "Lockpick", "Radio", "Watch" } do
			assert(QuestService:ConfiscatePoliceItem(player, id), "Remaining search item failed")
		end

		assert(attributes.QuestState == 10, "Fingerprints did not unlock")

		for state = 10, 14 do
			assert(
				QuestService:CompleteObjective(player, "AnniversaryQuest", state),
				"Booking stage failed"
			)
			assert(
				not QuestService:CompleteObjective(player, "AnniversaryQuest", state),
				"Stale booking action accepted"
			)
			QuestService:RemovePlayer(player)
			assert(QuestService:LoadPlayer(player), "Booking checkpoint did not reload")
			assert(attributes.QuestState == state + 1, "Booking checkpoint was lost")
		end

		assert(not attributes.QuestCompleted, "Police job completed the entire quest")
		assert(
			QuestService:CompleteObjective(player, "AnniversaryQuest", 15),
			"Finale did not unlock"
		)
		assert(attributes.QuestState == 16, "Flight chapter did not unlock")

		for state = 16, 21 do
			if state == 20 then
				assert(QuestService:UpdateProgress(player, "AnniversaryQuest", 2))
				QuestService:RemovePlayer(player)
				assert(QuestService:LoadPlayer(player))
				assert(attributes.QuestProgress == 2, "Delivered meals were lost on resume")
			end

			assert(QuestService:CompleteObjective(player, "AnniversaryQuest", state))
			assert(not QuestService:CompleteObjective(player, "AnniversaryQuest", state))
			QuestService:RemovePlayer(player)
			assert(QuestService:LoadPlayer(player), "Flight checkpoint did not reload")
			assert(attributes.QuestState == (state == 21 and 6 or state + 1))
		end

		assert(attributes.QuestState == 6, "Original finale checkpoint was changed")
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
