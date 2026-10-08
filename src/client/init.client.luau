local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = ReplicatedStorage:WaitForChild("Framework")
local characterHandlerModule = framework:WaitForChild("CharacterHandler")

local rojoProject = ReplicatedStorage:WaitForChild("RojoProject")
local shared = rojoProject:WaitForChild("Shared")
local PresentationBridge = require(shared:WaitForChild("MovementPresentationBridge"))

local CharacterHandler = require(characterHandlerModule)

if CharacterHandler.__MovementPresentationHooked then
	return
end

CharacterHandler.__MovementPresentationHooked = true

local originalUpdateCamera = CharacterHandler.UpdateCamera

function CharacterHandler.UpdateCamera(self, delta)
	originalUpdateCamera(self, delta)

	local ok, err = pcall(PresentationBridge.Step, self, delta or (1 / 60))
	if not ok then
		warn("[MovementLab] presentation step failed:", err)
	end
end

print("[MovementLab] Riftborn presentation layer attached to CharacterHandler")
