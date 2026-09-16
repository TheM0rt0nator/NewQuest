-- Presents cutscene dialogue with the game's NPCChat artwork and controls.
local StarterGui = game:GetService("StarterGui")
local QuestAnimations = require(script.Parent.QuestAnimations)
local QuestUISound = require(script.Parent.QuestUISound)

local CutsceneDialogue = {}

local function animateSpeaker(context, page)
	local sceneId = context.Scene.Id

	if not sceneId or not sceneId:find("Classroom") then
		return function()
			-- No classroom actor owns this dialogue page.
		end
	end

	local stage = workspace:FindFirstChild("ClassroomIntro")
	local actors = stage and stage:FindFirstChild("Actors")
	local names = { ["MS TAYLOR"] = "MsTaylor", MAYA = "Maya", LEO = "Leo", AMIRA = "Amira" }
	local actor = actors and actors:FindFirstChild(names[page.speaker] or "")
	local humanoid = actor and actor:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return function() end
	end

	local teacher = page.speaker == "MS TAYLOR"
	local selecting = teacher and (page.text:find("?", 1, true) ~= nil)
	local name = teacher and (selecting and "TeacherSelecting" or "TeacherTalking")
		or "StudentAnswering"
	local track = QuestAnimations.Play(humanoid, name, not selecting)

	return context:Defer(function()
		QuestAnimations.Stop(track)
	end)
end

local function createInterface(context)
	local template = StarterGui:FindFirstChild("NPCChat", true)
	assert(template and template:IsA("GuiObject"), "StarterGui.NPCChat template is missing")

	local gui = Instance.new("ScreenGui")
	gui.Name = "CutsceneDialogue"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 102
	context:Defer(function()
		gui:Destroy()
	end)

	local panel = template:Clone()
	panel.Visible = false
	panel.Parent = gui

	local speaker = panel:FindFirstChild("Title")
	local text = panel:FindFirstChild("Dialog")
	local nextButton = panel:FindFirstChild("Continue")
	assert(speaker and text and nextButton, "NPCChat needs Title, Dialog, and Continue")
	speaker.Text = ""
	text.Text = ""
	text.MaxVisibleGraphemes = 0
	nextButton.Visible = true
	QuestUISound.Bind(nextButton)

	local close = panel:FindFirstChild("Close")

	if close then
		close.Visible = false
	end

	local label = nextButton:FindFirstChildOfClass("TextLabel")

	if label then
		label.Text = "Continue"
	end

	-- Parent only after initialization, so template text cannot flash on screen.
	gui.Parent = context.Player.PlayerGui

	return { gui = gui, panel = panel, speaker = speaker, text = text, nextButton = nextButton }
end

function CutsceneDialogue.Play(context, pages)
	if not context.Dialogue then
		context.Dialogue = createInterface(context)
	end

	local interface = context.Dialogue

	for _, page in pages do
		context:Check()
		local stopAnimation = animateSpeaker(context, page)
		interface.speaker.Text = page.speaker
		interface.text.Text = page.text
		interface.text.MaxVisibleGraphemes = 0
		interface.panel.Visible = true

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
		stopAnimation()
	end

	interface.panel.Visible = false
end

return CutsceneDialogue
