local Config = require(script.Parent.Config)

local Progress = {}
local INGREDIENTS = {}

for _, ingredient in Config.SmoothieIngredients do
	INGREDIENTS[ingredient] = true
end

function Progress.New()
	return { Version = 3, Stage = 1, Values = {}, Completed = false }
end

function Progress.Migrate(data)
	if data.Version == 1 and type(data.Stage) == "number" then
		-- The old third/fourth stages have changed order and mechanics.
		if data.Completed or data.Stage >= 5 then
			data.Stage = 5
		elseif data.Stage >= 3 then
			data.Stage = 3
		end

		data.Values = {}
		data.Version = 2
	end

	if data.Version == 2 then
		data.Shirt = nil

		if data.Stage == 3 then
			data.Values = {}
		end

		data.Version = 3
	end
end

function Progress.Apply(data, kind, action)
	local values = data.Values

	if kind == "Mannequins" then
		local index = tonumber(action)

		if not index or index % 1 ~= 0 or index < 1 or index > Config.MannequinCount then
			return false, false, ""
		end

		values[action] = ((values[action] or Config.MannequinInitialTurns[index]) + 1) % 4
		local solved = true

		for number = 1, Config.MannequinCount do
			if (values[tostring(number)] or Config.MannequinInitialTurns[number]) ~= 0 then
				solved = false
			end
		end

		return true, solved, ""
	elseif kind == "Colour" then
		local colour = action:match("^Polish:(.+)$")

		if not colour then
			return false, false, ""
		end

		values.Code = values.Code or {}
		table.insert(values.Code, colour)
		values.CodeRejected = nil

		-- Match the latest inputs, regardless of where a previous attempt began.
		while #values.Code > #Config.NailCode do
			table.remove(values.Code, 1)
		end

		if #values.Code < #Config.NailCode then
			return true, false, ""
		end

		for index, expected in Config.NailCode do
			if values.Code[index] ~= expected then
				return true, false, ""
			end
		end

		return true, true, ""
	elseif kind == "Smoothie" then
		values.Ingredients = values.Ingredients or {}
		local ingredient = action:match("^Pick:(%a+)$")

		if ingredient and INGREDIENTS[ingredient] then
			if values.Held then
				return false, false, "Your hand is already full."
			end

			if values.Blended or #values.Ingredients >= 3 then
				return false, false, "The jug is full. Empty it to start again."
			end

			if table.find(values.Ingredients, ingredient) then
				return false, false, "There is already some of that in the jug."
			end

			values.Held = ingredient
			return true, false, ""
		elseif action == "Deposit" then
			if not values.Held then
				return false, false, "Your hand is empty."
			end

			table.insert(values.Ingredients, values.Held)
			values.Held = nil
			return true, false, ""
		elseif action == "Reset" then
			data.Values = {}
			return true, false, ""
		elseif action == "Blend" then
			if values.Held then
				return false, false, "Put down your ingredient first."
			end

			if #values.Ingredients < 2 then
				return false, false, "There is not enough in the jug yet."
			end

			values.Blended = true
			local solved = #values.Ingredients == #Config.SmoothieRecipe

			for _, required in Config.SmoothieRecipe do
				if not table.find(values.Ingredients, required) then
					solved = false
				end
			end

			return true, solved, "That doesn't look like the sample."
		end
	end

	return false, false, ""
end

function Progress.Advance(data, stageCount)
	data.Stage += 1
	data.Values = {}
	data.Completed = data.Stage > stageCount
end

return Progress
