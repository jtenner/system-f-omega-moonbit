///|
test "infer_type infers simple lambda arrows" {
  let state = state_with_primitives()
  let term = Term::lam("x", Type::con("Int"), Term::con("xv", Type::con("Int")))
  let inferred = must_type(state.infer_type(term))
  let expected = Type::arrow(Type::con("Int"), Type::con("Int"))
  assert_true(inferred == expected)
}

///|
test "infer_type infers applications" {
  let state = state_with_primitives()
  let id = Term::lam("x", Type::con("Int"), Term::var_term("x"))
  let app = Term::app(id, Term::con("one", Type::con("Int")))
  let inferred = must_type(state.infer_type(app))
  assert_true(inferred == Type::con("Int"))
}

///|
test "infer_type infers let by extending environment" {
  let state = state_with_primitives()
  let term = Term::let_term(
    "x",
    Term::con("one", Type::con("Int")),
    Term::var_term("x"),
  )
  let inferred = must_type(state.infer_type(term))
  assert_true(inferred == Type::con("Int"))
}

///|
test "infer_type infers type lambdas and type applications" {
  let state = state_with_primitives()
  let poly = Term::tylam(
    "A",
    Star,
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let poly_ty = must_type(state.infer_type(poly))
  assert_true(poly_ty is Forall(_, _, _))

  let applied = Term::tyapp(poly, Type::con("Int"))
  let applied_ty = must_type(state.infer_type(applied))
  assert_true(applied_ty == Type::arrow(Type::con("Int"), Type::con("Int")))
}

///|
test "infer_type infers record literals and projections" {
  let state = state_with_primitives()
  let record = Term::record([
    ("a", Term::con("one", Type::con("Int"))),
    ("b", Term::con("truth", Type::con("Bool"))),
  ])
  let record_ty = must_type(state.infer_type(record))
  assert_true(record_ty is Record(_))

  let projected = Term::project(record, "b")
  let projected_ty = must_type(state.infer_type(projected))
  assert_true(projected_ty == Type::con("Bool"))
}

///|
test "infer_type infers tuple literals and tuple projection" {
  let state = state_with_primitives()
  let tuple = Term::tuple([
    Term::con("one", Type::con("Int")),
    Term::con("truth", Type::con("Bool")),
  ])
  let tuple_ty = must_type(state.infer_type(tuple))
  assert_true(tuple_ty == Type::tuple([Type::con("Int"), Type::con("Bool")]))

  let second = Term::tuple_project(tuple, 1)
  let second_ty = must_type(state.infer_type(second))
  assert_true(second_ty == Type::con("Bool"))
}

///|
test "infer_type tuple projection reports index out of bounds" {
  let state = state_with_primitives()
  let tuple = Term::tuple([Term::con("one", Type::con("Int"))])
  let result = state.infer_type(Term::tuple_project(tuple, 3))
  assert_true(result is Err(TupleIndexOutOfBounds(_, 3)))
}

///|
test "infer_type infers structural variant injection" {
  let state = state_with_primitives()
  let variant_ty = Type::variant([("Only", Type::unit())])
  let term = Term::inject("Only", Term::unit(), variant_ty)
  let inferred = must_type(state.infer_type(term))
  assert_true(inferred == variant_ty)
}

///|
test "infer_type infers nominal enum injection with type arguments" {
  let state = state_with_maybe_enum()
  let maybe_int = Type::app(Type::con("Maybe"), Type::con("Int"))
  let term = Term::inject("Some", Term::con("one", Type::con("Int")), maybe_int)
  let inferred = must_type(state.infer_type(term))
  assert_true(inferred == maybe_int)
}

///|
test "infer_type infers match branches with common type" {
  let state = state_with_primitives()
  let variant_ty = Type::variant([("A", Type::unit()), ("B", Type::unit())])
  let scrutinee = Term::inject("A", Term::unit(), variant_ty)
  let term = Term::match_term(scrutinee, [
    (
      Pattern::variant("A", Pattern::wildcard()),
      Term::con("one", Type::con("Int")),
    ),
    (
      Pattern::variant("B", Pattern::wildcard()),
      Term::con("two", Type::con("Int")),
    ),
  ])
  let inferred = must_type(state.infer_type(term))
  assert_true(inferred == Type::con("Int"))
}

///|
test "infer_type rejects non-exhaustive matches" {
  let state = state_with_primitives()
  let variant_ty = Type::variant([("A", Type::unit()), ("B", Type::unit())])
  let scrutinee = Term::inject("A", Term::unit(), variant_ty)
  let term = Term::match_term(scrutinee, [
    (
      Pattern::variant("A", Pattern::wildcard()),
      Term::con("one", Type::con("Int")),
    ),
  ])
  let result = state.infer_type(term)
  assert_true(result is Err(MissingCase("B")))
}

///|
test "infer_type supports fold and unfold for recursive tuple mu types" {
  let state = state_with_primitives()
  let rec_ty = Type::mu(
    "X",
    Type::tuple([Type::con("Int"), Type::var_type("X")]),
  )
  let folded = Term::fold(rec_ty, Term::con("bottom", Type::never()))
  let folded_ty = must_type(state.infer_type(folded))
  assert_true(folded_ty == rec_ty)

  let unfolded_ty = must_type(state.infer_type(Term::unfold(folded)))
  assert_true(unfolded_ty == Type::tuple([Type::con("Int"), rec_ty]))
}

///|
test "check_type checks lambdas against expected arrows" {
  let state = state_with_primitives()
  let term = Term::lam("x", Type::con("Int"), Term::var_term("x"))
  let checked = must_checked(
    state.check_type(term, Type::arrow(Type::con("Int"), Type::con("Int"))),
  )
  assert_true(checked.ty == Type::arrow(Type::con("Int"), Type::con("Int")))
}

///|
test "check_type checks type lambdas against forall types" {
  let state = state_with_primitives()
  let term = Term::tylam(
    "A",
    Star,
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let expected = Type::forall(
    "T",
    Star,
    Type::arrow(Type::var_type("T"), Type::var_type("T")),
  )
  let checked = must_checked(state.check_type(term, expected))
  assert_true(checked.ty == expected)
}

///|
test "check_type validates record field sets" {
  let state = state_with_primitives()
  let term = Term::record([("x", Term::con("one", Type::con("Int")))])
  let expected_ok = Type::record([("x", Type::con("Int"))])
  assert_true(state.check_type(term, expected_ok) is Ok(_))

  let expected_bad = Type::record([("y", Type::con("Int"))])
  assert_true(state.check_type(term, expected_bad) is Err(TypeMismatch(_, _)))
}

///|
test "check_type validates tuple arity" {
  let state = state_with_primitives()
  let term = Term::tuple([Term::con("one", Type::con("Int"))])
  let expected = Type::tuple([Type::con("Int"), Type::con("Bool")])
  let result = state.check_type(term, expected)
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "check_type fold requires recursive expected type" {
  let state = state_with_primitives()
  let fold_term = Term::fold(
    Type::con("Int"),
    Term::con("one", Type::con("Int")),
  )
  let result = state.check_type(fold_term, Type::con("Int"))
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "infer_type_with_mode supports infer and check modes" {
  let state = state_with_primitives()
  let term = Term::con("one", Type::con("Int"))

  let inferred = must_type(state.infer_type_with_mode(term, InferMode::infer()))
  assert_true(inferred == Type::con("Int"))

  let checked = must_type(
    state.infer_type_with_mode(term, InferMode::check(Type::con("Int"))),
  )
  assert_true(checked == Type::con("Int"))
}

///|
test "typecheck_with_constraints aligns with direct inference" {
  let state = state_with_primitives()
  let term = Term::lam("x", Type::con("Int"), Term::var_term("x"))
  let direct = must_type(state.type_check(term))
  let constrained = must_type(state.typecheck_with_constraints(term))
  assert_true(direct == constrained)
}

///|
test "auto_instantiate applies plain forall arguments automatically" {
  let state = state_with_primitives()
  let term = Term::tylam(
    "A",
    Star,
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let auto = state.auto_instantiate(term)
  match auto {
    Ok(result) => {
      assert_true(result.term is TyApp(_, _))
      assert_true(result.ty is Arrow(EVar(_), EVar(_)))
    }
    _ => panic()
  }
}
