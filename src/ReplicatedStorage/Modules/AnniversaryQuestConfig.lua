-- Stable state IDs are saved in the shared player profile. Append new stages;
-- do not renumber existing states when adding the rest of the adventure.
local AnniversaryQuestConfig = {
	Name = "AnniversaryQuest",
	AdventureStateId = 2,
	States = {
		ClassroomIntro = 1,
		YourFuture = 2,
		DoctorIntro = 2, -- Preserve the previously saved YourFuture checkpoint.
		DoctorTasks = 3,
		DoctorComplete = 4,
	},
	Objectives = {
		{
			Id = 1,
			Key = "ClassroomIntro",
			Type = "Event",
			Goal = 1,
			Progress = 0,
			Description = "Listen to your classmates' dreams",
			ResumeMarker = "Arrival",
			Cutscene = "ClassroomIntro",
		},
		{
			Id = 2,
			Key = "YourFuture",
			Type = "Event",
			Goal = 1,
			Progress = 0,
			Description = "Your first shift as a doctor",
			ResumeStage = "DoctorQuest",
			ResumeMarker = "Arrival",
			Cutscene = "DoctorIntro",
		},
		{
			Id = 3,
			Key = "DoctorTasks",
			Type = "Event",
			Goal = 6,
			Progress = 0,
			Description = "Complete the patient care board",
			ResumeStage = "DoctorQuest",
			ResumeMarker = "Arrival",
		},
		{
			Id = 4,
			Key = "DoctorComplete",
			Type = "Event",
			Goal = 1,
			Progress = 0,
			Description = "Doctor shift complete — the patient is stable",
			ResumeStage = "DoctorQuest",
			ResumeMarker = "Arrival",
		},
	},
}

return AnniversaryQuestConfig
