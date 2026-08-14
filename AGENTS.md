# AGENTS.md

## Project Development Rules

This is a production Property Marketplace platform. Code must prioritize:
- High cohesion
- Low coupling
- Clear separation of responsibilities
- Maintainability
- Testability
- Consistent structure
- Incremental feature delivery

The project is developed **feature-by-feature (vertical slices)**, not by completing all backend first and frontend later.

---

## 1. Core Development Workflow

ALWAYS follow this order:

1. Understand the feature requirement.
2. Check existing architecture and related code.
3. Identify the smallest complete vertical slice.
4. Plan the affected layers/files before coding.
5. Implement backend/domain logic.
6. Implement API/integration layer.
7. Implement Flutter UI/state/integration.
8. Test the complete feature end-to-end.
9. Fix issues and refactor.
10. Mark the feature complete.
11. Only then move to the next feature.

Never implement large groups of unrelated features simultaneously.

### Example

Do NOT:

    Build all backend
    → Build all Flutter
    → Integrate everything

DO:

    Authentication
    → Backend
    → API
    → Flutter
    → Integration
    → Test
    → Complete

    Property
    → Backend
    → API
    → Flutter
    → Integration
    → Test
    → Complete

---

## 2. Architecture First, Implementation Second

Before feature development, establish and respect:

- Overall system architecture
- Database relationships
- API conventions
- Authentication strategy
- Authorization/roles
- Error handling
- Validation strategy
- File storage strategy
- Payment architecture
- Notification architecture
- Environment configuration

Do not redesign architecture casually during feature implementation.

If an architectural change becomes necessary:
1. Explain why.
2. Identify affected modules.
3. Prefer the smallest safe change.
4. Do not silently introduce a new architectural pattern.

---

## 3. Feature Boundaries

Each feature must have a clear responsibility.

Prefer:

    Feature A
      ├── domain/business logic
      ├── data/repository
      ├── API/service
      └── UI/integration

Avoid:

    One giant service
    One giant controller
    One giant Flutter screen
    Shared utility classes containing unrelated logic

A module should expose only what other modules actually need.

Keep internal implementation details private.

---

## 4. High Cohesion / Low Coupling

### High cohesion

Related logic belongs together.

Example:

    payment/
      payment.service
      payment.repository
      payment.model
      payment.controller

Do not scatter payment logic throughout unrelated modules.

### Low coupling

Modules communicate through stable interfaces/contracts.

Avoid:

- Direct database access from UI
- UI containing business logic
- Controllers containing complex business rules
- Payment logic inside property services
- Hard-coded infrastructure dependencies
- Circular dependencies

Prefer:

    UI
      ↓
    State / Controller
      ↓
    API / Application Service
      ↓
    Domain Logic
      ↓
    Repository
      ↓
    Database

---

## 5. Backend Rules

Use a layered architecture.

Recommended responsibility:

### Controller / Route
- Receive request
- Validate request shape
- Call application/service layer
- Return response

### Service / Use Case
- Business logic
- Workflow orchestration
- Business validation

### Repository
- Database access
- Persistence operations

### Model / Entity
- Domain data
- Domain rules where appropriate

Controllers must remain thin.

Do not put business logic directly into routes/controllers.

Do not let repositories contain business workflows.

---

## 6. Flutter Rules

Flutter code must separate:

- UI/presentation
- State management
- Domain/application logic
- Data/API access
- Models

Widgets should primarily render state and handle UI events.

Do not place API calls, payment workflows, database logic, or complex business rules directly inside widgets.

Avoid giant widgets.

Split complex screens into meaningful components.

Prefer feature-based organization over one global folder containing every screen.

Example:

    features/
      auth/
      property/
      search/
      payment/
      subscription/
      profile/

Each feature owns its related UI, state, models, and data access.

---

## 7. File Structure

Prefer feature-based structure.

Example backend:

    src/
      modules/
        auth/
          controllers/
          services/
          repositories/
          models/
          routes/
          validators/
        property/
        payment/
        subscription/
        notification/
        user/

      shared/
        middleware/
        errors/
        utils/
        config/

Shared code must genuinely be shared.

Do NOT place feature-specific code inside `shared`.

Example Flutter:

    lib/
      core/
        config/
        errors/
        network/
        theme/
        utils/

      features/
        auth/
        property/
        search/
        payment/
        subscription/
        notification/
        profile/

      shared/
        widgets/

Do not create folders merely for appearance. Add structure when it provides a clear responsibility.

---

## 8. Naming

Use predictable names.

Prefer explicit names over clever names.

Examples:

    PropertyRepository
    PropertyService
    CreatePropertyRequest
    PropertyResponse

Avoid:

    Handler
    Manager
    Helper
    Utils

unless the responsibility is genuinely generic.

Use the project's existing naming conventions when they are already established.

Do not introduce inconsistent naming styles.

---

## 9. API Contracts

API contracts must be explicit and consistent.

Every endpoint should define:

- HTTP method
- URL
- Request format
- Validation
- Authentication requirement
- Response format
- Error behavior

Do not make Flutter depend on undocumented backend behavior.

When an API contract changes:
1. Update backend.
2. Update documentation/types.
3. Update Flutter integration.
4. Test both sides.

---

## 10. Error Handling

Errors must be handled intentionally.

Backend:
- Validate input.
- Use consistent error responses.
- Never expose sensitive internal errors.
- Log unexpected errors.

Flutter:
- Handle loading.
- Handle success.
- Handle expected failures.
- Handle network failures.
- Show meaningful user feedback.

Never silently swallow errors.

Avoid:

    try {
      ...
    } catch (_) {}

---

## 11. Security

Never hard-code:

- Passwords
- API keys
- Tokens
- KHQR credentials
- Database credentials
- Private secrets

Use environment variables or the project's secret-management mechanism.

Validate all external input.

Never trust client-side validation alone.

Authorization must be enforced on the backend.

Never expose sensitive database fields through API responses.

---

## 12. Database

Database design must reflect the domain.

Prefer normalized relational structures unless there is a documented reason otherwise.

Avoid:
- Duplicate data without reason
- Uncontrolled JSON blobs
- Generic "everything" tables
- Foreign keys represented only as strings when relationships should exist
- Business rules hidden entirely inside application code

Use migrations for schema changes.

Never manually modify production schema without a migration/recovery plan.

---

## 13. Payments

Payment code is high-risk.

Treat payment processing as an isolated module.

Never assume:

    "payment request succeeded = payment completed"

Payment status must be verified according to the payment provider's mechanism.

Transactions must be traceable.

Store appropriate:
- transaction ID
- payment status
- amount
- timestamps
- related user
- related subscription/post

Payment operations should be idempotent where possible.

Never allow a repeated callback/request to create duplicate transactions or subscriptions.

---

## 14. Testing

Every completed vertical slice must be tested before moving on.

Minimum flow:

    Build
      ↓
    Run
      ↓
    Test happy path
      ↓
    Test validation/errors
      ↓
    Test authorization
      ↓
    Test integration
      ↓
    Refactor
      ↓
    Complete

Do not postpone all testing until the end of the project.

---

## 15. Definition of Done

A feature is NOT complete merely because the code compiles.

A feature is complete when:

- Backend works
- API contract works
- Database works
- Flutter integration works
- Loading/error states work
- Validation works
- Authorization works
- Main user flow works
- Important edge cases are tested
- Code is clean
- No unnecessary duplication exists
- Documentation is updated when necessary

Then mark the feature:

    COMPLETE

---

## 16. Change Control

Do not implement unrelated improvements while working on a feature.

If you discover something outside the current scope:

1. Finish the current feature if possible.
2. Record the issue.
3. Do not silently expand the task.
4. Handle it separately.

Avoid "while I'm here" changes.

---

## 17. Refactoring

Refactor when it improves:

- Cohesion
- Coupling
- Readability
- Testability
- Duplication
- Maintainability

Do not refactor entire modules without reason.

Prefer small, controlled refactors.

Do not rewrite working code merely because another style looks nicer.

---

## 18. Dependencies

Before adding a package/library:

- Check whether existing functionality already solves the problem.
- Prefer stable, well-maintained dependencies.
- Avoid unnecessary packages.
- Do not add a dependency for trivial functionality.

Every dependency increases maintenance cost.

---

## 19. Development Environment

Use separate environments:

    Development
        ↓
    Staging
        ↓
    Production

Never test experimental features directly in production.

Flutter development/testing should use the staging API.

Production credentials must never be committed to source control.

---

## 20. Git

Make small, meaningful commits.

Prefer:

    feat(auth): add login API
    feat(property): create property endpoint
    fix(payment): prevent duplicate transaction
    refactor(property): separate repository logic

Avoid:

    update
    changes
    fix stuff
    final
    test

Do not mix unrelated features in one commit.

---

## 21. Agent Behavior

Before modifying code:

- Inspect relevant existing files.
- Understand current patterns.
- Reuse established architecture.
- Do not invent unnecessary abstractions.

When implementing:

- Make the smallest correct change.
- Keep changes within the current feature.
- Follow existing conventions.
- Avoid unrelated refactoring.

After implementing:

- Check compilation/static analysis.
- Run relevant tests.
- Verify integration.
- Review changed files for unnecessary complexity.

If requirements are ambiguous, do not invent important business rules.

Ask for clarification or clearly state the assumption.

---

## 22. Token-Efficient Agent Behavior

Be concise.

Do not repeatedly explain the architecture.

Do not print entire files unless requested.

When reporting work, use:

    Implemented:
    - ...

    Tested:
    - ...

    Remaining:
    - ...

Only inspect files relevant to the current task.

Do not repeatedly scan the entire repository.

---

## 23. Core Principle

The project is built as a sequence of **small, complete, production-quality vertical slices**.

Prefer:

    SIMPLE
    → COHESIVE
    → DECOUPLED
    → TESTABLE
    → COMPLETE

over:

    FAST
    → LARGE
    → COUPLED
    → "FIX LATER"

**Never optimize for the number of features written. Optimize for the number of features completely delivered.**