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
test "infer_type_with_borrow_analysis returns placeholder error when enabled" {
  let state = TypeCheckerState::fresh()
  let result = state.infer_type_with_borrow_analysis(
    Term::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(Message(_)))
}

///|
test "check_type_with_borrow_analysis returns placeholder error when enabled" {
  let state = TypeCheckerState::fresh()
  let result = state.check_type_with_borrow_analysis(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(Message(_)))
}
