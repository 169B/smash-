-- @ScriptType: LocalScript
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local player = game.Players.LocalPlayer
local char = script.Parent
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")

-- Double Jump Animation
local DOUBLE_JUMP_ANIM_ID = "rbxassetid://125526256487210" -- Double jump animation (from game assets)
local FALL_ANIM_ID = "rbxassetid://507767968" -- Standard R15 fall animation

local doubleJumpAnim = Instance.new("Animation")
doubleJumpAnim.AnimationId = DOUBLE_JUMP_ANIM_ID

local fallAnim = Instance.new("Animation")
fallAnim.AnimationId = FALL_ANIM_ID

local doubleJumpTrack = nil
local fallTrack = nil
local isPlayingDoubleJump = false
local isPlayingFall = false

-- Preload the animation
local function preloadAnimation()
	if not doubleJumpTrack then
		doubleJumpTrack = animator:LoadAnimation(doubleJumpAnim)
		doubleJumpTrack.Priority = Enum.AnimationPriority.Action2
		doubleJumpTrack.Looped = false
	end
	if not fallTrack then
		fallTrack = animator:LoadAnimation(fallAnim)
		fallTrack.Priority = Enum.AnimationPriority.Action2
		fallTrack.Looped = true
	end
end

-- Disable/enable the Animate script
local function setAnimateEnabled(enabled)
	return true
end

local function isAbilityTrack(track)
	local abilityIds = {
		["567479941"] = true, -- Sword
		["522635514"] = true, -- Rocket/Paintball
	}
	local id = track.Animation.AnimationId:match("%d+")
	if id and abilityIds[id] then
		return true
	end
	if track.Animation.AnimationId == "rbxassetid://98167960747176" or track.Animation.AnimationId == "rbxassetid://132313749719915" then
		return true
	end
	return false
end

-- Stop all other animations
local function stopAllOtherAnimations()
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track ~= doubleJumpTrack and track ~= fallTrack and not isAbilityTrack(track) then
			track:Stop()
		end
	end
end

-- === THE DYNAMIC Z-LOCK ===
local spawnZ = root.Position.Z 

-- Listen for teleport updates
char:GetAttributeChangedSignal("SpawnZ"):Connect(function()
	local newZ = char:GetAttribute("SpawnZ")
	if newZ then
		spawnZ = newZ
	end
end)

-- SETTINGS
local MAX_JUMPS = 2
local JUMP_POWER = 40
local currentJumps = 0
local isDropping = false
local isHoldingS = false
local lookDir = 1 -- 1 for Right (D), -1 for Left (A) on screen

-- MOVEMENT STATES
local isHoldingLeft = false
local isHoldingRight = false

local PLATFORM_GROUP = "Platforms"
local PLAYER_GROUP = "Players"

-- PHYSICS INITIALIZATION
hum.AutoRotate = true 
hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) 

local rootAttach = root:FindFirstChild("RootAttachment") or Instance.new("Attachment", root)
local alignOri = root:FindFirstChild("LockOrientation") or Instance.new("AlignOrientation")
alignOri.Name = "LockOrientation"
alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
alignOri.Attachment0 = rootAttach
alignOri.RigidityEnabled = true 
alignOri.Parent = root

local eventsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Events")
local RequestMovement = eventsFolder:WaitForChild("RequestMovement")

-- 1. INPUT LOGIC
local function handleMovement(actionName, inputState)
	local isPressed = (inputState == Enum.UserInputState.Begin)
	if actionName == "MoveLeft" then isHoldingLeft = isPressed end
	if actionName == "MoveRight" then isHoldingRight = isPressed end
end

ContextActionService:BindAction("MoveLeft", handleMovement, false, Enum.KeyCode.A, Enum.KeyCode.Left)
ContextActionService:BindAction("MoveRight", handleMovement, false, Enum.KeyCode.D, Enum.KeyCode.Right)

-- 2. JUMP LOGIC (Responsive Velocity)
local lastJumpTick = 0
local function handleJump(actionName, inputState)
	local isPressed = (inputState == Enum.UserInputState.Begin)
	if actionName == "PlatformJump" then
		char:SetAttribute("IsHoldingW", isPressed)
	end
	if inputState == Enum.UserInputState.Begin then
		-- Always signal jump request to the server (for breaking stuns/edges)
		char:SetAttribute("JumpRequested", tick())
		
		-- If stunned (on an edge), apply immediate client-side launch to break free
		if char:GetAttribute("IsStunned") then
			root.Anchored = false
			char:SetAttribute("IsStunned", false)
			
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, JUMP_POWER * 1.25, 0)
			hum.Jump = true
			currentJumps = MAX_JUMPS -- Take away double jump after jumping off ledge
			
			-- Immediately clear edge state animations
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if track ~= doubleJumpTrack and track ~= fallTrack then
					track:Stop(0)
				end
			end
			return
		end
		
		if tick() - lastJumpTick < 0.15 then return end 

		if hum.FloorMaterial ~= Enum.Material.Air or (currentJumps < MAX_JUMPS and not char:GetAttribute("AirbombNoDoubleJump")) then
			lastJumpTick = tick()
			
			-- Play double jump animation on second jump
			if currentJumps >= 1 then
				preloadAnimation()
				
				-- Stop fall animation if it's playing
				if fallTrack and isPlayingFall then
					fallTrack:Stop(0.05)
					isPlayingFall = false
				end
				
				setAnimateEnabled(false)
				-- stopAllOtherAnimations() removed to prevent breaking default Animate script
				doubleJumpTrack:Play(0.05, 1, 1.05)
				isPlayingDoubleJump = true

				-- Slash particle effect
				local attachment = Instance.new("Attachment")
				attachment.Parent = root

				local particles = Instance.new("ParticleEmitter")
				particles.Parent = attachment
				particles.Texture = "rbxassetid://6711256324"
				particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
				particles.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 2),
					NumberSequenceKeypoint.new(0.5, 1.5),
					NumberSequenceKeypoint.new(1, 0)
				})
				particles.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.5, 0.3),
					NumberSequenceKeypoint.new(1, 1)
				})
				particles.Lifetime = NumberRange.new(0.1, 0.2)
				particles.Speed = NumberRange.new(0, 2)
				particles.SpreadAngle = Vector2.new(90, 90)
				particles.LightEmission = 1
				particles.LightInfluence = 0
				particles.Rotation = NumberRange.new(0, 360)
				particles.RotSpeed = NumberRange.new(0, 0)
				particles:Emit(8)

				task.delay(0.3, function()
					attachment:Destroy()
				end)
				
				-- Stop animation after flip completes
				task.delay(0.53, function()
					isPlayingDoubleJump = false
				end)
			end
			
			currentJumps += 1
			-- Direct velocity application bypasses humanoid lag
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, JUMP_POWER, 0)
		end
	end
end

ContextActionService:BindAction("PlatformJump", handleJump, false, Enum.KeyCode.Space, Enum.KeyCode.W, Enum.KeyCode.Up)

-- 3. DROP LOGIC
local function handleDrop(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		isHoldingS = true
		isDropping = true
	elseif inputState == Enum.UserInputState.End then
		isHoldingS = false
		isDropping = false
	end
end

ContextActionService:BindAction("PlatformDrop", handleDrop, false, Enum.KeyCode.S, Enum.KeyCode.Down)

-- 7. BINDABLE EVENT SYNC
RequestMovement.Event:Connect(function(actionName, inputState)
	if actionName == "MoveLeft" or actionName == "MoveRight" then
		handleMovement(actionName, inputState)
	elseif actionName == "PlatformJump" then
		handleJump(actionName, inputState)
	elseif actionName == "PlatformDrop" then
		handleDrop(actionName, inputState)
	end
end)

-- 4. JUMP TRACKING
char:GetAttributeChangedSignal("IsStunned"):Connect(function()
	if not char:GetAttribute("IsStunned") then
		-- When leaving a stun/grab, ensure we are in a clean state
		if not isPlayingFall and not isPlayingDoubleJump then
			setAnimateEnabled(true)
		end
		
		-- If we just fell off a ledge (not jumped), give us 1 jump used so next is double jump
		if hum.FloorMaterial == Enum.Material.Air and currentJumps == 0 then
			currentJumps = 1
		end
	else
		-- When entering a stun/grab, reset jumps
		currentJumps = 0
	end
end)

hum.StateChanged:Connect(function(oldState, newState)
	preloadAnimation()
	
	if newState == Enum.HumanoidStateType.Landed then
		currentJumps = 0
		-- Clear airbomb double jump restriction
		char:SetAttribute("AirbombNoDoubleJump", nil)
		-- Stop double jump on landing
		if isPlayingDoubleJump then
			if doubleJumpTrack then doubleJumpTrack:Stop(0.1) end
			isPlayingDoubleJump = false
			setAnimateEnabled(true)
		end
	elseif newState == Enum.HumanoidStateType.Freefall and currentJumps == 0 then
		currentJumps = 1 
	end
end)

-- 5. SMART GHOSTING
local overlapParams = OverlapParams.new()

-- Helper to check if ability animations are playing
local function isAbilityAnimationPlaying()
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track == doubleJumpTrack or track == fallTrack then
			continue
		end
		
		if isAbilityTrack(track) and track.IsPlaying then
			return true
		end
	end
	return false
end
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances = {char}

RunService.Stepped:Connect(function()
	if not char or not char.Parent or not hum or not hum.Parent or hum.Health <= 0 then return end
	local shouldGhost = (root.AssemblyLinearVelocity.Y > 0.5 or isDropping or isHoldingS)

	if not shouldGhost then
		local checkSize = Vector3.new(2, 6, 2)
		local overlaps = workspace:GetPartBoundsInBox(root.CFrame, checkSize, overlapParams)
		if overlaps then
			for _, part in pairs(overlaps) do
				if part.CollisionGroup == PLATFORM_GROUP then
					shouldGhost = true
					break
				end
			end
		end
	end

	local targetGroup = shouldGhost and PLAYER_GROUP or "Default"
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = targetGroup
		end
	end
end)

-- 6. EXECUTE MOVEMENT & PHYSICS (Heartbeat)
RunService.Heartbeat:Connect(function(dt)
	if not char or not char.Parent or not hum or not hum.Parent or hum.Health <= 0 then return end
	if char:GetAttribute("ScreenKOActive") then return end
	
	-- A. Dynamic Z-Lock (Always run this to keep player on plane)
	local currentPos = root.Position
	root.CFrame = root.CFrame + Vector3.new(0, 0, spawnZ - currentPos.Z)
	root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, 0)
	
	-- Skip movement logic if stunned (e.g. on an edge)
	if char:GetAttribute("IsStunned") then 
		if isPlayingFall then
			if fallTrack then fallTrack:Stop(0.1) end
			isPlayingFall = false
		end
		return 
	end

	-- Fall Speed Logic

	-- B. Directional Math
	local screenMove = 0
	if isHoldingRight then screenMove = 1 end
	if isHoldingLeft then screenMove = -1 end

	-- C. World Movement (Inverted for Flipped Camera)
	local worldMoveX = -screenMove 
	hum:Move(Vector3.new(worldMoveX, 0, 0), false)

	-- D. Visual Rotation & Attribute Sync
	local visualFlip = char:GetAttribute("VisualFlip") or 1
	if screenMove ~= 0 then
		lookDir = screenMove
		-- Points character in direction of screen movement
		alignOri.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(worldMoveX * visualFlip, 0, 0))
	else
		-- Maintain orientation based on lookDir and visualFlip even when standing still
		local currentWorldDir = -lookDir
		alignOri.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(currentWorldDir * visualFlip, 0, 0))
	end

	-- Tells ServerCombat which way to fire based on your screen
	char:SetAttribute("LookDir", lookDir)

	-- E. Animation Management
	if isPlayingDoubleJump then
		-- Double jump is playing, wait for it to finish
		return
	end

	if hum.FloorMaterial == Enum.Material.Air then
		-- Play fall animation for all air states (unless double jumping)
		if not isPlayingFall or (fallTrack and not fallTrack.IsPlaying) then
			setAnimateEnabled(false)
			-- stopAllOtherAnimations() removed to prevent breaking default Animate script
			preloadAnimation()
			if fallTrack then fallTrack:Play(0.1) end
			isPlayingFall = true
		end
	else
		-- On ground
		if isPlayingFall then
			if fallTrack then fallTrack:Stop(0.1) end
			isPlayingFall = false
			setAnimateEnabled(true)
		end
	end
end)