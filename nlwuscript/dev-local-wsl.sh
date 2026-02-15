#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: dev-local-wsl.sh [options]

Options:
  --repo <path>            Repository path in WSL (default: current directory)
  --mode <check|dev|watch|full|ui-dev|exec|codex-auth|codex-oauth>
                           check: only verify environment/install/build, then exit
                           dev:   run pnpm gateway:dev
                           watch: run pnpm gateway:watch --force
                           full:  run gateway:dev + ui:dev together
                           exec:  run one custom command after runtime checks
                           codex-auth: import ~/.codex/auth.json, fallback to OAuth
  --skip-install           Skip pnpm install
  --skip-build             Skip pnpm ui:build and pnpm build
  --reinstall              Use pnpm install --force
  --duration-seconds <n>   For tests: run long process for n seconds then stop
  --exec-cmd "<cmd>"       Command string used by --mode exec
  --raw-stream             Enable OPENCLAW_RAW_STREAM=1
  --raw-stream-path <path> Set OPENCLAW_RAW_STREAM_PATH
  --help                   Show this help
EOF
}

log() {
  printf '[dev-local] %s\n' "$*"
}

die() {
  printf '[dev-local] ERROR: %s\n' "$*" >&2
  exit 1
}

REPO_PATH=""
MODE="dev"
SKIP_INSTALL=0
SKIP_BUILD=0
REINSTALL=0
DURATION_SECONDS=0
RAW_STREAM=0
RAW_STREAM_PATH=""
EXEC_CMD=""

normalize_home() {
  if [[ -n "${HOME:-}" && "$HOME" =~ ^[A-Za-z]: ]]; then
    local linux_home=""
    linux_home="$(getent passwd "$(id -un)" | cut -d: -f6 2>/dev/null || true)"
    if [[ -n "$linux_home" && -d "$linux_home" ]]; then
      export HOME="$linux_home"
    fi
  fi
}

ensure_node_runtime() {
  command -v node >/dev/null 2>&1 || true
  local node_major
  node_major="$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)"
  if [[ "$node_major" =~ ^[0-9]+$ ]] && (( node_major >= 22 )); then
    return 0
  fi

  local candidates=()
  if [[ -n "${NVM_DIR:-}" ]]; then
    candidates+=("${NVM_DIR}/nvm.sh")
  fi
  if [[ -n "${HOME:-}" ]]; then
    candidates+=("${HOME}/.nvm/nvm.sh")
  fi
  local passwd_home=""
  passwd_home="$(getent passwd "$(id -un)" | cut -d: -f6 2>/dev/null || true)"
  if [[ -n "$passwd_home" ]]; then
    candidates+=("${passwd_home}/.nvm/nvm.sh")
  fi

  local nvm_script=""
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -s "$candidate" ]]; then
      nvm_script="$candidate"
      break
    fi
  done

  if [[ -n "$nvm_script" ]]; then
    # shellcheck disable=SC1090
    . "$nvm_script"
    if command -v nvm >/dev/null 2>&1; then
      log "Node <22 detected. Trying nvm install/use 22."
      nvm install 22 >/dev/null
      nvm use 22 >/dev/null
      node_major="$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)"
      if [[ "$node_major" =~ ^[0-9]+$ ]] && (( node_major >= 22 )); then
        return 0
      fi
    fi
  fi

  die "Node.js major version must be >=22 (current: $(node -v 2>/dev/null || echo missing))"
}

ensure_pnpm_runtime() {
  if command -v pnpm >/dev/null 2>&1 && pnpm -v >/dev/null 2>&1; then
    return 0
  fi

  command -v corepack >/dev/null 2>&1 || die "pnpm not found and corepack is unavailable"
  log "Preparing pnpm@10.23.0 with corepack"
  corepack enable >/dev/null 2>&1 || true
  corepack prepare pnpm@10.23.0 --activate >/dev/null
  command -v pnpm >/dev/null 2>&1 || die "pnpm is still unavailable after corepack prepare"
  pnpm -v >/dev/null 2>&1 || die "pnpm command exists but cannot execute"
}

bootstrap_openclaw_state() {
  local config_path="$HOME/.openclaw/openclaw.json"
  if [[ -f "$config_path" ]]; then
    return 0
  fi

  log "Bootstrapping ~/.openclaw config (non-interactive)"
  if ! pnpm openclaw onboard --non-interactive --accept-risk --auth-choice skip --skip-channels --skip-skills --skip-ui --no-install-daemon --flow quickstart; then
    log "Bootstrap returned non-zero. Continuing if config file now exists."
  fi

  [[ -f "$config_path" ]] || die "Failed to initialize OpenClaw config: $config_path"
}

import_codex_cli_auth() {
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - <<'PY'
import json
import os
import pathlib
import sys

home = pathlib.Path.home()
codex_auth = home / ".codex" / "auth.json"
if not codex_auth.exists():
  print("NO_CODEX_AUTH_FILE")
  sys.exit(2)

raw = json.loads(codex_auth.read_text())
tokens = raw.get("tokens") or {}
access = tokens.get("access_token")
refresh = tokens.get("refresh_token")
account_id = tokens.get("account_id")
if not access or not refresh:
  print("INVALID_CODEX_AUTH_FILE")
  sys.exit(3)

expires = int(codex_auth.stat().st_mtime * 1000) + 60 * 60 * 1000
cred = {
  "type": "oauth",
  "provider": "openai-codex",
  "access": access,
  "refresh": refresh,
  "expires": expires,
}
if isinstance(account_id, str) and account_id:
  cred["accountId"] = account_id

# Write to both default and dev profiles
for profile_suffix in ["", "-dev"]:
  state_dir = home / f".openclaw{profile_suffix}"
  if profile_suffix and not state_dir.exists():
    print(f"SKIP_PROFILE_{profile_suffix}")
    continue

  agent_dir = state_dir / "agents" / "main" / "agent"
  agent_dir.mkdir(parents=True, exist_ok=True)
  auth_path = agent_dir / "auth-profiles.json"

  store = {"version": 1, "profiles": {}}
  if auth_path.exists():
    try:
      parsed = json.loads(auth_path.read_text())
      if isinstance(parsed, dict):
        store = parsed
    except Exception:
      pass

  if not isinstance(store, dict):
    store = {"version": 1, "profiles": {}}
  store.setdefault("version", 1)
  profiles = store.setdefault("profiles", {})
  if not isinstance(profiles, dict):
    profiles = {}
    store["profiles"] = profiles

  profiles["openai-codex:default"] = dict(cred)
  auth_path.write_text(json.dumps(store, ensure_ascii=False, indent=2))
  os.chmod(auth_path, 0o600)

  config_path = state_dir / "openclaw.json"
  if config_path.exists():
    cfg = json.loads(config_path.read_text())
    if not isinstance(cfg, dict):
      cfg = {}
  else:
    cfg = {}

  auth_cfg = cfg.setdefault("auth", {})
  profiles_cfg = auth_cfg.setdefault("profiles", {})
  profiles_cfg["openai-codex:default"] = {"provider": "openai-codex", "mode": "oauth"}
  order_cfg = auth_cfg.setdefault("order", {})
  existing = [x for x in order_cfg.get("openai-codex", []) if x != "openai-codex:default"]
  order_cfg["openai-codex"] = ["openai-codex:default", *existing]

  agents = cfg.setdefault("agents", {})
  defaults = agents.setdefault("defaults", {})
  model = defaults.setdefault("model", {})
  model["primary"] = "openai-codex/gpt-5.2-codex"

  config_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
  os.chmod(config_path, 0o600)
  print(f"IMPORTED_CODEX_AUTH_OK ({state_dir})")

PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || die "--repo requires a value"
      REPO_PATH="$2"
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || die "--mode requires a value"
      MODE="$2"
      shift 2
      ;;
    --skip-install)
      SKIP_INSTALL=1
      shift
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --reinstall)
      REINSTALL=1
      shift
      ;;
    --duration-seconds)
      [[ $# -ge 2 ]] || die "--duration-seconds requires a value"
      DURATION_SECONDS="$2"
      shift 2
      ;;
    --exec-cmd)
      [[ $# -ge 2 ]] || die "--exec-cmd requires a value"
      EXEC_CMD="$2"
      shift 2
      ;;
    --raw-stream)
      RAW_STREAM=1
      shift
      ;;
    --raw-stream-path)
      [[ $# -ge 2 ]] || die "--raw-stream-path requires a value"
      RAW_STREAM_PATH="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

case "$MODE" in
  check|dev|watch|full|ui-dev|exec|codex-auth|codex-oauth) ;;
    *)
      die "Invalid --mode '$MODE' (expected check|dev|watch|full|ui-dev|exec|codex-auth|codex-oauth)"
    ;;
esac

if ! [[ "$DURATION_SECONDS" =~ ^[0-9]+$ ]]; then
  die "--duration-seconds must be a non-negative integer"
fi

if [[ "$MODE" == "exec" && -z "$EXEC_CMD" ]]; then
  die "--mode exec requires --exec-cmd"
fi

if [[ -n "$REPO_PATH" ]]; then
  cd "$REPO_PATH"
fi

normalize_home
REPO_ROOT="$(pwd)"
[[ -f "$REPO_ROOT/package.json" ]] || die "Not a repo root (missing package.json): $REPO_ROOT"
[[ -d "$REPO_ROOT/src" ]] || die "Not a repo root (missing src directory): $REPO_ROOT"

log "Repo root: $REPO_ROOT"

command -v bash >/dev/null 2>&1 || die "bash not found"
ensure_node_runtime
ensure_pnpm_runtime

if (( RAW_STREAM == 1 )); then
  export OPENCLAW_RAW_STREAM=1
fi
if [[ -n "$RAW_STREAM_PATH" ]]; then
  export OPENCLAW_RAW_STREAM_PATH="$RAW_STREAM_PATH"
fi

if (( SKIP_INSTALL == 0 )); then
  if (( REINSTALL == 1 )); then
    log "Installing dependencies with --force"
    pnpm install --force
  else
    log "Installing dependencies"
    pnpm install
  fi
else
  log "Skipping dependency install"
fi

if (( SKIP_BUILD == 0 )); then
  log "Building TypeScript dist"
  pnpm build
  log "Building Control UI assets"
  pnpm ui:build
else
  log "Skipping build steps"
fi

if [[ "$MODE" == "check" ]]; then
  log "Check mode done: environment/install/build succeeded."
  exit 0
fi

run_codex_oauth() {
  # Direct OAuth — no onboard wizard prompts, no spinners.
  # Uses a standalone Node.js script that calls loginOpenAICodex directly.
  local script_path="$REPO_PATH/nlwuscript/codex-oauth-direct.mjs"
  if [[ ! -f "$script_path" ]]; then
    die "codex-oauth-direct.mjs not found at $script_path"
  fi
  node "$script_path"
}

if [[ "$MODE" == "codex-oauth" ]]; then
  bootstrap_openclaw_state
  run_codex_oauth
  exit 0
fi

if [[ "$MODE" == "codex-auth" ]]; then
  bootstrap_openclaw_state
  if import_codex_cli_auth; then
    # Check if the imported token is still valid (not expired)
    local_status_output="$(pnpm openclaw models status 2>&1 || true)"
    if echo "$local_status_output" | grep -qE 'openai-codex:default ok'; then
      log "Imported existing ~/.codex/auth.json into OpenClaw auth profiles."
      pnpm openclaw models set openai-codex/gpt-5.2-codex 2>/dev/null || true
      echo "$local_status_output"
      exit 0
    fi
    log "Imported token from ~/.codex/auth.json is expired. Need fresh OAuth login."
  else
    log "No reusable Codex CLI auth found."
  fi

  log "Falling back to OAuth browser login."
  run_codex_oauth
  exit 0
fi

cleanup_pids=()
cleanup() {
  local pid
  for pid in "${cleanup_pids[@]}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
    fi
  done
}
trap cleanup EXIT INT TERM

run_with_optional_timeout() {
  local seconds="$1"
  shift
  if (( seconds == 0 )); then
    exec "$@"
  fi

  "$@" &
  local cmd_pid=$!
  cleanup_pids+=("$cmd_pid")
  log "Started PID $cmd_pid. Auto-stop in ${seconds}s for test run."
  sleep "$seconds"

  if kill -0 "$cmd_pid" >/dev/null 2>&1; then
    log "Timeout reached. Stopping PID $cmd_pid."
    kill "$cmd_pid" >/dev/null 2>&1 || true
    wait "$cmd_pid" >/dev/null 2>&1 || true
    return 0
  fi

  wait "$cmd_pid"
}

run_gateway_cmd() {
  local cmd=()
  case "$MODE" in
    dev)
      # Check if any channels are configured (e.g. telegram).
      # If so, run the gateway directly without OPENCLAW_SKIP_CHANNELS=1.
      # Otherwise, use pnpm gateway:dev (which skips channels for speed).
      if has_configured_channels; then
        log "Channels detected in config — starting gateway WITH channels enabled"
        cmd=(node scripts/run-node.mjs --dev gateway)
      else
        cmd=(pnpm gateway:dev)
      fi
      ;;
    watch)
      cmd=(pnpm gateway:watch --force)
      ;;
    *)
      die "run_gateway_cmd called with invalid MODE=$MODE"
      ;;
  esac

  log "Running: ${cmd[*]}"
  run_with_optional_timeout "$DURATION_SECONDS" "${cmd[@]}"
}

has_configured_channels() {
  # Return 0 (true) if any chat channel is enabled in the dev config.
  if ! command -v python3 >/dev/null 2>&1; then
    return 1
  fi
  python3 -c "
import json, pathlib, sys
for profile in ['.openclaw-dev', '.openclaw']:
    p = pathlib.Path.home() / profile / 'openclaw.json'
    if not p.exists():
        continue
    try:
        cfg = json.loads(p.read_text())
    except Exception:
        continue
    channels = cfg.get('channels', {})
    for ch_id, ch_cfg in channels.items():
        if isinstance(ch_cfg, dict) and ch_cfg.get('enabled'):
            sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

if [[ "$MODE" == "exec" ]]; then
  log "Running custom command: $EXEC_CMD"
  run_with_optional_timeout "$DURATION_SECONDS" bash -lc "$EXEC_CMD"
  exit 0
fi

if [[ "$MODE" == "ui-dev" ]]; then
  log "Starting UI dev server (foreground)"
  log "UI: http://localhost:5173/?gatewayUrl=ws://127.0.0.1:19001"
  run_with_optional_timeout "$DURATION_SECONDS" pnpm ui:dev --host 0.0.0.0 --port 5173
  exit 0
fi

if [[ "$MODE" == "full" ]]; then
  log "Starting UI dev server in background"
  pnpm ui:dev --host 0.0.0.0 --port 5173 &
  UI_PID=$!
  cleanup_pids+=("$UI_PID")
  log "UI dev PID: $UI_PID"
  # Read gateway token from dev config
  gw_token=""
  if command -v python3 >/dev/null 2>&1; then
    gw_token="$(python3 -c "
import json, pathlib
p = pathlib.Path.home() / '.openclaw-dev' / 'openclaw.json'
c = json.loads(p.read_text()) if p.exists() else {}
print(c.get('gateway',{}).get('auth',{}).get('token',''))
" 2>/dev/null || true)"
  fi
  if [[ -n "$gw_token" ]]; then
    log "UI URL (with token):"
    log "  http://localhost:5173/?gatewayUrl=ws://127.0.0.1:19001&token=$gw_token"
  else
    log "UI URL:"
    log "  http://localhost:5173/?gatewayUrl=ws://127.0.0.1:19001"
  fi

  MODE="dev"
  run_gateway_cmd
  exit 0
fi

run_gateway_cmd
