///|
fn mk_eq_int_dict() -> Term {
  Term::dict("Eq", Type::con("Int"), [
    (
      "eq",
      Term::lam(
        "x",
        Type::con("Int"),
        Term::lam("y", Type::con("Int"), Term::con("true", Type::con("Bool"))),
      ),
    ),
  ])
}

///|
test "add_trait_def rejects non-star method types" {
  let state = state_with_primitives()
  let bad_method = Type::lam("A", Star, Type::var_type("A"))
  let result = state.add_trait_def("Bad", "T", Star, [("m", bad_method)])
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "add_trait_impl requires dictionary terms" {
  let state = state_with_primitives()
  let with_trait = must_type_state(
    state.add_trait_def("Eq", "T", Star, [
      (
        "eq",
        Type::arrow(
          Type::var_type("T"),
          Type::arrow(Type::var_type("T"), Type::con("Bool")),
        ),
      ),
    ]),
  )
  let result = with_trait.add_trait_impl("Eq", Type::con("Int"), Term::unit())
  assert_true(result is Err(Message(_)))
}

///|
test "infer_dict_type reports missing methods" {
  let state = state_with_primitives()
  let with_trait = must_type_state(
    state.add_trait_def("Eq", "T", Star, [
      (
        "eq",
        Type::arrow(
          Type::var_type("T"),
          Type::arrow(Type::var_type("T"), Type::con("Bool")),
        ),
      ),
    ]),
  )
  let dict = Term::dict("Eq", Type::con("Int"), [])
  let inferred = with_trait.infer_type(dict)
  assert_true(inferred is Err(MissingMethod("Eq", "eq")))
}

///|
test "add_dict registers dictionary bindings in context" {
  let state = state_with_eq_trait_and_int_dict()
  let mut found = false
  for b in state.ctx.0 {
    match b {
      Dict(binding) if binding.name == "eqInt" => {
        found = true
        assert_true(binding.trait_name == "Eq")
        assert_true(binding.ty == Type::con("Int"))
      }
      _ => ()
    }
  }
  assert_true(found)
}

///|
test "trait_method resolves method types for literal dictionary terms" {
  let state = state_with_eq_trait_and_int_dict()
  let method_ty = must_type(
    state.infer_type(Term::trait_method(mk_eq_int_dict(), "eq")),
  )
  let expected = Type::arrow(
    Type::con("Int"),
    Type::arrow(Type::con("Int"), Type::con("Bool")),
  )
  assert_true(method_ty == expected)
}

///|
test "trait_method on non-dictionary reports mismatch" {
  let state = state_with_eq_trait_and_int_dict()
  let result = state.infer_type(
    Term::trait_method(Term::con("one", Type::con("Int")), "eq"),
  )
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "check_trait_implementation finds exact matches" {
  let state = state_with_eq_trait_and_int_dict()
  let result = state.check_trait_implementation("Eq", Type::con("Int"))
  assert_true(result is Ok(_))
}

///|
test "check_trait_implementation can use polymorphic variable impl type" {
  let base = state_with_primitives()
  let with_trait = must_type_state(
    base.add_trait_def("Eq", "A", Star, [
      (
        "eq",
        Type::arrow(
          Type::var_type("A"),
          Type::arrow(Type::var_type("A"), Type::con("Bool")),
        ),
      ),
    ]),
  )
  let flexible = with_trait.meta.fresh_meta_var(Star)
  let poly_dict = Term::dict("Eq", flexible, [
    (
      "eq",
      Term::lam(
        "x",
        flexible,
        Term::lam("y", flexible, Term::con("true", Type::con("Bool"))),
      ),
    ),
  ])
  let with_poly_impl = must_type_state(
    with_trait.add_trait_impl("Eq", flexible, poly_dict),
  )
  let found = with_poly_impl.check_trait_implementation("Eq", Type::con("Bool"))
  match found {
    Ok(dict_term) =>
      match dict_term {
        Dict("Eq", ty, _) => assert_true(ty == Type::con("Bool"))
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "check_trait_constraints returns dictionaries and errors when missing" {
  let state = state_with_eq_trait_and_int_dict()
  let ok = state.check_trait_constraints([
    TraitConstraint::{ trait_name: "Eq", ty: Type::con("Int") },
  ])
  match ok {
    Ok(dicts) => assert_eq(dicts.length(), 1)
    _ => panic()
  }

  let missing = state.check_trait_constraints([
    TraitConstraint::{ trait_name: "Eq", ty: Type::con("Bool") },
  ])
  assert_true(missing is Err(MissingTraitImpl("Eq", _)))
}

///|
test "infer_trait_lam and trait_app infer instantiated body type" {
  let state = state_with_eq_trait_and_int_dict()
  let trait_fn = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let poly_ty = must_type(state.infer_type(trait_fn))
  assert_true(poly_ty is BoundedForall(_, _, _, _))

  let applied = Term::trait_app(trait_fn, Type::con("Int"), [mk_eq_int_dict()])
  let applied_ty = must_type(state.infer_type(applied))
  assert_true(applied_ty == Type::arrow(Type::con("Int"), Type::con("Int")))
}

///|
test "infer_trait_app checks dictionary count" {
  let state = state_with_eq_trait_and_int_dict()
  let trait_fn = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let bad = Term::trait_app(trait_fn, Type::con("Int"), [])
  let result = state.infer_type(bad)
  assert_true(result is Err(WrongNumberOfDicts(1, 0)))
}

///|
test "instantiate_with_traits resolves bounded forall constraints" {
  let state = state_with_eq_trait_and_int_dict()
  let poly = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Type::arrow(Type::var_type("A"), Type::var_type("A")),
  )
  let instantiated = state.instantiate_with_traits(poly)
  match instantiated {
    Ok(result) => {
      assert_eq(result.dicts.length(), 1)
      assert_true(result.ty is Arrow(EVar(_), EVar(_)))
    }
    _ => panic()
  }
}

///|
test "auto_instantiate inserts trait dictionaries for bounded foralls" {
  let state = state_with_eq_trait_and_int_dict()
  let term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let auto = state.auto_instantiate(term)
  match auto {
    Ok(result) => {
      assert_true(result.term is TraitApp(_, _, _))
      assert_true(result.ty is Arrow(EVar(_), EVar(_)))
    }
    _ => panic()
  }
}

///|
test "add_trait_impl rejects duplicate trait implementation targets" {
  let base = state_with_eq_trait_and_int_dict()
  let duplicate = base.add_trait_impl("Eq", Type::con("Int"), mk_eq_int_dict())
  assert_true(duplicate is Err(DuplicateBinding("Eq")))
}

///|
test "add_dict rejects duplicate dictionary names" {
  let base = state_with_eq_trait_and_int_dict()
  let duplicate = base.add_dict("eqInt", mk_eq_int_dict())
  assert_true(duplicate is Err(DuplicateBinding("eqInt")))
}
