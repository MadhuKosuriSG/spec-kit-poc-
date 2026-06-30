# Quickstart: JWT Authentication System

**Feature**: JWT Authentication System | **Date**: 2026-06-30

This guide covers local setup and manual verification of the feature. Run all commands from the repo root.

## Prerequisites

- Ruby 3.2.4 (verify: `ruby -v`)
- PostgreSQL running locally or via Docker
- Bundler (`gem install bundler` if missing)

## Setup

### 1. Add required gems

Edit `Gemfile`:

```ruby
# Uncomment bcrypt (already present, just commented out)
gem "bcrypt", "~> 3.1.7"

# Add new gems
gem "jwt", "~> 2.9"
gem "rack-attack", "~> 6.7"

group :development, :test do
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
end
```

Then:

```bash
bundle install
```

### 2. Set up the JWT secret

```bash
rails credentials:edit
```

Add inside the credentials file:

```yaml
jwt_secret_key: your-long-random-secret-here
```

Generate a strong secret with: `ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"`

### 3. Install RSpec

```bash
rails generate rspec:install
```

### 4. Create and migrate the database

```bash
rails db:create db:migrate
```

### 5. Run the test suite

```bash
bundle exec rspec
```

All specs should pass before beginning implementation.

---

## Manual Verification

Start the server:

```bash
rails server
```

### Register a new user

```bash
curl -s -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"user":{"name":"Jane Doe","email":"jane@example.com","password":"securepass123"}}' | jq .
```

Expected: `201 Created` with `{"message":"Account created successfully"}`

### Log in

```bash
curl -s -X POST http://localhost:3000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"email":"jane@example.com","password":"securepass123"}' | jq .
```

Expected: `200 OK` with `{"token":"eyJ..."}`

### Inspect the token

```bash
TOKEN="<paste token here>"
echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq .
```

Expected payload: `{"sub": <id>, "email": "jane@example.com", "iat": <timestamp>, "exp": <timestamp>}`

### Verify error responses

Duplicate email (422):
```bash
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"user":{"name":"Jane Doe","email":"jane@example.com","password":"securepass123"}}'
```

Wrong password (401):
```bash
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"email":"jane@example.com","password":"wrongpassword"}'
```

---

## Key Files

| File | Purpose |
|------|---------|
| `app/models/user.rb` | User model — validations, `has_secure_password`, email normalisation |
| `app/services/auth_token_service.rb` | JWT encode/decode |
| `app/controllers/api/v1/users_controller.rb` | Registration endpoint |
| `app/controllers/api/v1/sessions_controller.rb` | Login endpoint |
| `config/initializers/rack_attack.rb` | Rate limiting configuration |
| `db/migrate/*_create_users.rb` | Users table migration |
| `spec/models/user_spec.rb` | Unit specs — model validations |
| `spec/requests/api/v1/users_spec.rb` | Request specs — registration |
| `spec/requests/api/v1/sessions_spec.rb` | Request specs — login |
| `spec/services/auth_token_service_spec.rb` | Unit specs — JWT service |
