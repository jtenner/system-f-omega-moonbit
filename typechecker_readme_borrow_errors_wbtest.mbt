///|
test "README borrow error UseAfterMove failing example reports UseAfterMove" {
  let result = readme_borrow_error_use_after_move_failing()
  assert_true(result is Err(UseAfterMove(_)))
}

///|
test "README borrow error UseAfterMove fix example succeeds" {
  assert_true(readme_borrow_error_use_after_move_fix() is Ok(_))
}

///|
test "README borrow error MovedValueBorrow failing example reports MovedValueBorrow" {
  let result = readme_borrow_error_moved_value_borrow_failing()
  assert_true(result is Err(MovedValueBorrow(_)))
}

///|
test "README borrow error MovedValueBorrow fix example succeeds" {
  assert_true(readme_borrow_error_moved_value_borrow_fix() is Ok(_))
}

///|
test "README borrow error BorrowConflict failing example reports BorrowConflict" {
  let result = readme_borrow_error_borrow_conflict_failing()
  assert_true(result is Err(BorrowConflict(_, _)))
}

///|
test "README borrow error BorrowConflict fix example succeeds" {
  assert_true(readme_borrow_error_borrow_conflict_fix() is Ok(_))
}

///|
test "README borrow error MutateWhileBorrowed failing example reports MutateWhileBorrowed" {
  let result = readme_borrow_error_mutate_while_borrowed_failing()
  assert_true(result is Err(MutateWhileBorrowed(_)))
}

///|
test "README borrow error MutateWhileBorrowed fix example succeeds" {
  assert_true(readme_borrow_error_mutate_while_borrowed_fix() is Ok(_))
}

///|
test "README borrow error AssignToImmutable failing example reports AssignToImmutable" {
  let result = readme_borrow_error_assign_to_immutable_failing()
  assert_true(result is Err(AssignToImmutable(_)))
}

///|
test "README borrow error AssignToImmutable fix example succeeds" {
  assert_true(readme_borrow_error_assign_to_immutable_fix() is Ok(_))
}

///|
test "README borrow error BorrowOutlivesOwner failing example reports BorrowOutlivesOwner" {
  let result = readme_borrow_error_borrow_outlives_owner_failing()
  assert_true(result is Err(BorrowOutlivesOwner(_)))
}

///|
test "README borrow error BorrowOutlivesOwner fix example succeeds" {
  assert_true(readme_borrow_error_borrow_outlives_owner_fix() is Ok(_))
}

///|
test "README borrow error DanglingReferenceEscape failing example reports DanglingReferenceEscape" {
  let result = readme_borrow_error_dangling_reference_escape_failing()
  assert_true(result is Err(DanglingReferenceEscape(_)))
}

///|
test "README borrow error DanglingReferenceEscape fix example succeeds" {
  assert_true(readme_borrow_error_dangling_reference_escape_fix() is Ok(_))
}

///|
test "README borrow error InvalidBorrowTarget failing example reports InvalidBorrowTarget" {
  let result = readme_borrow_error_invalid_borrow_target_failing()
  assert_true(result is Err(InvalidBorrowTarget(_)))
}

///|
test "README borrow error InvalidBorrowTarget fix example succeeds" {
  assert_true(readme_borrow_error_invalid_borrow_target_fix() is Ok(_))
}

///|
test "README borrow error RegionConstraintUnsatisfied failing example reports RegionConstraintUnsatisfied" {
  let result = readme_borrow_error_region_constraint_unsatisfied_failing()
  assert_true(result is Err(RegionConstraintUnsatisfied(_)))
}

///|
test "README borrow error RegionConstraintUnsatisfied fix example succeeds" {
  assert_true(readme_borrow_error_region_constraint_unsatisfied_fix() is Ok(_))
}
