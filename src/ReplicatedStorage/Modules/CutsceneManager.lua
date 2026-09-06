-- One shared client runner. No framework initialization is required.
local ContextActionService = game:GetService('ContextActionService')
local ProximityPromptService = game:GetService('ProximityPromptService')
local Cutscene = require(script.Parent.Cutscene)

local Manager = {}
local runner = Cutscene.new({
	Setup = function(context)
		-- Suppress default movement without changing another system's control-enabled state.
		local action = 'AnniversaryCutsceneMovement'
		context:Defer(function() ContextActionService:UnbindAction(action) end)
		ContextActionService:BindActionAtPriority(action, function()
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value + 1, table.unpack(Enum.PlayerActions:GetEnumItems()))
		context:Set(ProximityPromptService, 'Enabled', false)

		local gui = Instance.new('ScreenGui')
		context:Defer(function() gui:Destroy() end)
		gui.Name = 'CutsceneControls'
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 101
		local skip = Instance.new('TextButton')
		skip.Text = 'Skip'
		skip.TextSize = 18
		skip.Font = Enum.Font.GothamMedium
		skip.Size = UDim2.fromOffset(110, 42)
		skip.AnchorPoint = Vector2.new(1, 1)
		skip.Position = UDim2.new(1, -24, 1, -24)
		skip.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
		skip.TextColor3 = Color3.new(1, 1, 1)
		skip.Parent = gui
		local clicked = skip.Activated:Connect(function() context.Cancelled = true; context.Reason = 'Skipped' end)
		context:Defer(function() clicked:Disconnect() end)
		gui.Parent = context.Player.PlayerGui
	end,
})

function Manager.Play(scene, data)
	return runner:Play(scene, data)
end

function Manager.Cancel(reason)
	return runner:Cancel(reason)
end

function Manager.IsPlaying()
	return runner:IsPlaying()
end

return Manager
