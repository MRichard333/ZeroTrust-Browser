// ============================================================
//  ZeroTrust Browser — user.js
//  Maximum security + privacy hardening for Firefox
//  Mountain OS / mrichard333.com
//
//  Extension ID confirmed: zerotrust@mrichard333.com
//  Firefox minimum supported: 140 (current stable: 148)
// ============================================================


// ── STARTUP ─────────────────────────────────────────────────
// Pipe-separated URLs = multiple tabs on startup
user_pref("browser.startup.homepage", "https://mrichard333.com/webtools|https://mrichard333.com/dashboard|https://mrichard333.com/link-scanner");
user_pref("browser.startup.page", 1);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtabpage.activity-stream.enabled", false);
// NOTE: browser.newtab.url is dead since FF41 — do not use.
//       New tab override requires a WebExtension (zerotrust-newtab.xpi).


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
user_pref("security.tls.version.min", 3);                      // TLS 1.2 minimum (3=TLS1.2)
user_pref("security.tls.version.max", 4);                      // TLS 1.3 maximum
user_pref("security.tls.enable_0rtt_data", false);             // disable 0-RTT (replay attack risk)
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("browser.xul.error_pages.expert_bad_cert", true);
user_pref("security.OCSP.enabled", 1);
user_pref("security.OCSP.require", true);
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.pki.crlite_mode", 2);


// ── DNS OVER HTTPS (strict — no system DNS fallback) ─────────
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
// 5 = reject trackers + partition all 3rd-party (best modern setting)
user_pref("network.cookie.cookieBehavior", 5);
user_pref("network.cookie.lifetimePolicy", 0);
user_pref("network.cookie.thirdparty.sessionOnly", true);
user_pref("network.cookie.thirdparty.nonsecureSessionOnly", true);


// ── FINGERPRINTING ───────────────────────────────────────────
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.resistFingerprinting.block_mozAddonManager", true);
user_pref("privacy.fingerprintingProtection", true);           // FF114+ supplemental engine
user_pref("browser.display.use_system_colors", false);
user_pref("browser.link.open_newwindow", 3);
user_pref("browser.link.open_newwindow.restriction", 0);


// ── WEBRTC — fully disabled to prevent IP leaks ─────────────
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
// Local lists on, remote lookups off (privacy)
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
user_pref("privacy.userContext.enabled", true);                // containers
user_pref("privacy.userContext.ui.enabled", true);


// ── UI ───────────────────────────────────────────────────────
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);