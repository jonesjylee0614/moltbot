[CmdletBinding()]
param(
  [string]$WslDistro = "",
  [ValidateSet("check", "dev", "watch", "full", "ui-dev", "codex-auth", "codex-oauth")]
  [string]$Mode = "dev",
  [switch]$SkipInstall,
  [switch]$SkipBuild,
  [switch]$Reinstall,
  [int]$DurationSeconds = 0,
  [switch]$RawStream,
  [string]$RawStreamPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
  param([Parameter(Mandatory = $true)][string]$Message)
  Write-Host "[dev-local] $Message"
}

function Normalize-WslText {
  param([string]$Text)
  if ($null -eq $Text) {
    return ""
  }
  return ($Text -replace ([string][char]0), "").Trim()
}

function Get-DefaultWslDistro {
  $verboseList = & wsl -l -v 2>$null
  if ($LASTEXITCODE -eq 0 -and $verboseList) {
    foreach ($line in $verboseList) {
      $clean = Normalize-WslText $line
      if ($clean -match "^\s*\*\s+([^\s]+)") {
        return $matches[1]
      }
    }
  }

  $simpleList = & wsl -l -q 2>$null
  if ($LASTEXITCODE -eq 0 -and $simpleList) {
    foreach ($line in $simpleList) {
      $candidate = Normalize-WslText $line
      if (-not [string]::IsNullOrWhiteSpace($candidate)) {
        return $candidate
      }
    }
  }

  return $null
}

function Convert-PathToWsl {
  param(
    [Parameter(Mandatory = $true)][string]$PathText,
    [Parameter(Mandatory = $true)][string]$Distro
  )

  if ($PathText -match '^[A-Za-z]:\\') {
    $winPathForWsl = $PathText -replace '\\', '/'
    $converted = (& wsl -d $Distro -- wslpath -a "$winPathForWsl").Trim()
    if (-not $converted) {
      throw "Failed to convert Windows path to WSL path: $PathText"
    }
    return $converted
  }

  return $PathText
}

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
  throw "wsl command not found. Install WSL first: wsl --install"
}

if ($DurationSeconds -lt 0) {
  throw "DurationSeconds must be >= 0."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$wslScriptWinPath = Join-Path $repoRoot "nlwuscript/dev-local-wsl.sh"
if (-not (Test-Path $wslScriptWinPath)) {
  throw "Missing script: $wslScriptWinPath"
}

$selectedDistro = $WslDistro
if ([string]::IsNullOrWhiteSpace($selectedDistro)) {
  $selectedDistro = Get-DefaultWslDistro
}
$selectedDistro = Normalize-WslText $selectedDistro
if ([string]::IsNullOrWhiteSpace($selectedDistro)) {
  throw "No WSL distro found. Run: wsl --install -d Ubuntu-22.04"
}

Write-Info "Using WSL distro: $selectedDistro"

& wsl -d $selectedDistro -- bash -lc "echo __WSL_OK__" | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Failed to start WSL distro: $selectedDistro"
}

$repoRootForWslPath = $repoRoot -replace '\\', '/'
$repoRootWsl = Normalize-WslText (& wsl -d $selectedDistro -- wslpath -a "$repoRootForWslPath")
if (-not $repoRootWsl) {
  throw "Failed to resolve repo path in WSL."
}

$scriptWsl = "$repoRootWsl/nlwuscript/dev-local-wsl.sh"
$wslArgs = @(
  "-d", $selectedDistro,
  "--",
  "bash", $scriptWsl,
  "--repo", $repoRootWsl,
  "--mode", $Mode
)

if ($SkipInstall) { $wslArgs += "--skip-install" }
if ($SkipBuild) { $wslArgs += "--skip-build" }
if ($Reinstall) { $wslArgs += "--reinstall" }
if ($DurationSeconds -gt 0) { $wslArgs += @("--duration-seconds", $DurationSeconds.ToString()) }
if ($RawStream) { $wslArgs += "--raw-stream" }
if (-not [string]::IsNullOrWhiteSpace($RawStreamPath)) {
  $rawPathWsl = Convert-PathToWsl -PathText $RawStreamPath -Distro $selectedDistro
  $wslArgs += @("--raw-stream-path", $rawPathWsl)
}

Write-Info "Repo in WSL: $repoRootWsl"
Write-Info "Mode: $Mode"

& wsl @wslArgs
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
  throw "WSL debug script failed with exit code $exitCode."
}

Write-Info "Completed."
