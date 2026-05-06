-- @ScriptType: LocalScript
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Store all platforms we want to handle
local platforms = {}

local function findPlatforms()
	local foundPlatforms = {}
	
	-- Find Grasslands platform
	local grasslands = workspace:FindFirstChild("Grasslands")
	if grasslands then
		local sketchfabModel = grasslands:FindFirstChild("Sketchfab_model")
		if sketchfabModel then
			local mushroom = sketchfabModel:FindFirstChild("mushroomkingdom2.obj.cleaner.materialmerger.gles")
			if mushroom then
				local platform = mushroom:FindFirstChild("Platform")
				if platform and platform:IsA("BasePart") then
					table.insert(foundPlatforms, platform)
				end
			end
		end
	end
	
	-- Find Steampunk platform
	local steampunk = workspace:FindFirstChild("Steampunk")
	if steampunk then
		local platform = steampunk:FindFirstChild("Platform")
		if platform and platform:IsA("BasePart") then
			table.insert(foundPlatforms, platform)
		end
	end
	
	return foundPlatforms
end

-- Wait until at least one platform is loaded
platforms = findPlatforms()
while #platforms == 0 do
	task.wait(0.5)
	platforms = findPlatforms()
end

local isHoldingDrop = false
local dropTime = 0

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- We don't check gameProcessed here because 'S' and 'Down' are movement keys
	-- and will always be marked as processed by the game engine
	if input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		isHoldingDrop = true
		dropTime = tick() + 0.35 -- Drop for at least 0.35s even if tapped
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		isHoldingDrop = false
	end
end)

-- Track dropping state per platform
local droppingPlatforms = {}

local function updatePlatformCollision(platform)
	if not rootPart or not platform then return end
	
	local velocityY = rootPart.AssemblyLinearVelocity.Y
	local platformTop = platform.Position.Y + (platform.Size.Y / 2)
	local platformBottom = platform.Position.Y - (platform.Size.Y / 2)
	
	-- Calculate the bottom of the player's feet
	local bottomOfFeet
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		bottomOfFeet = rootPart.Position.Y - (humanoid.HipHeight + rootPart.Size.Y/2)
	else
		bottomOfFeet = rootPart.Position.Y - 3
	end
	
	-- If the player is actively trying to drop
	if isHoldingDrop or tick() < dropTime then
		droppingPlatforms[platform] = true
	end

	if droppingPlatforms[platform] then
		-- Stay non-solid until the player is clearly below the platform
		if bottomOfFeet < platformBottom - 1 then
			droppingPlatforms[platform] = nil
		else
			platform.CanCollide = false
			return
		end
	end

	-- One-way collision logic
	if velocityY > 1.0 then
		-- Always pass through when jumping up
		platform.CanCollide = false
	elseif bottomOfFeet >= platformTop - 1.0 then
		-- Only solid if feet are on or above the top surface
		platform.CanCollide = true
	else
		-- Non-solid if inside or below
		platform.CanCollide = false
	end
end

RunService.Stepped:Connect(function()
	-- Refresh platform list in case new ones were added
	local currentPlatforms = findPlatforms()
	if #currentPlatforms > #platforms then
		platforms = currentPlatforms
	end
	
	-- Update collision for all platforms
	for _, platform in ipairs(platforms) do
		updatePlatformCollision(platform)
	end
end)