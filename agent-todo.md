# Agent TODO: Remaining Backlog

## Verified State (2026-02-23)
- Library tests are green: `/home/jtenner/.moon/bin/moon test --package jtenner/sfo` -> `Total tests: 751, passed: 751, failed: 0`.
- Completed items were removed during cleanup. This file tracks only unfinished work.

## Priority P0: README Beginner Guide and Full-Library Examples
- P0 status: completed on 2026-02-23; active engineering priority now moves to P1 borrow soundness/policy work.
- [x] Rewrite `README.mbt.md` intro for type-theory beginners with a step-by-step mental model: `Kind`, `Type`, `Term`, `TypeCheckerState`, and context/meta state.
- [x] Add a "Borrow Checker Quickstart" section with a runnable `Term::borrow_shared` example pair (accepted + rejected) and explanation.
- [x] Add a "Borrow Checker Quickstart" section with a runnable `Term::borrow_mut` example pair (accepted + rejected) and explanation.
- [x] Add a "Borrow Checker Quickstart" section with a runnable `Term::deref` example pair (accepted + rejected) and explanation.
- [x] Add a "Borrow Checker Quickstart" section with a runnable `Term::assign` example pair (accepted + rejected) and explanation.
- [x] Add a "Borrow Checker Quickstart" section with a runnable `Term::move_term` example pair (accepted + rejected) and explanation.
- [x] Extend `typechecker_readme_quickstart_wbtest.mbt` doc-smoke coverage for `Term::assign` and `Term::move_term` quickstart snippets once those sections are added.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `UseAfterMove` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `MovedValueBorrow` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `BorrowConflict` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `MutateWhileBorrowed` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `AssignToImmutable` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `BorrowOutlivesOwner` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `DanglingReferenceEscape` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `InvalidBorrowTarget` with minimal failing program and fix.
- [x] Add "Borrow Errors and Fix Patterns" coverage for `RegionConstraintUnsatisfied` with minimal failing program and fix.
- [x] Add a beginner cookbook example for higher-kinded types and kind checking.
- [x] Add a beginner cookbook example for type-level lambdas and type application.
- [x] Add a beginner cookbook example for `Forall` and `BoundedForall`.
- [x] Add a beginner cookbook example for traits, dictionaries, and bounded polymorphism.
- [x] Add a beginner cookbook example for records, variants, tuples, and pattern matching.
- [x] Add a beginner cookbook example for recursive types (`Mu`) with `fold`/`unfold`.
- [x] Add a beginner cookbook example for module import/dependency helpers and rename APIs.
- [x] Add a compact "From Error to Fix" troubleshooting table mapping common `TypingError` variants to likely causes and first debugging steps.
- [x] Create/update whitebox doc-smoke tests for key README snippets so examples remain executable.
- [x] Add doc-smoke assertions for upcoming "Borrow Errors and Fix Patterns" README examples to keep error/fix snippets executable.
- [x] Require `/home/jtenner/.moon/bin/moon test --package jtenner/sfo` after README edits and record the result in backlog updates.

## Priority P1: Borrow Soundness and Policy Consolidation
- [x] Split `check_type` into explicit core/policy layers so fallback infer paths can reuse native-policy analysis state instead of re-scanning terms in mixed infer/check flows.
- [x] Extend region constraint generation for trait dictionary flow and polymorphic boundaries.
- [x] Add explicit tests for region safety across trait abstraction and polymorphic generalization boundaries.
- [x] Remove legacy `collect_known_region_probe_errors` sentinel special-casing once direct placeholder compatibility tests are migrated to structural region-op programs.
- [x] Add focused coverage for generalized `BorrowOpRegionUnsatisfied` payload shape for `infer:<id> -> static`.
- [x] Add focused coverage for generalized `BorrowOpRegionUnsatisfied` payload shape for `static -> infer:<id>`.
- [x] Replace shape-based fallback detection in `check_type_with_native_policy_flag` with execution-path signaling from `check_type` core to guarantee exact no-rescan behavior as check rules evolve.
- [x] Add targeted nested mixed infer/check tests to ensure native policy executes exactly once for fallback-rooted terms and still runs for explicit-check roots with nested borrows.
- [x] Add mixed infer/check regression coverage for additional explicit-check roots (`Lam`, `TyLam`, `TraitLam`, `Move`) to lock root-only fallback signaling semantics.
- [x] Add borrow-lifetime regression tests that distinguish nested projection borrows that end in-expression from borrows that escape to outer scope.
- [x] Extend projection-escape lifetime lowering coverage beyond tuple literals (e.g. record projection and non-literal tuple sources) to prevent unsound borrow shortening in additional projection forms.
- [x] Add IR-level regression assertions for tuple-projection lowering so selected-element vs non-selected-element scope depths remain stable across refactors.
- [x] Extend tuple-projection passthrough lowering beyond let-identity sources to additional non-literal producers (e.g. match/if-style branch joins and function-returned tuples) without regressing current scope semantics.
- [x] Add record-projection passthrough lowering for non-literal record sources and IR-level selected-vs-non-selected field depth assertions.
- [ ] Extend projection passthrough to additional call shapes beyond direct lambda applications (e.g. let-bound function aliases) while keeping conservative fallback for unknown callees.
- [ ] Add nested-producer regression coverage (`let -> match -> projection`, `let -> app -> projection`) to lock scope-depth and branch-boundary invariants across composed lowering paths.

## Priority P2: Probe Removal and Test Migration
- P2 status: completed on 2026-02-23 via semantic borrow-program migration in negative/spec/edge-case suites.
- [x] Migrate remaining probe-based error tests to real borrow AST programs while preserving semantic coverage.
- [x] Retire probe-only scaffolding (`borrow_probe_term`, `__err_*`-driven scenarios) after equivalent native/semantic coverage is confirmed.

## Priority P3: Diagnostics and Developer UX
- [ ] Finalize actionable payload formats for all borrow/lifetime errors in `types.mbt` (especially `BorrowConflict`).
- [ ] Add payload assertions in tests for all borrow/lifetime errors (operation, place path, active/conflicting loan context, region constraint).
- [ ] Implement robust `Show`/pretty rendering for borrow structures and borrow/lifetime errors in `show.mbt`.

## Priority P4: Code Organization and Maintenance
- [ ] Split `borrow_scaffold.mbt` into focused modules (`borrow_ir.mbt`, `region_solver.mbt`, `borrow_checker.mbt`) with no behavior regression.
- [ ] Regenerate and review `pkg.generated.mbti` after each API-affecting change.
- [ ] Keep `/home/jtenner/.moon/bin/moon fmt` and `/home/jtenner/.moon/bin/moon test --package jtenner/sfo` green after each vertical slice.
- [ ] Remove or consume currently unused borrow test-support helpers (`typing_error_kind_from_ir_result`, `typing_error_kind_from_constraints_result`, `typing_error_kind_from_facts_result`) to keep test runs warning-clean.

## Validation Commands
- `/home/jtenner/.moon/bin/moon test --package jtenner/sfo`
- `/home/jtenner/.moon/bin/moon fmt`
- `/home/jtenner/.moon/bin/moon info`
