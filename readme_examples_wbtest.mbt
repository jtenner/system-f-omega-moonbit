///|
fn readme_beginner_mental_model_labels() -> Array[String] {
  ["Kind", "Type", "Term", "TypeCheckerState", "Context+MetaEnv"]
}

///|
fn readme_state_with_int_binding() -> TypeCheckerState {
  TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])
}

///|
fn readme_quickstart_borrow_shared_accepted() -> Result[Type, TypingError] {
  let state = readme_state_with_int_binding()
  state.infer_type(Term::borrow_shared(Term::var_term("x")))
}

///|
fn readme_quickstart_borrow_shared_rejected() -> Result[Type, TypingError] {
  let state = readme_state_with_int_binding()
  state.infer_type(Term::borrow_shared(Term::unit()))
}

///|
fn readme_quickstart_borrow_mut_accepted() -> Result[Type, TypingError] {
  let state = readme_state_with_int_binding()
  state.infer_type(Term::borrow_mut(Term::var_term("x")))
}

///|
fn readme_quickstart_borrow_mut_rejected() -> Result[Type, TypingError] {
  let term = Term::let_term(
    "x",
    Term::unit(),
    Term::tuple_project(
      Term::tuple([
        Term::borrow_mut(Term::var_term("x")),
        Term::borrow_shared(Term::var_term("x")),
        Term::unit(),
      ]),
      2,
    ),
  )
  TypeCheckerState::fresh().infer_type(term)
}

///|
fn readme_quickstart_deref_accepted() -> Result[Type, TypingError] {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term(
      "p",
      Type::ref_type(
        Region::named("p_region"),
        Mutability::shared(),
        Type::con("Int"),
      ),
    ),
  ])
  state.infer_type(Term::deref(Term::var_term("p")))
}

///|
fn readme_quickstart_deref_rejected() -> Result[Type, TypingError] {
  let state = readme_state_with_int_binding()
  state.infer_type(Term::deref(Term::var_term("x")))
}

///|
fn readme_state_with_ref_binding(mutability : Mutability) -> TypeCheckerState {
  TypeCheckerState::fresh().extend_context([
    Binding::term(
      "p",
      Type::ref_type(Region::named("p_region"), mutability, Type::con("Int")),
    ),
  ])
}

///|
fn readme_quickstart_assign_accepted() -> Result[Type, TypingError] {
  let state = readme_state_with_ref_binding(Mutability::mutable())
  state.infer_type(
    Term::assign(Term::var_term("p"), Term::con("one", Type::con("Int"))),
  )
}

///|
fn readme_quickstart_assign_rejected() -> Result[Type, TypingError] {
  let state = readme_state_with_ref_binding(Mutability::shared())
  state.infer_type(
    Term::assign(Term::var_term("p"), Term::con("one", Type::con("Int"))),
  )
}

///|
fn readme_quickstart_move_term_accepted() -> Result[Type, TypingError] {
  let state = readme_state_with_int_binding()
  state.infer_type(Term::move_term(Term::var_term("x")))
}

///|
fn readme_quickstart_move_term_rejected() -> Result[Type, TypingError] {
  let term = Term::let_term(
    "x",
    Term::unit(),
    Term::tuple_project(
      Term::tuple([
        Term::move_term(Term::var_term("x")),
        Term::borrow_shared(Term::var_term("x")),
        Term::unit(),
      ]),
      2,
    ),
  )
  TypeCheckerState::fresh().infer_type(term)
}

///|
fn readme_quickstart_tyapp_intrinsic_borrow_shared_example() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  TypeCheckerState::fresh().analyze_borrows(
    borrow_intrinsic_ops_term([
      Term::app(
        Term::tyapp(Term::var_term("borrow_shared"), Type::unit()),
        Term::var_term("x"),
      ),
    ]),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
}

///|
fn readme_quickstart_tyapp_intrinsic_conflict_example() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  TypeCheckerState::fresh().analyze_borrows(
    borrow_intrinsic_ops_term([
      Term::app(
        Term::tyapp(Term::var_term("borrow_mut"), Type::unit()),
        Term::var_term("x"),
      ),
      Term::app(
        Term::tyapp(Term::var_term("borrow_shared"), Type::unit()),
        Term::var_term("x"),
      ),
    ]),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
}

///|
fn readme_quickstart_tyapp_intrinsic_deref_example() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  TypeCheckerState::fresh().analyze_borrows(
    borrow_intrinsic_ops_term([
      Term::app(
        Term::tyapp(Term::var_term("deref"), Type::con("Int")),
        Term::var_term("p"),
      ),
    ]),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
}

///|
fn readme_analyze_borrow_ops(
  ops : Array[Term],
) -> Result[BorrowAnalysisResult, TypingError] {
  TypeCheckerState::fresh().analyze_borrows(
    borrow_intrinsic_ops_term(ops),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
}

///|
fn readme_borrow_error_use_after_move_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("move_value", Term::var_term("x")),
    borrow_intrinsic_unary("use_value", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_use_after_move_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("move_value", Term::var_term("x")),
    borrow_intrinsic_binary("assign_mutable", Term::var_term("x"), Term::unit()),
    borrow_intrinsic_unary("use_value", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_moved_value_borrow_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("move_value", Term::var_term("x")),
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_moved_value_borrow_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_borrow_conflict_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_mut", Term::var_term("x")),
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_borrow_conflict_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_mut", Term::var_term("x")),
    borrow_intrinsic_unary("release", Term::var_term("x")),
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_mutate_while_borrowed_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
    borrow_intrinsic_binary("assign_mutable", Term::var_term("x"), Term::unit()),
  ])
}

///|
fn readme_borrow_error_mutate_while_borrowed_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
    borrow_intrinsic_unary("release", Term::var_term("x")),
    borrow_intrinsic_binary("assign_mutable", Term::var_term("x"), Term::unit()),
  ])
}

///|
fn readme_borrow_error_assign_to_immutable_failing() -> Result[
  Type,
  TypingError,
] {
  readme_quickstart_assign_rejected()
}

///|
fn readme_borrow_error_assign_to_immutable_fix() -> Result[Type, TypingError] {
  readme_quickstart_assign_accepted()
}

///|
fn readme_borrow_error_borrow_outlives_owner_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("region_outlives_owner", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_borrow_outlives_owner_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_dangling_reference_escape_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("region_dangling_escape", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_dangling_reference_escape_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_invalid_borrow_target_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_shared", Term::unit()),
  ])
}

///|
fn readme_borrow_error_invalid_borrow_target_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
}

///|
fn readme_borrow_error_region_constraint_unsatisfied_failing() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    Term::con(
      "BorrowOpRegionUnsatisfied__named:alpha__named:omega",
      Type::unit(),
    ),
  ])
}

///|
fn readme_borrow_error_region_constraint_unsatisfied_fix() -> Result[
  BorrowAnalysisResult,
  TypingError,
] {
  readme_analyze_borrow_ops([
    Term::con("BorrowOpRegionUnsatisfied__infer:0__infer:1", Type::unit()),
  ])
}

///|
fn readme_cookbook_higher_kinded_kind_example() -> Result[
  (Kind, Kind),
  TypingError,
] {
  let s0 = TypeCheckerState::fresh()
  let s1 = match s0.add_type("Int", Star) {
    Ok(state) => state
    Err(error) => return Err(error)
  }
  let s2 = match s1.add_type("Maybe", Kind::arrow(Star, Star)) {
    Ok(state) => state
    Err(error) => return Err(error)
  }
  let constructor_kind = match s2.check_kind(Type::con("Maybe"), false) {
    Ok(kind) => kind
    Err(error) => return Err(error)
  }
  let applied_kind = match
    s2.check_kind(Type::app(Type::con("Maybe"), Type::con("Int")), false) {
    Ok(kind) => kind
    Err(error) => return Err(error)
  }
  Ok((constructor_kind, applied_kind))
}

///|
fn readme_cookbook_type_level_lambda_application_example() -> Result[
  Type,
  TypingError,
] {
  let state = state_with_primitives()
  let poly = Term::tylam(
    "A",
    Star,
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  state.infer_type(Term::tyapp(poly, Type::con("Int")))
}

///|
fn readme_cookbook_forall_and_bounded_forall_example() -> Result[
  (Type, Type),
  TypingError,
] {
  let state = state_with_eq_trait_and_int_dict()
  let forall_term = Term::tylam(
    "A",
    Star,
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )
  let bounded_term = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::lam("x", Type::var_type("A"), Term::var_term("x")),
  )

  let forall_ty = match state.infer_type(forall_term) {
    Ok(ty) => ty
    Err(error) => return Err(error)
  }
  let bounded_ty = match state.infer_type(bounded_term) {
    Ok(ty) => ty
    Err(error) => return Err(error)
  }
  Ok((forall_ty, bounded_ty))
}

///|
fn readme_cookbook_traits_dictionaries_bounded_poly_example() -> Result[
  Type,
  TypingError,
] {
  let state = state_with_eq_trait_and_int_dict()
  let int_dict = Term::dict("Eq", Type::con("Int"), [
    (
      "eq",
      Term::lam(
        "x",
        Type::con("Int"),
        Term::lam("y", Type::con("Int"), Term::con("true", Type::con("Bool"))),
      ),
    ),
  ])
  state.infer_type(Term::trait_method(int_dict, "eq"))
}

///|
fn readme_cookbook_records_variants_tuples_patterns_example() -> Result[
  (Type, Type, Type),
  TypingError,
] {
  let state = state_with_primitives()
  let record_term = Term::record([
    ("a", Term::con("one", Type::con("Int"))),
    ("b", Term::con("truth", Type::con("Bool"))),
  ])
  let tuple_term = Term::tuple([
    Term::con("one", Type::con("Int")),
    Term::con("truth", Type::con("Bool")),
  ])
  let variant_ty = Type::variant([("A", Type::unit()), ("B", Type::unit())])
  let match_term = Term::match_term(
    Term::inject("A", Term::unit(), variant_ty),
    [
      (
        Pattern::variant("A", Pattern::wildcard()),
        Term::con("one", Type::con("Int")),
      ),
      (
        Pattern::variant("B", Pattern::wildcard()),
        Term::con("two", Type::con("Int")),
      ),
    ],
  )

  let record_project_ty = match
    state.infer_type(Term::project(record_term, "b")) {
    Ok(ty) => ty
    Err(error) => return Err(error)
  }
  let tuple_project_ty = match
    state.infer_type(Term::tuple_project(tuple_term, 1)) {
    Ok(ty) => ty
    Err(error) => return Err(error)
  }
  let match_ty = match state.infer_type(match_term) {
    Ok(ty) => ty
    Err(error) => return Err(error)
  }
  Ok((record_project_ty, tuple_project_ty, match_ty))
}

///|
fn readme_cookbook_recursive_mu_fold_unfold_example() -> Result[
  (Type, Type),
  TypingError,
] {
  let state = state_with_primitives()
  let rec_ty = Type::mu(
    "X",
    Type::tuple([Type::con("Int"), Type::var_type("X")]),
  )
  let folded = Term::fold(rec_ty, Term::con("bottom", Type::never()))
  let folded_ty = match state.infer_type(folded) {
    Ok(ty) => ty
    Err(error) => return Err(error)
  }
  let unfolded_ty = match state.infer_type(Term::unfold(folded)) {
    Ok(ty) => ty
    Err(error) => return Err(error)
  }
  Ok((folded_ty, unfolded_ty))
}

///|
fn readme_context_has_term_binding(
  state : TypeCheckerState,
  name : String,
) -> Bool {
  for binding in state.ctx.0 {
    match binding {
      Term(term_binding) if term_binding.name == name => return true
      _ => ()
    }
  }
  false
}

///|
fn readme_cookbook_import_dependency_rename_example() -> Result[
  (Bool, Bool, Bool),
  TypingError,
] {
  let s0 = TypeCheckerState::fresh()
  let s1 = match s0.add_type("Int", Star) {
    Ok(state) => state
    Err(error) => return Err(error)
  }
  let from = match s1.add_builtin("value", Type::con("Int"), None) {
    Ok(state) => state
    Err(error) => return Err(error)
  }
  let deps = match from.collect_dependencies(["value"]) {
    Ok(set) => set
    Err(error) => return Err(error)
  }
  let into = TypeCheckerState::fresh()
  let imported = match
    import_module(from~, into~, roots=["value"], aliases=None) {
    Ok(state) => state
    Err(error) => return Err(error)
  }
  let renamed = from.rename_term(
    Term::lam(
      "x",
      Type::var_type("A"),
      Term::app(Term::var_term("x"), Term::var_term("free")),
    ),
    Map::from_array([("A", "B"), ("free", "free2")]),
  )

  let rename_rewrites_free_term = renamed ==
    Term::lam(
      "x",
      Type::var_type("B"),
      Term::app(Term::var_term("x"), Term::var_term("free2")),
    )
  Ok(
    (
      deps.contains("Int"),
      readme_context_has_term_binding(imported, "value"),
      rename_rewrites_free_term,
    ),
  )
}

///|
fn readme_troubleshooting_rows() -> Array[(String, String, String)] {
  [
    (
      "TypeMismatch", "Expected type and inferred type diverge (often after missing normalization).",
      "Normalize both sides and check branch return types first.",
    ),
    (
      "Unbound", "A term/type/dictionary name is missing from the current context.",
      "Confirm you added it with add_type/add_term/add_dict before inference.",
    ),
    (
      "BorrowConflict", "Overlapping mutable/shared loans exist at the same time.",
      "Release/shorten one borrow scope before taking the next borrow.",
    ),
    (
      "UseAfterMove", "A place was moved and then used again without reinitialization.",
      "Reinitialize the place (or avoid the later use) before reuse.",
    ),
    (
      "InvalidBorrowTarget", "Borrow/deref/assign was applied to a non-place expression.",
      "Use a place target like x, x.field, tuple index, or deref(p).",
    ),
    (
      "RegionConstraintUnsatisfied", "A required outlives edge is missing in the solved region graph.",
      "Inspect generated region constraints and add missing ownership edges.",
    ),
  ]
}
