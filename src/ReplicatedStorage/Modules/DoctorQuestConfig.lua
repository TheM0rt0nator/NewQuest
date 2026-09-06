local DoctorQuestConfig = {
	TaskIds = { "Medicine", "Shock", "Scalpel", "Bandage", "BloodBag", "Injection" },
	Tasks = {
		Medicine = { Label = "Medicine", Action = "Give medicine", Color = Color3.fromRGB(93, 187, 203) },
		Shock = { Label = "Shock", Action = "Use defibrillator", Color = Color3.fromRGB(250, 198, 72) },
		Scalpel = { Label = "Scalpel", Action = "Perform surgery", Color = Color3.fromRGB(180, 206, 220) },
		Bandage = { Label = "Bandage", Action = "Apply bandage", Color = Color3.fromRGB(236, 227, 203) },
		BloodBag = { Label = "Blood bag", Action = "Replace blood bag", Color = Color3.fromRGB(192, 76, 92) },
		Injection = { Label = "Injection", Action = "Give injection", Color = Color3.fromRGB(136, 175, 232) },
	},
	TreatmentDuration = 8,
	WarningFraction = 0.75,
	NormalBeatInterval = 0.85,
	BeatIntervalIncrease = 0.28,
	BeepSoundId = "rbxassetid://172905765",
}

return DoctorQuestConfig
