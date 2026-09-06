local Steps = require(game.ReplicatedStorage.Modules.Cutscene).Steps

return function(stage, onReady)
	return {
		Id = "DoctorIntro",
		Markers = stage.Markers,
		Bars = { barHeight = 0.08, animationTime = 0.3 },
		Steps = {
			Steps.Camera("Wide", 0, 58),
			Steps.Call(onReady),
			Steps.Wait(1),
			Steps.Camera("Patient", 1.2, 52),
			Steps.Dialog({
				{
					speaker = "YOUR FIRST SHIFT",
					text = "Your patient is ready. Follow the care board: collect each item, then bring it back to the bed.",
				},
			}),
			Steps.Wait(0.5),
		},
	}
end
