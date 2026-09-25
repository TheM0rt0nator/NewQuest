local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("SecretQuest")
local Config = require(shared:WaitForChild("Config"))
local QuestUI = require(shared:WaitForChild("QuestUI"))
local QuestCelebration = require(shared:WaitForChild("QuestCelebration"))
local CelebrationConfig = require(shared:WaitForChild("AnniversaryQuestConfig"))
local celebrationFinished = shared:WaitForChild("CelebrationFinished")

if game.PlaceId ~= Config.PlaceId and game.PlaceId ~= Config.TestPlaceId then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui
local label
local stopCelebration
local lastCelebration

local preloadThread = task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({
			CelebrationConfig.CompletionSoundId,
			CelebrationConfig.CompletionFireworkSoundId,
			CelebrationConfig.CompletionLogoImageId,
		})
	end)
end)

local function stopPlayback()
	if stopCelebration then
		stopCelebration()
		stopCelebration = nil
	end
end

local function updateCelebration()
	local startedAt = player:GetAttribute("SecretCelebrationStartedAt")

	if not startedAt then
		stopPlayback()
		return
	end

	if startedAt == lastCelebration then
		return
	end

	lastCelebration = startedAt
	stopPlayback()
	stopCelebration = QuestCelebration.Play(playerGui, function()
		stopCelebration = nil
		celebrationFinished:FireServer(startedAt)
	end, {
		Heading = "SECRET QUEST",
		Message = "Your secret badge is claimed!",
		ReturnText = "Returning to Berry Avenue...",
	})
end

local function update()
	local message = player:GetAttribute("SecretReturnMessage") or ""

	if message == "" then
		if gui then
			gui.Enabled = false
		end

		return
	end

	-- Only portal save/award/travel feedback; no puzzle HUD or navigation arrows.
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "SecretReturnFeedback"
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
		label =
			QuestUI.Label(gui, "Status", "", UDim2.fromScale(0.5, 0.85), UDim2.new(0.8, 0, 0, 70))
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		local limit = Instance.new("UISizeConstraint")
		limit.MaxSize = Vector2.new(600, 90)
		limit.Parent = label
	end

	gui.Enabled = true
	label.Text = message
end

local connection = player:GetAttributeChangedSignal("SecretReturnMessage"):Connect(update)
local celebrationConnection =
	player:GetAttributeChangedSignal("SecretCelebrationStartedAt"):Connect(updateCelebration)
local characterConnection = player.CharacterRemoving:Connect(stopPlayback)

script.Destroying:Connect(function()
	connection:Disconnect()
	celebrationConnection:Disconnect()
	characterConnection:Disconnect()
	stopPlayback()

	if coroutine.status(preloadThread) ~= "dead" then
		task.cancel(preloadThread)
	end

	if gui then
		gui:Destroy()
	end
end)

update()
updateCelebration()
