local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local stage = workspace:WaitForChild("PoliceQuest")
local doorReference = stage:WaitForChild("CellDoor")

while not doorReference.Value do
	doorReference:GetPropertyChangedSignal("Value"):Wait()
end

local door = doorReference.Value

local function readMotion()
	local encoded = door:GetAttribute("CellDoorMotion")
	if not encoded then
		return nil
	end

	local motion = HttpService:JSONDecode(encoded)
	return CFrame.new(table.unpack(motion.Target)), motion.Duration
end

local visual = door:Clone()
visual.Name = "PoliceCellDoorVisual"

-- Keep replication updates away from the animated geometry and collisions.
for _, object in visual:GetDescendants() do
	if object:IsA("BaseScript") or object:IsA("ProximityPrompt") then
		object:Destroy()
	elseif object:IsA("BasePart") then
		object.Anchored = true
	end
end

visual:PivotTo(readMotion() or door:GetPivot())
visual.Parent = workspace

local originals = {}

for _, part in door:GetDescendants() do
	if part:IsA("BasePart") then
		originals[part] =
			{ Transparency = part.LocalTransparencyModifier, CanCollide = part.CanCollide }
		part.LocalTransparencyModifier = 1
		part.CanCollide = false
	end
end

local animation
local value
local changedConnection
local completedConnection

local function stopAnimation()
	if completedConnection then
		completedConnection:Disconnect()
		completedConnection = nil
	end

	if changedConnection then
		changedConnection:Disconnect()
		changedConnection = nil
	end

	if animation then
		animation:Cancel()
		animation:Destroy()
		animation = nil
	end

	if value then
		value:Destroy()
		value = nil
	end
end

local function updateDoor()
	stopAnimation()

	local destination, duration = readMotion()

	if not destination then
		return
	end

	if duration <= 0 then
		visual:PivotTo(destination)
		return
	end

	value = Instance.new("CFrameValue")
	value.Value = visual:GetPivot()
	changedConnection = value.Changed:Connect(function(transform)
		visual:PivotTo(transform)
	end)
	animation = TweenService:Create(
		value,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ Value = destination }
	)
	completedConnection = animation.Completed:Connect(function()
		visual:PivotTo(destination)
		stopAnimation()
	end)
	animation:Play()
end

local revisionConnection = door:GetAttributeChangedSignal("CellDoorMotion"):Connect(updateDoor)
local destroyConnection
local closed = false

local function cleanup()
	if closed then
		return
	end

	closed = true
	revisionConnection:Disconnect()
	destroyConnection:Disconnect()
	stopAnimation()
	visual:Destroy()

	for part, original in originals do
		if part.Parent then
			part.LocalTransparencyModifier = original.Transparency
			part.CanCollide = original.CanCollide
		end
	end

	table.clear(originals)
end

destroyConnection = door.Destroying:Connect(cleanup)
script.Destroying:Connect(cleanup)
