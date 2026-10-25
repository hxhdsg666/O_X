--[[
=====================================================================
   O_X HUB  ·  Runtime（O_X_Runtime.lua 轻量运行时工具）
   ---------------------------------------------------------------
   提供   : 节流任务、带缓存的 HTTP、安全的 getgenv 读写、版本比较
            UI 用的字符串宽度估算、列表差分刷新
   说明   : 全部 pcall 包裹，执行器缺什么就退化成空操作，绝不让主流程崩
=====================================================================
]]

local Runtime = {}

--[[---- 节流：同一 key 在 interval 内只跑一次 ----]]
local throttle = {}
function Runtime.once(key, interval, fn)
	local now = os.clock()
	local last = throttle[key]
	if last and (now - last) < (interval or 1) then
		return false
	end
	throttle[key] = now
	return pcall(fn) or false
end

--[[---- 带缓存 HTTP ----]]
local httpCache = {}
function Runtime.http(url, ttl)
	ttl = ttl or 300
	local hit = httpCache[url]
	if hit and (os.clock() - hit.t) < ttl then
		return hit.body
	end
	local body = nil
	pcall(function()
		body = game:HttpGet(url, true)
	end)
	if body then
		httpCache[url] = { body = body, t = os.clock() }
	end
	return body, (body ~= nil)
end

--[[---- getgenv 安全读写 ----]]
function Runtime.setGlobal(name, value)
	if getgenv then
		pcall(function()
			getgenv()[name] = value
		end)
	end
end

function Runtime.getGlobal(name)
	if getgenv then
		local ok, value = pcall(function()
			return getgenv()[name]
		end)
		if ok then return value end
	end
	return nil
end

--[[---- 版本比较：返回 1 / 0 / -1 ----]]
function Runtime.compareVersion(a, b)
	local function parts(v)
		local t = {}
		for n in tostring(v or "0"):gmatch("%d+") do
			t[#t + 1] = tonumber(n)
		end
		return t
	end
	local pa, pb = parts(a), parts(b)
	for i = 1, math.max(#pa, #pb) do
		local x = pa[i] or 0
		local y = pb[i] or 0
		if x > y then return 1 end
		if x < y then return -1 end
	end
	return 0
end

--[[---- 估算文本像素宽度（Gotham 12 号约为 0.58 倍字号） ----]]
function Runtime.textWidth(text, size)
	return math.floor(#tostring(text or "") * (size or 12) * 0.56)
end

--[[---- 列表差分：按 id 复用行，避免刷新闪烁 ----]]
function Runtime.diff(rows, items, keyOf, createRow, updateRow)
	local seen = {}
	for _, item in ipairs(items) do
		local key = keyOf(item)
		seen[key] = true
		local row = rows[key]
		if not row then
			row = createRow(item, key)
			rows[key] = row
		end
		updateRow(row, item)
	end
	for key, row in pairs(rows) do
		if not seen[key] then
			pcall(function() row:Destroy() end)
			rows[key] = nil
		end
	end
end

--[[---- 安全执行字符串脚本（脚本中心用） ----]]
function Runtime.execute(source, label)
	if type(source) ~= "string" or source == "" then
		return false, "空脚本"
	end
	local fn, err = nil, nil
	pcall(function()
		fn = loadstring(source)
	end)
	if type(fn) ~= "function" then
		return false, "编译失败：" .. tostring(err or "语法错误")
	end
	local ok, res = pcall(fn)
	if not ok then
		return false, tostring(res)
	end
	return true, tostring(res or "已执行") .. (label and (" · " .. label) or "")
end

--[[---- 时间格式化 ----]]
function Runtime.clock(seconds)
	seconds = math.floor(seconds or 0)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

return Runtime
