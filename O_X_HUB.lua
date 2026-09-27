--=====================================================================
--  O_X HUB  ·  加载动画 + 飞行
--  Version : 1.0.0
--  Date    : 2026-09-27
--
--  用法（执行器里粘贴执行）：
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/<用户名>/<仓库>/refs/heads/main/O_X_HUB.lua"))()
--=====================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--========================== 配置区 ==========================
local CONFIG = {
	Title    = "O_X HUB",
	Version  = "v1.0.0",
	FlySpeed = 60,                                                    -- 默认飞行速度
	MaxSpeed = 300,                                                   -- 速度条上限
	FlyKey   = Enum.KeyCode.F,                                        -- 开关飞行
	UpKeys   = { Enum.KeyCode.Space },                                -- 上升
	DownKeys = { Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift },  -- 下降
}

--========================== 主题色 ==========================
local C = {
	Bg      = Color3.fromRGB(13, 14, 18),
	Panel   = Color3.fromRGB(22, 24, 30),
	Panel2  = Color3.fromRGB(32, 35, 44),
	Stroke  = Color3.fromRGB(48, 52, 64),
	Accent  = Color3.fromRGB(99, 102, 241),
	Accent2 = Color3.fromRGB(168, 85, 247),
	Text    = Color3.fromRGB(237, 239, 245),
	Sub     = Color3.fromRGB(138, 144, 162),
	Green   = Color3.fromRGB(34, 197, 94),
	Red     = Color3.fromRGB(239, 68, 68),
}

local FONT_N = Enum.Font.GothamMedium
local FONT_B = Enum.Font.GothamBold

--========================== 工具函数 ==========================

-- 快速创建实例：props 里的 Parent 最后赋值，children 自动挂载
local function new(class, props, children)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

-- 整体淡入
local function fadeIn(root, dur)
	local info = TweenInfo.new(dur or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			local target = d.TextTransparency
			if target < 1 then
				d.TextTransparency = 1
				TweenService:Create(d, info, { TextTransparency = target }):Play()
			end
			if d:IsA("GuiObject") then
				local bg = d.BackgroundTransparency
				if bg < 1 then
					d.BackgroundTransparency = 1
					TweenService:Create(d, info, { BackgroundTransparency = bg }):Play()
				end
			end
		elseif d:IsA("Frame") or d:IsA("ScrollingFrame") then
			local target = d.BackgroundTransparency
			if target < 1 then
				d.BackgroundTransparency = 1
				TweenService:Create(d, info, { BackgroundTransparency = target }):Play()
			end
		elseif d:IsA("UIStroke") then
			local target = d.Transparency
			if target < 1 then
				d.Transparency = 1
				TweenService:Create(d, info, { Transparency = target }):Play()
			end
		end
	end
end

-- 拖拽
local function makeDraggable(frame, handle)
	local dragging, dragStart, startPos = false, nil, nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- GUI 挂载点（优先执行器的 gethui，其次 CoreGui，最后 PlayerGui）
local function getGuiParent()
	local ok, hui = pcall(function() return gethui() end)
	if ok and hui then return hui end
	local ok2, core = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and core then return core end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local GUI_PARENT = getGuiParent()

--========================== 滑块组件 ==========================
local function createSlider(parent, opts)
	local min, max = opts.Min or 0, opts.Max or 100

	local hit = new("Frame", {
		Name = "SliderHit",
		Size = UDim2.new(0, opts.Width or 206, 0, 20),
		Position = opts.Position,
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local track = new("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = C.Panel2,
		BorderSizePixel = 0,
		Parent = hit,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local knob = new("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = C.Text,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = hit,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	new("UIStroke", { Color = C.Accent, Thickness = 2, Parent = knob })

	local dragging = false

	local function setValue(v, fire)
		v = math.clamp(v, min, max)
		local frac = (v - min) / (max - min)
		fill.Size = UDim2.new(frac, 0, 1, 0)
		knob.Position = UDim2.new(frac, 0, 0.5, 0)
		if fire and opts.OnChange then
			opts.OnChange(v)
		end
		return v
	end

	local function fromInput(input)
		local w = track.AbsoluteSize.X
		if w <= 0 then return end
		local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / w, 0, 1)
		setValue(min + (max - min) * rel, true)
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			fromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	setValue(opts.Default or min, false)
	return setValue
end

--=====================================================================
--  一、加载动画
--=====================================================================
local function createLoadingScreen(onDone)
	local gui = new("ScreenGui", {
		Name = "O_X_HUB_Loading",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 100000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GUI_PARENT,
	})

	local bg = new("Frame", {
		Name = "Bg",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		Parent = gui,
	})

	-- 顶部/底部氛围光带
	local glowTop = new("Frame", {
		Size = UDim2.new(1, 0, 0, 220),
		Position = UDim2.new(0, 0, 0, -160),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Parent = bg,
	})
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = glowTop,
	})

	local container = new("Frame", {
		Name = "Container",
		Size = UDim2.new(0, 340, 0, 200),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = bg,
	})

	-- LOGO
	local logo = new("Frame", {
		Name = "Logo",
		Size = UDim2.new(0, 64, 0, 64),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = container,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 18), Parent = logo })
	new("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new(C.Accent, C.Accent2),
		Parent = logo,
	})
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "A",
		TextSize = 34,
		Font = FONT_B,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = logo,
	})

	-- 标题
	new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0.5, 0, 0, 76),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = CONFIG.Title,
		TextSize = 21,
		Font = FONT_B,
		TextColor3 = C.Text,
		Parent = container,
	})

	-- 状态文字
	local status = new("TextLabel", {
		Name = "Status",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0.5, 0, 0, 104),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "正在启动...",
		TextSize = 13,
		Font = FONT_N,
		TextColor3 = C.Sub,
		Parent = container,
	})

	-- 进度条
	local track = new("Frame", {
		Name = "Track",
		Size = UDim2.new(0, 300, 0, 6),
		Position = UDim2.new(0.5, 0, 0, 136),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = C.Panel2,
		BorderSizePixel = 0,
		Parent = container,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	new("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new(C.Accent, C.Accent2),
		Parent = fill,
	})

	-- 百分比
	local percent = new("TextLabel", {
		Name = "Percent",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0.5, 0, 0, 150),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "0%",
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		Parent = container,
	})

	-- 版本号
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0.5, 0, 1, -18),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = CONFIG.Title .. "  " .. CONFIG.Version,
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = Color3.fromRGB(80, 84, 100),
		Parent = container,
	})

	-- 进度驱动
	local current = 0
	local function setPct(v)
		current = v
		fill.Size = UDim2.new(v / 100, 0, 1, 0)
		percent.Text = string.format("%d%%", math.floor(v + 0.5))
	end
	setPct(0)

	local function animateTo(target, dur)
		local start = current
		local nv = Instance.new("NumberValue")
		nv.Value = 0
		local conn = nv:GetPropertyChangedSignal("Value"):Connect(function()
			setPct(start + (target - start) * nv.Value)
		end)
		local tween = TweenService:Create(
			nv,
			TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = 1 }
		)
		tween:Play()
		tween.Completed:Wait()
		conn:Disconnect()
		nv:Destroy()
		setPct(target)
	end

	local stages = {
		{ text = "初始化运行环境...", pct = 18,  dur = 0.45 },
		{ text = "加载核心模块...",   pct = 42,  dur = 0.55 },
		{ text = "注入界面组件...",   pct = 68,  dur = 0.55 },
		{ text = "校验执行权限...",   pct = 90,  dur = 0.45 },
		{ text = "启动完成",          pct = 100, dur = 0.35 },
	}

	task.spawn(function()
		task.wait(0.25)
		for _, s in ipairs(stages) do
			status.Text = s.text
			animateTo(s.pct, s.dur)
			task.wait(0.05)
		end

		task.wait(0.35)

		-- 淡出并销毁
		local fadeInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(bg, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(glowTop, fadeInfo, { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, fadeInfo, { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") then
				TweenService:Create(d, fadeInfo, { BackgroundTransparency = 1 }):Play()
			end
		end
		task.wait(0.5)

		gui:Destroy()
		if onDone then onDone() end
	end)
end

--=====================================================================
--  二、主界面
--=====================================================================
local guiMain = new("ScreenGui", {
	Name = "O_X HUB",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 99999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Enabled = false,
	Parent = GUI_PARENT,
})

local panel = new("Frame", {
	Name = "Panel",
	Size = UDim2.new(0, 230, 0, 168),
	Position = UDim2.new(0, 24, 0, 90),
	BackgroundColor3 = C.Panel,
	BorderSizePixel = 0,
	Parent = guiMain,
})
new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = panel })
new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = panel })

-- 标题栏（拖拽区）
local header = new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = C.Panel2,
	BorderSizePixel = 0,
	Parent = panel,
})
new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = header })
new("Frame", { -- 抹平标题栏底部圆角
	Size = UDim2.new(1, 0, 0, 12),
	Position = UDim2.new(0, 0, 1, -12),
	BackgroundColor3 = C.Panel2,
	BorderSizePixel = 0,
	Parent = header,
})

new("TextLabel", {
	Size = UDim2.new(1, -24, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text = CONFIG.Title,
	TextSize = 14,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
})
new("TextLabel", {
	Size = UDim2.new(0, 60, 1, 0),
	Position = UDim2.new(1, -68, 0, 0),
	BackgroundTransparency = 1,
	Text = CONFIG.Version,
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = C.Sub,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = header,
})

makeDraggable(panel, header)

-- 飞行开关按钮
local toggleBtn = new("TextButton", {
	Name = "FlyToggle",
	Size = UDim2.new(1, -24, 0, 36),
	Position = UDim2.new(0, 12, 0, 48),
	BackgroundColor3 = C.Panel2,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "飞行  已关闭",
	TextSize = 14,
	Font = FONT_B,
	TextColor3 = C.Sub,
	Parent = panel,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = toggleBtn })
local toggleStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = toggleBtn })

-- 速度行
new("TextLabel", {
	Size = UDim2.new(0, 80, 0, 16),
	Position = UDim2.new(0, 12, 0, 94),
	BackgroundTransparency = 1,
	Text = "飞行速度",
	TextSize = 12,
	Font = FONT_N,
	TextColor3 = C.Sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = panel,
})

local speedLabel = new("TextLabel", {
	Size = UDim2.new(0, 80, 0, 16),
	Position = UDim2.new(1, -92, 0, 94),
	BackgroundTransparency = 1,
	Text = tostring(CONFIG.FlySpeed),
	TextSize = 12,
	Font = FONT_B,
	TextColor3 = C.Accent,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = panel,
})

-- 底部提示
new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 14),
	Position = UDim2.new(0, 12, 1, -22),
	BackgroundTransparency = 1,
	Text = "F 开关飞行 · 空格上升 / Ctrl 下降",
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = Color3.fromRGB(96, 101, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = panel,
})

--========================== 提示条 ==========================
local notifyHolder = new("Frame", {
	Name = "NotifyHolder",
	Size = UDim2.new(0, 260, 0, 44),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 24),
	BackgroundTransparency = 1,
	Parent = guiMain,
})

local function notify(text, color)
	local box = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(0, 0, 0, -20),
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
		Parent = notifyHolder,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = box })
	new("UIStroke", { Color = color or C.Accent, Thickness = 1, Parent = box })
	new("Frame", { -- 左侧色条
		Size = UDim2.new(0, 4, 1, -16),
		Position = UDim2.new(0, 6, 0, 8),
		BackgroundColor3 = color or C.Accent,
		BorderSizePixel = 0,
		Parent = box,
	})
	new("TextLabel", {
		Size = UDim2.new(1, -26, 1, 0),
		Position = UDim2.new(0, 18, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 13,
		Font = FONT_N,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = box,
	})

	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(box, info, { Position = UDim2.new(0, 0, 0, 0) }):Play()

	task.delay(2.4, function()
		local out = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local t1 = TweenService:Create(box, out, { Position = UDim2.new(0, 0, 0, -20) })
		t1:Play()
		t1.Completed:Wait()
		box:Destroy()
	end)
end

--=====================================================================
--  三、飞行模块
--=====================================================================
local Fly = {
	Enabled = false,        -- 用户意图
	Active  = false,        -- 运行状态
	Speed   = CONFIG.FlySpeed,
	BodyVelocity = nil,
	BodyGyro     = nil,
	Connections  = {},
}

local mobileUp, mobileDown = false, false

local function getRoot()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

function Fly:Update()
	local root = getRoot()
	if not root or not self.BodyVelocity or not self.BodyGyro then return end

	local cam = workspace.CurrentCamera
	if not cam then return end

	local move = Vector3.zero

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		-- 移动端：直接用摇杆方向（已是相机相对）
		local hum = getHumanoid()
		if hum then
			move = hum.MoveDirection
		end
	else
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local fwd = Vector3.new(look.X, 0, look.Z)
		local rgt = Vector3.new(right.X, 0, right.Z)
		if fwd.Magnitude > 0 then fwd = fwd.Unit end
		if rgt.Magnitude > 0 then rgt = rgt.Unit end

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + fwd end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - fwd end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + rgt end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - rgt end
	end

	local up = mobileUp
	local down = mobileDown

	if not up then
		for _, k in ipairs(CONFIG.UpKeys) do
			if UserInputService:IsKeyDown(k) then up = true break end
		end
	end
	if not down then
		for _, k in ipairs(CONFIG.DownKeys) do
			if UserInputService:IsKeyDown(k) then down = true break end
		end
	end

	if up then move = move + Vector3.new(0, 1, 0) end
	if down then move = move - Vector3.new(0, 1, 0) end

	if move.Magnitude > 0 then
		move = move.Unit
	end

	self.BodyVelocity.Velocity = move * self.Speed
	self.BodyGyro.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
end

function Fly:Start()
	if self.Active then return end
	local root, hum = getRoot(), getHumanoid()
	if not root or not hum then return end

	hum.PlatformStand = true

	local bv = new("BodyVelocity", {
		Name = "O_X_HUB_Fly",
		MaxForce = Vector3.new(9e9, 9e9, 9e9),
		Velocity = Vector3.zero,
		Parent = root,
	})

	local bg = new("BodyGyro", {
		Name = "O_X_HUB_Gyro",
		MaxTorque = Vector3.new(9e9, 9e9, 9e9),
		P = 10000,
		D = 500,
		CFrame = root.CFrame,
		Parent = root,
	})

	self.BodyVelocity = bv
	self.BodyGyro = bg
	self.Active = true

	table.insert(self.Connections, RunService.RenderStepped:Connect(function()
		pcall(function() self:Update() end)
	end))
end

function Fly:Stop()
	if not self.Active then return end
	self.Active = false

	for _, conn in ipairs(self.Connections) do
		pcall(function() conn:Disconnect() end)
	end
	self.Connections = {}

	if self.BodyVelocity then
		pcall(function() self.BodyVelocity:Destroy() end)
		self.BodyVelocity = nil
	end
	if self.BodyGyro then
		pcall(function() self.BodyGyro:Destroy() end)
		self.BodyGyro = nil
	end

	local hum = getHumanoid()
	if hum then
		pcall(function() hum.PlatformStand = false end)
	end
end

function Fly:SetEnabled(state)
	self.Enabled = state

	if state then
		self:Start()
		if not self.Active then
			self.Enabled = false
			notify("角色未加载，无法起飞", C.Red)
			return
		end
		toggleBtn.Text = "飞行  已开启"
		toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		toggleBtn.BackgroundColor3 = C.Green
		toggleStroke.Color = C.Green
		notify("飞行已开启  ·  速度 " .. math.floor(self.Speed), C.Green)
	else
		self:Stop()
		toggleBtn.Text = "飞行  已关闭"
		toggleBtn.TextColor3 = C.Sub
		toggleBtn.BackgroundColor3 = C.Panel2
		toggleStroke.Color = C.Stroke
		notify("飞行已关闭", C.Red)
	end
end

function Fly:Toggle()
	self:SetEnabled(not self.Enabled)
end

-- 速度滑块
createSlider(panel, {
	Position = UDim2.new(0, 12, 0, 118),
	Width = 206,
	Min = 10,
	Max = CONFIG.MaxSpeed,
	Default = CONFIG.FlySpeed,
	OnChange = function(v)
		Fly.Speed = v
		speedLabel.Text = tostring(math.floor(v))
	end,
})

toggleBtn.MouseButton1Click:Connect(function()
	Fly:Toggle()
end)

-- 快捷键
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == CONFIG.FlyKey then
		Fly:Toggle()
	end
end)

-- 复活后自动恢复飞行
LocalPlayer.CharacterAdded:Connect(function()
	Fly:Stop()
	task.wait(0.8)
	if Fly.Enabled then
		Fly:Start()
	end
end)

--========================== 移动端方向键 ==========================
if UserInputService.TouchEnabled then
	local holder = new("Frame", {
		Name = "MobilePad",
		Size = UDim2.new(0, 56, 0, 124),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -24, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = guiMain,
	})

	local function mkBtn(y, text, setter)
		local btn = new("TextButton", {
			Size = UDim2.new(0, 56, 0, 56),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundColor3 = C.Panel,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = text,
			TextSize = 22,
			Font = FONT_B,
			TextColor3 = C.Text,
			Parent = holder,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })
		new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = btn })

		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				setter(true)
				btn.BackgroundColor3 = C.Accent
			end
		end)
		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				setter(false)
				btn.BackgroundColor3 = C.Panel
			end
		end)
		return btn
	end

	mkBtn(0, "▲", function(v) mobileUp = v end)
	mkBtn(68, "▼", function(v) mobileDown = v end)
end

--=====================================================================
--  四、启动流程
--=====================================================================
createLoadingScreen(function()
	guiMain.Enabled = true
	panel.Position = UDim2.new(0, 24, 0, 74)
	fadeIn(guiMain, 0.35)
	TweenService:Create(
		panel,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 24, 0, 90) }
	):Play()
	task.wait(0.15)
	notify(CONFIG.Title .. " 加载完成  ·  " .. CONFIG.Version, C.Accent)
end)
