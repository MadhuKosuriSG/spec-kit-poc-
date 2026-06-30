# Tasks: JWT Authentication System

**Input**: Design documents from `/specs/001-jwt-auth/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2)
- All tasks include exact file paths

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Install missing dependencies and configure the test framework — required before any implementation begins.

- [x] T001 Update `Gemfile`: uncomment `gem "bcrypt", "~> 3.1.7"`; add `gem "jwt", "~> 2.9"` and `gem "rack-attack", "~> 6.7"` to the main group; add `gem "rspec-rails", "~> 6.1"`, `gem "factory_bot_rails"`, and `gem "faker"` to the `:development, :test` group; add `gem "shoulda-matchers", "~> 6.0"` to the `:test` group
- [x] T002 Run `bundle install` to install all gems added in T001
- [x] T003 [P] Run `rails generate rspec:install` to create `spec/spec_helper.rb` and `spec/rails_helper.rb`
- [x] T004 [P] Add `config.middleware.use Rack::Attack` to `config/application.rb` inside the `Application` class body
- [x] T005 [P] Generate a secure JWT secret — run `ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"` — then open Rails encrypted credentials via `rails credentials:edit` and add `jwt_secret_key: <generated_value>`
- [x] T006 Configure `spec/rails_helper.rb` (after T003): add `config.include FactoryBot::Syntax::Methods` inside the `RSpec.configure` block; append a `Shoulda::Matchers.configure` block targeting `:rails` and `:rspec` after the `RSpec.configure` block

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema and API routing — MUST be complete before any user story begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T007 Run `rails generate migration CreateUsers`; edit the generated file in `db/migrate/` to use `create_table :users` with columns `t.string :name, null: false`, `t.string :email, null: false`, `t.string :password_digest, null: false`, and `t.timestamps`; add `add_index :users, :email, unique: true` after the `create_table` block
- [x] T008 Run `rails db:migrate` to apply the CreateUsers migration to the development database; run `rails db:migrate RAILS_ENV=test` to apply it to the test database
- [x] T009 Add API routing to `config/routes.rb`: inside the `Rails.application.routes.draw` block add `namespace :api do; namespace :v1 do; resources :users, only: [:create]; resources :sessions, only: [:create]; end; end`
- [x] T010 [P] Create `config/initializers/rack_attack.rb`: add a throttle block limiting each IP to 5 requests per 20 seconds on `POST /api/v1/users` and `POST /api/v1/sessions`; override `Rack::Attack.throttled_responder` to return `[429, { "Content-Type" => "application/json" }, [{ error: "Too many requests. Please try again later." }.to_json]]`

**Checkpoint**: Foundation ready — both user stories can now begin.

---

## Phase 3: User Story 1 — New User Registration (Priority: P1) 🎯 MVP

**Goal**: A new user submits name, email, and password; the system creates their account and returns 201, or returns structured 422 errors for any invalid input.

**Independent Test**: Fully verifiable via `POST /api/v1/users` alone — valid data (→ 201), duplicate email (→ 422), missing fields (→ 422), short password (→ 422), invalid email format (→ 422), and rate limit exhaustion (→ 429). No other feature required.

> **NOTE**: Write tests T011–T013 first. Run `bundle exec rspec` — they MUST fail before implementing T014–T015.

- [x] T011 [US1] Write `spec/models/user_spec.rb`: RSpec unit specs using Shoulda Matchers — `validate_presence_of :name`, `validate_length_of(:name).is_at_most(255)`, `validate_presence_of :email`, `validate_uniqueness_of(:email).case_insensitive`, `validate_length_of(:email).is_at_most(255)`, `have_secure_password`, `validate_length_of(:password).is_at_least(8).on(:create)`; add a custom example asserting that email `" User@Example.com "` is stored as `"user@example.com"` after save; add a custom example asserting that name `"  Jane  "` is stored as `"Jane"` after save
- [x] T012 [P] [US1] Write `spec/factories/users.rb`: FactoryBot factory for `:user` with `name { Faker::Name.name }`, `email { Faker::Internet.unique.email.downcase }`, and `password { Faker::Internet.password(min_length: 8) }`
- [x] T013 [P] [US1] Write `spec/requests/api/v1/users_spec.rb`: request specs covering all 5 acceptance scenarios from spec.md — (1) valid input → 201 with body `{ "message": "Account created successfully" }` and no password in response; (2) duplicate email → 422 with `errors.email` present; (3) invalid email format → 422 with `errors.email` present; (4) password shorter than 8 chars → 422 with `errors.password` present; (5) missing required field → 422 with per-field errors; plus edge cases: `User@Example.com` treated as duplicate of `user@example.com`; whitespace-only name or email treated as blank and returns 422; name > 255 chars → 422; email > 255 chars → 422
- [x] T014 [US1] Create `app/models/user.rb`: `has_secure_password`; `validates :name, presence: true, length: { maximum: 255 }`; `validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }, length: { maximum: 255 }`; `validates :password, length: { minimum: 8 }, allow_nil: true`; `before_validation :normalize_fields`; private method `normalize_fields` that sets `self.email = email.to_s.strip.downcase` and `self.name = name.to_s.strip`
- [x] T015 [US1] Create `app/controllers/api/v1/users_controller.rb` with module wrapping `Api::V1`: `create` action — `@user = User.new(user_params)`; on `@user.save` render `{ message: "Account created successfully" }` with `status: :created`; else render `{ errors: @user.errors.as_json(full_messages: false) }` with `status: :unprocessable_entity`; private `user_params` method: `params.require(:user).permit(:name, :email, :password)`

**Checkpoint**: Run `bundle exec rspec spec/models/user_spec.rb spec/requests/api/v1/users_spec.rb` — all specs MUST be green before proceeding.

---

## Phase 4: User Story 2 — Registered User Login (Priority: P2)

**Goal**: A registered user submits email and password; the system returns a signed JWT token (200) or a generic error that does not reveal which credential was wrong (401/422).

**Independent Test**: Fully verifiable via `POST /api/v1/sessions` alone — valid credentials (→ 200 with JWT whose decoded payload includes `sub`, `email`, `iat`, `exp`), wrong password (→ 401, `"Invalid email or password"`), unknown email (→ 401, same message), missing fields (→ 422). User Story 1 (registration) must be complete to create test users.

> **NOTE**: Write tests T016–T017 first. They MUST fail before implementing T018–T019.

- [x] T016 [P] [US2] Write `spec/services/auth_token_service_spec.rb`: describe `AuthTokenService.encode(user)` — returns a non-nil string; decoded payload `sub` equals `user.id`; decoded payload `email` equals `user.email`; `iat` is within 5 seconds of `Time.now.to_i`; `exp` is within 5 seconds of `(Time.now + 7.days).to_i`; algorithm header is `"HS256"`. Describe `AuthTokenService.decode(token)` — returns a hash with correct `sub` and `email` for a valid token; raises `JWT::DecodeError` when the token signature is tampered; raises `JWT::ExpiredSignature` when `exp` is in the past.
- [x] T017 [P] [US2] Write `spec/requests/api/v1/sessions_spec.rb`: request specs covering all 4 acceptance scenarios — (1) valid email + correct password → 200 with `token` key in response body; decoded token contains correct `sub` and `email`; (2) correct email, wrong password → 401 with body `{ "error": "Invalid email or password" }`; (3) email not associated with any account → 401 with the same generic error as scenario 2 (no leak of email existence); (4) email or password field missing or empty → 422 with per-field blank errors; edge case: `User@Example.com` authenticates the same account as `user@example.com`
- [x] T018 [US2] Create `app/services/auth_token_service.rb`: define `SECRET = Rails.application.credentials.jwt_secret_key!`; class method `self.encode(user)` — builds `payload = { sub: user.id, email: user.email, iat: Time.now.to_i, exp: (Time.now + 7.days).to_i }` and returns `JWT.encode(payload, SECRET, "HS256")`; class method `self.decode(token)` — returns `JWT.decode(token, SECRET, true, algorithms: ["HS256"]).first` (raises `JWT::DecodeError` or `JWT::ExpiredSignature` on invalid or expired tokens)
- [x] T019 [US2] Create `app/controllers/api/v1/sessions_controller.rb` with module wrapping `Api::V1`: `create` action — validate presence of `session_params[:email]` and `session_params[:password]` and return 422 with per-field blank errors if either is blank; find user with `User.find_by(email: session_params[:email].to_s.strip.downcase)`; call `user&.authenticate(session_params[:password])`; on success render `{ token: AuthTokenService.encode(user) }` with `status: :ok`; on failure render `{ error: "Invalid email or password" }` with `status: :unauthorized`; private `session_params`: `params.permit(:email, :password)`

**Checkpoint**: Run `bundle exec rspec spec/services/auth_token_service_spec.rb spec/requests/api/v1/sessions_spec.rb` — all specs MUST be green before proceeding.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Code quality, full suite validation, and manual end-to-end verification.

- [x] T020 [P] Run RuboCop: `bundle exec rubocop`; fix all reported offences until the output shows zero violations; do not suppress offences with `# rubocop:disable` without documented justification in a comment explaining why
- [x] T021 Run full RSpec suite: `bundle exec rspec --format documentation`; every spec MUST be green with no failures, errors, or pending examples on critical paths; note total spec count in output
- [x] T022 [P] Manual end-to-end verification: start `rails server`; execute each curl command from `specs/001-jwt-auth/quickstart.md` in order (register → login → inspect token); confirm registration returns 201, login returns 200 with a decodable JWT, and the decoded payload contains `sub`, `email`, `iat`, `exp`
- [x] T023 [P] Verify rate limiting: start `rails server`; send 6 rapid POST requests to `/api/v1/sessions` from the same IP (e.g., `for i in {1..6}; do curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:3000/api/v1/sessions -H "Content-Type: application/json" -d '{"email":"x@x.com","password":"wrong"}'; done`); confirm the 6th response is `429` with body `{ "error": "Too many requests. Please try again later." }`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Requires Phase 1 complete — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Requires Phase 2 complete
- **User Story 2 (Phase 4)**: Requires Phase 2 complete; also requires T014 (User model) from Phase 3
- **Polish (Phase 5)**: Requires Phases 3 and 4 complete

### User Story Dependencies

- **US1 (P1)**: Depends only on Phase 2. Start here for MVP.
- **US2 (P2)**: Depends on Phase 2 and T014 (User model). US2 spec tasks T016–T017 can be written in parallel with US1 implementation tasks T014–T015.

### Within Each User Story

- Spec tasks MUST be written and confirmed failing before implementation tasks begin
- User model (T014) before UsersController (T015) — controller instantiates the model
- AuthTokenService (T018) before SessionsController (T019) — controller calls the service
- Factory (T012) before running any spec that calls `create(:user)`

---

## Parallel Opportunities

### Phase 1 (after T002 `bundle install` completes)

```
T003 rspec:install  ──→ concurrent with T004 (rack-attack middleware)
                    ──→ concurrent with T005 (Rails credentials)
T006 rails_helper   ──→ after T003 completes
```

### Phase 3 User Story 1 (after Phase 2 complete)

```
T011 user_spec.rb         ──→ concurrent with T012 (factory)
                          ──→ concurrent with T013 (users request spec)
T014 User model           ──→ after all three specs written
T015 UsersController      ──→ after T014
```

### Phase 4 User Story 2 (after T014 complete)

```
T016 auth_token_service_spec.rb  ──→ concurrent with T017 (sessions request spec)
T018 AuthTokenService            ──→ after both specs written
T019 SessionsController          ──→ after T018
```

### Phase 5 (after Phases 3 & 4 complete)

```
T020 RuboCop           ──→ concurrent with T022 (quickstart check)
                       ──→ concurrent with T023 (rate limit check)
T021 full RSpec suite  ──→ after T020 (ensures zero RuboCop offences first)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: `bundle exec rspec spec/models spec/requests/api/v1/users_spec.rb`
5. Registration endpoint is fully functional and independently deployable

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Phase 3 (US1) → Registration works → Deploy / Demo
3. Phase 4 (US2) → Login + JWT works → Deploy / Demo
4. Phase 5 → Polish → Production-ready

### Single Developer Sequence

```
T001 → T002 → [T003, T004, T005] → T006 →
T007 → T008 → T009, T010 →
[T011, T012, T013] → T014 → T015 → (checkpoint) →
[T016, T017] → T018 → T019 → (checkpoint) →
[T020, T022, T023] → T021
```

---

## Notes

- `[P]` tasks touch different files — safe to run concurrently with no merge conflicts
- `allow_nil: true` on the password length validation is intentional: prevents the validation from triggering when updating other User attributes without changing the password
- `has_secure_password` automatically validates `password_digest` presence — do not add a redundant `validates :password_digest, presence: true`
- `credentials.jwt_secret_key!` (with bang) raises `KeyError` at boot if the key is missing — fail-fast is preferred over a silent `nil` that would produce obscure JWT errors at runtime
- RuboCop is pre-configured via `rubocop-rails-omakase` in `.rubocop.yml` — do not modify the config; fix code to comply
- US1 and US2 both use the `:user` factory from `spec/factories/users.rb` — create it in Phase 3 since that is where it is first needed
