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
fn intrinsic_name_from_term(term : Term) -> String? {
  match term {
    Var(name) => Some(name)
    Con(name, _) => Some(name)
    TyApp(inner, _) => intrinsic_name_from_term(inner)
    _ => None
  }
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
                Region::named("region::" + place.key_path()),
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
pub fn Place::key_path(self : Place) -> String {
  let mut key = self.root
  for projection in self.projections {
    match projection {
      Field(label) => key = key + "." + label
      TupleIndex(index) => key = key + "." + index.to_string()
      Deref => key = key + ".*"
    }
  }
  key
}

///|
pub fn Place::from_key_path(path : String) -> Place? {
  if path.is_empty() {
    return None
  }

  let tokens = path.split(".").map(StringView::to_string).collect()
  if tokens.length() == 0 || tokens[0].is_empty() {
    return None
  }

  let mut place = Place::root(tokens[0])
  let mut index = 1
  while index < tokens.length() {
    let token = tokens[index]
    if token.is_empty() {
      return None
    }
    if token == "*" {
      place = place.deref_place()
      index = index + 1
      continue
    }
    match parse_tuple_index_token(token) {
      Some(tuple_index) => place = place.tuple_index(tuple_index)
      None => place = place.field(token)
    }
    index = index + 1
  }

  Some(place)
}

///|
/// Description: Lowers `Term` to borrow-analysis IR.
/// Example: `let _ = lower_to_borrow_ir(Term::unit())`
pub fn lower_to_borrow_ir(term : Term) -> Result[BorrowIr, TypingError] {
  let nodes : Array[BorrowIrNode] = []
  ignore(lower_term_into_ir(term, 0, 0, nodes))
  Ok(BorrowIr::{ nodes, })
}
