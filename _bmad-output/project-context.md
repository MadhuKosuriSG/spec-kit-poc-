---
project_name: 'spec-kit-poc'
user_name: 'madhu'
date: '2026-07-03'
sections_completed: ['technology_stack', 'language_specific_rules']
existing_patterns_found: 6
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- **Ruby**: 3.2.4 | **Rails**: 7.2.3
- **Database**: PostgreSQL only — no other DB is supported (Constitution VI)
- **Auth**: `jwt` 2.10.3 (HS256 only), `bcrypt` 3.1.22 via `has_secure_password`, `rack-attack` 6.8.0
- **Testing**: `rspec-rails` 6.1.5, `factory_bot_rails` 6.5.1, `faker` 3.8.0, `shoulda-matchers` 6.5.0
- **Style**: `rubocop-rails-omakase` (`.rubocop.yml` inherits it — zero offences required to merge)
- **Background jobs**: ActiveJob; Sidekiq preferred for production (not yet added — add only when a job is actually needed)
- **Containerization**: Docker (`Dockerfile`, `.dockerignore` present) — all environments must be reproducible via it
- **API format**: JSON only; `Content-Type: application/json` required on all mutating requests
- **Secrets**: Rails encrypted credentials (`rails credentials:edit`) — never plain-text in source control

## Critical Implementation Rules

### Language-Specific Rules

- Follow Rails' omakase style (`rubocop-rails-omakase`) — do not introduce a personal/team style config; `.rubocop.yml` only adds exceptions on top of the inherited gem
- Comments are reserved for non-obvious constraints or workarounds only — code must be self-documenting (Constitution V)
- Magic numbers/strings MUST be named constants or config entries, not inline literals
- Use `before_validation` callbacks for field normalization (e.g. `strip`, `downcase`) rather than doing it ad hoc in controllers — see `User#normalize_fields` for the established pattern
- Prefer Rails idioms (`has_secure_password`, `enum`, ActiveRecord validations) over hand-rolled logic — e.g. password hashing uses `has_secure_password`, not manual `BCrypt::Password` calls
