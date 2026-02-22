# Agent TODO: Borrow Checker + Lifetime (Region) Analysis

## Outcome
- [ ] Add ownership, borrowing, and lifetime checking with region constraints.
- [ ] Keep current System F-omega typing behavior unchanged for existing terms.
- [ ] Integrate borrow/lifetime diagnostics into `TypingError` with clear failure modes.
- [ ] Preserve package API compatibility for existing callers (`infer_type`, `check_type`, `type_check`).

## Backward-Compatibility Guardrails
- [ ] Existing AST forms must typecheck exactly as before when no borrow/reference forms are used.
- [ ] Existing public methods keep names/signatures unless a strictly additive overload/option is introduced.
- [ ] Existing tests remain green before enabling new borrow-specific tests by default.
- [ ] New enum variants are additive; old constructors/helpers keep current behavior.
- [ ] New analysis pass is a no-op for borrow-free terms.

## Architecture Game Plan (Phased)

### Phase 0: Design Freeze and Invariants
- [ ] Write a short design note in repo docs with:
- [ ] Ownership model (`Affine` default, optional `Copy` path).
- [ ] Borrow rules (many shared OR one mutable; no aliasing mutation).
- [ ] Region model (constraint-based outlives graph, no ad-hoc lexical-only shortcuts).
- [ ] Escaping rules (no returning references to dead locals).
- [ ] Decide MVP vs stretch:
- [ ] MVP: inferred lifetimes + borrow checking for local scopes.
- [ ] Stretch: explicit lifetime parameters in types/signatures.
- [ ] Define deterministic error precedence when multiple violations exist.

### Phase 1: Core Data Model Additions (`types.mbt`)
- [ ] Add ownership and reference primitives:
- [ ] `Mutability` enum (`Shared`, `Mutable`).
- [ ] `Region` enum (`Named`, `Infer`, `Static` or equivalent).
- [ ] `BorrowKind`/`LoanKind` enum (if distinct from mutability in implementation).
- [ ] Extend `Type` with reference form:
- [ ] `Ref(region, mutability, inner_type)`.
- [ ] Optional future-proofing: additive region quantification form (`ForallRegion`) if explicit lifetime polymorphism is required.
- [ ] Extend `Term` with memory/borrow operations:
- [ ] Borrow creation (`BorrowShared`, `BorrowMut`, or unified borrow constructor).
- [ ] Dereference (`Deref`).
- [ ] Assignment (`Assign`).
- [ ] Optional mut-binding form (`LetMut`) if mutable locals are explicit.
- [ ] Add analysis-side structs (kept additive):
- [ ] `Place` + projection path for fields/tuples/deref.
- [ ] `Loan` with id, place, mutability, origin, and region.
- [ ] `RegionConstraint` for outlives relationships.
- [ ] `BorrowFacts`/`BorrowEnv` summary object for pass output.
- [ ] Extend `TypingError` with borrow/lifetime variants:
- [ ] `UseAfterMove`.
- [ ] `MovedValueBorrow`.
- [ ] `BorrowConflict`.
- [ ] `MutateWhileBorrowed`.
- [ ] `AssignToImmutable`.
- [ ] `BorrowOutlivesOwner` (or `LifetimeTooShort`).
- [ ] `DanglingReferenceEscape`.
- [ ] `InvalidBorrowTarget`.
- [ ] `RegionConstraintUnsatisfied`.

### Phase 2: Typechecker Plumbing (`typechecker.mbt`)
- [ ] Add type inference/checking rules for new term forms:
- [ ] Borrow operations produce `Type::Ref(...)`.
- [ ] Deref requires reference type and returns inner type.
- [ ] Assignment requires mutable place and type compatibility.
- [ ] Update helper operations for new type variant:
- [ ] `normalize_type` and `normalize_type_impl`.
- [ ] `apply_substitution` and substitution internals.
- [ ] `alpha_rename`/capture-avoidance paths that touch `Type`.
- [ ] `compute_free_types` and rename helpers.
- [ ] `types_equal`, `subsumes`, and `unify_types` handling of `Ref`.
- [ ] Add region/lifetime constraint pipeline:
- [ ] `collect_region_constraints(term, type, state)`.
- [ ] `solve_region_constraints(constraints)`.
- [ ] `check_borrow_rules(term, solved_regions, state)`.
- [ ] Integrate pipeline points:
- [ ] Run borrow analysis after successful typing in `infer_type` and `check_type` paths.
- [ ] Keep behavior identical for terms without borrow/reference operations.
- [ ] Add a feature/options entrypoint if needed:
- [ ] `infer_type_with_options` / `check_type_with_options` with defaults preserving current behavior.

### Phase 3: Maintainable Separation (New Modules Recommended)
- [ ] Extract non-typing borrow logic out of monolithic `typechecker.mbt`:
- [ ] `borrow_ir.mbt` (lowering terms into analysis-friendly form with stable node ids).
- [ ] `region_solver.mbt` (outlives graph, SCC/cycle checks, solve).
- [ ] `borrow_checker.mbt` (loan issuance/conflict/move checks).
- [ ] Keep `typechecker.mbt` as orchestrator, not a second monolith.
- [ ] Ensure module boundaries are pure and unit-testable.

### Phase 4: Ownership and Move Semantics
- [ ] Track move state for places:
- [ ] whole-variable moves.
- [ ] partial moves for tuples/records.
- [ ] reinitialization rules after move.
- [ ] Define copyability policy:
- [ ] initial explicit allowlist (primitives/unit).
- [ ] optional trait-based `Copy` integration later.
- [ ] Enforce move/borrow interplay:
- [ ] cannot move while borrowed.
- [ ] cannot mutably borrow moved/uninitialized place.
- [ ] use-after-move diagnostics.

### Phase 5: Regions and Lifetime Inference
- [ ] Introduce region variables for borrow introductions and significant scope boundaries.
- [ ] Generate outlives constraints from:
- [ ] variable scopes.
- [ ] assignment and reborrow relationships.
- [ ] function argument/return reference flow.
- [ ] Solve constraints via fixed-point/topological approach with deterministic ordering.
- [ ] Reject unresolved/contradictory region constraints with specific errors.
- [ ] Optional upgrade path to non-lexical lifetimes (NLL):
- [ ] compute last-use liveness to end borrows earlier than lexical block end.

### Phase 6: Trait, Polymorphism, and Existing Feature Interactions
- [ ] Define and implement interaction with:
- [ ] `Forall` and `BoundedForall`.
- [ ] trait dictionaries (`Dict`, `TraitLam`, `TraitApp`, `TraitMethod`).
- [ ] recursive types (`Mu`), records/variants/tuples, and pattern matching.
- [ ] Prevent unsound dictionary/reference escapes across trait abstraction boundaries.
- [ ] Decide whether trait methods may return borrowed references tied to receiver regions.
- [ ] If explicit lifetime polymorphism is added, ensure instantiation/subsumption handles it.

### Phase 7: Imports, Renaming, and Free-Name Analysis
- [ ] Update rename/free-name helpers for new `Type`/`Term` variants:
- [ ] `rename_type`, `rename_term`, `rename_pattern`, `rename_binding`.
- [ ] `compute_free_types`, `compute_free_terms`, `compute_free_patterns`.
- [ ] Ensure import aliasing/conflict detection remains stable with new constructs.
- [ ] Confirm `collect_dependencies` and `import_module` do not regress with reference-bearing definitions.

### Phase 8: Diagnostics, UX, and Docs
- [ ] Add concise, actionable error text for each borrow/lifetime failure.
- [ ] Include context in errors (variable/place, required vs actual outlives relation).
- [ ] Expand `show.mbt` placeholders for new types/terms to make debug output usable.
- [ ] Update `README.mbt.md` with:
- [ ] ownership model,
- [ ] borrow syntax/semantics,
- [ ] region/lifetime examples,
- [ ] migration notes for old code (expected: no changes unless new features are used).

### Phase 9: API and Tooling Finalization
- [ ] Run `/home/jtenner/.moon/bin/moon test --package jtenner/sfo`.
- [ ] Run `/home/jtenner/.moon/bin/moon info` and inspect `pkg.generated.mbti` for intended additive API only.
- [ ] Run `/home/jtenner/.moon/bin/moon fmt`.
- [ ] Add changelog/release note section documenting new borrow/lifetime checks.

## Core Package Change List (Concrete File Targets)

### `types.mbt`
- [ ] Add new enums/structs for regions, loans, places, constraints, borrow facts.
- [ ] Add `Type::Ref(...)` and term constructors for borrow/deref/assign/mut binding.
- [ ] Add borrow/lifetime `TypingError` variants.
- [ ] Keep old constructors and helper method behavior unchanged.

### `typechecker.mbt`
- [ ] Extend type inference/checking for new term/type forms.
- [ ] Implement region constraint generation + solving.
- [ ] Implement loan conflict and move-state checks.
- [ ] Integrate borrow pass into existing `infer_type`/`check_type` pipeline.
- [ ] Update normalize/unify/substitution/rename/free-name paths for new variants.

### `show.mbt`
- [ ] Add readable rendering for new `Type`, `Term`, and possibly error variants to improve debugging.

### `pkg.generated.mbti`
- [ ] Regenerate and verify only additive API changes are exposed.

### Test files
- [ ] Add new whitebox suites:
- [ ] `typechecker_borrow_core_wbtest.mbt`
- [ ] `typechecker_borrow_infer_check_wbtest.mbt`
- [ ] `typechecker_borrow_regions_wbtest.mbt`
- [ ] `typechecker_borrow_traits_wbtest.mbt`
- [ ] `typechecker_borrow_error_paths_wbtest.mbt`
- [ ] Expand `test_support_wbtest.mbt` with helpers for borrow/region assertions.
- [ ] Keep existing suites unchanged except where additive constructors require pattern updates.

## Feature Backlog With Subtasks

### Feature A: Reference Types and Terms
- [ ] Add AST constructors.
- [ ] Add constructor methods (`Type::ref`, `Term::borrow_shared`, etc.).
- [ ] Add kind/type rules for constructors.
- [ ] Add normalization and substitution coverage.

### Feature B: Place Analysis
- [ ] Implement place extraction from terms (`x`, `x.f`, `x.0`, `*p`).
- [ ] Handle nested projections with deterministic canonicalization.
- [ ] Add place equality/overlap checks for conflict detection.

### Feature C: Loan Tracking
- [ ] Create loan issuance rules.
- [ ] Track active loans by region and place.
- [ ] Implement conflict matrix:
- [ ] shared/shared allowed,
- [ ] shared/mutable denied,
- [ ] mutable/mutable denied except exact reborrow policy if allowed.
- [ ] Add loan expiry based on solved region endpoints.

### Feature D: Move Checking
- [ ] Mark moves on non-copy values.
- [ ] Disallow uses after move.
- [ ] Disallow borrowing moved values.
- [ ] Support reinitialization to restore availability.

### Feature E: Region Constraint Solver
- [ ] Represent outlives graph (`r1 : r2` edges).
- [ ] Generate constraints from scope nesting and borrow/use sites.
- [ ] Solve with deterministic transitive closure/fixed point.
- [ ] Detect unsatisfied constraints and cyclic contradictions where applicable.

### Feature F: Control-Flow-Aware Lifetimes
- [ ] Build lightweight CFG for `Let`, `Match`, and branch joins.
- [ ] Merge move and loan states at join points.
- [ ] Support borrow ending at last use (NLL-style) where feasible.

### Feature G: Trait + Polymorphism Safety
- [ ] Ensure trait dictionary lookup cannot hide lifetime violations.
- [ ] Ensure bounded polymorphism constraints do not lose region obligations.
- [ ] Verify generalized types do not capture local regions unsafely.

### Feature H: Diagnostics and Explainability
- [ ] Map errors to specific term forms and places.
- [ ] Add stable ordering for multi-error scenarios (first causal violation).
- [ ] Include suggested fix hints for common failures.

## Test Matrix: Primary Cases

### Typing + Borrow Basics
- [ ] Shared borrow then read (`&x`, deref/read).
- [ ] Mutable borrow then write (`&mut x`, assignment through deref).
- [ ] Two shared borrows coexisting.
- [ ] Mutable borrow exclusivity against existing shared borrow.
- [ ] Mutable borrow exclusivity against existing mutable borrow.

### Move Semantics
- [ ] Move then use (error).
- [ ] Move then reinitialize then use (ok).
- [ ] Borrow then move while borrow active (error).
- [ ] Move from tuple/record field and access unaffected fields (policy-specific expected behavior).

### Lifetime/Region Soundness
- [ ] Borrow does not outlive owner local scope.
- [ ] Returned reference to parameter with sufficient outlives relation (ok).
- [ ] Returned reference to local temporary (error).
- [ ] Reborrow lifetime shorter than parent borrow (ok).

### Existing Features Interop
- [ ] Borrow inside `Let`, `Lam`, `App`.
- [ ] Borrowed fields in records and tuples.
- [ ] Borrows across `Match` branches with join.
- [ ] Borrows with `Mu`/`Fold`/`Unfold` values (soundness preserved).
- [ ] Trait method calls with borrowed receivers/args.

## Test Matrix: Edge Cases

### Region Solver Edge Cases
- [ ] Unsatisfied outlives constraints with minimal counterexample.
- [ ] Deeply nested region constraints (stress test).
- [ ] Multiple equivalent solutions produce deterministic chosen result.

### Control Flow Edge Cases
- [ ] Borrow introduced in one branch but used after join.
- [ ] Move in one branch, use after join.
- [ ] Early-return-like shape encoded by branch structure with active loans.

### Alias/Projection Edge Cases
- [ ] Overlapping places (`x` vs `x.f`, `*p` aliasing rules).
- [ ] Nested projections with mutable borrow of parent then child access.
- [ ] Tuple index projection conflicts (`x.0` vs whole `x`).

### Polymorphism and Traits Edge Cases
- [ ] Generalization over values containing references.
- [ ] Trait dictionary containing methods that capture local borrows.
- [ ] Bounded polymorphic functions with borrowed arguments.

### Normalization/Substitution Edge Cases
- [ ] Substitution through reference types with bound region/type names.
- [ ] `normalize_type` stability when aliases/enums contain refs.
- [ ] Unification of reference types with region variables and evars.

### Regression and Compatibility
- [ ] Run all existing 98+ whitebox tests unchanged.
- [ ] Confirm no behavior change for borrow-free programs.
- [ ] Confirm import/rename/free-name helpers continue to pass existing suites.

## Definition of Done
- [ ] All new borrow/lifetime suites pass.
- [ ] All existing suites pass without semantic regressions.
- [ ] Public API changes are additive and documented.
- [ ] README and examples include borrow/lifetime usage and limits.
- [ ] Error messages are deterministic and actionable.

