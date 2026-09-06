local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)
local Steps = require(ReplicatedStorage.Modules.Cutscene).Steps

return function(stage, onReady)
	return {
		Id = "ClassroomFinale",
		ReturnToPlayer = true,
		Markers = stage.Markers,
		Bars = { barHeight = 0.08, animationTime = 0.35 },
		Validate = function(context)
			local humanoid = context.Player.Character:FindFirstChildOfClass("Humanoid")
			assert(
				humanoid and humanoid.SeatPart == context.Data.StudentSeat,
				"Student is not seated"
			)
		end,
		Steps = {
			Steps.Camera("Wide", 0, 60),
			Steps.Call(function(context)
				local bell = Instance.new("Sound")
				bell.Name = "SchoolBell"
				bell.SoundId = Config.SchoolBellSoundId
				bell.Volume = 0.65
				bell.Parent = SoundService
				context.Data.SchoolBell = bell
				context:Defer(function()
					bell:Destroy()
				end)
				task.spawn(function()
					pcall(function()
						ContentProvider:PreloadAsync({ bell })
					end)
				end)
				onReady(context)
			end),
			Steps.Camera("Teacher", 1.2, 52),
			Steps.Dialog({
				{
					speaker = "MS TAYLOR",
					text = "We've heard some wonderful dreams today. "
						.. "Everyone has something to offer.",
				},
			}),
			Steps.Camera(function(context)
				local focus = context.Data.StudentSeat.Position + Vector3.new(0, 2.4, 0)
				return CFrame.lookAt(focus + Vector3.new(7, 0.8, -3), focus)
			end, 1.2, 52),
			Steps.Dialog({
				{
					speaker = "MS TAYLOR",
					text = "And what about you? What do you want to be?",
				},
			}),
			Steps.Call(function(context)
				context.Data.SchoolBell:Play()
			end),
			Steps.Wait(0.8),
			Steps.Camera("Teacher", 0.8, 52),
			Steps.Dialog({
				{
					speaker = "MS TAYLOR",
					text = "There's the bell! Keep dreaming big, everyone. Class dismissed!",
				},
			}),
			Steps.Camera("Wide", 1, 60),
		},
	}
end
