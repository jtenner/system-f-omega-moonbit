# Project Agents.md Guide

This repository is a [MoonBit](https://docs.moonbitlang.com) implementation of a
System F-omega style typechecker with:

- higher-kinded types
- type-level lambdas and applications
- polymorphism (`Forall`, `BoundedForall`)
- records, variants, tuples
- recursive types (`Mu`) + fold/unfold
- native borrow/reference terms and types (`Ref`, `borrow_shared`,
  `borrow_mut`, `deref`, `assign`, `move`)
- region/lifetime constraint solving + borrow conflict checking
- trait dictionaries and bounded polymorphism
- module-level import/rename/dependency analysis helpers

You can browse/install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- Root package sources:
  - `types.mbt`: core data model (`Kind`, `Type`, `Term`, `Pattern`, context,
    bindings, borrow/lifetime data structures, errors)
  - `typechecker.mbt`: type/kind inference+checking, unification, normalization,
    trait logic, import/rename/free-name analysis, and native borrow typing rules
  - `borrow_ir.mbt`: borrow operation parsing, place extraction/key-path helpers,
    and IR lowering entrypoints
  - `region_solver.mbt`: region-constraint collection from IR + region solving
  - `borrow_checker.mbt`: borrow-rule checking over lowered IR and solved regions
  - `borrow_diagnostics.mbt`: diagnostics helper glue for place-path conversion
    and invalid-target operation extraction used by borrow payload assembly
  - `borrow_scaffold.mbt`: borrow analysis orchestration wrappers and shared
    helper internals used by IR/solver/checker phases
  - `show.mbt`: `Show`/`Debug`/pretty-print rendering for core syntax trees
  - `sfo_mnb.mbt`: package entry notes for this single-package library
- Root docs:
  - `README.mbt.md` (package readme used by MoonBit metadata)
  - `README.md` (copy kept in repo root)
- Root test helpers:
  - `test_support_wbtest.mbt`
  - `borrow_test_support_wbtest.mbt`
- Root test suites (whitebox):
  - Core/type-system suites:
    `typechecker_core_wbtest.mbt`, `typechecker_kind_pattern_wbtest.mbt`,
    `typechecker_infer_check_wbtest.mbt`, `typechecker_traits_wbtest.mbt`,
    `typechecker_env_import_wbtest.mbt`, `typechecker_roundout_wbtest.mbt`
  - Error/coverage suites:
    `typechecker_error_paths_wbtest.mbt`,
    `typechecker_error_branches2_wbtest.mbt`,
    `typechecker_error_coverage3_wbtest.mbt`,
    `typechecker_coverage_boost_wbtest.mbt`
  - Borrow/lifetime suites: all `typechecker_borrow_*_wbtest.mbt` files,
    including matrix suites such as
    `typechecker_borrow_feature_mountain_red_wbtest.mbt`
  - README parity suites:
    `readme_examples_wbtest.mbt`,
    `typechecker_readme_quickstart_wbtest.mbt`,
    `typechecker_readme_cookbook_wbtest.mbt`,
    `typechecker_readme_borrow_errors_wbtest.mbt`
- Other top-level tests:
  - `sanity_wbtest.mbt`
  - `sfo_mnb_wbtest.mbt`
  - `sfo_mnb_test.mbt`

MoonBit package conventions still apply: `moon.pkg` per package, `_test.mbt` for
blackbox tests, `_wbtest.mbt` for whitebox tests.

## Coding Conventions

- Keep MoonBit block style: each top-level block separated by `///|`.
- Block order is intentionally non-semantic; refactors can move blocks safely.
- Prefer constructor methods on owning types (`Type::con`, `Type::arrow`, etc.).
- State-mutating behavior should remain instance methods on `TypeCheckerState`.
- Keep public API additions reflected in `pkg.generated.mbti` via `moon info`.

## Typechecker Architecture

### Data model

- Core syntax:
  - `Kind`: `Star` or `Arrow(Kind, Kind)`.
  - `Type`: includes rigid vars/constructors, evars, arrows, native refs
    (`Ref(Region, Mutability, Type)`), polymorphism, type lambdas/apps,
    records/variants, recursive `Mu`, tuples.
  - `Term`: includes typed lambdas/apps, type apps, native borrow operations
    (`BorrowShared`, `BorrowMut`, `Deref`, `Assign`, `Move`), trait dictionaries,
    pattern matching, fold/unfold, tuples.
  - `Pattern`: variable/wildcard/constructor/record/variant/tuple patterns.
- Borrow/lifetime model:
  - `Mutability`, `Region`, `PlaceProjection`, `Place`, `LoanId`, `Loan`.
  - `RegionConstraint` (`Outlives`, `Equal`, `Placeholder`).
  - `BorrowCheckerOptions`, `RegionSolution`, `BorrowFacts`,
    `BorrowAnalysisResult`.
  - `BorrowIrNode`, `BorrowIr` (lowered IR for borrow analysis).
  - Compatibility layers: `BorrowType` and `BorrowTerm`.
  - Diagnostics: `BorrowConflictPayload`, `BorrowErrorPayload`.
  - Borrow-related `TypingError` variants include:
    `UseAfterMove`, `MovedValueBorrow`, `BorrowConflict`,
    `MutateWhileBorrowed`, `AssignToImmutable`, `BorrowOutlivesOwner`,
    `DanglingReferenceEscape`, `InvalidBorrowTarget`,
    `RegionConstraintUnsatisfied`.

### State and environments

- `TypeCheckerState` = `Context` + `MetaEnv`.
- `MetaEnv` tracks:
  - `counter`
  - `kinds` of each evar id
  - solved `solutions` (`evar -> type`)
- `Context` is an ordered binding stack:
  `Term`, `Type`, `TraitDef`, `TraitImpl`, `Dict`, `TypeAlias`, `Enum`.
- Borrow/lifetime analysis outputs are returned explicitly as
  `BorrowAnalysisResult` (not persisted in `TypeCheckerState`).

### Core pipeline

- `infer_type` infers term types bottom-up.
- `check_type` checks against expected type, with structured rules and fallback
  to infer+subsumption.
- `check_kind` validates kinding of types.
- `unify_types` + `solve_constraints` drives constraint solving.
- `normalize_type` expands aliases/enums, performs type-level beta-reduction,
  resolves solved evars.
- Native borrow policy is integrated into inference/checking paths; terms that
  contain native borrow syntax trigger borrow/lifetime analysis.
- Borrow/lifetime pipeline:
  - `lower_to_borrow_ir`
  - `collect_region_constraints_from_ir`
  - `solve_region_constraints_ir`
  - `check_borrow_rules_ir`
  - state wrappers:
    `collect_region_constraints`, `solve_region_constraints`,
    `check_borrow_rules`, `analyze_borrows`,
    `infer_type_with_borrow_analysis`, `check_type_with_borrow_analysis`

### Notable subsystems

- Pattern handling: `check_pattern`, `check_exhaustive`, `bindings`.
- Traits:
  - `add_trait_def`, `add_trait_impl`, `add_dict`
  - `check_trait_implementation`, `check_trait_constraints`
  - term forms `TraitLam`, `TraitApp`, `TraitMethod`
- Borrow/lifetimes:
  - place extraction: `borrow_place_from_term`
  - IR + region constraints: `lower_to_borrow_ir`,
    `collect_region_constraints_from_ir`
  - region solve + rule checks: `solve_region_constraints_ir`,
    `check_borrow_rules_ir`
  - top-level orchestration: `analyze_borrows`
- Import/deps:
  - `collect_dependencies` (DFS + cycle detection)
  - `import_module` (dependency closure, topo order, aliasing, conflict policy)
- Renaming/free-name analysis:
  - `rename_type`, `rename_term`, `rename_pattern`, `rename_binding`
  - `compute_free_types`, `compute_free_patterns`, `compute_free_terms`

## Important Invariants

- Value-level term types should kind-check to `Star` where required.
- EVar kind information must be present in `meta.kinds` when evars are created.
- Substitution must respect binders (`Forall`, `BoundedForall`, `Lam`, `Mu`,
  `TyLam`, trait type vars).
- `normalize_type` is used before many equality/unification decisions.
- Borrow targets for native operations must be valid place expressions
  (var/con/project/tuple-project/deref-shaped places).
- Borrow conflict detection uses prefix-overlap on `Place` projections:
  parent/child places alias for conflict checks.
- Mutable borrows conflict with any overlapping active loan; shared borrows
  conflict with overlapping mutable loans.
- Moved places are tracked by canonical place keys; assignment to a place
  reinitializes that place and its sub-places.
- Region solve returns `Err(RegionConstraintUnsatisfied(...))` if unresolved
  placeholder constraints remain.
- Dictionary-related operations depend on both `TraitImpl` bindings and `Dict`
  bindings (for context-level resolution APIs).

## Test Plan and Coverage

Current test suite contains 776 tests (whitebox + blackbox) with strong borrow
and error-path coverage.

1. Core typechecker suites:
   `typechecker_core_wbtest.mbt`,
   `typechecker_kind_pattern_wbtest.mbt`,
   `typechecker_infer_check_wbtest.mbt`,
   `typechecker_traits_wbtest.mbt`,
   `typechecker_env_import_wbtest.mbt`,
   `typechecker_roundout_wbtest.mbt`.
2. Borrow/lifetime functional suites:
   `typechecker_borrow_core_wbtest.mbt`,
   `typechecker_borrow_native_wbtest.mbt`,
   `typechecker_borrow_infer_check_wbtest.mbt`,
   `typechecker_borrow_regions_wbtest.mbt`,
   `typechecker_borrow_traits_wbtest.mbt`,
   `typechecker_borrow_payload_wbtest.mbt`,
   plus borrow-edge and error-path suites.
3. Borrow/lifetime matrix/stress suites:
   `typechecker_borrow_feature_red_wbtest.mbt`,
   `typechecker_borrow_feature_mountain_red_wbtest.mbt`,
   `typechecker_borrow_spec_matrix_wbtest.mbt`,
   `typechecker_borrow_negative_error_matrix_wbtest.mbt`.
4. Error/coverage suites:
   `typechecker_error_paths_wbtest.mbt`,
   `typechecker_error_branches2_wbtest.mbt`,
   `typechecker_error_coverage3_wbtest.mbt`,
   `typechecker_coverage_boost_wbtest.mbt`.
5. README parity + examples:
   `readme_examples_wbtest.mbt`,
   `typechecker_readme_quickstart_wbtest.mbt`,
   `typechecker_readme_cookbook_wbtest.mbt`,
   `typechecker_readme_borrow_errors_wbtest.mbt`.

`test_support_wbtest.mbt` and `borrow_test_support_wbtest.mbt` provide reusable
setup and result-unwrapping helpers.

## Tooling and Commands

- Moon binary for this workspace:
  `/home/jtenner/.moon/bin/moon`
- Format/interface update:
  - `/home/jtenner/.moon/bin/moon check --package-path . --deny-warn`
  - `/home/jtenner/.moon/bin/moon info`
  - `/home/jtenner/.moon/bin/moon fmt`
- Run tests for library package:
  - `/home/jtenner/.moon/bin/moon test`

Note: running `moon test` for the whole workspace may include other targets and
can fail independently of library tests; use the package-scoped command above
for typechecker validation.

## Practical Testing Notes

- `Kind`, `Type`, `Term`, and `Pattern` implement `Show`; `assert_eq` on those
  values is fine.
- For semantic checks, prefer structural assertions/pattern matching over
  snapshots unless output formatting is the behavior under test.
- For error-path checks, prefer matching on explicit `Err(...)` variants.
- For borrow diagnostics, prefer checking structured payloads
  (`TypingError::borrow_payload`) instead of brittle string matching.

## Maintenance Workflow

When changing semantics or APIs:

1. Update implementation in `typechecker.mbt` / `borrow_scaffold.mbt`
   (and `types.mbt` if required).
2. Add/update tests in subsystem-specific `_wbtest.mbt` files.
3. Run:
   - `/home/jtenner/.moon/bin/moon check --package-path . --deny-warn`
   - `/home/jtenner/.moon/bin/moon test`
   - `/home/jtenner/.moon/bin/moon info`
   - `/home/jtenner/.moon/bin/moon fmt`
4. Review `.mbti` diffs to confirm intended API surface changes.
5. If behavior visible in docs changed, update README snippets and matching
   README parity tests.
