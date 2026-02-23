# Agent TODO: Active Backlog

## Verified State (2026-02-23)
- Library tests are green: `/home/jtenner/.moon/bin/moon test --package jtenner/sfo` -> `Total tests: 780, passed: 780, failed: 0`.
- Warning audit is clean: `/home/jtenner/.moon/bin/moon check --package-path . --deny-warn`.
- Interface metadata is current: `/home/jtenner/.moon/bin/moon info` (no `pkg.generated.mbti` diff in this slice).
- Completed history was archived; this file now tracks only active and newly discovered work.

## Priority P4: Code Organization and Maintenance
- P4 status: in progress on 2026-02-23; borrow pipeline was modularized, with one diagnostics relocation slice still open.
- [ ] Move diagnostics payload assembly (`TypingError::borrow_payload` and closely-related glue) out of `borrow_scaffold.mbt` into `borrow_diagnostics.mbt` to co-locate diagnostics logic.
- [ ] Add focused regression tests for diagnostics helper behavior (`invalid_target_operation_from_details` extraction, place path roundtrip in payload fields) independent of pretty-print formatting.
- [ ] Keep `/home/jtenner/.moon/bin/moon fmt`, `/home/jtenner/.moon/bin/moon check --package-path . --deny-warn`, and `/home/jtenner/.moon/bin/moon test --package jtenner/sfo` green after each vertical slice.

## Recently Completed (2026-02-23 Round 4)
- [x] Relocated diagnostics helper glue (`place_key`, `place_from_key_path`, `invalid_target_operation_from_details`) from `borrow_scaffold.mbt` into `borrow_diagnostics.mbt`.
- [x] Added direct IR regression coverage for TyApp-wrapped intrinsic conflict behavior in `check_borrow_rules_ir`.
- [x] Added README doc-smoke coverage for TyApp-wrapped intrinsic call examples and synced README snippets to executable helper tests.
- [x] Re-ran `/home/jtenner/.moon/bin/moon info` and confirmed no unintended `.mbti` surface drift in this slice.

## Validation Commands
- `/home/jtenner/.moon/bin/moon test --package jtenner/sfo`
- `/home/jtenner/.moon/bin/moon fmt`
- `/home/jtenner/.moon/bin/moon check --package-path . --deny-warn`
- `/home/jtenner/.moon/bin/moon info`
