local Steps = require(game.ReplicatedStorage.Modules.Cutscene).Steps

return function(stage, onReady, onDream)
	return {
		Id = "FlightClassroom",
		ReturnToPlayer = true,
		Markers = stage.Markers,
		Bars = { barHeight = 0.08, animationTime = 0.35 },
		Validate = function(context)
			local humanoid = context.Player.Character:FindFirstChildOfClass("Humanoid")
			assert(
				humanoid and humanoid.SeatPart == context.Data.StudentSeat,
				"Student is not seated"
			)

			for _, name in { "Wide", "Teacher", "Amira" } do
				context:GetCFrame(name)
			end
		end,

		Steps = {
			Steps.Camera("Wide", 0, 60),
			Steps.Call(onReady),
			Steps.Camera("Teacher", 1, 52),
			Steps.Dialog({
				{
					speaker = "MS TAYLOR",
					text = "Thank you, Leo. Amira, what would you like to be when you grow up?",
				},
			}),
			Steps.Camera("Amira", 1, 50),
			Steps.Dialog({
				{
					speaker = "AMIRA",
					text = "I want to be an air hostess! "
						.. "I'd love to travel the world and help everyone have a safe, happy flight.",
				},
			}),

			-- Cover Amira's shot before the runner restores the camera and bars.
			Steps.Call(function(context)
				if onDream then
					onDream(context)
				end
			end),
		},
	}
end
