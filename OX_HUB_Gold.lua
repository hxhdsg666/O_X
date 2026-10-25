--[[
=====================================================================
   O_X HUB  ·  黄金版   (Gold × Mets Edition)
   ---------------------------------------------------------------
   模块   : 透视 / 锁头 / 自动开火 / 瞬移 / 换皮 / 飞行 FlyV2 / 杂项 / 脚本中心
   外部   : 注入 1.2s 后自动执行 pastefy 锁头 + RIVALS SkinChanger（原样 loadstring）
   主题   : 暖金 + 烈焰红 + 皇家蓝（取自参考图配色）
   按键   : RightShift 隐藏/显示   F 飞行   T 刷新玩家列表
   执行器 : Delta / Fluxus / Arceus X / Codex / KRNL 等
            （透视需要执行器支持 Drawing 库）
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

--[[====================  2. 主题（暖金 / 红 / 皇家蓝）  ====================]]

local Theme = {
	bg     = Color3.fromRGB(17, 14, 13),
	panel  = Color3.fromRGB(26, 21, 19),
	panel2 = Color3.fromRGB(38, 30, 26),
	stroke = Color3.fromRGB(66, 52, 44),
	text   = Color3.fromRGB(246, 239, 231),
	sub    = Color3.fromRGB(172, 151, 134),
	gold   = Color3.fromRGB(245, 170, 45),
	gold2  = Color3.fromRGB(255, 210, 122),
	red    = Color3.fromRGB(226, 70, 48),
	blue   = Color3.fromRGB(58, 118, 240),
	green  = Color3.fromRGB(92, 226, 148),
	dark   = Color3.fromRGB(30, 20, 8),
}

local Colors = {
	["黄金"]   = Color3.fromRGB(245, 170, 45),
	["烈焰红"] = Color3.fromRGB(255, 92, 70),
	["皇家蓝"] = Color3.fromRGB(80, 150, 255),
	["薄荷绿"] = Color3.fromRGB(96, 235, 160),
	["纯白"]   = Color3.fromRGB(240, 240, 240),
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

local gui = Instance.new("ScreenGui")
gui.Name = "OX_HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999

local parentOK = pcall(function()
	local target = nil
	if gethui then
		target = gethui()
	end
	if not target then
		target = game:GetService("CoreGui")
	end
	gui.Parent = target
end)

if not parentOK or not gui.Parent then
	gui.Parent = LP:WaitForChild("PlayerGui")
end

if getgenv then
	getgenv().OX_HUB_GUI = gui
end

-- 桌面版固定尺寸 / 手机版全屏铺满，两种布局
local DESKTOP_W, DESKTOP_H = 700, 470
local compact = IS_TOUCH

local uiScaleValue = 1
if not compact then
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	uiScaleValue = math.clamp(math.min((vp.X - 40) / DESKTOP_W, (vp.Y - 40) / DESKTOP_H), 0.6, 1)
end

-- 主窗口
local win = mk("Frame", {
	Name = "Window",
	Size = compact and UDim2.fromScale(1, 1) or UDim2.fromOffset(DESKTOP_W, DESKTOP_H),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Theme.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 1,
	Parent = gui,
})
mk("UICorner", { CornerRadius = UDim.new(0, 12) }, win)
mk("UIStroke", { Color = Theme.gold, Thickness = 1, Transparency = 0.55 }, win)
if not compact then
	mk("UIScale", { Scale = uiScaleValue }, win)
end

-- 外阴影（挂在 gui 上，跟随窗口位置）
local shadow = mk("Frame", {
	Size = compact and UDim2.fromScale(1, 1) or UDim2.fromOffset(DESKTOP_W + 24, DESKTOP_H + 24),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = gui,
})
mk("UICorner", { CornerRadius = UDim.new(0, 18) }, shadow)
if not compact then
	mk("UIScale", { Scale = uiScaleValue }, shadow)
end

win:GetPropertyChangedSignal("Position"):Connect(function()
	shadow.Position = win.Position
end)

-- 顶部三色渐变条
local strip = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 3,
	Parent = win,
})
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.gold2),
		ColorSequenceKeypoint.new(0.5, Theme.red),
		ColorSequenceKeypoint.new(1, Theme.blue),
	}),
}, strip)
mk("UICorner", { CornerRadius = UDim.new(0, 2) }, strip)

-- 标题栏
local titleBar = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 48),
	Position = UDim2.fromOffset(0, 3),
	BackgroundColor3 = Theme.panel,
	BorderSizePixel = 0,
	ZIndex = 2,
	Parent = win,
})
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 24)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 17, 15)),
	}),
	Rotation = 90,
}, titleBar)

local dragArea = mk("Frame", {
	Size = UDim2.new(1, -120, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 3,
	Parent = titleBar,
})

local logo = mk("Frame", {
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.fromOffset(14, 11),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 4,
	Parent = titleBar,
})
mk("UICorner", { CornerRadius = UDim.new(0, 7) }, logo)
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.gold2),
		ColorSequenceKeypoint.new(1, Theme.red),
	}),
	Rotation = 45,
}, logo)
mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Theme.dark,
	Text = "OX",
	ZIndex = 5,
	Parent = logo,
})

mk("TextLabel", {
	Size = UDim2.fromOffset(160, 16),
	Position = UDim2.fromOffset(50, 10),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Theme.gold2,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "O_X HUB",
	ZIndex = 4,
	Parent = titleBar,
})

mk("TextLabel", {
	Size = UDim2.fromOffset(220, 14),
	Position = UDim2.fromOffset(50, 26),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "GOLD EDITION · 锁头 / 透视 / 飞行",
	ZIndex = 4,
	Parent = titleBar,
})

local minimizeBtn = mk("TextButton", {
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -58, 0, 12),
	BackgroundColor3 = Theme.panel2,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 6,
	Parent = titleBar,
})
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, minimizeBtn)
mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Theme.sub,
	Text = "—",
	ZIndex = 7,
	Parent = minimizeBtn,
})

local closeBtn = mk("TextButton", {
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -30, 0, 12),
	BackgroundColor3 = Theme.panel2,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 6,
	Parent = titleBar,
})
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)
mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Theme.red,
	Text = "×",
	ZIndex = 7,
	Parent = closeBtn,
})

-- 侧边栏
local sidebar = mk("Frame", {
	Size = UDim2.new(0, 132, 1, -75),
	Position = UDim2.fromOffset(0, 51),
	BackgroundColor3 = Theme.panel,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 2,
	Parent = win,
})
mk("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
}, sidebar)
mk("UIListLayout", {
	Padding = UDim.new(0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

-- 内容区
local content = mk("Frame", {
	Size = UDim2.new(1, -132, 1, -75),
	Position = UDim2.fromOffset(132, 51),
	BackgroundColor3 = Theme.bg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 2,
	Parent = win,
})

-- 底部信息条
local footer = mk("Frame", {
	Size = UDim2.new(1, -132, 0, 24),
	Position = UDim2.new(0, 132, 1, -24),
	BackgroundColor3 = Theme.panel,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	ZIndex = 2,
	Parent = win,
})
mk("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.fromOffset(10, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = Theme.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Teleport 传送   ·   Refresh 刷新人名   ·   O_X HUB v1.1",
	ZIndex = 3,
	Parent = footer,
})

-- 隐藏后的小悬浮球
local floatBtn = mk("TextButton", {
	Size = UDim2.fromOffset(46, 46),
	Position = UDim2.new(0, 14, 0.4, 0),
	BackgroundColor3 = Theme.gold,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 50,
	Parent = gui,
})
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, floatBtn)
mk("UIStroke", { Color = Theme.gold2, Thickness = 1, Transparency = 0.3 }, floatBtn)
mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Theme.dark,
	Text = "OX",
	ZIndex = 51,
	Parent = floatBtn,
})

--[[====================  10. UI 组件库  ====================]]

local SliderDrag = { active = nil }

UserInputService.InputChanged:Connect(function(input)
	if SliderDrag.active and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		pcall(SliderDrag.active, input.Position)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		SliderDrag.active = nil
	end
end)

local function createSection(parent, text)
	local holder = mk("Frame", {
		Size = UDim2.new(1, -8, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("TextLabel", {
		Size = UDim2.fromOffset(96, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Theme.gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		Parent = holder,
	})
	mk("Frame", {
		Size = UDim2.new(1, -104, 0, 1),
		Position = UDim2.fromOffset(100, 12),
		BackgroundColor3 = Theme.stroke,
		BorderSizePixel = 0,
		Parent = holder,
	})
	return holder
end

local function createLabel(parent, text, height, color)
	return mk("TextLabel", {
		Size = UDim2.new(1, -8, 0, height or 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = color or Theme.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = text,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
end

local function createToggle(parent, text, default, callback)
	local state = default == true

	local row = mk("Frame", {
		Size = UDim2.new(1, -8, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})

	local hover = mk("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.panel2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, hover)

	mk("TextLabel", {
		Size = UDim2.new(1, -56, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		Parent = row,
	})

	local track = mk("Frame", {
		Size = UDim2.fromOffset(36, 19),
		Position = UDim2.new(1, -42, 0.5, -9.5),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.35 }, track)

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(15, 15),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Theme.sub,
		BorderSizePixel = 0,
		Parent = track,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local function paint(animate)
		local bgGoal = state and Theme.gold or Theme.panel2
		local posGoal = state and UDim2.new(1, -17, 0, 2) or UDim2.new(0, 2, 0, 2)
		local knobGoal = state and Theme.dark or Theme.sub
		if animate then
			TweenService:Create(track, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { BackgroundColor3 = bgGoal }):Play()
			TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = posGoal, BackgroundColor3 = knobGoal }):Play()
		else
			track.BackgroundColor3 = bgGoal
			knob.Position = posGoal
			knob.BackgroundColor3 = knobGoal
		end
	end

	local hit = mk("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = row,
	})
	hit.MouseEnter:Connect(function() hover.BackgroundTransparency = 0.6 end)
	hit.MouseLeave:Connect(function() hover.BackgroundTransparency = 1 end)
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

local function createSlider(parent, text, min, max, default, decimals, callback)
	local value = default

	local row = mk("Frame", {
		Size = UDim2.new(1, -8, 0, 42),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})

	mk("TextLabel", {
		Size = UDim2.new(1, -90, 0, 18),
		Position = UDim2.fromOffset(6, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		Parent = row,
	})

	local valueLabel = mk("TextLabel", {
		Size = UDim2.fromOffset(80, 18),
		Position = UDim2.new(1, -86, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Theme.gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		Parent = row,
	})

	local track = mk("Frame", {
		Size = UDim2.new(1, -14, 0, 5),
		Position = UDim2.fromOffset(6, 30),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

	local fill = mk("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.gold,
		BorderSizePixel = 0,
		Parent = track,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.gold2),
			ColorSequenceKeypoint.new(1, Theme.red),
		}),
	}, fill)

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, -6, 0, -4),
		BackgroundColor3 = Color3.fromRGB(255, 240, 214),
		BorderSizePixel = 0,
		Parent = track,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local function setValue(v, fire)
		value = math.clamp(v, min, max)
		local alpha = 0
		if max > min then
			alpha = (value - min) / (max - min)
		end
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -6, 0, -4)
		valueLabel.Text = string.format("%." .. tostring(decimals) .. "f", value)
		if fire and callback then callback(value) end
	end

	local function applyFromPosition(pos)
		local width = math.max(track.AbsoluteSize.X, 1)
		local rel = math.clamp((pos.X - track.AbsolutePosition.X) / width, 0, 1)
		local raw = min + (max - min) * rel
		setValue(round(raw, decimals), true)
	end

	local hit = mk("TextButton", {
		Size = UDim2.new(1, 6, 0, 22),
		Position = UDim2.fromOffset(0, 20),
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

local function createButton(parent, text, callback, accent)
	local btn = mk("TextButton", {
		Size = UDim2.new(1, -8, 0, 30),
		BackgroundColor3 = accent and Theme.gold or Theme.panel2,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(parent),
		Parent = parent,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
	mk("UIStroke", {
		Color = accent and Theme.gold2 or Theme.stroke,
		Thickness = 1,
		Transparency = accent and 0.35 or 0.45,
	}, btn)

	local label = mk("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = accent and Theme.dark or Theme.text,
		Text = text,
		Parent = btn,
	})

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			BackgroundColor3 = accent and Color3.fromRGB(255, 196, 96) or Color3.fromRGB(52, 41, 35),
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			BackgroundColor3 = accent and Theme.gold or Theme.panel2,
		}):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)

	return btn
end

local function createDropdown(parent, text, options, default, callback)
	local value = default

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
		TextSize = 13,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		Parent = row,
	})

	local btn = mk("TextButton", {
		Size = UDim2.fromOffset(140, 24),
		Position = UDim2.new(1, -146, 0.5, -12),
		BackgroundColor3 = Theme.panel2,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
	mk("UIStroke", { Color = Theme.stroke, Thickness = 1, Transparency = 0.4 }, btn)

	local btnLabel = mk("TextLabel", {
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.gold2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = value .. "   ▾",
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
		local sizeY = #options * 24 + 10
		local px = math.clamp(abs.X, 8, math.max(screen.X - 148, 8))
		local py = math.clamp(abs.Y + 27, 8, math.max(screen.Y - sizeY - 8, 8))

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
			ZIndex = 100,
			Parent = gui,
		})
		mk("UICorner", { CornerRadius = UDim.new(0, 7) }, popup)
		mk("UIStroke", { Color = Theme.gold, Thickness = 1, Transparency = 0.45 }, popup)
		if not compact then
			mk("UIScale", { Scale = uiScaleValue }, popup)
		end
		mk("UIPadding", {
			PaddingTop = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}, popup)
		mk("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, popup)

		for i, opt in ipairs(options) do
			local item = mk("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Theme.panel,
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 101,
				Parent = popup,
			})
			mk("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(6, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = (opt == value) and Theme.gold or Theme.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = opt,
				ZIndex = 102,
				Parent = item,
			})
			item.MouseEnter:Connect(function()
				item.BackgroundTransparency = 0.2
			end)
			item.MouseLeave:Connect(function()
				item.BackgroundTransparency = 1
			end)
			item.MouseButton1Click:Connect(function()
				value = opt
				btnLabel.Text = value .. "   ▾"
				closePopup()
				if callback then callback(value) end
			end)
		end
	end

	btn.MouseButton1Click:Connect(openPopup)

	return function(v)
		value = v
		btnLabel.Text = value .. "   ▾"
	end
end

--[[====================  11. 页面 / 标签  ====================]]

local Pages = {}
local TabButtons = {}

local function newPage(name)
	local page = mk("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.gold,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 3,
		Parent = content,
	})
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	mk("UIPadding", { PaddingBottom = UDim.new(0, 14), PaddingRight = UDim.new(0, 6) }, page)
	Pages[name] = page
	return page
end

local function selectTab(name)
	for n, page in pairs(Pages) do
		page.Visible = (n == name)
	end
	for n, entry in pairs(TabButtons) do
		local on = (n == name)
		entry.btn.BackgroundColor3 = on and Theme.panel2 or Theme.panel
		entry.btn.BackgroundTransparency = on and 0 or 1
		entry.label.TextColor3 = on and Theme.gold or Theme.sub
		entry.bar.Visible = on
	end
end

local function createTab(name, subtitle)
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.panel,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(sidebar),
		Parent = sidebar,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

	local bar = mk("Frame", {
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.fromOffset(2, 9),
		BackgroundColor3 = Theme.gold,
		BorderSizePixel = 0,
		Visible = false,
		Parent = btn,
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

	local label = mk("TextLabel", {
		Size = UDim2.new(1, -14, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = name,
		Parent = btn,
	})

	btn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)

	TabButtons[name] = { btn = btn, label = label, bar = bar }
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
createDropdown(pageESP, "ESP 颜色", { "黄金", "烈焰红", "皇家蓝", "薄荷绿", "纯白" }, "黄金", function(v)
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

--[[====================  12.5 加载动画 + 启动选择页  ====================]]

-- 盖满全屏的启动遮罩（先于内容层，动画结束后淡出）
local startup = mk("Frame", {
	Name = "Startup",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 8, 7),
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	ZIndex = 400,
	Parent = gui,
})

local startupGrad = mk("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.86,
	BorderSizePixel = 0,
	ZIndex = 401,
	Parent = startup,
})
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.gold),
		ColorSequenceKeypoint.new(0.55, Theme.red),
		ColorSequenceKeypoint.new(1, Theme.blue),
	}),
	Rotation = 35,
}, startupGrad)

local card = mk("Frame", {
	Size = UDim2.fromOffset(360, 250),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Theme.bg,
	BorderSizePixel = 0,
	ZIndex = 402,
	Parent = startup,
})
mk("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
mk("UIStroke", { Color = Theme.gold, Thickness = 1, Transparency = 0.35 }, card)

local logoBig = mk("Frame", {
	Size = UDim2.fromOffset(60, 60),
	Position = UDim2.fromOffset(150, 22),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 403,
	Parent = card,
})
mk("UICorner", { CornerRadius = UDim.new(0, 16) }, logoBig)
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.gold2),
		ColorSequenceKeypoint.new(1, Theme.red),
	}),
	Rotation = 45,
}, logoBig)
mk("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextColor3 = Theme.dark,
	Text = "OX",
	ZIndex = 404,
	Parent = logoBig,
})

mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.fromOffset(0, 92),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Theme.gold2,
	Text = "O_X HUB",
	ZIndex = 403,
	Parent = card,
})

local loadingLabel = mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.fromOffset(0, 116),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextColor3 = Theme.sub,
	Text = "正在初始化模块…",
	ZIndex = 403,
	Parent = card,
})

local barBg = mk("Frame", {
	Size = UDim2.new(1, -100, 0, 5),
	Position = UDim2.fromOffset(50, 146),
	BackgroundColor3 = Theme.panel2,
	BorderSizePixel = 0,
	ZIndex = 403,
	Parent = card,
})
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, barBg)

local barFill = mk("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 404,
	Parent = barBg,
})
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, barFill)
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.gold2),
		ColorSequenceKeypoint.new(1, Theme.red),
	}),
}, barFill)

local pctLabel = mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.fromOffset(0, 158),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = Theme.gold,
	Text = "0%",
	ZIndex = 403,
	Parent = card,
})

-- ---- 启动选择页（加载完才出现） ----
local chooser = mk("Frame", {
	Name = "Chooser",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 8, 7),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 410,
	Parent = gui,
})
mk("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 18, 12)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 10, 16)),
	}),
	Rotation = 90,
}, chooser)

local chooserTitle = mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, 0.26, -60),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 28,
	TextColor3 = Theme.gold2,
	Text = "O_X HUB",
	ZIndex = 411,
	Parent = chooser,
})

mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0.26, -22),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = Theme.sub,
	Text = "选择你的运行模式",
	ZIndex = 411,
	Parent = chooser,
})

-- 模式按钮容器
local modeRow = mk("Frame", {
	Size = UDim2.fromOffset(460, 150),
	Position = UDim2.new(0.5, 0, 0.5, -10),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	ZIndex = 411,
	Parent = chooser,
})
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 14),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, modeRow)

local DESKTOP_ICON = "🖥"
local MOBILE_ICON = "📱"

local function makeModeCard(title, desc, icon, order, onClick)
	local b = mk("TextButton", {
		Size = UDim2.fromOffset(210, 140),
		BackgroundColor3 = Theme.panel,
		BackgroundTransparency = 0.05,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		ZIndex = 412,
		Parent = modeRow,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, b)
	mk("UIStroke", { Color = Theme.gold, Thickness = 1, Transparency = 0.55 }, b)
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 24)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 19, 17)),
		}),
		Rotation = 90,
	}, b)

	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 42),
		Position = UDim2.fromOffset(0, 14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 26,
		TextColor3 = Theme.gold2,
		Text = icon,
		ZIndex = 413,
		Parent = b,
	})

	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 64),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Theme.text,
		Text = title,
		ZIndex = 413,
		Parent = b,
	})

	mk("TextLabel", {
		Size = UDim2.new(1, -24, 0, 36),
		Position = UDim2.fromOffset(12, 88),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = Theme.sub,
		TextWrapped = true,
		Text = desc,
		ZIndex = 413,
		Parent = b,
	})

	b.MouseEnter:Connect(function()
		pcall(function()
			TweenService:Create(b, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(52, 40, 32),
			}):Play()
		end)
	end)
	b.MouseLeave:Connect(function()
		pcall(function()
			TweenService:Create(b, TweenInfo.new(0.15), {
				BackgroundColor3 = Theme.panel,
			}):Play()
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

	-- 窗口尺寸立即切换
	if compact then
		win.Size = UDim2.fromScale(1, 1)
		win.AnchorPoint = Vector2.new(0.5, 0.5)
		win.Position = UDim2.fromScale(0.5, 0.5)
		local sc = win:FindFirstChildOfClass("UIScale")
		if sc then sc.Scale = 1 end
	else
		win.Size = UDim2.fromOffset(DESKTOP_W, DESKTOP_H)
		win.Position = UDim2.fromScale(0.5, 0.5)
		local sc = win:FindFirstChildOfClass("UIScale")
		if sc then sc.Scale = uiScaleValue end
	end

	-- 手机模式自动把锁头改成常开
	if compact then
		Aim.hold = false
	elseif wasMobile then
		Aim.hold = true
	end

	Util.notify(compact and "已切换到手机模式（全屏）" or "已切换到电脑模式（窗口）")
end

local function showChooser()
	if chooserDone then return end
	chooserDone = true
	chooser.Visible = true

	-- 模式卡片出现动画
	for _, cardBtn in ipairs(modeRow:GetChildren()) do
		if cardBtn:IsA("TextButton") then
			cardBtn.BackgroundTransparency = 1
			pcall(function()
				TweenService:Create(cardBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
					BackgroundTransparency = 0.05,
				}):Play()
			end)
		end
	end
end

makeModeCard("电脑版 Desktop", "窗口模式 700×470，可拖动、自动贴边\n快捷键 RightShift / F / T", DESKTOP_ICON, 1, function()
	applyMode("desktop")
	chooser.Visible = false
	selectTab("透视")
	Util.notify("O_X HUB 已启动 · 电脑模式")
end)

makeModeCard("手机版 Mobile", "全屏铺满，大按钮易点\n自动隐藏键盘快捷键提示", MOBILE_ICON, 2, function()
	applyMode("mobile")
	chooser.Visible = false
	selectTab("透视")
	Util.notify("O_X HUB 已启动 · 手机模式")
end)

-- 加载进度动画
local loadSteps = {
	"正在加载主题…",
	"正在初始化透视模块…",
	"正在初始化锁头 / 自动开火…",
	"正在初始化飞行 FlyV2…",
	"正在初始化瞬移 / 换皮…",
	"准备就绪",
}

task.spawn(function()
	local total = 1.6
	local t0 = os.clock()
	while true do
		local p = math.clamp((os.clock() - t0) / total, 0, 1)
		barFill.Size = UDim2.new(p, 0, 1, 0)
		pctLabel.Text = tostring(math.floor(p * 100)) .. "%"
		local idx = math.clamp(math.floor(p * #loadSteps) + 1, 1, #loadSteps)
		loadingLabel.Text = loadSteps[idx]
		if p >= 1 then break end
		task.wait(0.02)
	end
	task.wait(0.1)

	-- 淡出加载层
	TweenService:Create(startup, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	task.wait(0.26)
	startup.Visible = false
	showChooser()
end)

-- 默认页面（选择前不显示窗口内容）
selectTab("透视")

--[[====================  13. 通知系统  ====================]]

local toastHolder = mk("Frame", {
	Size = UDim2.fromOffset(260, 300),
	Position = UDim2.new(1, -276, 0, 16),
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

local function notify(text)
	toastCount = toastCount + 1
	local toast = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.panel,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		LayoutOrder = toastCount,
		ZIndex = 201,
		Parent = toastHolder,
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 7) }, toast)
	mk("UIStroke", { Color = Theme.gold, Thickness = 1, Transparency = 0.5 }, toast)

	mk("Frame", {
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.fromOffset(0, 6),
		BackgroundColor3 = Theme.gold,
		BorderSizePixel = 0,
		ZIndex = 202,
		Parent = toast,
	})

	mk("TextLabel", {
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		ZIndex = 202,
		Parent = toast,
	})

	task.delay(3, function()
		if toast and toast.Parent then
			pcall(function()
				TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				for _, d in ipairs(toast:GetDescendants()) do
					if d:IsA("TextLabel") then
						TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
					end
				end
			end)
			task.wait(0.32)
			pcall(function() toast:Destroy() end)
		end
	end)
end

Util.notify = notify

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

-- 最小化 / 隐藏
local function setUIVisible(state)
	win.Visible = state
	floatBtn.Visible = not state
end

-- 边缘吸附：松手后自动贴边（手机版跳过）
UserInputService.InputEnded:Connect(function(input)
	if compact then return end
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
