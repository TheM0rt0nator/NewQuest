-- Run once in Studio Edit mode to preserve the teacher's current appearance.
return function()
	local Players = game:GetService("Players")
	local actors = workspace.ClassroomIntro.Actors
	local previous = actors.MsTaylor

	if previous.Humanoid.RigType == Enum.HumanoidRigType.R15 then
		return previous
	end

	local description = previous.Humanoid:GetAppliedDescription()
	local rig =
		Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	rig.Name = "MsTaylor"
	rig.PrimaryPart = rig.HumanoidRootPart
	rig.HumanoidRootPart.Anchored = true
	rig.Humanoid.AutoRotate = false
	rig.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	for _, object in rig:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
		elseif object:IsA("BaseScript") then
			object:Destroy()
		end
	end

	local oldColors = previous:FindFirstChildOfClass("BodyColors")
	local newColors = rig:FindFirstChildOfClass("BodyColors")

	for _, property in
		{
			"HeadColor3",
			"TorsoColor3",
			"LeftArmColor3",
			"RightArmColor3",
			"LeftLegColor3",
			"RightLegColor3",
		}
	do
		newColors[property] = oldColors[property]
	end

	for _, name in { "Collar", "Tie" } do
		local original = previous.Torso:FindFirstChild(name)

		if original then
			local clone = original:Clone()

			for _, child in clone:GetChildren() do
				if child:IsA("WeldConstraint") then
					child:Destroy()
				end
			end

			clone.CFrame = rig.UpperTorso.CFrame
				* previous.Torso.CFrame:ToObjectSpace(original.CFrame)
			clone.Parent = rig.UpperTorso

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rig.UpperTorso
			weld.Part1 = clone
			weld.Parent = clone
		end
	end

	local oldFace = previous.Head:FindFirstChildOfClass("Decal")
	local newFace = rig.Head:FindFirstChildOfClass("Decal")

	if oldFace and newFace then
		newFace.Texture = oldFace.Texture
	end

	local previousRoot = previous.HumanoidRootPart
	local floorY = previousRoot.Position.Y - previousRoot.Size.Y / 2 - 2
	local standingHeight = rig.Humanoid.HipHeight + rig.HumanoidRootPart.Size.Y / 2
	rig:PivotTo(
		CFrame.new(previousRoot.Position.X, floorY + standingHeight, previousRoot.Position.Z)
			* previousRoot.CFrame.Rotation
	)

	for key, value in previous:GetAttributes() do
		rig:SetAttribute(key, value)
	end

	rig.Parent = actors
	previous:Destroy()

	return rig
end
