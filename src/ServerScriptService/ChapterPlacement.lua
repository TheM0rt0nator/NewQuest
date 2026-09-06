local ChapterPlacement = {}
local pending = {}

function ChapterPlacement.Release(character)
	local placement = pending[character]
	if not placement then
		return
	end
	pending[character] = nil
	if placement.root.Parent then
		placement.root.Anchored = placement.anchored
	end
end

function ChapterPlacement.Hold(character, target)
	ChapterPlacement.Release(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local placement = { root = root, anchored = root.Anchored }
	pending[character] = placement
	root.Anchored = true
	character:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	-- BeginIntro/BeginSeating releases this after the client sees the destination.
	task.delay(30, function()
		if pending[character] == placement then
			ChapterPlacement.Release(character)
		end
	end)
end

return ChapterPlacement
