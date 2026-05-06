-- @ScriptType: LocalScript
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- THE NEW STUDIO GUARD
-- LocalScripts only run during Play Mode, so we just check if the game is running.
if not RunService:IsRunning() then
	return
end

local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- If for some reason we aren't a player yet, stop here.
if not localPlayer then return end

-- SETTINGS
local PADDING = 15
local MIN_ZOOM = 45
local MAX_ZOOM = 85
local SMOOTH_SPEED = 0.1 

-- Camera Regions
local cameraRegions = {}

local function updateCameraRegions()
	cameraRegions = {}
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "CameraRegion" then
			table.insert(cameraRegions, descendant)
		end
	end
end

updateCameraRegions()
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("BasePart") and desc.Name == "CameraRegion" then
		updateCameraRegions()
	end
end)
workspace.DescendantRemoving:Connect(function(desc)
	if desc:IsA("BasePart") and desc.Name == "CameraRegion" then
		updateCameraRegions()
	end
end)

-- Variable to store the Z-axis anchor
local spawnZ = 0 
local mapName = ""
local firstUpdate = true
local forceSnap = false

-- Update settings from character attributes
local function updateSettings(char)
	char = char or localPlayer.Character
	if not char then return end
	
	spawnZ = char:GetAttribute("SpawnZ") or spawnZ
	mapName = char:GetAttribute("MapName") or mapName
	MIN_ZOOM = char:GetAttribute("MinZoom") or 45
	MAX_ZOOM = char:GetAttribute("MaxZoom") or 85
end

localPlayer.CharacterAdded:Connect(function(char)
	char:GetAttributeChangedSignal("SpawnZ"):Connect(function() updateSettings(char) end)
	char:GetAttributeChangedSignal("MapName"):Connect(function() updateSettings(char) end)
	char:GetAttributeChangedSignal("MinZoom"):Connect(function() updateSettings(char) end)
	char:GetAttributeChangedSignal("MaxZoom"):Connect(function() updateSettings(char) end)
	updateSettings(char)
	forceSnap = true
end)

if localPlayer.Character then
	local char = localPlayer.Character
	char:GetAttributeChangedSignal("SpawnZ"):Connect(function() updateSettings(char) end)
	char:GetAttributeChangedSignal("MapName"):Connect(function() updateSettings(char) end)
	char:GetAttributeChangedSignal("MinZoom"):Connect(function() updateSettings(char) end)
	char:GetAttributeChangedSignal("MaxZoom"):Connect(function() updateSettings(char) end)
	updateSettings(char)
end

local function lockCamera()
	camera.CameraType = Enum.CameraType.Scriptable
end

-- Initialize lock
lockCamera()

local function getPlayerLocations()
	local locations = {}
	
	for _, p in pairs(Players:GetPlayers()) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hum = char:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				local theirSpawnZ = char:GetAttribute("SpawnZ")
				-- Only include if they are in the same area (same SpawnZ attribute)
				if theirSpawnZ == spawnZ then
					table.insert(locations, char.HumanoidRootPart.Position)
				end
			end
		end
	end
	return locations
end

RunService.RenderStepped:Connect(function()
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Ensure we have the latest settings
	local lastSpawnZ = spawnZ
	updateSettings()
	
	if localPlayer:GetAttribute("ScreenKOPlaying") then
		return
	end
	
	local char = localPlayer.Character
	local isSpawned = char and char:GetAttribute("Spawned")
	local positions = getPlayerLocations()
	if #positions == 0 then return end

	local shouldSnap = math.abs(spawnZ - lastSpawnZ) > 5 or forceSnap or isSpawned
	forceSnap = false

	-- A. Find Bounds
	local minX, maxX = positions[1].X, positions[1].X
	local minY, maxY = positions[1].Y, positions[1].Y

	for i = 2, #positions do
		local p = positions[i]
		minX = math.min(minX, p.X)
		maxX = math.max(maxX, p.X)
		minY = math.min(minY, p.Y)
		maxY = math.max(maxY, p.Y)
	end

	local centerX = (minX + maxX) / 2
	local centerY = (minY + maxY) / 2
	
	-- C. Calculate Zoom
	local distH = (maxX - minX) + PADDING
	local distV = (maxY - minY) + PADDING
	local cameraDist = math.max(distH, distV) * 1.1
	cameraDist = math.clamp(cameraDist, MIN_ZOOM, MAX_ZOOM)

	-- D. Clamp within CameraRegion
	local currentRegion = nil
	
	-- Try to find region by MapName first
	if mapName ~= "" then
		local mapFolder = workspace:FindFirstChild(mapName)
		if mapFolder then
			for _, region in ipairs(cameraRegions) do
				if region:IsDescendantOf(mapFolder) then
					currentRegion = region
					break
				end
			end
		end
	end
	
	-- Fallback to Z-distance if no map-specific region found
	if not currentRegion then
		local minDiff = math.huge
		for _, region in ipairs(cameraRegions) do
			local diff = math.abs(region.Position.Z - spawnZ)
			if diff < minDiff then
				minDiff = diff
				currentRegion = region
			end
		end
	end

	if currentRegion then
		local rPos = currentRegion.Position
		local rSize = currentRegion.Size
		
		local minRegionX = rPos.X - rSize.X / 2
		local maxRegionX = rPos.X + rSize.X / 2
		local minRegionY = rPos.Y - rSize.Y / 2
		local maxRegionY = rPos.Y + rSize.Y / 2
		
		centerX = math.clamp(centerX, minRegionX, maxRegionX)
		centerY = math.clamp(centerY, minRegionY, maxRegionY)
	end

	-- E. POSITION THE CAMERA ON THE OTHER SIDE
	-- We use spawnZ - cameraDist to be on the "back" side
	-- We use CFrame.lookAt to point it exactly at the center of the stage
	local distOffset = 0
	
	if mapName == "Stadium" then
		distOffset = 15
	end
	
	local cameraPos = Vector3.new(centerX, centerY, spawnZ - (cameraDist + distOffset))
	local lookAtPos = Vector3.new(centerX, centerY, spawnZ)

	local targetCFrame = CFrame.lookAt(cameraPos, lookAtPos)

	if firstUpdate or shouldSnap then
		camera.CFrame = targetCFrame
		firstUpdate = false
	else
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, SMOOTH_SPEED)
	end
end)