///|
fn append_projection(
  projections : Array[PlaceProjection],
  projection : PlaceProjection,
) -> Array[PlaceProjection] {
  let next : Array[PlaceProjection] = []
  for p in projections {
    next.push(p)
  }
  next.push(projection)
  next
}

///|
fn region_for_node(node_id : Int) -> Region {
  Region::infer(node_id)
}

///|
/// Description: Stable schema marker used for match-branch join boundaries in borrow IR.
/// Example: `let _ = borrow_ir_match_branch_boundary_marker_name()`
pub fn borrow_ir_match_branch_boundary_marker_name() -> String {
  "BorrowIrBoundaryMatchBranch"
}

///|
/// Description: Stable borrow-IR schema version for operation-tag and boundary-node encoding.
/// Example: `let _ = borrow_ir_schema_version()`
pub fn borrow_ir_schema_version() -> Int {
  1
}

///|
fn borrow_ir_match_branch_boundary_term() -> Term {
  Term::con(borrow_ir_match_branch_boundary_marker_name(), Type::unit())
}

///|
fn is_borrow_ir_match_branch_boundary_term(term : Term) -> Bool {
  match term {
    Con(name, Tuple(elements)) =>
      name == borrow_ir_match_branch_boundary_marker_name() &&
      elements.length() == 0
    _ => false
  }
}

///|
priv enum BorrowOperation {
  BorrowSharedOperation(Place)
  BorrowMutOperation(Place)
  MoveOperation(Place)
  UseOperation(Place)
  AssignMutableOperation(Place)
  AssignImmutableOperation(Place)
  ReleaseOperation(Place)
  InvalidTargetOperation(String)
  RegionOutlivesOwnerOperation(Place)
  RegionDanglingEscapeOperation(Place)
  RegionUnsatisfiedOperation(RegionConstraint)
}

///|
fn parse_region_schema_token(token : String) -> Region? {
  if token.is_empty() {
    return None
  }

  if token == "static" {
    return Some(Region::static_region())
  }

  match token.strip_prefix("infer:") {
    Some(id_token) =>
      match parse_tuple_index_token(id_token.to_string()) {
        Some(id) => return Some(Region::infer(id))
        None => return None
      }
    None => ()
  }

  match token.strip_prefix("named:") {
    Some(name) => {
      let name = name.to_string()
      if name.is_empty() {
        return None
      }
      return Some(Region::named(name))
    }
    None => ()
  }

  Some(Region::named(token))
}

///|
fn parse_borrow_operation_parts(payload : String) -> Array[String] {
  payload.split("__").map(StringView::to_string).collect()
}

///|
fn parse_region_outlives_owner_operation(
  constructor_name : String,
) -> BorrowOperation? {
  match constructor_name.strip_prefix("BorrowOpRegionOutlivesOwner__") {
    Some(place_payload) =>
      match
        parse_borrow_place_tokens(
          parse_borrow_operation_parts(place_payload.to_string()),
        ) {
        Some(place) => Some(RegionOutlivesOwnerOperation(place))
        None => None
      }
    None => None
  }
}

///|
fn parse_region_dangling_escape_operation(
  constructor_name : String,
) -> BorrowOperation? {
  match constructor_name.strip_prefix("BorrowOpRegionDanglingEscape__") {
    Some(place_payload) =>
      match
        parse_borrow_place_tokens(
          parse_borrow_operation_parts(place_payload.to_string()),
        ) {
        Some(place) => Some(RegionDanglingEscapeOperation(place))
        None => None
      }
    None => None
  }
}

///|
fn parse_region_unsatisfied_operation(
  constructor_name : String,
) -> BorrowOperation? {
  match constructor_name.strip_prefix("BorrowOpRegionUnsatisfied__") {
    Some(region_payload) => {
      let parts = parse_borrow_operation_parts(region_payload.to_string())
      if parts.length() != 2 {
        return None
      }
      let left = match parse_region_schema_token(parts[0]) {
        Some(region) => region
        None => return None
      }
      let right = match parse_region_schema_token(parts[1]) {
        Some(region) => region
        None => return None
      }
      Some(RegionUnsatisfiedOperation(RegionConstraint::outlives(left, right)))
    }
    None => None
  }
}

///|
fn parse_invalid_target_operation(
  constructor_name : String,
) -> BorrowOperation? {
  match constructor_name.strip_prefix("BorrowOpInvalidTarget__") {
    Some(operation_name) => {
      let operation_name = operation_name.to_string()
      if operation_name.is_empty() {
        return None
      }
      Some(InvalidTargetOperation(operation_name))
    }
    None => None
  }
}

///|
fn parse_borrow_operation_from_constructor_name(
  constructor_name : String,
) -> BorrowOperation? {
  match parse_region_outlives_owner_operation(constructor_name) {
    Some(operation) => return Some(operation)
    None => ()
  }
  match parse_region_dangling_escape_operation(constructor_name) {
    Some(operation) => return Some(operation)
    None => ()
  }
  match parse_region_unsatisfied_operation(constructor_name) {
    Some(operation) => return Some(operation)
    None => ()
  }
  match parse_invalid_target_operation(constructor_name) {
    Some(operation) => return Some(operation)
    None => ()
  }
  parse_generalized_borrow_operation_from_constructor_name(constructor_name)
}

///|
fn parse_tuple_index_token(token : String) -> Int? {
  if token.is_empty() {
    return None
  }

  let mut value = 0
  for c in token {
    let code = c.to_int()
    if code < '0'.to_int() || code > '9'.to_int() {
      return None
    }
    value = value * 10 + (code - '0'.to_int())
  }
  Some(value)
}

///|
fn parse_borrow_place_tokens(tokens : Array[String]) -> Place? {
  if tokens.length() == 0 {
    return None
  }

  let root = tokens[0]
  if root.is_empty() {
    return None
  }

  let mut place = Place::root(root)
  let mut index = 1
  while index < tokens.length() {
    let token = tokens[index]
    if token == "deref" {
      place = place.deref_place()
      index = index + 1
      continue
    }

    match token.strip_prefix("field:") {
      Some(label) => {
        let label = label.to_string()
        if label.is_empty() {
          return None
        }
        place = place.field(label)
        index = index + 1
        continue
      }
      None => ()
    }

    match token.strip_prefix("tuple:") {
      Some(tuple_index_token) =>
        match parse_tuple_index_token(tuple_index_token.to_string()) {
          Some(tuple_index) => {
            place = place.tuple_index(tuple_index)
            index = index + 1
            continue
          }
          None => return None
        }
      None => ()
    }

    return None
  }

  Some(place)
}

///|
fn parse_generalized_borrow_operation_from_constructor_name(
  constructor_name : String,
) -> BorrowOperation? {
  // Stable generalized operation schema:
  // `BorrowOp<OpName>__<root>__(field:<label>|tuple:<index>|deref)*`
  // Examples:
  // - BorrowOpBorrowShared__x
  // - BorrowOpBorrowMut__x__field:left__deref
  // - BorrowOpMove__q__field:a__tuple:1
  let parts : Array[String] = constructor_name
    .split("__")
    .map(StringView::to_string)
    .collect()

  if parts.length() < 2 {
    return None
  }

  let op_name = parts[0]
  let place_tokens : Array[String] = []
  let mut index = 1
  while index < parts.length() {
    place_tokens.push(parts[index])
    index = index + 1
  }

  let place = match parse_borrow_place_tokens(place_tokens) {
    Some(place) => place
    None => return None
  }

  match op_name {
    "BorrowOpBorrowShared" => Some(BorrowSharedOperation(place))
    "BorrowOpBorrowMut" => Some(BorrowMutOperation(place))
    "BorrowOpMove" => Some(MoveOperation(place))
    "BorrowOpUse" => Some(UseOperation(place))
    "BorrowOpAssignMutable" => Some(AssignMutableOperation(place))
    "BorrowOpAssignImmutable" => Some(AssignImmutableOperation(place))
    "BorrowOpRelease" => Some(ReleaseOperation(place))
    _ => None
  }
}

///|
fn intrinsic_name_from_term(term : Term) -> String? {
  match term {
    Var(name) => Some(name)
    Con(name, _) => Some(name)
    _ => None
  }
}

///|
fn place_from_term(term : Term) -> Place? {
  match term {
    Var(name) => Some(Place::root(name))
    Con(name, _) => Some(Place::root(name))
    Project(base, label) =>
      match place_from_term(base) {
        Some(place) => Some(place.field(label))
        None => None
      }
    TupleProject(base, index) =>
      match place_from_term(base) {
        Some(place) => Some(place.tuple_index(index))
        None => None
      }
    App(callee, arg) =>
      match intrinsic_name_from_term(callee) {
        Some("deref") =>
          match place_from_term(arg) {
            Some(place) => Some(place.deref_place())
            None => None
          }
        Some("deref_place") =>
          match place_from_term(arg) {
            Some(place) => Some(place.deref_place())
            None => None
          }
        _ => None
      }
    Deref(inner) =>
      match place_from_term(inner) {
        Some(place) => Some(place.deref_place())
        None => None
      }
    Fold(_, inner) => place_from_term(inner)
    Unfold(inner) => place_from_term(inner)
    _ => None
  }
}

///|
/// Description: Canonical place extraction shared by typing and borrow-IR lowering.
/// Example: `let _ = borrow_place_from_term(Term::var_term("x"))`
pub fn borrow_place_from_term(term : Term) -> Place? {
  place_from_term(term)
}

///|
fn borrow_operation_from_intrinsic_name(name : String) -> BorrowOperation? {
  match name {
    "region_outlives_owner" =>
      Some(RegionOutlivesOwnerOperation(Place::root("region_probe")))
    "region_dangling_escape" =>
      Some(RegionDanglingEscapeOperation(Place::root("region_probe")))
    "region_unsatisfied" =>
      Some(
        RegionUnsatisfiedOperation(
          RegionConstraint::outlives(
            Region::named("region_probe::left"),
            Region::named("region_probe::right"),
          ),
        ),
      )
    "invalid_borrow_target" => Some(InvalidTargetOperation(name))
    _ => None
  }
}

///|
fn borrow_operation_from_intrinsic_unary_call(
  name : String,
  target : Term,
) -> BorrowOperation? {
  match name {
    "borrow_shared" =>
      match place_from_term(target) {
        Some(place) => Some(BorrowSharedOperation(place))
        None => Some(InvalidTargetOperation("borrow_shared"))
      }
    "borrow_ref" =>
      match place_from_term(target) {
        Some(place) => Some(BorrowSharedOperation(place))
        None => Some(InvalidTargetOperation("borrow_ref"))
      }
    "borrow_shared_ref" =>
      match place_from_term(target) {
        Some(place) => Some(BorrowSharedOperation(place))
        None => Some(InvalidTargetOperation("borrow_shared_ref"))
      }
    "borrow_mut" =>
      match place_from_term(target) {
        Some(place) => Some(BorrowMutOperation(place))
        None => Some(InvalidTargetOperation("borrow_mut"))
      }
    "move_value" =>
      match place_from_term(target) {
        Some(place) => Some(MoveOperation(place))
        None => Some(InvalidTargetOperation("move_value"))
      }
    "move_term" =>
      match place_from_term(target) {
        Some(place) => Some(MoveOperation(place))
        None => Some(InvalidTargetOperation("move_term"))
      }
    "move" =>
      match place_from_term(target) {
        Some(place) => Some(MoveOperation(place))
        None => Some(InvalidTargetOperation("move"))
      }
    "use_value" =>
      match place_from_term(target) {
        Some(place) => Some(UseOperation(place))
        None => Some(InvalidTargetOperation("use_value"))
      }
    "use" =>
      match place_from_term(target) {
        Some(place) => Some(UseOperation(place))
        None => Some(InvalidTargetOperation("use"))
      }
    "release" =>
      match place_from_term(target) {
        Some(place) => Some(ReleaseOperation(place))
        None => Some(InvalidTargetOperation("release"))
      }
    "release_borrow" =>
      match place_from_term(target) {
        Some(place) => Some(ReleaseOperation(place))
        None => Some(InvalidTargetOperation("release_borrow"))
      }
    "assign_mutable" =>
      match place_from_term(target) {
        Some(place) => Some(AssignMutableOperation(place))
        None => Some(InvalidTargetOperation("assign_mutable"))
      }
    "assign" =>
      match place_from_term(target) {
        Some(place) => Some(AssignMutableOperation(place))
        None => Some(InvalidTargetOperation("assign"))
      }
    "assign_immutable" =>
      match place_from_term(target) {
        Some(place) => Some(AssignImmutableOperation(place))
        None => Some(InvalidTargetOperation("assign_immutable"))
      }
    "assign_const" =>
      match place_from_term(target) {
        Some(place) => Some(AssignImmutableOperation(place))
        None => Some(InvalidTargetOperation("assign_const"))
      }
    "region_outlives_owner" =>
      match place_from_term(target) {
        Some(place) => Some(RegionOutlivesOwnerOperation(place))
        None => Some(InvalidTargetOperation("region_outlives_owner"))
      }
    "region_dangling_escape" =>
      match place_from_term(target) {
        Some(place) => Some(RegionDanglingEscapeOperation(place))
        None => Some(InvalidTargetOperation("region_dangling_escape"))
      }
    "region_unsatisfied" =>
      match place_from_term(target) {
        Some(place) =>
          Some(
            RegionUnsatisfiedOperation(
              RegionConstraint::outlives(
                Region::named("region::" + place_key(place)),
                Region::named("region::required"),
              ),
            ),
          )
        None => Some(InvalidTargetOperation("region_unsatisfied"))
      }
    _ => None
  }
}

///|
fn intrinsic_name_requires_single_argument(name : String) -> Bool {
  match name {
    "borrow_shared" => true
    "borrow_ref" => true
    "borrow_shared_ref" => true
    "borrow_mut" => true
    "move_value" => true
    "move_term" => true
    "move" => true
    "use_value" => true
    "use" => true
    "release" => true
    "release_borrow" => true
    "region_outlives_owner" => true
    "region_dangling_escape" => true
    "region_unsatisfied" => true
    _ => false
  }
}

///|
fn borrow_operation_from_intrinsic_binary_call(
  name : String,
  target : Term,
  value : Term,
) -> BorrowOperation? {
  ignore(value)
  if intrinsic_name_requires_single_argument(name) {
    return Some(InvalidTargetOperation(name))
  }

  match name {
    "assign_mutable" =>
      match place_from_term(target) {
        Some(place) => Some(AssignMutableOperation(place))
        None => Some(InvalidTargetOperation("assign_mutable"))
      }
    "assign" =>
      match place_from_term(target) {
        Some(place) => Some(AssignMutableOperation(place))
        None => Some(InvalidTargetOperation("assign"))
      }
    "assign_immutable" =>
      match place_from_term(target) {
        Some(place) => Some(AssignImmutableOperation(place))
        None => Some(InvalidTargetOperation("assign_immutable"))
      }
    "assign_const" =>
      match place_from_term(target) {
        Some(place) => Some(AssignImmutableOperation(place))
        None => Some(InvalidTargetOperation("assign_const"))
      }
    _ => None
  }
}

///|
fn borrow_operation_from_term(term : Term) -> BorrowOperation? {
  match term {
    BorrowShared(target) =>
      match place_from_term(target) {
        Some(place) => Some(BorrowSharedOperation(place))
        None => Some(InvalidTargetOperation("borrow_shared"))
      }
    BorrowMut(target) =>
      match place_from_term(target) {
        Some(place) => Some(BorrowMutOperation(place))
        None => Some(InvalidTargetOperation("borrow_mut"))
      }
    Deref(target) =>
      match place_from_term(target) {
        Some(place) => Some(UseOperation(place))
        None => Some(InvalidTargetOperation("deref"))
      }
    Assign(target, _value) =>
      match place_from_term(target) {
        Some(place) => Some(AssignMutableOperation(place))
        None => Some(InvalidTargetOperation("assign"))
      }
    Move(target) =>
      match place_from_term(target) {
        Some(place) => Some(MoveOperation(place))
        None => Some(InvalidTargetOperation("move"))
      }
    Con(name, _) =>
      match parse_borrow_operation_from_constructor_name(name) {
        Some(operation) => Some(operation)
        None => borrow_operation_from_intrinsic_name(name)
      }
    Var(name) => borrow_operation_from_intrinsic_name(name)
    App(App(callee, target), value) =>
      match intrinsic_name_from_term(callee) {
        Some(name) =>
          borrow_operation_from_intrinsic_binary_call(name, target, value)
        None => None
      }
    App(callee, target) =>
      match intrinsic_name_from_term(callee) {
        Some(name) => borrow_operation_from_intrinsic_unary_call(name, target)
        None => None
      }
    _ => None
  }
}

///|
fn owner_region_for_place(place : Place) -> Region {
  Region::named("owner::" + place.root)
}

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
fn place_key(place : Place) -> String {
  let mut key = place.root
  for projection in place.projections {
    match projection {
      Field(label) => key = key + "." + label
      TupleIndex(index) => key = key + "." + index.to_string()
      Deref => key = key + ".*"
    }
  }
  key
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
fn lower_tuple_projection_tuple_literal_into_ir(
  tuple_term : Term,
  elements : Array[Term],
  projected_index : Int,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  let tuple_id = next_id
  nodes.push(BorrowIrNode::{
    id: tuple_id,
    term: tuple_term,
    scope_depth: projection_scope_depth + 1,
  })
  let mut cursor = tuple_id + 1

  loop 0 {
    i if i < elements.length() => {
      let element_scope_depth = if i == projected_index {
        projection_scope_depth
      } else {
        projection_scope_depth + 1
      }
      cursor = lower_term_into_ir(
        elements[i],
        element_scope_depth,
        cursor,
        nodes,
      )
      continue i + 1
    }
    _ => ()
  }

  cursor
}

///|
fn let_body_alias_call_argument(body : Term, binder_name : String) -> Term? {
  match body {
    App(Var(call_name), arg) if call_name == binder_name => Some(arg)
    _ => None
  }
}

///|
fn lower_tuple_projection_passthrough_let_into_ir(
  tuple_term : Term,
  binder_name : String,
  tuple_value : Term,
  body : Term,
  projected_index : Int,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  let let_id = next_id
  nodes.push(BorrowIrNode::{
    id: let_id,
    term: tuple_term,
    scope_depth: projection_scope_depth + 1,
  })
  let mut cursor = let_id + 1

  let can_project_through_body = match body {
    Var(body_name) => body_name == binder_name
    _ => false
  }
  let alias_call_arg = let_body_alias_call_argument(body, binder_name)

  if can_project_through_body {
    cursor = lower_tuple_projection_source_into_ir(
      tuple_value, projected_index, projection_scope_depth, cursor, nodes,
    )
  } else {
    match alias_call_arg {
      Some(arg) =>
        cursor = lower_tuple_projection_source_into_ir(
          Term::app(tuple_value, arg),
          projected_index,
          projection_scope_depth,
          cursor,
          nodes,
        )
      None =>
        cursor = lower_term_into_ir(
          tuple_value,
          projection_scope_depth + 1,
          cursor,
          nodes,
        )
    }
  }

  cursor = lower_term_into_ir(body, projection_scope_depth + 1, cursor, nodes)
  cursor
}

///|
fn lower_tuple_projection_passthrough_match_into_ir(
  tuple_term : Term,
  scrutinee : Term,
  cases : Array[(Pattern, Term)],
  projected_index : Int,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  let match_id = next_id
  nodes.push(BorrowIrNode::{
    id: match_id,
    term: tuple_term,
    scope_depth: projection_scope_depth + 1,
  })
  let mut cursor = match_id + 1

  cursor = lower_term_into_ir(
    scrutinee,
    projection_scope_depth + 1,
    cursor,
    nodes,
  )
  for case_entry in cases {
    let (_, body_term) = case_entry
    cursor = lower_tuple_projection_source_into_ir(
      body_term, projected_index, projection_scope_depth, cursor, nodes,
    )
    nodes.push(BorrowIrNode::{
      id: cursor,
      term: borrow_ir_match_branch_boundary_term(),
      scope_depth: projection_scope_depth,
    })
    cursor = cursor + 1
  }

  cursor
}

///|
fn lower_tuple_projection_passthrough_lambda_app_into_ir(
  tuple_term : Term,
  callee : Term,
  arg : Term,
  projected_index : Int,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  match callee {
    Lam(_, _, body) => {
      let app_id = next_id
      nodes.push(BorrowIrNode::{
        id: app_id,
        term: tuple_term,
        scope_depth: projection_scope_depth + 1,
      })
      let mut cursor = app_id + 1
      cursor = lower_term_into_ir(
        arg,
        projection_scope_depth + 1,
        cursor,
        nodes,
      )
      cursor = lower_tuple_projection_source_into_ir(
        body, projected_index, projection_scope_depth, cursor, nodes,
      )
      cursor
    }
    _ =>
      lower_term_into_ir(tuple_term, projection_scope_depth + 1, next_id, nodes)
  }
}

///|
fn lower_tuple_projection_source_into_ir(
  tuple_term : Term,
  projected_index : Int,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  match tuple_term {
    Tuple(elements) =>
      lower_tuple_projection_tuple_literal_into_ir(
        tuple_term, elements, projected_index, projection_scope_depth, next_id, nodes,
      )
    Let(name, tuple_value, body) =>
      lower_tuple_projection_passthrough_let_into_ir(
        tuple_term, name, tuple_value, body, projected_index, projection_scope_depth,
        next_id, nodes,
      )
    Match(scrutinee, cases) =>
      lower_tuple_projection_passthrough_match_into_ir(
        tuple_term, scrutinee, cases, projected_index, projection_scope_depth, next_id,
        nodes,
      )
    App(callee, arg) =>
      lower_tuple_projection_passthrough_lambda_app_into_ir(
        tuple_term, callee, arg, projected_index, projection_scope_depth, next_id,
        nodes,
      )
    _ =>
      lower_term_into_ir(tuple_term, projection_scope_depth + 1, next_id, nodes)
  }
}

///|
fn lower_record_projection_record_literal_into_ir(
  record_term : Term,
  fields : Array[(String, Term)],
  selected_label : String,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  let record_id = next_id
  nodes.push(BorrowIrNode::{
    id: record_id,
    term: record_term,
    scope_depth: projection_scope_depth + 1,
  })
  let mut cursor = record_id + 1

  for field_entry in fields {
    let (label, field_term) = field_entry
    let field_scope_depth = if label == selected_label {
      projection_scope_depth
    } else {
      projection_scope_depth + 1
    }
    cursor = lower_term_into_ir(field_term, field_scope_depth, cursor, nodes)
  }

  cursor
}

///|
fn lower_record_projection_passthrough_let_into_ir(
  record_term : Term,
  binder_name : String,
  record_value : Term,
  body : Term,
  selected_label : String,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  let let_id = next_id
  nodes.push(BorrowIrNode::{
    id: let_id,
    term: record_term,
    scope_depth: projection_scope_depth + 1,
  })
  let mut cursor = let_id + 1

  let can_project_through_body = match body {
    Var(body_name) => body_name == binder_name
    _ => false
  }
  let alias_call_arg = let_body_alias_call_argument(body, binder_name)

  if can_project_through_body {
    cursor = lower_record_projection_source_into_ir(
      record_value, selected_label, projection_scope_depth, cursor, nodes,
    )
  } else {
    match alias_call_arg {
      Some(arg) =>
        cursor = lower_record_projection_source_into_ir(
          Term::app(record_value, arg),
          selected_label,
          projection_scope_depth,
          cursor,
          nodes,
        )
      None =>
        cursor = lower_term_into_ir(
          record_value,
          projection_scope_depth + 1,
          cursor,
          nodes,
        )
    }
  }

  cursor = lower_term_into_ir(body, projection_scope_depth + 1, cursor, nodes)
  cursor
}

///|
fn lower_record_projection_passthrough_match_into_ir(
  record_term : Term,
  scrutinee : Term,
  cases : Array[(Pattern, Term)],
  selected_label : String,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  let match_id = next_id
  nodes.push(BorrowIrNode::{
    id: match_id,
    term: record_term,
    scope_depth: projection_scope_depth + 1,
  })
  let mut cursor = match_id + 1

  cursor = lower_term_into_ir(
    scrutinee,
    projection_scope_depth + 1,
    cursor,
    nodes,
  )
  for case_entry in cases {
    let (_, body_term) = case_entry
    cursor = lower_record_projection_source_into_ir(
      body_term, selected_label, projection_scope_depth, cursor, nodes,
    )
    nodes.push(BorrowIrNode::{
      id: cursor,
      term: borrow_ir_match_branch_boundary_term(),
      scope_depth: projection_scope_depth,
    })
    cursor = cursor + 1
  }

  cursor
}

///|
fn lower_record_projection_passthrough_lambda_app_into_ir(
  record_term : Term,
  callee : Term,
  arg : Term,
  selected_label : String,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  match callee {
    Lam(_, _, body) => {
      let app_id = next_id
      nodes.push(BorrowIrNode::{
        id: app_id,
        term: record_term,
        scope_depth: projection_scope_depth + 1,
      })
      let mut cursor = app_id + 1
      cursor = lower_term_into_ir(
        arg,
        projection_scope_depth + 1,
        cursor,
        nodes,
      )
      cursor = lower_record_projection_source_into_ir(
        body, selected_label, projection_scope_depth, cursor, nodes,
      )
      cursor
    }
    _ =>
      lower_term_into_ir(
        record_term,
        projection_scope_depth + 1,
        next_id,
        nodes,
      )
  }
}

///|
fn lower_record_projection_source_into_ir(
  record_term : Term,
  selected_label : String,
  projection_scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  match record_term {
    Record(fields) =>
      lower_record_projection_record_literal_into_ir(
        record_term, fields, selected_label, projection_scope_depth, next_id, nodes,
      )
    Let(name, record_value, body) =>
      lower_record_projection_passthrough_let_into_ir(
        record_term, name, record_value, body, selected_label, projection_scope_depth,
        next_id, nodes,
      )
    Match(scrutinee, cases) =>
      lower_record_projection_passthrough_match_into_ir(
        record_term, scrutinee, cases, selected_label, projection_scope_depth, next_id,
        nodes,
      )
    App(callee, arg) =>
      lower_record_projection_passthrough_lambda_app_into_ir(
        record_term, callee, arg, selected_label, projection_scope_depth, next_id,
        nodes,
      )
    _ =>
      lower_term_into_ir(
        record_term,
        projection_scope_depth + 1,
        next_id,
        nodes,
      )
  }
}

///|
fn lower_term_into_ir(
  term : Term,
  scope_depth : Int,
  next_id : Int,
  nodes : Array[BorrowIrNode],
) -> Int {
  let id = next_id
  nodes.push(BorrowIrNode::{ id, term, scope_depth })
  let mut cursor = id + 1

  match term {
    Var(_) => ()
    Con(_, _) => ()
    Lam(_, _, body) =>
      cursor = lower_term_into_ir(body, scope_depth + 1, cursor, nodes)
    App(callee, arg) => {
      cursor = lower_term_into_ir(callee, scope_depth + 1, cursor, nodes)
      cursor = lower_term_into_ir(arg, scope_depth + 1, cursor, nodes)
    }
    BorrowShared(target) =>
      cursor = lower_term_into_ir(target, scope_depth + 1, cursor, nodes)
    BorrowMut(target) =>
      cursor = lower_term_into_ir(target, scope_depth + 1, cursor, nodes)
    Deref(inner) =>
      cursor = lower_term_into_ir(inner, scope_depth + 1, cursor, nodes)
    Assign(target, value) => {
      cursor = lower_term_into_ir(target, scope_depth + 1, cursor, nodes)
      cursor = lower_term_into_ir(value, scope_depth + 1, cursor, nodes)
    }
    Move(inner) =>
      cursor = lower_term_into_ir(inner, scope_depth + 1, cursor, nodes)
    Let(_, value, body) => {
      cursor = lower_term_into_ir(value, scope_depth + 1, cursor, nodes)
      cursor = lower_term_into_ir(body, scope_depth + 1, cursor, nodes)
    }
    TyLam(_, _, body) =>
      cursor = lower_term_into_ir(body, scope_depth + 1, cursor, nodes)
    TyApp(value, _) =>
      cursor = lower_term_into_ir(value, scope_depth + 1, cursor, nodes)
    Dict(_, _, methods) =>
      for method_entry in methods {
        let (_, method_term) = method_entry
        cursor = lower_term_into_ir(method_term, scope_depth + 1, cursor, nodes)
      }
    TraitLam(_, _, _, _, _, body) =>
      cursor = lower_term_into_ir(body, scope_depth + 1, cursor, nodes)
    TraitApp(value, _, dicts) => {
      cursor = lower_term_into_ir(value, scope_depth + 1, cursor, nodes)
      for dict_term in dicts {
        cursor = lower_term_into_ir(dict_term, scope_depth + 1, cursor, nodes)
      }
    }
    TraitMethod(dict_term, _) =>
      cursor = lower_term_into_ir(dict_term, scope_depth + 1, cursor, nodes)
    Record(fields) =>
      for field_entry in fields {
        let (_, field_term) = field_entry
        cursor = lower_term_into_ir(field_term, scope_depth + 1, cursor, nodes)
      }
    Project(record_term, label) =>
      cursor = lower_record_projection_source_into_ir(
        record_term, label, scope_depth, cursor, nodes,
      )
    Inject(_, value_term, _) =>
      cursor = lower_term_into_ir(value_term, scope_depth + 1, cursor, nodes)
    Match(scrutinee, cases) => {
      cursor = lower_term_into_ir(scrutinee, scope_depth + 1, cursor, nodes)
      for case_entry in cases {
        let (_, body_term) = case_entry
        cursor = lower_term_into_ir(body_term, scope_depth + 1, cursor, nodes)
        // Boundary node at parent scope separates sibling branches.
        nodes.push(BorrowIrNode::{
          id: cursor,
          term: borrow_ir_match_branch_boundary_term(),
          scope_depth,
        })
        cursor = cursor + 1
      }
    }
    Fold(_, inner_term) =>
      cursor = lower_term_into_ir(inner_term, scope_depth + 1, cursor, nodes)
    Unfold(inner_term) =>
      cursor = lower_term_into_ir(inner_term, scope_depth + 1, cursor, nodes)
    Tuple(elements) =>
      for element in elements {
        cursor = lower_term_into_ir(element, scope_depth + 1, cursor, nodes)
      }
    TupleProject(tuple_term, index) =>
      cursor = lower_tuple_projection_source_into_ir(
        tuple_term, index, scope_depth, cursor, nodes,
      )
  }
  cursor
}

///|
fn add_outlives_edge(
  outlives : Map[Region, Set[Region]],
  left : Region,
  right : Region,
) -> Bool {
  let tos = match outlives.get(left) {
    Some(existing) => existing
    None => {
      let created : Set[Region] = Set::new()
      outlives.set(left, created)
      created
    }
  }

  if tos.contains(right) {
    return false
  }

  tos.add(right)
  true
}

///|
fn solution_has_outlives_edge(
  solved : RegionSolution,
  from : Region,
  to : Region,
) -> Bool {
  match solved.outlives.get(from) {
    Some(tos) => tos.contains(to)
    None => false
  }
}

///|
fn solution_satisfies_region_constraint(
  solved : RegionSolution,
  constraint : RegionConstraint,
) -> Bool {
  match constraint {
    Outlives(from, to) => solution_has_outlives_edge(solved, from, to)
    Equal(left, right) =>
      solution_has_outlives_edge(solved, left, right) &&
      solution_has_outlives_edge(solved, right, left)
    Placeholder(_) => false
  }
}

///|
fn solve_outlives_transitively(
  outlives : Map[Region, Set[Region]],
) -> Map[Region, Set[Region]] {
  let mut changed = true
  while changed {
    changed = false

    let snapshot : Array[(Region, Array[Region])] = []
    for entry in outlives {
      let (from, tos) = entry
      snapshot.push((from, tos.to_array()))
    }

    for entry in snapshot {
      let (from, mids) = entry
      for mid in mids {
        match outlives.get(mid) {
          Some(mid_tos) =>
            for target in mid_tos {
              if add_outlives_edge(outlives, from, target) {
                changed = true
              }
            }
          None => ()
        }
      }
    }
  }
  outlives
}

///|
/// Description: Constructs shared mutability marker.
/// Example: `let _ = Mutability::shared()`
pub fn Mutability::shared() -> Mutability {
  Shared
}

///|
/// Description: Constructs mutable mutability marker.
/// Example: `let _ = Mutability::mutable()`
pub fn Mutability::mutable() -> Mutability {
  Mutable
}

///|
/// Description: Constructs a named region.
/// Example: `let _ = Region::named("r")`
pub fn Region::named(name : String) -> Region {
  Named(name)
}

///|
/// Description: Constructs an inference region id.
/// Example: `let _ = Region::infer(0)`
pub fn Region::infer(id : Int) -> Region {
  Infer(id)
}

///|
/// Description: Constructs the static region.
/// Example: `let _ = Region::static_region()`
pub fn Region::static_region() -> Region {
  Static
}

///|
/// Description: Constructs a field place projection.
/// Example: `let _ = PlaceProjection::field("x")`
pub fn PlaceProjection::field(label : String) -> PlaceProjection {
  Field(label)
}

///|
/// Description: Constructs a tuple-index place projection.
/// Example: `let _ = PlaceProjection::tuple_index(0)`
pub fn PlaceProjection::tuple_index(index : Int) -> PlaceProjection {
  TupleIndex(index)
}

///|
/// Description: Constructs a dereference place projection.
/// Example: `let _ = PlaceProjection::deref_projection()`
pub fn PlaceProjection::deref_projection() -> PlaceProjection {
  Deref
}

///|
/// Description: Constructs a root place.
/// Example: `let _ = Place::root("x")`
pub fn Place::root(name : String) -> Place {
  Place::{ root: name, projections: [] }
}

///|
/// Description: Adds a field projection to a place.
/// Example: `let _ = Place::root("x").field("y")`
pub fn Place::field(self : Place, label : String) -> Place {
  Place::{
    root: self.root,
    projections: append_projection(self.projections, Field(label)),
  }
}

///|
/// Description: Adds a tuple-index projection to a place.
/// Example: `let _ = Place::root("x").tuple_index(0)`
pub fn Place::tuple_index(self : Place, index : Int) -> Place {
  Place::{
    root: self.root,
    projections: append_projection(self.projections, TupleIndex(index)),
  }
}

///|
/// Description: Adds a dereference projection to a place.
/// Example: `let _ = Place::root("x").deref_place()`
pub fn Place::deref_place(self : Place) -> Place {
  Place::{
    root: self.root,
    projections: append_projection(self.projections, Deref),
  }
}

///|
/// Description: Constructs an outlives region constraint.
/// Example: `let _ = RegionConstraint::outlives(Region::named("a"), Region::named("b"))`
pub fn RegionConstraint::outlives(
  left : Region,
  right : Region,
) -> RegionConstraint {
  Outlives(left, right)
}

///|
/// Description: Constructs a region-equality constraint.
/// Example: `let _ = RegionConstraint::equal(Region::infer(0), Region::infer(1))`
pub fn RegionConstraint::equal(
  left : Region,
  right : Region,
) -> RegionConstraint {
  Equal(left, right)
}

///|
/// Description: Constructs a placeholder region constraint for scaffold phases.
/// Example: `let _ = RegionConstraint::placeholder("...")`
pub fn RegionConstraint::placeholder(message : String) -> RegionConstraint {
  Placeholder(message)
}

///|
/// Description: Constructs borrow checker options with analysis enabled.
/// Example: `let _ = BorrowCheckerOptions::default()`
pub fn BorrowCheckerOptions::default() -> BorrowCheckerOptions {
  BorrowCheckerOptions::{ enabled: true, use_nll: false, diagnostics: true }
}

///|
/// Description: Constructs options with borrow analysis disabled.
/// Example: `let _ = BorrowCheckerOptions::disabled()`
pub fn BorrowCheckerOptions::disabled() -> BorrowCheckerOptions {
  BorrowCheckerOptions::{ enabled: false, use_nll: false, diagnostics: false }
}

///|
/// Description: Constructs an empty region solution.
/// Example: `let _ = RegionSolution::empty()`
pub fn RegionSolution::empty() -> RegionSolution {
  RegionSolution::{ outlives: Map::new(), unresolved: [] }
}

///|
/// Description: Constructs empty borrow facts.
/// Example: `let _ = BorrowFacts::empty()`
pub fn BorrowFacts::empty() -> BorrowFacts {
  BorrowFacts::{ loans: [], moved_places: Set::new(), constraints: [] }
}

///|
/// Description: Constructs an empty borrow analysis result.
/// Example: `let _ = BorrowAnalysisResult::empty()`
pub fn BorrowAnalysisResult::empty() -> BorrowAnalysisResult {
  BorrowAnalysisResult::{
    facts: BorrowFacts::empty(),
    solved: RegionSolution::empty(),
  }
}

///|
/// Description: Constructs a borrow "owned" scaffold type wrapper.
/// Example: `let _ = BorrowType::owned(Type::con("Int"))`
pub fn BorrowType::owned(ty : Type) -> BorrowType {
  Owned(ty)
}

///|
/// Description: Constructs a borrow reference scaffold type wrapper.
/// Example: `let _ = BorrowType::ref_type(Region::named("r"), Mutability::shared(), Type::con("Int"))`
pub fn BorrowType::ref_type(
  region : Region,
  mutability : Mutability,
  inner : Type,
) -> BorrowType {
  Ref(region, mutability, inner)
}

///|
/// Description: Constructs a shared-borrow scaffold term.
/// Example: `let _ = BorrowTerm::borrow_shared(Place::root("x"))`
pub fn BorrowTerm::borrow_shared(place : Place) -> BorrowTerm {
  BorrowShared(place)
}

///|
/// Description: Constructs a mutable-borrow scaffold term.
/// Example: `let _ = BorrowTerm::borrow_mut(Place::root("x"))`
pub fn BorrowTerm::borrow_mut(place : Place) -> BorrowTerm {
  BorrowMut(place)
}

///|
/// Description: Constructs a dereference scaffold term.
/// Example: `let _ = BorrowTerm::deref(Term::var_term("p"))`
pub fn BorrowTerm::deref(term : Term) -> BorrowTerm {
  Deref(term)
}

///|
/// Description: Constructs an assignment scaffold term.
/// Example: `let _ = BorrowTerm::assign(Place::root("x"), Term::unit())`
pub fn BorrowTerm::assign(place : Place, value : Term) -> BorrowTerm {
  Assign(place, value)
}

///|
/// Description: Constructs a move scaffold term.
/// Example: `let _ = BorrowTerm::move_term(Term::var_term("x"))`
pub fn BorrowTerm::move_term(term : Term) -> BorrowTerm {
  Move(term)
}

///|
/// Description: Lowers `Term` to borrow-analysis IR.
/// Example: `let _ = lower_to_borrow_ir(Term::unit())`
pub fn lower_to_borrow_ir(term : Term) -> Result[BorrowIr, TypingError] {
  let nodes : Array[BorrowIrNode] = []
  ignore(lower_term_into_ir(term, 0, 0, nodes))
  Ok(BorrowIr::{ nodes, })
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
/// Example: `let _ = solve_region_constraints_placeholder([])`
pub fn solve_region_constraints_placeholder(
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

///|
/// Description: Borrow-rule checker entry point for lowered IR.
/// Example: `let _ = check_borrow_rules_placeholder(BorrowIr::{ nodes: [] }, RegionSolution::empty(), BorrowCheckerOptions::default())`
pub fn check_borrow_rules_placeholder(
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

///|
/// Description: Placeholder API for collecting region constraints from a typed term.
/// Example: `let _ = TypeCheckerState::fresh().collect_region_constraints(Term::unit(), Type::unit())`
pub fn TypeCheckerState::collect_region_constraints(
  self : TypeCheckerState,
  term : Term,
  ty : Type,
) -> Result[Array[RegionConstraint], TypingError] {
  ignore(self)
  ignore(ty)
  let ir = match lower_to_borrow_ir(term) {
    Ok(ir) => ir
    Err(t) => return Err(t)
  }
  let constraints = match collect_region_constraints_from_ir(ir) {
    Ok(constraints) => constraints
    Err(t) => return Err(t)
  }

  Ok(constraints)
}

///|
/// Description: Placeholder API for solving region constraints.
/// Example: `let _ = TypeCheckerState::fresh().solve_region_constraints([])`
pub fn TypeCheckerState::solve_region_constraints(
  self : TypeCheckerState,
  constraints : Array[RegionConstraint],
) -> Result[RegionSolution, TypingError] {
  ignore(self)
  solve_region_constraints_placeholder(constraints)
}

///|
/// Description: Placeholder API for borrow-rule checking after region solving.
/// Example: `let _ = TypeCheckerState::fresh().check_borrow_rules(Term::unit(), RegionSolution::empty(), BorrowCheckerOptions::default())`
pub fn TypeCheckerState::check_borrow_rules(
  self : TypeCheckerState,
  term : Term,
  solved : RegionSolution,
  options : BorrowCheckerOptions,
) -> Result[BorrowFacts, TypingError] {
  ignore(self)
  let ir = match lower_to_borrow_ir(term) {
    Ok(ir) => ir
    Err(t) => return Err(t)
  }
  check_borrow_rules_placeholder(ir, solved, options)
}

///|
/// Description: Placeholder orchestration API for borrow + lifetime analysis.
/// Example: `let _ = TypeCheckerState::fresh().analyze_borrows(Term::unit(), Type::unit(), BorrowCheckerOptions::default())`
pub fn TypeCheckerState::analyze_borrows(
  self : TypeCheckerState,
  term : Term,
  ty : Type,
  options : BorrowCheckerOptions,
) -> Result[BorrowAnalysisResult, TypingError] {
  if !options.enabled {
    return Ok(BorrowAnalysisResult::empty())
  }

  let constraints = match self.collect_region_constraints(term, ty) {
    Ok(constraints) => constraints
    Err(t) => return Err(t)
  }
  let solved = match self.solve_region_constraints(constraints) {
    Ok(solved) => solved
    Err(t) => return Err(t)
  }

  let facts = match self.check_borrow_rules(term, solved, options) {
    Ok(facts) => facts
    Err(t) => return Err(t)
  }

  Ok(BorrowAnalysisResult::{ facts, solved })
}

///|
/// Description: Placeholder wrapper that keeps legacy inference unchanged when disabled.
/// Example: `let _ = TypeCheckerState::fresh().infer_type_with_borrow_analysis(Term::unit(), BorrowCheckerOptions::disabled())`
pub fn TypeCheckerState::infer_type_with_borrow_analysis(
  self : TypeCheckerState,
  term : Term,
  options : BorrowCheckerOptions,
) -> Result[Type, TypingError] {
  if !options.enabled {
    return self.infer_type(term)
  }

  let inferred_with_native_flag = match
    infer_type_with_native_policy_flag(self, term) {
    Ok(result) => result
    Err(t) => return Err(t)
  }
  let inferred = inferred_with_native_flag.0
  if inferred_with_native_flag.1 {
    return Ok(inferred)
  }

  match self.analyze_borrows(term, inferred, options) {
    Ok(_) => Ok(inferred)
    Err(t) => Err(t)
  }
}

///|
/// Description: Placeholder wrapper that keeps legacy checking unchanged when disabled.
/// Example: `let _ = TypeCheckerState::fresh().check_type_with_borrow_analysis(Term::unit(), Type::unit(), BorrowCheckerOptions::disabled())`
pub fn TypeCheckerState::check_type_with_borrow_analysis(
  self : TypeCheckerState,
  term : Term,
  expected : Type,
  options : BorrowCheckerOptions,
) -> Result[CheckedType, TypingError] {
  if !options.enabled {
    return self.check_type(term, expected)
  }

  let checked_with_native_flag = match
    check_type_with_native_policy_flag(self, term, expected) {
    Ok(result) => result
    Err(t) => return Err(t)
  }
  let checked = checked_with_native_flag.0
  if checked_with_native_flag.1 {
    return Ok(checked)
  }

  match self.analyze_borrows(term, checked.ty, options) {
    Ok(_) => Ok(checked)
    Err(t) => Err(t)
  }
}
