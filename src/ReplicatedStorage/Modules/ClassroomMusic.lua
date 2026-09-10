local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.AnniversaryQuestConfig)
local ClassroomMusic = {}
local current
local fade

local template = Instance.new("Sound")
template.Name = "ClassroomMusicTemplate"
template.SoundId = Config.ClassroomMusicSoundId
template.Volume = 0
template.Looped = true
template.Parent = SoundService

task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({ template })
	end)
end)

function ClassroomMusic.Stop()
	local sound = current

	if not sound then
		return
	end

	if fade then
		fade:Cancel()
	end

	fade = TweenService:Create(sound, TweenInfo.new(0.65), { Volume = 0 })
	fade:Play()
	task.delay(0.65, function()
		if current == sound then
			current = nil
			fade = nil
		end

		sound:Destroy()
	end)
end

function ClassroomMusic.Start(context)
	if fade then
		fade:Cancel()
		fade = nil
	end

	if current then
		current:Destroy()
	end

	local sound = template:Clone()
	sound.Name = "ClassroomMusic"
	sound.Parent = SoundService
	current = sound
	context:Defer(function()
		if current == sound then
			ClassroomMusic.Stop()
		end
	end)

	if not sound.IsLoaded then
		pcall(function()
			ContentProvider:PreloadAsync({ sound })
		end)
	end

	context:Check()

	if sound.IsLoaded and current == sound then
		sound:Play()
		fade = TweenService:Create(sound, TweenInfo.new(1), { Volume = Config.ClassroomMusicVolume })
		fade:Play()
	end
end

return ClassroomMusic
