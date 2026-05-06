-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayKnockoutSound = Events:WaitForChild("PlayKnockoutSound")

PlayKnockoutSound.OnClientEvent:Connect(function()
	local originalSound = workspace:FindFirstChild("ExplosionAudio")
	if originalSound and originalSound:IsA("Sound") then
		local s = originalSound:Clone()
		s.Parent = SoundService
		s:Play()
		game:GetService("Debris"):AddItem(s, 5)
	else
		warn("ExplosionAudio not found in workspace!")
	end
end)