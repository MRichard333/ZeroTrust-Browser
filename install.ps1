# ============================================================
#  ZeroTrust Browser — Windows Setup Script
#  Supports: Windows 10 / 11
#  Run as Administrator in PowerShell:
#    Right-click PowerShell → "Run as administrator"
#    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#    .\install.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function ok($msg)      { Write-Host "[OK] $msg" -ForegroundColor Green }
function warn($msg)    { Write-Host "[!!] $msg" -ForegroundColor Yellow }
function err($msg)     { Write-Host "[XX] $msg" -ForegroundColor Red; exit 1 }
function section($msg) { Write-Host "`n---- $msg ----" -ForegroundColor Cyan }

Write-Host ""
Write-Host "  ZeroTrust Browser Setup -- Windows" -ForegroundColor White
Write-Host "  ------------------------------------"
Write-Host ""

# ════════════════════════════════════════════════════════════
# 1. CHECK ADMIN
# ════════════════════════════════════════════════════════════
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    err "Please run this script as Administrator (right-click PowerShell -> Run as administrator)"
}

# ════════════════════════════════════════════════════════════
# 2. DETECT / INSTALL FIREFOX
# ════════════════════════════════════════════════════════════
section "Firefox"

$FirefoxPaths = @(
    "C:\Program Files\Mozilla Firefox\firefox.exe",
    "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
)
$FirefoxBin = $null
foreach ($p in $FirefoxPaths) {
    if (Test-Path $p) { $FirefoxBin = $p; break }
}

if (-not $FirefoxBin) {
    warn "Firefox not found. Downloading installer..."
    $Installer = "$env:TEMP\firefox-installer.exe"
    Invoke-WebRequest -Uri "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" -OutFile $Installer
    Start-Process -FilePath $Installer -Args "/S" -Wait
    Remove-Item $Installer -Force
    foreach ($p in $FirefoxPaths) {
        if (Test-Path $p) { $FirefoxBin = $p; break }
    }
    if (-not $FirefoxBin) { err "Firefox installation failed." }
    ok "Firefox installed"
} else {
    $Version = & $FirefoxBin --version 2>$null
    ok "Firefox found: $Version"
}

# Determine Firefox install directory
$FirefoxDir = Split-Path -Parent $FirefoxBin

# ════════════════════════════════════════════════════════════
# 3. DOWNLOAD EXTENSIONS LOCALLY
# ════════════════════════════════════════════════════════════
section "Caching extensions locally"

$ExtCache = Join-Path $ScriptDir "ext-cache"
New-Item -ItemType Directory -Force -Path $ExtCache | Out-Null

$Extensions = @{
    "zerotrust.xpi"   = "https://addons.mozilla.org/firefox/downloads/file/4730187/zerotrust_dashboard_extension-2.1.0.xpi"
    "ublock.xpi"      = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
    "bitwarden.xpi"   = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"
    "containers.xpi"  = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi"
    "clearurls.xpi"   = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi"
    "localcdn.xpi"    = "https://addons.mozilla.org/firefox/downloads/latest/localcdn-fork-of-decentraleyes/latest.xpi"
}

foreach ($Name in $Extensions.Keys) {
    $Dest = Join-Path $ExtCache $Name
    if (Test-Path $Dest) {
        ok "$Name -- already cached"
    } else {
        Write-Host "  Downloading $Name..." -NoNewline
        try {
            Invoke-WebRequest -Uri $Extensions[$Name] -OutFile $Dest -UseBasicParsing
            Write-Host " done" -ForegroundColor Green
        } catch {
            warn "$Name -- download failed, will use AMO on first launch"
            Remove-Item $Dest -Force -ErrorAction SilentlyContinue
        }
    }
}

# ════════════════════════════════════════════════════════════
# 4. ENTERPRISE POLICIES
#    Windows: %ProgramFiles%\Mozilla Firefox\distribution\
# ════════════════════════════════════════════════════════════
section "Enterprise policies"

$PoliciesDir = Join-Path $FirefoxDir "distribution"
New-Item -ItemType Directory -Force -Path $PoliciesDir | Out-Null

$PoliciesSrc = Join-Path $ScriptDir "policies.json"
if (-not (Test-Path $PoliciesSrc)) { err "policies.json not found in $ScriptDir" }
Copy-Item $PoliciesSrc (Join-Path $PoliciesDir "policies.json") -Force
ok "policies.json -> $PoliciesDir"

# Patch extension URLs to local file:// paths
$PatchScript = Join-Path $ScriptDir "patch_policies.py"
if ((Test-Path $PatchScript) -and (Get-Command python3 -ErrorAction SilentlyContinue)) {
    $PolicyFile = Join-Path $PoliciesDir "policies.json"
    python3 $PatchScript $PolicyFile $ExtCache $ScriptDir
    ok "Extension URLs patched to local file:// paths"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PolicyFile = Join-Path $PoliciesDir "policies.json"
    python $PatchScript $PolicyFile $ExtCache $ScriptDir
    ok "Extension URLs patched to local file:// paths"
} else {
    warn "Python not found -- extensions will install via AMO on first launch"
}

# ════════════════════════════════════════════════════════════
# 5. FIND FIREFOX PROFILE
# ════════════════════════════════════════════════════════════
section "Firefox profile"

$MozillaDir = Join-Path $env:APPDATA "Mozilla\Firefox"
$ProfilesIni = Join-Path $MozillaDir "profiles.ini"

if (-not (Test-Path $ProfilesIni)) {
    warn "No profile found. Creating via headless launch..."
    Start-Process -FilePath $FirefoxBin -Args "--headless --no-remote" -PassThru | ForEach-Object {
        Start-Sleep 6
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
}

$ProfilePath = $null
if (Test-Path $ProfilesIni) {
    $Ini = Get-Content $ProfilesIni -Raw
    # Find default profile from [Install*] section
    if ($Ini -match '(?ms)\[Install[^\]]*\].*?Default=([^\r\n]+)') {
        $Default = $Matches[1].Trim()
        if ($Default.StartsWith('/') -or $Default -match '^[A-Za-z]:') {
            $ProfilePath = $Default
        } else {
            $ProfilePath = Join-Path $MozillaDir $Default
        }
    }
    # Fallback: find Default=1 profile
    if (-not $ProfilePath -or -not (Test-Path $ProfilePath)) {
        $Sections = $Ini -split '\[Profile'
        foreach ($S in $Sections) {
            if ($S -match 'Default=1' -and $S -match 'Path=([^\r\n]+)') {
                $Rel = $Matches[1].Trim()
                if ($S -match 'IsRelative=0') {
                    $ProfilePath = $Rel
                } else {
                    $ProfilePath = Join-Path $MozillaDir $Rel
                }
                break
            }
        }
    }
}

if (-not $ProfilePath -or -not (Test-Path $ProfilePath)) {
    $ProfileDirs = Get-ChildItem $MozillaDir -Directory | Where-Object { $_.Name -match '\.' }
    if ($ProfileDirs.Count -eq 0) { err "No Firefox profiles found in $MozillaDir" }
    $ProfilePath = $ProfileDirs[0].FullName
    warn "Auto-detect failed. Using: $ProfilePath"
}

ok "Profile: $ProfilePath"

# ════════════════════════════════════════════════════════════
# 6. user.js
# ════════════════════════════════════════════════════════════
section "user.js"

$UserJsSrc = Join-Path $ScriptDir "user.js"
if (-not (Test-Path $UserJsSrc)) { err "user.js not found" }
$UserJsDest = Join-Path $ProfilePath "user.js"
if (Test-Path $UserJsDest) {
    Copy-Item $UserJsDest "$UserJsDest.bak" -Force
    warn "Backed up existing user.js"
}
Copy-Item $UserJsSrc $UserJsDest -Force
ok "user.js installed"

# ════════════════════════════════════════════════════════════
# 7. userChrome.css
# ════════════════════════════════════════════════════════════
section "userChrome.css"

$ChromeCssSrc = Join-Path $ScriptDir "userChrome.css"
if (-not (Test-Path $ChromeCssSrc)) { err "userChrome.css not found" }
$ChromeDir = Join-Path $ProfilePath "chrome"
New-Item -ItemType Directory -Force -Path $ChromeDir | Out-Null
Copy-Item $ChromeCssSrc (Join-Path $ChromeDir "userChrome.css") -Force
ok "userChrome.css installed"

# ════════════════════════════════════════════════════════════
# 8. STAGE EXTENSIONS
# ════════════════════════════════════════════════════════════
section "Staging extensions"

$ExtDir = Join-Path $ProfilePath "extensions"
New-Item -ItemType Directory -Force -Path $ExtDir | Out-Null

$ExtMap = @{
    "zerotrust@mrichard333.com"              = "zerotrust.xpi"
    "uBlock0@raymondhill.net"                = "ublock.xpi"
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden.xpi"
    "@testpilot-containers"                  = "containers.xpi"
    "{74145f27-f039-47ce-a470-a662b129930a}" = "clearurls.xpi"
    "{b86e4813-687a-43e6-ab65-0bde4ab75758}" = "localcdn.xpi"
}

foreach ($Id in $ExtMap.Keys) {
    $Src = Join-Path $ExtCache $ExtMap[$Id]
    if (Test-Path $Src) {
        Copy-Item $Src (Join-Path $ExtDir "$Id.xpi") -Force
        ok "$($ExtMap[$Id]) staged"
    } else {
        warn "$($ExtMap[$Id]) -- not cached, installs via AMO on first launch"
    }
}

# ════════════════════════════════════════════════════════════
# 9. DESKTOP SHORTCUT
# ════════════════════════════════════════════════════════════
section "Desktop shortcut"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\ZeroTrust Browser.lnk")
$Shortcut.TargetPath = $FirefoxBin
$Shortcut.Arguments = '--name "ZeroTrust Browser"'
$Shortcut.Description = "ZeroTrust Browser — Secured by MRichard333"
$Shortcut.WorkingDirectory = $FirefoxDir
$Shortcut.Save()
ok "Desktop shortcut created"

# ════════════════════════════════════════════════════════════
# 10. SET DEFAULT BROWSER
# ════════════════════════════════════════════════════════════
section "Default browser"

try {
    # Register Firefox as default via Windows settings
    Start-Process "ms-settings:defaultapps" -ErrorAction SilentlyContinue
    warn "Windows 10/11 requires you to set the default browser manually."
    warn "The Settings app has been opened -- click 'Web browser' and select Firefox."
} catch {
    warn "Could not open Settings. Set default browser manually."
}

# ════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  ------------------------------------" -ForegroundColor White
Write-Host "  ZeroTrust Browser setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  . policies.json  -> $PoliciesDir"
Write-Host "  . user.js        -> $ProfilePath"
Write-Host "  . extensions/    -> $ExtDir"
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "     1. Fully quit Firefox (not just close the window)"
Write-Host "     2. Relaunch Firefox"
Write-Host "     3. Check about:policies  -- should show Active"
Write-Host "     4. Check about:addons    -- extensions should appear"
Write-Host ""
