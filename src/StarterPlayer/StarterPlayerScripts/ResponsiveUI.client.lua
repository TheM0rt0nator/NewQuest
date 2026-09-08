local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local entries = {}
local cameraConnection
local scale = 1

local screenNames = {
	ClassroomChapter = true,
	PoliceBooking = true,
	FlightCabin = true,
	CutsceneDialogue = true,
}

local function scaled(value)
	return UDim2.new(
		value.X.Scale,
		value.X.Offset * scale,
		value.Y.Scale,
		value.Y.Offset * scale
	)
end

local function apply(object, original)
	if object:IsA("GuiObject") or object:IsA("BillboardGui") then
		object.Size = scaled(original.Size)
	end

	if object:IsA("GuiObject") then
		object.Position = scaled(original.Position)
	end

	if original.TextSize then
		object.TextSize = math.max(9, original.TextSize * scale)
	elseif object:IsA("UITextSizeConstraint") then
		object.MinTextSize = math.max(8, math.floor(original.MinTextSize * scale))
		object.MaxTextSize = math.max(object.MinTextSize, original.MaxTextSize * scale)
	elseif object:IsA("UIPadding") then
		for property, value in original do
			object[property] = UDim.new(value.Scale, value.Offset * scale)
		end
	end
end

local function register(object, billboard)
	if entries[object] then
		return
	end

	local original = {}

	if object:IsA("GuiObject") or object:IsA("BillboardGui") then
		original.Size = object.Size
	end

	if object:IsA("GuiObject") then
		original.Position = object.Position
	end

	if object:IsA("TextLabel") or object:IsA("TextButton") then
		original.TextSize = object.TextSize

		if billboard then
			object.TextScaled = true
			object.TextWrapped = true
		end
	elseif object:IsA("UITextSizeConstraint") then
		original.MinTextSize = object.MinTextSize
		original.MaxTextSize = object.MaxTextSize
	elseif object:IsA("UIPadding") then
		for _, property in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do
			original[property] = object[property]
		end
	end

	if object:IsA("BillboardGui") then
		object.AlwaysOnTop = true
	end

	if next(original) then
		entries[object] = original
		apply(object, original)
	end
end

local function discover(object)
	local screen = object:FindFirstAncestorOfClass("ScreenGui")

	if screen and screenNames[screen.Name] then
		register(object, false)

		return
	end

	local billboard = object:IsA("BillboardGui") and object
		or object:FindFirstAncestorOfClass("BillboardGui")
	local stage = billboard and billboard:FindFirstAncestor("PoliceQuest")
		or billboard and billboard:FindFirstAncestor("DoctorQuest")
		or billboard and billboard:FindFirstAncestor("FlightQuest")

	if stage then
		register(object, true)
	end
end

local function updateViewport()
	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local viewport = camera.ViewportSize
	scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.5, 1)

	for object, original in entries do
		apply(object, original)
	end
end

local function bindCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
	end

	local camera = workspace.CurrentCamera
	cameraConnection = camera
		and camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateViewport)
	updateViewport()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

for _, root in { playerGui, workspace } do
	root.DescendantAdded:Connect(function(object)
		-- UI constructors finish assigning properties before capturing their defaults.
		task.defer(discover, object)
	end)
	root.DescendantRemoving:Connect(function(object)
		entries[object] = nil
	end)

	for _, object in root:GetDescendants() do
		discover(object)
	end
end
