-- @ScriptType: LocalScript
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local fireEvent = ReplicatedStorage:WaitForChild("FireRocketEvent")
local player = Players.LocalPlayer

local COOLDOWN = 1.5
local lastFire = 0

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == nil then -- Unbound from E to avoid conflict with Sword
		if tick() - lastFire < COOLDOWN then return end
		
		local character = player.Character
		if not character then return end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			lastFire = tick()
			fireEvent:FireServer()
		end
	end
end)
