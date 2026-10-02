--=====================================================================
--  O_X HUB  ·  通用设置 + 飞行 + 服务器脚本
--  Version : 2.0.1
--  Date    : 2026-10-02
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
--      + DOORS（透视 / 自动 / 移动 / 地图，楼层自动检测，顶部页签是新版式）
--      ⚠️ DOORS 是"大厅 6516141723 + 游戏内 6839171747"两个 place，两个都认
--    · v2.0.1 修复：DOORS 认 place（大厅不再显示成酒店 / 进游戏不再被拦）、
--      地图页改成跟服务器卡片同一条传送链；劫案的自瞄与自动完成（扫描节流 + 交互判据）
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
		pdAllPrompts   = "全图模式",
		pdAllPromptsD  = "不只战利品：地图上所有交互点（门 / 箱子 / 保险箱 / 撬棍点）都按一遍",
		pdTp           = "瞬移",
		pdTpD          = "关掉就按下面的速度跑过去",
		pdLootEsp      = "目标高亮",
		pdLootEspD     = "给战利品和交互点挂名字，隔墙可见",
		pdActRange     = "交互范围",
		pdLootRange    = "高亮范围",
		pdMoveSpeed    = "移动速度",
		pdCarry        = "同时拿包",
		pdDoneOn       = "自动完成已开启",
		pdDoneOff      = "自动完成已关闭",
		pdStep         = "自动完成  ·  目标 %s  ·  手上 %s 个包",
		pdGoing        = "前往 %s",
		pdOpening      = "先开 %s",
		pdThrow        = "送去撤离点  ·  %s 个包",
		pdNothing      = "地图上没有能交互的目标了，先去撤离点等着",
		pdAllDone      = "自动完成  ·  一共处理了 %s 个目标",
		pdLootOn       = "目标高亮已开启",
		pdLootOff      = "目标高亮已关闭",
		pdCameras      = "破坏摄像头",
		pdCamerasD     = "打掉 Workspace.Cameras 里的所有摄像头（要执行器有 getconnections）",
		pdCamNoKey     = "拿不到 RemoteKey，破摄像头这条走不通",
		pdDiagS        = "交互 %s · 战利品 %s · 手上 %s 个包",
		pdDiagA        = "守卫 %s · 武器表 %s · 静默 %s · 视角锁 %s",
		pdErrFmt       = "出错：%s",
		pdNoLoot       = "扫到交互点但没认出战利品，先开箱或等它刷出来",
		pdNoVan        = "找不到撤离点（BagSecuredArea），包丢不出去",
		pdSilentFail   = "抓不到武器表，静默自瞄还没挂上（先进一局）",
		pdCamOn        = "破坏摄像头已开启",
		pdCamOff       = "破坏摄像头已关闭",
		pdYell         = "吼平民",
		pdYellD        = "每 2 秒把地图上的平民喊到你身边（Yell 远程）",
		pdReady        = "自动准备",
		pdReadyD       = "自动按准备，不用手点",
		pdLobbyBack    = "打完回大厅",
		pdLobbyBackD   = "结算界面一出来就自动回主游戏；配合大厅刷图能一直刷",
		pdBackSoon     = "结算了，3 秒后回大厅",
		pdLobbyFarm    = "自动刷图",
		pdLobbyFarmD   = "在大厅自动开 Shadow Raid（Nightmare · 潜入）并开始，打完自动回来",
		pdLobbyHint    = "开了之后：离开已有大厅 → 建 Shadow Raid（Nightmare、潜入）→ 自动开始 → 落地自动重跑脚本。换地图要改代码里那两个字符串。",
		pdLobbyOn      = "自动刷图已开启",
		pdLobbyOff     = "自动刷图已关闭",
		pdLobbyFail    = "找不到大厅远程，这个游戏版本可能改过名字",

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
		pdFollow       = "跟随速度",
		pdInfStam      = "无限体力",
		pdInfStamD     = "体力一直拉满，跑图不喘",
		pdInfAmmo      = "无限弹药",
		pdInfAmmoD     = "拦 Bullet 远程，把消耗弹药改成 false",
		pdInfAmmoOn    = "无限弹药已开启",
		pdInfAmmoOff   = "无限弹药已关闭",
		pdKillAll      = "全灭警察",
		pdKillAllD     = "贴到守卫身上用近战远程打死，全图挨个来；近战杀不掉的丢进远处小黑屋钉住（不再来回窜）",
		pdKillDone     = "已清掉 %s 个守卫",
		pdKillOn       = "全灭警察已开启",
		pdKillOff      = "全灭警察已关闭",
		pdKillFail     = "既没有 RemoteKey 也没有 MeleeDamage，杀不动",
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
		pdTSpot        = "交互点",
		pdVoidHint     = "服务端不吃近战：杀不动的警卫已丢到远处小黑屋钉住，不再贴脸来回窜",

		-- DOORS 面板（place 6516141723 · 楼层靠 GameData.Floor 自动检测）
		srvDoors       = "DOORS",
		dsChipIdle     = "未在 DOORS",
		dsChipLive     = "%s  ·  门 %s",
		dsTabEsp       = "透视",
		dsTabAuto      = "自动",
		dsTabMove      = "移动",
		dsTabMap       = "地图",

		dsEspTitle     = "透视",
		dsEspSub       = "隔墙可见 · 名字 + 方框",
		dsEspEntity    = "实体透视",
		dsEspEntityD   = "追人的东西全部标红，远远就能看到",
		dsEspItem      = "道具透视",
		dsEspItemD     = "钥匙 / 撬锁器 / 手电筒 / 十字架…",
		dsEspDoor      = "门透视",
		dsEspDoorD     = "当前房间的门和出口标成琥珀色",
		dsEspHide      = "藏身点透视",
		dsEspHideD     = "所有柜子都标出来，跑图不用瞎找",
		dsEspDist      = "显示距离",
		dsEspRange     = "透视范围",
		dsEspHint      = "透视 0.3 秒扫一次，超出范围的先丢。关掉立刻清干净，不会留残影。",

		dsAutoTitle    = "自动",
		dsAutoSub      = "开了就一直跑，关掉就停",
		dsAutoHide     = "自动躲藏",
		dsAutoHideD    = "Rush / Ambush / Halt 一来就钻进最近的柜子，走了自动出来",
		dsAutoInteract = "自动交互",
		dsAutoInteractD= "把交互距离内的按钮 / 把手 / 电梯全按一遍",
		dsAutoPickup   = "自动拾取",
		dsAutoPickupD  = "走过路过的道具直接捡起来",
		dsAutoNext     = "自动进门",
		dsAutoNextD    = "把你推到当前房间的门前，游戏自己会把门打开",
		dsAutoRevive   = "自动复活",
		dsAutoReviveD  = "倒下之后自动点复活（还有复活次数才有用）",

		dsMoveTitle    = "移动",
		dsMoveSub      = "改了立刻生效，复活后自动重新应用",
		dsBright       = "全亮",
		dsBrightD      = "把 Lighting 拉亮，黑屋子和停电都看得见",
		dsNoclip       = "穿墙",
		dsNoclipD      = "角色不再和任何东西碰撞，关掉立刻还原",
		dsSpeed        = "移动速度",
		dsJump         = "跳跃高度",
		dsReach        = "交互距离",
		dsMoveHint     = "速度和跳跃只改你自己的角色。穿墙关掉时会把所有部件的碰撞还原成 true。",

		dsMapTitle     = "地图",
		dsMapSub       = "自动检测地点与楼层 · 跨服务器传送走的是服务器那套",
		dsMapGo        = "传送",
		dsMapJump      = "跳到门号",
		dsMapJumpGo    = "传送到这扇门",
		dsMapLobby     = "回大厅",
		dsMapHint      = "大厅和游戏内是两个服务器，点「传送」就是一次真正的服务器传送（落地自动重跑脚本）。换楼层只能坐电梯。",
		dsAreaDoors    = "%s 扇门",
		dsAreaNoDoor   = "起点 / 没有门",

		dsAreaLobby    = "大厅",
		dsAreaHotel    = "酒店",
		dsAreaBackdoor = "后门",
		dsAreaMines    = "矿洞",
		dsAreaRooms    = "密室",
		dsAreaRetro    = "复古酒店",
		dsAreaParty    = "派对",

		dsTDoor        = "门",
		dsTHide        = "藏身点",
		dsOnFmt        = "%s已开启",
		dsOffFmt       = "%s已关闭",
		dsBrightOn     = "全亮已开启",
		dsBrightOff    = "全亮已关闭",
		dsNoclipOn     = "穿墙已开启",
		dsNoclipOff    = "穿墙已关闭",
		dsHideIn       = "发现 %s  ·  已自动躲进柜子",
		dsHideOut      = "安全了  ·  已从柜子里出来",
		dsHideNone     = "附近没有藏身点，只能硬吃了",
		dsTpDone       = "已传送到「%s」",
		dsTpDoor       = "已传送到门 %s",
		dsTpNoRoom     = "这一层还没刷出这扇门",
		dsLobbyBack    = "正在回大厅",
		dsLobbyGo      = "正在回大厅  ·  到了坐「%s」的电梯",
		dsLobbyFail    = "找不到大厅远程，这个版本可能改过名字",
		dsPlaceId      = "place %s",
		dsPlaceLobby   = "大厅",
		dsPlaceLobbyD  = "从 Roblox 点进来的那个服务器，坐电梯开局",
		dsPlaceGame    = "游戏内",
		dsPlaceGameD   = "酒店 / 后门 / 矿洞 / 密室都在这一个服务器里",
		dsCurFloor     = "当前楼层",
		dsCurFloorFmt  = "%s  ·  门 %s",
		dsAlreadyThere = "已经在「%s」了",
		dsFloorSwitch  = "「%s」要坐电梯过去  ·  先送你回大厅",










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
		pdAllPrompts   = "Whole map",
		pdAllPromptsD  = "Not just loot: presses every interactable on the map (doors, boxes, safes, pry points)",
		pdTp           = "Teleport",
		pdTpD          = "Off = run there at the speed below",
		pdLootEsp      = "Loot highlight",
		pdLootEspD     = "Name tags on loot and interactables, through walls",
		pdActRange     = "Interact range",
		pdLootRange    = "Highlight range",
		pdMoveSpeed    = "Move speed",
		pdCarry        = "Bags at once",
		pdDoneOn       = "Auto complete on",
		pdDoneOff      = "Auto complete off",
		pdStep         = "Auto complete  ·  target %s  ·  carrying %s",
		pdGoing        = "Heading to %s",
		pdOpening      = "Opening %s first",
		pdThrow        = "Stashing  ·  %s bag(s)",
		pdNothing      = "Nothing left to interact with, waiting at the exfil",
		pdAllDone      = "Auto complete  ·  %s targets handled",
		pdLootOn       = "Loot highlight on",
		pdLootOff      = "Loot highlight off",
		pdCameras      = "Break cameras",
		pdCamerasD     = "Shoots down every camera in Workspace.Cameras (needs getconnections)",
		pdCamNoKey     = "No RemoteKey, cannot break cameras",
		pdDiagS        = "prompts %s · loot %s · bags %s",
		pdDiagA        = "guards %s · gun tables %s · silent %s · camlock %s",
		pdErrFmt       = "Error: %s",
		pdNoLoot       = "Prompts found but no loot recognised yet, open crates first",
		pdNoVan        = "No exfil point (BagSecuredArea), cannot stash bags",
		pdSilentFail   = "No weapon table yet, silent aim not hooked (join a heist first)",
		pdCamOn        = "Cameras disabled",
		pdCamOff       = "Camera breaking off",
		pdYell         = "Yell at civilians",
		pdYellD        = "Yells at the map's civilians every 2 seconds",
		pdReady        = "Auto ready",
		pdReadyD       = "Presses ready for you",
		pdLobbyBack    = "Back to lobby",
		pdLobbyBackD   = "Returns to the main game the moment the results screen shows; pairs with lobby farming",
		pdBackSoon     = "Heist done, back to the lobby in 3s",
		pdLobbyFarm    = "Lobby farm",
		pdLobbyFarmD   = "Makes a Shadow Raid (Nightmare, Stealth) lobby, starts it, comes back after every run",
		pdLobbyHint    = "While on: leaves any lobby, makes Shadow Raid (Nightmare, Stealth), starts it, and reruns the script on landing. Edit the two strings in code to change map.",
		pdLobbyOn      = "Lobby farm on",
		pdLobbyOff     = "Lobby farm off",
		pdLobbyFail    = "Lobby remotes missing, the game may have renamed them",

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
		pdFollow       = "Follow speed",
		pdInfStam      = "Infinite stamina",
		pdInfStamD     = "Stamina stays maxed, no more huffing",
		pdInfAmmo      = "Infinite ammo",
		pdInfAmmoD     = "Hooks the Bullet remote and sets UseAmmo to false",
		pdInfAmmoOn    = "Infinite ammo on",
		pdInfAmmoOff   = "Infinite ammo off",
		pdKillAll      = "Wipe the police",
		pdKillAllD     = "Melee-snaps each guard across the map; guards shrugging melee get banished far away and pinned",
		pdKillDone     = "Cleared %s guards",
		pdKillOn       = "Police wipe on",
		pdKillOff      = "Police wipe off",
		pdKillFail     = "No RemoteKey and no MeleeDamage, cannot kill",
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
		pdTSpot        = "spot",
		pdVoidHint     = "Melee refused: unkillable guards get banished far away and pinned instead of jittering",

		-- DOORS panel (place 6516141723 · floor auto-detected from GameData.Floor)
		srvDoors       = "DOORS",
		dsChipIdle     = "Not in DOORS",
		dsChipLive     = "%s  ·  Door %s",
		dsTabEsp       = "ESP",
		dsTabAuto      = "Auto",
		dsTabMove      = "Move",
		dsTabMap       = "Floors",

		dsEspTitle     = "ESP",
		dsEspSub       = "Visible through walls · name + box",
		dsEspEntity    = "Entity ESP",
		dsEspEntityD   = "Anything that chases you is drawn in red",
		dsEspItem      = "Item ESP",
		dsEspItemD     = "Keys / lockpicks / flashlights / crucifixes...",
		dsEspDoor      = "Door ESP",
		dsEspDoorD     = "The current room's door and exit, in amber",
		dsEspHide      = "Hiding spot ESP",
		dsEspHideD     = "Every closet marked, no more blind searching",
		dsEspDist      = "Show distance",
		dsEspRange     = "ESP range",
		dsEspHint      = "ESP sweeps every 0.3s and drops anything out of range. Turning it off clears everything at once.",

		dsAutoTitle    = "Auto",
		dsAutoSub      = "Runs while on, stops the moment you turn it off",
		dsAutoHide     = "Auto hide",
		dsAutoHideD    = "Dives into the nearest closet when Rush / Ambush / Halt shows up, leaves when it is gone",
		dsAutoInteract = "Auto interact",
		dsAutoInteractD= "Presses every prompt inside your reach",
		dsAutoPickup   = "Auto pickup",
		dsAutoPickupD  = "Picks up the items you walk past",
		dsAutoNext     = "Auto advance",
		dsAutoNextD    = "Pushes you to the current room's door, the game opens it for you",
		dsAutoRevive   = "Auto revive",
		dsAutoReviveD  = "Clicks revive the moment you go down (needs revives left)",

		dsMoveTitle    = "Move",
		dsMoveSub      = "Applies instantly, re-applied after a respawn",
		dsBright       = "Fullbright",
		dsBrightD      = "Brightens Lighting so dark rooms and blackouts stay readable",
		dsNoclip       = "Noclip",
		dsNoclipD      = "No collisions at all, restored the moment you turn it off",
		dsSpeed        = "Walk speed",
		dsJump         = "Jump power",
		dsReach        = "Reach",
		dsMoveHint     = "Speed and jump only affect your own character. Turning noclip off restores collisions on every part.",

		dsMapTitle     = "Floors",
		dsMapSub       = "Place and floor auto-detected · cross-server travel uses the same chain as the server cards",
		dsMapGo        = "Go",
		dsMapJump      = "Jump to door",
		dsMapJumpGo    = "Teleport to this door",
		dsMapLobby     = "Back to lobby",
		dsMapHint      = "Lobby and In game are two separate servers; \"Go\" performs a real server teleport (the script re-runs on arrival). Floors can only be changed by elevator.",
		dsAreaDoors    = "%s doors",
		dsAreaNoDoor   = "Start / no doors",

		dsAreaLobby    = "Lobby",
		dsAreaHotel    = "The Hotel",
		dsAreaBackdoor = "The Backdoor",
		dsAreaMines    = "The Mines",
		dsAreaRooms    = "The Rooms",
		dsAreaRetro    = "Retro Hotel",
		dsAreaParty    = "Party",

		dsTDoor        = "Door",
		dsTHide        = "Hiding spot",
		dsOnFmt        = "%s on",
		dsOffFmt       = "%s off",
		dsBrightOn     = "Fullbright on",
		dsBrightOff    = "Fullbright off",
		dsNoclipOn     = "Noclip on",
		dsNoclipOff    = "Noclip off",
		dsHideIn       = "%s incoming  ·  auto-hid in a closet",
		dsHideOut      = "Safe again  ·  left the closet",
		dsHideNone     = "No hiding spot nearby, you are taking this one",
		dsTpDone       = "Teleported to %s",
		dsTpDoor       = "Teleported to door %s",
		dsTpNoRoom     = "That door is not loaded on this floor yet",
		dsLobbyBack    = "Heading back to the lobby",
		dsLobbyGo      = "Heading back to the lobby  ·  take the %s elevator there",
		dsLobbyFail    = "Lobby remote not found, this build may have renamed it",
		dsPlaceId      = "place %s",
		dsPlaceLobby   = "Lobby",
		dsPlaceLobbyD  = "The server you join from Roblox; take the elevator to start",
		dsPlaceGame    = "In game",
		dsPlaceGameD   = "Hotel / Backdoor / Mines / Rooms all live in this one server",
		dsCurFloor     = "Floor",
		dsCurFloorFmt  = "%s  ·  Door %s",
		dsAlreadyThere = "Already in %s",
		dsFloorSwitch  = "%s needs the elevator  ·  sending you back to the lobby",










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
	Version = "v2.0.1",

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
	srv_doors = [==[
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
	sfx_notify = "mp3", sfx_close = "mp3", sfx_deny = "mp3", srv_nds = "png", srv_heist = "png",
	srv_doors = "png" }

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

--========================== 服务器：DOORS ==========================
-- DOORS 👁（LSPLASH）是**两个 place**：
--   6516141723 = 大厅（从 Roblox 点进来的那个，只有电梯 / 商店）
--   6839171747 = 游戏内（所有楼层都在这一个 place 里）
-- 楼层靠 ReplicatedStorage.GameData.Floor（Hotel / Backdoor / Mines / Rooms / Retro / Party）
-- 区分，LatestRoom 是门号。⚠️ 只认大厅那个 ID 的话，一进游戏就会被拦在门外（实机踩过）。
local DS = {
	Lobby = 6516141723,
	Game  = 6839171747,
	-- 官方附属 place（语音房等），能进就说明在 DOORS 里
	Extra = { 12308344607 },
	-- GameData.Floor 可能出现的值（认新 place 时的白名单）
	Floors = { Hotel = true, Backdoor = true, Mines = true, Rooms = true,
		Retro = true, Party = true, Lobby = true, Fools = true },
}

-- 在不在 DOORS 里（两个 place + 附属 place 都算）
local function dsInPlace()
	local ok, pid = pcall(function() return game.PlaceId end)
	if not ok or type(pid) ~= "number" then return false, nil end
	if pid == DS.Lobby or pid == DS.Game then return true, pid end
	for _, id in ipairs(DS.Extra) do
		if pid == id then return true, pid end
	end
	-- 兜底：官方以后加新 place（活动大厅之类）时也能认出来。
	-- 判据卡得很死：GameData 下同时有 Floor(StringValue，值是已知楼层名) 和 LatestRoom(NumberValue)。
	local ok2, has = pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local gd = rs:FindFirstChild("GameData")
		if not gd then return false end
		local fl = gd:FindFirstChild("Floor")
		local lr = gd:FindFirstChild("LatestRoom")
		if not (fl and lr) then return false end
		if not fl:IsA("StringValue") or not lr:IsA("NumberValue") then return false end
		return DS.Floors[tostring(fl.Value)] == true
	end)
	if ok2 and has then return true, pid end
	return false, pid
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
	-- DOORS 面板：窗口开关 + 关脚本时的清理（真正实现都在下面那个 dsBuild 里）
	local openDoorsWindow = function() end
	local DsCloseRequest = function() end
	local dsCleanup = function() end
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
	-- 卡片上写大厅那个 ID（从 Roblox 点进来的就是它）；真正的判定走 dsInPlace（两个 place 都认）
	addServerCard(3, L("srvDoors"), DS.Lobby, "srv_doors", dsInPlace, function() openDoorsWindow() end)

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 234),
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
		local PD_W, PD_H = 520, 560
		local pd = {
			-- 潜入
			AutoDone = false, AllPrompts = false, Tp = true, LootEsp = false,
			Cameras = false, Yell = false, Ready = false, LobbyBack = false,
			ActRange = 15, LootRange = 200, MoveSpeed = 75, CarryMax = 1,
			-- 强攻
			Aim = false, Fire = false, OnlyEnemy = true, Head = true, Walls = false,
			Esp = false, InfStam = false, InfAmmo = false, KillAll = false,
			Priority = "cross", Fov = 90, Range = 300, Follow = 1, EspRange = 600,
			-- 运行时
			Items = {}, Esps = {}, Boxes = {}, Taken = setmetatable({}, { __mode = "k" }),
			Bad = setmetatable({}, { __mode = "k" }),
			prompts = {}, spots = {}, clicks = {}, scanAt = 0, names = {}, run = 0,
			carry = 0, key = nil, ammoOld = nil, ammoHooked = false,
			lastKill = 0, lastYell = 0, lastReady = 0, lastBox = 0, lastAmmo = 0,
			-- 第三轮：静默自瞄 / 贴脸交互 / 诊断（真脚本做法，见 _body2.lua 注释）
			locked = nil, hit = nil, frozen = false, silentOrig = {}, projCache = {},
			silent = false, silentN = 0, gunN = 0, camOk = false, aimAt = 0,
			promptN = 0, lootN = 0, enemyN = 0, diagAt = 0, err = nil, errAt = 0,
			dcache = nil, dcAt = 0, killMiss = {}, voidSet = {}, voidPos = nil, voidN = 0, voidAt = 0, pinAt = 0, voidWarn = false, _ncHooked = false, aimFnCalls = 0, aimNoTarget = 0, aimNoPos = 0,
		}
		local pdAutoDoneLoop            -- 先声明：潜入页的开关要用它
		local pdEspSweep                -- 透视收尾（多处要用）
		local pdLobbyFarm               -- 大厅自动开图刷（主游戏页那个开关）
		local pdSetAmmo                 -- 无限弹药的元表钩子（开关直接调用，见潜入/强攻页）
		local pdSilent                  -- 静默自瞄开关（包装武器子弹表，强攻页调用）
		local pdVan                     -- 撤离车/包点（先声明：body1 的 pdIsDeposit 要用）
		local pdAimBind                 -- 自瞄的渲染步绑定（窗口开关时挂/摘）
		local pdAimUnbind
		local pdUnsnap                  -- 解钉（潜入页关掉自动完成时要用，见 _body2）

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
				Size = UDim2.new(1, 0, 0, 30),
				Position = UDim2.new(0, 0, 0, y),
				BackgroundColor3 = C.Card,
				BorderSizePixel = 0,
				Parent = page,
			})
			new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = card })
			new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = card })
			new("TextLabel", {
				Size = UDim2.new(1, -70, 0, 14),
				Position = UDim2.new(0, 13, 0, 1),
				BackgroundTransparency = 1,
				Text = name,
				TextSize = 13,
				Font = FONT_B,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			new("TextLabel", {
				Size = UDim2.new(1, -70, 0, 12),
				Position = UDim2.new(0, 13, 0, 15),
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
				Position = UDim2.new(1, -54, 0, y + 4),
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

		-- ---------- 页：主游戏（大厅） ----------
		local pdUpdatePage = pdAddPage("update")
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 26),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -78),
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
			Position = UDim2.new(0.5, 0, 0.5, -46),
			BackgroundTransparency = 1,
			Text = L("pdNoScript"),
			TextSize = 14,
			Font = FONT_N,
			TextColor3 = C.Sub,
			Parent = pdUpdatePage,
		})
		new("TextLabel", {
			Size = UDim2.new(1, -70, 0, 40),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -8),
			BackgroundTransparency = 1,
			Text = L("pdUpdateHint"),
			TextSize = 11,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextWrapped = true,
			Parent = pdUpdatePage,
		})

		-- 大厅里唯一能用的东西：自动开图刷（notoriety-autowin 那套）
		pdRow(pdUpdatePage, 60, "LobbyFarm", L("pdLobbyFarm"), L("pdLobbyFarmD"), false, function(v)
			if v then
				notify(L("pdLobbyOn"), C.Green)
				task.spawn(pdLobbyFarm)
			else
				notify(L("pdLobbyOff"), C.Red)
			end
		end)
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 0, 104),
			BackgroundTransparency = 1,
			Text = L("pdLobbyHint"),
			TextSize = 11,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Parent = pdUpdatePage,
		})

		-- ---------- 页：潜入 ----------
		local pdStealth = pdAddPage("stealth")
		pdAddNav("stealth", L("pdTabStealth"), 1)
		pdHead(pdStealth, L("pdStealthTitle"), L("pdStealthSub"))

		-- 跑到哪一步了（"点了有反应"的关键反馈）
		local pdStatus = new("TextLabel", {
			Name = "HeistStatus",
			Size = UDim2.new(0, 220, 0, 14),
			Position = UDim2.new(1, -220, 0, 4),
			BackgroundTransparency = 1,
			Text = "",
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Green,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = pdStealth,
		})

		pdRow(pdStealth, 40, "AutoDone", L("pdAutoDone"), L("pdAutoDoneD"), false, function(v)
			pd.AutoDone = v
			if v then
				pd.carry = 0
				notify(L("pdDoneOn"), C.Green)
				task.spawn(pdAutoDoneLoop)
			else
				pd.run = pd.run + 1
				pdStatus.Text = ""
				pcall(pdUnsnap)                       -- 关掉时一定解钉：钉住 = 手机摇杆和触屏全没反应
				notify(L("pdDoneOff"), C.Red)
			end
		end)
		pdRow(pdStealth, 74, "AllPrompts", L("pdAllPrompts"), L("pdAllPromptsD"), false,
			function(v) pd.AllPrompts = v end)
		pdRow(pdStealth, 108, "Tp", L("pdTp"), L("pdTpD"), true, function(v) pd.Tp = v end)
		pdRow(pdStealth, 142, "LootEsp", L("pdLootEsp"), L("pdLootEspD"), false, function(v)
			pd.LootEsp = v
			notify(v and L("pdLootOn") or L("pdLootOff"), v and C.Green or C.Red)
		end)
		pdRow(pdStealth, 176, "Cameras", L("pdCameras"), L("pdCamerasD"), false, function(v)
			pd.Cameras = v
			notify(v and L("pdCamOn") or L("pdCamOff"), v and C.Green or C.Red)
		end)
		pdRow(pdStealth, 210, "Yell", L("pdYell"), L("pdYellD"), false, function(v) pd.Yell = v end)
		pdRow(pdStealth, 244, "Ready", L("pdReady"), L("pdReadyD"), false, function(v) pd.Ready = v end)
		pdRow(pdStealth, 278, "LobbyBack", L("pdLobbyBack"), L("pdLobbyBackD"), false,
			function(v) pd.LobbyBack = v end)

		pdSlider(pdStealth, 316, L("pdActRange"), 5, 100, pd.ActRange, function(v) pd.ActRange = v end)
		pdSlider(pdStealth, 358, L("pdLootRange"), 20, 800, pd.LootRange, function(v) pd.LootRange = v end)
		pdSlider(pdStealth, 400, L("pdMoveSpeed"), 20, 300, pd.MoveSpeed, function(v) pd.MoveSpeed = v end)
		pdSlider(pdStealth, 442, L("pdCarry"), 1, 2, pd.CarryMax, function(v) pd.CarryMax = v end)

		-- ---------- 页：强攻 ----------
		local pdAssault = pdAddPage("assault")
		pdAddNav("assault", L("pdTabAssault"), 2)
		pdHead(pdAssault, L("pdAssaultTitle"), L("pdAssaultSub"))

		local PRI_KEY = { cross = "pdPriCross", near = "pdPriNear", low = "pdPriLow" }

		pdRow(pdAssault, 40, "Aim", L("pdAim"), L("pdAimD"), false, function(v)
			pd.Aim = v
			if v then
				pcall(pdAimBind)                        -- 相机锁（排在游戏相机脚本之后写）
				pcall(pdSilent, true)                   -- 子弹改道；武器表晚加载就靠心跳每 2 秒重试
				if not pd.silent then notify(L("pdSilentFail"), C.Amber) end
				-- 3 秒后诊断：没挂上 / 没认出敌人 / 武器表没找到
				task.delay(3, function()
					if not pd.Aim then return end
					if not pd.aimBound then notify("自瞄挂不上：执行器可能拦了 RenderStep", C.Red) end
					if (pd.enemyN or 0) == 0 then notify("没认出敌人：守卫文件夹名可能不在关键词表里", C.Amber) end
					if pd.silentN == 0 then notify("静默自瞄没找到武器表：子弹不会跟准星", C.Amber) end
				end)
			elseif not pd.Fire then
				pcall(pdAimUnbind)
				pcall(pdSilent, false)
			end
			notify(v and string.format(L("pdAimOn"), L(PRI_KEY[pd.Priority])) or L("pdAimOff"),
				v and C.Green or C.Red)
			if v and #pd.Items == 0 then notify(L("pdNoNpc"), C.Amber) end
		end)
		pdRow(pdAssault, 74, "Fire", L("pdFire"), L("pdFireD"), false, function(v)
			pd.Fire = v
			if v then pcall(pdAimBind) end
		end)
		pdRow(pdAssault, 108, "OnlyEnemy", L("pdOnlyEnemy"), L("pdOnlyEnemyD"), true,
			function(v) pd.OnlyEnemy = v end)
		pdRow(pdAssault, 142, "Head", L("pdHead"), L("pdHeadD"), true, function(v) pd.Head = v end)
		pdRow(pdAssault, 176, "Walls", L("pdWalls"), L("pdWallsD"), false, function(v) pd.Walls = v end)
		pdRow(pdAssault, 210, "Esp", L("pdEsp"), L("pdEspD"), false, function(v)
			pd.Esp = v
			notify(v and L("pdEspOn") or L("pdEspOff"), v and C.Green or C.Red)
		end)
		pdRow(pdAssault, 244, "InfStam", L("pdInfStam"), L("pdInfStamD"), false,
			function(v) pd.InfStam = v end)
		pdRow(pdAssault, 278, "InfAmmo", L("pdInfAmmo"), L("pdInfAmmoD"), false, function(v)
			pd.InfAmmo = v
			pcall(function() pdSetAmmo(v) end)
			if v then
				notify(L("pdInfAmmoOn"), C.Green)
			else
				notify(L("pdInfAmmoOff"), C.Red)
			end
		end)
		pdRow(pdAssault, 312, "KillAll", L("pdKillAll"), L("pdKillAllD"), false, function(v)
			pd.KillAll = v
			if not v then
				pd.killList, pd.killTarget, pd.killWarned, pd.killN = nil, nil, nil, 0
				pd.killMiss, pd.voidWarn = {}, false
			end
			notify(v and L("pdKillOn") or L("pdKillOff"), v and C.Green or C.Red)
		end)

		-- 优先目标：一行里塞三个胶囊，省一整行
		new("TextLabel", {
			Size = UDim2.new(0, 80, 0, 22),
			Position = UDim2.new(0, 0, 0, 348),
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
				Size = UDim2.new(0, 90, 0, 22),
				Position = UDim2.new(0, 84 + (i - 1) * 94, 0, 348),
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
				TextSize = 11,
				Font = FONT_B,
				TextColor3 = C.Sub,
				Parent = btn,
			})
			btn.MouseButton1Click:Connect(function() pdPriApply(key) end)
			priRows[key] = { btn = btn, stroke = stroke, label = label }
		end
		pdPriApply("cross")

		pdSlider(pdAssault, 376, L("pdFov"), 10, 360, pd.Fov, function(v) pd.Fov = v end)
		pdSlider(pdAssault, 414, L("pdAimRange"), 20, 1000, pd.Range, function(v) pd.Range = v end)
		pdSlider(pdAssault, 452, L("pdFollow"), 20, 100, 100, function(v) pd.Follow = v / 100 end)

		-- 诊断行：一眼看出"到底挂上没有"（心跳每 0.5 秒刷一次）
		local function pdDiagLabel(page, name)
			return new("TextLabel", {
				Name = name,
				Size = UDim2.new(1, 0, 0, 12),
				Position = UDim2.new(0, 0, 0, 486),
				BackgroundTransparency = 1,
				Text = "",
				TextSize = 10,
				Font = FONT_N,
				TextColor3 = C.Dim,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = page,
			})
		end
		local pdDiagStealth = pdDiagLabel(pdStealth, "HeistDiag")
		local pdDiagAssault = pdDiagLabel(pdAssault, "HeistDiag")

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
				-- 游戏自己会把当前劫案写进 Workspace 属性（实测 CurrentHeist），比查 place 名字准
				local name
				pcall(function()
					local heist = workspace:GetAttribute("CurrentHeist")
					if type(heist) == "string" and heist ~= "" then name = heist end
				end)
				name = name or pdMapName(pid)
				if SHUTDOWN then return end
				pdTag.Text = string.format(L("pdMapTag"), name)
			end)
		end

		-- ---------------- Notoriety 里的位置 ----------------
		-- Workspace.Police（敌人）/ Citizens（平民）/ BigLoot·Lootables（战利品）/
		-- BagSecuredArea（撤离点）/ Cameras（摄像头）；远程在 RS_Package.Remotes。
		-- 名字随版本可能变，所以全部 FindFirstChild + 兜底。
		local LOOT_FOLDERS = { "BigLoot", "Lootables", "Loot", "Lootable", "LootBag",
			"SafeSpots", "OpenedSafe", "OpenMilitaryCrate", "MilitaryCrate",
			"ShadowBoxes", "Vault", "Bags", "Coke", "WeaponBagger" }
		-- 物品名（实机里同一个战利品在不同地图挂在不同容器里，光靠文件夹名会漏）
		local LOOT_NAMES = { "DepositGoldBar", "GoldBar", "MoneyStack", "Painting",
			"Cola", "Barrel", "Bag", "Money", "Cash", "Jewel", "Gem", "Necklace",
			"Watch", "Artifact" }
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
			for _ = 1, 4 do
				if not inst then return nil end
				if inst:IsA("BasePart") then return inst.Position end
				if inst:IsA("Attachment") then return inst.WorldPosition end
				if inst:IsA("Model") then
					local p = inst.PrimaryPart or inst:FindFirstChildOfClass("Part")
					return p and p.Position or nil
				end
				-- 交互点本身没有位置，得往上找到挂它的那个部件
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

		local function pdNameHit(name, list)
			if type(name) ~= "string" or name == "" then return false end
			local low = string.lower(name)
			for _, kw in ipairs(list) do
				if string.find(low, string.lower(kw), 1, true) then return true end
			end
			return false
		end

		-- 交互点是不是战利品。三路一起判，因为实机里战利品 prompt 常挂在 Hitbox 子件上、
		-- 父级可能是地图临时容器 —— 上一版只看 6 层内的文件夹名，所以老报"没有战利品"。
		local function pdIsLoot(p)
			local txt = ""
			pcall(function()
				txt = tostring(p.ActionText or "") .. " " .. tostring(p.ObjectText or "")
			end)
			if pdNameHit(txt, { "grab", "steal", "take", "pick", "loot", "rob",
				"collect", "carry", "lift", "pocket" }) then
				return true
			end
			local node, depth = p, 0
			while node and node ~= workspace and depth < 12 do
				if pdNameHit(node.Name, LOOT_FOLDERS) or pdNameHit(node.Name, LOOT_NAMES) then
					return true
				end
				node, depth = node.Parent, depth + 1
			end
			return false
		end

		-- 敌我识别：玩家一律队友 / 本人（Notoriety 是合作劫案）；剩下的按文件夹 + 名字认。
		-- 实机反馈"是不是没识别警卫"：警卫可能不在 Police 文件夹（增援直接生在地上、
		-- 不同地图文件夹改名），所以名字关键词也认：Guard / Cop / Police / SWAT / Officer…
		local PD_KW = {
			enemy = { "police", "guard", "cop", "security", "swat", "officer",
				"sheriff", "tactical", "riot", "marine", "enemy", "hostile", "fbi", "agent" },
			civ = { "citizen", "civilian", "hostage", "shopper", "pedestrian", "clerk" },
			depV = { "secured", "unload", "drop off", "drop bags",
				"put bags", "load bag", "get in", "enter van", "escape", "extract" },
			depN = { "secured", "bagsecured", "van", "truck", "escape", "extract", "exit" },
		}
		local function pdKind(model)
			local plr = Players:GetPlayerFromCharacter(model)
			if plr then return (plr == LocalPlayer) and "me" or "ally" end
			local node, depth = model, 0
			while node and node ~= workspace and depth < 8 do
				local n = tostring(node.Name)
				if pdNameHit(n, PD_KW.enemy) then return "enemy" end
				if pdNameHit(n, PD_KW.civ) then return "civ" end
				for _, f in ipairs(ALLY_FOLDERS) do
					if n == f then return "ally" end
				end
				node, depth = node.Parent, depth + 1
			end
			local nm = string.lower(tostring(model.Name))
			for _, kw in ipairs(PD.AllyKw) do
				if string.find(nm, kw, 1, true) then return "ally" end
			end
			return "other"
		end

		-- 撤离 / 装车类交互点：绝不能当目标（上一版实机"一直传送到车上"就是
		-- 装包 prompt 的文字 / 容器名带 bag·secured 被当成战利品，无限跑车）。
		-- 丢包只走 ThrowBag 远程，不看 prompt。
		local function pdIsDeposit(p)
			local txt = ""
			pcall(function()
				txt = tostring(p.ActionText or "") .. " " .. tostring(p.ObjectText or "")
			end)
			if pdNameHit(txt, PD_KW.depV) then return true end
			local node, depth = p, 0
			while node and node ~= workspace and depth < 12 do
				if pdNameHit(node.Name, PD_KW.depN) then return true end
				node, depth = node.Parent, depth + 1
			end
			local pos = pdPos(p)
			local van = pdVan and pdVan()
			if pos and van then
				local ok, d = pcall(function() return (pos - van.Position).Magnitude end)
				if ok and d and d < 18 then return true end
			end
			return false
		end

		-- ---------------- 扫描：交互点 / 人物 ----------------
		-- 手机端实测：每 0.4 秒全树 GetDescendants() 明显掉帧（触屏发黏 = 用户说的"断触"），
		-- 所以实例表缓存 2.5 秒才重取一次，0.4 秒只是重走这份缓存。
		local function pdScan()
			local ps, cs, list, spots = {}, {}, {}, {}
			local now = os.clock()
			local stale = (not pd.dcache) or (now - pd.dcAt > 2.5)
			if pd.dirty and (now - pd.dcAt > 0.8) then stale = true end
			if stale then
				local ok, d = pcall(function() return workspace:GetDescendants() end)
				pd.dcache = ok and d or {}
				pd.dcAt = now
				pd.dirty = false
			end
			for _, d in ipairs(pd.dcache) do
				if d:IsA("ProximityPrompt") then
					-- dcache 是快照：prompt 被消费后 Parent=nil 但还在数组里，不剔掉就会反复当目标
					if d.Parent and d.Enabled ~= false then
						ps[#ps + 1] = d
						-- 位置和"是不是战利品"一次算好（省得每轮重走祖先链）
						local part, n = d.Parent, 0
						while part and not part:IsA("BasePart") and n < 6 do
							part, n = part.Parent, n + 1
						end
						spots[#spots + 1] = {
							p = d, part = part, pos = pdPos(d), loot = pdIsLoot(d),
							dep = pdIsDeposit(d),
						}
					end
				elseif d:IsA("ClickDetector") then
					if d.Parent then cs[#cs + 1] = d end
				elseif d:IsA("Humanoid") then
					local model = d.Parent
					if model and d.Health > 0 then
						list[#list + 1] = { model = model, hum = d, kind = pdKind(model) }
					end
				end
			end
			local lootN, enemyN = 0, 0
			for _, s in ipairs(spots) do
				if s.loot and not s.dep then lootN = lootN + 1 end
			end
			for _, it in ipairs(list) do
				if it.kind == "enemy" then enemyN = enemyN + 1 end
			end
			pd.prompts, pd.clicks, pd.Items = ps, cs, list
			pd.spots, pd.promptN, pd.lootN, pd.enemyN = spots, #spots, lootN, enemyN
		end

		-- 树一变就打个"脏"标记 —— 但**不立刻丢缓存**。
		-- 🔴 v2.0.1 修的关键 bug：之前是 DescendantAdded/Removing 直接 pd.dcache = nil，
		--    可实机里子弹 / 弹壳 / 枪口火光每秒让这两个事件触发几十次，缓存等于永远失效，
		--    于是每 0.4 秒就来一次 workspace:GetDescendants()（几万个实例）——
		--    手机端直接卡成"点了没反应"，自瞄和自动完成都是被这个拖死的。
		--    现在：脏了提前重扫，但最快 0.8 秒一次（新刷出的战利品照样 0.8 秒内看得见）。
		pcall(function()
			local function pdDirty() pd.dirty = true end
			track(workspace.DescendantAdded:Connect(pdDirty))
			track(workspace.DescendantRemoving:Connect(pdDirty))
		end)

		-- ---------------- 透视：所有人 + 战利品，方框 + 名字，按类型分色 ----------------
		local ESP_COLOR = { enemy = C.Red, civ = C.Amber, ally = C.Green,
			other = C.Sub, loot = C.White, spot = C.Dim }
		local ESP_KEY = { enemy = "pdTEnemy", civ = "pdTCiv", ally = "pdTAlly",
			other = "pdTOther", loot = "pdTLoot", spot = "pdTSpot" }
		local ESP_BOX = { enemy = Vector3.new(3, 5.5, 2.2), civ = Vector3.new(3, 5.5, 2.2),
			ally = Vector3.new(3, 5.5, 2.2), other = Vector3.new(3, 5.5, 2.2),
			loot = Vector3.new(1.8, 1.8, 1.8), spot = Vector3.new(1.8, 1.8, 1.8) }

		local function pdEspPart(inst)
			if not inst then return nil end
			if inst:IsA("BasePart") then return inst end
			return inst:FindFirstChild("Head") or inst:FindFirstChild("HumanoidRootPart")
				or inst.PrimaryPart or inst:FindFirstChildOfClass("Part")
		end

		local function pdEspOff(part)
			local e = pd.Esps[part]
			if not e then return end
			pd.Esps[part] = nil
			if e.gui then pcall(function() e.gui:Destroy() end) end
			if e.box then pcall(function() e.box:Destroy() end) end
		end

		pdEspSweep = function()
			for part in pairs(pd.Esps) do pdEspOff(part) end
		end

		local function pdEspSet(part, kind, text)
			local col = ESP_COLOR[kind] or C.White
			local e = pd.Esps[part]
			if not e then
				local gui = new("BillboardGui", {          -- 名字：BillboardGui 没有数量上限
					Name = "O_X_ESP",
					Size = UDim2.new(0, 160, 0, 16),
					StudsOffset = Vector3.new(0, 2.4, 0),
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
					TextColor3 = col,
					TextStrokeTransparency = 0.3,
					Parent = gui,
				})
				local box = new("BoxHandleAdornment", {     -- 方框：跟着模型，隔墙可见
					Name = "O_X_BOX",
					Adornee = part,
					AlwaysOnTop = true,
					ZIndex = 5,
					Transparency = 0.55,
					Color3 = col,
					Size = ESP_BOX[kind] or Vector3.new(3, 5.5, 2.2),
					Parent = part,
				})
				pd.Esps[part] = { gui = gui, label = label, box = box, kind = kind }
				return
			end
			if e.kind ~= kind then
				e.kind = kind
				e.label.TextColor3 = col
				e.box.Color3 = col
				e.box.Size = ESP_BOX[kind] or Vector3.new(3, 5.5, 2.2)
			end
			if e.label.Text ~= text then e.label.Text = text end
		end

		local function pdRank(kind)
			if kind == "enemy" then return 1 end
			if kind == "civ" then return 2 end
			if kind == "ally" then return 3 end
			if kind == "loot" then return 4 end
			if kind == "spot" then return 6 end
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
			if pd.LootEsp or pd.AutoDone or pd.AllPrompts then
				-- 自动完成开着时把**所有**要跑的交互点都画出来（不然用户看着像"高亮没用"）：
				-- 战利品白色，其它交互点暗灰；装包点不画。
				for _, s in ipairs(pd.spots) do     -- pd.spots 扫描时已经算好挂 prompt 的部件；不再重算 loot
					local part = s.part or pdEspPart(s.p.Parent)
					if part and not s.dep then
						if s.loot then
							list[#list + 1] = { part = part, kind = "loot",
								name = s.p.Name, rng = pd.LootRange }
						elseif pd.AutoDone or pd.AllPrompts then
							list[#list + 1] = { part = part, kind = "spot",
								name = (s.part and s.part.Name) or s.p.Name, rng = pd.LootRange }
						end
					end
				end
			end
			table.sort(list, function(a, b) return pdRank(a.kind) < pdRank(b.kind) end)
			local n = 0
			for _, it in ipairs(list) do
				local rng = it.rng or pd.EspRange
				local dist = pdDist(it.part)
				if dist and dist <= rng then
					n = n + 1
					if n <= 80 then       -- ponytail: 一屏最多挂 80 个，再多没意义还掉帧
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
		-- ---------------- 场景原语 ----------------
		-- 执行器 API 一律"用的时候再查"：pdBuild 在 boot 就跑完了，而执行器的全局
		-- 可能晚一步才出现（测试环境就是这样）。查到就缓存，查不到下次接着试。
		local EXC = {}
		local function ex(name)
			local v = EXC[name]
			if v then return v end
			v = execFn(name)
			if v then EXC[name] = v end
			return v
		end

		local function pdChar()
			return LocalPlayer.Character
		end

		local function pdMoveTo(pos)
			if not pos then return end
			local root = getRoot()
			if not root then return end
			if pd.Tp then
				pcall(function() root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
				return
			end
			local hum = getHumanoid()
			local flat = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z)
			if flat.Magnitude > 0.2 then
				pcall(function() root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit) end)
			end
			if hum then
				-- 记下原始速度，关脚本时还原（不然会盖掉通用页那条滑块的设定）
				if not pd.walk0 then pcall(function() pd.walk0 = hum.WalkSpeed end) end
				pcall(function() hum.WalkSpeed = pd.MoveSpeed end)
				pcall(function() hum:MoveTo(pos) end)
			end
		end

		-- 挂着 prompt 的那个部件（战利品 prompt 常挂在 Hitbox 子件上，要往上找）
		local function pdPartOf(inst)
			local n, i = inst, 0
			while n and i < 6 do
				if n:IsA("BasePart") then return n end
				n, i = n.Parent, i + 1
			end
			return nil
		end

		-- 贴上去再按：直接把角色钉在交互点旁边并面向它。
		-- 抄 madmoney firePromptOnPart（feather v3.0:299-349）：贴住 → 等 0.2 秒让服务器认位置 → 再触发。
		-- 不贴的话，服务器那边玩家还在十米外，prompt 按了也白按 —— 这是"自动完成没反应"的头号原因。
		local function pdSnapTo(part)
			local root = getRoot()
			if not (root and part) then return false end
			local hum = getHumanoid()
			pd.frozen = true
			pd.snapAt = os.clock()
			pcall(function() root.CFrame = CFrame.new(part.Position + Vector3.new(0, 2.5, 0), part.Position) end)
			pcall(function()
				pd.snapOld = root.Anchored            -- 还原成原来的值，别擅自解锁（原来就是 true 就别动）
				root.Anchored = true
			end)
			if hum then
				pcall(function()
					pd.standOld = hum.PlatformStand   -- 记住原来的 PlatformStand，解钉时还原（不然会盖掉飞行/缓降的状态）
					hum.PlatformStand = true
				end)
			end
			return true
		end

		-- 一定要还原：钉住的时候角色的移动/触屏摇杆全废，漏一次就变成"UI 断触"（手机上手感极差）
		local function pdUnsnap()
			pd.frozen = false
			pd.snapAt = nil
			local root, hum = getRoot(), getHumanoid()
			if root then pcall(function() root.Anchored = pd.snapOld == true end) end
			pd.snapOld = nil
			if hum and pd.standOld ~= nil then
				pcall(function() hum.PlatformStand = pd.standOld end)
			elseif hum then
				pcall(function() hum.PlatformStand = false end)
			end
			pd.standOld = nil
		end

		-- 交互配方（三家合并，都是实机跑通的脚本里的原文做法）：
		--  · autowin_shadowraid.lua:22-35  —— InputHoldBegin → 等 HoldDuration → InputHoldEnd
		--  · madmoney firePromptOnPart:299-349 —— MaxActivationDistance=9999 / Enabled=true / 贴脸 / fireproximityprompt
		--  · XXMZ beta:1004-1035（instant interact）—— HoldDuration 直接改 0，长按变瞬发
		-- 成功信号 = ProximityPromptService.PromptTriggered（RealNotorietyLib.Lib.Interact 就是这么判的）
		local function pdInteract(p, part)
			if not p or not p.Parent then return false end
			if part and not part.Parent then part = nil end
			-- 保存原值（交互完还原，不然关掉自动完成后手动互动也废了）
			local origDist, origHold, origLOS, origEnabled
			pcall(function()
				origDist = p.MaxActivationDistance
				origHold = p.HoldDuration
				origLOS = p.RequiresLineOfSight
				origEnabled = p.Enabled
			end)
			pcall(function() p.MaxActivationDistance = 9999 end)
			pcall(function() p.Enabled = true end)
			pcall(function() p.RequiresLineOfSight = false end)
			local hold = tonumber(p.HoldDuration) or 0
			-- 有的 prompt 写死 20 秒（假的，实际服务器只看 CompleteInteraction）
			if hold > 0 then pcall(function() p.HoldDuration = 0 end) end
			if part then
				pdSnapTo(part)
				task.wait(0.25)                                  -- let server register position
			end
			pd.hit = nil
			pdStatus.Text = "按 prompt... " .. tostring(p.Name)
			local fx = ex("fireproximityprompt")
			if fx then pcall(fx, p) end
			pcall(function() p:InputHoldBegin() end)
			task.wait(math.clamp(hold, 0.05, 2) + 0.35)
			pcall(function() p:InputHoldEnd() end)
			-- 兜底一：执行器没有 fireproximityprompt 时再补一发
			if not pd.hit and p.Parent and fx then
				pcall(fx, p)
				task.wait(0.15)
			end
			-- 兜底二：自己发两个远程（RealNotorietyLib 的 Lib.Interact，10 个脚本都用这条）
			-- 传的是 prompt 本身（不是 item），服务器按 InteractList[prompt.Name].timer 计时
			pdStatus.Text = "发远程... " .. tostring(p.Name)
			local fired = false
			local startR, compR = pdRemote("StartInteraction"), pdRemote("CompleteInteraction")
			if startR then
				fired = pcall(function() startR:FireServer(p) end)
				task.wait(0.12)
				if compR then pcall(function() compR:FireServer(p) end) end
				task.wait(0.2)
			end
			-- 🔴 v2.0.1：解钉不再看 part 在不在 —— 钉住时角色是 Anchored + PlatformStand，
			--    漏一次解钉，手机上就是"摇杆/触屏全废"（用户报的断触）。
			pdUnsnap()
			task.wait(0.12)
			-- 还原 prompt 属性（关掉自动完成后手动互动还得用）
			pcall(function()
				if origDist then p.MaxActivationDistance = origDist end
				if origHold then p.HoldDuration = origHold end
				if origLOS ~= nil then p.RequiresLineOfSight = origLOS end
				if origEnabled ~= nil then p.Enabled = origEnabled end
			end)
			-- 返回值：confirmed（真成了） / soft（远程发出去了但没等到确认）
			--   ① 收到 PromptTriggered（本地按下去那条路径）
			--   ② prompt 没了 / 被关掉（服务器处理完就收走）
			--   ③ soft：劫案里战利品被拿走后 prompt 通常还留在原地，
			--      老代码只看 ①② 就会判成"交互失败"，把目标永久拉黑 ——
			--      实机症状就是"跑过去 → 交互失败 → 再跑过去 → 又失败"，一件都拿不到。
			local confirmed = (pd.hit ~= nil) or (p.Parent == nil) or (p.Enabled == false)
			return confirmed, fired
		end

		-- 手上/背包里的工具名（电锯、撬棍、卡这类都要靠名字丢出去）
		local function pdToolNames()
			local out, seen = {}, {}
			local holders = { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }
			for _, holder in ipairs(holders) do
				if holder then
					local ok, kids = pcall(function() return holder:GetChildren() end)
					for _, t in ipairs(ok and kids or {}) do
						if t:IsA("Tool") and t.Name ~= "Mask" and not seen[t.Name] then
							seen[t.Name] = true
							out[#out + 1] = t.Name
						end
					end
				end
			end
			return out
		end

		-- Damage / HitObject 这两个远程要 RemoteKey（DarkHub 从 Bullet 的回调里挖 upvalue）
		local function pdKey()
			if pd.key then return pd.key end      -- 失败不缓存：执行器 API 可能晚一步才就绪
			local gcon, gupv = ex("getconnections"), ex("getupvalue")
			if not (gcon and gupv) then return nil end
			pcall(function()
				local pack = pdPack()
				local bullet = pack and pack:FindFirstChild("Assets", true)
				bullet = bullet and bullet:FindFirstChild("Remotes", true)
				bullet = bullet and bullet:FindFirstChild("Bullet")
				if not bullet then return end
				local conns = gcon(bullet.OnClientEvent)
				local fn = conns and conns[1] and conns[1].Function
				if not fn then return end
				local up3 = gupv(fn, 3)
				local newFn = type(up3) == "table" and up3.new or nil
				if not newFn then return end
				local k = gupv(newFn, 18)
				if type(k) == "number" then pd.key = k end
			end)
			return pd.key or nil
		end

		-- 破摄像头：HitObject(RemoteKey, 摄像头部件, ...) 那套
		local function pdCameras()
			local pack = pdPack()
			local folder = workspace:FindFirstChild("Cameras")
			if not folder then return 0 end
			local key = pdKey()
			local hit = pdRemote("HitObject")
			if not key or not hit then return -1 end
			local n = 0
			for _, v in ipairs(folder:GetChildren()) do
				local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("MeshPart", true)
					or v:FindFirstChildWhichIsA("BasePart", true)
				if part then
					pcall(function()
						hit:FireServer(key, part, false, nil, nil,
							Vector3.new(3.02631664, 2.68741488, 3.29028654))
					end)
					n = n + 1
				end
			end
			return n
		end

		-- Yell 平民：把所有平民赶过去（brickmane 那套）
		local function pdYellNow()
			local y = pdRemote("PlayerYell")
			if not y then return false end
			local folder
			for _, n in ipairs(CIV_FOLDERS) do
				folder = folder or workspace:FindFirstChild(n)
			end
			if not folder then return false end
			local ok, list = pcall(function() return folder:GetChildren() end)
			if not ok or type(list) ~= "table" then return false end
			pcall(function() y:FireServer(list) end)
			return true
		end

		-- 自动准备（大厅里那个 Ready）
		local function pdReadyNow()
			local r = pdRemote("PlayerReady")
			if not r then return false end
			pcall(function() r:FireServer("Class 1", true) end)
			return true
		end

		-- 全灭警察：真脚本的做法（rblxploit API :135-138）是把自己贴到守卫身上再
		-- repeat MeleeDamage:FireServer(guard, 999, 100) until dead —— MeleeDamage
		-- 服务端只查距离，所以贴脸必中，不需要 RemoteKey。一次全打会卡帧（每发都要挪 CFrame），
		-- 改成队列：心跳里每 0.12 秒处理当前目标、每步补两发，1.5 秒还没死就换下一个。
		local function pdKillFire(t)
			local hum, model = t.hum, t.model
			if not (hum and hum.Parent and model and model.Parent and hum.Health > 0) then return end
			local root = hum.RootPart or model:FindFirstChild("HumanoidRootPart")
			local mine = getRoot()
			if not mine then
				-- 角色没加载完（刚复活/传送中），等一帧再试
				task.wait(0.2)
				mine = getRoot()
			end
			if root and mine then
				pcall(function() mine.CFrame = CFrame.new(root.Position, root.Position + root.CFrame.LookVector) end)
			end
			local melee = pdRemote("MeleeDamage")
			if melee then
				pcall(function()
					melee:FireServer(model, 999, 100)
					melee:FireServer(model, 999, 100)
				end)
			end
			-- 有 RemoteKey 就再补一发 Damage（不用贴脸那条路）
			local dmg, key = pdRemote("Damage"), pdKey()
			if dmg and key then
				pcall(function()
					dmg:FireServer("Damage", key, hum, math.huge, root, "Knife",
						root and root.CFrame.LookVector or Vector3.new(0, 0, 1))
				end)
			end
		end

		-- 关禁闭（用户点名要的功能）：近战糊脸两秒都杀不掉的警卫 = 服务端根本不认
		-- 这个远程，继续换着目标贴就是"在警卫附近窜来窜去"。改成整批扔到远处，
		-- 心跳每 0.4 秒钉住一次（不是它网络所有权的主人挪不动就是挪不动，无害）。
		local function pdVoidPut(model)
			if pd.voidSet[model] then return end
			local mine = getRoot()
			if not mine then return end
			if not pd.voidPos then
				pd.voidPos = mine.Position + Vector3.new(1500, 400, 1500)
			end
			pd.voidN = pd.voidN + 1
			pd.voidSet[model] = pd.voidN
			if not pd.voidWarn then
				pd.voidWarn = true
				notify(L("pdVoidHint"), C.Amber)
			end
		end

		local function pdVoidPin(now)
			if not (pd.KillAll and pd.voidPos) then return end
			if now - pd.pinAt < 0.4 then return end
			pd.pinAt = now
			for model, i in pairs(pd.voidSet) do
				local keep = false
				pcall(function()
					local hrp = model:FindFirstChild("HumanoidRootPart")
					local hum = model:FindFirstChildOfClass("Humanoid")
					if hrp and (not hum or hum.Health > 0) then
						keep = true
						hrp.CFrame = CFrame.new(pd.voidPos
							+ Vector3.new((i % 5) * 6, 0, math.floor(i / 5) * 6))
					end
				end)
				if not keep then pd.voidSet[model] = nil end
			end
		end

		local function pdKillStep(now)
			if not pdRemote("MeleeDamage") and not pdRemote("Damage") then
				if not pd.killWarned then pd.killWarned = true; notify(L("pdKillFail"), C.Amber) end
				return
			end
			local t = pd.killTarget
			if t and not (t.hum and t.hum.Parent and t.hum.Health > 0) then
				pd.killN = (pd.killN or 0) + 1
				t, pd.killTarget = nil, nil
			end
			if not t then
				if not pd.killList or #pd.killList == 0 then
					if (pd.killN or 0) > 0 then
						notify(string.format(L("pdKillDone"), pd.killN), C.Green)
						pd.killN = 0
					end
					pdScan()
					local q = {}
					for _, it in ipairs(pd.Items) do
						if it.kind == "enemy" and it.hum and it.hum.Health > 0
							and not pd.voidSet[it.model] then q[#q + 1] = it end
					end
					pd.killList = q
					if #q == 0 then
						if not pd.killWarned then pd.killWarned = true; notify(L("pdNoNpc"), C.Amber) end
						return
					end
					pd.killWarned = nil
				end
				t = table.remove(pd.killList, 1)
				pd.killTarget, pd.killAt2 = t, now
			end
			if not t then return end
			pdKillFire(t)
			if now - (pd.killAt2 or now) > 1.5 then
				if t.hum and t.hum.Health <= 0 then
					pd.killN = (pd.killN or 0) + 1
				else
					-- 贴脸两轮都杀不掉就不再碰它（窜来窜去的老毛病），扔小黑屋
					local miss = (pd.killMiss[t.model] or 0) + 1
					pd.killMiss[t.model] = miss
					if miss >= 2 then pdVoidPut(t.model) end
				end
				pd.killTarget = nil
			end
		end

		-- 无限弹药：拦 Bullet 的 FireServer，把 UseAmmo 改成 false（DarkHub 那套）
		pdSetAmmo = function(on)
			local grm, sro = ex("getrawmetatable"), ex("setreadonly")
			if not on then
				if pd.ammoHooked and grm and sro then
					pcall(function()
						local mt = grm(game)
						sro(mt, false)
						mt.__namecall = pd.ammoOld
						sro(mt, true)
					end)
				end
				pd.ammoHooked, pd.ammoOld = false, nil
				return true
			end
			if pd.ammoHooked then return true end
			local ncc = ex("newcclosure")
			local gname = ex("getnamecallmethod")
			if not (grm and sro and ncc and gname) then return false end
			pd.ammoHooked = pcall(function()
				local mt = grm(game)
				pd.ammoOld = mt.__namecall
				sro(mt, false)
				mt.__namecall = ncc(function(self, ...)
					if gname() == "FireServer" and tostring(self) == "Bullet" then
						local args = { ... }
						if type(args[1]) == "table" then pcall(function() args[1].UseAmmo = false end) end
						return pd.ammoOld(self, table.unpack(args))
					end
					return pd.ammoOld(self, ...)
				end)
				sro(mt, true)
			end)
			return pd.ammoHooked
		end

		-- 无限弹药的兜底：钩子挂不上（没有 getrawmetatable）就直接把弹药数值写大
		local function pdAmmoRefill()
			local char = pdChar()
			if not char then return false end
			local any = false
			for _, nm in ipairs({ "PrimaryAmmo", "SecondaryAmmo" }) do
				local v = char:FindFirstChild(nm)
				if v and type(v.Value) == "number" and v.Value < 1e9 then
					any = true
					pcall(function() v.Value = 9e10 end)
				end
			end
			return any
		end

		-- ---------------- 自瞄 ----------------
		-- 手机端手指按住屏幕时不要抢相机：写 Camera.CFrame 会让玩家的触屏拖视角完全没反应，
		-- 看起来就是"UI 断触"。命中交给静默自瞄（改子弹方向），视角让玩家自己转。
		local function pdTouching()
			if not UserInputService.TouchEnabled then return false end
			local ok, list = pcall(function() return UserInputService:GetTouches() end)
			return ok and type(list) == "table" and #list > 0
		end

		local function pdAimPos(model)
			if pd.Head then
				local head = model:FindFirstChild("Head")
				if head then return head.Position end
			end
			local root = model:FindFirstChild("HumanoidRootPart")
			if root then return root.Position end
			return pdPos(model)
		end

		-- 能不能看见（隔着墙就别锁了；Walls 开关一开就无视）
		local function pdVisible(cam, model)
			if pd.Walls then return true end
			local ok, vis = pcall(function()
				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Exclude
				rp.FilterDescendantsInstances = { LocalPlayer.Character, model }
				local from = cam.CFrame.Position
				local to = pdAimPos(model)
				if not to then return true end
				return workspace:Raycast(from, to - from, rp) == nil
			end)
			if not ok then return true end
			return vis
		end

		local function pdPick(cam)
			local origin = cam.CFrame.Position
			local look = cam.CFrame.LookVector
			local best, bscore, bang
			for _, t in ipairs(pd.Items) do
				local use = (t.kind == "enemy")
					or (not pd.OnlyEnemy and t.kind ~= "me" and t.kind ~= "ally")
				if use and t.hum and t.hum.Health > 0 then
					local pos = pdAimPos(t.model)
					if pos then
						local d = (pos - origin).Magnitude
						local dir = d > 0.01 and (pos - origin).Unit or look
						local ang = math.deg(math.acos(math.clamp(look:Dot(dir), -1, 1)))
						-- v1.9.7：不再用 pdVisible 做硬门（手机端相机贴墙时 raycast 必败）。
						-- 可见性只做加分项：看得见优先，看不见也照样锁（静默自瞄改子弹方向绕墙打）。
						if d <= pd.Range then
							local score = ang
							if pd.Priority == "near" then score = d
							elseif pd.Priority == "low" then score = t.hum.Health end
							if ang > math.max(pd.Fov * 0.5, 8) then score = score + 100000 end
							-- 🔴 v2.0.1：可见性射线只对"有机会成为最佳目标"的那个做。
							--    之前对每个 NPC 每帧都 raycast（20 个目标 = 每秒 1200 次），
							--    实机直接掉帧，手感就是"自瞄卡卡的"。
							if not bscore or score < bscore then
								if not pdVisible(cam, t.model) then score = score + 5000 end
								if not bscore or score < bscore then best, bscore, bang = t, score, ang end
							end
						end
					end
				end
			end
			return best, bang
		end

		-- 自瞄落点（视觉锁）。真脚本的原文做法就是每帧直接写 Camera.CFrame：
		--   XXMZ beta:273-289 aimAtTarget：
		--     Camera.CFrame = CFrame.new(cameraPos, targetPos)            -- 或者 Lerp(..., sensitivity/100)
		-- 上一版推 mousemoverel 的做法在实机里没用，已删。
		-- 🔴 关键是"什么时候写"：必须排在游戏自带相机脚本后面，所以挂在 Camera 优先级的下一步
		--    （RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, fn)），
		--    写早了会被相机脚本这一帧盖掉 —— 这才是"只转视角/看不出效果"的根因。
		local function pdApplyAim(cam, pos)
			local camPos = cam.CFrame.Position
			local ok = pcall(function()
				if pd.Follow < 0.999 then
					cam.CFrame = cam.CFrame:Lerp(CFrame.new(camPos, pos), math.clamp(pd.Follow, 0.05, 1))
				else
					cam.CFrame = CFrame.new(camPos, pos)
				end
			end)
			if ok then pd.camOk = true end
		end

		local function pdFire()
			local char = LocalPlayer.Character
			local tool = char and char:FindFirstChildWhichIsA("Tool")
			if tool and tool.Activate then pcall(function() tool:Activate() end) end
			local m1 = ex("mouse1click")
			if m1 then pcall(m1) end
			local vim = ex("VirtualInputManager") or game:GetService("VirtualInputManager")
			if vim then
				pcall(function() vim:SendMouseButtonEvent(0, 0, 0, true, game, 1) end)
				pcall(function() vim:SendMouseButtonEvent(0, 0, 0, false, game, 1) end)
			end
		end

		-- ---------------- 静默自瞄：让子弹本身拐弯 ----------------
		-- 原文出处：ltseverydayyou 的 Notoriety.luau（199KB，61 处 silent aim）
		--   :3561-3591 getLocalGunsEnvironment —— getsenv(PlayerScripts.SPS_Package.LocalGuns)
		--   :2965-2987 getProjectileTableFromShoot —— getupvalue(shoot, 28)，不是 table 就
		--               getupvalue(getupvalue(shoot, 2), 28)；判据 type(rawget(t,"new"))=="function"
		--   :3030-3096 包装体的核心就是把 Data.TargetPosition / Data.Direction 改成目标
		-- 这条路子不碰鼠标也不碰相机：武器系统自己算出来的子弹轨迹被我们改了，所以"必中"。
		local function pdGunsEnv()
			local ok, env = pcall(function()
				local ps = LocalPlayer:FindFirstChild("PlayerScripts")
				local sps = ps and ps:FindFirstChild("SPS_Package")
				local guns = sps and sps:FindFirstChild("LocalGuns")
				if not guns then return nil end
				local gs = ex("getsenv")
				if gs then return gs(guns) end
				local renv = ex("getrenv")
				if renv then
					local r = renv()
					if type(r) == "table" and r.getsenv then return r.getsenv(guns) end
				end
				return nil
			end)
			if ok and type(env) == "table" then return env end
			return nil
		end

		-- 武器状态表 = 带 shoot 函数的 table。先在同一环境里递归找，找不到再用 jqmesc 那招翻 getgc。
		local function pdGunStates()
			local out, seen, nodes = {}, {}, 0
			local env = pdGunsEnv()
			local function scan(v, depth)
				if type(v) ~= "table" or seen[v] or depth > 6 or nodes > 4000 then return end
				seen[v], nodes = true, nodes + 1
				if type(rawget(v, "shoot")) == "function" then
					out[#out + 1] = v
					return
				end
				for _, x in pairs(v) do scan(x, depth + 1) end
			end
			if env then pcall(scan, env, 0) end
			-- getgc 很贵（大游戏能卡 100ms+），没找到东西时也最多 8 秒试一次
			if #out == 0 and (not pd.gcAt or os.clock() - pd.gcAt > 8) then
				pd.gcAt = os.clock()
				local gc = ex("getgc")
				if gc then
					local ok, list = pcall(gc, true)
					for _, v in ipairs(ok and list or {}) do
						if type(v) == "table" and type(rawget(v, "shoot")) == "function" then
							out[#out + 1] = v
						end
					end
				end
			end
			pd.gunN = #out
			return out
		end

		-- v1.9.7：暴力搜全部 upvalue（不再硬编码 28），加 getgc 兜底
		local function pdProjectileTable(shoot)
			local g = ex("getupvalue")
			if not g or type(shoot) ~= "function" then return nil end
			local function ok(t)
				return type(t) == "table" and type(rawget(t, "new")) == "function"
			end
			-- 先试 28（参考脚本的标准位置）
			local o, t = pcall(g, shoot, 28)
			if o and ok(t) then return t end
			-- 暴力搜全部 upvalue（最多 80 个）
			for i = 1, 80 do
				local ov, v = pcall(g, shoot, i)
				if ov and ok(v) then return v end
				if ov and type(v) == "function" then
					for j = 1, 80 do
						local ov2, v2 = pcall(g, v, j)
						if ov2 and ok(v2) then return v2 end
						if not ov2 then break end
					end
				end
				if not ov then break end
			end
			-- getgc 兜底：搜所有 table 找带 .new 函数且名字像 Projectile/Bullet 的
			local gc = ex("getgc")
			if gc then
				local ok2, list = pcall(gc)
				if ok2 then
					for _, v in ipairs(list or {}) do
						if ok(v) then
							local n = rawget(v, "__type") or rawget(v, "name") or ""
							if type(n) == "string" and (n:find("roject") or n:find("ullet") or n:find("hot")) then
								return v
							end
						end
					end
				end
			end
			return nil
		end

		pdSilent = function(on)
			if not on then
				for tbl, orig in pairs(pd.silentOrig) do
					pcall(function() rawset(tbl, "new", orig) end)
				end
				pd.silentOrig = {}
				pd.silent, pd.silentN = false, 0
				return false
			end
			local patched = 0
			for _, st in ipairs(pdGunStates()) do
				local shoot = rawget(st, "shoot")
				-- 每个 shoot 函数只反查一次子弹表（暴力遍历 upvalue 很贵，别每 2 秒重来一遍）
				local tbl = pd.projCache[shoot]
				if tbl == nil then
					tbl = pdProjectileTable(shoot) or false
					pd.projCache[shoot] = tbl
				end
				local orig = tbl and rawget(tbl, "new")
				if tbl and type(orig) == "function" and not pd.silentOrig[tbl] then
					pd.silentOrig[tbl] = orig
					rawset(tbl, "new", function(Data, ...)
						pcall(function()
							local tgt = pd.locked
							if tgt and type(Data) == "table" and Data.Player == LocalPlayer
								and typeof(Data.StartPosition) == "Vector3" then
								local d = tgt - Data.StartPosition
								if d.Magnitude > 0.001 then
									Data.TargetPosition = tgt
									Data.Direction = d.Unit
								end
							end
						end)
						return orig(Data, ...)
					end)
					patched = patched + 1
				end
			end
			pd.silentN = patched
			pd.silent = patched > 0

			-- v1.9.7：__namecall 兜底（Rivals 做法）—— 拦 Bullet:FireServer 改方向。
			-- 执行器不支持 hookmetamethod 就跳过，静默自瞄只靠 projectileTable 包装。
			if not pd._ncHooked then
				local hmm = ex("hookmetamethod")
				if hmm then
					pcall(function()
						local oldNC
						oldNC = hmm(game, "__namecall", function(self, ...)
							local method = getnamecallmethod()
							local args = {...}
							if method == "FireServer" and tostring(self) == "Bullet"
								and pd.locked and pd.silent then
								pcall(function()
									if type(args[1]) == "table" and typeof(args[1].StartPosition) == "Vector3" then
										local d = pd.locked - args[1].StartPosition
										if d.Magnitude > 0.001 then
											args[1].TargetPosition = pd.locked
											args[1].Direction = d.Unit
										end
									end
								end)
							end
							return oldNC(self, unpack(args))
						end)
						pd._ncHooked = true
					end)
				end
			end

			return pd.silent or pd._ncHooked == true
		end

		-- ---------------- 潜入：全图自动完成 ----------------
		-- 顺序：扫全部交互点 →（战利品在集装箱里就先开箱）→ 过去 → 交互 → 拿包 → 满了去撤离点丢包 → 循环
		-- 复杂地图里"开箱/放电锯/刷卡"本身就是别的 ProximityPrompt，所以统一按「旁边的交互点先按一遍」处理。
		-- pd.spots 由 pdScan 建好：{ p = prompt, part = 挂 prompt 的部件, pos = 位置, loot = 是不是战利品 }
		-- 这里只做"挑哪个"，不再自己去解析部件（解析一次就够，省得每轮重走一遍祖先链）。
		local function pdNearbySpot(pos, limit, wantLoot)
			local best, bd
			for _, s in ipairs(pd.spots) do
				if s.pos and s.loot == wantLoot and not s.dep
					and not pd.Taken[s.p] and not pd.Bad[s.p] then
					local d = (s.pos - pos).Magnitude
					if d <= limit and (not bd or d < bd) then best, bd = s, d end
				end
			end
			return best
		end

		local function pdRunSpot(s, allowEquip)
			if not (s and s.p and s.p.Parent) then return false, "gone" end
			local pos = s.pos
			if not pos then
				pd.Bad[s.p] = true
				return false, "nopos"
			end
			pdStatus.Text = "移动中... " .. tostring((s.part and s.part.Name) or "?")
			pdMoveTo(pos)
			pdStatus.Text = "交互中... " .. tostring((s.part and s.part.Name) or "?")
			local done, soft = pdInteract(s.p, s.part or pdPartOf(s.p))
			if done then
				pd.Taken[s.p] = true
				return true
			end
			-- 还按不动：八成卡在"要装备"上（撬棍/电锯），把手里的工具逐个丢上去试试
			if allowEquip then
				local place = pdRemote("PlaceEquipment")
				if place then
					for _, name in ipairs(pdToolNames()) do
						pcall(function() place:FireServer(name, CFrame.new(pos), s.part or s.p.Parent) end)
						task.wait(1)
						local d2, s2 = pdInteract(s.p, s.part or pdPartOf(s.p))
						if d2 then
							pd.Taken[s.p] = true
							return true, "equip:" .. name
						end
						soft = soft or s2
					end
				end
			end
			-- 远程确实发出去了、只是没等到确认：当"试过了"处理，别永久拉黑、也别刷"交互失败"
			if soft then
				pd.Taken[s.p] = true
				return true, "soft"
			end
			pd.Bad[s.p] = true
			notify("交互失败: " .. tostring((s.part and s.part.Name) or "?"), C.Amber)
			return false, "fail"
		end

		-- 挑下一个目标：战利品优先而且**不管多远都去**（用户报过"远处的战利品不动"），
		-- 非战利品（箱盖/门/电锯架）只有开了"所有交互点"才当目标，权重压到最低。
		local function pdPickSpot()
			local root = getRoot()
			if not root then return nil end
			local origin = root.Position
			local best, bs
			for _, s in ipairs(pd.spots) do
				if s.pos and not s.dep and not pd.Taken[s.p] and not pd.Bad[s.p] then
					if s.loot or pd.AllPrompts then
						local score = (s.pos - origin).Magnitude + (s.loot and 0 or 5000)
						if not bs or score < bs then best, bs = s, score end
					end
				end
			end
			return best
		end

		-- 手上几个包。权威来源是 GUI：MissionEquipment["Loot Bag"].txtamt.Text
		-- （空串 = 1，没有 Loot Bag 这个对象 = 0）—— rapi:225-236。GUI 读不到才用自己数的。
		local function pdBagsUI()
			local n
			pcall(function()
				local sg = LocalPlayer.PlayerGui:FindFirstChild("SG_Package")
				local main = sg and sg:FindFirstChild("MainGui")
				local ps = main and main:FindFirstChild("PlayerStats")
				local lps = ps and ps:FindFirstChild("LocalPlayerStats")
				local info = lps and lps:FindFirstChild("info_items")
				local eq = info and info:FindFirstChild("MissionEquipment")
				if not eq then return end
				local bag = eq:FindFirstChild("Loot Bag")
				if not bag then
					n = 0
					return
				end
				local amt = bag:FindFirstChild("txtamt")
				local t = amt and amt.Text
				n = (t == nil or t == "") and 1 or (tonumber(t) or 1)
			end)
			return n
		end

		local function pdBags()
			local ui = pdBagsUI()
			if type(ui) == "number" then pd.carry = ui end
			return pd.carry or 0
		end

		pdVan = function()
			local area = pdChild(workspace, "BagSecuredArea", "SecuredArea", "EscapeArea")
			if not area then return nil end
			return area:FindFirstChild("FloorPart") or area.PrimaryPart
				or area:FindFirstChildWhichIsA("BasePart", true)
		end

		-- 去撤离点把包丢出去。madmoney:369-374 也是先贴到 van 再 ThrowBag（参数是方向向量）；
		-- autowin_shadowraid.lua 则直接用 BagSecuredArea.FloorPart。
		local function pdDumpBags()
			local van = pdVan()
			local throw = pdRemote("ThrowBag")
			local n = math.max(1, pdBags())
			if not van then
				pdStatus.Text = L("pdNoVan")
				task.wait(1)
				return false
			end
			if pd.dumpAt and os.clock() - pd.dumpAt < 2 then
				task.wait(2)                                      -- 服务器还没把包收走，别刷屏
				return false
			end
			pd.dumpAt = os.clock()
			pdMoveTo(van.Position)
			task.wait(0.35)
			pdSnapTo(van)                                        -- 贴上去再丢，服务器才认
			task.wait(0.25)
			pdStatus.Text = string.format(L("pdThrow"), tostring(n))
			if throw then
				for _ = 1, n do
					pcall(function() throw:FireServer(Vector3.new(0, 0, 0)) end)
					task.wait(0.35)
				end
			end
			pdUnsnap()
			pd.carry = 0
			task.wait(0.5)
			return true
		end

		local done = 0

		-- 一步：扫 → 满了就去丢 → 挑目标 →（箱子里的话先开箱）→ 贴上去按
		local function pdAutoDoneStep()
			-- 用户原话："先把警卫给黑屋 然后再自动完成"
			-- 如果 KillAll 开着且还有活警卫没处理完，先等它跑完
			if pd.KillAll and pd.killList and #pd.killList > 0 then
				pdStatus.Text = "等警卫清完..."
				task.wait(0.5)
				return
			end
			pdScan()
			if pd.Cameras then pdCameras() end
			if pdBags() >= pd.CarryMax then
				pdDumpBags()
				return
			end
			local s = pdPickSpot()
			if not s then
				-- 没目标：只有手上真有包才去车边丢包。空手也传送过去 = 用户报的
				-- "一直传送到车上 也没拿战利品"（装包点被当战利品的循环）。
				if pdBags() > 0 then
					pdDumpBags()
					return
				end
				if done == 0 then
					pdStatus.Text = (pd.lootN == 0) and L("pdNoLoot") or L("pdNothing")
					if not pd.warned then
						pd.warned = true
						notify(pdStatus.Text, C.Amber)
					end
				else
					pdStatus.Text = string.format(L("pdAllDone"), tostring(done))
				end
				task.wait(1.5)
				-- 每轮重新扫一遍：地图会刷新新目标（开箱后里面才有战利品）
				for p in pairs(pd.Taken) do pd.Taken[p] = nil end
				for p in pairs(pd.Bad) do pd.Bad[p] = nil end
				task.wait(1)
				return
			end
			if s.loot then
				-- 战利品在箱子 / 保险柜 / 集装箱里：先把旁边那个交互点按一遍
				-- （开箱、撬棍、放电锯、刷卡在游戏里都只是别的 ProximityPrompt，所以统一处理）
				local box = pdNearbySpot(s.pos, 30, false)
				if box then
					pdStatus.Text = "发现箱子: " .. tostring((box.part and box.part.Name) or "?") .. " → 去开"
					pdRunSpot(box, true)                        -- allowEquip=true：开箱也能放撬棍/电锯/卡
					pdScan()
					s = pdPickSpot() or s
				else
					pdStatus.Text = "战利品无箱子: " .. tostring((s.part and s.part.Name) or "?")
				end
			end
			pdStatus.Text = string.format(L("pdGoing"), tostring((s.part and s.part.Name) or "?"))
			local ok = pdRunSpot(s, s.loot)
			if ok then
				done = done + 1
				pd.warned = false
				local bags = pdBags()
				if s.loot and pdBagsUI() == nil then
					pd.carry = bags + 1                        -- 没有 GUI 的场合（测试/别的版本）自己数
					bags = pd.carry
				end
				pdStatus.Text = string.format(L("pdStep"), tostring(done), tostring(bags))
				if bags >= pd.CarryMax then
					pdDumpBags()
					pdStatus.Text = string.format(L("pdStep"), tostring(done), tostring(pdBags()))
				end
			end
			task.wait(0.15)
		end

		pdAutoDoneLoop = function()
			local me = pd.run + 1
			pd.run = me
			done = 0
			while pd.AutoDone and not SHUTDOWN and pd.run == me do
				local ok, err = pcall(pdAutoDoneStep)
				if not ok then
					-- 出错不能把循环打断（断了就是"点了没反应"），写进诊断行接着跑
					pd.err, pd.errAt = tostring(err), os.clock()
					pdStatus.Text = string.format(L("pdErrFmt"), tostring(err):sub(1, 60))
					task.wait(1)
				end
				task.wait(0.1)
			end
			pdStatus.Text = ""
		end

		-- ---------------- 大厅：自动开图刷（notoriety-autowin 那套） ----------------
		pdLobbyFarm = function()
			local make, start = pdRemote("MakeLobby"), pdRemote("StartGame")
			local rs = game:GetService("ReplicatedStorage")
			local lobbies = rs:FindFirstChild("Lobbies")
			if not (make and start and lobbies) then
				notify(L("pdLobbyFail"), C.Red)
				return
			end
			local leave = pdRemote("LeaveLobby")
			local mine = lobbies:FindFirstChild(LocalPlayer.DisplayName)
			if mine and leave then pcall(function() leave:FireServer(mine) end) end
			task.wait(0.3)
			local queue = execFn("queueonteleport") or execFn("queue_on_teleport")
			if not queue then
				-- 有的执行器只在 syn.queue_on_teleport 上暴露排队（跟主面板 joinPlace 一条链）
				pcall(function()
					local syn = rawget(_G, "syn")
					if type(syn) == "table" and isCallable(syn.queue_on_teleport) then
						queue = syn.queue_on_teleport
					end
				end)
			end
			if queue and CONFIG.RawUrl then
				pcall(queue, string.format('loadstring(game:HttpGet("%s?t=" .. os.time()))()', CONFIG.RawUrl))
			end
			-- ponytail: 地图/难度写死 Shadow Raid + Nightmare（autowin 的默认组合），要换改这两个字符串
			pcall(function()
				make:InvokeServer("Shadow Raid", "Nightmare", 1, "PUBLIC", "Stealth",
					false, false, 1, false, false, {})
			end)
			task.wait(0.25)
			mine = lobbies:FindFirstChild(LocalPlayer.DisplayName)
			if mine then pcall(function() start:FireServer(mine) end) end
			notify(L("pdLobbyOn"), C.Green)
		end

		-- 打完自动回大厅（等结算界面出来再传，不然会被判中途退出）
		local function pdResultsOpen()
			local ok, res = pcall(function()
				local sg = LocalPlayer.PlayerGui:FindFirstChild("SG_Package")
				local main = sg and sg:FindFirstChild("MainGui")
				local f = main and main:FindFirstChild("frame_heistResults")
				return f ~= nil and f.Visible == true
			end)
			return ok and res == true
		end

		local pdReturnAt = 0
		local function pdLobbyReturnTick()
			if not pd.LobbyBack then pdReturnAt = 0 return end
			if not pdResultsOpen() then pdReturnAt = 0 return end
			if pdReturnAt == 0 then
				pdReturnAt = os.clock()
				notify(L("pdBackSoon"), C.Green)
				return
			end
			if os.clock() - pdReturnAt >= 3 then
				pdReturnAt = 0
				pd.LobbyBack = false
				pd.AutoDone = false
				pd.run = pd.run + 1
				joinPlace(PD.Place, L("srvHeist"))
			end
		end

		-- ---------------- 自瞄绑定 ----------------
		-- 关键在"什么时候写 Camera.CFrame"：游戏自带的相机脚本也在这条链上跑，
		-- 我们得排在它后面（Camera 优先级的下一步），否则这一帧写完就被它盖回去。
		-- 没有 BindToRenderStep 的执行器退化成 RenderStepped（XXMZ beta 就是纯 RenderStepped，也能用）。
		local pdAimConn = nil
		local pdAimFn = function()
			if SHUTDOWN or not (pd.Aim or pd.Fire) then return end
			pd.aimFnCalls = (pd.aimFnCalls or 0) + 1
			local cam = workspace.CurrentCamera
			if not cam then return end
			local target, ang = pdPick(cam)
			if not target then
				pd.locked = nil
				pd.ang = nil
				pd.aimNoTarget = (pd.aimNoTarget or 0) + 1
				return
			end
			local pos = pdAimPos(target.model)
			if not pos then
				pd.locked = nil
				pd.aimNoPos = (pd.aimNoPos or 0) + 1
				return
			end
			pd.locked = pos                                       -- 静默自瞄改子弹方向用的就是它
			pd.ang = ang or 0
			-- v1.9.7：手机端不再检查 pdTouching —— 用户主动开了自瞄就是要锁。
			pdApplyAim(cam, pos)
			-- 🔴 v2.0.1：自动开火要等视角真的压到目标上再扣扳机。
			--    之前"锁上就开火"，跟随速度没拉满时相机还在半路，子弹全打偏 —— 手感就是"开了自动开火打不中"。
			if pd.Fire and (pd.ang or 0) <= 6 and os.clock() - (pd.lastFire or 0) >= 0.08 then
				pd.lastFire = os.clock()
				pdFire()
			end
		end

		pdAimBind = function()
			if pd.aimBound then return end
			pd.aimBound = true
			local okBind = pcall(function()
				RunService:BindToRenderStep("OX_pdAim",
					Enum.RenderPriority.Camera.Value + 5, pdAimFn)  -- v1.9.7：+5 盖过游戏自带相机脚本
			end)
			if okBind then
				pd.aimBound = "bind"
				return
			end
			pdAimConn = RunService.RenderStepped:Connect(pdAimFn)
			track(pdAimConn)
			pd.aimBound = "step"
		end

		pdAimUnbind = function()
			if not pd.aimBound then return end
			pcall(function() RunService:UnbindFromRenderStep("OX_pdAim") end)
			if pdAimConn then
				pcall(function() pdAimConn:Disconnect() end)
				pdAimConn = nil
			end
			pd.aimBound = nil
			pd.locked = nil
		end

		-- ---------------- 常驻循环 ----------------
		-- 🔴 不再看 pdWin.Visible：窗口收起/关掉之后功能照样得跑（上一版就栽在这）。
		--    每段逻辑都用 pcall 兜住，出错写进 pd.err 显示在诊断行上，绝不把循环打断
		--    （一旦断连，用户看到的就是"点了没反应"）。
		local pdTicker = 0
		-- 报错只在最近 12 秒内挂红：修好之后诊断行会自己恢复（不然一次瞬时报错永远挡住守卫数）
		local function pdErrLive()
			return pd.err and (os.clock() - (pd.errAt or 0) < 12)
		end
		local function pdDiagText()
			if pdErrLive() then return string.format(L("pdErrFmt"), tostring(pd.err):sub(1, 90)) end
			local base = string.format(L("pdDiagS"), tostring(pd.promptN), tostring(pd.lootN), tostring(pdBags()))
				.. "   ·   "
				.. string.format(L("pdDiagA"), tostring(pd.enemyN), tostring(pd.gunN),
					pd.silent and "✓" or "✗", pd.camOk and "✓" or "✗")
			-- v1.9.7: 实机诊断信息（只在 Aim/Fire 开启时显示）
			if pd.Aim or pd.Fire then
				local bound = pd.aimBound == "bind" and "B" or (pd.aimBound == "step" and "S" or "-")
				local calls = tostring(pd.aimFnCalls or 0)
				local locked = pd.locked and "✓" or "✗"
				base = base .. " [" .. bound .. ":" .. calls .. ":" .. locked .. "]"
			end
			return base
		end

		local function pdDiagSweep()
			if not pdDiagStealth then return end
			local txt = pdDiagText()
			pdDiagStealth.Text = txt
			if pdDiagAssault then pdDiagAssault.Text = txt end
			local col = pdErrLive() and C.Red or ((pd.silent or pd.camOk) and C.Green or C.Dim)
			pdDiagStealth.TextColor3 = col
			if pdDiagAssault then pdDiagAssault.TextColor3 = col end
		end

		local function pdSafe(fn)
			local ok, err = pcall(fn)
			if not ok then
				pd.err, pd.errAt = tostring(err), os.clock()
			end
		end

		-- PromptTriggered = 交互真的成了的信号（RealNotorietyLib.Lib.Interact 就靠它）
		pcall(function()
			local pps = game:GetService("ProximityPromptService")
			track(pps.PromptTriggered:Connect(function(p)
				pd.hit = p
				pd.err = nil
			end))
		end)

		track(RunService.Heartbeat:Connect(function()
			if SHUTDOWN then return end
			local now = os.clock()
			-- 自瞄：开关一开就挂上（武器表可能晚一步才加载，没挂上就每 2 秒重试）
			pdSafe(function()
				if pd.Aim or pd.Fire then
					if not pd.aimBound then pdAimBind() end
					-- 🔴 v2.0.1：不再只在"没挂上"时重试。换局 / 重载武器模块会生成新的子弹表，
					--    老代码挂上一次就再也不管了 → 静默自瞄在下一局悄悄失效。
					--    pdSilent 对已经挂过的表是幂等的，定期重挂没成本（挂不上时慢一点重试）。
					local gap = pd.silent and 2 or 3
					if now - pd.aimAt >= gap then
						pd.aimAt = now
						pdSilent(true)
					end
				end
			end)
			pdSafe(function()
				local need = pd.AutoDone or pd.Esp or pd.LootEsp or pd.Aim or pd.KillAll or pd.Cameras
				if need and now - pd.scanAt >= 0.4 then
					pd.scanAt = now
					pdScan()
					pdRefreshEsp()
				end
			end)
			pdSafe(function()
				if pd.InfStam then
					local char = pdChar()
					local st = char and char:FindFirstChild("Stamina")
					local mx = char and char:FindFirstChild("MaxStamina")
					if st and mx then st.Value = mx.Value end
				end
			end)
			pdSafe(function()
				if pd.InfAmmo and not pd.ammoHooked and now - pd.lastAmmo >= 1 then
					pd.lastAmmo = now
					pdAmmoRefill()
				end
			end)
			pdSafe(function()
				if pd.Cameras and now - pdTicker >= 3 then
					local n = pdCameras()
					if n == -1 then notify(L("pdCamNoKey"), C.Amber) end
				end
			end)
			pdSafe(function()
				-- 兜底解钉：贴脸时角色是 Anchored + PlatformStand，手机上等于摇杆/触屏全废。
				-- 万一哪一步出错没解掉，6 秒后强制解开。
				if pd.frozen and pd.snapAt and os.clock() - pd.snapAt > 6 then pdUnsnap() end
			end)
			pdSafe(function()
				if pd.KillAll and now - (pd.killAt or 0) >= 0.12 then
					pd.killAt = now
					pdKillStep(now)
				end
				pdVoidPin(now)
			end)
			pdSafe(function()
				if pd.Yell and now - pd.lastYell >= 2 then
					pd.lastYell = now
					pdYellNow()
				end
			end)
			pdSafe(function()
				if pd.Ready and now - pd.lastReady >= 2 then
					pd.lastReady = now
					pdReadyNow()
				end
			end)
			pdSafe(function()
				if pd.LobbyBack then pdLobbyReturnTick() end
			end)
			pdSafe(function()
				if now - pd.diagAt >= 0.5 then
					pd.diagAt = now
					pdDiagSweep()
				end
			end)
			if now - pdTicker >= 3 then pdTicker = now end
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
			task.spawn(function()
				task.wait(0.05)
				pdScan()
				pdRefreshEsp()
			end)
			if pdIsMain() then notify(L("pdUpdateOn"), C.Amber) end
		end

		-- ✕ 只关窗口：潜入 / 强攻的状态留着（跟农场一个道理，关了面板照样在跑）
		PdCloseRequest = function()
			pdWin.Visible = false
			pdReopen.Visible = false
		end

		-- 结束整个脚本时：停掉所有开关，把挂在场景里的透视收干净
		pdCleanup = function()
			pcall(pdSilent, false)
			pcall(pdAimUnbind)
			pcall(pdUnsnap)
			pd.AutoDone, pd.LootEsp, pd.Esp, pd.Aim, pd.Fire = false, false, false, false, false
			pd.KillAll, pd.InfStam, pd.Cameras, pd.Yell, pd.Ready, pd.LobbyBack = false, false, false, false, false, false
			pd.run = pd.run + 1
			pdSetAmmo(false)
			pdEspSweep()
			local hum = getHumanoid()
			if hum and pd.walk0 then pcall(function() hum.WalkSpeed = pd.walk0 end) end
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

	local pdOk, pdErr = pcall(pdBuild)
	if not pdOk then
		warn("[O_X HUB] Notoriety 初始化失败:", tostring(pdErr))
		-- 在屏幕上显示错误，让用户能看到
		pcall(function()
			local errLabel = Instance.new("TextLabel")
			errLabel.Name = "NotorietyError"
			errLabel.Size = UDim2.new(0, 400, 0, 100)
			errLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
			errLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			errLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			errLabel.Text = "Notoriety 脚本加载失败:\n" .. tostring(pdErr):sub(1, 200)
			errLabel.TextSize = 14
			errLabel.Parent = game:GetService("CoreGui")
		end)
	end

	--========================== 服务器脚本：DOORS ==========================
	-- place 6516141723（DOORS 👁 by LSPLASH）。
	-- 区域（楼层）靠 ReplicatedStorage.GameData.Floor（StringValue）+ LatestRoom（NumberValue）自动检测；
	-- 门号按社区脚本的通用换算：Backdoor = room-51、Mines = room+100，其余楼层 room 就是门号。
	-- ⚠️ 跟劫案一样整块塞进独立函数 —— boot 的 200 个 local 名额很紧（改完必跑 _check + _lint + _run）。
	local function dsBuild()
		local DS_W, DS_H = 520, 500

		local ds = {
			-- 透视
			Esp = false, EspItem = false, EspDoor = false, EspHide = false, EspDist = true,
			EspRange = 400,
			-- 自动
			AutoHide = false, AutoInteract = false, AutoPickup = false, AutoNext = false,
			AutoRevive = false,
			-- 移动
			Bright = false, Noclip = false, Speed = 16, Jump = 50, Reach = 12, JumpTo = 1,
			-- 运行时
			Area = nil, DoorN = nil, RoomN = nil, Rooms = 0,
			esps = {}, run = 0, noclipped = {}, lastEsp = 0,
			brightSaved = nil,
			hideSpot = nil, hideOn = false, hideWarned = false,
		}

		-- ⚠️ 前向声明：界面（早）要调功能模块（晚）里的东西。不先占位的话，
		-- 闭包会绑到全局名字上 → nil → 运行时炸（luaparse 语法检查不报，_lint.js 才抓得到）。
		local DS_TABS = {}
		local dsApplyBright = function() end
		local dsApplySpeed = function() end
		local dsRestoreCollide = function() end
		local dsRenderStatus = function() end
		local DsGoPlace = function() end
		local DsGoFloor = function() end
		local DsJumpRequest = function() end
		local DsJumpToNumber = function() end
		local DsLobbyRequest = function() end

		-- 会追着你跑、必须躲起来的实体（值 = 触发躲藏的距离阈值，社区脚本通用值）
		local HIDE_ENTS = {
			RushMoving = 85, AmbushMoving = 150, BashMoving = 150, Scribbles = 100,
			DronesStampede = 100, A60 = 125, A120 = 85, GlitchRush = 90,
			GlitchAmbush = 175, BackdoorRush = 85, Halt = 200, Seek = 200,
		}

		-- 透视要画出来的所有实体（含"看着它就行"的那几个）
		local ALL_ENTS = {
			RushMoving = true, AmbushMoving = true, BashMoving = true, Scribbles = true,
			DronesStampede = true, A60 = true, A120 = true, GlitchRush = true,
			GlitchAmbush = true, BackdoorRush = true, Halt = true, Seek = true,
			SeekHands = true, SeekArms = true, Eyes = true, Lookman = true,
			BackdoorLookman = true, Figure = true, FigureRig = true, FigureRagdoll = true,
			Screech = true, ScreechHitbox = true, Dupe = true, Void = true, Jack = true,
			Timothy = true, Shadow = true, Snare = true, SnareCeiling = true,
			GiggleCeiling = true, Groundskeeper = true, TellerRig = true, Creak = true,
			NoiseModel = true, StemsEntity = true, Glitch = true, Window = true,
		}

		-- 地上的道具（走过去就会自动捡）
		local ITEMS = {
			Key = true, Lockpick = true, Crucifix = true, Flashlight = true, Vitamins = true,
			Bandage = true, SkeletonKey = true, ["Skeleton Key"] = true, Lighter = true,
			Bottle = true, Shears = true, Candle = true, Battery = true, Shakelight = true,
			Gold = true, Rift = true, Potion = true, Bread = true, Cracker = true, Cheese = true,
		}

		-- 两个 place（点「传送」= 真正的服务器式传送）
		local DS_PLACES = {
			{ key = "Lobby", place = DS.Lobby, name = "dsPlaceLobby", desc = "dsPlaceLobbyD" },
			{ key = "Game",  place = DS.Game,  name = "dsPlaceGame",  desc = "dsPlaceGameD" },
		}
		-- 游戏内的楼层顺序（地图页那两排 pill）
		local DS_FLOOR_ORDER = { "Hotel", "Backdoor", "Mines", "Rooms", "Retro", "Party" }

		-- 全部区域（"记住全地图"）。doors = 该区域的门数上限，0 表示没有门。
		local DS_AREAS = {
			{ key = "Lobby", doors = 0 },
			{ key = "Hotel", doors = 100 },
			{ key = "Backdoor", doors = 50 },
			{ key = "Mines", doors = 250 },
			{ key = "Rooms", doors = 1000 },
			{ key = "Retro", doors = 100 },
			{ key = "Party", doors = 100 },
		}

		-- 区域名：认识的走语言包，不认识的（比如活动楼层）直接显示原始 key
		local AREA_SET = {}
		for _, a in ipairs(DS_AREAS) do AREA_SET[a.key] = true end
		local function dsAreaName(key)
			if key and AREA_SET[key] then return L("dsArea" .. key) end
			return tostring(key or "?")
		end

		-- ---------------- 小工具 ----------------
		local function dsRS()
			local ok, v = pcall(function() return game:GetService("ReplicatedStorage") end)
			return ok and v or nil
		end

		local function dsGameData()
			local rs = dsRS()
			if not rs then return nil end
			local ok, v = pcall(function() return rs:FindFirstChild("GameData") end)
			return ok and v or nil
		end

		local function dsFloorKey()
			local gd = dsGameData()
			if not gd then return nil end
			local ok, v = pcall(function()
				local f = gd:FindFirstChild("Floor")
				return f and f.Value
			end)
			if ok and type(v) == "string" and v ~= "" then return v end
			return nil
		end

		local function dsRoomNum()
			local gd = dsGameData()
			if not gd then return nil end
			local ok, v = pcall(function()
				local r = gd:FindFirstChild("LatestRoom")
				return r and r.Value
			end)
			if ok and type(v) == "number" then return v end
			return nil
		end

		-- 当前区域：在大厅 place 里就是"大厅"；在游戏里才看 Floor。
		-- LatestRoom <= 0 = 还没开局（电梯里），也当大厅。
		local function dsPid()
			local ok, pid = pcall(function() return game.PlaceId end)
			return (ok and type(pid) == "number") and pid or nil
		end

		local function dsAreaNow()
			local pid = dsPid()
			if pid == DS.Lobby then return "Lobby" end
			local room = dsRoomNum()
			if type(room) == "number" and room <= 0 then return "Lobby" end
			local f = dsFloorKey()
			if f then return f end
			if pid == DS.Game then return "Hotel" end
			return nil
		end

		local function dsRooms()
			local ok, v = pcall(function()
				return game:GetService("Workspace"):FindFirstChild("CurrentRooms")
			end)
			return ok and v or nil
		end

		-- 门号换算：玩家在游戏里看到的门号
		local function dsDoorNum(floor, room)
			if type(room) ~= "number" then return nil end
			if floor == "Backdoor" then
				local n = room - 51
				return n > 0 and n or room
			elseif floor == "Mines" then
				return room + 100
			end
			return room
		end

		-- 反查：门号 -> CurrentRooms 里的房间名（传送用）
		local function dsRoomKey(floor, door)
			if floor == "Backdoor" then return tostring(door + 51) end
			if floor == "Mines" then return tostring(door - 100) end
			return tostring(door)
		end

		-- 从任意实例里挑一个能读 Position 的部件
		local function dsPartOf(inst)
			if not inst then return nil end
			local ok, isPart = pcall(function() return inst:IsA("BasePart") end)
			if ok and isPart then return inst end
			local out
			pcall(function()
				out = inst:FindFirstChild("Door") or inst.PrimaryPart
					or inst:FindFirstChildOfClass("Part") or inst:FindFirstChild("Handle")
			end)
			return out
		end

		local function dsDist(part)
			local root = getRoot()
			if not part or not root then return math.huge end
			local ok, d = pcall(function() return (part.Position - root.Position).Magnitude end)
			return ok and d or math.huge
		end

		-- 触发一个 ProximityPrompt：优先执行器的 fireproximityprompt，退到官方 InputHold 那对方法
		local function dsFire(prompt)
			if not prompt then return false end
			local fn = execFn("fireproximityprompt")
			if fn then
				local ok, r = pcall(fn, prompt)
				if ok and r ~= false then return true end
			end
			local ok = pcall(function()
				if prompt.InputHoldBegin then prompt:InputHoldBegin() end
				if prompt.InputHoldEnd then prompt:InputHoldEnd() end
			end)
			return ok
		end

		-- 假装碰一下（捡道具）：有 firetouchinterest 就用，没有就把角色挪过去
		local function dsTouch(part)
			if not part then return false end
			local root = getRoot()
			if not root then return false end
			local fn = execFn("firetouchinterest")
			if fn then
				local ok = pcall(function() fn(root, part, 0); fn(part, root, 1) end)
				if ok then return true end
			end
			return pcall(function() root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0)) end)
		end

		local function dsTeleportTo(part, dy)
			if not part then return false end
			local root = getRoot()
			local pos = part.Position + Vector3.new(0, dy or 4, 0)
			if root and pcall(function() root.CFrame = CFrame.new(pos) end) then return true end
			local char = LocalPlayer.Character
			if not char then return false end
			return pcall(function() char:MoveTo(pos) end)
		end

		-- ---------------- 窗口骨架（拖动 / － 胶囊 / ✕ 关窗，跟另外两个服务器窗口一致） ----------------
		local dsWin = new("Frame", {
			Name = "DoorsWindow",
			Size = UDim2.new(0, DS_W, 0, DS_H),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			Visible = false,
			Parent = guiMain,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = dsWin })
		new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = dsWin })
		local dsScale = new("UIScale", { Scale = 1, Parent = dsWin })

		local dsHeader = new("Frame", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, SRV_HEAD_H),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			Parent = dsWin,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.win), Parent = dsHeader })
		new("Frame", {
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.new(0, 0, 1, -12),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			Parent = dsHeader,
		})
		new("Frame", {
			Size = UDim2.new(1, -24, 0, 1),
			Position = UDim2.new(0, 12, 1, -1),
			BackgroundColor3 = C.Stroke,
			BorderSizePixel = 0,
			Parent = dsHeader,
		})

		do
			local box = new("Frame", {
				Size = UDim2.new(0, 22, 0, 22),
				Position = UDim2.new(0, 14, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = C.Card2,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = dsHeader,
			})
			new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = box })
			local a = getAsset("srv_doors")
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
		end

		new("TextLabel", {
			Size = UDim2.new(0, 76, 1, 0),
			Position = UDim2.new(0, 44, 0, 0),
			BackgroundTransparency = 1,
			Text = L("srvDoors"),
			TextSize = 14,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsHeader,
		})

		-- 实时状态胶囊：● 区域 · 门号 —— 这就是"自动检测地图"的窗口
		local dsChip = new("Frame", {
			Name = "LiveChip",
			Size = UDim2.new(0, 186, 0, 22),
			Position = UDim2.new(0, 116, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Card,
			BorderSizePixel = 0,
			Parent = dsHeader,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dsChip })
		local dsChipStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = dsChip })
		local dsChipDot = new("Frame", {
			Name = "Dot",
			Size = UDim2.new(0, 6, 0, 6),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Dim,
			BorderSizePixel = 0,
			Parent = dsChip,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dsChipDot })
		local dsChipText = new("TextLabel", {
			Name = "ChipText",
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.new(0, 22, 0, 0),
			BackgroundTransparency = 1,
			Text = L("dsChipIdle"),
			TextSize = 11,
			Font = FONT_M,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsChip,
		})

		local dsMinBtn = new("TextButton", {
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
			Parent = dsHeader,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = dsMinBtn })
		local dsMinStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = dsMinBtn })
		bindHover(dsMinBtn, {
			Bg = { C.Card, C.Card2 }, Stroke = dsMinStroke, StrokeOn = C.Stroke2,
			Label = dsMinBtn, LabelOn = C.Text,
		})

		local dsCloseBtn = new("TextButton", {
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
			Parent = dsHeader,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = dsCloseBtn })
		local dsCloseStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = dsCloseBtn })
		bindHover(dsCloseBtn, {
			Bg = { C.Card, C.Red }, Stroke = dsCloseStroke, StrokeOn = C.Red,
			Label = dsCloseBtn, LabelOn = C.White,
		})

		makeDraggable(dsWin, dsHeader, function() return dsScale.Scale end)

		-- ---------------- 顶部页签（跟另外两个窗口的左侧栏不一样，这是这次的新版式） ----------------
		local dsTabBar = new("Frame", {
			Name = "TabBar",
			Size = UDim2.new(1, -20, 0, 34),
			Position = UDim2.new(0, 10, 0, SRV_HEAD_H + 2),
			BackgroundColor3 = C.Side,
			BorderSizePixel = 0,
			Parent = dsWin,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = dsTabBar })

		local dsIndicator = new("Frame", {
			Name = "TabIndicator",
			Size = UDim2.new(0, 0, 0, 2),
			Position = UDim2.new(0, 0, 1, -2),
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = dsTabBar,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dsIndicator })

		local dsContent = new("Frame", {
			Name = "Content",
			Size = UDim2.new(1, -20, 1, -(SRV_HEAD_H + 2) - 34 - 16),
			Position = UDim2.new(0, 10, 0, SRV_HEAD_H + 2 + 34 + 6),
			BackgroundTransparency = 1,
			Parent = dsWin,
		})

		local dsPages, dsTabs = {}, {}

		local function dsAddPage(key)
			local page = new("Frame", {
				Name = "DoorsPage_" .. key,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = false,
				Parent = dsContent,
			})
			dsPages[key] = page
			return page
		end

		local function dsShow(key)
			for k, page in pairs(dsPages) do page.Visible = (k == key) end
			for k, t in pairs(dsTabs) do
				local on = (k == key)
				tween(t.label, EASE.soft, { TextColor3 = on and C.Text or C.Sub })
				tween(t.btn, EASE.soft, { BackgroundColor3 = on and C.Card or C.Side })
			end
			local item = dsTabs[key]
			if item then
				tween(dsIndicator, EASE.pop, {
					Size = UDim2.new(0, item.w, 0, 2),
					Position = UDim2.new(0, item.x, 1, -2),
				})
			end
			local target = dsPages[key]
			if target then staggerIn(target:GetChildren(), 8, 0.03, 0.3) end
		end

		local function dsAddTab(key, text, order)
			local n = math.max(#DS_TABS, 1)
			local w = math.floor((DS_W - 32) / n)
			local x = 6 + (order - 1) * w
			local btn = new("TextButton", {
				Name = "Doors_" .. key,
				Size = UDim2.new(0, w - 4, 1, 0),
				Position = UDim2.new(0, x, 0, 0),
				BackgroundColor3 = C.Side,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = dsTabBar,
			})
			new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
			local label = new("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = text,
				TextSize = 12,
				Font = FONT_B,
				TextColor3 = C.Sub,
				Parent = btn,
			})
			btn.MouseButton1Click:Connect(function() dsShow(key) end)
			btn.MouseEnter:Connect(function()
				if not dsPages[key] or not dsPages[key].Visible then
					tween(label, EASE.soft, { TextColor3 = C.Text })
				end
			end)
			btn.MouseLeave:Connect(function()
				if not dsPages[key] or not dsPages[key].Visible then
					tween(label, EASE.soft, { TextColor3 = C.Sub })
				end
			end)
			dsTabs[key] = { btn = btn, label = label, x = x, w = w - 4 }
			return btn
		end

		-- ---------------- 组件：开关卡片 / 滑块行 ----------------
		local function dsCard(parent, x, y, w, h, name, title, desc, color, default, onChange)
			local card = new("Frame", {
				Name = name .. "Card",
				Size = UDim2.new(0, w, 0, h),
				Position = UDim2.new(0, x, 0, y),
				BackgroundColor3 = C.Card,
				BorderSizePixel = 0,
				Parent = parent,
			})
			new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = card })
			new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = card })

			local dot = new("Frame", {
				Name = "Dot",
				Size = UDim2.new(0, 6, 0, 6),
				Position = UDim2.new(0, 14, 0, 15),
				BackgroundColor3 = color,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = card,
			})
			new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

			new("TextLabel", {
				Size = UDim2.new(1, -74, 0, 18),
				Position = UDim2.new(0, 26, 0, 8),
				BackgroundTransparency = 1,
				Text = title,
				TextSize = 13,
				Font = FONT_B,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			if desc and desc ~= "" then
				new("TextLabel", {
					Size = UDim2.new(1, -30, 0, h - 28),
					Position = UDim2.new(0, 26, 0, 26),
					BackgroundTransparency = 1,
					Text = desc,
					TextSize = 10,
					Font = FONT_N,
					TextColor3 = C.Dim,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					Parent = card,
				})
			end

			local sw = createSwitch(card, {
				Name = name,
				Position = UDim2.new(1, -52, 0, 11),
				Default = default,
				OnChange = function(v)
					tween(dot, EASE.soft, { BackgroundTransparency = v and 0 or 1 })
					if onChange then onChange(v) end
				end,
			})
			return card, sw
		end

		local function dsSliderRow(parent, y, title, min, max, default, log, fmt, onChange)
			new("TextLabel", {
				Size = UDim2.new(1, -70, 0, 16),
				Position = UDim2.new(0, 0, 0, y),
				BackgroundTransparency = 1,
				Text = title,
				TextSize = 12,
				Font = FONT_N,
				TextColor3 = C.Sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = parent,
			})
			local val = new("TextLabel", {
				Size = UDim2.new(0, 66, 0, 16),
				Position = UDim2.new(1, -66, 0, y),
				BackgroundTransparency = 1,
				Text = fmt(default),
				TextSize = 12,
				Font = FONT_M,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = parent,
			})
			local set = createSlider(parent, {
				Position = UDim2.new(0, 0, 0, y + 18),
				Min = min, Max = max, Default = default, Log = log,
				OnChange = function(v)
					val.Text = fmt(v)
					if onChange then onChange(v) end
				end,
			})
			return set
		end

		-- 一条细分割线（有理由的线：分隔功能组，不是装饰）
		local function dsRule(parent, y)
			new("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, y),
				BackgroundColor3 = C.Stroke,
				BorderSizePixel = 0,
				Parent = parent,
			})
		end

		-- ---------------- 页面 1：透视 ----------------
		local dsEspPage = dsAddPage("esp")
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsEspTitle"),
			TextSize = 15,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsEspPage,
		})
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsEspSub"),
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsEspPage,
		})

		local ESP_COLOR = { ent = C.Red, item = C.Green, door = C.Amber, hide = C.Accent2 }
		local ESP_SIZE = {
			ent = Vector3.new(4, 6, 3),
			item = Vector3.new(1.6, 1.6, 1.6),
			door = Vector3.new(6, 8, 1),
			hide = Vector3.new(5, 6, 5),
		}

		dsCard(dsEspPage, 0, 44, 236, 62, "EspEnt",
			L("dsEspEntity"), L("dsEspEntityD"), ESP_COLOR.ent, false,
			function(v) ds.Esp = v end)
		dsCard(dsEspPage, 244, 44, 236, 62, "EspItem",
			L("dsEspItem"), L("dsEspItemD"), ESP_COLOR.item, false,
			function(v) ds.EspItem = v end)
		dsCard(dsEspPage, 0, 114, 236, 62, "EspDoor",
			L("dsEspDoor"), L("dsEspDoorD"), ESP_COLOR.door, false,
			function(v) ds.EspDoor = v end)
		dsCard(dsEspPage, 244, 114, 236, 62, "EspHide",
			L("dsEspHide"), L("dsEspHideD"), ESP_COLOR.hide, false,
			function(v) ds.EspHide = v end)

		dsRule(dsEspPage, 190)

		local dsDistRow = new("Frame", {
			Name = "DistRow",
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 0, 202),
			BackgroundColor3 = C.Card,
			BorderSizePixel = 0,
			Parent = dsEspPage,
		})
		new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = dsDistRow })
		new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = dsDistRow })
		new("TextLabel", {
			Size = UDim2.new(1, -70, 0, 18),
			Position = UDim2.new(0, 14, 0, 11),
			BackgroundTransparency = 1,
			Text = L("dsEspDist"),
			TextSize = 13,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsDistRow,
		})
		createSwitch(dsDistRow, {
			Name = "EspDist",
			Position = UDim2.new(1, -52, 0, 9),
			Default = true,
			OnChange = function(v) ds.EspDist = v end,
		})

		dsSliderRow(dsEspPage, 254, L("dsEspRange"), 50, 1200, 400, true, function(v)
			return tostring(math.floor(v)) .. "m"
		end, function(v) ds.EspRange = v end)

		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 306),
			BackgroundTransparency = 1,
			Text = L("dsEspHint"),
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Parent = dsEspPage,
		})

		-- ---------------- 页面 2：自动 ----------------
		local dsAutoPage = dsAddPage("auto")
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsAutoTitle"),
			TextSize = 15,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsAutoPage,
		})
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsAutoSub"),
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsAutoPage,
		})

		dsCard(dsAutoPage, 0, 44, 480, 60, "AutoHide",
			L("dsAutoHide"), L("dsAutoHideD"), C.Red, false,
			function(v)
				ds.AutoHide = v
				if not v then ds.hideOn = false; ds.hideSpot = nil end
				notify(string.format(v and L("dsOnFmt") or L("dsOffFmt"), L("dsAutoHide")),
					v and C.Green or C.Sub)
			end)
		dsCard(dsAutoPage, 0, 110, 480, 60, "AutoInteract",
			L("dsAutoInteract"), L("dsAutoInteractD"), C.Accent2, false,
			function(v)
				ds.AutoInteract = v
				notify(string.format(v and L("dsOnFmt") or L("dsOffFmt"), L("dsAutoInteract")),
					v and C.Green or C.Sub)
			end)
		dsCard(dsAutoPage, 0, 176, 480, 60, "AutoPickup",
			L("dsAutoPickup"), L("dsAutoPickupD"), C.Green, false,
			function(v)
				ds.AutoPickup = v
				notify(string.format(v and L("dsOnFmt") or L("dsOffFmt"), L("dsAutoPickup")),
					v and C.Green or C.Sub)
			end)
		dsCard(dsAutoPage, 0, 242, 480, 60, "AutoNext",
			L("dsAutoNext"), L("dsAutoNextD"), C.Amber, false,
			function(v)
				ds.AutoNext = v
				notify(string.format(v and L("dsOnFmt") or L("dsOffFmt"), L("dsAutoNext")),
					v and C.Green or C.Sub)
			end)
		dsCard(dsAutoPage, 0, 308, 480, 60, "AutoRevive",
			L("dsAutoRevive"), L("dsAutoReviveD"), C.Sub, false,
			function(v)
				ds.AutoRevive = v
				notify(string.format(v and L("dsOnFmt") or L("dsOffFmt"), L("dsAutoRevive")),
					v and C.Green or C.Sub)
			end)

		-- ---------------- 页面 3：移动 ----------------
		local dsMovePage = dsAddPage("move")
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsMoveTitle"),
			TextSize = 15,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsMovePage,
		})
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsMoveSub"),
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsMovePage,
		})

		dsCard(dsMovePage, 0, 44, 236, 60, "Bright",
			L("dsBright"), L("dsBrightD"), C.Amber, false,
			function(v)
				ds.Bright = v
				dsApplyBright()
				notify(v and L("dsBrightOn") or L("dsBrightOff"), v and C.Green or C.Sub)
			end)
		dsCard(dsMovePage, 244, 44, 236, 60, "Noclip",
			L("dsNoclip"), L("dsNoclipD"), C.Accent2, false,
			function(v)
				ds.Noclip = v
				if not v then dsRestoreCollide() end
				notify(v and L("dsNoclipOn") or L("dsNoclipOff"), v and C.Green or C.Sub)
			end)

		dsRule(dsMovePage, 116)

		dsSliderRow(dsMovePage, 128, L("dsSpeed"), 16, 300, 16, false, function(v)
			return tostring(math.floor(v))
		end, function(v) ds.Speed = v; dsApplySpeed() end)

		dsSliderRow(dsMovePage, 178, L("dsJump"), 50, 300, 50, false, function(v)
			return tostring(math.floor(v))
		end, function(v) ds.Jump = v; dsApplySpeed() end)

		dsSliderRow(dsMovePage, 228, L("dsReach"), 8, 60, 12, false, function(v)
			return tostring(math.floor(v))
		end, function(v) ds.Reach = v end)

		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 282),
			BackgroundTransparency = 1,
			Text = L("dsMoveHint"),
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Parent = dsMovePage,
		})

		-- ---------------- 页面 4：地图（两个地点 + 楼层） ----------------
		-- 这里跟"服务器卡片"是一条链：跨 place 就 queue-on-teleport + Teleport，
		-- 同一个 place 里才谈得上"传到这层入口"。
		local dsMapPage = dsAddPage("map")
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsMapTitle"),
			TextSize = 15,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsMapPage,
		})
		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = L("dsMapSub"),
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsMapPage,
		})

		-- ① 两个地点：点「传送」= 真正的 place 传送（跟服务器卡片一模一样）
		local dsPlaceRows = {}
		for i, pl in ipairs(DS_PLACES) do
			local card = new("Frame", {
				Name = "Place_" .. pl.key,
				Size = UDim2.new(0, 236, 0, 64),
				Position = UDim2.new(0, (i - 1) * 244, 0, 40),
				BackgroundColor3 = C.Card,
				BorderSizePixel = 0,
				Parent = dsMapPage,
			})
			new("UICorner", { CornerRadius = UDim.new(0, R.card), Parent = card })
			local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = card })

			local dot = new("Frame", {
				Name = "Dot",
				Size = UDim2.new(0, 6, 0, 6),
				Position = UDim2.new(0, 14, 0, 16),
				BackgroundColor3 = C.Green,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = card,
			})
			new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

			new("TextLabel", {
				Size = UDim2.new(1, -90, 0, 18),
				Position = UDim2.new(0, 26, 0, 8),
				BackgroundTransparency = 1,
				Text = L(pl.name),
				TextSize = 14,
				Font = FONT_B,
				TextColor3 = C.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			local sub = new("TextLabel", {
				Name = "Sub",
				Size = UDim2.new(1, -30, 0, 14),
				Position = UDim2.new(0, 26, 0, 28),
				BackgroundTransparency = 1,
				Text = string.format(L("dsPlaceId"), tostring(pl.place)),
				TextSize = 10,
				Font = FONT_M,
				TextColor3 = C.Dim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			new("TextLabel", {
				Size = UDim2.new(1, -30, 0, 14),
				Position = UDim2.new(0, 26, 0, 44),
				BackgroundTransparency = 1,
				Text = L(pl.desc),
				TextSize = 9,
				Font = FONT_N,
				TextColor3 = C.Dim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})

			local go = new("TextButton", {
				Name = "Go",
				Size = UDim2.new(0, 54, 0, 26),
				Position = UDim2.new(1, -64, 0, 8),
				BackgroundColor3 = C.Card2,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = L("dsMapGo"),
				TextSize = 11,
				Font = FONT_B,
				TextColor3 = C.Sub,
				Parent = card,
			})
			new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = go })
			local goStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = go })
			bindHover(go, {
				Bg = { C.Card2, C.Accent }, Stroke = goStroke, StrokeOn = C.Accent,
				Label = go, LabelOn = C.White,
			})
			bindPress(go, C.Accent)
			go.MouseButton1Click:Connect(function() DsGoPlace(pl.key) end)

			dsPlaceRows[pl.key] = { stroke = stroke, dot = dot, go = go }
		end

		dsRule(dsMapPage, 116)

		-- ② 当前楼层
		new("TextLabel", {
			Size = UDim2.new(0, 70, 0, 16),
			Position = UDim2.new(0, 0, 0, 126),
			BackgroundTransparency = 1,
			Text = L("dsCurFloor"),
			TextSize = 12,
			Font = FONT_N,
			TextColor3 = C.Sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsMapPage,
		})
		local dsCurText = new("TextLabel", {
			Name = "CurText",
			Size = UDim2.new(1, -80, 0, 16),
			Position = UDim2.new(0, 74, 0, 126),
			BackgroundTransparency = 1,
			Text = L("dsDetecting"),
			TextSize = 12,
			Font = FONT_M,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsMapPage,
		})

		-- ③ 楼层 pill（3 列 × 2 行）：在这一局里才点得动
		local dsFloorRows = {}
		for i, key in ipairs(DS_FLOOR_ORDER) do
			local col = (i - 1) % 3
			local row = math.floor((i - 1) / 3)
			local btn = new("TextButton", {
				Name = "Floor_" .. key,
				Size = UDim2.new(0, 161, 0, 30),
				Position = UDim2.new(0, col * 169, 0, 150 + row * 38),
				BackgroundColor3 = C.Card,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = dsMapPage,
			})
			new("UICorner", { CornerRadius = UDim.new(0, R.ctl), Parent = btn })
			local stroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = btn })
			local label = new("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = L("dsArea" .. key),
				TextSize = 12,
				Font = FONT_N,
				TextColor3 = C.Sub,
				Parent = btn,
			})
			btn.MouseButton1Click:Connect(function() DsGoFloor(key) end)
			btn.MouseEnter:Connect(function()
				tween(btn, EASE.soft, { BackgroundColor3 = C.Card2 })
				tween(label, EASE.soft, { TextColor3 = C.Text })
			end)
			btn.MouseLeave:Connect(function()
				local on = (key == ds.Area)
				tween(btn, EASE.soft, { BackgroundColor3 = on and C.Card2 or C.Card })
				tween(label, EASE.soft, { TextColor3 = on and C.Text or C.Sub })
			end)
			dsFloorRows[key] = { btn = btn, stroke = stroke, label = label }
		end

		dsRule(dsMapPage, 232)

		-- ④ 跳到门号（只在本层有意义）
		dsSliderRow(dsMapPage, 242, L("dsMapJump"), 1, 1000, 1, false, function(v)
			return tostring(math.floor(v))
		end, function(v) ds.JumpTo = math.floor(v) end)

		createButton(dsMapPage, {
			Name = "JumpGo",
			Size = UDim2.new(0, 148, 0, 30),
			Position = UDim2.new(0, 0, 0, 296),
			Text = L("dsMapJumpGo"),
			TextSize = 12,
			Style = "solid",
			OnClick = function() DsJumpRequest() end,
		})
		createButton(dsMapPage, {
			Name = "GoLobby",
			Size = UDim2.new(0, 148, 0, 30),
			Position = UDim2.new(0, 156, 0, 296),
			Text = L("dsMapLobby"),
			TextSize = 12,
			Style = "ghost",
			OnClick = function() DsLobbyRequest() end,
		})

		new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 336),
			BackgroundTransparency = 1,
			Text = L("dsMapHint"),
			TextSize = 10,
			Font = FONT_N,
			TextColor3 = C.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Parent = dsMapPage,
		})

		-- 页签：顺序固定，跟上面 4 个页面一一对应
		DS_TABS = {
			{ key = "esp", text = L("dsTabEsp") },
			{ key = "auto", text = L("dsTabAuto") },
			{ key = "move", text = L("dsTabMove") },
			{ key = "map", text = L("dsTabMap") },
		}
		for i, t in ipairs(DS_TABS) do dsAddTab(t.key, t.text, i) end
		dsShow("esp")

		-- ---------------- 状态显示（自动检测的可视化） ----------------
		dsRenderStatus = function()
			local area = ds.Area
			local pid = dsPid()
			local inLobby = (area == nil) or (area == "Lobby")
			if not area then
				dsChipDot.BackgroundColor3 = C.Dim
				dsChipText.Text = L("dsChipIdle")
				dsChipText.TextColor3 = C.Dim
				dsChipStroke.Color = C.Stroke
			else
				dsChipDot.BackgroundColor3 = C.Green
				dsChipText.Text = string.format(L("dsChipLive"), dsAreaName(area),
					inLobby and "—" or tostring(ds.DoorN or "?"))
				dsChipText.TextColor3 = C.Text
				dsChipStroke.Color = C.Green
			end

			-- 当前地点：在大厅 place 就是大厅，否则就是游戏内
			local herePlace = (pid == DS.Lobby) and "Lobby" or ((pid == DS.Game) and "Game" or nil)
			for key, r in pairs(dsPlaceRows) do
				local here = (key == herePlace)
				tween(r.dot, EASE.soft, { BackgroundTransparency = here and 0 or 1 })
				tween(r.stroke, EASE.soft, { Color = here and C.Accent or C.Stroke })
				tween(r.go, EASE.soft, { TextColor3 = here and C.Dim or C.Sub })
			end

			-- 当前楼层
			for key, r in pairs(dsFloorRows) do
				local here = (key == area)
				tween(r.stroke, EASE.soft, { Color = here and C.Accent or C.Stroke })
				tween(r.btn, EASE.soft, { BackgroundColor3 = here and C.Card2 or C.Card })
				tween(r.label, EASE.soft, { TextColor3 = here and C.Text or C.Sub })
			end
			if dsCurText then
				if inLobby then
					dsCurText.Text = dsAreaName(area or "Lobby")
				else
					dsCurText.Text = string.format(L("dsCurFloorFmt"), dsAreaName(area),
						tostring(ds.DoorN or "?"))
				end
			end
		end

		-- ---------------- 功能实现 ----------------
		dsApplySpeed = function()
			local hum = getHumanoid()
			if not hum then return end
			pcall(function() hum.WalkSpeed = ds.Speed end)
			pcall(function()
				hum.UseJumpPower = true
				hum.JumpPower = ds.Jump
			end)
		end

		dsRestoreCollide = function()
			for part in pairs(ds.noclipped) do
				pcall(function() part.CanCollide = true end)
				ds.noclipped[part] = nil
			end
		end

		local function dsApplyNoclip()
			local char = LocalPlayer.Character
			if not char then return end
			local ok, list = pcall(function() return char:GetDescendants() end)
			if not ok then return end
			for _, d in ipairs(list) do
				local isPart = false
				pcall(function() isPart = d:IsA("BasePart") end)
				if isPart and d.CanCollide then
					pcall(function() d.CanCollide = false end)
					ds.noclipped[d] = true
				end
			end
		end

		local function dsLighting()
			local ok, v = pcall(function() return game:GetService("Lighting") end)
			return ok and v or nil
		end

		-- 全亮的目标值：提出来只造一次，别每帧 fromRGB
		local BRIGHT_AMBIENT = Color3.fromRGB(178, 178, 178)

		dsApplyBright = function()
			local lt = dsLighting()
			if not lt then return end
			if ds.Bright then
				if not ds.brightSaved then
					ds.brightSaved = {}
					pcall(function()
						ds.brightSaved.Brightness = lt.Brightness
						ds.brightSaved.Ambient = lt.Ambient
						ds.brightSaved.OutdoorAmbient = lt.OutdoorAmbient
						ds.brightSaved.FogEnd = lt.FogEnd
						ds.brightSaved.ClockTime = lt.ClockTime
						ds.brightSaved.GlobalShadows = lt.GlobalShadows
					end)
				end
				-- 只在被游戏改回去时才重写 —— 每帧都写 6 个属性 + 造 Color3 太浪费
				-- （真 Roblox 里 Color3 是按值比较的，所以 Ambient 漂了也能抓到；
				--   mock 里每次 fromRGB 都是新表，比较恒不等 = 退回"每帧都写"，不影响断言）
				if lt.Brightness ~= 2 or lt.FogEnd ~= 100000
					or lt.GlobalShadows ~= false or lt.ClockTime ~= 14
					or lt.Ambient ~= BRIGHT_AMBIENT then
					pcall(function()
						lt.Brightness = 2
						lt.Ambient = BRIGHT_AMBIENT
						lt.OutdoorAmbient = BRIGHT_AMBIENT
						lt.FogEnd = 100000
						lt.ClockTime = 14
						lt.GlobalShadows = false
					end)
				end
			elseif ds.brightSaved then
				local s = ds.brightSaved
				pcall(function()
					lt.Brightness = s.Brightness
					lt.Ambient = s.Ambient
					lt.OutdoorAmbient = s.OutdoorAmbient
					lt.FogEnd = s.FogEnd
					lt.ClockTime = s.ClockTime
					lt.GlobalShadows = s.GlobalShadows
				end)
				ds.brightSaved = nil
			end
		end

		-- 找最近的藏身点（柜子）：有 HidePrompt / HidingPrompt 的都算
		local function dsFindHideSpot()
			local rooms = dsRooms()
			if not rooms or not getRoot() then return nil end
			local best, bestD = nil, math.huge
			pcall(function()
				for _, room in ipairs(rooms:GetChildren()) do
					for _, obj in ipairs(room:GetChildren()) do
						local n = obj.Name
						local prompt = obj:FindFirstChild("HidePrompt")
							or obj:FindFirstChild("HidingPrompt")
						if not prompt and (n:find("Closet") or n:find("Wardrobe")
							or n:find("Locker") or n:find("HidingSpot") or n:find("Hiding")) then
							prompt = obj:FindFirstChild("HidePrompt", true)
								or obj:FindFirstChild("HidingPrompt", true)
						end
						if prompt then
							local part = dsPartOf(obj)
							local d = dsDist(part)
							if d < bestD and d <= 60 then
								best, bestD = { obj = obj, prompt = prompt, part = part }, d
							end
						end
					end
				end
			end)
			return best
		end

		-- 自动躲藏：附近有追人的实体就钻柜子，安全了再出来
		local function dsAutoHideStep()
			local char = LocalPlayer.Character
			if not char or not getRoot() then return end
			local hiding = false
			pcall(function() hiding = (char:GetAttribute("Hiding") == true) end)

			local danger = nil
			local ws = game:GetService("Workspace")
			pcall(function()
				for name, limit in pairs(HIDE_ENTS) do
					local ent = ws:FindFirstChild(name)
					local part = ent and dsPartOf(ent)
					if part then
						local d = dsDist(part)
						if d <= limit and (not danger or d < danger.d) then
							danger = { name = name, d = d }
						end
					end
				end
			end)

			if danger and not hiding then
				local spot = dsFindHideSpot()
				if spot then
					if spot.part then dsTeleportTo(spot.part, 2) end
					dsFire(spot.prompt)
					ds.hideSpot = spot
					if not ds.hideOn then
						ds.hideOn = true
						notify(string.format(L("dsHideIn"), danger.name), C.Red)
					end
				elseif not ds.hideWarned then
					ds.hideWarned = true
					notify(L("dsHideNone"), C.Amber)
				end
			elseif not danger and hiding and ds.hideSpot then
				dsFire(ds.hideSpot.prompt)
				ds.hideSpot = nil
				if ds.hideOn then
					ds.hideOn = false
					notify(L("dsHideOut"), C.Green)
				end
			end
		end

		-- 自动交互 / 自动拾取：扫当前房间的 prompt 和道具
		local function dsAutoDoStep()
			local rooms = dsRooms()
			if not rooms or not getRoot() or not ds.RoomN then return end
			local room
			pcall(function() room = rooms:FindFirstChild(tostring(ds.RoomN)) end)
			if not room then return end
			local reach = ds.Reach
			pcall(function()
				for _, d in ipairs(room:GetDescendants()) do
					if ds.AutoInteract then
						local ok, isPrompt = pcall(function() return d:IsA("ProximityPrompt") end)
						if ok and isPrompt and d.Enabled ~= false then
							if dsDist(dsPartOf(d.Parent)) <= reach then dsFire(d) end
						end
					end
					if ds.AutoPickup then
						local ok, isTool = pcall(function() return d:IsA("Tool") or d:IsA("Model") end)
						if ok and isTool and ITEMS[d.Name] then
							dsTouch(dsPartOf(d) or d)
						end
					end
				end
			end)
		end

		-- 自动进门：把角色推到当前房间的门那儿（游戏自己会开）
		local function dsAutoNextStep()
			local rooms = dsRooms()
			if not rooms or not ds.RoomN then return end
			local room
			pcall(function() room = rooms:FindFirstChild(tostring(ds.RoomN)) end)
			local door = room and dsPartOf(room)
			if door then dsTeleportTo(door, 3) end
		end

		local function dsAutoReviveStep()
			local rs = dsRS()
			if not rs then return end
			local char = LocalPlayer.Character
			local alive = false
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				alive = (hum ~= nil) and (hum.Health > 0)
			end
			if alive then return end
			pcall(function()
				local rf = rs:FindFirstChild("RemotesFolder")
				local rev = rf and rf:FindFirstChild("Revive")
				if rev then rev:FireServer() end
			end)
		end

		-- ---------------- 对外动作（界面按钮调） ----------------
		DsJumpToNumber = function(n)
			local rooms = dsRooms()
			if not rooms then return false end
			local room
			pcall(function() room = rooms:FindFirstChild(dsRoomKey(ds.Area, n)) end)
			if not room then pcall(function() room = rooms:FindFirstChild(tostring(n)) end) end
			if not room then return false end
			local part = dsPartOf(room)
			if not part then return false end
			return dsTeleportTo(part, 4)
		end

		DsJumpRequest = function()
			local n = ds.JumpTo or 1
			if DsJumpToNumber(n) then
				notify(string.format(L("dsTpDoor"), tostring(n)), C.Green)
			else
				notify(L("dsTpNoRoom"), C.Amber)
			end
		end

		DsLobbyRequest = function(areaKey)
			local rs = dsRS()
			local ok = false
			if rs then
				pcall(function()
					local rf = rs:FindFirstChild("RemotesFolder")
					local lobby = rf and rf:FindFirstChild("Lobby")
					if lobby then
						lobby:FireServer()
						ok = true
					end
				end)
			end
			if not ok then
				notify(L("dsLobbyFail"), C.Red)
			elseif areaKey then
				notify(string.format(L("dsLobbyGo"), dsAreaName(areaKey)), C.Green)
			else
				notify(L("dsLobbyBack"), C.Green)
			end
		end

		-- 传送到某个 place —— 跟服务器卡片完全同一条链（排队重执行 + Teleport + 三层降级）
		DsGoPlace = function(key)
			local target = (key == "Lobby") and DS.Lobby or DS.Game
			local pid = dsPid()
			local name = L(key == "Lobby" and "dsPlaceLobby" or "dsPlaceGame")
			if pid == target then
				notify(string.format(L("dsAlreadyThere"), name), C.Amber)
				return
			end
			joinPlace(target, L("srvDoors"))
		end

		-- 点楼层：不在游戏里就先传进游戏；已经在游戏里就传送到这层入口
		DsGoFloor = function(key)
			local pid = dsPid()
			if pid ~= DS.Game then
				DsGoPlace("Game")
				return
			end
			if key ~= ds.Area then
				-- 游戏里换层只能坐电梯：把你送回大厅，在那儿选电梯
				notify(string.format(L("dsFloorSwitch"), dsAreaName(key)), C.Amber)
				DsLobbyRequest()
				return
			end
			if DsJumpToNumber(1) then
				notify(string.format(L("dsTpDone"), dsAreaName(key)), C.Green)
			else
				notify(L("dsTpNoRoom"), C.Amber)
			end
		end

		-- ---------------- 透视 ----------------
		local function dsEspOff(part)
			local e = ds.esps[part]
			if not e then return end
			ds.esps[part] = nil
			if e.gui then pcall(function() e.gui:Destroy() end) end
			if e.box then pcall(function() e.box:Destroy() end) end
		end

		local function dsEspSweep()
			for part in pairs(ds.esps) do dsEspOff(part) end
		end

		local function dsEspSet(part, kind, text)
			local col = ESP_COLOR[kind] or C.White
			local e = ds.esps[part]
			if not e then
				local gui = new("BillboardGui", {
					Name = "O_X_DS_ESP",
					Size = UDim2.new(0, 160, 0, 16),
					StudsOffset = Vector3.new(0, 2.6, 0),
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
					TextColor3 = col,
					TextStrokeTransparency = 0.3,
					Parent = gui,
				})
				local box = new("BoxHandleAdornment", {
					Name = "O_X_DS_BOX",
					Adornee = part,
					AlwaysOnTop = true,
					ZIndex = 5,
					Transparency = 0.55,
					Color3 = col,
					Size = ESP_SIZE[kind] or Vector3.new(3, 4, 3),
					Parent = part,
				})
				ds.esps[part] = { gui = gui, label = label, box = box, kind = kind }
				return
			end
			if e.kind ~= kind then
				e.kind = kind
				e.label.TextColor3 = col
				e.box.Color3 = col
				e.box.Size = ESP_SIZE[kind] or Vector3.new(3, 4, 3)
			end
			if e.label.Text ~= text then e.label.Text = text end
		end

		local function dsEspLabel(name, part)
			if not ds.EspDist then return name end
			local d = dsDist(part)
			if d == math.huge then return name end
			return string.format("%s  [%dm]", name, math.floor(d))
		end

		local function dsRefreshEsp()
			local ws = game:GetService("Workspace")
			local seen = {}
			local function add(part, kind, name)
				if not part or seen[part] then return end
				if dsDist(part) > ds.EspRange then return end
				seen[part] = true
				dsEspSet(part, kind, dsEspLabel(name, part))
			end

			if ds.Esp then
				pcall(function()
					for _, obj in ipairs(ws:GetChildren()) do
						if ALL_ENTS[obj.Name] then add(dsPartOf(obj), "ent", obj.Name) end
					end
				end)
			end
			if ds.EspDoor or ds.EspItem or ds.EspHide then
				local rooms = dsRooms()
				pcall(function()
					if not rooms then return end
					for _, room in ipairs(rooms:GetChildren()) do
						for _, obj in ipairs(room:GetChildren()) do
							local n = obj.Name
							if ds.EspDoor and (n == "Door" or n == "RoomExit") then
								add(dsPartOf(obj), "door", L("dsTDoor"))
							elseif ds.EspItem and ITEMS[n] then
								add(dsPartOf(obj), "item", n)
							elseif ds.EspHide then
								local isHide = (obj:FindFirstChild("HidePrompt") ~= nil)
									or (obj:FindFirstChild("HidingPrompt") ~= nil)
								if isHide then add(dsPartOf(obj), "hide", L("dsTHide")) end
							end
						end
					end
				end)
			end

			for part in pairs(ds.esps) do
				if not seen[part] then dsEspOff(part) end
			end
		end

		-- ---------------- 主循环 ----------------
		local function dsStep()
			if SHUTDOWN then return end
			ds.run = ds.run + 1

			-- 1) 区域 / 门号自动检测
			local floor, room = dsAreaNow(), dsRoomNum()
			if floor ~= ds.Area or room ~= ds.RoomN then
				ds.Area, ds.RoomN = floor, room
				ds.DoorN = dsDoorNum(floor, room)
				dsRenderStatus()
			end

			-- 2) 移动类
			if ds.Noclip then pcall(dsApplyNoclip) end
			if ds.Bright then pcall(dsApplyBright) end

			-- 3) 自动类
			if ds.AutoHide then pcall(dsAutoHideStep) end
			if ds.AutoInteract or ds.AutoPickup then pcall(dsAutoDoStep) end
			if ds.AutoNext then pcall(dsAutoNextStep) end
			if ds.AutoRevive then pcall(dsAutoReviveStep) end

			-- 4) 透视（0.3s 一次，跟劫案一个思路：别每帧扫全树）
			--    用 os.clock 而不是累加 dt —— 假时钟下才好测
			local now = os.clock()
			if now - ds.lastEsp >= 0.3 then
				ds.lastEsp = now
				if ds.Esp or ds.EspItem or ds.EspDoor or ds.EspHide then
					pcall(dsRefreshEsp)
				elseif next(ds.esps) then
					pcall(dsEspSweep)
				end
			end
		end

		track(RunService.Heartbeat:Connect(dsStep))

		-- 区域 / 门号一变就刷新（比轮询更及时，也让"自动检测"更明显）
		track((function()
			local gd = dsGameData()
			local conns = {}
			if gd then
				for _, name in ipairs({ "Floor", "LatestRoom" }) do
					pcall(function()
						local v = gd:FindFirstChild(name)
						if v and v.GetPropertyChangedSignal then
							table.insert(conns, v:GetPropertyChangedSignal("Value"):Connect(function()
								if SHUTDOWN then return end
								ds.Area, ds.RoomN = dsAreaNow(), dsRoomNum()
								ds.DoorN = dsDoorNum(ds.Area, ds.RoomN)
								dsRenderStatus()
							end))
						end
					end)
				end
			end
			return {
				Disconnect = function()
					for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
				end,
			}
		end)())

		-- 复活之后把速度 / 跳跃重新按上去
		track(LocalPlayer.CharacterAdded:Connect(function()
			task.wait(1)
			if SHUTDOWN then return end
			ds.noclipped = {}
			pcall(dsApplySpeed)
		end))

		-- ---------------- 打开 / 收起 / 关闭 ----------------
		local dsPlaySplash = makeWindowSplash(dsWin, "DoorsSplash", L("srvDoors"), "srv_doors", R.win)

		local dsReopen = new("TextButton", {
			Name = "DoorsReopen",
			Size = UDim2.new(0, 116, 0, 32),
			Position = UDim2.new(0, 20, 0, 272),
			BackgroundColor3 = C.Window,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Visible = false,
			Parent = guiMain,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dsReopen })
		local dsReopenStroke = new("UIStroke", { Color = C.Stroke, Thickness = 1, Parent = dsReopen })
		local dsReopenScale = new("UIScale", { Scale = 1, Parent = dsReopen })
		bindHover(dsReopen, {
			Stroke = dsReopenStroke, StrokeOn = C.Stroke2,
			Scale = dsReopenScale, ScaleOn = 1.06,
		})

		do
			local box = new("Frame", {
				Size = UDim2.new(0, 20, 0, 20),
				Position = UDim2.new(0, 7, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = C.Card2,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Parent = dsReopen,
			})
			new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
			local a = getAsset("srv_doors")
			if a then
				new("ImageLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = a,
					ScaleType = Enum.ScaleType.Crop,
					Parent = box,
				})
			end
		end
		new("TextLabel", {
			Size = UDim2.new(1, -34, 1, 0),
			Position = UDim2.new(0, 32, 0, 0),
			BackgroundTransparency = 1,
			Text = L("srvDoors"),
			TextSize = 12,
			Font = FONT_B,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dsReopen,
		})

		local dsReopenDragged = makeDraggable(dsReopen, dsReopen, nil, { threshold = 6, clamp = true })

		local function dsHideWin()
			dsWin.Visible = false
			dsReopen.Visible = true
			dsReopenScale.Scale = 0.4
			tween(dsReopenScale, EASE.pop, { Scale = computeScale(DS_W, DS_H) })
		end

		openDoorsWindow = function()
			if dsWin.Visible then return end
			dsReopen.Visible = false
			dsWin.Visible = true
			dsScale.Scale = math.clamp(computeScale(DS_W, DS_H) * 0.9, 0.5, 1)
			tween(dsScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = computeScale(DS_W, DS_H) })
			ds.Area, ds.RoomN = dsAreaNow(), dsRoomNum()
			ds.DoorN = dsDoorNum(ds.Area, ds.RoomN)
			dsRenderStatus()
			dsPlaySplash()
			task.spawn(function()
				task.wait(0.05)
				pcall(dsRefreshEsp)
			end)
		end

		-- ✕ 只关窗口：功能状态留着（跟另外两个服务器窗口一个语义）
		DsCloseRequest = function()
			dsWin.Visible = false
			dsReopen.Visible = false
		end

		-- 结束整个脚本时：停掉所有开关，还原被改过的属性
		dsCleanup = function()
			ds.run = ds.run + 1
			ds.Esp, ds.EspItem, ds.EspDoor, ds.EspHide = false, false, false, false
			ds.AutoHide, ds.AutoInteract, ds.AutoPickup = false, false, false
			ds.AutoNext, ds.AutoRevive = false, false
			ds.Noclip, ds.Bright = false, false
			ds.hideSpot, ds.hideOn = nil, false
			pcall(dsEspSweep)
			pcall(dsRestoreCollide)
			pcall(dsApplyBright)
			local hum = getHumanoid()
			if hum then
				pcall(function() hum.WalkSpeed = 16 end)
				pcall(function()
					hum.UseJumpPower = true
					hum.JumpPower = 50
				end)
			end
			dsWin.Visible = false
			dsReopen.Visible = false
		end

		dsScale.Scale = computeScale(DS_W, DS_H)
		dsReopenScale.Scale = dsScale.Scale

		dsMinBtn.MouseButton1Click:Connect(function() dsHideWin() end)
		dsCloseBtn.MouseButton1Click:Connect(function() DsCloseRequest() end)
		dsReopen.MouseButton1Click:Connect(function()
			if dsReopenDragged() then return end
			openDoorsWindow()
		end)

		track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			task.wait(0.2)
			if SHUTDOWN or not dsWin.Visible then return end
			dsScale.Scale = computeScale(DS_W, DS_H)
		end))
	end

	local dsOk, dsErr = pcall(dsBuild)
	if not dsOk then
		warn("[O_X HUB] DOORS 初始化失败:", tostring(dsErr))
		pcall(function()
			local errLabel = Instance.new("TextLabel")
			errLabel.Name = "DoorsError"
			errLabel.Size = UDim2.new(0, 400, 0, 100)
			errLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
			errLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			errLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			errLabel.Text = "DOORS 脚本加载失败:\n" .. tostring(dsErr):sub(1, 200)
			errLabel.TextSize = 14
			errLabel.Parent = game:GetService("CoreGui")
		end)
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
		pcall(dsCleanup)
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
		-- 注意：这里**不能**清 pending —— 脚本被重新注入（或用户切语言重启）时，
		-- 上一份留下的"传送失败、下次注入重试"标记会被这行吃掉，
		-- 而 boot 里的 autoResolvePending 是在这之后才跑的，等于静默丢掉重试。
		kill()
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
