#!/usr/bin/env python3
"""
patch_policies.py — called by install.sh
Updates ExtensionSettings install_urls to local file:// paths.

Usage:
  python3 patch_policies.py <policies.json> <ext-cache-dir> <script-dir>
"""

import json, os, sys

pol_path   = sys.argv[1]   # path to the deployed policies.json
cache_dir  = sys.argv[2]   # ext-cache/ directory
script_dir = sys.argv[3]   # project root (where zerotrust-newtab.xpi lives)

# (filename_in_cache_dir, filename_in_script_dir_as_fallback)
ID_TO_FILES = {
    "zerotrust@mrichard333.com":              ("zerotrust.xpi",        None),
    "uBlock0@raymondhill.net":                ("ublock.xpi",           None),
    "{446900e4-71c2-419f-a6a7-df9c091e268b}": ("bitwarden.xpi",        None),
    "@testpilot-containers":                  ("containers.xpi",       None),
    "{74145f27-f039-47ce-a470-a662b129930a}": ("clearurls.xpi",        None),
    "{b86e4813-687a-43e6-ab65-0bde4ab75758}": ("localcdn.xpi",         None),
    # newtab lives in script_dir, not ext-cache
    "zerotrust-newtab@mrichard333.com":       (None, "zerotrust-newtab.xpi"),
}

with open(pol_path) as f:
    pol = json.load(f)

ext = pol.get("policies", {}).get("ExtensionSettings", {})
patched = 0

for ext_id, (cache_file, script_file) in ID_TO_FILES.items():
    if ext_id not in ext:
        continue

    found = None

    # Check cache_dir first
    if cache_file:
        p = os.path.join(cache_dir, cache_file)
        if os.path.isfile(p):
            found = p

    # Fall back to script_dir
    if not found and script_file:
        p = os.path.join(script_dir, script_file)
        if os.path.isfile(p):
            found = p

    if found:
        ext[ext_id]["install_url"] = "file://" + os.path.abspath(found)
        print(f"  [ok] {ext_id[:44]:<44} -> {os.path.basename(found)}")
        patched += 1
    else:
        print(f"  [--] {ext_id[:44]:<44} -> not cached, keeping existing URL")

with open(pol_path, "w") as f:
    json.dump(pol, f, indent=2)

print(f"\n  {patched} URL(s) patched in {pol_path}")