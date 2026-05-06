-- @ScriptType: LocalScript
local character = script.Parent

local function disableSound(descendant)
	if descendant:IsA("Sound") and descendant.Name == "Died" then
		descendant.Volume = 0
	end
end

for _, desc in ipairs(character:GetDescendants()) do
	disableSound(desc)
end

character.DescendantAdded:Connect(disableSound)