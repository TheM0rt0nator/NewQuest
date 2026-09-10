-- One shared client runner. No framework initialization is required.
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Cutscene = require(script.Parent.Cutscene)
local CutsceneDialogue = require(script.Parent.CutsceneDialogue)
local ClassroomMusic = require(script.Parent.ClassroomMusic)

local classroomScenes = {
	ClassroomIntro = true,
	PoliceClassroom = true,
	FlightClassroom = true,
	ClassroomFinale = true,
}

local Manager = {}
local runner = Cutscene.new({
	Adapters = {
		Dialog = CutsceneDialogue.Play,
	},
	Setup = function(context)
		-- Suppress default movement without changing another system's control-enabled state.
		local action = "AnniversaryCutsceneMovement"
		context:Defer(function()
			ContextActionService:UnbindAction(action)
		end)

		ContextActionService:BindActionAtPriority(
			action,

			function()
				return Enum.ContextActionResult.Sink
			end,

			false,
			Enum.ContextActionPriority.High.Value + 1,
			table.unpack(Enum.PlayerActions:GetEnumItems())
		)
		context:Set(ProximityPromptService, "Enabled", false)

		if classroomScenes[context.Scene.Id] then
			ClassroomMusic.Start(context)
		end
	end,
})

function Manager.Play(scene, data)
	return runner:Play(scene, data)
end

function Manager.Cancel(reason)
	return runner:Cancel(reason)
end

function Manager.IsPlaying()
	return runner:IsPlaying()
end

return Manager
