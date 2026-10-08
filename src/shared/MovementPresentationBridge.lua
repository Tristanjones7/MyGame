-- MovementPresentationBridge
-- Adapter between the original movement pack's CharacterHandler state object
-- and our presentation-only layer. No physics are changed here.

local Presentation = require(script.Parent.MovementPresentation)

local Bridge = {}
local drivers = setmetatable({}, { __mode = "k" })

function Bridge.Init(controller)
	local driver = Presentation.new(controller.Character)
	if not driver then
		warn("MovementPresentationBridge: could not create pose driver")
		return nil
	end

	drivers[controller] = {
		Driver = driver,
		WasInAir = controller.InAir == true,
		WasWallRunning = false,
	}

	return driver
end

function Bridge.Get(controller)
	local entry = drivers[controller]
	return entry and entry.Driver or nil
end

function Bridge.Step(controller, dt)
	local entry = drivers[controller]
	if not entry then
		local driver = Bridge.Init(controller)
		if not driver then return end
		entry = drivers[controller]
	end

	local driver = entry.Driver
	local humanoid = controller.Humanoid
	local grounded = controller.InAir ~= true
	local moving = humanoid and humanoid.MoveDirection.Magnitude > 0.1
	local sliding = controller.States and controller.States.Sliding == true
	local wallRunning = controller.States and controller.States.WallRunning == true

	-- Riftborn-style run overlay only while normal grounded locomotion is active.
	driver:SetRunning(grounded and moving and not sliding and not wallRunning)

	-- CharacterHandler stores "Left"/"Right" for the active wall direction.
	local side = controller.WallDirection == "Left" and -1 or 1
	driver:SetWallRunning(wallRunning, side)

	-- Trigger the procedural landing exactly on the air -> ground transition.
	if entry.WasInAir and grounded then
		driver:Land()
	end

	entry.WasInAir = controller.InAir == true
	entry.WasWallRunning = wallRunning

	driver:Step(dt)
end

function Bridge.Flip(controller, duration)
	local driver = Bridge.Get(controller)
	if driver then
		driver:Flip(duration)
	end
end

function Bridge.Destroy(controller)
	local entry = drivers[controller]
	if entry and entry.Driver then
		entry.Driver:Reset()
	end
	drivers[controller] = nil
end

return Bridge
