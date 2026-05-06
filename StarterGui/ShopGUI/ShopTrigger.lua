-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local shopFrame = script.Parent:WaitForChild("MainFrame")
local pad = workspace:WaitForChild("ShopPad", 5)
if not pad then
	warn("ShopPad not found!")
	script:Destroy()
	return
end

local OPEN_DISTANCE = 10 -- How close to stand to open

game:GetService("RunService").Heartbeat:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local dist = (char.HumanoidRootPart.Position - pad.Position).Magnitude

		if dist < OPEN_DISTANCE then
			shopFrame.Visible = true
		else
			shopFrame.Visible = false
		end
	end
end)