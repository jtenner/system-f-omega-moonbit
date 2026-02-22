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
priv enum BorrowOperation {
  BorrowSharedOperation(Place)
  BorrowMutOperation(Place)
  MoveOperation(Place)
  UseOperation(Place)
  AssignMutableOperation(Place)
  AssignImmutableOperation(Place)
  ReleaseOperation(Place)
  InvalidTargetOperation(String)
  RegionOutlivesOwnerOperation
  RegionDanglingEscapeOperation
  RegionUnsatisfiedOperation
}

///|
fn parse_borrow_operation_from_constructor_name(
  constructor_name : String,
) -> BorrowOperation? {
  match constructor_name {
    "BorrowOpBorrowSharedX" => Some(BorrowSharedOperation(Place::root("x")))
    "BorrowOpBorrowSharedXField" =>
      Some(BorrowSharedOperation(Place::root("x").field("field")))
    "BorrowOpBorrowSharedY" => Some(BorrowSharedOperation(Place::root("y")))
    "BorrowOpBorrowMutX" => Some(BorrowMutOperation(Place::root("x")))
    "BorrowOpBorrowMutXField" =>
      Some(BorrowMutOperation(Place::root("x").field("field")))
    "BorrowOpMoveX" => Some(MoveOperation(Place::root("x")))
    "BorrowOpMoveXField" => Some(MoveOperation(Place::root("x").field("field")))
    "BorrowOpUseX" => Some(UseOperation(Place::root("x")))
    "BorrowOpUseXField" => Some(UseOperation(Place::root("x").field("field")))
    "BorrowOpUseY" => Some(UseOperation(Place::root("y")))
    "BorrowOpAssignMutableX" => Some(AssignMutableOperation(Place::root("x")))
    "BorrowOpAssignImmutableX" =>
      Some(AssignImmutableOperation(Place::root("x")))
    "BorrowOpReleaseX" => Some(ReleaseOperation(Place::root("x")))
    "BorrowOpInvalidTarget" =>
      Some(InvalidTargetOperation("BorrowOpInvalidTarget"))
    "BorrowOpRegionOutlivesOwner" => Some(RegionOutlivesOwnerOperation)
    "BorrowOpRegionDanglingEscape" => Some(RegionDanglingEscapeOperation)
    "BorrowOpRegionUnsatisfied" => Some(RegionUnsatisfiedOperation)
    _ =>
      parse_generalized_borrow_operation_from_constructor_name(constructor_name)
  }
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
    Fold(_, inner) => place_from_term(inner)
    Unfold(inner) => place_from_term(inner)
    _ => None
  }
}

///|
fn borrow_operation_from_intrinsic_name(name : String) -> BorrowOperation? {
  match name {
    "region_outlives_owner" => Some(RegionOutlivesOwnerOperation)
    "region_dangling_escape" => Some(RegionDanglingEscapeOperation)
    "region_unsatisfied" => Some(RegionUnsatisfiedOperation)
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
    "region_outlives_owner" => Some(RegionOutlivesOwnerOperation)
    "region_dangling_escape" => Some(RegionDanglingEscapeOperation)
    "region_unsatisfied" => Some(RegionUnsatisfiedOperation)
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
    RegionOutlivesOwnerOperation =>
      Some(RegionConstraint::placeholder("__err_borrow_outlives_owner"))
    RegionDanglingEscapeOperation =>
      Some(RegionConstraint::placeholder("__err_dangling_reference_escape"))
    RegionUnsatisfiedOperation =>
      Some(RegionConstraint::placeholder("__err_region_constraint_unsatisfied"))
    _ => None
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
    Project(record_term, _) =>
      cursor = lower_term_into_ir(record_term, scope_depth + 1, cursor, nodes)
    Inject(_, value_term, _) =>
      cursor = lower_term_into_ir(value_term, scope_depth + 1, cursor, nodes)
    Match(scrutinee, cases) => {
      cursor = lower_term_into_ir(scrutinee, scope_depth + 1, cursor, nodes)
      for case_entry in cases {
        let (_, body_term) = case_entry
        cursor = lower_term_into_ir(body_term, scope_depth + 1, cursor, nodes)
        // Boundary node at parent scope separates sibling branches.
        nodes.push(BorrowIrNode::{ id: cursor, term: Term::unit(), scope_depth })
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
    TupleProject(tuple_term, _) =>
      cursor = lower_term_into_ir(tuple_term, scope_depth + 1, cursor, nodes)
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
fn collect_known_region_probe_errors(
  constraints : Array[RegionConstraint],
) -> Result[Unit, TypingError] {
  let mut saw_outlives_owner = false
  let mut saw_dangling_escape = false
  let mut saw_unsatisfied = false

  for constraint in constraints {
    match constraint {
      Placeholder("__err_borrow_outlives_owner") => saw_outlives_owner = true
      Placeholder("__err_dangling_reference_escape") =>
        saw_dangling_escape = true
      Placeholder("__err_region_constraint_unsatisfied") =>
        saw_unsatisfied = true
      _ => ()
    }
  }

  if saw_outlives_owner {
    return Err(
      BorrowOutlivesOwner("region placeholder: __err_borrow_outlives_owner"),
    )
  }
  if saw_dangling_escape {
    return Err(
      DanglingReferenceEscape(
        "region placeholder: __err_dangling_reference_escape",
      ),
    )
  }
  if saw_unsatisfied {
    return Err(
      RegionConstraintUnsatisfied(
        RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
      ),
    )
  }

  Ok(())
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
  let scope_stack : Array[Int] = []

  for node in ir.nodes {
    let mut depth = node.scope_depth
    if depth < 0 {
      depth = 0
    }
    if depth > scope_stack.length() {
      depth = scope_stack.length()
    }

    while scope_stack.length() > depth {
      ignore(scope_stack.pop())
    }

    if depth > 0 && scope_stack.length() > 0 {
      let parent_id = scope_stack[scope_stack.length() - 1]
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

    scope_stack.push(node.id)
  }

  Ok(constraints)
}

///|
/// Description: Solves region constraints with equality expansion and transitive closure.
/// Example: `let _ = solve_region_constraints_placeholder([])`
pub fn solve_region_constraints_placeholder(
  constraints : Array[RegionConstraint],
) -> Result[RegionSolution, TypingError] {
  match collect_known_region_probe_errors(constraints) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }

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
  let mut next_loan_id = 0

  for node in ir.nodes {
    let mut scope_depth = node.scope_depth
    if scope_depth < 0 {
      scope_depth = 0
    }
    release_loans_outside_lexical_scope(loans, loan_scope_depths, scope_depth)

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
      Some(MoveOperation(place)) => {
        moved_places.push(place)
        moved_place_keys.add(place_key(place))
      }
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
      Some(RegionOutlivesOwnerOperation) =>
        constraints.push(
          RegionConstraint::placeholder("__err_borrow_outlives_owner"),
        )
      Some(RegionDanglingEscapeOperation) =>
        constraints.push(
          RegionConstraint::placeholder("__err_dangling_reference_escape"),
        )
      Some(RegionUnsatisfiedOperation) =>
        constraints.push(
          RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
        )
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

  let inferred = match self.infer_type(term) {
    Ok(ty) => ty
    Err(t) => return Err(t)
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

  let checked = match self.check_type(term, expected) {
    Ok(checked) => checked
    Err(t) => return Err(t)
  }

  match self.analyze_borrows(term, checked.ty, options) {
    Ok(_) => Ok(checked)
    Err(t) => Err(t)
  }
}
