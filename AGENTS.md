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
## 24. Final Architecture Rule

> **Organize code by business feature first, then by technical responsibility. Each module owns its business logic and data access. Keep cross-cutting infrastructure in `shared`. Maintain clear dependency direction and avoid circular dependencies. Do not create abstractions, layers, or services unless they solve an actual complexity or maintainability problem.**

---

# CODE MODULARIZATION & MAINTAINABILITY RULES

## Core Principle

All code must be modular, small, cohesive, and easy to understand.

Never solve a large requirement by creating one large file, class, service, controller, widget, or function.

Prefer:

Small responsibility
    ↓
Small module
    ↓
Small files
    ↓
Clear interfaces
    ↓
Easy testing
    ↓
Easy debugging

The codebase must remain understandable by another developer without requiring them to read the entire project.

---

# 1. SINGLE RESPONSIBILITY

Each file, class, service, controller, repository, widget, and function should have one primary responsibility.

BAD:

property_service.dart
- create property
- upload images
- process payments
- send notifications
- search properties
- validate users
- update subscriptions

GOOD:

property_creation_service.dart
property_image_service.dart
property_search_service.dart
property_publication_service.dart

Each component should do one thing well.

---

# 2. KEEP FILES SMALL

Avoid unnecessarily large files.

As a general guideline:

- Prefer files below ~200 lines.
- Files above ~300 lines require review.
- Files above ~500 lines should normally be split.
- Do not split files artificially just to meet a line count.

Line count is a warning signal, not an absolute rule.

A file should be split when it contains multiple responsibilities.

---

# 3. KEEP FUNCTIONS SMALL

Functions should perform one logical operation.

Prefer:

createProperty()
validateProperty()
saveProperty()
publishProperty()

over:

createAndValidateAndUploadAndSaveAndPublishProperty()

A function should be easy to understand without scrolling through hundreds of lines.

If a function requires many levels of nested conditions, consider extracting smaller functions.

---

# 4. KEEP CLASSES FOCUSED

A class should represent one clear responsibility.

BAD:

PropertyService
    ├── property CRUD
    ├── payment
    ├── notification
    ├── image processing
    └── search

GOOD:

PropertyService
PaymentService
NotificationService
MediaService
PropertySearchService

Business workflows may coordinate multiple services, but each service must maintain its own responsibility.

---

# 5. MODULARIZE BY FEATURE

Organize the system by business capability first.

Backend:

modules/
├── auth/
├── users/
├── properties/
├── search/
├── favorites/
├── subscriptions/
├── payments/
├── notifications/
├── media/
└── admin/

Flutter:

features/
├── auth/
├── user/
├── property/
├── search/
├── map/
├── favorites/
├── subscription/
├── payment/
└── notifications/

Do not create global folders such as:

screens/
models/
services/
controllers/

containing everything in the entire application.

Business functionality should remain grouped together.

---

# 6. LAYER RESPONSIBILITY

Backend dependency direction:

Controller
    ↓
Service / Use Case
    ↓
Repository
    ↓
Database

Controller:
- HTTP handling
- Request/response
- Authentication context
- Validation invocation

Service:
- Business rules
- Business workflows
- Coordination

Repository:
- Data persistence
- Queries
- Database interaction

Database layer:
- Database-specific implementation

Never allow controllers to directly perform complex database operations.

---

# 7. FLUTTER RESPONSIBILITY

Preferred flow:

UI
 ↓
ViewModel / State
 ↓
Repository
 ↓
Data Source / API
 ↓
Backend

UI should not contain:

- API calls
- Business rules
- Database logic
- Payment processing
- Complex data transformation

Widgets should primarily render state and handle user interaction.

---

# 8. EXTRACT WHEN COMPLEXITY APPEARS

Do not create unnecessary abstractions before they are needed.

However, split code when one of these occurs:

- File becomes difficult to navigate.
- Class has multiple responsibilities.
- Function performs multiple independent operations.
- Same logic appears in multiple places.
- Business logic is mixed with infrastructure logic.
- Testing becomes difficult.
- A change requires modifying unrelated functionality.
- Dependencies become difficult to understand.
- Circular dependencies appear.

Refactor before continuing to add more functionality.

---

# 9. AVOID GOD CLASSES

Never create classes that become the central location for unrelated logic.

Examples to avoid:

- AppService
- GlobalService
- MainService
- UtilityService
- PropertyManager containing everything
- UserManager containing everything

If a class keeps growing, identify the responsibilities and extract them into focused components.

---

# 10. AVOID GOD FILES

Never allow a single file to contain:

- Multiple unrelated classes
- Multiple unrelated services
- Hundreds of lines of business logic
- API calls + UI + validation + state management
- Multiple unrelated models

One file should normally have one primary abstraction.

---

# 11. DOMAIN BOUNDARIES

Each module owns its business logic.

Example:

properties/
    owns property rules

payments/
    owns payment rules

subscriptions/
    owns subscription rules

notifications/
    owns notification delivery

Do not duplicate the same business rule across modules.

If another module needs functionality, expose a clear service/interface rather than accessing internal implementation details.

---

# 12. CROSS-MODULE COMMUNICATION

Modules must communicate through clear public interfaces.

Example:

Payment module:

PaymentService
    ↓
PaymentProvider

Do not allow:

PropertyService
    ↓
payments/database tables directly

Instead:

PropertyService
    ↓
PaymentService

The exact implementation may vary, but the business boundary must remain clear.

---

# 13. FILE NAMING

Use predictable names.

Examples:

create_property_service
update_property_service
property_repository
property_repository_impl
property_controller
property_validator

Flutter:

property_list_screen
property_detail_screen
property_view_model
property_repository
property_model

Names should describe responsibility.

Avoid vague names:

helper
manager
handler
misc
common
stuff
utils

unless the responsibility is genuinely clear.

---

# 14. ONE CHANGE SHOULD HAVE A SMALL BLAST RADIUS

When modifying a feature, try to minimize the number of unrelated files affected.

Example:

Adding property validation should primarily affect:

property/
├── validators/
└── tests/

It should not require modifying:

auth/
payments/
notifications/
users/

unless there is a real dependency.

This makes bugs easier to locate.

---

# 15. VERTICAL SLICE DEVELOPMENT

Implement features as complete slices.

Example:

AUTHENTICATION

1. Database
2. Backend model
3. Repository
4. Service
5. Controller/API
6. Flutter repository
7. ViewModel
8. Screen
9. Integration
10. Tests

Then mark AUTHENTICATION complete.

Move to:

USER PROFILE

Then:

PROPERTY

Then:

SEARCH

Do not build every backend module first and integrate everything at the end.

---

# 16. BUG TRACEABILITY

Every feature should have a clear path:

UI
↓
ViewModel
↓
Repository
↓
API
↓
Controller
↓
Service
↓
Repository
↓
Database

A bug should be traceable through this chain.

Do not hide business logic inside random utility functions or UI components.

When debugging, identify which layer owns the problem before modifying code.

---

# 17. TESTABILITY

Every business-critical operation should be testable independently.

Examples:

createProperty()
publishProperty()
verifyPayment()
activateSubscription()

Business logic should not require Flutter UI or HTTP requests to be tested.

Use dependency injection where it provides meaningful testability.

---

# 18. REFACTORING RULE

If a feature is becoming difficult to understand, STOP adding new functionality temporarily.

Refactor first.

Example:

Before:

property_service.dart
500+ lines

After:

property_creation_service.dart
property_update_service.dart
property_publication_service.dart
property_search_service.dart
property_validation_service.dart

Then continue development.

Do not knowingly build new functionality on top of clearly problematic structure.

---

# 19. DON'T OVER-ABSTRACT

Modular does NOT mean creating an interface for everything.

Do not create:

IUserService
IUserRepository
IUserManager
IUserHandler
IUserProvider

unless the abstraction provides a real benefit.

Create abstractions when they provide:

* Replaceability
* Testability
* Clear boundaries
* Multiple implementations
* External provider isolation

Avoid abstraction purely for theoretical future requirements.

---

# 20. EXTERNAL PROVIDER ISOLATION

External systems should be isolated behind clear interfaces.

Examples:

PaymentProvider
└── KHQRProvider

StorageProvider
└── S3StorageProvider

NotificationProvider
└── FirebaseNotificationProvider

MapProvider
└── GoogleMapProvider

Business logic should depend on the abstraction, not provider-specific implementation.

This allows providers to be changed without rewriting business logic.

---

# 21. SHARED CODE RULE

Only move code into shared/ or common/ when it is genuinely used across multiple independent modules.

Do not use shared/ as a dumping ground.

If code belongs primarily to one feature, keep it inside that feature.

Prefer:

properties/utils/
over:

shared/property_utils/

when the code is property-specific.

---

# 22. DEPENDENCY RULE

Dependencies should move inward toward business logic.

Avoid circular dependencies.

Example:

GOOD:

Property Controller
↓
Property Service
↓
Property Repository

BAD:

Property Service
↔
Payment Service
↔
Property Service

If two modules become tightly coupled, redesign the interaction.

---

# 23. CHANGE BEFORE ADDING

Before creating a new file/class/service:

1. Search the existing codebase.
2. Check whether similar functionality already exists.
3. Reuse an existing abstraction if appropriate.
4. If the existing abstraction has too many responsibilities, refactor it.
5. Only then create a new component.

Avoid duplicate implementations.

---

# 24. AGENT IMPLEMENTATION PROCESS

For every task:

STEP 1 — Understand

* Identify the feature.
* Identify affected modules.
* Read only relevant files first.

STEP 2 — Plan

* Identify the smallest set of changes.
* Identify new files required.
* Identify existing files that should be reused.

STEP 3 — Implement

* Create small focused components.
* Keep dependencies explicit.
* Follow existing project conventions.

STEP 4 — Test

* Test the smallest affected unit.
* Test the API if applicable.
* Test the complete vertical slice.

STEP 5 — Review
Check:

* Is any file becoming too large?
* Is any class doing too much?
* Is business logic in the correct module?
* Are dependencies clean?
* Is duplicate logic introduced?
* Can another developer easily locate the code?

STEP 6 — Refactor
If the implementation is becoming difficult to maintain, refactor before continuing.

---

# 25. AGENT MUST NOT

Do not:

* Create giant files.
* Create giant classes.
* Create giant functions.
* Put business logic inside controllers.
* Put business logic inside Flutter widgets.
* Put database queries inside controllers.
* Put payment logic inside property services.
* Put unrelated functionality into shared/.
* Create unnecessary abstractions.
* Duplicate business logic.
* Create microservices without a demonstrated requirement.
* Refactor the entire project for a small feature.
* Modify unrelated modules without justification.

---

# 26. QUALITY CHECK BEFORE COMPLETING A TASK

Before reporting a task as complete, verify:

[ ] Responsibilities are clearly separated.
[ ] No unnecessarily large files were created.
[ ] No unnecessarily large functions/classes were created.
[ ] Business logic is in the correct module.
[ ] Dependencies are one-directional.
[ ] No circular dependencies were introduced.
[ ] No duplicate logic was introduced.
[ ] Existing abstractions were reused where appropriate.
[ ] New abstractions are justified.
[ ] Relevant tests pass.
[ ] The feature remains easy to locate and modify.

If several checks fail, refactor before considering the task complete.
