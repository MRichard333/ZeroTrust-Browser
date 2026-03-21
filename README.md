<div align="center">

<img src="https://mrichard333.com/gallery/MRichard333-Logo-V1-ts1605339261.png" width="80" alt="MRichard333 Logo"/>

# ZeroTrust Browser

**A privacy-first, security-hardened Firefox distribution for Mountain OS**

[![Firefox ESR](https://img.shields.io/badge/Firefox-ESR%20140+-orange?logo=firefox-browser&logoColor=white)](https://www.mozilla.org/firefox/enterprise/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue)](#installation)
[![License](https://img.shields.io/badge/License-MIT-green)](/LICENSE)
[![Extension](https://img.shields.io/badge/Extension-AMO-blueviolet)](https://addons.mozilla.org/en-US/firefox/addon/zerotrust-dashboard-extension/)
[![Website](https://img.shields.io/badge/Website-mrichard333.com-blue)](https://mrichard333.com/browser)

[**Start Page**](https://mrichard333.com/start) · [**Browser Info**](https://mrichard333.com/browser) · [**ZeroTrust Extension**](https://mrichard333.com/extension) · [**Dashboard**](https://mrichard333.com/dashboard)

</div>

---

## What is ZeroTrust Browser?

ZeroTrust Browser is a one-command Firefox setup that applies maximum security and privacy hardening out of the box. No manual configuration, no digging through `about:config` — everything is configured from day one.

Built for **Mountain OS** (Ubuntu base) but fully supported on **macOS** and **Windows** too.

> *"According to the FBI, cybercriminals stole over $3.5 billion from individuals in 2019 alone — and less than 9% was ever recovered. The browser is the most attacked surface on your device. ZeroTrust Browser was built to make it the hardest one to breach."*
> — MRichard333

---

## Features

| Category | What's included |
|---|---|
| **HTTPS** | HTTPS-only mode forced — HTTP is blocked entirely |
| **DNS** | DNS-over-HTTPS via Cloudflare (strict mode, no fallback) |
| **Tracking** | Full tracking protection — social, fingerprinting, cryptomining, email |
| **Telemetry** | All Firefox telemetry, crash reporting, and data collection disabled |
| **Fingerprinting** | Canvas, WebGL, battery, sensor, and WebRTC APIs restricted |
| **Cookies** | Third-party cookies partitioned per site (mode 5) |
| **Referer** | Cross-origin referer stripped to origin-only |
| **Prefetch** | DNS prefetch, speculative connections, and link preloading disabled |
| **TLS** | TLS 1.2 minimum, 0-RTT disabled, strict cert pinning (level 2) |
| **OCSP** | Hard-fail OCSP + CRLite strict mode |
| **Auto-clear** | Cache, sessions, and offline storage wiped on every shutdown |
| **Search** | DuckDuckGo set as default — no Google profiling |
| **UI** | Dark matrix theme via `userChrome.css`, bookmarks toolbar hidden |
| **Containers** | Firefox Multi-Account Containers enabled by default |

---

## Pre-installed Extensions

All extensions are force-installed via enterprise policy on first launch — no AMO browsing required.

| Extension | Purpose | Toolbar |
|---|---|---|
| 🛡️ [ZeroTrust Extension](https://addons.mozilla.org/en-US/firefox/addon/zerotrust-dashboard-extension/) | Real-time site scanning and threat scoring | Pinned |
| 🧱 [uBlock Origin](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/) | Ad and tracker blocking | Pinned |
| 🔑 [Bitwarden](https://addons.mozilla.org/en-US/firefox/addon/bitwarden-password-manager/) | Zero-knowledge password manager | — |
| 📦 [Multi-Account Containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/) | Cookie isolation per site | — |
| 🔗 [ClearURLs](https://addons.mozilla.org/en-US/firefox/addon/clearurls/) | Strip tracking parameters from URLs | — |
| 📡 [LocalCDN](https://addons.mozilla.org/en-US/firefox/addon/localcdn-fork-of-decentraleyes/) | Serve common libraries locally | — |

---

## Installation

### Requirements

- Firefox or Firefox ESR installed (the script will install it if missing)
- Internet connection (for downloading extensions)
- Administrator / sudo privileges

---

### 🐧 Linux (Mountain OS / Ubuntu)

```bash
# Clone the repository
git clone https://github.com/MRichard333/ZeroTrust-Browser.git
cd ZeroTrust-Browser

# Run the installer
chmod +x install.sh
sudo ./install.sh
```

Supports both **standard Firefox** and **Snap Firefox**. The script auto-detects which one is installed.

---

### 🍎 macOS (12 Monterey and later)

```bash
# Clone the repository
git clone https://github.com/MRichard333/ZeroTrust-Browser.git
cd ZeroTrust-Browser

# Run the macOS installer
chmod +x install-macos.sh
sudo ./install-macos.sh
```

Firefox will be downloaded automatically if not already installed.

> **Note:** macOS requires you to set the default browser manually via **System Settings → General → Default web browser**.

---

### 🪟 Windows (10 / 11)

```powershell
# Clone the repository or download the ZIP from GitHub
git clone https://github.com/MRichard333/ZeroTrust-Browser.git
cd ZeroTrust-Browser

# Open PowerShell as Administrator, then run:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install.ps1
```

Firefox will be downloaded automatically if not already installed.

> **Note:** Windows 10/11 requires you to set the default browser manually via **Settings → Apps → Default apps → Web browser**.

---

### After installation

1. **Fully quit Firefox** — File → Quit (not just close the window)
2. **Relaunch Firefox**
3. Verify at `about:policies` — all policies should show as **Active**
4. Verify at `about:addons` — ZeroTrust and uBlock should be **pinned to the toolbar**

---

## Project Structure

```
ZeroTrust-Browser/
├── install.sh           # Linux installer (Mountain OS / Ubuntu)
├── install-macos.sh     # macOS installer
├── install.ps1          # Windows installer (PowerShell)
├── patch_policies.py    # Helper: patches extension URLs to local file:// paths
├── policies.json        # Firefox enterprise policies
├── user.js              # Firefox profile hardening (200+ prefs)
├── userChrome.css       # Dark matrix UI theme
└── zerotrust-browser.desktop  # Linux desktop shortcut
```

---

## What the installer does

1. **Detects Firefox** — finds your installation or downloads it automatically
2. **Downloads extensions** — caches all 6 XPIs locally in `ext-cache/` so they install without needing AMO connectivity
3. **Deploys enterprise policies** — copies `policies.json` to the correct platform-specific location so Firefox reads it on next launch
4. **Installs `user.js`** — applies 200+ hardening preferences to your Firefox profile
5. **Installs `userChrome.css`** — applies the dark mountain theme to the browser UI
6. **Stages extensions** — places XPIs directly in `profile/extensions/` for immediate loading
7. **Creates shortcuts** — desktop shortcut and dock/taskbar pin (Linux/macOS)

---

## Start Page

ZeroTrust Browser opens to a custom start page at **[mrichard333.com/start](https://mrichard333.com/start)** — a dark icy-mountain themed dashboard with quick access to all ZeroTrust security tools, a live clock, and a DuckDuckGo search bar.

---

## Security Tools

All tools are free and available at **[mrichard333.com/webtools](https://mrichard333.com/webtools)**:

| Tool | Description |
|---|---|
| 🛡️ [ZeroTrust Extension](https://mrichard333.com/extension) | Real-time phishing and threat detection |
| 🩺 [Cyberhealth Audit](https://mrichard333.com/Cyberhealth) | Interactive digital hygiene checklist |
| ⚡ [Password Entropy](https://mrichard333.com/password-check) | Brute-force simulation and bit-strength analysis |
| 🔗 [URL Forensics](https://mrichard333.com/link-scanner) | Deep link analysis and redirect chain inspection |
| 🗜️ [Files Compressor](https://mrichard333.com/files-compressor) | Local video/image compression — no uploads |
| 📈 [SEO Analyser](https://mrichard333.com/seo-analyser) | 20+ automated SEO checks |
| 📊 [Security Dashboard](https://mrichard333.com/dashboard) | Full suite — identity breach, CVE tracker, dark web intel |

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first.

If you find a security issue, please report it via [mrichard333.com/contact](https://mrichard333.com/contact) rather than a public GitHub issue.

---

## License

MIT — see [LICENSE](/LICENSE) for details.

---

<div align="center">

Made with ❄️ by [MRichard333](https://mrichard333.com) · [Cyber Defense Hub](https://mrichard333.com/webtools) · Registered Non-Profit · Canada

</div>
