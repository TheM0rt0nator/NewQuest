local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cutscene = require(ReplicatedStorage.Modules.Cutscene)

local Steps = Cutscene.Steps

local function say(speaker, text)
	return Steps.Dialog({ { speaker = speaker, text = text } })
end

return function(stage, onReady)
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
			for _, name in { "PlayerSeat", "Wide", "Teacher", "Maya", "Leo", "Amira", "Player" } do
				context:GetCFrame(name)
			end
		end,
		Steps = {
			Steps.Camera("Wide", 0, 60),
			Steps.Call(function(context)
				context:Wait(0.1)
				onReady()
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
			Steps.Camera("Teacher", 0.8, 52),
			say("MS TAYLOR", "That's a wonderful reason, Maya. How about you, Leo?"),
			Steps.Camera("Leo", 1, 50),
			say(
				"LEO",
				"A pilot! I'd fly all over the world. Maybe I'll take the whole class one day!"
			),
			Steps.Camera("Amira", 1, 50),
			say("MS TAYLOR", "And you, Amira? What would you like to be?"),
			say("AMIRA", "I'd be an artist. I want to make pictures that tell stories."),
			Steps.Camera("Teacher", 1, 52),
			say(
				"MS TAYLOR",
				"A doctor, a pilot, and an artist. Every dream starts with a little curiosity."
			),
			Steps.Camera(function(context)
				local seat = context.Data.StudentSeat
				local focus = seat.Position + Vector3.new(0, 2.4, 0)
				return CFrame.lookAt(focus + Vector3.new(7, 0.8, -3), focus)
			end, 1.2, 52),
			say("MS TAYLOR", "And what about you? What would you like to be when you grow up?"),
			Steps.Wait(1.5),
			Steps.Call(function(context)
				context.Data.ClassroomFinished = true
			end),
		},
	}
end
