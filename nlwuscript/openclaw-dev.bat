@echo off
setlocal EnableExtensions
chcp 65001 >nul
if defined OPENCLAW_DEV_DEBUG echo on

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_DIR=%%~fI"

set "WSL_DISTRO=%OPENCLAW_WSL_DISTRO%"
if not defined WSL_DISTRO set "WSL_DISTRO=Ubuntu-22.04"

set "ACTION=%~1"
if not defined ACTION goto :help

if /I "%ACTION%"=="help" goto :help
if /I "%ACTION%"=="init" goto :init
if /I "%ACTION%"=="dev" goto :dev
if /I "%ACTION%"=="watch" goto :watch
if /I "%ACTION%"=="full" goto :full
if /I "%ACTION%"=="full-open" goto :full_open
if /I "%ACTION%"=="full-init" goto :full_init
if /I "%ACTION%"=="full-test" goto :full_test
if /I "%ACTION%"=="ui" goto :ui
if /I "%ACTION%"=="ui-dev" goto :ui_dev
if /I "%ACTION%"=="gateway" goto :gateway
if /I "%ACTION%"=="stop" goto :stop
if /I "%ACTION%"=="restart" goto :restart
if /I "%ACTION%"=="status" goto :status
if /I "%ACTION%"=="diag-disconnect" goto :diag_disconnect
if /I "%ACTION%"=="logs" goto :logs
if /I "%ACTION%"=="doctor" goto :doctor
if /I "%ACTION%"=="dashboard" goto :dashboard
if /I "%ACTION%"=="codex-login" goto :codex_login
if /I "%ACTION%"=="codex-oauth" goto :codex_oauth
if /I "%ACTION%"=="auth-status" goto :auth_status
if /I "%ACTION%"=="model-list" goto :model_list
if /I "%ACTION%"=="model-set" goto :model_set
if /I "%ACTION%"=="model-chat" goto :model_chat
if /I "%ACTION%"=="model-code" goto :model_code
if /I "%ACTION%"=="think" goto :think
if /I "%ACTION%"=="tg-add" goto :tg_add
if /I "%ACTION%"=="tg-lock" goto :tg_lock
if /I "%ACTION%"=="tg-status" goto :tg_status
if /I "%ACTION%"=="tg-list" goto :tg_list
if /I "%ACTION%"=="channels" goto :channels
if /I "%ACTION%"=="pair-list" goto :pair_list
if /I "%ACTION%"=="pair-approve" goto :pair_approve
if /I "%ACTION%"=="node-list" goto :node_list
if /I "%ACTION%"=="node-pending" goto :node_pending
if /I "%ACTION%"=="node-approve" goto :node_approve
if /I "%ACTION%"=="node-status" goto :node_status
if /I "%ACTION%"=="node-run" goto :node_run
if /I "%ACTION%"=="ngrok" goto :ngrok
if /I "%ACTION%"=="plugins-all" goto :plugins_all
if /I "%ACTION%"=="plugins-list" goto :plugins_list
if /I "%ACTION%"=="browser-setup" goto :browser_setup
if /I "%ACTION%"=="browser-ext" goto :browser_ext
if /I "%ACTION%"=="browser-status" goto :browser_status
if /I "%ACTION%"=="android-build" goto :android_build
if /I "%ACTION%"=="android-install" goto :android_install
if /I "%ACTION%"=="android-run" goto :android_run
if /I "%ACTION%"=="android-test" goto :android_test
if /I "%ACTION%"=="android-apk" goto :android_apk
if /I "%ACTION%"=="android-clean" goto :android_clean
if /I "%ACTION%"=="exec" goto :exec

echo [openclaw-dev] Unknown command: %ACTION%
echo.
goto :help

:help
echo ================== OpenClaw Local Dev Toolbox ==================
echo Repo Dir : %REPO_DIR%
echo WSL Distro: %WSL_DISTRO%
echo.
echo Usage:
echo   openclaw-dev.bat ^<command^> [args]
echo.
echo Startup:
echo   init                  First-time setup (install + build only)
echo   dev                   Start gateway dev mode (skip install/build)
echo   watch                 Start gateway watch mode (skip install/build)
echo   full                  Start UI + gateway (skip install/build)
echo   full-open             Open fixed UI URL, then start UI + gateway
echo   full-init             Start UI + gateway with install/build
echo   full-test [seconds]   Full start for test and auto-stop (default 120)
echo   ui                    Open fixed UI URL in browser
echo   ui-dev                Start UI dev server only (no gateway)
echo   stop                  Stop all running Gateway/UI processes
echo   restart               Stop then start full (UI + gateway)
echo   gateway               Start gateway only (no UI, same as dev)
echo.
echo Diagnostics:
echo   status                Check gateway + models status
echo   diag-disconnect       Quick checks for "Disconnected from gateway"
echo   logs                  Follow gateway logs
echo   doctor                Run openclaw doctor
echo   dashboard             Print dashboard URL (no auto-open)
echo.
echo Auth and models:
echo   codex-login           Smart login: reuse ~/.codex, auto-fallback OAuth
echo   codex-oauth           Force browser OAuth (print URL for you to copy)
echo   auth-status           Show auth/model status
echo   model-list            List available models
echo   model-set ^<id^>       Set default model (provider/model)
echo   model-chat            Set openai-codex/gpt-5.2
echo   model-code            Set openai-codex/gpt-5.2-codex
echo   think ^<level^>        Set default thinking (off/minimal/low/medium/high/xhigh)
echo.
echo Telegram:
echo   tg-add ^<token^> [acct] Add Telegram bot by token (acct default: default)
echo   tg-lock ^<uid^>        Lock bot to your Telegram User ID only
echo   tg-status             Show Telegram channel status
echo   tg-list               List all configured channels
echo   channels              Same as tg-list
echo   pair-list             List pending pairing requests
echo   pair-approve ^<code^>  Approve a pairing request
echo.
echo Nodes (multi-computer):
echo   node-list             List all connected/paired nodes
echo   node-pending          List pending node pairing requests
echo   node-approve ^<id^>    Approve a node pairing request
echo   node-status           Show node status and capabilities
echo   node-run ^<id^> ^<cmd^>  Run command on remote node
echo.
echo Plugins:
echo   plugins-all           Enable ALL bundled plugins
echo   plugins-list          List current plugin status
echo.
echo Browser Relay (Chrome extension):
echo   browser-setup         Enable browser relay in config
echo   browser-ext           Install Chrome extension (print path)
echo   browser-status        Check browser control service status
echo.
echo Android (apps/android):
echo   android-build         Build debug APK
echo   android-install       Build and install APK to connected device
echo   android-run           Build, install and launch on device
echo   android-test          Run unit tests
echo   android-apk           Show built APK path (copy to current dir)
echo   android-clean         Clean build cache
echo.
echo Network:
echo   ngrok [port]          Start ngrok tunnel (default port: 19001)
echo.
echo Advanced:
echo   exec ^<cmd^>           Run any openclaw command in WSL
echo.
echo Examples:
echo   openclaw-dev.bat init
echo   openclaw-dev.bat full
echo   openclaw-dev.bat full-test 180
echo   openclaw-dev.bat codex-login
echo   openclaw-dev.bat model-set openai-codex/gpt-5.2-codex
echo.
echo Tip:
echo   If your distro name is not Ubuntu-22.04, set this first:
echo   set OPENCLAW_WSL_DISTRO=YourDistroName
echo ================================================================
exit /b 0

:stop
echo [openclaw-dev] Stopping Gateway and UI...
call :ensure_repo_wsl
wsl -d %WSL_DISTRO% -- bash -c "pkill -f 'openclaw-gateway' 2>/dev/null; pkill -f 'run-node.mjs.*gateway' 2>/dev/null; pkill -f 'vite.*5173' 2>/dev/null; pkill -f 'ui:dev' 2>/dev/null; echo 'Processes killed'"
echo [openclaw-dev] Stopped.
exit /b 0

:restart
call :stop
timeout /t 2 /nobreak >nul
call :full
exit /b %ERRORLEVEL%

:init
call :run_ps -Mode check
exit /b %ERRORLEVEL%

:dev
call :run_ps -Mode dev -SkipInstall -SkipBuild
exit /b %ERRORLEVEL%

:watch
call :run_ps -Mode watch -SkipInstall -SkipBuild
exit /b %ERRORLEVEL%

:full
call :run_ps -Mode full -SkipInstall -SkipBuild
exit /b %ERRORLEVEL%

:full_open
call :ui
call :full
exit /b %ERRORLEVEL%

:full_init
call :run_ps -Mode full
exit /b %ERRORLEVEL%

:full_test
set "TEST_SECONDS=%~2"
if not defined TEST_SECONDS set "TEST_SECONDS=120"
call :run_ps -Mode full -SkipInstall -SkipBuild -DurationSeconds %TEST_SECONDS%
exit /b %ERRORLEVEL%

:ui
rem Use PowerShell to open URL (batch can't handle & in URLs reliably)
powershell -NoProfile -Command "$j=wsl -d '%WSL_DISTRO%' -- cat '~/.openclaw-dev/openclaw.json' 2>$null | ConvertFrom-Json -EA SilentlyContinue; $t=$j.gateway.auth.token; $u='http://localhost:5173/?gatewayUrl=ws://127.0.0.1:19001'; if($t){$u+='&token='+$t}; Write-Host '[openclaw-dev] Opening:' $u; Start-Process $u"
exit /b 0

:ui_dev
call :run_ps -Mode ui-dev -SkipInstall -SkipBuild
exit /b %ERRORLEVEL%

:gateway
call :run_ps -Mode dev -SkipInstall -SkipBuild
exit /b %ERRORLEVEL%

:status
call :run_wsl_repo "pnpm openclaw gateway status"
if errorlevel 1 exit /b %ERRORLEVEL%
call :run_wsl_repo "pnpm openclaw models status"
exit /b %ERRORLEVEL%

:diag_disconnect
call :run_wsl_repo "pnpm openclaw gateway status"
if errorlevel 1 exit /b %ERRORLEVEL%
call :run_wsl_repo "pnpm openclaw models status"
if errorlevel 1 exit /b %ERRORLEVEL%
call :run_wsl_repo "pnpm openclaw channels status"
exit /b %ERRORLEVEL%

:logs
call :run_wsl_repo "pnpm openclaw logs --follow"
exit /b %ERRORLEVEL%

:doctor
call :run_wsl_repo "pnpm openclaw doctor"
exit /b %ERRORLEVEL%

:dashboard
call :run_wsl_repo "pnpm openclaw dashboard --no-open"
exit /b %ERRORLEVEL%

:codex_login
call :run_ps -Mode codex-auth -SkipInstall -SkipBuild
exit /b %ERRORLEVEL%

:codex_oauth
call :run_ps -Mode codex-oauth -SkipInstall -SkipBuild
exit /b %ERRORLEVEL%

:auth_status
call :run_wsl_repo "pnpm openclaw models status"
exit /b %ERRORLEVEL%

:model_list
call :run_wsl_repo "pnpm openclaw models list"
exit /b %ERRORLEVEL%

:model_set
set "MODEL_ID=%~2"
if not defined MODEL_ID (
  echo [openclaw-dev] model-set requires an argument.
  echo Example: openclaw-dev.bat model-set openai-codex/gpt-5.2-codex
  exit /b 2
)
call :run_wsl_repo "pnpm openclaw models set %MODEL_ID%"
exit /b %ERRORLEVEL%

:model_chat
call :run_wsl_repo "pnpm openclaw models set openai-codex/gpt-5.2"
exit /b %ERRORLEVEL%

:model_code
call :run_wsl_repo "pnpm openclaw models set openai-codex/gpt-5.2-codex"
exit /b %ERRORLEVEL%

:think
set "THINK_LEVEL=%~2"
if not defined THINK_LEVEL (
  echo [openclaw-dev] think requires a level: off, minimal, low, medium, high, xhigh
  echo Example: bot think high
  exit /b 2
)
call :ensure_repo_wsl
wsl -d %WSL_DISTRO% -- python3 "%REPO_WSL%/nlwuscript/_set-think-level.py" "%THINK_LEVEL%"
exit /b %ERRORLEVEL%

:tg_add
set "TG_TOKEN=%~2"
if not defined TG_TOKEN (
  echo [openclaw-dev] tg-add requires a Telegram bot token.
  echo Get one from @BotFather in Telegram.
  echo Example: bot tg-add 123456:ABC-DEF...
  exit /b 2
)
set "TG_ACCOUNT=%~3"
if not defined TG_ACCOUNT set "TG_ACCOUNT=default"
call :ensure_repo_wsl
echo [openclaw-dev] Configuring Telegram bot (account: %TG_ACCOUNT%)...
wsl -d %WSL_DISTRO% -- python3 "%REPO_WSL%/nlwuscript/_tg-setup.py" "%TG_TOKEN%" "%TG_ACCOUNT%"
exit /b %ERRORLEVEL%

:tg_lock
set "TG_UID=%~2"
if not defined TG_UID (
  echo [openclaw-dev] tg-lock requires your Telegram User ID.
  echo To find it, message @userinfobot in Telegram.
  echo Example: bot tg-lock 123456789
  exit /b 2
)
call :ensure_repo_wsl
echo [openclaw-dev] Locking Telegram bot to user ID: %TG_UID%
wsl -d %WSL_DISTRO% -- python3 "%REPO_WSL%/nlwuscript/_tg-lockdown.py" "%TG_UID%"
exit /b %ERRORLEVEL%

:tg_status
call :run_wsl_repo "pnpm openclaw channels status --probe"
exit /b %ERRORLEVEL%

:tg_list
call :run_wsl_repo "pnpm openclaw channels list"
exit /b %ERRORLEVEL%

:channels
call :run_wsl_repo "pnpm openclaw channels list"
exit /b %ERRORLEVEL%

:pair_list
call :run_wsl_repo "pnpm openclaw pairing list telegram"
exit /b %ERRORLEVEL%

:pair_approve
set "PAIR_CODE=%~2"
if not defined PAIR_CODE (
  echo [openclaw-dev] pair-approve requires a pairing code.
  echo First run: bot pair-list
  echo Example: bot pair-approve ABC123
  exit /b 2
)
call :run_wsl_repo "pnpm openclaw pairing approve telegram %PAIR_CODE%"
exit /b %ERRORLEVEL%

:node_list
call :run_wsl_repo "pnpm openclaw nodes list"
exit /b %ERRORLEVEL%

:node_pending
echo [openclaw-dev] Checking device pairing requests...
call :run_wsl_repo "pnpm openclaw devices list"
exit /b %ERRORLEVEL%

:node_approve
set "NODE_REQ_ID=%~2"
if not defined NODE_REQ_ID (
  echo [openclaw-dev] node-approve requires a request ID.
  echo First run: bot node-pending
  echo Example: bot node-approve c7eee77b-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  exit /b 2
)
call :run_wsl_repo "pnpm openclaw devices approve %NODE_REQ_ID%"
exit /b %ERRORLEVEL%

:node_status
call :run_wsl_repo "pnpm openclaw nodes status"
exit /b %ERRORLEVEL%

:node_run
set "NODE_ID=%~2"
set "NODE_CMD=%~3"
if not defined NODE_ID (
  echo [openclaw-dev] node-run requires a node ID and command.
  echo Example: bot node-run mynode "git status"
  exit /b 2
)
if not defined NODE_CMD (
  echo [openclaw-dev] node-run requires a command.
  echo Example: bot node-run %NODE_ID% "git status"
  exit /b 2
)
call :run_wsl_repo "pnpm openclaw nodes run --node %NODE_ID% --raw %NODE_CMD%"
exit /b %ERRORLEVEL%

:ngrok
set "NGROK_EXE=C:\soft\net\ngrok-angk-linshi\ngrok.exe"
set "NGROK_CFG=C:\soft\net\ngrok-angk-linshi\ngrok-clawbot.cfg"
set "NGROK_SUB=%~2"
if not defined NGROK_SUB set "NGROK_SUB=all"
echo [openclaw-dev] Starting ngrok tunnels (Gateway + UI)...
echo [openclaw-dev] Config: %NGROK_CFG%
echo [openclaw-dev] Gateway: https://clawbot.xnng.yfqwl.com
echo [openclaw-dev] Web UI:  https://clawui.xnng.yfqwl.com
echo [openclaw-dev] Android: Host=clawbot.xnng.yfqwl.com Port=443 TLS=on
echo.
if /I "%NGROK_SUB%"=="gateway" (
  "%NGROK_EXE%" -config "%NGROK_CFG%" start gateway
) else if /I "%NGROK_SUB%"=="ui" (
  "%NGROK_EXE%" -config "%NGROK_CFG%" start ui
) else (
  "%NGROK_EXE%" -config "%NGROK_CFG%" start gateway ui
)
exit /b %ERRORLEVEL%

:plugins_all
echo [openclaw-dev] Enabling all bundled plugins...
call :ensure_repo_wsl
wsl -d %WSL_DISTRO% -- python3 "%REPO_WSL%/nlwuscript/_plugins-enable-all.py"
exit /b %ERRORLEVEL%

:plugins_list
call :run_wsl_repo "pnpm openclaw plugins list"
exit /b %ERRORLEVEL%

:browser_setup
echo [openclaw-dev] Enabling browser relay in config...
call :ensure_repo_wsl
wsl -d %WSL_DISTRO% -- python3 "%REPO_WSL%/nlwuscript/_browser-setup.py"
if errorlevel 1 exit /b 1
echo [openclaw-dev] Next: restart Gateway (bot full), then install extension (bot browser-ext)
exit /b 0

:browser_ext
echo [openclaw-dev] Installing and locating Chrome extension...
call :run_wsl_repo "pnpm openclaw browser extension install && pnpm openclaw browser extension path"
exit /b %ERRORLEVEL%

:browser_status
call :run_wsl_repo "pnpm openclaw browser status"
exit /b %ERRORLEVEL%

:android_build
echo [openclaw-dev] Building Android debug APK (Windows native)...
pushd "%REPO_DIR%\apps\android"
call gradlew.bat --no-daemon -Dorg.gradle.jvmargs="-Xmx2g -XX:+UseZGC --enable-native-access=ALL-UNNAMED" :app:assembleDebug
set "BUILD_ERR=%ERRORLEVEL%"
popd
if %BUILD_ERR%==0 (
  echo.
  echo [openclaw-dev] Build complete!
  call :android_find_apk
  echo [openclaw-dev] Use 'bot android-apk' to copy it to current directory.
)
exit /b %BUILD_ERR%

:android_install
echo [openclaw-dev] Building and installing APK to device (Windows native)...
pushd "%REPO_DIR%\apps\android"
call gradlew.bat --no-daemon -Dorg.gradle.jvmargs="-Xmx2g -XX:+UseZGC --enable-native-access=ALL-UNNAMED" :app:installDebug
set "BUILD_ERR=%ERRORLEVEL%"
popd
exit /b %BUILD_ERR%

:android_run
echo [openclaw-dev] Building, installing and launching on device (Windows native)...
pushd "%REPO_DIR%\apps\android"
call gradlew.bat --no-daemon -Dorg.gradle.jvmargs="-Xmx2g -XX:+UseZGC --enable-native-access=ALL-UNNAMED" :app:installDebug
set "BUILD_ERR=%ERRORLEVEL%"
popd
if %BUILD_ERR% neq 0 exit /b %BUILD_ERR%
echo [openclaw-dev] Starting app on device...
adb shell am start -n ai.openclaw.android/.MainActivity
exit /b %ERRORLEVEL%

:android_test
echo [openclaw-dev] Running Android unit tests (Windows native)...
pushd "%REPO_DIR%\apps\android"
call gradlew.bat --no-daemon -Dorg.gradle.jvmargs="-Xmx2g -XX:+UseZGC --enable-native-access=ALL-UNNAMED" :app:testDebugUnitTest
set "BUILD_ERR=%ERRORLEVEL%"
popd
exit /b %BUILD_ERR%

:android_apk
call :android_find_apk
if not defined APK_FOUND (
  echo [openclaw-dev] APK not found. Build it first:
  echo   bot android-build
  exit /b 1
)
copy /y "%APK_FOUND%" "%CD%\openclaw-debug.apk" >nul 2>&1
if not errorlevel 1 (
  echo [openclaw-dev] Copied to: %CD%\openclaw-debug.apk
  echo [openclaw-dev] Install via: adb install openclaw-debug.apk
) else (
  echo [openclaw-dev] Copy failed. Manually copy from:
  echo   %APK_FOUND%
)
exit /b 0

:android_find_apk
set "APK_FOUND="
set "APK_DIR=%REPO_DIR%\apps\android\app\build\outputs\apk\debug"
if not exist "%APK_DIR%" exit /b 1
for %%F in ("%APK_DIR%\openclaw-*.apk") do (
  set "APK_FOUND=%%F"
  echo [openclaw-dev] APK: %%~nxF
  for %%S in ("%%F") do echo [openclaw-dev] Size: %%~zS bytes
)
if not defined APK_FOUND (
  for %%F in ("%APK_DIR%\*.apk") do (
    set "APK_FOUND=%%F"
    echo [openclaw-dev] APK: %%~nxF
    for %%S in ("%%F") do echo [openclaw-dev] Size: %%~zS bytes
  )
)
exit /b 0

:android_clean
echo [openclaw-dev] Cleaning Android build cache...
pushd "%REPO_DIR%\apps\android"
call gradlew.bat clean
set "BUILD_ERR=%ERRORLEVEL%"
popd
exit /b %BUILD_ERR%

:exec
set "EXEC_ARGS="
shift
:exec_loop
if "%~1"=="" goto :exec_run
if defined EXEC_ARGS (
  set "EXEC_ARGS=%EXEC_ARGS% %~1"
) else (
  set "EXEC_ARGS=%~1"
)
shift
goto :exec_loop
:exec_run
if not defined EXEC_ARGS (
  echo [openclaw-dev] exec requires a command.
  echo Example: bot exec pnpm openclaw channels status
  exit /b 2
)
call :run_wsl_repo "pnpm openclaw %EXEC_ARGS%"
exit /b %ERRORLEVEL%

:run_ps
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%dev-local.ps1" -WslDistro "%WSL_DISTRO%" %*
exit /b %ERRORLEVEL%

:ensure_repo_wsl
if defined REPO_WSL exit /b 0
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$p=(Resolve-Path '%REPO_DIR%').Path; $drive=$p.Substring(0,1).ToLower(); $rest=$p.Substring(2) -replace '\\','/'; '/mnt/' + $drive + $rest"`) do set "REPO_WSL=%%I"
if not defined REPO_WSL (
  echo [openclaw-dev] Failed to convert repo path to WSL path.
  echo   %REPO_DIR%
  exit /b 1
)
exit /b 0

:run_wsl_repo
set "WSL_REPO_CMD=%~1"
call :ensure_repo_wsl
if errorlevel 1 exit /b 1
:: Auto-inject --profile dev for pnpm openclaw commands (Gateway runs on dev profile, port 19001)
set "WSL_REPO_CMD_FINAL=%WSL_REPO_CMD%"
echo %WSL_REPO_CMD% | findstr /c:"pnpm openclaw" >nul 2>&1
if not errorlevel 1 (
  echo %WSL_REPO_CMD% | findstr /c:"--profile" >nul 2>&1
  if errorlevel 1 (
    set "WSL_REPO_CMD_FINAL=%WSL_REPO_CMD:pnpm openclaw=pnpm openclaw --profile dev%"
  )
)
wsl -d %WSL_DISTRO% --cd "%REPO_WSL%" -- bash "./nlwuscript/dev-local-wsl.sh" --repo "%REPO_WSL%" --mode exec --skip-install --skip-build --exec-cmd "%WSL_REPO_CMD_FINAL%"
exit /b %ERRORLEVEL%
