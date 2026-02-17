///|
test "types_equal covers structural forms and failure paths" {
  let state = TypeCheckerState::fresh()

  let app1 = Type::app(
    Type::app(Type::con("F"), Type::con("A")),
    Type::con("B"),
  )
  let app2 = Type::app(
    Type::app(Type::con("F"), Type::con("A")),
    Type::con("B"),
  )
  let app3 = Type::app(
    Type::app(Type::con("F"), Type::con("A")),
    Type::con("C"),
  )
  assert_true(state.types_equal(app1, app2))
  assert_false(state.types_equal(app1, app3))

  let forall1 = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("A")),
  )
  let forall2 = Type::forall(
    "B",
    Star,
    Type::arrow(Type::var_type("B"), Type::var_type("B")),
  )
  let forall_bad = Type::forall(
    "B",
    Kind::arrow(Star, Star),
    Type::arrow(Type::var_type("B"), Type::var_type("B")),
  )
  assert_true(state.types_equal(forall1, forall2))
  assert_false(state.types_equal(forall1, forall_bad))

  let lam1 = Type::lam("A", Star, Type::var_type("A"))
  let lam2 = Type::lam("B", Star, Type::var_type("B"))
  let lam_bad = Type::lam("B", Kind::arrow(Star, Star), Type::var_type("B"))
  assert_true(state.types_equal(lam1, lam2))
  assert_false(state.types_equal(lam1, lam_bad))

  assert_true(
    state.types_equal(
      Type::app(Type::var_type("X"), Type::con("Int")),
      Type::app(Type::var_type("X"), Type::con("Int")),
    ),
  )

  assert_true(
    state.types_equal(
      Type::record([("a", Type::con("Int")), ("b", Type::con("Bool"))]),
      Type::record([("b", Type::con("Bool")), ("a", Type::con("Int"))]),
    ),
  )
  assert_false(
    state.types_equal(
      Type::record([("a", Type::con("Int"))]),
      Type::record([("a", Type::con("Int")), ("b", Type::con("Bool"))]),
    ),
  )

  let bf1 = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Type::var_type("A"),
  )
  let bf2 = Type::bounded_forall(
    "B",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("B") }],
    Type::var_type("B"),
  )
  let bf_bad = Type::bounded_forall(
    "B",
    Star,
    [TraitConstraint::{ trait_name: "Show", ty: Type::var_type("B") }],
    Type::var_type("B"),
  )
  assert_true(state.types_equal(bf1, bf2))
  assert_false(state.types_equal(bf1, bf_bad))

  assert_true(
    state.types_equal(
      Type::variant([("L", Type::con("Int")), ("R", Type::con("Bool"))]),
      Type::variant([("R", Type::con("Bool")), ("L", Type::con("Int"))]),
    ),
  )
  assert_false(
    state.types_equal(
      Type::variant([("L", Type::con("Int"))]),
      Type::variant([("R", Type::con("Int"))]),
    ),
  )

  let mu1 = Type::mu("X", Type::variant([("In", Type::var_type("X"))]))
  let mu2 = Type::mu("Y", Type::variant([("In", Type::var_type("Y"))]))
  assert_true(state.types_equal(mu1, mu2))

  assert_true(
    state.types_equal(
      Type::tuple([Type::con("Int"), Type::con("Bool")]),
      Type::tuple([Type::con("Int"), Type::con("Bool")]),
    ),
  )
  assert_false(
    state.types_equal(
      Type::tuple([Type::con("Int")]),
      Type::tuple([Type::con("Int"), Type::con("Bool")]),
    ),
  )
}

///|
test "infer_type_with_mode check branch returns errors from check_type" {
  let state = state_with_primitives()
  let term = Term::con("truth", Type::con("Bool"))
  let result = state.infer_type_with_mode(
    term,
    InferMode::check(Type::con("Int")),
  )
  assert_true(result is Err(TypeMismatch(_, _)))
}

///|
test "occurs_check_evar covers all major type constructors" {
  let state = TypeCheckerState::fresh()
  let fv = state.meta.fresh_meta_var(Star)
  let name = match fv {
    EVar(n) => n
    _ => panic()
  }

  let samples : Array[Type] = [
    Type::var_type("A"),
    Type::arrow(Type::con("Int"), Type::con("Bool")),
    Type::app(Type::con("F"), Type::con("Int")),
    Type::forall("A", Star, Type::var_type("A")),
    Type::bounded_forall(
      "A",
      Star,
      [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
      Type::var_type("A"),
    ),
    Type::record([("x", Type::con("Int"))]),
    Type::variant([("Some", Type::con("Int"))]),
    Type::tuple([Type::con("Int"), Type::con("Bool")]),
    Type::mu("X", Type::var_type("X")),
    Type::never(),
    Type::con("Int"),
    Type::lam("A", Star, Type::var_type("A")),
  ]

  for ty in samples {
    ignore(state.meta.occurs_check_evar(name, ty))
  }
}

///|
test "apply_substitution_to_term visits all term constructors" {
  let state = TypeCheckerState::fresh()
  let subst = Map::from_array([
    ("X", Type::con("Int")),
    ("Y", Type::con("Bool")),
  ])

  let terms : Array[Term] = [
    Term::var_term("v"),
    Term::lam("x", Type::var_type("X"), Term::var_term("x")),
    Term::app(Term::var_term("f"), Term::var_term("x")),
    Term::tylam("X", Star, Term::con("id", Type::var_type("X"))),
    Term::tyapp(Term::var_term("poly"), Type::var_type("X")),
    Term::con("c", Type::var_type("X")),
    Term::dict("Eq", Type::var_type("X"), [
      ("eq", Term::lam("x", Type::var_type("X"), Term::var_term("x"))),
    ]),
    Term::trait_lam(
      "d",
      "Eq",
      "X",
      Star,
      [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("X") }],
      Term::var_term("d"),
    ),
    Term::trait_app(Term::var_term("tf"), Type::var_type("X"), [
      Term::var_term("d"),
    ]),
    Term::trait_method(Term::var_term("d"), "eq"),
    Term::let_term("x", Term::var_term("v"), Term::var_term("x")),
    Term::match_term(Term::var_term("m"), [
      (Pattern::wildcard(), Term::var_term("m")),
    ]),
    Term::record([("x", Term::var_term("v"))]),
    Term::project(Term::var_term("r"), "x"),
    Term::inject(
      "Some",
      Term::var_term("v"),
      Type::variant([("Some", Type::var_type("X"))]),
    ),
    Term::tuple([Term::var_term("a"), Term::var_term("b")]),
    Term::tuple_project(Term::var_term("t"), 0),
    Term::fold(Type::var_type("X"), Term::var_term("v")),
    Term::unfold(Term::var_term("u")),
  ]

  for term in terms {
    ignore(state.apply_substitution_to_term(subst, term, Set::new()))
  }
}

///|
test "instantiate_term visits all specialized constructor branches" {
  let state = TypeCheckerState::fresh()
  let terms : Array[Term] = [
    Term::tylam("A", Star, Term::con("k", Type::var_type("A"))),
    Term::app(Term::var_term("f"), Term::var_term("x")),
    Term::lam(
      "x",
      Type::forall("A", Star, Type::var_type("A")),
      Term::var_term("x"),
    ),
    Term::tyapp(
      Term::var_term("f"),
      Type::forall("A", Star, Type::var_type("A")),
    ),
    Term::match_term(Term::var_term("m"), [
      (Pattern::wildcard(), Term::var_term("m")),
    ]),
    Term::inject(
      "Some",
      Term::var_term("v"),
      Type::forall("A", Star, Type::var_type("A")),
    ),
    Term::dict("Eq", Type::forall("A", Star, Type::var_type("A")), [
      ("eq", Term::tylam("A", Star, Term::var_term("x"))),
    ]),
    Term::trait_lam(
      "d",
      "Eq",
      "A",
      Star,
      [
        TraitConstraint::{
          trait_name: "Eq",
          ty: Type::forall("A", Star, Type::var_type("A")),
        },
      ],
      Term::var_term("d"),
    ),
    Term::record([("x", Term::var_term("v"))]),
    Term::let_term("x", Term::var_term("v"), Term::var_term("x")),
    Term::tuple([Term::var_term("a"), Term::var_term("b")]),
  ]

  for term in terms {
    ignore(state.instantiate_term(term))
  }
}

///|
test "compute_free_terms traverses match dict trait and recursive term forms" {
  let state = TypeCheckerState::fresh()
  let term = Term::let_term(
    "x",
    Term::dict("Eq", Type::var_type("T"), [
      (
        "eq",
        Term::trait_lam(
          "d",
          "Eq",
          "A",
          Star,
          [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
          Term::match_term(
            Term::inject(
              "Some",
              Term::var_term("x"),
              Type::variant([("Some", Type::var_type("A"))]),
            ),
            [
              (
                Pattern::variant("Some", Pattern::var_pattern("y")),
                Term::trait_method(
                  Term::trait_app(Term::var_term("f"), Type::var_type("A"), [
                    Term::var_term("d"),
                  ]),
                  "eq",
                ),
              ),
            ],
          ),
        ),
      ),
    ]),
    Term::tuple_project(
      Term::tuple([
        Term::fold(Type::mu("X", Type::var_type("X")), Term::var_term("x")),
        Term::unfold(Term::var_term("u")),
      ]),
      1,
    ),
  )

  let free = state.compute_free_terms(term)
  assert_true(free.traits.contains("Eq"))
  assert_true(free.labels.contains("Some"))
}

///|
test "import_module handles automatic renaming and override updates" {
  let from = TypeCheckerState::fresh().extend_context([
    Binding::type_binding("T", Star),
    Binding::term("id", Type::arrow(Type::con("T"), Type::con("T"))),
  ])
  let into = TypeCheckerState::fresh().extend_context([
    Binding::type_binding("T", Star),
    Binding::term("id2", Type::con("T")),
  ])

  let imported = import_module(from~, into~, roots=["id"], aliases=None)
  match imported {
    Ok(state) => {
      let mut has_renamed_t = false
      let mut has_id = false
      for b in state.ctx.0 {
        if b is Type(t) && t.name != "T" {
          has_renamed_t = true
        }
        if b is Term(t) && t.name == "id" {
          has_id = true
        }
      }
      assert_true(has_renamed_t)
      assert_true(has_id)
    }
    _ => panic()
  }

  let from2 = TypeCheckerState::fresh().extend_context([
    Binding::type_binding("T", Star),
    Binding::trait_def("Eq", "A", Star, [
      (
        "eq",
        Type::arrow(
          Type::var_type("A"),
          Type::arrow(Type::var_type("A"), Type::con("Bool")),
        ),
      ),
    ]),
    Binding::term("id", Type::arrow(Type::con("T"), Type::con("T"))),
  ])
  let into2 = TypeCheckerState::fresh().extend_context([
    Binding::term("idRenamed", Type::con("T")),
  ])
  let aliases = ImportAliases::{
    types: Some(Map::from_array([("T", "TNew")])),
    traits: Some(Map::from_array([("Eq", "EqNew")])),
    terms: Some(Map::from_array([("id", "idRenamed")])),
    labels: Some(Map::from_array([("eq", "eq2")])),
  }
  let overridden = import_module(
    from=from2,
    into=into2,
    roots=["id", "Eq", "T"],
    aliases=Some(aliases),
    allow_overrides=true,
  )
  assert_true(overridden is Ok(_))
}

///|
test "collect_dependencies handles missing roots and all binding variants" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::type_binding("T", Star),
    Binding::type_alias("AliasT", [], [], Type::con("T")),
    Binding::enum_def("E", Star, [], [("C", Type::con("AliasT"))], false),
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

  let missing = state.collect_dependencies(["missingRoot"])
  match missing {
    Ok(set) => assert_eq(set.length(), 0)
    _ => panic()
  }

  let deps = state.collect_dependencies(["Impl"])
  assert_true(deps is Err(CircularImport(_, _)))

  let dict_root = state.collect_dependencies(["d"])
  assert_true(dict_root is Err(CircularImport(_, _)))
}

///|
test "add API helpers succeed across mixed pre-existing binding kinds" {
  let base = TypeCheckerState::fresh().extend_context([
    Binding::type_binding("BaseT", Star),
    Binding::trait_def("BaseTr", "A", Star, [
      ("m", Type::arrow(Type::var_type("A"), Type::con("BaseT"))),
    ]),
    Binding::type_alias("BaseAlias", [], [], Type::con("BaseT")),
    Binding::enum_def("BaseE", Star, [], [("BC", Type::unit())], false),
    Binding::dict("baseDict", "BaseTr", Type::con("BaseT")),
  ])

  let s1 = must_type_state(
    base.add_term(
      "newTerm",
      Term::con("u", Type::con("BaseT")),
      Some(Type::con("BaseT")),
    ),
  )
  let s2 = must_type_state(
    s1.add_builtin("newBuiltin", Type::con("BaseT"), None),
  )
  let s3 = must_type_state(s2.add_type("NewType", Star))
  let s4 = must_type_state(
    s3.add_type_alias("NewAlias", [], [], Type::con("BaseT")),
  )
  let s5 = must_type_state(
    s4.add_enum("NewEnum", [], [], [("N", Type::con("BaseT"))], false),
  )
  let s6 = must_type_state(
    s5.add_trait_def("NewTrait", "X", Star, [
      ("id", Type::arrow(Type::var_type("X"), Type::var_type("X"))),
    ]),
  )
  let dict = Term::dict("NewTrait", Type::con("BaseT"), [
    ("id", Term::lam("x", Type::con("BaseT"), Term::var_term("x"))),
  ])
  let s7 = must_type_state(s6.add_dict("newDict", dict))
  assert_true(s7.ctx.find_type_binding("NewType") is Some(_))
}

///|
test "show implementations are callable for type term and pattern" {
  ignore(Type::con("Int").to_string())
  ignore(Term::var_term("x").to_string())
  ignore(Pattern::wildcard().to_string())
}
