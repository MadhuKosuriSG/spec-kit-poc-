# Implementation Plan: JWT Authentication System

**Branch**: `001-jwt-auth` | **Date**: 2026-06-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-jwt-auth/spec.md`

## Summary

Build a JWT-based authentication system on an existing Rails 7.2 / PostgreSQL application. The feature adds a `users` table, a `User` model with bcrypt-hashed passwords via `has_secure_password`, two RESTful API endpoints (`POST /api/v1/users` for registration and `POST /api/v1/sessions` for login), an `AuthTokenService` that issues HS256-signed JWTs containing `sub`, `email`, `iat`, and `exp` (7-day expiry), and IP-based rate limiting via `rack-attack` on both endpoints.

## Technical Context

**Language/Version**: Ruby 3.2.4

**Primary Dependencies**:
- Rails 7.2.3 (existing)
- `jwt` (~> 2.9) — JWT encoding/decoding
- `bcrypt` (~> 3.1.7) — already in Gemfile, commented out; needs uncommenting
- `rack-attack` (~> 6.7) — IP-based rate limiting on auth endpoints

**Storage**: PostgreSQL — `users` table with `name`, `email` (unique, lowercase-normalised), `password_digest` columns; no token persistence (JWTs are stateless)

**Testing**: RSpec (`rspec-rails`), FactoryBot (`factory_bot_rails`), Faker, Shoulda Matchers — **not yet in Gemfile; must be added before implementation begins**

**Target Platform**: Linux server (Docker — `Dockerfile` present in repo root)

**Project Type**: Rails web service — API controllers under `api/v1` namespace; JSON-only responses

**Performance Goals**: < 2 seconds p50 for both registration (SC-001) and login (SC-002) under standard operating load

**Constraints**: HS256 JWT signing with server-side secret stored in Rails encrypted credentials; 7-day token expiry; rate limiting at 5 requests / 20 seconds per IP on both auth endpoints

**Scale/Scope**: Single Rails application; user count not quantified; no horizontal scaling requirement in scope for this feature

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. RESTful API Design | ✅ PASS | `POST /api/v1/users` → 201; `POST /api/v1/sessions` → 200; 422 for validation errors; 401 for auth failure; 429 for rate limit |
| II. Test-First Quality | ⚠️ SETUP REQUIRED | `rspec-rails`, `factory_bot_rails`, `faker`, `shoulda-matchers` not in Gemfile — resolved in Phase 0 |
| III. KISS / YAGNI | ✅ PASS | `has_secure_password` (no manual bcrypt); one service object (`AuthTokenService`); no refresh tokens; no token revocation |
| IV. Clean Architecture | ✅ PASS | Thin controllers; `AuthTokenService` in `app/services/`; `User` model owns validations only |
| V. Rails Conventions | ✅ PASS | Namespace routing block; standard Rails generators; RuboCop via `rubocop-rails-omakase` |
| VI. Database Excellence | ✅ PASS | Unique index on `email`; NOT NULL on all columns; reversible migration; no N+1 risk (no associations) |
| VII. Security First | ✅ PASS | Strong params on all inputs; `has_secure_password`; HS256 secret in Rails credentials (not source control); `rack-attack` throttling; generic auth error messages |
| VIII. API Documentation | ✅ PASS | `contracts/` generated in Phase 1 |

**Complexity Tracking**: No constitution violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-jwt-auth/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── post-api-v1-users.md
│   └── post-api-v1-sessions.md
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── application_controller.rb   # existing
│   └── api/
│       └── v1/
│           ├── users_controller.rb      # registration endpoint
│           └── sessions_controller.rb   # login endpoint
├── models/
│   ├── application_record.rb       # existing
│   └── user.rb                     # User model with has_secure_password
└── services/
    └── auth_token_service.rb       # JWT encode/decode

config/
├── initializers/
│   └── rack_attack.rb              # rate limiting configuration
└── routes.rb                       # api/v1 namespace block

db/
└── migrate/
    └── [timestamp]_create_users.rb

spec/
├── rails_helper.rb                 # RSpec + FactoryBot + Shoulda config
├── spec_helper.rb
├── factories/
│   └── users.rb
├── models/
│   └── user_spec.rb
├── requests/
│   └── api/
│       └── v1/
│           ├── users_spec.rb
│           └── sessions_spec.rb
└── services/
    └── auth_token_service_spec.rb
```

**Structure Decision**: Single-project Rails layout. API controllers namespaced under `api/v1` via a routing namespace block. Service objects in `app/services/` per Constitution Principle IV. RSpec specs mirror `app/` structure under `spec/`.
