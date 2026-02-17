///|
test "infer_type returns unbound for missing variable" {
  let state = TypeCheckerState::fresh()
  let result = state.infer_type(Term::var_term("missing"))
  assert_true(result is Err(Unbound("missing")))
}

///|
test "check_kind returns unbound for unknown evar id" {
  let state = TypeCheckerState::fresh()
  let result = state.check_kind(EVar("404"), false)
  assert_true(result is Err(Unbound("404")))
}

///|
test "check_kind app rejects non-type-function head" {
  let state = state_with_primitives()
  let result = state.check_kind(
    Type::app(Type::con("Int"), Type::con("Bool")),
    false,
  )
  assert_true(result is Err(NotATypeFunction(_)))
}

///|
test "infer_tyapp returns type mismatch when callee is not forall" {
  let state = state_with_primitives()
  let term = Term::tyapp(Term::con("one", Type::con("Int")), Type::con("Int"))
  let result = state.infer_type(term)
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "infer_tyapp reports kind mismatch in type argument" {
  let state = state_with_primitives()
  let poly = Term::tylam("A", Star, Term::con("v", Type::var_type("A")))
  let bad_arg = Type::lam("X", Star, Type::var_type("X"))
  let result = state.infer_type(Term::tyapp(poly, bad_arg))
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "infer_app reports not-a-function for non-arrow callee" {
  let state = state_with_primitives()
  let app = Term::app(
    Term::con("one", Type::con("Int")),
    Term::con("one", Type::con("Int")),
  )
  let result = state.infer_type(app)
  assert_true(result is Err(NotAFunction(_)))
}

///|
test "infer_unfold reports not-a-function for non-mu types" {
  let state = state_with_primitives()
  let result = state.infer_type(
    Term::unfold(Term::con("one", Type::con("Int"))),
  )
  assert_true(result is Err(NotAFunction(_)))
}

///|
test "infer_project reports not-a-record for non-record values" {
  let state = state_with_primitives()
  let result = state.infer_type(
    Term::project(Term::con("one", Type::con("Int")), "x"),
  )
  assert_true(result is Err(NotARecord(_)))
}

///|
test "infer_project reports missing field for absent label" {
  let state = state_with_primitives()
  let record = Term::record([("x", Term::con("one", Type::con("Int")))])
  let result = state.infer_type(Term::project(record, "y"))
  assert_true(result is Err(MissingField(_, "y")))
}

///|
test "infer_tuple_project reports not-a-tuple when scrutinee is not tuple" {
  let state = state_with_primitives()
  let result = state.infer_type(
    Term::tuple_project(Term::con("one", Type::con("Int")), 0),
  )
  assert_true(result is Err(NotATuple(_)))
}

///|
test "infer_inject reports not-a-variant for non-variant types" {
  let state = state_with_primitives()
  let term = Term::inject("A", Term::unit(), Type::con("Int"))
  let result = state.infer_type(term)
  assert_true(result is Err(NotAVariant(_)))
}

///|
test "infer_inject reports invalid label for structural variants" {
  let state = state_with_primitives()
  let variant_ty = Type::variant([("A", Type::unit())])
  let term = Term::inject("B", Term::unit(), variant_ty)
  let result = state.infer_type(term)
  assert_true(result is Err(InvalidVariantLabel(_, "B")))
}

///|
test "check_type inject reports not-a-variant for expected non-variant" {
  let state = state_with_primitives()
  let term = Term::inject("A", Term::unit(), Type::con("Int"))
  let result = state.check_type(term, Type::con("Int"))
  assert_true(result is Err(NotAVariant(_)))
}

///|
test "check_type inject reports kind mismatch for expected structural variant" {
  let state = state_with_primitives()
  let term = Term::inject(
    "B",
    Term::unit(),
    Type::variant([("A", Type::unit())]),
  )
  let result = state.check_type(term, Type::variant([("A", Type::unit())]))
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "check_pattern variant reports not-a-variant for concrete non-variant types" {
  let state = state_with_primitives()
  let result = state.check_pattern(
    Pattern::variant("A", Pattern::wildcard()),
    Type::con("Int"),
  )
  assert_true(result is Err(NotAVariant(_)))
}

///|
test "check_pattern variant reports invalid label for structural variants" {
  let state = state_with_primitives()
  let result = state.check_pattern(
    Pattern::variant("B", Pattern::wildcard()),
    Type::variant([("A", Type::unit())]),
  )
  assert_true(result is Err(InvalidVariantLabel(_, "B")))
}

///|
test "check_pattern variant reports unbound when inferring enum from unknown label" {
  let state = state_with_primitives()
  let evar = state.meta.fresh_meta_var(Star)
  let result = state.check_pattern(
    Pattern::variant("UnknownLabel", Pattern::wildcard()),
    evar,
  )
  assert_true(result is Err(Unbound("UnknownLabel")))
}

///|
test "check_pattern tuple reports not-a-tuple" {
  let state = state_with_primitives()
  let result = state.check_pattern(
    Pattern::tuple([Pattern::wildcard()]),
    Type::con("Int"),
  )
  assert_true(result is Err(NotATuple(_)))
}

///|
test "check_pattern record reports not-a-record" {
  let state = state_with_primitives()
  let result = state.check_pattern(
    Pattern::record([("x", Pattern::wildcard())]),
    Type::con("Int"),
  )
  assert_true(result is Err(NotARecord(_)))
}

///|
test "check_pattern enum application reports kind mismatch on wrong arity" {
  let state = state_with_maybe_enum()
  let result = state.check_pattern(
    Pattern::variant("Some", Pattern::wildcard()),
    Type::con("Maybe"),
  )
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "check_exhaustive enum instance reports kind mismatch on wrong arity" {
  let state = must_type_state(
    state_with_primitives().add_enum(
      "Pairish",
      ["A", "B"],
      [Star, Star],
      [("P", Type::unit())],
      false,
    ),
  )
  let bad = Type::app(Type::con("Pairish"), Type::con("Int"))
  let result = state.check_exhaustive(
    [Pattern::variant("P", Pattern::wildcard())],
    bad,
  )
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "infer_trait_app reports type mismatch for non-bounded term" {
  let state = state_with_eq_trait_and_int_dict()
  let term = Term::trait_app(
    Term::con("one", Type::con("Int")),
    Type::con("Int"),
    [],
  )
  let result = state.infer_type(term)
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "infer_trait_app reports kind mismatch on type argument" {
  let state = state_with_eq_trait_and_int_dict()
  let trait_fn = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let bad_arg = Type::lam("X", Star, Type::var_type("X"))
  let result = state.infer_type(
    Term::trait_app(trait_fn, bad_arg, [mk_eq_int_dict()]),
  )
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "infer_trait_app validates provided dictionary type against constraint" {
  let state = state_with_eq_trait_and_int_dict()
  let trait_fn = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let wrong_dict = Term::dict("Eq", Type::con("Bool"), [
    (
      "eq",
      Term::lam(
        "x",
        Type::con("Bool"),
        Term::lam("y", Type::con("Bool"), Term::con("true", Type::con("Bool"))),
      ),
    ),
  ])
  let result = state.infer_type(
    Term::trait_app(trait_fn, Type::con("Int"), [wrong_dict]),
  )
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "infer_trait_method on missing dictionary variable is unbound" {
  let state = state_with_eq_trait_and_int_dict()
  let result = state.infer_type(
    Term::trait_method(Term::var_term("missingDict"), "eq"),
  )
  assert_true(result is Err(Unbound("missingDict")))
}

///|
test "infer_trait_method on dictionary variable with missing trait definition is unbound" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("d", Type::con("Dictionary")),
    Binding::dict("d", "MissingTrait", Type::con("Int")),
  ])
  let result = state.infer_type(Term::trait_method(Term::var_term("d"), "m"))
  assert_true(result is Err(Unbound("MissingTrait")))
}

///|
test "infer_trait_method on dictionary literal reports missing method" {
  let state = state_with_eq_trait_and_int_dict()
  let dict = Term::dict("Eq", Type::con("Int"), [])
  let result = state.infer_type(Term::trait_method(dict, "eq"))
  assert_true(result is Err(MissingMethod("Eq", "eq")))
}

///|
test "infer_dict reports unbound trait definitions" {
  let state = state_with_primitives()
  let dict = Term::dict("Missing", Type::con("Int"), [])
  let result = state.infer_type(dict)
  assert_true(result is Err(Unbound("Missing")))
}

///|
test "infer_dict reports trait kind mismatch" {
  let state = state_with_primitives()
  let with_trait = must_type_state(
    state.add_trait_def("Ctor", "F", Kind::arrow(Star, Star), []),
  )
  let dict = Term::dict("Ctor", Type::con("Int"), [])
  let result = with_trait.infer_type(dict)
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "infer_dict reports method type mismatch" {
  let state = state_with_eq_trait_and_int_dict()
  let dict = Term::dict("Eq", Type::con("Int"), [
    (
      "eq",
      Term::lam(
        "x",
        Type::con("Int"),
        Term::lam("y", Type::con("Int"), Term::con("wrong", Type::con("Int"))),
      ),
    ),
  ])
  let result = state.infer_type(dict)
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "add_builtin reports kind mismatch for non-star declaration" {
  let state = state_with_primitives()
  let declared = Type::lam("A", Star, Type::var_type("A"))
  let result = state.add_builtin("bad", declared, None)
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "add_builtin reports checking errors for provided terms" {
  let state = state_with_primitives()
  let result = state.add_builtin(
    "bad",
    Type::con("Int"),
    Some(Term::con("truth", Type::con("Bool"))),
  )
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "add_term reports checking errors with expected type" {
  let state = state_with_primitives()
  let result = state.add_term(
    "x",
    Term::con("truth", Type::con("Bool")),
    Some(Type::con("Int")),
  )
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "add_term reports inference errors when expected type is absent" {
  let state = TypeCheckerState::fresh()
  let result = state.add_term("x", Term::var_term("missing"), None)
  assert_true(result is Err(Unbound("missing")))
}

///|
test "add_type_alias reports body kind mismatch" {
  let state = state_with_primitives()
  let body = Type::lam("A", Star, Type::var_type("A"))
  let result = state.add_type_alias("Bad", [], [], body)
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "add_enum reports variant field kind mismatch" {
  let state = state_with_primitives()
  let result = state.add_enum(
    "BadEnum",
    [],
    [],
    [("Case", Type::lam("A", Star, Type::var_type("A")))],
    false,
  )
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "add_dict expects dictionary terms" {
  let state = state_with_eq_trait_and_int_dict()
  let result = state.add_dict("notDict", Term::unit())
  assert_true(result is Err(Message(_)))
}

///|
test "add_dict propagates dictionary method validation errors" {
  let state = state_with_eq_trait_and_int_dict()
  let dict = Term::dict("Eq", Type::con("Int"), [])
  let result = state.add_dict("broken", dict)
  assert_true(result is Err(MissingMethod("Eq", "eq")))
}

///|
test "process_constraint has_kind propagates check_kind failures" {
  let state = TypeCheckerState::fresh()
  let constraint = Constraint::has_kind(Type::con("Missing"), Star, state)
  let result = state.process_constraint(constraint, [], Map::new())
  assert_true(result is Err(Unbound("Missing")))
}

///|
test "process_constraint has_type propagates infer_type failures" {
  let state = TypeCheckerState::fresh()
  let constraint = Constraint::has_type(
    Term::var_term("missing"),
    Type::con("Int"),
    state,
  )
  let result = state.process_constraint(constraint, [], Map::new())
  assert_true(result is Err(Unbound("missing")))
}

///|
test "solve_constraints reports kind-equality failures" {
  let state = TypeCheckerState::fresh()
  let worklist : Worklist = [Constraint::kind_eq(Star, Kind::arrow(Star, Star))]
  let result = state.solve_constraints(worklist, Map::new())
  assert_true(result is Err(KindMismatch(_, _)))
}
