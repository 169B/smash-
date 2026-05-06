-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ScreenKOEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ScreenKOEvent")
local ScreenKODeathBeamEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ScreenKODeathBeamEvent")
local Camera = workspace.CurrentCamera

local DOUBLE_JUMP_ANIM_ID = "rbxassetid://125526256487210"
local SCREEN_KO_ANIM_ID = "rbxassetid://83514971910549"
local SHATTER_TEXTURE = "rbxassetid://243098098"

local function createShatterEffect(position)
	local attachment = Instance.new("Attachment")
	attachment.Position = position
	attachment.Parent = workspace.Terrain
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SHATTER_TEXTURE
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
	emitter.LightEmission = 0.5
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(10, 30)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Rate = 0
	emitter.Parent = attachment
	
	emitter:Emit(50)
	Debris:AddItem(attachment, 1.5)
end

local activeKOs = {}

local frozenParts = {}
local frozenAnimations = {}

local function freezeWorld(victimChar, effectBody)
	-- Freeze logic removed
end

local function unfreezeWorld()
	-- Unfreeze logic removed
end

ScreenKOEvent.OnClientEvent:Connect(function(victim, safeRegionPos)
	if not victim or not victim.Character then return end
	
	-- Debounce to prevent double-firing for the same victim
	if activeKOs[victim] then return end
	activeKOs[victim] = true
	task.delay(5, function()
		activeKOs[victim] = nil
	end)
	
	local localPlayer = Players.LocalPlayer
	
	-- Store original camera state
	local originalSubject = Camera.CameraSubject
	local originalFOV = Camera.FieldOfView
	local originalCFrame = Camera.CFrame
	local victimChar = victim.Character
	local victimHumanoid = victimChar:FindFirstChildOfClass("Humanoid")
	
	-- Set camera to scriptable to freeze it in place
	freezeWorld(victim.Character, body)
	-- Camera.CameraType = Enum.CameraType.Scriptable
	
	-- Use a clone for the effect instead of the original character
	victimChar.Archivable = true
	local body = victimChar:Clone()
	
	if not body then return end
	
	body.Parent = workspace
	
	-- Hide the original character for this client
	if victimChar then
		local vHumanoid = victimChar:FindFirstChildOfClass("Humanoid")
		if vHumanoid then
			vHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		for _, part in ipairs(victim.Character:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.Transparency = 1
			end
		end
	end
	
	local track
	local animator
	
	-- Setup the body
	body.PrimaryPart = body:FindFirstChild("HumanoidRootPart") or body:FindFirstChild("Torso") or body:FindFirstChild("UpperTorso") or body:FindFirstChildOfClass("BasePart")
	
	-- Scale the body down slightly
	body:ScaleTo(0.7)
	
	-- Hide name and health on the clone
	local bodyHumanoid = body:FindFirstChildOfClass("Humanoid")
	if bodyHumanoid then
		bodyHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		
		-- Make the clone flat like paper (thinner)
		local success, desc = pcall(function() return bodyHumanoid:GetAppliedDescription() end)
		if success and desc then
			desc.DepthScale = 0.1
			pcall(function() bodyHumanoid:ApplyDescription(desc) end)
		else
			local depthScale = bodyHumanoid:FindFirstChild("DepthScale")
			if not depthScale then
				depthScale = Instance.new("NumberValue")
				depthScale.Name = "DepthScale"
				depthScale.Parent = bodyHumanoid
			end
			depthScale.Value = 0.1
		end
	end
	
	-- Disable all scripts in the clone
	for _, part in ipairs(body:GetDescendants()) do
		if part:IsA("Script") or part:IsA("LocalScript") then
			part.Enabled = false
		end
	end
	
	-- Specifically disable the Animate script in the clone
	local animateScript = body:FindFirstChild("Animate")
	if animateScript then
		animateScript.Disabled = true
	end
	
	-- Stop all animation tracks in the clone's humanoid
	local bodyHumanoid = body:FindFirstChildOfClass("Humanoid")
	local tempAnimator = bodyHumanoid and bodyHumanoid:FindFirstChildOfClass("Animator")
	if tempAnimator then
		for _, t in ipairs(tempAnimator:GetPlayingAnimationTracks()) do
			t:Stop(0)
		end
	end
	
	-- Play freeze animation on the clone
	animator = tempAnimator
	if animator then
		local freezeAnim = Instance.new("Animation")
		freezeAnim.AnimationId = SCREEN_KO_ANIM_ID
		track = animator:LoadAnimation(freezeAnim)
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		track:Play()
	end
	
	for _, part in ipairs(body:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = (part == body.PrimaryPart)
			part.CanCollide = false
			part.CastShadow = false
			if part.Name == "HumanoidRootPart" then
				part.Transparency = 1
			else
				part.Transparency = 1
				TweenService:Create(part, TweenInfo.new(1.0, Enum.EasingStyle.Linear), {Transparency = 0}):Play()
			end
		elseif part:IsA("Decal") then
			part.Transparency = 1
			TweenService:Create(part, TweenInfo.new(1.0, Enum.EasingStyle.Linear), {Transparency = 0}):Play()
		end
	end
	
	-- Calculate scale to fit nicely on the screen
	local fov = Camera.FieldOfView
	local distance = 15.0
	local finalDistance = 8.0 -- Further away from camera for the final impact
	local visibleHeight = 2 * distance * math.tan(math.rad(fov / 2))
	local _, size = body:GetBoundingBox()
	local scaleFactor = (visibleHeight * 0.4) / size.Y -- 0.6 to take up less of the screen
	local originalScale = body:GetScale()
	body:ScaleTo(scaleFactor)
	
	-- Start from 290 studs above and 400 studs in front of the camera
	local startOffset = CFrame.new(0, 290, -400) * CFrame.Angles(0, math.pi, 0)
	
	-- Calculate random position on screen
	local visibleWidth = visibleHeight * (Camera.ViewportSize.X / Camera.ViewportSize.Y)
	local randomX = (math.random() - 0.5) * visibleWidth * 0.7
	
	local mapName = victimChar:GetAttribute("MapName")
	local randomY
	if mapName == "Stadium" then
		-- Hit lower on the screen for Stadium
		-- Range: -40% to 0% (-0.4 to 0.0)
		randomY = (math.random() * 0.4 - 0.4) * visibleHeight
	else
		-- Range: -40% to +40% (-0.4 to 0.4)
		randomY = (math.random() * 0.8 - 0.4) * visibleHeight
	end
	
	local endOffset = CFrame.new(randomX, randomY, -finalDistance) * CFrame.Angles(0, math.pi, 0)
	
	-- Center the character based on its bounding box
	local bboxCFrame, _ = body:GetBoundingBox()
	local centerOffset = body:GetPivot():Inverse() * bboxCFrame
	
	-- Random rotation for the final impact (Z-axis roll so they stay flat against the screen)
	local finalZRotation = (math.random() - 0.5) * math.pi * 2
	local randomRot = CFrame.new()
	
	-- Slam effect (Fling toward camera using RenderStepped to stay relative to screen)
	local freezeDuration = 1.0
	local flingDuration = 0.4
	local startTime = os.clock()
	
	local connection
	local soundPlayed = false
	local imageShown = false
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		
		-- Play sound 0.25 seconds before impact
		if elapsed >= (freezeDuration + flingDuration - 0.25) and not soundPlayed then
			soundPlayed = true
			local hitSound = Instance.new("Sound")
			hitSound.SoundId = "rbxassetid://138023055460454"
			hitSound.Parent = workspace
			hitSound:Play()
			Debris:AddItem(hitSound, 5)
			
			local currentKOCount = Players.LocalPlayer:GetAttribute("ScreenKOCount") or 0
			Players.LocalPlayer:SetAttribute("ScreenKOCount", currentKOCount + 1)
			Players.LocalPlayer:SetAttribute("ScreenKOPlaying", true)
		end
		
		-- Show cracked screen image exactly at impact
		if elapsed >= (freezeDuration + flingDuration) and not imageShown then
			imageShown = true
			local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
			if playerGui then
				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = "CrackedScreenGui"
				screenGui.IgnoreGuiInset = true
				screenGui.Parent = playerGui
				
				-- Calculate where the clone will hit the screen in 2D pixels
				local finalWorldPos = (Camera.CFrame * endOffset).Position
				local screenPos = Camera:WorldToScreenPoint(finalWorldPos)
				
				local imageLabel = Instance.new("ImageLabel")
				-- Use the actual Image ID, not the Decal ID
				imageLabel.Image = "rbxassetid://80931993786653"
				imageLabel.BackgroundTransparency = 1
				imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				imageLabel.Rotation = math.random(0, 360)
				-- Make it large enough to look like a realistic screen crack
				imageLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
				imageLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
				imageLabel.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
				imageLabel.ScaleType = Enum.ScaleType.Fit
				imageLabel.Parent = screenGui
				
				-- Fade out after a moment (wait 2 seconds, fade for 1 second)
				TweenService:Create(imageLabel, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 2), {ImageTransparency = 1}):Play()
				Debris:AddItem(screenGui, 3.5)
				
				task.delay(3, function()
					local newCount = (Players.LocalPlayer:GetAttribute("ScreenKOCount") or 1) - 1
					Players.LocalPlayer:SetAttribute("ScreenKOCount", newCount)
					if newCount <= 0 then
						Players.LocalPlayer:SetAttribute("ScreenKOPlaying", false)
					end
				end)
			end
		end
		
		if elapsed < freezeDuration then
			-- Stay at the start position during the freeze
			local currentCFrame = Camera.CFrame * startOffset * randomRot
			body:PivotTo(currentCFrame * centerOffset:Inverse())
			return
		end
		
		local flingElapsed = elapsed - freezeDuration
		local alpha = math.clamp(flingElapsed / flingDuration, 0, 1)
		
		-- Use Quad Out easing for the alpha
		local easedAlpha = 1 - (1 - alpha) ^ 2
		
		local currentOffset = startOffset:Lerp(endOffset, easedAlpha)
		
		-- Spin the character while flying, ending at the final Z rotation
		local spinX = math.pi * 2 * alpha
		local spinY = math.pi * 2 * alpha
		local spinZ = finalZRotation * easedAlpha
		local spinCFrame = CFrame.Angles(spinX, spinY, spinZ)
		local currentCFrame = Camera.CFrame * currentOffset * randomRot:Lerp(CFrame.new(), easedAlpha) * spinCFrame
		
		body:PivotTo(currentCFrame * centerOffset:Inverse())
		
		if alpha >= 1 then
			connection:Disconnect()
			
			-- Animation is already playing, just anchor the parts
			for _, part in ipairs(body:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			
			-- Shatter
			createShatterEffect(body.PrimaryPart.Position)
			
			-- Flash
			local flash = Instance.new("ColorCorrectionEffect")
			flash.Brightness = 1
			flash.Parent = Camera
			TweenService:Create(flash, TweenInfo.new(0.3), {Brightness = 0}):Play()
			Debris:AddItem(flash, 0.3)
			
			-- Wait on screen for 1 second before falling
			task.wait(1.0)
			
			if body and body.Parent then
				local fallDuration = 1.5
				local fallStartTime = os.clock()
				local startPivot = body:GetPivot()
				
				local fallConnection
				fallConnection = RunService.RenderStepped:Connect(function()
					if not body or not body.Parent then
						fallConnection:Disconnect()
						return
					end
					
					local fallElapsed = os.clock() - fallStartTime
					if fallElapsed >= fallDuration then
						fallConnection:Disconnect()
						body:Destroy()
						return
					end
					
					-- Accelerate downwards relative to the camera's UpVector to slide down the screen
					local dropDistance = 100 * (fallElapsed * fallElapsed)
					local currentPivot = startPivot - (Camera.CFrame.UpVector * dropDistance)
					body:PivotTo(currentPivot)
				end)
				
				-- Calculate final position after falling and send to server for death beam
				local finalDropDistance = 100 * (fallDuration * fallDuration)
				local finalFallPosition = startPivot - (Camera.CFrame.UpVector * finalDropDistance)
				
				-- Send the final position to the server for the death beam effect
				ScreenKODeathBeamEvent:FireServer(victim, finalFallPosition.Position, safeRegionPos)
				
				task.wait(fallDuration)
			end
			
			-- Keep the screen effect for an extra 3.5 seconds
			task.wait(3.5)
			
			-- Wait for the victim to respawn if they haven't already
			if victim.Parent and (victim.Character == victimChar or not victim.Character) then
				local bindable = Instance.new("BindableEvent")
				local conn1 = victim.CharacterAdded:Connect(function() bindable:Fire() end)
				local conn2 = Players.PlayerRemoving:Connect(function(p) 
					if p == victim then bindable:Fire() end 
				end)
				
				-- 10 second timeout fallback
				task.delay(10, function() bindable:Fire() end)
				
				bindable.Event:Wait()
				conn1:Disconnect()
				conn2:Disconnect()
				bindable:Destroy()
			end
			
			-- Reset camera subject
			unfreezeWorld()
			-- Camera.CameraType = Enum.CameraType.Custom
			-- local localHumanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			-- Camera.CameraSubject = localHumanoid or originalSubject
		end
	end)
end)