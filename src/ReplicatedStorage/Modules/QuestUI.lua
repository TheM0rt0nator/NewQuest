-- Native UI styled to match Berry Avenue's NPCChat: pale paper and Arcade text.
local QuestUI = {
	Paper = Color3.fromRGB(252, 250, 255),
	Ink = Color3.fromRGB(32, 27, 38),
	Accent = Color3.fromRGB(222, 210, 241),
	Success = Color3.fromRGB(200, 231, 210),
}

function QuestUI.Style(object, isButton)
	object.BorderSizePixel = 0
	object.BackgroundTransparency = 0
	object.BackgroundColor3 = isButton and QuestUI.Accent or QuestUI.Paper
	object.TextColor3 = QuestUI.Ink
	object.Font = Enum.Font.Arcade
	object.TextScaled = true
	object.TextWrapped = true

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 12
	limit.MaxTextSize = 28
	limit.Parent = object

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = object

	local border = Instance.new("UIStroke")
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Color = QuestUI.Ink
	border.Thickness = 2
	border.Parent = object

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = object

	if isButton then
		object.AutoButtonColor = true
	end
end

function QuestUI.Label(parent, name, content, position, size)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = content
	label.Position = position
	label.Size = size
	QuestUI.Style(label)
	label.Parent = parent

	return label
end

function QuestUI.Button(parent, name, content, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = content
	button.Position = position
	button.Size = size
	QuestUI.Style(button, true)
	button.Parent = parent

	return button
end

return QuestUI
