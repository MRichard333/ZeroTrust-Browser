// ============================================================
//  Mountain OS — Firefox Profile Configuration (user.js)
//  Auto-loaded by Firefox on startup from the profile folder.
// ============================================================


// ── HOMEPAGE & NEW TAB ──────────────────────────────────────
user_pref("browser.startup.homepage", "https://mrichard333.com/webtools");
user_pref("browser.startup.page", 1);                          // 1 = homepage on startup
user_pref("browser.newtabpage.enabled", false);                // disable default new tab page
user_pref("browser.newtab.url", "https://mrichard333.com/webtools");
user_pref("browser.newtabpage.activity-stream.enabled", false);


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


// ── HARDWARE ACCELERATION ───────────────────────────────────
user_pref("gfx.webrender.all", true);                          // enable WebRender compositor
user_pref("media.hardware-video-decoding.enabled", true);      // GPU video decoding
user_pref("layers.acceleration.force-enabled", true);          // force GPU layers
user_pref("gfx.canvas.azure.accelerated", true);
user_pref("webgl.disabled", false);                            // keep WebGL on
user_pref("webgl.enable-webgl2", true);


// ── PRIVACY & SECURITY HARDENING ────────────────────────────
// Tracking protection
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.firstparty.isolate", true);

// Cookies
user_pref("network.cookie.cookieBehavior", 1);                 // block third-party cookies
user_pref("network.cookie.lifetimePolicy", 0);

// DNS over HTTPS
user_pref("network.trr.mode", 2);                              // DoH with fallback
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");

// Fingerprinting & WebRTC leak prevention
user_pref("privacy.resistFingerprinting", true);
user_pref("media.peerconnection.ice.no_host", true);           // prevent local IP leak via WebRTC

// Referer policy
user_pref("network.http.referer.XOriginPolicy", 2);            // send referer only on same origin
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);    // trim to origin only

// Safe browsing (keep malware protection, disable Google reporting)
user_pref("browser.safebrowsing.malware.enabled", true);
user_pref("browser.safebrowsing.phishing.enabled", true);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);

// Misc
user_pref("dom.security.https_only_mode", true);               // HTTPS-only mode
user_pref("security.ssl.require_safe_negotiation", true);
user_pref("browser.send_pings", false);                        // disable hyperlink auditing
user_pref("geo.enabled", false);                               // disable geolocation
user_pref("permissions.default.geo", 2);
user_pref("camera.control.face_detection.enabled", false);
