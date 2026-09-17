local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestAnimations = require(ReplicatedStorage.Modules.QuestAnimations)

local FlightSitting = {}

function FlightSitting.Play(humanoid)
	assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Flight sitting requires an R15 rig")

	-- The new idle has zero-weight leg poses. Keep the original seated pose
	-- underneath it so the pelvis and lap still match the seats and belts.
	local base = QuestAnimations.Play(humanoid, "FlightSeatBase", true, Enum.AnimationPriority.Action)
	local idle = QuestAnimations.Play(humanoid, "StudentSeatIdle", true, Enum.AnimationPriority.Action2)
	local tracks = { base, idle }
	local handle = {}

	function handle:Stop(fadeTime)
		for _, track in tracks do
			track:Stop(fadeTime or 0)
		end
	end

	function handle:Destroy()
		for _, track in tracks do
			QuestAnimations.Stop(track)
		end

		table.clear(tracks)
	end

	return handle
end

return FlightSitting
