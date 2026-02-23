///|
fn has_outlives_edge(
  solution : RegionSolution,
  left : Region,
  right : Region,
) -> Bool {
  for entry in solution.outlives {
    let (from, tos) = entry
    if from == left && tos.contains(right) {
      return true
    }
  }
  false
}

///|
fn collect_constructor_names_into(term : Term, names : Array[String]) -> Unit {
  match term {
    Var(_) => ()
    Con(name, _) => names.push(name)
    Lam(_, _, body) => collect_constructor_names_into(body, names)
    App(callee, arg) => {
      collect_constructor_names_into(callee, names)
      collect_constructor_names_into(arg, names)
    }
    BorrowShared(target) => collect_constructor_names_into(target, names)
    BorrowMut(target) => collect_constructor_names_into(target, names)
    Deref(inner) => collect_constructor_names_into(inner, names)
    Assign(target, value) => {
      collect_constructor_names_into(target, names)
      collect_constructor_names_into(value, names)
    }
    Move(inner) => collect_constructor_names_into(inner, names)
    Let(_, value, body) => {
      collect_constructor_names_into(value, names)
      collect_constructor_names_into(body, names)
    }
    TyLam(_, _, body) => collect_constructor_names_into(body, names)
    TyApp(value, _) => collect_constructor_names_into(value, names)
    Dict(_, _, methods) =>
      for method_entry in methods {
        let (_, method_term) = method_entry
        collect_constructor_names_into(method_term, names)
      }
    TraitLam(_, _, _, _, _, body) => collect_constructor_names_into(body, names)
    TraitApp(value, _, dicts) => {
      collect_constructor_names_into(value, names)
      for dict_term in dicts {
        collect_constructor_names_into(dict_term, names)
      }
    }
    TraitMethod(dict_term, _) =>
      collect_constructor_names_into(dict_term, names)
    Record(fields) =>
      for field in fields {
        let (_, field_term) = field
        collect_constructor_names_into(field_term, names)
      }
    Project(record_term, _) =>
      collect_constructor_names_into(record_term, names)
    Inject(_, value_term, _) =>
      collect_constructor_names_into(value_term, names)
    Match(scrutinee, cases) => {
      collect_constructor_names_into(scrutinee, names)
      for case in cases {
        let (_, body_term) = case
        collect_constructor_names_into(body_term, names)
      }
    }
    Fold(_, inner) => collect_constructor_names_into(inner, names)
    Unfold(inner) => collect_constructor_names_into(inner, names)
    Tuple(elements) =>
      for element in elements {
        collect_constructor_names_into(element, names)
      }
    TupleProject(tuple_term, _) =>
      collect_constructor_names_into(tuple_term, names)
  }
}

///|
fn collect_constructor_names(term : Term) -> Array[String] {
  let names : Array[String] = []
  collect_constructor_names_into(term, names)
  names
}

///|
fn builder_sample_cases() -> Array[(String, String)] {
  [
    ("safe_shared_read_01", "Ok"),
    ("safe_mut_reborrow_01", "Ok"),
    ("safe_nll_last_use_01", "Ok"),
    ("safe_branch_join_01", "Ok"),
    ("safe_trait_poly_01", "Ok"),
    ("safe_recursive_projection_01", "Ok"),
    ("err_borrow_conflict_01", "BorrowConflict"),
    ("err_use_after_move_01", "UseAfterMove"),
    ("err_moved_value_borrow_01", "MovedValueBorrow"),
    ("err_assign_to_immutable_01", "AssignToImmutable"),
    ("err_mutate_while_borrowed_01", "MutateWhileBorrowed"),
    ("err_outlives_owner_01", "BorrowOutlivesOwner"),
    ("err_dangling_escape_01", "DanglingReferenceEscape"),
    ("err_region_unsatisfied_01", "RegionConstraintUnsatisfied"),
    ("err_invalid_target_01", "InvalidBorrowTarget"),
    ("err_trait_escape_01", "DanglingReferenceEscape"),
    ("err_partial_move_projection_01", "UseAfterMove"),
  ]
}

///|
fn borrow_ops_term(op_names : Array[String]) -> Term {
  let ops : Array[Term] = []
  for name in op_names {
    ops.push(Term::con(name, Type::unit()))
  }
  ops.push(Term::unit())
  Term::tuple_project(Term::tuple(ops), ops.length() - 1)
}

///|
fn borrow_intrinsic_ops_term(ops : Array[Term]) -> Term {
  let seq : Array[Term] = []
  for op in ops {
    seq.push(op)
  }
  seq.push(Term::unit())
  Term::tuple_project(Term::tuple(seq), seq.length() - 1)
}

///|
fn borrow_intrinsic_unary(name : String, target : Term) -> Term {
  Term::app(Term::var_term(name), target)
}

///|
fn borrow_intrinsic_binary(name : String, left : Term, right : Term) -> Term {
  Term::app(Term::app(Term::var_term(name), left), right)
}

///|
test "RED: lower_to_borrow_ir should succeed for pure unit terms" {
  let result = lower_to_borrow_ir(Term::unit())
  assert_true(result is Ok(_))
}

///|
test "RED: lower_to_borrow_ir should produce at least one node for let terms" {
  let term = Term::let_term("x", Term::unit(), Term::var_term("x"))
  let result = lower_to_borrow_ir(term)
  assert_true(result is Ok(_))
  match result {
    Ok(ir) => assert_true(ir.nodes.length() > 0)
    _ => ()
  }
}

///|
test "RED: collect_region_constraints_from_ir should accept empty IR" {
  let result = collect_region_constraints_from_ir(BorrowIr::{ nodes: [] })
  assert_true(result is Ok(_))
}

///|
test "RED: collect_region_constraints should accept pure terms" {
  let state = TypeCheckerState::fresh()
  let result = state.collect_region_constraints(Term::unit(), Type::unit())
  assert_true(result is Ok(_))
}

///|
test "RED: solve_region_constraints should solve basic outlives edges" {
  let result = solve_region_constraints_placeholder([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
  ])
  assert_true(result is Ok(_))
  match result {
    Ok(solution) =>
      assert_true(
        has_outlives_edge(solution, Region::named("a"), Region::named("b")),
      )
    _ => ()
  }
}

///|
test "RED: solve_region_constraints should compute transitive outlives" {
  let result = solve_region_constraints_placeholder([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
    RegionConstraint::outlives(Region::named("b"), Region::named("c")),
  ])
  assert_true(result is Ok(_))
  match result {
    Ok(solution) =>
      assert_true(
        has_outlives_edge(solution, Region::named("a"), Region::named("c")),
      )
    _ => ()
  }
}

///|
test "RED: check_borrow_rules should accept pure unit terms" {
  let state = TypeCheckerState::fresh()
  let result = state.check_borrow_rules(
    Term::unit(),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: check_borrow_rules should accept simple let terms" {
  let state = TypeCheckerState::fresh()
  let term = Term::let_term("x", Term::unit(), Term::var_term("x"))
  let result = state.check_borrow_rules(
    term,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: analyze_borrows should accept pure unit terms" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: analyze_borrows should remain ok across options for pure terms" {
  let state = TypeCheckerState::fresh()
  let opts = BorrowCheckerOptions::{
    enabled: true,
    use_nll: true,
    diagnostics: false,
  }
  let result = state.analyze_borrows(Term::unit(), Type::unit(), opts)
  assert_true(result is Ok(_))
}

///|
test "RED: infer wrapper should match legacy inference for pure terms when enabled" {
  let state = TypeCheckerState::fresh()
  let legacy = state.infer_type(Term::unit())
  let with_borrow = state.infer_type_with_borrow_analysis(
    Term::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(legacy is Ok(_))
  assert_true(with_borrow is Ok(_))
  match (legacy, with_borrow) {
    (Ok(a), Ok(b)) => assert_true(a == b)
    _ => ()
  }
}

///|
test "RED: check wrapper should match legacy checking for pure terms when enabled" {
  let state = TypeCheckerState::fresh()
  let legacy = state.check_type(Term::unit(), Type::unit())
  let with_borrow = state.check_type_with_borrow_analysis(
    Term::unit(),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(legacy is Ok(_))
  assert_true(with_borrow is Ok(_))
  match (legacy, with_borrow) {
    (Ok(a), Ok(b)) => assert_true(a.ty == b.ty)
    _ => ()
  }
}

///|
test "RED: synthetic probe tags should not trigger feature errors" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    borrow_probe_term("__err_use_after_move"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: invalid-borrow-target probe should behave like ordinary constructor" {
  let state = TypeCheckerState::fresh()
  let result = state.infer_type_with_borrow_analysis(
    borrow_probe_term("__err_invalid_borrow_target"),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: feature term builders should avoid legacy __feature constructor tags" {
  for c in builder_sample_cases() {
    let (tag, _) = c
    let names = collect_constructor_names(borrow_feature_term(tag))
    for name in names {
      assert_false(name.contains("__feature_"))
      assert_false(name.contains("BorrowFeature"))
    }
  }
}

///|
test "RED: feature term builders should use generalized path-based BorrowOp names" {
  for c in builder_sample_cases() {
    let (tag, _) = c
    let names = collect_constructor_names(borrow_feature_term(tag))
    for name in names {
      if name.contains("BorrowOpBorrow") ||
        name.contains("BorrowOpMove") ||
        name.contains("BorrowOpUse") ||
        name.contains("BorrowOpAssign") ||
        name.contains("BorrowOpRelease") {
        assert_true(name.contains("__"))
      }
    }
  }
}

///|
test "RED: legacy BorrowFeature markers should be treated as ordinary constructors" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    Term::con("BorrowFeatureErrUseAfterMove", Type::unit()),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: semantic borrow ops should report root-vs-field borrow conflicts" {
  let state = TypeCheckerState::fresh()
  let term = borrow_ops_term([
    "BorrowOpBorrowMut__x", "BorrowOpBorrowShared__x__field:field",
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "BorrowConflict",
  )
}

///|
test "RED: semantic borrow ops should report use-after-move for partial projections" {
  let state = TypeCheckerState::fresh()
  let term = borrow_ops_term(["BorrowOpMove__x__field:field", "BorrowOpUse__x"])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "UseAfterMove")
}

///|
test "RED: fixed BorrowOp X/Y constructor tags should be treated as ordinary constructors" {
  let state = TypeCheckerState::fresh()
  let term = borrow_ops_term([
    "BorrowOpBorrowMutX", "BorrowOpBorrowSharedXField",
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: semantic region ops should report dangling escape errors" {
  let state = TypeCheckerState::fresh()
  let term = borrow_ops_term(["BorrowOpRegionDanglingEscape__x"])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "DanglingReferenceEscape",
  )
}

///|
test "RED: fixed region/invalid constructor probe tags should be ordinary constructors" {
  let state = TypeCheckerState::fresh()
  let term = borrow_ops_term([
    "BorrowOpRegionOutlivesOwner", "BorrowOpRegionDanglingEscape", "BorrowOpRegionUnsatisfied",
    "BorrowOpInvalidTarget",
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: generalized BorrowOp paths should parse field+deref projections for conflict checks" {
  let state = TypeCheckerState::fresh()
  let term = borrow_ops_term([
    "BorrowOpBorrowMut__z__field:left__deref", "BorrowOpBorrowShared__z",
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "BorrowConflict",
  )
}

///|
test "RED: generalized BorrowOp paths should parse tuple projections for move/use checks" {
  let state = TypeCheckerState::fresh()
  let term = borrow_ops_term([
    "BorrowOpMove__q__field:a__tuple:1", "BorrowOpUse__q",
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "UseAfterMove")
}

///|
test "RED: intrinsic AST borrow ops should report root-vs-field conflicts" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary("borrow_mut", Term::var_term("x")),
    borrow_intrinsic_unary(
      "borrow_shared",
      Term::project(Term::var_term("x"), "field"),
    ),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "BorrowConflict",
  )
}

///|
test "RED: intrinsic AST move/use ops should report projection overlap use-after-move" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary(
      "move_value",
      Term::tuple_project(Term::var_term("x"), 0),
    ),
    borrow_intrinsic_unary("use_value", Term::var_term("x")),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "UseAfterMove")
}

///|
test "RED: intrinsic AST borrow ops should reject non-place targets" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary("borrow_shared", Term::unit()),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "InvalidBorrowTarget",
  )
}

///|
test "RED: intrinsic AST region ops should report dangling escape" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    Term::var_term("region_dangling_escape"),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "DanglingReferenceEscape",
  )
}

///|
test "RED: intrinsic alias names should report use-after-move for tuple projections" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary("move", Term::tuple_project(Term::var_term("x"), 0)),
    borrow_intrinsic_unary("use", Term::var_term("x")),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "UseAfterMove")
}

///|
test "RED: intrinsic curried borrow form should reject non-place targets" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_binary("borrow_shared", Term::unit(), Term::unit()),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "InvalidBorrowTarget",
  )
}

///|
test "RED: intrinsic curried unary forms should be rejected even with valid first argument places" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_binary("borrow_shared", Term::var_term("x"), Term::unit()),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "InvalidBorrowTarget",
  )
}

///|
test "RED: tuple-index projection overlaps root for borrow conflicts" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary(
      "borrow_mut",
      Term::tuple_project(Term::var_term("x"), 0),
    ),
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "BorrowConflict",
  )
}

///|
test "RED: deref projection overlaps root for borrow conflicts" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary(
      "borrow_mut",
      Term::app(Term::var_term("deref"), Term::var_term("x")),
    ),
    borrow_intrinsic_unary("borrow_shared", Term::var_term("x")),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "BorrowConflict",
  )
}

///|
test "RED: mixed scenarios should prefer first borrow-rule violation by operation order" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary("borrow_mut", Term::var_term("x")),
    borrow_intrinsic_unary(
      "borrow_shared",
      Term::project(Term::var_term("x"), "field"),
    ),
    borrow_intrinsic_unary("move", Term::var_term("x")),
    borrow_intrinsic_unary("use", Term::var_term("x")),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "BorrowConflict",
  )
}

///|
test "RED: mixed scenarios should prefer solver-stage region errors before borrow-rule conflicts" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    Term::var_term("region_unsatisfied"),
    borrow_intrinsic_unary("borrow_mut", Term::var_term("x")),
    borrow_intrinsic_unary(
      "borrow_shared",
      Term::project(Term::var_term("x"), "field"),
    ),
  ])
  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(RegionConstraintUnsatisfied(_)))
  match result {
    Err(RegionConstraintUnsatisfied(constraint)) =>
      assert_true(
        constraint ==
        RegionConstraint::outlives(
          Region::named("region_probe::left"),
          Region::named("region_probe::right"),
        ),
      )
    _ => panic()
  }
}

///|
test "RED: feature term builders should map representative categories to expected analysis kinds" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in builder_sample_cases() {
    let (tag, expected) = c
    let kind = typing_error_kind_from_analysis_result(
      state.analyze_borrows(borrow_feature_term(tag), Type::unit(), options),
    )
    assert_true(kind == expected)
  }
}
