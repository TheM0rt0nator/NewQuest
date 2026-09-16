-- Shared sitting animation for the classroom cast and the player's seat session.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestAnimations = require(ReplicatedStorage.Modules.QuestAnimations)

local ClassroomSitting = {}

function ClassroomSitting.Play(humanoid)
	assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Classroom sitting requires an R15 rig")

	return QuestAnimations.Play(humanoid, "StudentSeatIdle", true, Enum.AnimationPriority.Action)
end

return ClassroomSitting
