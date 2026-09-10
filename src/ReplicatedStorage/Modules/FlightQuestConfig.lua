local FlightQuestConfig = {
	TakeoffSoundId = "rbxassetid://16880017184",
	CruiseSoundId = "rbxassetid://16882075643",
	InteractionDistance = 10,
	SceneDurations = { [16] = 14, [17] = 24, [19] = 24, [21] = 8 },
	Meals = { "Sandwich", "Salad", "Pasta" },
	Passengers = {
		{ Name = "Sofia", Seat = "Seat1", Meal = "Sandwich" },
		{ Name = "Ben", Seat = "Seat17", Meal = "Pasta" },
		{ Name = "Maya", Seat = "Seat6", Meal = "Salad" },
		{ Name = "Noah", Seat = "Seat20", Meal = "Sandwich" },
		{ Name = "Amira", Seat = "Seat9", Meal = "Salad" },
		{ Name = "Leo", Seat = "Seat23", Meal = "Pasta" },
	},
	SeatbeltPassenger = "Ben",
}

return FlightQuestConfig
