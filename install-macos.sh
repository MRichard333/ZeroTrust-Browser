#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser — macOS Setup Script
#  Supports: macOS 12 Monterey and later
#  Run with: chmod +x install-macos.sh && sudo ./install-macos.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Always use the real user even when called via sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(dscl . -read /Users/"$REAL_USER" NFSHomeDirectory | awk '{print $2}')

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
err()     { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}──── $1 ────${NC}"; }

echo ""
echo "  ZeroTrust Browser Setup — macOS"
echo "  ────────────────────────────────"
echo "  Real user: $REAL_USER → $REAL_HOME"
echo ""

# ════════════════════════════════════════════════════════════
# 1. DETECT / INSTALL FIREFOX
# ════════════════════════════════════════════════════════════
section "Firefox"

FIREFOX_APP="/Applications/Firefox.app"
FIREFOX_BIN="$FIREFOX_APP/Contents/MacOS/firefox"

if [[ ! -f "$FIREFOX_BIN" ]]; then
    warn "Firefox not found. Downloading..."
    DMG="/tmp/firefox.dmg"
    curl -fsSL "https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US" -o "$DMG"
    hdiutil attach "$DMG" -quiet -nobrowse -mountpoint /Volumes/Firefox
    cp -R "/Volumes/Firefox/Firefox.app" /Applications/
    hdiutil detach /Volumes/Firefox -quiet
    rm -f "$DMG"
    ok "Firefox installed"
else
    ok "Firefox found: $("$FIREFOX_BIN" --version 2>/dev/null | head -1)"
fi

# ════════════════════════════════════════════════════════════
# 2. DOWNLOAD EXTENSIONS LOCALLY
# ════════════════════════════════════════════════════════════
section "Caching extensions locally"

EXT_CACHE="$SCRIPT_DIR/ext-cache"
mkdir -p "$EXT_CACHE"

dl() {
  local label="$1" url="$2" dest="$3"
  if [[ -f "$dest" ]]; then ok "$label — already cached"; return; fi
  echo -n "  Downloading $label... "
  if curl -fsSL --connect-timeout 15 --retry 2 "$url" -o "$dest" 2>/dev/null; then
    echo -e "${GREEN}done${NC} ($(du -sh "$dest" | cut -f1))"
  else
    warn "$label — download failed, will use AMO on first launch"
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
#    macOS: /Applications/Firefox.app/Contents/Resources/distribution/
# ════════════════════════════════════════════════════════════
section "Enterprise policies"

[[ -f "$SCRIPT_DIR/policies.json" ]] || err "policies.json not found in $SCRIPT_DIR"

POLICIES_DIR="$FIREFOX_APP/Contents/Resources/distribution"
mkdir -p "$POLICIES_DIR"
cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR/policies.json"
ok "policies.json → $POLICIES_DIR"

# Patch extension URLs to local file:// paths
if command -v python3 &>/dev/null && [[ -f "$SCRIPT_DIR/patch_policies.py" ]]; then
    python3 "$SCRIPT_DIR/patch_policies.py" \
        "$POLICIES_DIR/policies.json" \
        "$EXT_CACHE" \
        "$SCRIPT_DIR" \
        && ok "Extension URLs patched to local file:// paths" \
        || warn "patch_policies.py failed — extensions will install via AMO"
fi

# ════════════════════════════════════════════════════════════
# 4. FIND FIREFOX PROFILE
# ════════════════════════════════════════════════════════════
section "Firefox profile"

FIREFOX_DIR="$REAL_HOME/Library/Application Support/Firefox"
PROFILES_INI="$FIREFOX_DIR/profiles.ini"

if [[ ! -d "$FIREFOX_DIR" ]]; then
    warn "No profile found. Creating via headless launch..."
    sudo -u "$REAL_USER" "$FIREFOX_BIN" --headless --no-remote &>/dev/null &
    FFPID=$!; sleep 6; kill "$FFPID" 2>/dev/null || true; wait "$FFPID" 2>/dev/null || true
    ok "Profile created"
fi

PROFILE_PATH=""

if [[ -f "$PROFILES_INI" ]]; then
    DEFAULT=$(awk '/^\[Install/{i=1} i&&/^Default=/{print substr($0,9);i=0}' "$PROFILES_INI")
    [[ -n "$DEFAULT" ]] && {
        [[ "$DEFAULT" == /* ]] && PROFILE_PATH="$DEFAULT" || PROFILE_PATH="$FIREFOX_DIR/$DEFAULT"
    }
    if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
        FALLBACK=$(awk '/^\[Profile/{i=1;p="";r=1;d=0} i&&/^Path=/{p=substr($0,6)} i&&/^IsRelative=0/{r=0} i&&/^Default=1/{d=1} i&&/^$/{if(d&&p!="")print(r?"REL:":"ABS:")p;i=0}' "$PROFILES_INI")
        [[ -n "$FALLBACK" ]] && {
            [[ "$FALLBACK" == REL:* ]] && PROFILE_PATH="$FIREFOX_DIR/${FALLBACK#REL:}" || PROFILE_PATH="${FALLBACK#ABS:}"
        }
    fi
fi

if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
    mapfile -t DIRS < <(find "$FIREFOX_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
    [[ ${#DIRS[@]} -eq 0 ]] && err "No profiles found in $FIREFOX_DIR"
    PROFILE_PATH="${DIRS[0]}"
    warn "Auto-detect failed. Using: $PROFILE_PATH"
fi

ok "Profile: $PROFILE_PATH"

# ════════════════════════════════════════════════════════════
# 5. user.js
# ════════════════════════════════════════════════════════════
section "user.js"

[[ -f "$SCRIPT_DIR/user.js" ]] || err "user.js not found"
DEST_JS="$PROFILE_PATH/user.js"
[[ -f "$DEST_JS" ]] && cp "$DEST_JS" "$DEST_JS.bak.$(date +%Y%m%d%H%M%S)" && warn "Backed up existing user.js"
cp "$SCRIPT_DIR/user.js" "$DEST_JS"
chown "$REAL_USER" "$DEST_JS"
ok "user.js installed"

# ════════════════════════════════════════════════════════════
# 6. userChrome.css
# ════════════════════════════════════════════════════════════
section "userChrome.css"

[[ -f "$SCRIPT_DIR/userChrome.css" ]] || err "userChrome.css not found"
mkdir -p "$PROFILE_PATH/chrome"
cp "$SCRIPT_DIR/userChrome.css" "$PROFILE_PATH/chrome/userChrome.css"
chown -R "$REAL_USER" "$PROFILE_PATH/chrome"
ok "userChrome.css installed"

# ════════════════════════════════════════════════════════════
# 7. STAGE EXTENSIONS
# ════════════════════════════════════════════════════════════
section "Staging extensions"

EXT_DIR="$PROFILE_PATH/extensions"
mkdir -p "$EXT_DIR"

stage() {
  local id="$1" src="$2" label="$3"
  [[ -f "$src" ]] && cp "$src" "$EXT_DIR/${id}.xpi" && ok "$label staged" \
    || warn "$label — not cached, installs via AMO on first launch"
}

stage "zerotrust@mrichard333.com"              "$EXT_CACHE/zerotrust.xpi"  "ZeroTrust Extension"
stage "uBlock0@raymondhill.net"                "$EXT_CACHE/ublock.xpi"     "uBlock Origin"
stage "{446900e4-71c2-419f-a6a7-df9c091e268b}" "$EXT_CACHE/bitwarden.xpi"  "Bitwarden"
stage "@testpilot-containers"                  "$EXT_CACHE/containers.xpi" "Multi-Account Containers"
stage "{74145f27-f039-47ce-a470-a662b129930a}" "$EXT_CACHE/clearurls.xpi"  "ClearURLs"
stage "{b86e4813-687a-43e6-ab65-0bde4ab75758}" "$EXT_CACHE/localcdn.xpi"   "LocalCDN"

chown -R "$REAL_USER" "$EXT_DIR"

# ════════════════════════════════════════════════════════════
# 8. SET DEFAULT BROWSER
# ════════════════════════════════════════════════════════════
section "Default browser"

# macOS requires user interaction to set default browser
sudo -u "$REAL_USER" open "x-apple.systempreferences:com.apple.preference.general" 2>/dev/null || true
warn "macOS requires you to set the default browser manually."
warn "System Preferences → General → Default web browser → Firefox"

# ════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════
echo ""
echo "  ────────────────────────────────"
echo -e "  ${GREEN}ZeroTrust Browser setup complete!${NC}"
echo ""
echo "  · policies.json  → $POLICIES_DIR"
echo "  · user.js        → $PROFILE_PATH"
echo "  · extensions/    → $EXT_DIR"
echo ""
echo "  ⚠  NEXT STEPS:"
echo "     1. Fully quit Firefox (Cmd+Q)"
echo "     2. Relaunch Firefox"
echo "     3. Check about:policies  (should show Active)"
echo "     4. Check about:addons    (extensions should appear)"
echo ""
