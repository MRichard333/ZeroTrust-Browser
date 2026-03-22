/**
 * ZeroTrust Browser — user.js  v2.4
 *
 * Philosophy: match vanilla Firefox performance exactly,
 * then add only security prefs with zero or near-zero CPU cost.
 * Hardware-expensive prefs are set by the installer per tier.
 *
 * What vanilla Firefox does NOT protect against that we add:
 *   - WebRTC IP leaks          (media.peerconnection.enabled)
 *   - Telemetry / phoning home (toolkit.telemetry.*)
 *   - DNS in plaintext         (network.trr.mode=3 + DoH)
 *   - TLS 0-RTT replay         (security.tls.enable_0rtt_data)
 *   - OCSP round-trip latency  (CRLite replaces it)
 *   - Canvas fingerprinting    (canvas.poisondata — lightweight)
 *   - Battery/sensor APIs      (dom.battery.enabled etc)
 *   - Geolocation              (geo.enabled)
 *   - Sponsored content        (newtabpage activity-stream)
 *   - Firefox Sync account     (identity.fxaccounts.enabled)
 *
 * What we deliberately do NOT change from Firefox defaults:
 *   - JIT / JS engine          (ion, baselinejit) — 3-10x perf impact
 *   - Smooth scrolling         (GPU-composited, costs nothing)
 *   - WebRender / GPU          (Firefox auto-detects correctly)
 *   - Process count            (Firefox tunes this well)
 *   - Memory cache             (Firefox auto-tunes, we only override on low-RAM)
 *   - resistFingerprinting     (timer clamping breaks every animation)
 *   - ETP category             (strict is Firefox's default now)
 *   - Fission                  (only disabled on very low RAM by installer)
 */

// ── [STARTUP] ─────────────────────────────────────────────
user_pref("browser.aboutConfig.showWarning",              false);
user_pref("browser.sessionstore.resume_from_crash",       false);
user_pref("browser.startup.homepage_override.mstone",     "ignore");
user_pref("startup.homepage_override_url",                "");
user_pref("startup.homepage_welcome_url",                 "");
user_pref("startup.homepage_welcome_url.additional",      "");

// ── [GEOLOCATION] ──────────────────────────────────────────
user_pref("geo.enabled",                                  false);
user_pref("geo.provider.network.url",                     "");

// ── [DNS / ECH] ────────────────────────────────────────────
// ECH hides destination hostname from passive observers
user_pref("network.dns.echconfig.enabled",                true);
user_pref("network.dns.http3_echconfig.enabled",          true);
// Strict DoH — no plaintext DNS fallback
// URI is overwritten by installer to the user's chosen provider
user_pref("network.trr.mode",                             3);
user_pref("network.trr.uri",                              "https://dns.quad9.net/dns-query");

// ── [HTTPS] ────────────────────────────────────────────────
user_pref("dom.security.https_only_mode",                 true);
user_pref("dom.security.https_only_mode_ever_enabled",    true);
user_pref("dom.security.https_only_mode.upgrade_local",   true);

// ── [TLS] ──────────────────────────────────────────────────
user_pref("security.tls.version.min",                     3); // TLS 1.2 minimum
user_pref("security.tls.enable_0rtt_data",                false); // no replay attacks
user_pref("security.cert_pinning.enforcement_level",      2);
// CRLite: locally-cached revocation — same security as OCSP, zero latency
user_pref("security.OCSP.enabled",                        1);
user_pref("security.OCSP.require",                        false); // hard-fail = 200-800ms per page
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.pki.crlite_mode",                     2);

// ── [PRIVACY] ──────────────────────────────────────────────
// resistFingerprinting deliberately omitted — it clamps ALL JS timers
// to 100ms which makes every animation, scroll, and interaction stutter.
// canvas.poisondata gives canvas protection without the timer clamping.
user_pref("privacy.fingerprintingProtection",             true);
user_pref("canvas.poisondata",                            true);

// WebRTC leaks your real IP even behind a VPN — disable completely
user_pref("media.peerconnection.enabled",                 false);

// Fingerprinting surfaces — all zero CPU cost to disable
user_pref("dom.battery.enabled",                          false);
user_pref("device.sensors.enabled",                       false);
user_pref("dom.gamepad.enabled",                          false);
user_pref("dom.vr.enabled",                               false);
user_pref("javascript.use_us_english_locale",             true);

// ── [COOKIES] ──────────────────────────────────────────────
// Mode 5 is now Firefox's default (v120+) — keeping explicit is fine
user_pref("network.cookie.cookieBehavior",                5);
user_pref("network.cookie.cookieBehavior.pbmode",         5);
user_pref("privacy.partition.network_state",              true);
user_pref("privacy.partition.serviceWorkers",             true);

// ── [PREFETCH] ─────────────────────────────────────────────
// Disable all speculative loading — saves RAM and CPU on old hardware,
// negligible impact on modern hardware since pages are fast anyway
user_pref("network.dns.disablePrefetch",                  true);
user_pref("network.dns.disablePrefetchFromHTTPS",         true);
user_pref("network.http.speculative-parallel-limit",      0);
user_pref("network.preload",                              false);
user_pref("network.prefetch-next",                        false);
user_pref("network.preconnect",                           false);
user_pref("network.early-hints.enabled",                  false);
user_pref("network.early-hints.preconnect.enabled",       false);

// ── [REFERER] ──────────────────────────────────────────────
user_pref("network.http.referer.XOriginPolicy",           2);
user_pref("network.http.referer.XOriginTrimmingPolicy",   2);

// ── [TRACKING] ─────────────────────────────────────────────
// ETP strict is Firefox's default now — these just make it explicit
user_pref("privacy.trackingprotection.enabled",           true);
user_pref("privacy.trackingprotection.socialtracking.enabled",  true);
user_pref("privacy.trackingprotection.cryptomining.enabled",    true);
user_pref("privacy.trackingprotection.fingerprinting.enabled",  true);
user_pref("privacy.trackingprotection.emailtracking.enabled",   true);

// ── [TELEMETRY] ────────────────────────────────────────────
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

// ── [CACHE] ────────────────────────────────────────────────
// Clear sensitive data on close but keep history/cookies for usability
user_pref("privacy.sanitize.sanitizeOnShutdown",          true);
user_pref("privacy.clearOnShutdown.cache",                true);
user_pref("privacy.clearOnShutdown.cookies",              false);
user_pref("privacy.clearOnShutdown.downloads",            true);
user_pref("privacy.clearOnShutdown.formdata",             true);
user_pref("privacy.clearOnShutdown.history",              false);
user_pref("privacy.clearOnShutdown.offlineApps",          true);
user_pref("privacy.clearOnShutdown.sessions",             true);
user_pref("privacy.clearOnShutdown.sitesettings",         false);
// browser.cache.disk.enable and browser.cache.memory.capacity
// are set by the installer based on your hardware tier

// ── [NETWORK PERFORMANCE] ──────────────────────────────────
// These match or exceed Firefox defaults — safe on all hardware
user_pref("network.http.http2.enabled",                   true);
user_pref("network.http.http3.enabled",                   true);
user_pref("network.http.max-connections",                 900);
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.tcp.tcp_fastopen_enable",              true);
user_pref("network.dnsCacheEntries",                      1000);
user_pref("network.dnsCacheExpiration",                   3600);
user_pref("network.dnsCacheExpirationGracePeriod",        240);
user_pref("network.trr.max-fails",                        5);

// ── [PROCESS MODEL] ────────────────────────────────────────
// Let Firefox auto-tune process count — it knows your hardware
// Installer overrides dom.ipc.processCount only on very low RAM
user_pref("dom.ipc.processPriorityManager.backgroundUsesEcoQoS", true);
user_pref("browser.tabs.unloadOnLowMemory",               true);
user_pref("browser.low_commit_space_threshold_mb",        256);
user_pref("browser.sessionstore.restore_on_demand",       true);
user_pref("browser.sessionstore.restore_hidden_tabs",     false);
user_pref("nglayout.initialpaint.delay",                  0);
user_pref("nglayout.initialpaint.delay_in_oopif",         0);
user_pref("places.frecency.updateIdleTime",               300000);

// ── [UI] ───────────────────────────────────────────────────
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.uidensity",                            1);
// Do NOT disable accessibility.force_disabled here —
// it prevents screen readers and breaks some system integrations.
// The installer sets it only on confirmed low-tier hardware.
user_pref("browser.newtabpage.activity-stream.showSponsored",            false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites",    false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets",           false);

// ── [MEDIA] ────────────────────────────────────────────────
user_pref("media.autoplay.default",                       5);
user_pref("media.autoplay.blocking_policy",               2);
// PiP disabled — spawns extra compositor thread, clutters UI
user_pref("media.videocontrols.picture-in-picture.enabled", false);

// ── [SEARCH] ───────────────────────────────────────────────
user_pref("browser.search.suggest.enabled",               false);
user_pref("browser.urlbar.suggest.searches",              false);
user_pref("browser.urlbar.speculativeConnect.enabled",    false);
user_pref("browser.search.suggest.enabled.private",       false);

// ── [EXTENSIONS] ───────────────────────────────────────────
user_pref("extensions.webextensions.restrictedDomains",   "accounts-static.cdn.mozilla.net,accounts.firefox.com,addons.cdn.mozilla.net,addons.mozilla.org,api.accounts.firefox.com,content.cdn.mozilla.net,discovery.addons.mozilla.org,install.mozilla.org,oauth.accounts.firefox.com,profile.accounts.firefox.com,support.mozilla.org,sync.services.mozilla.com");

// ── [MISC] ─────────────────────────────────────────────────
user_pref("identity.fxaccounts.enabled",                  false);
// Safe Browsing: keep ON for malware/phishing, disable only remote download check
user_pref("browser.safebrowsing.malware.enabled",         true);
user_pref("browser.safebrowsing.phishing.enabled",        true);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("extensions.pocket.enabled",                    false);
user_pref("extensions.screenshots.disabled",              true);

// ── Hardware-tuned prefs appended below by installer ───────
// Do not add dom.ipc.processCount, browser.cache.*, gfx.webrender.*,
// layers.*, javascript.options.*, or general.smoothScroll here.