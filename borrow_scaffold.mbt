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
fn probe_tag_from_term(term : Term) -> String? {
  match term {
    Con(name, _) => Some(name)
    _ => None
  }
}

///|
fn probe_ir_for_term(term : Term) -> BorrowIr {
  BorrowIr::{ nodes: [BorrowIrNode::{ id: 0, term, scope_depth: 0 }] }
}

///|
fn probe_tag_from_ir(ir : BorrowIr) -> String? {
  match ir.nodes {
    [first, ..] => probe_tag_from_term(first.term)
    _ => None
  }
}

///|
fn probe_place(label : String) -> Place {
  Place::root(label)
}

///|
fn contains_region_probe(
  constraints : Array[RegionConstraint],
  expected : String,
) -> Bool {
  for c in constraints {
    if c is Placeholder(actual) && actual == expected {
      return true
    }
  }
  false
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
/// Description: Placeholder lowering from `Term` to borrow-analysis IR.
/// Example: `let _ = lower_to_borrow_ir(Term::unit())`
pub fn lower_to_borrow_ir(term : Term) -> Result[BorrowIr, TypingError] {
  match probe_tag_from_term(term) {
    Some("__ok_borrow") => Ok(probe_ir_for_term(term))
    Some("__err_use_after_move") => Ok(probe_ir_for_term(term))
    Some("__err_moved_value_borrow") => Ok(probe_ir_for_term(term))
    Some("__err_borrow_conflict") => Ok(probe_ir_for_term(term))
    Some("__err_mutate_while_borrowed") => Ok(probe_ir_for_term(term))
    Some("__err_assign_to_immutable") => Ok(probe_ir_for_term(term))
    Some("__err_borrow_outlives_owner") => Ok(probe_ir_for_term(term))
    Some("__err_dangling_reference_escape") => Ok(probe_ir_for_term(term))
    Some("__err_region_constraint_unsatisfied") => Ok(probe_ir_for_term(term))
    Some("__err_invalid_borrow_target") =>
      Err(InvalidBorrowTarget("... invalid borrow target probe"))
    _ =>
      // ...
      Err(Message("... lower_to_borrow_ir"))
  }
}

///|
/// Description: Placeholder extraction of region constraints from borrow IR.
/// Example: `let _ = collect_region_constraints_from_ir(BorrowIr::{ nodes: [] })`
pub fn collect_region_constraints_from_ir(
  ir : BorrowIr,
) -> Result[Array[RegionConstraint], TypingError] {
  match probe_tag_from_ir(ir) {
    Some("__ok_borrow") => Ok([])
    Some("__err_use_after_move") => Ok([])
    Some("__err_moved_value_borrow") => Ok([])
    Some("__err_borrow_conflict") => Ok([])
    Some("__err_mutate_while_borrowed") => Ok([])
    Some("__err_assign_to_immutable") => Ok([])
    Some("__err_borrow_outlives_owner") =>
      Ok([RegionConstraint::placeholder("__err_borrow_outlives_owner")])
    Some("__err_dangling_reference_escape") =>
      Ok([RegionConstraint::placeholder("__err_dangling_reference_escape")])
    Some("__err_region_constraint_unsatisfied") =>
      Ok([RegionConstraint::placeholder("__err_region_constraint_unsatisfied")])
    _ =>
      // ...
      Err(Message("... collect_region_constraints_from_ir"))
  }
}

///|
/// Description: Placeholder region-constraint solver.
/// Example: `let _ = solve_region_constraints_placeholder([])`
pub fn solve_region_constraints_placeholder(
  constraints : Array[RegionConstraint],
) -> Result[RegionSolution, TypingError] {
  if contains_region_probe(constraints, "__err_borrow_outlives_owner") {
    return Err(BorrowOutlivesOwner("... owner"))
  }

  if contains_region_probe(constraints, "__err_dangling_reference_escape") {
    return Err(DanglingReferenceEscape("... dangling"))
  }

  if contains_region_probe(constraints, "__err_region_constraint_unsatisfied") {
    return Err(
      RegionConstraintUnsatisfied(
        RegionConstraint::placeholder("__err_region_constraint_unsatisfied"),
      ),
    )
  }

  if constraints.length() == 0 {
    return Ok(RegionSolution::empty())
  }

  // ...
  Err(Message("... solve_region_constraints"))
}

///|
/// Description: Placeholder borrow-rule checker.
/// Example: `let _ = check_borrow_rules_placeholder(BorrowIr::{ nodes: [] }, RegionSolution::empty(), BorrowCheckerOptions::default())`
pub fn check_borrow_rules_placeholder(
  ir : BorrowIr,
  solved : RegionSolution,
  options : BorrowCheckerOptions,
) -> Result[BorrowFacts, TypingError] {
  ignore(solved)
  ignore(options)
  match probe_tag_from_ir(ir) {
    Some("__ok_borrow") => Ok(BorrowFacts::empty())
    Some("__err_use_after_move") => Err(UseAfterMove("... moved place"))
    Some("__err_moved_value_borrow") =>
      Err(MovedValueBorrow("... moved value borrow"))
    Some("__err_borrow_conflict") =>
      Err(BorrowConflict(probe_place("x"), probe_place("x").field("field")))
    Some("__err_mutate_while_borrowed") =>
      Err(MutateWhileBorrowed(probe_place("x")))
    Some("__err_assign_to_immutable") =>
      Err(AssignToImmutable(probe_place("x")))
    _ =>
      // ...
      Err(Message("... check_borrow_rules"))
  }
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
  collect_region_constraints_from_ir(ir)
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
