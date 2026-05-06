-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CombatUI = script.Parent
local Container = CombatUI:WaitForChild("DamageContainer")
local Template = CombatUI:WaitForChild("PlayerTemplate")

local playerEntries = {}
local shakeConnections = {}
local lastPercents = {}
local targetPercents = {}
local displayedPercents = {}
local hitShakeTimes = {}

local function getSmashColor(percent)
	if percent < 30 then
		return Color3.fromRGB(255, 255, 255) -- White
	elseif percent < 75 then
		return Color3.fromRGB(255, 220, 0) -- Yellow
	elseif percent < 120 then
		return Color3.fromRGB(255, 100, 0) -- Orange
	else
		return Color3.fromRGB(200, 0, 0) -- Dark Red
	end
end

local function colorToHex(color)
	return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
end

local function updateLives(entry, lives)
	local container = entry:FindFirstChild("LivesContainer")
	if not container then return end
	
	for i = 1, 3 do
		local life = container:FindFirstChild("Life" .. i)
		if life then
			life.BackgroundTransparency = (i <= lives) and 0 or 0.8
			life.BackgroundColor3 = (i <= lives) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50)
		end
	end
end

local function updateEntry(player, entry, percent)
	local label = entry:FindFirstChild("Percentage")
	if not label then return end
	
	targetPercents[player] = percent
	
	if not lastPercents[player] then 
		lastPercents[player] = 200 
		displayedPercents[player] = percent
	end
	
	if percent > lastPercents[player] then
		hitShakeTimes[player] = tick()
	end
	lastPercents[player] = percent

	-- Shake and Smooth Number logic
	if shakeConnections[player] then return end -- Already running

	local origPos = UDim2.new(0, 0, 0.55, 0)
	
	shakeConnections[player] = RunService.RenderStepped:Connect(function(dt)
		local currentTarget = targetPercents[player] or 0
		local currentDisplayed = displayedPercents[player] or 0
		
		-- Smoothly increase number
		if math.abs(currentTarget - currentDisplayed) > 0.01 then
			displayedPercents[player] = currentDisplayed + (currentTarget - currentDisplayed) * math.clamp(dt * 15, 0, 1)
		else
			displayedPercents[player] = currentTarget
		end
		
		local displayVal = displayedPercents[player]
		local formattedNumber = string.format("%.1f", displayVal)
		local wholeNumber, decimalNumber = formattedNumber:match("(%d+)%.(%d+)")

		local currentColor = getSmashColor(displayVal)
		local hexColor = colorToHex(currentColor)

		label.Text = string.format(
			'<font color=\"%s\"><font size=\"55\">%s</font><font size=\"30\">.%s%%</font></font>', 
			hexColor, wholeNumber, decimalNumber
		)

		local timeSinceHit = tick() - (hitShakeTimes[player] or 0)
		local hitIntensity = 0
		
		-- Temporary violent shake when hit
		if timeSinceHit < 0.4 then
			hitIntensity = (0.4 - timeSinceHit) * 45 -- Increased intensity and duration for "jitter"
		end
		
		-- Permanent subtle shake at high damage
		local baseIntensity = 0
		if displayVal >= 100 then
			baseIntensity = math.clamp((displayVal - 100) / 40, 1, 8) 
		end
		
		local totalIntensity = hitIntensity + baseIntensity
		
		if totalIntensity > 0 then
			local offsetX = math.random(-totalIntensity, totalIntensity)
			local offsetY = math.random(-totalIntensity, totalIntensity)
			label.Position = origPos + UDim2.new(0, offsetX, 0, offsetY)
		else
			label.Position = origPos
		end
	end)
end

local function removePlayer(player)
	if playerEntries[player] then
		if shakeConnections[player] then
			shakeConnections[player]:Disconnect()
			shakeConnections[player] = nil
		end
		playerEntries[player]:Destroy()
		playerEntries[player] = nil
		lastPercents[player] = nil
		targetPercents[player] = nil
		displayedPercents[player] = nil
		hitShakeTimes[player] = nil
	end
end

local function addPlayer(player)
	removePlayer(player)
	
	local entry = Template:Clone()
	entry.Name = player.Name
	entry.Visible = false
	entry.Parent = Container
	playerEntries[player] = entry
	
	-- Set username
	if entry:FindFirstChild("Username") then
		entry.Username.Text = player.DisplayName
	end
	
	-- Set headshot
	task.spawn(function()
		local userId = player.UserId
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size100x100
		local success, content = pcall(function()
			return Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
		end)
		if success then
			entry.Headshot.Image = content
		end
	end)
	
	local function onCharacterAdded(character)
		local damageValue = character:WaitForChild("DamagePercent", 10)
		
		-- Update visibility based on map
		local function updateVisibility()
			local localPlayer = Players.LocalPlayer
			if not localPlayer or not localPlayer.Character then return end
			
			local localMap = localPlayer.Character:GetAttribute("MapName")
			local targetMap = character:GetAttribute("MapName")
			
			-- Only show if maps match and are not empty
			local isSameMap = (localMap == targetMap) and (localMap ~= "" and localMap ~= nil)
			entry.Visible = isSameMap
		end
		
		-- Listen for map changes on both players
		character:GetAttributeChangedSignal("MapName"):Connect(updateVisibility)
		local localPlayer = Players.LocalPlayer
		if localPlayer then
			localPlayer.CharacterAdded:Connect(function(newChar)
				newChar:GetAttributeChangedSignal("MapName"):Connect(updateVisibility)
				updateVisibility()
			end)
			if localPlayer.Character then
				localPlayer.Character:GetAttributeChangedSignal("MapName"):Connect(updateVisibility)
			end
		end
		
		updateVisibility()

		local livesValue = character:WaitForChild("Lives", 10)
		if livesValue then
			updateLives(entry, livesValue.Value)
			livesValue.Changed:Connect(function(val)
				updateLives(entry, val)
			end)
		end

		if damageValue then
			updateEntry(player, entry, damageValue.Value)
			damageValue.Changed:Connect(function(val)
				updateEntry(player, entry, val)
			end)
		else
			updateEntry(player, entry, 200)
		end
	end
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

for _, p in ipairs(Players:GetPlayers()) do
	addPlayer(p)
end