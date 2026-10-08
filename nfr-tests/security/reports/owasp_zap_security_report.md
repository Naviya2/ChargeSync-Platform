# 🛡️ OWASP ZAP Security Evaluation Report
**Project:** ChargeSync – Intelligent EV Charging Reservation and Recommendation Platform  
**Target Environments:**  
- **ASP.NET Core Web API:** `http://localhost:5035`  
- **React Web Portal:** `http://localhost:5173`  
- **Database:** Local PostgreSQL (`ChargeSync-Test` on `localhost:5432`)  
**Scan Timestamp:** 2026-10-08 11:04:08  
**Evaluation Standard:** OWASP Top 10 (2021) & OWASP API Security Top 10 (2023)  

---

## 1. Executive Summary

| Metric | Value |
|---|---|
| **Total Security Checks Executed** | **16** |
| **Checks Passed** | **10** (62.5%) |
| **Active Defects (Failed)** | **0** |
| **Security Advisories / Warnings** | **6** |
| **Scan Execution Duration** | **1.76 seconds** |

### Alert Summary by Risk Severity

| Severity Level | Alert Count | Definition |
|---|:---:|---|
| **Critical** | **0** | Direct system compromise, remote code execution, authentication bypass |
| **High** | **0** | Sensitive data breach, direct privilege escalation |
| **Medium** | **3** | Missing Content-Security-Policy, X-Frame-Options clickjacking advisory |
| **Low / Informational** | **3** | Server header banner disclosure, rate-limiting tuning advisory |

---

## 2. Test Execution Matrix

| Test ID | Category | Name | ZAP Plugin ID | Risk | Status | Result / Observation |
|---|---|---|:---:|:---:|:---:|---|
| **SEC-HDR-01** | Security Headers | X-Content-Type-Options Header Missing | `10021` | **Low** | ⚠️ Warning | X-Content-Type-Options header is missing. Browsers may attempt to MIME-sniff response content. |
| **SEC-HDR-02** | Information Disclosure | Server Version / Banner Disclosure | `10055` | **Low** | ⚠️ Warning | Server discloses web server technology via 'Server: Kestrel'. Attackers can fingerprint the host. |
| **SEC-HDR-03** | Security Misconfiguration | Cross-Domain CORS Misconfiguration | `10098` | **Medium** | ⚠️ Warning | CORS policy reflects arbitrary origins or uses wildcard: '*'. Sensitive data may be accessible cross-origin. |
| **SEC-HDR-04** | Security Headers | Content-Security-Policy (CSP) Missing | `10038` | **Medium** | ⚠️ Warning | Content-Security-Policy header is missing on frontend. Recommended to restrict inline script execution and XSS vectors. |
| **SEC-HDR-05** | Security Headers | X-Frame-Options Clickjacking Protection | `10020` | **Medium** | ⚠️ Warning | X-Frame-Options header missing. The application could be embedded in an iframe on third-party sites. |
| **SEC-AUTH-01** | Broken Authentication | Invalid Credentials Rejection | `90034` | **High** | ✅ Pass | System strictly rejects incorrect authentication credentials without revealing specific reason. |
| **SEC-AUTH-02** | Broken Authentication | JWT 'alg: none' Signature Bypass Resistance | `90034` | **Critical** | ✅ Pass | ASP.NET Core JWT middleware strictly validates digital HMAC signatures and rejects unsigned 'alg: none' tokens. |
| **SEC-AUTH-03** | Broken Authentication | Missing Authentication Token Barrier | `90034` | **High** | ✅ Pass | Protected endpoints require valid Bearer token and reject unauthenticated requests with HTTP 401. |
| **SEC-AUTHZ-01** | Broken Function Level Authorization | Driver Access to Staff POS Endpoint (BFLA) | `90036` | **High** | ✅ Pass | ASP.NET Core policy authorization successfully rejected Driver attempting to create on-site walk-in reservations. |
| **SEC-AUTHZ-02** | Broken Object Level Authorization | Driver Self-Approval Protection | `90035` | **High** | ✅ Pass | Driver role is strictly prohibited from approving reservations; requires StationOwner or Admin role. |
| **SEC-AUTHZ-03** | Mass Assignment | Registration Input Validation | `90037` | **High** | ✅ Pass | Registration rejected malformed or unpermitted role payload with status 400. |
| **SEC-INJ-01** | Injection | SQL Injection Parameter Resilience (EF Core Parameterization) | `40018` | **High** | ✅ Pass | Station search and filter queries use Entity Framework Core parameterized SQL. No SQL syntax errors or database exceptions were triggered. |
| **SEC-INJ-02** | Cross-Site Scripting | Reflected XSS Input Sanitization | `40012` | **Medium** | ✅ Pass | XSS characters are safely encoded or returned as strict JSON content-type, preventing browser execution. |
| **SEC-ERR-01** | Security Misconfiguration | Standardized Problem Details Error Handling | `90022` | **Medium** | ✅ Pass | Server utilizes ASP.NET Core RFC 7807/9110 Problem Details for errors, suppressing raw stack traces. |
| **SEC-ERR-02** | Sensitive Data Exposure | Sensitive Credential Masking in DTOs | `10062` | **High** | ✅ Pass | Application DTOs strictly exclude PasswordHash and authentication secrets from API serialization. |
| **SEC-RATE-01** | Unrestricted Resource Consumption | Rate Limiting on Authentication Endpoint | `90038` | **Low** | ⚠️ Warning | All 25 requests processed in 0.34s without HTTP 429 rate limit trigger. Recommendation: Add ASP.NET Core RateLimiter middleware to protect against brute-force attacks. |

---

## 3. Detailed Security Findings & Advisories

### [LOW] X-Content-Type-Options Header Missing (Plugin ID: 10021)
- **Category:** Security Headers
- **Description:** X-Content-Type-Options header is missing. Browsers may attempt to MIME-sniff response content.
- **Evidence:** `Header missing on /api/stations/all`
- **Remediation Recommendation:**

### [LOW] Server Version / Banner Disclosure (Plugin ID: 10055)
- **Category:** Information Disclosure
- **Description:** Server discloses web server technology via 'Server: Kestrel'. Attackers can fingerprint the host.
- **Evidence:** `Server: Kestrel`
- **Remediation Recommendation:**
  * Suppress the Kestrel server header in `Program.cs` via `builder.WebHost.ConfigureKestrel(s => s.AddServerHeader = false);`.

### [MEDIUM] Cross-Domain CORS Misconfiguration (Plugin ID: 10098)
- **Category:** Security Misconfiguration
- **Description:** CORS policy reflects arbitrary origins or uses wildcard: '*'. Sensitive data may be accessible cross-origin.
- **Evidence:** `Access-Control-Allow-Origin: *`
- **Remediation Recommendation:**

### [MEDIUM] Content-Security-Policy (CSP) Missing (Plugin ID: 10038)
- **Category:** Security Headers
- **Description:** Content-Security-Policy header is missing on frontend. Recommended to restrict inline script execution and XSS vectors.
- **Evidence:** `CSP header absent on React web root.`
- **Remediation Recommendation:**
  * Define a strict `Content-Security-Policy` header on the web server restricting script sources (`script-src 'self'`).

### [MEDIUM] X-Frame-Options Clickjacking Protection (Plugin ID: 10020)
- **Category:** Security Headers
- **Description:** X-Frame-Options header missing. The application could be embedded in an iframe on third-party sites.
- **Evidence:** `X-Frame-Options header absent on web portal.`
- **Remediation Recommendation:**
  * Configure `X-Frame-Options: DENY` or `SAMEORIGIN` in the web server middleware to prevent embedding the app in malicious iframes.

### [LOW] Rate Limiting on Authentication Endpoint (Plugin ID: 90038)
- **Category:** Unrestricted Resource Consumption
- **Description:** All 25 requests processed in 0.34s without HTTP 429 rate limit trigger. Recommendation: Add ASP.NET Core RateLimiter middleware to protect against brute-force attacks.
- **Evidence:** `Processed 25 requests in 0.34s without throttling.`
- **Remediation Recommendation:**
  * Configure ASP.NET Core RateLimiter middleware on sensitive endpoints (`/api/auth/login`) using sliding window rate limits.

