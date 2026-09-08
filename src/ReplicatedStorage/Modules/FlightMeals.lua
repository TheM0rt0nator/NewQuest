local FlightMeals = {}

function FlightMeals.Create(meal)
	local model = Instance.new("Model")
	model.Name = meal

	local function part(name, size, position, color)
		local object = Instance.new("Part")
		object.Name = name
		object.Size = size
		object.Position = position
		object.Color = color
		object.Anchored = true
		object.CanCollide = false
		object.CanTouch = false
		object.Massless = true
		object.Parent = model

		return object
	end

	model.PrimaryPart = part("Tray", Vector3.new(1.3, 0.1, 1), Vector3.zero,
		Color3.fromRGB(219, 224, 231))

	if meal == "Sandwich" then
		part("Bread", Vector3.new(0.85, 0.15, 0.65), Vector3.new(0, 0.14, 0),
			Color3.fromRGB(231, 191, 128))
		part("Lettuce", Vector3.new(0.9, 0.07, 0.68), Vector3.new(0, 0.25, 0),
			Color3.fromRGB(94, 153, 64))
		part("Tomato", Vector3.new(0.76, 0.07, 0.58), Vector3.new(0, 0.32, 0),
			Color3.fromRGB(198, 68, 53))
		part("BreadTop", Vector3.new(0.85, 0.15, 0.65), Vector3.new(0, 0.42, 0),
			Color3.fromRGB(231, 191, 128))
	else
		for index = 1, 9 do
			local x = ((index - 1) % 3 - 1) * 0.25
			local z = (math.floor((index - 1) / 3) - 1) * 0.23
			local color = meal == "Salad" and Color3.fromRGB(91, 157, 65)
				or Color3.fromRGB(239, 188, 88)

			if index % 4 == 0 then
				color = Color3.fromRGB(208, 77, 51)
			end

			local food = part("Food", Vector3.new(0.24, 0.2, 0.23),
				Vector3.new(x, 0.16, z), color)
			food.Shape = meal == "Salad" and Enum.PartType.Ball or Enum.PartType.Cylinder
		end
	end

	return model
end

return FlightMeals
