///|
test "unify_types branch sweep covers major structural and meta-variable paths" {
  let state = state_with_primitives()

  let run = fn(left : Type, right : Type) -> Result[Unit, TypingError] {
    let wl : Worklist = []
    let subst : Substitution = Map::new()
    let r = state.unify_types(left, right, wl, subst)
    match r {
      Ok(_) => ignore(state.solve_constraints(wl, subst))
      _ => ()
    }
    r
  }

  ignore(run(Type::mu("X", Type::con("Int")), Type::con("Int")))
  ignore(run(Type::con("Int"), Type::mu("X", Type::con("Int"))))
  assert_true(run(Type::never(), Type::never()) is Ok(_))
  assert_true(run(Type::never(), Type::con("Int")) is Ok(_))
  assert_true(run(Type::con("Int"), Type::never()) is Err(TypeMismatch(_, _)))
  assert_true(
    run(Type::var_type("A"), Type::var_type("B")) is Err(TypeMismatch(_, _)),
  )
  assert_true(
    run(Type::var_type("A"), Type::arrow(Type::var_type("A"), Type::con("Int")))
    is Err(Cyclic("A")),
  )
  assert_true(
    run(Type::var_type("A"), Type::con("Int")) is Err(TypeMismatch(_, _)),
  )
  assert_true(
    run(Type::con("Int"), Type::var_type("A")) is Err(TypeMismatch(_, _)),
  )

  let e1 = state.meta.fresh_meta_var(Star)
  let n1 = match e1 {
    EVar(name) => name
    _ => panic()
  }
  state.meta.solutions.set(n1, Type::con("Int"))
  assert_true(run(e1, Type::con("Int")) is Ok(_))

  let e2 = state.meta.fresh_meta_var(Star)
  let n2 = match e2 {
    EVar(name) => name
    _ => panic()
  }
  let wl2 : Worklist = []
  let subst2 : Substitution = Map::new()
  subst2.set(n2, Type::con("Int"))
  assert_true(state.unify_types(e2, Type::con("Int"), wl2, subst2) is Ok(_))

  let e3 = state.meta.fresh_meta_var(Star)
  let n3 = match e3 {
    EVar(name) => name
    _ => panic()
  }
  assert_true(
    run(e3, Type::arrow(Type::con("Int"), EVar(n3))) is Err(Cyclic(_)),
  )

  let e4 = state.meta.fresh_meta_var(Star)
  let n4 = match e4 {
    EVar(name) => name
    _ => panic()
  }
  state.meta.solutions.set(n4, Type::con("Bool"))
  assert_true(run(Type::con("Bool"), e4) is Ok(_))

  let app_ok_l = Type::app(Type::con("F"), Type::con("Int"))
  let app_ok_r = Type::app(Type::con("F"), Type::con("Int"))
  assert_true(run(app_ok_l, app_ok_r) is Ok(_))
  assert_true(
    run(Type::app(Type::con("F"), Type::con("Int")), Type::con("F"))
    is Err(TypeMismatch(_, _)),
  )

  let maybe_state = state_with_maybe_enum()
  let wl3 : Worklist = []
  let subst3 : Substitution = Map::new()
  assert_true(
    maybe_state.unify_types(
      Type::app(Type::con("Maybe"), Type::con("Int")),
      Type::variant([("None", Type::unit()), ("Some", Type::con("Int"))]),
      wl3,
      subst3,
    )
    is Ok(_),
  )
  assert_true(maybe_state.solve_constraints(wl3, subst3) is Ok(_))
  let wl4 : Worklist = []
  let subst4 : Substitution = Map::new()
  assert_true(
    maybe_state.unify_types(
      Type::variant([("None", Type::unit()), ("Some", Type::con("Int"))]),
      Type::app(Type::con("Maybe"), Type::con("Int")),
      wl4,
      subst4,
    )
    is Ok(_),
  )
  assert_true(maybe_state.solve_constraints(wl4, subst4) is Ok(_))

  assert_true(
    run(
      Type::arrow(Type::con("Int"), Type::con("Int")),
      Type::arrow(Type::never(), Type::con("Int")),
    )
    is Ok(_),
  )
  assert_true(
    run(
      Type::arrow(Type::con("Int"), Type::con("Int")),
      Type::arrow(Type::con("Int"), Type::con("Int")),
    )
    is Ok(_),
  )

  let f1 = Type::forall("A", Star, Type::var_type("A"))
  let f2 = Type::forall("B", Star, Type::var_type("B"))
  assert_true(run(f1, f2) is Ok(_))

  let b1 = Type::bounded_forall(
    "A",
    Star,
    [
      TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") },
      TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") },
    ],
    Type::var_type("A"),
  )
  let b2 = Type::bounded_forall(
    "B",
    Star,
    [
      TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") },
      TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") },
    ],
    Type::var_type("B"),
  )
  assert_true(run(b1, b2) is Ok(_))

  assert_true(
    run(
      Type::app(Type::var_type("F"), Type::con("Int")),
      Type::app(Type::var_type("F"), Type::con("Int")),
    )
    is Ok(_),
  )
  assert_true(
    run(
      Type::lam("A", Star, Type::var_type("A")),
      Type::lam("B", Star, Type::var_type("B")),
    )
    is Ok(_),
  )
  assert_true(
    run(
      Type::record([("x", Type::con("Int"))]),
      Type::record([("x", Type::con("Int"))]),
    )
    is Ok(_),
  )
  assert_true(
    run(
      Type::variant([("x", Type::con("Int"))]),
      Type::variant([("x", Type::con("Int"))]),
    )
    is Ok(_),
  )
  assert_true(
    run(Type::mu("X", Type::var_type("X")), Type::mu("Y", Type::var_type("Y")))
    is Ok(_),
  )
  assert_true(
    run(
      Type::tuple([Type::con("Int"), Type::con("Bool")]),
      Type::tuple([Type::con("Int"), Type::con("Bool")]),
    )
    is Ok(_),
  )
  assert_true(
    run(Type::con("Int"), Type::con("Bool")) is Err(TypeMismatch(_, _)),
  )
}

///|
test "rename sweep covers term type pattern and binding variants" {
  let state = TypeCheckerState::fresh()
  let ren = Map::from_array([
    ("u", "u2"),
    ("c", "c2"),
    ("F", "F2"),
    ("L", "L2"),
    ("Eq", "Eq2"),
    ("m", "m2"),
    ("T", "T2"),
    ("x", "x2"),
  ])

  let rich_type = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Type::tuple([
      Type::arrow(Type::var_type("T"), Type::con("F")),
      Type::app(Type::con("F"), Type::var_type("T")),
      Type::forall("B", Star, Type::var_type("B")),
      Type::lam("C", Star, Type::var_type("C")),
      Type::record([("L", Type::var_type("T"))]),
      Type::variant([("L", Type::var_type("T"))]),
      Type::mu("M", Type::var_type("M")),
      EVar("0"),
      Type::never(),
    ]),
  )

  let terms : Array[Term] = [
    Term::var_term("u"),
    Term::lam("x", rich_type, Term::var_term("x")),
    Term::app(Term::var_term("u"), Term::var_term("x")),
    Term::tylam("T", Star, Term::var_term("u")),
    Term::tyapp(Term::var_term("u"), rich_type),
    Term::con("c", rich_type),
    Term::record([("L", Term::var_term("u"))]),
    Term::project(Term::var_term("r"), "L"),
    Term::inject("L", Term::var_term("u"), Type::variant([("L", rich_type)])),
    Term::tuple([Term::var_term("u"), Term::var_term("x")]),
    Term::tuple_project(Term::var_term("t"), 1),
    Term::let_term("x", Term::var_term("u"), Term::var_term("x")),
    Term::match_term(Term::var_term("u"), [
      (
        Pattern::tuple([
          Pattern::con("c", rich_type),
          Pattern::record([
            ("L", Pattern::variant("L", Pattern::var_pattern("x"))),
          ]),
        ]),
        Term::var_term("x"),
      ),
    ]),
    Term::fold(rich_type, Term::var_term("u")),
    Term::unfold(Term::var_term("u")),
    Term::dict("Eq", rich_type, [("m", Term::var_term("u"))]),
    Term::trait_lam(
      "d",
      "Eq",
      "T",
      Star,
      [TraitConstraint::{ trait_name: "Eq", ty: rich_type }],
      Term::var_term("u"),
    ),
    Term::trait_app(Term::var_term("u"), rich_type, [Term::var_term("d")]),
    Term::trait_method(Term::var_term("d"), "m"),
  ]

  for term in terms {
    ignore(state.rename_term(term, ren))
  }

  let patterns : Array[Pattern] = [
    Pattern::var_pattern("x"),
    Pattern::con("c", rich_type),
    Pattern::record([("L", Pattern::wildcard())]),
    Pattern::variant("L", Pattern::var_pattern("u")),
    Pattern::tuple([Pattern::var_pattern("u"), Pattern::wildcard()]),
  ]
  for p in patterns {
    ignore(state.rename_pattern(p, ren, Set::new()))
  }

  let bindings : Array[Binding] = [
    Binding::term("u", rich_type),
    Binding::type_binding("T", Star),
    Binding::trait_def("Eq", "A", Star, [("m", rich_type)]),
    Binding::trait_impl(
      "Eq",
      rich_type,
      Term::dict("Eq", rich_type, [("m", Term::var_term("u"))]),
    ),
    Binding::dict("d", "Eq", rich_type),
    Binding::enum_def("E", Star, [], [("L", rich_type)], false),
    Binding::type_alias("AliasT", [], [], rich_type),
  ]
  for b in bindings {
    ignore(state.rename_binding(b, ren))
  }
}

///|
test "import_module branch sweep covers aliases dependencies and overrides" {
  let from = TypeCheckerState::fresh().extend_context([
    Binding::type_binding("T", Star),
    Binding::type_alias("AliasT", [], [], Type::con("T")),
    Binding::enum_def("E", Star, [], [("L", Type::con("AliasT"))], false),
    Binding::trait_def("Tr", "A", Star, [
      ("m", Type::arrow(Type::var_type("A"), Type::con("E"))),
    ]),
    Binding::trait_impl(
      "Impl",
      Type::con("T"),
      Term::dict("Tr", Type::con("T"), [
        ("m", Term::con("c", Type::arrow(Type::con("T"), Type::con("E")))),
      ]),
    ),
    Binding::dict("d", "Impl", Type::con("T")),
    Binding::term("v", Type::con("AliasT")),
  ])

  let into = TypeCheckerState::fresh().extend_context([
    Binding::type_binding("T", Star),
    Binding::term("v2", Type::con("T")),
    Binding::term("root", Type::con("T")),
  ])

  let aliases_partial = ImportAliases::{
    types: Some(Map::from_array([("v", "root")])),
    traits: None,
    terms: None,
    labels: None,
  }
  let imported = import_module(
    from~,
    into~,
    roots=["v", "AliasT", "E", "Tr", "missingRoot"],
    aliases=Some(aliases_partial),
    allow_overrides=true,
  )
  assert_true(imported is Ok(_))

  let duplicated = import_module(
    from~,
    into=TypeCheckerState::fresh().extend_context([
      Binding::term("v", Type::con("T")),
    ]),
    roots=["v"],
    aliases=None,
    allow_overrides=false,
  )
  assert_true(duplicated is Err(DuplicateBinding("v")))
}
