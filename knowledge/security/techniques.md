# Techniques — Tested Recipes

Reusable, read-only-first techniques confirmed to work during real engagements. Each entry states the goal, the command, and how to read the result.

## Passive reconnaissance

- **Enumerate subdomains via Certificate Transparency.** `crt.sh` and Cert Spotter cross-check each other; either may be rate-limited or flaky.
  - `curl -s "https://crt.sh/?q=%25.<domain>&output=json"` — parse `name_value`.
  - `curl -s "https://api.certspotter.com/v1/issuances?domain=<domain>&include_subdomains=true&expand=dns_names"`
- **Discover correlated domains by certificate organization.** `curl -s "https://crt.sh/?O=<ORG>&output=json"` returns certificates whose subject organization matches; parse `.common_name` for the domains. This surfaces sibling domains that share no brand string (sibling domains of the group). Confirm each with WHOIS registrant/CNPJ and a shared MX before any request.
- **DNS and mail posture.** `dig +short NS/MX/TXT/AAAA/CAA <domain>` and `dig +short TXT _dmarc.<domain>`. A DMARC `p=none` permits spoofing; `p=reject` enforces.
- **TLS fingerprint.** `echo | openssl s_client -connect <host>:443 -servername <host> 2>/dev/null | openssl x509 -noout -subject -issuer -dates`.
- **HTTP fingerprint.** `curl -sS -D - -o /dev/null https://<host>/` — server, CDN, security headers, cookie flags, redirect chain, framework hints (`x-redirect-by`, `x-magento-*`, `x-powered-by`, `X-Jenkins`).

- **Distinguish GoDaddy Managed WordPress from a standalone Cloudflare proxy.** A host behind GoDaddy's
  managed-WP edge returns `server: cloudflare` + `cf-ray` **and** `x-gateway-cache-*`/`x-gateway-request-id`
  headers, with a GoDaddy DV certificate and rDNS `*.secureserver.net`. Do not read this as a user-provisioned
  Cloudflare WAF; the origin is GoDaddy itself.

## Version discovery

- **Magento version via setup page.** `GET /setup/` often exposes `Magento Version X.Y.Z-pN`.
- **Jenkins version via header.** `X-Jenkins: <version>` on any response, including `403`.
- **GitLab version via page data.** The `gon` JSON on `/help` or the sign-in page carries `gitlab_version` `{major, minor, patch}`.
- **WordPress hardening probe.** `GET /wp-json/wp/v2/users` (401/403 = hardened), `/xmlrpc.php` (403 = hardened), `/wp-login.php` (404 = hidden).

## Attack-surface probes (read-only)

- **Exposed setup / docs / APIs.** Probe `/setup/`, `/graphql`, `/rest/V1/`, `/api/documentation`, `/docs`, `/.env`, `/.git/config`, `/app/etc/env.php`, `/*.sql`, backup paths. Record status and headers.
- **GraphQL introspection.** `POST /graphql` with `{"query":"{__schema{queryType{name}}}"}` — a JSON `data.__schema` response means introspection is enabled (aids attackers; the interim mitigation for template/GraphQL flaws is not applied).
- **Open registration (do not create an account).** `GET /users/sign_up` — a rendered form with fields is evidence of a public form; whether it yields access requires an authorized test.
- **Cookie flags.** `Set-Cookie` attributes: `Secure`, `HttpOnly`, `SameSite`. Absence of `Secure`/`HttpOnly` on a session cookie is a finding.
- **Leak the origin through the app's own redirect.** A reverse proxy misconfigured to **redirect** (not proxy) an internal path hands out the backend hostname. Request server-side routes without following redirects (`curl -sS -D - -o /dev/null https://<host>/api/`); a `301`/`302` whose `Location` is an internal name (`*.elb.amazonaws.com`, a private IP, an `http://` URL) discloses the origin. Then: `dig` it, confirm reachability with **one** read-only `GET`/`HEAD`, and check `443` (a refused 443 with a `200` on port 80 = CDN/WAF bypass over plaintext). Probe the leaked origin's sensitive paths (`/api`, `/admin`, `/server/*`) **before** rating severity — if they `404` on the origin, the impact is limited to public content.

## Supply-chain OSINT

- Extract vendor hosts from page source (`src`/`href`), answer headers, and DNS; identify platform, payments, marketing, CDN, hosting.
- For each vendor, map platform/version and check the watchlist + vendor advisories. Third parties are OSINT-only.

## Supabase-backed single-page apps

- **Find the backend.** Grep the JS bundle for `*.supabase.co`, `createClient`, and key patterns. A `sb_publishable_…` (or legacy `eyJ…` anon) key is public by design — the risk is RLS, not the key. A `sb_secret_…` key in a bundle is a critical finding.
- **Check the auth policy.** `GET /auth/v1/settings` with the public key shows `disable_signup`, `mailer_autoconfirm`, and enabled providers.
- **Measure RLS without reading rows.** `HEAD /rest/v1/<table>?select=id&limit=1` with `Prefer: count=exact`; the `content-range` header reveals whether the public key can read. `*/0` = RLS blocks anonymous; `0-N/N` with N>0 = exposed.
- **REST schema root.** `GET /rest/v1/` may return `401 {"message":"Secret API key required"}` (new Supabase behavior) — that is hardening, not a finding.
- **Edge functions.** Live at `<project>.supabase.co/functions/v1/<name>`, not on the app domain. Probe with `OPTIONS`/`GET`; an unauthenticated `GET` returning `401` confirms auth is enforced.
- **Extract tables/RPCs from the bundle.** Grep for `` .from(`table`) ``, `.select(`, `.rpc(` — this reveals the real data model to target with the RLS check.
- **Find storage buckets and test them unauthenticated.** Grep for `.storage.from(` to get bucket names, then `POST /storage/v1/object/list/<bucket>` and the `/storage/v1/object/public/<bucket>/<file>` URL with no auth — a public bucket lists and downloads.
- **Test tenant isolation via a writable tenant column.** If `profiles.organization_id` (or similar) is user-writable, read the target tenant id from a readable table (`projects.organization_id`), PATCH it onto your own row, and re-count the tenant-scoped table. Revert afterward.
- **Re-establish a Supabase session by password recovery without touching the password.** `POST /auth/v1/recover` sends a reset mail; read the message from a public inbox (`https://www.mailinator.com/api/v2/domains/public/inboxes/<inbox>`, then `/messages/<id>`), extract the `/auth/v1/verify?token=<hash>&type=recovery` link, and `GET` it: a `303` `Location` carries `#access_token=…&refresh_token=…`. Use the token directly; do not `PUT /auth/v1/user` or submit a guessed password.
- **Test the bucket the app actually uses, not the one you guess.** Grep the bundle for `storage.from(` (literal or a variable like `` gN=`<bucket-name>` ``) and for per-tenant upload path prefixes. A private `attachments` bucket can hide a second, differently-scoped bucket that the tenant hop opens.
- **Prove a storage write path without a persistent URL.** `POST /storage/v1/object/list/<bucket>` with `{"prefix":"","limit":1000}` enumerates folders; `POST /storage/v1/object/sign/<bucket>/<path>` with `{"expiresIn":60}` returns a `signedURL`; a ranged/`HEAD` `GET` of it confirms content type and size with minimal transfer.

## Next.js applications

- **Map the auth model.** A `307`/`302` to `/login` on every route means middleware auth. NextAuth exposes `/api/auth/providers`, `/api/auth/csrf`, `/api/auth/session` publicly — `/api/auth/signin/<provider>` returning `?error=Configuration` means the provider is misconfigured (no client id/secret).
- **Test the middleware bypass (CVE-2025-29927).** Add `x-middleware-subrequest` header (`middleware`, `middleware:middleware:middleware:middleware:middleware`, `pages/middleware`, `src/middleware`) to a protected route; a `200` instead of the redirect is a bypass. A repeated `307` means it is not applicable.
- **Server Actions.** Grep the bundle for `createServerReference("<id>",…,"<name>Action")` to get action IDs. Actions are invoked with `POST <page>` + `Next-Action: <id>`; a foreign `Origin` should be rejected — verify CSRF handling.

## JavaScript bundles and client config

- **Extract the embedded dependency manifest from a Vite bundle.** Vite apps often inline `package.json` (a JSON object with `"name"`/`"dependencies"`). Grep for `"dependencies":{` or a known dependency (`react-router`, `axios`); the surrounding object gives exact semver ranges for advisory correlation. A CRA bundle usually has none.
- **Detect development config shipped to production.** Grep the bundle for `production:!1`, `production:false`, `localhost:`, and `redirectUri`. An Angular `environment` object with `apiUrl:"http://localhost:8080/api"` and an MSAL `redirectUri:"http://localhost:4200"` inside a production bundle is a misconfiguration finding.
- **Decode any JWT found in a bundle before rating it.** Base64url-decode the payload and read `iss`, `exp`, `client_name`, and the claims. `iss: https://authsandbox.<vendor>` with a sample merchant ("Loja Exemplo") and a past `exp` is a sandbox artifact, not a live secret — rate it as a pattern risk, not a high.
- **Confirm a bucket is private with a HEAD.** `curl -sS -I https://<bucket>.s3.amazonaws.com/` — `403` = exists and denies anonymous access; `404` = name free. HEAD carries no body, so no object keys leak.
- **Classify a Firebase web API key without touching data.** The web key is public by design. Grep the bundle for `firestore|getDatabase|firebase/auth`; if absent, only analytics/messaging is used. `GET https://identitytoolkit.googleapis.com/v1/projects?key=<key>` returning `400` shows Auth/Identity Toolkit is not enabled.
- **An SPA's client routes are not HTTP-verifiable.** Every path returns the same shell (200); read route existence from the bundle, not per-route status. Probe the backend route (not the SPA) with `OPTIONS`/`HEAD`: `401` = exists and requires auth, `404` on HEAD = POST-only route.
- **Read session-token storage from the bundle.** Grep for `document.cookie` set calls and `localStorage.setItem`. A cookie set from JS has no `HttpOnly`; note `SameSite`/`Secure` and whether the token is copied into an `Authorization` header.

## Public object storage (Cloud Storage / S3)

- **Detect an anonymously listable bucket from its host header.** A CDN subdomain that answers `GET /` with `server: UploadServer` and an XML `ListBucketResult` body is a Google Cloud Storage bucket with public listing. The `<Name>` element gives the bucket name; `<IsTruncated>true</IsTruncated>` means more objects exist (paginate with `Marker`/`NextMarker` only if authorized — one page proves the misconfiguration).
- **Triage the exposure before rating it.** Read the returned XML only (no object download). Public marketing assets (`banners/`, `email/`, `*.pdf` training) make the finding about *enumeration*, not data loss — rate moderate, not high. Namespaces named `int-`, `-dev`, `staging` raise it: listing is never needed for CDN operation.
- **The bucket name outlives the hostname.** Note the bucket name from `<Name>` — the same bucket can later be referenced by a different hostname, and the fix (remove `allUsers` from bucket IAM) is per bucket, not per host.
- **An expired TLS cert does not block GCS access.** When a `dev.cdn`-style host fails validation, `curl -k` (one request) still reveals whether the bucket is public.

## Legacy TLS on modern OpenSSL

- **`openssl s_client -tls1` fails with `no protocols available` on OpenSSL 3.x.** TLS 1.0/1.1 are disabled at the default security level. Force them with `-cipher 'DEFAULT@SECLEVEL=0'`.
- **Do NOT read `Protocol: TLSv1.1` as success.** On a rejected handshake, `s_client` still prints the *requested* protocol. A legacy protocol is accepted only when the output contains `SSL-Session:` **and** no `alert protocol version`. Grepping for `Protocol:` alone produces false positives on every host.
- **macOS has no `timeout`.** Use a plain pipe (`echo | openssl s_client …`) or `gtimeout`; a missing `timeout` makes the probe return empty and silently reports "no TLS".

## Certificate and redirect hygiene

- **A wildcard cert whose CN belongs to a different domain is a delegation signal.** `CN=*.agency-domain` with SAN including the target's wildcard (`*.target.tld`) means the target's wildcard is issued inside a third party's ACM/CA account. Report it as an ownership/dependency observation, not a vulnerability.
- **Read SANs for internal naming.** A public cert often carries `*.int.gcp.<corp>`, `*.gke2.ope.<corp>`, or an internal IdP host — inventory the internal naming printed on public certificates.
- **`X-Frame-Options: ALLOW-FROM <uri>` is dead.** Modern browsers ignore it (no clickjacking protection). Report it as a finding, separate from the host's CSP.
- **An empty CSP directive protects nothing.** `frame-ancestors;` (no value) is invalid and ignored. An empty directive is a fix, not a control.

## Database functions and RPCs

- **Test RPC authorization with a non-existent UUID, never a real record.** Call the function with the correct argument names (read them from the bundle call site, e.g. `<rpc_name>({<arg_name>})`). A `23503` foreign-key error is positive proof the function **passed the authorization check and reached the write**; a `42501`/`P0001` authorization error means a role check exists. The random id guarantees no row is created.
- **Read the parameter names from the bundle.** Grep `` .rpc(`name`,{ `` to see the exact named parameters, or PostgREST returns `PGRST202` for the wrong signature.

- **Surface decommissioned subdomains via Wayback CDX.** `curl "http://web.archive.org/cdx/search/cdx?url=<domain>&matchType=domain&output=json&fl=original&collapse=urlkey&limit=5000"` and collect the host part of every URL. This reveals hostnames that CT/DNS brute-force miss because they no longer resolve (NXDOMAIN) — e.g. a legacy HR portal that was once public. Then `dig` each to confirm current NXDOMAIN and, if reachable, treat it as an in-scope asset.
- **Rails/Webpacker source maps via the manifest.** `GET /packs/manifest.json` lists the compiled bundles *and* their `.js.map` files. If a `.map` is served, download it and grep the `sourcesContent` for secrets and internal hostnames. Presence of the map is a finding (source exposure); absence of secrets does not remove the finding — verify both before rating.

## Rules of engagement for every technique

- `GET`/`HEAD` only unless an authorized active test says otherwise. No credentials, no bodies, no mutations.
- One request per probe; never mass-scan. Rate-limit any active test and respect the agreed window.
- Cross-check a version with a second source before attributing a CVE.
