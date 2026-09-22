local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)
local Props = require(script.Parent.Props)

local Smoothie = {}
Smoothie.__index = Smoothie

function Smoothie.new(stage)
	return setmetatable({
		Stage = stage,
		Blender = stage.Blender,
		Token = 0,
		LidRest = stage.Blender.Lid.CFrame,
		BladeRest = stage.Blender.Blade.CFrame,
	}, Smoothie)
end

function Smoothie:Cancel()
	self.Token += 1

	if self.Tween then
		self.Tween:Cancel()
		self.Tween = nil
	end

	if self.Carried then
		self.Carried:Destroy()
		self.Carried = nil
	end

	self.Blender.Effects:ClearAllChildren()
	self.Blender.Lid.CFrame = self.LidRest
	self.Blender.Blade.CFrame = self.BladeRest
end

function Smoothie:Move(model, goal, duration)
	local token = self.Token
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()
	local connection = value.Changed:Connect(function(cf)
		model:PivotTo(cf)
	end)
	local tween = TweenService:Create(value, TweenInfo.new(duration, Enum.EasingStyle.Quad), {
		Value = goal,
	})
	self.Tween = tween
	tween:Play()
	local status = tween.Completed:Wait()
	connection:Disconnect()
	value:Destroy()
	tween:Destroy()

	if self.Tween == tween then
		self.Tween = nil
	end

	return token == self.Token and status == Enum.PlaybackState.Completed
end

function Smoothie:Equip(character, ingredient)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hand = character
		and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))

	if not ingredient or not hand or not humanoid or humanoid.Health <= 0 then
		if self.Carried then
			self.Carried:Destroy()
			self.Carried = nil
		end

		return
	end

	if
		self.Carried
		and self.Carried.Parent == character
		and self.CarriedIngredient == ingredient
	then
		return
	end

	if self.Carried then
		self.Carried:Destroy()
	end

	local cf = hand.CFrame * CFrame.new(0, -0.35, -0.6)
	local model = Props.Ingredient(character, ingredient, cf, 0.8)
	self.CarriedIngredient = ingredient
	local handle = model.PrimaryPart

	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.Anchored = false
			object.Massless = true
			object.CanQuery = false

			if object ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = object
				weld.Parent = object
			end
		end
	end

	local grip = Instance.new("WeldConstraint")
	grip.Name = "HandGrip"
	grip.Part0 = hand
	grip.Part1 = handle
	grip.Parent = handle
	self.Carried = model
end

function Smoothie:Deposit(ingredient)
	local carried = self.Carried

	if not carried then
		return false
	end

	self.Carried = nil

	for _, object in carried:GetDescendants() do
		if object:IsA("WeldConstraint") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
		end
	end

	carried.Parent = self.Blender.Effects
	local centre = self.Blender.Centre.CFrame
	local raised = centre * CFrame.new(0, 3, 0)

	if not self:Move(carried, raised, 0.4) then
		return false
	end

	if ingredient == "Milk" then
		if
			not self:Move(
				carried,
				centre * CFrame.new(0.8, 2.1, 0) * CFrame.Angles(0, 0, math.pi / 2),
				0.25
			)
		then
			return false
		end

		local stream = Props.Cylinder(
			self.Blender.Effects,
			"MilkStream",
			0.22,
			1.8,
			centre * CFrame.new(0, 0.9, 0),
			Props.Colours.Milk
		)
		local tween = TweenService:Create(stream, TweenInfo.new(0.65), { Transparency = 0.3 })
		self.Tween = tween
		tween:Play()
		local state = tween.Completed:Wait()
		tween:Destroy()
		self.Tween = nil

		if state ~= Enum.PlaybackState.Completed then
			return false
		end
	else
		carried:ScaleTo(0.45)

		if not self:Move(carried, centre * CFrame.new(0, -0.6, 0), 0.35) then
			return false
		end
	end

	self.Blender.Effects:ClearAllChildren()
	return true
end

function Smoothie:Blend(ingredients, solved)
	local token = self.Token
	local blender = self.Blender
	blender.Lid.CFrame = blender.Centre.CFrame * CFrame.new(0, 1.65, 0)
	local centre = blender.Centre.CFrame
	local contents = blender.Contents
	local offsets = {}
	blender.Liquid.Color = solved and Props.Colours.Pink or Props.MixtureColour(ingredients)

	for _, item in contents:GetChildren() do
		if item:IsA("Model") then
			offsets[item] = centre:ToObjectSpace(item:GetPivot())
		end
	end

	local angle = Instance.new("NumberValue")
	local connection = angle.Changed:Connect(function(value)
		blender.Liquid.Transparency = 1 - value / (math.pi * 12)
		blender.Blade.CFrame = self.BladeRest * CFrame.Angles(0, value, 0)

		for item, offset in offsets do
			item:PivotTo(centre * CFrame.Angles(0, value, 0) * offset)
		end
	end)
	local tween = TweenService:Create(angle, TweenInfo.new(2, Enum.EasingStyle.Linear), {
		Value = math.pi * 12,
	})
	self.Tween = tween
	tween:Play()
	local status = tween.Completed:Wait()
	connection:Disconnect()
	angle:Destroy()
	tween:Destroy()
	self.Tween = nil
	blender.Lid.CFrame = self.LidRest

	return token == self.Token and status == Enum.PlaybackState.Completed
end

function Smoothie:Render(data, character)
	local complete = data.Stage > 4
	local values = data.Stage == 4 and data.Values or {}
	local ingredients = values.Ingredients or {}
	local blended = complete or values.Blended
	local blender = self.Blender
	blender.Contents:ClearAllChildren()
	blender.Blade.CFrame = self.BladeRest
	blender.Liquid.Transparency = 1

	if blended then
		local colour = Props.Colours.Pink

		if not complete then
			colour = Props.MixtureColour(ingredients)
		end

		blender.Liquid.Color = colour
		blender.Liquid.Transparency = 0
	else
		for index, ingredient in ingredients do
			if ingredient == "Milk" then
				blender.Liquid.Color = Props.Colours.Milk
				blender.Liquid.Transparency = 0.5
			else
				Props.Ingredient(
					blender.Contents,
					ingredient,
					blender.Centre.CFrame * CFrame.new((index - 2) * 0.4, -0.65 + index * 0.15, 0),
					0.45
				)
			end
		end
	end

	self:Equip(character, values.Held)
	Props.Interaction(blender.Centre).Prompt.Enabled = data.Stage == 4 and values.Held ~= nil
	Props.Interaction(self.Stage.BlendButton).Prompt.Enabled = data.Stage == 4
		and #ingredients >= 2
		and not values.Held
		and not blended
	Props.Interaction(self.Stage.ResetButton).Prompt.Enabled = data.Stage == 4
		and (#ingredients > 0 or values.Held ~= nil)

	for _, name in Config.SmoothieIngredients do
		local consumed = complete and table.find(Config.SmoothieRecipe, name) ~= nil
			or values.Held == name
			or table.find(ingredients, name) ~= nil

		for _, part in self.Stage.Ingredients[name]:GetDescendants() do
			if part:IsA("BasePart") and part ~= self.Stage.Ingredients[name].PrimaryPart then
				part.Transparency = consumed and 1 or 0
			end
		end

		Props.Interaction(self.Stage.Ingredients[name].PrimaryPart).Prompt.Enabled = data.Stage == 4
			and not values.Held
			and not blended
			and #ingredients < 3
			and not table.find(ingredients, name)
	end
end

return Smoothie
