local Config = require(script.Parent.PoliceQuestConfig)

local PoliceEvidence = {}
local DARK = Color3.fromRGB(35, 39, 48)
local SILVER = Color3.fromRGB(186, 198, 210)
local GOLD = Color3.fromRGB(223, 182, 80)

local mounts = {
	Phone = { "LeftUpperLeg", CFrame.new(0, 0.1, -0.58) },
	Wallet = { "RightUpperLeg", CFrame.new(0, 0.05, -0.58) },
	Keys = { "LowerTorso", CFrame.new(-1.15, -0.55, -0.8) },
	Lockpick = { "LowerTorso", CFrame.new(1.15, -0.55, -0.8) },
	Radio = { "UpperTorso", CFrame.new(0, 0.65, -0.72) },
	Watch = { "RightLowerArm", CFrame.new(0, -0.25, -0.57) },
}

local function build(item, body, offset)
	local model = Instance.new("Model")
	model.Name = item.Id
	model:SetAttribute("ItemId", item.Id)
	model:SetAttribute("Label", item.Label)

	local origin = body.CFrame * offset

	local function part(name, size, position, color, round)
		local object = Instance.new("Part")
		object.Name = name
		object.Size = size
		object.CFrame = origin * CFrame.new(position)
		object.Color = color
		object.Material = Enum.Material.SmoothPlastic
		object.Massless = true
		object.CanCollide = false
		object.CanTouch = false

		if round then
			object.Shape = Enum.PartType.Cylinder
			object.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
		end

		object.Parent = model

		if not model.PrimaryPart then
			model.PrimaryPart = object
		else
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = model.PrimaryPart
			weld.Part1 = object
			weld.Parent = object
		end

		return object
	end

	if item.Id == "Phone" then
		part("Case", Vector3.new(0.62, 1, 0.14), Vector3.zero, DARK)
		part(
			"Screen",
			Vector3.new(0.51, 0.74, 0.03),
			Vector3.new(0, 0.04, -0.085),
			Color3.fromRGB(89, 174, 210)
		)
		part(
			"HomeButton",
			Vector3.new(0.03, 0.08, 0.08),
			Vector3.new(0, -0.41, -0.085),
			SILVER,
			true
		)
	elseif item.Id == "Wallet" then
		part("Leather", Vector3.new(0.74, 0.5, 0.18), Vector3.zero, Color3.fromRGB(103, 61, 39))
		part(
			"Fold",
			Vector3.new(0.67, 0.035, 0.03),
			Vector3.new(0, -0.16, -0.105),
			Color3.fromRGB(181, 133, 85)
		)
		part("Clasp", Vector3.new(0.14, 0.21, 0.03), Vector3.new(0.2, 0, -0.105), GOLD)
	elseif item.Id == "Keys" then
		part("KeyHead", Vector3.new(0.09, 0.3, 0.3), Vector3.new(0, 0.12, 0), SILVER, true)
		for index = 1, 2 do
			local x = (index - 1) * 0.2 - 0.08
			part("KeyStem", Vector3.new(0.07, 0.47, 0.08), Vector3.new(x, -0.2, -0.03), GOLD)
			part(
				"KeyTeeth",
				Vector3.new(0.18, 0.12, 0.08),
				Vector3.new(x + 0.055, -0.34, -0.03),
				GOLD
			)
		end
	elseif item.Id == "Lockpick" then
		part(
			"Grip",
			Vector3.new(0.16, 0.35, 0.12),
			Vector3.new(0, -0.15, 0),
			Color3.fromRGB(151, 51, 57)
		)
		part("Pick", Vector3.new(0.055, 0.48, 0.06), Vector3.new(0, 0.24, 0), SILVER)
		part("Hook", Vector3.new(0.17, 0.06, 0.06), Vector3.new(0.055, 0.46, 0), SILVER)
		part("TensionWrench", Vector3.new(0.06, 0.6, 0.08), Vector3.new(0.24, 0.04, 0), SILVER)
		part("WrenchTip", Vector3.new(0.2, 0.06, 0.08), Vector3.new(0.17, -0.24, 0), SILVER)
	elseif item.Id == "Radio" then
		part("Housing", Vector3.new(0.55, 0.75, 0.26), Vector3.zero, DARK)
		part("Antenna", Vector3.new(0.07, 0.48, 0.07), Vector3.new(-0.17, 0.59, 0), DARK)
		part(
			"Display",
			Vector3.new(0.37, 0.18, 0.035),
			Vector3.new(0, 0.17, -0.15),
			Color3.fromRGB(155, 200, 127)
		)
		for index = 1, 3 do
			part(
				"Speaker",
				Vector3.new(0.36, 0.035, 0.035),
				Vector3.new(0, -index * 0.075, -0.15),
				SILVER
			)
		end
	elseif item.Id == "Watch" then
		part("Strap", Vector3.new(0.29, 0.76, 0.1), Vector3.zero, DARK)
		part("Bezel", Vector3.new(0.13, 0.48, 0.48), Vector3.new(0, 0, -0.09), GOLD, true)
		part(
			"Face",
			Vector3.new(0.025, 0.37, 0.37),
			Vector3.new(0, 0, -0.17),
			Color3.fromRGB(248, 242, 225),
			true
		)
		part("HourHand", Vector3.new(0.035, 0.14, 0.02), Vector3.new(0, 0.055, -0.19), DARK)
		part("MinuteHand", Vector3.new(0.16, 0.025, 0.02), Vector3.new(0.065, 0, -0.19), DARK)
	end

	local attachment = Instance.new("WeldConstraint")
	attachment.Name = "BodyWeld"
	attachment.Part0 = body
	attachment.Part1 = model.PrimaryPart
	attachment.Parent = model.PrimaryPart

	return model
end

function PoliceEvidence.Install(stage)
	local folder = stage:FindFirstChild("Evidence")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Evidence"
		folder.Parent = stage
	end

	for _, item in Config.Items do
		if not folder:FindFirstChild(item.Id) then
			local mount = mounts[item.Id]
			build(item, stage.Suspect[mount[1]], mount[2]).Parent = folder
		end
	end

	return folder
end

function PoliceEvidence.Refresh(stage, player)
	local state = player:GetAttribute("QuestState")

	for _, model in stage.Evidence:GetChildren() do
		local visible = (state == 8 or state == 9)
			and player:GetAttribute("PoliceConfiscated_" .. model.Name) ~= true
		model:SetAttribute("Available", visible)

		for _, object in model:GetDescendants() do
			if object:IsA("BasePart") then
				if object:GetAttribute("OriginalTransparency") == nil then
					object:SetAttribute("OriginalTransparency", object.Transparency)
				end

				object.Transparency = visible and object:GetAttribute("OriginalTransparency") or 1
				object.CanQuery = visible
			end
		end
	end
end

return PoliceEvidence
