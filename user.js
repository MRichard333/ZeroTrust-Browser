/**
 * ZeroTrust Browser — user.js
 * Firefox hardening preferences
 *
 * Sections:
 *   [STARTUP]       First-launch and update behavior
 *   [GEOLOCATION]   Location API
 *   [DNS]           Encrypted DNS / ECH
 *   [HTTPS]         HTTPS-only enforcement
 *   [TLS]           TLS version, 0-RTT, OCSP
 *   [PRIVACY]       Fingerprinting, canvas, WebGL, WebRTC, battery
 *   [COOKIES]       Cookie partitioning, storage isolation
 *   [PREFETCH]      Speculative loading, prefetch, prerender
 *   [REFERER]       Cross-origin referer stripping
 *   [TRACKING]      ETP, social tracking, cryptomining
 *   [TELEMETRY]     All Mozilla data collection
 *   [CACHE]         Disk cache, session history on close
 *   [PERFORMANCE]   JS engine, rendering, network, GPU acceleration
 *   [MEDIA]         Autoplay, DRM
 *   [UI]            userChrome, compact mode, toolbar
 *   [SEARCH]        Default search engine behavior
 *   [EXTENSIONS]    Extension security policies
 *   [MISC]          Everything else
 *
 * References:
 *   https://arkenfox.github.io/gui/
 *   https://mozilla.github.io/policy-templates/
 *   https://support.mozilla.org/en-US/products/firefox/privacy-and-security
 */

// ============================================================
// [STARTUP] — First-launch, update, onboarding
// ============================================================

// Disable about:config warning
user_pref("browser.aboutConfig.showWarning", false);

// Do not restore session on crash (avoids auto-reopening malicious pages)
user_pref("browser.sessionstore.resume_from_crash", false);

// Disable first-run and post-update pages (phoning home)
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_override_url", "");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");

// ============================================================
// [GEOLOCATION] — Disable location API entirely
// ============================================================

// Disable geolocation (prevents IP and GPS-based tracking)
user_pref("geo.enabled", false);

// Remove Mozilla's geolocation service URL (defense-in-depth)
user_pref("geo.provider.network.url", "");

// ============================================================
// [DNS] — Encrypted DNS and Encrypted Client Hello (ECH)
// ============================================================

// ECH — hides the destination hostname from passive observers on TLS handshake
// This is one of the most important modern anti-surveillance prefs
user_pref("network.dns.echconfig.enabled", true);
user_pref("network.dns.http3_echconfig.enabled", true);

// Fallback mode for DoH: 3 = strict (no plaintext DNS fallback)
user_pref("network.trr.mode", 3);

// Resolver URI is also set via policies.json (policy takes priority over user.js)
// Keeping it here too as defense-in-depth in case policies don't load
user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");

// ============================================================
// [HTTPS] — Force HTTPS everywhere
// ============================================================

// HTTPS-only mode — Firefox will refuse to load HTTP pages
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_ever_enabled", true);

// Upgrade insecure requests (belt-and-suspenders with HTTPS-only)
user_pref("dom.security.https_only_mode.upgrade_local", true);

// ============================================================
// [TLS] — Protocol hardening
// ============================================================

// Minimum TLS version: 1.2 (1.0 and 1.1 have known attacks)
user_pref("security.tls.version.min", 3); // 3 = TLS 1.2, 4 = TLS 1.3

// Disable 0-RTT (TLS 1.3 early data) — replay attack vector
user_pref("security.tls.enable_0rtt_data", false);

// Certificate pinning: 2 = strict (enforced even for user-added CAs)
user_pref("security.cert_pinning.enforcement_level", 2);

// OCSP hard-fail — if certificate status cannot be confirmed, block the connection
user_pref("security.OCSP.require", true);

// CRLite strict mode — use locally cached CRL data, block on revocation
user_pref("security.pki.crlite_mode", 2);

// ============================================================
// [PRIVACY] — Fingerprinting, WebRTC, Canvas, Battery, Sensors
// ============================================================

// Enable Firefox's built-in fingerprinting resistance
user_pref("privacy.resistFingerprinting", true);

// Letterbox mode — normalizes viewport size to reduce fingerprinting surface
user_pref("privacy.resistFingerprinting.letterboxing", true);

// Disable WebRTC entirely — WebRTC can leak local and public IPs
// even behind a VPN. Most users do not need peer-to-peer connections.
// Re-enable manually if you use video calling (Google Meet, Discord, etc.)
user_pref("media.peerconnection.enabled", false);

// If you need WebRTC, at minimum restrict which IPs are exposed:
// user_pref("media.peerconnection.ice.default_address_only", true);
// user_pref("media.peerconnection.ice.no_host", true);

// Disable canvas fingerprinting — sites use canvas to uniquely ID browsers
user_pref("privacy.fingerprintingProtection", true);

// Disable WebGL — high fingerprinting surface and potential GPU exploit vector
user_pref("webgl.disabled", true);

// Disable battery status API — used for cross-site tracking
user_pref("dom.battery.enabled", false);

// Disable device sensor access (accelerometer, gyroscope, etc.)
user_pref("device.sensors.enabled", false);

// Disable gamepad API unless needed (fingerprinting surface)
user_pref("dom.gamepad.enabled", false);

// Disable VR/AR APIs
user_pref("dom.vr.enabled", false);

// Spoof locale to English to reduce fingerprint
user_pref("javascript.use_us_english_locale", true);

// ============================================================
// [COOKIES] — Partitioned storage, third-party isolation
// ============================================================

// Cookie behavior mode 5: reject trackers AND partition all foreign cookies
// This is stricter than the default "reject trackers" (mode 1)
user_pref("network.cookie.cookieBehavior", 5);
user_pref("network.cookie.cookieBehavior.pbmode", 5);

// First-party isolation (alternate approach — may break some sites)
// user_pref("privacy.firstparty.isolate", true);

// State partitioning — isolate storage (localStorage, indexedDB) per top-level site
user_pref("privacy.partition.network_state", true);
user_pref("privacy.partition.serviceWorkers", true);

// ============================================================
// [PREFETCH] — Disable speculative loading
// ============================================================

// DNS prefetch — browser pre-resolves links before you click them
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);

// Speculative connections — pre-opens TCP connections to linked domains
user_pref("network.http.speculative-parallel-limit", 0);

// Link preloading (<link rel="preload"> hints)
user_pref("network.preload", false);

// Prerender / prefetch of full pages
user_pref("network.prefetch-next", false);

// ============================================================
// [REFERER] — Strip cross-origin referrer information
// ============================================================

// Cross-origin referer policy: 2 = send only origin (no path)
user_pref("network.http.referer.XOriginPolicy", 2);

// Trim referer to origin-only for cross-origin requests
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);

// ============================================================
// [TRACKING] — Enhanced Tracking Protection
// ============================================================

// ETP strict mode — blocks all known trackers, social, fingerprinting, crypto
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);

// ============================================================
// [TELEMETRY] — Disable all Mozilla data collection
// ============================================================

// Core telemetry
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);

// Crash reporting
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);

// Firefox Studies / Shield experiments
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");

// Health report
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);

// Ping Centre (usage analytics)
user_pref("browser.ping-centre.telemetry", false);

// ============================================================
// [CACHE] — Clear data on close, minimize disk exposure
// ============================================================

// Clear cookies and site data on close
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", false); // keep logins; set true for max privacy
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", false);  // keep browsing history; set true for max privacy
user_pref("privacy.clearOnShutdown.offlineApps", true);
user_pref("privacy.clearOnShutdown.sessions", true);
user_pref("privacy.clearOnShutdown.sitesettings", false);

// Disable disk cache — reduces fingerprinting surface and avoids writing decrypted
// content to disk. This is the main privacy trade-off: disk cache would be faster
// for returning visits but exposes content to forensic recovery.
user_pref("browser.cache.disk.enable", false);

// Memory cache — set to 512 MB. With no disk cache, a generous memory cache is
// the primary performance buffer for revisited assets within a session.
// Reduce this on machines with < 4 GB RAM (e.g. set to 131072 for 128 MB).
user_pref("browser.cache.memory.capacity", 524288); // 512 MB

// ============================================================
// [PERFORMANCE] — JS engine, rendering, network, GPU
//
// NOTE ON TRADE-OFFS: Some hardening prefs (letterboxing, RFP,
// OCSP hard-fail, strict DoH, no disk cache) carry measurable
// performance costs. The prefs below recover as much speed as
// possible without weakening the security model.
// ============================================================

// --- JavaScript engine ---

// Ion JIT compiler — keep enabled (disabling it is a large perf regression)
// Some hardened configs disable JIT; we do not because uBlock Origin + ETP
// already block the primary exploit delivery mechanisms that JIT enables.
user_pref("javascript.options.ion", true);
user_pref("javascript.options.baselinejit", true);
user_pref("javascript.options.native_regexp", true);

// Wasm — keep enabled (needed for modern web apps; disabling causes hangs)
user_pref("javascript.options.wasm", true);

// --- Rendering & GPU ---

// Force GPU-accelerated compositing (hardware rendering)
// This is the single biggest performance win on most machines.
user_pref("layers.acceleration.force-enabled", true);
user_pref("layers.gpu-process.enabled", true);

// WebRender — GPU-based rendering pipeline (much faster than software path)
// Enabled by default on modern hardware; force it on in case heuristics disabled it.
user_pref("gfx.webrender.all", true);
user_pref("gfx.webrender.compositor", true);
user_pref("gfx.webrender.compositor.force-enabled", true);

// Canvas acceleration — keep hardware canvas enabled for page rendering speed
// (note: canvas *readback* for fingerprinting is still blocked by RFP above)
user_pref("gfx.canvas.accelerated", true);

// Disable software fallback for WebRender
user_pref("gfx.webrender.software", false);

// --- Network ---

// HTTP/2 and HTTP/3 (QUIC) — dramatically reduce connection overhead on modern servers
user_pref("network.http.http2.enabled", true);
user_pref("network.http.http3.enabled", true);

// Pipelining — allow multiple requests over a single connection
user_pref("network.http.pipelining", true);
user_pref("network.http.proxy.pipelining", true);
user_pref("network.http.pipelining.maxrequests", 8);

// Max connections — increase parallel download capacity
user_pref("network.http.max-connections", 900);
user_pref("network.http.max-persistent-connections-per-server", 10);

// TCP Fast Open — reduces round-trips on repeat connections to same host
user_pref("network.tcp.tcp_fastopen_enable", true);

// DNS cache TTL and size — cache more DNS results longer in-memory
// Reduces the overhead of TRR (encrypted DNS) lookups on repeat navigations
user_pref("network.dnsCacheEntries", 1000);
user_pref("network.dnsCacheExpiration", 3600);        // 1 hour
user_pref("network.dnsCacheExpirationGracePeriod", 240);

// TRR (DoH) connection count — allow more parallel encrypted DNS queries
user_pref("network.trr.max-fails", 5);

// --- Process model ---

// Content processes — more processes = better tab isolation and parallelism
// Default is 8; setting higher helps on machines with many cores/RAM.
// Do not set above 8 on machines with < 8 GB RAM.
user_pref("dom.ipc.processCount", 8);

// Background process priority — de-prioritize background tabs to free CPU
user_pref("dom.ipc.processPriorityManager.backgroundUsesEcoQoS", true);
user_pref("browser.tabs.unloadOnLowMemory", true);

// --- Paint & layout ---

// Reduce paint throttling delay in background tabs (faster tab switching)
user_pref("nglayout.initialpaint.delay", 0);
user_pref("nglayout.initialpaint.delay_in_oopif", 0);

// Increase layout flush frequency (smoother rendering on fast machines)
user_pref("layout.frame_rate", 60);

// --- Session restore ---

// Reduce sessionstore write frequency (default 15s) to lower I/O overhead
user_pref("browser.sessionstore.interval", 30000); // 30 seconds

// ============================================================
// [MEDIA] — Autoplay, DRM
// ============================================================

// Block autoplay by default (audio and video)
user_pref("media.autoplay.default", 5); // 0=allow, 1=block-audio, 5=block-all
user_pref("media.autoplay.blocking_policy", 2);

// ============================================================
// [UI] — userChrome, toolbar, compact mode
// ============================================================

// Required to load userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Enable compact density mode
user_pref("browser.uidensity", 1);

// Disable accessibility services (reduces attack surface)
user_pref("accessibility.force_disabled", 1);

// Disable about:newtab sponsored content
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);

// ============================================================
// [SEARCH] — Default search, address bar behavior
// ============================================================

// Do not send search queries to Google for suggestions (uses DuckDuckGo)
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);

// Disable search suggestions in private windows
user_pref("browser.search.suggest.enabled.private", false);

// ============================================================
// [EXTENSIONS] — Extension security
// ============================================================

// Block extensions from running on extension store pages
user_pref("extensions.webextensions.restrictedDomains", "accounts-static.cdn.mozilla.net,accounts.firefox.com,addons.cdn.mozilla.net,addons.mozilla.org,api.accounts.firefox.com,content.cdn.mozilla.net,discovery.addons.mozilla.org,install.mozilla.org,oauth.accounts.firefox.com,profile.accounts.firefox.com,support.mozilla.org,sync.services.mozilla.com");

// ============================================================
// [MISC]
// ============================================================

// Disable Firefox Sync (no cloud account needed for a local privacy build)
// Remove the two lines below if you use Firefox Sync intentionally
user_pref("identity.fxaccounts.enabled", false);

// Disable Safe Browsing check-ins (it phones Google; uBlock Origin covers this)
// WARNING: Safe Browsing also blocks malware downloads. uBlock + ClearURLs compensate.
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);

// Disable pocket integration
user_pref("extensions.pocket.enabled", false);

// Disable Firefox screenshots
user_pref("extensions.screenshots.disabled", true);