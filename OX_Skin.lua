--[[
=====================================================================
   O_X HUB  ·  Skin Engine（主题与描边引擎，挂在 O_X UI 上的轻量扩展）
   ---------------------------------------------------------------
   用途   : 深色 / 浅色主题互切、描边批量重着色、RGB 循环（Chroma）模式
   用法   : local SE = require(...) or loadstring(...)()
            SE.attach(Theme, guiFrame)
            SE.setMode("light")          -- 切主题
            SE.chroma(true)              -- 开霓虹循环
   说明   : 只改颜色和描边，不动布局；失败不抛错，界面照常可用
=====================================================================
]]

local SE = {}

local Tween = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- 把 Color3 转成 "r,g,b" 便于比较
local function key(c)
	return string.format("%d,%d,%d,%d",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5),
		math.floor((c.A or 1) * 255 + 0.5))
end

--[[====================  内部状态  ====================]]

local State = {
	theme = nil,
	root = nil,
	conn = nil,
	chroma = false,
	base = {},
}

local BASE = {
	dark = {
		bg      = Color3.fromRGB(13, 14, 17),
		panel   = Color3.fromRGB(19, 20, 24),
		panel2  = Color3.fromRGB(28, 30, 35),
		stroke  = Color3.fromRGB(50, 53, 60),
		text    = Color3.fromRGB(240, 241, 244),
		sub     = Color3.fromRGB(130, 135, 145),
		accent  = Color3.fromRGB(124, 140, 255),
	},
	light = {
		bg      = Color3.fromRGB(246, 246, 248),
		panel   = Color3.fromRGB(255, 255, 255),
		panel2  = Color3.fromRGB(237, 238, 242),
		stroke  = Color3.fromRGB(212, 214, 220),
		text    = Color3.fromRGB(26, 27, 31),
		sub     = Color3.fromRGB(118, 122, 132),
		accent  = Color3.fromRGB(58, 78, 226),
	},
}

local function setOne(obj, role, color, time)
	local props = {}
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		if role == "text" or role == "sub" or role == "accent" then
			props.TextColor3 = color
		end
	end
	if obj:IsA("GuiObject") and (role == "bg" or role == "panel" or role == "panel2" or role == "accent") then
		props.BackgroundColor3 = color
	end
	if obj:IsA("UIStroke") then
		props.Color = color
	end
	if obj:IsA("Frame") and role == "accent" then
		props.BackgroundColor3 = color
	end
	if obj:IsA("UIGradient") and role == "accent" then
		props.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.35))
	end
	if next(props) then
		if time and time > 0 then
			Tween:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad), props):Play()
		else
			for k, v in next, props do
				pcall(function() obj[k] = v end)
			end
		end
	end
end

--[[====================  对外接口  ====================]]

-- 绑定主题表与根节点，之后所有重着色都走这里
function SE.attach(theme, root)
	State.theme = theme
	State.root = root
	if theme then
		State.base = BASE[theme.mode or "dark"] or BASE.dark
	end
	return SE
end

-- 给某个控件打上语义角色，切换主题时自动跟随
function SE.tag(obj, role)
	if obj then
		pcall(function() obj:SetAttribute("oxRole", role) end)
	end
	return obj
end

function SE.repaint(time)
	if not State.root or not State.theme then return end
	local pal = State.theme.palette or State.theme
	local t = time or 0.22
	for _, obj in ipairs(State.root:GetDescendants()) do
		local role = obj:GetAttribute("oxRole")
		if role and pal[role] then
			pcall(setOne, obj, role, pal[role], t)
		end
	end
end

-- 切换深色 / 浅色
function SE.setMode(mode)
	if not BASE[mode] then return end
	local theme = State.theme
	if not theme then return end
	theme.mode = mode
	local src = BASE[mode]
	for k, v in next, src do
		theme[k] = v
		theme.palette[k] = v
	end
	SE.repaint(0.25)
end

function SE.toggleMode()
	if not State.theme then return "dark" end
	if State.theme.mode == "dark" then
		SE.setMode("light")
	else
		SE.setMode("dark")
	end
	return State.theme.mode
end

-- 霓虹循环：描边与强调色按时间色相旋转
function SE.chroma(on)
	State.chroma = on == true
	if State.conn then
		pcall(function() State.conn:Disconnect() end)
		State.conn = nil
	end
	if not State.chroma or not State.root or not State.theme then
		return
	end
	State.conn = RunService.RenderStepped:Connect(function()
		local h = (os.clock() * 0.12) % 1
		local c = Color3.fromHSV(h, 0.55, 1)
		for _, obj in ipairs(State.root:GetDescendants()) do
			local role = obj:GetAttribute("oxRole")
			if role == "accent" and obj:IsA("UIStroke") then
				pcall(function() obj.Color = c end)
			end
		end
	end)
end

function SE.isChroma()
	return State.chroma
end

function SE.hex(h)
	h = tostring(h or "ffffff"):gsub("#", "")
	local r = tonumber(h:sub(1, 2), 16) or 255
	local g = tonumber(h:sub(3, 4), 16) or 255
	local b = tonumber(h:sub(5, 6), 16) or 255
	return rgb(r, g, b)
end

SE.rgb = rgb
SE.tag = SE.tag
SE.BASE = BASE

return SE
