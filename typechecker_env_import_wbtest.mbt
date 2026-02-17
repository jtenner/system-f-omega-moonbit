///|
fn has_binding_named(state : TypeCheckerState, name : String) -> Bool {
  for b in state.ctx.0 {
    match b {
      Term(t) if t.name == name => return true
      Type(t) if t.name == name => return true
      TraitDef(t) if t.name == name => return true
      TraitImpl(t) if t.trait_name == name => return true
      Dict(t) if t.name == name => return true
      TypeAlias(t) if t.name == name => return true
      Enum(t) if t.name == name => return true
      _ => ()
    }
  }
  false
}

///|
test "add_type and add_term reject duplicate binding names" {
  let state = state_with_primitives()
  let dup_type = state.add_type("Int", Star)
  assert_true(dup_type is Err(DuplicateBinding("Int")))

  let with_term = must_type_state(
    state.add_term("idInt", Term::con("one", Type::con("Int")), None),
  )
  let dup_term = with_term.add_term(
    "idInt",
    Term::con("two", Type::con("Int")),
    None,
  )
  assert_true(dup_term is Err(DuplicateBinding("idInt")))
}

///|
test "add_type_alias validates parameter and kind arity" {
  let state = state_with_primitives()
  let result = state.add_type_alias(
    "BadAlias",
    ["A", "B"],
    [Star],
    Type::var_type("A"),
  )
  assert_true(result is Err(Message(_)))
}

///|
test "add_enum computes effective recursive flag from actual usage" {
  let non_recursive = must_type_state(
    state_with_primitives().add_enum(
      "Box",
      ["A"],
      [Star],
      [("Wrap", Type::var_type("A"))],
      true,
    ),
  )
  let box_def = non_recursive.ctx.find_enum("Box").unwrap()
  assert_false(box_def.recursive)

  let recursive = state_with_list_enum()
  let list_def = recursive.ctx.find_enum("List").unwrap()
  assert_true(list_def.recursive)
}

///|
test "normalize_type expands aliases with and without arguments" {
  let state = state_with_primitives()
  let with_aliases = must_type_state(
    state
    .add_type_alias(
      "PairInt",
      [],
      [],
      Type::tuple([Type::con("Int"), Type::con("Int")]),
    )
    .bind(s => s.add_type_alias("Id", ["A"], [Star], Type::var_type("A"))),
  )
  let pair_norm = with_aliases.normalize_type(Type::con("PairInt"))
  assert_true(pair_norm == Type::tuple([Type::con("Int"), Type::con("Int")]))

  let id_app_norm = with_aliases.normalize_type(
    Type::app(Type::con("Id"), Type::con("Bool")),
  )
  assert_true(id_app_norm == Type::con("Bool"))
}

///|
test "normalize_type expands recursive enums to mu-variants" {
  let state = state_with_list_enum()
  let list_int = Type::app(Type::con("List"), Type::con("Int"))
  let norm = state.normalize_type(list_int)
  match norm {
    Mu(name, Variant(cases)) => {
      let labels = Set::from_array(cases.map(c => c.0))
      assert_true(labels.contains("Nil"))
      assert_true(labels.contains("Cons"))

      let mut cons_ty : Type? = None
      for c in cases {
        if c.0 == "Cons" {
          cons_ty = Some(c.1)
        }
      }
      match cons_ty {
        Some(Tuple([head, tail])) => {
          assert_true(head == Type::con("Int"))
          assert_true(tail == Type::var_type(name))
        }
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "collect_dependencies follows transitive references" {
  let state = state_with_primitives()
  let with_alias = must_type_state(
    state.add_type_alias("WrapInt", [], [], Type::con("Int")),
  )
  let with_term = must_type_state(
    with_alias.add_builtin("value", Type::con("WrapInt"), None),
  )
  let deps = with_term.collect_dependencies(["value"])
  match deps {
    Ok(found) => {
      assert_true(found.contains("value"))
      assert_true(found.contains("WrapInt"))
      assert_true(found.contains("Int"))
    }
    _ => panic()
  }
}

///|
test "collect_dependencies detects import cycles" {
  let cyclic = TypeCheckerState::fresh().extend_context([
    Binding::type_alias("A", [], [], Type::con("B")),
    Binding::type_alias("B", [], [], Type::con("A")),
  ])
  let result = cyclic.collect_dependencies(["A"])
  assert_true(result is Err(CircularImport(_, _)))
}

///|
test "import_module applies aliases and renames references" {
  let from0 = TypeCheckerState::fresh()
  let from1 = must_type_state(from0.add_type("T", Star))
  let from_state = must_type_state(from1.add_builtin("v", Type::con("T"), None))

  let aliases = ImportAliases::{
    types: Some(Map::from_array([("T", "T2")])),
    traits: None,
    terms: Some(Map::from_array([("v", "v2")])),
    labels: None,
  }

  let imported = import_module(
    from=from_state,
    into=TypeCheckerState::fresh(),
    roots=["T", "v"],
    aliases=Some(aliases),
  )
  match imported {
    Ok(state) => {
      assert_true(has_binding_named(state, "T2"))
      assert_true(has_binding_named(state, "v2"))
      let mut found_term = false
      for b in state.ctx.0 {
        if b is Term(t) && t.name == "v2" {
          found_term = true
          assert_true(t.ty == Type::con("T2"))
        }
      }
      assert_true(found_term)
    }
    _ => panic()
  }
}

///|
test "import_module reports duplicate root names without overrides" {
  let from = must_type_state(
    TypeCheckerState::fresh()
    .add_type("T", Star)
    .bind(s => s.add_builtin("v", Type::con("T"), None)),
  )
  let into = must_type_state(
    TypeCheckerState::fresh()
    .add_type("T", Star)
    .bind(s => s.add_builtin("v", Type::con("T"), None)),
  )
  let result = import_module(from~, into~, roots=["v"], aliases=None)
  assert_true(result is Err(DuplicateBinding("v")))
}

///|
test "rename_type renames free symbols but preserves bound vars" {
  let state = TypeCheckerState::fresh()
  let ty = Type::forall(
    "A",
    Star,
    Type::record([("left", Type::var_type("A")), ("right", Type::con("Old"))]),
  )
  let ren = Map::from_array([("A", "Z"), ("Old", "New"), ("left", "L")])
  let renamed = state.rename_type(ty, ren)
  let expected = Type::forall(
    "A",
    Star,
    Type::record([("L", Type::var_type("A")), ("right", Type::con("New"))]),
  )
  assert_true(renamed == expected)
}

///|
test "rename_term respects bound names and rewrites free references" {
  let state = TypeCheckerState::fresh()
  let term = Term::lam(
    "x",
    Type::var_type("A"),
    Term::app(Term::var_term("x"), Term::var_term("free")),
  )
  let ren = Map::from_array([("x", "y"), ("A", "B"), ("free", "free2")])
  let renamed = state.rename_term(term, ren)
  let expected = Term::lam(
    "x",
    Type::var_type("B"),
    Term::app(Term::var_term("x"), Term::var_term("free2")),
  )
  assert_true(renamed == expected)
}

///|
test "rename_pattern updates variables and labels" {
  let state = TypeCheckerState::fresh()
  let pattern = Pattern::record([
    ("old", Pattern::variant("Tag", Pattern::var_pattern("v"))),
  ])
  let ren = Map::from_array([("old", "new"), ("Tag", "Tag2"), ("v", "v2")])
  let renamed = state.rename_pattern(pattern, ren, Set::new())
  let expected = Pattern::record([
    ("new", Pattern::variant("Tag2", Pattern::var_pattern("v2"))),
  ])
  assert_true(renamed == expected)
}

///|
test "rename_binding rewrites type aliases and term names" {
  let state = TypeCheckerState::fresh()
  let binding = Binding::type_alias(
    "OldAlias",
    [],
    [],
    Type::record([("l", Type::con("Old"))]),
  )
  let ren = Map::from_array([
    ("OldAlias", "NewAlias"),
    ("Old", "New"),
    ("l", "L"),
  ])
  let renamed = state.rename_binding(binding, ren)
  match renamed {
    TypeAlias(al) => {
      assert_true(al.name == "NewAlias")
      assert_true(al.body == Type::record([("L", Type::con("New"))]))
    }
    _ => panic()
  }
}

///|
test "compute_free_types tracks vars constructors traits and labels" {
  let state = TypeCheckerState::fresh()
  let ty = Type::bounded_forall(
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Type::record([
      ("field", Type::arrow(Type::var_type("A"), Type::con("Box"))),
      ("free", Type::var_type("B")),
    ]),
  )
  let free = state.compute_free_types(ty)
  assert_true(free.type_vars.contains("B"))
  assert_true(free.type_cons.contains("Box"))
  assert_true(free.traits.contains("Eq"))
  assert_true(free.labels.contains("field"))
  assert_true(free.labels.contains("free"))
}

///|
test "compute_free_patterns and compute_free_terms gather identifiers" {
  let state = TypeCheckerState::fresh()
  let pattern = Pattern::record([
    ("label", Pattern::variant("Tag", Pattern::var_pattern("x"))),
  ])
  let pfree = state.compute_free_patterns(pattern)
  assert_true(pfree.vars.contains("x"))
  assert_true(pfree.labels.contains("label"))
  assert_true(pfree.labels.contains("Tag"))

  let term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::record([("out", Term::var_term("free"))]),
  )
  let tfree = state.compute_free_terms(term)
  assert_true(tfree.terms.contains("free"))
  assert_true(tfree.traits.contains("Eq"))
  assert_true(tfree.labels.contains("out"))
}

///|
test "context finders and extend_context expose added bindings" {
  let base = TypeCheckerState::fresh()
  let extended = base.extend_context([
    Binding::type_binding("T", Star),
    Binding::enum_def("E", Star, [], [("Case", Type::unit())], false),
    Binding::type_alias("AliasT", [], [], Type::con("T")),
  ])
  assert_true(extended.ctx.find_type_binding("T") is Some(_))
  assert_true(extended.ctx.find_enum("E") is Some(_))
  assert_true(extended.ctx.find_type_alias("AliasT") is Some(_))
  assert_true(extended.ctx.find_enum_by_variant_label("Case") is Some(_))
}
