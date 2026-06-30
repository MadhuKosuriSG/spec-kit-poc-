<!--
## Sync Impact Report
- **Version change**: N/A → 1.0.0 (initial ratification)
- **Modified principles**: N/A — initial creation
- **Added sections**: Core Principles (I–VIII), Technology Stack, Development Workflow, Governance
- **Removed sections**: None
- **Templates reviewed**:
  - `.specify/templates/plan-template.md` ✅ aligned — Constitution Check gate will enforce these 8 principles
  - `.specify/templates/spec-template.md` ✅ aligned — requirements format compatible with Rails/RSpec project
  - `.specify/templates/tasks-template.md` ✅ aligned — phase structure covers Rails setup, migrations, service objects, and test tasks
- **Follow-up TODOs**: None — all fields resolved
-->

# Spec Kit POC Constitution

## Core Principles

### I. RESTful API Design (NON-NEGOTIABLE)

All HTTP endpoints MUST follow REST conventions: correct HTTP verbs (GET, POST, PUT/PATCH, DELETE),
resource-based URL naming (plural nouns, nested only when semantically required), and idempotency
expectations honoured. Every error response MUST return a meaningful HTTP status code (4xx for client
errors, 5xx for server errors) with a structured JSON body containing at minimum `error` and `message`
fields. Success responses MUST use the appropriate 2xx code: 201 for resource creation, 204 for
deletion without a body, 200 otherwise.

### II. Test-First Quality (NON-NEGOTIABLE)

RSpec MUST be used for all automated testing across three layers:
- **Unit specs**: models, service objects, and plain Ruby classes in isolation.
- **Request specs**: full HTTP contract coverage for every public endpoint.
- **Integration specs**: cross-layer user-journey coverage for critical paths.

Tests MUST be written before or alongside implementation — no feature is complete until all specs
pass. Coverage gates MUST prevent merging when critical paths are untested.

### III. Simplicity & Pragmatism (KISS & YAGNI)

Code MUST solve only the problem at hand. Abstractions, patterns, and infrastructure MUST NOT be
introduced speculatively or for anticipated future requirements. Every layer of indirection MUST
be justified by a current, concrete need. When two approaches are equally valid, choose the more
readable one. Over-engineered solutions to simple problems are considered defects.

### IV. Clean Architecture & SOLID

Controllers MUST remain thin: parse the request, whitelist params, call one service or domain
object, and render the response. Business logic MUST live in service objects (`app/services/`) or
domain classes — never in controllers or views. Models MUST focus on domain behaviour (validations,
associations, scopes, domain methods) and MUST NOT contain orchestration or cross-cutting logic
(avoid fat models). Design patterns — Service Object, Strategy, Factory, Decorator, Repository —
MUST be applied only where they solve a clear, present problem, not as default scaffolding. All
non-trivial classes MUST adhere to the Single Responsibility, Open/Closed, Liskov Substitution,
Interface Segregation, and Dependency Inversion principles.

### V. Rails Conventions & Code Style

Rails' convention over configuration MUST be followed unless there is a documented, compelling
reason to deviate. Naming, directory structure, generators, routing, and ActiveRecord associations
MUST match established Rails idioms. All Ruby code MUST pass RuboCop checks — `.rubocop.yml` is
authoritative. Code MUST be clear, readable, and self-documenting; comments are reserved for
non-obvious constraints or workarounds. Magic numbers and inline strings MUST be replaced with
named constants or configuration entries.

### VI. Database Excellence

PostgreSQL is the only supported database. Schema design MUST follow third-normal-form (3NF)
unless a documented denormalisation is justified by measured performance data. Every foreign key
MUST carry a database-level constraint. Columns MUST carry NOT NULL constraints where nullability
is not a semantic requirement. Indexes MUST be present on all foreign key columns and on any
column used in WHERE, ORDER BY, or JOIN clauses under expected query patterns. N+1 queries are
PROHIBITED — use `includes`, `preload`, or `eager_load` as appropriate, and verify with Bullet
in development. All schema changes MUST be delivered as versioned, reversible ActiveRecord
migrations.

### VII. Security First (NON-NEGOTIABLE)

All code MUST follow Rails security best practices:
- Strong Parameters MUST be used on every controller action that accepts user input.
- Mass assignment vulnerabilities and direct object reference exploits are PROHIBITED.
- SQL injection is PROHIBITED — use parameterised queries or the ActiveRecord query interface only.
- Sensitive data (credentials, tokens, PII) MUST NOT appear in logs or API responses.
- Authentication and authorisation MUST be enforced at the controller layer before any domain
  logic executes.
- Dependencies MUST be kept up to date; known CVEs MUST be remediated promptly.
- HTTPS MUST be enforced in all non-development environments.

### VIII. API Documentation & Spec Synchronisation

Every public API endpoint MUST be documented with its request/response schema, supported status
codes, and error shapes. Specifications in `specs/` MUST be kept synchronised with the
implementation at all times — a passing test suite with a drifted spec is a defect. Specs MUST
be written or updated before implementation begins and revised whenever behaviour changes.
The `/speckit-specify` workflow is the authoritative mechanism for managing feature specifications.

## Technology Stack

- **Runtime**: Ruby (see `.ruby-version`), Ruby on Rails 7.2+
- **Database**: PostgreSQL — primary and only supported data store
- **Testing**: RSpec (unit, request, integration); FactoryBot for test data factories; Faker for
  synthetic test data generation
- **Code Quality**: RuboCop (`.rubocop.yml` is the authoritative style configuration)
- **API Format**: JSON only; `Content-Type: application/json` MUST be set on all mutating requests
- **Background Jobs**: ActiveJob with a supported adapter (Sidekiq preferred for production)
- **Environment Config**: Rails encrypted credentials; secrets MUST NOT be committed to source
  control in plain text
- **Containerisation**: Docker (`Dockerfile` and `.dockerignore` are present); all environments
  MUST be reproducible via the provided container configuration

## Development Workflow

All new work MUST begin on a feature branch following the naming convention enforced by
`/speckit-git-feature`. A pull request MUST pass ALL of the following gates before merging:

1. RuboCop reports zero offences.
2. Full RSpec suite is green with no skipped or pending specs on critical paths.
3. No new N+1 queries introduced (verified via Bullet in development or manual review).
4. Constitution Check in `plan.md` is completed and shows no unresolved violations.
5. API spec and implementation are synchronised — no undocumented endpoints or drifted schemas.
6. Database migrations reviewed for correctness, reversibility, and index coverage.

Code reviews MUST verify adherence to the Core Principles, with particular attention to
Principle IV (Clean Architecture) and Principle VII (Security).

## Governance

This constitution supersedes all informal practices. It MUST be consulted at the start of every
feature plan (`/speckit-plan` Constitution Check gate) and re-checked after Phase 1 design.

**Amendment procedure**:
1. Propose the amendment in a pull request with a clear rationale and impact assessment.
2. The amendment MUST be reviewed and approved by at least one senior contributor.
3. All templates and dependent artifacts flagged in the Sync Impact Report MUST be updated in the
   same pull request.
4. `CONSTITUTION_VERSION` MUST be incremented per semantic versioning: MAJOR for backward-
   incompatible principle removals or redefinitions; MINOR for new principles or materially
   expanded guidance; PATCH for clarifications or wording refinements.
5. `LAST_AMENDED_DATE` MUST be updated to the merge date in ISO format (YYYY-MM-DD).

**Compliance**: All PRs and code reviews MUST verify adherence to the principles above.
Complexity that violates a principle MUST be documented in the `Complexity Tracking` table in
`plan.md` with explicit justification for why a simpler alternative was rejected.

**Version**: 1.0.0 | **Ratified**: 2026-06-29 | **Last Amended**: 2026-06-29
