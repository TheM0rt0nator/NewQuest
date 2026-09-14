local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.AnniversaryQuestConfig)

local QuestCelebration = {}
local active
local CONTROL_ACTION = "QuestCompletionCelebration"
local INK = Color3.fromRGB(59, 51, 44)
local CORAL = Color3.fromRGB(255, 139, 142)
local PINK = Color3.fromRGB(250, 210, 232)
local CREAM = Color3.fromRGB(255, 231, 155)
local MINT = Color3.fromRGB(169, 239, 193)
local COLORS = {
	Color3.fromRGB(255, 214, 113),
	Color3.fromRGB(219, 184, 255),
	Color3.fromRGB(255, 161, 198),
	Color3.fromRGB(147, 234, 221),
}
local BURSTS = {
	{ 0.15, 0.19, 0.3 },
	{ 0.5, 0.82, 0.25 },
	{ 1.1, 0.1, 0.65 },
	{ 1.7, 0.89, 0.63 },
	{ 2.5, 0.28, 0.18 },
	{ 3, 0.74, 0.72 },
	{ 3.8, 0.16, 0.42 },
	{ 4.25, 0.85, 0.38 },
}

local function frame(parent, name, size, position, color)
	local object = Instance.new("Frame")
	object.Name = name
	object.AnchorPoint = Vector2.new(0.5, 0.5)
	object.Size = size
	object.Position = position
	object.BackgroundColor3 = color
	object.BorderSizePixel = 0
	object.Parent = parent

	return object
end

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = object
end

local function border(object, thickness)
	local outline = Instance.new("UIStroke")
	outline.Color = INK
	outline.Thickness = thickness
	outline.LineJoinMode = Enum.LineJoinMode.Miter
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Parent = object
end

local function label(parent, name, content, y, height, color, maxSize)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.AnchorPoint = Vector2.new(0.5, 0)
	object.Position = UDim2.fromScale(0.5, y)
	object.Size = UDim2.fromScale(0.9, height)
	object.BackgroundTransparency = 1
	object.Text = content
	object.TextColor3 = color
	object.Font = Enum.Font.Arcade
	object.TextScaled = true
	object.TextWrapped = true
	object.ZIndex = 12
	object.Parent = parent

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = 10
	limit.Parent = object

	return object
end

function QuestCelebration.Play(playerGui, onFinished)
	if active then
		return active.Stop
	end

	local session = { Tweens = {}, Particles = {}, Sounds = {}, Closed = false }
	active = session

	local gui = Instance.new("ScreenGui")
	gui.Name = "QuestCelebration"
	gui.DisplayOrder = 250
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "Celebration"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundColor3 = Color3.fromRGB(30, 20, 49)
	canvas.BackgroundTransparency = 0.2
	canvas.GroupTransparency = 1
	canvas.Active = true
	canvas.Parent = gui

	local function tween(object, duration, properties, style)
		local animation = TweenService:Create(
			object,
			TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			properties
		)
		table.insert(session.Tweens, animation)
		animation:Play()
	end

	local card =
		frame(canvas, "Card", UDim2.fromScale(0.68, 0.55), UDim2.fromScale(0.5, 0.53), CORAL)
	card.ZIndex = 10
	border(card, 4)

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(760, 460)
	constraint.Parent = card

	local scale = Instance.new("UIScale")
	scale.Scale = 0.65
	scale.Parent = card

	local header =
		frame(card, "Header", UDim2.fromScale(1, 0.16), UDim2.fromScale(0.5, 0.08), CREAM)
	header.ZIndex = 11
	border(header, 3)

	local heading = label(header, "Heading", "ANNIVERSARY ADVENTURE", 0.15, 0.7, INK, 25)
	heading.BackgroundColor3 = Color3.new(1, 1, 1)
	heading.BackgroundTransparency = 0
	border(heading, 2)

	local inset = frame(card, "Inset", UDim2.fromScale(0.97, 0.63), UDim2.fromScale(0.5, 0.5), PINK)
	inset.ZIndex = 11

	local logo = Instance.new("ImageLabel")
	logo.Name = "AnniversaryLogo"
	logo.AnchorPoint = Vector2.new(0.5, 0)
	logo.Position = UDim2.fromScale(0.5, 0.04)
	logo.Size = UDim2.fromScale(0.9, 0.22)
	logo.BackgroundTransparency = 1
	logo.BorderSizePixel = 0
	logo.Image = Config.CompletionLogoImageId
	logo.ScaleType = Enum.ScaleType.Fit
	logo.ZIndex = 12
	logo.Parent = inset

	label(inset, "Title", "QUEST COMPLETE!", 0.29, 0.2, INK, 42)
	label(inset, "Message", "Every great future starts with a dream.", 0.54, 0.14, INK, 20)

	local reward = label(inset, "Reward", "YOU DID IT!", 0.76, 0.15, INK, 22)
	reward.Size = UDim2.fromScale(0.5, 0.15)
	reward.BackgroundColor3 = MINT
	reward.BackgroundTransparency = 0
	border(reward, 2)

	label(card, "Return", "Returning to Berry Avenue...", 0.85, 0.06, INK, 17)

	local track = frame(
		card,
		"ProgressTrack",
		UDim2.fromScale(0.75, 0.027),
		UDim2.fromScale(0.5, 0.955),
		Color3.fromRGB(164, 164, 164)
	)
	track.ZIndex = 11
	border(track, 2)

	local progress = frame(track, "Progress", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0.5), MINT)
	progress.AnchorPoint = Vector2.new(0, 0.5)
	progress.ZIndex = 12

	local sound = Instance.new("Sound")
	sound.Name = "QuestCompletionFanfare"
	sound.SoundId = Config.CompletionSoundId
	sound.Volume = 0.65
	sound.Parent = SoundService
	sound:Play()

	-- Allocate one voice per burst so overlapping explosions keep their tails.
	for index = 1, #BURSTS do
		local explosion = Instance.new("Sound")
		explosion.Name = "QuestFireworkExplosion"
		explosion.SoundId = Config.CompletionFireworkSoundId
		explosion.Volume = Config.CompletionFireworkVolume
		explosion.Parent = SoundService
		session.Sounds[index] = explosion
	end

	ContextActionService:BindActionAtPriority(
		CONTROL_ACTION,
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 10,
		table.unpack(Enum.PlayerActions:GetEnumItems())
	)

	local connection
	local destroyConnection

	local function stop()
		if session.Closed then
			return
		end

		session.Closed = true

		if connection then
			connection:Disconnect()
		end

		if destroyConnection then
			destroyConnection:Disconnect()
		end

		for _, animation in session.Tweens do
			animation:Cancel()
			animation:Destroy()
		end

		table.clear(session.Tweens)
		table.clear(session.Particles)

		for _, explosion in session.Sounds do
			explosion:Destroy()
		end

		table.clear(session.Sounds)
		sound:Destroy()
		gui:Destroy()
		ContextActionService:UnbindAction(CONTROL_ACTION)

		if active == session then
			active = nil
		end
	end

	session.Stop = stop
	destroyConnection = gui.Destroying:Connect(stop)

	local random = Random.new()
	local function burst(data, index, now)
		local explosion = session.Sounds[index]
		explosion.PlaybackSpeed = random:NextNumber(0.95, 1.05)
		explosion:Play()

		local viewport = canvas.AbsoluteSize
		local origin = Vector2.new(data[2] * viewport.X, data[3] * viewport.Y)
		local radius = math.min(viewport.X, viewport.Y) * 0.16
		local color = COLORS[(index - 1) % #COLORS + 1]

		for sparkIndex = 1, 24 do
			local angle = sparkIndex / 24 * math.pi * 2
			local velocity = Vector2.new(math.cos(angle), math.sin(angle))
				* radius
				* random:NextNumber(0.8, 1.25)
			local spark = frame(
				canvas,
				"FireworkSpark",
				UDim2.fromOffset(5, 12),
				UDim2.fromOffset(origin.X, origin.Y),
				color
			)
			spark.ZIndex = 3
			spark.Rotation = math.deg(angle) + 90
			round(spark, UDim.new(1, 0))
			table.insert(session.Particles, {
				Object = spark,
				Origin = origin,
				Velocity = velocity,
				Born = now,
				Lifetime = random:NextNumber(1.1, 1.6),
				Gravity = Vector2.new(0, radius * 0.55),
			})
		end
	end

	tween(canvas, 0.3, { GroupTransparency = 0 })
	tween(scale, 0.65, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(card, 0.65, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
	tween(progress, Config.CompletionCelebrationDuration - 0.5, { Size = UDim2.fromScale(1, 1) })

	local started = os.clock()
	local nextBurst = 1
	local fading = false

	-- This is the only frame connection, owned by this short celebration.
	connection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local elapsed = now - started

		while BURSTS[nextBurst] and elapsed >= BURSTS[nextBurst][1] do
			burst(BURSTS[nextBurst], nextBurst, now)
			nextBurst += 1
		end

		for index = #session.Particles, 1, -1 do
			local particle = session.Particles[index]
			local age = now - particle.Born
			local fraction = age / particle.Lifetime

			if fraction >= 1 then
				particle.Object:Destroy()
				table.remove(session.Particles, index)
			else
				local position = particle.Origin
					+ particle.Velocity * age
					+ particle.Gravity * age * age
				particle.Object.Position = UDim2.fromOffset(position.X, position.Y)
				particle.Object.BackgroundTransparency = fraction * fraction
				particle.Object.Size =
					UDim2.fromOffset(5 * (1 - fraction * 0.6), 12 * (1 - fraction))
			end
		end

		if not fading and elapsed >= Config.CompletionCelebrationDuration - 0.4 then
			fading = true
			tween(canvas, 0.4, { GroupTransparency = 1 })
		end

		if elapsed >= Config.CompletionCelebrationDuration then
			stop()
			onFinished()
		end
	end)

	return stop
end

return QuestCelebration
