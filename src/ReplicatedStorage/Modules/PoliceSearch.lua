local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local PoliceSearch = {}
local INSTRUCTION = "Drag the items off the suspect, then release to confiscate them."
local MINIMUM_DRAG = 1.5

function PoliceSearch.Start(player, stage, invoke, instruction)
	local camera = workspace.CurrentCamera
	local evidence = stage:WaitForChild("Evidence")
	local connections = {}
	local closed = false
	local processing = false
	local drag

	local previewFolder = Instance.new("Folder")
	previewFolder.Name = "PoliceSearchDrag"
	previewFolder.Parent = workspace

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.fromRGB(222, 210, 241)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = previewFolder

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { evidence, stage.Suspect }

	local function rayAt(position)
		-- InputObject.Position is measured below the top bar, in core UI coordinates.
		return camera:ScreenPointToRay(position.X, position.Y)
	end

	local function hitAt(position)
		local ray = rayAt(position)

		return workspace:Raycast(ray.Origin, ray.Direction * 100, params)
	end

	local function itemAt(position)
		local hit = hitAt(position)
		local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")

		if
			model
			and model.Parent == evidence
			and model:GetAttribute("Available")
			and not player:GetAttribute("PoliceConfiscated_" .. model.Name)
		then
			return model, hit.Position
		end

		return nil
	end

	local function restore(current)
		current.preview:Destroy()

		for part, transparency in current.hidden do
			if part.Parent then
				part.LocalTransparencyModifier = transparency
			end
		end
	end

	local function move(position)
		if not drag or processing then
			return
		end

		local ray = rayAt(position)
		local denominator = ray.Direction:Dot(drag.normal)

		if math.abs(denominator) < 0.001 then
			return
		end

		local distance = (drag.hit - ray.Origin):Dot(drag.normal) / denominator
		local delta = ray.Origin + ray.Direction * distance - drag.hit

		if delta.Magnitude > 6 then
			delta = delta.Unit * 6
		end

		drag.distance = delta.Magnitude
		drag.preview:PivotTo(drag.origin + delta)
	end

	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed or closed or processing or drag then
				return
			end

			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			local model, hit = itemAt(input.Position)

			if not model then
				return
			end

			-- Move a local 3D copy so dragging never pulls on the suspect's body welds.
			local preview = model:Clone()
			local hidden = {}

			for _, object in preview:GetDescendants() do
				if object:IsA("WeldConstraint") or object:IsA("JointInstance") then
					object:Destroy()
				elseif object:IsA("BasePart") then
					object.Anchored = true
					object.CanCollide = false
					object.CanTouch = false
					object.CanQuery = false
				end
			end

			for _, object in model:GetDescendants() do
				if object:IsA("BasePart") then
					hidden[object] = object.LocalTransparencyModifier
					object.LocalTransparencyModifier = 1
				end
			end

			preview.Parent = previewFolder
			drag = {
				model = model,
				preview = preview,
				hidden = hidden,
				input = input,
				hit = hit,
				normal = camera.CFrame.LookVector,
				origin = model:GetPivot(),
				distance = 0,
			}
			highlight.Adornee = preview
			highlight.Enabled = true
			instruction.Text = "Drag the "
				.. model:GetAttribute("Label")
				.. " away from the suspect."
		end)
	)

	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input)
			if not drag then
				return
			end

			if
				input == drag.input
				or drag.input.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == Enum.UserInputType.MouseMovement
			then
				move(input.Position)
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input)
			if not drag or processing then
				return
			end

			if
				input ~= drag.input
				and not (
					input.UserInputType == Enum.UserInputType.MouseButton1
					and drag.input.UserInputType == Enum.UserInputType.MouseButton1
				)
			then
				return
			end

			move(input.Position)

			local current = drag
			local hit = hitAt(input.Position)

			if current.distance < MINIMUM_DRAG or hit then
				drag = nil
				restore(current)
				highlight.Enabled = false
				instruction.Text = "Move the item clear of the suspect before releasing."

				return
			end

			processing = true

			local removed, reason = invoke("Confiscate", current.model.Name)
			processing = false

			if closed then
				return
			end

			drag = nil
			restore(current)
			highlight.Enabled = false
			instruction.Text = removed and "Item confiscated. " .. INSTRUCTION
				or reason
				or "Please try that item again."
		end)
	)

	table.insert(
		connections,
		RunService.RenderStepped:Connect(function()
			if drag or processing then
				return
			end

			-- GetMouseLocation includes the inset; convert it to the same space as clicks.
			local position = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			local model = itemAt(position)
			highlight.Adornee = model
			highlight.Enabled = model ~= nil
		end)
	)

	instruction.Text = INSTRUCTION

	return function()
		closed = true

		for _, connection in connections do
			connection:Disconnect()
		end

		if drag then
			restore(drag)
			drag = nil
		end

		previewFolder:Destroy()
	end
end

return PoliceSearch
