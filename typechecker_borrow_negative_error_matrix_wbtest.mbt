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
fn negative_matrix_has_outlives_edge(
  solution : RegionSolution,
  left : Region,
  right : Region,
) -> Bool {
  for entry in solution.outlives {
    let (from, tos) = entry
    if from == left && tos.contains(right) {
      return true
    }
  }
  false
}

///|
test "lower_to_borrow_ir accepts all synthetic probe terms as ordinary constructors" {
  for c in borrow_probe_error_cases() {
    let (tag, _) = c
    let result = lower_to_borrow_ir(borrow_probe_term(tag))
    assert_true(result is Ok(_))
  }
}

///|
test "collect_region_constraints_from_ir accepts empty and lowered probe IR" {
  let empty_ir_result = collect_region_constraints_from_ir(BorrowIr::{
    nodes: [],
  })
  assert_true(empty_ir_result is Ok(_))

  for c in borrow_probe_error_cases() {
    let (tag, _) = c
    let lowered = match lower_to_borrow_ir(borrow_probe_term(tag)) {
      Ok(ir) => ir
      Err(_) => panic()
    }
    let result = collect_region_constraints_from_ir(lowered)
    assert_true(result is Ok(_))
  }
}

///|
test "solve_region_constraints handles generic placeholders and structural constraints" {
  let outlives = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_borrow_outlives_owner"),
  ])
  assert_true(outlives is Err(RegionConstraintUnsatisfied(_)))

  let dangling = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_dangling_reference_escape"),
  ])
  assert_true(dangling is Err(RegionConstraintUnsatisfied(_)))

  let unsatisfied = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
  ])
  assert_true(
    typing_error_kind_from_solution_result(unsatisfied) ==
    "RegionConstraintUnsatisfied",
  )

  let solved = solve_region_constraints_placeholder([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
    RegionConstraint::outlives(Region::named("b"), Region::named("c")),
  ])
  assert_true(solved is Ok(_))
  match solved {
    Ok(solution) =>
      assert_true(
        negative_matrix_has_outlives_edge(
          solution,
          Region::named("a"),
          Region::named("c"),
        ),
      )
    _ => panic()
  }
}

///|
test "check_borrow_rules_placeholder treats probe-tag IR as ordinary and succeeds" {
  for c in borrow_probe_error_cases() {
    let (tag, _) = c
    let lowered = match lower_to_borrow_ir(borrow_probe_term(tag)) {
      Ok(ir) => ir
      Err(_) => panic()
    }
    let result = check_borrow_rules_placeholder(
      lowered,
      RegionSolution::empty(),
      BorrowCheckerOptions::default(),
    )
    assert_true(result is Ok(_))
  }
}

///|
test "check_borrow_rules_placeholder returns empty facts for ok probe" {
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
test "collect_region_constraints API accepts pure and probe terms" {
  let state = TypeCheckerState::fresh()

  let pure = state.collect_region_constraints(
    Term::let_term("x", Term::unit(), Term::var_term("x")),
    Type::unit(),
  )
  assert_true(pure is Ok(_))

  for c in borrow_probe_error_cases() {
    let (tag, _) = c
    let result = state.collect_region_constraints(
      borrow_probe_term(tag),
      Type::unit(),
    )
    assert_true(result is Ok(_))
  }
}

///|
test "solve_region_constraints API keeps known placeholder constraints generic" {
  let state = TypeCheckerState::fresh()

  let outlives = state.solve_region_constraints([
    RegionConstraint::placeholder("__err_borrow_outlives_owner"),
  ])
  assert_true(outlives is Err(RegionConstraintUnsatisfied(_)))

  let dangling = state.solve_region_constraints([
    RegionConstraint::placeholder("__err_dangling_reference_escape"),
  ])
  assert_true(dangling is Err(RegionConstraintUnsatisfied(_)))

  let unsatisfied = state.solve_region_constraints([
    RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
  ])
  assert_true(unsatisfied is Err(RegionConstraintUnsatisfied(_)))
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
test "analyze_borrows accepts all probe error tags when enabled" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_probe_error_cases() {
    let (tag, _) = c
    assert_true(
      typing_error_kind_from_analysis_result(
        state.analyze_borrows(borrow_probe_term(tag), Type::unit(), options),
      ) ==
      "Ok",
    )
  }
}

///|
test "infer_type_with_borrow_analysis accepts all probe tags when enabled" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_probe_error_cases() {
    let (tag, _) = c
    assert_true(
      typing_error_kind_from_type_result(
        state.infer_type_with_borrow_analysis(borrow_probe_term(tag), options),
      ) ==
      "Ok",
    )
  }
}

///|
test "check_type_with_borrow_analysis accepts all probe tags when enabled" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_probe_error_cases() {
    let (tag, _) = c
    assert_true(
      typing_error_kind_from_checked_result(
        state.check_type_with_borrow_analysis(
          borrow_probe_term(tag),
          Type::unit(),
          options,
        ),
      ) ==
      "Ok",
    )
  }
}
