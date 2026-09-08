local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cutscene = require(ReplicatedStorage.Modules.Cutscene)

local Steps = Cutscene.Steps

local function say(speaker, text)
	return Steps.Dialog({ { speaker = speaker, text = text } })
end

return function(stage, onReady, onDream)
	return {
		Id = "ClassroomIntro",
		Markers = stage.Markers,
		Bars = { barHeight = 0.08, animationTime = 0.35 },
		Validate = function(context)
			local humanoid = context.Player.Character:FindFirstChildOfClass("Humanoid")
			assert(
				context.Data.StudentSeat
					and humanoid
					and humanoid.Sit
					and humanoid.SeatPart == context.Data.StudentSeat,
				"Student must be seated before playback"
			)

			for _, name in { "PlayerSeat", "Wide", "Teacher", "Maya" } do
				context:GetCFrame(name)
			end
		end,

		Steps = {
			Steps.Camera("Wide", 0, 60),
			Steps.Call(function(context)
				context:Wait(0.1)
				onReady(context)
			end),

			Steps.Wait(1),
			say("MS TAYLOR", "Before we begin, let's talk about your futures."),
			Steps.Camera("Teacher", 1.2, 52),
			say(
				"MS TAYLOR",
				"What would you like to be when you grow up? Maya, shall we start with you?"
			),
			Steps.Camera("Maya", 1, 50),
			say(
				"MAYA",
				"I want to be a doctor! I want to help people feel better when they're poorly."
			),

			-- Completing Maya's dream advances the checkpoint to DoctorIntro.
			Steps.Call(function(context)
				if onDream then
					onDream(context)
				end

				context.Data.ClassroomFinished = true
			end),
		},
	}
end
