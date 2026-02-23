///|
test "types_equal handles forall alpha equivalence" {
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
  assert_true(state.types_equal(left, right))
}

///|
test "types_equal ignores record field ordering" {
  let state = TypeCheckerState::fresh()
  let left = Type::record([("a", Type::con("Int")), ("b", Type::con("Bool"))])
  let right = Type::record([("b", Type::con("Bool")), ("a", Type::con("Int"))])
  assert_true(state.types_equal(left, right))
}

///|
test "types_equal matches bounded forall constraints as a set" {
  let state = TypeCheckerState::fresh()
  let left = Type::bounded_forall(
    "A",
    Star,
    [
      TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") },
      TraitConstraint::{ trait_name: "Show", ty: Type::var_type("A") },
    ],
    Type::arrow(Type::var_type("A"), Type::var_type("A")),
  )
  let right = Type::bounded_forall(
    "B",
    Star,
    [
      TraitConstraint::{ trait_name: "Show", ty: Type::var_type("B") },
      TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") },
    ],
    Type::arrow(Type::var_type("B"), Type::var_type("B")),
  )
  assert_true(state.types_equal(left, right))
}

///|
test "merge_substs lets local substitution override global entries" {
  let globals = Map::from_array([
    ("x", Type::con("Bool")),
    ("y", Type::con("Int")),
  ])
  let locals = Map::from_array([("x", Type::con("Int"))])
  let merged = merge_substs(locals, globals)
  assert_true(merged["x"] == Type::con("Int"))
  assert_true(merged["y"] == Type::con("Int"))
}

///|
test "kind arity and peel_n_params work for arrow chains" {
  let k = Kind::arrow(Star, Kind::arrow(Star, Star))
  assert_eq(k.arity(), 2)
  let peeled = k.peel_n_params(2)
  match peeled {
    Ok((params, result)) => {
      assert_eq(params.length(), 2)
      assert_true(params[0] == Star)
      assert_true(params[1] == Star)
      assert_true(result == Star)
    }
    _ => panic()
  }
}

///|
test "peel_n_params fails when there are not enough arguments" {
  let k = Kind::arrow(Star, Star)
  let result = k.peel_n_params(2)
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "type is_meta_var recognizes evars only" {
  assert_true(EVar("0").is_meta_var())
  assert_false(Type::var_type("A").is_meta_var())
}

///|
test "fresh_meta_var registers kind in state" {
  let state = TypeCheckerState::fresh()
  let fv = state.meta.fresh_meta_var(Star)
  let kind = must_kind(state.check_kind(fv, false))
  assert_eq(kind, Star)
}

///|
test "solve_meta_var stores solution and rejects conflicting rebinding" {
  let state = TypeCheckerState::fresh()
  let fv = state.meta.fresh_meta_var(Star)
  let name = match fv {
    EVar(name) => name
    _ => panic()
  }

  assert_true(state.solve_meta_var(name, Type::con("Int")) is Ok(_))
  assert_true(state.solve_meta_var(name, Type::con("Int")) is Ok(_))
  assert_true(
    state.solve_meta_var(name, Type::con("Bool")) is Err(TypeMismatch(_, _)),
  )
}

///|
test "solve_meta_var rejects cyclic assignment" {
  let state = TypeCheckerState::fresh()
  let fv = state.meta.fresh_meta_var(Star)
  let name = match fv {
    EVar(name) => name
    _ => panic()
  }
  let cyclic = Type::arrow(Type::con("Int"), EVar(name))
  assert_true(state.solve_meta_var(name, cyclic) is Err(Cyclic(_)))
}

///|
test "occurs_check_evar follows solved metavariables" {
  let state = TypeCheckerState::fresh()
  let f0 = state.meta.fresh_meta_var(Star)
  let f1 = state.meta.fresh_meta_var(Star)
  let n0 = match f0 {
    EVar(name) => name
    _ => panic()
  }
  let n1 = match f1 {
    EVar(name) => name
    _ => panic()
  }
  assert_true(
    state.solve_meta_var(n1, Type::arrow(Type::con("Int"), EVar(n0))) is Ok(_),
  )
  assert_true(state.meta.occurs_check_evar(n0, EVar(n1)))
}

///|
test "apply_substitution respects forall binders for vars" {
  let state = TypeCheckerState::fresh()
  let ty = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("X")),
  )
  let subst = Map::from_array([
    ("A", Type::con("Int")),
    ("X", Type::con("Bool")),
  ])
  let applied = state.apply_substitution(subst, ty)
  let expected = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::con("Bool")),
  )
  assert_true(applied == expected)
}

///|
test "apply_substitution uses global meta solutions" {
  let state = TypeCheckerState::fresh()
  let fv = state.meta.fresh_meta_var(Star)
  let name = match fv {
    EVar(name) => name
    _ => panic()
  }
  assert_true(state.solve_meta_var(name, Type::con("Int")) is Ok(_))
  let applied = state.apply_substitution(
    Map::new(),
    Type::arrow(fv, Type::con("Bool")),
  )
  assert_true(applied == Type::arrow(Type::con("Int"), Type::con("Bool")))
}

///|
test "apply_substitution_to_term avoids replacing bound type vars" {
  let state = TypeCheckerState::fresh()
  let term = Term::tylam("A", Star, Term::con("k", Type::var_type("A")))
  let subst = Map::from_array([("A", Type::con("Int"))])
  let applied = state.apply_substitution_to_term(subst, term, Set::new())
  assert_true(applied == term)
}

///|
test "instantiate_type opens forall and bounded_forall with fresh metas" {
  let state = TypeCheckerState::fresh()
  let poly = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("A")),
  )
  let opened = state.instantiate_type(poly)
  assert_true(opened is Arrow(EVar(_), EVar(_)))

  let constrained = Type::bounded_forall(
    "B",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") }],
    Type::var_type("B"),
  )
  let opened_constrained = state.instantiate_type(constrained)
  assert_true(opened_constrained is EVar(_))
}

///|
test "instantiate_term converts top-level tylam to tyapp" {
  let state = TypeCheckerState::fresh()
  let term = Term::tylam("A", Star, Term::var_term("x"))
  let instantiated = state.instantiate_term(term)
  match instantiated {
    TyApp(inner, EVar(_)) => assert_true(inner == Term::var_term("x"))
    _ => panic()
  }
}

///|
test "spine helpers recover head and argument list" {
  let ty = Type::app(
    Type::app(Type::con("F"), Type::con("Int")),
    Type::con("Bool"),
  )
  assert_true(ty.get_spine_head() == Type::con("F"))
  let args = ty.get_spine_args()
  assert_eq(args.length(), 2)
  assert_true(args[0] == Type::con("Int"))
  assert_true(args[1] == Type::con("Bool"))
}

///|
test "substitute_type does not cross forall binder for same variable" {
  let ty = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("X")),
  )
  let substituted = ty.substitute_type("A", Type::con("Int"))
  assert_true(substituted == ty)
}

///|
test "alpha_rename updates free occurrences under binders" {
  let ty = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("B")),
  )
  let renamed = ty.alpha_rename("B", "C")
  let expected = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("C")),
  )
  assert_true(renamed == expected)
}

///|
test "occurs_check treats bound mu variable as non-free" {
  let ty = Type::mu("X", Type::var_type("X"))
  assert_false(ty.occurs_check("X"))
}

///|
test "unify_types rejects degenerate recursive mu types" {
  let state = TypeCheckerState::fresh()
  let mu = Type::mu("X", Type::var_type("X"))
  let wl : Worklist = []
  let subst : Substitution = Map::new()
  assert_true(
    state.unify_types(mu, Type::con("Int"), wl, subst) is Err(Cyclic(_)),
  )
}

///|
test "collect_type_vars excludes bound names" {
  let ty = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("B")),
  )
  let free = ty.collect_type_vars()
  assert_eq(free.length(), 1)
  assert_true(free[0] == "B")
}

///|
test "create_variant_lambda wraps variant in kind-many lambdas" {
  let variant = Type::variant([("None", Type::unit())])
  let wrapped = variant.create_variant_lambda(Kind::arrow(Star, Star))
  match wrapped {
    Lam(name, Star, Variant(_)) => assert_true(name == "t0")
    _ => panic()
  }
}

///|
test "resolve_meta_vars resolves arrow structures recursively" {
  let state = TypeCheckerState::fresh()
  let f0 = state.meta.fresh_meta_var(Star)
  let n0 = match f0 {
    EVar(name) => name
    _ => panic()
  }
  assert_true(state.solve_meta_var(n0, Type::con("Int")) is Ok(_))
  let resolved = state.resolve_meta_vars(Type::arrow(f0, Type::con("Bool")))
  assert_true(resolved == Type::arrow(Type::con("Int"), Type::con("Bool")))
}

///|
test "get_unbound_metas and has_unbound_metas agree" {
  let state = TypeCheckerState::fresh()
  let f0 = state.meta.fresh_meta_var(Star)
  let f1 = state.meta.fresh_meta_var(Star)
  let n0 = match f0 {
    EVar(name) => name
    _ => panic()
  }
  let n1 = match f1 {
    EVar(name) => name
    _ => panic()
  }
  assert_true(state.solve_meta_var(n0, Type::con("Int")) is Ok(_))

  let ty = Type::arrow(f0, f1)
  let unbound = state.get_unbound_metas(ty)
  let set = Set::from_array(unbound)
  assert_eq(set.length(), 1)
  assert_true(set.contains(n1))
  assert_true(state.has_unbound_metas(ty))
}
