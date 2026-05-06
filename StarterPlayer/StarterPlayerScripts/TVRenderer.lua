-- @ScriptType: LocalScript
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("TVRenderer: Script starting...")

local function findViewport()
	print("TVRenderer: Searching for ViewportFrame...")
	-- Try FocusPanel
	local cameraModel = nil
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "Camera" and child:IsA("Model") then
			cameraModel = child
			break
		end
	end
	
	if cameraModel then
		local focusPanel = cameraModel:FindFirstChild("FocusPanel")
		if focusPanel then
			local panel = focusPanel:FindFirstChild("Panel")
			local gui = panel and panel:FindFirstChild("SurfaceGui")
			local viewport = gui and gui:FindFirstChild("ViewportFrame")
			if viewport then 
				print("TVRenderer: Found ViewportFrame on FocusPanel")
				return viewport, gui, focusPanel
			end
		end
	end
	
	-- Try MiniTV
	local tvModel = Workspace:FindFirstChild("MiniTV")
	if tvModel then
		local screen = tvModel:FindFirstChild("Screen")
		local gui = screen and screen:FindFirstChild("TVScreenGui")
		local viewport = gui and gui:FindFirstChild("ViewportFrame")
		if viewport then 
			print("TVRenderer: Found ViewportFrame on MiniTV")
			return viewport, gui, nil
		end
	end
	
	return nil, nil, nil
end

local viewport, gui, focusPanel = findViewport()
if not viewport then 
	warn("TVRenderer: No ViewportFrame found on FocusPanel or MiniTV")
	return 
end

-- Ensure Camera exists
local vCamera = viewport.CurrentCamera
if not vCamera or vCamera.Parent ~= viewport then
	vCamera = Instance.new("Camera")
	vCamera.FieldOfView = 70
	vCamera.Parent = viewport
	viewport.CurrentCamera = vCamera
end

-- Ensure WorldModel exists
local worldModel = viewport:FindFirstChildOfClass("WorldModel")
if not worldModel then
	worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	
	-- Add a basic floor to the WorldModel
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(500, 1, 500)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(30, 30, 40)
	floor.Material = Enum.Material.Concrete
	floor.Parent = worldModel
end

local noSignal = gui:FindFirstChild("NoSignal") or Instance.new("TextLabel")
noSignal.Name = "NoSignal"
noSignal.Size = UDim2.new(1, 0, 1, 0)
noSignal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
noSignal.BackgroundTransparency = 0
noSignal.TextColor3 = Color3.fromRGB(255, 255, 255)
noSignal.Text = "LIVE STADIUM FEED"
noSignal.Font = Enum.Font.GothamBold
noSignal.TextSize = 50
noSignal.ZIndex = 10
noSignal.Parent = gui

local clones = {}

local function syncCharacter(char, clone)
	if not char or not clone then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local clonePart = clone:FindFirstChild(part.Name, true)
			if clonePart and clonePart:IsA("BasePart") then
				clonePart.CFrame = part.CFrame
			end
		end
	end
end

local function updateViewport()
	local currentChars = {}
	local positions = {}
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			currentChars[player.Character] = true
			table.insert(positions, player.Character.HumanoidRootPart.Position)
		end
	end
	
	-- Default view if no players
	local targetCentroid = Vector3.new(68, 220, -66) -- Stadium center
	local targetMaxDist = 100
	
	local focusedPlayerName = ""
	if focusPanel then
		local panel = focusPanel:FindFirstChild("Panel")
		local nicknameValue = panel and panel:FindFirstChild("FocusPlayerNickname")
		if nicknameValue then
			focusedPlayerName = nicknameValue.Value
		end
	end
	
	local focusedPlayer = nil
	if focusedPlayerName ~= "" then
		focusedPlayer = Players:FindFirstChild(focusedPlayerName)
	end
	
	if focusedPlayer and focusedPlayer.Character and focusedPlayer.Character:FindFirstChild("HumanoidRootPart") then
		noSignal.Visible = false
		viewport.Visible = true
		
		targetCentroid = focusedPlayer.Character.HumanoidRootPart.Position
		targetMaxDist = 5
		
		local floor = worldModel:FindFirstChild("Floor")
		if floor then floor.Position = Vector3.new(targetCentroid.X, -1, targetCentroid.Z) end
	elseif #positions > 0 then
		noSignal.Visible = false
		viewport.Visible = true
		
		local centroid = Vector3.new(0, 0, 0)
		for _, pos in ipairs(positions) do centroid = centroid + pos end
		targetCentroid = centroid / #positions
		
		local floor = worldModel:FindFirstChild("Floor")
		if floor then floor.Position = Vector3.new(targetCentroid.X, -1, targetCentroid.Z) end
		
		local maxDist = 10
		for _, pos in ipairs(positions) do
			local d = (pos - targetCentroid).Magnitude
			if d > maxDist then maxDist = d end
		end
		targetMaxDist = maxDist
	else
		noSignal.Visible = true
		viewport.Visible = true -- Keep it visible to show the arena
	end

	-- Update Camera
	local time = tick()
	local orbitRadius, camHeight
	
	if focusedPlayer then
		orbitRadius = 15
		camHeight = 5
	else
		orbitRadius = targetMaxDist + 60
		camHeight = targetMaxDist * 0.5 + 30
	end
	
	local camPos = targetCentroid + Vector3.new(
		math.sin(time * 0.1) * orbitRadius,
		camHeight,
		math.cos(time * 0.1) * orbitRadius
	)
	vCamera.CFrame = CFrame.lookAt(camPos, targetCentroid)

	-- Sync Clones
	for char, clone in pairs(clones) do
		if not currentChars[char] or not char.Parent then
			clone:Destroy()
			clones[char] = nil
		end
	end

	for char in pairs(currentChars) do
		local clone = clones[char]
		if not clone then
			char.Archivable = true
			clone = char:Clone()
			char.Archivable = false
			if clone then
				for _, item in ipairs(clone:GetDescendants()) do
					if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("TouchTransmitter") then
						item:Destroy()
					elseif item:IsA("BasePart") then
						item.Anchored = true
						item.CanCollide = false
					end
				end
				clone.Parent = worldModel
				clones[char] = clone
			end
		end
		syncCharacter(char, clone)
	end
end

RunService.RenderStepped:Connect(updateViewport)
print("TVRenderer: Active")
