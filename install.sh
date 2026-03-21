#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser — Full Setup Script
#  For Mountain OS (Ubuntu base)
#  Run with: sudo ./install.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Always resolve the REAL user even when called via sudo ───
# SUDO_USER is set by sudo to the original caller.
# If not running via sudo, fall back to $USER.
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

FIREFOX_DIR="$REAL_HOME/.mozilla/firefox"
SNAP_FIREFOX_DIR="$REAL_HOME/snap/firefox/common/.mozilla/firefox"

# Extension IDs (confirmed from manifests)
ZEROTRUST_ID="zerotrust@mrichard333.com"
UBLOCK_ID="uBlock0@raymondhill.net"
BITWARDEN_ID="{446900e4-71c2-419f-a6a7-df9c091e268b}"
CONTAINERS_ID="@testpilot-containers"
CLEARURLS_ID="{74145f27-f039-47ce-a470-a662b129930a}"
LOCALCDN_ID="{b86e4813-687a-43e6-ab65-0bde4ab75758}"
NEWTAB_ID="zerotrust-newtab@mrichard333.com"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
err()     { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}──── $1 ────${NC}"; }

echo ""
echo "  ZeroTrust Browser Setup — Mountain OS"
echo "  ──────────────────────────────────────"
echo "  Running as: $(id -un) (real user: $REAL_USER)"
echo ""

# ════════════════════════════════════════════════════════════
# 1. DETECT FIREFOX
# ════════════════════════════════════════════════════════════
section "Firefox"

IS_SNAP=false
FIREFOX_BIN=""

if sudo -u "$REAL_USER" snap list firefox &>/dev/null 2>&1; then
  IS_SNAP=true
  FIREFOX_DIR="$SNAP_FIREFOX_DIR"
  FIREFOX_BIN="/snap/bin/firefox"
  ok "Snap Firefox detected"
elif command -v firefox-esr &>/dev/null; then
  FIREFOX_BIN=$(command -v firefox-esr)
  ok "Firefox ESR found: $("$FIREFOX_BIN" --version 2>/dev/null | head -1)"
elif command -v firefox &>/dev/null; then
  FIREFOX_BIN=$(command -v firefox)
  ok "Firefox found: $("$FIREFOX_BIN" --version 2>/dev/null | head -1)"
else
  warn "Firefox not found — installing via apt..."
  apt-get update -qq
  apt-get install -y firefox-esr
  FIREFOX_BIN=$(command -v firefox-esr)
  ok "Firefox ESR installed"
fi

# ════════════════════════════════════════════════════════════
# 2. DOWNLOAD EXTENSIONS LOCALLY
# ════════════════════════════════════════════════════════════
section "Caching extensions locally"

EXT_CACHE="$SCRIPT_DIR/ext-cache"
mkdir -p "$EXT_CACHE"

dl() {
  local label="$1" url="$2" dest="$3"
  if [[ -f "$dest" ]]; then
    ok "$label — already cached"
    return
  fi
  echo -n "  Downloading $label... "
  if curl -fsSL --connect-timeout 15 --retry 2 "$url" -o "$dest" 2>/dev/null; then
    echo -e "${GREEN}done${NC} ($(du -sh "$dest" | cut -f1))"
  else
    warn "$label — download failed, will fall back to AMO on first launch"
    rm -f "$dest"
  fi
}

dl "ZeroTrust Extension"      "https://addons.mozilla.org/firefox/downloads/file/4730187/zerotrust_dashboard_extension-2.1.0.xpi"  "$EXT_CACHE/zerotrust.xpi"
dl "uBlock Origin"             "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"                       "$EXT_CACHE/ublock.xpi"
dl "Bitwarden"                 "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"           "$EXT_CACHE/bitwarden.xpi"
dl "Multi-Account Containers"  "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi"            "$EXT_CACHE/containers.xpi"
dl "ClearURLs"                 "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi"                           "$EXT_CACHE/clearurls.xpi"
dl "LocalCDN"                  "https://addons.mozilla.org/firefox/downloads/latest/localcdn-fork-of-decentraleyes/latest.xpi"      "$EXT_CACHE/localcdn.xpi"

# ════════════════════════════════════════════════════════════
# 3. ENTERPRISE POLICIES
# ════════════════════════════════════════════════════════════
section "Enterprise policies"

[[ -f "$SCRIPT_DIR/policies.json" ]] || err "policies.json not found in $SCRIPT_DIR"

if [[ "$IS_SNAP" == true ]]; then
  POLICIES_DIR="/var/snap/firefox/common/policies"
  POLICIES_DIR_USER="$REAL_HOME/snap/firefox/common/policies"
  mkdir -p "$POLICIES_DIR"
  mkdir -p "$POLICIES_DIR_USER"
  cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR/policies.json"
  cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR_USER/policies.json"
  ok "policies.json → $POLICIES_DIR (system)"
  ok "policies.json → $POLICIES_DIR_USER (user)"
else
  POLICIES_DIR="/usr/lib/firefox/distribution"
  [[ -d "/usr/lib/firefox-esr/distribution" ]] && POLICIES_DIR="/usr/lib/firefox-esr/distribution"
  mkdir -p "$POLICIES_DIR"
  cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR/policies.json"
  ok "policies.json → $POLICIES_DIR"
fi

# Patch extension install_urls to use local file:// paths
python3 "$SCRIPT_DIR/patch_policies.py" \
  "$POLICIES_DIR/policies.json" \
  "$EXT_CACHE" \
  "$SCRIPT_DIR" \
  && ok "Extension URLs patched to local file:// paths" \
  || warn "patch_policies.py failed — extensions will install via AMO on first launch"

if [[ "$IS_SNAP" == true ]]; then
  python3 "$SCRIPT_DIR/patch_policies.py" \
    "$POLICIES_DIR_USER/policies.json" \
    "$EXT_CACHE" \
    "$SCRIPT_DIR" || true
fi

# ════════════════════════════════════════════════════════════
# 4. FIREFOX PROFILE
# ════════════════════════════════════════════════════════════
section "Firefox profile"

if [[ ! -d "$FIREFOX_DIR" ]]; then
  warn "No profile found — creating via headless launch as $REAL_USER..."
  # Must run as the real user, not root
  sudo -u "$REAL_USER" "$FIREFOX_BIN" --headless --no-remote &>/dev/null &
  FFPID=$!
  sleep 6
  kill "$FFPID" 2>/dev/null || true
  wait "$FFPID" 2>/dev/null || true
  ok "Profile created"
fi

PROFILES_INI="$FIREFOX_DIR/profiles.ini"
PROFILE_PATH=""

if [[ -f "$PROFILES_INI" ]]; then
  DEFAULT_PROFILE=$(awk '/^\[Install/{in_i=1} in_i && /^Default=/{print substr($0,9); in_i=0}' "$PROFILES_INI")
  if [[ -n "$DEFAULT_PROFILE" ]]; then
    [[ "$DEFAULT_PROFILE" == /* ]] \
      && PROFILE_PATH="$DEFAULT_PROFILE" \
      || PROFILE_PATH="$FIREFOX_DIR/$DEFAULT_PROFILE"
  fi
  if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
    FALLBACK=$(awk '
      /^\[Profile/{in_p=1;path="";rel=1;def=0}
      in_p&&/^Path=/{path=substr($0,6)}
      in_p&&/^IsRelative=0/{rel=0}
      in_p&&/^Default=1/{def=1}
      in_p&&/^$/{if(def&&path!="")print (rel?"REL:":"ABS:")path; in_p=0}
    ' "$PROFILES_INI")
    if [[ -n "$FALLBACK" ]]; then
      [[ "$FALLBACK" == REL:* ]] \
        && PROFILE_PATH="$FIREFOX_DIR/${FALLBACK#REL:}" \
        || PROFILE_PATH="${FALLBACK#ABS:}"
    fi
  fi
fi

if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
  warn "Auto-detect failed — available profiles:"
  mapfile -t DIRS < <(find "$FIREFOX_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
  [[ ${#DIRS[@]} -eq 0 ]] && err "No profiles found in $FIREFOX_DIR"
  for i in "${!DIRS[@]}"; do echo "  [$i] ${DIRS[$i]}"; done
  read -rp "  Enter number [0]: " CHOICE
  PROFILE_PATH="${DIRS[${CHOICE:-0}]}"
fi

[[ -d "$PROFILE_PATH" ]] || err "Profile not found: $PROFILE_PATH"
ok "Profile: $PROFILE_PATH"

# ════════════════════════════════════════════════════════════
# 5. user.js
# ════════════════════════════════════════════════════════════
section "user.js"

[[ -f "$SCRIPT_DIR/user.js" ]] || err "user.js not found"
DEST_JS="$PROFILE_PATH/user.js"
[[ -f "$DEST_JS" ]] && cp "$DEST_JS" "$DEST_JS.bak.$(date +%Y%m%d%H%M%S)" && warn "Backed up existing user.js"
cp "$SCRIPT_DIR/user.js" "$DEST_JS"
ok "user.js installed"

# ════════════════════════════════════════════════════════════
# 6. userChrome.css
# ════════════════════════════════════════════════════════════
section "userChrome.css"

[[ -f "$SCRIPT_DIR/userChrome.css" ]] || err "userChrome.css not found"
mkdir -p "$PROFILE_PATH/chrome"
cp "$SCRIPT_DIR/userChrome.css" "$PROFILE_PATH/chrome/userChrome.css"
ok "userChrome.css installed"

# ════════════════════════════════════════════════════════════
# 7. STAGE EXTENSIONS IN PROFILE
# ════════════════════════════════════════════════════════════
section "Staging extensions"

EXT_DIR="$PROFILE_PATH/extensions"
mkdir -p "$EXT_DIR"

stage() {
  local id="$1" src="$2" label="$3"
  if [[ -f "$src" ]]; then
    cp "$src" "$EXT_DIR/${id}.xpi"
    ok "$label staged"
  else
    warn "$label — not cached, will install via AMO on first launch"
  fi
}

stage "$ZEROTRUST_ID"  "$EXT_CACHE/zerotrust.xpi"  "ZeroTrust Extension"
stage "$UBLOCK_ID"     "$EXT_CACHE/ublock.xpi"     "uBlock Origin"
stage "$BITWARDEN_ID"  "$EXT_CACHE/bitwarden.xpi"  "Bitwarden"
stage "$CONTAINERS_ID" "$EXT_CACHE/containers.xpi" "Multi-Account Containers"
stage "$CLEARURLS_ID"  "$EXT_CACHE/clearurls.xpi"  "ClearURLs"
stage "$LOCALCDN_ID"   "$EXT_CACHE/localcdn.xpi"   "LocalCDN"

# ════════════════════════════════════════════════════════════
# 8. NEWTAB EXTENSION
#    Build the XPI on the fly if not already in project folder.
#    Then stage it and update policies with the exact file:// path.
# ════════════════════════════════════════════════════════════
section "ZeroTrust New Tab extension"

NEWTAB_XPI="$SCRIPT_DIR/zerotrust-newtab.xpi"

if [[ ! -f "$NEWTAB_XPI" ]]; then
  warn "zerotrust-newtab.xpi not found — building it now..."
  NEWTAB_BUILD="$(mktemp -d)"
  mkdir -p "$NEWTAB_BUILD/icons"

  cat > "$NEWTAB_BUILD/manifest.json" <<'MANIFEST'
{
  "manifest_version": 2,
  "name": "ZeroTrust New Tab",
  "version": "1.0.0",
  "description": "ZeroTrust Browser new tab page for Mountain OS",
  "browser_specific_settings": {
    "gecko": {
      "id": "zerotrust-newtab@mrichard333.com",
      "strict_min_version": "109.0"
    }
  },
  "chrome_url_overrides": { "newtab": "newtab.html" },
  "permissions": []
}
MANIFEST

  cat > "$NEWTAB_BUILD/newtab.html" <<'NEWTABHTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ZeroTrust Browser</title>
<style>
  *,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
  :root{
    --green:#00e664;--green-dim:#00c853;
    --gm:rgba(0,230,100,0.08);
    --text:#e2f0e2;--dim:#7a9e82;--muted:#3a5040;
    --surface:rgba(8,14,10,0.72);--surface2:rgba(10,18,13,0.88);
    --border:rgba(0,230,100,0.1);--border-hi:rgba(0,230,100,0.2);
  }
  html,body{height:100%;overflow:hidden;background:#060c09}
  body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',system-ui,sans-serif;
    -webkit-font-smoothing:antialiased;color:var(--text);
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    min-height:100vh;overflow-y:auto;overflow-x:hidden;position:relative}
  canvas{position:fixed;inset:0;z-index:0;pointer-events:none}
  .aurora{position:fixed;top:0;left:0;right:0;height:45vh;pointer-events:none;z-index:0;
    background:radial-gradient(ellipse 80% 60% at 30% -10%,rgba(0,200,83,0.13) 0%,transparent 70%),
      radial-gradient(ellipse 60% 40% at 70% -5%,rgba(0,160,80,0.09) 0%,transparent 65%),
      radial-gradient(ellipse 40% 30% at 50% 0%,rgba(0,230,100,0.06) 0%,transparent 60%);
    animation:ashift 12s ease-in-out infinite alternate}
  @keyframes ashift{0%{opacity:.8;transform:scaleX(1)}100%{opacity:1;transform:scaleX(1.06)}}
  svg.mtn{position:fixed;inset:0;z-index:1;pointer-events:none}
  .page{position:relative;z-index:10;width:100%;max-width:700px;
    display:flex;flex-direction:column;align-items:center;gap:22px;padding:28px 20px 32px}
  .logo{display:flex;align-items:center;gap:11px}
  .logo svg{filter:drop-shadow(0 0 12px rgba(0,230,100,0.45))}
  .lt{font-size:25px;font-weight:800;color:var(--text);letter-spacing:-.8px}
  .lt em{font-style:normal;color:var(--green);text-shadow:0 0 22px rgba(0,230,100,0.5)}
  .tl{font-size:10px;color:var(--muted);letter-spacing:2px;text-transform:uppercase;font-weight:500;text-align:center;margin-top:5px}
  .clk{font-size:60px;font-weight:100;color:var(--text);letter-spacing:-4px;line-height:1;
    font-variant-numeric:tabular-nums;
    text-shadow:0 0 60px rgba(0,230,100,0.15),0 2px 40px rgba(0,0,0,.6);text-align:center}
  .dt{font-size:11px;color:var(--dim);letter-spacing:2px;text-transform:uppercase;text-align:center;margin-top:4px}
  .sb{display:flex;align-items:center;width:100%;background:var(--surface);
    border:1px solid var(--border-hi);border-radius:14px;padding:13px 17px;gap:11px;
    backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);transition:border-color .2s,box-shadow .2s}
  .sb:focus-within{border-color:var(--green-dim);box-shadow:0 0 0 3px rgba(0,200,83,.12),0 8px 32px rgba(0,0,0,.5)}
  .si{color:var(--muted);flex-shrink:0}
  .inp{flex:1;border:none;outline:none;font-size:15px;color:var(--text);background:transparent;caret-color:var(--green)}
  .inp::placeholder{color:var(--muted)}
  .ddg{display:flex;align-items:center;gap:5px;font-size:9px;font-weight:700;color:var(--dim);
    background:var(--gm);border:1px solid var(--border);border-radius:5px;padding:3px 8px;
    white-space:nowrap;text-transform:uppercase;letter-spacing:.5px;flex-shrink:0}
  .sec-hdr{display:flex;align-items:center;gap:10px;width:100%}
  .sec-t{font-size:9px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:1.5px;white-space:nowrap}
  .sec-l{flex:1;height:1px;background:var(--border)}
  .grid{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;width:100%}
  .card{display:flex;flex-direction:column;gap:9px;padding:13px 11px;background:var(--surface);
    border:1px solid var(--border);border-radius:12px;text-decoration:none;color:var(--text);
    backdrop-filter:blur(16px);-webkit-backdrop-filter:blur(16px);
    transition:border-color .2s,background .2s,transform .15s,box-shadow .2s;
    position:relative;overflow:hidden}
  .card::after{content:'';position:absolute;top:0;left:-100%;width:55%;height:1px;
    background:linear-gradient(90deg,transparent,var(--green),transparent);
    transition:left .45s ease;opacity:0}
  .card:hover{border-color:rgba(0,230,100,.35);background:var(--surface2);
    transform:translateY(-2px);box-shadow:0 10px 30px rgba(0,0,0,.5)}
  .card:hover::after{left:120%;opacity:1}
  .iw{width:30px;height:30px;background:var(--gm);border:1px solid rgba(0,230,100,.14);
    border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;
    transition:background .2s,border-color .2s}
  .card:hover .iw{background:rgba(0,230,100,.14);border-color:rgba(0,230,100,.3)}
  .cn{font-size:10px;font-weight:700;color:var(--text);line-height:1.3}
  .cd{font-size:9px;color:var(--muted);line-height:1.4;margin-top:1px}
  .db{display:flex;align-items:center;justify-content:space-between;gap:14px;width:100%;
    padding:15px 18px;background:var(--surface);border:1px solid var(--border-hi);
    border-radius:14px;text-decoration:none;color:var(--text);backdrop-filter:blur(20px);
    -webkit-backdrop-filter:blur(20px);transition:border-color .2s,background .2s,box-shadow .2s;
    position:relative;overflow:hidden}
  .db::before{content:'';position:absolute;top:0;left:0;right:0;height:1px;
    background:linear-gradient(90deg,transparent 5%,rgba(0,230,100,.5) 50%,transparent 95%)}
  .db:hover{border-color:rgba(0,230,100,.4);background:var(--surface2);
    box-shadow:0 12px 40px rgba(0,0,0,.6),0 0 40px rgba(0,200,83,.06)}
  .dl{display:flex;align-items:center;gap:13px}
  .di{width:40px;height:40px;background:var(--gm);border:1px solid rgba(0,230,100,.2);
    border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:19px;flex-shrink:0}
  .dn{font-size:13px;font-weight:800;color:var(--text);letter-spacing:-.3px}
  .ds{font-size:10px;color:var(--muted);margin-top:2px}
  .pills{display:flex;gap:4px;margin-top:6px;flex-wrap:wrap}
  .pill{font-size:8px;font-weight:700;color:var(--green-dim);background:var(--gm);
    border:1px solid rgba(0,200,83,.15);border-radius:3px;padding:2px 5px;letter-spacing:.3px;text-transform:uppercase}
  .cta{font-size:11px;font-weight:800;color:#060c09;background:var(--green);border-radius:8px;
    padding:9px 15px;white-space:nowrap;flex-shrink:0;letter-spacing:-.2px;
    transition:background .15s,box-shadow .15s;box-shadow:0 0 20px rgba(0,230,100,.25)}
  .db:hover .cta{background:#10ff70;box-shadow:0 0 32px rgba(0,230,100,.45)}
  .status{display:flex;align-items:center;font-size:10px;color:var(--muted)}
  .si2{display:flex;align-items:center;gap:5px;padding:0 14px}
  .si2+.si2{border-left:1px solid var(--border)}
  .dot{width:5px;height:5px;border-radius:50%;background:var(--green);
    box-shadow:0 0 7px var(--green);animation:beat 2.5s ease-in-out infinite}
  .stm{font-variant-numeric:tabular-nums;font-weight:600;color:var(--dim)}
  @keyframes beat{0%,100%{opacity:1;box-shadow:0 0 6px var(--green)}50%{opacity:.6;box-shadow:0 0 13px var(--green)}}
</style>
</head>
<body>
<canvas id="sc"></canvas>
<div class="aurora"></div>
<svg class="mtn" viewBox="0 0 1440 900" preserveAspectRatio="xMidYMax slice">
  <defs>
    <linearGradient id="mf" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#0a1f12"/><stop offset="100%" stop-color="#061009"/></linearGradient>
    <linearGradient id="mm" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#0d2818"/><stop offset="100%" stop-color="#071510"/></linearGradient>
    <linearGradient id="mn" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#071a0e"/><stop offset="100%" stop-color="#040d07"/></linearGradient>
    <linearGradient id="sn" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="rgba(200,240,210,0.55)"/><stop offset="100%" stop-color="rgba(100,160,120,0)"/></linearGradient>
  </defs>
  <ellipse cx="720" cy="620" rx="500" ry="80" fill="rgba(0,200,83,0.04)"/>
  <ellipse cx="720" cy="620" rx="300" ry="50" fill="rgba(0,200,83,0.06)"/>
  <path d="M0 680 L80 560 L160 620 L260 490 L360 580 L440 520 L540 460 L640 540 L720 470 L800 530 L880 460 L980 510 L1080 440 L1180 510 L1280 470 L1360 540 L1440 500 L1440 900 L0 900Z" fill="url(#mf)" opacity=".9"/>
  <path d="M540 460 L490 490 L540 460 L590 485Z" fill="url(#sn)"/>
  <path d="M720 470 L680 500 L720 470 L760 498Z" fill="url(#sn)"/>
  <path d="M1080 440 L1030 475 L1080 440 L1130 472Z" fill="url(#sn)"/>
  <path d="M0 720 L60 630 L140 680 L220 600 L320 650 L420 560 L500 620 L580 540 L680 610 L760 550 L860 600 L960 520 L1060 590 L1160 530 L1260 600 L1360 550 L1440 580 L1440 900 L0 900Z" fill="url(#mm)" opacity=".95"/>
  <path d="M420 560 L380 590 L420 560 L465 585Z" fill="url(#sn)" opacity=".8"/>
  <path d="M580 540 L545 570 L580 540 L618 567Z" fill="url(#sn)" opacity=".8"/>
  <path d="M960 520 L920 555 L960 520 L1002 553Z" fill="url(#sn)" opacity=".8"/>
  <path d="M0 720 L60 630 L140 680 L220 600 L320 650 L420 560 L500 620 L580 540 L680 610 L760 550 L860 600 L960 520 L1060 590 L1160 530 L1260 600 L1360 550 L1440 580" fill="none" stroke="rgba(0,200,83,0.12)" stroke-width="2"/>
  <path d="M0 800 L100 710 L200 760 L300 690 L420 740 L520 660 L620 720 L720 650 L820 710 L920 640 L1020 700 L1120 650 L1220 710 L1320 660 L1440 720 L1440 900 L0 900Z" fill="url(#mn)"/>
  <path d="M0 800 L100 710 L200 760 L300 690 L420 740 L520 660 L620 720 L720 650 L820 710 L920 640 L1020 700 L1120 650 L1220 710 L1320 660 L1440 720" fill="none" stroke="rgba(0,200,83,0.08)" stroke-width="1.5"/>
  <path d="M0 860 Q360 820 720 840 Q1080 860 1440 830 L1440 900 L0 900Z" fill="#020806" opacity=".8"/>
  <ellipse cx="360" cy="820" rx="200" ry="20" fill="rgba(0,200,83,0.025)"/>
  <ellipse cx="1080" cy="810" rx="180" ry="18" fill="rgba(0,200,83,0.025)"/>
</svg>
<div class="page">
  <div style="text-align:center">
    <div class="logo">
      <svg width="32" height="32" viewBox="0 0 36 36" fill="none">
        <rect width="36" height="36" rx="9" fill="#00c853"/>
        <path d="M18 6L8 11V19.5C8 25.3 12.5 30.6 18 32C23.5 30.6 28 25.3 28 19.5V11L18 6Z" fill="#060c09" opacity=".95"/>
        <path d="M14.5 18.5L17 21L22 15.5" stroke="#00e664" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
      <span class="lt">Zero<em>Trust</em> Browser</span>
    </div>
    <div class="tl">Mountain OS · Secured by ZeroTrust</div>
  </div>
  <div style="text-align:center">
    <div class="clk" id="clk">00:00</div>
    <div class="dt" id="dt"></div>
  </div>
  <div class="sb">
    <svg class="si" width="15" height="15" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>
    </svg>
    <input class="inp" type="text" id="search" placeholder="Search or enter address..." autofocus onkeydown="go(event)"/>
    <span class="ddg">
      <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      DuckDuckGo
    </span>
  </div>
  <div style="width:100%">
    <div class="sec-hdr"><span class="sec-t">Security &amp; Utility Tools</span><span class="sec-l"></span></div>
    <div class="grid" style="margin-top:10px">
      <a class="card" href="https://mrichard333.com/extension"><div class="iw">🛡️</div><div><div class="cn">ZeroTrust Extension</div><div class="cd">Real-time protection</div></div></a>
      <a class="card" href="https://mrichard333.com/Cyberhealth"><div class="iw">🩺</div><div><div class="cn">Cyberhealth Audit</div><div class="cd">Digital hygiene check</div></div></a>
      <a class="card" href="https://mrichard333.com/password-check"><div class="iw">⚡</div><div><div class="cn">Password Entropy</div><div class="cd">Brute-force simulation</div></div></a>
      <a class="card" href="https://mrichard333.com/link-scanner"><div class="iw">🔗</div><div><div class="cn">URL Forensics</div><div class="cd">Deep link analysis</div></div></a>
      <a class="card" href="https://mrichard333.com/files-compressor"><div class="iw">🗜️</div><div><div class="cn">Files Compressor</div><div class="cd">Local, no uploads</div></div></a>
      <a class="card" href="https://mrichard333.com/seo-analyser"><div class="iw">📈</div><div><div class="cn">SEO Analyser</div><div class="cd">20+ automated checks</div></div></a>
      <a class="card" href="https://mrichard333.com/webtools"><div class="iw">🔍</div><div><div class="cn">View All Free Tools</div><div class="cd">More tools</div></div></a>
      <a class="card" href="https://mrichard333.com"><div class="iw">🏠</div><div><div class="cn">Home</div><div class="cd">Fraud prevention</div></div></a>
    </div>
  </div>
  <a class="db" href="https://mrichard333.com/dashboard">
    <div class="dl">
      <div class="di">📊</div>
      <div>
        <div class="dn">Security Dashboard</div>
        <div class="ds">Full suite · login required</div>
        <div class="pills">
          <span class="pill">Dark Web</span><span class="pill">CVE Tracker</span>
          <span class="pill">Identity Breach</span><span class="pill">Vendor Risk</span>
          <span class="pill">+6 more</span>
        </div>
      </div>
    </div>
    <span class="cta">Open Dashboard →</span>
  </a>
  <div class="status">
    <div class="si2"><span class="dot"></span><span>ZeroTrust Active</span></div>
    <div class="si2"><span class="stm" id="st"></span></div>
    <div class="si2"><span>Mountain OS</span></div>
  </div>
</div>
<script>
  const cv=document.getElementById('sc'),cx=cv.getContext('2d');
  function rs(){cv.width=window.innerWidth;cv.height=window.innerHeight;ds()}
  function ds(){
    cx.clearRect(0,0,cv.width,cv.height);
    const n=Math.floor(cv.width*cv.height/3000);
    for(let i=0;i<n;i++){
      const x=Math.random()*cv.width,y=Math.random()*cv.height*.65;
      const r=Math.random()*.9+.1,a=Math.random()*.6+.1;
      cx.beginPath();cx.arc(x,y,r,0,Math.PI*2);
      cx.fillStyle='rgba(180,240,200,'+a+')';cx.fill();
    }
  }
  rs();window.addEventListener('resize',rs);
  const DD=['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  const MM=['January','February','March','April','May','June','July','August','September','October','November','December'];
  function tick(){
    const n=new Date(),h=String(n.getHours()).padStart(2,'0'),m=String(n.getMinutes()).padStart(2,'0'),s=String(n.getSeconds()).padStart(2,'0');
    const c=document.getElementById('clk');if(c)c.textContent=h+':'+m;
    const d=document.getElementById('dt');if(d)d.textContent=DD[n.getDay()]+', '+MM[n.getMonth()]+' '+n.getDate();
    const t=document.getElementById('st');if(t)t.textContent=h+':'+m+':'+s;
  }
  tick();setInterval(tick,1000);
  function go(e){
    if(e.key!=='Enter')return;
    const q=e.target.value.trim();if(!q)return;
    const isUrl=/^https?:\/\//.test(q)||/^[\w-]+\.[\w]{2,}(\/|$)/.test(q);
    window.location.href=isUrl?(q.startsWith('http')?q:'https://'+q):'https://duckduckgo.com/?q='+encodeURIComponent(q);
  }
  document.getElementById('search').focus();
</script>
</body>
</html>
NEWTABHTML

  python3 -c "
import struct,zlib
def png(sz,r,g,b):
    def ck(n,d):
        c=zlib.crc32(n+d)&0xffffffff
        return struct.pack('>I',len(d))+n+d+struct.pack('>I',c)
    ih=struct.pack('>IIBBBBB',sz,sz,8,2,0,0,0)
    raw=b''.join(b'\x00'+bytes([r,g,b])*sz for _ in range(sz))
    return b'\x89PNG\r\n\x1a\n'+ck(b'IHDR',ih)+ck(b'IDAT',zlib.compress(raw))+ck(b'IEND',b'')
open('$NEWTAB_BUILD/icons/icon48.png','wb').write(png(48,0,200,83))
open('$NEWTAB_BUILD/icons/icon128.png','wb').write(png(128,0,200,83))
"
  (cd "$NEWTAB_BUILD" && zip -r "$NEWTAB_XPI" . -x "*.DS_Store" >/dev/null)
  rm -rf "$NEWTAB_BUILD"
  ok "zerotrust-newtab.xpi built ($(du -sh "$NEWTAB_XPI" | cut -f1))"
fi

# Stage the XPI in the profile and update policies with exact file:// path
cp "$NEWTAB_XPI" "$EXT_DIR/${NEWTAB_ID}.xpi"
STAGED_PATH="$(realpath "$EXT_DIR/${NEWTAB_ID}.xpi")"

python3 - "$POLICIES_DIR/policies.json" "$NEWTAB_ID" "$STAGED_PATH" <<'PYEOF'
import json, sys
path, ext_id, staged = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f: pol = json.load(f)
pol.setdefault('policies',{}).setdefault('ExtensionSettings',{})[ext_id] = {
    'installation_mode': 'force_installed',
    'install_url': 'file://' + staged
}
with open(path,'w') as f: json.dump(pol,f,indent=2)
print(f'  newtab policy → file://{staged}')
PYEOF

ok "ZeroTrust New Tab staged and policies updated"

# Fix ownership — everything in the profile must belong to REAL_USER
chown -R "$REAL_USER":"$REAL_USER" "$PROFILE_PATH"

# ════════════════════════════════════════════════════════════
# 9. CUSTOM ICON
# ════════════════════════════════════════════════════════════
section "Custom icon"

ICON_DIR="$SCRIPT_DIR/icons"
if [[ -d "$ICON_DIR" ]]; then
  [[ -f "$ICON_DIR/zerotrust_256.png" ]] && \
    cp "$ICON_DIR/zerotrust_256.png" /usr/share/icons/zerotrust-browser.png
  for SIZE in 16 32 48 64 128 256; do
    ICON_FILE="$ICON_DIR/zerotrust_${SIZE}.png"
    if [[ -f "$ICON_FILE" ]]; then
      mkdir -p "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
      cp "$ICON_FILE" "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/zerotrust-browser.png"
    fi
  done
  gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true
  ok "Custom icons installed"
else
  warn "icons/ folder not found — using Firefox icon"
fi

# ════════════════════════════════════════════════════════════
# 10. DESKTOP SHORTCUT
# ════════════════════════════════════════════════════════════
section "Desktop shortcut"

[[ -f "$SCRIPT_DIR/zerotrust-browser.desktop" ]] || err "zerotrust-browser.desktop not found"

DESKTOP_LOCAL="$REAL_HOME/.local/share/applications/zerotrust-browser.desktop"
mkdir -p "$(dirname "$DESKTOP_LOCAL")"
cp "$SCRIPT_DIR/zerotrust-browser.desktop" "$DESKTOP_LOCAL"
chmod +x "$DESKTOP_LOCAL"
chown "$REAL_USER":"$REAL_USER" "$DESKTOP_LOCAL"

if [[ -d "$REAL_HOME/Desktop" ]]; then
  cp "$SCRIPT_DIR/zerotrust-browser.desktop" "$REAL_HOME/Desktop/zerotrust-browser.desktop"
  chmod +x "$REAL_HOME/Desktop/zerotrust-browser.desktop"
  chown "$REAL_USER":"$REAL_USER" "$REAL_HOME/Desktop/zerotrust-browser.desktop"
  ok "Desktop shortcut created"
fi

cp "$SCRIPT_DIR/zerotrust-browser.desktop" /usr/share/applications/zerotrust-browser.desktop 2>/dev/null && \
  update-desktop-database /usr/share/applications/ 2>/dev/null && \
  ok "System app entry registered" || warn "Could not register system-wide — local entry still works"

# ════════════════════════════════════════════════════════════
# 11. DEFAULT BROWSER
# ════════════════════════════════════════════════════════════
section "Default browser"

if command -v xdg-settings &>/dev/null; then
  sudo -u "$REAL_USER" xdg-settings set default-web-browser zerotrust-browser.desktop 2>/dev/null && \
    ok "Set as default browser" || warn "Set default browser manually in System Settings"
elif command -v update-alternatives &>/dev/null; then
  update-alternatives --set x-www-browser "$FIREFOX_BIN" 2>/dev/null && \
    ok "Default browser set" || warn "Could not set default browser"
fi

# ════════════════════════════════════════════════════════════
# 12. PIN TO GNOME DOCK
# ════════════════════════════════════════════════════════════
section "Taskbar pin"

if command -v gsettings &>/dev/null; then
  CURRENT=$(sudo -u "$REAL_USER" gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "@as []")
  if echo "$CURRENT" | grep -q "zerotrust-browser\|firefox"; then
    ok "Browser already in dock"
  else
    NEW=$(echo "$CURRENT" | sed "s/]$/, 'zerotrust-browser.desktop']/")
    sudo -u "$REAL_USER" gsettings set org.gnome.shell favorite-apps "$NEW" 2>/dev/null && \
      ok "Pinned to GNOME dock" || warn "Pin manually by right-clicking the app in Activities"
  fi
else
  warn "gsettings not available — pin manually"
fi

# ════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════
echo ""
echo "  ──────────────────────────────────────"
echo -e "  ${GREEN}ZeroTrust Browser setup complete!${NC}"
echo ""
echo "  · policies.json  → $POLICIES_DIR"
echo "  · user.js        → $PROFILE_PATH"
echo "  · chrome/        → $PROFILE_PATH/chrome/"
echo "  · extensions/    → $PROFILE_PATH/extensions/"
echo ""
echo "  ⚠  NEXT STEPS:"
echo "     1. Fully QUIT Firefox (File → Quit)"
echo "     2. Relaunch Firefox"
echo "     3. Verify: about:policies  (should show Active)"
echo "     4. Verify: about:addons    (extensions installed)"
echo ""