# Research: JWT Authentication System

**Phase**: 0 | **Date**: 2026-06-30 | **Plan**: [plan.md](plan.md)

## Decision 1: JWT Library

**Decision**: Use the `jwt` gem (v2.9+) directly via `AuthTokenService`.

**Rationale**: The `jwt` gem is the de facto standard Ruby JWT library. A thin service object wrapping `JWT.encode` / `JWT.decode` is the KISS-compliant approach — it introduces exactly one abstraction for one concrete need and is trivially testable. Higher-level gems like `knock` or `devise-jwt` add middleware, routing concerns, and assumptions about the auth lifecycle that conflict with the explicit, minimal scope of this feature. `knock` is also unmaintained as of Rails 7.

**Alternatives considered**:
- `knock` — unmaintained, opinionated routing; rejected
- `devise-jwt` — requires Devise, which is overkill for registration + login only; rejected
- Manual HMAC (`OpenSSL::HMAC`) — correct but reimplements what `jwt` already provides; rejected per YAGNI

**Implementation note**: Add `gem "jwt", "~> 2.9"` to Gemfile. Secret key stored in Rails encrypted credentials as `jwt_secret_key`. `AuthTokenService.encode(payload)` and `AuthTokenService.decode(token)` are the only public interface.

---

## Decision 2: Password Hashing

**Decision**: Use Rails' `has_secure_password` macro (backed by bcrypt).

**Rationale**: `has_secure_password` is a first-class Rails feature that handles bcrypt hashing transparently, provides the `authenticate(password)` method, and enforces `password_digest` presence — eliminating boilerplate. It requires the `bcrypt` gem, which is already in the Gemfile (commented out) and only needs uncommenting. This is the most convention-compliant choice per Constitution Principle V.

**Alternatives considered**:
- Manual `BCrypt::Password` — correct but verbose; rejected as unnecessary abstraction per YAGNI
- Argon2 (`argon2` gem) — stronger algorithm but no Rails-native integration, adds deployment complexity; deferred unless security requirements explicitly demand it

**Implementation note**: Uncomment `gem "bcrypt", "~> 3.1.7"` in Gemfile. Add `has_secure_password` to `User` model. `password_digest` column in migration (string, NOT NULL). Minimum password length enforced via `validates :password, length: { minimum: 8 }, allow_nil: true` (allow_nil prevents validation triggering on update when password not changed).

---

## Decision 3: Rate Limiting

**Decision**: Use `rack-attack` (~> 6.7) with IP-based throttles on both auth endpoints.

**Rationale**: `rack-attack` is the Rails community standard for request throttling. It operates at the Rack middleware layer — before the Rails router — ensuring throttled requests consume minimal resources. Configuration is declarative and kept in a single initializer (`config/initializers/rack_attack.rb`). Throttle limits: 5 requests per 20 seconds per IP on `POST /api/v1/users` and `POST /api/v1/sessions`, returning 429 with a structured JSON error body.

**Alternatives considered**:
- `slowpoke` — focused on timeouts, not rate limiting; rejected
- Nginx-level rate limiting — valid in production but not in scope for the application layer; deferred to infrastructure
- No rate limiting — rejected; spec FR-014 explicitly requires it

**Implementation note**: Add `gem "rack-attack", "~> 6.7"` to Gemfile. Add `config.middleware.use Rack::Attack` to `config/application.rb`. Configure `Rack::Attack.throttle` blocks in initializer. Override `Rack::Attack.throttled_responder` to return JSON 429 consistent with error response format.

---

## Decision 4: RSpec Test Stack

**Decision**: Add `rspec-rails`, `factory_bot_rails`, `faker`, and `shoulda-matchers` to the `:test` group.

**Rationale**: Constitution Principle II mandates RSpec across three layers: unit (model + service), request (HTTP contract), and integration. FactoryBot provides readable, maintainable test data factories. Faker generates realistic synthetic data. Shoulda Matchers provides one-liner model validation assertions (`validate_presence_of`, `validate_uniqueness_of`, etc.) that keep specs concise and focused.

**Alternatives considered**:
- Minitest (default Rails) — present in project but Constitution explicitly mandates RSpec; rejected
- `database_cleaner` — useful but not required with RSpec's `use_transactional_fixtures: true` (Rails default); deferred
- `webmock` — no external HTTP calls in this feature; not needed

**Implementation note**:
```ruby
# Gemfile
group :development, :test do
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
end
```
Run `rails generate rspec:install` after bundle. Configure `shoulda-matchers` in `spec/rails_helper.rb`.

---

## Resolved Unknowns Summary

| Unknown | Resolution |
|---------|------------|
| JWT library | `jwt` gem + `AuthTokenService` wrapper |
| Password hashing | `has_secure_password` (bcrypt, built-in Rails) |
| Rate limiting | `rack-attack` with IP throttle, 5 req / 20s |
| Test stack | `rspec-rails` + `factory_bot_rails` + `faker` + `shoulda-matchers` |
| JWT secret storage | Rails encrypted credentials (`jwt_secret_key`) |
| Token expiry | 7 days (604,800 seconds) — resolved in clarification |
| Signing algorithm | HS256 — resolved in clarification |
| JWT payload claims | `sub`, `email`, `iat`, `exp` — resolved in clarification |
| API URL namespace | `/api/v1/` — resolved in clarification |
