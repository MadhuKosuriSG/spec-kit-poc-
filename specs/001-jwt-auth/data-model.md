# Data Model: JWT Authentication System

**Phase**: 1 | **Date**: 2026-06-30 | **Plan**: [plan.md](plan.md)

## Entities

### User

Represents a registered person with the ability to authenticate.

**Table**: `users`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | bigint | PRIMARY KEY, NOT NULL, auto-increment | Rails default |
| `name` | string(255) | NOT NULL | Full name; whitespace trimmed before validation |
| `email` | string(255) | NOT NULL, UNIQUE | Stored as lowercase; whitespace trimmed before save |
| `password_digest` | string | NOT NULL | bcrypt hash managed by `has_secure_password` |
| `created_at` | datetime(6) | NOT NULL | Rails timestamp |
| `updated_at` | datetime(6) | NOT NULL | Rails timestamp |

**Indexes**:
- `index_users_on_email` — UNIQUE, on `email` column (supports uniqueness check and case-insensitive lookup)

**No foreign keys** — Users has no associations in this feature scope.

---

### Authentication Token (JWT) — not persisted

JWTs are stateless and not stored in the database. The payload structure is part of the data contract, not the schema.

**JWT Payload**:

| Claim | Type | Value |
|-------|------|-------|
| `sub` | integer | User's database `id` |
| `email` | string | User's email address (lowercase) |
| `iat` | integer | Unix timestamp — token issued-at time |
| `exp` | integer | Unix timestamp — `iat` + 604,800 seconds (7 days) |

**Signing**: HS256 (HMAC-SHA256) using `jwt_secret_key` from Rails encrypted credentials.

---

## Validation Rules

### User Model

| Field | Rule | Error Message | Source |
|-------|------|--------------|--------|
| `name` | Presence required | "Name can't be blank" | FR-002 |
| `name` | Max length 255 chars | "Name is too long (maximum is 255 characters)" | Edge case |
| `email` | Presence required | "Email can't be blank" | FR-002 |
| `email` | Valid email format | "Email is invalid" | FR-003 |
| `email` | Uniqueness (case-insensitive) | "Email has already been taken" | FR-004 |
| `email` | Max length 255 chars | "Email is too long (maximum is 255 characters)" | Edge case |
| `password` | Presence required (on create) | "Password can't be blank" | FR-002, FR-005 |
| `password` | Minimum 8 characters | "Password is too short (minimum is 8 characters)" | FR-005 |

**Normalisation** (before_validation callbacks):
- `email` → `strip.downcase`
- `name` → `strip`
- `password` → NOT stripped (whitespace may be intentional per spec edge cases)

---

## State Transitions

This feature has no complex state machine. User lifecycle within scope:

```
[non-existent] ---(POST /api/v1/users)---> [registered/active]
[registered]   ---(POST /api/v1/sessions)--> [authenticated: holds JWT]
```

Account deactivation, locking, and email verification are out of scope.

---

## Schema Migration (reference)

```ruby
# db/migrate/[timestamp]_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```
