[![MRichard333 Logo](https://mrichard333.com/gallery/MRichard333-Logo-V1-ts1605339261.png)](https://mrichard333.com)

# ZeroTrust Browser

**A privacy-first, security-hardened Firefox distribution for Mountain OS**

[![Firefox ESR](https://img.shields.io/badge/Firefox-ESR%20140+-orange?logo=firefox-browser&logoColor=white)](https://www.mozilla.org/firefox/enterprise/)
[![Version](https://img.shields.io/badge/Version-2.2.0-brightgreen)](#changelog)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue)](#installation)
[![License](https://img.shields.io/badge/License-MIT-green)](https://github.com/MRichard333/ZeroTrust-Browser/blob/main/LICENSE)
[![Extension](https://img.shields.io/badge/Extension-AMO-blueviolet)](https://addons.mozilla.org/en-US/firefox/addon/zerotrust-dashboard-extension/)
[![CI](https://img.shields.io/badge/CI-shellcheck%20%7C%20JSON%20%7C%20PSScriptAnalyzer-blue)](#ci--quality)
[![Website](https://img.shields.io/badge/Website-mrichard333.com-blue)](https://mrichard333.com/browser)

[**Start Page**](https://mrichard333.com/start) · [**Browser Info**](https://mrichard333.com/browser) · [**ZeroTrust Extension**](https://mrichard333.com/extension) · [**Dashboard**](https://mrichard333.com/dashboard)

---

## What is ZeroTrust Browser?

ZeroTrust Browser is a one-command Firefox setup that applies maximum security, privacy hardening, and performance tuning out of the box. No manual configuration, no digging through `about:config` — everything is configured from day one.

Built for **Mountain OS** (Ubuntu base) but fully supported on **macOS** and **Windows** too.

> *"According to the FBI, cybercriminals stole over $3.5 billion from individuals in 2019 alone — and less than 9% was ever recovered. The browser is the most attacked surface on your device. ZeroTrust Browser was built to make it the hardest one to breach."*
> — MRichard333

---

## One-Command Install

No cloning required. Run the command for your platform and everything is configured automatically.

### 🐧 Linux (Mountain OS / Ubuntu / Debian)

```bash
curl -fsSL https://mrichard333.com/zerotrust-install.sh | sudo bash
```

Supports **standard Firefox**, **Snap Firefox**, and **Flatpak Firefox** — auto-detected.

### 🍎 macOS (12 Monterey and later)

```bash
curl -fsSL https://mrichard333.com/zerotrust-install-macos.sh | sudo bash
```

Firefox is downloaded automatically if not already installed.

### 🪟 Windows (10 / 11)

```powershell
# Open PowerShell as Administrator, then run:
irm https://mrichard333.com/zerotrust-install.ps1 | iex
```

Firefox is downloaded automatically if not already installed.

> **Note:** macOS and Windows require setting the default browser manually after install.

---

## Features

| Category | What's included |
| --- | --- |
| **HTTPS** | HTTPS-only mode forced — HTTP is blocked entirely |
| **DNS** | DNS-over-HTTPS with provider choice at install time (Quad9 / Cloudflare / Mullvad / NextDNS) |
| **ECH** | Encrypted Client Hello — hides destination hostname from network observers |
| **Tracking** | Full tracking protection — social, fingerprinting, cryptomining, email |
| **Telemetry** | All Firefox telemetry, crash reporting, and data collection disabled |
| **Fingerprinting** | Canvas, WebGL, battery, sensor, and WebRTC APIs restricted |
| **WebRTC** | Fully disabled — prevents IP leaks even behind a VPN |
| **Cookies** | Third-party cookies partitioned per site (mode 5) |
| **Referer** | Cross-origin referer stripped to origin-only |
| **Prefetch** | DNS prefetch, speculative connections, and link preloading disabled |
| **TLS** | TLS 1.2 minimum, 0-RTT disabled, strict cert pinning (level 2) |
| **OCSP** | Hard-fail OCSP + CRLite strict mode |
| **Auto-clear** | Cache, sessions, and offline storage wiped on every shutdown |
| **Search** | DuckDuckGo set as default — no Google profiling |
| **Performance** | GPU acceleration forced, WebRender enabled, HTTP/3, DNS caching, 512 MB memory cache |
| **UI** | Dark matrix theme via `userChrome.css`, bookmarks toolbar hidden |
| **Containers** | Firefox Multi-Account Containers enabled by default |

---

## Pre-installed Extensions

All extensions are force-installed via enterprise policy on first launch — no AMO browsing required.

| Extension | Purpose | Toolbar |
| --- | --- | --- |
| 🛡️ [ZeroTrust Extension](https://addons.mozilla.org/en-US/firefox/addon/zerotrust-dashboard-extension/) | Real-time site scanning and threat scoring | Pinned |
| 🧱 [uBlock Origin](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/) | Ad and tracker blocking | Pinned |
| 🔑 [Bitwarden](https://addons.mozilla.org/en-US/firefox/addon/bitwarden-password-manager/) | Zero-knowledge password manager | — |
| 📦 [Multi-Account Containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/) | Cookie isolation per site | — |
| 🔗 [ClearURLs](https://addons.mozilla.org/en-US/firefox/addon/clearurls/) | Strip tracking parameters from URLs | — |
| 📡 [LocalCDN](https://addons.mozilla.org/en-US/firefox/addon/localcdn-fork-of-decentraleyes/) | Serve common libraries locally | — |

---

## Installation (Git / Manual)

If you prefer to clone the repo instead of using the one-command install:

### Requirements

- Firefox or Firefox ESR installed (the script will install it if missing)
- Internet connection (for downloading extensions)
- Administrator / sudo privileges

### 🐧 Linux

```bash
git clone https://github.com/MRichard333/ZeroTrust-Browser.git
cd ZeroTrust-Browser
chmod +x install.sh
sudo ./install.sh
```

### 🍎 macOS

```bash
git clone https://github.com/MRichard333/ZeroTrust-Browser.git
cd ZeroTrust-Browser
chmod +x install-macos.sh
sudo ./install-macos.sh
```

### 🪟 Windows

```powershell
git clone https://github.com/MRichard333/ZeroTrust-Browser.git
cd ZeroTrust-Browser
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install.ps1
```

### After installation

1. **Fully quit Firefox** — File → Quit (not just close the window)
2. **Relaunch Firefox**
3. Verify at `about:policies` — all policies should show as **Active**
4. Verify at `about:addons` — ZeroTrust and uBlock should be **pinned to the toolbar**

---

## What the Installer Does

1. **Checks for existing install** — prompts before re-running, backs up existing `user.js`
2. **Lets you choose your DoH provider** — Quad9, Cloudflare, Mullvad, or NextDNS
3. **Detects Firefox** — standard, ESR, Snap, or Flatpak on Linux; downloads if missing on macOS/Windows
4. **Downloads and caches extensions** — all 6 XPIs stored locally so they install without AMO connectivity
5. **Deploys enterprise policies** — copies `policies.json` to the correct platform-specific path
6. **Installs `user.js`** — applies 200+ hardening preferences plus performance tuning to your Firefox profile
7. **Installs `userChrome.css`** — applies the dark matrix theme to the browser UI
8. **Stages extensions** — places XPIs directly in `profile/extensions/` for immediate loading
9. **Creates shortcuts** — desktop shortcut and dock/taskbar pin (Linux/macOS)
10. **Marks install complete** — safe to re-run; will ask before overwriting

---

## Project Structure

```
ZeroTrust-Browser/
├── install.sh                 # Linux installer (Mountain OS / Ubuntu / Flatpak / Snap)
├── install-macos.sh           # macOS installer
├── install.ps1                # Windows installer (PowerShell)
├── policies.json              # Firefox enterprise policies
├── user.js                    # Firefox profile hardening (200+ prefs, fully commented)
├── userChrome.css             # Dark matrix UI theme
├── patch_policies.py          # Helper: patches extension URLs to local file:// paths
├── zerotrust-browser.desktop  # Linux desktop shortcut
├── zerotrust-newtab.xpi       # Bundled new tab extension
├── icons/                     # App icons (16–256px)
├── CHANGELOG.md               # Version history
└── SECURITY.md                # Vulnerability disclosure policy
```

---

## Performance

ZeroTrust Browser v2.2 includes dedicated performance hardening alongside the security configuration. Key improvements over a default Firefox install:

- **GPU acceleration forced** — WebRender compositor enabled regardless of hardware heuristics, which is the most common cause of sluggishness on Linux
- **HTTP/3 (QUIC)** — reduces connection overhead on modern servers
- **DNS caching** — 1,000-entry in-memory DNS cache with a 1-hour TTL, compensating for strict-mode DoH latency
- **512 MB memory cache** — with disk cache disabled for privacy, a large memory cache makes revisiting pages fast within a session
- **Encrypted Client Hello (ECH)** — privacy improvement that also removes a DNS round-trip in some configurations
- **Background tab deprioritisation** — frees CPU for the active tab

The one real performance cost of the security model is `privacy.resistFingerprinting` with letterboxing. If you find specific sites sluggish, disabling letterboxing (`privacy.resistFingerprinting.letterboxing = false` in `about:config`) is the first thing to try.

---

## DNS Provider Choice

The installer asks you to choose your DNS-over-HTTPS provider at setup time. All run in strict mode with no plaintext fallback.

| Provider | Operator | Location | Notes |
| --- | --- | --- | --- |
| **Quad9** *(default)* | Non-profit | Switzerland | Blocks known malicious domains |
| **Cloudflare** | Cloudflare Inc. | USA | Fastest globally; logs minimal data |
| **Mullvad** | Mullvad VPN | Sweden | No-log; pairs well with Mullvad VPN |
| **NextDNS** | NextDNS Inc. | USA | Configurable filtering via dashboard |

You can change provider after install by editing `network.trr.uri` in `about:config`.

---

## CI & Quality

Every push runs automated checks via GitHub Actions:

- **shellcheck** — lints `install.sh`, `install-macos.sh`, and `uninstall.sh`
- **JSON validation** — verifies `policies.json` syntax and required policy keys
- **PSScriptAnalyzer** — lints `install.ps1` on Windows runner
- **user.js validation** — confirms all critical hardening prefs are present

---

## Uninstalling

```bash
# Linux / macOS
sudo ./uninstall.sh
```

```powershell
# Windows
.\uninstall.ps1
```

The uninstaller removes policies, `user.js`, `userChrome.css`, staged extensions, shortcuts, and icons. Your Firefox profile, bookmarks, and saved passwords are untouched.

---

## Start Page

ZeroTrust Browser opens to **[mrichard333.com/start](https://mrichard333.com/start)** — a dark icy-mountain themed dashboard with quick access to all ZeroTrust security tools, a live clock, and a DuckDuckGo search bar. The start page is built and maintained by the same author as this browser distribution.

---

## Security Tools

All tools are free and available at **[mrichard333.com/webtools](https://mrichard333.com/webtools)**:

| Tool | Description |
| --- | --- |
| 🛡️ [ZeroTrust Extension](https://mrichard333.com/extension) | Real-time phishing and threat detection |
| 🩺 [Cyberhealth Audit](https://mrichard333.com/Cyberhealth) | Interactive digital hygiene checklist |
| ⚡ [Password Entropy](https://mrichard333.com/password-check) | Brute-force simulation and bit-strength analysis |
| 🔗 [URL Forensics](https://mrichard333.com/link-scanner) | Deep link analysis and redirect chain inspection |
| 🗜️ [Files Compressor](https://mrichard333.com/files-compressor) | Local video/image compression — no uploads |
| 📈 [SEO Analyser](https://mrichard333.com/seo-analyser) | 20+ automated SEO checks |
| 📊 [Security Dashboard](https://mrichard333.com/dashboard) | Full suite — identity breach, CVE tracker, dark web intel |

---

## vs. arkenfox

ZeroTrust Browser and [arkenfox user.js](https://github.com/arkenfox/user.js) share similar goals. The differences:

- **ZeroTrust is a full distribution** — one command installs Firefox, extensions, policies, and theme. arkenfox is a `user.js` file you apply manually.
- **Enterprise policies** — ZeroTrust uses `policies.json` to lock settings and force-install extensions at the system level, which `user.js` alone cannot do.
- **Performance tuning included** — GPU acceleration, HTTP/3, and DNS caching are configured out of the box.
- **Custom ecosystem** — the ZeroTrust Extension, start page, and security tools are purpose-built for this distribution.

If you want maximum `user.js` control and maintain your own setup, arkenfox is excellent. If you want everything configured in one command, ZeroTrust Browser is built for that.

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

If you find a security vulnerability, please report it privately via [mrichard333.com/contact](https://mrichard333.com/contact) rather than opening a public GitHub issue. See [SECURITY.md](./SECURITY.md) for the full disclosure policy.

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for the full version history.

**v2.2.0** — One-command curl installers, DNS provider selection, Flatpak support, idempotency, performance tuning, ECH, WebRTC disabled, `user.js` fully commented, CI added, `SECURITY.md` and `CHANGELOG.md` added, `uninstall.sh` added.

---

## License

MIT — see [LICENSE](https://github.com/MRichard333/ZeroTrust-Browser/blob/main/LICENSE) for details.

---

Made with ❄️ by [MRichard333](https://mrichard333.com) · [Cyber Defense Hub](https://mrichard333.com/webtools) · Registered Non-Profit · Canada