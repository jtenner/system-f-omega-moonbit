///|
fn projections_prefix_match(
  prefix : Array[PlaceProjection],
  full : Array[PlaceProjection],
) -> Bool {
  if prefix.length() > full.length() {
    return false
  }
  let mut index = 0
  while index < prefix.length() {
    if prefix[index] != full[index] {
      return false
    }
    index = index + 1
  }
  true
}

///|
fn places_overlap(left : Place, right : Place) -> Bool {
  if left.root != right.root {
    return false
  }
  projections_prefix_match(left.projections, right.projections) ||
  projections_prefix_match(right.projections, left.projections)
}

///|
fn find_conflicting_loan(
  loans : Array[Loan],
  place : Place,
  mutability : Mutability,
) -> Loan? {
  for loan in loans {
    if !places_overlap(loan.place, place) {
      continue
    }
    if loan.mutability == Mutable || mutability == Mutable {
      return Some(loan)
    }
  }
  None
}

///|
fn has_overlapping_loan(loans : Array[Loan], place : Place) -> Bool {
  for loan in loans {
    if places_overlap(loan.place, place) {
      return true
    }
  }
  false
}

///|
fn has_overlapping_moved_place(
  moved_places : Array[Place],
  place : Place,
) -> Bool {
  for moved_place in moved_places {
    if places_overlap(moved_place, place) {
      return true
    }
  }
  false
}

///|
priv struct MatchBranchMoveFrame {
  scope_depth : Int
  remaining_boundaries : Int
  base_places : Array[Place]
  base_place_keys : Set[String]
  meet_places : Array[Place]?
  meet_place_keys : Set[String]?
}

///|
fn clone_moved_places(places : Array[Place]) -> Array[Place] {
  let cloned : Array[Place] = []
  for place in places {
    cloned.push(place)
  }
  cloned
}

///|
fn clone_moved_place_keys(keys : Set[String]) -> Set[String] {
  let cloned : Set[String] = Set::new()
  for key in keys {
    cloned.add(key)
  }
  cloned
}

///|
fn clear_moved_place_keys(keys : Set[String]) -> Unit {
  let snapshot = keys.to_array()
  for key in snapshot {
    keys.remove(key)
  }
}

///|
fn replace_moved_place_state(
  moved_places : Array[Place],
  moved_place_keys : Set[String],
  next_places : Array[Place],
  next_keys : Set[String],
) -> Unit {
  while moved_places.length() > 0 {
    ignore(moved_places.pop())
  }
  clear_moved_place_keys(moved_place_keys)

  for place in next_places {
    moved_places.push(place)
  }
  for key in next_keys {
    moved_place_keys.add(key)
  }
}

///|
fn record_moved_place(
  moved_places : Array[Place],
  moved_place_keys : Set[String],
  place : Place,
) -> Unit {
  let key = place_key(place)
  if moved_place_keys.contains(key) {
    return
  }
  moved_places.push(place)
  moved_place_keys.add(key)
}

///|
fn intersect_moved_place_states(
  left_places : Array[Place],
  left_keys : Set[String],
  right_keys : Set[String],
) -> (Array[Place], Set[String]) {
  let intersected_keys : Set[String] = Set::new()
  for key in left_keys {
    if right_keys.contains(key) {
      intersected_keys.add(key)
    }
  }

  let intersected_places : Array[Place] = []
  let seen : Set[String] = Set::new()
  for place in left_places {
    let key = place_key(place)
    if intersected_keys.contains(key) && !seen.contains(key) {
      intersected_places.push(place)
      seen.add(key)
    }
  }

  (intersected_places, intersected_keys)
}

///|
fn assignment_reinitializes_moved_place(
  assigned_place : Place,
  moved_place : Place,
) -> Bool {
  if assigned_place.root != moved_place.root {
    return false
  }
  projections_prefix_match(assigned_place.projections, moved_place.projections)
}

///|
fn clear_reinitialized_moved_places(
  moved_places : Array[Place],
  moved_place_keys : Set[String],
  assigned_place : Place,
) -> Unit {
  let mut index = 0
  while index < moved_places.length() {
    let moved_place = moved_places[index]
    if assignment_reinitializes_moved_place(assigned_place, moved_place) {
      moved_place_keys.remove(place_key(moved_place))
      ignore(moved_places.remove(index))
    } else {
      index = index + 1
    }
  }
}

///|
fn release_loans_for_place(
  loans : Array[Loan],
  loan_scope_depths : Map[LoanId, Int],
  place : Place,
) -> Unit {
  let mut index = 0
  while index < loans.length() {
    if places_overlap(loans[index].place, place) {
      loan_scope_depths.remove(loans[index].id)
      ignore(loans.remove(index))
    } else {
      index = index + 1
    }
  }
}

///|
fn release_loans_outside_lexical_scope(
  loans : Array[Loan],
  loan_scope_depths : Map[LoanId, Int],
  scope_depth : Int,
) -> Unit {
  let mut index = 0
  while index < loans.length() {
    let loan = loans[index]
    let loan_scope_depth = match loan_scope_depths.get(loan.id) {
      Some(depth) => depth
      None => scope_depth
    }

    if loan_scope_depth > scope_depth {
      loan_scope_depths.remove(loan.id)
      ignore(loans.remove(index))
    } else {
      index = index + 1
    }
  }
}

///|
/// Description: Borrow-rule checker entry point for lowered IR.
/// Example: `let _ = check_borrow_rules_ir(BorrowIr::{ nodes: [] }, RegionSolution::empty(), BorrowCheckerOptions::default())`
pub fn check_borrow_rules_ir(
  ir : BorrowIr,
  solved : RegionSolution,
  options : BorrowCheckerOptions,
) -> Result[BorrowFacts, TypingError] {
  if !options.enabled {
    return Ok(BorrowFacts::empty())
  }

  if solved.unresolved.length() > 0 {
    return Err(RegionConstraintUnsatisfied(solved.unresolved[0]))
  }

  let loans : Array[Loan] = []
  let loan_scope_depths : Map[LoanId, Int] = Map::new()
  let moved_places : Array[Place] = []
  let moved_place_keys : Set[String] = Set::new()
  let constraints : Array[RegionConstraint] = []
  let match_move_frames : Array[MatchBranchMoveFrame] = []
  let mut next_loan_id = 0

  for node in ir.nodes {
    let mut scope_depth = node.scope_depth
    if scope_depth < 0 {
      scope_depth = 0
    }
    release_loans_outside_lexical_scope(loans, loan_scope_depths, scope_depth)

    match node.term {
      Match(_, cases) =>
        if cases.length() > 0 {
          match_move_frames.push(MatchBranchMoveFrame::{
            scope_depth,
            remaining_boundaries: cases.length(),
            base_places: clone_moved_places(moved_places),
            base_place_keys: clone_moved_place_keys(moved_place_keys),
            meet_places: None,
            meet_place_keys: None,
          })
        }
      _ => ()
    }

    if is_borrow_ir_match_branch_boundary_term(node.term) &&
      match_move_frames.length() > 0 {
      let frame_index = match_move_frames.length() - 1
      let frame = match_move_frames[frame_index]
      if frame.scope_depth == scope_depth && frame.remaining_boundaries > 0 {
        let branch_places = clone_moved_places(moved_places)
        let branch_keys = clone_moved_place_keys(moved_place_keys)

        let next_meet = match (frame.meet_places, frame.meet_place_keys) {
          (Some(meet_places), Some(meet_keys)) =>
            Some(
              intersect_moved_place_states(meet_places, meet_keys, branch_keys),
            )
          _ => Some((branch_places, branch_keys))
        }
        let next_meet_places = match next_meet {
          Some(pair) => Some(pair.0)
          None => None
        }
        let next_meet_keys = match next_meet {
          Some(pair) => Some(pair.1)
          None => None
        }

        let remaining = frame.remaining_boundaries - 1
        let updated_frame = MatchBranchMoveFrame::{
          scope_depth: frame.scope_depth,
          remaining_boundaries: remaining,
          base_places: frame.base_places,
          base_place_keys: frame.base_place_keys,
          meet_places: next_meet_places,
          meet_place_keys: next_meet_keys,
        }

        if remaining > 0 {
          match_move_frames[frame_index] = updated_frame
          replace_moved_place_state(
            moved_places,
            moved_place_keys,
            updated_frame.base_places,
            updated_frame.base_place_keys,
          )
        } else {
          replace_moved_place_state(
            moved_places,
            moved_place_keys,
            match updated_frame.meet_places {
              Some(places) => places
              None => updated_frame.base_places
            },
            match updated_frame.meet_place_keys {
              Some(keys) => keys
              None => updated_frame.base_place_keys
            },
          )
          ignore(match_move_frames.pop())
        }
        continue
      }
    }

    match borrow_operation_from_term(node.term) {
      Some(BorrowSharedOperation(place)) => {
        if !solution_has_outlives_edge(
            solved,
            owner_region_for_place(place),
            region_for_node(node.id),
          ) {
          return Err(BorrowOutlivesOwner(place_key(place)))
        }

        if has_overlapping_moved_place(moved_places, place) {
          return Err(MovedValueBorrow(place_key(place)))
        }
        match find_conflicting_loan(loans, place, Shared) {
          Some(conflicting_loan) =>
            return Err(BorrowConflict(conflicting_loan.place, place))
          None => {
            loans.push(Loan::{
              id: next_loan_id,
              place,
              mutability: Shared,
              origin: place.root,
              region: region_for_node(node.id),
            })
            loan_scope_depths.set(next_loan_id, scope_depth)
            next_loan_id = next_loan_id + 1
          }
        }
      }
      Some(BorrowMutOperation(place)) => {
        if !solution_has_outlives_edge(
            solved,
            owner_region_for_place(place),
            region_for_node(node.id),
          ) {
          return Err(BorrowOutlivesOwner(place_key(place)))
        }

        if has_overlapping_moved_place(moved_places, place) {
          return Err(MovedValueBorrow(place_key(place)))
        }
        match find_conflicting_loan(loans, place, Mutable) {
          Some(conflicting_loan) =>
            return Err(BorrowConflict(conflicting_loan.place, place))
          None => {
            loans.push(Loan::{
              id: next_loan_id,
              place,
              mutability: Mutable,
              origin: place.root,
              region: region_for_node(node.id),
            })
            loan_scope_depths.set(next_loan_id, scope_depth)
            next_loan_id = next_loan_id + 1
          }
        }
      }
      Some(MoveOperation(place)) =>
        record_moved_place(moved_places, moved_place_keys, place)
      Some(UseOperation(place)) =>
        if has_overlapping_moved_place(moved_places, place) {
          return Err(UseAfterMove(place_key(place)))
        }
      Some(AssignMutableOperation(place)) => {
        if has_overlapping_loan(loans, place) {
          return Err(MutateWhileBorrowed(place))
        }
        clear_reinitialized_moved_places(moved_places, moved_place_keys, place)
      }
      Some(AssignImmutableOperation(place)) =>
        return Err(AssignToImmutable(place))
      Some(ReleaseOperation(place)) =>
        release_loans_for_place(loans, loan_scope_depths, place)
      Some(InvalidTargetOperation(operation_name)) =>
        return Err(
          InvalidBorrowTarget(
            operation_name + " target is not a valid place expression",
          ),
        )
      Some(RegionOutlivesOwnerOperation(place)) => {
        let required = RegionConstraint::outlives(
          owner_region_for_place(place),
          region_for_node(node.id),
        )
        constraints.push(required)
        if !solution_satisfies_region_constraint(solved, required) {
          return Err(BorrowOutlivesOwner(place_key(place)))
        }
      }
      Some(RegionDanglingEscapeOperation(place)) => {
        let required = RegionConstraint::outlives(
          region_for_node(node.id),
          owner_region_for_place(place),
        )
        constraints.push(required)
        if !solution_satisfies_region_constraint(solved, required) {
          return Err(DanglingReferenceEscape(place_key(place)))
        }
      }
      Some(RegionUnsatisfiedOperation(required)) => {
        constraints.push(required)
        if !solution_satisfies_region_constraint(solved, required) {
          return Err(RegionConstraintUnsatisfied(required))
        }
      }
      None => ()
    }
  }

  Ok(BorrowFacts::{ loans, moved_places: moved_place_keys, constraints })
}
