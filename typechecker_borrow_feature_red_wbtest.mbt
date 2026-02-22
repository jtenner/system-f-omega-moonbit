///|
fn has_outlives_edge(
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
test "RED: lower_to_borrow_ir should succeed for pure unit terms" {
  let result = lower_to_borrow_ir(Term::unit())
  assert_true(result is Ok(_))
}

///|
test "RED: lower_to_borrow_ir should produce at least one node for let terms" {
  let term = Term::let_term("x", Term::unit(), Term::var_term("x"))
  let result = lower_to_borrow_ir(term)
  assert_true(result is Ok(_))
  match result {
    Ok(ir) => assert_true(ir.nodes.length() > 0)
    _ => ()
  }
}

///|
test "RED: collect_region_constraints_from_ir should accept empty IR" {
  let result = collect_region_constraints_from_ir(BorrowIr::{ nodes: [] })
  assert_true(result is Ok(_))
}

///|
test "RED: collect_region_constraints should accept pure terms" {
  let state = TypeCheckerState::fresh()
  let result = state.collect_region_constraints(Term::unit(), Type::unit())
  assert_true(result is Ok(_))
}

///|
test "RED: solve_region_constraints should solve basic outlives edges" {
  let result = solve_region_constraints_placeholder([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
  ])
  assert_true(result is Ok(_))
  match result {
    Ok(solution) =>
      assert_true(
        has_outlives_edge(solution, Region::named("a"), Region::named("b")),
      )
    _ => ()
  }
}

///|
test "RED: solve_region_constraints should compute transitive outlives" {
  let result = solve_region_constraints_placeholder([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
    RegionConstraint::outlives(Region::named("b"), Region::named("c")),
  ])
  assert_true(result is Ok(_))
  match result {
    Ok(solution) =>
      assert_true(
        has_outlives_edge(solution, Region::named("a"), Region::named("c")),
      )
    _ => ()
  }
}

///|
test "RED: check_borrow_rules should accept pure unit terms" {
  let state = TypeCheckerState::fresh()
  let result = state.check_borrow_rules(
    Term::unit(),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: check_borrow_rules should accept simple let terms" {
  let state = TypeCheckerState::fresh()
  let term = Term::let_term("x", Term::unit(), Term::var_term("x"))
  let result = state.check_borrow_rules(
    term,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: analyze_borrows should accept pure unit terms" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: analyze_borrows should remain ok across options for pure terms" {
  let state = TypeCheckerState::fresh()
  let opts = BorrowCheckerOptions::{
    enabled: true,
    use_nll: true,
    diagnostics: false,
  }
  let result = state.analyze_borrows(Term::unit(), Type::unit(), opts)
  assert_true(result is Ok(_))
}

///|
test "RED: infer wrapper should match legacy inference for pure terms when enabled" {
  let state = TypeCheckerState::fresh()
  let legacy = state.infer_type(Term::unit())
  let with_borrow = state.infer_type_with_borrow_analysis(
    Term::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(legacy is Ok(_))
  assert_true(with_borrow is Ok(_))
  match (legacy, with_borrow) {
    (Ok(a), Ok(b)) => assert_true(a == b)
    _ => ()
  }
}

///|
test "RED: check wrapper should match legacy checking for pure terms when enabled" {
  let state = TypeCheckerState::fresh()
  let legacy = state.check_type(Term::unit(), Type::unit())
  let with_borrow = state.check_type_with_borrow_analysis(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(legacy is Ok(_))
  assert_true(with_borrow is Ok(_))
  match (legacy, with_borrow) {
    (Ok(a), Ok(b)) => assert_true(a.ty == b.ty)
    _ => ()
  }
}

///|
test "RED: synthetic probe tags should not trigger feature errors" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    borrow_probe_term("__err_use_after_move"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: invalid-borrow-target probe should behave like ordinary constructor" {
  let state = TypeCheckerState::fresh()
  let result = state.infer_type_with_borrow_analysis(
    borrow_probe_term("__err_invalid_borrow_target"),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}
