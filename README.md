# Roblox Scripts

Roblox 执行器脚本集合，通过 `loadstring` + `HttpGet` 分发。

## 脚本列表

| 文件 | 说明 |
| --- | --- |
| `O_X_HUB.lua` | 加载动画 + 飞行面板 |

## 用法

执行器里粘贴执行：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hxhdsg666/O_X/refs/heads/main/O_X_HUB.lua"))()
```

改完脚本发现还是旧效果，加时间戳破缓存：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/hxhdsg666/O_X/refs/heads/main/O_X_HUB.lua?t=" .. os.time()))()
```

## O_X_HUB.lua 功能

**加载动画** — 全屏深色遮罩 + LOGO + 5 阶段进度条，走完自动淡出。

**飞行面板**（左上角可拖动）

| 操作 | 说明 |
| --- | --- |
| `F` / 点按钮 | 开关飞行 |
| `W A S D` | 沿相机视角水平移动 |
| `空格` | 上升 |
| `左Ctrl` / `左Shift` | 下降 |
| 速度滑块 | 10 ~ 300 |

移动端自动在右侧出现 ▲ / ▼ 升降按钮，方向由摇杆控制。角色复活后若飞行原为开启状态会自动恢复。

## 注意

- 地址必须是 `raw.githubusercontent.com`，用 `github.com/.../blob/...` 会拿到 HTML，`loadstring` 会报语法错误。
- 仓库必须**公开**，私有仓库的 raw 地址需要鉴权，执行器取不到。
- 文件名建议保持纯英文，部分执行器的 `HttpGet` 对非 ASCII 路径处理不一致。
