///|
fn state_with_native_int_binding() -> TypeCheckerState {
  TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])
}

///|
fn native_conflicting_borrow_term() -> Term {
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
test "RED NATIVE: Place key_path roundtrips with from_key_path parser" {
  let place = Place::root("x").field("left").tuple_index(2).deref_place()
  let path = place.key_path()
  assert_eq(path, "x.left.2.*")

  match Place::from_key_path(path) {
    Some(parsed) => assert_eq(parsed.key_path(), path)
    None => panic()
  }
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
test "RED NATIVE: infer shared borrow should allocate deterministic region from place" {
  let state = state_with_native_int_binding()
  let result = state.infer_type(Term::borrow_shared(Term::var_term("x")))
  assert_true(result is Ok(_))

  match result {
    Ok(Ref(Named(region), Shared, Con(inner))) => {
      assert_eq(region, "borrow::x")
      assert_eq(inner, "Int")
    }
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
test "RED NATIVE: infer shared borrow on projected place should allocate deterministic region" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::record([("field", Type::con("Int"))])),
  ])

  let result = state.infer_type(
    Term::borrow_shared(Term::project(Term::var_term("x"), "field")),
  )
  assert_true(result is Ok(_))

  match result {
    Ok(Ref(Named(region), Shared, Con(inner))) => {
      assert_eq(region, "borrow::x.field")
      assert_eq(inner, "Int")
    }
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
test "RED NATIVE: infer borrow should accept constructor-form deref place targets" {
  let ptr_type = Type::ref_type(
    Region::named("ptr_region"),
    Mutability::shared(),
    Type::con("Int"),
  )
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("p", ptr_type),
  ])

  let deref_builtin = Term::con(
    "deref",
    Type::arrow(ptr_type, Type::con("Int")),
  )
  let target = Term::app(deref_builtin, Term::var_term("p"))
  let result = state.infer_type(Term::borrow_shared(target))
  assert_true(result is Ok(_))
}

///|
test "RED NATIVE: check_type should accept constructor-form deref place targets with matching expected ref" {
  let ptr_type = Type::ref_type(
    Region::named("ptr_region"),
    Mutability::shared(),
    Type::con("Int"),
  )
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("p", ptr_type),
  ])

  let deref_builtin = Term::con(
    "deref",
    Type::arrow(ptr_type, Type::con("Int")),
  )
  let target = Term::app(deref_builtin, Term::var_term("p"))
  let expected = Type::ref_type(
    Region::named("borrow::p.*"),
    Mutability::shared(),
    Type::con("Int"),
  )

  let result = state.check_type(Term::borrow_shared(target), expected)
  assert_true(result is Ok(_))
}

///|
test "RED NATIVE: check_type should reject constructor-form deref place target with mismatched expected region" {
  let ptr_type = Type::ref_type(
    Region::named("ptr_region"),
    Mutability::shared(),
    Type::con("Int"),
  )
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("p", ptr_type),
  ])

  let deref_builtin = Term::con(
    "deref",
    Type::arrow(ptr_type, Type::con("Int")),
  )
  let target = Term::app(deref_builtin, Term::var_term("p"))
  let expected = Type::ref_type(
    Region::named("borrow::p"),
    Mutability::shared(),
    Type::con("Int"),
  )

  let result = state.check_type(Term::borrow_shared(target), expected)
  assert_true(typing_error_kind_from_checked_result(result) == "TypeMismatch")
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
test "RED NATIVE: infer_type should surface native borrow conflicts in primary flow" {
  let state = TypeCheckerState::fresh()
  let result = state.infer_type(native_conflicting_borrow_term())
  assert_true(typing_error_kind_from_type_result(result) == "BorrowConflict")
}

///|
test "RED NATIVE: check_type should surface native borrow conflicts in primary flow" {
  let state = TypeCheckerState::fresh()
  let result = state.check_type(native_conflicting_borrow_term(), Type::unit())
  assert_true(typing_error_kind_from_checked_result(result) == "BorrowConflict")
}

///|
test "RED NATIVE: check_type should reject region-mismatched expected refs for borrow_shared" {
  let state = state_with_native_int_binding()
  let expected = Type::ref_type(
    Region::named("some_other_region"),
    Mutability::shared(),
    Type::con("Int"),
  )
  let result = state.check_type(
    Term::borrow_shared(Term::var_term("x")),
    expected,
  )
  assert_true(typing_error_kind_from_checked_result(result) == "TypeMismatch")
}

///|
test "RED NATIVE: check_type should reject mutability-mismatched expected refs for borrow_shared" {
  let state = state_with_native_int_binding()
  let expected = Type::ref_type(
    Region::named("borrow::x"),
    Mutability::mutable(),
    Type::con("Int"),
  )
  let result = state.check_type(
    Term::borrow_shared(Term::var_term("x")),
    expected,
  )
  assert_true(typing_error_kind_from_checked_result(result) == "TypeMismatch")
}

///|
test "RED NATIVE: check_type should reject region-mismatched expected refs for borrow_mut" {
  let state = state_with_native_int_binding()
  let expected = Type::ref_type(
    Region::named("wrong_region"),
    Mutability::mutable(),
    Type::con("Int"),
  )
  let result = state.check_type(Term::borrow_mut(Term::var_term("x")), expected)
  assert_true(typing_error_kind_from_checked_result(result) == "TypeMismatch")
}

///|
test "RED NATIVE: check_type should reject mutability-mismatched expected refs for borrow_mut" {
  let state = state_with_native_int_binding()
  let expected = Type::ref_type(
    Region::named("borrow::x"),
    Mutability::shared(),
    Type::con("Int"),
  )
  let result = state.check_type(Term::borrow_mut(Term::var_term("x")), expected)
  assert_true(typing_error_kind_from_checked_result(result) == "TypeMismatch")
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
  let term = native_conflicting_borrow_term()

  let result = state.infer_type_with_borrow_analysis(
    term,
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_type_result(result) == "BorrowConflict")
}

///|
test "RED NATIVE: native borrow conflict should surface from wrapper check flow" {
  let state = TypeCheckerState::fresh()
  let term = native_conflicting_borrow_term()

  let result = state.check_type_with_borrow_analysis(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_checked_result(result) == "BorrowConflict")
}
