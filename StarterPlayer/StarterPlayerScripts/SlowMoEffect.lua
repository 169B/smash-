-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local slowMoEvent = ReplicatedStorage:WaitForChild("SlowMoZoomEvent")
local camera = workspace.CurrentCamera

local isSlowMo = false
local activeConnections = {}

local function setAnimSpeed(char, speed)
    if not char or not char:IsA("Model") then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            track:AdjustSpeed(speed)
        end
        
        if speed < 1 then
            if not activeConnections[char] then
                activeConnections[char] = animator.AnimationPlayed:Connect(function(track)
                    track:AdjustSpeed(speed)
                end)
            end
        else
            if activeConnections[char] then
                activeConnections[char]:Disconnect()
                activeConnections[char] = nil
            end
        end
    end
    
    -- Also slow down any animators in tools (sword animations)
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") or tool:IsA("Model") then
            local toolAnimator = tool:FindFirstChildWhichIsA("Animator", true)
            if toolAnimator then
                for _, track in ipairs(toolAnimator:GetPlayingAnimationTracks()) do
                    track:AdjustSpeed(speed)
                end
                if speed < 1 then
                    -- We don't track tool connections separately for simplicity, 
                    -- but the character loop should catch most things.
                end
            end
        end
    end
end

slowMoEvent.OnClientEvent:Connect(function(victim, attacker, abilityName)
    local camera = workspace.CurrentCamera
    if isSlowMo then return end
    isSlowMo = true
    
    local originalFOV = camera.FieldOfView
    
    camera.CameraType = Enum.CameraType.Scriptable
    
    local victimPos = victim and victim:FindFirstChild("HumanoidRootPart") and victim.HumanoidRootPart.Position
    if not victimPos then 
        victimPos = victim and victim:GetPivot().Position or Vector3.new(0,0,0)
    end
    
    local attackerPos
    if typeof(attacker) == "Instance" and attacker:IsA("Model") then
        attackerPos = attacker:FindFirstChild("HumanoidRootPart") and attacker.HumanoidRootPart.Position or attacker:GetPivot().Position
    elseif typeof(attacker) == "Vector3" then
        attackerPos = attacker
    else
        attackerPos = victimPos + Vector3.new(0, 0, 5)
    end
    
    local midPoint = (victimPos + attackerPos) / 2
    local dir = (camera.CFrame.Position - midPoint).Unit
    if dir.Magnitude == 0 or dir ~= dir then dir = Vector3.new(0, 0, 1) end
    local zoomPos = midPoint + dir * 15 -- Zoom in close
    
    -- Add a cool color correction effect
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Saturation = -0.8
    cc.Contrast = 0.4
    cc.Parent = camera
    
    TweenService:Create(camera, TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        CFrame = CFrame.lookAt(zoomPos, midPoint),
        FieldOfView = 30
    }):Play()
    
    -- Slow down character and sword animations
    local function enforceAll()
        setAnimSpeed(victim, 0.05)
        if typeof(attacker) == "Instance" and attacker:IsA("Model") then
            setAnimSpeed(attacker, 0.05)
        end
        -- Also slow down other players for a consistent global effect
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                setAnimSpeed(player.Character, 0.05)
            end
        end
    end
    
    enforceAll()
    
    -- Play a second hit animation in slow motion
    if typeof(attacker) == "Instance" and attacker:IsA("Model") then
        task.spawn(function()
            task.wait(0.2) -- Wait a bit into the slow mo
            local hum = attacker:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if animator then
                local anim = Instance.new("Animation")
                
                -- Use appropriate animation based on ability
                if abilityName == "Kick" then
                    anim.AnimationId = "rbxassetid://134352543257888"
                else
                    anim.AnimationId = "rbxassetid://567479941" -- Side Swipe
                end
                
                local track = animator:LoadAnimation(anim)
                track.Priority = Enum.AnimationPriority.Action
                track:Play()
                
                -- Adjust speed to fit the slow motion duration
                track:AdjustSpeed(0.25) 
                
                -- Play sound and effect if sword is present
                local sword = attacker:FindFirstChild("Sword") or attacker:FindFirstChild("VisualSword") or attacker:FindFirstChild("VisualSword_SlowMo")
                if sword then
                    local handle = sword:FindFirstChild("Handle")
                    if handle then
                        local sound = handle:FindFirstChild("SlashSound")
                        if sound then sound:Play() end
                        
                        local trail = handle:FindFirstChild("SwordTrail")
                        if trail then
                            trail.Enabled = true
                            task.delay(3.5, function() trail.Enabled = false end)
                        end
                    end
                end
            end
        end)
    end
    
    local enforcement = task.spawn(function()
        local start = tick()
        while tick() - start < 3 do
            enforceAll()
            task.wait(0.1)
        end
    end)
    
    -- Wait for the freeze/animation phase (2 seconds)
    task.wait(2)
    
    -- Start the fly away camera follow for the last second of slowdown
    local flyAwayDuration = 1.0
    local startTime = tick()
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > flyAwayDuration then
            if connection then connection:Disconnect() end
            return
        end
        
        local currentVictimPos = victim and victim:FindFirstChild("HumanoidRootPart") and victim.HumanoidRootPart.Position or victimPos
        local progress = elapsed / flyAwayDuration
        local easeOut = 1 - (1 - progress) * (1 - progress)
        local currentZoom = 15 + (easeOut * 65) 
        local camPos = currentVictimPos + dir * currentZoom
        camera.CFrame = CFrame.lookAt(camPos, currentVictimPos)
    end)
    
    -- Widen the FOV as they fly away
    TweenService:Create(camera, TweenInfo.new(flyAwayDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        FieldOfView = originalFOV + 40 
    }):Play()
    
    -- Wait for the last second of slowdown
    task.wait(1)
    
    -- End slowdown
    task.cancel(enforcement)
    if connection then connection:Disconnect() end
    
    -- Create a blast effect at the moment of release (speed up)
    local blast = Instance.new("Part")
    blast.Shape = Enum.PartType.Ball
    blast.Size = Vector3.new(2, 2, 2)
    blast.Material = Enum.Material.Neon
    blast.Color = Color3.new(1, 1, 1)
    blast.Transparency = 0.4
    blast.Anchored = true
    blast.CanCollide = false
    blast.CFrame = CFrame.new(victim and victim:GetPivot().Position or midPoint)
    blast.Parent = workspace
    
    TweenService:Create(blast, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(30, 30, 30),
        Transparency = 1
    }):Play()
    task.delay(0.4, function() blast:Destroy() end)

    -- Restore character animations
    setAnimSpeed(victim, 1)
    if typeof(attacker) == "Instance" and attacker:IsA("Model") then
        setAnimSpeed(attacker, 1)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            setAnimSpeed(player.Character, 1)
        end
    end
    
    cc:Destroy()
    
    -- Return to normal gameplay camera
    camera.CameraType = Enum.CameraType.Custom
    TweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        FieldOfView = originalFOV
    }):Play()
    
    task.wait(0.3)
    isSlowMo = false
end)