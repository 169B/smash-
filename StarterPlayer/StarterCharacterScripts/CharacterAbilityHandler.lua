-- @ScriptType: LocalScript
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local char = script.Parent or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local animator = hum:WaitForChild("Animator")

local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local AbilityEvent = eventsFolder:WaitForChild("AbilityEvent")
local AbilityTriggered = eventsFolder:WaitForChild("AbilityTriggered")
local RequestAbility = eventsFolder:WaitForChild("RequestAbility")
local AbilityConfirm = eventsFolder:WaitForChild("AbilityConfirm")

-- 1. SETTINGS, COOLDOWNS, & ASSET IDs
local onCooldown = {}
local cooldownSettings = {
	["Sword"] = {
		Key = Enum.KeyCode.E, 
		Cooldown = 2, 
		Action = "Sword", 
		Title = "SWORD", 
		Color = Color3.fromRGB(200, 50, 50),
		AssetID = 567479941 -- R15 Side Swipe Animation ID
	},
	["Kick"] = {
		Key = nil, 
		Cooldown = 1.5, 
		Action = "Kick", 
		Title = "KICK", 
		Color = Color3.fromRGB(100, 200, 100),
		AssetID = 134352543257888
	},
	["Rocket"] = {
		Key = nil, 
		Cooldown = 3, 
		Action = "Rocket", 
		Title = "ROCKET", 
		Color = Color3.fromRGB(50, 150, 250),
		AssetID = 522635514 -- Tool Slash Animation (proper animation ID)
	},
	["Paintball"] = {
		Key = Enum.UserInputType.MouseButton1, 
		Cooldown = 1, 
		Action = "Paintball", 
		Title = "GUN", 
		Color = Color3.fromRGB(255, 255, 255),
		AssetID = 522635514 -- Tool Slash Animation (proper animation ID)
	},
	["AthleteM1"] = {
		Key = nil, 
		Cooldown = 0.5, 
		Action = "AthleteM1", 
		Title = "STRIKE", 
		Color = Color3.fromRGB(255, 150, 0),
	},
	["Trowel"] = {
		Key = Enum.KeyCode.F, 
		Cooldown = 4, 
		Action = "Trowel", 
		Title = "WALL", 
		Color = Color3.fromRGB(255, 255, 255)
	},
	["Bomb"] = {
		Key = Enum.KeyCode.R, 
		Cooldown = 2, 
		Action = "Bomb", 
		Title = "BOMB", 
		Color = Color3.fromRGB(50, 50, 50)
	},
}

-- 2. HELPER: VISUAL COOLDOWN EFFECT
local function startCooldownUI(buttonName, duration)
	if duration <= 0 then return end
	onCooldown[buttonName] = true
	local button = ContextActionService:GetButton(buttonName)

	if button then
		local originalColor = cooldownSettings[buttonName] and cooldownSettings[buttonName].Color or button.BackgroundColor3
		button.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Darken when used

		task.delay(duration, function()
			onCooldown[buttonName] = false
			-- Re-fetch the button in case it was recreated
			local currentButton = ContextActionService:GetButton(buttonName)
			if currentButton then
				currentButton.BackgroundColor3 = originalColor
			end
		end)
	else
		task.delay(duration, function() onCooldown[buttonName] = false end)
	end
end

-- Animation tracks cache
local animationTracks = {}

-- Play animation for ability
local function playAbilityAnimation(abilityName)
	local config = cooldownSettings[abilityName]
	if not config then return end
	
	local animId
	if abilityName == "AthleteM1" then
		local ids = {"79021705950796", "81564357897668"}
		local nextAnimIndex = char:GetAttribute("NextAnimIndex") or 1
		animId = "rbxassetid://" .. ids[nextAnimIndex]
		char:SetAttribute("NextAnimIndex", nextAnimIndex == 1 and 2 or 1)
	elseif config.AssetID then
		animId = "rbxassetid://" .. config.AssetID
	else
		return
	end
	
	-- Stop any other playing animations for this ability to prevent overlapping/looping issues
	for id, track in pairs(animationTracks) do
		if track.IsPlaying and (abilityName == "AthleteM1" and (id == "rbxassetid://79021705950796" or id == "rbxassetid://81564357897668")) then
			track:Stop(0.1)
		end
	end

	-- Get or create animation track
	if not animationTracks[animId] then
		local anim = script.Parent:FindFirstChild(abilityName .. "Anim")
		if not anim or not anim:IsA("Animation") then
			anim = Instance.new("Animation")
			anim.Name = abilityName .. "Anim"
			anim.AnimationId = animId
			anim.Parent = script.Parent
		else
			-- If it exists but has a different ID, update it
			anim.AnimationId = animId
		end
		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action3
		track.Looped = false -- ENSURE NOT LOOPED
		animationTracks[animId] = track
	end
	
	local track = animationTracks[animId]
	track.Looped = false -- Double check
	track:Play(0.1, 1, 1) -- fadeTime, weight, speed
	
	return track
end

-- 3. CORE ABILITY EXECUTION
local lastClientFire = {}
local function handleAbility(actionName, inputState)
	if char:GetAttribute("IsStunned") then return end
	
	if inputState == Enum.UserInputState.Begin then

		-- Athlete M1 override
		local classTag = char:FindFirstChild("Class")
		local className = classTag and classTag.Value or ""
		if actionName == "Paintball" and className == "Athlete" then
			actionName = "AthleteM1"
		end

		local config = cooldownSettings[actionName]
		if not config or onCooldown[actionName] then 
			print("Config not found or on cooldown")
			return 
		end

		-- Determine the actual action to perform
		local actualAction = config.Action
		local actualActionName = actionName
		local isAirbomb = false
		local airbombAngle = false
		local airbombDir = 0 -- Direction for diagonal airbomb: -1 for left, 1 for right
		
		-- Special handling for Sword (E key): Check if W is held
		if actionName == "Sword" then
			local isHoldingW = char:GetAttribute("IsHoldingW") or UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
			if isHoldingW then
				actualAction = "Kick"
				actualActionName = "Kick"
				config = cooldownSettings["Kick"]
				
				if not config or onCooldown["Kick"] then
					print("Kick on cooldown")
					return
				end
			end
		end

		-- Special handling for Bomb (R key): Check if A or D is held
		if actionName == "Bomb" then
			local isHoldingA = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
			local isHoldingD = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)
			local isHoldingW = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
			
			if isHoldingW and (isHoldingA or isHoldingD) then
				-- Airbomb with diagonal launch: W+A+R or W+D+R
				isAirbomb = true
				airbombAngle = true
				airbombDir = isHoldingA and -1 or 1
			elseif isHoldingA or isHoldingD then
				-- Override: Fire rocket instead of placing bomb
				actualAction = "Rocket"
				actualActionName = "Rocket"
				config = cooldownSettings["Rocket"]
				
				-- Check rocket cooldown
				if not config or onCooldown["Rocket"] then
					print("Rocket on cooldown")
					return
				end
			elseif isHoldingW then
				-- Airbomb mode: W + R
				isAirbomb = true
			end
		end

		-- Play animation for this ability
		playAbilityAnimation(actualActionName)

		-- Get the 2D direction from the Movement script's attribute
		local currentLookDir = char:GetAttribute("LookDir") or 1

		-- Fire to Server (Passing the Action name, current direction, airbomb flag, angle flag, and direction)
		print("Firing AbilityEvent:", actualAction, currentLookDir, isAirbomb, airbombAngle, airbombDir)
		AbilityEvent:FireServer(actualAction, currentLookDir, isAirbomb, airbombAngle, airbombDir)

		-- Cooldown UI is started when server confirms via AbilityConfirm event
	end
end

-- Listen for server confirmation of ability use
AbilityConfirm.OnClientEvent:Connect(function(abilityName, cooldown)
	-- Start Cooldown UI for the actual ability
	startCooldownUI(abilityName, cooldown)

	-- If it's AthleteM1, also update the Paintball UI
	local uiActionName = abilityName
	if abilityName == "AthleteM1" then
		uiActionName = "Paintball"
		startCooldownUI(uiActionName, cooldown)
	end
	
	-- Signal UI to start timer
	AbilityTriggered:Fire(uiActionName, cooldown)
end)

-- 4. BIND ACTIONS & STYLE BUTTONS
for name, data in pairs(cooldownSettings) do
	if data.Key then
		ContextActionService:BindAction(name, function(actionName, inputState, inputObject)
			handleAbility(actionName, inputState, inputObject)
			return Enum.ContextActionResult.Pass
		end, false, data.Key)
	end
	ContextActionService:SetTitle(name, data.Title)

	-- Style Mobile Button
	local button = ContextActionService:GetButton(name)
	if button then
		button.BackgroundColor3 = data.Color
		button.Size = UDim2.new(0, 75, 0, 75)
		-- Optional: You could use data.AssetID here to set a button image if you wanted!
	end
end

-- Handle character respawn to reset animator reference
local function onCharacterAdded(newCharacter)
	char = newCharacter
	hum = newCharacter:WaitForChild("Humanoid")
	root = newCharacter:WaitForChild("HumanoidRootPart")
	animator = hum:WaitForChild("Animator")
	animationTracks = {}
	
	newCharacter:SetAttribute("VisualFlip", 1)
	
	-- Reset all cooldowns on respawn
	for buttonName, _ in pairs(onCooldown) do
		onCooldown[buttonName] = false
		-- Restore button color if it exists
		local button = ContextActionService:GetButton(buttonName)
		if button and cooldownSettings[buttonName] then
			button.BackgroundColor3 = cooldownSettings[buttonName].Color
		end
	end
end

player.CharacterAdded:Connect(onCharacterAdded)

-- 5. DYNAMIC MOBILE BUTTON PLACEMENT
local function updateAbilityButtons()
	local viewport = workspace.CurrentCamera.ViewportSize
	local isLandscape = viewport.X > viewport.Y

	if isLandscape then
		ContextActionService:SetPosition("Paintball", UDim2.new(0.85, 0, 0.70, 0)) 
		ContextActionService:SetPosition("Sword", UDim2.new(0.75, 0, 0.70, 0))
		ContextActionService:SetPosition("Rocket", UDim2.new(0.80, 0, 0.50, 0))
		ContextActionService:SetPosition("Trowel", UDim2.new(0.70, 0, 0.50, 0))
		ContextActionService:SetPosition("Bomb", UDim2.new(0.90, 0, 0.45, 0))
	else
		ContextActionService:SetPosition("Paintball", UDim2.new(0.80, 0, 0.80, 0))
		ContextActionService:SetPosition("Sword", UDim2.new(0.60, 0, 0.80, 0))
		ContextActionService:SetPosition("Rocket", UDim2.new(0.80, 0, 0.65, 0))
		ContextActionService:SetPosition("Trowel", UDim2.new(0.60, 0, 0.65, 0))
		ContextActionService:SetPosition("Bomb", UDim2.new(0.70, 0, 0.50, 0))
	end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAbilityButtons)
task.delay(0.5, updateAbilityButtons)

-- 6. SYNC WITH MOVEMENT BUTTONS
task.spawn(function()
	task.wait(1)
	local jumpBtn = ContextActionService:GetButton("PlatformJump")
	if jumpBtn then
		jumpBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		jumpBtn.Size = UDim2.new(0, 90, 0, 90)
	end
end)

-- 7. EXTERNAL REQUEST SYNC
RequestAbility.Event:Connect(function(actionName)
	handleAbility(actionName, Enum.UserInputState.Begin)
end)