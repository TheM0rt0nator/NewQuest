local RunService = game:GetService("RunService")

local DreamTransition = {}
DreamTransition.__index = DreamTransition

function DreamTransition.new(playerGui)
	local self = setmetatable({}, DreamTransition)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DreamTransition"
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 120
	gui.Parent = playerGui
	self.Gui = gui

	local veil = Instance.new("Frame")
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = Color3.fromRGB(235, 230, 255)
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.Active = true
	veil.Parent = gui
	self.Veil = veil

	local blur = Instance.new("BlurEffect")
	blur.Name = "DreamBlur"
	blur.Size = 0
	blur.Parent = workspace.CurrentCamera
	self.Blur = blur

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "DreamColor"
	color.Parent = workspace.CurrentCamera
	self.Color = color
	return self
end

-- Lens breathing and camera sway build into an opaque veil over the teleport.
function DreamTransition:Animate(entering, check)
	local camera = workspace.CurrentCamera
	local originalFrame = camera.CFrame
	local originalFov = camera.FieldOfView
	local originalType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local ok, reason = xpcall(function()
		local started = os.clock()
		local duration = entering and 1.4 or 1.6
		repeat
			check()
			assert(workspace.CurrentCamera == camera, "Camera changed during dream transition")
			local elapsed = os.clock() - started
			local progress = math.clamp(elapsed / duration, 0, 1)
			local eased = progress * progress * (3 - 2 * progress)
			local strength = entering and eased or 1 - eased
			self.Blur.Size = 48 * strength
			self.Color.Brightness = 0.18 * strength
			self.Color.Saturation = -0.35 * strength
			self.Color.TintColor = Color3.new(1, 1, 1):Lerp(
				Color3.fromRGB(216, 207, 255), strength
			)
			self.Veil.BackgroundTransparency = 1 - strength ^ 3
			camera.FieldOfView = originalFov + strength * (10 + math.sin(elapsed * 5) * 4)
			camera.CFrame = originalFrame * CFrame.Angles(
				math.rad(math.sin(elapsed * 3) * strength),
				0,
				math.rad(math.sin(elapsed * 4) * 2.5 * strength)
			)
			RunService.RenderStepped:Wait()
		until progress >= 1
	end, debug.traceback)
	camera.CFrame = originalFrame
	camera.FieldOfView = originalFov
	camera.CameraType = originalType
	if not ok then
		self:Destroy()
		error(reason, 0)
	end
end

function DreamTransition:Cover(check)
	self:Animate(true, check)
end

function DreamTransition:Reveal(check)
	self:Animate(false, check)
	self:Destroy()
end

function DreamTransition:Destroy()
	self.Gui:Destroy()
	self.Blur:Destroy()
	self.Color:Destroy()
end

return DreamTransition
