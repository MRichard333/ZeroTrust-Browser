// ============================================================
//  ZeroTrust Browser — user.js
//  Maximum security + privacy hardening for Firefox
//  Dark Matrix theme / Mountain OS / mrichard333.com
//
//  Extension ID: zerotrust@mrichard333.com
//  Firefox minimum supported: 109
// ============================================================


// ── STARTUP ─────────────────────────────────────────────────
// Open the ZeroTrust new tab page on startup (same as new tab)
// browser.startup.page 3 = restore previous session; we use
// page 0 (blank) + the newtab extension handles the display.
user_pref("browser.startup.page", 0);                          // 0 = blank/newtab on startup
user_pref("browser.newtabpage.enabled", true);                 // let the extension take over new tab
user_pref("browser.newtabpage.activity-stream.enabled", false);


// ── DEFAULT SEARCH ENGINE — DuckDuckGo ──────────────────────
// Sets DDG as the default. The policies.json SearchBar pref keeps
// the search bar unified with the URL bar.
user_pref("browser.search.defaultenginename", "DuckDuckGo");
user_pref("browser.search.selectedEngine", "DuckDuckGo");
user_pref("browser.urlbar.placeholderName", "DuckDuckGo");
user_pref("browser.search.suggest.enabled", true);             // keep suggestions
user_pref("browser.urlbar.suggest.searches", true);


// ── AUTO-CLEAR NON-IMPORTANT DATA (every 24h) ────────────────
// Firefox's built-in sanitize-on-shutdown clears data when the
// browser closes. We pair it with a 24h idle-triggered clear via
// privacy.sanitize.timeSpan so stale data never lingers.
//
// What IS cleared (non-important / fingerprinting risk):
//   cache, offlineApps, siteSettings, sessions (temp), downloads log
// What is NOT cleared (important / user would lose):
//   passwords, bookmarks, formHistory, history (kept for convenience)

user_pref("privacy.sanitize.sanitizeOnShutdown", true);

// Items cleared on shutdown
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", false);           // keep — would log you out everywhere
user_pref("privacy.clearOnShutdown.downloads", true);          // clear download list (not files)
user_pref("privacy.clearOnShutdown.formdata", false);          // keep — useful autofill
user_pref("privacy.clearOnShutdown.history", false);           // keep — user preference
user_pref("privacy.clearOnShutdown.offlineApps", true);        // clear offline/PWA storage
user_pref("privacy.clearOnShutdown.sessions", true);           // clear active login sessions
user_pref("privacy.clearOnShutdown.siteSettings", false);      // keep — user's per-site perms
user_pref("privacy.clearOnShutdown.openWindows", false);       // keep — don't kill open tabs

// New Firefox 128+ clearOnShutdown_v2 keys (same intent, new namespace)
user_pref("privacy.clearOnShutdown_v2.cache", true);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
user_pref("privacy.clearOnShutdown_v2.downloads", true);
user_pref("privacy.clearOnShutdown_v2.formData", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.siteSettings", false);

// Time span for manual/timed clears: 5 = last 24 hours
user_pref("privacy.sanitize.timeSpan", 5);

// Clear third-party storage after 24h of no interaction (FF117+)
user_pref("network.cookie.thirdparty.sessionOnly", true);
user_pref("privacy.purge_trackers.enabled", true);
user_pref("privacy.purge_trackers.max_age_in_days", 1);        // purge tracker storage after 1 day


// ── DARK THEME ───────────────────────────────────────────────
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("browser.theme.content-theme", 0);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("devtools.theme", "dark");


// ── TELEMETRY & DATA COLLECTION ─────────────────────────────
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.server", "");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);


// ── POCKET & SPONSORED CONTENT ──────────────────────────────
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.default.sites", "");
user_pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.suggest.pocket", false);


// ── HARDWARE ACCELERATION ───────────────────────────────────
user_pref("gfx.webrender.all", true);
user_pref("media.hardware-video-decoding.enabled", true);
user_pref("layers.acceleration.force-enabled", true);
user_pref("gfx.canvas.azure.accelerated", true);
user_pref("webgl.disabled", false);
user_pref("webgl.enable-webgl2", true);


// ── HTTPS & TLS ─────────────────────────────────────────────
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_ever_enabled", true);
user_pref("dom.security.https_only_mode_pbm", true);
user_pref("security.ssl.require_safe_negotiation", true);
user_pref("security.tls.version.min", 3);
user_pref("security.tls.version.max", 4);
user_pref("security.tls.enable_0rtt_data", false);
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("browser.xul.error_pages.expert_bad_cert", true);
user_pref("security.OCSP.enabled", 1);
user_pref("security.OCSP.require", true);
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.pki.crlite_mode", 2);


// ── DNS OVER HTTPS (strict) ──────────────────────────────────
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");
user_pref("network.trr.bootstrapAddress", "1.1.1.1");
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);


// ── TRACKING PROTECTION ──────────────────────────────────────
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("privacy.partition.network_state.ocsp_cache", true);
user_pref("privacy.partition.serviceWorkers", true);
user_pref("privacy.partition.always_partition_third_party_non_cookie_storage", true);
user_pref("privacy.partition.always_partition_third_party_non_cookie_storage.exempt_sessionstorage", false);


// ── COOKIES ──────────────────────────────────────────────────
user_pref("network.cookie.cookieBehavior", 5);
user_pref("network.cookie.lifetimePolicy", 0);
user_pref("network.cookie.thirdparty.sessionOnly", true);
user_pref("network.cookie.thirdparty.nonsecureSessionOnly", true);


// ── FINGERPRINTING ───────────────────────────────────────────
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.resistFingerprinting.block_mozAddonManager", true);
user_pref("privacy.fingerprintingProtection", true);
user_pref("browser.display.use_system_colors", false);
user_pref("browser.link.open_newwindow", 3);
user_pref("browser.link.open_newwindow.restriction", 0);


// ── WEBRTC — fully disabled ──────────────────────────────────
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);
user_pref("media.peerconnection.ice.default_address_only", true);


// ── REFERER POLICY ───────────────────────────────────────────
user_pref("network.http.referer.XOriginPolicy", 2);
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);
user_pref("network.http.referer.defaultPolicy", 2);
user_pref("network.http.referer.defaultPolicy.pbmode", 2);


// ── PREFETCH & SPECULATIVE CONNECTIONS ───────────────────────
user_pref("network.prefetch-next", false);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.places.speculativeConnect.enabled", false);


// ── GEOLOCATION & SENSORS ────────────────────────────────────
user_pref("geo.enabled", false);
user_pref("geo.provider.use_gpsd", false);
user_pref("geo.provider.use_geoclue", false);
user_pref("permissions.default.geo", 2);
user_pref("device.sensors.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("dom.gamepad.enabled", false);
user_pref("dom.vr.enabled", false);
user_pref("dom.vibrator.enabled", false);


// ── CAMERA / MICROPHONE ──────────────────────────────────────
user_pref("permissions.default.camera", 2);
user_pref("permissions.default.microphone", 2);
user_pref("camera.control.face_detection.enabled", false);


// ── SAFE BROWSING ────────────────────────────────────────────
user_pref("browser.safebrowsing.malware.enabled", true);
user_pref("browser.safebrowsing.phishing.enabled", true);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", true);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", true);


// ── MISC SECURITY ────────────────────────────────────────────
user_pref("browser.send_pings", false);
user_pref("dom.event.clipboardevents.enabled", false);
user_pref("beacon.enabled", false);
user_pref("network.allow-experiments", false);
user_pref("security.dialog_enable_delay", 1000);
user_pref("privacy.userContext.enabled", true);
user_pref("privacy.userContext.ui.enabled", true);


// ── UI ───────────────────────────────────────────────────────
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);