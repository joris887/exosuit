# Exosuit — Windows installer wrapper
#
# All install logic lives in install.sh — this wrapper only locates a bash
# to run it with, so the two installers can never drift apart.
#
# Git Bash ships with Git for Windows, which Claude Code on Windows already
# requires — so every Exosuit user has it.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/joris887/exosuit/main/install.ps1 | iex"
#   .\install.ps1 --dry-run        (flags are passed through to install.sh)

$ErrorActionPreference = "Stop"

$installShUrl = "https://raw.githubusercontent.com/joris887/exosuit/main/install.sh"

# Windows PowerShell 5.1 may default to TLS 1.0, which GitHub rejects
if ($PSVersionTable.PSVersion.Major -lt 6) {
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

# --- Locate bash (Git Bash on Windows, system bash elsewhere) ---
$bash = $null
$candidates = @()
if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles "Git\bin\bash.exe") }
if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe") }
if ($env:LocalAppData) { $candidates += (Join-Path $env:LocalAppData "Programs\Git\bin\bash.exe") }
foreach ($candidate in $candidates) {
    if (Test-Path $candidate) { $bash = $candidate; break }
}
if (-not $bash) {
    # PATH fallback — but never the System32 WSL stub, which fails when WSL isn't set up
    $found = Get-Command bash -ErrorAction SilentlyContinue
    if ($found -and $found.Source -and ($found.Source -notmatch 'System32')) {
        $bash = $found.Source
    }
}
if (-not $bash) {
    Write-Host ""
    Write-Host "Exosuit needs Git Bash, which ships with Git for Windows." -ForegroundColor Red
    Write-Host "Claude Code on Windows requires Git for Windows too, so you'll want it either way:"
    Write-Host ""
    Write-Host "    https://git-scm.com/download/win"
    Write-Host ""
    Write-Host "Install it, restart your terminal, and re-run this command."
    exit 1
}

# --- Fetch install.sh and run it in the current directory ---
$tmpScript = Join-Path ([System.IO.Path]::GetTempPath()) "exosuit-install.sh"
Invoke-RestMethod -Uri $installShUrl -OutFile $tmpScript
try {
    if ($args -and $args.Count -gt 0) {
        & $bash $tmpScript @args
    } else {
        & $bash $tmpScript
    }
    exit $LASTEXITCODE
} finally {
    Remove-Item $tmpScript -ErrorAction SilentlyContinue
}
