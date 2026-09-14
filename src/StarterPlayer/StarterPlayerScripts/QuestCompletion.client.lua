local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local QuestCelebration = require(ReplicatedStorage.Modules.QuestCelebration)
local QuestConfig = require(ReplicatedStorage.Modules.AnniversaryQuestConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local returnRemote = ReplicatedStorage:WaitForChild("ReturnToBerryAvenue")
local stopCelebration
local finished = false
local previewing = false
local previewGui
local previewButton

-- Warm celebration assets once to reduce delays when the screen opens.
local preloadThread = task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({
			QuestConfig.CompletionSoundId,
			QuestConfig.CompletionFireworkSoundId,
			QuestConfig.CompletionLogoImageId,
		})
	end)
end)

local function stopPlayback()
	if stopCelebration then
		stopCelebration()
		stopCelebration = nil
	end

	previewing = false

	if previewButton then
		previewButton.Text = "TEST COMPLETION"
	end
end

local function refresh()
	if player:GetAttribute("QuestReturnStatus") ~= "Celebrating" then
		if not previewing then
			stopPlayback()
		end

		return
	end

	-- Actual completion takes ownership if it arrives during a Studio preview.
	if previewing then
		stopPlayback()
	end

	if stopCelebration or finished then
		return
	end

	stopCelebration = QuestCelebration.Play(playerGui, function()
		stopCelebration = nil
		finished = true
		returnRemote:FireServer("CelebrationFinished")
	end)
end

if RunService:IsStudio() then
	previewGui = Instance.new("ScreenGui")
	previewGui.Name = "QuestCompletionPreview"
	previewGui.DisplayOrder = 251
	previewGui.ResetOnSpawn = false
	previewGui.Parent = playerGui

	previewButton = Instance.new("TextButton")
	previewButton.Name = "TestCompletion"
	previewButton.AnchorPoint = Vector2.new(1, 1)
	previewButton.Position = UDim2.new(1, -16, 1, -16)
	previewButton.Size = UDim2.fromOffset(220, 40)
	previewButton.BackgroundColor3 = Color3.fromRGB(250, 210, 232)
	previewButton.BorderColor3 = Color3.fromRGB(59, 51, 44)
	previewButton.BorderSizePixel = 2
	previewButton.Font = Enum.Font.Arcade
	previewButton.TextColor3 = Color3.fromRGB(59, 51, 44)
	previewButton.TextSize = 14
	previewButton.Text = "TEST COMPLETION"
	previewButton.Parent = previewGui

	previewButton.Activated:Connect(function()
		if player:GetAttribute("QuestReturnStatus") == "Celebrating" then
			return
		end

		if previewing then
			stopPlayback()
			return
		end

		previewing = true
		previewButton.Text = "STOP PREVIEW"
		stopCelebration = QuestCelebration.Play(playerGui, stopPlayback)
	end)
end

local statusConnection = player:GetAttributeChangedSignal("QuestReturnStatus"):Connect(refresh)
script.Destroying:Connect(function()
	statusConnection:Disconnect()

	if coroutine.status(preloadThread) ~= "dead" then
		task.cancel(preloadThread)
	end

	stopPlayback()

	if previewGui then
		previewGui:Destroy()
	end
end)

refresh()
