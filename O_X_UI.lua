--[[
=====================================================================
   O_X HUB  ·  O_X UI v2.0 界面组件库  (O_X_UI.lua)
   ---------------------------------------------------------------
   风格   : 极简暗黑 / 大圆角 / 细描边 / 克制的蓝色强调
   导出   : 组件工厂 + Theme + 主题切换 + 微交互（hover 位移、按压回弹）
   依赖   : 无（纯 Roblox 实例，不依赖执行器）
   用法   : local UI = loadstring(...)()
            UI.mount(parent, {compact = false, scale = 1})
            UI.Toggle(page, "透视总开关", false, function(v) ... end)
=====================================================================
]]

local UI = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--[[====================  设计令牌  ====================]]

-- 主色板：写死在这里，切换主题只改一张表
local PALETTES = {
	dark = {
		bg      = Color3.fromRGB(13, 14, 17),
		panel   = Color3.fromRGB(19, 20, 24),
		panel2  = Color3.fromRGB(28, 30, 35),
		stroke  = Color3.fromRGB(48, 51, 58),
		text    = Color3.fromRGB(240, 241, 244),
		sub     = Color3.fromRGB(130, 135, 145),
		accent  = Color3.fromRGB(124, 140, 255),
		accent2 = Color3.fromRGB(196, 205, 255),
	},
	light = {
		bg      = Color3.fromRGB(247, 247, 249),
		panel   = Color3.fromRGB(255, 255, 255),
		panel2  = Color3.fromRGB(238, 239, 242),
		stroke  = Color3.fromRGB(214, 216, 222),
		text    = Color3.fromRGB(24, 25, 29),
		sub     = Color3.fromRGB(120, 124, 133),
		accent  = Color3.fromRGB(58, 78, 226),
		accent2 = Color3.fromRGB(120, 140, 255),
	},
}

local Theme = {
	mode    = "dark",
	bg      = PALETTES.dark.bg,
	panel   = PALETTES.dark.panel,
	panel2  = PALETTES.dark.panel2,
	stroke  = PALETTES.dark.stroke,
	text    = PALETTES.dark.text,
	sub     = PALETTES.dark.sub,
	accent  = PALETTES.dark.accent,
	accent2 = PALETTES.dark.accent2,
	palette = PALETTES.dark,
}

local FONT = Enum.Font.Gotham
local FONT_B = Enum.Font.GothamBold
local FONT_M = Enum.Font.GothamMedium

--[[====================  基础构造  ====================]]

local function mk(class, props, parent)
	local obj = Instance.new(class)
	for k, v in next, props do
		pcall(function() obj[k] = v end)
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

local function corner(radius, parent)
	return mk("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(color, thickness, transparency, parent)
	return mk("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function padding(parent, all, top, bottom)
	return mk("UIPadding", {
		PaddingLeft = UDim.new(0, all or 0),
		PaddingRight = UDim.new(0, all or 0),
		PaddingTop = UDim.new(0, top or all or 0),
		PaddingBottom = UDim.new(0, bottom or all or 0),
	}, parent)
end

local function tween(obj, time, props, style)
	TweenService:Create(obj, TweenInfo.new(time or 0.16, style or Enum.EasingStyle.Quad), props):Play()
end

-- 布局序号自增
local function nextOrder(parent)
	local n = (parent:GetAttribute("layoutOrder") or 0) + 1
	parent:SetAttribute("layoutOrder", n)
	return n
end

local function round(v, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(v * mult + 0.5) / mult
end

UI.mk = mk
UI.corner = corner
UI.stroke = stroke
UI.padding = padding
UI.tween = tween
UI.nextOrder = nextOrder
UI.round = round
UI.Theme = Theme
UI.PALETTES = PALETTES
UI.FONT = FONT
UI.FONT_B = FONT_B
UI.FONT_M = FONT_M

--[[====================  文字块  ====================]]

-- 快速文本，返回 TextLabel
function UI.text(parent, props)
	local conf = {
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}
	for k, v in next, props or {} do
		conf[k] = v
	end
	return mk("TextLabel", conf, parent)
end

-- 图标（用 UTF8 符号渲染，执行器无需贴图）
function UI.icon(parent, glyph, size, color, pos)
	return mk("TextLabel", {
		Size = UDim2.fromOffset(size or 16, size or 16),
		Position = pos or UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Font = FONT_B,
		TextSize = (size or 16) - 2,
		TextColor3 = color or Theme.sub,
		Text = glyph or "•",
	}, parent)
end

--[[====================  容器：卡片 / 分组  ====================]]

-- 首页统计卡
function UI.statCard(parent, label, valueOf)
	local card = mk("Frame", {
		Size = UDim2.new(0.25, -7, 0, 58),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
	}, parent)
	corner(12, card)
	stroke(Theme.stroke, 1, 0.55, card)

	mk("TextLabel", {
		Size = UDim2.new(1, -18, 0, 14),
		Position = UDim2.fromOffset(10, 11),
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 9,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label,
	}, card)

	local value = mk("TextLabel", {
		Size = UDim2.new(1, -18, 0, 20),
		Position = UDim2.fromOffset(10, 27),
		BackgroundTransparency = 1,
		Font = FONT_B,
		TextSize = 15,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "—",
	}, card)

	-- 右上角一点强调线
	mk("Frame", {
		Size = UDim2.fromOffset(14, 2),
		Position = UDim2.new(1, -24, 0, 12),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
	}, card)

	return function(v)
		if value and value.Parent then
			value.Text = tostring(v)
		end
	end
end

-- 区块标题：小字 + 细线，极简
function UI.section(parent, text)
	local holder = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(parent),
	}, parent)

	mk("TextLabel", {
		Size = UDim2.fromOffset(200, 26),
		BackgroundTransparency = 1,
		Font = FONT_B,
		TextSize = 10,
		TextColor3 = Theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(text or ""),
	}, holder)

	mk("Frame", {
		Size = UDim2.new(1, -206, 0, 1),
		Position = UDim2.fromOffset(206, 13),
		BackgroundColor3 = Theme.stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
	}, holder)

	return holder
end

function UI.label(parent, text, height, color)
	return UI.text(parent, {
		Size = UDim2.new(1, 0, 0, height or 30),
		TextSize = 11,
		TextColor3 = color or Theme.sub,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.15,
		Text = text,
		LayoutOrder = nextOrder(parent),
	}, parent)
end

--[[====================  开关  ====================]]

function UI.toggle(parent, text, default, callback)
	local state = default == true

	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
	}, parent)
	corner(10, row)
	local rowStroke = stroke(Theme.stroke, 1, 0.6, row)

	mk("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
	}, row)

	local track = mk("Frame", {
		Size = UDim2.fromOffset(34, 18),
		Position = UDim2.new(1, -46, 0.5, -9),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
	}, row)
	corner(9, track)

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Theme.sub,
		BorderSizePixel = 0,
	}, track)
	corner(6, knob)

	local function paint(animate)
		local on = state
		local trackGoal = on and Theme.accent or Theme.panel2
		local knobGoal = on and Color3.fromRGB(255, 255, 255) or Theme.sub
		local posGoal = on and UDim2.new(1, -15, 0, 3) or UDim2.fromOffset(3, 3)
		if animate then
			tween(track, 0.18, { BackgroundColor3 = trackGoal })
			tween(knob, 0.18, { BackgroundColor3 = knobGoal, Position = posGoal })
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
	}, row)

	hit.MouseEnter:Connect(function()
		tween(row, 0.15, { BackgroundColor3 = Theme.panel2 })
		rowStroke.Transparency = 0.3
	end)
	hit.MouseLeave:Connect(function()
		tween(row, 0.15, { BackgroundColor3 = Theme.panel })
		rowStroke.Transparency = 0.6
	end)
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

--[[====================  滑块  ====================]]

local sliderDrag = { active = nil }

UserInputService.InputChanged:Connect(function(input)
	if sliderDrag.active and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		pcall(sliderDrag.active, input.Position)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		sliderDrag.active = nil
	end
end)

function UI.slider(parent, text, min, max, default, decimals, callback)
	local value = default

	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
	}, parent)
	corner(10, row)
	stroke(Theme.stroke, 1, 0.6, row)

	mk("TextLabel", {
		Size = UDim2.new(1, -70, 0, 20),
		Position = UDim2.fromOffset(12, 8),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
	}, row)

	local valueLabel = mk("TextLabel", {
		Size = UDim2.fromOffset(64, 20),
		Position = UDim2.new(1, -70, 0, 8),
		BackgroundTransparency = 1,
		Font = FONT_B,
		TextSize = 11,
		TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
	}, row)

	local track = mk("Frame", {
		Size = UDim2.new(1, -24, 0, 3),
		Position = UDim2.fromOffset(12, 32),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
	}, row)
	corner(2, track)

	local fill = mk("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
	}, track)
	corner(2, fill)

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(0, -5, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, track)
	corner(5, knob)

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
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 22),
		BackgroundTransparency = 1,
		Text = "",
	}, row)

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			sliderDrag.active = applyFromPosition
			applyFromPosition(input.Position)
		end
	end)

	setValue(default, false)

	return function(v, silent)
		setValue(v, false)
		if not silent and callback then callback(v) end
	end
end

--[[====================  按钮  ====================]]

function UI.button(parent, text, callback, accent)
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = accent and Theme.accent or Theme.panel,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(parent),
	}, parent)
	corner(10, btn)
	local s = stroke(accent and Theme.accent2 or Theme.stroke, 1, accent and 0.5 or 0.6, btn)

	local label = mk("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = FONT_B,
		TextSize = 12,
		TextColor3 = accent and Color3.fromRGB(255, 255, 255) or Theme.text,
		Text = text,
	}, btn)

	btn.MouseEnter:Connect(function()
		if accent then
			tween(btn, 0.15, { BackgroundColor3 = Theme.accent2 })
		else
			tween(btn, 0.15, { BackgroundColor3 = Theme.panel2 })
		end
		s.Transparency = 0.2
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundColor3 = accent and Theme.accent or Theme.panel })
		s.Transparency = accent and 0.5 or 0.6
	end)
	btn.MouseButton1Click:Connect(function()
		-- 按压回弹
		pcall(function()
			local us = btn:FindFirstChildOfClass("UIScale") or mk("UIScale", { Scale = 1 }, btn)
			tween(us, 0.06, { Scale = 0.97 })
			task.delay(0.08, function()
				if us and us.Parent then
					tween(us, 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
				end
			end)
		end)
		if callback then callback() end
	end)

	return btn
end

-- 小号操作按钮（行内，如「应用」「复制」）
function UI.chip(parent, text, callback, width)
	local btn = mk("TextButton", {
		Size = UDim2.fromOffset(width or 64, 26),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, parent)
	corner(8, btn)

	mk("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = FONT_B,
		TextSize = 10,
		TextColor3 = Theme.text,
		Text = text,
	}, btn)

	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.accent end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.panel2 end)
	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	return btn
end

--[[====================  下拉  ====================]]

function UI.dropdown(parent, text, options, default, callback, overlayParent)
	local value = default

	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
	}, parent)
	corner(10, row)
	stroke(Theme.stroke, 1, 0.6, row)

	mk("TextLabel", {
		Size = UDim2.new(1, -150, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
	}, row)

	local btn = mk("TextButton", {
		Size = UDim2.fromOffset(126, 24),
		Position = UDim2.new(1, -138, 0.5, -12),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, row)
	corner(8, btn)

	local btnLabel = mk("TextLabel", {
		Size = UDim2.new(1, -22, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = tostring(value),
	}, btn)

	mk("TextLabel", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(1, -16, 0.5, -5),
		BackgroundTransparency = 1,
		Font = FONT_B,
		TextSize = 8,
		TextColor3 = Theme.sub,
		Text = "▼",
	}, btn)

	local popup, backdrop

	local function close()
		if backdrop then
			pcall(function() backdrop:Destroy() end)
			backdrop = nil
		end
		if popup then
			pcall(function() popup:Destroy() end)
			popup = nil
		end
	end

	local function open()
		if popup then
			close()
			return
		end
		local host = overlayParent or row:FindFirstAncestorOfClass("ScreenGui") or row
		local cam = workspace.CurrentCamera
		local screen = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local abs = btn.AbsolutePosition
		local absSize = btn.AbsoluteSize
		local h = math.min(#options * 26 + 8, 8 * 26 + 8)
		local px = math.clamp(abs.X, 8, math.max(screen.X - 146, 8))
		local py = math.clamp(abs.Y + absSize.Y + 4, 8, math.max(screen.Y - h - 8, 8))

		backdrop = mk("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 90,
		}, host)
		backdrop.MouseButton1Click:Connect(close)

		popup = mk("Frame", {
			Size = UDim2.fromOffset(140, h),
			Position = UDim2.fromOffset(px, py),
			BackgroundColor3 = Theme.panel,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 100,
		}, host)
		corner(10, popup)
		stroke(Theme.stroke, 1, 0.2, popup)
		padding(popup, 4)

		local list = mk("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.stroke,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 101,
		}, popup)
		mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

		for i, opt in ipairs(options) do
			local item = mk("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Theme.panel,
				BackgroundTransparency = (opt == value) and 0.75 or 1,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 102,
			}, list)
			corner(7, item)

			mk("TextLabel", {
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				BackgroundTransparency = 1,
				Font = (opt == value) and FONT_B or FONT,
				TextSize = 11,
				TextColor3 = (opt == value) and Theme.accent or Theme.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(opt),
				ZIndex = 103,
			}, item)

			item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.85 end)
			item.MouseLeave:Connect(function()
				item.BackgroundTransparency = (opt == value) and 0.75 or 1
			end)
			item.MouseButton1Click:Connect(function()
				value = opt
				btnLabel.Text = tostring(value)
				close()
				if callback then callback(value) end
			end)
		end
	end

	btn.MouseButton1Click:Connect(open)

	return function(v, silent)
		value = v
		btnLabel.Text = tostring(v)
		if not silent and callback then callback(v) end
	end
end

--[[====================  输入框  ====================]]

function UI.input(parent, text, default, callback)
	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
	}, parent)
	corner(10, row)
	local s = stroke(Theme.stroke, 1, 0.6, row)

	mk("TextLabel", {
		Size = UDim2.new(1, -150, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	}, row)

	local box = mk("TextBox", {
		Size = UDim2.fromOffset(126, 24),
		Position = UDim2.new(1, -138, 0.5, -12),
		BackgroundColor3 = Theme.panel2,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.text,
		Text = default or "",
		PlaceholderText = "填写 ID",
		PlaceholderColor3 = Theme.sub,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	corner(8, box)
	padding(box, 8)

	box.Focused:Connect(function()
		s.Transparency = 0
		s.Color = Theme.accent
	end)
	box.FocusLost:Connect(function()
		s.Transparency = 0.6
		s.Color = Theme.stroke
		if callback then callback(box.Text) end
	end)

	return box
end

--[[====================  调色板行  ====================]]

function UI.swatches(parent, title, colors, callback)
	local row = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(parent),
	}, parent)
	corner(10, row)
	stroke(Theme.stroke, 1, 0.6, row)

	mk("TextLabel", {
		Size = UDim2.fromOffset(60, 34),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
	}, row)

	for i, c in ipairs(colors) do
		local sw = mk("TextButton", {
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(74 + (i - 1) * 26, 8),
			BackgroundColor3 = c[2],
			Text = "",
			AutoButtonColor = false,
		}, row)
		corner(9, sw)
		sw.MouseButton1Click:Connect(function()
			if callback then callback(c[1], c[2]) end
		end)
	end

	return row
end

UI.Theme.mode = "dark"

--[[====================  主挂载：窗口骨架  ====================]]

function UI.mount(parent, conf)
	conf = conf or {}
	local compact = conf.compact == true
	local scaleValue = conf.scale or 1
	local W, H = 720, 480

	local gui = mk("ScreenGui", {
		Name = "OX_HUB",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	}, parent)

	local win = mk("Frame", {
		Name = "Window",
		Size = compact and UDim2.fromScale(1, 1) or UDim2.fromOffset(W, H),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui)

	-- 外壳：底色 + 大圆角，桌面端有 1px 描边
	local shell = mk("Frame", {
		Name = "Shell",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.bg,
		BorderSizePixel = 0,
	}, win)
	corner(12, shell)
	stroke(Theme.stroke, 1, 0.45, shell)

	local layout = {
		gui = gui,
		win = win,
		shell = shell,
		compact = compact,
		scale = scaleValue,
	}
	return layout
end

return UI
