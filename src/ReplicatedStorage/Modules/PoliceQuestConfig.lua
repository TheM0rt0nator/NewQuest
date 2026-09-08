local PoliceQuestConfig = {
	Items = {
		{ Id = "Phone", Label = "Phone" },
		{ Id = "Wallet", Label = "Wallet" },
		{ Id = "Keys", Label = "Keys" },
		{ Id = "Lockpick", Label = "Lockpick" },
		{ Id = "Radio", Label = "Radio" },
		{ Id = "Watch", Label = "Watch" },
	},
	ScanDuration = 5,
	PhotoDuration = 1.5,
	WalkSpeed = 7,
	InteractionDistance = 9,
	DepartureDelay = 6,
	Routes = {
		[9] = { "LobbyWalk", "LobbyTurn", "BookingTurn" },
		[12] = { "BookingExit", "CellHallSouth", "CellHallCorner", "CellHallNorth" },
	},
}

return PoliceQuestConfig
