-- Offsets are relative to the palm, independent of each supply tray's pose.
local DoctorGrip = {}

local GRIPS = {
	Medicine = CFrame.new(0, -0.12, -0.18) * CFrame.Angles(0, math.pi / 2, 0),
	Scalpel = CFrame.new(0, -0.12, -0.08) * CFrame.Angles(0, 0, -math.pi / 2),
	Bandage = CFrame.new(-0.12, -0.25, -0.2) * CFrame.Angles(0, math.pi / 2, 0),
	-- Hold the bag by its top edge, with the reservoir extending past the fingers.
	BloodBag = CFrame.new(0, -0.7, -0.18) * CFrame.Angles(math.pi / 2, 0, math.pi),
	Injection = CFrame.new(0, -0.4, -0.18) * CFrame.Angles(0, 0, -math.pi / 2),
	Shock = CFrame.new(0, -0.12, 0),
}

local function attach(model, hand, offset)
	local reference = model:FindFirstChild("Handle", true) or model.PrimaryPart
	assert(reference and reference:IsA("BasePart"), "Doctor prop needs a grip part")

	-- Align the actual handle rather than the bounding box or tray pivot.
	local pivotFromHandle = reference.CFrame:ToObjectSpace(model:GetPivot())
	local palm = hand.CFrame

	if hand.Name == "Right Arm" or hand.Name == "Left Arm" then
		palm *= CFrame.new(0, -0.75, 0)
	end

	model:PivotTo(palm * offset * pivotFromHandle)

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true

			local weld = Instance.new("WeldConstraint")
			weld.Name = "DoctorHandGrip"
			weld.Part0 = hand
			weld.Part1 = part
			weld.Parent = part
		end
	end
end

function DoctorGrip.Attach(item, character, taskId)
	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	assert(rightHand and leftHand, "Doctor animations require both hands")

	-- Remove template joints so the paddles cannot bind both hands together.
	for _, descendant in item:GetDescendants() do
		if descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		end
	end

	if taskId == "Shock" then
		attach(item.RightPaddle, rightHand, GRIPS.Shock)
		attach(item.LeftPaddle, leftHand, GRIPS.Shock)
	else
		attach(item, rightHand, assert(GRIPS[taskId], "Unknown doctor grip"))
	end

	item.Parent = character
end

return DoctorGrip
