local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local QuestUISound = {}
local bound = setmetatable({}, { __mode = "k" })
local sound = Instance.new("Sound")
sound.Name = "QuestButtonClick"
sound.SoundId = "rbxassetid://8730872559"
sound.Volume = 0.5
sound.Parent = SoundService

task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({ sound })
	end)
end)

function QuestUISound.Play()
	-- Never queue a delayed click behind the user's next action.
	if sound.IsLoaded then
		sound.PlaybackSpeed = math.random(8, 12) / 10
		sound.TimePosition = 0
		sound:Play()
	end
end

function QuestUISound.Bind(button)
	if bound[button] then
		return
	end

	bound[button] = true
	button.Activated:Connect(QuestUISound.Play)
end

return QuestUISound
