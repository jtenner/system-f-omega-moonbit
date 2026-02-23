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

///|
fn infer_check_native_conflict_term() -> Term {
  Term::let_term(
    "x",
    Term::unit(),
    Term::tuple_project(
      Term::tuple([
        Term::borrow_mut(Term::var_term("x")),
        Term::borrow_shared(Term::var_term("x")),
        Term::unit(),
      ]),
      2,
    ),
  )
}

///|
test "infer_type_with_borrow_analysis matches infer_type for native borrow conflicts" {
  let state = TypeCheckerState::fresh()
  let term = infer_check_native_conflict_term()
  let direct = state.infer_type(term)
  let wrapped = state.infer_type_with_borrow_analysis(
    term,
    BorrowCheckerOptions::default(),
  )

  assert_true(typing_error_kind_from_type_result(direct) == "BorrowConflict")
  assert_true(typing_error_kind_from_type_result(wrapped) == "BorrowConflict")
}

///|
test "check_type_with_borrow_analysis matches check_type for native borrow conflicts" {
  let state = TypeCheckerState::fresh()
  let term = infer_check_native_conflict_term()
  let direct = state.check_type(term, Type::unit())
  let wrapped = state.check_type_with_borrow_analysis(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )

  assert_true(typing_error_kind_from_checked_result(direct) == "BorrowConflict")
  assert_true(
    typing_error_kind_from_checked_result(wrapped) == "BorrowConflict",
  )
}

///|
test "check_type_with_borrow_analysis enforces native borrow policy for explicit expected tuples" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::unit()),
  ])
  let term = Term::tuple([
    Term::borrow_mut(Term::var_term("x")),
    Term::borrow_shared(Term::var_term("x")),
    Term::unit(),
  ])
  let expected = Type::tuple([
    Type::ref_type(
      Region::named("borrow::x"),
      Mutability::mutable(),
      Type::unit(),
    ),
    Type::ref_type(
      Region::named("borrow::x"),
      Mutability::shared(),
      Type::unit(),
    ),
    Type::unit(),
  ])

  let result = state.check_type_with_borrow_analysis(
    term,
    expected,
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_checked_result(result) == "BorrowConflict")
}

///|
test "infer native-policy helper returns native flag false for non-borrow terms" {
  let state = TypeCheckerState::fresh()
  let result = infer_type_with_native_policy_flag(state, Term::unit())
  assert_true(result is Ok(_))
  match result {
    Ok((Tuple(elements), false)) => assert_eq(elements.length(), 0)
    _ => panic()
  }
}

///|
test "infer native-policy helper returns native flag true for native borrow terms" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])
  let result = infer_type_with_native_policy_flag(
    state,
    Term::borrow_shared(Term::var_term("x")),
  )
  assert_true(result is Ok(_))
  match result {
    Ok((Ref(_, Shared, Con(inner)), true)) => assert_eq(inner, "Int")
    _ => panic()
  }
}

///|
test "check native-policy helper returns native flag false for non-borrow terms" {
  let state = TypeCheckerState::fresh()
  let result = check_type_with_native_policy_flag(
    state,
    Term::unit(),
    Type::unit(),
  )
  assert_true(result is Ok(_))
  match result {
    Ok((checked, false)) => assert_true(checked.ty == Type::unit())
    _ => panic()
  }
}

///|
test "check native-policy helper returns native flag false when core check has not applied policy yet" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])
  let expected = Type::ref_type(
    Region::named("borrow::x"),
    Mutability::shared(),
    Type::con("Int"),
  )
  let result = check_type_with_native_policy_flag(
    state,
    Term::borrow_shared(Term::var_term("x")),
    expected,
  )
  assert_true(result is Ok(_))
  match result {
    Ok((checked, false)) => assert_true(checked.ty == expected)
    _ => panic()
  }
}

///|
test "check native-policy helper returns native flag true when fallback inference already applied policy" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])
  let term = Term::tuple_project(
    Term::tuple([Term::borrow_shared(Term::var_term("x")), Term::unit()]),
    1,
  )
  let result = check_type_with_native_policy_flag(state, term, Type::unit())
  assert_true(result is Ok(_))
  match result {
    Ok((checked, true)) => assert_true(checked.ty == Type::unit())
    _ => panic()
  }
}
