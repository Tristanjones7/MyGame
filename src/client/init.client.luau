local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[MovementLab] client booting")

local framework = ReplicatedStorage:WaitForChild("Framework", 10)
if not framework then
	warn("[MovementLab] Framework not found in ReplicatedStorage")
	return
end

local characterHandlerModule = framework:WaitForChild("CharacterHandler", 10)
if not characterHandlerModule then
	warn("[MovementLab] CharacterHandler not found under ReplicatedStorage.Framework")
	return
end

local shared
local rojoProject = ReplicatedStorage:FindFirstChild("RojoProject")
if rojoProject then
	shared = rojoProject:FindFirstChild("Shared")
end
if not shared then
	shared = ReplicatedStorage:FindFirstChild("Shared")
end
if not shared then
	warn("[MovementLab] Could not find shared modules at ReplicatedStorage.RojoProject.Shared or ReplicatedStorage.Shared")
	return
end

local bridgeModule = shared:FindFirstChild("MovementPresentationBridge")
if not bridgeModule then
	warn("[MovementLab] MovementPresentationBridge not found in", shared:GetFullName())
	return
end

local okBridge, PresentationBridge = pcall(require, bridgeModule)
if not okBridge then
	warn("[MovementLab] Failed to require MovementPresentationBridge:", PresentationBridge)
	return
end

local okHandler, CharacterHandler = pcall(require, characterHandlerModule)
if not okHandler then
	warn("[MovementLab] Failed to require CharacterHandler:", CharacterHandler)
	return
end

if CharacterHandler.__MovementPresentationHooked then
	print("[MovementLab] presentation hook already attached")
	return
end

if type(CharacterHandler.UpdateCamera) ~= "function" then
	warn("[MovementLab] CharacterHandler.UpdateCamera is not a function; hook not attached")
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

print("[MovementLab] Riftborn presentation layer attached to CharacterHandler using", shared:GetFullName())
