///|
test "infer_type_with_borrow_analysis matches legacy inference when disabled" {
  let state = TypeCheckerState::fresh()
  let term = Term::unit()
  let legacy = must_type(state.infer_type(term))
  let scaffold = must_type(
    state.infer_type_with_borrow_analysis(
      term,
      BorrowCheckerOptions::disabled(),
    ),
  )
  assert_true(legacy == scaffold)
}

///|
test "check_type_with_borrow_analysis matches legacy checking when disabled" {
  let state = TypeCheckerState::fresh()
  let term = Term::unit()
  let expected = Type::unit()

  let legacy = must_checked(state.check_type(term, expected))
  let scaffold = must_checked(
    state.check_type_with_borrow_analysis(
      term,
      expected,
      BorrowCheckerOptions::disabled(),
    ),
  )

  assert_true(legacy.ty == scaffold.ty)
}

///|
test "infer_type_with_borrow_analysis succeeds for pure terms when enabled" {
  let state = TypeCheckerState::fresh()
  let legacy = state.infer_type(Term::unit())
  let result = state.infer_type_with_borrow_analysis(
    Term::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
  match (legacy, result) {
    (Ok(a), Ok(b)) => assert_true(a == b)
    _ => panic()
  }
}

///|
test "check_type_with_borrow_analysis succeeds for pure terms when enabled" {
  let state = TypeCheckerState::fresh()
  let legacy = state.check_type(Term::unit(), Type::unit())
  let result = state.check_type_with_borrow_analysis(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
  match (legacy, result) {
    (Ok(a), Ok(b)) => assert_true(a.ty == b.ty)
    _ => panic()
  }
}
