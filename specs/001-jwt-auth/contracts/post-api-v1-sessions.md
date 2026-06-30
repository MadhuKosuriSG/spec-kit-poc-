# Contract: POST /api/v1/sessions (Login)

**Feature**: JWT Authentication System | **Version**: v1 | **Date**: 2026-06-30

## Overview

Authenticates a registered user and returns a signed JWT token. The token is valid for 7 days and must be presented in subsequent requests as a Bearer token.

## Request

**Method**: `POST`
**Path**: `/api/v1/sessions`
**Content-Type**: `application/json`

### Body

```json
{
  "email": "jane@example.com",
  "password": "securepassword123"
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `email` | string | Yes | Matched case-insensitively; whitespace trimmed before lookup |
| `password` | string | Yes | Matched against stored bcrypt hash; whitespace NOT trimmed |

## Responses

### 200 OK — Authentication successful

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjQyLCJlbWFpbCI6ImphbmVAZXhhbXBsZS5jb20iLCJpYXQiOjE3NTEyMzQ1NjcsImV4cCI6MTc1MTgzOTM2N30.SIGNATURE"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `token` | string | HS256-signed JWT; valid for 7 days from issuance |

**JWT Payload** (decoded):

```json
{
  "sub": 42,
  "email": "jane@example.com",
  "iat": 1751234567,
  "exp": 1751839367
}
```

| Claim | Description |
|-------|-------------|
| `sub` | User's database ID (integer) |
| `email` | User's email address (lowercase) |
| `iat` | Unix timestamp — token issued-at |
| `exp` | Unix timestamp — token expiry (`iat` + 604,800 seconds) |

---

### 401 Unauthorized — Authentication failure

Returned when the email is not found **or** the password is incorrect. The response is identical in both cases to prevent user enumeration (FR-013).

```json
{
  "error": "Invalid email or password"
}
```

---

### 422 Unprocessable Entity — Missing fields

Returned when `email` or `password` is absent or empty (including whitespace-only strings).

```json
{
  "errors": {
    "email": ["can't be blank"],
    "password": ["can't be blank"]
  }
}
```

---

### 429 Too Many Requests — Rate limit exceeded

Returned when a single IP sends more than 5 requests in a 20-second window.

```json
{
  "error": "Too many requests. Please try again later."
}
```

---

## HTTP Status Code Summary

| Scenario | Status |
|----------|--------|
| Valid credentials | 200 OK |
| Missing or empty fields | 422 Unprocessable Entity |
| Wrong email or wrong password | 401 Unauthorized |
| Rate limit exceeded | 429 Too Many Requests |

## Notes

- The error message for 401 is always `"Invalid email or password"` regardless of whether the email exists. This prevents attackers from discovering registered email addresses.
- Email matching is case-insensitive: `User@Example.com` resolves to `user@example.com`.
- The token should be included in subsequent authenticated requests as: `Authorization: Bearer <token>` (token validation endpoint is out of scope for this feature).
- No refresh token mechanism exists. The client must re-authenticate after 7 days.
