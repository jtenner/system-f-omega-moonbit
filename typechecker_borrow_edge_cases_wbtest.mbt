///|
fn ir_with_two_nodes(first : Term, second : Term) -> BorrowIr {
  BorrowIr::{
    nodes: [
      BorrowIrNode::{ id: 0, term: first, scope_depth: 0 },
      BorrowIrNode::{ id: 1, term: second, scope_depth: 1 },
    ],
  }
}

///|
test "lower_to_borrow_ir returns Message for non-con probe terms" {
  let term = Term::lam("x", Type::unit(), Term::var_term("x"))
  let result = lower_to_borrow_ir(term)
  assert_true(typing_error_kind_from_ir_result(result) == "Message")
}

///|
test "collect_region_constraints propagates invalid-borrow-target lowering errors" {
  let state = TypeCheckerState::fresh()
  let result = state.collect_region_constraints(
    borrow_probe_term("__err_invalid_borrow_target"),
    Type::unit(),
  )
  assert_true(
    typing_error_kind_from_constraints_result(result) == "InvalidBorrowTarget",
  )
}

///|
test "check_borrow_rules propagates invalid-borrow-target lowering errors" {
  let state = TypeCheckerState::fresh()
  let result = state.check_borrow_rules(
    borrow_probe_term("__err_invalid_borrow_target"),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_facts_result(result) == "InvalidBorrowTarget",
  )
}

///|
test "analyze_borrows propagates invalid-borrow-target errors first" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    borrow_probe_term("__err_invalid_borrow_target"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "InvalidBorrowTarget",
  )
}

///|
test "enabled wrappers preserve base typing errors before borrow analysis" {
  let state = TypeCheckerState::fresh()
  let infer_result = state.infer_type_with_borrow_analysis(
    Term::var_term("missing"),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_type_result(infer_result) == "Unbound")

  let check_result = state.check_type_with_borrow_analysis(
    Term::var_term("missing"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_checked_result(check_result) == "Unbound")
}

///|
test "enabled wrappers succeed for ok probe term" {
  let state = TypeCheckerState::fresh()

  let inferred = state.infer_type_with_borrow_analysis(
    borrow_probe_term("__ok_borrow"),
    BorrowCheckerOptions::default(),
  )
  match inferred {
    Ok(ty) => assert_true(ty == Type::unit())
    _ => panic()
  }

  let checked = state.check_type_with_borrow_analysis(
    borrow_probe_term("__ok_borrow"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  match checked {
    Ok(result) => assert_true(result.ty == Type::unit())
    _ => panic()
  }
}

///|
test "disabled analyze_borrows short-circuits even on invalid probes" {
  let state = TypeCheckerState::fresh()

  let invalid_result = state.analyze_borrows(
    borrow_probe_term("__err_invalid_borrow_target"),
    Type::unit(),
    BorrowCheckerOptions::disabled(),
  )
  assert_true(invalid_result is Ok(_))

  let unknown_result = state.analyze_borrows(
    Term::var_term("missing"),
    Type::unit(),
    BorrowCheckerOptions::disabled(),
  )
  assert_true(unknown_result is Ok(_))
}

///|
test "collect_region_constraints_from_ir dispatches by first node tag" {
  let ir_first_use_after = ir_with_two_nodes(
    borrow_probe_term("__err_use_after_move"),
    borrow_probe_term("__err_dangling_reference_escape"),
  )
  let first_use_after = collect_region_constraints_from_ir(ir_first_use_after)
  match first_use_after {
    Ok(constraints) => assert_eq(constraints.length(), 0)
    _ => panic()
  }

  let ir_first_dangling = ir_with_two_nodes(
    borrow_probe_term("__err_dangling_reference_escape"),
    borrow_probe_term("__err_use_after_move"),
  )
  let first_dangling = collect_region_constraints_from_ir(ir_first_dangling)
  match first_dangling {
    Ok(constraints) => {
      assert_eq(constraints.length(), 1)
      assert_true(
        constraints[0] ==
        RegionConstraint::placeholder("__err_dangling_reference_escape"),
      )
    }
    _ => panic()
  }
}

///|
test "check_borrow_rules_placeholder dispatches by first node tag" {
  let first_ok = check_borrow_rules_placeholder(
    ir_with_two_nodes(
      borrow_probe_term("__ok_borrow"),
      borrow_probe_term("__err_borrow_conflict"),
    ),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(first_ok is Ok(_))

  let first_conflict = check_borrow_rules_placeholder(
    ir_with_two_nodes(
      borrow_probe_term("__err_borrow_conflict"),
      borrow_probe_term("__ok_borrow"),
    ),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(
    typing_error_kind_from_facts_result(first_conflict) == "BorrowConflict",
  )
}

///|
test "collect_region_constraints_from_ir returns Message when first node is unrecognized" {
  let ir = ir_with_two_nodes(
    Term::unit(),
    borrow_probe_term("__err_borrow_outlives_owner"),
  )
  let result = collect_region_constraints_from_ir(ir)
  assert_true(typing_error_kind_from_constraints_result(result) == "Message")
}

///|
test "check_borrow_rules_placeholder returns Message when first node is unrecognized" {
  let ir = ir_with_two_nodes(
    Term::unit(),
    borrow_probe_term("__err_use_after_move"),
  )
  let result = check_borrow_rules_placeholder(
    ir,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_facts_result(result) == "Message")
}

///|
test "solve_region_constraints placeholder precedence prefers outlives first" {
  let result = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
    RegionConstraint::placeholder("__err_dangling_reference_escape"),
    RegionConstraint::placeholder("__err_borrow_outlives_owner"),
  ])
  assert_true(
    typing_error_kind_from_solution_result(result) == "BorrowOutlivesOwner",
  )
}

///|
test "solve_region_constraints placeholder precedence then prefers dangling" {
  let result = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
    RegionConstraint::placeholder("__err_dangling_reference_escape"),
  ])
  assert_true(
    typing_error_kind_from_solution_result(result) == "DanglingReferenceEscape",
  )
}

///|
test "solve_region_constraints returns Message for unmatched placeholder or structural constraints" {
  let unmatched = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__unknown_region_probe"),
  ])
  assert_true(typing_error_kind_from_solution_result(unmatched) == "Message")

  let structural = solve_region_constraints_placeholder([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
  ])
  assert_true(typing_error_kind_from_solution_result(structural) == "Message")
}

///|
test "check_borrow_rules_placeholder ignores solved/options in scaffold mode" {
  let solved = RegionSolution::{
    outlives: Map::from_array([(Region::named("a"), Set::new())]),
    unresolved: [RegionConstraint::placeholder("x")],
  }

  let disabled_opts = BorrowCheckerOptions::disabled()
  let result = check_borrow_rules_placeholder(
    ir_with_two_nodes(
      borrow_probe_term("__err_use_after_move"),
      borrow_probe_term("__ok_borrow"),
    ),
    solved,
    disabled_opts,
  )

  assert_true(typing_error_kind_from_facts_result(result) == "UseAfterMove")
}

///|
test "analyze_borrows with use_nll variation preserves scaffold error mapping" {
  let state = TypeCheckerState::fresh()
  let opts = BorrowCheckerOptions::{
    enabled: true,
    use_nll: true,
    diagnostics: false,
  }

  let result = state.analyze_borrows(
    borrow_probe_term("__err_assign_to_immutable"),
    Type::unit(),
    opts,
  )
  assert_true(
    typing_error_kind_from_analysis_result(result) == "AssignToImmutable",
  )
}
