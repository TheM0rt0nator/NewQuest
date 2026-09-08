-- Self-contained letterbox UI; camera/FOV ownership belongs to the cutscene runner.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CinematicBars = {}
CinematicBars.__index = CinematicBars

function CinematicBars.new(options)
	local config = { barHeight = 0.12, animationTime = 0.4 }

	for key, value in pairs(options or {}) do
		config[key] = value
	end

	assert(config.barHeight >= 0 and config.barHeight <= 0.5, "Invalid bar height")
	assert(config.animationTime >= 0 and config.animationTime < math.huge, "Invalid bar duration")

	local gui = Instance.new("ScreenGui")
	gui.Name = "CinematicBars"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ScreenInsets = Enum.ScreenInsets.None

	local self = setmetatable({ config = config, Gui = gui, Tweens = {} }, CinematicBars)

	for _, name in { "Top", "Bottom" } do
		local bar = Instance.new("Frame")
		bar.Name = name
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.Size = UDim2.fromScale(1, config.barHeight)
		bar.Position = UDim2.fromScale(0, name == "Top" and -config.barHeight or 1)
		bar.Parent = gui
		self[name] = bar
	end

	gui.Parent =
		assert(Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"), "PlayerGui unavailable")
	return self
end

function CinematicBars:_Animate(top, bottom)
	for _, tween in self.Tweens do
		tween:Cancel()
		tween:Destroy()
	end

	table.clear(self.Tweens)

	for bar, position in { [self.Top] = top, [self.Bottom] = bottom } do
		local tween = TweenService:Create(
			bar,
			TweenInfo.new(
				self.config.animationTime,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut
			),
			{ Position = UDim2.fromScale(0, position) }
		)
		table.insert(self.Tweens, tween)
		tween:Play()
	end
end

function CinematicBars:Show()
	self:_Animate(0, 1 - self.config.barHeight)
end

function CinematicBars:Hide()
	self:_Animate(-self.config.barHeight, 1)
end

function CinematicBars:Destroy()
	for _, tween in self.Tweens do
		tween:Cancel()
		tween:Destroy()
	end

	table.clear(self.Tweens)
	self.Gui:Destroy()
end

return CinematicBars
