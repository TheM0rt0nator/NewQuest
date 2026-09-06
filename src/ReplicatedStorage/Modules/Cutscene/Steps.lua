-- Step factories return functions executed sequentially by Cutscene:Play.
local Steps = {}

function Steps.Wait(seconds)
	return function(context) context:Wait(seconds) end
end

function Steps.Call(callback)
	return function(context) callback(context) end
end

function Steps.Camera(target, duration, fieldOfView)
	return function(context)
		local properties = { CFrame = context:GetCFrame(target) }
		if fieldOfView then properties.FieldOfView = fieldOfView end
		if duration and duration > 0 then
			context:Tween(context.Camera, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), properties)
		else
			for property, value in pairs(properties) do context.Camera[property] = value end
		end
	end
end

function Steps.Move(actor, target)
	return function(context)
		local model = context:Resolve(actor)
		local destination = context:GetCFrame(target)
		local previous = model:GetPivot()
		context:Defer(function()
			if model.Parent then model:PivotTo(previous) end
		end)
		model:PivotTo(destination)
	end
end

-- The adapter owns presentation; it must use context:Wait/Await for asynchronous work.
function Steps.Dialog(pages, options)
	return function(context)
		assert(context.Adapters.Dialog, 'Supply a Dialog adapter to play dialogue')
		context.Adapters.Dialog(context, context:Resolve(pages), options or {})
	end
end

function Steps.Animation(track, fadeTime)
	return function(context)
		local animation = context:Resolve(track)
		assert(not animation.IsPlaying, 'Use a dedicated cutscene AnimationTrack')
		context:Defer(function() animation:Stop(fadeTime or 0.1) end)
		animation:Play(fadeTime or 0.1)
	end
end

function Steps.Sound(sound)
	return function(context)
		local original = context:Resolve(sound)
		local clone = original:Clone()
		context:Defer(function() clone:Destroy() end)
		clone.Parent = original.Parent
		clone:Play()
	end
end

return Steps
