-- @ScriptType: LocalScript
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = script.Parent
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")

local events = ReplicatedStorage:WaitForChild("Events")
local EdgeGrabEvent = events:WaitForChild("EdgeGrabEvent")
local EdgeReleaseEvent = events:WaitForChild("EdgeReleaseEvent")

local ANIMATION_ID = "rbxassetid://98167960747176"
local MIRRORED_ANIMATION_ID = "rbxassetid://132313749719915"

local edgeAnimation = Instance.new("Animation")
edgeAnimation.AnimationId = ANIMATION_ID

local mirroredEdgeAnimation = Instance.new("Animation")
mirroredEdgeAnimation.AnimationId = MIRRORED_ANIMATION_ID

local activeTrack = nil

local edges = {}
local lastGrab = 0
local GRAB_COOLDOWN = 2

-- Listen for "S" key to release from edge
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.S then
		root.Anchored = false
		character:SetAttribute("IsStunned", false)
		EdgeReleaseEvent:FireServer()
	end
end)

local function updateEdges()
	edges = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "RightEdge" or d.Name == "LeftEdge") then
			table.insert(edges, d)
		end
	end
end

updateEdges()
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and (d.Name == "RightEdge" or d.Name == "LeftEdge") then
		table.insert(edges, d)
	end
end)

character:GetAttributeChangedSignal("IsStunned"):Connect(function()
	if not character:GetAttribute("IsStunned") then
		lastGrab = tick() -- Reset cooldown when releasing the ledge
	end
end)

RunService.Heartbeat:Connect(function()
	if humanoid.Health <= 0 then return end
	
	-- If we are stunned, we should be anchored (managed by server or this script)
	if character:GetAttribute("IsStunned") then 
		return 
	end
	
	-- If we are not stunned but the animation is still playing, stop it
	if activeTrack and activeTrack.IsPlaying then
		activeTrack:Stop(0)
		activeTrack = nil
	end
	
	-- If we were anchored by this script but are no longer stunned, unanchor
	if root.Anchored and tick() - lastGrab > 0.5 then
		root.Anchored = false
	end

	if tick() - lastGrab < GRAB_COOLDOWN then return end
	
	-- Only grab if falling or moving downwards
	if root.AssemblyLinearVelocity.Y > 0.1 then return end
	
	for _, edge in ipairs(edges) do
		if not edge or not edge.Parent then continue end
		
		-- Simple distance check
		local diff = root.Position - edge.Position
		local dist = diff.Magnitude
		
		if dist < 4 then
			-- Check if head is near the top of the edge
			local edgeTop = edge.Position.Y + (edge.Size.Y / 2)
			local headY = head.Position.Y
			
			-- If head is roughly at or slightly above the edge top
			if math.abs(headY - edgeTop) < 2 then
				lastGrab = tick()
				
				-- 1. Immediate Client-Side Anchor for smoothness
				root.Anchored = true
				
				-- Play animation immediately on client
				local animator = humanoid:FindFirstChildOfClass("Animator")
				if animator then
					local animToPlay = edgeAnimation
					if edge.Name == "RightEdge" then
						animToPlay = mirroredEdgeAnimation
					end
					
					activeTrack = animator:LoadAnimation(animToPlay)
					activeTrack.Priority = Enum.AnimationPriority.Action
					activeTrack:Play()
					
					-- Stop other tracks to prevent "floating" blend
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						if track ~= activeTrack then
							track:Stop(0.1)
						end
					end
				end
				
				-- 2. Position snapping (Client-side)
				local headHeightOffset = head.Position.Y - root.Position.Y
				local targetY = edgeTop - headHeightOffset + (head.Size.Y * 0.1)
				
				local targetX = edge.Position.X
				if edge.Name == "RightEdge" then
					targetX = targetX - 2.5
				elseif edge.Name == "LeftEdge" then
					targetX = targetX + 2.5
				end
				
				local rotation = root.CFrame.Rotation
				local lookVector = nil
				local lookDir = nil
				if edge.Name == "RightEdge" then
					lookVector = Vector3.new(1, 0, 0) -- Face Left (screen)
					lookDir = -1
				elseif edge.Name == "LeftEdge" then
					lookVector = Vector3.new(-1, 0, 0) -- Face Right (screen)
					lookDir = 1
				end
				
				if lookVector then
					rotation = CFrame.lookAt(Vector3.zero, lookVector)
					local lockOri = root:FindFirstChild("LockOrientation")
					if lockOri then
						lockOri.CFrame = rotation
					end
					if lookDir then
						character:SetAttribute("LookDir", lookDir)
					end
				end
				
				root.CFrame = CFrame.new(targetX, targetY, root.Position.Z) * rotation
				
				-- 3. Notify Server
				EdgeGrabEvent:FireServer(edge)
				break
			end
		end
	end
end)
