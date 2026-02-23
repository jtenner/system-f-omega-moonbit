///|
test "borrow core scaffold exposes mutability, region, and place constructors" {
  let shared = Mutability::shared()
  let mutable = Mutability::mutable()
  assert_true(shared == Shared)
  assert_true(mutable == Mutable)

  let named = Region::named("r")
  let inferred = Region::infer(42)
  let static_r = Region::static_region()
  assert_true(named == Named("r"))
  assert_true(inferred == Infer(42))
  assert_true(static_r == Static)

  let place = Place::root("x").field("field").tuple_index(0).deref_place()
  assert_eq(place.root, "x")
  assert_eq(place.projections.length(), 3)
}

///|
test "borrow core scaffold exposes borrow type and term wrappers" {
  let ref_ty = BorrowType::ref_type(
    Region::named("r"),
    Mutability::shared(),
    Type::con("Int"),
  )
  match ref_ty {
    Ref(Named(name), Shared, Con(tn)) => {
      assert_eq(name, "r")
      assert_eq(tn, "Int")
    }
    _ => panic()
  }

  let assign = BorrowTerm::assign(Place::root("x"), Term::unit())
  match assign {
    Assign(place, value) => {
      assert_eq(place.root, "x")
      assert_true(value == Term::unit())
    }
    _ => panic()
  }
}

///|
test "borrow core scaffold exposes empty defaults" {
  let options = BorrowCheckerOptions::default()
  assert_true(options.enabled)
  assert_false(options.use_nll)
  assert_true(options.diagnostics)

  let disabled = BorrowCheckerOptions::disabled()
  assert_false(disabled.enabled)

  let solution = RegionSolution::empty()
  assert_eq(solution.unresolved.length(), 0)

  let facts = BorrowFacts::empty()
  assert_eq(facts.loans.length(), 0)
  assert_eq(facts.constraints.length(), 0)

  let result = BorrowAnalysisResult::empty()
  assert_eq(result.facts.loans.length(), 0)
  assert_eq(result.solved.unresolved.length(), 0)
}

///|
test "borrow core scaffold exposes native borrow syntax detector" {
  assert_false(term_contains_native_borrow_syntax(Term::unit()))
  assert_false(
    term_contains_native_borrow_syntax(
      Term::let_term("x", Term::unit(), Term::var_term("x")),
    ),
  )
  assert_true(
    term_contains_native_borrow_syntax(
      Term::let_term(
        "x",
        Term::unit(),
        Term::tuple_project(
          Term::tuple([
            Term::borrow_mut(Term::var_term("x")),
            Term::borrow_shared(Term::var_term("x")),
            Term::unit(),
          ]),
          2,
        ),
      ),
    ),
  )
}

///|
test "borrow core scaffold exposes stable borrow IR schema markers" {
  assert_eq(borrow_ir_schema_version(), 1)
  assert_true(
    borrow_ir_match_branch_boundary_marker_name() ==
    "BorrowIrBoundaryMatchBranch",
  )
}
