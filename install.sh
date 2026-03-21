#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser — Full Setup Script
#  For Mountain OS (Ubuntu base)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIREFOX_DIR="$HOME/.mozilla/firefox"
SNAP_FIREFOX_DIR="$HOME/snap/firefox/common/.mozilla/firefox"

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
echo ""

# ════════════════════════════════════════════════════════════
# 1. DETECT FIREFOX
# ════════════════════════════════════════════════════════════
section "Firefox"

IS_SNAP=false
FIREFOX_BIN=""

if snap list firefox &>/dev/null 2>&1; then
  IS_SNAP=true
  FIREFOX_DIR="$SNAP_FIREFOX_DIR"
  FIREFOX_BIN="/snap/bin/firefox"
  ok "Snap Firefox detected"
elif command -v firefox &>/dev/null; then
  FIREFOX_BIN=$(command -v firefox)
  ok "Firefox found: $(firefox --version 2>/dev/null | head -1)"
else
  warn "Firefox not found — installing via apt..."
  sudo apt-get update -qq
  sudo apt-get install -y firefox
  FIREFOX_BIN=$(command -v firefox)
  ok "Firefox installed"
fi

# ════════════════════════════════════════════════════════════
# 2. DOWNLOAD EXTENSIONS LOCALLY
#    Local XPIs let Firefox install without AMO connectivity
#    and bypass the force_installed timing race.
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
#    Snap reads from /var/snap/firefox/common/policies
#    Non-snap reads from /usr/lib/firefox/distribution
# ════════════════════════════════════════════════════════════
section "Enterprise policies"

[[ -f "$SCRIPT_DIR/policies.json" ]] || err "policies.json not found in $SCRIPT_DIR"

if [[ "$IS_SNAP" == true ]]; then
  POLICIES_DIR="/var/snap/firefox/common/policies"
  POLICIES_DIR_USER="$HOME/snap/firefox/common/policies"
  sudo mkdir -p "$POLICIES_DIR"
  mkdir -p "$POLICIES_DIR_USER"
  sudo cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR/policies.json"
  cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR_USER/policies.json"
  ok "policies.json → $POLICIES_DIR (system)"
  ok "policies.json → $POLICIES_DIR_USER (user)"
else
  POLICIES_DIR="/usr/lib/firefox/distribution"
  [[ -d "/usr/lib/firefox-esr/distribution" ]] && POLICIES_DIR="/usr/lib/firefox-esr/distribution"
  sudo mkdir -p "$POLICIES_DIR"
  sudo cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR/policies.json"
  ok "policies.json → $POLICIES_DIR"
fi

# Patch all extension install_urls to use local file:// paths where available.
# This is done with a single clean Python script — no heredoc string escaping issues.
python3 "$SCRIPT_DIR/patch_policies.py" \
  "$POLICIES_DIR/policies.json" \
  "$EXT_CACHE" \
  "$ZEROTRUST_ID" "$UBLOCK_ID" "$BITWARDEN_ID" "$CONTAINERS_ID" "$CLEARURLS_ID" "$LOCALCDN_ID" \
  2>/dev/null && ok "Extension URLs patched to local file:// paths" \
  || warn "Could not patch extension URLs (python3 error) — AMO URLs will be used"

if [[ "$IS_SNAP" == true ]]; then
  cp "$POLICIES_DIR/policies.json" "$POLICIES_DIR_USER/policies.json" 2>/dev/null || true
fi

# ════════════════════════════════════════════════════════════
# 4. FIREFOX PROFILE
# ════════════════════════════════════════════════════════════
section "Firefox profile"

if [[ ! -d "$FIREFOX_DIR" ]]; then
  warn "No profile found — creating via headless launch..."
  "$FIREFOX_BIN" --headless --no-remote &>/dev/null &
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
#    Placing XPIs directly in profile/extensions/{id}.xpi
#    means Firefox loads them on next launch — no AMO needed,
#    no timing issues with policy enforcement.
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

# Newtab extension — from project folder, not ext-cache
NEWTAB_XPI="$SCRIPT_DIR/zerotrust-newtab.xpi"
if [[ -f "$NEWTAB_XPI" ]]; then
  cp "$NEWTAB_XPI" "$EXT_DIR/${NEWTAB_ID}.xpi"
  ok "ZeroTrust New Tab staged"
else
  warn "zerotrust-newtab.xpi not found in $SCRIPT_DIR — new tab page will not load"
fi

# ════════════════════════════════════════════════════════════
# 8. CUSTOM ICON
# ════════════════════════════════════════════════════════════
section "Custom icon"

ICON_DIR="$SCRIPT_DIR/icons"
if [[ -d "$ICON_DIR" ]]; then
  [[ -f "$ICON_DIR/zerotrust_256.png" ]] && \
    sudo cp "$ICON_DIR/zerotrust_256.png" /usr/share/icons/zerotrust-browser.png
  for SIZE in 16 32 48 64 128 256; do
    ICON_FILE="$ICON_DIR/zerotrust_${SIZE}.png"
    if [[ -f "$ICON_FILE" ]]; then
      sudo mkdir -p "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
      sudo cp "$ICON_FILE" "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/zerotrust-browser.png"
    fi
  done
  sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true
  ok "Custom icons installed"
else
  warn "icons/ folder not found — using Firefox icon"
fi

# ════════════════════════════════════════════════════════════
# 9. DESKTOP SHORTCUT
# ════════════════════════════════════════════════════════════
section "Desktop shortcut"

[[ -f "$SCRIPT_DIR/zerotrust-browser.desktop" ]] || err "zerotrust-browser.desktop not found"

DESKTOP_LOCAL="$HOME/.local/share/applications/zerotrust-browser.desktop"
cp "$SCRIPT_DIR/zerotrust-browser.desktop" "$DESKTOP_LOCAL"
chmod +x "$DESKTOP_LOCAL"

if [[ -d "$HOME/Desktop" ]]; then
  cp "$SCRIPT_DIR/zerotrust-browser.desktop" "$HOME/Desktop/zerotrust-browser.desktop"
  chmod +x "$HOME/Desktop/zerotrust-browser.desktop"
  ok "Desktop shortcut created"
fi

sudo cp "$SCRIPT_DIR/zerotrust-browser.desktop" /usr/share/applications/zerotrust-browser.desktop 2>/dev/null && \
  sudo update-desktop-database /usr/share/applications/ 2>/dev/null && \
  ok "System app entry registered" || warn "Could not register system-wide — local entry still works"

# ════════════════════════════════════════════════════════════
# 10. DEFAULT BROWSER
# ════════════════════════════════════════════════════════════
section "Default browser"

if command -v xdg-settings &>/dev/null; then
  xdg-settings set default-web-browser zerotrust-browser.desktop 2>/dev/null && \
    ok "Set as default browser" || warn "Set default browser manually in System Settings"
elif command -v update-alternatives &>/dev/null; then
  sudo update-alternatives --set x-www-browser "$FIREFOX_BIN" 2>/dev/null && \
    ok "Default browser set" || warn "Could not set default browser"
fi

# ════════════════════════════════════════════════════════════
# 11. PIN TO GNOME DOCK
# ════════════════════════════════════════════════════════════
section "Taskbar pin"

if command -v gsettings &>/dev/null; then
  CURRENT=$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "@as []")
  if echo "$CURRENT" | grep -q "zerotrust-browser\|firefox"; then
    ok "Browser already in dock"
  else
    NEW=$(echo "$CURRENT" | sed "s/]$/, 'zerotrust-browser.desktop']/")
    gsettings set org.gnome.shell favorite-apps "$NEW" 2>/dev/null && \
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
echo "     4. Verify: about:addons    (ZeroTrust + uBlock pinned)"
echo ""