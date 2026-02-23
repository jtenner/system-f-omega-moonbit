///|
test "check_kind strict mode reports unbound type constructor" {
  let state = TypeCheckerState::fresh()
  let result = state.check_kind(Type::con("Missing"), false)
  assert_true(result is Err(Unbound("Missing")))
}

///|
test "check_kind lenient mode treats unknown constructor as star" {
  let state = TypeCheckerState::fresh()
  let kind = must_kind(state.check_kind(Type::con("Missing"), true))
  assert_eq(kind, Star)
}

///|
test "check_kind computes type alias kind from parameters" {
  let state = state_with_primitives()
  let with_alias = must_type_state(
    state.add_type_alias("Id", ["A"], [Star], Type::var_type("A")),
  )
  let kind = must_kind(with_alias.check_kind(Type::con("Id"), false))
  assert_true(kind == Kind::arrow(Star, Star))
}

///|
test "check_kind app reports argument kind mismatch" {
  let state = state_with_primitives()
  let with_alias = must_type_state(
    state.add_type_alias("Id", ["A"], [Star], Type::var_type("A")),
  )
  let bad_arg = Type::lam("X", Star, Type::var_type("X"))
  let result = with_alias.check_kind(Type::app(Type::con("Id"), bad_arg), false)
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "unify_kinds accepts equal kinds and rejects mismatches" {
  assert_true(unify_kinds(Star, Star) is Ok(_))
  assert_true(
    unify_kinds(Star, Kind::arrow(Star, Star)) is Err(KindMismatch(_, _)),
  )
}

///|
test "unify_variable handles tautology and cycles" {
  let state = TypeCheckerState::fresh()
  let subst : Substitution = Map::new()
  assert_true(state.unify_variable("A", Type::var_type("A"), subst) is Ok(_))
  assert_true(
    state.unify_variable(
      "A",
      Type::arrow(Type::var_type("A"), Type::con("Int")),
      subst,
    )
    is Err(Cyclic("A")),
  )
}

///|
test "unify_types handles alpha-equivalent forall types" {
  let state = TypeCheckerState::fresh()
  let left = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("A")),
  )
  let right = Type::forall(
    "B",
    Star,
    Type::arrow(Type::var_type("B"), Type::var_type("B")),
  )
  let wl : Worklist = []
  let subst : Substitution = Map::new()
  assert_true(state.unify_types(left, right, wl, subst) is Ok(_))
  assert_true(state.solve_constraints(wl, subst) is Ok(_))
}

///|
test "unify_types supports nominal enum with structural variant" {
  let state = state_with_maybe_enum()
  let left = Type::app(Type::con("Maybe"), Type::con("Int"))
  let right = Type::variant([("Some", Type::con("Int")), ("None", Type::unit())])
  let wl : Worklist = []
  let subst : Substitution = Map::new()
  assert_true(state.unify_types(left, right, wl, subst) is Ok(_))
  assert_true(state.solve_constraints(wl, subst) is Ok(_))
}

///|
test "unify_types arrow special-case allows bottom in domain" {
  let state = state_with_primitives()
  let left = Type::arrow(Type::never(), Type::con("Int"))
  let right = Type::arrow(Type::con("Bool"), Type::con("Int"))
  let wl : Worklist = []
  let subst : Substitution = Map::new()
  assert_true(state.unify_types(left, right, wl, subst) is Ok(_))
}

///|
test "unify_types rejects record label mismatches" {
  let state = TypeCheckerState::fresh()
  let left = Type::record([("x", Type::con("Int"))])
  let right = Type::record([("y", Type::con("Int"))])
  let wl : Worklist = []
  let subst : Substitution = Map::new()
  assert_true(
    state.unify_types(left, right, wl, subst) is Err(TypeMismatch(_, _)),
  )
}

///|
test "solve_constraints can process has_kind and has_type constraints" {
  let state = state_with_primitives()
  let wl : Worklist = [
    Constraint::has_kind(Type::con("Int"), Star, state),
    Constraint::has_type(Term::unit(), Type::unit(), state),
  ]
  let subst : Substitution = Map::new()
  assert_true(state.solve_constraints(wl, subst) is Ok(_))
}

///|
test "subsumes accepts bottom specific and rejects bottom general" {
  let state = state_with_primitives()
  let wl1 : Worklist = []
  let s1 : Substitution = Map::new()
  assert_true(state.subsumes(Type::con("Int"), Type::never(), wl1, s1) is Ok(_))

  let wl2 : Worklist = []
  let s2 : Substitution = Map::new()
  assert_true(
    state.subsumes(Type::never(), Type::con("Int"), wl2, s2)
    is Err(TypeMismatch(_, _)),
  )
}

///|
test "is_assignable_to handles bottom as expected" {
  let state = state_with_primitives()
  assert_true(state.is_assignable_to(Type::never(), Type::con("Int")))
  assert_false(state.is_assignable_to(Type::con("Int"), Type::never()))
}

///|
test "bindings collects variable binders from nested patterns" {
  let state = TypeCheckerState::fresh()
  let pattern = Pattern::record([
    ("a", Pattern::var_pattern("x")),
    ("b", Pattern::tuple([Pattern::var_pattern("y"), Pattern::wildcard()])),
  ])
  let bound = state.bindings(pattern)
  let names = Set::new()
  for pair in bound {
    names.add(pair.0)
  }
  assert_eq(names.length(), 2)
  assert_true(names.contains("x"))
  assert_true(names.contains("y"))
}

///|
test "check_pattern tuple validates arity and element types" {
  let state = state_with_primitives()
  let ok = state.check_pattern(
    Pattern::tuple([Pattern::var_pattern("x"), Pattern::wildcard()]),
    Type::tuple([Type::con("Int"), Type::con("Bool")]),
  )
  assert_true(ok is Ok(_))

  let bad = state.check_pattern(
    Pattern::tuple([Pattern::var_pattern("x")]),
    Type::tuple([Type::con("Int"), Type::con("Bool")]),
  )
  assert_true(bad is Err(TypeMismatch(_, _)))
}

///|
test "check_pattern record reports missing fields" {
  let state = state_with_primitives()
  let result = state.check_pattern(
    Pattern::record([("x", Pattern::wildcard())]),
    Type::record([("y", Type::con("Int"))]),
  )
  assert_true(result is Err(MissingField(_, "x")))
}

///|
test "check_pattern variant resolves enum variant payload type" {
  let state = state_with_maybe_enum()
  let ty = Type::app(Type::con("Maybe"), Type::con("Int"))
  let result = state.check_pattern(
    Pattern::variant("Some", Pattern::var_pattern("v")),
    ty,
  )
  match result {
    Ok(ctx) =>
      match ctx.0 {
        [Term(binding)] => {
          assert_true(binding.name == "v")
          assert_true(binding.ty == Type::con("Int"))
        }
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "check_pattern constructor uses assignability" {
  let state = state_with_primitives()
  let ok = state.check_pattern(
    Pattern::con("IntCon", Type::con("Int")),
    Type::con("Int"),
  )
  assert_true(ok is Ok(_))

  let bad = state.check_pattern(
    Pattern::con("IntCon", Type::con("Int")),
    Type::con("Bool"),
  )
  assert_true(bad is Err(TypeMismatch(_, _)))
}

///|
test "check_exhaustive detects missing structural variant labels" {
  let state = state_with_primitives()
  let variant = Type::variant([("A", Type::unit()), ("B", Type::unit())])
  let result = state.check_exhaustive(
    [Pattern::variant("A", Pattern::wildcard())],
    variant,
  )
  assert_true(result is Err(MissingCase("B")))
}

///|
test "check_exhaustive accepts wildcard patterns immediately" {
  let state = state_with_primitives()
  let variant = Type::variant([("A", Type::unit()), ("B", Type::unit())])
  let result = state.check_exhaustive([Pattern::wildcard()], variant)
  assert_true(result is Ok(_))
}

///|
test "check_exhaustive supports enum scrutinee types" {
  let state = state_with_maybe_enum()
  let ty = Type::app(Type::con("Maybe"), Type::con("Int"))
  let result = state.check_exhaustive(
    [Pattern::variant("Some", Pattern::wildcard())],
    ty,
  )
  assert_true(result is Err(MissingCase("None")))
}
