--[[
=====================================================================
   O_X HUB  ·  Gold Edition  v2.0   (Minimal Edition)
   ---------------------------------------------------------------
   模块   : 透视 / 锁头 / 自动开火 / 瞬移 / 换皮 / 飞行 FlyV2 / 杂项 / 脚本中心
   启动   : 视频加载层（110 帧色块流循环播放）→ 模式选择 → 主界面
   界面   : 极简暗黑 · 724×486 · 圆角 12 · 月光蓝强调色 · 侧栏 10 页
   主题   : 深色 / 浅色一键切换（设置页）
   外部   : 注入 1.2s 后自动执行 pastefy 锁头 + RIVALS SkinChanger（原样 loadstring）
   按键   : RightShift 隐藏/显示   F 飞行   T 刷新玩家列表
   执行器 : Delta / Fluxus / Arceus X / Codex / KRNL 等
            （透视需要执行器支持 Drawing 库）
   ---------------------------------------------------------------
   依赖模块（同仓库，缺失自动降级，不影响主功能）：
     O_X_Loading.lua   加载动画
     O_X_Telemetry.lua FPS / Ping / 人数遥测
     OX_Assets.lua     110 帧视频色块流 + 图标网格（约 635 KB）
     O_X_UI.lua        备用组件库
=====================================================================
]]

--[[====================  0. 服务 / 环境  ====================]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")

local LP = Players.LocalPlayer

local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function getCamera()
	return workspace.CurrentCamera
end

local DrawingAvailable = false
do
	local ok, result = pcall(function()
		return type(Drawing) == "table" and type(Drawing.new) == "function"
	end)
	DrawingAvailable = (ok and result == true)
end

-- 防止重复注入
if getgenv then
	if getgenv().OX_HUB_UNLOAD then
		pcall(getgenv().OX_HUB_UNLOAD)
		getgenv().OX_HUB_UNLOAD = nil
	end
	local old = getgenv().OX_HUB_GUI
	if old then
		pcall(function() old:Destroy() end)
	end
end

local Util = {}
Util.notify = function() end
Util.setStatus = function() end

--[[====================  1. 基础工具  ====================]]

local function mk(class, props, parent)
	local obj = Instance.new(class)
	for k, v in next, props do
		obj[k] = v
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

local function nextOrder(parent)
	local n = (parent:GetAttribute("layoutOrder") or 0) + 1
	parent:SetAttribute("layoutOrder", n)
	return n
end

local function round(v, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(v * mult + 0.5) / mult
end

--[[====================  2. 主题（v2.0 极简暗黑 / 灰蓝强调）  ====================]]

-- 主题表：所有界面颜色都从这里取，切换深/浅色只改这一张表
-- 旧变量名（gold / gold2 / red / blue）保留为别名，外部脚本引用不会断
local Theme = {
	mode    = "dark",
	bg      = Color3.fromRGB(13, 14, 17),
	panel   = Color3.fromRGB(19, 20, 24),
	panel2  = Color3.fromRGB(28, 30, 35),
	stroke  = Color3.fromRGB(48, 51, 58),
	text    = Color3.fromRGB(240, 241, 244),
	sub     = Color3.fromRGB(130, 135, 145),
	accent  = Color3.fromRGB(124, 140, 255),
	accent2 = Color3.fromRGB(196, 205, 255),
	green   = Color3.fromRGB(118, 226, 168),
	red     = Color3.fromRGB(226, 82, 74),
	gold    = Color3.fromRGB(124, 140, 255),
	gold2   = Color3.fromRGB(196, 205, 255),
	blue    = Color3.fromRGB(90, 130, 255),
	dark    = Color3.fromRGB(10, 11, 13),
}
Theme.palette = Theme

local function switchTheme(mode)
	local src
	if mode == "light" then
		src = {
			bg      = Color3.fromRGB(246, 246, 248),
			panel   = Color3.fromRGB(255, 255, 255),
			panel2  = Color3.fromRGB(237, 238, 242),
			stroke  = Color3.fromRGB(212, 214, 220),
			text    = Color3.fromRGB(26, 27, 31),
			sub     = Color3.fromRGB(118, 122, 132),
			accent  = Color3.fromRGB(58, 78, 226),
			accent2 = Color3.fromRGB(120, 140, 255),
		}
	else
		src = {
			bg      = Color3.fromRGB(13, 14, 17),
			panel   = Color3.fromRGB(19, 20, 24),
			panel2  = Color3.fromRGB(28, 30, 35),
			stroke  = Color3.fromRGB(48, 51, 58),
			text    = Color3.fromRGB(240, 241, 244),
			sub     = Color3.fromRGB(130, 135, 145),
			accent  = Color3.fromRGB(124, 140, 255),
			accent2 = Color3.fromRGB(196, 205, 255),
		}
		mode = "dark"
	end
	Theme.mode = mode
	for k, v in next, src do
		Theme[k] = v
	end
	Theme.gold = Theme.accent
	Theme.gold2 = Theme.accent2
end

local Colors = {
	["月光蓝"] = Color3.fromRGB(124, 140, 255),
	["霓虹青"] = Color3.fromRGB(96, 232, 224),
	["薄荷绿"] = Color3.fromRGB(118, 226, 168),
	["樱粉"]   = Color3.fromRGB(255, 138, 176),
	["纯白"]   = Color3.fromRGB(245, 246, 250),
	["珊瑚橘"] = Color3.fromRGB(255, 158, 108),
}

--[[====================  3. 功能状态表  ====================]]

local ESP = {
	enabled   = false,
	box       = true,
	name      = true,
	distance  = true,
	health    = true,
	skeleton  = false,
	headDot   = false,
	tracer    = false,
	teamCheck = true,
	maxDist   = 800,
	color     = Theme.gold,
}

local Aim = {
	enabled   = false,
	hold      = not IS_TOUCH,
	part      = "头部",
	fov       = 140,
	smooth    = 0.35,
	maxDist   = 600,
	teamCheck = true,
	wallCheck = true,
	showFov   = true,
	lockMouse = false,
}

local Fly = {
	enabled = false,
	speed   = 80,
	vspeed  = 50,
	bv      = nil,
	gyro    = nil,
	conn    = nil,
}

local Misc = {
	walkspeed  = 16,
	jump       = 50,
	infJump    = false,
	noclip     = false,
	fullbright = false,
	customSpeed = false,
	customJump  = false,
	antiAfk     = true,
}

-- 自动开火（TriggerBot）：准星压在敌人身上自动点左键
local Fire = {
	enabled = false,
	delay   = 0.08,   -- 两次开火最小间隔
	part    = "头部",
	maxDist = 600,
	teamCheck = true,
	wallCheck = true,
	fov     = 200,    -- 0 = 只看准星正下方那一点
	lastShot = 0,
	lastTarget = nil,
}

-- 瞬移（Teleport）
local TP = {
	radius  = 12,     -- 多人列表一次显示多少个
	page    = 1,
	step    = 8,      -- 前后左右偏移单位
	dropHeight = 3,   -- 脚下悬空高度
}

--[[====================  4. 透视 ESP  ====================]]

local ESP_CACHE = {}

local function dnew(class, props)
	if not DrawingAvailable then return nil end
	local ok, obj = pcall(Drawing.new, class)
	if not ok or not obj then return nil end
	if props then
		for k, v in next, props do
			local key, val = k, v
			pcall(function() obj[key] = val end)
		end
	end
	pcall(function() obj.Visible = false end)
	return obj
end

local function track(c, obj)
	if obj then
		c.objects[#c.objects + 1] = obj
	end
	return obj
end

local function buildCache(player)
	local c = { objects = {}, lines = {}, player = player }

	c.boxShadow = track(c, dnew("Square", { Thickness = 3, Filled = false, Color = Color3.new(0, 0, 0) }))
	c.box       = track(c, dnew("Square", { Thickness = 1, Filled = false, Color = ESP.color }))
	c.name      = track(c, dnew("Text",   { Size = 14, Center = true, Outline = true, Color = ESP.color }))
	c.dist      = track(c, dnew("Text",   { Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(235, 235, 235) }))
	c.hpBg      = track(c, dnew("Square", { Thickness = 0, Filled = true, Color = Color3.new(0, 0, 0) }))
	c.hpBar     = track(c, dnew("Square", { Thickness = 0, Filled = true, Color = Theme.green }))
	c.tracer    = track(c, dnew("Line",   { Thickness = 1, Color = ESP.color }))
	c.head      = track(c, dnew("Circle", { Thickness = 1, Filled = true, NumSides = 16, Color = ESP.color }))

	pcall(function()
		c.name.Font = Drawing.Fonts.Plex
		c.dist.Font = Drawing.Fonts.Plex
	end)

	ESP_CACHE[player] = c
	return c
end

local function hideCache(c)
	for _, obj in ipairs(c.objects) do
		pcall(function() obj.Visible = false end)
	end
	for _, line in ipairs(c.lines) do
		if line then
			pcall(function() line.Visible = false end)
		end
	end
end

local function newLine(c)
	local line = dnew("Line", { Thickness = 1 })
	if line then
		c.lines[#c.lines + 1] = line
	end
	return line
end

local function project(camera, worldPos)
	local sp = camera:WorldToViewportPoint(worldPos)
	if sp.Z <= 0 then
		return nil
	end
	return Vector2.new(sp.X, sp.Y)
end

local R15_SEGS = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}

local R6_SEGS = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

local function updateESP()
	if not DrawingAvailable then
		return
	end
	local camera = getCamera()
	if not camera then
		return
	end
	local vp = camera.ViewportSize

	if ESP.enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LP and not ESP_CACHE[player] then
				pcall(buildCache, player)
			end
		end
	end

	for player, c in pairs(ESP_CACHE) do
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local head = char and char:FindFirstChild("Head")

		local show = ESP.enabled and char ~= nil and hrp ~= nil and hum ~= nil
			and head ~= nil and hum.Health > 0

		if show and ESP.teamCheck and player.Team ~= nil and LP.Team ~= nil
			and player.Team == LP.Team then
			show = false
		end

		local dist = 0
		if show then
			dist = (camera.CFrame.Position - hrp.Position).Magnitude
			if dist > ESP.maxDist then
				show = false
			end
		end

		if not show then
			hideCache(c)
		else
			local okBox, cf, size = pcall(function()
				local a, b = char:GetBoundingBox()
				return a, b
			end)

			if not okBox then
				hideCache(c)
			else
				local topScreen = project(camera, (cf * CFrame.new(0, size.Y / 2, 0)).Position)
				local botScreen = project(camera, (cf * CFrame.new(0, -size.Y / 2, 0)).Position)

				if not topScreen or not botScreen then
					hideCache(c)
				else
					local boxH = math.abs(botScreen.Y - topScreen.Y)
					if boxH < 3 then
						hideCache(c)
					else
						local boxW = math.max(boxH * 0.55, 6)
						local bx = topScreen.X - boxW / 2
						local by = math.min(topScreen.Y, botScreen.Y)

						-- 方框
						if ESP.box and c.box and c.boxShadow then
							c.boxShadow.Position = Vector2.new(bx - 1, by - 1)
							c.boxShadow.Size = Vector2.new(boxW + 2, boxH + 2)
							c.boxShadow.Transparency = 0.55
							c.boxShadow.Visible = true

							c.box.Color = ESP.color
							c.box.Position = Vector2.new(bx, by)
							c.box.Size = Vector2.new(boxW, boxH)
							c.box.Visible = true
						else
							if c.box then c.box.Visible = false end
							if c.boxShadow then c.boxShadow.Visible = false end
						end

						-- 名字
						if ESP.name and c.name then
							c.name.Text = player.Name
							c.name.Color = ESP.color
							c.name.Position = Vector2.new(bx + boxW / 2, by - 17)
							c.name.Visible = true
						elseif c.name then
							c.name.Visible = false
						end

						-- 距离
						if ESP.distance and c.dist then
							c.dist.Text = string.format("%dm", math.floor(dist))
							c.dist.Position = Vector2.new(bx + boxW / 2, by + boxH + 2)
							c.dist.Visible = true
						elseif c.dist then
							c.dist.Visible = false
						end

						-- 血量条
						local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
						if ESP.health and c.hpBg and c.hpBar then
							local barX = bx - 7
							c.hpBg.Position = Vector2.new(barX, by)
							c.hpBg.Size = Vector2.new(3, boxH)
							c.hpBg.Visible = true

							local barH = boxH * hpRatio
							c.hpBar.Position = Vector2.new(barX, by + (boxH - barH))
							c.hpBar.Size = Vector2.new(3, barH)
							c.hpBar.Color = Color3.fromRGB(255, 80, 70):Lerp(Color3.fromRGB(92, 226, 148), hpRatio)
							c.hpBar.Visible = true
						else
							if c.hpBg then c.hpBg.Visible = false end
							if c.hpBar then c.hpBar.Visible = false end
						end

						-- 射线
						if ESP.tracer and c.tracer then
							c.tracer.From = Vector2.new(vp.X / 2, vp.Y)
							c.tracer.To = Vector2.new(bx + boxW / 2, by + boxH)
							c.tracer.Color = ESP.color
							c.tracer.Visible = true
						elseif c.tracer then
							c.tracer.Visible = false
						end

						-- 头部圆点
						local headScreen = project(camera, head.Position)
						if ESP.headDot and c.head and headScreen then
							c.head.Position = headScreen
							c.head.Radius = 4
							c.head.Color = ESP.color
							c.head.Visible = true
						elseif c.head then
							c.head.Visible = false
						end

						-- 骨骼
						if ESP.skeleton then
							local rig = R6_SEGS
							if hum.RigType == Enum.HumanoidRigType.R15 then
								rig = R15_SEGS
							end
							local idx = 0
							for _, seg in ipairs(rig) do
								local a = char:FindFirstChild(seg[1])
								local b = char:FindFirstChild(seg[2])
								if a and b then
									local pa = project(camera, a.Position)
									local pb = project(camera, b.Position)
									if pa and pb then
										idx = idx + 1
										local line = c.lines[idx]
										if not line then
											line = newLine(c)
										end
										if line then
											line.From = pa
											line.To = pb
											line.Color = ESP.color
											line.Thickness = 1
											line.Visible = true
										end
									end
								end
							end
							for i = idx + 1, #c.lines do
								if c.lines[i] then
									c.lines[i].Visible = false
								end
							end
						else
							for _, line in ipairs(c.lines) do
								if line then
									line.Visible = false
								end
							end
						end
					end
				end
			end
		end
	end
end

--[[====================  5. 锁头 Aimbot  ====================]]

local fovCircle = nil
if DrawingAvailable then
	fovCircle = dnew("Circle", { Thickness = 1, Filled = false, NumSides = 64 })
end

local function getAimPart(char, mode)
	if mode == "头部" then
		return char:FindFirstChild("Head")
	elseif mode == "躯干" then
		return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	elseif mode == "根部" then
		return char:FindFirstChild("HumanoidRootPart")
	else
		local camera = getCamera()
		if not camera then return nil end
		local best, bestD = nil, math.huge
		for _, p in ipairs(char:GetChildren()) do
			if p:IsA("BasePart") then
				local d = (p.Position - camera.CFrame.Position).Magnitude
				if d < bestD then
					best, bestD = p, d
				end
			end
		end
		return best
	end
end

local function hasLineOfSight(part)
	local camera = getCamera()
	if not camera then return false end
	local origin = camera.CFrame.Position
	local direction = part.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = { camera }
	if LP.Character then
		filter[#filter + 1] = LP.Character
	end
	params.FilterDescendantsInstances = filter
	local result = workspace:Raycast(origin, direction, params)
	return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function updateAim()
	local camera = getCamera()
	if not camera then return end

	if not Aim.enabled then
		if fovCircle then fovCircle.Visible = false end
		return
	end

	local mouse = UserInputService:GetMouseLocation()

	if fovCircle then
		if Aim.showFov then
			fovCircle.Position = mouse
			fovCircle.Radius = Aim.fov / 2
			fovCircle.Color = ESP.color
			fovCircle.Transparency = 0.65
			fovCircle.Visible = true
		else
			fovCircle.Visible = false
		end
	end

	if Aim.hold and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		return
	end

	local localChar = LP.Character
	local localHum = localChar and localChar:FindFirstChildOfClass("Humanoid")
	if not localHum or localHum.Health <= 0 then
		return
	end

	local best, bestScore = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP then
			local char = player.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")

			if char and hum and hrp and hum.Health > 0 then
				local skip = false
				if Aim.teamCheck and player.Team ~= nil and LP.Team ~= nil
					and player.Team == LP.Team then
					skip = true
				end

				if not skip then
					local dist = (camera.CFrame.Position - hrp.Position).Magnitude
					if dist <= Aim.maxDist then
						local part = getAimPart(char, Aim.part)
						if part then
							local sp = camera:WorldToViewportPoint(part.Position)
							if sp.Z > 0 then
								local screen = Vector2.new(sp.X, sp.Y)
								local delta = (screen - mouse).Magnitude
								if delta <= Aim.fov / 2 then
									local clear = true
									if Aim.wallCheck then
										clear = hasLineOfSight(part)
									end
									if clear and delta < bestScore then
										best, bestScore = part, delta
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if best then
		local goal = CFrame.new(camera.CFrame.Position, best.Position)
		local alpha = math.clamp(Aim.smooth, 0.05, 1)
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)

		if Aim.lockMouse and mousemoverel then
			pcall(function()
				local sp = camera:WorldToViewportPoint(best.Position)
				if sp.Z > 0 then
					mousemoverel(sp.X - mouse.X, sp.Y - mouse.Y)
				end
			end)
		end
	end
end

--[[====================  5.5 自动开火 TriggerBot  ====================]]

local function clickTool()
	-- PC：模拟左键点击
	if type(mouse1click) == "function" then
		pcall(mouse1click)
		return true
	end
	-- 移动端 / 通用：直接激活角色手上的工具
	local char = LP.Character
	if not char then return false end
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		pcall(function() tool:Activate() end)
		return true
	end
	return false
end

local function updateFire()
	if not Fire.enabled then
		Fire.lastTarget = nil
		return
	end

	local camera = getCamera()
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not camera or not hum or hum.Health <= 0 then
		return
	end

	-- 鼠标可显隐时，说明鼠标在界面外，不该自动扣扳机
	local mouseLocked = pcall(function()
		return UserInputService.MouseIconEnabled == false
	end)
	if mouseLocked == false then
		Fire.lastTarget = nil
		return
	end

	local now = os.clock()
	if Fire.lastShot and (now - Fire.lastShot) < Fire.delay then
		return
	end

	local cameraPos = camera.CFrame.Position
	local vps = camera.ViewportSize
	local center = Vector2.new(vps.X / 2, vps.Y / 2)
	local best, bestDelta = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP then
			local pchar = player.Character
			local phum = pchar and pchar:FindFirstChildOfClass("Humanoid")
			local phrp = pchar and pchar:FindFirstChild("HumanoidRootPart")
			if pchar and phum and phrp and phum.Health > 0 then
				local skip = false
				if Fire.teamCheck and player.Team ~= nil and LP.Team ~= nil
					and player.Team == LP.Team then
					skip = true
				end

				if not skip then
					local dist = (cameraPos - phrp.Position).Magnitude
					if dist <= Fire.maxDist then
						local part = getAimPart(pchar, Fire.part)
						if part then
							local sp = camera:WorldToViewportPoint(part.Position)
							if sp.Z > 0 then
								local delta = (Vector2.new(sp.X, sp.Y) - center).Magnitude
								if delta <= Fire.fov and delta < bestDelta then
									if (not Fire.wallCheck) or hasLineOfSight(part) then
										best, bestDelta = part, delta
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if best then
		Fire.lastTarget = best
		Fire.lastShot = now
		clickTool()
	else
		Fire.lastTarget = nil
	end
end

-- 准星命中目标时给一条提示线
local fireDot = nil
if DrawingAvailable then
	fireDot = dnew("Circle", { Thickness = 2, Filled = false, NumSides = 8, Visible = false })
end

local function updateFireDot()
	if not fireDot then return end
	local camera = getCamera()
	if not (Fire.enabled and Fire.lastTarget and camera) then
		fireDot.Visible = false
		return
	end
	local sp = camera:WorldToViewportPoint(Fire.lastTarget.Position)
	if sp.Z > 0 then
		fireDot.Position = Vector2.new(sp.X, sp.Y)
		fireDot.Radius = 7
		fireDot.Color = Theme.red
		fireDot.Visible = true
	else
		fireDot.Visible = false
	end
end

--[[====================  5.6 瞬移 Teleport  ====================]]

local function getRoot()
	local char = LP.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function tpToRoot(targetRoot, label)
	if not targetRoot then
		Util.notify("目标无效")
		return false
	end
	local myRoot = getRoot()
	if not myRoot then
		Util.notify("角色未加载")
		return false
	end

	-- 目标位置下方探一下地面
	local target = targetRoot.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { LP.Character, targetRoot.Parent }
	local hit = workspace:Raycast(target, Vector3.new(0, -50, 0), params)
	if hit then
		target = hit.Position + Vector3.new(0, TP.dropHeight, 0)
	else
		target = target + Vector3.new(0, 0.5, 0)
	end

	pcall(function()
		myRoot.CFrame = CFrame.new(target)
	end)
	if label then
		Util.notify("已瞬移到 " .. label)
	end
	return true
end

local function tpToPlayer(player)
	if player == LP then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	tpToRoot(root, player.Name)
end

local function tpOffset(dirName)
	local myRoot = getRoot()
	local camera = getCamera()
	if not myRoot or not camera then return end
	local v = Vector3.new(0, 0, 0)
	if dirName == "前" then
		v = camera.CFrame.LookVector
	elseif dirName == "后" then
		v = -camera.CFrame.LookVector
	elseif dirName == "左" then
		v = -camera.CFrame.RightVector
	elseif dirName == "右" then
		v = camera.CFrame.RightVector
	elseif dirName == "上" then
		v = Vector3.new(0, 1, 0)
	elseif dirName == "下" then
		v = Vector3.new(0, -1, 0)
	end
	myRoot.CFrame = CFrame.new(myRoot.Position + v * TP.step)
end

local function tpToCFrame(pos)
	local myRoot = getRoot()
	if myRoot then
		myRoot.CFrame = CFrame.new(pos)
	end
end

--[[====================  5.7 换肤 Skin  ====================]]

local Skin = {
	char = false,
	hat = false,
	head = false,
	shirt = false,
	shirtId = "",
	pants = false,
	pantsId = "",
	shirtColor = Color3.fromRGB(226, 70, 48),
	pantsColor = Color3.fromRGB(58, 118, 240),
	lastApplied = nil,
}

local function ensureMesh(handle)
	if not handle:FindFirstChildOfClass("SpecialMesh") then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxasset://fonts/hat.mesh"
		mesh.Parent = handle
	end
end

local function applyHatAccessory()
	local char = LP.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return false end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local old = char:FindFirstChild("OX_HatAccessory")
	if old then old:Destroy() end

	local att = head:FindFirstChild("OX_HatAttachment_Ref")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "OX_HatAttachment_Ref"
		att.Position = Vector3.new(0, 1.1, 0)
		att.Parent = head
	end

	local attach = Instance.new("Attachment")
	attach.Name = "OX_HatAttachment"
	attach.Position = Vector3.new(0, 0, 0)
	attach.Rotation = Vector3.new(0, 0, 0)

	local acc = Instance.new("Accessory")
	acc.Name = "OX_HatAccessory"
	acc.Parent = char

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(3.2, 3.2, 0.5)
	handle.Color = Skin.shirtColor
	handle.Material = Enum.Material.Neon
	handle.CanCollide = false
	handle.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
	handle.Parent = acc
	ensureMesh(handle)
	attach.Parent = handle

	local accAtt = Instance.new("Attachment")
	accAtt.Name = "OX_HatAttachment"
	accAtt.Parent = acc

	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = handle
	weld.Part1 = head
	weld.C0 = CFrame.new(0, 1.1, 0)
	weld.C1 = CFrame.new(0, 0, 0)
	weld.Parent = handle

	return true
end

local function clearAccessories()
	local char = LP.Character
	if not char then return end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Accessory") then
			pcall(function() v:Destroy() end)
		end
	end
end

local function findShirtPants()
	local char = LP.Character
	if not char then return nil end
	local shirt, pants
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Shirt") then shirt = v end
		if v:IsA("Pants") then pants = v end
	end
	return shirt, pants
end

local function applyShirt()
	local char = LP.Character
	if not char then return false end
	local shirt = findShirtPants()
	if not shirt then
		shirt = Instance.new("Shirt")
		shirt.Parent = char
	end
	if Skin.shirtId ~= "" then
		shirt.ShirtTemplate = Skin.shirtId
	else
		shirt.ShirtTemplate = ""
	end
	return true
end

local function applyPants()
	local char = LP.Character
	if not char then return false end
	local _, pants = findShirtPants()
	if not pants then
		pants = Instance.new("Pants")
		pants.Parent = char
	end
	if Skin.pantsId ~= "" then
		pants.PantsTemplate = Skin.pantsId
	else
		pants.PantsTemplate = ""
	end
	return true
end

local function applyBodyColor()
	local char = LP.Character
	if not char then return false end
	local changed = 0
	for _, p in ipairs(char:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "Handle" then
			local isLeg = string.find(p.Name, "Leg") ~= nil or string.find(p.Name, "Foot") ~= nil
			pcall(function()
				p.Color = isLeg and Skin.pantsColor or Skin.shirtColor
			end)
			changed = changed + 1
		end
	end
	return changed > 0
end

local function applySkin()
	local char = LP.Character
	if not char then
		Util.notify("角色未加载")
		return
	end

	if Skin.char then
		applyBodyColor()
	end
	if Skin.hat then
		applyHatAccessory()
	end
	if Skin.shirt then
		applyShirt()
	end
	if Skin.pants then
		applyPants()
	end

	Skin.lastApplied = os.clock()
	Util.notify("换肤已应用")
end

local function resetSkin()
	local char = LP.Character
	if not char then return end
	clearAccessories()
	local shirt, pants = findShirtPants()
	if shirt then pcall(function() shirt:Destroy() end) end
	if pants then pcall(function() pants:Destroy() end) end
	for _, p in ipairs(char:GetChildren()) do
		if p:IsA("BasePart") then
			pcall(function() p.Color = Color3.fromRGB(163, 162, 165) end)
		end
	end
	Util.notify("已恢复默认外观")
end

--[[====================  6. 飞行 FlyV2  ====================]]

local flyRestartQueued = false

function Fly:stop()
	if self.conn then
		pcall(function() self.conn:Disconnect() end)
		self.conn = nil
	end
	if self.bv then
		pcall(function() self.bv:Destroy() end)
		self.bv = nil
	end
	if self.gyro then
		pcall(function() self.gyro:Destroy() end)
		self.gyro = nil
	end
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function() hum.PlatformStand = false end)
	end
end

function Fly:start()
	self:stop()

	local char = LP.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return false
	end

	pcall(function() hum.PlatformStand = true end)

	local bv = Instance.new("BodyVelocity")
	bv.Name = "OX_Fly"
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = hrp

	local gyro = Instance.new("BodyGyro")
	gyro.Name = "OX_FlyGyro"
	gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	gyro.P = 3000
	gyro.D = 500
	gyro.CFrame = hrp.CFrame
	gyro.Parent = hrp

	self.bv = bv
	self.gyro = gyro

	self.conn = RunService.RenderStepped:Connect(function()
		if not Fly.enabled then
			return
		end
		local c = LP.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if not root or not h or h.Health <= 0 then
			return
		end
		if bv.Parent ~= root then
			bv.Parent = root
		end
		if gyro.Parent ~= root then
			gyro.Parent = root
		end

		local camera = getCamera()
		if not camera then return end

		local dir = Vector3.new(0, 0, 0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

		if dir.Magnitude > 0 then
			dir = dir.Unit
		end

		bv.Velocity = Vector3.new(dir.X * Fly.speed, dir.Y * Fly.vspeed, dir.Z * Fly.speed)
		gyro.CFrame = CFrame.new(root.Position) * camera.CFrame.Rotation
	end)

	return true
end

function Fly:setEnabled(state)
	self.enabled = state
	if state then
		local ok = self:start()
		if not ok then
			Util.notify("飞行启动失败：角色未加载完成")
		end
	else
		self:stop()
	end
end

-- 复活后自动恢复飞行
LP.CharacterAdded:Connect(function()
	if Fly.enabled then
		if flyRestartQueued then return end
		flyRestartQueued = true
		task.wait(0.8)
		flyRestartQueued = false
		if Fly.enabled then
			Fly:start()
		end
	end
end)

--[[====================  7. 杂项逻辑  ====================]]

local fullbrightBackup = nil

local function setFullbright(state)
	if state then
		if not fullbrightBackup then
			fullbrightBackup = {
				Brightness = Lighting.Brightness,
				ClockTime = Lighting.ClockTime,
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
				FogEnd = Lighting.FogEnd,
				GlobalShadows = Lighting.GlobalShadows,
			}
		end
		Lighting.Brightness = 3
		Lighting.ClockTime = 12
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
	else
		if fullbrightBackup then
			for k, v in pairs(fullbrightBackup) do
				pcall(function() Lighting[k] = v end)
			end
			fullbrightBackup = nil
		end
	end
end

-- 反挂机
LP.Idled:Connect(function()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

-- 无限跳跃
UserInputService.JumpRequest:Connect(function()
	if not Misc.infJump then return end
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end)
	end
end)

-- 速度 / 跳跃 / 穿墙 持续应用
task.spawn(function()
	while task.wait(0.4) do
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			if Misc.customSpeed and math.abs(hum.WalkSpeed - Misc.walkspeed) > 0.5 then
				pcall(function() hum.WalkSpeed = Misc.walkspeed end)
			end
			if Misc.customJump then
				pcall(function()
					hum.UseJumpPower = true
					if math.abs((hum.JumpPower or 0) - Misc.jump) > 0.5 then
						hum.JumpPower = Misc.jump
					end
				end)
			end
		end
		if Misc.noclip and char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide and not p:FindFirstAncestorOfClass("Accessory") then
					pcall(function() p.CanCollide = false end)
				end
			end
		end
	end
end)

--[[====================  8. 外部脚本（锁头 / RIVALS 换肤）  ====================]]

local RemoteScripts = {
	lock = "https://pastefy.app/XKdoJzdZ/raw",
	skin = "https://rawscripts.net/raw/RIVALS-yabujin-skinchanger-crack-105883",
}

-- true：注入后自动执行上面两个外部脚本；false：只在「脚本」页手动点按钮
local AUTO_LOAD_REMOTE = true

-- 通用远程脚本执行器（失败的链接不会带崩整个 Hub）
local function execRemote(url, label)
	Util.setStatus("载入中 " .. label .. " ...", Theme.sub)
	Util.notify("正在载入：" .. label)

	local ok, err = pcall(function()
		local source = game:HttpGet(url)
		if type(source) ~= "string" or #source < 20 then
			error("返回内容为空或无效")
		end
		local fn, perr = loadstring(source)
		if not fn then
			error(perr or "loadstring 失败")
		end
		fn()
	end)

	if ok then
		Util.setStatus(label .. " 载入成功 ✓", Theme.green)
		Util.notify(label .. " 载入成功 ✓")
	else
		Util.setStatus(label .. " 载入失败：" .. tostring(err), Theme.red)
		Util.notify(label .. " 载入失败")
	end
	return ok
end

-- 独立线程执行，即使界面构建失败也照样把这两条 loadstring 跑完
if AUTO_LOAD_REMOTE then
	task.spawn(function()
		task.wait(1.0)  -- 等加载动画演完，遮罩和外部脚本窗口不会打架
		local okLock = execRemote(RemoteScripts.lock, "锁头脚本")
		task.wait(0.5)
		local okSkin = execRemote(RemoteScripts.skin, "RIVALS SkinChanger")
		Util.setStatus(
			"锁头 " .. (okLock and "✓" or "✗") .. "    RIVALS 换肤 " .. (okSkin and "✓" or "✗"),
			(okLock and okSkin) and Theme.green or Theme.gold2
		)
		if okLock then
			Util.notify("外部锁头已生效，内置锁头建议保持关闭以免抢镜头")
		end
		if okSkin then
			Util.notify("RIVALS 换肤脚本已载入")
		end
	end)
end

--[[====================  9. 界面  ====================]]

-- 界面配置（UI v2.0 起集中放这里，方便调尺寸 / 速度 / 贴图开关）
local CONFIG = {
	version     = "2.0",
	width       = 724,
	height      = 486,
	sidebarW    = 150,
	headerH     = 56,
	footerH     = 30,
	radius      = 12,
	loadSeconds = 4.2,     -- 加载动画时长（秒）
	loadSpeed   = 1,       -- 视频播放倍速
	loadVideo   = true,    -- 关闭则加载层只用纯色渐变，省性能
	saveName    = "OX_HUB_v2_settings.json",
}

-- 挂载点：优先 gethui()，其次 CoreGui，最后 PlayerGui（按需求自动判空）
local function resolveGuiParent()
	local ok, hui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and hui then
		return hui
	end

	local ok2, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and core then
		return core
	end

	return LP:WaitForChild("PlayerGui")
end

local GUI_PARENT = resolveGuiParent()

--[[---- 外部模块：界面引擎 / 加载动画 / 遥测（缺失时自动降级，不影响主功能）----]]
local function tryLoad(url, label)
	local ok, mod = pcall(function()
		return loadstring(game:HttpGet(url, true))()
	end)
	if ok and type(mod) == "table" then
		return mod
	end
	warn("[O_X HUB] 模块加载失败：" .. tostring(label) .. " -> " .. tostring(mod))
	return nil
end

local REMOTE_BASE = "https://raw.githubusercontent.com/hxhdsg666/O_X/main/"
local UI_Kit = tryLoad(REMOTE_BASE .. "O_X_UI.lua", "O_X_UI")
local OX_Loading = tryLoad(REMOTE_BASE .. "O_X_Loading.lua", "O_X_Loading")
local OX_Telemetry = tryLoad(REMOTE_BASE .. "O_X_Telemetry.lua", "O_X_Telemetry")

-- 贴图数据：优先用同目录的 OX_Assets.lua（体积大），失败则加载层自动跳过视频
local OX_ASSETS = nil
do
	local ok, assets = pcall(function()
		return loadstring(game:HttpGet(REMOTE_BASE .. "OX_Assets.lua", true))()
	end)
	-- 数据文件以「return {...}」结尾，若执行器把 return 当成主 chunk 返回就直接拿
	if ok and type(assets) == "table" and assets.frames then
		OX_ASSETS = assets
	end
	-- 没拿到再退一步：把源码当字符串重新 loadstring 执行一次
	if not OX_ASSETS then
		local ok2, source = pcall(function()
			return game:HttpGet(REMOTE_BASE .. "OX_Assets.lua", true)
		end)
		if ok2 and type(source) == "string" then
			local fn = loadstring(source)
			if type(fn) == "function" then
				local ok3, data = pcall(fn)
				if ok3 and type(data) == "table" and data.frames then
					OX_ASSETS = data
				end
			end
		end
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "OX_HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999

gui.Parent = GUI_PARENT

if getgenv then
	getgenv().OX_HUB_GUI = gui
end

-- 桌面版固定尺寸 / 手机版全屏铺满，两种布局
local DESKTOP_W, DESKTOP_H = CONFIG.width, CONFIG.height
local compact = IS_TOUCH

local uiScaleValue = 1
if not compact then
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	uiScaleValue = math.clamp(math.min((vp.X - 48) / DESKTOP_W, (vp.Y - 48) / DESKTOP_H), 0.62, 1)
end

--[[---- 字体与节奏 ----]]
local F_BOLD = Enum.Font.GothamBold
local F_MED  = Enum.Font.GothamMedium
local F_REG  = Enum.Font.Gotham

--[[---- 主窗口 ----]]
local win = mk("Frame", {
	Name = "Window",
	Size = compact and UDim2.fromScale(1, 1) or UDim2.fromOffset(DESKTOP_W, DESKTOP_H),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Theme.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 2,
	Parent = gui,
})
mk("UICorner", { CornerRadius = UDim.new(0, CONFIG.radius) }, win)
local winStroke = mk("UIStroke", {
	Color = Theme.stroke,
	Thickness = 1,
	Transparency = 0.25,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, win)
if not compact then
	mk("UIScale", { Scale = uiScaleValue }, win)
end

-- 外层柔光：在窗口外再垫一层极淡的描边，做出"悬浮"层次
local halo = mk("Frame", {
	Size = compact and UDim2.fromScale(1, 1) or UDim2.fromOffset(DESKTOP_W + 2, DESKTOP_H + 2),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1,
	Parent = gui,
})
mk("UICorner", { CornerRadius = UDim.new(0, CONFIG.radius + 1) }, halo)
mk("UIStroke", { Color = Theme.accent, Thickness = 1, Transparency = 0.92 }, halo)
if not compact then
	mk("UIScale", { Scale = uiScaleValue }, halo)
end
local shadow = halo

win:GetPropertyChangedSignal("Position"):Connect(function()
	pcall(function() shadow.Position = win.Position end)
end)

--[[---- 标题栏 ----]]
local titleBar = mk("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, CONFIG.headerH),
	BackgroundColor3 = Theme.panel,
	BorderSizePixel = 0,
	ZIndex = 3,
	Parent = win,
})
mk("UICorner", { CornerRadius = UDim.new(0, CONFIG.radius) }, titleBar)

-- 标题栏底部 1px 分隔，把圆角遮掉
mk("Frame", {
	Size = UDim2.new(1, 0, 0, CONFIG.headerH / 2),
	Position = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = Theme.panel,
	BorderSizePixel = 0,
	ZIndex = 3,
	Parent = titleBar,
})

local dragArea = mk("Frame", {
	Size = UDim2.new(1, -180, 1, 0),
	BackgroundTransparency = 1,
	Active = true,
	ZIndex = 4,
	Parent = titleBar,
})

-- 顶部强调线：从左到右的极细渐变，唯一的高饱和元素
local accentLine = mk("Frame", {
	Size = UDim2.new(1, -2, 0, 1),
	Position = UDim2.fromOffset(1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = titleBar,
})
mk("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.18, 0.15),
		NumberSequenceKeypoint.new(0.55, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Color = ColorSequence.new(Theme.accent, Theme.accent2),
}, accentLine)

-- 图标：专辑封面裁成圆角方块
local logo = mk("Frame", {
	Name = "Logo",
	Size = UDim2.fromOffset(30, 30),
	Position = UDim2.fromOffset(14, 13),
	BackgroundColor3 = Theme.panel2,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 4,
	Parent = titleBar,
})
mk("UICorner", { CornerRadius = UDim.new(0, 9) }, logo)
mk("UIStroke", { Color = Theme.accent, Thickness = 1, Transparency = 0.55 }, logo)

-- 图标填充：用 6x6 色块还原专辑封面（不依赖执行器的图像解码能力）
local function paintIconBlocks(assets, parent, cellsOut)
	pcall(function()
		if not assets or not assets.icon then return false end
		local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		local map = {}
		for i = 1, #B64 do map[string.sub(B64, i, i)] = i - 1 end
		local str = assets.icon
		local out, buf, bits = {}, 0, 0
		for i = 1, #str do
			local v = map[string.sub(str, i, i)]
			if v then
				buf = buf * 64 + v
				bits = bits + 6
				if bits >= 8 then
					bits = bits - 8
					out[#out + 1] = math.floor(buf / (2 ^ bits)) % 256
				end
			end
		end
		if #out < 108 then return false end
		local grid = mk("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = parent,
		})
		for i = 1, 36 do
			local o = (i - 1) * 3 + 1
			local cell = mk("Frame", {
				Size = UDim2.new(1 / 6, 0.6, 1 / 6, 0.6),
				Position = UDim2.new(((i - 1) % 6) / 6, 0, math.floor((i - 1) / 6) / 6, 0),
				BackgroundColor3 = Color3.fromRGB(
					math.clamp((out[o] or 30) + 8, 0, 255),
					math.clamp((out[o + 1] or 30) + 6, 0, 255),
					math.clamp((out[o + 2] or 36) + 12, 0, 255)
				),
				BorderSizePixel = 0,
				ZIndex = 6,
				Parent = grid,
			})
			if cellsOut then cellsOut[#cellsOut + 1] = cell end
		end
		return true
	end)
	return false
end

task.spawn(function()
	local ok, assets = pcall(function()
		return OX_ASSETS
	end)
	if ok and assets then
		if not paintIconBlocks(assets, logo) then
			mk("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = F_BOLD,
				TextSize = 13,
				TextColor3 = Theme.accent2,
				Text = "OX",
				ZIndex = 6,
				Parent = logo,
			})
		end
	else
		mk("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = F_BOLD,
			TextSize = 13,
			TextColor3 = Theme.accent2,
			Text = "OX",
			ZIndex = 6,
			Parent = logo,
		})
	end
end)

mk("TextLabel", {
	Name = "Title",
	Size = UDim2.fromOffset(180, 18),
	Position = UDim2.fromOffset(52, 11),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 14,
	TextColor3 = Theme.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "O_X  HUB",
	ZIndex = 4,
	Parent = titleBar,
})

local versionTag = mk("Frame", {
	Size = UDim2.fromOffset(38, 14),
	Position = UDim2.fromOffset(112, 13),
	BackgroundColor3 = Theme.panel2,
	BorderSizePixel = 0,
	ZIndex = 4,
	Parent = titleBar,
})
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, versionTag)
mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 8,
	TextColor3 = Theme.accent,
	Text = "v" .. CONFIG.version,
	ZIndex = 5,
	Parent = versionTag,
})

mk("TextLabel", {
	Name = "Sub",
	Size = UDim2.fromOffset(220, 12),
	Position = UDim2.fromOffset(52, 30),
	BackgroundTransparency = 1,
	Font = F_REG,
	TextSize = 9,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "MINIMAL EDITION · 透视 / 锁头 / 飞行",
	ZIndex = 4,
	Parent = titleBar,
})

-- LIVE 状态灯（接 Telemetry）
local liveBadge = mk("Frame", {
	Size = UDim2.fromOffset(52, 20),
	Position = UDim2.new(1, -118, 0, 18),
	BackgroundColor3 = Theme.panel2,
	BorderSizePixel = 0,
	ZIndex = 4,
	Parent = titleBar,
})
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, liveBadge)
local liveDot = mk("Frame", {
	Size = UDim2.fromOffset(5, 5),
	Position = UDim2.fromOffset(8, 7.5),
	BackgroundColor3 = Theme.green,
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = liveBadge,
})
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, liveDot)
local liveLabel = mk("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.fromOffset(17, 0),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 8,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "LIVE",
	ZIndex = 5,
	Parent = liveBadge,
})

-- 窗口按钮：圆点风格（极简），hover 才亮
local function makeWinButton(posX, glyph, danger)
	local btn = mk("TextButton", {
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, posX, 0, 16),
		BackgroundColor3 = Theme.panel2,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = titleBar,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
	local hover = mk("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = danger and Theme.red or Theme.panel2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = btn,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, hover)
	mk("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 12,
		TextColor3 = danger and Theme.red or Theme.sub,
		Text = glyph,
		ZIndex = 7,
		Parent = btn,
	})
	btn.MouseEnter:Connect(function()
		hover.BackgroundTransparency = danger and 0.82 or 0.5
	end)
	btn.MouseLeave:Connect(function()
		hover.BackgroundTransparency = 1
	end)
	return btn, hover
end

local minimizeBtn = makeWinButton(-58, "—", false)
local closeBtn = makeWinButton(-32, "×", true)

--[[---- 侧边栏 ----]]
local sidebar = mk("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, CONFIG.sidebarW, 1, -CONFIG.headerH - CONFIG.footerH),
	Position = UDim2.fromOffset(0, CONFIG.headerH),
	BackgroundColor3 = Theme.panel,
	BorderSizePixel = 0,
	ZIndex = 3,
	Parent = win,
})
mk("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
}, sidebar)
mk("UIListLayout", {
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

-- 侧栏分隔线（渲染层级高于滚动条）
mk("Frame", {
	Size = UDim2.new(0, 1, 1, -CONFIG.headerH - CONFIG.footerH),
	Position = UDim2.fromOffset(CONFIG.sidebarW, CONFIG.headerH),
	BackgroundColor3 = Theme.stroke,
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	ZIndex = 4,
	Parent = win,
})

--[[---- 内容区 ----]]
local content = mk("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -CONFIG.sidebarW, 1, -CONFIG.headerH - CONFIG.footerH),
	Position = UDim2.fromOffset(CONFIG.sidebarW, CONFIG.headerH),
	BackgroundColor3 = Theme.bg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = false,
	ZIndex = 3,
	Parent = win,
})

--[[---- 底部状态条 ----]]
local footer = mk("Frame", {
	Name = "Footer",
	Size = UDim2.new(1, 0, 0, CONFIG.footerH),
	Position = UDim2.new(0, 0, 1, -CONFIG.footerH),
	BackgroundColor3 = Theme.panel,
	BorderSizePixel = 0,
	ZIndex = 3,
	Parent = win,
})
mk("UICorner", { CornerRadius = UDim.new(0, CONFIG.radius) }, footer)
mk("Frame", {
	Size = UDim2.new(1, 0, 0, CONFIG.footerH / 2),
	Position = UDim2.fromOffset(0, 0),
	BackgroundColor3 = Theme.panel,
	BorderSizePixel = 0,
	ZIndex = 3,
	Parent = footer,
})

local footerText = mk("TextLabel", {
	Size = UDim2.new(1, -150, 1, 0),
	Position = UDim2.fromOffset(16, 0),
	BackgroundTransparency = 1,
	Font = F_REG,
	TextSize = 9,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "就绪 · RightShift 隐藏 · F 飞行 · T 刷新名单",
	ZIndex = 4,
	Parent = footer,
})

local footerStats = mk("TextLabel", {
	Size = UDim2.fromOffset(140, 1),
	Position = UDim2.new(1, -152, 0, 0),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundTransparency = 1,
	Font = F_MED,
	TextSize = 9,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = "",
	ZIndex = 4,
	Parent = footer,
})
footerStats.Size = UDim2.fromOffset(140, CONFIG.footerH)

--[[---- 隐藏后的悬浮球（改用封面图标 + 呼吸光环）----]]
local floatBtn = mk("TextButton", {
	Size = UDim2.fromOffset(44, 44),
	Position = UDim2.new(0, 14, 0.4, 0),
	BackgroundColor3 = Theme.panel,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 50,
	Parent = gui,
})
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, floatBtn)
mk("UIStroke", { Color = Theme.accent, Thickness = 1, Transparency = 0.45 }, floatBtn)
local floatFallback = mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 13,
	TextColor3 = Theme.accent2,
	Text = "OX",
	ZIndex = 52,
	Parent = floatBtn,
})

task.spawn(function()
	local ok, assets = pcall(function()
		return OX_ASSETS
	end)
	if ok and assets and paintIconBlocks(assets, floatBtn) then
		floatFallback.Visible = false
	end
end)

-- 悬浮球呼吸光环
task.spawn(function()
	while floatBtn.Parent do
		local st = floatBtn:FindFirstChildOfClass("UIStroke")
		if st then
			pcall(function()
				TweenService:Create(st, TweenInfo.new(1.1), { Transparency = 0.15 }):Play()
			end)
			task.wait(1.1)
			pcall(function()
				TweenService:Create(st, TweenInfo.new(1.1), { Transparency = 0.6 }):Play()
			end)
			task.wait(1.1)
		else
			task.wait(1)
		end
	end
end)

--[[====================  10. UI 组件库  ====================]]

-- 拖动条状态（旧版在组件库里声明，保留位置以免后续引用报空）
local SliderDrag = { active = nil }

--[[---- 通用微交互：hover 抬升 + 描边高亮 ----]]
local function bindHover(row, strokeObj, baseColor, hoverColor)
	row.MouseEnter:Connect(function()
		pcall(function()
			TweenService:Create(row, TweenInfo.new(0.14), { BackgroundColor3 = hoverColor }):Play()
			if strokeObj then
				TweenService:Create(strokeObj, TweenInfo.new(0.14), { Transparency = 0.25 }):Play()
			end
		end)
	end)
	row.MouseLeave:Connect(function()
		pcall(function()
			TweenService:Create(row, TweenInfo.new(0.14), { BackgroundColor3 = baseColor }):Play()
			if strokeObj then
				TweenService:Create(strokeObj, TweenInfo.new(0.14), { Transparency = 0.55 }):Play()
			end
		end)
	end)
end

--[[---- 区块标题：小号大写 + 右侧细线 ----]]
local function createSection(parent, text)
	local holder = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("TextLabel", {
		Size = UDim2.fromOffset(220, 30),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 9,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(tostring(text)),
		Parent = holder,
	})
	mk("Frame", {
		Size = UDim2.new(1, -228, 0, 1),
		Position = UDim2.fromOffset(228, 15),
		BackgroundColor3 = Theme.stroke,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = holder,
	})
	return holder
end

local function createLabel(parent, text, height, color)
	return mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, height or 28),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 10,
		TextColor3 = color or Theme.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.2,
		Text = text,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
end

--[[---- 开关：整行卡片 + 细胶囊滑块 ----]]
local function createToggle(parent, text, default, callback)
	local state = default == true

	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
	local rowStroke = mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.55 }, row)

	mk("TextLabel", {
		Size = UDim2.new(1, -72, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Parent = row,
	})

	local track = mk("Frame", {
		Size = UDim2.fromOffset(34, 18),
		Position = UDim2.new(1, -46, 0.5, -9),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Theme.sub,
		BorderSizePixel = 0,
		Parent = track,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local function paint(animate)
		local on = state
		local trackGoal = on and Theme.accent or Theme.panel2
		local knobGoal = on and Color3.fromRGB(255, 255, 255) or Theme.sub
		local posGoal = on and UDim2.new(1, -15, 0, 3) or UDim2.fromOffset(3, 3)
		if animate then
			TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = trackGoal }):Play()
			TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				BackgroundColor3 = knobGoal,
				Position = posGoal,
			}):Play()
		else
			track.BackgroundColor3 = trackGoal
			knob.BackgroundColor3 = knobGoal
			knob.Position = posGoal
		end
	end

	local hit = mk("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = row,
	})
	bindHover(hit, rowStroke, Theme.panel, Theme.panel2)
	hit.MouseButton1Click:Connect(function()
		state = not state
		paint(true)
		if callback then callback(state) end
	end)

	paint(false)

	return function(value, silent)
		state = value == true
		paint(true)
		if not silent and callback then callback(state) end
	end
end

--[[---- 滑块 ----]]
local function createSlider(parent, text, min, max, default, decimals, callback)
	local value = default

	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
	local rowStroke = mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.55 }, row)

	mk("TextLabel", {
		Size = UDim2.new(1, -74, 0, 20),
		Position = UDim2.fromOffset(12, 9),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Parent = row,
	})

	local valueLabel = mk("TextLabel", {
		Size = UDim2.fromOffset(64, 20),
		Position = UDim2.new(1, -74, 0, 9),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 11,
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		Parent = row,
	})

	local track = mk("Frame", {
		Size = UDim2.new(1, -24, 0, 3),
		Position = UDim2.fromOffset(12, 34),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

	local fill = mk("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(0, -5, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = track,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
	mk("UIStroke", { Color = Theme.accent, Thickness = 1, Transparency = 0.2 }, knob)

	local function setValue(v, fire)
		value = math.clamp(v, min, max)
		local alpha = 0
		if max > min then
			alpha = (value - min) / (max - min)
		end
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -5, 0.5, -5)
		valueLabel.Text = string.format("%." .. tostring(decimals or 0) .. "f", value)
		if fire and callback then callback(value) end
	end

	local function applyFromPosition(pos)
		local width = math.max(track.AbsoluteSize.X, 1)
		local rel = math.clamp((pos.X - track.AbsolutePosition.X) / width, 0, 1)
		setValue(round(min + (max - min) * rel, decimals), true)
	end

	local hit = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 24),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = row,
	})

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			SliderDrag.active = applyFromPosition
			applyFromPosition(input.Position)
		end
	end)

	setValue(default, false)

	return function(v, silent)
		setValue(v, false)
		if not silent and callback then callback(v) end
	end
end

--[[---- 按钮 ----]]
local function createButton(parent, text, callback, accent)
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = accent and Theme.accent or Theme.panel,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 10) }, btn)
	local s = mk("UIStroke", {
		Color = accent and Theme.accent2 or Theme.stroke,
		Thickness = 1,
		Transparency = accent and 0.45 or 0.55,
	}, btn)

	mk("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 12,
		TextColor3 = accent and Color3.fromRGB(16, 17, 22) or Theme.text,
		Text = text,
		Parent = btn,
	})

	local us = mk("UIScale", { Scale = 1 }, btn)
	btn.MouseEnter:Connect(function()
		pcall(function()
			TweenService:Create(btn, TweenInfo.new(0.14), {
				BackgroundColor3 = accent and Theme.accent2 or Theme.panel2,
			}):Play()
			s.Transparency = 0.2
		end)
	end)
	btn.MouseLeave:Connect(function()
		pcall(function()
			TweenService:Create(btn, TweenInfo.new(0.14), {
				BackgroundColor3 = accent and Theme.accent or Theme.panel,
			}):Play()
			s.Transparency = accent and 0.45 or 0.55
		end)
	end)
	btn.MouseButton1Click:Connect(function()
		pcall(function()
			TweenService:Create(us, TweenInfo.new(0.07), { Scale = 0.975 }):Play()
			task.delay(0.09, function()
				if us and us.Parent then
					TweenService:Create(us, TweenInfo.new(0.16, Enum.EasingStyle.Back), { Scale = 1 }):Play()
				end
			end)
		end)
		if callback then callback() end
	end)

	return btn
end

--[[---- 下拉 ----]]
local function createDropdown(parent, text, options, default, callback)
	local value = default

	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
	local rowStroke = mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.55 }, row)

	mk("TextLabel", {
		Size = UDim2.new(1, -156, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Parent = row,
	})

	local btn = mk("TextButton", {
		Size = UDim2.fromOffset(126, 26),
		Position = UDim2.new(1, -136, 0.5, -13),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)

	local btnLabel = mk("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Font = F_MED,
		TextSize = 11,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = tostring(value),
		Parent = btn,
	})

	mk("TextLabel", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(1, -18, 0.5, -5),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 7,
		TextColor3 = Theme.sub,
		Text = "▼",
		Parent = btn,
	})

	local popup = nil
	local backdrop = nil

	local function closePopup()
		if backdrop then
			pcall(function() backdrop:Destroy() end)
			backdrop = nil
		end
		if popup then
			pcall(function() popup:Destroy() end)
			popup = nil
		end
	end

	local function openPopup()
		if popup then
			closePopup()
			return
		end
		local camera = workspace.CurrentCamera
		local screen = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local abs = btn.AbsolutePosition
		local sizeY = math.min(#options * 26 + 8, 26 * 8 + 8)
		local px = math.clamp(abs.X, 8, math.max(screen.X - 148, 8))
		local py = math.clamp(abs.Y + 30, 8, math.max(screen.Y - sizeY - 8, 8))

		backdrop = mk("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 90,
			Parent = gui,
		})
		backdrop.MouseButton1Click:Connect(closePopup)

		popup = mk("Frame", {
			Size = UDim2.fromOffset(140, sizeY),
			Position = UDim2.fromOffset(px, py),
			BackgroundColor3 = Theme.panel,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 100,
			Parent = gui,
		})
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, popup)
		mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.15 }, popup)
		if not compact then
			mk("UIScale", { Scale = uiScaleValue }, popup)
		end
		mk("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}, popup)

		local list = mk("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.stroke,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 101,
			Parent = popup,
		})
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

		for i, opt in ipairs(options) do
			local item = mk("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Theme.panel,
				BackgroundTransparency = (opt == value) and 0.82 or 1,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 102,
				Parent = list,
			})
			mk("UICorner", { CornerRadius = UDim.new(0, 7) }, item)
			mk("TextLabel", {
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				BackgroundTransparency = 1,
				Font = (opt == value) and F_BOLD or F_REG,
				TextSize = 11,
				TextColor3 = (opt == value) and Theme.accent or Theme.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(opt),
				ZIndex = 103,
				Parent = item,
			})
			item.MouseEnter:Connect(function()
				item.BackgroundTransparency = 0.88
			end)
			item.MouseLeave:Connect(function()
				item.BackgroundTransparency = (opt == value) and 0.82 or 1
			end)
			item.MouseButton1Click:Connect(function()
				value = opt
				btnLabel.Text = tostring(value)
				closePopup()
				if callback then callback(value) end
			end)
		end
	end

	btn.MouseButton1Click:Connect(openPopup)

	return function(v, silent)
		value = v
		btnLabel.Text = tostring(v)
		if not silent and callback then callback(v) end
	end
end

--[[====================  11. 页面 / 标签  ====================]]

local Pages = {}
local TabButtons = {}
local TabOrder = {}

local function newPage(name)
	local page = mk("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, -28, 1, -24),
		Position = UDim2.fromOffset(20, 14),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		Visible = false,
		ZIndex = 5,
		Parent = content,
	})
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	mk("UIPadding", { PaddingBottom = UDim.new(0, 16), PaddingRight = UDim.new(0, 8) }, page)
	Pages[name] = page
	return page
end

-- 页面切换：淡入 + 轻微上浮
local function selectTab(name)
	for n, page in pairs(Pages) do
		if n == name then
			page.Visible = true
			pcall(function()
				page.Position = UDim2.fromOffset(20, 22)
				TweenService:Create(page, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Position = UDim2.fromOffset(20, 14),
				}):Play()
			end)
		else
			page.Visible = false
		end
	end
	for n, entry in pairs(TabButtons) do
		local on = (n == name)
		entry.btn.BackgroundColor3 = on and Theme.panel2 or Theme.panel
		entry.btn.BackgroundTransparency = on and 0 or 1
		entry.label.TextColor3 = on and Theme.text or Theme.sub
		entry.label.Font = on and F_BOLD or F_REG
		entry.bar.Visible = on
		entry.icon.TextTransparency = on and 0 or 0.45
		entry.icon.TextColor3 = on and Theme.accent or Theme.sub
	end
end

-- 侧栏条目：左侧强调条 + 图标 + 文字
local TAB_ICONS = {
	["透视"] = "◈",
	["锁头"] = "◎",
	["自动开火"] = "⌁",
	["瞬移"] = "→",
	["换皮"] = "❖",
	["飞行"] = "⟡",
	["杂项"] = "⚙",
	["脚本"] = "‹›",
	["设置"] = "⚑",
	["关于"] = "✦",
}

local function createTab(name)
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.panel,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(sidebar),
		ZIndex = 4,
		Parent = sidebar,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)

	local bar = mk("Frame", {
		Size = UDim2.fromOffset(2, 14),
		Position = UDim2.fromOffset(0, 9),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
		Parent = btn,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

	local icon = mk("TextLabel", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromOffset(10, 8),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextTransparency = 0.45,
		Text = TAB_ICONS[name] or "•",
		ZIndex = 5,
		Parent = btn,
	})

	local label = mk("TextLabel", {
		Size = UDim2.new(1, -36, 1, 0),
		Position = UDim2.fromOffset(30, 0),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 11,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = name,
		ZIndex = 5,
		Parent = btn,
	})

	btn.MouseEnter:Connect(function()
		if btn.BackgroundTransparency > 0.5 then
			pcall(function()
				btn.BackgroundTransparency = 0.55
			end)
		end
	end)
	btn.MouseLeave:Connect(function()
		if bar.Visible == false then
			pcall(function()
				btn.BackgroundTransparency = 1
			end)
		end
	end)
	btn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)

	TabButtons[name] = { btn = btn, label = label, bar = bar, icon = icon }
	TabOrder[#TabOrder + 1] = name
	return btn
end

--[[====================  12. 各页面内容  ====================]]

-- ---------- 透视 ----------
local pageESP = newPage("透视")
createTab("透视")
createSection(pageESP, "ESP 开关")
createToggle(pageESP, "透视总开关", false, function(v) ESP.enabled = v end)
createSection(pageESP, "显示元素")
createToggle(pageESP, "显示方框", true, function(v) ESP.box = v end)
createToggle(pageESP, "显示名字", true, function(v) ESP.name = v end)
createToggle(pageESP, "显示距离", true, function(v) ESP.distance = v end)
createToggle(pageESP, "显示血量条", true, function(v) ESP.health = v end)
createToggle(pageESP, "显示骨骼", false, function(v) ESP.skeleton = v end)
createToggle(pageESP, "显示头部圆点", false, function(v) ESP.headDot = v end)
createToggle(pageESP, "显示射线", false, function(v) ESP.tracer = v end)
createSection(pageESP, "参数")
createToggle(pageESP, "队伍检查（忽略队友）", true, function(v) ESP.teamCheck = v end)
createSlider(pageESP, "最大显示距离", 50, 2000, 800, 0, function(v) ESP.maxDist = v end)
createDropdown(pageESP, "ESP 颜色", { "月光蓝", "霓虹青", "薄荷绿", "樱粉", "珊瑚橘", "纯白" }, "月光蓝", function(v)
	ESP.color = Colors[v] or ESP.color
end)
createLabel(pageESP, "提示：透视依赖执行器的 Drawing 库。若没有任何显示，说明当前执行器不支持 Drawing，换 Delta / Fluxus 即可。", 34)

-- ---------- 锁头 ----------
local pageAim = newPage("锁头")
createTab("锁头")
createSection(pageAim, "瞄准开关")
createToggle(pageAim, "锁头总开关", false, function(v) Aim.enabled = v end)
createToggle(pageAim, "按住右键触发（关闭=常开 / 手机默认关）", not IS_TOUCH, function(v) Aim.hold = v end)
createSection(pageAim, "锁定设置")
createDropdown(pageAim, "锁定部位", { "头部", "躯干", "最近部位", "根部" }, "头部", function(v) Aim.part = v end)
createSlider(pageAim, "FOV 范围（像素）", 20, 400, 140, 0, function(v) Aim.fov = v end)
createSlider(pageAim, "平滑度（1 = 瞬锁）", 0.05, 1, 0.35, 2, function(v) Aim.smooth = v end)
createSlider(pageAim, "最大锁定距离", 50, 1000, 600, 0, function(v) Aim.maxDist = v end)
createSection(pageAim, "过滤")
createToggle(pageAim, "队伍检查", true, function(v) Aim.teamCheck = v end)
createToggle(pageAim, "墙体检测（隔墙不锁）", true, function(v) Aim.wallCheck = v end)
createToggle(pageAim, "显示 FOV 圈", true, function(v) Aim.showFov = v end)
createToggle(pageAim, "锁定鼠标（mousemoverel）", false, function(v) Aim.lockMouse = v end)
createLabel(pageAim, "用法：开启总开关后按住鼠标右键，准星靠近目标即可自动贴头；平滑度越小越跟手。", 34)

-- ---------- 自动开火 ----------
local pageFire = newPage("自动开火")
createTab("自动开火")
createSection(pageFire, "TriggerBot")
createToggle(pageFire, "自动开火总开关", false, function(v)
	Fire.enabled = v
	Fire.lastShot = 0
	Util.notify(v and "自动开火已开启" or "自动开火已关闭")
end)
createSection(pageFire, "触发条件")
createDropdown(pageFire, "判定部位", { "头部", "躯干", "最近部位", "根部" }, "头部", function(v) Fire.part = v end)
createSlider(pageFire, "判定半径（0 = 只看准星中心）", 0, 300, 40, 0, function(v) Fire.fov = v end)
createSlider(pageFire, "开火间隔（秒）", 0.02, 0.5, 0.08, 2, function(v) Fire.delay = v end)
createSlider(pageFire, "最大开火距离", 50, 1500, 600, 0, function(v) Fire.maxDist = v end)
createSection(pageFire, "过滤")
createToggle(pageFire, "队伍检查", true, function(v) Fire.teamCheck = v end)
createToggle(pageFire, "墙体检测（隔墙不开火）", true, function(v) Fire.wallCheck = v end)
createLabel(pageFire, "原理：准星命中敌人时自动触发左键（移动端调用手上工具 Activate）。判定半径调小更稳，太大容易乱扫。", 40)

-- ---------- 瞬移 ----------
local pageTP = newPage("瞬移")
createTab("瞬移")
createSection(pageTP, "自身位移")
createSlider(pageTP, "单次位移距离", 2, 100, 8, 0, function(v) TP.step = v end)
local tpPadRow = mk("Frame", {
	Size = UDim2.new(1, -8, 0, 66),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(pageTP),
	Parent = pageTP,
})
local tpDirs = {
	{ "前", 0, 0 }, { "上", 1, 0 }, { "后", 2, 0 },
	{ "左", 0, 1 }, { "下", 1, 1 }, { "右", 2, 1 },
}
for _, d in ipairs(tpDirs) do
	local b = mk("TextButton", {
		Size = UDim2.fromOffset(64, 28),
		Position = UDim2.fromOffset(d[2] * 70, d[3] * 34),
		BackgroundColor3 = Theme.panel2,
		Text = "",
		AutoButtonColor = false,
		Parent = tpPadRow,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.4 }, b)
	mk("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Theme.gold2,
		Text = d[1],
		Parent = b,
	})
	b.MouseButton1Click:Connect(function()
		pcall(tpOffset, d[1])
	end)
end
createButton(pageTP, "回到出生点", function()
	local sp = workspace:FindFirstChild("SpawnLocation")
	if sp then
		tpToCFrame(sp.Position + Vector3.new(0, 4, 0))
	else
		Util.notify("本图没有默认出生点")
	end
end)
createButton(pageTP, "升高 20 格", function()
	local r = getRoot()
	if r then
		pcall(function() r.CFrame = CFrame.new(r.Position + Vector3.new(0, 20, 0)) end)
	end
end)

createSection(pageTP, "传送到玩家")
local tpList = mk("Frame", {
	Size = UDim2.new(1, -8, 0, 10),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(pageTP),
	Parent = pageTP,
})
mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tpList)

local refreshTPList

refreshTPList = function()
	for _, c in ipairs(tpList:GetChildren()) do
		if c:IsA("TextButton") then
			pcall(function() c:Destroy() end)
		end
	end

	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP then
			list[#list + 1] = player
		end
	end
	table.sort(list, function(a, b) return a.Name < b.Name end)

	if #list == 0 then
		mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = Theme.sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "大厅里还没有其他玩家",
			Parent = tpList,
		})
		return
	end

	for i, player in ipairs(list) do
		local b = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Theme.panel2,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			Parent = tpList,
		})
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
		mk("TextLabel", {
			Size = UDim2.new(1, -60, 1, 0),
			Position = UDim2.fromOffset(8, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Theme.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = player.Name,
			Parent = b,
		})
		mk("TextLabel", {
			Size = UDim2.fromOffset(46, 26),
			Position = UDim2.new(1, -50, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = Theme.gold,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "传送",
			Parent = b,
		})
		b.MouseButton1Click:Connect(function()
			pcall(tpToPlayer, player)
		end)
	end
end

createButton(pageTP, "刷新玩家列表", function()
	refreshTPList()
end)
createLabel(pageTP, "传送只移动你自己的角色，不做任何反检测包装；地图里的透明墙、击杀区照样生效。", 34)
refreshTPList()

-- ---------- 换皮 ----------
local pageSkin = newPage("换皮")
createTab("换皮")
createSection(pageSkin, "RIVALS 换肤（外部脚本）")
createButton(pageSkin, "启动 RIVALS SkinChanger", function()
	execRemote(RemoteScripts.skin, "RIVALS SkinChanger")
end, true)
createButton(pageSkin, "启动 锁头脚本（pastefy）", function()
	execRemote(RemoteScripts.lock, "锁头脚本")
end)
createSection(pageSkin, "本地外观（只改你客户端里看见的自己）")
createToggle(pageSkin, "身体换色", false, function(v)
	Skin.char = v
	if v then pcall(applyBodyColor) end
end)
createToggle(pageSkin, "戴发光帽子", false, function(v)
	Skin.hat = v
	if v then pcall(applyHatAccessory) end
end)
createToggle(pageSkin, "穿自定义衬衫 Shirt", false, function(v)
	Skin.shirt = v
	if v then pcall(applyShirt) end
end)
createToggle(pageSkin, "穿自定义裤子 Pants", false, function(v)
	Skin.pants = v
	if v then pcall(applyPants) end
end)
createSection(pageSkin, "参数")
createLabel(pageSkin, "衣服 ID 填图片 Decal 的数字 ID；留空则使用下面的纯色。", 30)

local function makeIdRow(parent, title, getValue, setValue)
	local row = mk("Frame", {
		Size = UDim2.new(1, -8, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("TextLabel", {
		Size = UDim2.new(1, -160, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = row,
	})
	local box = mk("TextBox", {
		Size = UDim2.fromOffset(150, 24),
		Position = UDim2.new(1, -156, 0.5, -12),
		BackgroundColor3 = Theme.panel2,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.gold2,
		Text = getValue(),
		PlaceholderText = "如 123456789",
		PlaceholderColor3 = Theme.sub,
		ClearTextOnFocus = false,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
	mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.4 }, box)
	box.FocusLost:Connect(function()
		setValue(box.Text)
	end)
	return box
end

makeIdRow(pageSkin, "衬衫图片 ID", function() return Skin.shirtId end, function(v)
	Skin.shirtId = tostring(v or "")
	if Skin.shirt then pcall(applyShirt) end
end)
makeIdRow(pageSkin, "裤子图片 ID", function() return Skin.pantsId end, function(v)
	Skin.pantsId = tostring(v or "")
	if Skin.pants then pcall(applyPants) end
end)

local paletteRow = mk("Frame", {
	Size = UDim2.new(1, -8, 0, 30),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(pageSkin),
	Parent = pageSkin,
})
mk("TextLabel", {
	Size = UDim2.fromOffset(70, 30),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = Theme.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "配色",
	Parent = paletteRow,
})
local palette = {
	{ "金", Color3.fromRGB(245, 170, 45) },
	{ "红", Color3.fromRGB(226, 70, 48) },
	{ "蓝", Color3.fromRGB(58, 118, 240) },
	{ "黑", Color3.fromRGB(20, 20, 22) },
	{ "白", Color3.fromRGB(240, 240, 240) },
}
for i, c in ipairs(palette) do
	local sw = mk("TextButton", {
		Size = UDim2.fromOffset(28, 20),
		Position = UDim2.fromOffset(72 + (i - 1) * 34, 5),
		BackgroundColor3 = c[2],
		Text = "",
		AutoButtonColor = false,
		Parent = paletteRow,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, sw)
	mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.3 }, sw)
	sw.MouseButton1Click:Connect(function()
		Skin.shirtColor = c[2]
		Skin.pantsColor = c[2]:Lerp(Color3.fromRGB(0, 0, 0), 0.35)
		if Skin.char then pcall(applyBodyColor) end
		if Skin.hat then pcall(applyHatAccessory) end
		Util.notify("配色已切换：" .. c[1])
	end)
end

createSection(pageSkin, "应用")
createButton(pageSkin, "立即应用换皮", function()
	pcall(applySkin)
end, true)
createButton(pageSkin, "恢复默认外观", function()
	pcall(resetSkin)
end)
createSection(pageSkin, "说明")
createLabel(pageSkin, "本地换皮只改你客户端里的模型，别人看不见；要真正换掉 RIVALS 的皮肤/特效，用「脚本」页的 SkinChanger 外部脚本。", 34)

-- ---------- 飞行 ----------
local pageFly = newPage("飞行")
createTab("飞行")
createSection(pageFly, "FlyV2")
local setFlyToggle = createToggle(pageFly, "飞行开关（F 键）", false, function(v)
	Fly:setEnabled(v)
end)
createSlider(pageFly, "水平速度", 10, 300, 80, 0, function(v) Fly.speed = v end)
createSlider(pageFly, "垂直速度（升降）", 10, 300, 50, 0, function(v) Fly.vspeed = v end)
createButton(pageFly, "立即落地（解除飞行）", function()
	setFlyToggle(false)
end)
createLabel(pageFly, "操作：WASD 平移，空格上升，左Ctrl 下降，视角朝哪就飞向哪。复活后会自动恢复飞行。", 40)

-- ---------- 杂项 ----------
local pageMisc = newPage("杂项")
createTab("杂项")
createSection(pageMisc, "角色")
createSlider(pageMisc, "移动速度 WalkSpeed", 16, 200, 16, 0, function(v)
	Misc.walkspeed = v
	Misc.customSpeed = true
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function() hum.WalkSpeed = v end)
	end
end)
createSlider(pageMisc, "跳跃力 JumpPower", 50, 300, 50, 0, function(v)
	Misc.jump = v
	Misc.customJump = true
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.UseJumpPower = true
			hum.JumpPower = v
		end)
	end
end)
createToggle(pageMisc, "无限跳跃", false, function(v) Misc.infJump = v end)
createToggle(pageMisc, "穿墙 Noclip", false, function(v)
	Misc.noclip = v
	if not v then
		local char = LP.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and not p:FindFirstAncestorOfClass("Accessory") then
					pcall(function() p.CanCollide = true end)
				end
			end
		end
	end
end)
createButton(pageMisc, "重置角色（重生）", function()
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function() hum.Health = 0 end)
	else
		Util.notify("角色未加载")
	end
end)
createSection(pageMisc, "环境")
createToggle(pageMisc, "全亮 Fullbright", false, function(v)
	Misc.fullbright = v
	setFullbright(v)
end)
createLabel(pageMisc, "反挂机默认开启，挂机也不会被踢。", 22)

-- ---------- 脚本 ----------
local pageScript = newPage("脚本")
createTab("脚本")
createSection(pageScript, "外部脚本")
createLabel(pageScript, "注入后会自动执行下面两个脚本（AUTO_LOAD_REMOTE），也可以手动重载。失败通常是链接失效或被执行器拦截。", 30)
local statusLabel = createLabel(pageScript, "状态：待机", 22, Theme.gold2)

local function setStatus(text, color)
	statusLabel.Text = "状态：" .. text
	statusLabel.TextColor3 = color or Theme.gold2
end

-- 让脚本中心的执行结果显示到界面状态栏
Util.setStatus = setStatus

createButton(pageScript, "载入 锁头脚本（pastefy）", function()
	execRemote(RemoteScripts.lock, "锁头脚本")
end, true)

createButton(pageScript, "载入 RIVALS SkinChanger（rawscripts）", function()
	execRemote(RemoteScripts.skin, "RIVALS SkinChanger")
end, true)

createButton(pageScript, "一键全部载入", function()
	task.spawn(function()
		execRemote(RemoteScripts.lock, "锁头脚本")
		task.wait(0.5)
		execRemote(RemoteScripts.skin, "RIVALS SkinChanger")
	end)
end, true)

createSection(pageScript, "内置模块")
createLabel(pageScript, "本界面里的透视 / 锁头 / 飞行全部为脚本内置实现，不依赖上述外部链接，断链也能用。", 30)

-- ---------- 设置 ----------
local pageCfg = newPage("设置")
createTab("设置")
createSection(pageCfg, "外观")
local themeMode = "dark"
local applyThemeMode
applyThemeMode = function(mode)
	themeMode = mode
	switchTheme(mode)
	if getgenv then
		pcall(function() getgenv().OX_THEME_MODE = mode end)
	end
	Util.notify(mode == "light" and "已切换到浅色主题" or "已切换到深色主题")
	-- 需要重建的渐变类控件由 applyThemeMode 负责登记，其余即时生效
end

createDropdown(pageCfg, "主题模式", { "深色 Dark", "浅色 Light" }, "深色 Dark", function(v)
	applyThemeMode(string.find(v, "浅色") and "light" or "dark")
end)
createDropdown(pageCfg, "启动动画", { "开（视频循环）", "关（省性能）" }, "开（视频循环）", function(v)
	CONFIG.loadVideo = string.find(v, "开") ~= nil
end)
createSlider(pageCfg, "动画时长（秒）", 1.5, 8, CONFIG.loadSeconds, 1, function(v)
	CONFIG.loadSeconds = v
end)

createSection(pageCfg, "交互")
createToggle(pageCfg, "进入时播放启动动画", true, function(v)
	CONFIG.playIntro = v
end)
createButton(pageCfg, "重播启动动画", function()
	if OX_Loading and OX_Loading.run then
		OX_Loading.run({
			assets = (function()
				local ok, a = pcall(function() return OX_ASSETS end)
				return ok and a or nil
			end)(),
			theme = Theme,
			gui = gui,
			duration = math.min(CONFIG.loadSeconds, 3),
			speed = CONFIG.loadSpeed,
			onDone = function() Util.notify("启动动画已重播") end,
		})
	end
end)
createToggle(pageCfg, "桌面端边缘自动吸附", true, function(v)
	CONFIG.edgeSnap = v
end)

createSection(pageCfg, "绘制")
createToggle(pageCfg, "透视使用 Drawing 库", true, function()
	Util.notify(DrawingAvailable and "Drawing 可用" or "当前执行器不支持 Drawing")
end)
createButton(pageCfg, "检测执行器能力", function()
	local caps = {}
	caps[#caps + 1] = DrawingAvailable and "Drawing ✓" or "Drawing ×"
	caps[#caps + 1] = (type(getsynasset) == "function") and "getsynasset ✓" or "getsynasset ×"
	caps[#caps + 1] = (type(getcustomasset) == "function") and "getcustomasset ✓" or "getcustomasset ×"
	caps[#caps + 1] = (type(getgenv) == "function") and "getgenv ✓" or "getgenv ×"
	Util.notify("能力：" .. table.concat(caps, "   "))
	pcall(function()
		setStatus("能力：" .. table.concat(caps, " / "), Theme.accent2)
	end)
end)
createLabel(pageCfg, "提示：透视需要执行器支持 Drawing。如果没有方框，换 Delta / Fluxus / Arceus X。", 30)

-- ---------- 关于 ----------
local pageAbout = newPage("关于")
createTab("关于")
createSection(pageAbout, "O_X HUB")

local heroCard = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 96),
	BackgroundColor3 = Theme.panel,
	BorderSizePixel = 0,
	LayoutOrder = nextOrder(pageAbout),
	Parent = pageAbout,
})
mk("UICorner", { CornerRadius = UDim.new(0, 14) }, heroCard)
mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.4 }, heroCard)
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.panel),
		ColorSequenceKeypoint.new(1, Theme.panel2),
	}),
	Rotation = 40,
}, heroCard)

local heroIcon = mk("Frame", {
	Size = UDim2.fromOffset(52, 52),
	Position = UDim2.fromOffset(18, 22),
	BackgroundColor3 = Theme.panel2,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = heroCard,
})
mk("UICorner", { CornerRadius = UDim.new(0, 14) }, heroIcon)
local heroImg = mk("ImageLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Image = "",
	ScaleType = Enum.ScaleType.Crop,
	Parent = heroIcon,
})
mk("UICorner", { CornerRadius = UDim.new(0, 14) }, heroImg)
mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 20,
	TextColor3 = Theme.accent2,
	Text = "OX",
	Parent = heroIcon,
})

mk("TextLabel", {
	Size = UDim2.fromOffset(240, 24),
	Position = UDim2.fromOffset(84, 24),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 17,
	TextColor3 = Theme.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "O_X HUB  ·  Gold",
	Parent = heroCard,
})
mk("TextLabel", {
	Size = UDim2.fromOffset(300, 34),
	Position = UDim2.fromOffset(84, 48),
	BackgroundTransparency = 1,
	Font = F_REG,
	TextSize = 10,
	TextColor3 = Theme.sub,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = "Minimal Edition v" .. CONFIG.version .. "  ·  透视 / 锁头 / 自动开火 / 飞行 / 换皮\n启动画面取自 fakemink · Easter 视频帧，全部内嵌，无外链。",
	Parent = heroCard,
})

createSection(pageAbout, "模块一览")
local moduleInfo = {
	{ "透视 ESP", "方框 / 骨骼 / 射线 / 血量，按玩家距离过滤" },
	{ "锁头 Aimbot", "平滑跟随，FOV 圈绘制，墙体检测" },
	{ "自动开火", "准星命中即开火，可调半径与间隔" },
	{ "飞行 FlyV2", "WASD 平移，空格 / Ctrl 升降" },
	{ "换皮 Skin", "本地外观替换 + RIVALS 外部脚本桥接" },
}
for _, row in ipairs(moduleInfo) do
	local card = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(pageAbout),
		Parent = pageAbout,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
	mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.6 }, card)
	mk("TextLabel", {
		Size = UDim2.fromOffset(120, 42),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 11,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = row[1],
		Parent = card,
	})
	mk("TextLabel", {
		Size = UDim2.new(1, -142, 42, 0),
		Position = UDim2.fromOffset(130, 0),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 10,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = row[2],
		Parent = card,
	})
end

createSection(pageAbout, "快捷键")
createLabel(pageAbout, "RightShift  隐藏 / 显示窗口        F  飞行开关        T  刷新玩家名单", 22, Theme.accent2)

createButton(pageAbout, "复制注入脚本链接", function()
	local link = "loadstring(game:HttpGet('https://raw.githubusercontent.com/hxhdsg666/O_X/main/O_X_HUB_Gold.lua'))()"
	pcall(function()
		if type(setclipboard) == "function" then
			setclipboard(link)
		end
	end)
	Util.notify("链接已复制到剪贴板")
end, true)

--[[====================  12.5 加载动画 + 启动选择页  ====================]]

-- 选择模式后淡出引导层
local chooser = mk("Frame", {
	Name = "Chooser",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(6, 6, 8),
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 430,
	Parent = gui,
})
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 11)),
	}),
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.05),
	}),
}, chooser)

mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 22),
	Position = UDim2.new(0, 0, 0.5, -104),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 11,
	TextColor3 = Color3.fromRGB(140, 145, 158),
	Text = "S E L E C T   M O D E",
	ZIndex = 431,
	Parent = chooser,
})

mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	Position = UDim2.new(0, 0, 0.5, -84),
	BackgroundTransparency = 1,
	Font = F_BOLD,
	TextSize = 26,
	TextColor3 = Color3.fromRGB(245, 246, 250),
	Text = "选择运行模式",
	ZIndex = 431,
	Parent = chooser,
})

local modeRow = mk("Frame", {
	Size = UDim2.fromOffset(500, 130),
	Position = UDim2.new(0.5, 0, 0.5, -30),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	ZIndex = 431,
	Parent = chooser,
})
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 14),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, modeRow)

local function makeModeCard(title, desc, glyph, order, onClick)
	local b = mk("TextButton", {
		Size = UDim2.fromOffset(228, 118),
		BackgroundColor3 = Color3.fromRGB(19, 20, 24),
		BackgroundTransparency = 0.15,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		ZIndex = 432,
		Parent = modeRow,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 16) }, b)
	local st = mk("UIStroke", { Color = Color3.fromRGB(56, 58, 68), Thickness = 1, Transparency = 0.4 }, b)

	mk("TextLabel", {
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(18, 16),
		BackgroundColor3 = Color3.fromRGB(32, 34, 41),
		BorderSizePixel = 0,
		Font = F_BOLD,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(196, 205, 255),
		Text = glyph,
		ZIndex = 433,
		Parent = b,
	})
	local iconHolder = b:FindFirstChildOfClass("TextLabel")
	if iconHolder then
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, iconHolder)
	end

	mk("TextLabel", {
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(18, 58),
		BackgroundTransparency = 1,
		Font = F_BOLD,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(240, 241, 244),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		ZIndex = 433,
		Parent = b,
	})

	mk("TextLabel", {
		Size = UDim2.new(1, -36, 0, 28),
		Position = UDim2.fromOffset(18, 80),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 9,
		TextColor3 = Color3.fromRGB(138, 143, 156),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = desc,
		ZIndex = 433,
		Parent = b,
	})

	b.MouseEnter:Connect(function()
		pcall(function()
			TweenService:Create(b, TweenInfo.new(0.16), {
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(26, 28, 34),
			}):Play()
			st.Color = Color3.fromRGB(124, 140, 255)
			st.Transparency = 0.55
		end)
	end)
	b.MouseLeave:Connect(function()
		pcall(function()
			TweenService:Create(b, TweenInfo.new(0.16), {
				BackgroundTransparency = 0.15,
				BackgroundColor3 = Color3.fromRGB(19, 20, 24),
			}):Play()
			st.Color = Color3.fromRGB(56, 58, 68)
			st.Transparency = 0.4
		end)
	end)
	b.MouseButton1Click:Connect(function()
		if onClick then onClick() end
	end)
	return b
end

local chooserDone = false

local function applyMode(mode)
	local wasMobile = compact
	compact = (mode == "mobile")

	if compact then
		win.Size = UDim2.fromScale(1, 1)
		win.AnchorPoint = Vector2.new(0.5, 0.5)
		win.Position = UDim2.fromScale(0.5, 0.5)
		local sc = win:FindFirstChildOfClass("UIScale")
		if sc then sc.Scale = 1 end
		if halo then
			halo.Visible = false
		end
	else
		win.Size = UDim2.fromOffset(DESKTOP_W, DESKTOP_H)
		win.Position = UDim2.fromScale(0.5, 0.5)
		local sc = win:FindFirstChildOfClass("UIScale")
		if sc then sc.Scale = uiScaleValue end
		if halo then
			halo.Visible = true
		end
	end

	if compact then
		Aim.hold = false
	elseif wasMobile then
		Aim.hold = true
	end

	Util.notify(compact and "已进入手机模式 · 全屏" or "已进入电脑模式 · 窗口")
end

local function hideChooser()
	chooserDone = true
	pcall(function()
		TweenService:Create(chooser, TweenInfo.new(0.24), { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(chooser:GetDescendants()) do
			if d:IsA("TextLabel") then
				pcall(function()
					TweenService:Create(d, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
				end)
			elseif d:IsA("TextButton") then
				pcall(function()
					TweenService:Create(d, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
				end)
			end
		end
	end)
	task.delay(0.26, function()
		if chooser then chooser.Visible = false end
	end)
end

local function showChooser()
	if chooserDone then return end
	chooser.Visible = true
	chooser.BackgroundTransparency = 1
	pcall(function()
		TweenService:Create(chooser, TweenInfo.new(0.3), { BackgroundTransparency = 0.25 }):Play()
	end)
	task.spawn(function()
		for _, cardBtn in ipairs(modeRow:GetChildren()) do
			if cardBtn:IsA("TextButton") then
				local target = cardBtn.BackgroundTransparency
				cardBtn.BackgroundTransparency = 1
				task.wait(0.05)
				pcall(function()
					TweenService:Create(cardBtn, TweenInfo.new(0.26, Enum.EasingStyle.Quad), {
						BackgroundTransparency = target,
					}):Play()
				end)
			end
		end
	end)
end

makeModeCard("电脑版 Desktop", "窗口 724×486 · 可拖动 · 自动贴边\nRightShift 隐藏 / F 飞行 / T 刷新", "◫", 1, function()
	applyMode("desktop")
	hideChooser()
	selectTab("透视")
	Util.notify("O_X HUB v" .. CONFIG.version .. " 已启动")
end)

makeModeCard("手机版 Mobile", "全屏铺满 · 大触控区 · 锁头常开\n自动隐藏键盘提示", "▤", 2, function()
	applyMode("mobile")
	hideChooser()
	selectTab("透视")
	Util.notify("O_X HUB v" .. CONFIG.version .. " 已启动 · 移动端")
end)

--[[---- 启动流程：视频加载层 -> 模式选择 ----]]

local function beginStartup()
	local assets = nil
	pcall(function()
		assets = OX_ASSETS
	end)

	if CONFIG.loadVideo and OX_Loading and assets then
		pcall(function()
			OX_Loading.run({
				assets = assets,
				theme = Theme,
				gui = gui,
				duration = CONFIG.loadSeconds,
				speed = CONFIG.loadSpeed,
				onDone = function()
					showChooser()
				end,
			})
			return
		end)
	end

	-- 退路：简化加载条
	local simple = mk("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(9, 9, 12),
		BorderSizePixel = 0,
		ZIndex = 500,
		Parent = gui,
	})
	local bar = mk("Frame", {
		Size = UDim2.fromOffset(160, 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.stroke,
		BorderSizePixel = 0,
		ZIndex = 501,
		Parent = simple,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	local fill = mk("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		ZIndex = 502,
		Parent = bar,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local p = math.clamp((os.clock() - t0) / 1.2, 0, 1)
			fill.Size = UDim2.new(p, 0, 1, 0)
			if p >= 1 then break end
			task.wait(0.02)
		end
		pcall(function()
			TweenService:Create(simple, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(bar, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(fill, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		end)
		task.wait(0.3)
		simple:Destroy()
		showChooser()
	end)
end

selectTab("透视")
beginStartup()

--[[====================  13. 通知系统  ====================]]

local toastHolder = mk("Frame", {
	Size = UDim2.fromOffset(250, 320),
	Position = UDim2.new(1, -264, 0, 14),
	BackgroundTransparency = 1,
	ZIndex = 200,
	Parent = gui,
})
mk("UIListLayout", {
	Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Top,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)

local toastCount = 0

-- 通知：从右侧滑入 + 进度条倒计时，极简一条
local function notify(text, kind)
	toastCount = toastCount + 1
	local accent = Theme.accent
	if kind == "warn" then
		accent = Color3.fromRGB(255, 176, 92)
	elseif kind == "error" then
		accent = Theme.red
	elseif kind == "ok" then
		accent = Theme.green
	end

	local toast = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(24, 0),
		BackgroundColor3 = Theme.panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		LayoutOrder = toastCount,
		ZIndex = 201,
		Parent = toastHolder,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 9) }, toast)
	mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.35 }, toast)

	mk("Frame", {
		Size = UDim2.fromOffset(2, 18),
		Position = UDim2.fromOffset(0, 9),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 202,
		Parent = toast,
	})
	pcall(function()
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, toast:FindFirstChildOfClass("Frame"))
	end)

	mk("TextLabel", {
		Size = UDim2.new(1, -14, 0, 20),
		Position = UDim2.fromOffset(10, 2),
		BackgroundTransparency = 1,
		Font = F_REG,
		TextSize = 10,
		TextColor3 = Theme.text,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		ZIndex = 202,
		Parent = toast,
	})

	local timer = mk("Frame", {
		Size = UDim2.new(1, -20, 0, 1),
		Position = UDim2.fromOffset(10, 26),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 202,
		Parent = toast,
	})
	pcall(function()
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, timer)
	end)

	pcall(function()
		TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
			Position = UDim2.fromOffset(0, 0),
		}):Play()
		TweenService:Create(timer, TweenInfo.new(3.0, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, -20, 0, 1),
			BackgroundTransparency = 1,
		}):Play()
	end)

	-- 最多保留 4 条，超出丢掉最旧的
	local kids = toastHolder:GetChildren()
	local frames = {}
	for _, c in ipairs(kids) do
		if c:IsA("Frame") then
			frames[#frames + 1] = c
		end
	end
	if #frames > 4 then
		pcall(function() frames[1]:Destroy() end)
	end

	task.delay(3.1, function()
		if toast and toast.Parent then
			pcall(function()
				TweenService:Create(toast, TweenInfo.new(0.26), {
					Position = UDim2.fromOffset(26, 0),
					BackgroundTransparency = 1,
				}):Play()
				for _, d in ipairs(toast:GetDescendants()) do
					if d:IsA("TextLabel") then
						TweenService:Create(d, TweenInfo.new(0.24), { TextTransparency = 1 }):Play()
					elseif d:IsA("UIStroke") then
						TweenService:Create(d, TweenInfo.new(0.24), { Transparency = 1 }):Play()
					elseif d:IsA("Frame") then
						TweenService:Create(d, TweenInfo.new(0.24), { BackgroundTransparency = 1 }):Play()
					end
				end
			end)
			task.wait(0.28)
			pcall(function() toast:Destroy() end)
		end
	end)
end

Util.notify = notify

--[[==== 状态遥测：顶栏 LIVE 灯 + 底部 FPS / Ping / 人数 ====]]

local telemetrySampler = nil
pcall(function()
	if OX_Telemetry and OX_Telemetry.sampler then
		telemetrySampler = OX_Telemetry.sampler()
	end
end)

task.spawn(function()
	while gui.Parent do
		if telemetrySampler then
			local ok, data = pcall(telemetrySampler)
			if ok and data then
				local fps = data.fps or 0
				if footerStats and footerStats.Parent then
					footerStats.Text = string.format(
						"%d FPS   ·   %s ms   ·   %d 人",
						fps,
						data.ping and data.ping >= 0 and tostring(data.ping) or "--",
						data.players or 0
					)
				end
				if liveLabel and liveLabel.Parent then
					local healthy = fps >= 30
					liveLabel.Text = healthy and "LIVE" or "LAG"
					liveLabel.TextColor3 = healthy and Theme.sub or Color3.fromRGB(255, 140, 120)
					if liveDot and liveDot.Parent then
						liveDot.BackgroundColor3 = healthy and Theme.green or Theme.red
					end
				end
			end
		end
		task.wait(1)
	end
end)

--[[====================  14. 交互逻辑  ====================]]

-- 拖动窗口
local dragging = false
local dragStart = nil
local dragOrigin = nil

dragArea.InputBegan:Connect(function(input)
	if compact then return end -- 手机版全屏，不需要拖动
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		dragOrigin = win.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		win.Position = UDim2.new(
			dragOrigin.X.Scale,
			dragOrigin.X.Offset + delta.X / uiScaleValue,
			dragOrigin.Y.Scale,
			dragOrigin.Y.Offset + delta.Y / uiScaleValue
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- 最小化 / 隐藏：带缩放淡出，返回时从悬浮球弹出
local function setUIVisible(state)
	if state then
		win.Visible = true
		floatBtn.Visible = false
		pcall(function()
			local sc = win:FindFirstChildOfClass("UIScale")
			local target = compact and 1 or uiScaleValue
			if sc then
				sc.Scale = target * 0.94
				TweenService:Create(sc, TweenInfo.new(0.24, Enum.EasingStyle.Back), { Scale = target }):Play()
			end
		end)
	else
		-- 整窗缩一下再藏，不做逐节点改透明度（避免下次显示时全白）
		pcall(function()
			local sc = win:FindFirstChildOfClass("UIScale")
			if sc then
				local target = compact and 1 or uiScaleValue
				TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Scale = target * 0.94 }):Play()
			end
		end)
		task.delay(0.16, function()
			if win then win.Visible = false end
			pcall(function()
				local sc = win:FindFirstChildOfClass("UIScale")
				if sc then sc.Scale = compact and 1 or uiScaleValue end
			end)
			if floatBtn then floatBtn.Visible = true end
		end)
	end
end

-- 边缘吸附：松手后自动贴边（手机版跳过）
UserInputService.InputEnded:Connect(function(input)
	if compact then return end
	if CONFIG.edgeSnap == false then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if dragging then
		dragging = false
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local w = DESKTOP_W * uiScaleValue
		local h = DESKTOP_H * uiScaleValue
		local curX = win.AbsolutePosition.X + win.AbsoluteSize.X / 2
		local curY = win.AbsolutePosition.Y + win.AbsoluteSize.Y / 2
		local margin = 10
		local targetX = (curX < vp.X / 2) and (margin + w / 2) or (vp.X - margin - w / 2)
		local targetY = math.clamp(curY, h / 2 + margin, vp.Y - h / 2 - margin)
		pcall(function()
			TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				Position = UDim2.fromOffset(targetX, targetY),
			}):Play()
		end)
	end
end)

minimizeBtn.MouseButton1Click:Connect(function()
	setUIVisible(false)
end)

floatBtn.MouseButton1Click:Connect(function()
	setUIVisible(true)
end)

-- 关闭 / 卸载
local renderConn = nil

local function unload()
	ESP.enabled = false
	Aim.enabled = false
	Misc.noclip = false
	pcall(function() Fly:setEnabled(false) end)

	if renderConn then
		pcall(function() renderConn:Disconnect() end)
		renderConn = nil
	end
	if fovCircle then
		pcall(function() fovCircle:Remove() end)
		fovCircle = nil
	end
	for _, c in pairs(ESP_CACHE) do
		pcall(hideCache, c)
		for _, obj in ipairs(c.objects) do
			pcall(function() obj:Remove() end)
		end
		for _, line in ipairs(c.lines) do
			pcall(function() line:Remove() end)
		end
	end
	ESP_CACHE = {}

	if getgenv then
		getgenv().OX_HUB_GUI = nil
		getgenv().OX_HUB_UNLOAD = nil
	end
end

closeBtn.MouseButton1Click:Connect(function()
	pcall(unload)
	gui:Destroy()
end)

-- 快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if UserInputService:GetFocusedTextBox() then return end

	-- 还没选模式之前，快捷键不生效
	if chooser and chooser.Visible then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		setUIVisible(not win.Visible)
	elseif input.KeyCode == Enum.KeyCode.F then
		Fly:setEnabled(not Fly.enabled)
		setFlyToggle(Fly.enabled, true)
		Util.notify(Fly.enabled and "飞行已开启" or "飞行已关闭")
	elseif input.KeyCode == Enum.KeyCode.T then
		pcall(refreshTPList)
		Util.notify("玩家列表已刷新（共 " .. tostring(#Players:GetPlayers() - 1) .. " 人）")
	end
end)

--[[====================  15. 主循环  ====================]]

renderConn = RunService.RenderStepped:Connect(function()
	if DrawingAvailable then
		pcall(updateESP)
	end
	pcall(updateAim)
	pcall(updateFire)
	pcall(updateFireDot)
end)

Players.PlayerRemoving:Connect(function(player)
	local c = ESP_CACHE[player]
	if c then
		for _, obj in ipairs(c.objects) do
			pcall(function() obj:Remove() end)
		end
		for _, line in ipairs(c.lines) do
			pcall(function() line:Remove() end)
		end
		ESP_CACHE[player] = nil
	end
end)

--[[====================  16. 启动提示  ====================]]

if getgenv then
	getgenv().OX_HUB_UNLOAD = unload
end

task.delay(0.6, function()
	notify("O_X HUB 已注入 · RightShift 隐藏界面 · F 飞行")
	if not DrawingAvailable then
		notify("当前执行器不支持 Drawing，透视不可用")
	end
	if AUTO_LOAD_REMOTE then
		notify("正在自动载入外部脚本（锁头 / RIVALS 换肤）")
	end
end)
