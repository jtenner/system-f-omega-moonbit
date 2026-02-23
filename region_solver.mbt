///|
fn owner_region_for_place(place : Place) -> Region {
  Region::named("owner::" + place.root)
}

///|
fn region_constraint_for_operation(
  node_id : Int,
  operation : BorrowOperation,
) -> RegionConstraint? {
  match operation {
    BorrowSharedOperation(place) =>
      Some(
        RegionConstraint::outlives(
          owner_region_for_place(place),
          region_for_node(node_id),
        ),
      )
    BorrowMutOperation(place) =>
      Some(
        RegionConstraint::outlives(
          owner_region_for_place(place),
          region_for_node(node_id),
        ),
      )
    RegionOutlivesOwnerOperation(_) => None
    RegionDanglingEscapeOperation(_) => None
    RegionUnsatisfiedOperation(_) => None
    _ => None
  }
}

///|
fn is_trait_dictionary_or_polymorphic_boundary_term(term : Term) -> Bool {
  match term {
    Dict(_, _, _) => true
    TraitLam(_, _, _, _, _, _) => true
    TraitApp(_, _, _) => true
    TraitMethod(_, _) => true
    TyLam(_, _, _) => true
    _ => false
  }
}

///|
fn add_owner_outlives_boundary_constraints(
  constraints : Array[RegionConstraint],
  place : Place,
  scope_stack_ids : Array[Int],
  scope_stack_terms : Array[Term],
) -> Unit {
  let owner_region = owner_region_for_place(place)
  loop 0 {
    i if i < scope_stack_ids.length() => {
      if is_trait_dictionary_or_polymorphic_boundary_term(scope_stack_terms[i]) {
        constraints.push(
          RegionConstraint::outlives(
            owner_region,
            region_for_node(scope_stack_ids[i]),
          ),
        )
      }
      continue i + 1
    }
    _ => ()
  }
}

///|
/// Description: Extracts region constraints from borrow IR scope nesting.
/// Example: `let _ = collect_region_constraints_from_ir(BorrowIr::{ nodes: [] })`
pub fn collect_region_constraints_from_ir(
  ir : BorrowIr,
) -> Result[Array[RegionConstraint], TypingError] {
  let constraints : Array[RegionConstraint] = []
  let scope_stack_ids : Array[Int] = []
  let scope_stack_terms : Array[Term] = []

  for node in ir.nodes {
    let mut depth = node.scope_depth
    if depth < 0 {
      depth = 0
    }
    if depth > scope_stack_ids.length() {
      depth = scope_stack_ids.length()
    }

    while scope_stack_ids.length() > depth {
      ignore(scope_stack_ids.pop())
      ignore(scope_stack_terms.pop())
    }

    if depth > 0 && scope_stack_ids.length() > 0 {
      let parent_id = scope_stack_ids[scope_stack_ids.length() - 1]
      constraints.push(
        RegionConstraint::outlives(
          region_for_node(parent_id),
          region_for_node(node.id),
        ),
      )
    }

    match borrow_operation_from_term(node.term) {
      Some(operation) =>
        match region_constraint_for_operation(node.id, operation) {
          Some(constraint) => constraints.push(constraint)
          None => ()
        }
      None => ()
    }

    match borrow_operation_from_term(node.term) {
      Some(BorrowSharedOperation(place)) =>
        add_owner_outlives_boundary_constraints(
          constraints, place, scope_stack_ids, scope_stack_terms,
        )
      Some(BorrowMutOperation(place)) =>
        add_owner_outlives_boundary_constraints(
          constraints, place, scope_stack_ids, scope_stack_terms,
        )
      _ => ()
    }

    scope_stack_ids.push(node.id)
    scope_stack_terms.push(node.term)
  }

  Ok(constraints)
}

///|
/// Description: Solves region constraints with equality expansion and transitive closure.
/// Example: `let _ = solve_region_constraints_ir([])`
pub fn solve_region_constraints_ir(
  constraints : Array[RegionConstraint],
) -> Result[RegionSolution, TypingError] {
  let outlives : Map[Region, Set[Region]] = Map::new()
  let unresolved : Array[RegionConstraint] = []

  for constraint in constraints {
    match constraint {
      Outlives(left, right) => ignore(add_outlives_edge(outlives, left, right))
      Equal(left, right) => {
        ignore(add_outlives_edge(outlives, left, right))
        ignore(add_outlives_edge(outlives, right, left))
      }
      Placeholder(_) => unresolved.push(constraint)
    }
  }

  if unresolved.length() > 0 {
    return Err(RegionConstraintUnsatisfied(unresolved[0]))
  }

  let solved = solve_outlives_transitively(outlives)
  Ok(RegionSolution::{ outlives: solved, unresolved: [] })
}
