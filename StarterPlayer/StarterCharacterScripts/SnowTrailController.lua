-- @ScriptType: LocalScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Find the snow trail effect template
local effectsFolder = ReplicatedStorage:FindFirstChild("Effects")
if not effectsFolder then return end

local trailAttachmentTemplate = effectsFolder:FindFirstChild("SnowTrailAttachment")
if not trailAttachmentTemplate then return end

-- Clone the effect for this character
local trailAttachment = trailAttachmentTemplate:Clone()
trailAttachment.Parent = rootPart

local trailEmitter = trailAttachment:FindFirstChild("SnowCloudTrail")
if not trailEmitter then
    trailAttachment:Destroy()
    return
end

local function updateTrail()
    local moveDirection = rootPart.AssemblyLinearVelocity
    local isOnGround = humanoid:GetState() == Enum.HumanoidStateType.Running

    -- Check if the character is moving horizontally or is in the air
    if Vector2.new(moveDirection.X, moveDirection.Z).Magnitude > 1 or not isOnGround then
        trailEmitter.Enabled = true
    else
        trailEmitter.Enabled = false
    end
end

-- Run the update function every frame
game:GetService("RunService").RenderStepped:Connect(updateTrail)
