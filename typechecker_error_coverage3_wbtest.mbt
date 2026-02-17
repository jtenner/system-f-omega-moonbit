///|
test "types_equal spine and duplicate-record error edges" {
  let state = TypeCheckerState::fresh()

  let app_left = Type::app(
    Type::con("Box"),
    Type::forall("A", Star, Type::var_type("A")),
  )
  let app_right = Type::app(
    Type::con("Box"),
    Type::forall("B", Star, Type::var_type("B")),
  )
  assert_true(state.types_equal(app_left, app_right))

  assert_false(
    state.types_equal_spine(
      Type::con("Box"),
      Type::app(Type::con("Box"), Type::con("Int")),
    ),
  )
  assert_true(
    state.types_equal_spine(
      Type::app(Type::con("Pair"), Type::con("Int")),
      Type::app(Type::con("Pair"), Type::con("Int")),
    ),
  )

  assert_false(
    state.types_equal(
      Type::record([("x", Type::con("Int"))]),
      Type::record([("x", Type::con("Bool"))]),
    ),
  )
  assert_false(
    state.types_equal(
      Type::record([("a", Type::con("Int")), ("a", Type::con("Int"))]),
      Type::record([("a", Type::con("Int")), ("b", Type::con("Int"))]),
    ),
  )
  assert_false(
    state.types_equal(
      Type::record([("a", Type::con("Int")), ("a", Type::con("Int"))]),
      Type::record([("a", Type::con("Bool")), ("a", Type::con("Int"))]),
    ),
  )

  assert_false(
    state.types_equal(
      Type::bounded_forall(
        "A",
        Star,
        [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
        Type::var_type("A"),
      ),
      Type::bounded_forall(
        "B",
        Kind::arrow(Star, Star),
        [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") }],
        Type::var_type("B"),
      ),
    ),
  )
  assert_false(
    state.types_equal(
      Type::bounded_forall(
        "A",
        Star,
        [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
        Type::var_type("A"),
      ),
      Type::bounded_forall("B", Star, [], Type::var_type("B")),
    ),
  )

  assert_false(
    state.types_equal(
      Type::variant([("L", Type::unit())]),
      Type::variant([("L", Type::unit()), ("R", Type::unit())]),
    ),
  )

  assert_true(
    state.types_equal(
      Type::tuple([Type::forall("A", Star, Type::var_type("A"))]),
      Type::tuple([Type::forall("B", Star, Type::var_type("B"))]),
    ),
  )
}

///|
test "occurs checks bindings and enum exhaustive error paths" {
  assert_false(Type::forall("A", Star, Type::var_type("A")).occurs_check("A"))
  assert_true(Type::forall("B", Star, Type::var_type("A")).occurs_check("A"))
  assert_false(Type::lam("A", Star, Type::var_type("A")).occurs_check("A"))
  assert_true(
    Type::lam("B", Star, Type::app(Type::var_type("A"), Type::var_type("B"))).occurs_check(
      "A",
    ),
  )
  assert_true(Type::record([("x", Type::var_type("A"))]).occurs_check("A"))
  assert_true(Type::variant([("x", Type::var_type("A"))]).occurs_check("A"))
  assert_true(
    Type::bounded_forall(
      "T",
      Star,
      [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
      Type::con("Int"),
    ).occurs_check("A"),
  )
  assert_true(Type::mu("X", Type::var_type("X")).occurs_check("Z"))
  assert_true(Type::tuple([Type::var_type("A")]).occurs_check("A"))
  assert_false(Type::never().occurs_check("A"))

  let state = TypeCheckerState::fresh()
  let e = state.meta.fresh_meta_var(Star)
  let e_name = match e {
    EVar(name) => name
    _ => panic()
  }
  let constrained = Type::bounded_forall(
    "T",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: EVar(e_name) }],
    Type::var_type("T"),
  )
  assert_true(state.meta.occurs_check_evar(e_name, constrained))

  let bindings = state.bindings(
    Pattern::tuple([
      Pattern::variant("Some", Pattern::var_pattern("x")),
      Pattern::con("Ctor", Type::con("Int")),
    ]),
  )
  assert_eq(bindings.length(), 1)
  assert_eq(bindings[0].0, "x")

  let empty_labels = Pattern::var_pattern("v").extract_pattern_labels()
  assert_eq(empty_labels.length(), 0)

  let maybe_state = state_with_maybe_enum()
  let maybe_int = Type::app(Type::con("Maybe"), Type::con("Int"))
  let missing = maybe_state.check_exhaustive(
    [Pattern::variant("None", Pattern::wildcard())],
    maybe_int,
  )
  assert_true(missing is Err(MissingCase(_)))
  let complete = maybe_state.check_exhaustive(
    [
      Pattern::variant("None", Pattern::wildcard()),
      Pattern::variant("Some", Pattern::wildcard()),
    ],
    maybe_int,
  )
  assert_true(complete is Ok(_))
}

///|
test "check_pattern variant tuple and record return targeted errors" {
  let bad_enum_state = TypeCheckerState::fresh().extend_context([
    Binding::enum_def(
      "Broken",
      Star,
      ["A"],
      [("Wrap", Type::var_type("A"))],
      false,
    ),
  ])
  let unknown_ty = bad_enum_state.meta.fresh_meta_var(Star)
  let bad_kind = bad_enum_state.check_pattern(
    Pattern::variant("Wrap", Pattern::wildcard()),
    unknown_ty,
  )
  assert_true(bad_kind is Err(KindMismatch(_, _)))

  let not_nominal = bad_enum_state.check_pattern(
    Pattern::variant("Wrap", Pattern::wildcard()),
    Type::app(Type::var_type("F"), Type::con("Int")),
  )
  assert_true(not_nominal is Err(NotAVariant(_)))

  let maybe_state = state_with_maybe_enum()
  let nominal_ok = maybe_state.check_pattern(
    Pattern::variant("Some", Pattern::var_pattern("x")),
    Type::app(Type::con("Maybe"), Type::con("Int")),
  )
  assert_true(nominal_ok is Ok(_))

  let not_variant_default = maybe_state.check_pattern(
    Pattern::variant("Some", Pattern::wildcard()),
    Type::arrow(Type::con("Int"), Type::con("Int")),
  )
  assert_true(not_variant_default is Err(NotAVariant(_)))

  let tuple_inner_error = maybe_state.check_pattern(
    Pattern::tuple([Pattern::variant("Some", Pattern::wildcard())]),
    Type::tuple([Type::con("Int")]),
  )
  assert_true(tuple_inner_error is Err(NotAVariant(_)))

  let tuple_bottom_error = maybe_state.check_pattern(
    Pattern::tuple([Pattern::variant("NeverHere", Pattern::wildcard())]),
    Type::never(),
  )
  assert_true(tuple_bottom_error is Err(NotAVariant(_)))

  let record_bottom_error = maybe_state.check_pattern(
    Pattern::record([("x", Pattern::variant("NeverHere", Pattern::wildcard()))]),
    Type::never(),
  )
  assert_true(record_bottom_error is Err(_))

  let record_arity_error = maybe_state.check_pattern(
    Pattern::record([("x", Pattern::wildcard()), ("y", Pattern::wildcard())]),
    Type::record([("x", Type::con("Int"))]),
  )
  assert_true(record_arity_error is Err(TypeMismatch(_, _)))

  let record_success = maybe_state.check_pattern(
    Pattern::record([("x", Pattern::var_pattern("v"))]),
    Type::record([("x", Type::con("Int"))]),
  )
  assert_true(record_success is Ok(_))

  let record_inner_error = maybe_state.check_pattern(
    Pattern::record([("x", Pattern::variant("Some", Pattern::wildcard()))]),
    Type::record([("x", Type::con("Int"))]),
  )
  assert_true(record_inner_error is Err(NotAVariant(_)))
}

///|
test "substitute_type and check_kind cover nested propagation errors" {
  let same_bound = Type::bounded_forall(
    "X",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("X") }],
    Type::var_type("X"),
  )
  assert_eq(same_bound.substitute_type("X", Type::con("Int")), same_bound)

  let same_lam = Type::lam("X", Star, Type::var_type("X"))
  assert_eq(same_lam.substitute_type("X", Type::con("Int")), same_lam)

  let same_mu = Type::mu("X", Type::var_type("X"))
  assert_eq(same_mu.substitute_type("X", Type::con("Int")), same_mu)

  assert_eq(Type::never().substitute_type("X", Type::con("Int")), Type::never())

  assert_true(Kind::star().is_star_kind())

  let kind_state = state_with_primitives().extend_context([
    Binding::type_alias(
      "BadAlias",
      ["A"],
      [Star],
      Type::var_type("MissingBody"),
    ),
    Binding::enum_def(
      "TwoParam",
      Kind::arrow(Star, Kind::arrow(Star, Star)),
      ["A", "B"],
      [("Mk", Type::tuple([Type::var_type("A"), Type::var_type("B")]))],
      false,
    ),
  ])

  assert_true(
    kind_state.check_kind(Type::con("BadAlias"), false)
    is Err(Unbound("MissingBody")),
  )
  assert_true(kind_state.check_kind(Type::con("TwoParam"), false) is Ok(_))
  assert_true(
    kind_state.check_kind(Type::var_type("Nope"), false) is Err(Unbound("Nope")),
  )
  assert_true(
    kind_state.check_kind(Type::mu("X", Type::var_type("NoBody")), false)
    is Err(Unbound("NoBody")),
  )
  assert_true(
    kind_state.check_kind(
      Type::variant([("x", Type::var_type("NoCase"))]),
      false,
    )
    is Err(Unbound("NoCase")),
  )
  assert_true(
    kind_state.check_kind(
      Type::record([("x", Type::var_type("NoField"))]),
      false,
    )
    is Err(Unbound("NoField")),
  )

  assert_true(
    kind_state.check_kind(
      Type::app(Type::var_type("NoFunc"), Type::con("Int")),
      false,
    )
    is Err(Unbound("NoFunc")),
  )
  assert_true(
    kind_state.check_kind(
      Type::app(
        Type::lam("A", Star, Type::var_type("A")),
        Type::var_type("NoArg"),
      ),
      false,
    )
    is Err(Unbound("NoArg")),
  )
  assert_true(
    kind_state.check_kind(
      Type::lam("A", Star, Type::var_type("NoBody2")),
      false,
    )
    is Err(Unbound("NoBody2")),
  )
  assert_true(
    kind_state.check_kind(
      Type::bounded_forall(
        "A",
        Star,
        [
          TraitConstraint::{
            trait_name: "Eq",
            ty: Type::var_type("NoConstraint"),
          },
        ],
        Type::con("Int"),
      ),
      false,
    )
    is Err(Unbound("NoConstraint")),
  )
  assert_true(
    kind_state.check_kind(
      Type::bounded_forall("A", Star, [], Type::var_type("NoBody3")),
      false,
    )
    is Err(Unbound("NoBody3")),
  )
  assert_true(
    kind_state.check_kind(
      Type::bounded_forall(
        "A",
        Star,
        [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
        Type::lam("B", Star, Type::var_type("B")),
      ),
      false,
    )
    is Err(KindMismatch(_, _)),
  )
  assert_true(
    kind_state.check_kind(
      Type::forall("A", Star, Type::var_type("NoBody4")),
      false,
    )
    is Err(Unbound("NoBody4")),
  )
  assert_true(
    kind_state.check_kind(
      Type::arrow(Type::var_type("NoFrom"), Type::con("Int")),
      false,
    )
    is Err(Unbound("NoFrom")),
  )
  assert_true(
    kind_state.check_kind(
      Type::arrow(Type::con("Int"), Type::var_type("NoTo")),
      false,
    )
    is Err(Unbound("NoTo")),
  )
  assert_true(
    kind_state.check_kind(
      Type::tuple([Type::con("Int"), Type::var_type("NoTuple")]),
      false,
    )
    is Err(Unbound("NoTuple")),
  )
  assert_true(kind_state.check_kind(Type::never(), false) is Ok(Star))

  let renamed = Type::bounded_forall(
    "Q",
    Star,
    [
      TraitConstraint::{
        trait_name: "Eq",
        ty: Type::app(Type::var_type("X"), Type::var_type("Q")),
      },
    ],
    Type::lam(
      "L",
      Star,
      Type::mu("M", Type::app(Type::var_type("X"), Type::var_type("M"))),
    ),
  ).alpha_rename("X", "Z")
  assert_true(renamed.occurs_check("Z"))
}

///|
test "unify_types meta-variable and structural mismatch errors" {
  let state = state_with_primitives()

  let wl1 : Worklist = []
  let subst1 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::con("Int"),
      Type::mu("X", Type::var_type("X")),
      wl1,
      subst1,
    )
    is Err(Cyclic("X")),
  )

  let wl2 : Worklist = []
  let subst2 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::never(),
      Type::lam("A", Star, Type::var_type("A")),
      wl2,
      subst2,
    )
    is Err(TypeMismatch(_, _)),
  )

  let e1 = state.meta.fresh_meta_var(Star)
  let n1 = match e1 {
    EVar(name) => name
    _ => panic()
  }
  let wl3 : Worklist = []
  let subst3 : Substitution = Map::new()
  assert_true(state.unify_types(Type::var_type("A"), e1, wl3, subst3) is Ok(_))
  assert_true(subst3.contains(n1))

  let e2 = state.meta.fresh_meta_var(Star)
  let n2 = match e2 {
    EVar(name) => name
    _ => panic()
  }
  state.meta.solutions.set(n2, Type::con("Int"))
  let wl4 : Worklist = []
  let subst4 : Substitution = Map::new()
  assert_true(
    state.unify_types(e2, Type::con("Bool"), wl4, subst4)
    is Err(TypeMismatch(_, _)),
  )

  let e3 = state.meta.fresh_meta_var(Star)
  let n3 = match e3 {
    EVar(name) => name
    _ => panic()
  }
  state.meta.solutions.set(n3, Type::con("Int"))
  let wl5 : Worklist = []
  let subst5 : Substitution = Map::new()
  assert_true(
    state.unify_types(Type::con("Bool"), e3, wl5, subst5)
    is Err(TypeMismatch(_, _)),
  )

  let e4 = state.meta.fresh_meta_var(Star)
  let n4 = match e4 {
    EVar(name) => name
    _ => panic()
  }
  let wl6 : Worklist = []
  let subst6 : Substitution = Map::new()
  subst6.set(n4, Type::con("Int"))
  assert_true(
    state.unify_types(Type::con("Bool"), e4, wl6, subst6)
    is Err(TypeMismatch(_, _)),
  )

  let e5 = state.meta.fresh_meta_var(Star)
  let n5 = match e5 {
    EVar(name) => name
    _ => panic()
  }
  let wl7 : Worklist = []
  let subst7 : Substitution = Map::new()
  assert_true(
    state.unify_types(Type::arrow(Type::con("Int"), EVar(n5)), e5, wl7, subst7)
    is Err(Cyclic(_)),
  )

  let wl8 : Worklist = []
  let subst8 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::app(Type::con("Box"), Type::con("Int")),
      Type::app(Type::con("Box"), Type::con("Bool")),
      wl8,
      subst8,
    )
    is Ok(_),
  )

  let pairish_state = must_type_state(
    state.add_enum(
      "Pairish",
      ["A", "B"],
      [Star, Star],
      [("Mk", Type::tuple([Type::var_type("A"), Type::var_type("B")]))],
      false,
    ),
  )
  let wl9 : Worklist = []
  let subst9 : Substitution = Map::new()
  assert_true(
    pairish_state.unify_types(
      Type::variant([("Mk", Type::tuple([Type::con("Int"), Type::con("Bool")]))]),
      Type::app(Type::con("Pairish"), Type::con("Int")),
      wl9,
      subst9,
    )
    is Err(TypeMismatch(_, _)),
  )

  let wl10 : Worklist = []
  let subst10 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::variant([("A", Type::con("Int"))]),
      Type::variant([("A", Type::con("Int")), ("B", Type::con("Bool"))]),
      wl10,
      subst10,
    )
    is Err(TypeMismatch(_, _)),
  )

  let e7 = state.meta.fresh_meta_var(Star)
  let wl11 : Worklist = []
  let subst11 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::variant([("A", e7)]),
      Type::variant([("A", Type::con("Int"))]),
      wl11,
      subst11,
    )
    is Ok(_),
  )
  assert_eq(wl11.length(), 1)

  let wl12 : Worklist = []
  let subst12 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::mu("X", Type::tuple([Type::var_type("X")])),
      Type::mu("Y", Type::tuple([Type::con("Int")])),
      wl12,
      subst12,
    )
    is Ok(_),
  )
  assert_eq(wl12.length(), 1)

  let e8 = state.meta.fresh_meta_var(Star)
  let wl13 : Worklist = []
  let subst13 : Substitution = Map::new()
  assert_true(
    state.unify_types(
      Type::tuple([e8]),
      Type::tuple([Type::con("Int")]),
      wl13,
      subst13,
    )
    is Ok(_),
  )
  assert_eq(wl13.length(), 1)
}

///|
test "unify_variable and apply_substitution edge behavior" {
  let state = state_with_primitives()

  let s1 : Substitution = Map::new()
  s1.set("A", Type::con("Int"))
  assert_true(state.unify_variable("A", Type::con("Int"), s1) is Ok(_))
  assert_true(
    state.unify_variable("A", Type::con("Bool"), s1) is Err(TypeMismatch(_, _)),
  )

  let s2 : Substitution = Map::new()
  assert_true(
    state.unify_variable("A", Type::mu("X", Type::var_type("X")), s2)
    is Err(Cyclic("X")),
  )

  let s3 : Substitution = Map::new()
  assert_true(state.unify_variable("A", Type::con("Int"), s3) is Ok(_))
  assert_true(s3.contains("A"))

  let e_subst : Substitution = Map::new()
  e_subst.set("0", EVar("0"))
  ignore(state.apply_substitution(e_subst, EVar("0")))
  ignore(state.apply_substitution(Map::new(), Type::never()))

  let deep_subst = Map::from_array([
    ("X", Type::con("Int")),
    ("Y", Type::con("Bool")),
  ])
  let deep_type = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("X") }],
    Type::lam(
      "B",
      Star,
      Type::tuple([
        Type::app(Type::var_type("X"), Type::var_type("Y")),
        Type::mu("M", Type::var_type("X")),
        Type::never(),
      ]),
    ),
  )
  ignore(state.apply_substitution(deep_subst, deep_type))
}

///|
test "check_type lambda forall trait-lambda and fallback errors" {
  let state = state_with_primitives()
  assert_true(
    state.check_type(Term::unit(), Type::lam("A", Star, Type::var_type("A")))
    is Err(KindMismatch(_, _)),
  )

  let lam_unify_err = state.check_type(
    Term::lam("x", Type::con("Int"), Term::var_term("x")),
    Type::arrow(Type::con("Bool"), Type::con("Int")),
  )
  assert_true(lam_unify_err is Err(TypeMismatch(_, _)))

  let lam_solve_err = state.check_type(
    Term::lam(
      "x",
      Type::arrow(Type::con("Int"), Type::con("Bool")),
      Term::con("one", Type::con("Int")),
    ),
    Type::arrow(
      Type::arrow(Type::con("Int"), Type::con("Int")),
      Type::con("Int"),
    ),
  )
  assert_true(lam_solve_err is Err(TypeMismatch(_, _)))

  let lam_bottom = state.check_type(
    Term::lam("x", Type::never(), Term::con("one", Type::con("Int"))),
    Type::arrow(Type::never(), Type::con("Int")),
  )
  assert_true(lam_bottom is Ok(_))

  let meta_arg = state.meta.fresh_meta_var(Star)
  let lam_meta = state.check_type(
    Term::lam("x", meta_arg, Term::con("one", Type::con("Int"))),
    Type::arrow(Type::con("Int"), Type::con("Int")),
  )
  assert_true(lam_meta is Ok(_))

  let tylam_kind_err = state.check_type(
    Term::tylam("A", Star, Term::unit()),
    Type::forall("B", Kind::arrow(Star, Star), Type::unit()),
  )
  assert_true(tylam_kind_err is Err(KindMismatch(_, _)))

  let tylam_body_err = state.check_type(
    Term::tylam("A", Star, Term::var_term("missing")),
    Type::forall("B", Star, Type::con("Int")),
  )
  assert_true(tylam_body_err is Err(Unbound("missing")))

  let trait_state = state_with_eq_trait_and_int_dict()
  let trait_term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::con(
      "eqImpl",
      Type::arrow(
        Type::var_type("A"),
        Type::arrow(Type::var_type("A"), Type::con("Bool")),
      ),
    ),
  )
  let trait_kind_err = trait_state.check_type(
    trait_term,
    Type::bounded_forall(
      "B",
      Kind::arrow(Star, Star),
      [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") }],
      Type::arrow(
        Type::var_type("B"),
        Type::arrow(Type::var_type("B"), Type::con("Bool")),
      ),
    ),
  )
  assert_true(trait_kind_err is Err(KindMismatch(_, _)))

  let trait_ok = trait_state.check_type(
    trait_term,
    Type::bounded_forall(
      "B",
      Star,
      [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") }],
      Type::arrow(
        Type::var_type("B"),
        Type::arrow(Type::var_type("B"), Type::con("Bool")),
      ),
    ),
  )
  assert_true(trait_ok is Ok(_))

  let record_len_err = state.check_type(
    Term::record([("x", Term::unit())]),
    Type::record([]),
  )
  assert_true(record_len_err is Err(TypeMismatch(_, _)))

  let record_field_err = state.check_type(
    Term::record([("x", Term::con("t", Type::con("Bool")))]),
    Type::record([("x", Type::con("Int"))]),
  )
  assert_true(record_field_err is Err(TypeMismatch(_, _)))

  let tuple_ok = state.check_type(
    Term::tuple([
      Term::con("one", Type::con("Int")),
      Term::con("t", Type::con("Bool")),
    ]),
    Type::tuple([Type::con("Int"), Type::con("Bool")]),
  )
  assert_true(tuple_ok is Ok(_))

  let inject_ok = state.check_type(
    Term::inject("A", Term::unit(), Type::variant([("A", Type::unit())])),
    Type::variant([("A", Type::unit())]),
  )
  assert_true(inject_ok is Err(KindMismatch(_, _)))

  let mu_int = Type::mu("X", Type::con("Int"))
  let fold_ok = state.check_type(
    Term::fold(mu_int, Term::con("one", Type::con("Int"))),
    mu_int,
  )
  assert_true(fold_ok is Ok(_))

  let fallback_infer_err = state.check_type(
    Term::var_term("missing"),
    Type::con("Int"),
  )
  assert_true(fallback_infer_err is Err(Unbound("missing")))

  let poly_term = Term::tylam(
    "A",
    Star,
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let fallback_forall = state.check_type(
    poly_term,
    Type::arrow(Type::con("Int"), Type::con("Int")),
  )
  assert_true(fallback_forall is Ok(_))

  let expected_meta = state.meta.fresh_meta_var(Star)
  let fallback_meta = state.check_type(
    Term::con("one", Type::con("Int")),
    expected_meta,
  )
  assert_true(fallback_meta is Ok(_))
}

///|
test "infer_inject infer_match and infer helpers report expected errors" {
  let state = state_with_primitives()

  let bottom_variant = Type::variant([("Bot", Type::never())])
  assert_true(
    state.infer_type(
      Term::inject("Bot", Term::con("v", Type::con("Int")), bottom_variant),
    )
    is Ok(_),
  )

  let unit_variant = Type::variant([("U", Type::unit())])
  assert_true(
    state.infer_type(
      Term::inject("U", Term::con("v", Type::con("Int")), unit_variant),
    )
    is Err(TypeMismatch(_, _)),
  )

  let one_tuple_variant = Type::variant([
    ("One", Type::tuple([Type::con("Int")])),
  ])
  assert_true(
    state.infer_type(
      Term::inject("One", Term::con("one", Type::con("Int")), one_tuple_variant),
    )
    is Ok(_),
  )

  let pair_variant = Type::variant([
    ("Pair", Type::tuple([Type::con("Int"), Type::con("Bool")])),
  ])
  assert_true(
    state.infer_type(
      Term::inject("Pair", Term::con("one", Type::con("Int")), pair_variant),
    )
    is Err(TypeMismatch(_, _)),
  )
  assert_true(
    state.infer_type(
      Term::inject(
        "Pair",
        Term::tuple([Term::con("one", Type::con("Int"))]),
        pair_variant,
      ),
    )
    is Err(TypeMismatch(_, _)),
  )
  assert_true(
    state.infer_type(
      Term::inject(
        "Pair",
        Term::tuple([
          Term::con("one", Type::con("Int")),
          Term::con("t", Type::con("Bool")),
        ]),
        pair_variant,
      ),
    )
    is Ok(_),
  )

  let int_variant = Type::variant([("I", Type::con("Int"))])
  assert_true(
    state.infer_type(
      Term::inject("I", Term::con("t", Type::con("Bool")), int_variant),
    )
    is Err(TypeMismatch(_, _)),
  )

  let alias_state = state.extend_context([
    Binding::type_alias(
      "AliasV",
      [],
      [],
      Type::variant([("A", Type::con("Int"))]),
    ),
    Binding::type_alias(
      "AliasFn",
      ["T"],
      [Star],
      Type::variant([("A", Type::var_type("T"))]),
    ),
  ])
  assert_true(
    alias_state.infer_type(
      Term::inject("A", Term::con("one", Type::con("Int")), Type::con("AliasV")),
    )
    is Ok(_),
  )
  assert_true(
    alias_state.infer_type(
      Term::inject("B", Term::con("one", Type::con("Int")), Type::con("AliasV")),
    )
    is Err(InvalidVariantLabel(_, "B")),
  )

  let maybe_state = state_with_maybe_enum()
  assert_true(
    maybe_state.infer_type(
      Term::inject(
        "Some",
        Term::con("one", Type::con("Int")),
        Type::con("Maybe"),
      ),
    )
    is Err(TypeMismatch(_, _)),
  )
  assert_true(
    maybe_state.infer_type(
      Term::inject(
        "Some",
        Term::con("one", Type::con("Int")),
        Type::app(
          Type::con("Maybe"),
          Type::app(Type::con("Maybe"), Type::con("Int")),
        ),
      ),
    )
    is Err(KindMismatch(_, _)),
  )
  assert_true(
    maybe_state.infer_type(
      Term::inject(
        "Nope",
        Term::con("one", Type::con("Int")),
        Type::app(Type::con("Maybe"), Type::con("Int")),
      ),
    )
    is Err(InvalidVariantLabel(_, "Nope")),
  )
  assert_true(
    maybe_state.infer_type(
      Term::inject(
        "Some",
        Term::con("t", Type::con("Bool")),
        Type::app(Type::con("Maybe"), Type::con("Int")),
      ),
    )
    is Err(TypeMismatch(_, _)),
  )

  assert_true(
    alias_state.infer_type(
      Term::inject(
        "B",
        Term::con("one", Type::con("Int")),
        Type::app(Type::con("AliasFn"), Type::con("Int")),
      ),
    )
    is Err(InvalidVariantLabel(_, "B")),
  )
  assert_true(
    alias_state.infer_type(
      Term::inject(
        "A",
        Term::con("one", Type::con("Int")),
        Type::app(Type::con("UnknownHead"), Type::con("Int")),
      ),
    )
    is Err(NotAVariant(_)),
  )
  assert_true(
    alias_state.infer_type(
      Term::inject(
        "A",
        Term::con("one", Type::con("Int")),
        Type::app(Type::var_type("F"), Type::con("Int")),
      ),
    )
    is Err(NotAVariant(_)),
  )
  assert_true(
    alias_state.infer_type(
      Term::inject(
        "A",
        Term::con("one", Type::con("Int")),
        Type::arrow(Type::con("Int"), Type::con("Int")),
      ),
    )
    is Err(NotAVariant(_)),
  )

  assert_true(
    state.infer_type(Term::record([("x", Term::var_term("missing"))]))
    is Err(Unbound("missing")),
  )
  assert_true(
    state.infer_type(Term::project(Term::var_term("missing"), "x"))
    is Err(Unbound("missing")),
  )
  assert_true(
    state.infer_type(Term::tuple([Term::var_term("missing")]))
    is Err(Unbound("missing")),
  )
  assert_true(
    state.infer_type(Term::tuple_project(Term::var_term("missing"), 0))
    is Err(Unbound("missing")),
  )
  assert_true(
    state.infer_type(Term::unfold(Term::var_term("missing")))
    is Err(Unbound("missing")),
  )
  assert_true(
    state.infer_type(
      Term::fold(Type::mu("X", Type::con("Int")), Term::var_term("missing")),
    )
    is Err(Unbound("missing")),
  )
  assert_true(
    state.infer_type(
      Term::fold(
        Type::mu("X", Type::con("Int")),
        Term::con("b", Type::con("Bool")),
      ),
    )
    is Err(TypeMismatch(_, _)),
  )

  assert_true(
    state.infer_type(Term::match_term(Term::var_term("missing"), []))
    is Err(Unbound("missing")),
  )
  assert_true(
    state.infer_type(
      Term::match_term(Term::con("v", Type::con("Int")), [
        (Pattern::variant("A", Pattern::wildcard()), Term::unit()),
      ]),
    )
    is Err(NotAVariant(_)),
  )
  assert_true(
    state.infer_type(
      Term::match_term(Term::con("v", Type::variant([("A", Type::unit())])), [
        (Pattern::variant("A", Pattern::wildcard()), Term::var_term("missing")),
      ]),
    )
    is Err(Unbound("missing")),
  )

  let branch_scrutinee = Term::inject(
    "L",
    Term::unit(),
    Type::variant([("L", Type::unit()), ("R", Type::unit())]),
  )
  let branch_conflict = state.infer_type(
    Term::match_term(branch_scrutinee, [
      (
        Pattern::variant("L", Pattern::wildcard()),
        Term::lam("x", Type::con("Int"), Term::var_term("x")),
      ),
      (
        Pattern::variant("R", Pattern::wildcard()),
        Term::lam("x", Type::con("Int"), Term::con("t", Type::con("Bool"))),
      ),
    ]),
  )
  assert_true(branch_conflict is Err(TypeMismatch(_, _)))
}

///|
test "normalize rename free-type and import/collect dependency error edges" {
  let state = state_with_primitives().extend_context([
    Binding::type_alias("Loop0", [], [], Type::con("Loop0")),
    Binding::type_alias(
      "Self",
      ["A"],
      [Star],
      Type::app(Type::con("Self"), Type::var_type("A")),
    ),
    Binding::enum_def(
      "Weird",
      Star,
      [],
      [
        (
          "W",
          Type::tuple([
            Type::arrow(Type::con("Weird"), Type::con("Int")),
            Type::app(
              Type::lam("T", Star, Type::var_type("T")),
              Type::con("Weird"),
            ),
            Type::forall("Q", Star, Type::con("Weird")),
            Type::bounded_forall(
              "Q",
              Star,
              [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("Q") }],
              Type::con("Weird"),
            ),
            Type::record([("rec", Type::con("Weird"))]),
            Type::variant([("case", Type::con("Weird"))]),
            Type::mu("M", Type::con("Weird")),
            Type::tuple([Type::con("Weird")]),
          ]),
        ),
      ],
      true,
    ),
  ])

  ignore(state.normalize_type(Type::con("Loop0")))
  ignore(state.normalize_type(Type::app(Type::con("Self"), Type::con("Int"))))
  ignore(state.normalize_type(Type::con("Weird")))
  ignore(
    state.normalize_type(
      Type::app(Type::lam("A", Star, Type::var_type("A")), Type::con("Int")),
    ),
  )
  ignore(
    state.normalize_type(Type::mu("X", Type::mu("X", Type::var_type("X")))),
  )

  let ren = Map::from_array([("only", "renamed")])
  let ty = Type::bounded_forall(
    "A",
    Star,
    [
      TraitConstraint::{
        trait_name: "Eq",
        ty: Type::record([("lbl", Type::var_type("A"))]),
      },
    ],
    Type::variant([("lbl2", Type::var_type("A"))]),
  )
  ignore(state.rename_type(ty, ren))

  let term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::dict("Eq", Type::var_type("A"), [
      ("eq", Term::trait_method(Term::con("ctor", Type::con("Int")), "eq")),
    ]),
  )
  ignore(state.rename_term(term, ren))
  ignore(
    state.rename_pattern(
      Pattern::record([
        ("lbl", Pattern::con("Ctor", Type::con("Int"))),
        ("lbl2", Pattern::variant("Case", Pattern::var_pattern("x"))),
      ]),
      ren,
      Set::new(),
    ),
  )
  ignore(state.rename_binding(Binding::type_binding("T", Star), ren))
  ignore(
    state.rename_binding(
      Binding::trait_impl(
        "Eq",
        Type::con("Int"),
        Term::dict("Eq", Type::con("Int"), []),
      ),
      ren,
    ),
  )
  ignore(state.rename_binding(Binding::dict("d", "Eq", Type::con("Int")), ren))
  ignore(
    state.rename_binding(
      Binding::enum_def("E", Star, [], [("L", Type::con("Int"))], false),
      ren,
    ),
  )

  let free = state.compute_free_types(
    Type::tuple([
      EVar("0"),
      Type::never(),
      Type::forall("A", Star, Type::var_type("A")),
      Type::lam("B", Star, Type::var_type("B")),
    ]),
  )
  assert_true(free.type_vars.length() >= 0)

  let impl_dict = Term::dict(
    "Tr",
    Type::bounded_forall(
      "A",
      Star,
      [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
      Type::record([("lab", Type::var_type("A"))]),
    ),
    [
      (
        "m",
        Term::trait_app(
          Term::var_term("f"),
          Type::app(Type::con("Box"), Type::var_type("T")),
          [Term::var_term("d0"), Term::con("Ctor", Type::con("CtorTy"))],
        ),
      ),
    ],
  )
  let deps_state = TypeCheckerState::fresh().extend_context([
    Binding::trait_impl(
      "Tr",
      Type::bounded_forall(
        "A",
        Star,
        [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
        Type::record([("lab", Type::var_type("A"))]),
      ),
      impl_dict,
    ),
    Binding::dict("d", "Tr", Type::con("Int")),
    Binding::trait_def("Tr", "X", Star, [
      ("m", Type::arrow(Type::var_type("X"), Type::con("Int"))),
    ]),
    Binding::type_binding("Box", Kind::arrow(Star, Star)),
  ])

  let deps = deps_state.collect_dependencies(["Tr"])
  assert_true(deps is Err(CircularImport(_, _)))

  let cyclic_import = import_module(
    from=deps_state,
    into=TypeCheckerState::fresh(),
    roots=["Tr"],
    aliases=None,
  )
  assert_true(cyclic_import is Err(CircularImport(_, _)))

  let simple_from = TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])

  let import_aliases = ImportAliases::{
    types: None,
    traits: Some(Map::from_array([("Tr", "TrRen")])),
    terms: None,
    labels: None,
  }
  let imported = import_module(
    from=simple_from,
    into=TypeCheckerState::fresh(),
    roots=["x"],
    aliases=Some(import_aliases),
  )
  assert_true(imported is Ok(_))

  let incoming_none = import_module(
    from=deps_state,
    into=TypeCheckerState::fresh().extend_context([
      Binding::term("taken", Type::con("Int")),
    ]),
    roots=["missingRoot"],
    aliases=Some(ImportAliases::{
      types: None,
      traits: None,
      terms: Some(Map::from_array([("missingRoot", "taken")])),
      labels: None,
    }),
  )
  assert_true(incoming_none is Ok(_))

  let cycle_state = TypeCheckerState::fresh().extend_context([
    Binding::term("A", Type::con("B")),
    Binding::term("B", Type::con("A")),
  ])
  let cycle_import = import_module(
    from=cycle_state,
    into=TypeCheckerState::fresh(),
    roots=["A"],
    aliases=None,
  )
  assert_true(cycle_import is Err(CircularImport(_, _)))
}
