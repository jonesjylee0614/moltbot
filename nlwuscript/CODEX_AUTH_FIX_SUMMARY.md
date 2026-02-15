# Codex 授权修复记录（2026-02-15）

## 问题现象

- 执行 `bot codex-login` 时出现：
  - `Error: No provider plugins found. Install one via openclaw plugins install`

## 根因

- 旧登录路径使用了 `models auth login --provider openai-codex`，该路径依赖 provider 插件。
- 当前环境未安装 provider 插件，因此直接报错。

## 已做修改

- 更新 `nlwuscript/dev-local-wsl.sh`：
  - 新增 `--mode codex-auth`
  - 逻辑：优先复用 `~/.codex/auth.json` 导入 OpenClaw 认证；如果不存在可复用凭据，再回退到内置 OAuth 引导
- 更新 `nlwuscript/dev-local.ps1`：
  - `Mode` 增加 `codex-auth` 透传支持
- 更新 `nlwuscript/openclaw-dev.bat`：
  - `codex-login` 改为调用 `dev-local.ps1 -Mode codex-auth -SkipInstall -SkipBuild`
- 更新 `nlwuscript/README.zh-CN.md`：
  - 补充 `codex-login` 新链路说明（不依赖 provider 插件）
  - 增加对应报错说明与原因

## 本机实操结果

- 检测到已有 Codex CLI 凭据：`~/.codex/auth.json`（含 access/refresh token）
- 已将该凭据导入 OpenClaw：
  - 写入 `~/.openclaw/agents/main/agent/auth-profiles.json`
  - 更新 `~/.openclaw/openclaw.json` 的 `auth.profiles/auth.order`
  - 默认模型设为 `openai-codex/gpt-5.2-codex`

## 验证

- `bot auth-status`：显示 `openai-codex (OAuth)` 可用
- `bot model-list`：成功返回 `openai-codex/gpt-5.2-codex`
- `bot model-code`：成功设置默认模型为 `openai-codex/gpt-5.2-codex`

## 后续建议

- 若未来 token 过期，优先执行 `bot codex-login` 走 OAuth 续期。
- 日常先用 `bot auth-status` 做健康检查，再启动 `bot dev`/`bot full-open`。
