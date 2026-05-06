-- @ScriptType: LocalScript
local button = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. WAIT FOR THE REMOTE EVENT
-- Ensure your folder in ReplicatedStorage is named "Events"
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local EquipEvent = eventsFolder:WaitForChild("EquipCharacterEvent")

button.MouseButton1Click:Connect(function()
	-- 2. DEBUG LOG
	-- This helps you see in the Output window that the button was clicked
	print("Requesting change to: Ninja")

	-- 3. THE REMOTE CALL
	-- We use the colon (:) here to correctly call FireServer
	-- We pass the string "Ninja" to tell the server which class to load
	EquipEvent:FireServer("Ninja")

	-- 4. OPTIONAL: VISUAL FEEDBACK
	-- Flash the button color to show it was pressed
	local originalColor = button.BackgroundColor3
	button.BackgroundColor3 = Color3.fromRGB(150, 255, 150) -- Light Green flash
	task.wait(0.1)
	button.BackgroundColor3 = originalColor
end)