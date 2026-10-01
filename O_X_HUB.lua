--=====================================================================
--  O_X HUB  ·  通用设置 + 飞行
--  Version : 1.2.0
--  Date    : 2026-09-27
--
--  用法（执行器里粘贴执行）：
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/hxhdsg666/O_X/refs/heads/main/O_X_HUB.lua"))()
--
--  说明：
--    · 主窗口做成软件样式：右上角 ✕ 关闭 / － 最小化成图标
--    · 左侧是功能列表：主页 / 通用（速度·跳跃·重力）/ 飞行
--    · 飞行是独立窗口，可最小化、可关闭
--    · 飞行开启后角色进入飞行状态，官方摇杆 / WASD 直接控制方向，
--      没有任何额外的升降按钮。没有输入时自动悬停，不会下坠。
--=====================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--========================== 配置区 ==========================
local CONFIG = {
	Title   = "O_X HUB",
	Version = "v1.2.0",

	-- ---------- 飞行 ----------
	FlySpeed = 60,        -- 默认飞行速度
	MinSpeed = 0.01,      -- 速度滑块下限
	MaxSpeed = 3000,      -- 速度滑块上限

	FlyKey   = Enum.KeyCode.F,                                        -- 开关飞行
	UpKeys   = { Enum.KeyCode.Space },                                -- 键盘上升
	DownKeys = { Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift },  -- 键盘下降

	-- 官方控制器 GetMoveVector 的分量符号。
	-- 如果发现前后 / 左右方向反了，把对应的值取反即可。
	MoveZSign = -1,       -- Z 分量：-1 表示"负值为前进"
	MoveXSign = 1,        -- X 分量：1 表示"正值向右"

	-- ---------- 落地保护 ----------
	-- 有掉落伤害的服务器基本都监听 Humanoid.StateChanged 的 Freefall -> Landed。
	-- 所以保护分两层：
	--   ① 缓降到底、贴地站住、速度归零之后才放开控制 —— 角色根本没进入过自由落体
	--   ② 放开控制的瞬间短暂屏蔽 Freefall 状态，兜住引擎/脚本的边界判定
	SoftLand         = true,  -- 关闭飞行时缓降，避免摔伤
	SoftLandApproach = 2.5,   -- 接近速度系数：下降速度 = 离地余量 × 这个值
	SoftLandMaxSpeed = 110,   -- 缓降最大速度（高处快速接近）
	SoftLandMinSpeed = 6,     -- 缓降最低速度（贴地前慢慢蹭）
	SoftLandGap      = 0.4,   -- 离地小于这个值就算"站稳"
	SoftLandSettle   = 0.12,  -- 站稳后等这么久（让物理速度彻底归零）再放开控制
	SoftLandTimeout  = 20,    -- 兜底：最多缓降这么久
	FallShield       = true,  -- 放开控制时短暂屏蔽 Freefall 状态
	FallShieldTime   = 0.5,   -- 屏蔽时长

	-- ---------- 图标 ----------
	-- 内联的图标会写到执行器工作目录，再用 getcustomasset 转成可用资源
	IconFile = "oxhub_icon.jpg",
}

--========================== 主题色 ==========================
-- 配色跟随图标（暗色 + 红色涂鸦），主色用红橙渐变
local C = {
	Bg      = Color3.fromRGB(10, 10, 12),
	Window  = Color3.fromRGB(18, 18, 22),
	Side    = Color3.fromRGB(14, 14, 18),
	Card    = Color3.fromRGB(26, 26, 32),
	Card2   = Color3.fromRGB(34, 34, 42),
	Stroke  = Color3.fromRGB(44, 44, 54),
	Accent  = Color3.fromRGB(226, 42, 60),
	Accent2 = Color3.fromRGB(255, 110, 30),
	Text    = Color3.fromRGB(240, 240, 245),
	Sub     = Color3.fromRGB(140, 142, 155),
	Dim     = Color3.fromRGB(95, 97, 110),
	Green   = Color3.fromRGB(34, 197, 94),
	Red     = Color3.fromRGB(239, 68, 68),
	White   = Color3.fromRGB(255, 255, 255),
}

local FONT_N = Enum.Font.GothamMedium
local FONT_B = Enum.Font.GothamBold

-- 图标资源（160x160 JPEG，base64 内联，运行时写入执行器工作目录后转成可用资源）
local ICON_B64 = [==[
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
]==]

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

-- 速度显示格式化：小数值保留小数位，避免 0.01 被显示成 0
local function fmtSpeed(v)
	if v < 1 then
		return string.format("%.2f", v)
	elseif v < 10 then
		return string.format("%.1f", v)
	end
	return string.format("%d", math.floor(v + 0.5))
end

-- 执行器注入的函数（没有就是 nil，Luau 取不存在的全局不会报错）
local EXEC = {
	writefile      = writefile,
	getcustomasset = getcustomasset,
	getsynasset    = getsynasset,
	isfile         = isfile,
	gethui         = gethui,
}

local function execFn(name)
	local v = EXEC[name]
	if type(v) == "function" then return v end
	local ok, g = pcall(function() return _G[name] end)
	if ok and type(g) == "function" then return g end
	return nil
end

-- 整体淡入
local function fadeIn(root, dur)
	local info = TweenInfo.new(dur or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			local tt = d.TextTransparency
			if tt < 1 then
				d.TextTransparency = 1
				TweenService:Create(d, info, { TextTransparency = tt }):Play()
			end
			local bt = d.BackgroundTransparency
			if bt < 1 then
				d.BackgroundTransparency = 1
				TweenService:Create(d, info, { BackgroundTransparency = bt }):Play()
			end
		elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
			local it = d.ImageTransparency
			if it < 1 then
				d.ImageTransparency = 1
				TweenService:Create(d, info, { ImageTransparency = it }):Play()
			end
			local bt = d.BackgroundTransparency
			if bt < 1 then
				d.BackgroundTransparency = 1
				TweenService:Create(d, info, { BackgroundTransparency = bt }):Play()
			end
		elseif d:IsA("Frame") or d:IsA("ScrollingFrame") then
			local bt = d.BackgroundTransparency
			if bt < 1 then
				d.BackgroundTransparency = 1
				TweenService:Create(d, info, { BackgroundTransparency = bt }):Play()
			end
		elseif d:IsA("UIStroke") then
			local st = d.Transparency
			if st < 1 then
				d.Transparency = 1
				TweenService:Create(d, info, { Transparency = st }):Play()
			end
		end
	end
end

-- 拖拽。scaleFn 用来抵消 UIScale —— 否则缩放后拖拽会"跟不上手"
local function makeDraggable(frame, handle, scaleFn)
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
			local s = 1
			if scaleFn then
				local ok, v = pcall(scaleFn)
				if ok and type(v) == "number" and v > 0 then s = v end
			end
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X / s,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y / s
			)
		end
	end)
end

-- GUI 挂载点（优先执行器的 gethui，其次 CoreGui，最后 PlayerGui）
local function getGuiParent()
	local gethuiFn = execFn("gethui")
	if gethuiFn then
		local ok, hui = pcall(gethuiFn)
		if ok and hui then return hui end
	end
	local ok2, core = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and core then return core end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local GUI_PARENT = getGuiParent()

--========================== 图标资源 ==========================
-- 把内联的 base64 图片写进执行器工作目录，再用 getcustomasset 换成可用资源。
-- 不支持的执行器会自动回退成代码绘制的 O 字 LOGO。

local B64_LOOKUP = {}
do
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	for i = 1, #chars do
		B64_LOOKUP[string.byte(chars, i)] = i - 1
	end
end

-- 纯 Lua 的 base64 解码（不依赖执行器的 base64decode）
local function b64decode(data)
	local out, n, buf = {}, 0, 0
	for i = 1, #data do
		local c = string.byte(data, i)
		if c == 61 then break end          -- '=' 结束
		local v = B64_LOOKUP[c]
		if v then
			buf = buf * 64 + v
			n = n + 1
			if n == 4 then
				out[#out + 1] = string.char(
					math.floor(buf / 65536) % 256,
					math.floor(buf / 256) % 256,
					buf % 256
				)
				n, buf = 0, 0
			end
		end
	end
	if n == 3 then
		buf = buf * 64
		out[#out + 1] = string.char(math.floor(buf / 65536) % 256, math.floor(buf / 256) % 256)
	elseif n == 2 then
		buf = buf * 64 * 64
		out[#out + 1] = string.char(math.floor(buf / 65536) % 256)
	end
	return table.concat(out)
end

local ICON_ASSET, ICON_TRIED = nil, false

local function getIconAsset()
	if ICON_TRIED then return ICON_ASSET end
	ICON_TRIED = true

	local writeFile = execFn("writefile")
	local getCustom = execFn("getcustomasset") or execFn("getsynasset")
	local isFile    = execFn("isfile")

	if not writeFile or not getCustom then
		return nil
	end

	local ok, res = pcall(function()
		local name = CONFIG.IconFile
		local need = true
		if isFile then
			local okF, has = pcall(isFile, name)
			if okF and has then need = false end
		end
		if need then
			writeFile(name, b64decode(ICON_B64))
		end
		local asset = getCustom(name)
		if type(asset) ~= "string" or asset == "" then
			error("图标资源转换失败")
		end
		return asset
	end)

	if ok and type(res) == "string" then
		ICON_ASSET = res
	end
	return ICON_ASSET
end

-- 统一的 LOGO：有图标就用图标，没有就代码画一个
local function createLogo(parent, opts)
	opts = opts or {}
	local radius = opts.Radius or 8

	local holder = new("Frame", {
		Name = "Logo",
		Size = opts.Size or UDim2.new(0, 32, 0, 32),
		Position = opts.Position,
		AnchorPoint = opts.AnchorPoint,
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = holder })

	local asset = getIconAsset()
	if asset then
		local img = new("ImageLabel", {
			Name = "LogoImage",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = asset,
			ScaleType = Enum.ScaleType.Crop,
			Parent = holder,
		})
		new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = img })
	else
		new("UIGradient", { Rotation = 45, Color = ColorSequence.new(C.Accent, C.Accent2), Parent = holder })
		new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "O",
			TextSize = opts.TextSize or 16,
			Font = FONT_B,
			TextColor3 = C.White,
			Parent = holder,
		})
	end
	return holder
end

--========================== 角色工具 ==========================
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

-- 全局飞行速度（滑块和飞行模块共用，必须早于界面定义，否则闭包会绑到全局变量上）
local flySpeed = CONFIG.FlySpeed

--========================== 滑块组件 ==========================
local function createSlider(parent, opts)
	local min, max = opts.Min or 0, opts.Max or 100
	local useLog = opts.Log and min > 0

	-- 数值 <-> 滑块位置(0~1)。对数刻度下低速段才调得动
	local function toFrac(v)
		if useLog then
			return (math.log(v) - math.log(min)) / (math.log(max) - math.log(min))
		end
		return (v - min) / (max - min)
	end

	local function fromFrac(f)
		if useLog then
			return math.exp(math.log(min) + f * (math.log(max) - math.log(min)))
		end
		return min + (max - min) * f
	end

	local hit = new("Frame", {
		Name = "SliderHit",
		Size = UDim2.new(1, 0, 0, 22),
		Position = opts.Position,
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local track = new("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = C.Card2,
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
	new("UIGradient", { Color = ColorSequence.new(C.Accent, C.Accent2), Parent = fill })

	local knob = new("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = hit,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	new("UIStroke", { Color = C.Accent, Thickness = 2, Parent = knob })

	local dragging = false

	local function setValue(v, fire)
		v = math.clamp(v, min, max)
		local frac = math.clamp(toFrac(v), 0, 1)
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
		setValue(fromFrac(rel), true)
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

--========================== 按钮组件 ==========================
local function createButton(parent, opts)
	local style = opts.Style or "ghost"
	local baseBg = C.Card
	local hoverBg = C.Card2
	if style == "primary" then
		baseBg = C.Accent
		hoverBg = Color3.fromRGB(245, 70, 88)
	end

	local btn = new("TextButton", {
		Name = opts.Name or "Button",
		Size = opts.Size,
		Position = opts.Position,
		BackgroundColor3 = baseBg,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(0, opts.Radius or 10), Parent = btn })
	local stroke = new("UIStroke", {
		Color = opts.StrokeColor or C.Stroke,
		Thickness = 1,
		Parent = btn,
	})

	local label = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = opts.Text or "",
		TextSize = opts.TextSize or 14,
		Font = opts.Font or FONT_B,
		TextColor3 = opts.TextColor or C.Text,
		Parent = btn,
	})

	btn.MouseEnter:Connect(function()
		if style ~= "primary" then
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = hoverBg }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if style ~= "primary" then
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = baseBg }):Play()
		end
	end)
	btn.MouseButton1Click:Connect(function()
		if opts.OnClick then opts.OnClick() end
	end)

	return btn, label, stroke, baseBg
end

--========================== 开关组件 ==========================
local function createSwitch(parent, opts)
	local width = 40
	local holder = new("TextButton", {
		Name = opts.Name or "Switch",
		Size = UDim2.new(0, width, 0, 22),
		Position = opts.Position,
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = holder })

	local knob = new("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		BackgroundColor3 = C.Sub,
		BorderSizePixel = 0,
		Parent = holder,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local state = opts.Default and true or false

	local function render(animate)
		local info = TweenInfo.new(animate and 0.18 or 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(holder, info, { BackgroundColor3 = state and C.Green or C.Card2 }):Play()
		TweenService:Create(knob, info, {
			Position = state and UDim2.new(0, width - 19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = state and C.White or C.Sub,
		}):Play()
	end

	holder.MouseButton1Click:Connect(function()
		state = not state
		render(true)
		if opts.OnChange then opts.OnChange(state) end
	end)

	render(false)
	return holder
end

--========================== 提示条 ==========================
-- 单独一个 ScreenGui，主窗口隐藏时提示依然能弹出来
local notifyGui = new("ScreenGui", {
	Name = "O_X_HUB_Notify",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 100001,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = GUI_PARENT,
})

local notifyHolder = new("Frame", {
	Name = "NotifyHolder",
	Size = UDim2.new(0, 300, 0, 46),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 22),
	BackgroundTransparency = 1,
	ZIndex = 50,
	Parent = notifyGui,
})

local function notify(text, color)
	local box = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(0, 0, 0, -22),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = notifyHolder,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = box })
	new("UIStroke", { Color = color or C.Accent, Thickness = 1, Parent = box })
	new("Frame", {
		Size = UDim2.new(0, 4, 1, -16),
		Position = UDim2.new(0, 6, 0, 8),
		BackgroundColor3 = color or C.Accent,
		BorderSizePixel = 0,
		ZIndex = 50,
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
		ZIndex = 50,
		Parent = box,
	})

	local info = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(box, info, { Position = UDim2.new(0, 0, 0, 0) }):Play()
	task.delay(2.4, function()
		if not box.Parent then return end
		local out = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local t1 = TweenService:Create(box, out, { Position = UDim2.new(0, 0, 0, -22) })
		t1:Play()
		t1.Completed:Wait()
		box:Destroy()
	end)
end

--=====================================================================
--  一、加载动画
--=====================================================================
-- opts = { Title, Subtitle, Stages = {{text, pct, dur}, ...} }
local function createLoadingScreen(opts, onDone)
	opts = opts or {}
	local gui = new("ScreenGui", {
		Name = "O_X_HUB_Loading",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 100000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GUI_PARENT,
	})

	local bg = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local glow = new("Frame", {
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
		Parent = glow,
	})

	local container = new("Frame", {
		Size = UDim2.new(0, 340, 0, 200),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = bg,
	})

	createLogo(container, {
		Size = UDim2.new(0, 68, 0, 68),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Radius = 20,
		TextSize = 36,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0.5, 0, 0, 80),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = opts.Title or CONFIG.Title,
		TextSize = 21,
		Font = FONT_B,
		TextColor3 = C.Text,
		Parent = container,
	})

	local status = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0.5, 0, 0, 108),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = opts.Subtitle or "正在启动...",
		TextSize = 13,
		Font = FONT_N,
		TextColor3 = C.Sub,
		Parent = container,
	})

	local track = new("Frame", {
		Size = UDim2.new(0, 300, 0, 6),
		Position = UDim2.new(0.5, 0, 0, 140),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		Parent = container,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	new("UIGradient", { Color = ColorSequence.new(C.Accent, C.Accent2), Parent = fill })

	local percent = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0.5, 0, 0, 154),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "0%",
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		Parent = container,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0.5, 0, 1, -18),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = (opts.Title or CONFIG.Title) .. "  " .. CONFIG.Version,
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = Color3.fromRGB(70, 74, 90),
		Parent = container,
	})

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

	local stages = opts.Stages or {
		{ "初始化运行环境...", 18,  0.36 },
		{ "加载核心模块...",   42,  0.44 },
		{ "注入界面组件...",   68,  0.44 },
		{ "接管移动控制...",   90,  0.34 },
		{ "启动完成",          100, 0.26 },
	}

	task.spawn(function()
		task.wait(0.15)
		for _, s in ipairs(stages) do
			status.Text = s[1]
			animateTo(s[2], s[3])
			task.wait(0.03)
		end
		task.wait(0.25)

		local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(bg, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(glow, fadeInfo, { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, fadeInfo, { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") then
				TweenService:Create(d, fadeInfo, { BackgroundTransparency = 1 }):Play()
			elseif d:IsA("ImageLabel") then
				TweenService:Create(d, fadeInfo, { ImageTransparency = 1 }):Play()
			end
		end
		task.wait(0.45)
		gui:Destroy()
		if onDone then onDone() end
	end)
end

--=====================================================================
--  二、主界面
--=====================================================================
local WIN_W, WIN_H   = 520, 380
local SIDEBAR_W      = 132
local HEADER_H       = 46

local FLY_W, FLY_H   = 380, 318

local guiMain = new("ScreenGui", {
	Name = "O_X_HUB",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 99999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Enabled = false,
	Parent = GUI_PARENT,
})

local function computeScale(w, h)
	local cam = workspace.CurrentCamera
	if not cam then return 1 end
	local vp = cam.ViewportSize
	local s = math.min(vp.X / (w + 60), vp.Y / (h + 60), 1)
	return math.clamp(s, 0.55, 1)
end

--========================== 主窗口 ==========================
local window = new("Frame", {
	Name = "Window",
	Size = UDim2.new(0, WIN_W, 0, WIN_H),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	Parent = guiMain,
})
new("UICorner", { CornerRadius = UDim.new(0, 14), Parent = window })
new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = window })

local uiScale = new("UIScale", { Scale = 1, Parent = window })

-- 顶栏
local header = new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	Parent = window,
})
new("UICorner", { CornerRadius = UDim.new(0, 14), Parent = header })
new("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 1, -14),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	Parent = header,
})
new("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.new(0, 12, 1, -1),
	BackgroundColor3 = C.Stroke,
	BorderSizePixel = 0,
	Parent = header,
})

createLogo(header, {
	Size = UDim2.new(0, 26, 0, 26),
	Position = UDim2.new(0, 14, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Radius = 8,
	TextSize = 15,
})

new("TextLabel", {
	Size = UDim2.new(0, 140, 1, 0),
	Position = UDim2.new(0, 48, 0, 0),
	BackgroundTransparency = 1,
	Text = CONFIG.Title,
	TextSize = 15,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
})

new("TextLabel", {
	Size = UDim2.new(0, 80, 1, 0),
	Position = UDim2.new(1, -116, 0, 0),
	BackgroundTransparency = 1,
	Text = CONFIG.Version,
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = header,
})

-- 最小化（缩成图标）
local minBtn = new("TextButton", {
	Name = "Minimize",
	Size = UDim2.new(0, 26, 0, 26),
	Position = UDim2.new(1, -70, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = C.Card,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "－",
	TextSize = 13,
	Font = FONT_B,
	TextColor3 = C.Sub,
	Parent = header,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = minBtn })
minBtn.MouseEnter:Connect(function()
	minBtn.BackgroundColor3 = C.Card2
	minBtn.TextColor3 = C.Text
end)
minBtn.MouseLeave:Connect(function()
	minBtn.BackgroundColor3 = C.Card
	minBtn.TextColor3 = C.Sub
end)

-- 关闭
local closeBtn = new("TextButton", {
	Name = "Close",
	Size = UDim2.new(0, 26, 0, 26),
	Position = UDim2.new(1, -40, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = C.Card,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "✕",
	TextSize = 13,
	Font = FONT_B,
	TextColor3 = C.Sub,
	Parent = header,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = closeBtn })
closeBtn.MouseEnter:Connect(function()
	closeBtn.BackgroundColor3 = C.Red
	closeBtn.TextColor3 = C.White
end)
closeBtn.MouseLeave:Connect(function()
	closeBtn.BackgroundColor3 = C.Card
	closeBtn.TextColor3 = C.Sub
end)

makeDraggable(window, header, function() return uiScale.Scale end)

-- 侧边栏
local sidebar = new("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, SIDEBAR_W, 1, -HEADER_H - 12),
	Position = UDim2.new(0, 10, 0, HEADER_H + 6),
	BackgroundColor3 = C.Side,
	BorderSizePixel = 0,
	Parent = window,
})
new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = sidebar })

new("TextLabel", {
	Size = UDim2.new(1, -16, 0, 14),
	Position = UDim2.new(0, 14, 0, 8),
	BackgroundTransparency = 1,
	Text = "功能列表",
	TextSize = 10,
	Font = FONT_B,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = sidebar,
})

-- 内容区
local content = new("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -(SIDEBAR_W + 32), 1, -HEADER_H - 12),
	Position = UDim2.new(0, SIDEBAR_W + 22, 0, HEADER_H + 6),
	BackgroundTransparency = 1,
	Parent = window,
})

--========================== 页面系统 ==========================
local pages = {}
local navItems = {}

local function addPage(key)
	local page = new("Frame", {
		Name = "Page_" .. key,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = content,
	})
	pages[key] = page
	return page
end

local function showPage(key)
	for k, page in pairs(pages) do
		page.Visible = (k == key)
	end
	for k, item in pairs(navItems) do
		if pages[k] then
			local active = (k == key)
			item.bar.BackgroundTransparency = active and 0 or 1
			item.label.TextColor3 = active and C.Text or C.Sub
			item.btn.BackgroundColor3 = active and C.Card or C.Side
		end
	end
end

local function addNav(key, text, order, onClick)
	local y = 30 + (order - 1) * 32
	local btn = new("TextButton", {
		Name = "Nav_" .. key,
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.new(0, 8, 0, y),
		BackgroundColor3 = C.Side,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = sidebar,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

	local bar = new("Frame", {
		Size = UDim2.new(0, 3, 0, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Parent = btn,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

	local label = new("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 13,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = btn,
	})

	-- 右侧小圆点（飞行开着的时候亮绿）
	local dot = new("Frame", {
		Size = UDim2.new(0, 6, 0, 6),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.Dim,
		BorderSizePixel = 0,
		Parent = btn,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

	btn.MouseButton1Click:Connect(function()
		if onClick then
			onClick()
		else
			showPage(key)
		end
	end)
	btn.MouseEnter:Connect(function()
		if not pages[key] or not pages[key].Visible then btn.BackgroundColor3 = C.Card end
	end)
	btn.MouseLeave:Connect(function()
		if not pages[key] or not pages[key].Visible then btn.BackgroundColor3 = C.Side end
	end)

	navItems[key] = { btn = btn, bar = bar, label = label, dot = dot }
	return btn
end

-- 飞行窗口的开窗函数、飞行开关（都在后面定义，这里先占位）
local openFlyWindow = function() end
local FlyToggleRequest = function() end

--========================== 主页 ==========================
local home = addPage("home")
addNav("home", "主页", 1)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 0, 6),
	BackgroundTransparency = 1,
	Text = "欢迎使用 " .. CONFIG.Title,
	TextSize = 19,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = home,
})

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 0, 0, 32),
	BackgroundTransparency = 1,
	Text = "执行器脚本合集  ·  " .. CONFIG.Version,
	TextSize = 12,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = home,
})

-- 飞行状态卡片
local flyCard = new("TextButton", {
	Name = "FlyCard",
	Size = UDim2.new(1, 0, 0, 64),
	Position = UDim2.new(0, 0, 0, 60),
	BackgroundColor3 = C.Card,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	Parent = home,
})
new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = flyCard })
local flyCardStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = flyCard })

local flyDot = new("Frame", {
	Size = UDim2.new(0, 8, 0, 8),
	Position = UDim2.new(0, 16, 0, 20),
	BackgroundColor3 = C.Dim,
	BorderSizePixel = 0,
	Parent = flyCard,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = flyDot })

new("TextLabel", {
	Size = UDim2.new(1, -100, 0, 18),
	Position = UDim2.new(0, 32, 0, 14),
	BackgroundTransparency = 1,
	Text = "飞行",
	TextSize = 15,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = flyCard,
})

new("TextLabel", {
	Size = UDim2.new(1, -100, 0, 16),
	Position = UDim2.new(0, 32, 0, 34),
	BackgroundTransparency = 1,
	Text = "官方摇杆 / WASD 直接控制  ·  自动悬停",
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = flyCard,
})

local flyCardState = new("TextLabel", {
	Size = UDim2.new(0, 70, 1, 0),
	Position = UDim2.new(1, -80, 0, 0),
	BackgroundTransparency = 1,
	Text = "已关闭",
	TextSize = 12,
	Font = FONT_B,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = flyCard,
})

flyCard.MouseEnter:Connect(function() flyCard.BackgroundColor3 = C.Card2 end)
flyCard.MouseLeave:Connect(function() flyCard.BackgroundColor3 = C.Card end)
flyCard.MouseButton1Click:Connect(function() openFlyWindow() end)

-- 通用设置卡片
local genCard = new("TextButton", {
	Name = "GeneralCard",
	Size = UDim2.new(1, 0, 0, 64),
	Position = UDim2.new(0, 0, 0, 132),
	BackgroundColor3 = C.Card,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	Parent = home,
})
new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = genCard })
new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = genCard })

new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 18),
	Position = UDim2.new(0, 16, 0, 14),
	BackgroundTransparency = 1,
	Text = "通用",
	TextSize = 15,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = genCard,
})
new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 16),
	Position = UDim2.new(0, 16, 0, 34),
	BackgroundTransparency = 1,
	Text = "移动速度  ·  跳跃高度  ·  重力",
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = genCard,
})
genCard.MouseEnter:Connect(function() genCard.BackgroundColor3 = C.Card2 end)
genCard.MouseLeave:Connect(function() genCard.BackgroundColor3 = C.Card end)
genCard.MouseButton1Click:Connect(function() showPage("general") end)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 0, 208),
	BackgroundTransparency = 1,
	Text = "左侧切换功能页。飞行是独立窗口，可以单独最小化或关闭。",
	TextSize = 12,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Parent = home,
})

--========================== 通用设置 ==========================
local general = addPage("general")
addNav("general", "通用", 2)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0, 4),
	BackgroundTransparency = 1,
	Text = "通用设置",
	TextSize = 17,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = general,
})

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 0, 26),
	BackgroundTransparency = 1,
	Text = "改动立即生效，复活后自动重新应用",
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = general,
})

-- 一行设置 = 标题 + 数值 + 滑块
local function addSettingRow(y, opts)
	new("TextLabel", {
		Size = UDim2.new(1, -80, 0, 16),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundTransparency = 1,
		Text = opts.Label,
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = general,
	})

	local valueLabel = new("TextLabel", {
		Size = UDim2.new(0, 80, 0, 16),
		Position = UDim2.new(1, -80, 0, y),
		BackgroundTransparency = 1,
		Text = opts.Format(opts.Default),
		TextSize = 12,
		Font = FONT_B,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = general,
	})

	local setValue = createSlider(general, {
		Position = UDim2.new(0, 0, 0, y + 20),
		Min = opts.Min,
		Max = opts.Max,
		Default = opts.Default,
		Log = opts.Log,
		OnChange = function(v)
			valueLabel.Text = opts.Format(v)
			opts.OnChange(v)
		end,
	})

	return setValue, valueLabel
end

-- 角色属性（nil = 不覆盖）
local Settings = {
	WalkSpeed = nil,
	JumpPower = nil,
	Gravity   = nil,
}

local function applySettings()
	local hum = getHumanoid()
	if hum then
		if Settings.WalkSpeed then
			pcall(function() hum.WalkSpeed = Settings.WalkSpeed end)
		end
		if Settings.JumpPower then
			pcall(function()
				hum.UseJumpPower = true
				hum.JumpPower = Settings.JumpPower
			end)
		end
	end
	if Settings.Gravity then
		pcall(function() workspace.Gravity = Settings.Gravity end)
	end
end

-- 读当前值做滑块默认值
local function currentWalk()
	local hum = getHumanoid()
	local ok, v = pcall(function() return hum.WalkSpeed end)
	if ok and type(v) == "number" then return v end
	return 16
end
local function currentJump()
	local hum = getHumanoid()
	local ok, v = pcall(function() return hum.JumpPower end)
	if ok and type(v) == "number" and v > 0 then return v end
	return 50
end
local function currentGravity()
	local ok, v = pcall(function() return workspace.Gravity end)
	if ok and type(v) == "number" then return v end
	return 196.2
end

local walkDef, jumpDef, gravDef = currentWalk(), currentJump(), currentGravity()

local setWalk, walkLabel = addSettingRow(52, {
	Label = "移动速度",
	Min = 8, Max = 500,
	Default = math.clamp(walkDef, 8, 500),
	Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
	OnChange = function(v)
		Settings.WalkSpeed = v
		applySettings()
	end,
})

local setJump, jumpLabel = addSettingRow(108, {
	Label = "跳跃高度",
	Min = 0, Max = 500,
	Default = math.clamp(jumpDef, 0, 500),
	Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
	OnChange = function(v)
		Settings.JumpPower = v
		applySettings()
	end,
})

local setGrav, gravLabel = addSettingRow(164, {
	Label = "重力",
	Min = 0, Max = 500,
	Default = math.clamp(gravDef, 0, 500),
	Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
	OnChange = function(v)
		Settings.Gravity = v
		applySettings()
	end,
})

new("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 0, 222),
	BackgroundColor3 = C.Stroke,
	BorderSizePixel = 0,
	Parent = general,
})

local resetBtn, resetLabel = createButton(general, {
	Name = "ResetSettings",
	Size = UDim2.new(0, 96, 0, 30),
	Position = UDim2.new(0, 0, 0, 236),
	Text = "恢复默认",
	TextSize = 12,
	Radius = 8,
	OnClick = function()
		setWalk(16)
		setJump(50)
		setGrav(196)
		Settings.WalkSpeed = 16
		Settings.JumpPower = 50
		Settings.Gravity = 196
		applySettings()
		notify("已恢复默认属性", C.Accent)
	end,
})

new("TextLabel", {
	Size = UDim2.new(1, -110, 0, 30),
	Position = UDim2.new(0, 106, 0, 236),
	BackgroundTransparency = 1,
	Text = "重力改动影响整个服务器画面，慎调",
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextWrapped = true,
	Parent = general,
})

--========================== 飞行（独立窗口） ==========================
local flyNavBtn = addNav("fly", "飞行", 3, function() openFlyWindow() end)

local flyWin = new("Frame", {
	Name = "FlyWindow",
	Size = UDim2.new(0, FLY_W, 0, FLY_H),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	Visible = false,
	Parent = guiMain,
})
new("UICorner", { CornerRadius = UDim.new(0, 14), Parent = flyWin })
new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = flyWin })

local flyScale = new("UIScale", { Scale = 1, Parent = flyWin })

-- 飞行窗口顶栏
local flyHeader = new("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	Parent = flyWin,
})
new("UICorner", { CornerRadius = UDim.new(0, 14), Parent = flyHeader })
new("Frame", {
	Size = UDim2.new(1, 0, 0, 12),
	Position = UDim2.new(0, 0, 1, -12),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	Parent = flyHeader,
})
new("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.new(0, 12, 1, -1),
	BackgroundColor3 = C.Stroke,
	BorderSizePixel = 0,
	Parent = flyHeader,
})

createLogo(flyHeader, {
	Size = UDim2.new(0, 22, 0, 22),
	Position = UDim2.new(0, 14, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Radius = 7,
	TextSize = 13,
})

new("TextLabel", {
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(0, 44, 0, 0),
	BackgroundTransparency = 1,
	Text = "O_X 飞行",
	TextSize = 14,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = flyHeader,
})

local flyWinState = new("TextLabel", {
	Size = UDim2.new(0, 64, 1, 0),
	Position = UDim2.new(1, -128, 0, 0),
	BackgroundTransparency = 1,
	Text = "已停止",
	TextSize = 11,
	Font = FONT_B,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = flyHeader,
})

local flyMinBtn = new("TextButton", {
	Name = "Minimize",
	Size = UDim2.new(0, 24, 0, 24),
	Position = UDim2.new(1, -66, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = C.Card,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "－",
	TextSize = 12,
	Font = FONT_B,
	TextColor3 = C.Sub,
	Parent = flyHeader,
})
new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = flyMinBtn })
flyMinBtn.MouseEnter:Connect(function()
	flyMinBtn.BackgroundColor3 = C.Card2
	flyMinBtn.TextColor3 = C.Text
end)
flyMinBtn.MouseLeave:Connect(function()
	flyMinBtn.BackgroundColor3 = C.Card
	flyMinBtn.TextColor3 = C.Sub
end)

local flyCloseBtn = new("TextButton", {
	Name = "Close",
	Size = UDim2.new(0, 24, 0, 24),
	Position = UDim2.new(1, -38, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = C.Card,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "✕",
	TextSize = 12,
	Font = FONT_B,
	TextColor3 = C.Sub,
	Parent = flyHeader,
})
new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = flyCloseBtn })
flyCloseBtn.MouseEnter:Connect(function()
	flyCloseBtn.BackgroundColor3 = C.Red
	flyCloseBtn.TextColor3 = C.White
end)
flyCloseBtn.MouseLeave:Connect(function()
	flyCloseBtn.BackgroundColor3 = C.Card
	flyCloseBtn.TextColor3 = C.Sub
end)

makeDraggable(flyWin, flyHeader, function() return flyScale.Scale end)

-- 飞行窗口内容
local flyBody = new("Frame", {
	Size = UDim2.new(1, -32, 1, -42 - 14),
	Position = UDim2.new(0, 16, 0, 42 + 6),
	BackgroundTransparency = 1,
	Parent = flyWin,
})

local flyToggle, flyToggleLabel, flyToggleStroke = createButton(flyBody, {
	Name = "FlyToggle",
	Size = UDim2.new(1, 0, 0, 42),
	Position = UDim2.new(0, 0, 0, 4),
	Text = "开启飞行",
	TextSize = 15,
	Style = "primary",
	TextColor3 = C.White,
	StrokeColor = C.Accent,
	OnClick = function()
		FlyToggleRequest()
	end,
})

new("TextLabel", {
	Size = UDim2.new(0, 120, 0, 16),
	Position = UDim2.new(0, 0, 0, 58),
	BackgroundTransparency = 1,
	Text = "飞行速度",
	TextSize = 12,
	Font = FONT_N,
	TextColor3 = C.Sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = flyBody,
})

local speedLabel = new("TextLabel", {
	Size = UDim2.new(0, 100, 0, 16),
	Position = UDim2.new(1, -100, 0, 58),
	BackgroundTransparency = 1,
	Text = fmtSpeed(CONFIG.FlySpeed),
	TextSize = 12,
	Font = FONT_B,
	TextColor3 = C.Accent,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = flyBody,
})

createSlider(flyBody, {
	Position = UDim2.new(0, 0, 0, 80),
	Min = CONFIG.MinSpeed,
	Max = CONFIG.MaxSpeed,
	Default = CONFIG.FlySpeed,
	Log = true,   -- 对数刻度：0.01 ~ 3000 跨 5 个数量级，线性滑块够不到低速段
	OnChange = function(v)
		flySpeed = v
		speedLabel.Text = fmtSpeed(v)
	end,
})

new("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 0, 112),
	BackgroundColor3 = C.Stroke,
	BorderSizePixel = 0,
	Parent = flyBody,
})

new("TextLabel", {
	Size = UDim2.new(1, -60, 0, 16),
	Position = UDim2.new(0, 0, 0, 124),
	BackgroundTransparency = 1,
	Text = "落地保护",
	TextSize = 12,
	Font = FONT_N,
	TextColor3 = C.Sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = flyBody,
})

createSwitch(flyBody, {
	Name = "SoftLand",
	Position = UDim2.new(1, -40, 0, 121),
	Default = CONFIG.SoftLand,
	OnChange = function(v)
		CONFIG.SoftLand = v
	end,
})

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 0, 144),
	BackgroundTransparency = 1,
	Text = "关飞行后缓降贴地才放手，不会被判定摔伤",
	TextSize = 11,
	Font = FONT_N,
	TextColor3 = C.Dim,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = flyBody,
})

new("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 0, 166),
	BackgroundColor3 = C.Stroke,
	BorderSizePixel = 0,
	Parent = flyBody,
})

local hints = {
	{ "手机", "摇杆控制方向，滑动屏幕转向；抬头 + 前进即上升" },
	{ "电脑", "WASD 移动  ·  空格上升  ·  Ctrl / Shift 下降" },
	{ "开关", "按 F 键，或点上面的按钮" },
}
for i, h in ipairs(hints) do
	local y = 178 + (i - 1) * 22
	new("TextLabel", {
		Size = UDim2.new(0, 34, 0, 16),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundTransparency = 1,
		Text = h[1],
		TextSize = 11,
		Font = FONT_B,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyBody,
	})
	new("TextLabel", {
		Size = UDim2.new(1, -40, 0, 16),
		Position = UDim2.new(0, 40, 0, y),
		BackgroundTransparency = 1,
		Text = h[2],
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyBody,
	})
end

-- 飞行窗口的启动动画（O_X 飞行）
local flySplash = new("Frame", {
	Name = "FlySplash",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	ZIndex = 30,
	Visible = false,
	Parent = flyWin,
})
new("UICorner", { CornerRadius = UDim.new(0, 14), Parent = flySplash })

local splashLogo = createLogo(flySplash, {
	Size = UDim2.new(0, 52, 0, 52),
	Position = UDim2.new(0.5, 0, 0.5, -34),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Radius = 15,
	TextSize = 26,
})
splashLogo.ZIndex = 31

local splashTitle = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0.5, 0, 0.5, 14),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Text = "O_X 飞行",
	TextSize = 16,
	Font = FONT_B,
	TextColor3 = C.Text,
	ZIndex = 31,
	Parent = flySplash,
})

local splashBarBg = new("Frame", {
	Size = UDim2.new(0, 150, 0, 4),
	Position = UDim2.new(0.5, 0, 0.5, 42),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = C.Card2,
	BorderSizePixel = 0,
	ZIndex = 31,
	Parent = flySplash,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = splashBarBg })

local splashBar = new("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
	ZIndex = 31,
	Parent = splashBarBg,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = splashBar })
new("UIGradient", { Color = ColorSequence.new(C.Accent, C.Accent2), Parent = splashBar })

local splashBusy = false
local function playFlySplash()
	if splashBusy then return end
	splashBusy = true
	flySplash.Visible = true
	flySplash.BackgroundTransparency = 0
	splashBar.Size = UDim2.new(0, 0, 1, 0)
	splashTitle.TextTransparency = 0
	splashLogo.Visible = true

	task.spawn(function()
		TweenService:Create(
			splashBar,
			TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(1, 0, 1, 0) }
		):Play()
		task.wait(0.5)

		local fade = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(flySplash, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(splashTitle, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(splashLogo, fade, { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(splashLogo:GetDescendants()) do
			if d:IsA("ImageLabel") then
				TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
			elseif d:IsA("TextLabel") then
				TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") then
				TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
			end
		end
		for _, d in ipairs(splashBarBg:GetDescendants()) do
			if d:IsA("Frame") then
				TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
			end
		end
		TweenService:Create(splashBarBg, fade, { BackgroundTransparency = 1 }):Play()

		task.wait(0.26)
		flySplash.Visible = false
		flySplash.BackgroundTransparency = 0
		splashTitle.TextTransparency = 0
		splashLogo.BackgroundTransparency = 0
		splashBarBg.BackgroundTransparency = 0
		splashBar.BackgroundTransparency = 0
		for _, d in ipairs(splashLogo:GetDescendants()) do
			if d:IsA("ImageLabel") then d.ImageTransparency = 0
			elseif d:IsA("TextLabel") then d.TextTransparency = 0 end
		end
		splashBusy = false
	end)
end

--========================== 悬浮图标（最小化后） ==========================
local reopen = new("TextButton", {
	Name = "Reopen",
	Size = UDim2.new(0, 46, 0, 46),
	Position = UDim2.new(0, 20, 0, 96),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	Parent = guiMain,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = reopen })
new("UIStroke", { Color = C.Accent2, Thickness = 1, Parent = reopen })
local reopenScale = new("UIScale", { Scale = 1, Parent = reopen })

do
	local asset = getIconAsset()
	if asset then
		local img = new("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = asset,
			ScaleType = Enum.ScaleType.Crop,
			Parent = reopen,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = img })
	else
		new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "O",
			TextSize = 19,
			Font = FONT_B,
			TextColor3 = C.White,
			Parent = reopen,
		})
	end
end

-- 飞行窗口最小化后的悬浮胶囊
local flyReopen = new("TextButton", {
	Name = "FlyReopen",
	Size = UDim2.new(0, 78, 0, 32),
	Position = UDim2.new(0, 20, 0, 152),
	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	Parent = guiMain,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = flyReopen })
new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = flyReopen })
local flyReopenScale = new("UIScale", { Scale = 1, Parent = flyReopen })

local flyReopenDot = new("Frame", {
	Size = UDim2.new(0, 7, 0, 7),
	Position = UDim2.new(0, 12, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = C.Dim,
	BorderSizePixel = 0,
	Parent = flyReopen,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = flyReopenDot })
new("TextLabel", {
	Size = UDim2.new(1, -28, 1, 0),
	Position = UDim2.new(0, 24, 0, 0),
	BackgroundTransparency = 1,
	Text = "飞行",
	TextSize = 12,
	Font = FONT_B,
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = flyReopen,
})

local function updateScale()
	uiScale.Scale = computeScale(WIN_W, WIN_H)
	flyScale.Scale = computeScale(FLY_W, FLY_H)
	if reopen.Visible then reopenScale.Scale = uiScale.Scale end
	if flyReopen.Visible then flyReopenScale.Scale = flyScale.Scale end
end
updateScale()

--========================== 窗口显隐 ==========================
local function hideMain(collapse)
	window.Visible = false
	reopen.Visible = true
	reopenScale.Scale = collapse and 0.4 or uiScale.Scale
	TweenService:Create(
		reopenScale,
		TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = uiScale.Scale }
	):Play()
end

local function showMain()
	reopen.Visible = false
	window.Visible = true
	window.Size = UDim2.new(0, WIN_W, 0, WIN_H)
	uiScale.Scale = math.clamp(uiScale.Scale * 0.9, 0.5, 1)
	TweenService:Create(
		uiScale,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = computeScale(WIN_W, WIN_H) }
	):Play()
end

minBtn.MouseButton1Click:Connect(function() hideMain(true) end)
closeBtn.MouseButton1Click:Connect(function() hideMain(false) end)
reopen.MouseButton1Click:Connect(function() showMain() end)

local function hideFly()
	flyWin.Visible = false
	flyReopen.Visible = true
	flyReopenScale.Scale = 0.4
	TweenService:Create(
		flyReopenScale,
		TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = flyScale.Scale }
	):Play()
end

openFlyWindow = function()
	if flyWin.Visible then
		flyWin.Visible = true
		return
	end
	flyReopen.Visible = false
	flyWin.Visible = true
	flyScale.Scale = math.clamp(flyScale.Scale * 0.9, 0.5, 1)
	TweenService:Create(
		flyScale,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = computeScale(FLY_W, FLY_H) }
	):Play()
	playFlySplash()
end

flyMinBtn.MouseButton1Click:Connect(function() hideFly() end)
flyCloseBtn.MouseButton1Click:Connect(function() hideFly() end)
flyReopen.MouseButton1Click:Connect(function() openFlyWindow() end)

showPage("home")

--=====================================================================
--  三、飞行模块
--=====================================================================
local Fly = {
	Enabled        = false,   -- 用户意图（复活后据此恢复）
	Active         = false,   -- 运行态
	BodyVelocity   = nil,
	BodyGyro       = nil,
	Connections    = {},
	CancelSoftLand = nil,     -- 缓降的取消函数（重新起飞 / 复活时用）
}

-- 读取官方移动输入。
-- 关键点：PlatformStand = true 之后 Humanoid.MoveDirection 恒为 0，
-- 必须从 PlayerModule 的控制器层拿原始输入 —— 摇杆 / WASD / 手柄都走这里。
local _controls = nil
local function getControls()
	if _controls ~= nil then
		if _controls == false then return nil end
		return _controls
	end
	local ok, controls = pcall(function()
		local playerScripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
		if not playerScripts then return nil end
		local playerModule = require(playerScripts:WaitForChild("PlayerModule", 10))
		return playerModule:GetControls()
	end)
	_controls = (ok and controls) or false
	if _controls == false then return nil end
	return _controls
end

local function readMoveInput()
	local controls = getControls()
	if controls then
		local ok, mv = pcall(function() return controls:GetMoveVector() end)
		if ok and typeof(mv) == "Vector3" and mv.Magnitude > 0.01 then
			return mv
		end
	end

	-- 兜底：直接读键盘（PlayerModule 取不到时）
	local x, z = 0, 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then z = z - 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then z = z + 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then x = x + 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then x = x - 1 end
	return Vector3.new(x, 0, z)
end

local function anyKeyDown(keys)
	for _, k in ipairs(keys) do
		if UserInputService:IsKeyDown(k) then return true end
	end
	return false
end

-- 向下打射线，返回离地高度
local _rayParams = nil
local function getGroundDistance(root)
	local ok, dist = pcall(function()
		if not _rayParams then
			_rayParams = RaycastParams.new()
			local okE, exclude = pcall(function() return Enum.RaycastFilterType.Exclude end)
			_rayParams.FilterType = okE and exclude or Enum.RaycastFilterType.Blacklist
			_rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
		end
		local result = workspace:Raycast(root.Position, Vector3.new(0, -600, 0), _rayParams)
		if result then
			return (root.Position - result.Position).Magnitude
		end
		return math.huge
	end)
	if ok and typeof(dist) == "number" then
		return dist
	end
	return math.huge
end

-- 角色"站稳时" root 中心离地多高 = 脚底到 root 的距离。
-- 缓降到这个高度再放开控制，角色就是站着而不是掉下来。
local function getFootOffset(root)
	local char = root.Parent
	if not char then return 3 end

	local lowest = root.Position.Y
	pcall(function()
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				local bottom = d.Position.Y - d.Size.Y * 0.5
				if bottom < lowest then lowest = bottom end
			end
		end
	end)

	local off = root.Position.Y - lowest
	-- 姿态异常（躺地上、挂在墙上）时给个保守值
	if off < 0.5 or off > 12 then return 3 end
	return off
end

-- 短暂屏蔽 Freefall 状态。
-- 引擎的 StateChanged 不会再抛 Freefall -> Landed，靠状态判定摔伤的服务器就抓不到。
local function setFallShield(hum, on)
	if not CONFIG.FallShield then return end
	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, not on)
	end)
end

function Fly:BuildMovers(root)
	if self.BodyVelocity then
		pcall(function() self.BodyVelocity:Destroy() end)
	end
	if self.BodyGyro then
		pcall(function() self.BodyGyro:Destroy() end)
	end

	self.BodyVelocity = new("BodyVelocity", {
		Name = "O_X_HUB_Fly",
		MaxForce = Vector3.new(9e9, 9e9, 9e9),
		Velocity = Vector3.zero,
		Parent = root,
	})

	self.BodyGyro = new("BodyGyro", {
		Name = "O_X_HUB_Gyro",
		MaxTorque = Vector3.new(9e9, 9e9, 9e9),
		P = 10000,
		D = 500,
		CFrame = root.CFrame,
		Parent = root,
	})
end

function Fly:Update()
	local root = getRoot()
	if not root then return end

	-- 抗反作弊：移动器被游戏删掉就重建
	if not self.BodyVelocity or not self.BodyVelocity.Parent
		or not self.BodyGyro or not self.BodyGyro.Parent then
		self:BuildMovers(root)
	end

	local cam = workspace.CurrentCamera
	if not cam then return end
	local camCF = cam.CFrame

	local mv = readMoveInput()
	local dir = Vector3.zero

	if mv.Magnitude > 0.01 then
		-- mv.X = 左右，mv.Z = 前后
		-- 用相机的 LookVector 而不是水平投影：抬头前进即上升，符合"飞行状态"的直觉
		dir = (camCF.LookVector * (mv.Z * CONFIG.MoveZSign))
			+ (camCF.RightVector * (mv.X * CONFIG.MoveXSign))
		if dir.Magnitude > 0 then
			dir = dir.Unit
		end
	end

	-- 键盘垂直微调
	if anyKeyDown(CONFIG.UpKeys) then
		dir = dir + Vector3.new(0, 1, 0)
	end
	if anyKeyDown(CONFIG.DownKeys) then
		dir = dir - Vector3.new(0, 1, 0)
	end

	if dir.Magnitude > 0 then
		dir = dir.Unit
	end

	-- dir 为零向量时速度归零 = 悬停，重力被抵消，不会下坠
	self.BodyVelocity.Velocity = dir * flySpeed
	self.BodyGyro.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
end

function Fly:Start()
	if self.Active then return end
	local root, hum = getRoot(), getHumanoid()
	if not root or not hum then return end

	-- 还在缓降就直接打断，重新起飞
	if self.CancelSoftLand then
		local cancel = self.CancelSoftLand
		self.CancelSoftLand = nil
		pcall(cancel)
	end

	hum.PlatformStand = true
	setFallShield(hum, false)   -- 飞行中恢复 Freefall，不然角色状态机不自然
	self:BuildMovers(root)
	self.Active = true

	-- 预热官方控制器，避免第一次 RenderStepped 里才发现要 WaitForChild
	getControls()

	table.insert(self.Connections, RunService.RenderStepped:Connect(function()
		pcall(function() self:Update() end)
	end))
end

--=====================================================================
--  缓降落地
--  目标：放开控制的那一刻，角色是"已经站在地上、速度为零"的状态，
--  全程不产生 Freefall -> Landed 的状态转换，靠状态判定摔伤的服务器抓不到。
--=====================================================================
function Fly:SoftLand(root, hum)
	local bv = new("BodyVelocity", {
		Name = "O_X_HUB_Land",
		MaxForce = Vector3.new(9e9, 9e9, 9e9),
		Velocity = Vector3.zero,
		Parent = root,
	})

	local footOffset = getFootOffset(root)
	local t0         = os.clock()
	local settleAt   = nil
	local finished   = false

	-- 离得远就快、贴近了就慢，既快又不会砸下去
	local function descendSpeed(gap)
		return math.clamp(gap * CONFIG.SoftLandApproach, CONFIG.SoftLandMinSpeed, CONFIG.SoftLandMaxSpeed)
	end

	-- 立刻给初速度，别干等第一帧 Heartbeat 才动
	local startGap = getGroundDistance(root) - footOffset
	if startGap > CONFIG.SoftLandGap then
		bv.Velocity = Vector3.new(0, -descendSpeed(startGap), 0)
	end

	-- 离得远才提示，贴地那种一两秒就完事，不用打扰
	if startGap > 25 then
		notify("缓降中  ·  落地后自动交回操作", C.Accent)
	end

	local conn
	local function finish()
		if finished then return end
		finished = true
		Fly.CancelSoftLand = nil

		if conn then pcall(function() conn:Disconnect() end) end
		pcall(function() bv:Destroy() end)

		if hum and hum.Parent then
			-- 只有确实贴地才屏蔽 Freefall，否则宁可让它正常掉
			local grounded = false
			if root and root.Parent then
				grounded = getGroundDistance(root) - footOffset <= CONFIG.SoftLandGap + 2
			end
			if grounded then setFallShield(hum, true) end
			pcall(function() hum.PlatformStand = false end)
			if grounded then
				task.delay(CONFIG.FallShieldTime, function()
					if hum and hum.Parent then
						setFallShield(hum, false)
					end
				end)
			end
		end
	end
	self.CancelSoftLand = finish

	conn = RunService.Heartbeat:Connect(function()
		if finished then return end

		-- 角色没了 / 复活了
		if not root.Parent or not hum or not hum.Parent then
			finished = true
			Fly.CancelSoftLand = nil
			pcall(function() conn:Disconnect() end)
			pcall(function() bv:Destroy() end)
			if hum then setFallShield(hum, false) end
			return
		end

		-- 兜底：万一一直探不到地面（掉出地图、站在不可见碰撞上等）
		if os.clock() - t0 > CONFIG.SoftLandTimeout then
			finish()
			return
		end

		local gap = getGroundDistance(root) - footOffset

		if gap <= CONFIG.SoftLandGap then
			-- 已经贴地：速度彻底归零，等物理稳定下来再放手
			bv.Velocity = Vector3.zero
			if not settleAt then
				settleAt = os.clock()
			elseif os.clock() - settleAt >= CONFIG.SoftLandSettle then
				finish()
			end
		else
			settleAt = nil
			bv.Velocity = Vector3.new(0, -descendSpeed(gap), 0)
		end
	end)
end

function Fly:Stop(useSoftLand)
	local root, hum = getRoot(), getHumanoid()

	-- 上一轮缓降还没结束就先掐掉
	if self.CancelSoftLand then
		local cancel = self.CancelSoftLand
		self.CancelSoftLand = nil
		pcall(cancel)
	end

	if self.Active then
		for _, conn in ipairs(self.Connections) do
			pcall(function() conn:Disconnect() end)
		end
		self.Connections = {}
		self.Active = false
	end

	if self.BodyVelocity then
		pcall(function() self.BodyVelocity:Destroy() end)
		self.BodyVelocity = nil
	end
	if self.BodyGyro then
		pcall(function() self.BodyGyro:Destroy() end)
		self.BodyGyro = nil
	end

	if not hum then return end

	local gap = math.huge
	if root and root.Parent then
		gap = getGroundDistance(root) - getFootOffset(root)
	end

	if useSoftLand and CONFIG.SoftLand and gap > CONFIG.SoftLandGap then
		-- 高空：走缓降流程
		Fly:SoftLand(root, hum)
		return
	end

	-- 本来就在地上：直接放手。只在确实贴地时才屏蔽 Freefall，
	-- 免得玩家主动关掉保护从高空跳下去时角色反而卡在空中
	local grounded = gap <= CONFIG.SoftLandGap + 2
	if grounded then setFallShield(hum, true) end
	pcall(function() hum.PlatformStand = false end)
	if grounded then
		task.delay(CONFIG.FallShieldTime, function()
			if hum and hum.Parent then setFallShield(hum, false) end
		end)
	end
end

-- 状态同步到所有界面元素
local function syncFlyUI()
	local on = Fly.Enabled

	flyDot.BackgroundColor3 = on and C.Green or C.Dim
	flyCardState.Text = on and "已开启" or "已关闭"
	flyCardState.TextColor3 = on and C.Green or C.Dim
	flyCardStroke.Color = on and C.Green or C.Stroke

	navItems.fly.dot.BackgroundColor3 = on and C.Green or C.Dim
	flyReopenDot.BackgroundColor3 = on and C.Green or C.Dim

	flyToggleLabel.Text = on and "关闭飞行" or "开启飞行"
	flyToggle.BackgroundColor3 = on and C.Green or C.Accent
	flyToggleStroke.Color = on and C.Green or C.Accent
	flyWinState.Text = on and "飞行中" or "已停止"
	flyWinState.TextColor3 = on and C.Green or C.Dim
end

function Fly:SetEnabled(state)
	self.Enabled = state

	if state then
		self:Start()
		if not self.Active then
			self.Enabled = false
			syncFlyUI()
			notify("角色未加载，无法起飞", C.Red)
			return
		end
		syncFlyUI()
		notify("飞行已开启  ·  速度 " .. fmtSpeed(flySpeed), C.Green)
	else
		self:Stop(true)
		syncFlyUI()
		notify("飞行已关闭", C.Red)
	end
end

function Fly:Toggle()
	self:SetEnabled(not self.Enabled)
end

-- 接上界面按钮的回调（FlyToggleRequest 在前面已 forward declare）
FlyToggleRequest = function()
	Fly:Toggle()
end

syncFlyUI()

-- 快捷键
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == CONFIG.FlyKey then
		Fly:Toggle()
	end
end)

-- 复活后自动恢复飞行 + 重新应用通用属性
LocalPlayer.CharacterAdded:Connect(function()
	Fly:Stop(false)
	task.wait(0.8)
	applySettings()
	if Fly.Enabled then
		Fly:Start()
	end
end)

-- 相机重建时重算缩放
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.wait(0.2)
	updateScale()
end)

--=====================================================================
--  四、启动流程
--=====================================================================
createLoadingScreen(nil, function()
	applySettings()
	guiMain.Enabled = true
	fadeIn(guiMain, 0.35)
	uiScale.Scale = math.clamp(computeScale(WIN_W, WIN_H) * 0.88, 0.5, 1)
	TweenService:Create(
		uiScale,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = computeScale(WIN_W, WIN_H) }
	):Play()
	task.wait(0.15)
	notify(CONFIG.Title .. " 加载完成  ·  " .. CONFIG.Version, C.Accent)
end)
