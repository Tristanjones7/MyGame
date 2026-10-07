--[[
    @class Dash
    @client
    @description 
        Client physics for Dash ability.
]]

--- @ Section: Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Framework.Types)
local TweenService = game:GetService("TweenService")
local Debris = require(ReplicatedStorage.Modules.Debris)

--- @ Section: API
return {
    Start = function(self: Types.self)
        local Root = self.Root
        local Humanoid = self.Humanoid
        
        -- Dash in full camera direction (3D)
        local Camera = workspace.CurrentCamera
        local DashDirection = Camera.CFrame.LookVector
        
        if DashDirection.Magnitude < 0.1 then
            DashDirection = Root.CFrame.LookVector
        end
        DashDirection = DashDirection.Unit
        
        local DashSpeed = 160
        local DashDuration = 0.15
        
        local Velocity = Instance.new("BodyVelocity")
        Velocity.MaxForce = Vector3.new(1, 1, 1) * 200000
        Velocity.Velocity = DashDirection * DashSpeed
        Velocity.Parent = Root
        
        Debris(Velocity, DashDuration)
        
        local DashAnim = self.Animations.Boost2
        if DashAnim then
            DashAnim:Play(0.1)
        end
        
        local FOVModifier = self:CreateFOVModifier(25, "Dash")
        TweenService:Create(FOVModifier, TweenInfo.new(DashDuration * 3), {Value = 0}):Play()
        
        Debris(FOVModifier, DashDuration * 3)
    end,
}
