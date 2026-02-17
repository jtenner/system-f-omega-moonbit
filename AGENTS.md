# Project Agents.md Guide

This repository is a [MoonBit](https://docs.moonbitlang.com) implementation of a
System F-omega style typechecker with:

- higher-kinded types
- type-level lambdas and applications
- polymorphism (`Forall`, `BoundedForall`)
- records, variants, tuples
- recursive types (`Mu`) + fold/unfold
- trait dictionaries and bounded polymorphism
- module-level import/rename/dependency analysis helpers

You can browse/install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- Root package sources:
  - `types.mbt`: core data model (`Kind`, `Type`, `Term`, `Pattern`, context,
    bindings, errors)
  - `typechecker.mbt`: almost all algorithmic logic and constructors
  - `show.mbt`: placeholder `Show` impls for `Type`/`Term`/`Pattern`
  - `sfo_mnb.mbt`: package entry placeholder
- Root test suites (whitebox):
  - `test_support_wbtest.mbt`
  - `typechecker_core_wbtest.mbt`
  - `typechecker_kind_pattern_wbtest.mbt`
  - `typechecker_infer_check_wbtest.mbt`
  - `typechecker_traits_wbtest.mbt`
  - `typechecker_env_import_wbtest.mbt`
- Command package:
  - `cmd/main/main.mbt` (template executable)

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

- `Kind`: `Star` or `Arrow(Kind, Kind)`.
- `Type`: includes rigid vars/constructors, evars, arrows, polymorphism, type
  lambdas/apps, records/variants, recursive `Mu`, tuples.
- `Term`: value-level language with typed lambdas/apps, type apps, trait
  dictionaries and accessors, pattern matching, fold/unfold.
- `Pattern`: variable/wildcard/constructor/record/variant/tuple patterns.

### State and environments

- `TypeCheckerState` = `Context` + `MetaEnv`.
- `MetaEnv` tracks:
  - `counter`
  - `kinds` of each evar id
  - solved `solutions` (`evar -> type`)
- `Context` is an ordered binding stack:
  `Term`, `Type`, `TraitDef`, `TraitImpl`, `Dict`, `TypeAlias`, `Enum`.

### Core pipeline

- `infer_type` infers term types bottom-up.
- `check_type` checks against expected type, with structured rules and fallback
  to infer+subsumption.
- `check_kind` validates kinding of types.
- `unify_types` + `solve_constraints` drives constraint solving.
- `normalize_type` expands aliases/enums, performs type-level beta-reduction,
  resolves solved evars.

### Notable subsystems

- Pattern handling: `check_pattern`, `check_exhaustive`, `bindings`.
- Traits:
  - `add_trait_def`, `add_trait_impl`, `add_dict`
  - `check_trait_implementation`, `check_trait_constraints`
  - term forms `TraitLam`, `TraitApp`, `TraitMethod`
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
- Dictionary-related operations depend on both `TraitImpl` bindings and `Dict`
  bindings (for context-level resolution APIs).

## Test Plan and Coverage

Current whitebox suite covers all major moving parts with 98 tests:

1. `typechecker_core_wbtest.mbt`:
   core equalities, substitution, meta solving, spine helpers, instantiation,
   misc utilities.
2. `typechecker_kind_pattern_wbtest.mbt`:
   kind checking, type/kind unification, constraints, pattern checking,
   exhaustiveness.
3. `typechecker_infer_check_wbtest.mbt`:
   term inference/checking across lambdas/apps/records/tuples/variants/match/
   fold-unfold + inference modes.
4. `typechecker_traits_wbtest.mbt`:
   trait definitions, dictionaries, impl lookup, bounded trait application,
   auto-instantiation.
5. `typechecker_env_import_wbtest.mbt`:
   add_* APIs, normalization for aliases/enums, dependency cycles, import
   aliasing/conflicts, rename/free-name/context helpers.

`test_support_wbtest.mbt` provides reusable setup and result-unwrapping helpers.

## Tooling and Commands

- Moon binary for this workspace:
  `/home/jtenner/.moon/bin/moon`
- Format/interface update:
  - `/home/jtenner/.moon/bin/moon info`
  - `/home/jtenner/.moon/bin/moon fmt`
- Run tests for library package:
  - `/home/jtenner/.moon/bin/moon test --package jtenner/sfo_mnb`

Note: running `moon test` for the whole workspace may include `cmd/main` test
targets and can fail independently of library tests; use the package-scoped
command above for typechecker validation.

## Practical Testing Notes

- `Kind` does not implement `Show`, so avoid `assert_eq` directly on `Kind`;
  prefer `assert_true(kind == Star)` style.
- `Type`/`Term`/`Pattern` `Show` impls are placeholders in `show.mbt`; prefer
  structural assertions over string rendering.
- For error-path checks, prefer pattern matching on `Err(...)` variants.

## Maintenance Workflow

When changing semantics or APIs:

1. Update implementation in `typechecker.mbt` (and `types.mbt` if required).
2. Add/update tests in subsystem-specific `_wbtest.mbt` files.
3. Run:
   - `/home/jtenner/.moon/bin/moon test --package jtenner/sfo_mnb`
   - `/home/jtenner/.moon/bin/moon info`
   - `/home/jtenner/.moon/bin/moon fmt`
4. Review `.mbti` diffs to confirm intended API surface changes.
