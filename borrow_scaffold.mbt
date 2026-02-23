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
fn alias_passthrough_value_rebinds(value : Term, binder_name : String) -> Bool {
  match value {
    Var(source_name) => source_name == binder_name
    Lam(param_name, _, body_term) =>
      match body_term {
        App(Var(source_name), Var(forwarded_name)) =>
          source_name == binder_name && forwarded_name == param_name
        _ => false
      }
    _ => false
  }
}

///|
fn let_body_alias_call_argument(body : Term, binder_name : String) -> Term? {
  match body {
    App(Var(call_name), arg) if call_name == binder_name => Some(arg)
    Let(next_alias_name, alias_value, next_body) =>
      if alias_passthrough_value_rebinds(alias_value, binder_name) {
        let_body_alias_call_argument(next_body, next_alias_name)
      } else {
        None
      }
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
/// Description: Converts borrow/lifetime typing errors into structured actionable payloads.
/// Example: `let _ = UseAfterMove("x").borrow_payload()`
pub fn TypingError::borrow_payload(self : TypingError) -> BorrowErrorPayload? {
  match self {
    UseAfterMove(path) =>
      Some(BorrowErrorPayload::{
        error_kind: "UseAfterMove",
        operation: Some("use"),
        place: place_from_key_path(path),
        place_path: Some(path),
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: None,
        details: None,
      })
    MovedValueBorrow(path) =>
      Some(BorrowErrorPayload::{
        error_kind: "MovedValueBorrow",
        operation: Some("borrow"),
        place: place_from_key_path(path),
        place_path: Some(path),
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: None,
        details: None,
      })
    BorrowConflict(active_loan_place, requested_place) => {
      let active_loan_place_path = place_key(active_loan_place)
      let requested_place_path = place_key(requested_place)
      Some(BorrowErrorPayload::{
        error_kind: "BorrowConflict",
        operation: Some("borrow"),
        place: Some(requested_place),
        place_path: Some(requested_place_path),
        active_loan_place_path: Some(active_loan_place_path),
        requested_place_path: Some(requested_place_path),
        conflict: Some(BorrowConflictPayload::{
          active_loan_place,
          active_loan_place_path,
          requested_place,
          requested_place_path,
        }),
        region_constraint: None,
        details: None,
      })
    }
    MutateWhileBorrowed(place) => {
      let path = place_key(place)
      Some(BorrowErrorPayload::{
        error_kind: "MutateWhileBorrowed",
        operation: Some("assign_mutable"),
        place: Some(place),
        place_path: Some(path),
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: None,
        details: None,
      })
    }
    AssignToImmutable(place) => {
      let path = place_key(place)
      Some(BorrowErrorPayload::{
        error_kind: "AssignToImmutable",
        operation: Some("assign_immutable"),
        place: Some(place),
        place_path: Some(path),
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: None,
        details: None,
      })
    }
    BorrowOutlivesOwner(path) =>
      Some(BorrowErrorPayload::{
        error_kind: "BorrowOutlivesOwner",
        operation: Some("borrow_outlives_owner"),
        place: place_from_key_path(path),
        place_path: Some(path),
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: None,
        details: None,
      })
    DanglingReferenceEscape(path) =>
      Some(BorrowErrorPayload::{
        error_kind: "DanglingReferenceEscape",
        operation: Some("dangling_reference_escape"),
        place: place_from_key_path(path),
        place_path: Some(path),
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: None,
        details: None,
      })
    InvalidBorrowTarget(details) =>
      Some(BorrowErrorPayload::{
        error_kind: "InvalidBorrowTarget",
        operation: match invalid_target_operation_from_details(details) {
          Some(operation) => Some(operation)
          None => Some("invalid_target")
        },
        place: None,
        place_path: None,
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: None,
        details: Some(details),
      })
    RegionConstraintUnsatisfied(constraint) =>
      Some(BorrowErrorPayload::{
        error_kind: "RegionConstraintUnsatisfied",
        operation: Some("region_constraint"),
        place: None,
        place_path: None,
        active_loan_place_path: None,
        requested_place_path: None,
        conflict: None,
        region_constraint: Some(constraint),
        details: None,
      })
    _ => None
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
/// Description: API for collecting region constraints from a typed term.
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
/// Description: API for solving region constraints.
/// Example: `let _ = TypeCheckerState::fresh().solve_region_constraints([])`
pub fn TypeCheckerState::solve_region_constraints(
  self : TypeCheckerState,
  constraints : Array[RegionConstraint],
) -> Result[RegionSolution, TypingError] {
  ignore(self)
  solve_region_constraints_ir(constraints)
}

///|
/// Description: API for borrow-rule checking after region solving.
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
  check_borrow_rules_ir(ir, solved, options)
}

///|
/// Description: Orchestration API for borrow + lifetime analysis.
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
/// Description: Wrapper that keeps legacy inference unchanged when disabled.
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
/// Description: Wrapper that keeps legacy checking unchanged when disabled.
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
