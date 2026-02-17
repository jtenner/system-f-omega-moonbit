///|
fn must_type_state(
  result : Result[TypeCheckerState, TypingError],
) -> TypeCheckerState {
  match result {
    Ok(state) => state
    Err(_) => panic()
  }
}

///|
fn must_type(result : Result[Type, TypingError]) -> Type {
  match result {
    Ok(ty) => ty
    Err(_) => panic()
  }
}

///|
fn must_kind(result : Result[Kind, TypingError]) -> Kind {
  match result {
    Ok(kind) => kind
    Err(_) => panic()
  }
}

///|
fn must_checked(result : Result[CheckedType, TypingError]) -> CheckedType {
  match result {
    Ok(checked) => checked
    Err(_) => panic()
  }
}

///|
fn state_with_primitives() -> TypeCheckerState {
  let s0 = TypeCheckerState::fresh()
  let s1 = must_type_state(s0.add_type("Int", Star))
  let s2 = must_type_state(s1.add_type("Bool", Star))
  let s3 = must_type_state(s2.add_type("String", Star))
  must_type_state(s3.add_type("Unit", Star))
}

///|
fn state_with_maybe_enum() -> TypeCheckerState {
  let base = state_with_primitives()
  must_type_state(
    base.add_enum(
      "Maybe",
      ["A"],
      [Star],
      [("None", Type::unit()), ("Some", Var("A"))],
      false,
    ),
  )
}

///|
fn state_with_list_enum() -> TypeCheckerState {
  let base = state_with_primitives()
  must_type_state(
    base.add_enum(
      "List",
      ["A"],
      [Star],
      [
        ("Nil", Type::unit()),
        ("Cons", Type::tuple([Var("A"), Type::app(Con("List"), Var("A"))])),
      ],
      true,
    ),
  )
}

///|
fn state_with_eq_trait_and_int_dict() -> TypeCheckerState {
  let base = state_with_primitives()
  let with_trait = must_type_state(
    base.add_trait_def("Eq", "T", Star, [
      ("eq", Type::arrow(Var("T"), Type::arrow(Var("T"), Con("Bool")))),
    ]),
  )
  let int_dict = Term::dict("Eq", Con("Int"), [
    (
      "eq",
      Term::lam(
        "x",
        Con("Int"),
        Term::lam("y", Con("Int"), Term::con("true", Con("Bool"))),
      ),
    ),
  ])
  let with_impl = must_type_state(
    with_trait.add_trait_impl("Eq", Con("Int"), int_dict),
  )
  must_type_state(with_impl.add_dict("eqInt", int_dict))
}
