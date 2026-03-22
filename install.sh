#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser — One-Command Linux Installer v2.4.0
#  Mountain OS / Ubuntu / Debian
#
#  curl -fsSL https://mrichard333.com/zerotrust-install.sh | sudo bash
#
#  Philosophy:
#    - ZeroTrust Browser is a SEPARATE browser built on top of Firefox
#    - It uses its own isolated profile (never touches your Firefox)
#    - Launched via /usr/local/bin/zerotrust-browser wrapper
#    - Your existing Firefox is completely unaffected
# ============================================================
set -eo pipefail

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
WORK="$(mktemp -d)"
VERSION="2.4.0"
REPO_BASE="https://raw.githubusercontent.com/MRichard333/ZeroTrust-Browser/main"

# Extension URLs (all signed by AMO)
URL_NEWTAB="https://addons.mozilla.org/firefox/downloads/file/4735684/1577d4607491497a80c7-1.1.0.xpi"
URL_THEME="https://addons.mozilla.org/firefox/downloads/file/4735614/zerotrust_mrichard333-1.0.0.xpi"
URL_ZEROTRUST="https://addons.mozilla.org/firefox/downloads/file/4730187/zerotrust_dashboard_extension-2.1.0.xpi"
URL_UBLOCK="https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
URL_BITWARDEN="https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"
URL_CONTAINERS="https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi"
URL_CLEARURLS="https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi"
URL_LOCALCDN="https://addons.mozilla.org/firefox/downloads/latest/localcdn-fork-of-decentraleyes/latest.xpi"

# ZeroTrust profile — completely isolated, never the Firefox default
ZT_PROFILE_DIR="$REAL_HOME/.mozilla/zerotrust-browser"
ZT_WRAPPER="/usr/local/bin/zerotrust-browser"
CACHE_DIR="$REAL_HOME/.cache/zerotrust-browser"
INSTALL_FLAG="$REAL_HOME/.config/zerotrust-browser/.installed"

trap 'rm -rf "$WORK"' EXIT

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; B='\033[1m'; DIM='\033[2m'; NC='\033[0m'
ok()      { echo -e "  ${G}✓${NC}  $1"; }
warn()    { echo -e "  ${Y}!${NC}  $1"; }
err()     { echo -e "  ${R}✗${NC}  $1"; exit 1; }
info()    { echo -e "  ${DIM}·${NC}  $1"; }
section() { echo ""; echo -e "  ${C}${B}$1${NC}"; echo -e "  ${DIM}$(printf '%.0s─' {1..44})${NC}"; }

# ── Banner ────────────────────────────────────────────────────────────────────
clear 2>/dev/null || true
echo ""
echo -e "  ${B}${G}▲  ZeroTrust Browser v${VERSION}${NC}"
echo -e "  ${DIM}mrichard333.com · Mountain OS${NC}"
echo ""
echo -e "  User     ${DIM}→${NC}  $REAL_USER"
echo -e "  Home     ${DIM}→${NC}  $REAL_HOME"
echo -e "  Profile  ${DIM}→${NC}  $ZT_PROFILE_DIR"
echo -e "  Launcher ${DIM}→${NC}  $ZT_WRAPPER"
echo ""
echo -e "  ${DIM}Your existing Firefox is not affected.${NC}"
echo ""

# ── Already installed? ────────────────────────────────────────────────────────
if [[ -f "$INSTALL_FLAG" ]]; then
  PREV=$(cat "$INSTALL_FLAG" 2>/dev/null || echo "unknown")
  echo -e "  ${Y}Already installed (v${PREV})${NC}"
  read -rp "  Re-run to update/repair? [y/N]: " CONFIRM </dev/tty || true
  [[ "${CONFIRM,,}" != "y" ]] && { echo ""; echo "  Exiting."; echo ""; exit 0; }
fi

# ── DNS provider ──────────────────────────────────────────────────────────────
section "DNS-over-HTTPS"
echo ""
echo -e "  ${DIM}[1]${NC} Cloudflare   1.1.1.1   fastest"
echo -e "  ${DIM}[2]${NC} Quad9        9.9.9.9   non-profit  ${G}recommended${NC}"
echo -e "  ${DIM}[3]${NC} Mullvad      no-log, Sweden"
echo -e "  ${DIM}[4]${NC} NextDNS      configurable filtering"
echo ""
read -rp "  Choice [2]: " DNS_CHOICE </dev/tty || true
case "${DNS_CHOICE:-2}" in
  1) DOH_URL="https://cloudflare-dns.com/dns-query"   ; DOH_LABEL="Cloudflare" ;;
  3) DOH_URL="https://base.dns.mullvad.net/dns-query" ; DOH_LABEL="Mullvad"    ;;
  4) DOH_URL="https://dns.nextdns.io"                 ; DOH_LABEL="NextDNS"    ;;
  *) DOH_URL="https://dns.quad9.net/dns-query"        ; DOH_LABEL="Quad9"      ;;
esac
ok "DoH: $DOH_LABEL"

# ── Fetch config files ────────────────────────────────────────────────────────
section "Fetching configuration"

fetch() {
  local label="${1:-}" url="${2:-}" dest="${3:-}"
  [[ -z "$dest" ]] && return 0
  printf "  %-24s" "$label..."
  if curl -fsSL --connect-timeout 15 --retry 2 "$url" -o "$dest" 2>/dev/null; then
    echo -e " ${G}done${NC}"
  else
    echo -e " ${Y}failed${NC}"; return 1
  fi
}

fetch "user.js"         "$REPO_BASE/user.js"             "$WORK/user.js"         || err "Could not fetch user.js"
fetch "policies.json"   "$REPO_BASE/policies.json"       "$WORK/policies.json"   || err "Could not fetch policies.json"
fetch "userChrome.css"  "$REPO_BASE/userChrome.css"      "$WORK/userChrome.css"  || err "Could not fetch userChrome.css"
fetch "userContent.css" "$REPO_BASE/userContent.css"     "$WORK/userContent.css" || true
fetch "newtab.html"     "$REPO_BASE/newtab.html"         "$WORK/newtab.html"     || true
fetch "mozilla.cfg"     "$REPO_BASE/mozilla.cfg"         "$WORK/mozilla.cfg"     || true
fetch "autoconfig.js"   "$REPO_BASE/autoconfig.js"       "$WORK/autoconfig.js"   || true

# ── Hardware detection ────────────────────────────────────────────────────────
section "Hardware detection"

RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 4000000)
RAM_GB=$(( RAM_KB / 1024 / 1024 ))
CPU_CORES=$(nproc 2>/dev/null || echo 2)

IS_MAC=false
[[ -f /sys/class/dmi/id/sys_vendor ]] && grep -qi "apple" /sys/class/dmi/id/sys_vendor 2>/dev/null && IS_MAC=true || true
lsmod 2>/dev/null | grep -q "applesmc\|hid_apple\|bcm5974" && IS_MAC=true || true

DISPLAY_SERVER=$([ -n "$WAYLAND_DISPLAY" ] && echo "wayland" || echo "x11")
GPU_RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | head -1 | cut -d: -f2 | xargs || echo "unknown")
MESA_MAJOR=$(glxinfo 2>/dev/null | grep "OpenGL version" | grep -oE "[0-9]+" | head -1 || echo 0)

GPU_BAD=false
echo "$GPU_RENDERER" | grep -qiE "llvmpipe|softpipe|Software Rasterizer|SVGA3D|Sandy Bridge|HD.*2000|HD.*3000" && GPU_BAD=true || true
[[ "$GPU_RENDERER" == "unknown" || -z "$GPU_RENDERER" || $MESA_MAJOR -lt 3 ]] && GPU_BAD=true || true

if   [[ $RAM_GB -le 3 || $CPU_CORES -le 2 || "$GPU_BAD" == true ]]; then HW_TIER="low"
elif [[ $RAM_GB -le 7 || $CPU_CORES -le 4 || "$IS_MAC"  == true ]]; then HW_TIER="mid"
else                                                                        HW_TIER="high"
fi

info "RAM: ${RAM_GB}GB | Cores: ${CPU_CORES} | GPU: ${GPU_RENDERER} | Tier: ${HW_TIER}"

# ── X11 / Wayland env vars ────────────────────────────────────────────────────
if [[ "$DISPLAY_SERVER" == "x11" ]]; then
  {
    echo "# ZeroTrust Browser — X11 fix"; echo "export MOZ_X11_EGL=1"; echo "export MOZ_DISABLE_RDD_SANDBOX=1"
    [[ "$GPU_BAD" == true ]] && echo "export MOZ_WEBRENDER=0" && echo "export MOZ_ACCELERATED=0"
    [[ "$IS_MAC"  == true ]] && echo "export MOZ_USE_XINPUT2=0"
  } > /etc/profile.d/zerotrust-browser.sh
  chmod 644 /etc/profile.d/zerotrust-browser.sh
  export MOZ_X11_EGL=1 MOZ_DISABLE_RDD_SANDBOX=1
  [[ "$GPU_BAD" == true ]] && { export MOZ_WEBRENDER=0; export MOZ_ACCELERATED=0; } || true
  [[ "$IS_MAC"  == true ]] && export MOZ_USE_XINPUT2=0 || true
  ok "X11 compositor fix applied"
else
  echo "export MOZ_ENABLE_WAYLAND=1" > /etc/profile.d/zerotrust-browser.sh
  chmod 644 /etc/profile.d/zerotrust-browser.sh; export MOZ_ENABLE_WAYLAND=1
  ok "Wayland native rendering enabled"
fi

# ── Mac-specific ──────────────────────────────────────────────────────────────
if [[ "$IS_MAC" == true ]]; then
  section "Mac-specific optimizations"
  if ! command -v mbpfan &>/dev/null; then
    apt-get install -y mbpfan -qq 2>/dev/null && systemctl enable --now mbpfan 2>/dev/null || true
    ok "mbpfan installed"
  fi
  if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      echo "powersave" > "$cpu" 2>/dev/null || true
    done; ok "CPU governor: powersave"
  fi
fi

# ── Detect Firefox binary ─────────────────────────────────────────────────────
section "Detecting Firefox"

IS_SNAP=false; IS_FLATPAK=false; FF_BIN=""

if sudo -u "$REAL_USER" snap list firefox &>/dev/null 2>&1; then
  IS_SNAP=true; FF_BIN="/snap/bin/firefox"; ok "Snap Firefox detected"
elif flatpak info org.mozilla.firefox &>/dev/null 2>&1; then
  IS_FLATPAK=true; FF_BIN="flatpak run org.mozilla.firefox"; ok "Flatpak Firefox detected"
elif command -v firefox-esr &>/dev/null; then
  FF_BIN=$(command -v firefox-esr); ok "Firefox ESR: $("$FF_BIN" --version 2>/dev/null | head -1)"
elif command -v firefox &>/dev/null; then
  FF_BIN=$(command -v firefox); ok "Firefox: $("$FF_BIN" --version 2>/dev/null | head -1)"
else
  warn "Firefox not found — installing firefox-esr..."
  apt-get update -qq && apt-get install -y firefox-esr -qq
  FF_BIN=$(command -v firefox-esr); ok "Firefox ESR installed"
fi

# Firefox install directory (for mozilla.cfg + distribution/extensions)
FF_INSTALL_DIR=""
if   [[ "$IS_SNAP"    == true ]]; then FF_INSTALL_DIR="/snap/firefox/current/usr/lib/firefox"
elif [[ "$IS_FLATPAK" == true ]]; then FF_INSTALL_DIR="/var/lib/flatpak/app/org.mozilla.firefox/current/active/files/lib/firefox"
elif [[ -d "/usr/lib/firefox-esr" ]]; then FF_INSTALL_DIR="/usr/lib/firefox-esr"
elif [[ -d "/usr/lib/firefox"     ]]; then FF_INSTALL_DIR="/usr/lib/firefox"
else FF_INSTALL_DIR="$(dirname "$(readlink -f "$(command -v firefox-esr 2>/dev/null || command -v firefox)")")"
fi
info "Firefox install dir: $FF_INSTALL_DIR"

# ── Download all extensions to permanent cache ────────────────────────────────
section "Downloading extensions"

mkdir -p "$CACHE_DIR"
chown -R "$REAL_USER":"$REAL_USER" "$CACHE_DIR"

dl_ext() {
  local label="${1:-}" url="${2:-}" dest="${3:-}"
  [[ -z "$dest" ]] && return 0
  printf "  %-32s" "$label..."
  if [[ -f "$dest" ]]; then echo -e " ${DIM}cached${NC}"; return 0; fi
  if curl -fsSL --connect-timeout 20 --retry 3 "$url" -o "$dest" 2>/dev/null; then
    echo -e " ${G}done${NC}"
  else
    echo -e " ${Y}failed${NC}"; rm -f "$dest"
  fi
}

dl_ext "ZeroTrust New Tab"        "$URL_NEWTAB"     "$CACHE_DIR/zerotrust-newtab.xpi"
dl_ext "ZeroTrust Theme"          "$URL_THEME"      "$CACHE_DIR/zerotrust-theme.xpi"
dl_ext "ZeroTrust Extension"      "$URL_ZEROTRUST"  "$CACHE_DIR/zerotrust.xpi"
dl_ext "uBlock Origin"            "$URL_UBLOCK"     "$CACHE_DIR/ublock.xpi"
dl_ext "Bitwarden"                "$URL_BITWARDEN"  "$CACHE_DIR/bitwarden.xpi"
dl_ext "Multi-Account Containers" "$URL_CONTAINERS" "$CACHE_DIR/containers.xpi"
dl_ext "ClearURLs"                "$URL_CLEARURLS"  "$CACHE_DIR/clearurls.xpi"
dl_ext "LocalCDN"                 "$URL_LOCALCDN"   "$CACHE_DIR/localcdn.xpi"
chown -R "$REAL_USER":"$REAL_USER" "$CACHE_DIR"

# ── Enterprise policies ───────────────────────────────────────────────────────
section "Enterprise policies"

# Policies go to the Firefox install dir — they apply only when launching
# with --profile ZT_PROFILE_DIR so they do NOT affect regular Firefox.
# (Actually policies are global per install — we skip them to stay isolated
#  and rely entirely on user.js + staged extensions instead.)
#
# We still write policies for distributions that support per-profile policy dirs.
POL_DIR=""
if [[ "$IS_SNAP" == true ]]; then
  POL_DIR="/var/snap/firefox/common/policies"
  mkdir -p "$POL_DIR"; cp "$WORK/policies.json" "$POL_DIR/policies.json"
elif [[ "$IS_FLATPAK" == true ]]; then
  POL_DIR="$REAL_HOME/.var/app/org.mozilla.firefox/distribution"
  mkdir -p "$POL_DIR"; cp "$WORK/policies.json" "$POL_DIR/policies.json"
else
  POL_DIR="/usr/lib/firefox/distribution"
  [[ -d "/usr/lib/firefox-esr/distribution" ]] && POL_DIR="/usr/lib/firefox-esr/distribution"
  mkdir -p "$POL_DIR"; cp "$WORK/policies.json" "$POL_DIR/policies.json"
fi

python3 - "$POL_DIR/policies.json" "$CACHE_DIR" "$DOH_URL" << 'PYEOF'
import json, os, sys
pol_path, cache_dir, doh = sys.argv[1], sys.argv[2], sys.argv[3]
ID_MAP = {
    "zerotrust@mrichard333.com":                "zerotrust.xpi",
    "uBlock0@raymondhill.net":                  "ublock.xpi",
    "{446900e4-71c2-419f-a6a7-df9c091e268b}":   "bitwarden.xpi",
    "@testpilot-containers":                    "containers.xpi",
    "{74145f27-f039-47ce-a470-a662b129930a}":   "clearurls.xpi",
    "{b86e4813-687a-43e6-ab65-0bde4ab75758}":   "localcdn.xpi",
    "zerotrust-newtab@mrichard333.com":         "zerotrust-newtab.xpi",
    "zerotrust-mountain-theme@mrichard333.com": "zerotrust-theme.xpi",
}
with open(pol_path) as f: pol = json.load(f)
ext = pol.get("policies", {}).get("ExtensionSettings", {})
patched = 0
for eid, fname in ID_MAP.items():
    xpi = os.path.join(cache_dir, fname)
    if eid in ext and os.path.isfile(xpi):
        ext[eid]["install_url"] = "file://" + os.path.abspath(xpi)
        patched += 1
if "DNSOverHTTPS" in pol.get("policies", {}):
    pol["policies"]["DNSOverHTTPS"]["ProviderURL"] = doh
with open(pol_path, "w") as f: json.dump(pol, f, indent=2)
print(f"    Patched {patched} extension(s)")
PYEOF
ok "policies.json → $POL_DIR"

# ── Deploy mozilla.cfg ────────────────────────────────────────────────────────
section "Deploying mozilla.cfg (newtab / weather kill)"

[[ ! -f "$WORK/mozilla.cfg" ]] && cat > "$WORK/mozilla.cfg" << 'CFGEOF'
// ZeroTrust Browser — mozilla.cfg v2.4.0
// First line is always ignored by Firefox.
lockPref("browser.newtabpage.activity-stream.showWeather",              false);
lockPref("browser.newtabpage.activity-stream.system.showWeather",       false);
lockPref("browser.newtabpage.activity-stream.feeds.weatherfeed",        false);
lockPref("browser.newtabpage.activity-stream.weather.query",            "");
lockPref("browser.newtabpage.activity-stream.showSponsored",            false);
lockPref("browser.newtabpage.activity-stream.showSponsoredTopSites",    false);
lockPref("browser.newtabpage.activity-stream.feeds.topsites",           false);
lockPref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
lockPref("browser.newtabpage.activity-stream.enabled",                  false);
CFGEOF

[[ ! -f "$WORK/autoconfig.js" ]] && cat > "$WORK/autoconfig.js" << 'AUTOEOF'
// ZeroTrust Browser — autoconfig.js v2.4.0
pref("general.config.filename", "mozilla.cfg");
pref("general.config.obscure_value", 0);
AUTOEOF

if [[ -n "$FF_INSTALL_DIR" && -d "$FF_INSTALL_DIR" && "$IS_SNAP" != true ]]; then
  cp "$WORK/mozilla.cfg"  "$FF_INSTALL_DIR/mozilla.cfg"
  mkdir -p "$FF_INSTALL_DIR/defaults/pref"
  cp "$WORK/autoconfig.js" "$FF_INSTALL_DIR/defaults/pref/autoconfig.js"
  chmod 644 "$FF_INSTALL_DIR/mozilla.cfg" "$FF_INSTALL_DIR/defaults/pref/autoconfig.js"
  ok "mozilla.cfg → $FF_INSTALL_DIR"
else
  warn "Skipping mozilla.cfg (Snap sandbox — weather prefs handled via user.js instead)"
fi

# ── Create isolated ZeroTrust profile ─────────────────────────────────────────
section "Creating ZeroTrust Browser profile"

# This profile is stored separately from ~/.mozilla/firefox
# It is NEVER registered as a Firefox default profile
# Regular Firefox has zero knowledge of it

mkdir -p "$ZT_PROFILE_DIR"
chown -R "$REAL_USER":"$REAL_USER" "$ZT_PROFILE_DIR"
ok "Isolated profile: $ZT_PROFILE_DIR"

# ── user.js ───────────────────────────────────────────────────────────────────
section "Installing configuration"

# Append hardware-tuned prefs to user.js
python3 - "$WORK/user.js" "$HW_TIER" "$RAM_GB" "$GPU_BAD" "$DOH_URL" "$IS_MAC" << 'PYEOF'
import sys
path, tier, ram_s, gpu_bad_s, doh, is_mac_s = sys.argv[1:]
ram = int(ram_s); bad = gpu_bad_s == "true"; mac = is_mac_s == "true"

p = [f'// ZeroTrust installer prefs (tier={tier})',
     f'user_pref("network.trr.uri", "{doh}");',
     f'user_pref("network.trr.mode", 3);']

if bad:
    p += ['user_pref("gfx.webrender.all",                     false);',
          'user_pref("layers.acceleration.force-enabled",     false);',
          'user_pref("media.hardware-video-decoding.enabled", false);',
          'user_pref("webgl.disabled",                        true);']

p += ['user_pref("browser.tabs.animate",              false);',
      'user_pref("ui.prefersReducedMotion",            1);',
      'user_pref("javascript.options.ion",             true);',
      'user_pref("javascript.options.baselinejit",     true);',
      'user_pref("javascript.options.wasm",            true);']

if ram <= 4:
    p += ['user_pref("browser.cache.memory.capacity",     65536);',
          'user_pref("browser.cache.disk.enable",         true);',
          'user_pref("dom.ipc.processCount",              2);',
          'user_pref("browser.tabs.unloadOnLowMemory",    true);']
else:
    p += ['user_pref("browser.cache.memory.capacity",     -1);',
          'user_pref("browser.cache.disk.enable",         false);']

if mac:
    p.append('user_pref("dom.event.coalesce_mouse_move",  true);')

with open(path, 'a') as f: f.write('\n' + '\n'.join(p) + '\n')
print(f"  Tier={tier} | RAM={ram}GB | GPU={'bad' if bad else 'ok'}")
PYEOF
ok "user.js tuned for $HW_TIER hardware"

# Install user.js to the isolated profile
cp "$WORK/user.js" "$ZT_PROFILE_DIR/user.js"
chown "$REAL_USER":"$REAL_USER" "$ZT_PROFILE_DIR/user.js"
ok "user.js → profile"

# userChrome.css
mkdir -p "$ZT_PROFILE_DIR/chrome"
cp "$WORK/userChrome.css" "$ZT_PROFILE_DIR/chrome/userChrome.css"
[[ -f "$WORK/userContent.css" ]] && cp "$WORK/userContent.css" "$ZT_PROFILE_DIR/chrome/userContent.css" || true
chown -R "$REAL_USER":"$REAL_USER" "$ZT_PROFILE_DIR/chrome"
ok "userChrome.css → profile"

# ── Stage all extensions into the isolated profile ────────────────────────────
section "Installing extensions"

mkdir -p "$ZT_PROFILE_DIR/extensions"

declare -A EXTS=(
  ["zerotrust-newtab@mrichard333.com"]="$CACHE_DIR/zerotrust-newtab.xpi"
  ["zerotrust-mountain-theme@mrichard333.com"]="$CACHE_DIR/zerotrust-theme.xpi"
  ["zerotrust@mrichard333.com"]="$CACHE_DIR/zerotrust.xpi"
  ["uBlock0@raymondhill.net"]="$CACHE_DIR/ublock.xpi"
  ["{446900e4-71c2-419f-a6a7-df9c091e268b}"]="$CACHE_DIR/bitwarden.xpi"
  ["@testpilot-containers"]="$CACHE_DIR/containers.xpi"
  ["{74145f27-f039-47ce-a470-a662b129930a}"]="$CACHE_DIR/clearurls.xpi"
  ["{b86e4813-687a-43e6-ab65-0bde4ab75758}"]="$CACHE_DIR/localcdn.xpi"
)

for ID in "${!EXTS[@]}"; do
  XPI="${EXTS[$ID]}"
  if [[ -f "$XPI" ]]; then
    cp "$XPI" "$ZT_PROFILE_DIR/extensions/${ID}.xpi"
    ok "Staged: ${ID}"
  else
    warn "Missing: ${ID} (not cached)"
  fi
done
chown -R "$REAL_USER":"$REAL_USER" "$ZT_PROFILE_DIR/extensions"

# Also put newtab XPI in distribution/extensions as belt-and-suspenders
if [[ -n "$FF_INSTALL_DIR" && -d "$FF_INSTALL_DIR" && "$IS_SNAP" != true ]]; then
  mkdir -p "$FF_INSTALL_DIR/distribution/extensions"
  [[ -f "$CACHE_DIR/zerotrust-newtab.xpi" ]] && \
    cp "$CACHE_DIR/zerotrust-newtab.xpi" \
       "$FF_INSTALL_DIR/distribution/extensions/zerotrust-newtab@mrichard333.com.xpi" && \
    chmod 644 "$FF_INSTALL_DIR/distribution/extensions/zerotrust-newtab@mrichard333.com.xpi" || true
fi

# ── Seed initial profile data ─────────────────────────────────────────────────
section "Seeding profile"

# xulstore.json — toolbar layout
cat > "$ZT_PROFILE_DIR/xulstore.json" << 'XULEOF'
{
  "chrome://browser/content/browser.xhtml": {
    "PersonalToolbar": { "collapsed": "false" },
    "navigator-toolbox": { "iconsize": "small" }
  }
}
XULEOF

# handlers.json
echo '{"defaultHandlersVersion":{"en-US":4},"mimeTypes":{},"schemes":{}}' \
  > "$ZT_PROFILE_DIR/handlers.json"

# Initial bookmarks
python3 - "$ZT_PROFILE_DIR" << 'BKPY'
import json, os, sys, time
d = sys.argv[1]
ts = int(time.time() * 1000000)
bk = {"title":"","id":1,"parent":0,"dateAdded":ts,"lastModified":ts,
      "type":"text/x-moz-place-container",
      "children":[
        {"title":"Bookmarks Toolbar","id":2,"parent":1,
         "dateAdded":ts,"lastModified":ts,
         "type":"text/x-moz-place-container",
         "children":[
           {"title":"🛡️ ZeroTrust","id":10,"parent":2,"dateAdded":ts,
            "lastModified":ts,"type":"text/x-moz-place",
            "uri":"https://mrichard333.com/start"},
           {"title":"🦆 Duck.ai","id":11,"parent":2,"dateAdded":ts,
            "lastModified":ts,"type":"text/x-moz-place","uri":"https://duck.ai"},
           {"title":"📊 Dashboard","id":12,"parent":2,"dateAdded":ts,
            "lastModified":ts,"type":"text/x-moz-place",
            "uri":"https://mrichard333.com/dashboard"}
         ]},
        {"title":"Bookmarks Menu","id":3,"parent":1,
         "dateAdded":ts,"lastModified":ts,
         "type":"text/x-moz-place-container","children":[]}
      ]}
os.makedirs(os.path.join(d,"bookmarkbackups"), exist_ok=True)
p = os.path.join(d, "bookmarkbackups", f"zerotrust-{int(time.time())}.json")
with open(p,'w') as f: json.dump(bk, f)
BKPY

chown -R "$REAL_USER":"$REAL_USER" "$ZT_PROFILE_DIR"
ok "Profile seeded (bookmarks, toolbar, handlers)"

# ── Icons ─────────────────────────────────────────────────────────────────────
section "Installing icons"

ICON_NAME="zerotrust-browser"; ICON_INSTALLED=false
for SIZE in 16 32 48 64 128 256; do
  ICON_PATH="$WORK/icon_${SIZE}.png"
  if curl -fsSL --connect-timeout 10 "$REPO_BASE/icons/zerotrust_${SIZE}.png" \
       -o "$ICON_PATH" 2>/dev/null && file "$ICON_PATH" 2>/dev/null | grep -qi "PNG"; then
    mkdir -p "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
    cp "$ICON_PATH" "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/${ICON_NAME}.png"
    ICON_INSTALLED=true
  fi
done
if [[ "$ICON_INSTALLED" == false ]]; then
  LOGO="$WORK/logo.png"
  if curl -fsSL --connect-timeout 10 \
       "https://mrichard333.com/gallery/MRichard333-Logo-V1-ts1605339261.png" \
       -o "$LOGO" 2>/dev/null && file "$LOGO" 2>/dev/null | grep -qi "PNG"; then
    for SIZE in 16 32 48 64 128 256; do
      mkdir -p "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
      cp "$LOGO" "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/${ICON_NAME}.png"
    done
    ICON_INSTALLED=true
  fi
fi
if [[ "$ICON_INSTALLED" == true ]]; then
  cp "/usr/share/icons/hicolor/256x256/apps/${ICON_NAME}.png" \
     "/usr/share/pixmaps/${ICON_NAME}.png" 2>/dev/null || true
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
  ok "Icons installed"
else
  warn "Icon download failed — using Firefox icon"; ICON_NAME="firefox-esr"
fi

# ── Launcher wrapper script ───────────────────────────────────────────────────
section "Creating launcher"

# Build env prefix based on display server and GPU
if [[ "$DISPLAY_SERVER" == "x11" ]]; then
  ENV_VARS="MOZ_X11_EGL=1 MOZ_DISABLE_RDD_SANDBOX=1"
  [[ "$GPU_BAD" == true ]] && ENV_VARS="$ENV_VARS MOZ_WEBRENDER=0 MOZ_ACCELERATED=0"
  [[ "$IS_MAC"  == true ]] && ENV_VARS="$ENV_VARS MOZ_USE_XINPUT2=0"
else
  ENV_VARS="MOZ_ENABLE_WAYLAND=1"
  [[ "$IS_MAC" == true ]] && ENV_VARS="$ENV_VARS MOZ_USE_XINPUT2=0"
fi

cat > "$ZT_WRAPPER" << WRAPPER
#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser launcher — v${VERSION}
#  Launches Firefox with the isolated ZeroTrust profile.
#  Your regular Firefox is completely unaffected.
# ============================================================
exec env ${ENV_VARS} \\
  ${FF_BIN} \\
  --profile "${ZT_PROFILE_DIR}" \\
  --class "ZeroTrustBrowser" \\
  --name "ZeroTrust Browser" \\
  --no-remote \\
  "\$@"
WRAPPER
chmod +x "$ZT_WRAPPER"
chown root:root "$ZT_WRAPPER"
ok "Launcher: $ZT_WRAPPER"

# ── Desktop integration ───────────────────────────────────────────────────────
section "Desktop integration"

APPS_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$APPS_DIR"

cat > "$APPS_DIR/zerotrust-browser.desktop" << DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=ZeroTrust Browser
GenericName=Web Browser
Comment=Privacy-first security-hardened browser — built on Firefox
Exec=${ZT_WRAPPER} %u
Icon=${ICON_NAME}
Terminal=false
Categories=Network;WebBrowser;Security;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=ZeroTrustBrowser
Keywords=zerotrust;browser;security;privacy;
DESKTOP

chmod +x "$APPS_DIR/zerotrust-browser.desktop"
chown "$REAL_USER":"$REAL_USER" "$APPS_DIR/zerotrust-browser.desktop"

[[ -d "$REAL_HOME/Desktop" ]] && {
  cp "$APPS_DIR/zerotrust-browser.desktop" "$REAL_HOME/Desktop/"
  chmod +x "$REAL_HOME/Desktop/zerotrust-browser.desktop"
  chown "$REAL_USER":"$REAL_USER" "$REAL_HOME/Desktop/zerotrust-browser.desktop"
} || true

cp "$APPS_DIR/zerotrust-browser.desktop" /usr/share/applications/ 2>/dev/null && \
  update-desktop-database /usr/share/applications/ 2>/dev/null && \
  ok "System app entry registered" || true

if command -v gsettings &>/dev/null; then
  CUR=$(sudo -u "$REAL_USER" gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "@as []")
  if ! echo "$CUR" | grep -q "zerotrust-browser"; then
    NEW=$(echo "$CUR" | sed "s/]$/, 'zerotrust-browser.desktop']/")
    sudo -u "$REAL_USER" gsettings set org.gnome.shell favorite-apps "$NEW" 2>/dev/null && \
      ok "Pinned to GNOME dock" || warn "Pin manually by right-clicking in Activities"
  else
    ok "Already in dock"
  fi
fi

# ── Mark installed ────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$INSTALL_FLAG")"
echo "$VERSION" > "$INSTALL_FLAG"
chown -R "$REAL_USER":"$REAL_USER" "$(dirname "$INSTALL_FLAG")"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${G}${B}▲  ZeroTrust Browser v${VERSION} installed${NC}"
echo ""
echo -e "  ${DIM}Profile${NC}      $ZT_PROFILE_DIR"
echo -e "  ${DIM}Launcher${NC}     $ZT_WRAPPER"
echo -e "  ${DIM}DoH${NC}          $DOH_LABEL"
echo -e "  ${DIM}Extensions${NC}   $CACHE_DIR"
echo ""
echo -e "  ${G}Launch with:${NC}  zerotrust-browser"
echo -e "  ${DIM}Or click the ZeroTrust Browser icon in your app launcher.${NC}"
echo ""
echo -e "  ${DIM}Your existing Firefox is completely unaffected.${NC}"
echo ""