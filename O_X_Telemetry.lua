--[[
=====================================================================
   O_X HUB  ·  Telemetry（O_X_Telemetry.lua 运行状态面板）
   ---------------------------------------------------------------
   用途   : 顶栏「LIVE」灯 + 底部状态条，实时显示 FPS / Ping / 内存 / 在线人数
   特性   : 每 0.5s 采样一次，不占用 RenderStepped；掉帧时灯变红
   依赖   : 无
=====================================================================
]]

local Telemetry = {}

local RunService = game:GetService("RunService")
local Stats = nil
pcall(function()
	Stats = game:GetService("Stats")
end)
local Players = game:GetService("Players")

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

-- 采样器：返回只读快照
function Telemetry.sampler()
	local frames = 0
	local acc = 0
	local fps = 60

	RunService.Heartbeat:Connect(function(dt)
		frames = frames + 1
		acc = acc + dt
		if acc >= 0.5 then
			fps = math.floor(frames / acc + 0.5)
			frames = 0
			acc = 0
		end
	end)

	local function ping()
		local ok, value = pcall(function()
			return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if ok and typeof(value) == "number" then
			return math.floor(value + 0.5)
		end
		return -1
	end

	local function memory()
		local ok, value = pcall(function()
			return Stats:GetTotalMemoryUsageMb()
		end)
		if ok and typeof(value) == "number" then
			return math.floor(value + 0.5)
		end
		return -1
	end

	return function()
		return {
			fps = fps,
			ping = ping(),
			mem = memory(),
			players = #Players:GetPlayers(),
		}
	end
end

-- 顶栏 LIVE 指示灯：返回 {setState(fps)}
function Telemetry.lamp(parent, theme)
	local holder = mk("Frame", {
		Name = "Live",
		Size = UDim2.fromOffset(58, 20),
		BackgroundColor3 = theme.panel2 or Color3.fromRGB(28, 30, 35),
		BorderSizePixel = 0,
	}, parent)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, holder)

	local dot = mk("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.fromOffset(9, 7),
		BackgroundColor3 = theme.green or theme.accent or Color3.fromRGB(120, 230, 170),
		BorderSizePixel = 0,
	}, holder)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

	local label = mk("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(19, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "LIVE",
	}, holder)

	return function(state)
		if not holder or not holder.Parent then return end
		local text = state.text or "LIVE"
		local healthy = state.healthy ~= false
		label.Text = text
		label.TextColor3 = healthy and (theme.sub or Color3.fromRGB(130, 135, 145)) or Color3.fromRGB(255, 120, 110)
		dot.BackgroundColor3 = healthy and (theme.green or theme.accent) or Color3.fromRGB(255, 92, 80)
	end
end

-- 底部状态文本，返回 set(text)
function Telemetry.footerText(parent, theme, initial)
	return mk("TextLabel", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = theme.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = initial or "",
		Parent = parent,
	})
end

Telemetry.mk = mk

return Telemetry
