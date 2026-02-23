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
fn nested_projection_borrow_ends_in_expression_term() -> Term {
  Term::tuple_project(
    Term::tuple([
      Term::tuple_project(
        Term::tuple([
          Term::borrow_shared(Term::project(Term::var_term("x"), "field")),
          Term::unit(),
        ]),
        1,
      ),
      Term::assign(Term::var_term("x"), Term::unit()),
      Term::unit(),
    ]),
    2,
  )
}

///|
fn nested_projection_borrow_escapes_outer_scope_term() -> Term {
  Term::tuple_project(
    Term::tuple([
      Term::tuple_project(
        Term::tuple([
          Term::borrow_shared(Term::project(Term::var_term("x"), "field")),
          Term::unit(),
        ]),
        0,
      ),
      Term::assign(Term::var_term("x"), Term::unit()),
      Term::unit(),
    ]),
    2,
  )
}

///|
fn non_literal_tuple_projection_borrow_ends_in_expression_term() -> Term {
  let tuple_source = Term::let_term(
    "tmp",
    Term::tuple([
      Term::borrow_shared(Term::project(Term::var_term("x"), "field")),
      Term::unit(),
    ]),
    Term::var_term("tmp"),
  )
  Term::tuple_project(
    Term::tuple([
      Term::tuple_project(tuple_source, 1),
      Term::assign(Term::var_term("x"), Term::unit()),
      Term::unit(),
    ]),
    2,
  )
}

///|
fn non_literal_tuple_projection_borrow_escapes_outer_scope_term() -> Term {
  let tuple_source = Term::let_term(
    "tmp",
    Term::tuple([
      Term::borrow_shared(Term::project(Term::var_term("x"), "field")),
      Term::unit(),
    ]),
    Term::var_term("tmp"),
  )
  Term::tuple_project(
    Term::tuple([
      Term::tuple_project(tuple_source, 0),
      Term::assign(Term::var_term("x"), Term::unit()),
      Term::unit(),
    ]),
    2,
  )
}

///|
fn record_projection_borrow_ends_in_expression_term() -> Term {
  let record_source = Term::record([
    ("field", Term::borrow_shared(Term::project(Term::var_term("x"), "field"))),
    ("other", Term::unit()),
  ])
  Term::tuple_project(
    Term::tuple([
      Term::project(record_source, "other"),
      Term::assign(Term::var_term("x"), Term::unit()),
      Term::unit(),
    ]),
    2,
  )
}

///|
fn record_projection_borrow_escapes_outer_scope_term() -> Term {
  let record_source = Term::record([
    ("field", Term::borrow_shared(Term::project(Term::var_term("x"), "field"))),
    ("other", Term::unit()),
  ])
  Term::tuple_project(
    Term::tuple([
      Term::project(record_source, "field"),
      Term::assign(Term::var_term("x"), Term::unit()),
      Term::unit(),
    ]),
    2,
  )
}

///|
fn branch_join_tuple_source_term() -> Term {
  Term::match_term(Term::var_term("scrutinee"), [
    (
      Pattern::wildcard(),
      Term::tuple([
        Term::borrow_shared(Term::var_term("x")),
        Term::borrow_shared(Term::var_term("y")),
      ]),
    ),
    (
      Pattern::wildcard(),
      Term::tuple([
        Term::borrow_shared(Term::var_term("z")),
        Term::borrow_shared(Term::var_term("w")),
      ]),
    ),
  ])
}

///|
fn function_returned_tuple_source_term() -> Term {
  Term::app(
    Term::lam(
      "_",
      Type::unit(),
      Term::tuple([
        Term::borrow_shared(Term::var_term("x")),
        Term::borrow_shared(Term::var_term("y")),
      ]),
    ),
    Term::unit(),
  )
}

///|
fn branch_join_record_source_term() -> Term {
  Term::match_term(Term::var_term("scrutinee"), [
    (
      Pattern::wildcard(),
      Term::record([
        ("left", Term::borrow_shared(Term::var_term("x"))),
        ("right", Term::borrow_shared(Term::var_term("y"))),
      ]),
    ),
    (
      Pattern::wildcard(),
      Term::record([
        ("left", Term::borrow_shared(Term::var_term("z"))),
        ("right", Term::borrow_shared(Term::var_term("w"))),
      ]),
    ),
  ])
}

///|
fn function_returned_record_source_term() -> Term {
  Term::app(
    Term::lam(
      "_",
      Type::unit(),
      Term::record([
        ("left", Term::borrow_shared(Term::var_term("x"))),
        ("right", Term::borrow_shared(Term::var_term("y"))),
      ]),
    ),
    Term::unit(),
  )
}

///|
fn let_bound_function_alias_tuple_source_term() -> Term {
  Term::let_term(
    "mk_tuple",
    Term::lam(
      "_",
      Type::unit(),
      Term::tuple([
        Term::borrow_shared(Term::var_term("x")),
        Term::borrow_shared(Term::var_term("y")),
      ]),
    ),
    Term::app(Term::var_term("mk_tuple"), Term::unit()),
  )
}

///|
fn let_bound_function_alias_record_source_term() -> Term {
  Term::let_term(
    "mk_record",
    Term::lam(
      "_",
      Type::unit(),
      Term::record([
        ("left", Term::borrow_shared(Term::var_term("x"))),
        ("right", Term::borrow_shared(Term::var_term("y"))),
      ]),
    ),
    Term::app(Term::var_term("mk_record"), Term::unit()),
  )
}

///|
fn let_wrapped_match_tuple_source_term() -> Term {
  Term::let_term("tmp", branch_join_tuple_source_term(), Term::var_term("tmp"))
}

///|
fn let_wrapped_match_record_source_term() -> Term {
  Term::let_term("tmp", branch_join_record_source_term(), Term::var_term("tmp"))
}

///|
fn let_wrapped_app_tuple_source_term() -> Term {
  Term::let_term(
    "tmp",
    function_returned_tuple_source_term(),
    Term::var_term("tmp"),
  )
}

///|
fn let_wrapped_app_record_source_term() -> Term {
  Term::let_term(
    "tmp",
    function_returned_record_source_term(),
    Term::var_term("tmp"),
  )
}

///|
fn first_borrow_shared_scope_depth_for_var(
  ir : BorrowIr,
  var_name : String,
) -> Int? {
  for node in ir.nodes {
    match node.term {
      BorrowShared(Var(name)) if name == var_name =>
        return Some(node.scope_depth)
      _ => ()
    }
  }
  None
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
test "RED: lower_to_borrow_ir should emit explicit match-branch boundary markers" {
  let term = Term::match_term(Term::var_term("scrutinee"), [
    (Pattern::wildcard(), Term::unit()),
    (Pattern::wildcard(), Term::unit()),
  ])
  let result = lower_to_borrow_ir(term)
  assert_true(result is Ok(_))
  match result {
    Ok(ir) => {
      let mut saw_boundary = false
      for node in ir.nodes {
        match node.term {
          Con(name, Tuple(elements)) =>
            if name == borrow_ir_match_branch_boundary_marker_name() &&
              elements.length() == 0 {
              saw_boundary = true
            }
          _ => ()
        }
      }
      assert_true(saw_boundary)
    }
    _ => panic()
  }
}

///|
test "collect_region_constraints treats ordinary constructors as inert terms" {
  let state = TypeCheckerState::fresh()
  let result = state.collect_region_constraints(
    ordinary_constructor_term("LegacyProbeLikeInvalidBorrowTarget"),
    Type::unit(),
  )
  assert_true(result is Ok(_))
}

///|
test "check_borrow_rules treats ordinary constructors as inert terms" {
  let state = TypeCheckerState::fresh()
  let result = state.check_borrow_rules(
    ordinary_constructor_term("LegacyProbeLikeInvalidBorrowTarget"),
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "analyze_borrows treats ordinary constructors as inert terms" {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    ordinary_constructor_term("LegacyProbeLikeInvalidBorrowTarget"),
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
test "enabled wrappers succeed for ordinary constructors" {
  let state = TypeCheckerState::fresh()

  let inferred = state.infer_type_with_borrow_analysis(
    ordinary_constructor_term("NoBorrowConstructorA"),
    BorrowCheckerOptions::default(),
  )
  match inferred {
    Ok(ty) => assert_true(ty == Type::unit())
    _ => panic()
  }

  let checked = state.check_type_with_borrow_analysis(
    ordinary_constructor_term("NoBorrowConstructorB"),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  match checked {
    Ok(result) => assert_true(result.ty == Type::unit())
    _ => panic()
  }
}

///|
test "disabled analyze_borrows short-circuits even on ordinary constructors" {
  let state = TypeCheckerState::fresh()

  let invalid_result = state.analyze_borrows(
    ordinary_constructor_term("NoBorrowConstructorDisabled"),
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
test "collect_region_constraints_from_ir follows scope depth for inert constructors" {
  let ir = ir_with_two_nodes(
    ordinary_constructor_term("ScopeDepthMarkerA"),
    ordinary_constructor_term("ScopeDepthMarkerB"),
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
        term: Term::con("BorrowOpBorrowShared__x", Type::unit()),
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
test "RED: collect_region_constraints_from_ir adds trait dictionary boundary owner edges" {
  let ir = BorrowIr::{
    nodes: [
      BorrowIrNode::{
        id: 0,
        term: Term::dict("Eq", Type::unit(), []),
        scope_depth: 0,
      },
      BorrowIrNode::{
        id: 1,
        term: Term::con("BorrowOpBorrowShared__x", Type::unit()),
        scope_depth: 1,
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
test "RED: collect_region_constraints_from_ir adds trait abstraction boundary owner edges" {
  let ir = BorrowIr::{
    nodes: [
      BorrowIrNode::{
        id: 0,
        term: TraitLam("dict", "Eq", "A", Star, [], Term::unit()),
        scope_depth: 0,
      },
      BorrowIrNode::{
        id: 1,
        term: Term::con("BorrowOpBorrowMut__x", Type::unit()),
        scope_depth: 1,
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
test "RED: collect_region_constraints_from_ir adds polymorphic boundary owner edges" {
  let ir = BorrowIr::{
    nodes: [
      BorrowIrNode::{
        id: 0,
        term: TyLam("A", Star, Term::unit()),
        scope_depth: 0,
      },
      BorrowIrNode::{
        id: 1,
        term: Term::con("BorrowOpBorrowShared__x", Type::unit()),
        scope_depth: 1,
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
      ordinary_constructor_term("ArbitraryConstructorA"),
      ordinary_constructor_term("ArbitraryConstructorB"),
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
        term: Term::con("BorrowOpBorrowShared__x", Type::unit()),
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
        term: Term::con("BorrowOpBorrowMut__x", Type::unit()),
        scope_depth: 1,
      },
      BorrowIrNode::{
        id: 1,
        term: Term::con("BorrowOpBorrowShared__x", Type::unit()),
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
test "RED: nested projection borrow that ends in-expression is released before outer assignment" {
  let state = TypeCheckerState::fresh()
  let term = nested_projection_borrow_ends_in_expression_term()

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: nested projection borrow that escapes to outer scope conflicts with outer assignment" {
  let state = TypeCheckerState::fresh()
  let term = nested_projection_borrow_escapes_outer_scope_term()

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(MutateWhileBorrowed(_)))
  match result {
    Err(MutateWhileBorrowed(place)) => {
      assert_true(place.root == "x")
      assert_eq(place.projections.length(), 0)
    }
    _ => panic()
  }
}

///|
test "RED: non-literal tuple projection borrow that ends in-expression is released before outer assignment" {
  let state = TypeCheckerState::fresh()
  let term = non_literal_tuple_projection_borrow_ends_in_expression_term()

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: non-literal tuple projection borrow that escapes to outer scope conflicts with outer assignment" {
  let state = TypeCheckerState::fresh()
  let term = non_literal_tuple_projection_borrow_escapes_outer_scope_term()

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(MutateWhileBorrowed(_)))
}

///|
test "RED: record projection borrow that ends in-expression is released before outer assignment" {
  let state = TypeCheckerState::fresh()
  let term = record_projection_borrow_ends_in_expression_term()

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(typing_error_kind_from_analysis_result(result) == "Ok")
}

///|
test "RED: record projection borrow that escapes to outer scope conflicts with outer assignment" {
  let state = TypeCheckerState::fresh()
  let term = record_projection_borrow_escapes_outer_scope_term()

  let result = state.analyze_borrows(
    term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Err(MutateWhileBorrowed(_)))
}

///|
test "RED: tuple-projection lowering keeps selected tuple-literal element shallower than non-selected element" {
  let term = Term::tuple_project(
    Term::tuple([
      Term::borrow_shared(Term::var_term("x")),
      Term::borrow_shared(Term::var_term("y")),
    ]),
    0,
  )
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(selected_depth), Some(non_selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: tuple-projection lowering keeps selected non-literal tuple source element shallower than non-selected element" {
  let tuple_source = Term::let_term(
    "tmp",
    Term::tuple([
      Term::borrow_shared(Term::var_term("x")),
      Term::borrow_shared(Term::var_term("y")),
    ]),
    Term::var_term("tmp"),
  )
  let term = Term::tuple_project(tuple_source, 1)
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: tuple-projection lowering keeps selected match-joined tuple element shallower than non-selected element" {
  let term = Term::tuple_project(branch_join_tuple_source_term(), 1)
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: tuple-projection lowering keeps selected function-returned tuple element shallower than non-selected element" {
  let term = Term::tuple_project(function_returned_tuple_source_term(), 1)
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: record-projection lowering keeps selected match-joined field shallower than non-selected field" {
  let term = Term::project(branch_join_record_source_term(), "right")
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: record-projection lowering keeps selected function-returned field shallower than non-selected field" {
  let term = Term::project(function_returned_record_source_term(), "right")
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: tuple-projection lowering keeps selected let-bound function-alias app element shallower than non-selected element" {
  let term = Term::tuple_project(
    let_bound_function_alias_tuple_source_term(),
    1,
  )
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: record-projection lowering keeps selected let-bound function-alias app field shallower than non-selected field" {
  let term = Term::project(
    let_bound_function_alias_record_source_term(),
    "right",
  )
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: tuple-projection lowering keeps selected let-to-match source element shallower than non-selected element" {
  let term = Term::tuple_project(let_wrapped_match_tuple_source_term(), 1)
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: record-projection lowering keeps selected let-to-match source field shallower than non-selected field" {
  let term = Term::project(let_wrapped_match_record_source_term(), "right")
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: tuple-projection lowering keeps selected let-to-app source element shallower than non-selected element" {
  let term = Term::tuple_project(let_wrapped_app_tuple_source_term(), 1)
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "RED: record-projection lowering keeps selected let-to-app source field shallower than non-selected field" {
  let term = Term::project(let_wrapped_app_record_source_term(), "right")
  let lowered = lower_to_borrow_ir(term)
  assert_true(lowered is Ok(_))
  match lowered {
    Ok(ir) =>
      match
        (
          first_borrow_shared_scope_depth_for_var(ir, "x"),
          first_borrow_shared_scope_depth_for_var(ir, "y"),
        ) {
        (Some(non_selected_depth), Some(selected_depth)) =>
          assert_true(selected_depth < non_selected_depth)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "collect_region_constraints_from_ir handles unrecognized-first-node IR" {
  let ir = ir_with_two_nodes(
    Term::unit(),
    ordinary_constructor_term("UnrecognizedConstructorAfterUnit"),
  )
  let result = collect_region_constraints_from_ir(ir)
  assert_true(result is Ok(_))
}

///|
test "check_borrow_rules_placeholder handles unrecognized-first-node IR" {
  let ir = ir_with_two_nodes(
    Term::unit(),
    ordinary_constructor_term("AnotherUnrecognizedConstructor"),
  )
  let result = check_borrow_rules_placeholder(
    ir,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(result is Ok(_))
}

///|
test "solve_region_constraints treats placeholder constraints as generic unsatisfied constraints" {
  let result = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("placeholder.constraint.unsatisfied"),
    RegionConstraint::placeholder("placeholder.constraint.dangling"),
    RegionConstraint::placeholder("placeholder.constraint.outlives"),
  ])
  assert_true(result is Err(RegionConstraintUnsatisfied(_)))
  match result {
    Err(RegionConstraintUnsatisfied(constraint)) =>
      assert_true(
        constraint ==
        RegionConstraint::placeholder("placeholder.constraint.unsatisfied"),
      )
    _ => panic()
  }
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
      ordinary_constructor_term("UnresolvedSolvedConstraintNodeA"),
      ordinary_constructor_term("UnresolvedSolvedConstraintNodeB"),
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
      ordinary_constructor_term("DisabledUnresolvedNodeA"),
      ordinary_constructor_term("DisabledUnresolvedNodeB"),
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
    ordinary_constructor_term("UseNllOrdinaryConstructor"),
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
test "RED: analyze_borrows uses branch-join moved-place meet semantics" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    Term::match_term(Term::var_term("scrutinee"), [
      (
        Pattern::wildcard(),
        borrow_intrinsic_unary("move_value", Term::var_term("x")),
      ),
      (Pattern::wildcard(), Term::unit()),
    ]),
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
test "RED: generalized region unsatisfied ops emit structural unsatisfied constraints" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    Term::con(
      "BorrowOpRegionUnsatisfied__named:alpha__named:omega",
      Type::unit(),
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
          Region::named("alpha"),
          Region::named("omega"),
        ),
      )
    _ => panic()
  }
}

///|
test "RED: generalized region unsatisfied ops preserve infer-to-static payload shape" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    Term::con("BorrowOpRegionUnsatisfied__infer:7__static", Type::unit()),
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
        RegionConstraint::outlives(Region::infer(7), Region::static_region()),
      )
    _ => panic()
  }
}

///|
test "RED: generalized region unsatisfied ops preserve static-to-infer payload shape" {
  let state = TypeCheckerState::fresh()
  let term = borrow_intrinsic_ops_term([
    Term::con("BorrowOpRegionUnsatisfied__static__infer:11", Type::unit()),
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
        RegionConstraint::outlives(Region::static_region(), Region::infer(11)),
      )
    _ => panic()
  }
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
test "RED: structural region ops preserve actionable outlives and dangling payloads" {
  let state = TypeCheckerState::fresh()
  let outlives_owner_term = borrow_intrinsic_ops_term([
    Term::con("BorrowOpRegionOutlivesOwner__x", Type::unit()),
  ])
  let outlives_owner_result = state.analyze_borrows(
    outlives_owner_term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(outlives_owner_result is Err(BorrowOutlivesOwner(_)))
  match outlives_owner_result {
    Err(BorrowOutlivesOwner(message)) => assert_true(message == "x")
    _ => panic()
  }

  let dangling_escape_term = borrow_intrinsic_ops_term([
    Term::con("BorrowOpRegionDanglingEscape__x", Type::unit()),
  ])
  let dangling_escape_result = state.analyze_borrows(
    dangling_escape_term,
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  assert_true(dangling_escape_result is Err(DanglingReferenceEscape(_)))
  match dangling_escape_result {
    Err(DanglingReferenceEscape(message)) => assert_true(message == "x")
    _ => panic()
  }
}
