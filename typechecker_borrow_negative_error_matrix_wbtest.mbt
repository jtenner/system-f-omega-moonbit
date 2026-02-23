///|
fn borrow_semantic_error_kinds() -> Array[String] {
  [
    "InvalidBorrowTarget", "BorrowOutlivesOwner", "DanglingReferenceEscape", "RegionConstraintUnsatisfied",
    "UseAfterMove", "MovedValueBorrow", "BorrowConflict", "MutateWhileBorrowed",
    "AssignToImmutable",
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
test "lower_to_borrow_ir accepts all semantic borrow error programs" {
  for kind in borrow_semantic_error_kinds() {
    let result = lower_to_borrow_ir(borrow_semantic_error_term_for_kind(kind))
    assert_true(result is Ok(_))
  }
}

///|
test "collect_region_constraints_from_ir accepts empty and lowered semantic error IR" {
  let empty_ir_result = collect_region_constraints_from_ir(BorrowIr::{
    nodes: [],
  })
  assert_true(empty_ir_result is Ok(_))

  for kind in borrow_semantic_error_kinds() {
    let lowered = match
      lower_to_borrow_ir(borrow_semantic_error_term_for_kind(kind)) {
      Ok(ir) => ir
      Err(_) => panic()
    }
    let result = collect_region_constraints_from_ir(lowered)
    assert_true(result is Ok(_))
  }
}

///|
test "solve_region_constraints handles unresolved placeholders and structural constraints" {
  let unresolved = solve_region_constraints_ir([
    RegionConstraint::placeholder("placeholder.alpha"),
  ])
  assert_true(unresolved is Err(RegionConstraintUnsatisfied(_)))

  let solved = solve_region_constraints_ir([
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
test "check_borrow_rules_ir keeps ordinary constructors inert" {
  let lowered = match
    lower_to_borrow_ir(ordinary_constructor_term("OrdinaryConstructorNoBorrow")) {
    Ok(ir) => ir
    Err(_) => panic()
  }
  let result = check_borrow_rules_ir(
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
test "collect_region_constraints API accepts pure and semantic error terms" {
  let state = TypeCheckerState::fresh()

  let pure = state.collect_region_constraints(
    Term::let_term("x", Term::unit(), Term::var_term("x")),
    Type::unit(),
  )
  assert_true(pure is Ok(_))

  for kind in borrow_semantic_error_kinds() {
    let result = state.collect_region_constraints(
      borrow_semantic_error_term_for_kind(kind),
      Type::unit(),
    )
    assert_true(result is Ok(_))
  }
}

///|
test "solve_region_constraints API reports unresolved placeholders" {
  let state = TypeCheckerState::fresh()
  let unresolved = state.solve_region_constraints([
    RegionConstraint::placeholder("placeholder.beta"),
  ])
  assert_true(unresolved is Err(RegionConstraintUnsatisfied(_)))
}

///|
test "analyze_borrows preserves legacy no-op when disabled" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    borrow_semantic_error_term_for_kind("UseAfterMove"),
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
test "analyze_borrows reports expected semantic error kinds when enabled" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for kind in borrow_semantic_error_kinds() {
    assert_true(
      typing_error_kind_from_analysis_result(
        state.analyze_borrows(
          borrow_semantic_error_term_for_kind(kind),
          Type::unit(),
          options,
        ),
      ) ==
      kind,
    )
  }
}

///|
test "infer_type_with_borrow_analysis reports expected semantic error kinds when enabled" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for kind in borrow_semantic_error_kinds() {
    assert_true(
      typing_error_kind_from_type_result(
        state.infer_type_with_borrow_analysis(
          borrow_semantic_error_term_for_kind(kind),
          options,
        ),
      ) ==
      kind,
    )
  }
}

///|
test "check_type_with_borrow_analysis reports expected semantic error kinds when enabled" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for kind in borrow_semantic_error_kinds() {
    assert_true(
      typing_error_kind_from_checked_result(
        state.check_type_with_borrow_analysis(
          borrow_semantic_error_term_for_kind(kind),
          Type::unit(),
          options,
        ),
      ) ==
      kind,
    )
  }
}
