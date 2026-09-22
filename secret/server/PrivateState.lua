local ServerStorage = game:GetService("ServerStorage")

local PrivateState = {}
local records = {}
local storage = ServerStorage:FindFirstChild("SecretQuestOriginals")

if not storage then
	storage = Instance.new("Folder")
	storage.Name = "SecretQuestOriginals"
	storage.Parent = ServerStorage
end

for _, record in storage:GetChildren() do
	local reference = record:FindFirstChild("Reference")

	if reference and reference.Value then
		records[reference.Value] = record
	else
		record:Destroy()
	end
end

function PrivateState.Remember(object, key, currentValue)
	local record = records[object]

	if not record then
		record = Instance.new("Folder")
		record.Name = object.ClassName
		record.Parent = storage
		local reference = Instance.new("ObjectValue")
		reference.Name = "Reference"
		reference.Value = object
		reference.Parent = record
		records[object] = record
	end

	local previous = record:GetAttribute(key)

	if previous == nil then
		previous = object:GetAttribute(key)

		if previous == nil then
			previous = currentValue
		end

		record:SetAttribute(key, previous)
	end

	object:SetAttribute(key, nil)
	return previous
end

function PrivateState.Anonymize(root)
	local objects = root:GetDescendants()
	table.insert(objects, root)

	for _, object in objects do
		object.Name = object.ClassName

		for key in object:GetAttributes() do
			object:SetAttribute(key, nil)
		end
	end
end

return PrivateState
