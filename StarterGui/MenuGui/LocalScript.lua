-- @ScriptType: LocalScript
-- ============================================================
--  BATTLEZONE X — Main Menu LocalScript  (Smash Bros Style)
--  Place inside: StarterGui > MainMenuGui > LocalScript
-- ============================================================

local TweenService  = game:GetService("TweenService")
local Players       = game:GetService("Players")
local Lighting      = game:GetService("Lighting")
local RunService    = game:GetService("RunService")

local player     = Players.LocalPlayer
local screenGui  = script.Parent
local camera     = workspace.CurrentCamera

local MainFrame, MapFrame, RosterFrame, BG, Arrow, TitleLabel, underline

screenGui.IgnoreGuiInset = true

-- ============================================================
--  GAMEPLAY GUI TOGGLE
-- ============================================================
local function setGameplayGuiVisible(visible)
	local pg = screenGui.Parent
	if not pg then return end
	for _, name in ipairs({"CombatUI", "AbilityGui", "ControlGui"}) do
		local g = pg:FindFirstChild(name)
		if g then g.Enabled = visible end
	end
end
setGameplayGuiVisible(false)

-- ============================================================
--  FREEZE & CINEMATIC CAMERA
-- ============================================================
local function freezePlayer(force)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	if not force then
		local loadingSpawn = workspace:FindFirstChild("LoadingSpawn")
		if player.RespawnLocation ~= nil and player.RespawnLocation ~= loadingSpawn then return end
	end
	hrp.Anchored = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(250, 60, -40), Vector3.new(225, 40, -68))
	if BG        then BG.Visible        = true  end
	if MainFrame then
		MainFrame.Visible   = true
		MainFrame.Position  = UDim2.new(0,0,0,0)
	end
	if MapFrame    then MapFrame.Visible    = false end
	if RosterFrame then RosterFrame.Visible = false end
	if Arrow       then Arrow.Visible       = true  end
	if TitleLabel  then TitleLabel.Visible  = true  end
	if underline   then underline.Visible   = true  end
	setGameplayGuiVisible(false)
end

-- ============================================================
--  COLORS  (Smash-palette: dark navy, vivid red, bright gold)
-- ============================================================
local C = {
	-- Core
	NavyDeep  = Color3.fromRGB(8,   10,  26),
	Navy      = Color3.fromRGB(12,  16,  42),
	NavyMid   = Color3.fromRGB(18,  24,  60),
	-- Accents
	Red       = Color3.fromRGB(220, 30,  30),
	RedDark   = Color3.fromRGB(130, 10,  10),
	Gold      = Color3.fromRGB(255, 210, 40),
	GoldDark  = Color3.fromRGB(180, 130, 10),
	Silver    = Color3.fromRGB(200, 210, 230),
	-- Fighters
	Green     = Color3.fromRGB(30,  170, 70),
	GreenDk   = Color3.fromRGB(10,  80,  28),
	Blue      = Color3.fromRGB(25,  100, 210),
	BlueDark  = Color3.fromRGB(10,  45,  120),
	Orange    = Color3.fromRGB(220, 120, 20),
	OrangeDk  = Color3.fromRGB(120, 60,  5),
	Purple    = Color3.fromRGB(110, 40,  180),
	PurpleDk  = Color3.fromRGB(55,  15,  100),
	-- Neutral
	Dark      = Color3.fromRGB(10,  10,  18),
	Panel     = Color3.fromRGB(16,  16,  28),
	White     = Color3.new(1,1,1),
	Black     = Color3.new(0,0,0),
}

-- ============================================================
--  TWEEN PRESETS
-- ============================================================
local fast = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local med  = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local slow = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ============================================================
--  HELPERS
-- ============================================================
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = color or C.Black
	s.Thickness = thickness or 2
	s.Parent    = parent
	return s
end

local function gradient(parent, c0, c1, rotation)
	local g = Instance.new("UIGradient")
	g.Color    = ColorSequence.new(c0, c1)
	g.Rotation = rotation or 135
	g.Parent   = parent
	return g
end

-- ============================================================
--  BURST PARTICLES
-- ============================================================
local function burst(parent, absPos, color)
	local relX = absPos.X / screenGui.AbsoluteSize.X
	local relY = absPos.Y / screenGui.AbsoluteSize.Y
	for i = 1, 16 do
		local p  = Instance.new("Frame")
		local sz = math.random(4, 10)
		p.Size                   = UDim2.new(0, sz, 0, sz)
		p.Position               = UDim2.new(relX, -sz/2, relY, -sz/2)
		p.BackgroundColor3       = (i % 3 == 0) and C.Gold or color
		p.BackgroundTransparency = 0
		p.BorderSizePixel        = 0
		p.ZIndex                 = 30
		corner(p, 2)
		p.Parent = screenGui
		local angle = math.rad((i/16)*360 + math.random(-20,20))
		local dist  = math.random(55, 120)
		local tx    = relX + (math.cos(angle)*dist) / screenGui.AbsoluteSize.X
		local ty    = relY + (math.sin(angle)*dist) / screenGui.AbsoluteSize.Y
		local tw = TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(tx, -sz/2, ty, -sz/2),
			BackgroundTransparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function() p:Destroy() end)
	end
end

-- ============================================================
--  BACKGROUND
-- ============================================================
local menuBlur = Instance.new("BlurEffect")
menuBlur.Name   = "MenuBlur"
menuBlur.Size   = 24
menuBlur.Parent = Lighting

-- Deep navy base
BG = Instance.new("Frame")
BG.Name                   = "BG"
BG.Size                   = UDim2.new(1,0,1,0)
BG.BackgroundColor3       = C.NavyDeep
BG.BackgroundTransparency = 0
BG.BorderSizePixel        = 0
BG.ZIndex                 = 0
BG.Parent                 = screenGui

-- Radial centre-glow (Smash has a bright spotlight feel)
local centreGlow = Instance.new("ImageLabel")
centreGlow.Size                 = UDim2.new(1.4, 0, 1.4, 0)
centreGlow.Position             = UDim2.new(-0.2, 0, -0.2, 0)
centreGlow.BackgroundTransparency = 1
centreGlow.Image                = "rbxassetid://5992240640"
centreGlow.ImageColor3          = Color3.fromRGB(30, 50, 160)
centreGlow.ImageTransparency    = 0.55
centreGlow.ZIndex               = 1
centreGlow.Parent               = BG

-- Diagonal speed-lines (Smash signature)
for i = 1, 12 do
	local line = Instance.new("Frame")
	line.Size                   = UDim2.new(1.5, 0, 0, math.random(1,3))
	line.Position               = UDim2.new(-0.25, 0, i/13, 0)
	line.Rotation               = -8
	line.BackgroundColor3       = C.White
	line.BackgroundTransparency = 0.88 + (i % 3)*0.03
	line.BorderSizePixel        = 0
	line.ZIndex                 = 1
	line.Parent                 = BG
end

-- Bottom red bar (Smash lower-third accent)
local redBar = Instance.new("Frame")
redBar.Size             = UDim2.new(1,0,0,6)
redBar.Position         = UDim2.new(0,0,0.95,0)
redBar.BackgroundColor3 = C.Red
redBar.BorderSizePixel  = 0
redBar.ZIndex           = 2
redBar.Parent           = BG
gradient(redBar, C.Red, C.Gold, 0)

-- Top thin gold line
local topBar = Instance.new("Frame")
topBar.Size             = UDim2.new(1,0,0,3)
topBar.Position         = UDim2.new(0,0,0,0)
topBar.BackgroundColor3 = C.Gold
topBar.BorderSizePixel  = 0
topBar.ZIndex           = 2
topBar.Parent           = BG
gradient(topBar, C.Gold, C.Red, 0)

-- ============================================================
--  TITLE LOGO  ("BATTLEZONE X" — impact-stacked Smash style)
-- ============================================================
TitleLabel = Instance.new("TextLabel")
TitleLabel.Name                   = "Title"
TitleLabel.Size                   = UDim2.new(0.65, 0, 0.17, 0)
TitleLabel.Position               = UDim2.new(0.02, 0, 0.01, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text                   = "BATTLEZONE X"
TitleLabel.Font                   = Enum.Font.LuckiestGuy
TitleLabel.TextSize               = 58
TitleLabel.TextColor3             = C.White
TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
TitleLabel.ZIndex                 = 10
TitleLabel.Parent                 = screenGui

-- Layered strokes for thick Smash-logo feel
stroke(TitleLabel, C.Black, 6)
local titleGlow = stroke(TitleLabel, C.Gold, 1)   -- thin gold rim

-- Animated underline that grows in
underline = Instance.new("Frame")
underline.Name             = "Underline"
underline.Size             = UDim2.new(0,0,0,5)
underline.Position         = UDim2.new(0.02,0,0.175,0)
underline.BackgroundColor3 = C.Gold
underline.BorderSizePixel  = 0
underline.ZIndex           = 10
underline.Parent           = screenGui
corner(underline, 3)
gradient(underline, C.Gold, C.Red, 0)
TweenService:Create(underline, TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	{Size = UDim2.new(0.55, 0, 0, 5)}):Play()

-- ============================================================
--  SELECTOR ARROW
-- ============================================================
Arrow = Instance.new("TextLabel")
Arrow.Name                   = "Arrow"
Arrow.Size                   = UDim2.new(0,40,0,40)
Arrow.BackgroundTransparency = 1
Arrow.Text                   = "▶"
Arrow.Font                   = Enum.Font.GothamBold
Arrow.TextSize               = 30
Arrow.TextColor3             = C.Gold
Arrow.ZIndex                 = 20
Arrow.Visible                = false
Arrow.Parent                 = screenGui
stroke(Arrow, C.Black, 2)

local arrowPulse = true
task.spawn(function()
	while arrowPulse do
		TweenService:Create(Arrow, TweenInfo.new(0.30), {TextTransparency=0}):Play()
		task.wait(0.30)
		TweenService:Create(Arrow, TweenInfo.new(0.30), {TextTransparency=0.4}):Play()
		task.wait(0.30)
	end
end)

-- ============================================================
--  SLIDE TRANSITIONS
-- ============================================================
local transitioning = false

local function slideToMap()
	if transitioning then return end
	transitioning   = true
	MapFrame.Visible   = true
	MapFrame.Position  = UDim2.new(1,0,0,0)
	TweenService:Create(MainFrame, med, {Position=UDim2.new(-1,0,0,0)}):Play()
	local t = TweenService:Create(MapFrame, med, {Position=UDim2.new(0,0,0,0)})
	t:Play()
	t.Completed:Connect(function() MainFrame.Visible=false; transitioning=false end)
end

local function slideToMain()
	if transitioning then return end
	transitioning   = true
	MainFrame.Visible  = true
	MainFrame.Position = UDim2.new(-1,0,0,0)
	TweenService:Create(MapFrame,  med, {Position=UDim2.new(1,0,0,0)}):Play()
	if RosterFrame then TweenService:Create(RosterFrame, med, {Position=UDim2.new(1,0,0,0)}):Play() end
	local t = TweenService:Create(MainFrame, med, {Position=UDim2.new(0,0,0,0)})
	t:Play()
	t.Completed:Connect(function()
		MapFrame.Visible = false
		if RosterFrame then RosterFrame.Visible=false end
		transitioning = false
	end)
end

local function slideToRoster()
	if transitioning then return end
	transitioning      = true
	RosterFrame.Visible   = true
	RosterFrame.Position  = UDim2.new(1,0,0,0)
	TweenService:Create(MainFrame, med, {Position=UDim2.new(-1,0,0,0)}):Play()
	local t = TweenService:Create(RosterFrame, med, {Position=UDim2.new(0,0,0,0)})
	t:Play()
	t.Completed:Connect(function() MainFrame.Visible=false; transitioning=false end)
end

-- ============================================================
--  MAIN FRAME
-- ============================================================
MainFrame = Instance.new("Frame")
MainFrame.Name                   = "MainFrame"
MainFrame.Size                   = UDim2.new(1,0,1,0)
MainFrame.BackgroundTransparency = 1
MainFrame.ZIndex                 = 5
MainFrame.Parent                 = screenGui

-- ============================================================
--  BUTTON FACTORY  (Smash-style: bold, skewed, layered)
-- ============================================================
local function createButton(cfg)
	-- Outer wrapper for skew effect
	local wrap = Instance.new("Frame")
	wrap.Name                   = cfg.name .. "_Wrap"
	wrap.Size                   = cfg.size
	wrap.Position               = cfg.pos
	wrap.BackgroundTransparency = 1
	wrap.ZIndex                 = 7
	wrap.Parent                 = cfg.parent or MainFrame

	local btn = Instance.new("TextButton")
	btn.Name             = cfg.name
	btn.Size             = UDim2.new(1,0,1,0)
	btn.Position         = UDim2.new(0,0,0,0)
	btn.Rotation         = cfg.rot or -1   -- slight Smash tilt
	btn.BackgroundColor3 = cfg.color
	btn.Text             = ""
	btn.BorderSizePixel  = 0
	btn.ClipsDescendants = true
	btn.ZIndex           = 8
	btn.Parent           = wrap
	corner(btn, 6)
	gradient(btn, cfg.color, cfg.colorDark, 150)

	-- Bright top-edge highlight (gives 3-D raised look)
	local topEdge = Instance.new("Frame")
	topEdge.Size               = UDim2.new(1,0,0,3)
	topEdge.Position           = UDim2.new(0,0,0,0)
	topEdge.BackgroundColor3   = C.White
	topEdge.BackgroundTransparency = 0.60
	topEdge.BorderSizePixel    = 0
	topEdge.ZIndex             = 9
	topEdge.Parent             = btn

	-- Bottom shadow edge
	local botEdge = Instance.new("Frame")
	botEdge.Size               = UDim2.new(1,0,0,4)
	botEdge.Position           = UDim2.new(0,0,1,-4)
	botEdge.BackgroundColor3   = C.Black
	botEdge.BackgroundTransparency = 0.50
	botEdge.BorderSizePixel    = 0
	botEdge.ZIndex             = 9
	botEdge.Parent             = btn

	-- Diagonal gloss slash
	local slash = Instance.new("Frame")
	slash.Size               = UDim2.new(0,50,2,0)
	slash.Position           = UDim2.new(0.75,0,-0.5,0)
	slash.BackgroundColor3   = C.White
	slash.BackgroundTransparency = 0.82
	slash.Rotation           = 18
	slash.BorderSizePixel    = 0
	slash.ZIndex             = 9
	slash.Parent             = btn

	-- Border stroke (grey default → gold on hover)
	local bStroke = Instance.new("UIStroke")
	bStroke.Color          = Color3.fromRGB(60,60,80)
	bStroke.Thickness      = 2
	bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bStroke.Parent         = btn

	-- Icon (large, left-anchored)
	if cfg.icon then
		local icon = Instance.new("TextLabel")
		icon.Size               = UDim2.new(0,56,1,0)
		icon.Position           = UDim2.new(0,8,0,0)
		icon.BackgroundTransparency = 1
		icon.Text               = cfg.icon
		icon.Font               = Enum.Font.LuckiestGuy
		icon.TextSize           = cfg.iconSize or 36
		icon.TextColor3         = C.White
		icon.TextXAlignment     = Enum.TextXAlignment.Center
		icon.ZIndex             = 10
		icon.Parent             = btn
		stroke(icon, C.Black, 2)
	end

	-- Primary label
	local lbl = Instance.new("TextLabel")
	lbl.Name               = "Label"
	lbl.Size               = UDim2.new(1,-72,0.52,0)
	lbl.Position           = UDim2.new(0,70,0.04,0)
	lbl.BackgroundTransparency = 1
	lbl.Text               = cfg.label
	lbl.Font               = Enum.Font.LuckiestGuy
	lbl.TextSize           = cfg.textSize or 28
	lbl.TextColor3         = C.White
	lbl.TextXAlignment     = Enum.TextXAlignment.Left
	lbl.ZIndex             = 10
	lbl.Parent             = btn
	stroke(lbl, C.Black, 2)

	-- Sub-label
	if cfg.sub then
		local sub = Instance.new("TextLabel")
		sub.Name               = "Sub"
		sub.Size               = UDim2.new(1,-72,0.36,0)
		sub.Position           = UDim2.new(0,70,0.60,0)
		sub.BackgroundTransparency = 1
		sub.Text               = cfg.sub
		sub.Font               = Enum.Font.GothamMedium
		sub.TextSize           = cfg.subSize or 12
		sub.TextColor3         = Color3.fromRGB(225,225,240)
		sub.TextXAlignment     = Enum.TextXAlignment.Left
		sub.ZIndex             = 10
		sub.Parent             = btn
	end

	-- Gold corner badge (BATTLE button only)
	if cfg.goldCorner then
		local badge = Instance.new("Frame")
		badge.Size             = UDim2.new(0,64,0,64)
		badge.Position         = UDim2.new(0,-16,0,-16)
		badge.Rotation         = 45
		badge.BackgroundColor3 = C.Gold
		badge.BackgroundTransparency = 0.20
		badge.BorderSizePixel  = 0
		badge.ZIndex           = 9
		badge.Parent           = btn
		-- Star inside badge
		local star = Instance.new("TextLabel")
		star.Size               = UDim2.new(1,0,1,0)
		star.BackgroundTransparency = 1
		star.Text               = "★"
		star.Font               = Enum.Font.LuckiestGuy
		star.TextSize           = 20
		star.TextColor3         = C.NavyDeep
		star.Rotation           = -45
		star.ZIndex             = 10
		star.Parent             = badge
	end

	-- Hover / click interaction
	local origSize = cfg.size
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, fast, {
			Size = UDim2.new(
				1 + 0.03, 0,
				1 + 0.04, 0
			)
		}):Play()
		bStroke.Color     = C.Gold
		bStroke.Thickness = 3
		Arrow.Visible  = true
		local abs = btn.AbsolutePosition
		Arrow.Position = UDim2.new(0, abs.X - 46, 0, abs.Y + btn.AbsoluteSize.Y/2 - 20)
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, fast, {Size = UDim2.new(1,0,1,0)}):Play()
		bStroke.Color     = Color3.fromRGB(60,60,80)
		bStroke.Thickness = 2
		Arrow.Visible = false
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.07), {Size = UDim2.new(0.97,0,0.96,0)}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, fast, {Size = UDim2.new(1,0,1,0)}):Play()
	end)

	return btn, wrap
end

-- ============================================================
--  MAIN MENU LAYOUT
--  Left column (60 %): BATTLE (tall) + two small buttons below
--  Right column (36 %): EXTRAS fills the same height block
-- ============================================================

-- BATTLE
local PlayBtn = createButton({
	name      = "BattleBtn",
	label     = "BATTLE",
	sub       = "Choose your stage and fight",
	icon      = "⚔",
	iconSize  = 52,
	color     = C.Red,
	colorDark = C.RedDark,
	pos       = UDim2.new(0.03, 0, 0.22, 0),
	size      = UDim2.new(0.44, 0, 0.33, 0),
	textSize  = 44,
	subSize   = 14,
	goldCorner = true,
})

-- ROSTER
local RosterBtn = createButton({
	name      = "RosterBtn",
	label     = "ROSTER",
	sub       = "Pick your fighter",
	icon      = "🥊",
	color     = C.Green,
	colorDark = C.GreenDk,
	pos       = UDim2.new(0.03, 0, 0.59, 0),
	size      = UDim2.new(0.21, 0, 0.21, 0),
	textSize  = 22,
})

-- REWARDS
createButton({
	name      = "RewardsBtn",
	label     = "REWARDS",
	sub       = "Coins & unlocks",
	icon      = "🏆",
	iconSize  = 28,
	color     = C.Orange,
	colorDark = C.OrangeDk,
	pos       = UDim2.new(0.26, 0, 0.59, 0),
	size      = UDim2.new(0.21, 0, 0.21, 0),
	textSize  = 22,
})

-- EXTRAS  (right column, matches BATTLE+gap height)
createButton({
	name      = "ExtrasBtn",
	label     = "EXTRAS",
	sub       = "Gallery & replays",
	icon      = "◆",
	color     = C.Blue,
	colorDark = C.BlueDark,
	pos       = UDim2.new(0.50, 0, 0.22, 0),
	size      = UDim2.new(0.20, 0, 0.21, 0),
	textSize  = 22,
})

-- ============================================================
--  STOCK-ICON ROW (decorative, bottom of screen — Smash flair)
-- ============================================================
local stockIcons = {"🔥","⚡","💥","❄","🌊","⚔","🛡","★"}
for i, ico in ipairs(stockIcons) do
	local s = Instance.new("TextLabel")
	s.Size               = UDim2.new(0,28,0,28)
	s.Position           = UDim2.new((i-1)/9 + 0.02, 0, 0.93, 0)
	s.BackgroundTransparency = 1
	s.Text               = ico
	s.Font               = Enum.Font.LuckiestGuy
	s.TextSize           = 22
	s.TextColor3         = Color3.fromRGB(180,190,210)
	s.ZIndex             = 6
	s.Parent             = MainFrame
end

-- Percent "damage" counter decoration (top-right, very Smash)
local pctLabel = Instance.new("TextLabel")
pctLabel.Size               = UDim2.new(0,160,0,60)
pctLabel.Position           = UDim2.new(0.80,0,0.02,0)
pctLabel.BackgroundTransparency = 1
pctLabel.Text               = "0%"
pctLabel.Font               = Enum.Font.LuckiestGuy
pctLabel.TextSize           = 52
pctLabel.TextColor3         = C.White
pctLabel.ZIndex             = 6
pctLabel.Parent             = MainFrame
stroke(pctLabel, C.Red, 3)

local pctSub = Instance.new("TextLabel")
pctSub.Size               = UDim2.new(0,160,0,20)
pctSub.Position           = UDim2.new(0.80,0,0.10,0)
pctSub.BackgroundTransparency = 1
pctSub.Text               = "READY TO FIGHT"
pctSub.Font               = Enum.Font.GothamBold
pctSub.TextSize           = 11
pctSub.TextColor3         = Color3.fromRGB(160,170,200)
pctSub.ZIndex             = 6
pctSub.Parent             = MainFrame

-- ============================================================
--  MAP SELECTION SCREEN
-- ============================================================
MapFrame = Instance.new("Frame")
MapFrame.Name                   = "MapFrame"
MapFrame.Size                   = UDim2.new(1,0,1,0)
MapFrame.Position               = UDim2.new(1,0,0,0)
MapFrame.BackgroundTransparency = 1
MapFrame.ZIndex                 = 5
MapFrame.Visible                = false
MapFrame.Parent                 = screenGui

-- Header panel (dark strip)
local mapHeader = Instance.new("Frame")
mapHeader.Size             = UDim2.new(1,0,0.18,0)
mapHeader.Position         = UDim2.new(0,0,0,0)
mapHeader.BackgroundColor3 = C.NavyMid
mapHeader.BackgroundTransparency = 0.15
mapHeader.BorderSizePixel  = 0
mapHeader.ZIndex           = 9
mapHeader.Parent           = MapFrame

local MapTitle = Instance.new("TextLabel")
MapTitle.Size               = UDim2.new(1,0,1,0)
MapTitle.BackgroundTransparency = 1
MapTitle.Text               = "⚡  SELECT STAGE"
MapTitle.Font               = Enum.Font.LuckiestGuy
MapTitle.TextSize           = 50
MapTitle.TextColor3         = C.White
MapTitle.ZIndex             = 10
MapTitle.Parent             = mapHeader
stroke(MapTitle, C.Black, 5)

-- Gold bar below header
local mapDivider = Instance.new("Frame")
mapDivider.Size             = UDim2.new(1,0,0,5)
mapDivider.Position         = UDim2.new(0,0,0.18,0)
mapDivider.BackgroundColor3 = C.Gold
mapDivider.BorderSizePixel  = 0
mapDivider.ZIndex           = 10
mapDivider.Parent           = MapFrame
gradient(mapDivider, C.Gold, C.Red, 0)

-- Stage card factory
local function createStageCard(name, icon, badge, color, colorDark, posX)
	local card = Instance.new("TextButton")
	card.Name             = name.."Card"
	card.Size             = UDim2.new(0.27, 0, 0.56, 0)
	card.Position         = UDim2.new(posX, 0, 0.24, 0)
	card.BackgroundColor3 = color
	card.Text             = ""
	card.BorderSizePixel  = 0
	card.ClipsDescendants = false
	card.ZIndex           = 8
	card.Parent           = MapFrame
	corner(card, 14)
	gradient(card, color, colorDark, 165)

	-- Inner shadow (bottom dark band)
	local innerShadow = Instance.new("Frame")
	innerShadow.Size               = UDim2.new(1,0,0.30,0)
	innerShadow.Position           = UDim2.new(0,0,0.70,0)
	innerShadow.BackgroundColor3   = C.Black
	innerShadow.BackgroundTransparency = 0.45
	innerShadow.BorderSizePixel    = 0
	innerShadow.ZIndex             = 8
	innerShadow.Parent             = card

	-- Gloss top
	local gloss = Instance.new("Frame")
	gloss.Size               = UDim2.new(1,0,0.20,0)
	gloss.BackgroundColor3   = C.White
	gloss.BackgroundTransparency = 0.75
	gloss.BorderSizePixel    = 0
	gloss.ZIndex             = 9
	gloss.Parent             = card

	local cs = Instance.new("UIStroke")
	cs.Color          = Color3.fromRGB(60,60,80)
	cs.Thickness      = 2
	cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cs.Parent         = card

	-- Stage icon
	local ico = Instance.new("TextLabel")
	ico.Size               = UDim2.new(1,0,0.48,0)
	ico.Position           = UDim2.new(0,0,0.08,0)
	ico.BackgroundTransparency = 1
	ico.Text               = icon
	ico.Font               = Enum.Font.LuckiestGuy
	ico.TextSize           = 72
	ico.TextColor3         = C.White
	ico.ZIndex             = 10
	ico.Parent             = card

	-- Name plate
	local plate = Instance.new("Frame")
	plate.Size             = UDim2.new(1,0,0.20,0)
	plate.Position         = UDim2.new(0,0,0.80,0)
	plate.BackgroundColor3 = C.Black
	plate.BackgroundTransparency = 0.30
	plate.BorderSizePixel  = 0
	plate.ZIndex           = 9
	plate.Parent           = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size               = UDim2.new(1,0,1,0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text               = name:upper()
	nameLbl.Font               = Enum.Font.LuckiestGuy
	nameLbl.TextSize           = 24
	nameLbl.TextColor3         = C.White
	nameLbl.ZIndex             = 10
	nameLbl.Parent             = plate
	stroke(nameLbl, C.Black, 2)

	-- POPULAR badge
	if badge then
		local b = Instance.new("Frame")
		b.Size             = UDim2.new(0,90,0,24)
		b.Position         = UDim2.new(0.5,-45,0,-13)
		b.BackgroundColor3 = C.Gold
		b.BorderSizePixel  = 0
		b.ZIndex           = 12
		b.Parent           = card
		corner(b, 5)
		local bLbl = Instance.new("TextLabel")
		bLbl.Size               = UDim2.new(1,0,1,0)
		bLbl.BackgroundTransparency = 1
		bLbl.Text               = badge:upper()
		bLbl.Font               = Enum.Font.GothamBold
		bLbl.TextSize           = 11
		bLbl.TextColor3         = C.NavyDeep
		bLbl.ZIndex             = 13
		bLbl.Parent             = b
	end

	-- Hover
	local origSize = card.Size
	card.MouseEnter:Connect(function()
		TweenService:Create(card, fast, {
			Size     = UDim2.new(origSize.X.Scale*1.07,0, origSize.Y.Scale*1.07,0),
			Position = UDim2.new(posX-0.01, 0, 0.21, 0)
		}):Play()
		cs.Color     = C.Gold
		cs.Thickness = 3
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(card, fast, {Size=origSize, Position=UDim2.new(posX,0,0.24,0)}):Play()
		cs.Color     = Color3.fromRGB(60,60,80)
		cs.Thickness = 2
	end)
	card.MouseButton1Down:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.07), {
			Size = UDim2.new(origSize.X.Scale*0.93,0, origSize.Y.Scale*0.93,0)
		}):Play()
	end)
	card.MouseButton1Up:Connect(function()
		TweenService:Create(card, fast, {Size=origSize}):Play()
	end)

	return card
end

local StadiumCard   = createStageCard("Stadium",    "🏟",  nil,       C.Blue,   C.BlueDark,  0.05)
local GrassCard     = createStageCard("Grasslands", "🌿",  "POPULAR", C.Green,  C.GreenDk,   0.37)
local SteampunkCard = createStageCard("Steampunk",  "⚙",   nil,       C.Orange, C.OrangeDk,  0.69)

-- Hint
local mapHint = Instance.new("TextLabel")
mapHint.Size               = UDim2.new(1,0,0.06,0)
mapHint.Position           = UDim2.new(0,0,0.91,0)
mapHint.BackgroundTransparency = 1
mapHint.Text               = "— HOVER TO PREVIEW  ·  CLICK TO ENTER —"
mapHint.Font               = Enum.Font.GothamMedium
mapHint.TextSize           = 13
mapHint.TextColor3         = Color3.fromRGB(140,150,180)
mapHint.ZIndex             = 10
mapHint.Parent             = MapFrame

-- ============================================================
--  ROSTER SELECTION SCREEN
-- ============================================================
RosterFrame = Instance.new("Frame")
RosterFrame.Name                   = "RosterFrame"
RosterFrame.Size                   = UDim2.new(1,0,1,0)
RosterFrame.Position               = UDim2.new(1,0,0,0)
RosterFrame.BackgroundTransparency = 1
RosterFrame.ZIndex                 = 5
RosterFrame.Visible                = false
RosterFrame.Parent                 = screenGui

-- Header panel
local rosterHeader = Instance.new("Frame")
rosterHeader.Size             = UDim2.new(1,0,0.18,0)
rosterHeader.Position         = UDim2.new(0,0,0,0)
rosterHeader.BackgroundColor3 = C.NavyMid
rosterHeader.BackgroundTransparency = 0.15
rosterHeader.BorderSizePixel  = 0
rosterHeader.ZIndex           = 9
rosterHeader.Parent           = RosterFrame

local RosterTitle = Instance.new("TextLabel")
RosterTitle.Size               = UDim2.new(1,0,1,0)
RosterTitle.BackgroundTransparency = 1
RosterTitle.Text               = "★  SELECT YOUR FIGHTER"
RosterTitle.Font               = Enum.Font.LuckiestGuy
RosterTitle.TextSize           = 50
RosterTitle.TextColor3         = C.White
RosterTitle.ZIndex             = 10
RosterTitle.Parent             = rosterHeader
stroke(RosterTitle, C.Black, 5)

local rDivider = Instance.new("Frame")
rDivider.Size             = UDim2.new(1,0,0,5)
rDivider.Position         = UDim2.new(0,0,0.18,0)
rDivider.BackgroundColor3 = C.Gold
rDivider.BorderSizePixel  = 0
rDivider.ZIndex           = 10
rDivider.Parent           = RosterFrame
gradient(rDivider, C.Gold, C.Red, 0)

-- Character card factory
local function createCharCard(name, icon, sub, color, colorDark, posX)
	local card = Instance.new("TextButton")
	card.Name             = name.."Card"
	card.Size             = UDim2.new(0.27, 0, 0.56, 0)
	card.Position         = UDim2.new(posX, 0, 0.24, 0)
	card.BackgroundColor3 = color
	card.Text             = ""
	card.BorderSizePixel  = 0
	card.ZIndex           = 8
	card.Parent           = RosterFrame
	corner(card, 14)
	gradient(card, color, colorDark, 165)

	local innerShadow = Instance.new("Frame")
	innerShadow.Size               = UDim2.new(1,0,0.25,0)
	innerShadow.Position           = UDim2.new(0,0,0.75,0)
	innerShadow.BackgroundColor3   = C.Black
	innerShadow.BackgroundTransparency = 0.45
	innerShadow.BorderSizePixel    = 0
	innerShadow.ZIndex             = 8
	innerShadow.Parent             = card

	local gloss = Instance.new("Frame")
	gloss.Size               = UDim2.new(1,0,0.18,0)
	gloss.BackgroundColor3   = C.White
	gloss.BackgroundTransparency = 0.72
	gloss.BorderSizePixel    = 0
	gloss.ZIndex             = 9
	gloss.Parent             = card

	local cs = stroke(card, Color3.fromRGB(60,60,80), 2)
	cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local ico = Instance.new("TextLabel")
	ico.Size               = UDim2.new(1,0,0.42,0)
	ico.Position           = UDim2.new(0,0,0.12,0)
	ico.BackgroundTransparency = 1
	ico.Text               = icon
	ico.Font               = Enum.Font.LuckiestGuy
	ico.TextSize           = 82
	ico.TextColor3         = C.White
	ico.ZIndex             = 10
	ico.Parent             = card
	stroke(ico, C.Black, 2)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size               = UDim2.new(1,0,0.15,0)
	nameLbl.Position           = UDim2.new(0,0,0.60,0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text               = name:upper()
	nameLbl.Font               = Enum.Font.LuckiestGuy
	nameLbl.TextSize           = 30
	nameLbl.TextColor3         = C.White
	nameLbl.ZIndex             = 10
	nameLbl.Parent             = card
	stroke(nameLbl, C.Black, 2)

	local subLbl = Instance.new("TextLabel")
	subLbl.Size               = UDim2.new(1,0,0.10,0)
	subLbl.Position           = UDim2.new(0,0,0.77,0)
	subLbl.BackgroundTransparency = 1
	subLbl.Text               = sub
	subLbl.Font               = Enum.Font.GothamMedium
	subLbl.TextSize           = 13
	subLbl.TextColor3         = Color3.fromRGB(220,220,240)
	subLbl.ZIndex             = 10
	subLbl.Parent             = card

	local origSize = card.Size
	card.MouseEnter:Connect(function()
		TweenService:Create(card, fast, {
			Size     = UDim2.new(origSize.X.Scale*1.07,0, origSize.Y.Scale*1.07,0),
			Position = UDim2.new(posX-0.01,0, 0.21,0)
		}):Play()
		cs.Color     = C.Gold
		cs.Thickness = 3
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(card, fast, {Size=origSize, Position=UDim2.new(posX,0,0.24,0)}):Play()
		cs.Color     = Color3.fromRGB(60,60,80)
		cs.Thickness = 2
	end)
	card.MouseButton1Click:Connect(function()
		burst(screenGui, card.AbsolutePosition + card.AbsoluteSize/2, color)
		local EquipEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("EquipCharacterEvent")
		EquipEvent:FireServer(name)
	end)

	return card
end

local DoomCard    = createCharCard("Doomspire", "🏰", "Classic balance",   C.Red,    C.RedDark,  0.05)
local AthleteCard = createCharCard("Athlete",   "🏃", "High speed & jump", C.Blue,   C.BlueDark, 0.37)
local NinjaCard   = createCharCard("Ninja",     "🥷", "Stealth & agility", C.Purple, C.PurpleDk, 0.69)

-- ============================================================
--  SHARED BACK BUTTON FACTORY
-- ============================================================
local function createBackBtn(parent)
	local btn = Instance.new("TextButton")
	btn.Name             = "BackBtn"
	btn.Size             = UDim2.new(0.14,0,0.09,0)
	btn.Position         = UDim2.new(0.02,0,0.88,0)
	btn.Rotation         = -1
	btn.BackgroundColor3 = C.Red
	btn.Text             = "◀  BACK"
	btn.Font             = Enum.Font.LuckiestGuy
	btn.TextSize         = 20
	btn.TextColor3       = C.White
	btn.BorderSizePixel  = 0
	btn.ZIndex           = 10
	btn.Parent           = parent
	corner(btn, 7)
	stroke(btn, C.Black, 2)
	gradient(btn, C.Red, C.RedDark, 135)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, fast, {Size=UDim2.new(0.155,0,0.10,0)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, fast, {Size=UDim2.new(0.14,0,0.09,0)}):Play()
	end)
	return btn
end

local BackBtn       = createBackBtn(MapFrame)
local RosterBackBtn = createBackBtn(RosterFrame)

-- ============================================================
--  BUTTON CONNECTIONS
-- ============================================================
PlayBtn.MouseButton1Click:Connect(function()
	burst(screenGui, PlayBtn.AbsolutePosition + PlayBtn.AbsoluteSize/2, C.Gold)
	task.wait(0.08)
	slideToMap()
end)

RosterBtn.MouseButton1Click:Connect(function()
	burst(screenGui, RosterBtn.AbsolutePosition + RosterBtn.AbsoluteSize/2, C.Green)
	task.wait(0.08)
	slideToRoster()
end)

BackBtn.MouseButton1Click:Connect(function()
	burst(screenGui, BackBtn.AbsolutePosition + BackBtn.AbsoluteSize/2, C.Red)
	task.wait(0.08)
	slideToMain()
end)

RosterBackBtn.MouseButton1Click:Connect(function()
	burst(screenGui, RosterBackBtn.AbsolutePosition + RosterBackBtn.AbsoluteSize/2, C.Red)
	task.wait(0.08)
	slideToMain()
end)

-- ============================================================
--  TELEPORT LOGIC
-- ============================================================
local function teleportTo(mapName)
	local character = player.Character
	if not character then return end
	local hrp      = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local RS      = game:GetService("ReplicatedStorage")
	local Events  = RS:FindFirstChild("Events")
	local TelReq  = Events and Events:FindFirstChild("TeleportRequest")
	if TelReq then TelReq:FireServer(mapName) end

	hrp.Anchored       = false
	BG.Visible         = false
	MainFrame.Visible  = false
	MapFrame.Visible   = false
	Arrow.Visible      = false
	TitleLabel.Visible = false
	underline.Visible  = false
	setGameplayGuiVisible(true)

	local blurTween = TweenService:Create(menuBlur, slow, {Size=0})
	blurTween:Play()
	blurTween.Completed:Connect(function()
		if menuBlur and menuBlur.Parent then menuBlur:Destroy() end
	end)

	task.wait(0.2)
	camera.CameraType = Enum.CameraType.Custom
	if humanoid then camera.CameraSubject = humanoid end
	arrowPulse = false
end

StadiumCard.MouseButton1Click:Connect(function()
	burst(screenGui, StadiumCard.AbsolutePosition + StadiumCard.AbsoluteSize/2, C.Blue)
	task.wait(0.12)
	teleportTo("Stadium")
end)

GrassCard.MouseButton1Click:Connect(function()
	burst(screenGui, GrassCard.AbsolutePosition + GrassCard.AbsoluteSize/2, C.Green)
	task.wait(0.12)
	teleportTo("Grasslands")
end)

SteampunkCard.MouseButton1Click:Connect(function()
	burst(screenGui, SteampunkCard.AbsolutePosition + SteampunkCard.AbsoluteSize/2, C.Orange)
	task.wait(0.12)
	teleportTo("Steampunk")
end)

-- ============================================================
--  SHOW MENU EVENT
-- ============================================================
local Events = game.ReplicatedStorage:WaitForChild("Events")
Events.ShowMenuEvent.OnClientEvent:Connect(function()
	BG.Visible         = true
	MainFrame.Visible  = true
	MainFrame.Position = UDim2.new(0,0,0,0)
	MapFrame.Visible   = false
	if RosterFrame then RosterFrame.Visible = false end
	Arrow.Visible      = true
	TitleLabel.Visible = true
	underline.Visible  = true
	setGameplayGuiVisible(false)

	if not Lighting:FindFirstChild("MenuBlur") then
		local nb = Instance.new("BlurEffect")
		nb.Name   = "MenuBlur"
		nb.Size   = 24
		nb.Parent = Lighting
		menuBlur  = nb
	end

	freezePlayer(true)
	arrowPulse = true
end)

task.spawn(freezePlayer)
player.CharacterAdded:Connect(function()
	freezePlayer(false)
end)