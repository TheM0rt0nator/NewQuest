local MQ_PLACE_ID = 99606216494108
local MQ_ANNIVERSARY_PLACE_ID = 133860577693306
local MAIN_ANNIVERSARY_PLACE_ID = 71485985593556
local SECRET_QUEST_HINT = "A little style, a sip of sweetness, a touch of colour..."
	.. " Bring three small finds back to my roots."

local anniversaryDestinationPlaceId = game.PlaceId == MQ_PLACE_ID and MQ_ANNIVERSARY_PLACE_ID
	or MAIN_ANNIVERSARY_PLACE_ID

return {
	SecretQuest = {
		DisplayName = "SECRET QUEST",
		Description = "A curious discovery.",
		Objectives = {
			{
				DisplayName = SECRET_QUEST_HINT,
				Type = "Event",
			},
			{
				DisplayName = "Completed!",
				Type = "Event",
			},
		},
	},

	AnniversaryQuest = {
		DisplayName = "ANNIVERSARY QUEST",
		Description = "Join the anniversary adventure.",
		DestinationPlaceId = anniversaryDestinationPlaceId,
		Objectives = {
			{
				DisplayName = "Meet Roblox at the celebration to start the anniversary quest",
				Type = "Event",
			},
			{
				-- The next quest step will be implemented here; arriving does not complete the whole quest.
				DisplayName = "Continue the anniversary adventure",
				Type = "Event",
			},
			{
				-- The existing quest UI expects the last objective to be the completion state.
				DisplayName = "Completed!",
				Type = "Event",
			},
		},
	},

	AcaiBowlQuest = {
		DisplayName = "The Hunt: Learn a new recipe",
		Description = "Make an Acai Bowl",
		Objectives = {
			{
				DisplayName = "Collect a bowl from the smoothie shop",
				Type = "Event",
			},
			{
				DisplayName = "Collect an acai tub from the smoothie shop",
				Type = "Event",
			},
			{
				DisplayName = "Grab a shopping trolley and collect 3 fruits from the grocery store",
				Type = "Progress",
				Goal = 3,
			},
			{
				DisplayName = "Pay for your shopping",
				Type = "Event",
			},
			{
				DisplayName = "Collect your shopping bag",
				Type = "Event",
			},
			{
				DisplayName = "Spawn a house or apartment",
				Type = "Event",
			},
			{
				DisplayName = "Go to your house and store your groceries in the fridge",
				Type = "Event",
			},
			{
				DisplayName = "Make the Acai Bowl",
				Type = "Event",
			},
			{
				DisplayName = "Completed! You have unlocked a new recipe: the Acai Bowl!",
				Type = "Event",
			},
		},
		CompletionBadgeId = 1319345198887520,
	},

	RoseQuest = {
		DisplayName = "ROSE QUEST",
		Description = "Explore Seould and discover the new album!",
		Objectives = {
			{
				DisplayName = "Collect a bowl from the smoothie shop",
				Type = "Event",
			},
		},
	},

	SeoulDanceQuest = {
		DisplayName = "SEOUL STAR QUEST",
		Description = "Travel to Seoul and perform on stage.",
		Objectives = {
			{
				DisplayName = "Teleport from Berry Avenue to Seoul",
				Type = "Event",
			},
			{
				DisplayName = "Go to the Seoul Dance Studio",
				Type = "Event",
			},
			{
				DisplayName = "Turn on the dance studio boombox",
				Type = "Event",
			},
			{
				DisplayName = "Do the CELEBRATION Pose from the Actions menu in the dance studio",
				Type = "Event",
			},
			{
				DisplayName = "Go to the Seoul Concert Hall",
				Type = "Event",
			},
			{
				DisplayName = "Do the CELEBRATION Pose from the Actions menu in the concert hall",
				Type = "Event",
			},
			{
				DisplayName = "Go back to the Seoul Dance Studio",
				Type = "Event",
			},
			{
				DisplayName = "Take the elevator to the CELEBRATION room",
				Type = "Event",
			},
			{
				DisplayName = "Completed!",
				Type = "Event",
			},
		},
	},
}
