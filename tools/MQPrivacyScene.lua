return function(map, storage, config)
	local CollectionService = game:GetService("CollectionService")
	local references = storage:FindFirstChild("SecretQuestBindings")
	if not references then
		references = Instance.new("Folder")
		references.Name = "SecretQuestBindings"
		references.Parent = storage
	end

	local function capture(name, object)
		local reference = references:FindFirstChild(name)
		if not reference then
			reference = Instance.new("ObjectValue")
			reference.Name = name
			reference.Value = assert(object, "Missing entrance object: " .. name)
			reference.Parent = references
		end

		for key, value in reference.Value:GetAttributes() do
			if key:match("^Secret") then
				reference:SetAttribute(key, value)
				reference.Value:SetAttribute(key, nil)
			end
		end

		return reference.Value
	end

	local originalTree = map:FindFirstChild("ClassicTree")
	local oldAnchors = map:FindFirstChild("SecretQuestStuff")
	local tree = capture("TreeModel", originalTree)
	local trunk = capture("Trunk", tree:FindFirstChild("Pillar"))
	local treeAnchor = capture("Tree", oldAnchors and oldAnchors:FindFirstChild("Tree"))
	local anchors = {}
	for _, item in config.Items do
		anchors[item.Id] = capture(item.Key, oldAnchors and oldAnchors:FindFirstChild(item.Key))
	end

	local function preparePrompt(anchor, itemId)
		local prompt = assert(anchor:FindFirstChildOfClass("ProximityPrompt"))
		CollectionService:RemoveTag(prompt, "SecretQuestPrompt")
		CollectionService:AddTag(prompt, "InteractionPrompt")
		prompt:SetAttribute("SecretQuestItemId", nil)
		prompt:SetAttribute("InteractionKey", itemId)
		prompt.Name = "ProximityPrompt"
		anchor.Name = anchor.ClassName
	end

	preparePrompt(treeAnchor)
	treeAnchor.Parent = tree
	for itemId, anchor in anchors do
		preparePrompt(anchor, itemId)
		if anchor.Parent == oldAnchors then
			local model = Instance.new("Model")
			model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			anchor.Parent = model
			model.Parent = map
		end
	end

	tree.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	tree.Name = "Model"
	for _, object in tree:GetDescendants() do
		object.Name = object.ClassName
		for key in object:GetAttributes() do
			if key:match("^Secret") then
				object:SetAttribute(key, nil)
			end
		end
	end

	if oldAnchors and #oldAnchors:GetChildren() == 0 then
		oldAnchors:Destroy()
	end

	assert(trunk:IsDescendantOf(tree))
	return references
end
