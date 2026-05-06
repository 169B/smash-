-- @ScriptType: LocalScript
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ARROW_ID = "rbxassetid://11135400344" -- Solid filled triangle
local ARROW_SIZE = UDim2.new(0, 90, 0, 90)
local EDGE_OFFSET = 10

local indicators = {}
local lastMap = ""
local activationTime = 0

local function updateIndicators()
	local char = localPlayer.Character
	local myMap = char and char:GetAttribute("MapName") or ""
	
	-- Handle map change and delay
	if myMap ~= lastMap then
		if myMap ~= "" then
			activationTime = os.clock() + 0.5
		else
			activationTime = 0
		end
		lastMap = myMap
	end
	
	if myMap == "" or os.clock() < activationTime then
		for _, img in pairs(indicators) do
			img.Visible = false
		end
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local pChar = player.Character
		local hrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
		local humanoid = pChar and pChar:FindFirstChildOfClass("Humanoid")
		local isAlive = humanoid and humanoid.Health > 0
		local theirMap = pChar and pChar:GetAttribute("MapName")
		
		if hrp and isAlive and theirMap == myMap then
			local pos = hrp.Position
			local screenPos, onScreen = camera:WorldToViewportPoint(pos)
			
			-- Show indicator if off-screen and on the sides
			if not onScreen or screenPos.Z < 0 then
				local img = indicators[player.UserId]
				if not img then
					img = Instance.new("TextLabel")
					img.Name = player.Name .. "_Indicator"
					img.BackgroundTransparency = 1
					img.Text = "▲"
					img.TextColor3 = Color3.fromRGB(255, 255, 0)
					img.TextSize = 90
					img.Font = Enum.Font.GothamBold
					img.Size = ARROW_SIZE
					img.AnchorPoint = Vector2.new(0.5, 0.5)
					img.ZIndex = 10
					img.Parent = script.Parent
					
					local headshot = Instance.new("ImageLabel")
					headshot.Name = "Headshot"
					headshot.BackgroundColor3 = Color3.new(0, 0, 0)
					headshot.BackgroundTransparency = 0.5
					headshot.Size = UDim2.new(0, 51, 0, 51)
					headshot.Position = UDim2.new(0.5, 0, 0.8, 0)
					headshot.AnchorPoint = Vector2.new(0.5, 0)
					headshot.ZIndex = 11
					headshot.Parent = img
					
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(1, 0)
					corner.Parent = headshot
					
					local stroke = Instance.new("UIStroke")
					stroke.Color = Color3.new(1, 1, 1)
					stroke.Thickness = 2
					stroke.Parent = headshot
					
					-- Get headshot image
					task.spawn(function()
						local thumbType = Enum.ThumbnailType.HeadShot
						local thumbSize = Enum.ThumbnailSize.Size100x100
						local content, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
						if headshot:IsDescendantOf(game) then
							headshot.Image = content
						end
					end)
					
					indicators[player.UserId] = img
				end
				
				local viewportSize = camera.ViewportSize
				local center = viewportSize / 2
				
				-- Calculate direction from center to player screen pos
				local dir = (Vector2.new(screenPos.X, screenPos.Y) - center)
				if screenPos.Z < 0 then
					dir = -dir
				end
				
				if dir.Magnitude < 0.001 then
					dir = Vector2.new(0, -1) -- Default up
				end
				
				dir = dir.Unit
				
				-- Calculate scale based on distance
				local distance = (camera.CFrame.Position - pos).Magnitude
				local scale = math.clamp(1 - ((distance - 20) / 180), 0.4, 1)
				
				-- Dynamic edge offset: half the current size + padding
				local currentHalfSize = (90 * scale) / 2
				local dynamicOffset = currentHalfSize - 15 -- Negative padding to push it closer to the edge due to font whitespace
				
				-- Project to screen edge
				local xLimit = center.X - dynamicOffset
				local yLimit = center.Y - dynamicOffset
				
				-- NEW LOGIC: Block if the direction is primarily pointing "Down" (positive Y)
				if dir.Y > 0 and math.abs(dir.Y) > math.abs(dir.X) then
					img.Visible = false
				else
					img.Visible = true
					img.TextColor3 = Color3.fromRGB(255, 255, 0)

					-- Project to Top, Left, or Right edges
					local ratioX = xLimit / math.abs(dir.X)
					local ratioY = yLimit / math.abs(dir.Y)
					local finalRatio = math.min(ratioX, ratioY)

					local targetPos = center + (dir * finalRatio)
					img.Position = UDim2.new(0, targetPos.X, 0, targetPos.Y)

					local rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
					img.Rotation = rotation

					img.TextSize = 90 * scale
					img.Size = UDim2.new(0, 90 * scale, 0, 90 * scale)

					local headshot = img:FindFirstChild("Headshot")
					if headshot then
						headshot.Rotation = -rotation
						headshot.Size = UDim2.new(0, 51 * scale, 0, 51 * scale)
					end
				end
			else
				if indicators[player.UserId] then
					indicators[player.UserId].Visible = false
				end
			end
		else
			if indicators[player.UserId] then
				indicators[player.UserId].Visible = false
			end
		end
	end
	
	-- Clean up players who left
	for id, img in pairs(indicators) do
		local found = false
		for _, p in ipairs(Players:GetPlayers()) do
			if p.UserId == id then
				found = true
				break
			end
		end
		if not found then
			img:Destroy()
			indicators[id] = nil
		end
	end
end

RunService.RenderStepped:Connect(updateIndicators)
