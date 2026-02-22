///|
test "new borrow-related TypingError variants are scaffolded" {
  let place = Place::root("x")
  let constraint = RegionConstraint::placeholder("...")

  let e1 : TypingError = UseAfterMove("x")
  let e2 : TypingError = MovedValueBorrow("x")
  let e3 : TypingError = BorrowConflict(place, place)
  let e4 : TypingError = MutateWhileBorrowed(place)
  let e5 : TypingError = AssignToImmutable(place)
  let e6 : TypingError = BorrowOutlivesOwner("x")
  let e7 : TypingError = DanglingReferenceEscape("x")
  let e8 : TypingError = InvalidBorrowTarget("x")
  let e9 : TypingError = RegionConstraintUnsatisfied(constraint)

  assert_true(e1 is UseAfterMove(_))
  assert_true(e2 is MovedValueBorrow(_))
  assert_true(e3 is BorrowConflict(_, _))
  assert_true(e4 is MutateWhileBorrowed(_))
  assert_true(e5 is AssignToImmutable(_))
  assert_true(e6 is BorrowOutlivesOwner(_))
  assert_true(e7 is DanglingReferenceEscape(_))
  assert_true(e8 is InvalidBorrowTarget(_))
  assert_true(e9 is RegionConstraintUnsatisfied(_))
}

///|
test "region helper placeholders return Message errors" {
  let ok_result = solve_region_constraints_placeholder([])
  assert_true(ok_result is Ok(_))

  let constraint_result = solve_region_constraints_placeholder([
    RegionConstraint::placeholder("..."),
  ])
  assert_true(constraint_result is Err(Message(_)))

  let checker_result = check_borrow_rules_placeholder(
    BorrowIr::{ nodes: [] },
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )
  assert_true(checker_result is Err(Message(_)))
}
