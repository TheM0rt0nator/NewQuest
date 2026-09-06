-- A reusable, cancellable dialogue adapter for scripted cutscenes.
local CutsceneDialogue = {}

local function createInterface(context)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CutsceneDialogue"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 102
	context:Defer(function()
		gui:Destroy()
	end)

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -28)
	panel.Size = UDim2.new(0.88, 0, 0, 190)
	panel.BackgroundColor3 = Color3.fromRGB(22, 29, 40)
	panel.BackgroundTransparency = 0.06
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(1000, 210)
	limit.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(177, 151, 97)
	stroke.Transparency = 0.4
	stroke.Parent = panel

	local speaker = Instance.new("TextLabel")
	speaker.Name = "Speaker"
	speaker.BackgroundTransparency = 1
	speaker.Position = UDim2.fromOffset(24, 14)
	speaker.Size = UDim2.new(1, -48, 0, 24)
	speaker.Font = Enum.Font.GothamBold
	speaker.TextSize = 20
	speaker.TextColor3 = Color3.fromRGB(235, 204, 140)
	speaker.TextXAlignment = Enum.TextXAlignment.Left
	speaker.Parent = panel

	local text = Instance.new("TextLabel")
	text.Name = "Dialogue"
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(24, 46)
	text.Size = UDim2.new(1, -48, 0, 98)
	text.Font = Enum.Font.Gotham
	text.TextSize = 26
	text.TextColor3 = Color3.fromRGB(245, 244, 239)
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.Parent = panel

	local nextButton = Instance.new("TextButton")
	nextButton.Name = "Continue"
	nextButton.AnchorPoint = Vector2.new(1, 1)
	nextButton.Position = UDim2.new(1, -18, 1, -8)
	nextButton.Size = UDim2.fromOffset(130, 36)
	nextButton.BackgroundTransparency = 1
	nextButton.Font = Enum.Font.GothamMedium
	nextButton.TextSize = 14
	nextButton.TextColor3 = Color3.fromRGB(222, 206, 171)
	nextButton.Text = "Continue  >"
	nextButton.Parent = panel

	gui.Parent = context.Player.PlayerGui

	return { gui = gui, panel = panel, speaker = speaker, text = text, nextButton = nextButton }
end

function CutsceneDialogue.Play(context, pages)
	if not context.Dialogue then
		context.Dialogue = createInterface(context)
	end

	local interface = context.Dialogue
	interface.panel.Visible = true

	for _, page in pages do
		context:Check()
		interface.speaker.Text = page.speaker
		interface.text.Text = page.text
		interface.text.MaxVisibleGraphemes = 0

		local reveal = false
		local advance = false
		local connection = interface.nextButton.Activated:Connect(function()
			if reveal then
				advance = true
			else
				reveal = true
			end
		end)
		local disconnect = context:Defer(function()
			connection:Disconnect()
		end)

		local characters = utf8.len(page.text) or #page.text
		local started = os.clock()
		while not reveal do
			local visible = math.floor((os.clock() - started) * 45)
			interface.text.MaxVisibleGraphemes = visible
			reveal = visible >= characters
			context:Wait(0.02)
		end

		interface.text.MaxVisibleGraphemes = -1
		local deadline = os.clock() + (page.duration or math.max(2.5, characters / 22))
		while not advance and os.clock() < deadline do
			context:Wait(0.05)
		end

		disconnect()
	end

	interface.panel.Visible = false
end

return CutsceneDialogue
