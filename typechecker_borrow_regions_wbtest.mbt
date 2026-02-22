///|
test "lower_to_borrow_ir is scaffolded with placeholder error" {
  let result = lower_to_borrow_ir(Term::unit())
  assert_true(result is Err(Message(_)))
}

///|
test "region collection and solving APIs are scaffolded" {
  let state = TypeCheckerState::fresh()

  let constraints_result = state.collect_region_constraints(
    Term::unit(),
    Type::unit(),
  )
  assert_true(constraints_result is Err(Message(_)))

  let solve_result = state.solve_region_constraints([])
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
test "borrow analysis orchestration returns placeholder error when enabled" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(Message(_)))
}
