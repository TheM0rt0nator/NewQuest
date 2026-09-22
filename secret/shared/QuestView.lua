-- Uses the same quest-card artwork and layout as MQ's StarterGui.Gui.Quest.
local QuestUI = require(script.Parent.QuestUI)
local QuestUISound = require(script.Parent.QuestUISound)

local QuestView = {}

local function image(parent, className, name, assetId, position, size)
	local object = Instance.new(className)
	object.Name = name
	object.BackgroundTransparency = 1
	object.Image = "rbxassetid://" .. assetId
	object.Position = position
	object.Size = size
	object.ScaleType = Enum.ScaleType.Fit
	object.Parent = parent

	return object
end

local function text(parent, name, content, position, size)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.BackgroundTransparency = 1
	object.Font = Enum.Font.Arcade
	object.Text = content
	object.TextColor3 = Color3.new(0, 0, 0)
	object.TextScaled = true
	object.TextWrapped = true
	object.Position = position
	object.Size = size
	object.Parent = parent

	return object
end

function QuestView.Create(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SecretQuestHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "Quest"
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromScale(1, 1)
	container.Parent = gui

	local card = image(
		container,
		"ImageLabel",
		"ObjectiveFrame",
		"16711912181",
		UDim2.fromScale(0.06, 0.417),
		UDim2.fromOffset(300, 235)
	)
	local close = image(
		card,
		"ImageButton",
		"Close",
		"8703682016",
		UDim2.fromScale(0.997, 0.01),
		UDim2.fromScale(0.1, 0.1)
	)
	close.AnchorPoint = Vector2.new(1, 0)
	close.ScaleType = Enum.ScaleType.Stretch
	QuestUISound.Bind(close)

	text(card, "Quest", "QUEST", UDim2.fromScale(0.02, 0), UDim2.fromScale(0.35, 0.138))
	local title = text(
		card,
		"Title",
		"Secret Quest",
		UDim2.fromScale(0.07, 0.173),
		UDim2.fromScale(0.885, 0.163)
	)
	title.TextXAlignment = Enum.TextXAlignment.Left

	local descriptionBox = image(
		card,
		"ImageLabel",
		"DescriptionBox",
		"16711942461",
		UDim2.fromScale(0.07, 0.32),
		UDim2.fromScale(0.871, 0.395)
	)
	descriptionBox.ScaleType = Enum.ScaleType.Stretch
	local description = text(
		descriptionBox,
		"Description",
		"Loading your adventure...",
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromScale(0.95, 0.85)
	)
	description.AnchorPoint = Vector2.new(0.5, 0.5)

	local progress =
		text(card, "Progress", "", UDim2.fromScale(0.5, 0.9), UDim2.fromScale(0.75, 0.15))
	progress.AnchorPoint = Vector2.new(0.5, 1)

	local toggle = image(
		container,
		"ImageButton",
		"Toggle",
		"105027459623911",
		UDim2.fromScale(0.02, 0.6),
		UDim2.fromOffset(58, 60)
	)
	toggle.Visible = false
	QuestUISound.Bind(toggle)

	local feedback =
		QuestUI.Label(card, "Feedback", "", UDim2.new(0, 0, 1, 10), UDim2.new(1, 0, 0, 68))
	feedback.UITextSizeConstraint.MaxTextSize = 18
	feedback.Visible = false

	return {
		Gui = gui,
		Container = container,
		Card = card,
		Close = close,
		Toggle = toggle,
		Description = description,
		Progress = progress,
		Feedback = feedback,
	}
end

function QuestView.Resize(view)
	local size = view.Container.AbsoluteSize

	if size.X < 1 or size.Y < 1 then
		return
	end

	local width = math.min(math.clamp(size.X * 0.24, 270, 360), size.X - 32)
	local height = width / 1.2754933834075928
	local left = size.X < 600 and 16 or size.X * 0.06
	local top = math.max(12, math.min(size.Y * 0.417, size.Y - height - 90))
	view.Card.Position = UDim2.fromOffset(left, top)
	view.Card.Size = UDim2.fromOffset(width, height)
	view.Toggle.Size = UDim2.fromOffset(58, 60)
end

return QuestView
