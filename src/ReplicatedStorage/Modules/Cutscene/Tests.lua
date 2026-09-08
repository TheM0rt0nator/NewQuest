-- Run manually on the CLIENT in a Studio play test; never runs automatically.
return function()
	local Cutscene = require(script.Parent)

	local Steps = Cutscene.Steps
	local camera = workspace.CurrentCamera
	local originalType, originalFOV = camera.CameraType, camera.FieldOfView

	local function scene(steps)
		return { Bars = false, Steps = steps }
	end

	local function restored(runner)
		assert(not runner:IsPlaying(), "Playing lock was not released")
		assert(camera.CameraType == originalType, "Camera type was not restored")
		assert(camera.FieldOfView == originalFOV, "FOV was not restored")
	end

	local runner = Cutscene.new()
	local order = {}
	local status = runner:Play(scene({
		Steps.Call(function(context)
			context:Defer(function()
				table.insert(order, "cleanup1")
			end)

			context:Defer(function()
				table.insert(order, "cleanup2")
			end)

			table.insert(order, "step1")
		end),

		Steps.Camera(CFrame.new(0, 10, 0), 0, 45),
		Steps.Wait(0.02),
		Steps.Call(function()
			table.insert(order, "step2")
		end),
	}))
	assert(status == "Completed", "Sequence did not complete")
	assert(
		table.concat(order, ",") == "step1,step2,cleanup2,cleanup1",
		"Steps or cleanup ran out of order"
	)
	restored(runner)

	local secondRunner = Cutscene.new()
	status = runner:Play(scene({
		Steps.Call(function()
			assert(
				secondRunner:Play(scene({})) == "Busy",
				"Concurrent camera ownership was allowed"
			)
			runner:Cancel("Test cancellation")
		end),

		Steps.Call(function()
			error("Must not run after cancellation")
		end),
	}))
	assert(status == "Cancelled", "Cancel did not stop the sequence")
	restored(runner)

	local failed, message = runner:Play(scene({
		Steps.Camera(CFrame.new(), 0, 35),
		Steps.Call(function()
			error("Expected failure")
		end),
	}))
	assert(
		failed == "Failed" and string.find(message, "Expected failure", 1, true),
		"Step failure was not reported"
	)
	restored(runner)

	local callback, stopped = nil, 0
	status = runner:Play(scene({
		Steps.Call(function(context)
			context:Await(function(done)
				callback = done

				return function()
					stopped = stopped + 1
				end
			end, 0.02)
		end),
	}))
	assert(status == "Failed" and stopped == 1, "Timeout must release its resources exactly once")
	callback() -- A callback from the failed scene must not affect the next scene.
	assert(runner:Play(scene({})) == "Completed", "Runner did not recover after a timeout")
	restored(runner)

	local cleanupRan = false
	status = runner:Play(scene({
		Steps.Call(function(context)
			context:Defer(function()
				cleanupRan = true
			end)

			context:Defer(function()
				error("Expected cleanup failure")
			end)
		end),
	}))
	assert(status == "Failed" and cleanupRan, "A failing cleanup must not prevent later cleanup")
	restored(runner)

	local setupRestored = false
	local setupFailure = Cutscene.new({
		Setup = function(context)
			context:Defer(function()
				setupRestored = true
			end)

			error("Expected setup failure")
		end,
	})
	assert(setupFailure:Play(scene({})) == "Failed", "Setup failure was not reported")
	assert(setupRestored, "Partial setup was not cleaned up")
	restored(setupFailure)
	setupFailure:Destroy()

	local model = Instance.new("Model")
	local part = Instance.new("Part")
	part.Anchored = true
	part.Parent = model
	model.Parent = workspace

	local previousPivot = model:GetPivot()
	status = runner:Play(scene({ Steps.Move(model, CFrame.new(20, 30, 40)) }))

	local actorRestored = model:GetPivot() == previousPivot
	model:Destroy()
	assert(status == "Completed" and actorRestored, "Actor position was not restored")

	local tweenFinished = false
	status = runner:Play(scene({
		Steps.Call(function()
			task.delay(0.02, function()
				runner:Cancel("Cancel tween")
			end)
		end),

		Steps.Camera(CFrame.new(0, 50, 0), 2, 40),
		Steps.Call(function()
			tweenFinished = true
		end),
	}))
	assert(status == "Cancelled" and not tweenFinished, "Tween cancellation ran later steps")
	restored(runner)

	status = runner:Play(scene({
		Steps.Call(function(context)
			task.delay(0.02, function()
				runner:Destroy()
			end)

			context:Wait(2)
		end),
	}))
	assert(status == "Cancelled", "Destroy did not cancel playback")
	assert(runner:Play(scene({})) == "Failed", "Destroyed runner accepted another scene")
	restored(runner)
	secondRunner:Destroy()
	print("Cutscene tests passed")
end
