local ServerStorage = game:GetService("ServerStorage")

local Config = require(script.Parent.SecretQuestConfig)

local Bindings = {}

function Bindings.GetEntries()
	local references = ServerStorage:FindFirstChild("SecretQuestBindings")
	if not references then
		warn("[SecretQuest] Entrance bindings have not been configured in this place.")
		return {}
	end

	local result = {}
	local trunk = references:FindFirstChild("Trunk")
	trunk = trunk and trunk.Value
	if trunk and trunk:IsA("BasePart") then
		table.insert(result, {
			GetPosition = function()
				if not trunk:IsDescendantOf(workspace) then
					return nil
				end

				return trunk.CFrame:PointToWorldSpace(Vector3.new(0, -trunk.Size.Y / 2 + 3, 0))
			end,
		})
	end

	for _, item in Config.Items do
		local reference = references:FindFirstChild(item.Key)
		local anchor = reference and reference.Value
		if anchor and anchor:IsA("BasePart") then
			table.insert(result, {
				ItemId = item.Id,
				GetPosition = function()
					return anchor.Parent and anchor.Position or nil
				end,
			})
		end
	end

	return result
end

return Bindings
