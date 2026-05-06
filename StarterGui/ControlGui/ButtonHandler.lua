-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local AbilityTriggered = eventsFolder:WaitForChild("AbilityTriggered")
local RequestAbility = eventsFolder:WaitForChild("RequestAbility")
local RequestMovement = eventsFolder:WaitForChild("RequestMovement")

-- Wait for GUI
local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")

-- Button labels
local buttonLabels = {
	["Sword"] = "SWORD [E]\nKICK [W+E]",
	["Rocket"] = "ROCKET\n[A/D + R]",
	["Paintball"] = "GUN\n[Click]",
	["Trowel"] = "WALL\n[F]",
	["Bomb"] = "BOMB\n[R]"
}

-- Cooldown timer display
local originalColors = {
	["Sword"] = Color3.fromRGB(200, 50, 50),
	["Rocket"] = Color3.fromRGB(50, 150, 250),
	["Paintball"] = Color3.fromRGB(255, 255, 255),
	["Trowel"] = Color3.fromRGB(255, 255, 255),
	["Bomb"] = Color3.fromRGB(50, 50, 50)
}

local activeTimers = {}

local function startTimer(actionName, duration)
	local button = mainFrame:FindFirstChild(actionName)
	if not button then return end
	
	-- Cancel existing timer for this button
	activeTimers[actionName] = (activeTimers[actionName] or 0) + 1
	local currentTimerId = activeTimers[actionName]
	
	button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	
	local endTime = tick() + duration
	task.spawn(function()
		while tick() < endTime do
			if activeTimers[actionName] ~= currentTimerId then return end -- Another timer started
			local remaining = math.ceil(endTime - tick())
			button.Text = (buttonLabels[actionName] or actionName) .. "\n[" .. remaining .. "s]"
			task.wait(0.1)
		end
		
		if activeTimers[actionName] == currentTimerId then
			button.Text = buttonLabels[actionName] or actionName
			button.BackgroundColor3 = originalColors[actionName] or Color3.fromRGB(200, 200, 200)
		end
	end)
end

AbilityTriggered.Event:Connect(startTimer)

-- Connect ability buttons
for name, _ in pairs(buttonLabels) do
	local button = mainFrame:FindFirstChild(name)
	if button then
		button.MouseButton1Click:Connect(function()
			RequestAbility:Fire(name)
		end)
	end
end

-- Connect movement buttons
local movementButtons = {
	["MoveLeft"] = "MoveLeft",
	["MoveRight"] = "MoveRight",
	["Jump"] = "PlatformJump",
	["Drop"] = "PlatformDrop"
}

for btnName, actionName in pairs(movementButtons) do
	local button = mainFrame:FindFirstChild(btnName)
	if button then
		button.MouseButton1Down:Connect(function()
			RequestMovement:Fire(actionName, Enum.UserInputState.Begin)
		end)
		button.MouseButton1Up:Connect(function()
			RequestMovement:Fire(actionName, Enum.UserInputState.End)
		end)
		-- Also handle mouse leaving the button while pressed
		button.MouseLeave:Connect(function()
			RequestMovement:Fire(actionName, Enum.UserInputState.End)
		end)
	end
end

-- Hide movement buttons on desktop
local isMobile = UserInputService.TouchEnabled
local leftBtn = mainFrame:FindFirstChild("MoveLeft")
local rightBtn = mainFrame:FindFirstChild("MoveRight")

if not isMobile then
	if leftBtn then leftBtn.Visible = false end
	if rightBtn then rightBtn.Visible = false end
end
