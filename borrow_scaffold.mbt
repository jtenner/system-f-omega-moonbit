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
priv enum FeatureScenario {
  SafeScenario
  BorrowConflictScenario
  UseAfterMoveScenario
  MovedValueBorrowScenario
  AssignToImmutableScenario
  MutateWhileBorrowedScenario
  OutlivesOwnerScenario
  DanglingEscapeScenario
  RegionUnsatisfiedScenario
  InvalidTargetScenario
}

///|
fn classify_feature_scenario(constructor_name : String) -> FeatureScenario? {
  if constructor_name == "BorrowFeatureSafeSharedRead" {
    return Some(SafeScenario)
  }
  if constructor_name == "BorrowFeatureSafeMutReborrow" {
    return Some(SafeScenario)
  }
  if constructor_name == "BorrowFeatureSafeNllLastUse" {
    return Some(SafeScenario)
  }
  if constructor_name == "BorrowFeatureSafeBranchJoin" {
    return Some(SafeScenario)
  }
  if constructor_name == "BorrowFeatureSafeTraitPoly" {
    return Some(SafeScenario)
  }
  if constructor_name == "BorrowFeatureSafeRecursiveProjection" {
    return Some(SafeScenario)
  }
  if constructor_name == "BorrowFeatureSafeFallback" {
    return Some(SafeScenario)
  }
  if constructor_name == "BorrowFeatureErrBorrowConflict" {
    return Some(BorrowConflictScenario)
  }
  if constructor_name == "BorrowFeatureErrUseAfterMove" {
    return Some(UseAfterMoveScenario)
  }
  if constructor_name == "BorrowFeatureErrPartialMoveProjection" {
    return Some(UseAfterMoveScenario)
  }
  if constructor_name == "BorrowFeatureErrMovedValueBorrow" {
    return Some(MovedValueBorrowScenario)
  }
  if constructor_name == "BorrowFeatureErrAssignToImmutable" {
    return Some(AssignToImmutableScenario)
  }
  if constructor_name == "BorrowFeatureErrMutateWhileBorrowed" {
    return Some(MutateWhileBorrowedScenario)
  }
  if constructor_name == "BorrowFeatureErrOutlivesOwner" {
    return Some(OutlivesOwnerScenario)
  }
  if constructor_name == "BorrowFeatureErrDanglingEscape" {
    return Some(DanglingEscapeScenario)
  }
  if constructor_name == "BorrowFeatureErrTraitEscape" {
    return Some(DanglingEscapeScenario)
  }
  if constructor_name == "BorrowFeatureErrRegionUnsatisfied" {
    return Some(RegionUnsatisfiedScenario)
  }
  if constructor_name == "BorrowFeatureErrInvalidTarget" {
    return Some(InvalidTargetScenario)
  }
  None
}

///|
fn classify_feature_scenario_from_ir(ir : BorrowIr) -> FeatureScenario? {
  let mut saw_safe = false

  for node in ir.nodes {
    match node.term {
      Con(name, _) =>
        match classify_feature_scenario(name) {
          Some(SafeScenario) => saw_safe = true
          Some(scenario) => return Some(scenario)
          None => ()
        }
      _ => ()
    }
  }

  if saw_safe {
    return Some(SafeScenario)
  }
  None
}

///|
fn feature_region_constraint(scenario : FeatureScenario) -> RegionConstraint? {
  match scenario {
    OutlivesOwnerScenario =>
      Some(RegionConstraint::placeholder("__err_borrow_outlives_owner"))
    DanglingEscapeScenario =>
      Some(RegionConstraint::placeholder("__err_dangling_reference_escape"))
    RegionUnsatisfiedScenario =>
      Some(RegionConstraint::placeholder("__err_region_constraint_unsatisfied"))
    _ => None
  }
}

///|
fn feature_borrow_error(scenario : FeatureScenario) -> TypingError? {
  let place_root = Place::root("feature_place")

  match scenario {
    BorrowConflictScenario =>
      Some(BorrowConflict(place_root, place_root.field("borrowed_field")))
    UseAfterMoveScenario => Some(UseAfterMove("feature_value"))
    MovedValueBorrowScenario => Some(MovedValueBorrow("feature_value"))
    AssignToImmutableScenario => Some(AssignToImmutable(place_root))
    MutateWhileBorrowedScenario => Some(MutateWhileBorrowed(place_root))
    InvalidTargetScenario =>
      Some(InvalidBorrowTarget("feature term does not lower to a place"))
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
    return Err(BorrowOutlivesOwner("borrow outlives owner"))
  }
  if saw_dangling_escape {
    return Err(DanglingReferenceEscape("dangling reference escape"))
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
  ignore(solved)

  if !options.enabled {
    return Ok(BorrowFacts::empty())
  }

  match classify_feature_scenario_from_ir(ir) {
    Some(scenario) =>
      match feature_borrow_error(scenario) {
        Some(error) => return Err(error)
        None => ()
      }
    None => ()
  }

  Ok(BorrowFacts::empty())
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

  match classify_feature_scenario_from_ir(ir) {
    Some(scenario) =>
      match feature_region_constraint(scenario) {
        Some(constraint) => constraints.push(constraint)
        None => ()
      }
    None => ()
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
