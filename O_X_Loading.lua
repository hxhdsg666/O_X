--[[
=====================================================================
   O_X HUB  ·  Loading  v2.0（O_X_Loading.lua）
   ---------------------------------------------------------------
   效果   : 全屏循环播放视频（色块渲染，不依赖执行器图像解码）
            + 缓慢推拉镜头 + 扫描线 + 暗角
            + 圆形封面图标 + 环形进度 + 打字机字幕 + 百分比
            + 结束白闪与缩放淡出
   参数   : { assets, theme, gui, duration, speed, cols, rows, onDone }
   兜底   : 无贴图数据时退化为流动渐变，动画照常跑完，不会卡死
=====================================================================
]]

local Loading = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local c3 = Color3.fromRGB

--[[---- base64 解码（纯 Lua，任何执行器可用）----]]
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64map = {}
for i = 1, #B64 do
	b64map[string.sub(B64, i, i)] = i - 1
end

local function b64decode(s)
	local out = {}
	local buf = 0
	local bits = 0
	for i = 1, #s do
		local ch = string.sub(s, i, i)
		local v = b64map[ch]
		if v then
			buf = buf * 64 + v
			bits = bits + 6
			if bits >= 8 then
				bits = bits - 8
				out[#out + 1] = math.floor(buf / (2 ^ bits)) % 256
			end
		end
	end
	return out
end

--[[---- 把整段流解析成「每帧一张色块表」----]]
-- 数据格式：frames * cols * rows * 3 字节的原始 RGB + 尾部压缩预览字节
local function parseFrames(assets)
	local raw = b64decode(assets.stream or "")
	local cols = assets.cols or 18
	local rows = assets.rows or 12
	local frameCount = assets.frames or 0
	local per = cols * rows * 3
	local out = {}
	if #raw < per * frameCount or frameCount == 0 then
		return out, cols, rows
	end
	for f = 0, frameCount - 1 do
		local base = f * per
		local grid = table.create(cols * rows)
		for i = 0, cols * rows - 1 do
			local o = base + i * 3 + 1
			grid[i + 1] = { raw[o] or 0, raw[o + 1] or 0, raw[o + 2] or 0 }
		end
		out[f + 1] = grid
	end
	return out, cols, rows
end

--[[======  主函数  ======]]

function Loading.run(cfg)
	local assets = cfg.assets
	local Theme = cfg.theme or { accent = c3(124, 140, 255), bg = c3(13, 14, 17) }
	local gui = cfg.gui
	local COLS = cfg.cols or (assets and assets.cols) or 18
	local ROWS = cfg.rows or (assets and assets.rows) or 12
	local ended = false
	local conns = {}

	local layer = Instance.new("Frame")
	layer.Name = "Loading"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundColor3 = c3(5, 5, 7)
	layer.BorderSizePixel = 0
	layer.ZIndex = 600
	layer.Parent = gui

	-- 舞台（整体推拉）
	local stage = Instance.new("Frame")
	stage.Size = UDim2.fromScale(1.1, 1.1)
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.BackgroundColor3 = c3(8, 8, 10)
	stage.BorderSizePixel = 0
	stage.ClipsDescendants = true
	stage.ZIndex = 601
	stage.Parent = layer

	-- 色块网格
	local cellW = 1 / COLS
	local cellH = 1 / ROWS
	local cells = {}
	for row = 0, ROWS - 1 do
		for col = 0, COLS - 1 do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.new(cellW + 0.006, 0, cellH + 0.006, 0)
			cell.Position = UDim2.new(col * cellW, 0, row * cellH, 0)
			cell.BackgroundColor3 = c3(22, 22, 26)
			cell.BorderSizePixel = 0
			cell.ZIndex = 601
			cell.Parent = stage
			cells[(row * COLS) + col + 1] = cell
		end
	end

	-- 暗角
	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = c3(0, 0, 0)
	shade.BackgroundTransparency = 0.35
	shade.BorderSizePixel = 0
	shade.ZIndex = 604
	shade.Parent = layer

	local topGrad = Instance.new("Frame")
	topGrad.Size = UDim2.new(1, 0, 0.5, 0)
	topGrad.BackgroundColor3 = c3(0, 0, 0)
	topGrad.BorderSizePixel = 0
	topGrad.ZIndex = 605
	topGrad.Parent = layer
	local tg = Instance.new("UIGradient")
	tg.Rotation = 90
	tg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	tg.Parent = topGrad

	local botGrad = Instance.new("Frame")
	botGrad.Size = UDim2.new(1, 0, 0.6, 0)
	botGrad.Position = UDim2.fromScale(0, 0.4)
	botGrad.BackgroundColor3 = c3(0, 0, 0)
	botGrad.BorderSizePixel = 0
	botGrad.ZIndex = 605
	botGrad.Parent = layer
	local bg2 = Instance.new("UIGradient")
	bg2.Rotation = 270
	bg2.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	bg2.Parent = botGrad

	-- 扫描线
	local scan = Instance.new("Frame")
	scan.Size = UDim2.new(1, 0, 0, 2)
	scan.BackgroundColor3 = c3(255, 255, 255)
	scan.BackgroundTransparency = 0.9
	scan.BorderSizePixel = 0
	scan.ZIndex = 606
	scan.Parent = layer

	--[[------ 中央信息区 ------]]
	local stack = Instance.new("Frame")
	stack.Size = UDim2.fromOffset(340, 280)
	stack.AnchorPoint = Vector2.new(0.5, 0.5)
	stack.Position = UDim2.fromScale(0.5, 0.5)
	stack.BackgroundTransparency = 1
	stack.ZIndex = 610
	stack.Parent = layer

	local ringBg = Instance.new("Frame")
	ringBg.Size = UDim2.fromOffset(96, 96)
	ringBg.AnchorPoint = Vector2.new(0.5, 0)
	ringBg.Position = UDim2.new(0.5, 0, 0, 0)
	ringBg.BackgroundTransparency = 1
	ringBg.ZIndex = 611
	ringBg.Parent = stack
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(1, 0)
	rc.Parent = ringBg
	local rs = Instance.new("UIStroke")
	rs.Color = c3(255, 255, 255)
	rs.Thickness = 1
	rs.Transparency = 0.85
	rs.Parent = ringBg

	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromOffset(96, 96)
	ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.new(0.5, 0, 0, 0)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 612
	ring.Parent = stack
	local rc2 = Instance.new("UICorner")
	rc2.CornerRadius = UDim.new(1, 0)
	rc2.Parent = ring
	local rs2 = Instance.new("UIStroke")
	rs2.Color = Theme.accent
	rs2.Thickness = 2
	rs2.Transparency = 1
	rs2.Parent = ring
	local ringGrad = Instance.new("UIGradient")
	ringGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	ringGrad.Parent = rs2

	-- 圆形封面图标（色块拼）
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(64, 64)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 16)
	icon.BackgroundColor3 = c3(18, 18, 22)
	icon.BorderSizePixel = 0
	icon.ClipsDescendants = true
	icon.ZIndex = 613
	icon.Parent = stack
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(1, 0)
	ic.Parent = icon
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = c3(255, 255, 255)
	iconStroke.Thickness = 1
	iconStroke.Transparency = 0.55
	iconStroke.Parent = icon

	local iconGrid = Instance.new("Frame")
	iconGrid.Size = UDim2.fromScale(1, 1)
	iconGrid.BackgroundTransparency = 1
	iconGrid.ZIndex = 614
	iconGrid.Parent = icon
	local iconCells = {}
	for r = 0, 5 do
		for c2 = 0, 5 do
			local d = Instance.new("Frame")
			d.Size = UDim2.new(1 / 6, 0, 1 / 6, 0)
			d.Position = UDim2.new(c2 / 6, 0, r / 6, 0)
			d.BackgroundColor3 = c3(28, 28, 34)
			d.BorderSizePixel = 0
			d.ZIndex = 614
			d.Parent = iconGrid
			iconCells[#iconCells + 1] = d
		end
	end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.Position = UDim2.fromOffset(0, 116)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 21
	title.TextColor3 = c3(255, 255, 255)
	title.Text = "O_X  HUB"
	title.TextTransparency = 1
	title.ZIndex = 615
	title.Parent = stack

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0, 14)
	sub.Position = UDim2.fromOffset(0, 148)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 9
	sub.TextColor3 = c3(214, 216, 224)
	sub.TextTransparency = 0.35
	sub.Text = ""
	sub.ZIndex = 615
	sub.Parent = stack

	local pct = Instance.new("TextLabel")
	pct.Size = UDim2.new(1, 0, 0, 14)
	pct.Position = UDim2.fromOffset(0, 176)
	pct.BackgroundTransparency = 1
	pct.Font = Enum.Font.GothamBold
	pct.TextSize = 10
	pct.TextColor3 = c3(255, 255, 255)
	pct.TextTransparency = 0.25
	pct.Text = "0%"
	pct.ZIndex = 615
	pct.Parent = stack

	local lineBg = Instance.new("Frame")
	lineBg.Size = UDim2.fromOffset(168, 2)
	lineBg.AnchorPoint = Vector2.new(0.5, 0)
	lineBg.Position = UDim2.new(0.5, 0, 0, 198)
	lineBg.BackgroundColor3 = c3(255, 255, 255)
	lineBg.BackgroundTransparency = 0.85
	lineBg.BorderSizePixel = 0
	lineBg.ZIndex = 615
	lineBg.Parent = stack
	local lbc = Instance.new("UICorner")
	lbc.CornerRadius = UDim.new(1, 0)
	lbc.Parent = lineBg

	local lineFill = Instance.new("Frame")
	lineFill.Size = UDim2.new(0, 0, 1, 0)
	lineFill.BackgroundColor3 = c3(255, 255, 255)
	lineFill.BorderSizePixel = 0
	lineFill.ZIndex = 616
	lineFill.Parent = lineBg
	local lfc = Instance.new("UICorner")
	lfc.CornerRadius = UDim.new(1, 0)
	lfc.Parent = lineBg

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = c3(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 640
	flash.Parent = layer

	--[[------ 预处理帧 ------]]
	local frames = {}
	if assets and assets.stream then
		local ok, data = pcall(parseFrames, assets)
		if ok and data then
			frames = data
		end
	end

	if assets and assets.icon then
		local ok, raw = pcall(b64decode, assets.icon or "")
		if ok and raw and #raw >= 6 * 6 * 3 then
			for i, cell in ipairs(iconCells) do
				local o = (i - 1) * 3 + 1
				local r = raw[o] or 30
				local g = raw[o + 1] or 30
				local b = raw[o + 2] or 36
				cell.BackgroundColor3 = c3(
					math.clamp(math.floor(r * 1.02 + 10), 0, 255),
					math.clamp(math.floor(g * 1.02 + 8), 0, 255),
					math.clamp(math.floor(b * 1.02 + 14), 0, 255)
				)
			end
		end
	end

	--[[------ 播放 ------]]
	local idx = 0
	local frameCount = #frames
	local fps = (assets and assets.fps or 12) * (cfg.speed or 1)
	local fpsAcc = 0

	local function paint()
		if frameCount == 0 then
			local t = os.clock() * 0.25
			for i, cell in ipairs(cells) do
				local h = (math.sin(t + i * 0.11) + 1) * 0.5
				cell.BackgroundColor3 = c3(12, 12, 16):Lerp(c3(48, 50, 64), h * 0.6)
			end
			return
		end
		idx = (idx % frameCount) + 1
		local grid = frames[idx]
		for i, cell in ipairs(cells) do
			local v = grid[i]
			if v then
				cell.BackgroundColor3 = c3(
					math.clamp(math.floor(v[1] + 6), 0, 255),
					math.clamp(math.floor(v[2] + 6), 0, 255),
					math.clamp(math.floor(v[3] + 10), 0, 255)
				)
			end
		end
	end

	local function stopAll()
		ended = true
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		conns = {}
	end

	paint()

	conns[#conns + 1] = RunService.Heartbeat:Connect(function(dt)
		if ended then return end
		fpsAcc = fpsAcc + dt
		if fpsAcc >= 1 / fps then
			fpsAcc = 0
			paint()
		end
		local p = (math.sin(os.clock() * 0.32) + 1) * 0.5
		local s = 1.08 + p * 0.06
		stage.Size = UDim2.fromScale(s, s)
		local sp = (os.clock() * 0.26) % 1
		scan.Position = UDim2.fromScale(0, sp)
		scan.BackgroundTransparency = 0.88 + math.sin(sp * math.pi) * 0.04
	end)

	-- 图标呼吸
	task.spawn(function()
		while not ended and icon.Parent do
			pcall(function()
				TweenService:Create(iconStroke, TweenInfo.new(1.0), { Transparency = 0.15 }):Play()
			end)
			task.wait(1.0)
			if ended then break end
			pcall(function()
				TweenService:Create(iconStroke, TweenInfo.new(1.0), { Transparency = 0.7 }):Play()
			end)
			task.wait(1.0)
		end
	end)

	-- 标题浮现
	pcall(function()
		local us = Instance.new("UIScale")
		us.Scale = 0.92
		us.Parent = title
		TweenService:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
		TweenService:Create(us, TweenInfo.new(0.7, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)

	local function setProgress(p)
		p = math.clamp(p, 0, 1)
		lineFill.Size = UDim2.new(p, 0, 1, 0)
		pct.Text = string.format("%d%%", math.floor(p * 100 + 0.5))
		if p > 0.01 then
			rs2.Transparency = 0.35
			ringGrad.Rotation = 45
			ringGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05),
				NumberSequenceKeypoint.new(math.max(p - 0.1, 0.01), 0.15),
				NumberSequenceKeypoint.new(p, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
	end

	local steps = {
		"正在挂载界面引擎…",
		"正在解码视频帧…",
		"正在载入透视与锁头模块…",
		"正在校准平滑与 FOV…",
		"正在准备 FlyV2…",
		"正在连接外部脚本…",
		"准备就绪",
	}
	local typeToken = 0
	local function typeText(text)
		typeToken = typeToken + 1
		local mine = typeToken
		sub.Text = ""
		for i = 1, #text do
			if ended or mine ~= typeToken then return end
			sub.Text = string.sub(text, 1, i)
			task.wait(0.018)
		end
	end

	task.spawn(function()
		local duration = cfg.duration or 4.0
		local per = duration / #steps
		for i = 1, #steps do
			task.spawn(typeText, steps[i])
			local t0 = os.clock()
			local from = (i - 1) / #steps
			local to = i / #steps
			while not ended do
				local p = math.clamp((os.clock() - t0) / per, 0, 1)
				local eased = 1 - (1 - p) * (1 - p)
				setProgress(from + (to - from) * eased)
				if p >= 1 then break end
				task.wait(0.016)
			end
		end
		if ended then return end
		setProgress(1)
		sub.Text = "准备就绪"
		task.wait(0.18)

		pcall(function()
			TweenService:Create(flash, TweenInfo.new(0.07), { BackgroundTransparency = 0.5 }):Play()
			for _, d in ipairs(stack:GetDescendants()) do
				if d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
				elseif d:IsA("UIStroke") then
					TweenService:Create(d, TweenInfo.new(0.2), { Transparency = 1 }):Play()
				end
			end
		end)
		task.wait(0.09)
		pcall(function()
			TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(stage, TweenInfo.new(0.42, Enum.EasingStyle.Quad), {
				Size = UDim2.fromScale(1.24, 1.24),
			}):Play()
			TweenService:Create(shade, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(layer, TweenInfo.new(0.42), { BackgroundTransparency = 1 }):Play()
			for _, cell in ipairs(cells) do
				TweenService:Create(cell, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			end
		end)
		task.wait(0.45)
		stopAll()
		layer.Visible = false
		if cfg.onDone then
			task.spawn(cfg.onDone)
		end
		task.delay(0.5, function()
			pcall(function() layer:Destroy() end)
		end)
	end)

	return {
		layer = layer,
		setProgress = setProgress,
		stop = stopAll,
	}
end

return Loading
