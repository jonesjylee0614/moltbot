# OpenClaw 本地调试工具箱（Windows + WSL）

本目录用于把常见的调试、认证、模型切换操作做成**短命令**，避免每次手敲长参数。

## 文件说明

- `dev-local.ps1`：Windows 启动入口，负责调起 WSL 脚本
- `dev-local-wsl.sh`：WSL 内执行安装、构建、启动
- `openclaw-dev.bat`：你日常使用的命令工具箱（推荐直接用这个）
- `codex-oauth-direct.mjs`：Codex OAuth 直连脚本（`codex-oauth` 调用）
- `..\bot.cmd`：仓库根目录快捷入口（已加入 PATH，任意目录可用 `bot ...`）

## 先决条件

- 已安装 WSL2
- WSL 内可用 `node`、`pnpm`（脚本会尽量自动修复）
- 默认 WSL 发行版名为 `Ubuntu-22.04`

如果你的发行版名不同，先在当前终端设置：

```bat
set OPENCLAW_WSL_DISTRO=你的发行版名称
```

## 一、常见启动命令（最常用）

### 1) 首次初始化（建议第一次先跑）

```bat
bot init
```

会执行：安装依赖 + 构建，但不启动服务。

### 2) 启动全部（UI + Gateway，最常用）

```bat
bot full
```

> **注意**：`bot full` 不会重新编译，直接启动，很快。

如果你希望自动打开浏览器，再启动全链路：

```bat
bot full-open
```

如果代码有改动需要重新编译：

```bat
bot full-init
```

### 3) 单独启动 Gateway（不启动 UI）

```bat
bot gateway
```

等价于 `bot dev`。如果需要热重载（代码改了自动重启）：

```bat
bot watch
```

### 4) 单独启动 UI 开发服务器（不启动 Gateway）

```bat
bot ui-dev
```

> 适合只改 UI 代码、Gateway 已经在另一个终端运行的场景。

### 5) 打开 UI 页面（不启动任何服务）

```bat
bot ui
```

只是用浏览器打开 `http://localhost:5173/?gatewayUrl=ws://127.0.0.1:19001`。

### 6) 自动测试启动（例如跑 180 秒）

```bat
bot full-test 180
```

用于验证能否拉起，时间到会自动停止。

## 二、`Disconnected from gateway` 的处理

最常见原因是 UI 未指向正确的 WebSocket 地址。

### 一键修复

```bat
bot ui
```

它会打开 `http://localhost:5173/?gatewayUrl=ws://127.0.0.1:19001`。

### 诊断命令

```bat
bot status
bot diag-disconnect
bot logs
```

## 三、Codex Auth 授权（你关心的重点）

### 1) 强制浏览器 OAuth 登录（推荐首次使用）

```bat
bot codex-oauth
```

终端会**清晰打印**一个 `https://auth.openai.com/...` 的 URL：
1. 复制 URL 到浏览器打开
2. 完成登录
3. 浏览器跳转到 `localhost:1455/...` 地址
4. 复制那个完整的跳转地址，粘贴回终端按 Enter

### 2) 智能登录（优先复用本地凭据）

```bat
bot codex-login
```

- 优先复用 `~/.codex/auth.json`（如果 token 仍有效，免重复登录）
- 如果 token 已过期或不存在，自动回退到浏览器 OAuth（和 `codex-oauth` 一样）

### 3) 检查授权状态

```bat
bot auth-status
```

## 四、模型切换（聊天模型 / 编码模型）

### 列出可用模型

```bat
bot model-list
```

### 手动切换

```bat
bot model-set openai-codex/gpt-5.2-codex
```

### 快捷命令

```bat
bot model-chat    # 切到日常聊天模型
bot model-code    # 切到代码模型
```

## 五、其他实用命令

```bat
bot dashboard     # 输出 dashboard 地址
bot doctor        # 运行体检
bot help          # 查看所有命令
```

## 六、推荐日常流程

1. 首次：`bot init`
2. 授权：`bot codex-oauth`
3. 切模型：`bot model-code`
4. 启动：`bot full`
5. 如断连：`bot ui`
6. 看日志：`bot logs`

## 七、分开启动的场景

如果你想在两个终端分别运行 Gateway 和 UI：

**终端 1（Gateway）：**
```bat
bot gateway
```

**终端 2（UI）：**
```bat
bot ui-dev
```

这样修改 UI 代码时会热更新，修改 Gateway 代码需要重启 `bot gateway`。

## 八、Telegram 接入

### 1) 获取 Bot Token

在 Telegram 中找 @BotFather → `/newbot` → 获取一个 `123456:ABC-DEF...` 格式的 token。

### 2) 配置 Telegram Bot

```bat
bot tg-add <你的token>
```

例如：
```bat
bot tg-add 8324978990:AAETg6Ox-AhxKyox6_7jk7rAjRLaExICCfo
```

这会自动：
- 在配置中启用 telegram 插件
- 写入 bot token
- 同时更新默认和 dev 两个 profile

如果需要添加多个 Telegram bot（非默认账号）：
```bat
bot tg-add <token> alerts
```

### 3) 启动 Gateway

```bat
bot full
```

> 注意：telegram channel 只在 Gateway 运行时才会激活。`bot full` 会启动 Gateway（不带 `OPENCLAW_SKIP_CHANNELS`），所以 Telegram 会正常加载。

### 4) 检查状态

```bat
bot tg-status
```

应该显示 `Telegram default: configured, token=config, enabled`。

### 5) 配对

在 Telegram 中向你的 bot 发送 `/start`，然后：

```bat
bot pair-list          # 查看待配对请求
bot pair-approve <code> # 批准配对
```

### 6) 查看已配置频道

```bat
bot channels
```

### 7) 安全加固（只允许你自己使用）

**默认行为**：OpenClaw 使用**配对机制**。未配对的用户发消息给 bot 时，bot **不会处理消息**，只会返回一个配对码。只有你手动批准后该用户才能使用。

如果你想**完全锁定**，只允许你自己 DM，并禁止所有群组：

```bat
bot tg-lock <你的Telegram User ID>
```

> 获取你的 Telegram User ID：在 Telegram 中搜索 `@userinfobot`，给它发消息即可获取。

这会设置：
- `dmPolicy = "allowlist"` — 只有你能 DM
- `groupPolicy = "disabled"` — 禁止所有群组使用

设置后需要重启 Gateway（`bot full`）才会生效。

### 常见问题

**Q: 启动 Gateway 后 Telegram 没有连接？**

脚本会自动检测配置中是否有启用的 channel。如果检测到（如 Telegram），会自动绕过 `OPENCLAW_SKIP_CHANNELS=1`，直接启动 gateway 并加载所有已启用的 channels。如果仍然有问题，检查：
1. `bot tg-status` 确认 Telegram 已配置
2. 确保 bot token 正确（从 @BotFather 获取）
3. 查看日志 `bot logs`

**Q: "Unknown channel: telegram"？**

说明 telegram 插件未启用。重新运行 `bot tg-add <token>` 来启用它。

## 九、多电脑控制（Node 模式）

### 架构

```
        Telegram / UI
            │
      ┌─────▼─────┐
      │  Gateway   │  ← 主电脑 (bot full)
      │  :18789    │
      └──┬────┬────┘
         │    │
    ┌────▼┐  ┌▼────┐
    │Node A│  │Node B│  ← 其他电脑
    └─────┘  └─────┘
```

### 1) 主电脑运行 Gateway

```bat
bot full
```

### 2) 其他电脑连接为 Node

在其他电脑安装 OpenClaw 后运行：

```bash
openclaw node run --host <主电脑IP> --port 18789 --display-name "办公电脑"
```

或安装为后台服务：
```bash
openclaw node install --host <主电脑IP> --port 18789 --display-name "办公电脑"
```

### 3) 主电脑批准 Node

```bat
bot node-pending            :: 查看待批准节点
bot node-approve <id>       :: 批准节点
```

### 4) 管理 Node

```bat
bot node-list               :: 查看所有节点
bot node-status             :: 查看节点状态和能力
bot node-run <id> "cmd"     :: 在指定节点执行命令
```

### 网络需求

- 端口 18789（WebSocket），需要局域网可达
- Gateway 需设置 token 认证（`gateway.auth.token`）
- 如 Gateway 仅绑定 loopback，可用 SSH 隧道或 Tailscale

## 十、Android 端编译与部署

项目包含一个完整的 Android 原生应用（`apps/android/`），使用 **Kotlin + Jetpack Compose** 构建。Android 端以**节点 (Node)** 身份连接 Gateway，提供手机端的摄像头、语音、短信、位置等能力。

### 编译 APK

```bat
bot android-build
```

编译成功后，APK 位于：`apps/android/app/build/outputs/apk/debug/openclaw-<版本>-debug.apk`

> **首次编译注意**：需要下载 Gradle 和依赖（约 2-3 分钟）。后续增量编译很快。
>
> **JDK 要求**：使用 ZGC 垃圾回收器（已自动配置），避免 JDK 21 G1 GC 崩溃问题。

### 获取 APK 文件

```bat
bot android-apk
```

会将 APK 复制到当前目录为 `openclaw-debug.apk`，方便传输到手机安装。

### 安装到手机

**方法一：USB + ADB（推荐）**

```bat
bot android-apk
adb install openclaw-debug.apk
```

**方法二：直接编译安装**（需要 USB 连接手机）

```bat
bot android-install
```

**方法三：手动传输**

将 `openclaw-debug.apk` 通过微信/QQ/网盘发送到手机，直接安装。

### 编译 + 安装 + 启动

```bat
bot android-run
```

一条命令完成编译、安装、启动应用（需要 USB 连接手机）。

### 运行单元测试

```bat
bot android-test
```

### 清理编译缓存

```bat
bot android-clean
```

### Android 连接 Gateway 完整指南

#### 架构关系

```
你的电脑 (Windows)             你的手机 (Android)
┌─────────────────┐            ┌──────────────────┐
│ bot full         │            │  OpenClaw App    │
│ (Gateway :18789) │◄─ WiFi ──►│  (节点 Node)      │
│                  │  WebSocket │                  │
│  Web UI (:5173)  │            │  提供:            │
│                  │            │  - 摄像头          │
│  AI 模型连接      │            │  - 语音对话        │
│                  │            │  - 短信           │
│                  │            │  - GPS 位置       │
└─────────────────┘            └──────────────────┘
```

#### 第一步：启动 Gateway

在电脑上运行：

```bat
bot full
```

确保 Gateway 在 **端口 18789** 上监听。

#### 第二步：安装并打开 App

在手机上安装 `openclaw-debug.apk`，打开 OpenClaw 应用。

#### 第三步：连接 Gateway

**自动发现（同一 WiFi）：**

手机和电脑在**同一个 WiFi 网络**时，App 会自动通过 **mDNS/NSD** 发现 Gateway。
你会在 App 中看到你的 Gateway 名称，点击即可连接。

**手动连接（自动发现失败时）：**

1. 在 App 中进入 **Settings → Advanced → Manual Gateway**
2. 输入电脑的局域网 IP 地址（如 `192.168.1.100`）
3. 端口填 `18789`（默认）
4. 如果 Gateway 设置了 token，在 **Gateway Token** 栏输入 token
5. 点击 **Connect (Manual)**

> 获取电脑 IP：在 cmd 中运行 `ipconfig`，找到你 WiFi 网卡的 IPv4 地址。
>
> 获取 Gateway token：查看 `~/.openclaw-dev/openclaw.json` 中的 `gateway.auth.token`，
> 或运行 `bot status` 查看。

#### 第四步：批准配对

首次连接时，Gateway 需要批准你的手机：

```bat
bot node-pending          :: 查看待批准的设备
bot node-approve <id>     :: 批准配对
```

批准后，手机会收到一个 device token，下次连接自动认证，无需再次批准。

#### 第五步：开始使用

连接成功后，你可以：

- **聊天**：在 App 中直接与 AI 对话
- **语音**：使用 Talk 模式进行语音交互
- **摄像头**：AI 可以调用你手机的摄像头拍照
- **位置**：AI 可以获取你的 GPS 位置
- **短信**：AI 可以读取/发送短信（需授权）

### 跨网络连接（Tailscale）

如果手机和电脑不在同一个网络（如手机用 4G、电脑在家里），可以使用 **Tailscale**：

1. 电脑和手机都安装 Tailscale 并登录同一账号
2. App 的 Manual Gateway 中输入电脑的 **Tailscale IP**（100.x.x.x）
3. 端口同样是 `18789`
4. 也支持 Wide-Area Bonjour 自动发现（需设置 `OPENCLAW_WIDE_AREA_DOMAIN`）

### 常见问题

**Q: App 找不到 Gateway？**

1. 确认手机和电脑在**同一 WiFi** 网络
2. 检查 Gateway 是否在运行（`bot status`）
3. 检查电脑防火墙是否放行了端口 **18789**
4. 尝试手动连接（输入 IP + 端口）

**Q: 连接后显示 "Pairing required"？**

正常现象，在电脑上执行 `bot node-pending` 查看并 `bot node-approve <id>` 批准即可。

**Q: 编译时 Gradle daemon 崩溃？**

已知 JDK 21 G1 GC 存在 bug。`bot android-build` 命令已自动配置 ZGC 回避此问题。
如果仍然崩溃，尝试 `bot android-clean` 后重新编译。

### 其他平台客户端

项目还包含：
- **iOS 应用**：`apps/ios/`（Swift，需要 macOS + Xcode）
- **macOS 菜单栏应用**：`apps/macos/`（Swift，需要 macOS）

这些平台只能在 macOS 上编译，Windows 用户请使用 Android 或 Web UI。
