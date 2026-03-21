#!/usr/bin/env bash

# ============================================================
# ZeroTrust Browser — Full Setup Script
# For Mountain OS (Ubuntu base), Ubuntu, Debian
# Run with: sudo ./install.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="2.2.0"

# Always resolve the real user even when called via sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
FIREFOX_DIR="$REAL_HOME/.mozilla/firefox"
SNAP_FIREFOX_DIR="$REAL_HOME/snap/firefox/common/.mozilla/firefox"
FLATPAK_FIREFOX_DIR="$REAL_HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"

# Extension IDs
ZEROTRUST_ID="zerotrust@mrichard333.com"
UBLOCK_ID="uBlock0@raymondhill.net"
BITWARDEN_ID="{446900e4-71c2-419f-a6a7-df9c091e268b}"
CONTAINERS_ID="@testpilot-containers"
CLEARURLS_ID="{74145f27-f039-47ce-a470-a662b129930a}"
LOCALCDN_ID="{b86e4813-687a-43e6-ab65-0bde4ab75758}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
err()     { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info()    { echo -e "    $1"; }
section() { echo -e "\n${CYAN}──── $1 ────${NC}"; }

echo ""
echo -e " ${BOLD}ZeroTrust Browser v${VERSION} — Installer${NC}"
echo " ─────────────────────────────────────────"
echo " Real user : $REAL_USER"
echo " Home      : $REAL_HOME"
echo ""

# ════════════════════════════════════════════════════════════
# IDEMPOTENCY CHECK
# ════════════════════════════════════════════════════════════
INSTALL_FLAG="$REAL_HOME/.config/zerotrust-browser/.installed"
if [[ -f "$INSTALL_FLAG" ]]; then
  PREV_VER=$(cat "$INSTALL_FLAG" 2>/dev/null || echo "unknown")
  warn "ZeroTrust Browser was already installed (v${PREV_VER})."
  read -rp "    Re-run to update/repair? [y/N]: " CONFIRM
  [[ "${CONFIRM,,}" == "y" ]] || { echo " Exiting."; exit 0; }
fi

# ════════════════════════════════════════════════════════════
# 1. DNS PROVIDER SELECTION
# ════════════════════════════════════════════════════════════
section "DNS-over-HTTPS Provider"
echo "  Choose your DoH provider:"
echo "  [1] Cloudflare    (1.1.1.1)         — fastest, US-based"
echo "  [2] Quad9         (9.9.9.9)          — non-profit, Switzerland, blocks malware"
echo "  [3] Mullvad DNS                      — no-log, Sweden, privacy-focused"
echo "  [4] NextDNS                          — configurable filtering"
read -rp "  Enter choice [2]: " DNS_CHOICE
case "${DNS_CHOICE:-2}" in
  1) DOH_URL="https://cloudflare-dns.com/dns-query" ; DOH_LABEL="Cloudflare" ;;
  3) DOH_URL="https://base.dns.mullvad.net/dns-query" ; DOH_LABEL="Mullvad" ;;
  4) DOH_URL="https://dns.nextdns.io" ; DOH_LABEL="NextDNS" ;;
  *) DOH_URL="https://dns.quad9.net/dns-query" ; DOH_LABEL="Quad9 (recommended)" ;;
esac
ok "Using DoH provider: $DOH_LABEL"

# ════════════════════════════════════════════════════════════
# 2. DETECT FIREFOX (standard, ESR, Snap, Flatpak)
# ════════════════════════════════════════════════════════════
section "Detecting Firefox"

IS_SNAP=false
IS_FLATPAK=false
FIREFOX_BIN=""

if sudo -u "$REAL_USER" snap list firefox &>/dev/null 2>&1; then
  IS_SNAP=true
  FIREFOX_DIR="$SNAP_FIREFOX_DIR"
  FIREFOX_BIN="/snap/bin/firefox"
  ok "Snap Firefox detected"
elif flatpak info org.mozilla.firefox &>/dev/null 2>&1; then
  IS_FLATPAK=true
  FIREFOX_DIR="$FLATPAK_FIREFOX_DIR"
  FIREFOX_BIN="flatpak run org.mozilla.firefox"
  ok "Flatpak Firefox detected"
elif command -v firefox-esr &>/dev/null; then
  FIREFOX_BIN=$(command -v firefox-esr)
  ok "Firefox ESR found: $("$FIREFOX_BIN" --version 2>/dev/null | head -1)"
elif command -v firefox &>/dev/null; then
  FIREFOX_BIN=$(command -v firefox)
  ok "Firefox found: $("$FIREFOX_BIN" --version 2>/dev/null | head -1)"
else
  warn "Firefox not found — installing Firefox ESR..."
  apt-get update -qq && apt-get install -y firefox-esr
  FIREFOX_BIN=$(command -v firefox-esr)
  ok "Firefox ESR installed"
fi

# ════════════════════════════════════════════════════════════
# 3. CACHE EXTENSIONS LOCALLY
# ════════════════════════════════════════════════════════════
section "Caching extensions locally"

EXT_CACHE="$SCRIPT_DIR/ext-cache"
mkdir -p "$EXT_CACHE"

# Download + verify SHA256 if a known hash is provided (pass "" to skip verification)
dl_verified() {
  local label="$1" url="$2" dest="$3" expected_sha="${4:-}"

  if [[ -f "$dest" ]]; then
    ok "$label — already cached"
    return
  fi

  echo -n "    Downloading $label... "
  if curl -fsSL --connect-timeout 15 --retry 2 "$url" -o "$dest" 2>/dev/null; then
    echo -e "${GREEN}done${NC} ($(du -sh "$dest" | cut -f1))"
    # Verify SHA256 if a hash was provided
    if [[ -n "$expected_sha" ]]; then
      actual_sha=$(sha256sum "$dest" | awk '{print $1}')
      if [[ "$actual_sha" == "$expected_sha" ]]; then
        ok "$label — SHA256 verified"
      else
        rm -f "$dest"
        warn "$label — SHA256 MISMATCH. File removed. Will install via AMO on first launch."
        warn "  Expected: $expected_sha"
        warn "  Got:      $actual_sha"
      fi
    else
      warn "$label — no pinned hash; skipping verification (latest from AMO)"
    fi
  else
    warn "$label — download failed, will install via AMO on first launch"
    rm -f "$dest"
  fi
}

# ZeroTrust extension is pinned to a specific version (hash can be updated per release)
dl_verified "ZeroTrust Extension" \
  "https://addons.mozilla.org/firefox/downloads/file/4730187/zerotrust_dashboard_extension-2.1.0.xpi" \
  "$EXT_CACHE/zerotrust.xpi" \
  ""   # <-- add SHA256 here once published

# AMO "latest" downloads — no stable hash, skip verification
dl_verified "uBlock Origin"          "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"                "$EXT_CACHE/ublock.xpi"    ""
dl_verified "Bitwarden"              "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"   "$EXT_CACHE/bitwarden.xpi" ""
dl_verified "Multi-Account Containers" "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi"  "$EXT_CACHE/containers.xpi" ""
dl_verified "ClearURLs"             "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi"                    "$EXT_CACHE/clearurls.xpi" ""
dl_verified "LocalCDN"              "https://addons.mozilla.org/firefox/downloads/latest/localcdn-fork-of-decentraleyes/latest.xpi" "$EXT_CACHE/localcdn.xpi" ""

# ════════════════════════════════════════════════════════════
# 4. ENTERPRISE POLICIES
# ════════════════════════════════════════════════════════════
section "Enterprise policies"

[[ -f "$SCRIPT_DIR/policies.json" ]] || err "policies.json not found in $SCRIPT_DIR"

# Determine policy destination
if [[ "$IS_SNAP" == true ]]; then
  POLICIES_DIR="/var/snap/firefox/common/policies"
  POLICIES_DIR_USER="$REAL_HOME/snap/firefox/common/policies"
  mkdir -p "$POLICIES_DIR" "$POLICIES_DIR_USER"
elif [[ "$IS_FLATPAK" == true ]]; then
  POLICIES_DIR="$REAL_HOME/.var/app/org.mozilla.firefox/distribution"
  mkdir -p "$POLICIES_DIR"
else
  POLICIES_DIR="/usr/lib/firefox/distribution"
  [[ -d "/usr/lib/firefox-esr/distribution" ]] && POLICIES_DIR="/usr/lib/firefox-esr/distribution"
  mkdir -p "$POLICIES_DIR"
fi

cp "$SCRIPT_DIR/policies.json" "$POLICIES_DIR/policies.json"
ok "policies.json → $POLICIES_DIR"

# Patch: inject local file:// paths + selected DoH URL
python3 - "$POLICIES_DIR/policies.json" "$EXT_CACHE" "$DOH_URL" <<'PYEOF'
import json, os, sys

pol_path  = sys.argv[1]
cache_dir = sys.argv[2]
doh_url   = sys.argv[3]

ID_TO_FILE = {
    "zerotrust@mrichard333.com":              "zerotrust.xpi",
    "uBlock0@raymondhill.net":                "ublock.xpi",
    "{446900e4-71c2-419f-a6a7-df9c091e268b}": "bitwarden.xpi",
    "@testpilot-containers":                  "containers.xpi",
    "{74145f27-f039-47ce-a470-a662b129930a}": "clearurls.xpi",
    "{b86e4813-687a-43e6-ab65-0bde4ab75758}": "localcdn.xpi",
}

with open(pol_path) as f:
    pol = json.load(f)

# Patch extension URLs
ext = pol.get("policies", {}).get("ExtensionSettings", {})
for ext_id, filename in ID_TO_FILE.items():
    if ext_id not in ext:
        continue
    xpi = os.path.join(cache_dir, filename)
    if os.path.isfile(xpi):
        ext[ext_id]["install_url"] = "file://" + os.path.abspath(xpi)
        print(f"  [patched] {ext_id[:46]:<46} -> {filename}")

# Patch DoH URL
if "DNSOverHTTPS" in pol.get("policies", {}):
    pol["policies"]["DNSOverHTTPS"]["ProviderURL"] = doh_url
    print(f"  [patched] DNSOverHTTPS -> {doh_url}")

with open(pol_path, "w") as f:
    json.dump(pol, f, indent=2)

PYEOF

ok "Policies patched (DoH + extension URLs)"

# Sync to Snap user copy if needed
if [[ "$IS_SNAP" == true ]]; then
  cp "$POLICIES_DIR/policies.json" "$POLICIES_DIR_USER/policies.json"
fi

# ════════════════════════════════════════════════════════════
# 5. FIREFOX PROFILE — create if missing
# ════════════════════════════════════════════════════════════
section "Firefox profile"

if [[ ! -d "$FIREFOX_DIR" ]]; then
  warn "No profile directory found — creating via headless launch as $REAL_USER..."
  sudo -u "$REAL_USER" $FIREFOX_BIN --headless --no-remote &>/dev/null &
  FFPID=$!
  sleep 6
  kill "$FFPID" 2>/dev/null || true
  wait "$FFPID" 2>/dev/null || true
  ok "Profile directory created"
fi

# Resolve active profile path
PROFILES_INI="$FIREFOX_DIR/profiles.ini"
PROFILE_PATH=""

if [[ -f "$PROFILES_INI" ]]; then
  DEFAULT=$(awk '/^\[Install/{i=1} i&&/^Default=/{print substr($0,9);i=0}' "$PROFILES_INI")
  if [[ -n "$DEFAULT" ]]; then
    [[ "$DEFAULT" == /* ]] && PROFILE_PATH="$DEFAULT" || PROFILE_PATH="$FIREFOX_DIR/$DEFAULT"
  fi

  if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
    FALLBACK=$(awk '/^\[Profile/{i=1;p="";r=1;d=0} i&&/^Path=/{p=substr($0,6)} i&&/^IsRelative=0/{r=0} i&&/^Default=1/{d=1} i&&/^$/{if(d&&p!="")print(r?"REL:":"ABS:")p;i=0}' "$PROFILES_INI")
    [[ -n "$FALLBACK" ]] && {
      [[ "$FALLBACK" == REL:* ]] \
        && PROFILE_PATH="$FIREFOX_DIR/${FALLBACK#REL:}" \
        || PROFILE_PATH="${FALLBACK#ABS:}"
    }
  fi
fi

if [[ -z "$PROFILE_PATH" || ! -d "$PROFILE_PATH" ]]; then
  mapfile -t DIRS < <(find "$FIREFOX_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
  [[ ${#DIRS[@]} -eq 0 ]] && err "No profiles found in $FIREFOX_DIR"
  echo "  Multiple profiles found — select the correct one:"
  for i in "${!DIRS[@]}"; do echo "    [$i] ${DIRS[$i]}"; done
  read -rp "  Enter number [0]: " CHOICE
  PROFILE_PATH="${DIRS[${CHOICE:-0}]}"
fi

[[ -d "$PROFILE_PATH" ]] || err "Profile not found: $PROFILE_PATH"
ok "Profile: $PROFILE_PATH"

# ════════════════════════════════════════════════════════════
# 6. user.js
# ════════════════════════════════════════════════════════════
section "user.js"

[[ -f "$SCRIPT_DIR/user.js" ]] || err "user.js not found"
DEST_JS="$PROFILE_PATH/user.js"

if [[ -f "$DEST_JS" ]]; then
  BACKUP="$DEST_JS.bak.$(date +%Y%m%d%H%M%S)"
  cp "$DEST_JS" "$BACKUP"
  warn "Backed up existing user.js → $BACKUP"
fi

cp "$SCRIPT_DIR/user.js" "$DEST_JS"
chown "$REAL_USER":"$REAL_USER" "$DEST_JS"
ok "user.js installed"

# ════════════════════════════════════════════════════════════
# 7. userChrome.css
# ════════════════════════════════════════════════════════════
section "userChrome.css"

[[ -f "$SCRIPT_DIR/userChrome.css" ]] || err "userChrome.css not found"
mkdir -p "$PROFILE_PATH/chrome"
cp "$SCRIPT_DIR/userChrome.css" "$PROFILE_PATH/chrome/userChrome.css"
chown -R "$REAL_USER":"$REAL_USER" "$PROFILE_PATH/chrome"
ok "userChrome.css installed"

# ════════════════════════════════════════════════════════════
# 8. STAGE EXTENSIONS IN PROFILE
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
    warn "$label — not cached, installs via AMO on first launch"
  fi
}

stage "$ZEROTRUST_ID"  "$EXT_CACHE/zerotrust.xpi"   "ZeroTrust Extension"
stage "$UBLOCK_ID"     "$EXT_CACHE/ublock.xpi"       "uBlock Origin"
stage "$BITWARDEN_ID"  "$EXT_CACHE/bitwarden.xpi"    "Bitwarden"
stage "$CONTAINERS_ID" "$EXT_CACHE/containers.xpi"   "Multi-Account Containers"
stage "$CLEARURLS_ID"  "$EXT_CACHE/clearurls.xpi"    "ClearURLs"
stage "$LOCALCDN_ID"   "$EXT_CACHE/localcdn.xpi"     "LocalCDN"

chown -R "$REAL_USER":"$REAL_USER" "$EXT_DIR"

# ════════════════════════════════════════════════════════════
# 9. CUSTOM ICON
# ════════════════════════════════════════════════════════════
section "Custom icon"

ICON_DIR="$SCRIPT_DIR/icons"
if [[ -d "$ICON_DIR" ]]; then
  [[ -f "$ICON_DIR/zerotrust_256.png" ]] && cp "$ICON_DIR/zerotrust_256.png" /usr/share/icons/zerotrust-browser.png
  for SIZE in 16 32 48 64 128 256; do
    [[ -f "$ICON_DIR/zerotrust_${SIZE}.png" ]] && {
      mkdir -p "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
      cp "$ICON_DIR/zerotrust_${SIZE}.png" "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/zerotrust-browser.png"
    }
  done
  gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true
  ok "Custom icons installed"
else
  warn "icons/ folder not found — using default Firefox icon"
fi

# ════════════════════════════════════════════════════════════
# 10. DESKTOP SHORTCUT
# ════════════════════════════════════════════════════════════
section "Desktop shortcut"

[[ -f "$SCRIPT_DIR/zerotrust-browser.desktop" ]] || err "zerotrust-browser.desktop not found"
APPS_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$APPS_DIR"

cp "$SCRIPT_DIR/zerotrust-browser.desktop" "$APPS_DIR/zerotrust-browser.desktop"
chmod +x "$APPS_DIR/zerotrust-browser.desktop"
chown "$REAL_USER":"$REAL_USER" "$APPS_DIR/zerotrust-browser.desktop"

[[ -d "$REAL_HOME/Desktop" ]] && {
  cp "$SCRIPT_DIR/zerotrust-browser.desktop" "$REAL_HOME/Desktop/zerotrust-browser.desktop"
  chmod +x "$REAL_HOME/Desktop/zerotrust-browser.desktop"
  chown "$REAL_USER":"$REAL_USER" "$REAL_HOME/Desktop/zerotrust-browser.desktop"
  ok "Desktop shortcut created"
}

cp "$SCRIPT_DIR/zerotrust-browser.desktop" /usr/share/applications/ 2>/dev/null \
  && update-desktop-database /usr/share/applications/ 2>/dev/null \
  && ok "System app entry registered" \
  || warn "Could not register system-wide app entry"

# ════════════════════════════════════════════════════════════
# 11. DEFAULT BROWSER
# ════════════════════════════════════════════════════════════
section "Default browser"

command -v xdg-settings &>/dev/null \
  && sudo -u "$REAL_USER" xdg-settings set default-web-browser zerotrust-browser.desktop 2>/dev/null \
  && ok "Default browser set" \
  || warn "Set default browser manually in System Settings"

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
    sudo -u "$REAL_USER" gsettings set org.gnome.shell favorite-apps "$NEW" 2>/dev/null \
      && ok "Pinned to GNOME dock" \
      || warn "Pin manually by right-clicking the app in Activities"
  fi
else
  warn "gsettings not available — pin manually"
fi

# ════════════════════════════════════════════════════════════
# MARK AS INSTALLED
# ════════════════════════════════════════════════════════════
mkdir -p "$(dirname "$INSTALL_FLAG")"
echo "$VERSION" > "$INSTALL_FLAG"
chown -R "$REAL_USER":"$REAL_USER" "$(dirname "$INSTALL_FLAG")"

# ════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════
echo ""
echo " ─────────────────────────────────────────"
echo -e " ${GREEN}${BOLD}ZeroTrust Browser v${VERSION} setup complete!${NC}"
echo ""
echo "  DoH Provider  → $DOH_LABEL"
echo "  policies.json → $POLICIES_DIR"
echo "  user.js       → $PROFILE_PATH"
echo "  extensions/   → $EXT_DIR"
echo ""
echo "  ⚠  Fully QUIT Firefox (File → Quit) then relaunch."
echo "  ✓  Verify at about:policies — all policies should show Active"
echo "  ✓  Verify at about:addons  — ZeroTrust and uBlock pinned to toolbar"
echo ""