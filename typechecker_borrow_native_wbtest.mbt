///|
fn state_with_native_int_binding() -> TypeCheckerState {
  TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])
}

///|
test "RED NATIVE: Type ref constructor should preserve region mutability and inner type" {
  let ref_ty = Type::ref_type(
    Region::named("r"),
    Mutability::shared(),
    Type::con("Int"),
  )

  match ref_ty {
    Ref(Named(name), Shared, Con(inner)) => {
      assert_eq(name, "r")
      assert_eq(inner, "Int")
    }
    _ => panic()
  }
}

///|
test "RED NATIVE: infer shared borrow should return shared ref type" {
  let state = state_with_native_int_binding()
  let result = state.infer_type(Term::borrow_shared(Term::var_term("x")))
  assert_true(result is Ok(_))

  match result {
    Ok(Ref(_, Shared, Con(inner))) => assert_eq(inner, "Int")
    _ => panic()
  }
}

///|
test "RED NATIVE: infer mutable borrow should return mutable ref type" {
  let state = state_with_native_int_binding()
  let result = state.infer_type(Term::borrow_mut(Term::var_term("x")))
  assert_true(result is Ok(_))

  match result {
    Ok(Ref(_, Mutable, Con(inner))) => assert_eq(inner, "Int")
    _ => panic()
  }
}

///|
test "RED NATIVE: infer deref should return inner type of native ref" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term(
      "p",
      Type::ref_type(
        Region::named("p_region"),
        Mutability::mutable(),
        Type::con("Int"),
      ),
    ),
  ])

  let result = state.infer_type(Term::deref(Term::var_term("p")))
  assert_true(result is Ok(_))
  match result {
    Ok(Con(name)) => assert_eq(name, "Int")
    _ => panic()
  }
}

///|
test "RED NATIVE: assign through mutable ref should infer unit and check unit" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term(
      "p",
      Type::ref_type(
        Region::named("p_region"),
        Mutability::mutable(),
        Type::con("Int"),
      ),
    ),
  ])

  let assign_term = Term::assign(
    Term::var_term("p"),
    Term::con("forty_two", Type::con("Int")),
  )

  let inferred = state.infer_type(assign_term)
  assert_true(inferred is Ok(_))
  match inferred {
    Ok(Tuple(elements)) => assert_eq(elements.length(), 0)
    _ => panic()
  }

  let checked = state.check_type(assign_term, Type::unit())
  assert_true(checked is Ok(_))
}

///|
test "RED NATIVE: assign through shared ref should return AssignToImmutable" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term(
      "p",
      Type::ref_type(
        Region::named("p_region"),
        Mutability::shared(),
        Type::con("Int"),
      ),
    ),
  ])

  let result = state.infer_type(
    Term::assign(Term::var_term("p"), Term::con("v", Type::con("Int"))),
  )

  assert_true(typing_error_kind_from_type_result(result) == "AssignToImmutable")
}

///|
test "RED NATIVE: move term should preserve operand type" {
  let state = state_with_native_int_binding()
  let result = state.infer_type(Term::move_term(Term::var_term("x")))
  assert_true(result is Ok(_))

  match result {
    Ok(Con(name)) => assert_eq(name, "Int")
    _ => panic()
  }
}

///|
test "RED NATIVE: enabled infer wrapper should use native borrow operations without intrinsic names" {
  let state = TypeCheckerState::fresh()
  let term = Term::let_term(
    "x",
    Term::unit(),
    Term::tuple_project(
      Term::tuple([Term::borrow_shared(Term::var_term("x")), Term::unit()]),
      1,
    ),
  )

  let result = state.infer_type_with_borrow_analysis(
    term,
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_type_result(result) == "Ok")
}

///|
test "RED NATIVE: native borrow conflict should surface from wrapper analysis" {
  let state = TypeCheckerState::fresh()
  let term = Term::let_term(
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

  let result = state.infer_type_with_borrow_analysis(
    term,
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_type_result(result) == "BorrowConflict")
}
