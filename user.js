/**
 * ZeroTrust Browser — user.js
 * Firefox hardening preferences
 *
 * IMPORTANT: Hardware-sensitive prefs (GPU, memory, process count,
 * fingerprinting overhead) are NOT set here. The installer detects
 * your hardware and appends the correct values automatically.
 * Do not add them here — the installer will override them anyway.
 *
 * Sections:
 *   [STARTUP]     First-launch and update behavior
 *   [GEOLOCATION] Location API
 *   [DNS]         Encrypted DNS / ECH
 *   [HTTPS]       HTTPS-only enforcement
 *   [TLS]         TLS version, 0-RTT, certificate validation
 *   [PRIVACY]     Fingerprinting, WebRTC, battery, sensors
 *   [COOKIES]     Cookie partitioning, storage isolation
 *   [PREFETCH]    Speculative loading
 *   [REFERER]     Cross-origin referer stripping
 *   [TRACKING]    Enhanced Tracking Protection
 *   [TELEMETRY]   All Mozilla data collection
 *   [CACHE]       Session history on close
 *   [NETWORK]     HTTP, DNS, connections
 *   [PROCESS]     Process model baseline
 *   [MEDIA]       Autoplay, PiP
 *   [UI]          userChrome, compact mode, toolbar
 *   [SEARCH]      Search engine behavior
 *   [EXTENSIONS]  Extension security policies
 *   [MISC]        Everything else
 *
 * Hardware-tuned prefs appended by installer:
 *   dom.ipc.processCount, browser.cache.memory.capacity,
 *   gfx.webrender.*, layers.*, privacy.resistFingerprinting,
 *   javascript.options.ion/baselinejit, general.smoothScroll,
 *   layout.frame_rate, browser.tabs.animate, ui.prefersReducedMotion
 */

// ============================================================
// [STARTUP]
// ============================================================

user_pref("browser.aboutConfig.showWarning",              false);
user_pref("browser.sessionstore.resume_from_crash",       false);
user_pref("browser.startup.homepage_override.mstone",     "ignore");
user_pref("startup.homepage_override_url",                "");
user_pref("startup.homepage_welcome_url",                 "");
user_pref("startup.homepage_welcome_url.additional",      "");

// ============================================================
// [GEOLOCATION]
// ============================================================

user_pref("geo.enabled",                                  false);
user_pref("geo.provider.network.url",                     "");

// ============================================================
// [DNS]
// ============================================================

user_pref("network.dns.echconfig.enabled",                true);
user_pref("network.dns.http3_echconfig.enabled",          true);
// Strict DoH — no plaintext DNS fallback
user_pref("network.trr.mode",                             3);
// URI is overwritten by installer to the user's chosen provider
user_pref("network.trr.uri",                              "https://dns.quad9.net/dns-query");

// ============================================================
// [HTTPS]
// ============================================================

user_pref("dom.security.https_only_mode",                 true);
user_pref("dom.security.https_only_mode_ever_enabled",    true);
user_pref("dom.security.https_only_mode.upgrade_local",   true);

// ============================================================
// [TLS]
// ============================================================

// 3 = TLS 1.2 minimum
user_pref("security.tls.version.min",                     3);
// Disable 0-RTT — replay attack vector
user_pref("security.tls.enable_0rtt_data",                false);
// Strict certificate pinning
user_pref("security.cert_pinning.enforcement_level",      2);

// OCSP: soft-fail + CRLite instead of hard-fail.
// Hard-fail (security.OCSP.require = true) makes a live network
// round-trip on EVERY TLS connection before a page loads — adds
// 200-800ms to every navigation on slow connections.
// CRLite is a locally-cached revocation database with equivalent
// security and zero per-connection latency.
user_pref("security.OCSP.enabled",                        1);
user_pref("security.OCSP.require",                        false);
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.pki.crlite_mode",                     2);

// ============================================================
// [PRIVACY]
// ============================================================

// privacy.resistFingerprinting is NOT set in this file.
// On old hardware RFP causes: synchronous canvas intercepts,
// 100ms timer clamping on ALL JavaScript (every animation stutters),
// and letterboxing redraws on every single resize event.
// The installer sets it based on your hardware tier:
//   low/mid  → false (lighter canvas.poisondata used instead)
//   high     → true  (full RFP enabled)

// Lightweight canvas fingerprint protection (works on all hardware)
user_pref("privacy.fingerprintingProtection",             true);
user_pref("canvas.poisondata",                            true);

// WebRTC disabled — leaks real IP even behind a VPN
user_pref("media.peerconnection.enabled",                 false);

// Fingerprinting surfaces
user_pref("dom.battery.enabled",                          false);
user_pref("device.sensors.enabled",                       false);
user_pref("dom.gamepad.enabled",                          false);
user_pref("dom.vr.enabled",                               false);
user_pref("javascript.use_us_english_locale",             true);

// ============================================================
// [COOKIES]
// ============================================================

// Mode 5: reject trackers AND partition all foreign cookies
user_pref("network.cookie.cookieBehavior",                5);
user_pref("network.cookie.cookieBehavior.pbmode",         5);
user_pref("privacy.partition.network_state",              true);
user_pref("privacy.partition.serviceWorkers",             true);

// ============================================================
// [PREFETCH]
// ============================================================

user_pref("network.dns.disablePrefetch",                  true);
user_pref("network.dns.disablePrefetchFromHTTPS",         true);
user_pref("network.http.speculative-parallel-limit",      0);
user_pref("network.preload",                              false);
user_pref("network.prefetch-next",                        false);
user_pref("network.preconnect",                           false);
user_pref("network.early-hints.enabled",                  false);
user_pref("network.early-hints.preconnect.enabled",       false);

// ============================================================
// [REFERER]
// ============================================================

user_pref("network.http.referer.XOriginPolicy",           2);
user_pref("network.http.referer.XOriginTrimmingPolicy",   2);

// ============================================================
// [TRACKING]
// ============================================================

user_pref("privacy.trackingprotection.enabled",           true);
user_pref("privacy.trackingprotection.socialtracking.enabled",  true);
user_pref("privacy.trackingprotection.cryptomining.enabled",    true);
user_pref("privacy.trackingprotection.fingerprinting.enabled",  true);
user_pref("privacy.trackingprotection.emailtracking.enabled",   true);

// ============================================================
// [TELEMETRY]
// ============================================================

user_pref("toolkit.telemetry.enabled",                    false);
user_pref("toolkit.telemetry.unified",                    false);
user_pref("toolkit.telemetry.server",                     "");
user_pref("toolkit.telemetry.archive.enabled",            false);
user_pref("toolkit.telemetry.newProfilePing.enabled",     false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled",         false);
user_pref("toolkit.telemetry.bhrPing.enabled",            false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled",  false);
user_pref("toolkit.telemetry.coverage.opt-out",           true);
user_pref("toolkit.coverage.opt-out",                     true);
user_pref("breakpad.reportURL",                           "");
user_pref("browser.tabs.crashReporting.sendReport",       false);
user_pref("app.shield.optoutstudies.enabled",             false);
user_pref("app.normandy.enabled",                         false);
user_pref("app.normandy.api_url",                         "");
user_pref("datareporting.healthreport.uploadEnabled",     false);
user_pref("datareporting.policy.dataSubmissionEnabled",   false);
user_pref("browser.ping-centre.telemetry",                false);

// ============================================================
// [CACHE] — disk/memory cache set by installer per hardware tier
// ============================================================

user_pref("privacy.sanitize.sanitizeOnShutdown",          true);
user_pref("privacy.clearOnShutdown.cache",                true);
user_pref("privacy.clearOnShutdown.cookies",              false);
user_pref("privacy.clearOnShutdown.downloads",            true);
user_pref("privacy.clearOnShutdown.formdata",             true);
user_pref("privacy.clearOnShutdown.history",              false);
user_pref("privacy.clearOnShutdown.offlineApps",          true);
user_pref("privacy.clearOnShutdown.sessions",             true);
user_pref("privacy.clearOnShutdown.sitesettings",         false);

// DO NOT set browser.cache.disk.enable or browser.cache.memory.capacity
// here — the installer writes the correct values for your hardware tier.

// ============================================================
// [NETWORK] — safe on all hardware
// ============================================================

user_pref("network.http.http2.enabled",                   true);
user_pref("network.http.http3.enabled",                   true);
// Note: network.http.pipelining is deprecated since Firefox 54 — omitted
user_pref("network.http.max-connections",                 900);
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.tcp.tcp_fastopen_enable",              true);
user_pref("network.dnsCacheEntries",                      1000);
user_pref("network.dnsCacheExpiration",                   3600);
user_pref("network.dnsCacheExpirationGracePeriod",        240);
user_pref("network.trr.max-fails",                        5);

// ============================================================
// [PROCESS] — baseline (installer overrides per tier)
// ============================================================

user_pref("dom.ipc.processPriorityManager.backgroundUsesEcoQoS", true);
user_pref("browser.tabs.unloadOnLowMemory",               true);
user_pref("browser.low_commit_space_threshold_mb",        256);
user_pref("browser.sessionstore.restore_on_demand",       true);
user_pref("browser.sessionstore.restore_hidden_tabs",     false);
user_pref("nglayout.initialpaint.delay",                  0);
user_pref("nglayout.initialpaint.delay_in_oopif",         0);
user_pref("places.frecency.updateIdleTime",               300000);

// ============================================================
// [MEDIA]
// ============================================================

user_pref("media.autoplay.default",                       5);
user_pref("media.autoplay.blocking_policy",               2);
user_pref("media.videocontrols.picture-in-picture.enabled", false);

// ============================================================
// [UI]
// ============================================================

user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.uidensity",                            1);
user_pref("accessibility.force_disabled",                 1);
user_pref("browser.newtabpage.activity-stream.showSponsored",            false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites",    false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets",           false);

// ============================================================
// [SEARCH]
// ============================================================

user_pref("browser.search.suggest.enabled",               false);
user_pref("browser.urlbar.suggest.searches",              false);
user_pref("browser.urlbar.speculativeConnect.enabled",    false);
user_pref("browser.search.suggest.enabled.private",       false);

// ============================================================
// [EXTENSIONS]
// ============================================================

user_pref("extensions.webextensions.restrictedDomains",   "accounts-static.cdn.mozilla.net,accounts.firefox.com,addons.cdn.mozilla.net,addons.mozilla.org,api.accounts.firefox.com,content.cdn.mozilla.net,discovery.addons.mozilla.org,install.mozilla.org,oauth.accounts.firefox.com,profile.accounts.firefox.com,support.mozilla.org,sync.services.mozilla.com");

// ============================================================
// [MISC]
// ============================================================

user_pref("identity.fxaccounts.enabled",                  false);

// Safe Browsing: keep malware/phishing ON — disabling it entirely
// leaves users exposed to drive-by malware downloads that uBlock
// does not catch. Only disable the remote download check (Google).
user_pref("browser.safebrowsing.malware.enabled",         true);
user_pref("browser.safebrowsing.phishing.enabled",        true);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);

user_pref("extensions.pocket.enabled",                    false);
user_pref("extensions.screenshots.disabled",              true);

// ============================================================
// Hardware-tuned prefs appended below by the installer.
// Everything after this line is auto-generated — do not edit.
// ============================================================