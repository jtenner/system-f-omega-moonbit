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
fn edge_case_has_outlives_edge(
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
test "lower_to_borrow_ir lowers lambda terms structurally" {
  let term = Term::lam("x", Type::unit(), Term::var_term("x"))
  let result = lower_to_borrow_ir(term)
  assert_true(result is Ok(_))
  match result {
    Ok(ir) => {
      assert_true(ir.nodes.length() >= 2)
      assert_true(ir.nodes[0].scope_depth == 0)
      assert_true(ir.nodes[1].scope_depth == 1)
    }
    _ => panic()
  }
}

///|
test "collect_region_constraints treats synthetic probes as ordinary terms" {
  let state = TypeCheckerState::fresh()
  let result = state.collect_region_constraints(
    borrow_probe_term("__err_invalid_borrow_target"),
    Type::unit(),
  )
  assert_true(result is Ok(_))
}

///|
test "check_borrow_rules treats synthetic probes as ordinary terms" {
  let state = TypeCheckerState::fresh()
  let result = state.check_borrow_rules(
    borrow_probe_term("__err_invalid_borrow_target"),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "analyze_borrows treats synthetic probes as ordinary terms" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    borrow_probe_term("__err_invalid_borrow_target"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
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
test "enabled wrappers succeed for ordinary constructor probes" {
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
    borrow_probe_term("__err_borrow_conflict"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  match checked {
    Ok(result) => assert_true(result.ty == Type::unit())
    _ => panic()
  }
}

///|
test "disabled analyze_borrows short-circuits even on synthetic probes" {
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
test "collect_region_constraints_from_ir follows scope depth instead of tags" {
  let ir = ir_with_two_nodes(
    borrow_probe_term("__err_use_after_move"),
    borrow_probe_term("__err_dangling_reference_escape"),
  )
  let result = collect_region_constraints_from_ir(ir)
  match result {
    Ok(constraints) => {
      assert_eq(constraints.length(), 1)
      assert_true(
        constraints[0] ==
        RegionConstraint::outlives(Region::infer(0), Region::infer(1)),
      )
    }
    _ => panic()
  }
}

///|
test "RED: collect_region_constraints_from_ir emits owner outlives edges for borrow operations" {
  let ir = BorrowIr::{
    nodes: [
      BorrowIrNode::{
        id: 0,
        term: Term::con("BorrowOpBorrowSharedX", Type::unit()),
        scope_depth: 0,
      },
    ],
  }
  let result = collect_region_constraints_from_ir(ir)
  assert_true(result is Ok(_))
  match result {
    Ok(constraints) =>
      assert_true(
        constraints.contains(
          RegionConstraint::outlives(
            Region::named("owner::x"),
            Region::infer(0),
          ),
        ),
      )
    _ => panic()
  }
}

///|
test "check_borrow_rules_placeholder accepts arbitrary IR nodes" {
  let result = check_borrow_rules_placeholder(
    ir_with_two_nodes(
      borrow_probe_term("__ok_borrow"),
      borrow_probe_term("__err_borrow_conflict"),
    ),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "RED: check_borrow_rules_placeholder enforces owner outlives edges from solved graph" {
  let ir = BorrowIr::{
    nodes: [
      BorrowIrNode::{
        id: 0,
        term: Term::con("BorrowOpBorrowSharedX", Type::unit()),
        scope_depth: 0,
      },
    ],
  }

  let missing = check_borrow_rules_placeholder(
    ir,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(missing is Err(BorrowOutlivesOwner(_)))
  match missing {
    Err(BorrowOutlivesOwner(owner)) => assert_true(owner == "x")
    _ => panic()
  }

  let owner_outlives : Set[Region] = Set::new()
  owner_outlives.add(Region::infer(0))
  let solved = RegionSolution::{
    outlives: Map::from_array([(Region::named("owner::x"), owner_outlives)]),
    unresolved: [],
  }
  let allowed = check_borrow_rules_placeholder(
    ir,
    solved,
    BorrowCheckerOptions::default(),
  )
  assert_true(allowed is Ok(_))
}

///|
test "RED: check_borrow_rules_placeholder should release loans at lexical scope exit without explicit release ops" {
  let ir = BorrowIr::{
    nodes: [
      BorrowIrNode::{
        id: 0,
        term: Term::con("BorrowOpBorrowMutX", Type::unit()),
        scope_depth: 1,
      },
      BorrowIrNode::{
        id: 1,
        term: Term::con("BorrowOpBorrowSharedX", Type::unit()),
        scope_depth: 0,
      },
    ],
  }

  let owner_outlives : Set[Region] = Set::new()
  owner_outlives.add(Region::infer(0))
  owner_outlives.add(Region::infer(1))
  let solved = RegionSolution::{
    outlives: Map::from_array([(Region::named("owner::x"), owner_outlives)]),
    unresolved: [],
  }

  let result = check_borrow_rules_placeholder(
    ir,
    solved,
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "collect_region_constraints_from_ir handles unrecognized-first-node IR" {
  let ir = ir_with_two_nodes(
    Term::unit(),
    borrow_probe_term("__err_borrow_outlives_owner"),
  )
  let result = collect_region_constraints_from_ir(ir)
  assert_true(result is Ok(_))
}

///|
test "check_borrow_rules_placeholder handles unrecognized-first-node IR" {
  let ir = ir_with_two_nodes(
    Term::unit(),
    borrow_probe_term("__err_use_after_move"),
  )
  let result = check_borrow_rules_placeholder(
    ir,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
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
test "solve_region_constraints reports unsatisfied placeholder and solves structural edges" {
  let unmatched = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__unknown_region_probe"),
  ])
  assert_true(
    typing_error_kind_from_solution_result(unmatched) ==
    "RegionConstraintUnsatisfied",
  )

  let structural = solve_region_constraints_placeholder([
    RegionConstraint::outlives(Region::named("a"), Region::named("b")),
  ])
  assert_true(structural is Ok(_))
  match structural {
    Ok(solution) =>
      assert_true(
        edge_case_has_outlives_edge(
          solution,
          Region::named("a"),
          Region::named("b"),
        ),
      )
    _ => panic()
  }
}

///|
test "RED: check_borrow_rules_placeholder reports unresolved solved constraints when enabled" {
  let solved = RegionSolution::{
    outlives: Map::from_array([(Region::named("a"), Set::new())]),
    unresolved: [RegionConstraint::placeholder("x")],
  }

  let enabled_opts = BorrowCheckerOptions::default()
  let result = check_borrow_rules_placeholder(
    ir_with_two_nodes(
      borrow_probe_term("__err_use_after_move"),
      borrow_probe_term("__ok_borrow"),
    ),
    solved,
    enabled_opts,
  )

  assert_true(result is Err(RegionConstraintUnsatisfied(_)))
  match result {
    Err(RegionConstraintUnsatisfied(constraint)) =>
      assert_true(constraint == RegionConstraint::placeholder("x"))
    _ => panic()
  }
}

///|
test "disabled check_borrow_rules_placeholder remains no-op for unresolved solved constraints" {
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

  assert_true(result is Ok(_))
}

///|
test "analyze_borrows with use_nll variation succeeds for ordinary constructors" {
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
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: analyze_borrows isolates sibling match-branch mutable borrows" {
  let state = TypeCheckerState::fresh()
  let branch_borrow = borrow_intrinsic_unary("borrow_mut", Term::var_term("x"))
  let term = Term::match_term(Term::var_term("scrutinee"), [
    (Pattern::wildcard(), branch_borrow),
    (Pattern::wildcard(), branch_borrow),
  ])

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: analyze_borrows clears moved-place state after assignment reinitialization" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    borrow_intrinsic_unary("move_value", Term::var_term("x")),
    borrow_intrinsic_binary("assign_mutable", Term::var_term("x"), Term::unit()),
    borrow_intrinsic_unary("use_value", Term::var_term("x")),
  ])

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: invalid borrow target payload includes intrinsic operation name" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_unary("borrow_shared", Term::unit())

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(InvalidBorrowTarget(_)))
  match result {
    Err(InvalidBorrowTarget(message)) => {
      assert_true(message.contains("borrow_shared"))
      assert_true(message.contains("place"))
    }
    _ => panic()
  }
}

///|
test "RED: outlives-owner payload includes projected place path" {
  let projected = Term::project(Term::var_term("x"), "field")
  let ir = BorrowIr::{
    nodes: [
      BorrowIrNode::{
        id: 0,
        term: borrow_intrinsic_unary("borrow_shared", projected),
        scope_depth: 0,
      },
    ],
  }

  let result = check_borrow_rules_placeholder(
    ir,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(BorrowOutlivesOwner(_)))
  match result {
    Err(BorrowOutlivesOwner(place)) => assert_true(place == "x.field")
    _ => panic()
  }
}

///|
test "RED: region placeholder payloads preserve actionable sentinel context" {
  let outlives_owner = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_borrow_outlives_owner"),
  ])
  assert_true(outlives_owner is Err(BorrowOutlivesOwner(_)))
  match outlives_owner {
    Err(BorrowOutlivesOwner(message)) =>
      assert_true(message.contains("__err_borrow_outlives_owner"))
    _ => panic()
  }

  let dangling_escape = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("__err_dangling_reference_escape"),
  ])
  assert_true(dangling_escape is Err(DanglingReferenceEscape(_)))
  match dangling_escape {
    Err(DanglingReferenceEscape(message)) =>
      assert_true(message.contains("__err_dangling_reference_escape"))
    _ => panic()
  }
}
