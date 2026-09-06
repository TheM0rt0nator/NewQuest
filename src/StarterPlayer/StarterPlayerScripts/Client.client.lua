local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Manager = require(ReplicatedStorage.Modules.CutsceneManager)
local QuestIntro = require(ReplicatedStorage.Cutscenes.QuestIntro)

-- Development preview only. The real quest will decide when each scene should play.
if not RunService:IsStudio() then return end
local player = Players.LocalPlayer
local gui = Instance.new('ScreenGui')
gui.Name = 'CutscenePreview'
gui.ResetOnSpawn = false
local button = Instance.new('TextButton')
button.Size = UDim2.fromOffset(230, 46)
button.Position = UDim2.fromOffset(24, 24)
button.Text = 'Play example cutscene'
button.TextSize = 16
button.Font = Enum.Font.GothamMedium
button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui
gui.Parent = player:WaitForChild('PlayerGui')
button.Activated:Connect(function()
	if Manager.IsPlaying() then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	if not humanoid or humanoid.Health <= 0 then return end
	button.Visible = false
	local markers = workspace:FindFirstChild('CutsceneMarkers')
	markers = markers and markers:FindFirstChild('Intro')
	local status, message
	if markers then
		status, message = Manager.Play(QuestIntro(markers))
	else
		status, message = 'Failed', 'Intro markers are missing'
	end
	button.Visible = true
	print('[QuestIntro]', status, message or '')
end)
