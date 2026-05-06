-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local event = ReplicatedStorage:WaitForChild("KnockbackEvent")
local player = game.Players.LocalPlayer

event.OnClientEvent:Connect(function(forceVector, attackerPos)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")

	if root and hum then
		-- IMPORTANT: Change state so the player "unclings" from the floor
		hum:ChangeState(Enum.HumanoidStateType.Freefall)

		-- Apply the force locally
		root.AssemblyLinearVelocity = forceVector
	end
end)