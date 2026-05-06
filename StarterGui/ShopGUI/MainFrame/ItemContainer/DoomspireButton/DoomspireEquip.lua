-- @ScriptType: LocalScript
local button = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. WAIT FOR THE REMOTE EVENT
-- Ensure your folder is named "Events" and the event is "EquipCharacterEvent"
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local EquipEvent = eventsFolder:WaitForChild("EquipCharacterEvent")

button.MouseButton1Click:Connect(function()
	-- 2. DEBUG LOG
	print("Requesting change to: Doomspire")

	-- 3. THE FIX: Using the colon (:) instead of a dot (.)
	-- This sends the signal to the ServerCombat script
	EquipEvent:FireServer("Doomspire")

	-- 4. OPTIONAL: VISUAL FEEDBACK
	-- This makes the button look clicked
	button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	task.wait(0.1)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end)