-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CameraShakeEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CameraShakeEvent")
local camera = workspace.CurrentCamera

local function shakeCamera(duration, intensity)
	local startTime = os.clock()
	local connection
	
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			connection:Disconnect()
			camera.CFrame = camera.CFrame * CFrame.new(0, 0, 0) -- Reset (not really needed but good practice)
			return
		end
		
		-- Fade out intensity over time
		local currentIntensity = intensity * (1 - (elapsed / duration))
		local shake = Vector3.new(
			(math.random() - 0.5) * currentIntensity,
			(math.random() - 0.5) * currentIntensity,
			(math.random() - 0.5) * currentIntensity
		)
		
		camera.CFrame = camera.CFrame * CFrame.new(shake)
	end)
end

CameraShakeEvent.OnClientEvent:Connect(shakeCamera)
