# Changelog

All notable changes to ZeroTrust Browser will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- `SECURITY.md` — vulnerability disclosure policy
- `CHANGELOG.md` — this file
- `uninstall.sh` / `uninstall.ps1` — clean removal scripts
- GitHub Actions CI: shellcheck, JSON validation, PowerShell linting
- ECH (Encrypted Client Hello) prefs in `user.js`
- WebRTC full disable pref (`media.peerconnection.enabled = false`)
- Flatpak Firefox support in `install.sh`
- DNS provider selection at install time (Cloudflare / Quad9 / Mullvad)
- Idempotency guards in all installers ("already configured — skipping")
- SHA256 checksum verification for downloaded Firefox binaries
- **[PERFORMANCE] section in `user.js`** with GPU acceleration, WebRender, HTTP/3, DNS caching, process tuning

### Changed
- `user.js` now fully commented and sectioned (arkenfox-style)
- Memory cache raised from 64 MB → 512 MB (was artificially low, major perf win with no disk cache)
- Default DoH provider changed to Quad9 (non-profit, Switzerland) — still overridable at install time
- `mrichard333.com/start` homepage restored — confirmed first-party (same author as ZeroTrust Browser)
- `patch_policies.py` logic merged into installer (no more post-hoc patching)

### Fixed
- Running the installer twice no longer duplicates entries or corrupts profiles
- GPU acceleration was not explicitly enabled — on some Linux configs Firefox defaulted to software rendering

---

## [2.1.0] — 2025-XX-XX
*(Initial public release — baseline for future versioning)*

### Added
- One-command setup for Linux (Mountain OS / Ubuntu), macOS, Windows
- Enterprise `policies.json` with HTTPS-only, DoH, tracking protection, TLS hardening
- `user.js` with 200+ Firefox hardening preferences
- Dark matrix `userChrome.css` theme
- Force-installed extensions: ZeroTrust, uBlock Origin, Bitwarden, Multi-Account Containers, ClearURLs, LocalCDN
- Custom new tab page via `zerotrust-newtab.xpi`
- Desktop shortcut and GNOME dock pin on Linux
- Snap Firefox detection and support