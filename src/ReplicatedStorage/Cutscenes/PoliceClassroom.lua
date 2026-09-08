local Steps = require(game.ReplicatedStorage.Modules.Cutscene).Steps

return function(stage, onReady, onDream)
	return {
		Id = "PoliceClassroom",
		ReturnToPlayer = true,
		Markers = stage.Markers,
		Bars = { barHeight = 0.08, animationTime = 0.35 },
		Validate = function(context)
			local humanoid = context.Player.Character:FindFirstChildOfClass("Humanoid")
			assert(
				humanoid and humanoid.SeatPart == context.Data.StudentSeat,
				"Student is not seated"
			)

			for _, name in { "Wide", "Teacher", "Leo" } do
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
					text = "Thank you, Maya. Leo, what would you like to be when you grow up?",
				},
			}),
			Steps.Camera("Leo", 1, 50),
			Steps.Dialog({
				{
					speaker = "LEO",
					text = "I want to be a police officer! "
						.. "I want to help people and keep everyone safe.",
				},
			}),

			-- Cover Leo's shot before the runner restores the camera and retracts the bars.
			Steps.Call(function(context)
				if onDream then
					onDream(context)
				end
			end),
		},
	}
end
