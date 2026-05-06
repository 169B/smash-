-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

-- Reference the existing Animation object directly
local anim = character:WaitForChild("SwordAnim") -- or wherever SwordAnim is located
local track = animator:LoadAnimation(anim)

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then -- change to your keybind
		if not track.IsPlaying then
			track:Play()
		end
	end
end)