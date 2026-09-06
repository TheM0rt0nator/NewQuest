local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Steps = require(ReplicatedStorage.Modules.Cutscene).Steps

-- The sample needs only marker parts. Replace these shots as the custom map is built.
return function(markers)
	local function shot(name)
		return function()
			return CFrame.lookAt(markers[name].Position, markers.Focus.Position)
		end
	end
	return {
		Id = "QuestIntro",
		Markers = markers,
		Bars = { barHeight = 0.1, animationTime = 0.4 },
		Validate = function(context)
			context:GetCFrame("Wide")
			context:GetCFrame("CloseUp")
			context:GetCFrame("Focus")
		end,
		Steps = {
			Steps.Camera(shot("Wide"), 0, 65),
			Steps.Wait(1),
			Steps.Camera(shot("CloseUp"), 3, 50),
			Steps.Wait(1),
		},
	}
end
