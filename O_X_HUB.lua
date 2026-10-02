--=====================================================================
--  O_X HUB  ·  通用设置 + 飞行
--  Version : 1.9.1
--  Date    : 2026-10-01
--
--  用法（执行器里粘贴执行）：
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/hxhdsg666/O_X/refs/heads/main/O_X_HUB.lua"))()
--
--  说明：
--    · 注入后第一屏是语言选择（英文 / 中文），选完才进加载动画
--    · 界面文案跟随所选语言；只有 "O_X HUB" 这个名字两种语言都不翻译
--    · 主窗口做成软件样式：右上角 － 最小化成图标 / ✕ 结束整个脚本
--    · 左侧是功能列表：主页 / 服务器 / 通用（速度·跳跃·重力）/ 飞行 / 设置
--    · 服务器：自然灾害模拟器（传送 / 农场）+ 劫案（主游戏无脚本，进地图才解锁潜入 / 强攻）
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
		navServers   = "服务器",
		navGeneral   = "通用",
		navFly       = "飞行",
		navSettings  = "设置",

		-- 服务器列表
		srvTitle     = "服务器脚本",
		srvSub       = "挑一个服务器，打开它专属的脚本面板",
		srvOpen      = "打开",
		srvMore      = "更多服务器还在做",
		srvNds       = "自然灾害模拟器",
		srvHeist     = "Notoriety",

		denyTitle    = "未在对应服务器内",
		denyBody     = "这个脚本只能在「%s」里用，你现在不在这个服务器。",
		denyNow      = "当前 Place ID：%s",
		denyJoin     = "加入对应服务器",
		joinOk       = "正在加入「%s」  ·  落地后会自动重新执行脚本",
		joinNoQueue  = "正在加入「%s」  ·  这个执行器不支持传送后自动执行，落地后请手动再注入一次",
		joinVia      = "正在加入「%s」（通过 %s）",
		joinFail     = "加入失败：%s  ·  游戏链接已复制到剪贴板，请用浏览器打开",
		joinSilent   = "传送未生效（执行器或 Roblox 拦截了）  ·  游戏链接已复制，请用浏览器打开",
		joinPending  = "已记下「%s」为目标服务器  ·  下次进入任意服务器时脚本会自动重试传送",
		joinPendingRetry = "上次未加入「%s」  ·  现在自动重试传送",

		-- 服务器面板
		srvTabTp     = "传送",
		srvTabFarm   = "农场",

		tpTitle      = "传送",
		tpSub        = "选一个地点，再点下面的按钮过去",
		tpLocSpawn   = "出生点",
		tpLocSpawnD  = "大厅出生点，灾害打不到这里",
		tpLocField   = "游戏场地",
		tpLocFieldD  = "每局开始所有人被送过去的那个岛",
		tpBtn        = "传送",
		tpDone       = "已传送到「%s」",
		tpNoChar     = "角色还没加载好",
		tpWrongPlace = "当前不在这个服务器里（Place ID %s），传送可能没效果",

		farmTitle    = "农场",
		farmSub      = "挂机拿胜利",
		farmAutoWin  = "自动获胜",
		farmAutoWinD = "开启后回到出生点，并且顶掉游戏内的传送",
		farmRunning  = "运行中",
		farmOn       = "自动获胜已开启  ·  已经回到出生点",
		farmOff      = "自动获胜已关闭",
		farmHint     = "开启期间角色会被按在出生点。游戏开局把你传去场地，也会被立刻拉回来。",

		-- 劫案面板（Notoriety · place 21532277 = 主游戏，universe 16680835 = 整款游戏）
		pdMainTag      = "主游戏",
		pdMapTag       = "地图：%s",
		pdDetecting    = "识别地图中...",
		pdUpdate       = "正在更新",
		pdNoScript     = "主游戏暂无脚本",
		pdUpdateHint   = "主游戏是大厅，脚本要进劫案地图才生效。进地图后再打开这个面板。",
		pdUpdateOn     = "正在更新  ·  主游戏暂无脚本",

		pdTabStealth   = "潜入",
		pdTabAssault   = "强攻",

		pdStealthTitle = "潜入",
		pdStealthSub   = "自动拿战利品、自动把包送走",
		pdAutoDone     = "自动完成",
		pdAutoDoneD    = "自己跑向每个战利品 → 交互 → 丢到撤离点，循环到没东西可拿",
		pdAutoAct      = "自动交互",
		pdAutoActD     = "附近有按钮 / 保险箱就顺手按一下（不走路线）",
		pdTp           = "瞬移",
		pdTpD          = "关掉就按下面的速度跑过去",
		pdLootEsp      = "目标高亮",
		pdLootEspD     = "给战利品和交互点挂名字，隔墙可见",
		pdActRange     = "交互范围",
		pdLootRange    = "高亮范围",
		pdMoveSpeed    = "移动速度",
		pdGrab         = "自动完成  ·  已拿走 %s 件",
		pdNoLoot       = "没找到能拿的战利品，等着刷新",
		pdDoneOn       = "自动完成已开启",
		pdDoneOff      = "自动完成已关闭",
		pdActOn        = "自动交互已开启  ·  范围 %s",
		pdActOff       = "自动交互已关闭",
		pdLootOn       = "目标高亮已开启",
		pdLootOff      = "目标高亮已关闭",

		pdAssaultTitle = "强攻",
		pdAssaultSub   = "自瞄只锁敌人，外带全场透视",
		pdAim          = "NPC 自瞄",
		pdAimD         = "视角转到敌人身上，同时把准星压到头上，子弹跟着准星走",
		pdFire         = "自动开火",
		pdFireD        = "锁定目标后自动扣扳机",
		pdOnlyEnemy    = "只瞄敌人",
		pdOnlyEnemyD   = "只锁 Police 里的守卫；平民、队友、AI 补位都不瞄",
		pdHead         = "锁头",
		pdHeadD        = "关掉就打身体",
		pdWalls        = "隔墙也瞄",
		pdWallsD       = "关掉只瞄看得见的",
		pdEsp          = "全场透视",
		pdEspD         = "红=敌人 琥珀=平民 绿=队友 白=战利品",
		pdPriority     = "优先目标",
		pdPriCross     = "准星最近",
		pdPriNear      = "距离最近",
		pdPriLow       = "血量最低",
		pdFov          = "视场角",
		pdAimRange     = "自瞄范围",
		pdAimOn        = "NPC 自瞄已开启  ·  优先 %s",
		pdAimOff       = "NPC 自瞄已关闭",
		pdEspOn        = "全场透视已开启",
		pdEspOff       = "全场透视已关闭",
		pdNoNpc        = "附近没有能锁定的敌人",

		pdTEnemy       = "敌人",
		pdTCiv         = "平民",
		pdTAlly        = "队友",
		pdTOther       = "NPC",
		pdTLoot        = "战利品",










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
		antiAfk      = "防挂机",
		antiAfkD     = "开着就不会因为 20 分钟没操作被踢出游戏",
		antiAfkOn    = "防挂机已开启  ·  挂机不会再被踢",
		antiAfkOff   = "防挂机已关闭",
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
		sound        = "音效",
		soundHint    = "关掉之后一点声音都没有",

		welcome      = "欢迎使用 %s  ·  按 F 开关飞行",
		closing      = "正在关闭...",
		closed       = "已安全退出",
		farewell     = "期待下次注入",
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
		navServers   = "Servers",
		navGeneral   = "General",
		navFly       = "Fly",
		navSettings  = "Settings",

		srvTitle     = "Server scripts",
		srvSub       = "Pick a game and open its own script panel",
		srvOpen      = "Open",
		srvMore      = "More servers are on the way",
		srvNds       = "Natural Disaster Survival",
		srvHeist     = "Notoriety",

		denyTitle    = "Wrong game",
		denyBody     = "This script only works in %s. You are not in that game right now.",
		denyNow      = "Current Place ID: %s",
		denyJoin     = "Join that game",
		joinOk       = "Joining %s  ·  the script re-runs automatically on arrival",
		joinNoQueue  = "Joining %s  ·  this executor cannot auto-run after teleport, inject again on arrival",
		joinVia      = "Joining %s (via %s)",
		joinFail     = "Join failed: %s  ·  game link copied to clipboard, open it in your browser",
		joinSilent   = "Teleport silently rejected by executor or Roblox  ·  game link copied, open it in your browser",
		joinPending  = "Marked %s as the target  ·  next time you join any server the script will retry the teleport automatically",
		joinPendingRetry = "Last attempt to join %s didn't work  ·  auto-retrying now",

		srvTabTp     = "Teleport",
		srvTabFarm   = "Farm",

		tpTitle      = "Teleport",
		tpSub        = "Pick a place, then hit the button below",
		tpLocSpawn   = "Spawn",
		tpLocSpawnD  = "Lobby spawn. Disasters never reach here",
		tpLocField   = "Game field",
		tpLocFieldD  = "The island everyone gets sent to each round",
		tpBtn        = "Teleport",
		tpDone       = "Teleported to %s",
		tpNoChar     = "Character is not loaded yet",
		tpWrongPlace = "You are not in this game (Place ID %s), teleport may do nothing",

		farmTitle    = "Farm",
		farmSub      = "Win without playing",
		farmAutoWin  = "Auto win",
		farmAutoWinD = "Returns to spawn and blocks the game's own teleports",
		farmRunning  = "RUNNING",
		farmOn       = "Auto win on  ·  back at spawn",
		farmOff      = "Auto win off",
		farmHint     = "While on, you are pinned to spawn. If the round sends you to the field, you get pulled right back.",

		-- Heist panel (Notoriety · place 21532277 = main game, universe 16680835)
		pdMainTag      = "Main game",
		pdMapTag       = "Map: %s",
		pdDetecting    = "Detecting map...",
		pdUpdate       = "Updating",
		pdNoScript     = "No script for the main game yet",
		pdUpdateHint   = "The main game is the lobby. Join a heist map first, then open this panel again.",
		pdUpdateOn     = "Updating  ·  no script for the main game yet",

		pdTabStealth   = "Stealth",
		pdTabAssault   = "Assault",

		pdStealthTitle = "Stealth",
		pdStealthSub   = "Takes the loot and drops the bags for you",
		pdAutoDone     = "Auto complete",
		pdAutoDoneD    = "Walks to every loot, interacts, stashes it, repeats",
		pdAutoAct      = "Auto interact",
		pdAutoActD     = "Presses nearby buttons and safes (no loot route)",
		pdTp           = "Teleport",
		pdTpD          = "Off = run there at the speed below",
		pdLootEsp      = "Loot highlight",
		pdLootEspD     = "Name tags on loot and interactables, through walls",
		pdActRange     = "Interact range",
		pdLootRange    = "Highlight range",
		pdMoveSpeed    = "Move speed",
		pdGrab         = "Auto complete  ·  %s grabbed",
		pdNoLoot       = "No loot to grab, waiting for respawn",
		pdDoneOn       = "Auto complete on",
		pdDoneOff      = "Auto complete off",
		pdActOn        = "Auto interact on  ·  range %s",
		pdActOff       = "Auto interact off",
		pdLootOn       = "Loot highlight on",
		pdLootOff      = "Loot highlight off",

		pdAssaultTitle = "Assault",
		pdAssaultSub   = "Aims at enemies only, plus full ESP",
		pdAim          = "NPC aimbot",
		pdAimD         = "Turns the view and puts the crosshair on the head, bullets follow it",
		pdFire         = "Auto fire",
		pdFireD        = "Pulls the trigger while locked",
		pdOnlyEnemy    = "Enemies only",
		pdOnlyEnemyD   = "Only guards in Police; civilians, teammates and AI bots are skipped",
		pdHead         = "Head lock",
		pdHeadD        = "Off = aim at the body",
		pdWalls        = "Aim through walls",
		pdWallsD       = "Off = visible targets only",
		pdEsp          = "Full ESP",
		pdEspD         = "Red enemy, amber civ, green ally, white loot",
		pdPriority     = "Priority",
		pdPriCross     = "Closest to crosshair",
		pdPriNear      = "Closest",
		pdPriLow       = "Lowest health",
		pdFov          = "Field of view",
		pdAimRange     = "Aim range",
		pdAimOn        = "NPC aimbot on  ·  priority %s",
		pdAimOff       = "NPC aimbot off",
		pdEspOn        = "Full ESP on",
		pdEspOff       = "Full ESP off",
		pdNoNpc        = "No enemy to lock onto nearby",

		pdTEnemy       = "enemy",
		pdTCiv         = "civilian",
		pdTAlly        = "teammate",
		pdTOther       = "npc",
		pdTLoot        = "loot",










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
		antiAfk      = "Anti AFK",
		antiAfkD     = "Stops the 20 minute idle kick",
		antiAfkOn    = "Anti AFK on  ·  idling will not kick you",
		antiAfkOff   = "Anti AFK off",
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
		sound        = "Sound",
		soundHint    = "Turn every notification silent",

		welcome      = "Welcome to %s  ·  press F to fly",
		closing      = "Shutting down...",
		closed       = "Session closed",
		farewell     = "Until next injection",
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
	Version = "v1.9.1",

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

	-- ---------- 音效 ----------
	-- 两个内联 mp3：notify = 右下角弹提示时，close = 结束脚本时
	Sound       = true,    -- 总开关（设置页可切）
	SoundNotify = 0.45,
	SoundClose  = 0.60,
	SoundDeny   = 0.55,

	-- ---------- 自我分发（传送后自动重新执行要用） ----------
	RawUrl = "https://raw.githubusercontent.com/hxhdsg666/O_X/refs/heads/main/O_X_HUB.lua",

	-- ---------- 联系方式 ----------
	Contact = "oxhub@atomicmail.io",
}

--========================== 设计令牌 ==========================
-- 全界面只允许用这里的值，别在别处现编颜色 / 圆角 / 缓动。
-- 一个强调色（红），一个圆角刻度，一套动效曲线 —— 三样都锁死。
local C = {
	-- 底层：不用纯黑，留一点冷灰层次，深色才有深度
	Void    = Color3.fromRGB(6, 6, 9),
	Bg      = Color3.fromRGB(9, 9, 12),
	Side    = Color3.fromRGB(11, 11, 15),
	Window  = Color3.fromRGB(14, 14, 18),
	Card    = Color3.fromRGB(20, 20, 26),
	Card2   = Color3.fromRGB(27, 27, 35),
	Raised  = Color3.fromRGB(35, 35, 45),
	Stroke  = Color3.fromRGB(37, 37, 47),
	Stroke2 = Color3.fromRGB(58, 58, 72),

	-- 唯一强调色（锁死，整份界面只用这一支）
	Accent   = Color3.fromRGB(232, 52, 72),
	Accent2  = Color3.fromRGB(255, 122, 46),
	AccentLo = Color3.fromRGB(72, 20, 28),

	-- 文字层级：靠明度分层，不靠字号堆叠
	Text  = Color3.fromRGB(238, 238, 244),
	Sub   = Color3.fromRGB(148, 150, 164),
	Dim   = Color3.fromRGB(96, 98, 112),
	White = Color3.fromRGB(255, 255, 255),

	-- 语义色：只表达状态，不做装饰
	Green = Color3.fromRGB(52, 199, 123),
	Amber = Color3.fromRGB(240, 180, 60),
	Red   = Color3.fromRGB(240, 88, 88),
}

-- 圆角刻度：窗口 16 / 卡片 12 / 控件 10 / 胶囊
local R = { win = 16, card = 12, ctl = 10, pill = 999 }

-- 动效曲线：统一节奏，别到处现编 TweenInfo
local EASE = {
	pop  = TweenInfo.new(0.36, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
	out  = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	soft = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	fast = TweenInfo.new(0.11, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	gone = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.In),
}

local FONT_N = Enum.Font.GothamMedium
local FONT_B = Enum.Font.GothamBold
local FONT_M = Enum.Font.Code        -- 等宽：版本号 / 终端行 / 数值

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
	sfx_notify = [==[
SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU3LjgzLjEwMAAAAAAAAAAAAAAA//tUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAASW5mbwAAAA8AAAAVAAAgQAARERERHR0dHR0pKSkpKTU1NTU1QUFBQU1NTU1NWVlZWVllZWVlZXFxcXF9fX19
fYiIiIiIlJSUlJSgoKCgrKysrKy4uLi4uMTExMTE0NDQ0Nzc3Nzc6Ojo6Oj09PT09P////8AAAAATGF2YzU3LjEwAAAAAAAA
AAAAAAAAJAL/AAAAAAAAIECQkWNX//uUZAAP8xBivQAjRrAqwAgAACJuCHmLCgCEd8kOMaFAEI75Wb8kN8b8xkBAMb/jx9fA
F4V/66JdN3gs/TiUq/oiUAEfuBnQAkJ4AIgG7npXcykIFFsUqRc+BQUDgPDH0p7IosyXinLe3/0Sb0/Te0Mp3FxcG4uKClO4
gAsMQXFxeyFDs+3/ghkJc/QXW/1BhZ//KO/5d/9BQT8MQfgm9TvlP4nSCBygcGBOD5Q4H1Bhfnnlop+89zcGDvH9rPXJ+pEQ
ObDmUD1DAZpnTO57iRBJDNqiAFSEx6sgyhRhlAZM2vRprnTzyJSs0dTxSCXisAYfHb/zMkXokfforkjLLn5SwLl/nfFqcVnW
eA1GptRzcyLTgoAloBBpEQB24jEbpplU/IHzIsjm5ZIebUiQhUA8KHFKBi6nEAAABCAKZdOPkVrOJ8iKPq7xdz5Tj/9M1MH/
+BFe8s/pu5HDMaZEZ0hVFAC/0Yjj+D+z/nufnnmT3NIxCgoNCHgtkJypmyMy//uUZCQBEg5iw1ghHfJM7HhAACNOCP2NCwCE
t8kOsWGsEI748lvRx5bXuymSmRH/r0lqGS/zdP+cg0+ZQF+ZbuuVr9ItMufDKfED+ZkWWSw5pkVtfKmb/2kRZjdV3+Lk5yia
EGAig4BRgpjwCgBTuRPIoqmzwqPnlWRF+sXOfPX5DRCWA5BPGBEZn0bLfsdnoQXOxQQEpk0eU2cw5gTOVJpf/dRrkUtkIUqI
oUhbMK4YPqiaKAIBSwFKallKZQcG1mKeR9lNnJq8i3/v1dZS56M2LH6WSIiEYjGXLJyRIAN/SAaSyyS+y5MyKoX+rte9lGEG
7qguqiQAQABahM5U/LDU9szNGNo8DlO+TL7QgwQbUqm2ea2kcwpfCHuSHImiXSHlZDuVL80a96rl+0Z/UyMueex/387PypeF
bQWIJDdHCDkHCr/5mSKFEZ2chzCZ8aPUhk+LMpQ+4r5i8TvW25U91Irz9jt3MsnW23w355IezObExIr+pk+lp0/22/Ly//uU
ZESL0nVjQsAhHHJLTEhABGb4SfGNCACIfAkgMaFEEI758j5rauZbkuqhBKKsBIHi0oi+Yz3WYK+Yi9MQiEUpPTz/AlGaXPdg
7Hv3S5ZjVSX11sj4NzfPLdCiElvmREk/BUK2cov9iM5Ej7blH9z9yUV0zmh7qmDIOQo2FTJQbow8xP8hVxZfKcwSQAHvIgjI
YRIJHhL7L0SJstzISrFJgiIgcLo2kj5LBG5tW25CzEhSjOOIOR3t/KIVK8uRyGQ51CfCOQzCyQGUtV2m8m00psjgH4c62Wfc
jRpFySE3S733B28JLPSv3QEvK6RJbTIypESxcRo6wnQjW75LGBMZuUXmjkWSnvW2J30ZrHjGdBFm6iHikTBTcJNHxmNIIgAB
bkkiiFA5ljDCqfUoJzP8kjaL1LyufRyKZzNzjR2+duDvNurycZCoxTnv/zuXIhFKcL2rGd59pH/cv8z9P3cxCJmpTcY+gzJL
CBS0WwmntaPtn5H6nCST5UZokEe2//uUZFmBMo9iQYAjTuBKrHhYBCOOCFWHDQCEeckcseFAEJr4ddbv2sK/TRF9UMoRLIj5
SA2MKUsiynzC/RL2RzhyWZKaMkjJDVoLsQWDus39ZEp5WkKcAAZFfh/ac5SM/wdLLto3JlaZEZTtBJ4iC9hIXpAZu8jIlGqF
GIyEwBrmwE/yRxNMN6a9/3fMPnZnqedR5TCGMhUgwAMAVSmNncs65QsaJltg8/0iI+w/vXsD+5KbdLSL7LzKiXxDFMR1s2pU
RVt1tO2hndmspFX3simXc3XK4J6pKHdEBoHVw4APEjBARBCQOsqRzn0XzownKXfN+sr5+kZny8F+yFBimxGW3RYWUrHiYkkl
TbFLgYJzKRzs1e9EWTa6fdSLZ2ehJARbJEi0Bl+xE2ZzMay7PfyzbOfcv2Ot5pbwEBnRZUOmk7Y2YopZO/pXLSKTV2dDNY3e
ZB+cKPasPZP8qWfvPRZw/gZOjxicIQTBBSDiXYUTXvFAACnJ3CczwmZ621vP//uUZHQFEk5jQsAhFHJFTFhrBCK+SVmJCACE
ccklMOFgEI4589dd8+QoGa36NS3fGjZG9c3ZypMZydM985CKahmgK5t5S/5nl7Jw8884X/uZvdqqP8Q/eGxkgU8hBVtfLjZ1
IEh/M/3bnZP//58zn/f///qyempf7GTzVC3Mp/LoW/Lnfv8WB02tNWlMq35zpxKlLh/vN+LuVsYqpJiIUJQFoZA8wh0mAmFf
p9oEcVLvqv1z3Mt7HnzOjs7GovVUWy6Wer6U9VzuzVc7NdjEV3RX1SREM6FVCmUejdheyGS9EZVqlGkcm1bpepjPZSmU5SiR
1GHFBAaUBihcABgEEGEAAAADnkQMhglhAmBiFEKKC5+YPIFphHglm3qYGZARKGvFQMAMCIRCgGAEAXYZAi4CqGrLrPjvLgaU
HpCt2Us8TjEyMqXF6VRuky2J4XGXyV9BNM+mcQlArEmXjM/a1BkEGahMCq5ZTTLNNkKJgk6akK1OXjxsM2kaKPvu6CfL//uU
ZJCAAltjQgUEYAJRbDhAoJQAWNoFDznoAAImQKIHDqAAB5BS2RNlMQYdpHmxmbFMihBiIqqrStWk6SC2NDRBFlspMtl8nyHE
BHCRYkBQBFSXjOk8mmh////+gfQ/////NxoFJAADWVA7LIJIiVRhqrWnEL7pZzeeqmEhVHTLmIgsDwmUZiz3mKxxpskLj5XO
MdDtGnuzyRxQKxIaRTrs5llV2fEWNDDRZEQoX6sp2+a5xNNYqo/g2Eg/C7OCqLY+JBsx/XU8gNQxN2PM0IJUwWQpx8IQwmGY
8BoGBCSFTP////zyjf////geAUAgLLQDACQBwwB0BbMBeBWjApxPsyHUlnMYdDETEs0QkxlsQ6MHXA1hQDhMDwBLDBaAFosA
K5gBgAYWAANOZnamA7E6uDrPxc9+8eZmZ5n9YbIqOiUsrI8JRH69js6YPpySaq1nx7a2i1G5XvO9bJo8rkySv3kg703pzZ2B
mT2Y8d4oLDdQR/sVdxt/PjR1bOwQ//uUZEgMBkdgRRd94ABNIPlJ54gAEMkzGC+9TcDFh6e0Bggq7s1H0S+8feHG9/Eiz/+J
Tef9033Jsbo/bv3z7es+mt3u8zv+tv5HXmldqXyTzSPPPM/njvJO7VbSAAcB/9DTatYzSEkDPDUSvToYc3lBM+k/+cJlVFLC
LwgaNKEYesYSRC6jw4UoESUm5Zwte58cYG1MJmWAVykYK+VZyKCDiA4+aB8ESA0ATANgGUVAiDAegUUwd0JGNMKVVDFbQi4w
ApOPMpkDQjArQO8wGkBZMEGBYDBngCAs2sVUxYSxG0XhbUDGpJXypnjeO8fyVhSRI8R/Jm1dxqeSuBO1ukC+axcGynp8Ipjp
Q5GOdBK3W/3IAeLWVD6q3PIGU9qTMuVKRT+Px8VEbj+X//ij+gAAKgOCRttIL9A2sdFkwCCWmX1v6fQZeIQ80DDDhZhOuLpV
3t3I7HD459bhZyKFf/9CQAAhZ4d9tbGiIGLyRtKg3fYMwCs0HmFpu+mg3pe6//uURA8AAs8uVHtJQyxapcp9bQJ9ixDjSa4l
TzFik+h11J3eTRYKnyRRcuSsN2lo9mj/e3ba2k+r4qLEQLUu/40EOaX3qO8gcoT/zX8aTlmXqPsDb6UGBazK+8D/36YqwAhP
/9tZGiZEtCNoYGjxgObBGug64SrYmzCEvthk/sKjFFnFiYXSBpl5Z8+/LvEzMVxfIaCNIWJ4GghN/1XOcG1E6dnDg21V4Sdb
Ap8U6MhpV/6VOiPjkosY9AACfbWyNoALuRBU6HA2ZduphIJlhAhmVbhDC8nlZlR101UMmih0EUAiIXE1jpWkSFqm01oSupR8
l6WDJl10QLOcrOuqtQ8gOVabP6O10a1LGo+h6EIj/+wgAB63WJwkAM6UNT8FA1MlYvMJgnJTXAU4rQcBBpercqPNS1QJo4uG
UAiLsEyoQGTg8hFQmD8ZNZjlZ1qnFVW6UBHGVIHEXShxpJwM6UEJxjSpIgtnN+/sRQAH7jlbSYXqmEVgEYQiqdzGeGfG//uU
ZAoIA5lSTlOpE+Q3wyqtHAM1jkV5Ka9oRwDoCKo0dhkGYuI+cKC6YKAQCAAMDQWclps3Ue6UXURFqsfS1Sl4G4YtKtlW3mwT
SfCGD45PlmSrzoPCGJIZ6UOdp1RXlNI6sszvZHQ70syqjGPRm//b9PBYww/wWOCHGHHHwcF+rrSgAAPvsNZGkK5WIIiEz1VB
JT8ot8///hqTjCOdely1W9K3Ms1IB0cec0MFVmv3Jr2IM60jDZly1iVuUlkgAEAFiECIZBRMAYT4z2YuDJHD0MHoWszdgqwU
QTIMvIGj6eMXvT+o1E7FoyqDOFc8MRnLIgEhAxjJvPCt3VYYyyEIWDdTkOYyM28/Qyq67uZJCkRUPOy1vaqkWt3svZ2/27Kv
S2Zvwf/BDgvghwABbv/tZGiR0IICgbwKlrq/yrG5eOblNcZZ2nz4VESgwwvx97TwRc8cof+03eqSKvSY/2u/RQL1phtgBByy
SONtEoBgMBcoGAza9RtCXOAWlUz6//uURAyAEr4fTutMGkRZJDodaMNrinxZNfW2AAFMkyq2nvAHgKNxELXRnra+qrXmFqsv
CW5B/puwtc7t9hjRXWEGYErBpkolr2DjFpsoFCjTBIsrbdWsqlLVs993b0ZtOgmpgBmXbWyNEALuUFjScpj5Y9BUPEqLArLI
rb8T3NQ0eTimVLox8WX1kyElkqXF60cVfJChsXkPPop4uEzYI1rK6ox8uLLfAI5DPQwXXdmZ8zGMMSolP+rp5togAEUIqRqk
kQBQUilDqGrSIWBSAGXmp91HSfNncBIoSz6c8qdv4sWF0SwMGYTn8Bw4nP+bb+lOXnwfEBkHy7wwH45Bdp8MbEJghBf2occt
d////7HAE5t9ZI8Qz8OcTVvyjdvGp+r2eQWwsDWPQcCLBVk3HwF4sH+XCKc6FsRoKyVXxJWeeA81Df6fv7PInfx8v7wHmocf
d7+BTL/dL7gUjnicGT9YMkBAM1tv9//tdQ2AAAAGdCgQdIwUKGXGClsZkBAG//uUZA6AA9glUm5zAAQ9BMrNyRQAju0VW72o
gDC2gyhnngAGA5jQHGSxOa8DJ2cjjQOAQIMnigDAEyiCELQMRu50+AiQFA5dZSTXQ25rMFh18NP080VLmN6lddgCKOxYhmvA
cGujOz0SxtzVi5hXxw5jQwxS34Dl9r+fPHu5jzaCaUhAMBrcNxv/thKAAAADIUkxAVJBUCBpqUimZ7QiytcRX1VREVX7CZBM
xjlY8gsTM5TsTIxUJaJifs0EgyjIABS77f2ytgQuXVsplPMFUxw5q1CAwe70XyUk6+4dj2EPHSqbHiuaF8uGZmYGalqRonnQ
c5ughQOpLsqpG5YQYizMjWUy26kaGtSJ0rHp7rdFnSz3ykGLSsqttl1HvPiEIAkOEvy2Wjucz5M0pFhOL07v/akgsZQAAeeI
BaHZ8KanhdxKpYW9zYC7v31/pbHreMnv/7x3o+Q3hbMtVAlKRYTi9O4gAAAKSZFAAL2AICJgKASGBKCCYTwTxjYojny6//uU
ZA4AA+dYyuvbUlAzQwqNBSMHj2z3L6z5Y8DKhKm0NIxmskYrIK5lElhmXbtiffQHnN5gCYYMKhUGJQF4pLGntnpTczzrXblj
ZhxyR8SmkrGR4GslHShGLyUhPXulDyRKWF43a1qcoJO2jsaY5h/StANF6dGVk/KAs9v/T/////8rLyAAJze7VskALEISQSEr
uILSpKtaOsRXo7wvPRx6qQ3YUJwGRG0tEAXozLmfnSnq+ztv9YAAAAiTssIAARQMHMVoEWmBeGMYhR85ztI6GIoGuZCwsRu5
zcGDiAuBgxDAGApZ0+THNXrM5eeF/43Tww3X2MqX3G+3uKKk4aHNU/3vlrEIgrO6x+XhWXJsN80ju4gFJ6s03u4Xm7/76EX5
v/nv/jsfn9H+UHytP2/nUrbAAmGtkoZJEg0IqAlnABwcBhE5oPg4fAA0CDju9NqtgWaLHf+xERK+v2uqSb93+GWzl9VAAD0W
5EQF/JmBcAEEggGCODiYaROhuHMP//uUZAyABAtAS1PcWjAtYXpdBYMVjmVvJ69kqoDehOp0sA0OmLkGkY9Jih15Pgn/iebR
JwhARhkEMhQTMpf2P5RkAEpQG4bl1B3E50mpq1za9znbeWta1zl2cOfKxJbTWpLi0tOMcbLHU1lc2D2du3VKqj6VdddT949X
v4ZH/X86JMn14itiP//1W11okAFC2ARogChoJSQhHgkFxBcpmn+OgIBkqcKt/5RQPtBMfQ4XkyPVsv4e+j+gAAAAxxtBAANN
LNAYAEwGQGDBGBfMNs3g4Nx6jE/ABMKgy85FzwjGhBGMHYEc+1jWHDDkFW2nZVGaZgVrHVSiw0TVlnQpDmRzFILzEd7uNQiL
P40dczu9rKHUHIQp1uY5V/qOmr0R5d+vfRdd///////+FPAADb/bWRIDs4HqFVYwcjCWGKAEyVFR5kSNYfEhIeGCwZySS79w
iMue5VdIjd1T7YqNOoqpi9qVjABd21skaICQ3EF98UPGSomjYJiJ03mmxalB//uURA2BImQNUuk5SFxN40o9aSNjiYBfSaDg
YbEsB6kwHCQuIl1OUFO6DJIBCQgHwYFEAAZEaxSQrgiOJGHEwsEHpHqkLh84pk6HjSHYVv9n//9XqskAAc+1tjZAFRu6tgjC
ykvuFyzhiIMBwi1eJquNFSYzojBJ28gl3KEeDgN7GHWSQK9DihL2njJoUSwNHHWJEw6qtx9+lUVQ1v////t/TS6gH/trLGJR
djlEhiDuvJA6AdRaRupEY9EYleuD9QzjKMqWsq8z/uOokBws0SM9IBIsaJmEmVizVjVkjISYYSOCvfdAJXf//Uunu2VOkB7/
+EBJx2uQAsCEdqNPEaUQovEnFjwIvQ2UjPFlAyX6NGBBwjEToBETQXDhMLC6DoAPSEawutdoq9q/mCPdWvxWOb/fv/5B9bkq
TIEltkskjQGOUpXkokWDBE/fkGAAz22aFOZkGJM6HDyzdQjl8lZEYyYvOkdQszJDn0obmkLxFRXNUDm5t41r8tWGwEQO//uU
RCKAAkoqT2sGGyRMwwl9Z0M0CXRXLaBlAQEuD6V0DQwoZHTNZYIAB2262tkgb1HWiBeAEKG2SVthBk5epa9yFWL5C03Vmhoi
3j7HfqU6dDYgSqDBM8LBc6LeSCBdYoLCcwRAjtljrhqnqrVOwzb4v7WvCAFs2jsbSAHaZ2gsGf8jgsTNc9ChNUIC3G04sluw
wXjZ6ib0dEps9WjHBxE7CbQM4SIlX7xhcG8mYPEwKJig9gwSbmZizZ/t7/pRQGABLJJJEgAKZlIJLjQkBhhp0CQh9oaePwLF
rwER2CF6CAloJBFKR+hsk1rs1VJHqRBoHVQ8VTUZ2vSqDIJqZcinXgIxjpUVWhn+xFUIAr7fbaSIAX3AhkKFCcDUIAcKApYR
NHqyNtE182vPL/ZM6nx7VcyZmzlbTz9vPvKDCQk0jLECAiMMICcVaSWlFgHAmR2aepn//+3cKAB9tttpEAI4yMLBqzp0qItV
D5oPnX+nZ4jiLBqwIMMwhEwBBipm//uURDmAAl8fTGgYMEBLI4mNAyMKCV0LHw2MrcEtEiV0DIwo2dqMGMzdTbFJFxT3idJh
ZsUMC4wcFXXh/85so2p9KK9vP//pAAmnwPoo4hNNd6SwUmdJoaiKdHRURkAE5VFKqUOxBRmCGeRkLqO6RCftIkdoUdtaZObm
ZHvsS+qtqU657257aNI7KZFcs9Wb//4aGAFpJdJIkAMZpRRiYUFQiTIOIJS2NOLKrfDQEvMOLBZaAWtelIIV1I7iWNnPwIth
ykPOuDxIQeeC4wBYqYbARhvLrPu1t7zp1X7EqgwAvPr9Y2iBzsgZeclkTg1BHVW8xd4IsutKcs/BUdhi/Ua+wW8sl3TlyguF
wXI0BoIlgiIRiFP3y0WRYA56wBNvWfK/ot/0J/S3q+iEEhIDybzfSRIDhJc3NU8PP+VDr2aDr1vbnZNyffregkfF1urCf3lo
NCigaGPGCjFNjBCYcSDKCakJhfOVXqUFyvHBFTvbTq9X/q7QAAI5ZI2gAB9y//uURFCAAm8VTGsZMaBJovl9CwYWCah/Ka0k
aEEzmuT1gw1whUSLH4CiDIhQ6CDgBneDQmVKY26kTBIwlApVmpuQoIDptT6tbc8jcyjeM1DFvKh16FlbRecSdNWQobklq312
7u3d2FgEAUpNEpEgB/6upzjrUCUFuKDVNnnM/x5cNe1RajlWpG+xmZk5mKc0e0ss4dZ3NCJdVQwvKdT0/9ObcyPZb/euGEQ6
FW7ZMwp366vuVRAAo3JI42kQ/ykUD1IlvnydY5ZaZ2K0dfXl99U6BZlocRa+Zd60GXVvXhv7+rElgaeQQh40XaXWFSAnwADL
5tIfaQco3eUWnof/p6RwaAUkv1kiQAuU44ttxLLTI0REbN2ZWSBrmwLfbUIq6PASLNVNuh6NPVeQVUDHOAcyJgWQaUDBW4DH
mzxgipjk2GkLFqawAjdS31/UCAA2lKrACSKpmihoagrom2CBZ+5SEVLFuRYgQCBQ4sNxI9uRJW1FTYjqmRmYhgiDElLF//uU
RGWAAmUcTWgYMFRLQ5lNAwgICZhrIYBoYUktKuOhgZW4ChFLUyvvL9fX57Jt7UqNOhu3rcrHbdDG9ZAAs1oH/dgoxYEKDQdL
0ZGAfutzK9sHitKFUEEsWuUyY3r+h0ocXYqtsThdKtO13Sv2tZeqP5SvVt+hSplezasl0bSjf4ZheGf//hoADv7W0gANxJB4
CgDChR4kkccAOvWRAIEjWcauYlBKMUMZgmEAhLhQ4O7YMn9jaORk5spMveSR5dTPVA6xOUETwszNIh0Bizl/94IA8s3221qI
3HW8EzLV6EuEqzkVWenmaooJnYphnJWNRClScG5cJVdSz1RaWpJd9rAv04Zt/i5wjzdS6lp7erjBztjGksJstvU7Xb/0gBU9
fyAYV2mq7Os4rJUbAYbfwKCsNFO4sWhojD6kuhU2YTnjf+c8k3MRbzpiTZkfQJDhZp4NkhxR6SKVqIi0Z7TYppd0eOHZMAOC
3EkAAP/UrM49LcO+KBmRmVGlbFSL//uURHuAAlEqyNAaGEBNByl9BeMWCQyJISBkYQElkmPpkw1om///It5K7SUzPcCYH0XM
Jot4bHIG1jXryXK6DLSykvedoIGTzyYzk21T9diPs0FtCDOAEVVw5+3oEbwLDSlINCmWiq5ob27rat5Zbzt3e3+E6lb00WZI
0J6t9cyLSMpJSPIqmmpPnCLo0j2ZoPIhnCZDiHG3PyZevS6NVZ5QR6ePr/g4T+n///4L8HSGSpLLZJGiQPLXLBtuJqy2p61E
8PCJS45FSMrSV0LlIpenCOGgwQMKRAYLQrNGHziaL1XC/22DnCpcoWWANlAAvfanTJdMYQ1rXcccKIyC1DksyJx79SnED695
boSZE8yKjlBmVmcS8+2hFQ7q+xqq9zvJRVKHKzMiWKQexGSRm6FVn+rjo/g8F9R/2BYzf/sDAv8HhAYMdwAG5JYEJIjDbVTN
Fagvjpkds17rMYfDeNqtNl7NrYvO/76dfyb7VBiRd10JuxwAJK6mkiAD6fj0//uUZJUAMtFjRkNDFPA8A8n9AeMJi32JGMyM
S8C3guWQAqRNj2Acmc9w1Sjixf+ka66tVgEFImb43DWKFceedO4ahLfCQ8bEoVIkKioaTwMZENL/jWLkvO+3GPp2V0A01TQV
MPAEZ+qUARoSAAst6MkIjtAiKuYXFDw4ILJgA5VhQwmSGA9nkOuHuK76Yn8lS2xcd2RazIq6uyVpW2hcdNKc7nfskTU2Km9/
//76//xYYj5hbGdCSDDlKk0Eess0FCM18jMDX//5lX//62Szqn//6I7J3KFBHGMpBQUGMZWMrGmKh2Mtv6JZP+//sZVYys/3
KZSCgoMg5UOMGBrAEglKCE8Ki5kVFx0EhoVjpMqw0SCQFIhI2SCoC1paFDQVGFWj0kgpypJ9oUR/YPSEv/sGWD01//8YhdVM
QU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//uU
RLMAAlQXx9AvGEBLwzjZMwYWScWM+AeETcjrBCFMlKRQVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVV
]==],
	sfx_deny = [==[
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
/zhyRuJa9HLIo//vFOjW5TaRinzTdCWgsAFZAAhV1i3WVsih4WF2UrQTBVL1+DT/1qfptzqP+2Wm4C48jWiQ7XbPbK0gsQgk
JVtVEwhJ11sqqVUqpfSbq7Mx/xtj1X9qupLnGPY6pMfrxmP6sWNV12WH3jf1VL9m9S40112ZlVQqxmpqXxj7t/VVvbVVXaqV
CiV+HV/UTEq4lu1LVVWBVAROokm43VsDHtRMUgIyNVXjATZNWPhqX/9X2Xql//uUZI4Ak71axUnvMDArwAiWBCJcCsVs+YCE
YAFmMB4AMA3B5cPbgEKtKr/t8NY1/hlD6xr0m9eidRMDFqql0vhgMFKReolVWsZeomU9S+GAuJ2OMyhRLP6CjUxBTUUzLjEw
MFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//uU
ZFGP8AAAaQAAAAgAAA0gAAABAAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVV
]==],
	srv_nds = [==[
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
]==],
	srv_heist = [==[
	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
]==],
	sfx_close = [==[
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
Is3elnMjSYS29LfFm/93otjUQaCYdMOFZZgK3vWcmmQT0oWKPQnTYxqgzei/YDN4q1SLYvT/+1LE6YMKrLUcTWEBgYycokGm
GWDJgIAY2jKBjWOrUllI1JqzHttYWucb/oChlNYesOq1Wrw1NS8Ic1+zMzeqms+k115wVUCoywyAqZH+GON+l1apsXHiX5Te
u4dFpVNafKSKpUXG/Bf+/u+KTEFNRTMuMTAwqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
qqqqqqqqABa+zlMFDAg5Ds7fuxgoIEcjpoRmnyMirmRn+RmXyM///zUMDBo5Gf/7UsTrAwto6RINMMrBZRwiRYYY+DWQy//7
LPP5UMmUMGBo6VD///kv6tQQJyMmWWl/zImWWVDaoZGoYKFCOhkwUMCDoZGrBQaVTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tSxO6ADMS/Cgeww8FbHyCkMI+BVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+1LE0APLjaLCQQR1AAAANIAAAARVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVQ==
]==],
}

--========================== 工具函数 ==========================

-- 元素"出厂时"的透明度。入场动画恢复时**永远用这个值** ——
-- 绝不读"当前值"：动画叠加时当前值可能是另一套动画刚设上去的中间态，
-- 把它当目标的话元素就会永久停在中间态（症状：整个界面文字全没了）。
local BASE_ALPHA = setmetatable({}, { __mode = "k" })

local function rememberAlpha(obj)
	if not obj:IsA("GuiObject") then return end
	local cls = obj.ClassName
	local e = { d = obj, bg = obj.BackgroundTransparency }
	if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
		e.tx = obj.TextTransparency
	elseif cls == "ImageLabel" or cls == "ImageButton" then
		e.im = obj.ImageTransparency
	end
	BASE_ALPHA[obj] = e
end

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
	rememberAlpha(obj)
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


--========================== 动效工具 ==========================
-- 全站统一走这几个helper，别在业务代码里到处 TweenService:Create

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

-- 抓一个元素（含子孙）的透明度，用来"先藏后显"
local function alphaSnapshot(root)
	local snap = {}
	local function cap(d)
		if not d:IsA("GuiObject") then return end
		local e = { d = d, bg = d.BackgroundTransparency }
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			e.tx = d.TextTransparency
		end
		if d:IsA("ImageLabel") or d:IsA("ImageButton") then
			e.im = d.ImageTransparency
		end
		snap[#snap + 1] = e
	end
	cap(root)
	for _, d in ipairs(root:GetDescendants()) do cap(d) end
	return snap
end

local function setAlpha(snap, v)
	for _, e in ipairs(snap) do
		if e.tx ~= nil then e.d.TextTransparency = (v == nil) and e.tx or v end
		if e.im ~= nil then e.d.ImageTransparency = (v == nil) and e.im or v end
		if e.bg ~= nil then e.d.BackgroundTransparency = (v == nil) and e.bg or v end
	end
end

-- 依次入场：从下方 dy 处落下 + 淡入。
-- 用 task.wait 而不是 task.delay —— 假时钟不推进时动画也能走完，测试才测得准
-- 记住每个元素"本来该在哪"：反复入场（切页 / 重启）时不会越滑越偏
local BASE_POS = setmetatable({}, { __mode = "k" })

-- 取元素"出厂透明度"。恢复目标固定，所以同一元素反复入场天然幂等，
-- 无论动画叠不叠加都不会把中间态当成目标。
local function snapshotAlpha(d)
	local e = BASE_ALPHA[d]
	if e then return e end
	-- 兜底：理论上不会有（所有实例都走 new()）
	e = { d = d, bg = d.BackgroundTransparency }
	local cls = d.ClassName
	if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
		e.tx = d.TextTransparency
	elseif cls == "ImageLabel" or cls == "ImageButton" then
		e.im = d.ImageTransparency
	end
	BASE_ALPHA[d] = e
	return e
end

local function slideIn(obj, dy, waitSec, dur)
	if not obj then return end
	local base = BASE_POS[obj]
	if not base then
		base = obj.Position
		BASE_POS[obj] = base
	end

	local snap = {}
	local function cap(d)
		if not d:IsA("GuiObject") then return end
		snap[#snap + 1] = snapshotAlpha(d)
	end
	cap(obj)
	for _, d in ipairs(obj:GetDescendants()) do cap(d) end

	obj.Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + (dy or 10))
	setAlpha(snap, 1)

	local total = dur or 0.34
	task.spawn(function()
		if waitSec and waitSec > 0 then task.wait(waitSec) end
		if not obj.Parent then return end
		local info = TweenInfo.new(total, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(obj, info, { Position = base }):Play()
		for _, e in ipairs(snap) do
			local props = {}
			if e.tx ~= nil then props.TextTransparency = e.tx end
			if e.im ~= nil then props.ImageTransparency = e.im end
			if e.bg ~= nil then props.BackgroundTransparency = e.bg end
			TweenService:Create(e.d, info, props):Play()
		end
	end)
end

local function staggerIn(objs, dy, step, dur)
	step = step or 0.05
	for i, o in ipairs(objs) do
		slideIn(o, dy, (i - 1) * step, dur)
	end
end

-- 悬停：背景 / 描边 / 文字 / 缩放 四件套一起过渡，全站统一手感
local function bindHover(btn, spec)
	local info  = spec.Info or EASE.soft
	local baseBg   = spec.Bg and spec.Bg[1]
	local hoverBg  = spec.Bg and spec.Bg[2]
	local baseStr  = spec.Stroke and spec.Stroke.Color
	local baseTxt  = spec.Label and spec.Label.TextColor3
	local scale    = spec.Scale

	local function apply(on)
		if baseBg then tween(btn, info, { BackgroundColor3 = on and hoverBg or baseBg }) end
		if baseStr then tween(spec.Stroke, info, { Color = on and spec.StrokeOn or baseStr }) end
		if baseTxt then tween(spec.Label, info, { TextColor3 = on and spec.LabelOn or baseTxt }) end
		if scale then tween(scale, info, { Scale = on and (spec.ScaleOn or 1.04) or 1 }) end
	end
	btn.MouseEnter:Connect(function() apply(true) end)
	btn.MouseLeave:Connect(function() apply(false) end)
end

-- 点击涟漪：从手指 / 光标落点扩散一圈
local function ripple(btn, x, y, color)
	local size = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.8
	local r = new("Frame", {
		Name = "Ripple",
		Size = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, x, 0, y),
		BackgroundColor3 = color or C.White,
		BackgroundTransparency = 0.84,
		BorderSizePixel = 0,
		ZIndex = (btn.ZIndex or 1) + 5,
		Parent = btn,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = r })
	tween(r, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, size, 0, size),
		BackgroundTransparency = 1,
	})
	task.delay(0.5, function() pcall(function() r:Destroy() end) end)
end

-- 按钮统一"按下反馈" + 涟漪（鼠标 / 触摸都吃）
local function bindPress(btn, color)
	btn.MouseButton1Down:Connect(function(x, y)
		local px = (type(x) == "number") and (x - btn.AbsolutePosition.X) or btn.AbsoluteSize.X * 0.5
		local py = (type(y) == "number") and (y - btn.AbsolutePosition.Y) or btn.AbsoluteSize.Y * 0.5
		ripple(btn, px, py, color)
	end)
end

-- 一条会呼吸的强调线（用于"正在运行"这类状态，不是纯装饰）
local function breathe(obj, lo, hi, dur)
	local a, b = lo or 0.35, hi or 1
	local t = TweenService:Create(obj, TweenInfo.new(dur or 0.9, Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = b })
	obj.BackgroundTransparency = a
	t:Play()
	return t
end

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
local ASSET_EXT = { icon = "jpg", flag_us = "png", flag_cn = "png",
	sfx_notify = "mp3", sfx_close = "mp3", sfx_deny = "mp3", srv_nds = "png", srv_heist = "png" }

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

--========================== 音效 ==========================
-- Sound.SoundId 吃 getcustomasset 的返回值（rbxasset://...）。
-- 拿不到资源 / 播放失败都只是没声音，绝不报错、绝不挡住界面。
local SFX_FOLDER

local function sfxFolder()
	if SFX_FOLDER and SFX_FOLDER.Parent then return SFX_FOLDER end
	local ok, f = pcall(function()
		local folder = Instance.new("Folder")
		folder.Name = "O_X_HUB_SFX"
		folder.Parent = game:GetService("SoundService")
		return folder
	end)
	SFX_FOLDER = ok and f or nil
	return SFX_FOLDER
end

-- 结束脚本时用：先别把音效容器删了，让最后那声放完
local function releaseSfxFolder()
	local f = SFX_FOLDER
	SFX_FOLDER = nil
	if f then
		task.delay(3, function() pcall(function() f:Destroy() end) end)
	end
end

local function playSfx(key, volume)
	if not CONFIG.Sound then return nil end
	local parent = sfxFolder()
	if not parent then return nil end
	local id = getAsset(key)
	if not id then return nil end

	local ok, snd = pcall(function()
		local s = Instance.new("Sound")
		s.Name = "O_X_HUB_SFX_" .. key
		s.SoundId = id
		s.Volume = volume or 0.5
		s.Parent = parent
		s:Play()
		return s
	end)
	if not ok or not snd then return nil end
	task.delay(6, function() pcall(function() snd:Destroy() end) end)
	return snd
end


-- 统一的 LOGO：有图标就用图标，没有就代码画一个
local function createLogo(parent, opts)
	opts = opts or {}
	local radius = opts.Radius or R.ctl

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

	-- 一圈很淡的描边：让 LOGO 在深底上有边界感。不用发光，发光容易糊
	new("UIStroke", { Color = C.Stroke2, Thickness = 1, Transparency = 0.4, Parent = holder })
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
	new("UIStroke", { Color = C.Stroke2, Thickness = 1, Transparency = 0.5, Parent = box })
	return box
end

-- 窗口开场动画：图标弹一下 + 标题落下 + 进度条扫过，再整层淡出。
-- 飞行窗口和服务器窗口共用同一套，返回一个 play() 函数。
-- ⚠️ 放在 boot 外面：不然它那一堆局部变量会算进 boot 的名额（Lua 每函数上限 200 个）
local function makeWindowSplash(parent, name, titleText, assetKey, radius)
	local splash = new("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		ZIndex = 30,
		Visible = false,
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(0, radius or R.win), Parent = splash })

	local glow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 150),
		Position = UDim2.new(0, 0, 0, -90),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 30,
		Parent = splash,
	})
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = glow,
	})

	local icon = new("Frame", {
		Size = UDim2.new(0, 54, 0, 54),
		Position = UDim2.new(0.5, 0, 0.5, -38),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 31,
		Parent = splash,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 16), Parent = icon })
	local iconScale = new("UIScale", { Scale = 1, Parent = icon })
	do
		local a = assetKey and getAsset(assetKey) or getIconAsset()
		if a then
			new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = a,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 32,
				Parent = icon,
			})
		else
			new("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "O",
				TextSize = 26,
				Font = FONT_B,
				TextColor3 = C.White,
				ZIndex = 32,
				Parent = icon,
			})
		end
	end

	local title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0.5, 0, 0.5, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = titleText,
		TextSize = 16,
		Font = FONT_B,
		TextColor3 = C.Text,
		ZIndex = 31,
		Parent = splash,
	})

	local barBg = new("Frame", {
		Size = UDim2.new(0, 150, 0, 4),
		Position = UDim2.new(0.5, 0, 0.5, 42),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		ZIndex = 31,
		Parent = splash,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barBg })
	local bar = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		ZIndex = 31,
		Parent = barBg,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
	new("UIGradient", { Color = ColorSequence.new(C.Accent, C.Accent2), Parent = bar })

	local busy = false
	return function()
		if busy then return end
		busy = true
		splash.Visible = true
		splash.BackgroundTransparency = 0
		glow.BackgroundTransparency = 0.88
		bar.Size = UDim2.new(0, 0, 1, 0)
		title.TextTransparency = 0
		icon.BackgroundTransparency = 0

		iconScale.Scale = 0.6
		tween(iconScale, EASE.pop, { Scale = 1 })
		slideIn(title, 8, 0.06, 0.3)

		task.spawn(function()
			TweenService:Create(bar,
				TweenInfo.new(0.44, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Size = UDim2.new(1, 0, 1, 0) }):Play()
			task.wait(0.52)

			local fade = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(splash, fade, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(glow, fade, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(title, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(icon, fade, { BackgroundTransparency = 1 }):Play()
			for _, d in ipairs(icon:GetDescendants()) do
				if d:IsA("ImageLabel") then
					TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
				elseif d:IsA("TextLabel") then
					TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
				end
			end
			task.wait(0.26)
			splash.Visible = false
			icon.BackgroundTransparency = 0
			for _, d in ipairs(icon:GetDescendants()) do
				if d:IsA("ImageLabel") then d.ImageTransparency = 0 end
				if d:IsA("TextLabel") then d.TextTransparency = 0 end
			end
			busy = false
		end)
	end
end

-- 不在目标服务器里时弹的拦截窗：一个模态 + bruh 音效，只能靠右上角 ✕ 关掉。
-- ⚠️ 放在 boot 外面：它那一堆局部变量不算进 boot 的 200 名额
local DENY_MODAL = nil

local function closeDenyModal()
	local f = DENY_MODAL
	DENY_MODAL = nil
	if f then pcall(f) end
end

-- 当前是不是在指定的 place 里 -> (是否匹配, 当前 id)
local function inPlace(id)
	local ok, pid = pcall(function() return game.PlaceId end)
	if ok and type(pid) == "number" then return pid == id, pid end
	return false, nil
end

--========================== 服务器：劫案 ==========================
-- place 21532277 = 主游戏（大厅，没脚本）；universe 16680835 = 整款游戏。
-- Roblox 里同一个 universe 的所有 place 共用 game.GameId，所以劫案地图
-- （珠宝店之类）也算"在这款游戏里"，能过关；主游戏在里面单独判。
local PD = {
	Place  = 21532277,
	Game   = 16680835,
	Maps   = {},   -- 可选：拿不到地图名时按 placeId 手动补，比如 [21532278] = "珠宝店"
	AllyKw = { "ally", "friend", "crew", "friendly", "teammate", "hostage", "civilian" },
}

-- 在不在「劫案」里（主游戏或任意地图） -> (是否匹配, 当前 placeId)
local function pdInGame()
	local ok, pid, gid = pcall(function() return game.PlaceId, game.GameId end)
	if not ok then return false, nil end
	if pid == PD.Place or gid == PD.Game or PD.Maps[pid] then return true, pid end
	return false, pid
end

-- 主游戏 = 从 Roblox 正常点进来的那个 place；其它 place 都当成劫案地图
local function pdIsMain()
	local ok, pid = pcall(function() return game.PlaceId end)
	return (not ok) or pid == PD.Place
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
		Size = UDim2.new(1, 0, 0, 26),
		Position = opts.Position,
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local track = new("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
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

	-- 旋钮：拖动 / 悬停时放大，给一点"抓住了"的手感
	local knob = new("Frame", {
		Name = "SliderKnob",
		Size = UDim2.new(0, 15, 0, 15),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = hit,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local knobStroke = new("UIStroke", { Color = C.Accent, Thickness = 2, Parent = knob })
	local knobScale  = new("UIScale", { Scale = 1, Parent = knob })

	local dragging = false

	local function setValue(v, fire)
		v = math.clamp(v, min, max)
		local frac = math.clamp(toFrac(v), 0, 1)
		fill.Size = UDim2.new(frac, 0, 1, 0)
		knob.Position = UDim2.new(frac, 0, 0.5, 0)
		if fire and opts.OnChange then opts.OnChange(v) end
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
			tween(knobScale, EASE.soft, { Scale = 1.34 })
			tween(knobStroke, EASE.soft, { Thickness = 3 })
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
			tween(knobScale, EASE.pop, { Scale = 1 })
			tween(knobStroke, EASE.soft, { Thickness = 2 })
		end
	end)

	setValue(opts.Default or min, false)
	return setValue
end

--========================== 按钮组件 ==========================
local function createButton(parent, opts)
	local style  = opts.Style or "ghost"
	local radius = opts.Radius or R.ctl

	local baseBg, hoverBg
	if style == "primary" then
		baseBg, hoverBg = C.Accent, Color3.fromRGB(244, 74, 92)
	elseif style == "solid" then
		baseBg, hoverBg = C.Raised, C.Card2
	else
		baseBg, hoverBg = C.Card, C.Card2
	end

	local btn = new("TextButton", {
		Name = opts.Name or "Button",
		Size = opts.Size,
		Position = opts.Position,
		BackgroundColor3 = baseBg,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,      -- 涟漪要裁在圆角里
		ZIndex = opts.ZIndex or 1,
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = btn })
	local stroke = new("UIStroke", {
		Color = opts.StrokeColor or (style == "primary" and C.Accent or C.Stroke),
		Thickness = 1,
		Parent = btn,
	})

	local label = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = opts.Text or "",
		TextSize = opts.TextSize or 14,
		Font = opts.Font or FONT_B,
		TextColor3 = opts.TextColor3 or opts.TextColor or C.Text,
		ZIndex = 2,
		Parent = btn,
	})

	bindHover(btn, {
		Bg       = { baseBg, hoverBg },
		Stroke   = stroke,
		StrokeOn = (style == "primary") and C.Accent2 or C.Stroke2,
		Label    = label,
		LabelOn  = (style == "primary") and C.White or C.Text,
	})
	bindPress(btn, (style == "primary") and C.White or C.Accent)

	btn.MouseButton1Click:Connect(function()
		if opts.OnClick then opts.OnClick() end
	end)

	return btn, label, stroke, baseBg
end

--========================== 开关组件 ==========================
local function createSwitch(parent, opts)
	local width, height = 40, 22
	local holder = new("TextButton", {
		Name = opts.Name or "Switch",
		Size = UDim2.new(0, width, 0, height),
		Position = opts.Position,
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = holder })
	local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = holder })

	local knob = new("Frame", {
		Name = "SwitchKnob",
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
		local info = animate and EASE.pop or EASE.fast
		tween(holder, info, { BackgroundColor3 = state and C.Accent or C.Card2 })
		tween(stroke, info, { Color = state and C.Accent2 or C.Stroke })
		tween(knob, info, {
			Position = state and UDim2.new(0, width - 19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = state and C.White or C.Sub,
		})
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
--========================== 右下角提示 ==========================
-- 单独一个 ScreenGui（不挂在主 GUI 下），主窗口隐藏时提示照样能弹。
-- 它在 boot 里创建，所以这里只写函数体。
local TOASTS = {}
local TOAST_W, TOAST_H, TOAST_GAP = 288, 52, 8

local function relayoutToasts()
	local step = TOAST_H + TOAST_GAP
	local y = 0
	for _, o in ipairs(TOASTS) do
		o.y = y
		tween(o.frame, EASE.out, { Position = UDim2.new(1, 0, 1, -y) })
		y = y + step
	end
end

local function dismissToast(t)
	for i, o in ipairs(TOASTS) do
		if o == t then table.remove(TOASTS, i) break end
	end
	tween(t.frame, EASE.gone, { Position = UDim2.new(1, 40, 1, -t.y) })
	for _, e in ipairs(t.snap) do
		local props = {}
		if e.tx ~= nil then props.TextTransparency = 1 end
		if e.im ~= nil then props.ImageTransparency = 1 end
		if e.bg ~= nil then props.BackgroundTransparency = 1 end
		TweenService:Create(e.d, EASE.gone, props):Play()
	end
	task.delay(0.3, function() pcall(function() t.frame:Destroy() end) end)
	relayoutToasts()
end

notify = function(text, color)
	if SHUTDOWN or not notifyHolder then return end
	color = color or C.Accent

	-- 旧的往上让一格
	local step = TOAST_H + TOAST_GAP
	for _, o in ipairs(TOASTS) do
		o.y = o.y + step
		tween(o.frame, EASE.out, { Position = UDim2.new(1, 0, 1, -o.y) })
	end

	local frame = new("Frame", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, TOAST_H),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 44, 1, 0),      -- 先摆在屏幕右侧外面
		BackgroundColor3 = C.Raised,
		BorderSizePixel = 0,
		ZIndex = 60,
		Parent = notifyHolder,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = frame })
	new("UIStroke", { Color = color, Thickness = 1, Transparency = 0.55, Parent = frame })

	-- 左侧色条：颜色即语义（成功绿 / 失败红 / 普通红）
	new("Frame", {
		Name = "ToastBar",
		Size = UDim2.new(0, 3, 1, -18),
		Position = UDim2.new(0, 7, 0, 9),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 61,
		Parent = frame,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -34, 1, -8),
		Position = UDim2.new(0, 20, 0, 4),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 13,
		Font = FONT_N,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		ZIndex = 61,
		Parent = frame,
	})

	-- 底部倒计时细线
	local bar = new("Frame", {
		Size = UDim2.new(1, -14, 0, 2),
		Position = UDim2.new(0, 7, 1, -6),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 61,
		Parent = frame,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

	local t = { frame = frame, y = 0, snap = nil }
	table.insert(TOASTS, 1, t)

	-- 入场：从右侧滑进来
	t.snap = alphaSnapshot(frame)
	setAlpha(t.snap, 1)
	task.spawn(function()
		task.wait(0.02)
		if not frame.Parent then return end
		TweenService:Create(frame, EASE.pop, { Position = UDim2.new(1, 0, 1, 0) }):Play()
		for _, e in ipairs(t.snap) do
			local props = {}
			if e.tx ~= nil then props.TextTransparency = e.tx end
			if e.im ~= nil then props.ImageTransparency = e.im end
			if e.bg ~= nil then props.BackgroundTransparency = e.bg end
			TweenService:Create(e.d, EASE.pop, props):Play()
		end
	end)

	tween(bar, TweenInfo.new(3.2, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
	playSfx("sfx_notify", CONFIG.SoundNotify)

	task.delay(3.4, function()
		if frame.Parent then dismissToast(t) end
	end)
end

--=====================================================================
--  一、开机动画（终端启动序列）
--=====================================================================
-- opts = { Title, Subtitle, Stages = {{text, pct, dur}, ...} }
-- 固定 720×420 画布 + UIScale，任何屏幕比例都不会散
-- 加入某个服务器。跨服之后要能自动重新执行脚本，只能靠执行器提供的
-- queueonteleport 之类的函数；拿不到就照样传送，但要如实告诉用户一句。
--
-- 传送三层降级：
--   1) **执行器私有 API**（Synapse X 的 syn.Teleport、Fluxus 的 fluxus.Teleport 等）：
--      这些是执行器自己实现的传送，**绕过 Roblox 客户端对 TeleportService 的限制**，
--      是 v1.8.3 之前的脚本漏掉的关键通道。
--   2) 官方 TeleportService:Teleport（fallback）：Roblox 客户端允许时也能用。
--   3) 全失败：复制游戏主页链接到剪贴板（手动兜底）。
--
-- 跨服重试（v1.8.4）：如果上面三条路全失败，就把这个目标服务器 ID 写到
-- _G.O_X_HUB_PENDING_JOIN 持久化。脚本下次被注入时（玩家被传送、或换了服务器、
-- 或被玩家手动再 loadstring 一次），boot 开头会先检查这个标记——
-- 如果当前 Place ID 还没到目标 place，**静默自动重试传送**。
-- 用户在执行器那边设成"加入任意服务器自动注入"就能彻底免手动。
local PENDING_KEY = "O_X_HUB_PENDING_JOIN"

local function pendingEnvs()
	local envs = {}
	pcall(function() envs[#envs + 1] = getgenv and getgenv() end)
	pcall(function() envs[#envs + 1] = _G end)
	return envs
end

local function setPendingJoin(id, name)
	for _, env in ipairs(pendingEnvs()) do
		pcall(function()
			env[PENDING_KEY] = { id = id, name = name, ts = os.time() }
		end)
	end
end

local function getPendingJoin()
	for _, env in ipairs(pendingEnvs()) do
		local v = rawget(env, PENDING_KEY)
		if type(v) == "table" and type(v.id) == "number" then
			return v
		end
	end
	return nil
end

local function clearPendingJoin()
	for _, env in ipairs(pendingEnvs()) do
		pcall(function() env[PENDING_KEY] = nil end)
	end
end

-- 提示条 GUI（提到外面是因为 boot 开头 autoResolvePending 就要用 notify）
local function ensureNotify()
	if notifyGui and notifyGui.Parent then return end
	notifyGui = new("ScreenGui", {
		Name = "O_X_HUB_Notify",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 100001,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GUI_PARENT,
	})
	TOASTS = {}
	notifyHolder = new("Frame", {
		Name = "NotifyHolder",
		Size = UDim2.new(0, TOAST_W, 0, 1),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = notifyGui,
	})
end

local EXEC_TELEPORT_LIBS = { "synapse", "syn", "fluxus", "FL", "script_ware", "SW", "krnl" }
local EXEC_TELEPORT_FNS = { "Teleport", "teleport" }

local function execTeleport(id)
	-- 1) obj.fn 形式：syn.Teleport / fluxus.Teleport / ...
	for _, libName in ipairs(EXEC_TELEPORT_LIBS) do
		local lib = execFn(libName)
		if type(lib) == "table" then
			for _, fnName in ipairs(EXEC_TELEPORT_FNS) do
				local fn = lib[fnName]
				if isCallable(fn) and pcall(fn, id) then
					return true, libName .. "." .. fnName
				end
			end
		end
	end
	-- 2) 直接全局函数：teleport(id)
	for _, fnName in ipairs(EXEC_TELEPORT_FNS) do
		local fn = execFn(fnName)
		if isCallable(fn) and pcall(fn, id) then
			return true, fnName
		end
	end
	return false, nil
end

local function joinPlace(id, name)
	local TeleportService = game:GetService("TeleportService")

	local queue = execFn("queueonteleport") or execFn("queue_on_teleport")
	if not queue then
		pcall(function()
			local syn = rawget(_G, "syn")
			if type(syn) == "table" and isCallable(syn.queue_on_teleport) then
				queue = syn.queue_on_teleport
			end
		end)
	end

	local queued = false
	if queue and CONFIG.RawUrl then
		local code = string.format('loadstring(game:HttpGet("%s?t=" .. os.time()))()', CONFIG.RawUrl)
		queued = pcall(queue, code)
	end

	-- 监听一次性的传送失败事件（异步，pcall 拦不住）
	local failConn
	if TeleportService.TeleportInitFailed then
		failConn = TeleportService.TeleportInitFailed:Connect(function(player, resultEnum, msg)
			if failConn then pcall(function() failConn:Disconnect() end) end
			notify(string.format(L("joinFail"), tostring(msg or resultEnum.Name or "unknown")), C.Amber)
		end)
	end

	-- 记下当前 Place ID，3 秒后用来验证传送是否真的发生了
	-- （执行器 / Roblox 反作弊会静默忽略 Teleport 请求，pcall 不会报错）
	local beforePlace = (pcall(function() return game.PlaceId end)) and game.PlaceId or nil

	local function copyGameLink()
		pcall(function()
			local clip = execFn("setclipboard") or execFn("toclipboard")
			if clip then clip("https://www.roblox.com/games/" .. tostring(id)) end
		end)
	end

	-- ===== 优先：执行器私有 teleport API（绕过客户端限制的关键）=====
	local execName
	local ok, usedVia = execTeleport(id)
	local anyAttempt = ok                                -- 至少试过一条通道
	if ok then
		notify(string.format(L("joinVia"), tostring(name), tostring(usedVia)), C.Accent)
	else
		-- ===== fallback：官方 TeleportService:Teleport =====
		ok, usedVia = pcall(function() TeleportService:Teleport(id) end)
		anyAttempt = true
		if not ok then
			ok, usedVia = pcall(function() TeleportService:Teleport(id, LocalPlayer) end)
		end
		if ok then
			notify(string.format(queued and L("joinOk") or L("joinNoQueue"), tostring(name)), C.Accent)
		else
			-- pcall 也抛了
			notify(string.format(L("joinFail"), tostring(usedVia or "Teleport rejected")), C.Amber)
			copyGameLink()
			-- 持久化为待传送：脚本下次注入时自动重试
			setPendingJoin(id, name)
			task.delay(3, function()
				if failConn then pcall(function() failConn:Disconnect() end) end
			end)
			return
		end
	end

	-- 验证：传送成功玩家会进入新 place、脚本会被卸载；
	-- 如果 3 秒后还在原 place，说明请求被静默忽略
	task.delay(3, function()
		if SHUTDOWN then return end
		local afterPlace = (pcall(function() return game.PlaceId end)) and game.PlaceId or nil
		if beforePlace and afterPlace == beforePlace then
			notify(L("joinSilent"), C.Amber)
			copyGameLink()
			-- 静默被拒 → 也记成 pending（下次注入会重试）
			setPendingJoin(id, name)
		end
		if failConn then pcall(function() failConn:Disconnect() end) end
	end)
end

-- boot 开头调一次：如果上一份脚本传送失败时留下了 pending，
-- 在新 place 上自动重试一次（静默，弹个 "正在加入" 提示）。
-- 用户执行器那边开"自动注入"就能彻底免手动。
local function autoResolvePending()
	local p = getPendingJoin()
	if not p then return end
	local current = (pcall(function() return game.PlaceId end)) and game.PlaceId or nil
	if current == p.id then
		-- 已经在目标服务器了（可能是用户手动加入的，也可能是某次传送终于成功了）
		clearPendingJoin()
		return
	end
	if current then
		-- 当前在某个非目标服务器 → 静默重试
		notify(string.format(L("joinPendingRetry"), tostring(p.name)), C.Accent)
	end
	joinPlace(p.id, p.name)
end

local function showDenyModal(titleText, bodyText, noteText, placeId, serverName)
	closeDenyModal()

	local gui = new("ScreenGui", {
		Name = "O_X_HUB_Deny",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 100010,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GUI_PARENT,
	})

	local scrim = new("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Void,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local card = new("Frame", {
		Name = "DenyCard",
		Size = UDim2.new(0, 400, 0, 240),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C.Window,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = scrim,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = card })
	local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Transparency = 1, Parent = card })
	local cardScale = new("UIScale", { Scale = 0.92, Parent = card })

	local badge = new("Frame", {
		Name = "Badge",
		Size = UDim2.new(0, 46, 0, 46),
		Position = UDim2.new(0.5, 0, 0, 28),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = C.AccentLo,
		BorderSizePixel = 0,
		Parent = card,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
	new("UIStroke", { Color = C.Accent, Thickness = 1, Transparency = 0.35, Parent = badge })
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "!",
		TextSize = 24,
		Font = FONT_B,
		TextColor3 = C.Accent,
		Parent = badge,
	})

	local title = new("TextLabel", {
		Size = UDim2.new(1, -56, 0, 24),
		Position = UDim2.new(0, 28, 0, 86),
		BackgroundTransparency = 1,
		Text = titleText,
		TextSize = 18,
		Font = FONT_B,
		TextColor3 = C.Text,
		Parent = card,
	})
	local body = new("TextLabel", {
		Size = UDim2.new(1, -64, 0, 40),
		Position = UDim2.new(0, 32, 0, 116),
		BackgroundTransparency = 1,
		Text = bodyText,
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})
	local note = new("TextLabel", {
		Size = UDim2.new(1, -64, 0, 16),
		Position = UDim2.new(0, 32, 0, 160),
		BackgroundTransparency = 1,
		Text = noteText,
		TextSize = 11,
		Font = FONT_M,
		TextColor3 = C.Dim,
		Parent = card,
	})

	-- 右上角的 ✕：指定过的关闭方式
	local closeBtn = new("TextButton", {
		Name = "Close",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -38, 0, 12),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "✕",
		TextSize = 14,
		Font = FONT_B,
		TextColor3 = C.Sub,
		Parent = card,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 9), Parent = closeBtn })
	local closeStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = closeBtn })
	bindHover(closeBtn, {
		Bg = { C.Card, C.Red }, Stroke = closeStroke, StrokeOn = C.Red,
		Label = closeBtn, LabelOn = C.White,
	})

	local closing = false
	local function close()
		if closing then return end
		closing = true
		local fade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(scrim, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(card, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		tween(cardScale, fade, { Scale = 0.94 })
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") then
				TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
			end
		end
		task.delay(0.24, function() pcall(function() gui:Destroy() end) end)
	end

	closeBtn.MouseButton1Click:Connect(close)

	-- 「加入对应服务器」：直接跳过去，并尽量排好落地后自动重新执行
	if placeId then
		createButton(card, {
			Name = "JoinServer",
			Size = UDim2.new(0, 200, 0, 36),
			Position = UDim2.new(0.5, -100, 0, 188),
			Text = L("denyJoin"),
			TextSize = 13,
			Style = "primary",
			TextColor3 = C.White,
			OnClick = function()
				close()
				joinPlace(placeId, serverName or tostring(placeId))
			end,
		})
	end


	-- 入场
	TweenService:Create(scrim, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.42 }):Play()
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 0 }):Play()
	tween(cardScale, EASE.pop, { Scale = 1 })
	slideIn(badge, 10, 0.04, 0.3)
	slideIn(title, 10, 0.09, 0.3)
	slideIn(body, 10, 0.14, 0.3)
	slideIn(note, 10, 0.19, 0.3)
	local joinBtn = card:FindFirstChild("JoinServer")
	if joinBtn then slideIn(joinBtn, 10, 0.24, 0.3) end

	DENY_MODAL = close
	return close
end

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
		Name = "Boot",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Void,
		BorderSizePixel = 0,
		Parent = gui,
	})

	-- 顶部一层很淡的氛围光：只压一点暖色，不做霓虹
	local glow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 340),
		Position = UDim2.new(0, 0, 0, -220),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.94,
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

	local stage = new("Frame", {
		Name = "BootStage",
		Size = UDim2.new(0, 720, 0, 420),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = bg,
	})
	local stageScale = new("UIScale", { Scale = 1, Parent = stage })
	local function fitStage()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		stageScale.Scale = math.clamp(math.min(vp.X / 800, vp.Y / 520), 0.45, 1.4)
	end
	fitStage()

	-- 扫过整屏的一条细光带：暗示"正在跑"
	local scan = new("Frame", {
		Name = "Scan",
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 0, -8),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = stage,
	})
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = scan,
	})
	tween(scan, TweenInfo.new(2.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
		{ Position = UDim2.new(0, 0, 0, 420) })

	-- ---------- 品牌区 ----------
	local logo = createLogo(stage, {
		Size = UDim2.new(0, 62, 0, 62),
		Position = UDim2.new(0, 0, 0, 6),
		Radius = 18,
		TextSize = 30,
	})
	local brand = new("TextLabel", {
		Size = UDim2.new(0, 460, 0, 36),
		Position = UDim2.new(0, 78, 0, 8),
		BackgroundTransparency = 1,
		Text = opts.Title or CONFIG.Title,
		TextSize = 28,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stage,
	})
	local subtitle = new("TextLabel", {
		Size = UDim2.new(0, 460, 0, 18),
		Position = UDim2.new(0, 79, 0, 44),
		BackgroundTransparency = 1,
		Text = opts.Subtitle or L("loading"),
		TextSize = 12,
		Font = FONT_M,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stage,
	})

	local rule = new("Frame", {
		Size = UDim2.new(0, 44, 0, 3),
		Position = UDim2.new(0, 0, 0, 84),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = stage,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = rule })
	tween(rule, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = UDim2.new(0, 132, 0, 3) })

	-- ---------- 终端面板 ----------
	local term = new("Frame", {
		Name = "BootTerm",
		Size = UDim2.new(1, 0, 0, 130),
		Position = UDim2.new(0, 0, 0, 112),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = stage,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = term })
	new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = term })

	local termLines = {}
	local function addLine(text)
		local y = 16 + #termLines * 21
		local row = new("Frame", {
			Name = "TermRow",
			Size = UDim2.new(1, -28, 0, 18),
			Position = UDim2.new(0, 14, 0, y),
			BackgroundTransparency = 1,
			Parent = term,
		})
		new("TextLabel", {
			Size = UDim2.new(0, 12, 1, 0),
			BackgroundTransparency = 1,
			Text = ">",
			TextSize = 12,
			Font = FONT_M,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		new("TextLabel", {
			Size = UDim2.new(1, -76, 1, 0),
			Position = UDim2.new(0, 16, 0, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextSize = 12,
			Font = FONT_M,
			TextColor3 = C.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local mark = new("TextLabel", {
			Size = UDim2.new(0, 56, 1, 0),
			Position = UDim2.new(1, -56, 0, 0),
			BackgroundTransparency = 1,
			Text = "...",
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		slideIn(row, 6, 0, 0.22)
		table.insert(termLines, { row = row, mark = mark })
		return mark
	end

	-- ---------- 进度条 ----------
	local track = new("Frame", {
		Size = UDim2.new(1, -72, 0, 6),
		Position = UDim2.new(0, 0, 0, 356),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		Parent = stage,
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

	local head = new("Frame", {
		Size = UDim2.new(0, 10, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = head })

	local percent = new("TextLabel", {
		Size = UDim2.new(0, 64, 0, 16),
		Position = UDim2.new(1, 0, 0, 351),
		BackgroundTransparency = 1,
		Text = "0%",
		TextSize = 12,
		Font = FONT_M,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = stage,
	})

	local version = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -22),
		BackgroundTransparency = 1,
		Text = CONFIG.Title .. "   " .. CONFIG.Version,
		TextSize = 11,
		Font = FONT_M,
		TextColor3 = Color3.fromRGB(66, 68, 80),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stage,
	})

	-- 品牌区依次落下
	staggerIn({ logo, brand, subtitle, rule }, 14, 0.06, 0.4)
	slideIn(term, 18, 0.18, 0.42)

	local current = 0
	local function setPct(v)
		current = v
		fill.Size = UDim2.new(v / 100, 0, 1, 0)
		head.Position = UDim2.new(v / 100, 0, 0.5, 0)
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
		local tw = TweenService:Create(nv,
			TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 1 })
		tw:Play()
		tw.Completed:Wait()
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
		task.wait(0.2)
		for _, st in ipairs(stages) do
			subtitle.Text = st[1]
			local mark = addLine(st[1])
			animateTo(st[2], st[3])
			mark.Text = "OK"
			mark.TextColor3 = C.Green
			task.wait(0.04)
		end
		task.wait(0.3)

		-- 整屏淡出
		local fade = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(bg, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(glow, fade, { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(stage:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") then
				TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
			elseif d:IsA("ImageLabel") then
				TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
			end
		end
		task.wait(0.46)
		gui:Destroy()
		if onDone then onDone() end
	end)
end

--=====================================================================
--  一·五、语言选择（注入后的第一屏）
--  两种语言都要露脸，所以这一屏不做翻译，中英并排写。
--  固定 760×440 画布 + UIScale，手机 / 电脑都是同一套构图。
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
		Name = "LangBg",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Void,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local glow = new("Frame", {
		Size = UDim2.new(0, 900, 0, 520),
		Position = UDim2.new(0, -260, 0, -260),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Parent = bg,
	})
	new("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = glow,
	})

	local stage = new("Frame", {
		Name = "LangStage",
		Size = UDim2.new(0, 760, 0, 440),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = bg,
	})
	local stageScale = new("UIScale", { Scale = 1, Parent = stage })
	local function fitStage()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		stageScale.Scale = math.clamp(math.min(vp.X / 830, vp.Y / 510), 0.42, 1.35)
	end
	fitStage()

	-- 左右两栏之间一条极细的分隔线（分隔真实内容，不是装饰）
	new("Frame", {
		Size = UDim2.new(0, 1, 1, -150),
		Position = UDim2.new(0, 348, 0, 75),
		BackgroundColor3 = C.Stroke,
		BorderSizePixel = 0,
		Parent = stage,
	})

	-- ---------- 左：品牌 ----------
	local logo = createLogo(stage, {
		Size = UDim2.new(0, 92, 0, 92),
		Position = UDim2.new(0, 22, 0, 86),
		Radius = 26,
		TextSize = 44,
	})
	local brand = new("TextLabel", {
		Size = UDim2.new(0, 300, 0, 42),
		Position = UDim2.new(0, 22, 0, 196),
		BackgroundTransparency = 1,
		Text = CONFIG.Title,               -- 这个名字两种语言都不翻译
		TextSize = 34,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stage,
	})
	local rule = new("Frame", {
		Size = UDim2.new(0, 46, 0, 3),
		Position = UDim2.new(0, 24, 0, 246),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Parent = stage,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = rule })

	local tagline = new("TextLabel", {
		Size = UDim2.new(0, 300, 0, 18),
		Position = UDim2.new(0, 23, 0, 262),
		BackgroundTransparency = 1,
		Text = CONFIG.Title .. "  " .. CONFIG.Version,
		TextSize = 12,
		Font = FONT_M,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stage,
	})

	-- ---------- 右：语言 ----------
	local prompt = new("TextLabel", {
		Size = UDim2.new(0, 340, 0, 18),
		Position = UDim2.new(0, 396, 0, 92),
		BackgroundTransparency = 1,
		Text = "选择语言  /  Select language",
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = stage,
	})

	local picking = false
	local function pick(key)
		if picking then return end
		picking = true
		playSfx("sfx_notify", 0.32)
		local fade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(stage, fade, { Position = UDim2.new(0.5, 0, 0.5, -14) }):Play()
		TweenService:Create(bg, fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(glow, fade, { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(stage:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") then
				TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
			elseif d:IsA("ImageLabel") then
				TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
			end
		end
		task.delay(0.24, function()
			pcall(function() gui:Destroy() end)
			onPick(key)
		end)
	end

	local cards = {}
	for i, opt in ipairs(LANG_CHOICES) do
		local btn = new("TextButton", {
			Name = "Pick_" .. opt.key,
			Size = UDim2.new(0, 340, 0, 92),
			Position = UDim2.new(0, 396, 0, 122 + (i - 1) * 104),
			BackgroundColor3 = C.Card,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			Parent = stage,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = btn })
		local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = btn })

		createFlag(btn, opt.flag, UDim2.new(0, 54, 0, 36), UDim2.new(0, 20, 0.5, 0),
			Vector2.new(0, 0.5), 7, opt.key == "zh" and "ZH" or "EN")

		new("TextLabel", {
			Size = UDim2.new(0, 200, 0, 22),
			Position = UDim2.new(0, 90, 0, 26),
			BackgroundTransparency = 1,
			Text = opt.name,
			TextSize = 17,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})
		new("TextLabel", {
			Size = UDim2.new(0, 200, 0, 16),
			Position = UDim2.new(0, 91, 0, 50),
			BackgroundTransparency = 1,
			Text = opt.desc,
			TextSize = 11,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})
		local arrow = new("TextLabel", {
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(1, -48, 0.5, -15),
			BackgroundTransparency = 1,
			Text = "→",
			TextSize = 18,
			Font = FONT_B,
			TextColor3 = C.Dim,
			Parent = btn,
		})

		-- 悬停：抬起来一点 + 描边亮起 + 箭头往右推
		btn.MouseEnter:Connect(function()
			tween(btn, EASE.soft, { BackgroundColor3 = C.Card2, Position = UDim2.new(0, 396, 0, 118 + (i - 1) * 104) })
			tween(stroke, EASE.soft, { Color = C.Accent })
			tween(arrow, EASE.soft, { TextColor3 = C.Accent, Position = UDim2.new(1, -40, 0.5, -15) })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, EASE.soft, { BackgroundColor3 = C.Card, Position = UDim2.new(0, 396, 0, 122 + (i - 1) * 104) })
			tween(stroke, EASE.soft, { Color = C.Stroke })
			tween(arrow, EASE.soft, { TextColor3 = C.Dim, Position = UDim2.new(1, -48, 0.5, -15) })
		end)
		btn.MouseButton1Click:Connect(function() pick(opt.key) end)
		cards[#cards + 1] = btn
	end

	staggerIn({ logo, brand, rule, tagline, prompt }, 16, 0.07, 0.42)
	staggerIn(cards, 22, 0.09, 0.46)
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

	-- 提示条 GUI（autoResolvePending / joinPlace 都依赖它，先建好）
	ensureNotify()

	-- 上一份脚本传送失败留下了目标 → 在当前 place 静默重试
	-- 用户执行器那边开"加入任意服务器自动注入"就能彻底免手动
	autoResolvePending()

	-- 全局连接的登记处 —— 主窗口 ✕ 关掉时要能把它们全断开。
	-- ⚠️ 必须放在 boot 开头：后面每个模块都要用，Lua 只认"声明在前"
	local function track(conn)
		table.insert(GLOBAL_CONNS, conn)
		return conn
	end

	local WIN_W, WIN_H   = 520, 380
	local SIDEBAR_W      = 132
	local HEADER_H       = 46

	local FLY_W, FLY_H   = 380, 356

	local SRV_W, SRV_H   = 520, 360
	local SRV_SIDE_W     = 118
	local SRV_HEAD_H     = 42

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
	new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = window })
	new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = window })

	local uiScale = new("UIScale", { Scale = 1, Parent = window })

	-- 顶栏压一条渐变强调线：软件感的来源，也把视觉重心拉到左边
	local topRule = new("Frame", {
		Name = "TopRule",
		Size = UDim2.new(0, 190, 0, 2),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = window,
	})
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = topRule,
	})

	-- 顶栏
	local header = new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		Parent = window,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = header })
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
		Size = UDim2.new(0, 150, 1, 0),
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
		Size = UDim2.new(0, 90, 1, 0),
		Position = UDim2.new(1, -168, 0, 0),
		BackgroundTransparency = 1,
		Text = CONFIG.Version,
		TextSize = 11,
		Font = FONT_M,
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
	bindHover(minBtn, {
		Bg = { C.Card, C.Card2 }, Stroke = minStroke, StrokeOn = C.Stroke2,
		Label = minBtn, LabelOn = C.Text,
	})

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
	bindHover(closeBtn, {
		Bg = { C.Card, C.Red }, Stroke = closeStroke, StrokeOn = C.Red,
		Label = closeBtn, LabelOn = C.White,
	})

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
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = sidebar })

	new("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14),
		Position = UDim2.new(0, 14, 0, 10),
		BackgroundTransparency = 1,
		Text = L("navGroup"),
		TextSize = 10,
		Font = FONT_B,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sidebar,
	})

	-- 会滑动的选中指示条：整份界面只有一条，跟着当前页走
	local navIndicator = new("Frame", {
		Name = "NavIndicator",
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 0, 0, 35),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = sidebar,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = navIndicator })

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

	-- 兜底自检：入场动画跑完之后，主界面里不该还有"本该完全不透明却全透明"的元素。
	-- 正常情况下一处都不会修；修到了说明动画逻辑又出问题了（会打日志）。
	-- 两个限定条件，免得把"故意淡出"的临时效果误判成故障：
	--   ① 只查"出厂时完全不透明"的元素（涟漪、开场动画的光晕本来就是半透明）
	--   ② 跳过被隐藏祖先挡住的（飞行开场动画跑完会把整层 Visible = false）
	local function healVisibility(delaySec)
		task.delay(delaySec or 1.2, function()
			if SHUTDOWN then return end

			local function hiddenByAncestor(d)
				local cur = d
				for _ = 1, 12 do
					if not cur or cur == guiMain then return false end
					if cur.Visible == false then return true end
					cur = cur.Parent
				end
				return false
			end

			local fixed, names = 0, {}
			for _, d in ipairs(guiMain:GetDescendants()) do
				local want = BASE_ALPHA[d]
				if want and not hiddenByAncestor(d) then
					local hit = false
					if want.tx == 0 and d.TextTransparency > 0.999 then
						d.TextTransparency = 0; hit = true
					end
					if want.im == 0 and d.ImageTransparency > 0.999 then
						d.ImageTransparency = 0; hit = true
					end
					if want.bg == 0 and d.BackgroundTransparency > 0.999 then
						d.BackgroundTransparency = 0; hit = true
					end
					if hit then
						fixed = fixed + 1
						if #names < 6 then names[#names + 1] = d.Name end
					end
				end
			end
			if fixed > 0 then
				pcall(function()
					print("[O_X_HUB] 入场自检：修好了 " .. fixed .. " 个卡在全透明的元素 -> "
						.. table.concat(names, ", "))
				end)
			end
		end)
	end

	local function showPage(key)
		for k, page in pairs(pages) do
			page.Visible = (k == key)
		end
		for k, item in pairs(navItems) do
			local active = (k == key)
			tween(item.label, EASE.soft, { TextColor3 = active and C.Text or C.Sub })
			tween(item.btn, EASE.soft, { BackgroundColor3 = active and C.Card or C.Side })
		end

		-- 指示条滑过去，而不是直接跳过去
		local item = navItems[key]
		if item then
			tween(navIndicator, EASE.pop, { Position = UDim2.new(0, 0, 0, item.y + 5) })
		end

		-- 内容轻轻浮上来
		local target = pages[key]
		if target then
			staggerIn(target:GetChildren(), 9, 0.03, 0.3)
			healVisibility(0.9)
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
		new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = btn })

		local label = new("TextLabel", {
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.new(0, 16, 0, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextSize = 13,
			Font = FONT_N,
			TextColor3 = C.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})

		-- 只有「飞行」带状态点：绿 = 正在飞。状态点表达真实状态，不做装饰
		local dot = nil
		if key == "fly" then
			dot = new("Frame", {
				Name = "NavDot",
				Size = UDim2.new(0, 6, 0, 6),
				Position = UDim2.new(1, -14, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = C.Green,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = btn,
			})
			new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		end

		btn.MouseButton1Click:Connect(function()
			if onClick then onClick() else showPage(key) end
		end)
		-- 悬停时不要盖掉"当前页"的高亮
		btn.MouseEnter:Connect(function()
			if not pages[key] or not pages[key].Visible then
				tween(btn, EASE.soft, { BackgroundColor3 = C.Card })
			end
			tween(label, EASE.soft, { TextColor3 = C.Text })
		end)
		btn.MouseLeave:Connect(function()
			if not pages[key] or not pages[key].Visible then
				tween(btn, EASE.soft, { BackgroundColor3 = C.Side })
			end
			tween(label, EASE.soft, {
				TextColor3 = (pages[key] and pages[key].Visible) and C.Text or C.Sub,
			})
		end)

		navItems[key] = { btn = btn, label = label, dot = dot, y = y }
		return btn
	end

	-- 飞行窗口的开窗函数、飞行开关（都在后面定义，这里先占位）
	local openFlyWindow = function() end
	local openSrvWindow = function() end
	local SrvTeleportRequest = function() end
	local SrvAutoWinRequest = function() end
	local SrvCloseRequest = function() end
	-- 劫案面板：窗口开关 + 关脚本时的清理（真正实现都在下面那个 do 块里）
	local openPdWindow = function() end
	local PdCloseRequest = function() end
	local pdCleanup = function() end
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
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0, 0, 0, 2),
		BackgroundTransparency = 1,
		Text = string.format(L("homeWelcome"), CONFIG.Title),
		TextSize = 20,
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
		TextSize = 11,
		Font = FONT_M,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = home,
	})

	-- 当前数值一览：等宽字体，数字对齐了才有"仪表盘"的感觉
	local statRow = new("Frame", {
		Name = "HomeStats",
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 0, 58),
		BackgroundTransparency = 1,
		Parent = home,
	})
	local homeStats = {}
	local STAT_DEF = {
		{ key = "walk", label = L("walkSpeed") },
		{ key = "jump", label = L("jumpPower") },
		{ key = "grav", label = L("gravity") },
	}
	for i, def in ipairs(STAT_DEF) do
		local tile = new("Frame", {
			Name = "Stat_" .. def.key,
			Size = UDim2.new(0, 113, 1, 0),
			Position = UDim2.new(0, (i - 1) * 121, 0, 0),
			BackgroundColor3 = C.Card,
			BorderSizePixel = 0,
			Parent = statRow,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = tile })
		new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = tile })
		new("TextLabel", {
			Size = UDim2.new(1, -20, 0, 14),
			Position = UDim2.new(0, 10, 0, 7),
			BackgroundTransparency = 1,
			Text = def.label,
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tile,
		})
		homeStats[def.key] = new("TextLabel", {
			Size = UDim2.new(1, -20, 0, 22),
			Position = UDim2.new(0, 10, 0, 23),
			BackgroundTransparency = 1,
			Text = "--",
			TextSize = 17,
			Font = FONT_M,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tile,
		})
	end

	local function refreshHomeStats()
		local hum = getHumanoid()
		local ws, jp = 16, 50
		if hum then
			local ok1, v1 = pcall(function() return hum.WalkSpeed end)
			if ok1 and type(v1) == "number" then ws = v1 end
			local ok2, v2 = pcall(function() return hum.JumpPower end)
			if ok2 and type(v2) == "number" then jp = v2 end
		end
		local gv = 196.2
		local ok3, v3 = pcall(function() return workspace.Gravity end)
		if ok3 and type(v3) == "number" then gv = v3 end
		if homeStats.walk then homeStats.walk.Text = string.format("%d", math.floor(ws + 0.5)) end
		if homeStats.jump then homeStats.jump.Text = string.format("%d", math.floor(jp + 0.5)) end
		if homeStats.grav then homeStats.grav.Text = string.format("%d", math.floor(gv + 0.5)) end
	end

	-- 飞行状态卡片
	local flyCard = new("TextButton", {
		Name = "FlyCard",
		Size = UDim2.new(1, 0, 0, 62),
		Position = UDim2.new(0, 0, 0, 124),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		Parent = home,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = flyCard })
	local flyCardStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = flyCard })

	local flyDot = new("Frame", {
		Name = "FlyDot",
		Size = UDim2.new(0, 7, 0, 7),
		Position = UDim2.new(0, 16, 0, 18),
		BackgroundColor3 = C.Dim,
		BorderSizePixel = 0,
		Parent = flyCard,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = flyDot })

	new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 18),
		Position = UDim2.new(0, 32, 0, 13),
		BackgroundTransparency = 1,
		Text = L("cardFlyTitle"),
		TextSize = 15,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyCard,
	})
	new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 16),
		Position = UDim2.new(0, 32, 0, 33),
		BackgroundTransparency = 1,
		Text = L("cardFlyDesc"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = flyCard,
	})
	local flyCardState = new("TextLabel", {
		Size = UDim2.new(0, 74, 1, 0),
		Position = UDim2.new(1, -88, 0, 0),
		BackgroundTransparency = 1,
		Text = L("stateOff"),
		TextSize = 12,
		Font = FONT_B,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = flyCard,
	})

	flyCard.MouseEnter:Connect(function()
		tween(flyCard, EASE.soft, { BackgroundColor3 = C.Card2, Position = UDim2.new(0, 0, 0, 122) })
		tween(flyCardStroke, EASE.soft, { Color = C.Accent })
	end)
	flyCard.MouseLeave:Connect(function()
		tween(flyCard, EASE.soft, { BackgroundColor3 = C.Card, Position = UDim2.new(0, 0, 0, 124) })
		tween(flyCardStroke, EASE.soft, { Color = C.Stroke })
	end)
	bindPress(flyCard, C.Accent)
	flyCard.MouseButton1Click:Connect(function() openFlyWindow() end)

	-- 通用设置卡片
	local genCard = new("TextButton", {
		Name = "GeneralCard",
		Size = UDim2.new(1, 0, 0, 62),
		Position = UDim2.new(0, 0, 0, 194),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		Parent = home,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = genCard })
	local genCardStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = genCard })

	new("TextLabel", {
		Size = UDim2.new(1, -60, 0, 18),
		Position = UDim2.new(0, 16, 0, 13),
		BackgroundTransparency = 1,
		Text = L("cardGenTitle"),
		TextSize = 15,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = genCard,
	})
	new("TextLabel", {
		Size = UDim2.new(1, -60, 0, 16),
		Position = UDim2.new(0, 16, 0, 33),
		BackgroundTransparency = 1,
		Text = L("cardGenDesc"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = genCard,
	})
	local genArrow = new("TextLabel", {
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.new(1, -44, 0, 0),
		BackgroundTransparency = 1,
		Text = "→",
		TextSize = 18,
		Font = FONT_B,
		TextColor3 = C.Dim,
		Parent = genCard,
	})

	genCard.MouseEnter:Connect(function()
		tween(genCard, EASE.soft, { BackgroundColor3 = C.Card2, Position = UDim2.new(0, 0, 0, 192) })
		tween(genCardStroke, EASE.soft, { Color = C.Accent })
		tween(genArrow, EASE.soft, { TextColor3 = C.Accent, Position = UDim2.new(1, -38, 0, 0) })
	end)
	genCard.MouseLeave:Connect(function()
		tween(genCard, EASE.soft, { BackgroundColor3 = C.Card, Position = UDim2.new(0, 0, 0, 194) })
		tween(genCardStroke, EASE.soft, { Color = C.Stroke })
		tween(genArrow, EASE.soft, { TextColor3 = C.Dim, Position = UDim2.new(1, -44, 0, 0) })
	end)
	bindPress(genCard, C.Accent)
	genCard.MouseButton1Click:Connect(function() showPage("general") end)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, 268),
		BackgroundTransparency = 1,
		Text = L("homeHint"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Parent = home,
	})

	--========================== 服务器 ==========================
	-- 跟主页一样是个 page（不新开窗口），右边列出可用的服务器脚本
	local serversPage = addPage("servers")
	addNav("servers", L("navServers"), 2)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 2),
		BackgroundTransparency = 1,
		Text = L("srvTitle"),
		TextSize = 17,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = serversPage,
	})
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundTransparency = 1,
		Text = L("srvSub"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = serversPage,
	})

	-- 一张服务器卡：图标 + 名字 + Place ID + 打开
	local srvList = new("Frame", {
		Name = "ServerList",
		Size = UDim2.new(1, 0, 1, -54),
		Position = UDim2.new(0, 0, 0, 54),
		BackgroundTransparency = 1,
		Parent = serversPage,
	})

	local function addServerCard(order, name, placeId, assetKey, gate, openFn)
		local y = (order - 1) * 78
		local card = new("TextButton", {
			Name = "SrvCard_" .. tostring(placeId),
			Size = UDim2.new(1, 0, 0, 70),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundColor3 = C.Card,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			Parent = srvList,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = card })
		local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = card })

		local iconBox = new("Frame", {
			Size = UDim2.new(0, 46, 0, 46),
			Position = UDim2.new(0, 14, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Card2,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = card,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = iconBox })
		local iconAsset = getAsset(assetKey)
		if iconAsset then
			new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = iconAsset,
				ScaleType = Enum.ScaleType.Crop,
				Parent = iconBox,
			})
		end
		new("UIStroke", { Color = C.Stroke2, Thickness = 1, Transparency = 0.5, Parent = iconBox })

		new("TextLabel", {
			Size = UDim2.new(1, -150, 0, 20),
			Position = UDim2.new(0, 74, 0, 14),
			BackgroundTransparency = 1,
			Text = name,
			TextSize = 15,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		new("TextLabel", {
			Size = UDim2.new(1, -150, 0, 16),
			Position = UDim2.new(0, 74, 0, 38),
			BackgroundTransparency = 1,
			Text = "place " .. tostring(placeId),
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local pill = new("Frame", {
			Size = UDim2.new(0, 64, 0, 28),
			Position = UDim2.new(1, -78, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Card2,
			BorderSizePixel = 0,
			Parent = card,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })
		local pillStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = pill })
		local pillText = new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = L("srvOpen"),
			TextSize = 12,
			Font = FONT_B,
			TextColor3 = C.Sub,
			Parent = pill,
		})

		card.MouseEnter:Connect(function()
			tween(card, EASE.soft, { BackgroundColor3 = C.Card2 })
			tween(stroke, EASE.soft, { Color = C.Accent })
			tween(pill, EASE.soft, { BackgroundColor3 = C.Accent })
			tween(pillStroke, EASE.soft, { Color = C.Accent })
			tween(pillText, EASE.soft, { TextColor3 = C.White })
		end)
		card.MouseLeave:Connect(function()
			tween(card, EASE.soft, { BackgroundColor3 = C.Card })
			tween(stroke, EASE.soft, { Color = C.Stroke })
			tween(pill, EASE.soft, { BackgroundColor3 = C.Card2 })
			tween(pillStroke, EASE.soft, { Color = C.Stroke })
			tween(pillText, EASE.soft, { TextColor3 = C.Sub })
		end)
		bindPress(card, C.Accent)
		-- 默认是"必须在同一个 place"；劫案那款游戏跨 place，传自己的判定进来
		local open = openFn or function() openSrvWindow() end
		card.MouseButton1Click:Connect(function()
			-- 不在对应的服务器里就不给用：响一声 + 弹拦截窗
			local okPlace, pid = (gate or inPlace)(placeId)
			if not okPlace then
				playSfx("sfx_deny", CONFIG.SoundDeny)
				showDenyModal(
					L("denyTitle"),
					string.format(L("denyBody"), name),
					string.format(L("denyNow"), tostring(pid or "?")),
					placeId,
					name
				)
				return
			end
			open()
		end)
		return card
	end

	addServerCard(1, L("srvNds"), 189707, "srv_nds")
	addServerCard(2, L("srvHeist"), PD.Place, "srv_heist", pdInGame, function() openPdWindow() end)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 156),
		BackgroundTransparency = 1,
		Text = L("srvMore"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = srvList,
	})

	--========================== 通用设置 ==========================
	local general = addPage("general")
	addNav("general", L("navGeneral"), 3)

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
			Position = UDim2.new(1, -80, 0, y - 1),
			BackgroundTransparency = 1,
			Text = opts.Format(opts.Default),
			TextSize = 14,
			Font = FONT_M,                 -- 等宽：拖动时数字不会左右抖
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

	-- 防挂机：Roblox 20 分钟没操作会踢人。
	-- 标准做法 —— 挂到 Idled 上，用 VirtualUser 假点一下鼠标就把计时器重置了。
	local antiAfkConn = nil
	local setAntiAfk = function(on)
		if antiAfkConn then pcall(function() antiAfkConn:Disconnect() end) antiAfkConn = nil end
		if on then
			local VirtualUser = game:GetService("VirtualUser")
			antiAfkConn = LocalPlayer.Idled:Connect(function()
				if SHUTDOWN then return end
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end)
			end)
			track(antiAfkConn)
		end
		notify(on and L("antiAfkOn") or L("antiAfkOff"), on and C.Green or C.Red)
	end

	local antiAfkRow = new("Frame", {
		Name = "AntiAfkRow",
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		Parent = general,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = antiAfkRow })
	new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = antiAfkRow })

	new("TextLabel", {
		Size = UDim2.new(1, -104, 0, 18),
		Position = UDim2.new(0, 14, 0, 9),
		BackgroundTransparency = 1,
		Text = L("antiAfk"),
		TextSize = 13,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = antiAfkRow,
	})
	new("TextLabel", {
		Size = UDim2.new(1, -104, 0, 14),
		Position = UDim2.new(0, 14, 0, 30),
		BackgroundTransparency = 1,
		Text = L("antiAfkD"),
		TextSize = 10,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = antiAfkRow,
	})

	createSwitch(antiAfkRow, {
		Name = "AntiAfkSwitch",
		Position = UDim2.new(1, -54, 0, 15),
		Default = false,
		OnChange = setAntiAfk,
	})

	local walkDef, jumpDef, gravDef = currentWalk(), currentJump(), currentGravity()

	local setWalk, walkLabel = addSettingRow(110, {
		Label = L("walkSpeed"),
		Min = 8, Max = 500,
		Default = math.clamp(walkDef, 8, 500),
		Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
		OnChange = function(v)
			Settings.WalkSpeed = v
			applySettings()
			refreshHomeStats()
		end,
	})

	local setJump, jumpLabel = addSettingRow(166, {
		Label = L("jumpPower"),
		Min = 0, Max = 500,
		Default = math.clamp(jumpDef, 0, 500),
		Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
		OnChange = function(v)
			Settings.JumpPower = v
			applySettings()
			refreshHomeStats()
		end,
	})

	local setGrav, gravLabel = addSettingRow(222, {
		Label = L("gravity"),
		Min = 0, Max = 500,
		Default = math.clamp(gravDef, 0, 500),
		Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
		OnChange = function(v)
			Settings.Gravity = v
			applySettings()
			refreshHomeStats()
		end,
	})

	new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 280),
		BackgroundColor3 = C.Stroke,
		BorderSizePixel = 0,
		Parent = general,
	})

	local resetBtn, resetLabel = createButton(general, {
		Name = "ResetSettings",
		Size = UDim2.new(0, 96, 0, 30),
		Position = UDim2.new(0, 0, 0, 290),
		Text = L("resetBtn"),
		TextSize = 12,
		Radius = R.ctl,
		OnClick = function()
			setWalk(16)
			setJump(50)
			setGrav(196)
			Settings.WalkSpeed = 16
			Settings.JumpPower = 50
			Settings.Gravity = 196
			applySettings()
			refreshHomeStats()
			notify(L("resetDone"), C.Accent)
		end,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 30),
		Position = UDim2.new(0, 106, 0, 290),
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
	addNav("settings", L("navSettings"), 5)

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
		Size = UDim2.new(1, 0, 0, 56),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		Parent = settingsPage,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = contactCard })
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
		Size = UDim2.new(1, -28, 0, 20),
		Position = UDim2.new(0, 14, 0, 27),
		BackgroundTransparency = 1,
		Text = CONFIG.Contact,
		TextSize = 14,
		Font = FONT_M,
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
		tween(contactCard, EASE.soft, { BackgroundColor3 = C.Card2 })
		tween(contactStroke, EASE.soft, { Color = C.Accent })
	end)
	contactCard.MouseLeave:Connect(function()
		tween(contactCard, EASE.soft, { BackgroundColor3 = C.Card })
		tween(contactStroke, EASE.soft, { Color = C.Stroke })
	end)
	bindPress(contactCard, C.Accent)
	contactCard.MouseButton1Click:Connect(function()
		if copyText(CONFIG.Contact) then
			notify(L("copied"), C.Green)
		else
			dumpClipboardCandidates()
			notify(string.format(L("copyFail"), CONFIG.Contact), C.Red)
		end
	end)

	local function divider(y)
		return new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundColor3 = C.Stroke,
			BorderSizePixel = 0,
			Parent = settingsPage,
		})
	end

	divider(120)

	-- 语言切换：切完重启脚本
	new("TextLabel", {
		Size = UDim2.new(1, -140, 0, 16),
		Position = UDim2.new(0, 0, 0, 134),
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
		Position = UDim2.new(1, -140, 0, 134),
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
			Position = UDim2.new(0, (i - 1) * 158, 0, 158),
			BackgroundColor3 = active and C.Card2 or C.Card,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			Parent = settingsPage,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = btn })
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
			bindHover(btn, { Bg = { C.Card, C.Card2 }, Stroke = stroke, StrokeOn = C.Stroke2 })
		end

		btn.MouseButton1Click:Connect(function()
			if opt.key == LANG then return end
			notify(string.format(L("langSwitched"), opt.name), C.Accent)
			restart(opt.key)
		end)
	end

	divider(214)

	-- 音效开关
	new("TextLabel", {
		Size = UDim2.new(1, -140, 0, 16),
		Position = UDim2.new(0, 0, 0, 228),
		BackgroundTransparency = 1,
		Text = L("sound"),
		TextSize = 12,
		Font = FONT_N,
		TextColor3 = C.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = settingsPage,
	})
	new("TextLabel", {
		Size = UDim2.new(0, 140, 0, 16),
		Position = UDim2.new(1, -140, 0, 228),
		BackgroundTransparency = 1,
		Text = L("soundHint"),
		TextSize = 10,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = settingsPage,
	})
	createSwitch(settingsPage, {
		Name = "SoundSwitch",
		Position = UDim2.new(1, -40, 0, 225),
		Default = CONFIG.Sound,
		OnChange = function(v)
			CONFIG.Sound = v
			if v then playSfx("sfx_notify", CONFIG.SoundNotify) end
		end,
	})

	--========================== 飞行（独立窗口） ==========================
	local flyNavBtn = addNav("fly", L("navFly"), 4, function() openFlyWindow() end)

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
	new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = flyWin })
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
	new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = flyHeader })
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

	-- 飞行中才亮的一条"运行中"细线（真实状态，不是装饰）
	local flyPulse = new("Frame", {
		Name = "FlyPulse",
		Size = UDim2.new(0, 120, 0, 2),
		Position = UDim2.new(0, 14, 0, 41),
		BackgroundColor3 = C.Green,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = flyWin,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = flyPulse })
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = flyPulse,
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
	bindHover(flyMinBtn, {
		Bg = { C.Card, C.Card2 }, Stroke = flyMinStroke, StrokeOn = C.Stroke2,
		Label = flyMinBtn, LabelOn = C.Text,
	})

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
	bindHover(flyCloseBtn, {
		Bg = { C.Card, C.Red }, Stroke = flyCloseStroke, StrokeOn = C.Red,
		Label = flyCloseBtn, LabelOn = C.White,
	})

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
		Position = UDim2.new(1, -100, 0, 57),
		BackgroundTransparency = 1,
		Text = fmtSpeed(CONFIG.FlySpeed),
		TextSize = 14,
		Font = FONT_M,
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

	local function flyDivider(y)
		return new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundColor3 = C.Stroke,
			BorderSizePixel = 0,
			Parent = flyBody,
		})
	end

	flyDivider(112)

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

	flyDivider(166)

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

	flyDivider(220)

	local hints = {
		{ L("hintMobile"), L("hintMobileV") },
		{ L("hintPC"),     L("hintPCV") },
		{ L("hintKey"),    L("hintKeyV") },
	}
	for i, h in ipairs(hints) do
		local y = 232 + (i - 1) * 22
		new("TextLabel", {
			Size = UDim2.new(0, 40, 0, 16),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundTransparency = 1,
			Text = h[1],
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = flyBody,
		})
		new("TextLabel", {
			Size = UDim2.new(1, -46, 0, 16),
			Position = UDim2.new(0, 46, 0, y),
			BackgroundTransparency = 1,
			Text = h[2],
			TextSize = 11,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = flyBody,
		})
	end

	-- 飞行窗口的启动动画（共用 helper）
	local playFlySplash = makeWindowSplash(flyWin, "FlySplash", L("flyTitle"), nil, R.win)

	--========================== 服务器窗口 ==========================
	-- 跟飞行窗口一个套路：独立 Frame、－ 收胶囊、✕ 关掉，打开时播开场动画
	local srvWin = new("Frame", {
		Name = "ServerWindow",
		Size = UDim2.new(0, SRV_W, 0, SRV_H),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		Visible = false,
		Parent = guiMain,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = srvWin })
	new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = srvWin })
	local srvScale = new("UIScale", { Scale = 1, Parent = srvWin })

	local srvHeader = new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, SRV_HEAD_H),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		Parent = srvWin,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = srvHeader })
	new("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		Parent = srvHeader,
	})
	new("Frame", {
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 1, -1),
		BackgroundColor3 = C.Stroke,
		BorderSizePixel = 0,
		Parent = srvHeader,
	})

	local function srvIconAt(parent, px, py, size, radius)
		local box = new("Frame", {
			Size = UDim2.new(0, size, 0, size),
			Position = UDim2.new(0, px, 0.5, py),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Card2,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = parent,
		})
		new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = box })
		local a = getAsset("srv_nds")
		if a then
			new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = a,
				ScaleType = Enum.ScaleType.Crop,
				Parent = box,
			})
		end
		new("UIStroke", { Color = C.Stroke2, Thickness = 1, Transparency = 0.5, Parent = box })
		return box
	end

	srvIconAt(srvHeader, 14, 0, 22, 7)

	new("TextLabel", {
		Size = UDim2.new(0, 200, 1, 0),
		Position = UDim2.new(0, 44, 0, 0),
		BackgroundTransparency = 1,
		Text = L("srvNds"),
		TextSize = 14,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = srvHeader,
	})

	-- 自动获胜开着的时候这里亮一个 RUNNING
	local srvRunTag = new("TextLabel", {
		Name = "RunTag",
		Size = UDim2.new(0, 84, 1, 0),
		Position = UDim2.new(1, -190, 0, 0),
		BackgroundTransparency = 1,
		Text = L("farmRunning"),
		TextSize = 10,
		Font = FONT_M,
		TextColor3 = C.Green,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTransparency = 1,
		Parent = srvHeader,
	})

	local srvMinBtn = new("TextButton", {
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
		Parent = srvHeader,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = srvMinBtn })
	local srvMinStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = srvMinBtn })
	bindHover(srvMinBtn, {
		Bg = { C.Card, C.Card2 }, Stroke = srvMinStroke, StrokeOn = C.Stroke2,
		Label = srvMinBtn, LabelOn = C.Text,
	})

	local srvCloseBtn = new("TextButton", {
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
		Parent = srvHeader,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = srvCloseBtn })
	local srvCloseStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = srvCloseBtn })
	bindHover(srvCloseBtn, {
		Bg = { C.Card, C.Red }, Stroke = srvCloseStroke, StrokeOn = C.Red,
		Label = srvCloseBtn, LabelOn = C.White,
	})

	makeDraggable(srvWin, srvHeader, function() return srvScale.Scale end)

	-- ---------- 主体：左边分区 / 右边内容 ----------
	local srvBody = new("Frame", {
		Size = UDim2.new(1, -20, 1, -SRV_HEAD_H - 12),
		Position = UDim2.new(0, 10, 0, SRV_HEAD_H + 6),
		BackgroundTransparency = 1,
		Parent = srvWin,
	})

	local srvSide = new("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, SRV_SIDE_W, 1, 0),
		BackgroundColor3 = C.Side,
		BorderSizePixel = 0,
		Parent = srvBody,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = srvSide })

	local srvIndicator = new("Frame", {
		Name = "SrvIndicator",
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 0, 0, 15),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = srvSide,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = srvIndicator })

	local srvContent = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -(SRV_SIDE_W + 18), 1, 0),
		Position = UDim2.new(0, SRV_SIDE_W + 14, 0, 0),
		BackgroundTransparency = 1,
		Parent = srvBody,
	})

	local srvPages, srvNav = {}, {}

	local function srvAddPage(key)
		local page = new("Frame", {
			Name = "SrvPage_" .. key,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = srvContent,
		})
		srvPages[key] = page
		return page
	end

	local function srvShow(key)
		for k, page in pairs(srvPages) do
			page.Visible = (k == key)
		end
		for k, item in pairs(srvNav) do
			local active = (k == key)
			tween(item.label, EASE.soft, { TextColor3 = active and C.Text or C.Sub })
			tween(item.btn, EASE.soft, { BackgroundColor3 = active and C.Card or C.Side })
		end
		local item = srvNav[key]
		if item then
			tween(srvIndicator, EASE.pop, { Position = UDim2.new(0, 0, 0, item.y + 5) })
		end
		local target = srvPages[key]
		if target then
			staggerIn(target:GetChildren(), 8, 0.03, 0.3)
		end
	end

	local function srvAddNav(key, text, order)
		local y = 10 + (order - 1) * 32
		local btn = new("TextButton", {
			Name = "Srv_" .. key,
			Size = UDim2.new(1, -16, 0, 28),
			Position = UDim2.new(0, 8, 0, y),
			BackgroundColor3 = C.Side,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = srvSide,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = btn })
		local label = new("TextLabel", {
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.new(0, 16, 0, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextSize = 13,
			Font = FONT_N,
			TextColor3 = C.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})
		btn.MouseButton1Click:Connect(function() srvShow(key) end)
		btn.MouseEnter:Connect(function()
			if not srvPages[key] or not srvPages[key].Visible then
				tween(btn, EASE.soft, { BackgroundColor3 = C.Card })
			end
			tween(label, EASE.soft, { TextColor3 = C.Text })
		end)
		btn.MouseLeave:Connect(function()
			if not srvPages[key] or not srvPages[key].Visible then
				tween(btn, EASE.soft, { BackgroundColor3 = C.Side })
			end
			tween(label, EASE.soft, {
				TextColor3 = (srvPages[key] and srvPages[key].Visible) and C.Text or C.Sub,
			})
		end)
		srvNav[key] = { btn = btn, label = label, y = y }
		return btn
	end

	-- ---------- 页面：传送 ----------
	local tpPage = srvAddPage("tp")
	srvAddNav("tp", L("srvTabTp"), 1)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 2),
		BackgroundTransparency = 1,
		Text = L("tpTitle"),
		TextSize = 16,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tpPage,
	})
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = L("tpSub"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tpPage,
	})

	local tpChoice = "spawn"
	local tpRows = {}

	local function tpSelect(key)
		tpChoice = key
		for k, row in pairs(tpRows) do
			local on = (k == key)
			tween(row.btn, EASE.soft, { BackgroundColor3 = on and C.Card2 or C.Card })
			tween(row.stroke, EASE.soft, {
				Color = on and C.Accent or C.Stroke,
				Thickness = on and 2 or 1,
			})
			tween(row.mark, EASE.soft, {
				BackgroundColor3 = on and C.Accent or C.Card2,
				BackgroundTransparency = on and 0 or 1,
			})
			tween(row.label, EASE.soft, { TextColor3 = on and C.Text or C.Sub })
		end
	end

	local TP_LOCS = {
		{ key = "spawn", name = L("tpLocSpawn"), desc = L("tpLocSpawnD") },
		{ key = "field", name = L("tpLocField"), desc = L("tpLocFieldD") },
	}
	for i, loc in ipairs(TP_LOCS) do
		local y = 54 + (i - 1) * 64
		local btn = new("TextButton", {
			Name = "TpLoc_" .. loc.key,
			Size = UDim2.new(1, 0, 0, 58),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundColor3 = C.Card,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			Parent = tpPage,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = btn })
		local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = btn })

		local mark = new("Frame", {
			Name = "Mark",
			Size = UDim2.new(0, 10, 0, 10),
			Position = UDim2.new(0, 16, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Card2,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = btn,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mark })

		local label = new("TextLabel", {
			Size = UDim2.new(1, -60, 0, 18),
			Position = UDim2.new(0, 38, 0, 12),
			BackgroundTransparency = 1,
			Text = loc.name,
			TextSize = 14,
			Font = FONT_B,
			TextColor3 = C.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})
		new("TextLabel", {
			Size = UDim2.new(1, -60, 0, 16),
			Position = UDim2.new(0, 38, 0, 32),
			BackgroundTransparency = 1,
			Text = loc.desc,
			TextSize = 11,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})

		btn.MouseButton1Click:Connect(function() tpSelect(loc.key) end)
		tpRows[loc.key] = { btn = btn, stroke = stroke, mark = mark, label = label }
	end
	tpSelect("spawn")

	createButton(tpPage, {
		Name = "TpGo",
		Size = UDim2.new(1, 0, 0, 42),
		Position = UDim2.new(0, 0, 0, 190),
		Text = L("tpBtn"),
		TextSize = 15,
		Style = "primary",
		TextColor3 = C.White,
		OnClick = function() SrvTeleportRequest(tpChoice) end,
	})

	-- ---------- 页面：农场 ----------
	local farmPage = srvAddPage("farm")
	srvAddNav("farm", L("srvTabFarm"), 2)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 2),
		BackgroundTransparency = 1,
		Text = L("farmTitle"),
		TextSize = 16,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = farmPage,
	})
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = L("farmSub"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = farmPage,
	})

	local farmCard = new("Frame", {
		Size = UDim2.new(1, 0, 0, 72),
		Position = UDim2.new(0, 0, 0, 54),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		Parent = farmPage,
	})
	new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = farmCard })
	local farmStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = farmCard })

	new("TextLabel", {
		Size = UDim2.new(1, -80, 0, 18),
		Position = UDim2.new(0, 16, 0, 14),
		BackgroundTransparency = 1,
		Text = L("farmAutoWin"),
		TextSize = 14,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = farmCard,
	})
	new("TextLabel", {
		Size = UDim2.new(1, -80, 0, 16),
		Position = UDim2.new(0, 16, 0, 38),
		BackgroundTransparency = 1,
		Text = L("farmAutoWinD"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = farmCard,
	})

	local farmRun = new("TextLabel", {
		Name = "FarmRunTag",
		Size = UDim2.new(0, 70, 0, 16),
		Position = UDim2.new(1, -168, 0.5, -8),
		BackgroundTransparency = 1,
		Text = L("farmRunning"),
		TextSize = 10,
		Font = FONT_M,
		TextColor3 = C.Green,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTransparency = 1,
		Parent = farmCard,
	})

	createSwitch(farmPage, {
		Name = "AutoWin",
		Position = UDim2.new(1, -56, 0, 79),
		Default = false,
		OnChange = function(v) SrvAutoWinRequest(v) end,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 0, 140),
		BackgroundTransparency = 1,
		Text = L("farmHint"),
		TextSize = 11,
		Font = FONT_N,
		TextColor3 = C.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Parent = farmPage,
	})

	srvShow("tp")

	-- 服务器窗口的开场动画（共用 helper）
	local playSrvSplash = makeWindowSplash(srvWin, "ServerSplash", L("srvNds"), "srv_nds", R.win)

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
	local reopenStroke = new("UIStroke", { Color = C.Accent2, Thickness = 1, Parent = reopen })
	local reopenScale = new("UIScale", { Scale = 1, Parent = reopen })
	bindHover(reopen, { Stroke = reopenStroke, StrokeOn = C.Accent, Scale = reopenScale, ScaleOn = 1.08 })

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
	local flyReopenStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = flyReopen })
	local flyReopenScale = new("UIScale", { Scale = 1, Parent = flyReopen })
	bindHover(flyReopen, { Stroke = flyReopenStroke, StrokeOn = C.Stroke2, Scale = flyReopenScale, ScaleOn = 1.06 })

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

	-- 服务器窗口最小化后的悬浮胶囊
	local srvReopen = new("TextButton", {
		Name = "ServerReopen",
		Size = UDim2.new(0, 104, 0, 32),
		Position = UDim2.new(0, 20, 0, 192),
		BackgroundColor3 = C.Window,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = guiMain,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = srvReopen })
	local srvReopenStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = srvReopen })
	local srvReopenScale = new("UIScale", { Scale = 1, Parent = srvReopen })
	bindHover(srvReopen, {
		Stroke = srvReopenStroke, StrokeOn = C.Stroke2,
		Scale = srvReopenScale, ScaleOn = 1.06,
	})

	local srvReopenIcon = new("Frame", {
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 7, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = srvReopen,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = srvReopenIcon })
	do
		local a = getAsset("srv_nds")
		if a then
			new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = a,
				ScaleType = Enum.ScaleType.Crop,
				Parent = srvReopenIcon,
			})
		end
	end
	new("TextLabel", {
		Size = UDim2.new(1, -34, 1, 0),
		Position = UDim2.new(0, 32, 0, 0),
		BackgroundTransparency = 1,
		Text = L("navServers"),
		TextSize = 12,
		Font = FONT_B,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = srvReopen,
	})

	local function updateScale()
		uiScale.Scale = computeScale(WIN_W, WIN_H)
		flyScale.Scale = computeScale(FLY_W, FLY_H)
		srvScale.Scale = computeScale(SRV_W, SRV_H)
		if reopen.Visible then reopenScale.Scale = uiScale.Scale end
		if flyReopen.Visible then flyReopenScale.Scale = flyScale.Scale end
		if srvReopen.Visible then srvReopenScale.Scale = srvScale.Scale end
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

	-- 服务器窗口：同一套语义（－ 收胶囊 / ✕ 关掉）
	local srvReopenDragged = makeDraggable(srvReopen, srvReopen, nil, { threshold = 6, clamp = true })

	local function hideSrv()
		srvWin.Visible = false
		srvReopen.Visible = true
		srvReopenScale.Scale = 0.4
		tween(srvReopenScale, EASE.pop, { Scale = srvScale.Scale })
	end

	local function closeSrvWindow()
		srvWin.Visible = false
		srvReopen.Visible = false
	end

	openSrvWindow = function()
		if srvWin.Visible then return end
		srvReopen.Visible = false
		srvWin.Visible = true
		srvScale.Scale = math.clamp(srvScale.Scale * 0.9, 0.5, 1)
		tween(srvScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = computeScale(SRV_W, SRV_H) })
		playSrvSplash()
	end

	srvMinBtn.MouseButton1Click:Connect(function() hideSrv() end)
	srvCloseBtn.MouseButton1Click:Connect(function() SrvCloseRequest() end)
	srvReopen.MouseButton1Click:Connect(function()
		if srvReopenDragged() then return end
		openSrvWindow()
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
	-- 飞行中顶栏那条细线的呼吸动画：只在开关切换时起停，不重复叠加
	local flyPulseTween = nil

	local function syncFlyUI()
		local on = Fly.Enabled

		flyDot.BackgroundColor3 = on and C.Green or C.Dim
		flyCardState.Text = on and L("stateOn") or L("stateOff")
		flyCardState.TextColor3 = on and C.Green or C.Dim
		tween(flyCardStroke, EASE.soft, { Color = on and C.Green or C.Stroke })

		-- 状态点只在真的在飞的时候才出现
		navItems.fly.dot.BackgroundColor3 = on and C.Green or C.Dim
		navItems.fly.dot.BackgroundTransparency = on and 0 or 1
		flyReopenDot.BackgroundColor3 = on and C.Green or C.Dim
		flyReopenDot.BackgroundTransparency = on and 0 or 0.4

		if on and not flyPulseTween then
			flyPulse.BackgroundTransparency = 0.15
			flyPulseTween = TweenService:Create(flyPulse,
				TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ BackgroundTransparency = 0.78 })
			flyPulseTween:Play()
		elseif not on and flyPulseTween then
			flyPulseTween:Cancel()
			flyPulseTween = nil
			flyPulse.BackgroundTransparency = 1
		end

		flyToggleLabel.Text = on and L("flyOff") or L("flyOn")
		tween(flyToggle, EASE.soft, { BackgroundColor3 = on and C.Green or C.Accent })
		tween(flyToggleStroke, EASE.soft, { Color = on and C.Green or C.Accent })
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

	--========================== 服务器脚本：自然灾害模拟器 ==========================
	-- place 189707。两个坐标是社区脚本里通用的固定点：
	--   出生点   大厅出生点，灾害打不到这里
	--   游戏场地 每局开始所有人被送过去的那个岛
	local NDS = {
		PlaceId = 189707,
		Spawn   = Vector3.new(-270.72131347656, 195.98658752441, 360.30114746094),
		Field   = Vector3.new(-105.42873382568, 48.893535614014, 6.6068959236145),
		Anchor  = 34,      -- 离出生点超过这么多 studs 就当成"被游戏传走了"，拉回来
		AutoWin = false,
		Conn    = nil,
	}

	local function ndsChar()
		local char = LocalPlayer.Character
		if not char then return nil, nil end
		return char, char:FindFirstChild("HumanoidRootPart")
	end

	-- 传送本身不出声，让调用方决定提示什么
	local function ndsMoveTo(pos)
		local char, root = ndsChar()
		if not char then return false end
		if root then
			if pcall(function() root.CFrame = CFrame.new(pos) end) then return true end
		end
		return pcall(function() char:MoveTo(pos) end)
	end

	SrvTeleportRequest = function(which)
		local pos   = (which == "field") and NDS.Field or NDS.Spawn
		local label = (which == "field") and L("tpLocField") or L("tpLocSpawn")
		if ndsMoveTo(pos) then
			notify(string.format(L("tpDone"), label), C.Green)
		else
			notify(L("tpNoChar"), C.Red)
		end
	end

	SrvAutoWinRequest = function(on)
		NDS.AutoWin = on and true or false

		if NDS.Conn then
			pcall(function() NDS.Conn:Disconnect() end)
			NDS.Conn = nil
		end

		farmRun.TextTransparency = NDS.AutoWin and 0 or 1
		srvRunTag.TextTransparency = NDS.AutoWin and 0 or 1
		tween(farmStroke, EASE.soft, { Color = NDS.AutoWin and C.Green or C.Stroke })

		if not NDS.AutoWin then
			notify(L("farmOff"), C.Red)
			return
		end

		ndsMoveTo(NDS.Spawn)

		-- 一直盯着：被游戏传走就立刻拉回出生点，等于免疫游戏内的传送
		NDS.Conn = RunService.Heartbeat:Connect(function()
			if SHUTDOWN or not NDS.AutoWin then return end
			local _, root = ndsChar()
			if not root then return end
			local d = root.Position - NDS.Spawn
			if d.Magnitude > NDS.Anchor then
				pcall(function() root.CFrame = CFrame.new(NDS.Spawn) end)
			end
		end)
		track(NDS.Conn)

		notify(L("farmOn"), C.Green)
	end

	-- 服务器窗口的 ✕：只关窗口，自动获胜继续跑（不然挂机就白挂了）
	SrvCloseRequest = function()
		closeSrvWindow()
	end

	--========================== 服务器脚本：劫案 ==========================
	-- place 21532277 = 主游戏（大厅）：面板只说「正在更新 / 主游戏暂无脚本」。
	-- 进任意劫案地图（同 universe 的其它 place）才解锁 潜入 / 强攻。
	-- ⚠️ 整块放在 pdBuild() 这个函数体里：boot 的 200 个局部变量名额已经很紧，
	-- 独立函数才有自己的额度（改完必须跑 _check + _lint + _run）。
	local function pdBuild()
		local PD_W, PD_H = 520, 480
		local pd = {
			AutoDone = false, AutoAct = false, Tp = true, MoveSpeed = 75,
			ActRange = 15, LootEsp = false, LootRange = 200,
			Aim = false, Fire = false, OnlyEnemy = true, Head = true,
			Walls = false, Esp = false, Priority = "cross",
			Fov = 90, Range = 300, EspRange = 600,          -- ponytail: 透视范围写死 600，页面放不下滑块了
			Items = {}, Esps = {}, Taken = setmetatable({}, { __mode = "k" }),
			prompts = {}, clicks = {}, scanAt = 0, names = {}, run = 0,
		}
		local pdAutoDoneLoop            -- 先声明：潜入页的开关要用它

		-- ---------------- 窗口骨架（跟服务器窗口同款：拖动 / － 胶囊 / ✕ 关窗） ----------------
		local pdWin = new("Frame", {
			Name = "HeistWindow",
			Size = UDim2.new(0, PD_W, 0, PD_H),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			Visible = false,
			Parent = guiMain,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = pdWin })
		new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = pdWin })
		local pdScale = new("UIScale", { Scale = 1, Parent = pdWin })

		local pdHeader = new("Frame", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, SRV_HEAD_H),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			Parent = pdWin,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = pdHeader })
		new("Frame", {
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.new(0, 0, 1, -12),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			Parent = pdHeader,
		})
		new("Frame", {
			Size = UDim2.new(1, -24, 0, 1),
			Position = UDim2.new(0, 12, 1, -1),
			BackgroundColor3 = C.Stroke,
			BorderSizePixel = 0,
			Parent = pdHeader,
		})

		local pdIcon = new("Frame", {
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(0, 14, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Card2,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = pdHeader,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = pdIcon })
		do
			local a = getAsset("srv_heist")
			if a then
				new("ImageLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = a,
					ScaleType = Enum.ScaleType.Crop,
					Parent = pdIcon,
				})
			end
		end
		new("UIStroke", { Color = C.Stroke2, Thickness = 1, Transparency = 0.5, Parent = pdIcon })

		new("TextLabel", {
			Size = UDim2.new(0, 150, 1, 0),
			Position = UDim2.new(0, 44, 0, 0),
			BackgroundTransparency = 1,
			Text = L("srvHeist"),
			TextSize = 14,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = pdHeader,
		})

		-- 右上角：主游戏 / 地图：珠宝店 / 识别地图中...
		local pdTag = new("TextLabel", {
			Name = "HeistTag",
			Size = UDim2.new(0, 170, 1, 0),
			Position = UDim2.new(1, -256, 0, 0),
			BackgroundTransparency = 1,
			Text = L("pdDetecting"),
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = pdHeader,
		})

		local pdMinBtn = new("TextButton", {
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
			Parent = pdHeader,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = pdMinBtn })
		local pdMinStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = pdMinBtn })
		bindHover(pdMinBtn, {
			Bg = { C.Card, C.Card2 }, Stroke = pdMinStroke, StrokeOn = C.Stroke2,
			Label = pdMinBtn, LabelOn = C.Text,
		})

		local pdCloseBtn = new("TextButton", {
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
			Parent = pdHeader,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = pdCloseBtn })
		local pdCloseStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = pdCloseBtn })
		bindHover(pdCloseBtn, {
			Bg = { C.Card, C.Red }, Stroke = pdCloseStroke, StrokeOn = C.Red,
			Label = pdCloseBtn, LabelOn = C.White,
		})

		makeDraggable(pdWin, pdHeader, function() return pdScale.Scale end)

		-- ---------- 主体：左边分区 / 右边内容 ----------
		local pdBody = new("Frame", {
			Size = UDim2.new(1, -20, 1, -SRV_HEAD_H - 12),
			Position = UDim2.new(0, 10, 0, SRV_HEAD_H + 6),
			BackgroundTransparency = 1,
			Parent = pdWin,
		})

		local pdSide = new("Frame", {
			Name = "Sidebar",
			Size = UDim2.new(0, SRV_SIDE_W, 1, 0),
			BackgroundColor3 = C.Side,
			BorderSizePixel = 0,
			Parent = pdBody,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = pdSide })

		local pdIndicator = new("Frame", {
			Name = "HeistIndicator",
			Size = UDim2.new(0, 3, 0, 18),
			Position = UDim2.new(0, 0, 0, 15),
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = pdSide,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pdIndicator })

		local pdContent = new("Frame", {
			Name = "Content",
			Size = UDim2.new(1, -(SRV_SIDE_W + 18), 1, 0),
			Position = UDim2.new(0, SRV_SIDE_W + 14, 0, 0),
			BackgroundTransparency = 1,
			Parent = pdBody,
		})

		local pdPages, pdNav = {}, {}

		local function pdAddPage(key)
			local page = new("Frame", {
				Name = "HeistPage_" .. key,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = false,
				Parent = pdContent,
			})
			pdPages[key] = page
			return page
		end

		local function pdShow(key)
			for k, page in pairs(pdPages) do
				page.Visible = (k == key)
			end
			for k, item in pairs(pdNav) do
				local active = (k == key)
				tween(item.label, EASE.soft, { TextColor3 = active and C.Text or C.Sub })
				tween(item.btn, EASE.soft, { BackgroundColor3 = active and C.Card or C.Side })
			end
			local item = pdNav[key]
			if item then
				tween(pdIndicator, EASE.pop, { Position = UDim2.new(0, 0, 0, item.y + 5) })
			end
			local target = pdPages[key]
			if target then
				staggerIn(target:GetChildren(), 8, 0.03, 0.3)
			end
		end

		local function pdAddNav(key, text, order)
			local y = 10 + (order - 1) * 32
			local btn = new("TextButton", {
				Name = "Heist_" .. key,
				Size = UDim2.new(1, -16, 0, 28),
				Position = UDim2.new(0, 8, 0, y),
				BackgroundColor3 = C.Side,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = pdSide,
			})
			new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = btn })
			local label = new("TextLabel", {
				Size = UDim2.new(1, -24, 1, 0),
				Position = UDim2.new(0, 16, 0, 0),
				BackgroundTransparency = 1,
				Text = text,
				TextSize = 13,
				Font = FONT_N,
				TextColor3 = C.Sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = btn,
			})
			btn.MouseButton1Click:Connect(function() pdShow(key) end)
			btn.MouseEnter:Connect(function()
				if not pdPages[key] or not pdPages[key].Visible then
					tween(btn, EASE.soft, { BackgroundColor3 = C.Card })
				end
				tween(label, EASE.soft, { TextColor3 = C.Text })
			end)
			btn.MouseLeave:Connect(function()
				if not pdPages[key] or not pdPages[key].Visible then
					tween(btn, EASE.soft, { BackgroundColor3 = C.Side })
				end
				tween(label, EASE.soft, {
					TextColor3 = (pdPages[key] and pdPages[key].Visible) and C.Text or C.Sub,
				})
			end)
			pdNav[key] = { btn = btn, label = label, y = y }
			return btn
		end

		-- 一行开关：名字 + 说明 + 开关；key 只用来命名，方便测试和排查
		local function pdRow(page, y, key, name, hint, def, onChange)
			local card = new("Frame", {
				Size = UDim2.new(1, 0, 0, 36),
				Position = UDim2.new(0, 0, 0, y),
				BackgroundColor3 = C.Card,
				BorderSizePixel = 0,
				Parent = page,
			})
			new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = card })
			new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = card })
			new("TextLabel", {
				Size = UDim2.new(1, -70, 0, 15),
				Position = UDim2.new(0, 13, 0, 3),
				BackgroundTransparency = 1,
				Text = name,
				TextSize = 13,
				Font = FONT_B,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			new("TextLabel", {
				Size = UDim2.new(1, -70, 0, 13),
				Position = UDim2.new(0, 13, 0, 19),
				BackgroundTransparency = 1,
				Text = hint,
				TextSize = 10,
				Font = FONT_N,
				TextColor3 = C.Dim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			createSwitch(page, {
				Name = "HeistSw_" .. key,
				Position = UDim2.new(1, -54, 0, y + 7),
				Default = def and true or false,
				OnChange = onChange,
			})
			return card
		end

		-- 一行滑块：名字 + 数值 + 滑轨
		local function pdSlider(page, y, name, min, max, def, onChange)
			local val = new("TextLabel", {
				Size = UDim2.new(0, 80, 0, 14),
				Position = UDim2.new(1, -80, 0, y),
				BackgroundTransparency = 1,
				Text = tostring(def),
				TextSize = 11,
				Font = FONT_M,
				TextColor3 = C.Sub,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = page,
			})
			new("TextLabel", {
				Size = UDim2.new(1, -90, 0, 14),
				Position = UDim2.new(0, 0, 0, y),
				BackgroundTransparency = 1,
				Text = name,
				TextSize = 12,
				Font = FONT_N,
				TextColor3 = C.Sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			createSlider(page, {
				Position = UDim2.new(0, 0, 0, y + 16),
				Min = min, Max = max, Default = def,
				OnChange = function(v)
					local n = math.floor(v + 0.5)
					val.Text = tostring(n)
					if onChange then onChange(n) end
				end,
			})
		end

		-- 标题 / 说明两行
		local function pdHead(page, title, sub)
			new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0, 0, 0, 2),
				BackgroundTransparency = 1,
				Text = title,
				TextSize = 16,
				Font = FONT_B,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
			new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 14),
				Position = UDim2.new(0, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = sub,
				TextSize = 11,
				Font = FONT_N,
				TextColor3 = C.Dim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = page,
			})
		end

		-- ---------- 页：主游戏（没脚本） ----------
		local pdUpdatePage = pdAddPage("update")
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 26),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -44),
			BackgroundTransparency = 1,
			Text = L("pdUpdate"),
			TextSize = 20,
			Font = FONT_B,
			TextColor3 = C.Text,
			Parent = pdUpdatePage,
		})
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -12),
			BackgroundTransparency = 1,
			Text = L("pdNoScript"),
			TextSize = 14,
			Font = FONT_N,
			TextColor3 = C.Sub,
			Parent = pdUpdatePage,
		})
		new("TextLabel", {
			Size = UDim2.new(1, -70, 0, 44),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 26),
			BackgroundTransparency = 1,
			Text = L("pdUpdateHint"),
			TextSize = 11,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextWrapped = true,
			Parent = pdUpdatePage,
		})

		-- ---------- 页：潜入 ----------
		local pdStealth = pdAddPage("stealth")
		pdAddNav("stealth", L("pdTabStealth"), 1)
		pdHead(pdStealth, L("pdStealthTitle"), L("pdStealthSub"))

		-- 自动完成跑到哪一步了（这个是"点了有反应"的关键反馈）
		local pdStatus = new("TextLabel", {
			Name = "HeistStatus",
			Size = UDim2.new(0, 190, 0, 14),
			Position = UDim2.new(1, -190, 0, 4),
			BackgroundTransparency = 1,
			Text = "",
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Green,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = pdStealth,
		})

		pdRow(pdStealth, 44, "AutoDone", L("pdAutoDone"), L("pdAutoDoneD"), false, function(v)
			pd.AutoDone = v
			if v then
				notify(L("pdDoneOn"), C.Green)
				task.spawn(pdAutoDoneLoop)
			else
				pd.run = pd.run + 1
				pdStatus.Text = ""
				notify(L("pdDoneOff"), C.Red)
			end
		end)
		pdRow(pdStealth, 84, "AutoAct", L("pdAutoAct"), L("pdAutoActD"), false, function(v)
			pd.AutoAct = v
			notify(v and string.format(L("pdActOn"), tostring(pd.ActRange)) or L("pdActOff"),
				v and C.Green or C.Red)
		end)
		pdRow(pdStealth, 124, "Tp", L("pdTp"), L("pdTpD"), true, function(v) pd.Tp = v end)
		pdRow(pdStealth, 164, "LootEsp", L("pdLootEsp"), L("pdLootEspD"), false, function(v)
			pd.LootEsp = v
			notify(v and L("pdLootOn") or L("pdLootOff"), v and C.Green or C.Red)
		end)

		pdSlider(pdStealth, 212, L("pdActRange"), 5, 80, pd.ActRange, function(v) pd.ActRange = v end)
		pdSlider(pdStealth, 258, L("pdLootRange"), 20, 600, pd.LootRange, function(v) pd.LootRange = v end)
		pdSlider(pdStealth, 304, L("pdMoveSpeed"), 20, 300, pd.MoveSpeed, function(v) pd.MoveSpeed = v end)

		-- ---------- 页：强攻 ----------
		local pdAssault = pdAddPage("assault")
		pdAddNav("assault", L("pdTabAssault"), 2)
		pdHead(pdAssault, L("pdAssaultTitle"), L("pdAssaultSub"))

		local PRI_KEY = { cross = "pdPriCross", near = "pdPriNear", low = "pdPriLow" }

		pdRow(pdAssault, 44, "Aim", L("pdAim"), L("pdAimD"), false, function(v)
			pd.Aim = v
			notify(v and string.format(L("pdAimOn"), L(PRI_KEY[pd.Priority])) or L("pdAimOff"),
				v and C.Green or C.Red)
			if v and #pd.Items == 0 then notify(L("pdNoNpc"), C.Amber) end
		end)
		pdRow(pdAssault, 84, "Fire", L("pdFire"), L("pdFireD"), false, function(v) pd.Fire = v end)
		pdRow(pdAssault, 124, "OnlyEnemy", L("pdOnlyEnemy"), L("pdOnlyEnemyD"), true,
			function(v) pd.OnlyEnemy = v end)
		pdRow(pdAssault, 164, "Head", L("pdHead"), L("pdHeadD"), true, function(v) pd.Head = v end)
		pdRow(pdAssault, 204, "Walls", L("pdWalls"), L("pdWallsD"), false, function(v) pd.Walls = v end)
		pdRow(pdAssault, 244, "Esp", L("pdEsp"), L("pdEspD"), false, function(v)
			pd.Esp = v
			notify(v and L("pdEspOn") or L("pdEspOff"), v and C.Green or C.Red)
		end)

		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 286),
			BackgroundTransparency = 1,
			Text = L("pdPriority"),
			TextSize = 12,
			Font = FONT_N,
			TextColor3 = C.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = pdAssault,
		})

		local priRows = {}
		local function pdPriApply(key)
			pd.Priority = key
			for k, row in pairs(priRows) do
				local on = (k == key)
				tween(row.btn, EASE.soft, { BackgroundColor3 = on and C.Card2 or C.Card })
				tween(row.stroke, EASE.soft, {
					Color = on and C.Accent or C.Stroke,
					Thickness = on and 2 or 1,
				})
				tween(row.label, EASE.soft, { TextColor3 = on and C.Text or C.Sub })
			end
		end

		for i, key in ipairs({ "cross", "near", "low" }) do
			local btn = new("TextButton", {
				Name = "HeistPri_" .. key,
				Size = UDim2.new(0, 108, 0, 26),
				Position = UDim2.new(0, (i - 1) * 116, 0, 302),
				BackgroundColor3 = C.Card,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = pdAssault,
			})
			new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = btn })
			local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = btn })
			local label = new("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = L(PRI_KEY[key]),
				TextSize = 12,
				Font = FONT_B,
				TextColor3 = C.Sub,
				Parent = btn,
			})
			btn.MouseButton1Click:Connect(function() pdPriApply(key) end)
			priRows[key] = { btn = btn, stroke = stroke, label = label }
		end
		pdPriApply("cross")

		pdSlider(pdAssault, 332, L("pdFov"), 10, 360, pd.Fov, function(v) pd.Fov = v end)
		pdSlider(pdAssault, 378, L("pdAimRange"), 20, 1000, pd.Range, function(v) pd.Range = v end)

		pdShow("stealth")

		-- ---------------- 主游戏 / 地图 两种形态 ----------------
		local function pdMode(main)
			pdSide.Visible = not main
			if main then
				pdContent.Size = UDim2.new(1, 0, 1, 0)
				pdContent.Position = UDim2.new(0, 0, 0, 0)
			else
				pdContent.Size = UDim2.new(1, -(SRV_SIDE_W + 18), 1, 0)
				pdContent.Position = UDim2.new(0, SRV_SIDE_W + 14, 0, 0)
			end
			for _, key in ipairs({ "stealth", "assault" }) do
				local item = pdNav[key]
				if item then item.btn.Visible = not main end
			end
			pdIndicator.Visible = not main
			pdShow(main and "update" or "stealth")
		end

		-- 地图名：先问 Roblox 要这个 place 的名字，拿不到再查手动表，最后退成 #id
		local function pdMapName(pid)
			if pd.names[pid] then return pd.names[pid] end
			local name
			local ok, info = pcall(function()
				return game:GetService("MarketplaceService"):GetProductInfo(pid)
			end)
			if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
				name = info.Name
			end
			name = name or PD.Maps[pid] or ("#" .. tostring(pid))
			pd.names[pid] = name
			return name
		end

		local function pdDetect()
			if pdIsMain() then
				pdTag.Text = L("pdMainTag")
				pdMode(true)
				return
			end
			pdTag.Text = L("pdDetecting")
			pdMode(false)
			local ok, pid = pdInGame()
			pid = pid or (pcall(function() return game.PlaceId end) and game.PlaceId) or 0
			task.spawn(function()
				local name = pdMapName(pid)
				if SHUTDOWN then return end
				pdTag.Text = string.format(L("pdMapTag"), name)
			end)
		end

		-- ---------------- Notoriety 里的位置 ----------------
		-- 结构：Workspace.Police（敌人）/ Citizens（平民）/ BigLoot·Lootables（战利品）/
		-- BagSecuredArea（撤离点）/ Cameras。名字随版本可能变，所以全部 FindFirstChild + 兜底。
		local CIV_FOLDERS  = { "Citizens", "Civilians", "Hostages" }
		local ALLY_FOLDERS = { "Crew", "Crewmates", "Teammates", "Allies" }

		local function pdChild(parent, ...)
			if not parent then return nil end
			for _, n in ipairs({ ... }) do
				local c = parent:FindFirstChild(n)
				if c then return c end
			end
			return nil
		end

		local function pdLoot()
			return pdChild(workspace, "BigLoot", "Lootables", "Loot", "Lootable")
		end

		local function pdPack()
			local ok, rs = pcall(function() return game:GetService("ReplicatedStorage") end)
			if not ok or not rs then return nil end
			return rs:FindFirstChild("RS_Package")
		end

		-- 远程名就那几个，递归找最省事（RS_Package 的层级改过几次）
		local function pdRemote(name)
			local pack = pdPack()
			if not pack then return nil end
			local ok, r = pcall(function() return pack:FindFirstChild(name, true) end)
			if ok then return r end
			return nil
		end

		local function pdPos(inst)
			for _ = 1, 3 do
				if not inst then return nil end
				if inst:IsA("BasePart") then return inst.Position end
				if inst:IsA("Attachment") then return inst.WorldPosition end
				if inst:IsA("Model") then
					local p = inst.PrimaryPart or inst:FindFirstChildOfClass("Part")
					return p and p.Position or nil
				end
				inst = inst.Parent
			end
			return nil
		end

		local function pdDist(inst)
			local pos = pdPos(inst)
			local root = getRoot()
			if not pos or not root then return nil end
			return (pos - root.Position).Magnitude
		end

		-- 敌我识别：按文件夹认最稳（Police = 敌人，Citizens = 平民）
		-- ponytail: 玩家一律当队友（Notoriety 是合作劫案，没有敌对玩家）；真有 PvP 再按 Team 判。
		local function pdKind(model)
			local node, depth = model, 0
			while node and node ~= workspace and depth < 8 do
				local n = node.Name
				if n == "Police" or n == "Enemies" or n == "Security" then return "enemy" end
				for _, f in ipairs(CIV_FOLDERS) do
					if n == f then return "civ" end
				end
				for _, f in ipairs(ALLY_FOLDERS) do
					if n == f then return "ally" end
				end
				node, depth = node.Parent, depth + 1
			end
			local plr = Players:GetPlayerFromCharacter(model)
			if plr then
				return (plr == LocalPlayer) and "me" or "ally"
			end
			local nm = string.lower(tostring(model.Name))
			for _, kw in ipairs(PD.AllyKw) do
				if string.find(nm, kw, 1, true) then return "ally" end
			end
			return "other"
		end

		-- ---------------- 扫描：交互点 / 人物 ----------------
		-- ponytail: 每 0.4 秒全树扫一次；地图大到卡帧就把间隔拉长或改 CollectionService 标签
		local function pdScan()
			local ps, cs, list = {}, {}, {}
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("ProximityPrompt") then
					if d.Enabled then ps[#ps + 1] = d end
				elseif d:IsA("ClickDetector") then
					cs[#cs + 1] = d
				elseif d:IsA("Humanoid") then
					local model = d.Parent
					if model and d.Health > 0 then
						list[#list + 1] = { model = model, hum = d, kind = pdKind(model) }
					end
				end
			end
			pd.prompts, pd.clicks, pd.Items = ps, cs, list
		end

		-- ---------------- 透视：所有人 + 战利品，按类型分色 ----------------
		local ESP_COLOR = { enemy = C.Red, civ = C.Amber, ally = C.Green,
			other = C.Sub, loot = C.White, me = C.White }
		local ESP_KEY = { enemy = "pdTEnemy", civ = "pdTCiv", ally = "pdTAlly",
			other = "pdTOther", loot = "pdTLoot" }

		local function pdEspPart(inst)
			if inst:IsA("BasePart") then return inst end
			return inst:FindFirstChild("Head") or inst:FindFirstChild("HumanoidRootPart")
				or inst.PrimaryPart or inst:FindFirstChildOfClass("Part")
		end

		local function pdEspOff(inst)
			local e = pd.Esps[inst]
			if e then
				pd.Esps[inst] = nil
				pcall(function() e.gui:Destroy() end)
			end
		end

		local function pdEspSet(part, kind, text)
			local e = pd.Esps[part]
			if not e then
				local gui = new("BillboardGui", {          -- BillboardGui 没有 Highlight 那种数量上限
					Name = "O_X_ESP",
					Size = UDim2.new(0, 150, 0, 16),
					StudsOffset = Vector3.new(0, 2.2, 0),
					AlwaysOnTop = true,
					Adornee = part,
					Parent = part,
				})
				local label = new("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = text,
					TextSize = 12,
					Font = FONT_B,
					TextColor3 = ESP_COLOR[kind] or C.White,
					TextStrokeTransparency = 0.3,
					Parent = gui,
				})
				pd.Esps[part] = { gui = gui, label = label, kind = kind }
				return
			end
			if e.kind ~= kind then
				e.kind = kind
				e.label.TextColor3 = ESP_COLOR[kind] or C.White
			end
			if e.label.Text ~= text then e.label.Text = text end
		end

		local function pdRank(kind)
			if kind == "enemy" then return 1 end
			if kind == "civ" then return 2 end
			if kind == "ally" then return 3 end
			if kind == "loot" then return 4 end
			return 5
		end

		local function pdRefreshEsp()
			local seen, list = {}, {}
			if pd.Esp then
				for _, t in ipairs(pd.Items) do
					if t.kind ~= "me" then
						local part = pdEspPart(t.model)
						if part then list[#list + 1] = { part = part, kind = t.kind, name = t.model.Name } end
					end
				end
			end
			if pd.LootEsp then
				local folder = pdLoot()
				if folder then
					for _, d in ipairs(folder:GetDescendants()) do
						local p = d:IsA("ProximityPrompt") and d or d:FindFirstChildOfClass("ProximityPrompt")
						if p and p.Parent then
							local part = pdEspPart(p.Parent)
							if part then
								list[#list + 1] = { part = part, kind = "loot", name = p.Parent.Name }
							end
						end
					end
				end
			end
			table.sort(list, function(a, b) return pdRank(a.kind) < pdRank(b.kind) end)
			local n = 0
			for _, it in ipairs(list) do
				local rng = (it.kind == "loot") and pd.LootRange or pd.EspRange
				local dist = pdDist(it.part)
				if dist and dist <= rng then
					n = n + 1
					if n <= 60 then       -- ponytail: 一屏最多挂 60 个名字，再多没意义还掉帧
						seen[it.part] = true
						pdEspSet(it.part, it.kind,
							string.format("%s  %s  %sm", tostring(it.name), L(ESP_KEY[it.kind]),
								tostring(math.floor(dist))))
					end
				end
			end
			for part in pairs(pd.Esps) do
				if not seen[part] then pdEspOff(part) end
			end
		end

		-- ---------------- 潜入：交互 + 自动完成 ----------------
		local function pdMoveTo(pos)
			local root = getRoot()
			if not root or not pos then return false end
			if pd.Tp then
				return pcall(function() root.CFrame = CFrame.new(pos) end)
			end
			local dist = (pos - root.Position).Magnitude
			local tw = TweenService:Create(root,
				TweenInfo.new(math.max(dist / pd.MoveSpeed, 0.05), Enum.EasingStyle.Linear),
				{ CFrame = CFrame.new(pos) })
			tw:Play()
			pcall(function() tw.Completed:Wait() end)
			return true
		end

		local function pdInteract(p)
			if not p or not p.Parent then return end
			pcall(function() p.RequiresLineOfSight = false end)
			local hold = 0
			pcall(function() hold = tonumber(p.HoldDuration) or 0 end)
			if hold > 5 then hold = 1 end            -- 有些锁是 20 秒的假 HoldDuration，别卡死
			local fire = execFn("fireproximityprompt")
			local start, finish = pdRemote("StartInteraction"), pdRemote("CompleteInteraction")
			-- 最多试 3 次：交互成功的话 prompt 会被销毁 / 关掉，那就提前结束
			for _ = 1, 3 do
				if not p.Parent or p.Enabled == false then break end
				if fire then pcall(fire, p) end
				if hold > 0.05 then
					if start and finish then
						pcall(function() start:FireServer(p) end)
						task.wait(hold)
						pcall(function() finish:FireServer(p) end)
					else
						pcall(function()
							p:InputHoldBegin()
							task.wait(hold)
							p:InputHoldEnd()
						end)
					end
				end
				task.wait(0.15)
			end
		end

		-- 自动完成：找战利品 -> 过去 -> 交互 -> 送到撤离点 -> 循环
		pdAutoDoneLoop = function()
			if SHUTDOWN or not pd.AutoDone then return end
			pd.run = pd.run + 1
			local me = pd.run
			local throwBag = pdRemote("ThrowBag")
			local van = pdChild(workspace, "BagSecuredArea", "SecuredArea", "EscapeVan")
			local done, warned = 0, false
			while pd.AutoDone and not SHUTDOWN and pd.run == me do
				local target, tpos
				local folder = pdLoot()
				if folder then
					for _, d in ipairs(folder:GetDescendants()) do
						local p = d:IsA("ProximityPrompt") and d or d:FindFirstChildOfClass("ProximityPrompt")
						if p and p.Enabled and not pd.Taken[p] then
							local pos = pdPos(p)
							if pos then target, tpos = p, pos break end
						end
					end
				end
				if not target then
					if not warned then
						warned = true
						notify(L("pdNoLoot"), C.Amber)
					end
					task.wait(2)
				else
					pd.Taken[target] = true
					done = done + 1
					local msg = string.format(L("pdGrab"), tostring(done))
					pdStatus.Text = msg
					notify(msg, C.Accent)
					pdMoveTo(tpos)
					task.wait(0.2)
					pdInteract(target)
					if van and throwBag then
						local vpos = pdPos(van)
						if vpos then
							pdMoveTo(vpos + Vector3.new(0, 3, 0))
							task.wait(0.25)
							local root = getRoot()
							local dir = Vector3.new(0, 0, -1)
							if root then
								local d = vpos - root.Position
								if d.Magnitude > 0.1 then dir = d.Unit end
							end
							pcall(function() throwBag:FireServer(dir) end)
							task.wait(1.2)
						end
					end
					task.wait(0.15)
				end
			end
			pd.AutoDone = false
			pdStatus.Text = ""
		end

		local promptAt = setmetatable({}, { __mode = "k" })

		local function pdAutoAct()
			local now = os.clock()
			local fire = execFn("fireproximityprompt")
			local n = 0
			for _, p in ipairs(pd.prompts) do
				local d = pdDist(p)
				if d and d <= pd.ActRange and (promptAt[p] or -1) + 0.8 <= now then
					promptAt[p] = now
					pcall(function() p.RequiresLineOfSight = false end)
					if fire then pcall(fire, p) end
					pcall(function()
						p:InputHoldBegin()
						p:InputHoldEnd()
					end)
					n = n + 1
					if n >= 6 then break end     -- 一帧最多碰 6 个，别把远程调用打爆
				end
			end
			local click = execFn("fireclickdetector")
			if click then
				for _, c in ipairs(pd.clicks) do
					local d = pdDist(c)
					if d and d <= pd.ActRange and (promptAt[c] or -1) + 0.8 <= now then
						promptAt[c] = now
						pcall(click, c)
					end
				end
			end
		end

		-- ---------------- 强攻：准星锁头 + 自动开火 ----------------
		local function pdAimPos(model)
			local head = model:FindFirstChild("Head")
			if pd.Head and head and head.Position then return head.Position end
			local root = model:FindFirstChild("HumanoidRootPart")
			if root and root.Position then return root.Position end
			if head and head.Position then return head.Position end
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum and hum.RootPart then return hum.RootPart.Position end
			return nil
		end

		local function pdVisible(origin, pos, model)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { LocalPlayer.Character, model }
			return workspace:Raycast(origin, pos - origin, params) == nil
		end

		-- 把自己人的种类全排掉：只瞄敌人（OnlyEnemy 关掉后才放开平民 / 其他 NPC）
		local function pdTargetable(kind)
			if kind == "enemy" then return true end
			if pd.OnlyEnemy then return false end
			return kind == "civ" or kind == "other"
		end

		local function pdPick(cam)
			local origin = cam.CFrame.Position
			local look = cam.CFrame.LookVector
			local half = math.rad(pd.Fov) * 0.5
			local best, bestScore
			for _, t in ipairs(pd.Items) do
				if pdTargetable(t.kind) then
					local pos = pdAimPos(t.model)
					if pos then
						local delta = pos - origin
						local dist = delta.Magnitude
						if dist > 0.5 and dist <= pd.Range then
							local ang = math.acos(math.clamp(delta.Unit:Dot(look), -1, 1))
							if ang <= half and (pd.Walls or pdVisible(origin, pos, t.model)) then
								local score
								if pd.Priority == "near" then
									score = dist
								elseif pd.Priority == "low" then
									score = t.hum.Health
								else
									score = ang
								end
								if not bestScore or score < bestScore then
									best, bestScore = t, score
								end
							end
						end
					end
				end
			end
			return best, origin
		end

		-- 视角转到目标 + 用执行器的鼠标函数把光标压到目标身上。
		-- 两个都做：锁鼠标的（准星在屏幕中心）和自由光标的（准星跟鼠标）都覆盖到。
		local function pdApplyAim(cam, pos)
			local origin = cam.CFrame.Position
			pcall(function() cam.CFrame = CFrame.new(origin, pos) end)
			-- 鼠标被锁在屏幕中心的那种游戏，准星本来就跟着视角走，再动鼠标只会每帧抖一下
			local locked = false
			pcall(function() locked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter end)
			if locked then return end
			local abs, rel = execFn("mousemoveabs"), execFn("mousemoverel")
			if not (abs or rel) then return end
			local ok, sp = pcall(function() return cam:WorldToScreenPoint(pos) end)
			if not ok or not sp then return end
			if abs then
				pcall(abs, sp.X, sp.Y)
			elseif rel then
				local loc = UserInputService:GetMouseLocation()
				pcall(rel, sp.X - loc.X, sp.Y - loc.Y)
			end
		end

		local function pdFire()
			local char = LocalPlayer.Character
			local tool = char and char:FindFirstChildOfClass("Tool")
			if tool and pcall(function() tool:Activate() end) then return end
			local m1 = execFn("mouse1click")
			if m1 and pcall(m1) then return end
			local ok, vu = pcall(function() return game:GetService("VirtualUser") end)
			if ok and vu then
				pcall(function() vu:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) end)
				pcall(function() vu:ClickButton1(Vector2.new(0, 0)) end)
			end
		end

		track(RunService.Heartbeat:Connect(function()
			if SHUTDOWN then return end
			if not (pd.AutoAct or pd.Esp or pd.LootEsp or pd.Aim or pd.Fire) then return end
			local now = os.clock()
			if now - pd.scanAt < 0.4 then return end
			pd.scanAt = now
			pdScan()
			pdRefreshEsp()
			if pd.AutoAct then pdAutoAct() end
		end))

		track(RunService.RenderStepped:Connect(function()
			if SHUTDOWN or not (pd.Aim or pd.Fire) then return end
			local cam = workspace.CurrentCamera
			if not cam then return end
			local target, origin = pdPick(cam)
			if not target then return end
			local pos = pdAimPos(target.model)
			if not pos then return end
			pdApplyAim(cam, pos)
			if pd.Fire then pdFire() end
		end))

		-- ---------------- 打开 / 收起 / 关闭 ----------------
		local pdPlaySplash = makeWindowSplash(pdWin, "HeistSplash", L("srvHeist"), "srv_heist", R.win)

		local pdReopen = new("TextButton", {
			Name = "HeistReopen",
			Size = UDim2.new(0, 116, 0, 32),
			Position = UDim2.new(0, 20, 0, 232),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Visible = false,
			Parent = guiMain,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pdReopen })
		local pdReopenStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = pdReopen })
		local pdReopenScale = new("UIScale", { Scale = 1, Parent = pdReopen })
		bindHover(pdReopen, {
			Stroke = pdReopenStroke, StrokeOn = C.Stroke2,
			Scale = pdReopenScale, ScaleOn = 1.06,
		})

		local pdReopenIcon = new("Frame", {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 7, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Card2,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = pdReopen,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = pdReopenIcon })
		do
			local a = getAsset("srv_heist")
			if a then
				new("ImageLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = a,
					ScaleType = Enum.ScaleType.Crop,
					Parent = pdReopenIcon,
				})
			end
		end
		new("TextLabel", {
			Size = UDim2.new(1, -34, 1, 0),
			Position = UDim2.new(0, 32, 0, 0),
			BackgroundTransparency = 1,
			Text = L("srvHeist"),
			TextSize = 12,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = pdReopen,
		})

		local pdReopenDragged = makeDraggable(pdReopen, pdReopen, nil, { threshold = 6, clamp = true })

		local function pdHide()
			pdWin.Visible = false
			pdReopen.Visible = true
			pdReopenScale.Scale = 0.4
			tween(pdReopenScale, EASE.pop, { Scale = computeScale(PD_W, PD_H) })
		end

		openPdWindow = function()
			if pdWin.Visible then return end
			pdReopen.Visible = false
			pdWin.Visible = true
			pdScale.Scale = math.clamp(computeScale(PD_W, PD_H) * 0.9, 0.5, 1)
			tween(pdScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = computeScale(PD_W, PD_H) })
			pdDetect()
			pdPlaySplash()
			if pdIsMain() then notify(L("pdUpdateOn"), C.Amber) end
		end

		-- ✕ 只关窗口：潜入 / 强攻的状态留着（跟农场一个道理，关了面板照样在跑）
		PdCloseRequest = function()
			pdWin.Visible = false
			pdReopen.Visible = false
		end

		-- 结束整个脚本时：停掉所有开关，把挂在场景里的透视收干净
		pdCleanup = function()
			pd.AutoDone, pd.AutoAct, pd.LootEsp, pd.Esp = false, false, false, false
			pd.Aim, pd.Fire = false, false
			pd.run = pd.run + 1
			for part in pairs(pd.Esps) do pdEspOff(part) end
			pdWin.Visible = false
			pdReopen.Visible = false
		end

		pdScale.Scale = computeScale(PD_W, PD_H)
		pdReopenScale.Scale = pdScale.Scale

		pdMinBtn.MouseButton1Click:Connect(function() pdHide() end)
		pdCloseBtn.MouseButton1Click:Connect(function() PdCloseRequest() end)
		pdReopen.MouseButton1Click:Connect(function()
			if pdReopenDragged() then return end
			openPdWindow()
		end)

		track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			task.wait(0.2)
			if SHUTDOWN or not pdWin.Visible then return end
			pdScale.Scale = computeScale(PD_W, PD_H)
		end))
	end
	pdBuild()

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
	-- 全屏告别层：关掉之后还留 2 秒，配 error 音效和"期待下次注入"
	local function showFarewell()
		local gui = new("ScreenGui", {
			Name = "O_X_HUB_Exit",
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			DisplayOrder = 100003,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = GUI_PARENT,
		})

		local bg = new("Frame", {
			Name = "FarewellBg",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Void,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = gui,
		})

		local card = new("Frame", {
			Name = "FarewellCard",
			Size = UDim2.new(0, 420, 0, 262),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = C.Window,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = bg,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = card })
		local cardStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Transparency = 1, Parent = card })
		local cardScale = new("UIScale", { Scale = 0.94, Parent = card })

		local logo = createLogo(card, {
			Size = UDim2.new(0, 76, 0, 76),
			Position = UDim2.new(0.5, 0, 0, 26),
			AnchorPoint = Vector2.new(0.5, 0),
			Radius = 22,
			TextSize = 36,
		})
		local logoScale = new("UIScale", { Scale = 0.6, Parent = logo })

		local title = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 112),
			BackgroundTransparency = 1,
			Text = CONFIG.Title,
			TextSize = 24,
			Font = FONT_B,
			TextColor3 = C.Text,
			Parent = card,
		})

		local closing = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0, 150),
			BackgroundTransparency = 1,
			Text = L("closing"),
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Dim,
			Parent = card,
		})

		local farewell = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 0, 172),
			BackgroundTransparency = 1,
			Text = L("farewell"),
			TextSize = 22,
			Font = FONT_B,
			TextColor3 = C.Accent,
			Parent = card,
		})

		local track = new("Frame", {
			Size = UDim2.new(0, 200, 0, 4),
			Position = UDim2.new(0.5, -100, 0, 216),
			BackgroundColor3 = C.Card2,
			BorderSizePixel = 0,
			Parent = card,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
		local bar = new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			Parent = track,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
		new("UIGradient", { Color = ColorSequence.new(C.Accent, C.Accent2), Parent = bar })

		-- 入场
		TweenService:Create(bg, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0 }):Play()
		TweenService:Create(card, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0 }):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 0 }):Play()
		tween(cardScale, EASE.pop, { Scale = 1 })
		tween(logoScale, EASE.pop, { Scale = 1 })
		slideIn(title, 10, 0.05, 0.3)
		slideIn(closing, 10, 0.11, 0.3)
		slideIn(farewell, 12, 0.17, 0.34)
		slideIn(track, 10, 0.23, 0.3)
		tween(bar, TweenInfo.new(1.5, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })

		-- 出场
		task.delay(1.9, function()
			local fade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(bg, fade, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(card, fade, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(cardStroke, fade, { Transparency = 1 }):Play()
			TweenService:Create(title, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(closing, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(farewell, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(track, fade, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(logo, fade, { BackgroundTransparency = 1 }):Play()
			for _, d in ipairs(logo:GetDescendants()) do
				if d:IsA("ImageLabel") then
					TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
				end
			end
			task.delay(0.45, function() pcall(function() gui:Destroy() end) end)
		end)
	end

	unloadAll = function(instant)
		if SHUTDOWN then return end
		SHUTDOWN = true

		-- 自动获胜还在跑的话先断掉，不然关掉之后它还会一直把你往出生点拉
		pcall(function() SrvAutoWinRequest(false) end)
		pcall(pdCleanup)
		pcall(closeDenyModal)

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

-- 重启：立刻收干净，不放动画也不出声，但 GUI 还是要销毁再重建（ensureNotify 检测到旧 GUI 还活着会跳过）
	if instant then
		kill()
		clearPendingJoin()
		return
	end

		-- 正常关闭：error 音效 + 抖一下 + 全屏告别
		playSfx("sfx_close", CONFIG.SoundClose)
		releaseSfxFolder()

		local basePos = window.Position
		local baseScale = uiScale.Scale
		task.spawn(function()
			for i = 1, 4 do
				local dx = (i % 2 == 1) and 7 or -5
				window.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + dx,
					basePos.Y.Scale, basePos.Y.Offset - 2)
				uiScale.Scale = baseScale * (1 + 0.012 * ((i % 2 == 1) and 1 or -1))
				task.wait(0.05)
			end
			window.Position = basePos
			uiScale.Scale = baseScale

			pcall(function()
				local t = TweenService:Create(
					uiScale,
					TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Scale = baseScale * 0.86 }
				)
				t:Play()
			end)
			task.wait(0.16)

			kill()
			showFarewell()
		end)
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
		refreshHomeStats()
		guiMain.Enabled = true

		-- ⚠️ 这里只能有一套入场动画。
		-- 之前是 fadeIn(guiMain) + staggerIn(...) 同一帧叠着跑，staggerIn 的快照会读到
		-- fadeIn 刚置上去的"全透明"，于是把全透明当成目标 → 界面再也不显示文字。
		-- 窗口从略小弹回原尺寸 + 顶栏 / 侧栏 / 内容依次落下，这一套就够了。
		-- 窗口从略小弹回原尺寸，顶栏 / 侧栏 / 内容依次落下
		uiScale.Scale = math.clamp(computeScale(WIN_W, WIN_H) * 0.9, 0.5, 1)
		TweenService:Create(
			uiScale,
			TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = computeScale(WIN_W, WIN_H) }
		):Play()
		staggerIn({ header, sidebar, content }, 12, 0.07, 0.36)
		healVisibility(1.2)

		task.wait(0.3)
		notify(string.format(L("welcome"), CONFIG.Title), C.Accent)
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
