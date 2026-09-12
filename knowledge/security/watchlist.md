# Watchlist — Tracked Vulnerabilities

Platform flaws monitored across engagements. Update the `Status` and `Last checked` fields as intelligence changes. Verified against vendor advisories and NVD before entering this table.

| ID | Product | Type | Sev | Affected range | Exploited | Fix / mitigation |
|---|---|---|---|---|---|---|
| CVE-2026-75650 | Magento / Adobe Commerce (StyleSmuggler) | Unauth RCE via template engine | 10.0 | Magento OS 2.4.6–2.4.9 (incl. `2026-aug` builds); Adobe Commerce / B2B 1.3.3–1.5.3 | **Yes — KEV, since 2026-09-04** | Adobe hotfix **VULN-39341** (APSB26-146); rotate credentials. Interim: disable GraphQL (breaks headless) |
| CVE-2025-54236 | Magento / Adobe Commerce (SessionReaper) | Account takeover / unauth RCE via REST | 9.1 | Adobe Commerce, Commerce B2B, Magento OS; Custom Attributes Serializable 0.1.0–0.4.0 | Yes | Adobe hotfix; upgrade Custom Attributes Serializable ≥ 0.4.0 |
| CVE-2024-34102 | Magento (CosmicSting) | XXE via GraphQL → unauth RCE | 9.8 | Pre-2.4.7-p1 lines (APSB24-40) | Yes | APSB24-40 patch |
| PolyShell | Magento REST API | Unauth file upload → RCE | high | All ≤ 2.4.9-alpha2 | Yes (defacement campaign) | Restrict upload dir; web server rules |
| CVE-2024-23897 | Jenkins | CLI path traversal / arbitrary file read (unauth) | 9.8 | ≤ 2.441 · LTS ≤ 2.426.2 | **Yes — KEV** | Upgrade ≥ 2.442 / LTS ≥ 2.426.3; restrict CLI/remoting |
| CVE-2024-43044 | Jenkins | Agent arbitrary file read | high | ≤ 2.470 · LTS ≤ 2.452.3 | — | Upgrade ≥ 2.471 / LTS ≥ 2.452.4 |
| CVE-2023-39151 | Jenkins | Stored XSS in build logs | med | ≤ 2.415 · LTS ≤ 2.401.2 | — | Upgrade |
| CVE-2024-0402 | GitLab | Arbitrary file write via workspace (auth) | 9.9 | 16.0–<16.5.8, 16.6–<16.6.6, 16.7–<16.7.4, 16.8–<16.8.1 | — | Fixed in 16.8.1 — **16.8.1 is the fix, not the flaw** |
| Evolution API 2.3.7 | Evolution API (WhatsApp) | Cross-instance authorization bypass (CWE-639) | high | ≤ 2.3.7 | — | Upgrade ≥ 2.4.0 (fix PR #2549); restrict manager/API by IP; rotate keys |
| CVE-2026-32475 | Elementor Pro | Unauth file upload → RCE (CWE-434) | 9.0 | Elementor Pro ≤ 4.2.1 | No (as of 2026-09-12) | Upgrade ≥ 4.2.2; disable Form widgets with File Upload |
| CVE-2026-17585 | Royal Addons for Elementor | Unauth sensitive info exposure via `wpr_keyword` postmeta oracle | med (5.3) | Royal Addons ≤ 1.7.1066 | No | **No patch (2026-09-12)**; remove/disable plugin until fixed |
| CVE-2026-13405 | Royal Addons for Elementor | Admin+ RCE via Widget Builder (multisite) | high | Royal Addons < 1.7.1066 | — | Upgrade ≥ 1.7.1066 |
| CVE-2026-19226 | Royal Addons for Elementor | Contributor+ stored XSS (Image Accordion effect) | med (6.8) | Royal Addons < 1.7.1066 | — | Upgrade ≥ 1.7.1066 |
| CVE-2026-18039 | Essential Addons for Elementor (Lite) | Unauth privilege escalation via profile-field mass assignment | high (8.1) | Essential Addons < 6.7.2 | — | Upgrade ≥ 6.7.2 |
| CVE-2026-12141 | Premium Addons for Elementor | Contributor+ stored XSS (`premium_tooltip_text`) | med (4.9) | Premium Addons ≤ 4.11.84 | — | Upgrade > 4.11.84 |
| CVE-2026-5934 | WP Rocket | Unauth stored XSS via `rocket_beacon` AJAX | med | WP Rocket ≤ 3.21.0.1 | — | Upgrade ≥ 3.21.1 |

## Version traps

- A patch level can carry the fix for one CVE while still being exposed to a newer out-of-band hotfix (Magento `2.4.7-p10` requires VULN-39341 for StyleSmuggler).
- The latest patch of a branch is not proof of safety — verify against the specific advisory, not the version string alone.
- Distribution-level security patches (e.g. Linux distro backports) do not map cleanly to upstream version ranges. Check the distro advisory too.
- A plugin's `readme.txt` Stable tag can lag the shipped code. The authoritative version is the plugin's own asset URL (`?ver=`) and the banner inside its minified JS — cross-check both before mapping a CVE.
- A bundled dependency's version string (e.g. `royal-elementor-addons/assets/js/lib/particles/particles.js?ver=3.0.6`) is not the plugin's version. Attributing it as the plugin version produces a false match.
- The fix version can sit immediately above the affected ceiling (Elementor Pro 3.30.0 vs fix 4.2.2; Royal Addons 1.7.1065 vs fix 1.7.1066). Read the patch level, not the major.

## Platform notes

- **Headless Magento / PWA**: depends on GraphQL, so the StyleSmuggler interim mitigation (disable GraphQL) is usually unavailable — treat as higher exposure.
- **Magento hosting (`*.magehub.com.br`, Magehub/Mageshop)**: multi-tenant Magento; a compromise can threaten neighbours → supply-chain relevance.
- **WordPress 7.1**: changed how hook callback IDs are built (string → int under some conditions); caching plugins that call `substr()` on them (WP Rocket < 3.23.2.2, fixed 2026-08-20) throw a fatal error. Treat a core-major jump as an availability review, not only a CVE review.
- **WordPress MCP adapter**: the `mcp` REST namespace exposes `POST/GET/DELETE /mcp/mcp-adapter-default-server` and `/mcp/mcp-oauth-server` — an agent/tool-execution surface to inventory separately from content APIs.
- **Evolution API ≥ 2.4.0**: requires license activation; an unlicensed deployment returns `503 LICENSE_REQUIRED` on business routes (license/manager/health stay public).
