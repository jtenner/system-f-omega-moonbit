///|
test "subsumes returns unbound when general bottom-check kinding fails" {
  let state = TypeCheckerState::fresh()
  let wl : Worklist = []
  let subst : Substitution = Map::new()
  let result = state.subsumes(EVar("missing"), Type::never(), wl, subst)
  assert_true(result is Err(Unbound("missing")))
}

///|
test "check_trait_implementation can match lambda targets via fresh application" {
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
  let dict = Term::dict("Eq", Type::con("Int"), [
    (
      "eq",
      Term::lam(
        "x",
        Type::con("Int"),
        Term::lam("y", Type::con("Int"), Term::con("true", Type::con("Bool"))),
      ),
    ),
  ])
  let with_impl = must_type_state(
    with_trait.add_trait_impl("Eq", Type::con("Int"), dict),
  )
  let target = Type::lam("A", Star, Type::con("Int"))
  let found = with_impl.check_trait_implementation("Eq", target)
  assert_true(found is Ok(_))
}

///|
test "extract_pattern_labels visits nested variant and tuple nodes" {
  let pattern = Pattern::tuple([
    Pattern::variant("L", Pattern::wildcard()),
    Pattern::record([
      ("x", Pattern::variant("R", Pattern::wildcard())),
      ("y", Pattern::con("C", Type::con("Int"))),
    ]),
  ])
  let labels = pattern.extract_pattern_labels()
  assert_true(labels.contains("L"))
  assert_true(labels.contains("R"))
}

///|
test "check_exhaustive reports not-a-variant for unknown nominal application" {
  let state = state_with_primitives()
  let ty = Type::app(Type::con("Unknown"), Type::con("Int"))
  let result = state.check_exhaustive([Pattern::wildcard()], ty)
  assert_true(result is Err(NotAVariant(_)))
}

///|
test "check_pattern variant unfolds recursive mu scrutinees" {
  let state = state_with_primitives()
  let mu_variant = Type::mu("X", Type::variant([("In", Type::var_type("X"))]))
  let result = state.check_pattern(
    Pattern::variant("In", Pattern::wildcard()),
    mu_variant,
  )
  assert_true(result is Ok(_))
}

///|
test "check_pattern variant can infer enum type from evar scrutinee" {
  let state = state_with_maybe_enum()
  let evar = state.meta.fresh_meta_var(Star)
  let result = state.check_pattern(
    Pattern::variant("Some", Pattern::wildcard()),
    evar,
  )
  assert_true(result is Ok(_))
}

///|
test "check_pattern tuple handles bottom scrutinee branch" {
  let state = state_with_primitives()
  let result = state.check_pattern(
    Pattern::tuple([Pattern::wildcard(), Pattern::wildcard()]),
    Type::never(),
  )
  assert_true(result is Ok(_))
}

///|
test "check_pattern record handles bottom scrutinee branch" {
  let state = state_with_primitives()
  let result = state.check_pattern(
    Pattern::record([("x", Pattern::wildcard())]),
    Type::never(),
  )
  assert_true(result is Ok(_))
}

///|
test "substitute_type traverses bounded forall record variant mu and tuple" {
  let ty = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("X") }],
    Type::tuple([
      Type::record([("r", Type::var_type("X"))]),
      Type::variant([("v", Type::mu("M", Type::var_type("X")))]),
      Type::app(Type::con("F"), Type::var_type("X")),
      Type::lam("B", Star, Type::var_type("X")),
      Type::forall("C", Star, Type::var_type("X")),
    ]),
  )
  let out = ty.substitute_type("X", Type::con("Int"))
  let free = out.collect_type_vars()
  assert_false(free.any(n => n == "X"))
}

///|
test "check_kind supports lenient unknown vars and reports mu body mismatch" {
  let state = state_with_primitives()
  let lenient = state.check_kind(Type::var_type("Unknown"), true)
  assert_true(lenient is Ok(Star))

  let mu_bad = state.check_kind(
    Type::mu("X", Type::lam("A", Star, Type::var_type("A"))),
    false,
  )
  assert_true(mu_bad is Err(KindMismatch(_, _)))
}

///|
test "check_kind reports non-star field and constraint kinds" {
  let state = state_with_primitives()
  let record_bad = state.check_kind(
    Type::record([("x", Type::lam("A", Star, Type::var_type("A")))]),
    false,
  )
  assert_true(record_bad is Err(KindMismatch(_, _)))

  let bounded_bad = state.check_kind(
    Type::bounded_forall(
      "A",
      Star,
      [
        TraitConstraint::{
          trait_name: "Eq",
          ty: Type::lam("B", Star, Type::var_type("B")),
        },
      ],
      Type::con("Int"),
    ),
    false,
  )
  assert_true(bounded_bad is Err(KindMismatch(_, _)))
}

///|
test "check_kind reports forall body and arrow endpoint mismatches" {
  let state = state_with_primitives()
  let forall_bad = state.check_kind(
    Type::forall("A", Star, Type::lam("B", Star, Type::var_type("B"))),
    false,
  )
  assert_true(forall_bad is Err(KindMismatch(_, _)))

  let arrow_bad_from = state.check_kind(
    Type::arrow(Type::lam("A", Star, Type::var_type("A")), Type::con("Int")),
    false,
  )
  assert_true(arrow_bad_from is Err(KindMismatch(_, _)))

  let arrow_bad_to = state.check_kind(
    Type::arrow(Type::con("Int"), Type::lam("A", Star, Type::var_type("A"))),
    false,
  )
  assert_true(arrow_bad_to is Err(KindMismatch(_, _)))
}

///|
test "check_kind tuple rejects non-star elements" {
  let state = state_with_primitives()
  let result = state.check_kind(
    Type::tuple([Type::con("Int"), Type::lam("A", Star, Type::var_type("A"))]),
    false,
  )
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "unify_types reports forall and bounded-forall incompatibilities" {
  let state = state_with_primitives()
  let wl1 : Worklist = []
  let subst1 : Substitution = Map::new()
  let f1 = Type::forall("A", Star, Type::var_type("A"))
  let f2 = Type::forall("A", Kind::arrow(Star, Star), Type::var_type("A"))
  assert_true(state.unify_types(f1, f2, wl1, subst1) is Err(TypeMismatch(_, _)))

  let wl2 : Worklist = []
  let subst2 : Substitution = Map::new()
  let b1 = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Type::var_type("A"),
  )
  let b2 = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Show", ty: Type::var_type("A") }],
    Type::var_type("A"),
  )
  assert_true(state.unify_types(b1, b2, wl2, subst2) is Err(TypeMismatch(_, _)))
}

///|
test "unify_types reports lam record variant and tuple mismatches" {
  let state = state_with_primitives()

  let wl1 : Worklist = []
  let subst1 : Substitution = Map::new()
  let l1 = Type::lam("A", Star, Type::var_type("A"))
  let l2 = Type::lam("A", Kind::arrow(Star, Star), Type::var_type("A"))
  assert_true(state.unify_types(l1, l2, wl1, subst1) is Err(TypeMismatch(_, _)))

  let wl2 : Worklist = []
  let subst2 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::record([("x", Type::con("Int"))]),
      Type::record([("y", Type::con("Int"))]),
      wl2,
      subst2,
    )
    is Err(TypeMismatch(_, _)),
  )

  let wl3 : Worklist = []
  let subst3 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::variant([("L", Type::con("Int"))]),
      Type::variant([("R", Type::con("Int"))]),
      wl3,
      subst3,
    )
    is Err(TypeMismatch(_, _)),
  )

  let wl4 : Worklist = []
  let subst4 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::tuple([Type::con("Int")]),
      Type::tuple([Type::con("Int"), Type::con("Bool")]),
      wl4,
      subst4,
    )
    is Err(TypeMismatch(_, _)),
  )
}

///|
test "unify_types enum and structural variant label sets must match" {
  let state = state_with_maybe_enum()
  let enum_ty = Type::app(Type::con("Maybe"), Type::con("Int"))
  let structural = Type::variant([
    ("Some", Type::con("Int")),
    ("Other", Type::unit()),
  ])
  let wl : Worklist = []
  let subst : Substitution = Map::new()
  let result = state.unify_types(enum_ty, structural, wl, subst)
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "infer_lam reports argument kind mismatch" {
  let state = state_with_primitives()
  let lam = Term::lam(
    "x",
    Type::lam("A", Star, Type::var_type("A")),
    Term::var_term("x"),
  )
  let result = state.infer_type(lam)
  assert_true(result is Err(KindMismatch(_, _)))
}

///|
test "infer_match reports explicit empty-match inference failure" {
  let state = state_with_primitives()
  let term = Term::match_term(Term::con("one", Type::con("Int")), [])
  let result = state.infer_type(term)
  assert_true(result is Err(Message(_)))
}

///|
test "infer_fold reports non-star fold type and non-mu fold targets" {
  let state = state_with_primitives()
  let bad_kind = state.infer_type(
    Term::fold(
      Type::lam("A", Star, Type::var_type("A")),
      Term::con("one", Type::con("Int")),
    ),
  )
  assert_true(bad_kind is Err(KindMismatch(_, _)))

  let non_mu = state.infer_type(
    Term::fold(Type::con("Int"), Term::con("one", Type::con("Int"))),
  )
  assert_true(non_mu is Err(TypeMismatch(_, _)))
}

///|
test "check_type trait lambda validates constraint list and names" {
  let state = state_with_eq_trait_and_int_dict()
  let term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )

  let bad_len = Type::bounded_forall("A", Star, [], Type::con("Int"))
  assert_true(state.check_type(term, bad_len) is Err(TypeMismatch(_, _)))

  let bad_name = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Show", ty: Type::var_type("A") }],
    Type::con("Int"),
  )
  assert_true(state.check_type(term, bad_name) is Err(TypeMismatch(_, _)))
}

///|
test "check_type trait lambda validates constraint type equality" {
  let state = state_with_eq_trait_and_int_dict()
  let term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::var_term("d"),
  )
  let bad_ty = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::con("Int") }],
    Type::con("Int"),
  )
  let result = state.check_type(term, bad_ty)
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "add_enum reports parameter and kind arity mismatch messages" {
  let state = state_with_primitives()
  let result = state.add_enum(
    "Bad",
    ["A", "B"],
    [Star],
    [("X", Type::unit())],
    false,
  )
  assert_true(result is Err(Message(_)))
}

///|
test "add_trait_impl propagates dictionary validation failures" {
  let state = state_with_eq_trait_and_int_dict()
  let broken = Term::dict("Eq", Type::con("Int"), [])
  let result = state.add_trait_impl("Eq", Type::con("Bool"), broken)
  assert_true(result is Err(MissingMethod("Eq", "eq")))
}

///|
test "typecheck_with_constraints propagates inference errors" {
  let state = TypeCheckerState::fresh()
  let result = state.typecheck_with_constraints(Term::var_term("missing"))
  assert_true(result is Err(Unbound("missing")))
}

///|
test "instantiate_with_traits and auto_instantiate report missing impls" {
  let state = state_with_primitives()
  let poly = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Type::var_type("A"),
  )
  let inst = state.instantiate_with_traits(poly)
  assert_true(inst is Err(MissingTraitImpl("Eq", _)))

  let with_trait = must_type_state(
    state.add_trait_def("Eq", "A", Star, [
      (
        "eq",
        Type::arrow(
          Type::var_type("A"),
          Type::arrow(Type::var_type("A"), Type::con("Bool")),
        ),
      ),
    ]),
  )
  let term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::var_term("d"),
  )
  let auto = with_trait.auto_instantiate(term)
  assert_true(auto is Err(_))
}
