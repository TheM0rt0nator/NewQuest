local ServerStorage = game:GetService("ServerStorage")

local templates = ServerStorage:WaitForChild("FlightMealTemplates")
local FlightMeals = {}

function FlightMeals.Create(meal)
	local template = templates:FindFirstChild(meal)
	assert(template and template:IsA("Model"), "Unknown flight meal: " .. tostring(meal))

	local model = template:Clone()

	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.Massless = true
		end
	end

	return model
end

return FlightMeals
