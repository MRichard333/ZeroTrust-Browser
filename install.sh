#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser — Full Setup Script
#  For Mountain OS (Ubuntu base)
#  Bundles: user.js, userChrome.css, policies.json,
#           newtab extension, custom icon,
#           desktop shortcut, default browser, taskbar pin
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIREFOX_DIR="$HOME/.mozilla/firefox"
SNAP_FIREFOX_DIR="$HOME/snap/firefox/common/.mozilla/firefox"

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
  ok "Firefox already installed: $(firefox --version 2>/dev/null | head -1)"
else
  warn "Firefox not found. Installing via apt..."
  sudo apt-get update -qq
  sudo apt-get install -y firefox
  FIREFOX_BIN=$(command -v firefox)
  ok "Firefox installed"
fi

# ════════════════════════════════════════════════════════════
# 2. ENTERPRISE POLICIES — force-installs extensions properly
# ════════════════════════════════════════════════════════════
section "Enterprise policies (extensions + settings)"

POLICIES_SRC="$SCRIPT_DIR/policies.json"
[[ -f "$POLICIES_SRC" ]] || err "policies.json not found in $SCRIPT_DIR"

if [[ "$IS_SNAP" == true ]]; then
  POLICIES_DIR="/etc/firefox/policies"
else
  POLICIES_DIR="/usr/lib/firefox/distribution"
  [[ -d "/usr/lib/firefox-esr/distribution" ]] && POLICIES_DIR="/usr/lib/firefox-esr/distribution"
fi

sudo mkdir -p "$POLICIES_DIR"
sudo cp "$POLICIES_SRC" "$POLICIES_DIR/policies.json"
ok "policies.json → $POLICIES_DIR"
ok "uBlock Origin + ZeroTrust Extension will auto-install on first Firefox launch"

# ════════════════════════════════════════════════════════════
# 3. CREATE FIREFOX PROFILE IF NEEDED
# ════════════════════════════════════════════════════════════
section "Firefox profile"

if [[ ! -d "$FIREFOX_DIR" ]]; then
  warn "No profile found. Creating via headless launch..."
  "$FIREFOX_BIN" --headless --no-remote &>/dev/null &
  FFPID=$!
  sleep 5
  kill "$FFPID" 2>/dev/null || true
  wait "$FFPID" 2>/dev/null || true
  ok "Profile created"
fi

PROFILES_INI="$FIREFOX_DIR/profiles.ini"
PROFILE_PATH=""

if [[ -f "$PROFILES_INI" ]]; then
  DEFAULT_PROFILE=$(awk '/^\[Install/{in_i=1} in_i && /^Default=/{print substr($0,9); in_i=0}' "$PROFILES_INI")
  if [[ -n "$DEFAULT_PROFILE" ]]; then
    [[ "$DEFAULT_PROFILE" == /* ]] && PROFILE_PATH="$DEFAULT_PROFILE" || PROFILE_PATH="$FIREFOX_DIR/$DEFAULT_PROFILE"
  fi
  if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
    FALLBACK=$(awk '/^\[Profile/{in_p=1;path="";rel=1;def=0} in_p&&/^Path=/{path=substr($0,6)} in_p&&/^IsRelative=0/{rel=0} in_p&&/^Default=1/{def=1} in_p&&/^$/{if(def&&path!="")print (rel?"REL:":"ABS:")path; in_p=0}' "$PROFILES_INI")
    if [[ -n "$FALLBACK" ]]; then
      [[ "$FALLBACK" == REL:* ]] && PROFILE_PATH="$FIREFOX_DIR/${FALLBACK#REL:}" || PROFILE_PATH="${FALLBACK#ABS:}"
    fi
  fi
fi

if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
  warn "Auto-detect failed. Available profiles:"
  mapfile -t PROFILE_DIRS < <(find "$FIREFOX_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
  [[ ${#PROFILE_DIRS[@]} -eq 0 ]] && err "No profiles found."
  for i in "${!PROFILE_DIRS[@]}"; do echo "  [$i] ${PROFILE_DIRS[$i]}"; done
  read -rp "  Enter number [0]: " CHOICE
  PROFILE_PATH="${PROFILE_DIRS[${CHOICE:-0}]}"
fi

[[ -d "$PROFILE_PATH" ]] || err "Profile not found: $PROFILE_PATH"
ok "Profile: $PROFILE_PATH"

# ════════════════════════════════════════════════════════════
# 4. user.js
# ════════════════════════════════════════════════════════════
section "user.js"

USER_JS="$SCRIPT_DIR/user.js"
[[ -f "$USER_JS" ]] || err "user.js not found"
DEST_JS="$PROFILE_PATH/user.js"
[[ -f "$DEST_JS" ]] && cp "$DEST_JS" "$DEST_JS.bak.$(date +%Y%m%d%H%M%S)" && warn "Existing user.js backed up"
cp "$USER_JS" "$DEST_JS"
ok "user.js installed"

# ════════════════════════════════════════════════════════════
# 5. userChrome.css
# ════════════════════════════════════════════════════════════
section "userChrome.css"

CHROME_DIR="$PROFILE_PATH/chrome"
mkdir -p "$CHROME_DIR"
CHROME_CSS="$SCRIPT_DIR/userChrome.css"
[[ -f "$CHROME_CSS" ]] || err "userChrome.css not found"
cp "$CHROME_CSS" "$CHROME_DIR/userChrome.css"

if ! grep -q "toolkit.legacyUserProfileCustomizations" "$DEST_JS"; then
  echo '' >> "$DEST_JS"
  echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$DEST_JS"
fi
ok "userChrome.css installed"

# ════════════════════════════════════════════════════════════
# 6. NEW TAB EXTENSION (proper WebExtension override)
# ════════════════════════════════════════════════════════════
section "New tab page extension"

NEWTAB_XPI="$SCRIPT_DIR/zerotrust-newtab.xpi"
if [[ -f "$NEWTAB_XPI" ]]; then
  EXT_ID="zerotrust-newtab@mrichard333.com"
  mkdir -p "$PROFILE_PATH/extensions"
  cp "$NEWTAB_XPI" "$PROFILE_PATH/extensions/${EXT_ID}.xpi"

  # Add to policies so it's trusted
  if command -v python3 &>/dev/null; then
   sudo python3 - "$POLICIES_DIR/policies.json" "$NEWTAB_XPI" "$EXT_ID" <<'PYEOF'
import json, sys
pol_path, xpi_path, ext_id = sys.argv[1], sys.argv[2], sys.argv[3]
with open(pol_path) as f: pol = json.load(f)
pol.setdefault("policies", {}).setdefault("ExtensionSettings", {})[ext_id] = {
  "installation_mode": "force_installed",
  "install_url": f"file://{xpi_path}"
}
with open(pol_path, "w") as f: json.dump(pol, f, indent=2)
print("policies.json updated with newtab extension")
PYEOF
  fi
  ok "New tab extension installed"
else
  warn "zerotrust-newtab.xpi not found — skipping"
fi

# ════════════════════════════════════════════════════════════
# 7. CUSTOM ICON
# ════════════════════════════════════════════════════════════
section "Custom icon"

ICON_DIR="$SCRIPT_DIR/icons"
if [[ -d "$ICON_DIR" ]]; then
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
# 8. DESKTOP SHORTCUT
# ════════════════════════════════════════════════════════════
section "Desktop shortcut"

DESKTOP_SRC="$SCRIPT_DIR/zerotrust-browser.desktop"
[[ -f "$DESKTOP_SRC" ]] || err "zerotrust-browser.desktop not found"

DESKTOP_LOCAL="$HOME/.local/share/applications/zerotrust-browser.desktop"
cp "$DESKTOP_SRC" "$DESKTOP_LOCAL" && chmod +x "$DESKTOP_LOCAL"

if [[ -d "$HOME/Desktop" ]]; then
  cp "$DESKTOP_SRC" "$HOME/Desktop/zerotrust-browser.desktop"
  chmod +x "$HOME/Desktop/zerotrust-browser.desktop"
  ok "Desktop icon created"
fi

sudo cp "$DESKTOP_SRC" /usr/share/applications/zerotrust-browser.desktop 2>/dev/null && \
  sudo update-desktop-database /usr/share/applications/ 2>/dev/null && \
  ok "System app entry registered" || \
  warn "Could not register system-wide — local entry still works"

# ════════════════════════════════════════════════════════════
# 9. SET AS DEFAULT BROWSER
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
# 10. PIN TO GNOME DOCK
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
echo "  · policies.json     → uBlock Origin + ZeroTrust ext (auto-installs)"
echo "  · user.js           → Privacy & performance prefs"
echo "  · userChrome.css    → Clean light UI theme"
echo "  · New tab extension → ZeroTrust homepage on every new tab"
echo "  · Custom icon       → ZeroTrust shield"
echo "  · Desktop shortcut  → ZeroTrust Browser"
echo "  · Default browser   → Set system-wide"
echo "  · Dock              → Pinned"
echo ""
echo "  Restart Firefox to apply all changes."
echo "  Extensions install automatically on first launch (needs internet)."
echo ""
