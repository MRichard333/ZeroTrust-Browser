#!/usr/bin/env bash

# ============================================================
# ZeroTrust Browser — Uninstaller
# Removes policies, user.js, userChrome.css, shortcuts, icons
# Run with: sudo ./uninstall.sh
# ============================================================

set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
FIREFOX_DIR="$REAL_HOME/.mozilla/firefox"
SNAP_FIREFOX_DIR="$REAL_HOME/snap/firefox/common/.mozilla/firefox"
FLATPAK_FIREFOX_DIR="$REAL_HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
INSTALL_FLAG="$REAL_HOME/.config/zerotrust-browser/.installed"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
section() { echo -e "\n${CYAN}──── $1 ────${NC}"; }
rm_if()   { [[ -e "$1" ]] && rm -rf "$1" && ok "Removed: $1" || true; }

echo ""
echo " ZeroTrust Browser — Uninstaller"
echo " ────────────────────────────────"
echo ""
echo " This will remove ZeroTrust policies, user.js, userChrome.css,"
echo " shortcuts, and icons. Your Firefox profile and bookmarks are untouched."
echo ""
read -rp " Continue? [y/N]: " CONFIRM
[[ "${CONFIRM,,}" == "y" ]] || { echo " Cancelled."; exit 0; }

# ════════════════════════════════════════════════════════════
# 1. POLICIES
# ════════════════════════════════════════════════════════════
section "Removing enterprise policies"

for dir in \
  "/usr/lib/firefox/distribution" \
  "/usr/lib/firefox-esr/distribution" \
  "/var/snap/firefox/common/policies" \
  "$REAL_HOME/snap/firefox/common/policies" \
  "$REAL_HOME/.var/app/org.mozilla.firefox/distribution"
do
  [[ -f "$dir/policies.json" ]] && rm_if "$dir/policies.json"
done

# ════════════════════════════════════════════════════════════
# 2. PROFILE FILES
# ════════════════════════════════════════════════════════════
section "Removing profile hardening files"

for base_dir in "$FIREFOX_DIR" "$SNAP_FIREFOX_DIR" "$FLATPAK_FIREFOX_DIR"; do
  [[ -d "$base_dir" ]] || continue
  while IFS= read -r -d '' profile; do
    [[ -f "$profile/user.js" ]]              && rm_if "$profile/user.js"
    [[ -f "$profile/chrome/userChrome.css" ]] && rm_if "$profile/chrome/userChrome.css"
    # Remove extension stagings
    for xpi_id in \
      "zerotrust@mrichard333.com" \
      "uBlock0@raymondhill.net" \
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" \
      "@testpilot-containers" \
      "{74145f27-f039-47ce-a470-a662b129930a}" \
      "{b86e4813-687a-43e6-ab65-0bde4ab75758}"
    do
      rm_if "$profile/extensions/${xpi_id}.xpi"
    done
  done < <(find "$base_dir" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
done

# ════════════════════════════════════════════════════════════
# 3. SHORTCUTS
# ════════════════════════════════════════════════════════════
section "Removing shortcuts"

rm_if "$REAL_HOME/.local/share/applications/zerotrust-browser.desktop"
rm_if "$REAL_HOME/Desktop/zerotrust-browser.desktop"
rm_if "/usr/share/applications/zerotrust-browser.desktop"
update-desktop-database /usr/share/applications/ 2>/dev/null || true

# ════════════════════════════════════════════════════════════
# 4. ICONS
# ════════════════════════════════════════════════════════════
section "Removing icons"

rm_if "/usr/share/icons/zerotrust-browser.png"
for SIZE in 16 32 48 64 128 256; do
  rm_if "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/zerotrust-browser.png"
done
gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true

# ════════════════════════════════════════════════════════════
# 5. INSTALL FLAG
# ════════════════════════════════════════════════════════════
section "Removing install marker"
rm_if "$INSTALL_FLAG"
rm_if "$(dirname "$INSTALL_FLAG")"

echo ""
echo " ────────────────────────────────"
echo -e " ${GREEN}Uninstall complete.${NC}"
echo " Relaunch Firefox to restore default settings."
echo ""
