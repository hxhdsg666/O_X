--=====================================================================
--  O_X HUB  ·  通用设置 + 飞行
--  Version : 1.4.1
--  Date    : 2026-10-01
--
--  用法（执行器里粘贴执行）：
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/hxhdsg666/O_X/refs/heads/main/O_X_HUB.lua"))()
--
--  说明：
--    · 注入后第一屏是语言选择（英文 / 中文），选完才进加载动画
--    · 界面文案跟随所选语言；只有 "O_X HUB" 这个名字两种语言都不翻译
--    · 主窗口做成软件样式：右上角 － 最小化成图标 / ✕ 结束整个脚本
--    · 左侧是功能列表：主页 / 通用（速度·跳跃·重力）/ 飞行 / 设置
--    · 设置页：联系作者（点一下复制邮箱）+ 语言切换（切换后脚本重启）
--    · 主窗口、飞行窗口、悬浮图标都可以拖动移动
--    · 飞行是独立窗口：－ 收成胶囊，✕ 只结束飞行
--    · 飞行开启后角色进入飞行状态，官方摇杆 / WASD 直接控制方向，
--      没有任何额外的升降按钮。没有输入时自动悬停，不会下坠。
--    · 伤害保护：飞行中把角色速度回零（服务端读到的速度恒为 0），
--      撞到东西、落地都不会掉血；关飞行时缓降到贴地才放手。
--=====================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 已经加载过就先卸掉上一份，避免重复执行时叠出两套界面 / 两套连接
if _G.O_X_HUB_LOADED then
	pcall(_G.O_X_HUB_LOADED, true)
end

--========================== 语言包 ==========================
-- 约定：`O_X HUB` 这个名字两种语言都不翻译，所以它不放进语言包。
-- 英文模式下界面上不允许出现任何中文（有断言在测）。
local LOCALES = {
	zh = {
		-- 加载动画
		loading      = "正在启动...",
		boot1        = "初始化运行环境...",
		boot2        = "加载核心模块...",
		boot3        = "注入界面组件...",
		boot4        = "接管移动控制...",
		boot5        = "启动完成",
		loaded       = "%s 加载完成  ·  %s",

		-- 侧栏
		navGroup     = "功能列表",
		navHome      = "主页",
		navGeneral   = "通用",
		navFly       = "飞行",
		navSettings  = "设置",

		-- 主页
		homeWelcome  = "欢迎使用 %s",
		homeSub      = "执行器脚本合集  ·  %s",
		cardFlyTitle = "飞行",
		cardFlyDesc  = "官方摇杆 / WASD 直接控制  ·  自动悬停",
		cardGenTitle = "通用",
		cardGenDesc  = "移动速度  ·  跳跃高度  ·  重力",
		homeHint     = "左侧切换功能页。飞行是独立窗口，可以单独最小化或关闭。",

		-- 通用设置
		genTitle     = "通用设置",
		genSub       = "改动立即生效，复活后自动重新应用",
		walkSpeed    = "移动速度",
		jumpPower    = "跳跃高度",
		gravity      = "重力",
		resetBtn     = "恢复默认",
		resetDone    = "已恢复默认属性",
		gravityWarn  = "重力改动影响整个服务器画面，慎调",

		-- 飞行窗口
		flyTitle     = "O_X 飞行",
		flyStopped   = "已停止",
		flyFlying    = "飞行中",
		flyOn        = "开启飞行",
		flyOff       = "关闭飞行",
		flySpeed     = "飞行速度",
		shieldTitle  = "伤害保护",
		shieldDesc   = "速度回零：撞到东西、落地都不掉血",
		softTitle    = "落地缓降",
		softDesc     = "关飞行后缓降到贴地才放手",
		hintMobile   = "手机",
		hintMobileV  = "摇杆控制方向，滑动屏幕转向；抬头 + 前进即上升",
		hintPC       = "电脑",
		hintPCV      = "WASD 移动  ·  空格上升  ·  Ctrl / Shift 下降",
		hintKey      = "开关",
		hintKeyV     = "按 F 键，或点上面的按钮",
		flyCapsule   = "飞行",
		stateOn      = "已开启",
		stateOff     = "已关闭",

		-- 提示条
		noChar       = "角色未加载，无法起飞",
		flyOnMsg     = "飞行已开启  ·  速度 %s",
		flyOffMsg    = "飞行已关闭",
		softLandMsg  = "缓降中  ·  落地后自动交回操作",
		shieldOnMsg  = "伤害保护已开启  ·  飞行中撞东西 / 落地都不掉血",
		shieldOffMsg = "伤害保护已关闭",

		-- 设置页
		setTitle     = "设置",
		setSub       = "联系作者与语言设置",
		contact      = "联系作者",
		contactHint  = "点一下复制邮箱",
		copied       = "邮箱已复制到剪贴板",
		copyFail     = "复制失败，请手动复制：%s",
		language     = "语言",
		langHint     = "切换后脚本会重启",
		langSwitched = "已切换为 %s，正在重启...",
		langNameZh   = "中文",
		langNameEn   = "英文",
	},

	en = {
		loading      = "Starting...",
		boot1        = "Initializing environment...",
		boot2        = "Loading core modules...",
		boot3        = "Building interface...",
		boot4        = "Taking over movement...",
		boot5        = "Ready",
		loaded       = "%s loaded  ·  %s",

		navGroup     = "FEATURES",
		navHome      = "Home",
		navGeneral   = "General",
		navFly       = "Fly",
		navSettings  = "Settings",

		homeWelcome  = "Welcome to %s",
		homeSub      = "Executor script suite  ·  %s",
		cardFlyTitle = "Flight",
		cardFlyDesc  = "Official joystick / WASD  ·  Auto hover",
		cardGenTitle = "General",
		cardGenDesc  = "Walk speed  ·  Jump power  ·  Gravity",
		homeHint     = "Switch pages from the sidebar. Flight opens in its own window.",

		genTitle     = "General settings",
		genSub       = "Changes apply instantly and reapply after respawn",
		walkSpeed    = "Walk speed",
		jumpPower    = "Jump power",
		gravity      = "Gravity",
		resetBtn     = "Reset to default",
		resetDone    = "Settings restored",
		gravityWarn  = "Gravity affects the whole server, change with care",

		flyTitle     = "O_X Flight",
		flyStopped   = "Stopped",
		flyFlying    = "Flying",
		flyOn        = "Start flight",
		flyOff       = "Stop flight",
		flySpeed     = "Flight speed",
		shieldTitle  = "Damage shield",
		shieldDesc   = "Zeroes velocity: no damage on impact or landing",
		softTitle    = "Soft landing",
		softDesc     = "Descends gently, releases once grounded",
		hintMobile   = "Mobile",
		hintMobileV  = "Joystick to move, swipe to turn; look up + forward to ascend",
		hintPC       = "PC",
		hintPCV      = "WASD to move  ·  Space up  ·  Ctrl / Shift down",
		hintKey      = "Toggle",
		hintKeyV     = "Press F, or click the button above",
		flyCapsule   = "Fly",
		stateOn      = "On",
		stateOff     = "Off",

		noChar       = "Character not loaded, cannot take off",
		flyOnMsg     = "Flight on  ·  speed %s",
		flyOffMsg    = "Flight off",
		softLandMsg  = "Descending  ·  control returns on landing",
		shieldOnMsg  = "Damage shield on  ·  no damage on impact or landing",
		shieldOffMsg = "Damage shield off",

		setTitle     = "Settings",
		setSub       = "Contact and language",
		contact      = "Contact",
		contactHint  = "Click to copy the address",
		copied       = "Address copied to clipboard",
		copyFail     = "Copy failed, please copy manually: %s",
		language     = "Language",
		langHint     = "Switching restarts the script",
		langSwitched = "Switched to %s, restarting...",
		langNameZh   = "Chinese",
		langNameEn   = "English",
	},
}

-- 当前语言（boot 时设定）。切换语言 = 重启整个界面，所以它放在 boot 外面。
local LANG = "zh"

-- 取词：当前语言没有就退回中文包，再没有就直接显示 key（方便发现漏翻）
local function L(key, ...)
	local pack = LOCALES[LANG] or LOCALES.zh
	local str  = pack[key]
	if str == nil then str = LOCALES.zh[key] end
	if str == nil then return key end
	if select("#", ...) > 0 then
		local ok, out = pcall(string.format, str, ...)
		if ok then return out end
	end
	return str
end

--========================== 配置区 ==========================
local CONFIG = {
	Title   = "O_X HUB",
	Version = "v1.4.1",

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

	-- ---------- 防摔伤 / 防撞击伤害 ----------
	-- 这类服务器的判定都在服务端，读的是同步过去的角色速度，
	-- 或者监听 Humanoid.StateChanged 的 Freefall -> Landed。所以做三层：
	--   ① 速度回零：每帧末尾把 AssemblyLinearVelocity 清零、下一帧开头还原。
	--      中间那一段正好是网络同步窗口 —— 服务端读到的速度恒为 0，
	--      摔伤判不到，高速撞到东西也判不到。（社区针对自然灾害模拟器的通用解法）
	--   ② 状态屏蔽：飞行期间关掉 Freefall / Landed / FallingDown，不给状态判定机会
	--   ③ 缓降落地：关飞行时缓降到贴地站住才放手，角色根本没自由落体过
	DamageShield      = true,  -- 总开关
	VelocitySpoof     = true,  -- ① 速度回零
	VelocitySpoofHold = 0.8,   -- 落地后继续回零这么久再停
	SoftLand          = true,  -- ③ 关闭飞行时缓降，避免摔伤
	SoftLandApproach  = 2.5,   -- 接近速度系数：下降速度 = 离地余量 × 这个值
	SoftLandMaxSpeed  = 110,   -- 缓降最大速度（高处快速接近）
	SoftLandMinSpeed  = 6,     -- 缓降最低速度（贴地前慢慢蹭）
	SoftLandGap       = 0.4,   -- 离地小于这个值就算"站稳"
	SoftLandSettle    = 0.12,  -- 站稳后等这么久（让物理速度彻底归零）再放开控制
	SoftLandTimeout   = 20,    -- 兜底：最多缓降这么久

	-- ---------- 图标 / 内联资源 ----------
	-- 内联资源会写到执行器工作目录，再用 getcustomasset 转成可用资源。
	-- ⚠️ 文件名必须带内容哈希！写死文件名的话，换图后执行器里残留的旧文件
	--    会让"已存在就跳过写入"直接跳过，getcustomasset 也按文件名缓存 → 永远显示旧图
	AssetPrefix = "oxhub_",
	IconFile    = "oxhub_icon.jpg",   -- 老版本用过的固定名，启动时顺手清掉

	-- ---------- 联系方式 ----------
	Contact = "oxhub@atomicmail.io",
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

-- 内联资源：图标 + 两面国旗（base64，运行时落盘再 getcustomasset）
-- 统一放一张表里，加资源只要往这里塞一条
local ASSET_B64 = {
	icon    = [==[
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
wKwdSh92PanUkceB5utP2CgD/9k=
]==],
	flag_us = [==[
iVBORw0KGgoAAAANSUhEUgAAAHgAAABQCAIAAABd+SbeAAABnklEQVR42u3bwU3DQBCFYRtRCbQAp9gl0Ep8o4+0AiUk4kIN
nCnDHCxZVtZRBMi7zvh7N0Yc2F+zs/OeTN3s9tXK9Pr9UYXT3fSH4+kw+0ul6mFB03Kqm90+bai26WYbLU895Oioxxk9HHs4
anqvc9bjz2hzeXHQx9Ohbbq26c7OX6oeeXRcarQ8czl8s9eze3SpeR0YtPWunGFJ52ae+uYMy3ijz6720nWGhWFhWG50dExP
O223nPVNGJb0OpeqMyw5DEvwGb0ewyL4FzD9Xfezxx6v+dnztWh91MvXZ0zQ04ZKH6uc9cDrxxr3aKESLRD8lwqYtrJHp09W
5vpW9miGhWEJalhKBUwbCv4FSQwLw1IJ/n+fdRRf70JmHb5U8qWSPdqXSkKlG3kMh4mZBvN56uOf8f74bI+2R/9jdGT+9Otq
PbIFLw43/Dc09ujSwX/lHzqtd0DT5dHR9z0KOhpoAhrobT+Gbw9PKOhooAlooIEmoGUdpKOBBpqAlnWQjgYaaAIaaAJa1qGj
CWigCWhZh44moIEmoIEGmhbVDxSCQ6gv5jfkAAAAAElFTkSuQmCC
]==],
	flag_cn = [==[
iVBORw0KGgoAAAANSUhEUgAAAHgAAABQCAIAAABd+SbeAAABiUlEQVR42u3b3U2EQBQGUCEUQAs+Wgv12s7SwpbgAwnZABlZ
ZkC5c77skzFEz4yXOz82j6/+Q85PiyA+9Of3E/TpslUpXw09Dn1tvnM6FeOaNNd3HZvQ49Cb0Scqh/ctU6OrLbg36DrGoZ8+
tY1Ze+V0fvVNW8dzP/4ynC1K1dlX3Hi12xL8f0MX/9NePDBe6ej+/CeopHU5UqPXNEVK6qLoTy1KfOhSE+0trGC4u2p0kV+4
noVfgdJxbGojfrvrOEBGOetluGdqIy7QR/+KSPk2K8PAPXVbUMGu6T1m9DRO82gFG7Yus0fO51g/YfpKsIq/t+tIH0Hl73Ce
tKy/cenYPB/JR1k8odL96D17/PMAeCVmzejNiZy/hbSuy9Mn3mi1xZfUiW9OnwqmTxRdoHGvw5mhK2GuhCkdgUrHzgYGdO6V
MH30FXO52s3rxn9lae9AC2jQoAU0aAENGrSABi2gQYMW0KAFNGjQAhq0gAYNWkCDFtCgQQto0AIaNGgBDVpAgwYtoEPkBwXU
pb8MT+3nAAAAAElFTkSuQmCC
]==],
}

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

-- 执行器注入的函数（没有就是 nil，Luau 取不存在的全局不会报错）。
-- 这里用**裸全局引用**先抓一遍：这是最可靠的一条路 ——
-- 有些执行器给脚本的是沙箱环境，那里的 `_G` 是一张全新的空表，
-- 但裸全局依然能顺着 __index 找到真正的注入函数。
local EXEC = {
	writefile      = writefile,
	getcustomasset = getcustomasset,
	getsynasset    = getsynasset,
	isfile         = isfile,
	gethui         = gethui,
	-- 剪贴板：各家名字不一样，能引用到的全抓在手里
	setclipboard    = setclipboard,
	toclipboard     = toclipboard,
	set_clipboard   = set_clipboard,
	setrbxclipboard = setrbxclipboard,
}

-- 有的执行器把注入函数包成 table / userdata（带 __call），所以不能只认 function
local function isCallable(v)
	local t = type(v)
	return t == "function" or t == "table" or t == "userdata"
end

-- 执行器环境：`_G` 和 `getgenv()` 不一定是同一张表，两张都翻
local EXEC_ENVS
local function execEnvs()
	if EXEC_ENVS then return EXEC_ENVS end
	local out = {}
	if type(_G) == "table" then table.insert(out, _G) end
	local ok, env = pcall(function()
		if type(getgenv) == "function" then return getgenv() end
	end)
	if ok and type(env) == "table" and env ~= _G then
		table.insert(out, env)
	end
	EXEC_ENVS = out
	return out
end

local function execFn(name)
	local v = EXEC[name]
	if isCallable(v) then return v end
	for _, env in ipairs(execEnvs()) do
		local ok, g = pcall(function() return env[name] end)
		if ok and isCallable(g) then return g end
	end
	return nil
end

--========================== 剪贴板 ==========================
-- 复制到剪贴板。不同执行器的名字/位置都不一样，挨个试；
-- 全都失败就明确告诉用户手动复制，绝不静默失败。
local CLIPBOARD_NAMES = {
	"setclipboard", "toclipboard", "set_clipboard", "setrbxclipboard",
	"writeclipboard", "write_clipboard", "setClipboard", "copyToClipboard",
}

local function copyText(text)
	-- 1) 常见名字：EXEC 里裸全局抓到的 → _G → getgenv()
	for _, name in ipairs(CLIPBOARD_NAMES) do
		local fn = execFn(name)
		if fn and pcall(fn, text) then return true end
	end
	-- 2) 名字没见过：把环境里所有带 "clip" 的东西都试一遍（最后的机会）
	for _, env in ipairs(execEnvs()) do
		local ok, keys = pcall(function()
			local out = {}
			for k in pairs(env) do
				if type(k) == "string" and string.find(string.lower(k), "clip", 1, true) then
					out[#out + 1] = k
				end
			end
			return out
		end)
		if ok then
			for _, k in ipairs(keys) do
				local ok2, v = pcall(function() return env[k] end)
				if ok2 and isCallable(v) and pcall(v, text) then return true end
			end
		end
	end
	return false
end

-- 失败时把环境里跟剪贴板相关的名字打到控制台，方便定位是哪家执行器
local function dumpClipboardCandidates()
	pcall(function()
		local found = {}
		for _, env in ipairs(execEnvs()) do
			for k in pairs(env) do
				if type(k) == "string" and string.find(string.lower(k), "clip", 1, true) then
					found[#found + 1] = tostring(k)
				end
			end
		end
		print("[O_X HUB] 剪贴板不可用，环境里带 clip 的名字："
			.. (#found > 0 and table.concat(found, ", ") or "（一个都没有）"))
	end)
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
-- 所有全局连接的登记处 —— 主窗口 ✕ 关掉时要能把它们全断开
local GLOBAL_CONNS = {}

-- 按住 handle 拖动 frame。
--   scaleFn        : 返回当前 UIScale.Scale —— 有缩放时 delta 要除回去，否则拖拽"跟不上手"
--   opts.threshold : 位移超过这么多像素才算拖动（挂在按钮上时用来区分"点击"和"拖动"）
--   opts.clamp     : 限制在屏幕内，别被拖出可视区
-- 返回一个函数；点击回调里调它就能知道"刚才那一下到底是点击还是拖动"
local function makeDraggable(frame, handle, scaleFn, opts)
	opts = opts or {}
	local dragging, moved = false, false
	local dragStart, startPos = nil, nil
	local threshold = opts.threshold or 0

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	local function getViewport()
		local w, h = 1920, 1080
		pcall(function()
			local cam = workspace.CurrentCamera
			if cam and cam.ViewportSize then
				w, h = cam.ViewportSize.X, cam.ViewportSize.Y
			end
		end)
		return w, h
	end

	table.insert(GLOBAL_CONNS, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart

			-- 没过阈值就还当它是"点击"，不移动
			if not moved and delta.Magnitude < threshold then return end
			moved = true

			local s = 1
			if scaleFn then
				local ok, v = pcall(scaleFn)
				if ok and type(v) == "number" and v > 0 then s = v end
			end

			local nx = startPos.X.Offset + delta.X / s
			local ny = startPos.Y.Offset + delta.Y / s

			-- 只在纯 offset 定位时才夹取，Scale 定位的窗口不动它
			if opts.clamp and startPos.X.Scale == 0 and startPos.Y.Scale == 0 then
				local vpW, vpH = getViewport()
				local w, h = frame.AbsoluteSize.X, frame.AbsoluteSize.Y
				if not w or w <= 0 then w = 46 * s end
				if not h or h <= 0 then h = 46 * s end
				nx = math.clamp(nx, 0, math.max(0, vpW - w))
				ny = math.clamp(ny, 0, math.max(0, vpH - h))
			end

			frame.Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
		end
	end))

	return function() return moved end
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

-- 内容哈希（djb2）—— 只用来拼文件名，不做安全用途。
-- 这里手写十六进制：hash 经常超过 2^31，string.format("%x", ...) 在部分运行时
-- （数值走双精度/32 位位运算的那种）会报 "number has no integer representation"。
local HEX_DIGITS = "0123456789abcdef"
local function contentHash(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 4294967296
	end
	local out = {}
	for i = 7, 0, -1 do
		local d = math.floor(h / (16 ^ i)) % 16
		out[#out + 1] = HEX_DIGITS:sub(d + 1, d + 1)
	end
	return table.concat(out)
end

-- 资源缓存（放在 boot 外面：重启语言时不用重新落盘）
--   TRIED[key] = true 表示"试过了"，CACHE[key] 为 nil 就是这台执行器用不了
local ASSET_TRIED, ASSET_CACHE = {}, {}

-- 各资源的文件扩展名（getcustomasset 靠它判断类型）
local ASSET_EXT = { icon = "jpg", flag_us = "png", flag_cn = "png" }

local function getAsset(key)
	if ASSET_TRIED[key] then return ASSET_CACHE[key] end
	ASSET_TRIED[key] = true

	local b64 = ASSET_B64[key]
	if not b64 then return nil end

	local writeFile = execFn("writefile")
	local getCustom = execFn("getcustomasset") or execFn("getsynasset")
	local isFile    = execFn("isfile")
	local delFile   = execFn("delfile")
	local listFiles = execFn("listfiles")

	if not writeFile or not getCustom then
		return nil
	end

	local ok, res = pcall(function()
		local data = b64decode(b64)
		local ext  = ASSET_EXT[key] or "png"

		-- 文件名里带内容哈希：换了图就是另一个文件，
		-- 既不会被"已存在就跳过"挡住，也绕开了 getcustomasset 按文件名做的缓存
		local prefix = CONFIG.AssetPrefix .. key .. "_"
		local name   = prefix .. contentHash(data) .. "." .. ext

		-- 清掉历史遗留：老版本写死的固定名 + 以前其它哈希留下的同名资源
		if delFile then
			if key == "icon" and CONFIG.IconFile then pcall(delFile, CONFIG.IconFile) end
			if listFiles then
				local okL, files = pcall(listFiles)
				if okL and type(files) == "table" then
					for _, f in ipairs(files) do
						local p = tostring(f)
						local base = p:match("([^/\\]+)$") or p
						if base ~= name and base:sub(1, #prefix) == prefix then
							pcall(delFile, p)
						end
					end
				end
			end
		end

		local need = true
		if isFile then
			local okF, has = pcall(isFile, name)
			-- 同名 = 同内容，可以放心跳过
			if okF and has then need = false end
		end
		if need then
			writeFile(name, data)
		end

		local asset = getCustom(name)
		if type(asset) ~= "string" or asset == "" then
			error("资源转换失败: " .. key)
		end
		return asset
	end)

	if ok and type(res) == "string" then
		ASSET_CACHE[key] = res
	else
		-- 写不进去也不能把整个脚本拖垮：界面会自动退回代码画的 LOGO
		pcall(function()
			print("[O_X HUB] 资源不可用 " .. tostring(key) .. " -> " .. tostring(res))
		end)
	end
	return ASSET_CACHE[key]
end

local function getIconAsset() return getAsset("icon") end

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

-- 国旗图标：拿不到资源就退回一个文字色块，界面不会开天窗
local function createFlag(parent, assetKey, size, pos, anchor, radius, fallbackText)
	local box = new("Frame", {
		Size = size,
		Position = pos,
		AnchorPoint = anchor or Vector2.new(0, 0),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(0, radius or 5), Parent = box })

	local asset = getAsset(assetKey)
	if asset then
		new("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = asset,
			ScaleType = Enum.ScaleType.Crop,
			Parent = box,
		})
	else
		new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = fallbackText or "",
			TextSize = 15,
			Font = FONT_B,
			TextColor3 = C.Sub,
			Parent = box,
		})
	end
	return box
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

--========================== 运行期状态 ==========================
-- 卸载标记：关掉之后所有还在跑的异步逻辑（缓降、提示、复活恢复）都要安静退出
local SHUTDOWN = false

-- 下面这几个每次 boot 都会重建，所以在外面先声明成 upvalue，boot 里再赋值
local notifyGui, notifyHolder, notify
local boot, unloadAll, restart

--========================== 提示条 ==========================
-- 单独一个 ScreenGui（不挂在主 GUI 下），这样主窗口隐藏时提示照样能弹。
-- 它在 boot 里创建，所以这里只写函数体。
notify = function(text, color)
	if SHUTDOWN then return end
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
		Text = opts.Subtitle or L("loading"),
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
		{ L("boot1"), 18,  0.36 },
		{ L("boot2"), 42,  0.44 },
		{ L("boot3"), 68,  0.44 },
		{ L("boot4"), 90,  0.34 },
		{ L("boot5"), 100, 0.26 },
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
--  一·五、语言选择（注入后的第一屏）
--  两种语言都要露脸，所以这一屏不做翻译，中英并排写
--=====================================================================
local LANG_CHOICES = {
	{ key = "en", flag = "flag_us", name = "English", desc = "English" },
	{ key = "zh", flag = "flag_cn", name = "中文",    desc = "简体中文" },
}

local function createLanguageScreen(onPick)
	local gui = new("ScreenGui", {
		Name = "O_X_HUB_Language",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 100002,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GUI_PARENT,
	})

	local bg = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Bg,
		BorderSizePixel = 0,
		Parent = gui,
	})

	-- 顶部光晕，跟加载页一个味道
	local glow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 260),
		Position = UDim2.new(0, 0, 0, -190),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.9,
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

	local card = new("Frame", {
		Name = "LangCard",
		Size = UDim2.new(0, 430, 0, 372),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		Parent = bg,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 18), Parent = card })
	new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = card })

	-- 中间：醒目的图标 + O_X HUB（这个名字不翻译）
	createLogo(card, {
		Size = UDim2.new(0, 104, 0, 104),
		Position = UDim2.new(0.5, 0, 0, 34),
		AnchorPoint = Vector2.new(0.5, 0),
		Radius = 28,
		TextSize = 50,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0.5, 0, 0, 152),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = CONFIG.Title,
		TextSize = 28,
		Font = FONT_B,
		TextColor3 = C.Text,
		Parent = card,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0.5, 0, 0, 190),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "选择语言  /  Select language",
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Dim,
		Parent = card,
	})

	local row = new("Frame", {
		Name = "LangRow",
		Size = UDim2.new(0, 316, 0, 106),
		Position = UDim2.new(0.5, 0, 0, 228),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local picking = false
	local function pick(key)
		if picking then return end
		picking = true
		TweenService:Create(
			card,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		):Play()
		TweenService:Create(
			bg,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		):Play()
		task.delay(0.22, function()
			pcall(function() gui:Destroy() end)
			onPick(key)
		end)
	end

	for i, opt in ipairs(LANG_CHOICES) do
		local btn = new("TextButton", {
			Name = "Pick_" .. opt.key,
			Size = UDim2.new(0, 150, 0, 106),
			Position = UDim2.new(0, (i - 1) * 166, 0, 0),
			BackgroundColor3 = C.Card,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = row,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = btn })
		local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = btn })

		-- 兜底文字用语言代码，不放汉字：英文模式下界面里一个汉字都不许有
		createFlag(btn, opt.flag, UDim2.new(0, 64, 0, 42), UDim2.new(0.5, 0, 0, 16),
			Vector2.new(0.5, 0), 6, opt.key == "zh" and "ZH" or "EN")

		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 0, 66),
			BackgroundTransparency = 1,
			Text = opt.name,
			TextSize = 15,
			Font = FONT_B,
			TextColor3 = C.Text,
			Parent = btn,
		})
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 86),
			BackgroundTransparency = 1,
			Text = opt.desc,
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			Parent = btn,
		})

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = C.Card2
			stroke.Color = C.Accent
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = C.Card
			stroke.Color = C.Stroke
		end)
		btn.MouseButton1Click:Connect(function() pick(opt.key) end)
	end
end

--=====================================================================
--  二、主界面
--  整个界面（含飞行窗口、悬浮图标、所有连接）都装在 boot 里。
--  切换语言 = 把旧的整份卸掉 + 再用新语言跑一次 boot，也就是"重启"。
--=====================================================================
boot = function(lang)
	LANG = lang
	SHUTDOWN = false
	GLOBAL_CONNS = {}

	-- 提示条 GUI（跟主界面一起重建）
	notifyGui = new("ScreenGui", {
		Name = "O_X_HUB_Notify",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 100001,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GUI_PARENT,
	})

	notifyHolder = new("Frame", {
		Name = "NotifyHolder",
		Size = UDim2.new(0, 300, 0, 46),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 22),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = notifyGui,
	})

	local WIN_W, WIN_H   = 520, 380
	local SIDEBAR_W      = 132
	local HEADER_H       = 46

	local FLY_W, FLY_H   = 380, 356

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
		Position = UDim2.new(1, -158, 0, 0),
		BackgroundTransparency = 1,
		Text = CONFIG.Version,
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	-- 最小化：只是把窗口缩成一个悬浮图标，什么都不结束
	local minBtn = new("TextButton", {
		Name = "Minimize",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -72, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "－",
		TextSize = 15,
		Font = FONT_B,
		TextColor3 = C.Sub,
		Parent = header,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 9), Parent = minBtn })
	local minStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = minBtn })
	minBtn.MouseEnter:Connect(function()
		minBtn.BackgroundColor3 = C.Card2
		minBtn.TextColor3 = C.Text
		minStroke.Color = C.Dim
	end)
	minBtn.MouseLeave:Connect(function()
		minBtn.BackgroundColor3 = C.Card
		minBtn.TextColor3 = C.Sub
		minStroke.Color = C.Stroke
	end)

	-- 关闭：真的结束 —— 停飞行、撤伤害保护、断开所有连接、销毁整个界面
	local closeBtn = new("TextButton", {
		Name = "Close",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -38, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "✕",
		TextSize = 14,
		Font = FONT_B,
		TextColor3 = C.Sub,
		Parent = header,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 9), Parent = closeBtn })
	local closeStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = closeBtn })
	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = C.Red
		closeBtn.TextColor3 = C.White
		closeStroke.Color = C.Red
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = C.Card
		closeBtn.TextColor3 = C.Sub
		closeStroke.Color = C.Stroke
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
		Text = L("navGroup"),
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
	-- 伤害保护总开关（速度回零模块在下面才定义，这里先占位，免得闭包绑到全局）
	local ShieldRequest = function() end
	-- 主窗口 ✕ = 结束整个脚本；飞行窗口 ✕ = 只结束飞行（都在后面接上）
	local ShutdownRequest = function() end
	local FlyCloseRequest = function() end

	--========================== 主页 ==========================
	local home = addPage("home")
	addNav("home", L("navHome"), 1)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 6),
		BackgroundTransparency = 1,
		Text = string.format(L("homeWelcome"), CONFIG.Title),
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
		Text = string.format(L("homeSub"), CONFIG.Version),
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
		Text = L("cardFlyTitle"),
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
		Text = L("cardFlyDesc"),
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
		Text = L("stateOff"),
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
		Text = L("cardGenTitle"),
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
		Text = L("cardGenDesc"),
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
		Text = L("homeHint"),
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
	addNav("general", L("navGeneral"), 2)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 4),
		BackgroundTransparency = 1,
		Text = L("genTitle"),
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
		Text = L("genSub"),
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
		Label = L("walkSpeed"),
		Min = 8, Max = 500,
		Default = math.clamp(walkDef, 8, 500),
		Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
		OnChange = function(v)
			Settings.WalkSpeed = v
			applySettings()
		end,
	})

	local setJump, jumpLabel = addSettingRow(108, {
		Label = L("jumpPower"),
		Min = 0, Max = 500,
		Default = math.clamp(jumpDef, 0, 500),
		Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
		OnChange = function(v)
			Settings.JumpPower = v
			applySettings()
		end,
	})

	local setGrav, gravLabel = addSettingRow(164, {
		Label = L("gravity"),
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
		Text = L("resetBtn"),
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
			notify(L("resetDone"), C.Accent)
		end,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 30),
		Position = UDim2.new(0, 106, 0, 236),
		BackgroundTransparency = 1,
		Text = L("gravityWarn"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		Parent = general,
	})

	--========================== 设置 ==========================
	-- 跟主页一样是个 page（不新开窗口）
	local settingsPage = addPage("settings")
	addNav("settings", L("navSettings"), 4)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 4),
		BackgroundTransparency = 1,
		Text = L("setTitle"),
		TextSize = 17,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = settingsPage,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = L("setSub"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = settingsPage,
	})

	-- 联系作者：整张卡片可点，点了复制邮箱
	local contactCard = new("TextButton", {
		Name = "ContactCard",
		Size = UDim2.new(1, 0, 0, 54),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = settingsPage,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = contactCard })
	local contactStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = contactCard })

	new("TextLabel", {
		Size = UDim2.new(0, 140, 0, 14),
		Position = UDim2.new(0, 14, 0, 9),
		BackgroundTransparency = 1,
		Text = L("contact"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = contactCard,
	})

	new("TextLabel", {
		Name = "ContactMail",
		Size = UDim2.new(1, -28, 0, 18),
		Position = UDim2.new(0, 14, 0, 26),
		BackgroundTransparency = 1,
		Text = CONFIG.Contact,
		TextSize = 14,
		Font = FONT_B,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = contactCard,
	})

	new("TextLabel", {
		Size = UDim2.new(0, 110, 1, 0),
		Position = UDim2.new(1, -124, 0, 0),
		BackgroundTransparency = 1,
		Text = L("contactHint"),
		TextSize = 10,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = contactCard,
	})

	contactCard.MouseEnter:Connect(function()
		contactCard.BackgroundColor3 = C.Card2
		contactStroke.Color = C.Accent
	end)
	contactCard.MouseLeave:Connect(function()
		contactCard.BackgroundColor3 = C.Card
		contactStroke.Color = C.Stroke
	end)
	contactCard.MouseButton1Click:Connect(function()
		if copyText(CONFIG.Contact) then
			notify(L("copied"), C.Green)
		else
			dumpClipboardCandidates()
			notify(string.format(L("copyFail"), CONFIG.Contact), C.Red)
		end
	end)

	new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 118),
		BackgroundColor3 = C.Stroke,
		BorderSizePixel = 0,
		Parent = settingsPage,
	})

	-- 语言切换：切完重启脚本
	new("TextLabel", {
		Size = UDim2.new(1, -140, 0, 16),
		Position = UDim2.new(0, 0, 0, 132),
		BackgroundTransparency = 1,
		Text = L("language"),
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = settingsPage,
	})

	new("TextLabel", {
		Size = UDim2.new(0, 140, 0, 16),
		Position = UDim2.new(1, -140, 0, 132),
		BackgroundTransparency = 1,
		Text = L("langHint"),
		TextSize = 10,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = settingsPage,
	})

	local LANG_BUTTONS = {
		{ key = "zh", name = L("langNameZh"), flag = "flag_cn", fallback = "ZH" },
		{ key = "en", name = L("langNameEn"), flag = "flag_us", fallback = "EN" },
	}
	for i, opt in ipairs(LANG_BUTTONS) do
		local active = (opt.key == LANG)
		local btn = new("TextButton", {
			Name = "Lang_" .. opt.key,
			Size = UDim2.new(0, 150, 0, 42),
			Position = UDim2.new(0, (i - 1) * 158, 0, 156),
			BackgroundColor3 = active and C.Card2 or C.Card,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = settingsPage,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 9), Parent = btn })
		local stroke = new("UIStroke", {
			Color = active and C.Accent or C.Stroke,
			Thickness = active and 2 or 1,
			Parent = btn,
		})

		createFlag(btn, opt.flag, UDim2.new(0, 30, 0, 20), UDim2.new(0, 12, 0.5, 0),
			Vector2.new(0, 0.5), 4, opt.fallback)

		new("TextLabel", {
			Size = UDim2.new(1, -54, 1, 0),
			Position = UDim2.new(0, 50, 0, 0),
			BackgroundTransparency = 1,
			Text = opt.name,
			TextSize = 13,
			Font = FONT_B,
			TextColor3 = active and C.Text or C.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})

		if not active then
			btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.Card2 end)
			btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.Card end)
		end

		btn.MouseButton1Click:Connect(function()
			if opt.key == LANG then return end
			notify(string.format(L("langSwitched"), opt.name), C.Accent)
			restart(opt.key)
		end)
	end

	--========================== 飞行（独立窗口） ==========================
	local flyNavBtn = addNav("fly", L("navFly"), 3, function() openFlyWindow() end)

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
		Text = L("flyTitle"),
		TextSize = 14,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyHeader,
	})

	local flyWinState = new("TextLabel", {
		Size = UDim2.new(0, 64, 1, 0),
		Position = UDim2.new(1, -142, 0, 0),
		BackgroundTransparency = 1,
		Text = L("flyStopped"),
		TextSize = 11,
		Font = FONT_B,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = flyHeader,
	})

	-- 最小化：收成侧边胶囊
	local flyMinBtn = new("TextButton", {
		Name = "Minimize",
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(1, -70, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "－",
		TextSize = 14,
		Font = FONT_B,
		TextColor3 = C.Sub,
		Parent = flyHeader,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = flyMinBtn })
	local flyMinStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = flyMinBtn })
	flyMinBtn.MouseEnter:Connect(function()
		flyMinBtn.BackgroundColor3 = C.Card2
		flyMinBtn.TextColor3 = C.Text
		flyMinStroke.Color = C.Dim
	end)
	flyMinBtn.MouseLeave:Connect(function()
		flyMinBtn.BackgroundColor3 = C.Card
		flyMinBtn.TextColor3 = C.Sub
		flyMinStroke.Color = C.Stroke
	end)

	-- 关闭：结束飞行（走落地保护）+ 收起窗口，不留胶囊
	local flyCloseBtn = new("TextButton", {
		Name = "Close",
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(1, -38, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "✕",
		TextSize = 13,
		Font = FONT_B,
		TextColor3 = C.Sub,
		Parent = flyHeader,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = flyCloseBtn })
	local flyCloseStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = flyCloseBtn })
	flyCloseBtn.MouseEnter:Connect(function()
		flyCloseBtn.BackgroundColor3 = C.Red
		flyCloseBtn.TextColor3 = C.White
		flyCloseStroke.Color = C.Red
	end)
	flyCloseBtn.MouseLeave:Connect(function()
		flyCloseBtn.BackgroundColor3 = C.Card
		flyCloseBtn.TextColor3 = C.Sub
		flyCloseStroke.Color = C.Stroke
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
		Text = L("flyOn"),
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
		Text = L("flySpeed"),
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
		Text = L("shieldTitle"),
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyBody,
	})

	createSwitch(flyBody, {
		Name = "DamageShield",
		Position = UDim2.new(1, -40, 0, 121),
		Default = CONFIG.DamageShield,
		OnChange = function(v)
			ShieldRequest(v)
		end,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 144),
		BackgroundTransparency = 1,
		Text = L("shieldDesc"),
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

	new("TextLabel", {
		Size = UDim2.new(1, -60, 0, 16),
		Position = UDim2.new(0, 0, 0, 178),
		BackgroundTransparency = 1,
		Text = L("softTitle"),
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyBody,
	})

	createSwitch(flyBody, {
		Name = "SoftLand",
		Position = UDim2.new(1, -40, 0, 175),
		Default = CONFIG.SoftLand,
		OnChange = function(v)
			CONFIG.SoftLand = v
		end,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 198),
		BackgroundTransparency = 1,
		Text = L("softDesc"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyBody,
	})

	new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 220),
		BackgroundColor3 = C.Stroke,
		BorderSizePixel = 0,
		Parent = flyBody,
	})

	local hints = {
		{ L("hintMobile"), L("hintMobileV") },
		{ L("hintPC"),     L("hintPCV") },
		{ L("hintKey"),    L("hintKeyV") },
	}
	for i, h in ipairs(hints) do
		local y = 232 + (i - 1) * 22
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
		Text = L("flyTitle"),
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
		Text = L("flyCapsule"),
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
	-- 悬浮图标（主窗口的圆标 / 飞行胶囊）也能拖着走。
	-- 带阈值：位移超过 6px 才算拖动，否则还是当点击，不会被拖拽吃掉
	local reopenDragged    = makeDraggable(reopen, reopen, nil, { threshold = 6, clamp = true })
	local flyReopenDragged = makeDraggable(flyReopen, flyReopen, nil, { threshold = 6, clamp = true })

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

	-- － 只是缩成图标；✕ 是结束整个脚本（停飞行 + 撤保护 + 销毁界面）
	minBtn.MouseButton1Click:Connect(function() hideMain(true) end)
	closeBtn.MouseButton1Click:Connect(function() ShutdownRequest() end)
	reopen.MouseButton1Click:Connect(function()
		if reopenDragged() then return end   -- 刚才是在拖它，不当点击
		showMain()
	end)

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

	-- 真·关闭飞行窗口：连胶囊一起收掉，不留入口（要再开就去主页卡片 / 左侧「飞行」）
	local function closeFlyWindow()
		flyWin.Visible = false
		flyReopen.Visible = false
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
	flyCloseBtn.MouseButton1Click:Connect(function() FlyCloseRequest() end)
	flyReopen.MouseButton1Click:Connect(function()
		if flyReopenDragged() then return end
		openFlyWindow()
	end)

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

	-- 屏蔽会触发摔伤判定的状态。
	-- StateChanged 不会再抛 Freefall -> Landed / FallingDown，靠状态判定摔伤的服务器就抓不到。
	-- 注意：SetStateEnabled 在客户端调用不会同步到服务端，但"状态变化"本身会同步，
	-- 所以客户端不进这些状态，服务端也就看不到。
	local SHIELD_STATES = {
		Enum.HumanoidStateType.Freefall,
		Enum.HumanoidStateType.Landed,
		Enum.HumanoidStateType.FallingDown,
	}

	local function setDamageShield(hum, on)
		if not CONFIG.DamageShield then return end
		for _, st in ipairs(SHIELD_STATES) do
			pcall(function() hum:SetStateEnabled(st, not on) end)
		end
	end

	-- 贴地放手后，状态屏蔽再撑这么久才撤掉
	local SHIELD_TIME = 0.5

	--=====================================================================
	--  速度回零（防摔伤 / 防撞击伤害）
	--
	--  原理：服务端的伤害判定读的是"同步过去的角色速度"。
	--  在 Heartbeat 末尾把 AssemblyLinearVelocity 清零、下一帧 RenderStepped 再还原，
	--  中间这一段正好是网络同步窗口 —— 服务端读到的速度恒为 0。
	--  角色的实际移动不受影响，因为物理步之前速度已经还原了。
	--=====================================================================
	local Spoof = {
		Active = false,
		Gen    = 0,      -- 代数，防止"延迟停止"误杀新开的回零
		Conns  = {},
	}

	function Spoof:Stop()
		self.Gen = self.Gen + 1
		if not self.Active then return end
		self.Active = false
		for _, c in ipairs(self.Conns) do
			pcall(function() c:Disconnect() end)
		end
		self.Conns = {}
	end

	function Spoof:Start()
		if not CONFIG.DamageShield or not CONFIG.VelocitySpoof then return end
		self.Gen = self.Gen + 1
		if self.Active then return end

		self.Active = true
		local saved = nil

		local hb
		hb = RunService.Heartbeat:Connect(function()
			if not self.Active then
				pcall(function() hb:Disconnect() end)
				return
			end
			local root = getRoot()
			if not root then return end
			pcall(function()
				saved = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.zero
			end)
		end)

		local rs
		rs = RunService.RenderStepped:Connect(function()
			if not self.Active then
				pcall(function() rs:Disconnect() end)
				return
			end
			if not saved then return end
			local root = getRoot()
			if root then
				pcall(function() root.AssemblyLinearVelocity = saved end)
			end
			saved = nil
		end)

		self.Conns = { hb, rs }
	end

	-- 一直回零到角色落地，再多撑一会儿才停
	function Spoof:StopWhenGrounded()
		if not self.Active then return end

		local gen = self.Gen
		local t0 = os.clock()

		local conn
		conn = RunService.Heartbeat:Connect(function()
			if not self.Active then
				pcall(function() conn:Disconnect() end)
				return
			end

			local root = getRoot()
			local hum  = getHumanoid()
			local done = false

			if not root or not root.Parent or not hum or not hum.Parent then
				done = true
			elseif getGroundDistance(root) - getFootOffset(root) <= CONFIG.SoftLandGap + 1 then
				done = true
			elseif os.clock() - t0 > 15 then
				done = true
			end

			if done then
				pcall(function() conn:Disconnect() end)
				task.delay(CONFIG.VelocitySpoofHold, function()
					-- 这中间要是又起飞了，就不能把新开的回零关掉
					if Spoof.Gen == gen then Spoof:Stop() end
				end)
			end
		end)

		table.insert(self.Conns, conn)
	end

	-- 完全撤掉伤害保护（复活 / 关脚本时用）
	function Fly:StopShield()
		Spoof:Stop()
		local hum = getHumanoid()
		if hum then setDamageShield(hum, false) end
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
		setDamageShield(hum, false)  -- 飞行中恢复 Freefall，不然角色状态机不自然
		Spoof:Start()                -- 速度回零：服务端读到的速度恒为 0，撞东西 / 落地都不掉血
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
			notify(L("softLandMsg"), C.Accent)
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
				if grounded then setDamageShield(hum, true) end
				pcall(function() hum.PlatformStand = false end)
				if grounded then
					task.delay(SHIELD_TIME, function()
						if hum and hum.Parent then
							setDamageShield(hum, false)
						end
					end)
				end
			end

			-- 回零再撑到落地之后一会儿才停，把落地那一瞬间也盖住
			Spoof:StopWhenGrounded()
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
				if hum then setDamageShield(hum, false) end
				Spoof:Stop()
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
			-- 高空：走缓降流程（回零继续跑着，落地由 SoftLand 收尾）
			Fly:SoftLand(root, hum)
			return
		end

		-- 本来就在地上：直接放手。只在确实贴地时才屏蔽 Freefall，
		-- 免得玩家主动关掉保护从高空跳下去时角色反而卡在空中
		local grounded = gap <= CONFIG.SoftLandGap + 2
		if grounded then setDamageShield(hum, true) end
		pcall(function() hum.PlatformStand = false end)
		if grounded then
			task.delay(SHIELD_TIME, function()
				if hum and hum.Parent then setDamageShield(hum, false) end
			end)
			-- 贴地放手：回零再撑一小会儿，把落地那一瞬间也盖住
			Spoof:StopWhenGrounded()
		else
			-- 主动从高空跳下去（关掉了落地保护）：没必要再回零，恢复正常物理
			Spoof:Stop()
		end
	end

	-- 状态同步到所有界面元素
	local function syncFlyUI()
		local on = Fly.Enabled

		flyDot.BackgroundColor3 = on and C.Green or C.Dim
		flyCardState.Text = on and L("stateOn") or L("stateOff")
		flyCardState.TextColor3 = on and C.Green or C.Dim
		flyCardStroke.Color = on and C.Green or C.Stroke

		navItems.fly.dot.BackgroundColor3 = on and C.Green or C.Dim
		flyReopenDot.BackgroundColor3 = on and C.Green or C.Dim

		flyToggleLabel.Text = on and L("flyOff") or L("flyOn")
		flyToggle.BackgroundColor3 = on and C.Green or C.Accent
		flyToggleStroke.Color = on and C.Green or C.Accent
		flyWinState.Text = on and L("flyFlying") or L("flyStopped")
		flyWinState.TextColor3 = on and C.Green or C.Dim
	end

	function Fly:SetEnabled(state)
		self.Enabled = state

		if state then
			self:Start()
			if not self.Active then
				self.Enabled = false
				syncFlyUI()
				notify(L("noChar"), C.Red)
				return
			end
			syncFlyUI()
			notify(string.format(L("flyOnMsg"), fmtSpeed(flySpeed)), C.Green)
		else
			self:Stop(true)
			syncFlyUI()
			notify(L("flyOffMsg"), C.Red)
		end
	end

	function Fly:Toggle()
		self:SetEnabled(not self.Enabled)
	end

	-- 接上界面按钮的回调（FlyToggleRequest 在前面已 forward declare）
	FlyToggleRequest = function()
		Fly:Toggle()
	end

	-- 伤害保护总开关：在飞就立刻开始 / 停止回零
	ShieldRequest = function(on)
		CONFIG.DamageShield = on
		if on then
			if Fly.Active then Spoof:Start() end
			notify(L("shieldOnMsg"), C.Green)
		else
			Spoof:Stop()
			local hum = getHumanoid()
			if hum then setDamageShield(hum, false) end
			notify(L("shieldOffMsg"), C.Red)
		end
	end

	syncFlyUI()

	-- 飞行窗口的 ✕：结束飞行（走落地保护，不会摔死）+ 收起窗口，不留胶囊
	FlyCloseRequest = function()
		Fly:SetEnabled(false)
		closeFlyWindow()
	end

	--========================== 全局连接（关闭时要能全断掉） ==========================
	local function track(conn)
		table.insert(GLOBAL_CONNS, conn)
		return conn
	end

	-- 快捷键
	track(UserInputService.InputBegan:Connect(function(input, processed)
		if SHUTDOWN or processed then return end
		if input.KeyCode == CONFIG.FlyKey then
			Fly:Toggle()
		end
	end))

	-- 复活后自动恢复飞行 + 重新应用通用属性
	track(LocalPlayer.CharacterAdded:Connect(function()
		if SHUTDOWN then return end
		Fly:Stop(false)
		Fly:StopShield()      -- 旧角色的回零 / 状态屏蔽全部撤掉，重新来过
		task.wait(0.8)
		if SHUTDOWN then return end
		applySettings()
		if Fly.Enabled then
			Fly:Start()
		end
	end))

	-- 相机重建时重算缩放
	track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.wait(0.2)
		if SHUTDOWN then return end
		updateScale()
	end))

	--=====================================================================
	--  主窗口 ✕ = 结束进程
	--  停飞行 → 撤伤害保护 → 断开所有连接 → 还原改过的属性 → 销毁界面
	--=====================================================================
	unloadAll = function(instant)
		if SHUTDOWN then return end
		SHUTDOWN = true

		-- 1. 停飞行。走缓降流程，别让玩家直接摔死
		pcall(function() Fly:SetEnabled(false) end)
		pcall(function() Fly:StopShield() end)
		local hum = getHumanoid()
		if hum then
			pcall(function() hum.PlatformStand = false end)
		end

		-- 2. 断开所有全局连接（含拖拽用的 InputChanged）
		for _, c in ipairs(GLOBAL_CONNS) do
			pcall(function() c:Disconnect() end)
		end
		GLOBAL_CONNS = {}

		-- 3. 还原被改过的全局属性（重力是 workspace 级的，必须还回去）
		pcall(function() workspace.Gravity = gravDef end)
		if hum then
			pcall(function() hum.WalkSpeed = walkDef end)
			pcall(function()
				hum.UseJumpPower = true
				hum.JumpPower = jumpDef
			end)
		end

		-- 4. 收起界面再销毁
		local function kill()
			pcall(function() guiMain:Destroy() end)
			pcall(function() notifyGui:Destroy() end)
			_G.O_X_HUB_LOADED = nil
		end

		if instant then
			kill()
			return
		end

		pcall(function()
			local t = TweenService:Create(
				uiScale,
				TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Scale = 0.86 }
			)
			t:Play()
		end)
		task.delay(0.16, kill)
	end

	ShutdownRequest = function()
		unloadAll(false)
	end

	_G.O_X_HUB_LOADED = unloadAll   -- 下次重复执行时能先把这一份卸干净

	--=====================================================================
	--  四、启动动画 -> 显示主界面
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
		notify(string.format(L("loaded"), CONFIG.Title, CONFIG.Version), C.Accent)
	end)
end

--=====================================================================
--  五、启动流程
--=====================================================================
-- 重启：把旧的整份卸掉，再用新语言跑一遍 boot。
-- 等价于重新注入，但不用联网，也不会闪一下语言选择页。
restart = function(lang)
	LANG = lang
	task.spawn(function()
		task.wait(0.45)                     -- 让"已切换语言"的提示先露个脸
		if unloadAll then pcall(unloadAll, true) end
		task.wait(0.12)
		boot(lang)
	end)
end

-- 注入后第一屏：选语言。选完才 boot（加载动画 + 主界面）
createLanguageScreen(function(lang)
	boot(lang)
end)
