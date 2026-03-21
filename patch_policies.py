#!/usr/bin/env python3
"""
patch_policies.py — called by install.sh
Updates ExtensionSettings install_urls to local file:// paths
where XPIs have been cached, falling back to AMO URLs.

Usage:
  python3 patch_policies.py <policies.json> <ext-cache-dir> [ext_id ...]
"""

import json
import os
import sys

pol_path  = sys.argv[1]
cache_dir = sys.argv[2]
ext_ids   = sys.argv[3:]

# Map extension IDs to their cached XPI filenames
ID_TO_FILE = {
    "zerotrust@mrichard333.com":                    "zerotrust.xpi",
    "uBlock0@raymondhill.net":                      "ublock.xpi",
    "{446900e4-71c2-419f-a6a7-df9c091e268b}":       "bitwarden.xpi",
    "@testpilot-containers":                        "containers.xpi",
    "{74145f27-f039-47ce-a470-a662b129930a}":       "clearurls.xpi",
    "{b86e4813-687a-43e6-ab65-0bde4ab75758}":       "localcdn.xpi",
    "zerotrust-newtab@mrichard333.com":             "zerotrust-newtab.xpi",
}

with open(pol_path) as f:
    pol = json.load(f)

ext_settings = pol.get("policies", {}).get("ExtensionSettings", {})

patched = 0
for ext_id, filename in ID_TO_FILE.items():
    if ext_id not in ext_settings:
        continue
    xpi_path = os.path.join(cache_dir, filename)
    if os.path.isfile(xpi_path):
        ext_settings[ext_id]["install_url"] = "file://" + os.path.abspath(xpi_path)
        print(f"  [✓] {ext_id[:40]:<40} → file://{filename}")
        patched += 1
    else:
        print(f"  [~] {ext_id[:40]:<40} → AMO (not cached)")

with open(pol_path, "w") as f:
    json.dump(pol, f, indent=2)

print(f"\n  Patched {patched} extension URL(s) in {pol_path}")
