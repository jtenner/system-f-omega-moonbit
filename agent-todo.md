# Agent TODO: Borrow Checker and Lifetime Backlog

## Verified State (2026-02-22)
- Library tests are green: `/home/jtenner/.moon/bin/moon test --package jtenner/sfo` -> `Total tests: 655, passed: 655, failed: 0`.
- Completed historical tasks were audited and removed from this list.
- This backlog now contains only unfinished, concrete tasks.

## Priority P0: Native Borrow Semantics in Core Typechecker
- [x] Add native borrow forms to core AST and types (`Type::Ref`, borrow term constructors) in `types.mbt`, and regenerate API with `moon info`.
- [x] Implement infer/check rules for native borrow terms in `typechecker.mbt` so borrow programs typecheck without intrinsic-name placeholders.
- [ ] Wire borrow analysis into the primary infer/check flow policy (not wrapper-only behavior), while preserving non-borrow behavior.
- [x] Replace wrapper-level dependency on unbound intrinsic vars (`borrow_shared`, `borrow_mut`, etc.) with typed native borrow syntax.
- [x] Add focused whitebox tests for native borrow typing (shared borrow, mutable borrow, deref, assign, move).

### P0 follow-ups discovered (2026-02-22)
- [ ] Define deterministic region allocation semantics for native `Type::Ref` inference (current implementation uses `Region::static_region()` as a temporary default).
- [ ] Tighten native borrow target validation so `infer/check` and borrow IR lowering share one canonical place-extraction routine.
- [ ] Add focused tests for native `check_type` region/mutability mismatch behavior (`Ref` expected type interactions).

## Priority P1: IR and Region Soundness
- [ ] Define and document a stable borrow IR schema for control flow, places, and scope boundaries in `borrow_scaffold.mbt`.
- [ ] Replace sentinel placeholder region errors (`__err_*`) in runtime semantics with structural region constraints derived from IR.
- [ ] Implement deterministic branch-join merge for moved-place state (path-sensitive meet instead of linear accumulation).
- [ ] Extend region constraint generation for trait dictionary flow and polymorphic boundaries.
- [ ] Add explicit tests for region safety across trait abstraction and polymorphic generalization boundaries.

## Priority P2: Probe Removal and Test Migration
- [ ] Retire probe-only error-path scaffolding (`borrow_probe_term`, `__err_*`-driven scenarios) once native borrow terms are in place.
- [ ] Replace remaining fixed support builders that emit legacy `BorrowOp...X` markers with generalized path-based builders.
- [ ] Keep equivalent semantic coverage by migrating probe tests to real borrow AST programs before deleting probe tests.
- [ ] Remove any remaining semantic coupling to constructor-name tags in `borrow_scaffold.mbt`.

## Priority P3: Diagnostics and Developer UX
- [ ] Finalize actionable payload formats for all borrow/lifetime errors in `types.mbt` (especially `BorrowConflict`).
- [ ] Add payload assertions in tests for all borrow/lifetime errors (operation, place path, active/conflicting loan context, region constraint).
- [ ] Implement robust `Show`/pretty rendering for borrow structures and borrow/lifetime errors in `show.mbt`.
- [ ] Add a short borrow/lifetime guide with examples and fix patterns in project docs.

## Priority P4: Code Organization and Maintenance
- [ ] Split `borrow_scaffold.mbt` into focused modules (`borrow_ir.mbt`, `region_solver.mbt`, `borrow_checker.mbt`) with no behavior regression.
- [ ] Regenerate and review `pkg.generated.mbti` after each API-affecting change.
- [ ] Keep `moon fmt` and `/home/jtenner/.moon/bin/moon test --package jtenner/sfo` green after each vertical slice.

## Validation Commands
- `/home/jtenner/.moon/bin/moon test --package jtenner/sfo`
- `/home/jtenner/.moon/bin/moon fmt`
- `/home/jtenner/.moon/bin/moon info`
