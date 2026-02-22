///|
test "lower_to_borrow_ir lowers pure terms into IR nodes" {
  let result = lower_to_borrow_ir(Term::unit())
  assert_true(result is Ok(_))
  match result {
    Ok(ir) => assert_true(ir.nodes.length() == 1)
    _ => panic()
  }
}

///|
test "region collection and solving APIs produce structural results" {
  let state = TypeCheckerState::fresh()
  let term = Term::let_term("x", Term::unit(), Term::var_term("x"))

  let constraints_result = state.collect_region_constraints(term, Type::unit())
  assert_true(constraints_result is Ok(_))

  match constraints_result {
    Ok(constraints) => assert_true(constraints.length() > 0)
    _ => panic()
  }

  let solve_result = state.solve_region_constraints([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
    RegionConstraint::outlives(Region::named("b"), Region::named("c")),
  ])
  assert_true(solve_result is Ok(_))
}

///|
test "borrow analysis orchestration is no-op when disabled" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::disabled(),
  )

  match result {
    Ok(analysis) => {
      assert_eq(analysis.facts.loans.length(), 0)
      assert_eq(analysis.facts.constraints.length(), 0)
      assert_eq(analysis.solved.unresolved.length(), 0)
    }
    _ => panic()
  }
}

///|
test "borrow analysis orchestration succeeds when enabled for pure terms" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}
