///|
fn borrow_probe_error_cases() -> Array[(String, String)] {
  [
    ("__err_invalid_borrow_target", "InvalidBorrowTarget"),
    ("__err_borrow_outlives_owner", "BorrowOutlivesOwner"),
    ("__err_dangling_reference_escape", "DanglingReferenceEscape"),
    ("__err_region_constraint_unsatisfied", "RegionConstraintUnsatisfied"),
    ("__err_use_after_move", "UseAfterMove"),
    ("__err_moved_value_borrow", "MovedValueBorrow"),
    ("__err_borrow_conflict", "BorrowConflict"),
    ("__err_mutate_while_borrowed", "MutateWhileBorrowed"),
    ("__err_assign_to_immutable", "AssignToImmutable"),
  ]
}

///|
test "lower_to_borrow_ir produces expected lowering-stage error kinds" {
  for c in borrow_probe_error_cases() {
    let (tag, expected_kind) = c
    let result = lower_to_borrow_ir(borrow_probe_term(tag))
    if expected_kind == "InvalidBorrowTarget" {
      assert_true(typing_error_kind_from_ir_result(result) == expected_kind)
    } else {
      assert_true(result is Ok(_))
    }
  }
}

///|
test "collect_region_constraints_from_ir produces region-stage errors only for non-probe ir" {
  let bad_ir = BorrowIr::{ nodes: [] }
  let bad_result = collect_region_constraints_from_ir(bad_ir)
  assert_true(
    typing_error_kind_from_constraints_result(bad_result) == "Message",
  )

  for c in borrow_probe_error_cases() {
    let (tag, _expected_kind) = c
    let lowered = match lower_to_borrow_ir(borrow_probe_term(tag)) {
      Ok(ir) => ir
      Err(_) => continue
    }
    let result = collect_region_constraints_from_ir(lowered)
    assert_true(result is Ok(_))
  }
}

///|
test "solve_region_constraints returns expected region-related error kinds" {
  let outlives = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_borrow_outlives_owner"),
  ])
  assert_true(
    typing_error_kind_from_solution_result(outlives) == "BorrowOutlivesOwner",
  )

  let dangling = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_dangling_reference_escape"),
  ])
  assert_true(
    typing_error_kind_from_solution_result(dangling) ==
    "DanglingReferenceEscape",
  )

  let unsatisfied = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
  ])
  assert_true(
    typing_error_kind_from_solution_result(unsatisfied) ==
    "RegionConstraintUnsatisfied",
  )

  let empty = solve_region_constraints_placeholder([])
  assert_true(empty is Ok(_))
}

///|
test "check_borrow_rules_placeholder returns expected borrow conflict and move errors" {
  let tags = [
    ("__err_use_after_move", "UseAfterMove"),
    ("__err_moved_value_borrow", "MovedValueBorrow"),
    ("__err_borrow_conflict", "BorrowConflict"),
    ("__err_mutate_while_borrowed", "MutateWhileBorrowed"),
    ("__err_assign_to_immutable", "AssignToImmutable"),
  ]

  for entry in tags {
    let (tag, expected_kind) = entry
    let lowered = match lower_to_borrow_ir(borrow_probe_term(tag)) {
      Ok(ir2) => ir2
      Err(_) => panic()
    }

    let result = check_borrow_rules_placeholder(
      lowered,
      RegionSolution::empty(),
      BorrowCheckerOptions::default(),
    )
    assert_true(typing_error_kind_from_facts_result(result) == expected_kind)
  }
}

///|
test "check_borrow_rules_placeholder succeeds for ok probe" {
  let lowered = match lower_to_borrow_ir(borrow_probe_term("__ok_borrow")) {
    Ok(ir) => ir
    Err(_) => panic()
  }

  let result = check_borrow_rules_placeholder(
    lowered,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )

  match result {
    Ok(facts) => {
      assert_eq(facts.loans.length(), 0)
      assert_eq(facts.constraints.length(), 0)
    }
    _ => panic()
  }
}

///|
test "collect_region_constraints API maps probe tags to expected constraints behavior" {
  let state = TypeCheckerState::fresh()

  let message_result = state.collect_region_constraints(
    Term::unit(),
    Type::unit(),
  )
  assert_true(
    typing_error_kind_from_constraints_result(message_result) == "Message",
  )

  let tags = [
    "__err_borrow_outlives_owner", "__err_dangling_reference_escape", "__err_region_constraint_unsatisfied",
    "__err_use_after_move", "__ok_borrow",
  ]

  for tag in tags {
    let result = state.collect_region_constraints(
      borrow_probe_term(tag),
      Type::unit(),
    )
    assert_true(result is Ok(_))
  }
}

///|
test "solve_region_constraints API maps placeholder constraints to expected error kinds" {
  let state = TypeCheckerState::fresh()

  assert_true(
    typing_error_kind_from_solution_result(
      state.solve_region_constraints([
        RegionConstraint::placeholder("__err_borrow_outlives_owner"),
      ]),
    ) ==
    "BorrowOutlivesOwner",
  )

  assert_true(
    typing_error_kind_from_solution_result(
      state.solve_region_constraints([
        RegionConstraint::placeholder("__err_dangling_reference_escape"),
      ]),
    ) ==
    "DanglingReferenceEscape",
  )

  assert_true(
    typing_error_kind_from_solution_result(
      state.solve_region_constraints([
        RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
      ]),
    ) ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "analyze_borrows preserves legacy no-op when disabled" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    borrow_probe_term("__err_use_after_move"),
    Type::unit(),
    BorrowCheckerOptions::disabled(),
  )

  match result {
    Ok(analysis) => {
      assert_eq(analysis.facts.loans.length(), 0)
      assert_eq(analysis.solved.unresolved.length(), 0)
    }
    _ => panic()
  }
}

///|
test "analyze_borrows propagates all probe error kinds when enabled" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_probe_error_cases() {
    let (tag, expected_kind) = c
    assert_true(
      typing_error_kind_from_analysis_result(
        state.analyze_borrows(borrow_probe_term(tag), Type::unit(), options),
      ) ==
      expected_kind,
    )
  }
}

///|
test "infer_type_with_borrow_analysis propagates all probe error kinds" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_probe_error_cases() {
    let (tag, expected_kind) = c
    assert_true(
      typing_error_kind_from_type_result(
        state.infer_type_with_borrow_analysis(borrow_probe_term(tag), options),
      ) ==
      expected_kind,
    )
  }
}

///|
test "check_type_with_borrow_analysis propagates all probe error kinds" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_probe_error_cases() {
    let (tag, expected_kind) = c
    assert_true(
      typing_error_kind_from_checked_result(
        state.check_type_with_borrow_analysis(
          borrow_probe_term(tag),
          Type::unit(),
          options,
        ),
      ) ==
      expected_kind,
    )
  }
}
