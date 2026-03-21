#!/usr/bin/env bash
# ============================================================
#  ZeroTrust Browser — Theme Builder
#  Packages theme/ into zerotrust-theme.xpi
#
#  Usage: ./build-theme.sh
# ============================================================
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SCRIPT_DIR/theme"
OUT="$SCRIPT_DIR/zerotrust-theme.xpi"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
section() { echo -e "\n${CYAN}---- $1 ----${NC}"; }

echo ""
echo "  ZeroTrust Theme Builder"
echo "  -----------------------"

section "Validating theme"

[[ -f "$THEME_DIR/manifest.json" ]] || { echo "ERROR: theme/manifest.json not found"; exit 1; }

# Validate JSON
python3 -c "
import json, sys
with open('$THEME_DIR/manifest.json') as f:
    m = json.load(f)
version = m.get('version', '?')
name    = m.get('name', '?')
print(f'  Name:    {name}')
print(f'  Version: {version}')
req = ['name','version','manifest_version','theme']
missing = [k for k in req if k not in m]
if missing:
    print(f'ERROR: missing keys: {missing}', file=sys.stderr)
    sys.exit(1)
"
ok "manifest.json valid"

section "Packaging XPI"

cd "$THEME_DIR"
[[ -f "$OUT" ]] && rm "$OUT"
zip -r "$OUT" manifest.json icon.png images/ 2>/dev/null
ok "zerotrust-theme.xpi -> $(du -sh "$OUT" | cut -f1)"

section "Done"
echo ""
echo "  Deploy:  copy zerotrust-theme.xpi to your repo root"
echo "  Install: add to policies.json ExtensionSettings or drag into Firefox"
echo ""
