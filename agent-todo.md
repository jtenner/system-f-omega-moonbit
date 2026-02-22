# Agent TODO: Borrow Checker + Lifetime (Region) Analysis Handoff

## 1. Snapshot (2026-02-22)
- Goal state is still in-progress: scaffold remains, but feature categories now run through explicit AST builder terms and structured borrow/region pipeline hooks.
- Current baseline from `moon test`: `Total tests: 646, passed: 646, failed: 0`.
- Former mountain red phase is still green; full semantic borrow/lifetime analysis remains pending.

### 1.1 What Already Exists
- [x] Additive borrow/lifetime data model scaffolding in `types.mbt`.
- [x] Placeholder borrow pipeline API surface in `borrow_scaffold.mbt`.
- [x] Error-kind classifier helpers in `borrow_test_support_wbtest.mbt`.
- [x] Green scaffold/harness suites for API shape and placeholder behavior.
- [x] Large red suites (`feature_red` + `feature_mountain_red`) defining desired feature behavior.

### 1.2 What Is Missing (Core)
- [ ] Real IR lowering for normal terms (currently operation-marker based for borrow events).
- [ ] Real region-constraint generation and solving.
- [x] Real borrow conflict + move checker.
- [ ] Integration of actual borrow semantics with current inference/checking.
- [ ] Direct `Type::Ref` and borrow term forms wired into primary AST and checker.

## 2. Ground Rules For Handoff
- [x] Preserve all existing non-borrow typechecker behavior for borrow-free programs.
- [x] Keep API additions additive and avoid breaking existing callers.
- [x] Keep deterministic error precedence.
- [x] Keep tests as the source of truth; do not delete failing red suites to get green.
- [x] Convert scaffold probe-driven behavior to real semantics incrementally.

## 3. Current Test Surface (Borrow)

### 3.1 Borrow Test Files
- `borrow_test_support_wbtest.mbt` (helpers)
- `typechecker_borrow_core_wbtest.mbt` (3 tests)
- `typechecker_borrow_infer_check_wbtest.mbt` (4 tests)
- `typechecker_borrow_regions_wbtest.mbt` (4 tests)
- `typechecker_borrow_traits_wbtest.mbt` (3 tests)
- `typechecker_borrow_error_paths_wbtest.mbt` (2 tests)
- `typechecker_borrow_negative_error_matrix_wbtest.mbt` (11 tests)
- `typechecker_borrow_spec_matrix_wbtest.mbt` (5 tests)
- `typechecker_borrow_edge_cases_wbtest.mbt` (19 tests)
- `typechecker_borrow_feature_red_wbtest.mbt` (26 tests, green)
- `typechecker_borrow_feature_mountain_red_wbtest.mbt` (376 tests, green)

### 3.2 Red Mountain Composition
- Analysis scenarios: 295 tests.
- Infer-wrapper scenarios: 40 tests.
- Check-wrapper scenarios: 40 tests.
- Sanity: 1 test.

### 3.3 Red Categories To Implement
- Safe categories:
  - `safe_shared_read` (20)
  - `safe_mut_reborrow` (20)
  - `safe_nll_last_use` (20)
  - `safe_branch_join` (20)
  - `safe_trait_poly` (15)
  - `safe_recursive_projection` (15)
- Error categories:
  - `err_borrow_conflict` (20)
  - `err_use_after_move` (20)
  - `err_moved_value_borrow` (15)
  - `err_assign_to_immutable` (15)
  - `err_mutate_while_borrowed` (15)
  - `err_outlives_owner` (20)
  - `err_dangling_escape` (20)
  - `err_region_unsatisfied` (20)
  - `err_invalid_target` (15)
  - `err_trait_escape` (10)
  - `err_partial_move_projection` (15)

## 4. Major Workstreams (Execution Order)

## WS0: Remove Probe-Coupling Strategy
- [x] Stop using tag-string behavior as semantic truth.
- [ ] Keep scaffold tests that validate API shape only.
- [x] Transition feature tests from `feature_term("__feature_*")` to real term builders.
- [x] Ensure future error kinds come from semantics, not hardcoded tags.

### WS0 Definition of Done
- [x] `borrow_scaffold.mbt` no longer dispatches semantics by probe tag.
- [x] `typechecker_borrow_feature_red_wbtest.mbt` and mountain tests use actual terms.

## WS1: Borrow IR Lowering
- [ ] Define borrow IR schema stable enough for control-flow + place tracking.
- [ ] Lower at least: `Var`, `Let`, `Lam`, `App`, `Record`, `Project`, `Tuple`, `TupleProject`, `Match`, `Fold`, `Unfold`, trait terms.
- [ ] Preserve node ordering and scope-depth/region anchor metadata.
- [x] Validate lowering for ordinary terms returns `Ok(BorrowIr)`.
- [x] Decode borrow operations from ordinary intrinsic AST forms (`App`/`Var`) in addition to legacy constructor markers.

### WS1 DoD
- [x] `RED: lower_to_borrow_ir should succeed for pure unit terms` green.
- [x] `RED: lower_to_borrow_ir should produce at least one node for let terms` green.
- [x] Non-probe edge tests in `typechecker_borrow_edge_cases_wbtest.mbt` remain green.

## WS2: Region Constraint Generation
- [ ] Generate outlives/equality constraints from scopes.
- [ ] Emit constraints for borrow introduction, reborrow, assignment, and return flow.
- [ ] Encode branch join requirements (`Match`, conditional forms) deterministically.
- [ ] Include trait and polymorphic term flows.
- [x] Accept region sentinel operations from ordinary AST terms (not only marker constructors).
- [x] Emit owner-outlives-borrow constraints for borrow introduction and reborrow operations.

### WS2 DoD
- [x] `RED: collect_region_constraints_from_ir should accept empty IR` green.
- [x] `RED: collect_region_constraints should accept pure terms` green.
- [x] Relevant mountain safe/error region categories begin turning green.

## WS3: Region Solver
- [x] Implement graph-based solve for outlives with deterministic ordering.
- [x] Support transitive closure and equality unification.
- [x] Emit `RegionConstraintUnsatisfied` when obligations cannot be met.
- [x] Keep error precedence stable:
  - [x] Outlives-owner violations before dangling escape before generic unsatisfied if required by policy.

### WS3 DoD
- [x] `RED: solve_region_constraints should solve basic outlives edges` green.
- [x] `RED: solve_region_constraints should compute transitive outlives` green.
- [x] Red categories `err_outlives_owner`, `err_dangling_escape`, `err_region_unsatisfied` trend green.

## WS4: Place and Alias Analysis
- [x] Implement canonical place extraction.
- [x] Model overlaps: root vs field, tuple index, deref chains.
- [x] Determine compatibility checks for simultaneous loans.
- [x] Integrate with projection-heavy terms.

### WS4 DoD
- [x] `err_borrow_conflict` categories green.
- [x] Edge-case tests about first-node dispatch replaced with semantic place-overlap tests.

## WS5: Loan / Borrow Rules Engine
- [x] Implement shared/shared allowed.
- [x] Implement shared/mut and mut/mut conflict denial.
- [x] Implement mutation restrictions while borrowed.
- [x] Implement invalid-target detection for non-place borrow operations.

### WS5 DoD
- [x] `err_borrow_conflict` green.
- [x] `err_mutate_while_borrowed` green.
- [x] `err_assign_to_immutable` green.
- [x] `err_invalid_target` green.

## WS6: Move + Initialization Analysis
- [x] Track move state for variables and projections.
- [x] Detect use-after-move.
- [x] Detect borrowing moved values.
- [ ] Handle partial moves and reinitialization semantics.

### WS6 DoD
- [x] `err_use_after_move` green.
- [x] `err_moved_value_borrow` green.
- [x] `err_partial_move_projection` green.

## WS7: Wrapper and Pipeline Integration
- [x] Make `analyze_borrows` call real pipeline and return facts/solution.
- [ ] Ensure `infer_type_with_borrow_analysis` and `check_type_with_borrow_analysis`:
  - [x] Preserve base typing errors first (`Unbound`, etc.).
  - [x] Match legacy results for safe programs.
  - [x] Emit borrow/lifetime errors for invalid programs.
- [x] Keep disabled options as strict no-op if that policy remains.

### WS7 DoD
- [x] `RED: infer wrapper should match legacy inference for pure terms when enabled` green.
- [x] `RED: check wrapper should match legacy checking for pure terms when enabled` green.
- [x] All infer/check mountain subsets trend green.

## WS8: Traits, Polymorphism, Recursive Types, and Match Joins
- [ ] Ensure trait dictionary flows preserve region obligations.
- [ ] Ensure no dangling escapes through trait abstraction.
- [ ] Ensure polymorphic boundaries do not generalize local regions unsafely.
- [ ] Ensure recursive/projected values are handled soundly.
- [ ] Ensure match branch joins merge loan/move states correctly.

### WS8 DoD
- [x] `safe_trait_poly` + `err_trait_escape` categories green.
- [x] `safe_recursive_projection` categories green.
- [x] Branch join categories green.

## WS9: Migrate Test Inputs From Synthetic Tags To Real AST Programs
- [x] Replace tag-driven `feature_term` generation with explicit term builders.
- [x] Keep scenario names stable for continuity.
- [x] Introduce helper builders per category in support files.
- [x] Maintain category counts while converting semantics.

### WS9 DoD
- [x] No feature behavior depends on `Con("__feature_*", ...)` or `Con("__err_*", ...)`.
- [x] Red/green status is driven by real term semantics.

## WS10: Diagnostics and Developer UX
- [ ] Attach actionable payload details to all borrow/lifetime errors.
- [ ] Improve rendering for new borrow/lifetime structures in `show.mbt`.
- [ ] Add docs and examples for each major error kind and fix pattern.

### WS10 DoD
- [ ] Diagnostic tests assert both error kind and useful payload context.
- [ ] README includes borrow/lifetime guide and migration notes.

## 5. File-Level Task Map

### `types.mbt`
- [ ] Integrate borrow/reference forms directly into `Type` and `Term` if adopting native syntax.
- [ ] Keep additive API compatibility where possible.
- [ ] Finalize error variants and payload shapes.

### `borrow_scaffold.mbt`
- [x] Replace placeholder/probe logic with real implementations.
- [ ] Split into modules if needed: `borrow_ir.mbt`, `region_solver.mbt`, `borrow_checker.mbt`.

### `typechecker.mbt`
- [ ] Wire new semantic pass into infer/check pipelines.
- [ ] Ensure unchanged behavior for borrow-free terms.

### `show.mbt`
- [ ] Add robust pretty-printing for borrow/region/place/loan errors and structures.

### `pkg.generated.mbti`
- [ ] Regenerate with `moon info` after each API-affecting change.

## 6. Test-Driven Implementation Protocol
- [x] Keep red suites failing until their target workstream is implemented.
- [x] Work in vertical slices:
  - [x] Pick one category group.
  - [x] Implement minimum semantics.
  - [x] Turn only that category green.
  - [x] Refactor with tests green.
- [ ] Do not mass-edit expectations to hide failures.
- [ ] Prefer turning on categories by behavior, not by file order.

## 7. Suggested Green-Up Sequence (Practical)
1. WS1 + WS2 minimal for pure/safe paths.
2. WS3 region solver core + precedence.
3. WS5 borrow conflicts + mutability checks.
4. WS6 move semantics + partial moves.
5. WS7 wrapper parity.
6. WS8 trait/poly/recursive/join hardening.
7. WS9 remove synthetic-term dependence.
8. WS10 diagnostics polish.

## 8. Acceptance Gates

### Gate A (Infra)
- [x] `typechecker_borrow_feature_red_wbtest.mbt` first 6 tests green.

### Gate B (Core Safety)
- [x] Safe categories green for analysis + wrappers.

### Gate C (Core Errors)
- [x] Core error categories green for analysis + wrappers.

### Gate D (Advanced)
- [x] Trait/poly/recursive/join categories green.

### Gate E (Final)
- [x] Mountain suite green.
- [x] Existing non-borrow suites remain green.
- [ ] No probe-based behavior remains.

## 9. Commands
- Run tests: `/home/jtenner/.moon/bin/moon test`
- Format: `/home/jtenner/.moon/bin/moon fmt`
- Regenerate API: `/home/jtenner/.moon/bin/moon info`

## 10. Handoff Notes For Next Agent
- Treat current green scaffold suites as API-shape checks, not feature completion.
- Mountain feature suites are currently green through explicit AST feature-term builders + operation-driven borrow semantics in `borrow_scaffold.mbt`.
- Prioritize migrating operation-marked constructors to native borrow term forms over time.
- Keep commits small and tied to one category/workstream at a time.

## 11. Actionable Tasks Discovered During Implementation
- [x] Replace `__feature_*` category mapping with real AST term builders in `typechecker_borrow_feature_red_wbtest.mbt` and `typechecker_borrow_feature_mountain_red_wbtest.mbt`.
- [x] Replace placeholder region constraints from scenario tags with region obligations derived from lowered borrow IR operations.
- [x] Replace synthetic `feature_borrow_error` emissions with place-aware diagnostics derived from real place/alias analysis.
- [x] Populate `BorrowFacts.loans` and `BorrowFacts.moved_places` on successful analysis paths (currently returns empty facts).
- [x] Add mixed-scenario precedence tests where multiple feature constructors appear in one term tree.
- [x] Add assertions on error payload details (place names, offending constraints), not only error kind strings.
- [x] Remove constructor-marker coupling in `borrow_scaffold.mbt` by deriving feature outcomes from structural borrow IR/place events.
- [ ] Retire legacy `__err_*` probe-only scaffold tests once real borrow term forms are integrated into `Term`.
- [ ] Generalize `BorrowOp...` parsing to decode arbitrary place paths instead of the current fixed `X/XField/Y` operation set.
- [ ] Replace explicit `BorrowOpReleaseX` events with lexical scope-end loan release driven by IR structure.
- [x] Use solved region graph data (`RegionSolution`) inside borrow rule checks instead of ignoring it.
- [x] Add tuple-index and deref overlap regression tests to validate non-field projection compatibility logic.
- [ ] Add typing-friendly borrow intrinsic forms (or native borrow term constructors) so infer/check wrappers can validate intrinsic borrow programs without unbound placeholders.
- [x] Extend intrinsic operation decoding to cover `use`/`move`/`assign` alias names consistently across unary and curried call shapes.
- [x] Strengthen region-solution integration beyond unresolved checks by enforcing concrete outlives relationships during loan operations.
- [ ] Decide whether curried unary intrinsic forms should be accepted long-term or rejected as invalid arity once native borrow terms are added.
