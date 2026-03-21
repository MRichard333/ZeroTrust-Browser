#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser — Full Setup Script
#  For Mountain OS (Ubuntu base)
#
#  Extension ID: zerotrust@mrichard333.com (confirmed from manifest)
#  Firefox min:  140 (current stable: 148)
#
#  KEY FIX: Extensions are downloaded and staged locally in
#  profile/extensions/ so Firefox loads them immediately
#  without depending on AMO connectivity or policy timing.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIREFOX_DIR="$HOME/.mozilla/firefox"
SNAP_FIREFOX_DIR="$HOME/snap/firefox/common/.mozilla/firefox"

# Confirmed extension IDs from manifest.json files
ZEROTRUST_ID="zerotrust@mrichard333.com"
ZEROTRUST_URL="https://addons.mozilla.org/firefox/downloads/file/4730187/zerotrust_dashboard_extension-2.1.0.xpi"
UBLOCK_ID="uBlock0@raymondhill.net"
UBLOCK_URL="https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"

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
# 1. FIREFOX
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
  ok "Firefox installed: $(firefox --version 2>/dev/null | head -1)"
else
  warn "Firefox not found. Installing via apt..."
  sudo apt-get update -qq
  sudo apt-get install -y firefox
  FIREFOX_BIN=$(command -v firefox)
  ok "Firefox installed"
fi

# ════════════════════════════════════════════════════════════
# 2. DOWNLOAD EXTENSIONS TO LOCAL CACHE
#    Caching locally means:
#    - Works offline after first install
#    - Firefox loads from file:// instantly (no AMO delay)
#    - Avoids force_installed timing race with AMO downloads
# ════════════════════════════════════════════════════════════
section "Downloading extensions to local cache"

EXT_CACHE="$SCRIPT_DIR/ext-cache"
mkdir -p "$EXT_CACHE"

download_ext() {
  local label="$1" url="$2" dest="$3"
  if [[ -f "$dest" ]]; then
    ok "$label already cached — skipping download"
    return 0
  fi
  echo -n "  Downloading $label... "
  if curl -fsSL --connect-timeout 15 --retry 2 "$url" -o "$dest"; then
    echo -e "${GREEN}done${NC} ($(du -sh "$dest" | cut -f1))"
  else
    warn "$label download failed — will use AMO URL in policies as fallback"
    rm -f "$dest"
  fi
}

ZEROTRUST_XPI="$EXT_CACHE/zerotrust.xpi"
UBLOCK_XPI="$EXT_CACHE/ublock-origin.xpi"

download_ext "ZeroTrust Dashboard Extension" "$ZEROTRUST_URL" "$ZEROTRUST_XPI"
download_ext "uBlock Origin" "$UBLOCK_URL" "$UBLOCK_XPI"

# ════════════════════════════════════════════════════════════
# 3. ENTERPRISE POLICIES
#
#  SNAP FIX: Snap Firefox ignores /etc/firefox/policies.
#  It reads policies from:
#    - /var/snap/firefox/common/policies  (system-wide, needs sudo)
#    - $HOME/snap/firefox/common/policies (per-user, no sudo)
#  We write to BOTH to guarantee it's picked up.
#
#  NON-SNAP: /usr/lib/firefox/distribution/policies.json
# ════════════════════════════════════════════════════════════
section "Enterprise policies"

POLICIES_SRC="$SCRIPT_DIR/policies.json"
[[ -f "$POLICIES_SRC" ]] || err "policies.json not found in $SCRIPT_DIR"

if [[ "$IS_SNAP" == true ]]; then
  POLICIES_DIR="/var/snap/firefox/common/policies"
  POLICIES_DIR_USER="$HOME/snap/firefox/common/policies"
  sudo mkdir -p "$POLICIES_DIR"
  sudo cp "$POLICIES_SRC" "$POLICIES_DIR/policies.json"
  mkdir -p "$POLICIES_DIR_USER"
  cp "$POLICIES_SRC" "$POLICIES_DIR_USER/policies.json"
  ok "policies.json → $POLICIES_DIR"
  ok "policies.json → $POLICIES_DIR_USER"
else
  POLICIES_DIR="/usr/lib/firefox/distribution"
  [[ -d "/usr/lib/firefox-esr/distribution" ]] && POLICIES_DIR="/usr/lib/firefox-esr/distribution"
  sudo mkdir -p "$POLICIES_DIR"
  sudo cp "$POLICIES_SRC" "$POLICIES_DIR/policies.json"
  ok "policies.json → $POLICIES_DIR"
fi

# Patch install_url to use local file:// path if XPI was downloaded.
# This eliminates the dependency on AMO being reachable at install time.
patch_extension_urls() {
  local pol_file="$1"
  local use_sudo="$2"

  local patch_cmd
  patch_cmd=$(cat <<PYEOF
import json, sys, os

pol_path     = "$pol_file"
zt_id        = "$ZEROTRUST_ID"
ub_id        = "$UBLOCK_ID"
zt_xpi       = "$ZEROTRUST_XPI"
ub_xpi       = "$UBLOCK_XPI"
zt_url_amo   = "$ZEROTRUST_URL"
ub_url_amo   = "$UBLOCK_URL"

with open(pol_path) as f:
    pol = json.load(f)

ext = pol.setdefault("policies", {}).setdefault("ExtensionSettings", {})

ext[ub_id] = {
    "installation_mode": "force_installed",
    "install_url": ("file://" + os.path.abspath(ub_xpi)) if os.path.isfile(ub_xpi) else ub_url_amo
}

ext[zt_id] = {
    "installation_mode": "force_installed",
    "install_url": ("file://" + os.path.abspath(zt_xpi)) if os.path.isfile(zt_xpi) else zt_url_amo
}

with open(pol_path, "w") as f:
    json.dump(pol, f, indent=2)

print(f"  ZeroTrust → {ext[zt_id]['install_url'][:72]}")
print(f"  uBlock    → {ext[ub_id]['install_url'][:72]}")
PYEOF
)

  if [[ "$use_sudo" == true ]]; then
    sudo python3 -c "$patch_cmd"
  else
    python3 -c "$patch_cmd"
  fi
}

if command -v python3 &>/dev/null; then
  if [[ "$IS_SNAP" == true ]]; then
    patch_extension_urls "$POLICIES_DIR/policies.json" true
    patch_extension_urls "$POLICIES_DIR_USER/policies.json" false
  else
    patch_extension_urls "$POLICIES_DIR/policies.json" true
  fi
  ok "policies.json patched with local XPI paths"
else
  warn "python3 not available — policies not patched (using AMO URLs)"
fi

# ════════════════════════════════════════════════════════════
# 4. CREATE FIREFOX PROFILE IF NEEDED
# ════════════════════════════════════════════════════════════
section "Firefox profile"

if [[ ! -d "$FIREFOX_DIR" ]]; then
  warn "No profile found. Creating via headless launch..."
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
  warn "Auto-detect failed. Available profiles:"
  mapfile -t PROFILE_DIRS < <(find "$FIREFOX_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
  [[ ${#PROFILE_DIRS[@]} -eq 0 ]] && err "No profiles found in $FIREFOX_DIR"
  for i in "${!PROFILE_DIRS[@]}"; do echo "  [$i] ${PROFILE_DIRS[$i]}"; done
  read -rp "  Enter number [0]: " CHOICE
  PROFILE_PATH="${PROFILE_DIRS[${CHOICE:-0}]}"
fi

[[ -d "$PROFILE_PATH" ]] || err "Profile not found: $PROFILE_PATH"
ok "Profile: $PROFILE_PATH"

# ════════════════════════════════════════════════════════════
# 5. user.js
# ════════════════════════════════════════════════════════════
section "user.js"

USER_JS_SRC="$SCRIPT_DIR/user.js"
[[ -f "$USER_JS_SRC" ]] || err "user.js not found"
DEST_JS="$PROFILE_PATH/user.js"
[[ -f "$DEST_JS" ]] && cp "$DEST_JS" "$DEST_JS.bak.$(date +%Y%m%d%H%M%S)" && warn "Existing user.js backed up"
cp "$USER_JS_SRC" "$DEST_JS"
ok "user.js installed"

# ════════════════════════════════════════════════════════════
# 6. userChrome.css
# ════════════════════════════════════════════════════════════
section "userChrome.css"

CHROME_DIR="$PROFILE_PATH/chrome"
mkdir -p "$CHROME_DIR"
CHROME_CSS_SRC="$SCRIPT_DIR/userChrome.css"
[[ -f "$CHROME_CSS_SRC" ]] || err "userChrome.css not found"
cp "$CHROME_CSS_SRC" "$CHROME_DIR/userChrome.css"
ok "userChrome.css installed"

# ════════════════════════════════════════════════════════════
# 7. STAGE EXTENSION XPIs IN PROFILE
#
#  This is the most reliable way to get extensions loaded:
#  place them directly in profile/extensions/{id}.xpi
#  Firefox picks them up on next launch without needing
#  to contact AMO or wait for policy enforcement timing.
# ════════════════════════════════════════════════════════════
section "Staging extensions in profile"

EXT_DIR="$PROFILE_PATH/extensions"
mkdir -p "$EXT_DIR"

if [[ -f "$ZEROTRUST_XPI" ]]; then
  cp "$ZEROTRUST_XPI" "$EXT_DIR/${ZEROTRUST_ID}.xpi"
  ok "zerotrust@mrichard333.com staged in profile/extensions/"
else
  warn "ZeroTrust XPI not cached — extension will install via AMO on first launch"
fi

if [[ -f "$UBLOCK_XPI" ]]; then
  cp "$UBLOCK_XPI" "$EXT_DIR/${UBLOCK_ID}.xpi"
  ok "uBlock0@raymondhill.net staged in profile/extensions/"
else
  warn "uBlock XPI not cached — extension will install via AMO on first launch"
fi

# ════════════════════════════════════════════════════════════
# 8. NEW TAB EXTENSION (optional)
# ════════════════════════════════════════════════════════════
section "New tab page extension"

NEWTAB_XPI="$SCRIPT_DIR/zerotrust-newtab.xpi"
if [[ -f "$NEWTAB_XPI" ]]; then
  NEWTAB_ID="zerotrust-newtab@mrichard333.com"
  cp "$NEWTAB_XPI" "$EXT_DIR/${NEWTAB_ID}.xpi"
  ok "zerotrust-newtab staged in profile/extensions/"
else
  warn "zerotrust-newtab.xpi not found — new tab page will be blank (expected)"
fi

# ════════════════════════════════════════════════════════════
# 9. CUSTOM ICON
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
  ok "Custom icon installed"
else
  warn "icons/ folder not found — using Firefox icon as fallback"
fi

# ════════════════════════════════════════════════════════════
# 10. DESKTOP SHORTCUT
# ════════════════════════════════════════════════════════════
section "Desktop shortcut"

DESKTOP_SRC="$SCRIPT_DIR/zerotrust-browser.desktop"
[[ -f "$DESKTOP_SRC" ]] || err "zerotrust-browser.desktop not found"

DESKTOP_LOCAL="$HOME/.local/share/applications/zerotrust-browser.desktop"
cp "$DESKTOP_SRC" "$DESKTOP_LOCAL" && chmod +x "$DESKTOP_LOCAL"

if [[ -d "$HOME/Desktop" ]]; then
  cp "$DESKTOP_SRC" "$HOME/Desktop/zerotrust-browser.desktop"
  chmod +x "$HOME/Desktop/zerotrust-browser.desktop"
  ok "Desktop shortcut created"
fi

sudo cp "$DESKTOP_SRC" /usr/share/applications/zerotrust-browser.desktop 2>/dev/null && \
  sudo update-desktop-database /usr/share/applications/ 2>/dev/null && \
  ok "System app entry registered" || \
  warn "Could not register system-wide — local entry still works"

# ════════════════════════════════════════════════════════════
# 11. DEFAULT BROWSER
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
# 12. PIN TO GNOME DOCK
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
  warn "gsettings not available — pin to taskbar manually"
fi

# ════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════
echo ""
echo "  ──────────────────────────────────────"
echo -e "  ${GREEN}ZeroTrust Browser setup complete!${NC}"
echo ""
echo "  · policies.json   → $POLICIES_DIR"
echo "  · user.js         → $PROFILE_PATH"
echo "  · userChrome.css  → $PROFILE_PATH/chrome/"
echo "  · Extensions      → $PROFILE_PATH/extensions/"
echo ""
echo "  ⚠  NEXT STEPS:"
echo "     1. Fully QUIT Firefox (File → Quit, not just close window)"
echo "     2. Relaunch Firefox"
echo "     3. Check about:policies  — policies should show as Active"
echo "     4. Check about:addons    — ZeroTrust + uBlock should appear"
echo ""
echo "  If extensions still don't appear after restart:"
echo "     • Open about:policies and look for any 'inactive' rows"
echo "     • Check that the install_url file:// paths exist on disk"
echo "     • Run: ls $PROFILE_PATH/extensions/"
echo ""