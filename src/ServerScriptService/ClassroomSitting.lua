-- Shared sitting animation for the classroom cast and the player's seat session.
local ANIMATION_ID = "rbxassetid://134259979568724"

local ClassroomSitting = {}
local animation = Instance.new("Animation")
animation.Name = "ClassroomSit"
animation.AnimationId = ANIMATION_ID

function ClassroomSitting.Play(humanoid)
	assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Classroom sitting requires an R15 rig")

	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local track = animator:LoadAnimation(animation)
	track.Name = "ClassroomSit"
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.15)

	return track
end

return ClassroomSitting
