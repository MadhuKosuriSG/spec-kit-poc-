# Contract: POST /api/v1/users (Registration)

**Feature**: JWT Authentication System | **Version**: v1 | **Date**: 2026-06-30

## Overview

Creates a new user account. Returns a success confirmation with no sensitive data. Does not issue a JWT — the client must log in separately.

## Request

**Method**: `POST`
**Path**: `/api/v1/users`
**Content-Type**: `application/json`

### Body

```json
{
  "user": {
    "name": "Jane Doe",
    "email": "jane@example.com",
    "password": "securepassword123"
  }
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `user.name` | string | Yes | Non-empty; max 255 chars; whitespace trimmed |
| `user.email` | string | Yes | Valid email format; case-insensitive unique; max 255 chars; whitespace trimmed; stored lowercase |
| `user.password` | string | Yes | Minimum 8 characters; whitespace NOT trimmed |

## Responses

### 201 Created — Registration successful

```json
{
  "message": "Account created successfully"
}
```

No user data, password, or token returned.

---

### 422 Unprocessable Entity — Validation failure

Returned when any field is invalid, missing, or empty (including whitespace-only strings after trimming).

```json
{
  "errors": {
    "name": ["can't be blank"],
    "email": ["has already been taken"],
    "password": ["is too short (minimum is 8 characters)"]
  }
}
```

`errors` is a hash where each key is the failing field name and each value is an array of one or more human-readable error strings.

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
| Valid registration | 201 Created |
| Missing or invalid fields | 422 Unprocessable Entity |
| Duplicate email | 422 Unprocessable Entity |
| Rate limit exceeded | 429 Too Many Requests |

## Notes

- The `password` field is accepted in the request but is NEVER returned in any response.
- Emails differing only by case (`User@Example.com` vs `user@example.com`) are treated as identical — duplicate email returns 422.
- Field values exceeding maximum length return 422 with an appropriate error message; values are never auto-truncated.
