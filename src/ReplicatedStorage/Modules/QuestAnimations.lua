local QuestAnimations = {}

local IDS = {
	HospitalBed = "rbxassetid://9609654502",
	TeacherIdle = "rbxassetid://125527528556264",
	TeacherTalking = "rbxassetid://92807885382082",
	TeacherSelecting = "rbxassetid://76245653184812",
	StudentSeatIdle = "rbxassetid://138156471015728",
	StudentAnswering = "rbxassetid://126768933512973",
	GiveMedicine = "rbxassetid://99777863176016",
	UseScalpel = "rbxassetid://79249944852722",
	ApplyBandage = "rbxassetid://131756866905760",
	ReplaceBloodBag = "rbxassetid://85418700628627",
	GiveInjection = "rbxassetid://139706929472533",
	UseDefibrillator = "rbxassetid://100040832065995",
	FingerprintScan = "rbxassetid://136311962752334",
}

function QuestAnimations.Play(humanoid, name, looped, priority)
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = assert(IDS[name], "Unknown quest animation: " .. name)

	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()

	if not success then
		warn("[QuestAnimations]", name, track)

		return nil
	end

	track.Name = name
	track.Looped = looped == true
	track.Priority = priority or Enum.AnimationPriority.Action2
	track:Play(0.15)

	return track
end

function QuestAnimations.Stop(track)
	if track then
		track:Stop(0)
		track:Destroy()
	end
end

return QuestAnimations
