-- MovementPresentation
-- Core procedural presentation values preserved from Riftborn's original MovementPoses system.
-- This module intentionally does NOT control velocity, jumping, wall-running, or other physics.

local Presentation = {}

Presentation.Config = {
	WallLean = 0.3,
	WallArmRaise = 1.35,
	WallArmReach = 0.3,
	NarutoLean = 0.65,
	NarutoArmBack = 1.05,
	NarutoArmOut = 0.15,
	LandTime = 0.45,
	LandDrop = 0.6,
	LandLean = 0.95,
	LandArmDown = 1.05,
}

local Driver = {}
Driver.__index = Driver

local function isJoint(joint)
	return joint and joint:IsA("Motor6D")
end

local function findJoint(character, partName, jointName)
	local part = character:FindFirstChild(partName)
	local joint = part and part:FindFirstChild(jointName)
	return isJoint(joint) and joint or nil
end

local function approach(current, target, speed, dt)
	local step = speed * dt
	if current < target then
		return math.min(target, current + step)
	end
	return math.max(target, current - step)
end

local function blend(joint, target, alpha)
	if joint and alpha > 0 then
		joint.Transform = joint.Transform:Lerp(target, math.clamp(alpha, 0, 1))
	end
end

function Presentation.new(character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoidRootPart then
		return nil
	end

	local self = setmetatable({}, Driver)
	self.Character = character
	self.Root = humanoidRootPart
	self.Flags = {
		Running = false,
		WallRunning = false,
		WallSide = 1,
	}
	self.Weights = {
		Run = 0,
		Wall = 0,
	}
	self.LandStarted = nil
	self.FlipStarted = nil
	self.FlipDuration = 0.45

	-- R15 first, with R6 shoulder fallbacks.
	self.RightShoulder = findJoint(character, "RightUpperArm", "RightShoulder") or findJoint(character, "Torso", "Right Shoulder")
	self.LeftShoulder = findJoint(character, "LeftUpperArm", "LeftShoulder") or findJoint(character, "Torso", "Left Shoulder")
	self.Waist = findJoint(character, "UpperTorso", "Waist")
	self.Neck = findJoint(character, "Head", "Neck") or findJoint(character, "Torso", "Neck")

	self.RootJoint = humanoidRootPart:FindFirstChild("RootJoint")
	if not self.RootJoint then
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("Motor6D") and descendant.Part0 == humanoidRootPart then
				self.RootJoint = descendant
				break
			end
		end
	end

	self.BaseRootC0 = self.RootJoint and self.RootJoint.C0 or nil

	return self
end

function Driver:SetRunning(enabled)
	self.Flags.Running = enabled == true
end

function Driver:SetWallRunning(enabled, side)
	self.Flags.WallRunning = enabled == true
	if side == -1 or side == 1 then
		self.Flags.WallSide = side
	end
end

function Driver:Land()
	self.LandStarted = os.clock()
end

function Driver:Flip(duration)
	self.FlipStarted = os.clock()
	self.FlipDuration = duration or 0.45
end

function Driver:Reset()
	self.Flags.Running = false
	self.Flags.WallRunning = false
	self.LandStarted = nil
	self.FlipStarted = nil
	if self.RootJoint and self.BaseRootC0 then
		self.RootJoint.C0 = self.BaseRootC0
	end
end

function Driver:Step(dt)
	if not self.Character.Parent then
		return
	end

	local config = Presentation.Config
	self.Weights.Run = approach(self.Weights.Run, self.Flags.Running and 1 or 0, 8, dt)
	self.Weights.Wall = approach(self.Weights.Wall, self.Flags.WallRunning and 1 or 0, 10, dt)

	-- Riftborn run pose: torso pitches forward while both arms trail behind.
	if self.Weights.Run > 0 then
		local w = self.Weights.Run
		local rightPose = CFrame.Angles(-config.NarutoArmBack, 0, config.NarutoArmOut)
		local leftPose = CFrame.Angles(-config.NarutoArmBack, 0, -config.NarutoArmOut)
		blend(self.RightShoulder, rightPose, w)
		blend(self.LeftShoulder, leftPose, w)
		blend(self.Waist, CFrame.Angles(-config.NarutoLean, 0, 0), w)
		blend(self.Neck, CFrame.Angles(config.NarutoLean * 0.7, 0, 0), w)
	end

	-- Riftborn wall-run pose: wall-side hand reaches outward/forward.
	if self.Weights.Wall > 0 then
		local side = self.Flags.WallSide
		local arm = side == 1 and self.RightShoulder or self.LeftShoulder
		local pose = CFrame.Angles(config.WallArmReach, 0, side * config.WallArmRaise)
		blend(arm, pose, self.Weights.Wall)
	end

	local rootOffset = CFrame.identity
	local rootDirty = false

	-- R6 does not have a Waist joint, so apply the Riftborn run lean at the RootJoint.
	if self.Weights.Run > 0 and not self.Waist then
		rootOffset *= CFrame.Angles(-config.NarutoLean * self.Weights.Run, 0, 0)
		rootDirty = true
	end

	-- Superhero-style landing timing from Riftborn.
	if self.LandStarted then
		local elapsed = os.clock() - self.LandStarted
		if elapsed >= config.LandTime then
			self.LandStarted = nil
		else
			local inWeight = math.clamp(elapsed / 0.08, 0, 1)
			local outWeight = math.clamp((config.LandTime - elapsed) / (config.LandTime - 0.2), 0, 1)
			local weight = inWeight * outWeight
			rootOffset *= CFrame.new(0, -config.LandDrop * weight, 0)
			blend(self.Waist, CFrame.Angles(-config.LandLean, 0, 0), weight)
			blend(self.RightShoulder, CFrame.Angles(config.LandArmDown, 0, 0), weight)
			blend(self.LeftShoulder, CFrame.Angles(-1.2, 0, -0.35), weight)
			rootDirty = true
		end
	end

	-- Front flip root rotation, matching Riftborn's procedural flip style.
	if self.FlipStarted then
		local alpha = math.clamp((os.clock() - self.FlipStarted) / self.FlipDuration, 0, 1)
		local eased = 1 - (1 - alpha) ^ 2
		rootOffset *= CFrame.Angles(-eased * math.pi * 2, 0, 0)
		rootDirty = true
		if alpha >= 1 then
			self.FlipStarted = nil
		end
	elseif self.Weights.Wall > 0 then
		rootOffset *= CFrame.Angles(0, 0, self.Flags.WallSide * config.WallLean * self.Weights.Wall)
		rootDirty = true
	end

	if self.RootJoint and self.BaseRootC0 then
		if rootDirty then
			self.RootJoint.C0 = rootOffset * self.BaseRootC0
		else
			self.RootJoint.C0 = self.BaseRootC0
		end
	end
end

return Presentation
