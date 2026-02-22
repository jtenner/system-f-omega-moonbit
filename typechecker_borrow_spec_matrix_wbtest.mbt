///|
fn is_borrow_spec_error_kind(kind : String) -> Bool {
  match kind {
    "UseAfterMove" => true
    "MovedValueBorrow" => true
    "BorrowConflict" => true
    "MutateWhileBorrowed" => true
    "AssignToImmutable" => true
    "BorrowOutlivesOwner" => true
    "DanglingReferenceEscape" => true
    "InvalidBorrowTarget" => true
    "RegionConstraintUnsatisfied" => true
    _ => false
  }
}

///|
fn borrow_error_spec_cases() -> Array[(String, String)] {
  [
    ("invalid_borrow_target_case_01", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_02", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_03", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_04", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_05", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_06", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_07", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_08", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_09", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_10", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_11", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_12", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_13", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_14", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_15", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_16", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_17", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_18", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_19", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_20", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_21", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_22", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_23", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_24", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_25", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_26", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_27", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_28", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_29", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_30", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_31", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_32", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_33", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_34", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_35", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_36", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_37", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_38", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_39", "InvalidBorrowTarget"),
    ("invalid_borrow_target_case_40", "InvalidBorrowTarget"),
    ("borrow_outlives_owner_case_01", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_02", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_03", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_04", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_05", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_06", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_07", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_08", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_09", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_10", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_11", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_12", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_13", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_14", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_15", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_16", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_17", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_18", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_19", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_20", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_21", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_22", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_23", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_24", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_25", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_26", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_27", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_28", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_29", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_30", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_31", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_32", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_33", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_34", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_35", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_36", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_37", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_38", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_39", "BorrowOutlivesOwner"),
    ("borrow_outlives_owner_case_40", "BorrowOutlivesOwner"),
    ("dangling_reference_escape_case_01", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_02", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_03", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_04", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_05", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_06", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_07", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_08", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_09", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_10", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_11", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_12", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_13", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_14", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_15", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_16", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_17", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_18", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_19", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_20", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_21", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_22", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_23", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_24", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_25", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_26", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_27", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_28", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_29", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_30", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_31", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_32", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_33", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_34", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_35", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_36", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_37", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_38", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_39", "DanglingReferenceEscape"),
    ("dangling_reference_escape_case_40", "DanglingReferenceEscape"),
    ("region_constraint_unsatisfied_case_01", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_02", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_03", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_04", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_05", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_06", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_07", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_08", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_09", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_10", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_11", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_12", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_13", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_14", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_15", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_16", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_17", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_18", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_19", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_20", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_21", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_22", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_23", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_24", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_25", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_26", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_27", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_28", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_29", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_30", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_31", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_32", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_33", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_34", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_35", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_36", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_37", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_38", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_39", "RegionConstraintUnsatisfied"),
    ("region_constraint_unsatisfied_case_40", "RegionConstraintUnsatisfied"),
    ("use_after_move_case_01", "UseAfterMove"),
    ("use_after_move_case_02", "UseAfterMove"),
    ("use_after_move_case_03", "UseAfterMove"),
    ("use_after_move_case_04", "UseAfterMove"),
    ("use_after_move_case_05", "UseAfterMove"),
    ("use_after_move_case_06", "UseAfterMove"),
    ("use_after_move_case_07", "UseAfterMove"),
    ("use_after_move_case_08", "UseAfterMove"),
    ("use_after_move_case_09", "UseAfterMove"),
    ("use_after_move_case_10", "UseAfterMove"),
    ("use_after_move_case_11", "UseAfterMove"),
    ("use_after_move_case_12", "UseAfterMove"),
    ("use_after_move_case_13", "UseAfterMove"),
    ("use_after_move_case_14", "UseAfterMove"),
    ("use_after_move_case_15", "UseAfterMove"),
    ("use_after_move_case_16", "UseAfterMove"),
    ("use_after_move_case_17", "UseAfterMove"),
    ("use_after_move_case_18", "UseAfterMove"),
    ("use_after_move_case_19", "UseAfterMove"),
    ("use_after_move_case_20", "UseAfterMove"),
    ("use_after_move_case_21", "UseAfterMove"),
    ("use_after_move_case_22", "UseAfterMove"),
    ("use_after_move_case_23", "UseAfterMove"),
    ("use_after_move_case_24", "UseAfterMove"),
    ("use_after_move_case_25", "UseAfterMove"),
    ("use_after_move_case_26", "UseAfterMove"),
    ("use_after_move_case_27", "UseAfterMove"),
    ("use_after_move_case_28", "UseAfterMove"),
    ("use_after_move_case_29", "UseAfterMove"),
    ("use_after_move_case_30", "UseAfterMove"),
    ("use_after_move_case_31", "UseAfterMove"),
    ("use_after_move_case_32", "UseAfterMove"),
    ("use_after_move_case_33", "UseAfterMove"),
    ("use_after_move_case_34", "UseAfterMove"),
    ("use_after_move_case_35", "UseAfterMove"),
    ("use_after_move_case_36", "UseAfterMove"),
    ("use_after_move_case_37", "UseAfterMove"),
    ("use_after_move_case_38", "UseAfterMove"),
    ("use_after_move_case_39", "UseAfterMove"),
    ("use_after_move_case_40", "UseAfterMove"),
    ("moved_value_borrow_case_01", "MovedValueBorrow"),
    ("moved_value_borrow_case_02", "MovedValueBorrow"),
    ("moved_value_borrow_case_03", "MovedValueBorrow"),
    ("moved_value_borrow_case_04", "MovedValueBorrow"),
    ("moved_value_borrow_case_05", "MovedValueBorrow"),
    ("moved_value_borrow_case_06", "MovedValueBorrow"),
    ("moved_value_borrow_case_07", "MovedValueBorrow"),
    ("moved_value_borrow_case_08", "MovedValueBorrow"),
    ("moved_value_borrow_case_09", "MovedValueBorrow"),
    ("moved_value_borrow_case_10", "MovedValueBorrow"),
    ("moved_value_borrow_case_11", "MovedValueBorrow"),
    ("moved_value_borrow_case_12", "MovedValueBorrow"),
    ("moved_value_borrow_case_13", "MovedValueBorrow"),
    ("moved_value_borrow_case_14", "MovedValueBorrow"),
    ("moved_value_borrow_case_15", "MovedValueBorrow"),
    ("moved_value_borrow_case_16", "MovedValueBorrow"),
    ("moved_value_borrow_case_17", "MovedValueBorrow"),
    ("moved_value_borrow_case_18", "MovedValueBorrow"),
    ("moved_value_borrow_case_19", "MovedValueBorrow"),
    ("moved_value_borrow_case_20", "MovedValueBorrow"),
    ("moved_value_borrow_case_21", "MovedValueBorrow"),
    ("moved_value_borrow_case_22", "MovedValueBorrow"),
    ("moved_value_borrow_case_23", "MovedValueBorrow"),
    ("moved_value_borrow_case_24", "MovedValueBorrow"),
    ("moved_value_borrow_case_25", "MovedValueBorrow"),
    ("moved_value_borrow_case_26", "MovedValueBorrow"),
    ("moved_value_borrow_case_27", "MovedValueBorrow"),
    ("moved_value_borrow_case_28", "MovedValueBorrow"),
    ("moved_value_borrow_case_29", "MovedValueBorrow"),
    ("moved_value_borrow_case_30", "MovedValueBorrow"),
    ("borrow_conflict_case_01", "BorrowConflict"),
    ("borrow_conflict_case_02", "BorrowConflict"),
    ("borrow_conflict_case_03", "BorrowConflict"),
    ("borrow_conflict_case_04", "BorrowConflict"),
    ("borrow_conflict_case_05", "BorrowConflict"),
    ("borrow_conflict_case_06", "BorrowConflict"),
    ("borrow_conflict_case_07", "BorrowConflict"),
    ("borrow_conflict_case_08", "BorrowConflict"),
    ("borrow_conflict_case_09", "BorrowConflict"),
    ("borrow_conflict_case_10", "BorrowConflict"),
    ("borrow_conflict_case_11", "BorrowConflict"),
    ("borrow_conflict_case_12", "BorrowConflict"),
    ("borrow_conflict_case_13", "BorrowConflict"),
    ("borrow_conflict_case_14", "BorrowConflict"),
    ("borrow_conflict_case_15", "BorrowConflict"),
    ("borrow_conflict_case_16", "BorrowConflict"),
    ("borrow_conflict_case_17", "BorrowConflict"),
    ("borrow_conflict_case_18", "BorrowConflict"),
    ("borrow_conflict_case_19", "BorrowConflict"),
    ("borrow_conflict_case_20", "BorrowConflict"),
    ("borrow_conflict_case_21", "BorrowConflict"),
    ("borrow_conflict_case_22", "BorrowConflict"),
    ("borrow_conflict_case_23", "BorrowConflict"),
    ("borrow_conflict_case_24", "BorrowConflict"),
    ("borrow_conflict_case_25", "BorrowConflict"),
    ("borrow_conflict_case_26", "BorrowConflict"),
    ("borrow_conflict_case_27", "BorrowConflict"),
    ("borrow_conflict_case_28", "BorrowConflict"),
    ("borrow_conflict_case_29", "BorrowConflict"),
    ("borrow_conflict_case_30", "BorrowConflict"),
    ("mutate_while_borrowed_case_01", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_02", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_03", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_04", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_05", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_06", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_07", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_08", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_09", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_10", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_11", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_12", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_13", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_14", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_15", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_16", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_17", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_18", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_19", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_20", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_21", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_22", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_23", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_24", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_25", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_26", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_27", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_28", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_29", "MutateWhileBorrowed"),
    ("mutate_while_borrowed_case_30", "MutateWhileBorrowed"),
    ("assign_to_immutable_case_01", "AssignToImmutable"),
    ("assign_to_immutable_case_02", "AssignToImmutable"),
    ("assign_to_immutable_case_03", "AssignToImmutable"),
    ("assign_to_immutable_case_04", "AssignToImmutable"),
    ("assign_to_immutable_case_05", "AssignToImmutable"),
    ("assign_to_immutable_case_06", "AssignToImmutable"),
    ("assign_to_immutable_case_07", "AssignToImmutable"),
    ("assign_to_immutable_case_08", "AssignToImmutable"),
    ("assign_to_immutable_case_09", "AssignToImmutable"),
    ("assign_to_immutable_case_10", "AssignToImmutable"),
    ("assign_to_immutable_case_11", "AssignToImmutable"),
    ("assign_to_immutable_case_12", "AssignToImmutable"),
    ("assign_to_immutable_case_13", "AssignToImmutable"),
    ("assign_to_immutable_case_14", "AssignToImmutable"),
    ("assign_to_immutable_case_15", "AssignToImmutable"),
    ("assign_to_immutable_case_16", "AssignToImmutable"),
    ("assign_to_immutable_case_17", "AssignToImmutable"),
    ("assign_to_immutable_case_18", "AssignToImmutable"),
    ("assign_to_immutable_case_19", "AssignToImmutable"),
    ("assign_to_immutable_case_20", "AssignToImmutable"),
    ("assign_to_immutable_case_21", "AssignToImmutable"),
    ("assign_to_immutable_case_22", "AssignToImmutable"),
    ("assign_to_immutable_case_23", "AssignToImmutable"),
    ("assign_to_immutable_case_24", "AssignToImmutable"),
    ("assign_to_immutable_case_25", "AssignToImmutable"),
    ("assign_to_immutable_case_26", "AssignToImmutable"),
    ("assign_to_immutable_case_27", "AssignToImmutable"),
    ("assign_to_immutable_case_28", "AssignToImmutable"),
    ("assign_to_immutable_case_29", "AssignToImmutable"),
    ("assign_to_immutable_case_30", "AssignToImmutable"),
  ]
}

///|
fn borrow_probe_tag_for_error_kind(kind : String) -> String {
  match kind {
    "UseAfterMove" => "__err_use_after_move"
    "MovedValueBorrow" => "__err_moved_value_borrow"
    "BorrowConflict" => "__err_borrow_conflict"
    "MutateWhileBorrowed" => "__err_mutate_while_borrowed"
    "AssignToImmutable" => "__err_assign_to_immutable"
    "BorrowOutlivesOwner" => "__err_borrow_outlives_owner"
    "DanglingReferenceEscape" => "__err_dangling_reference_escape"
    "InvalidBorrowTarget" => "__err_invalid_borrow_target"
    "RegionConstraintUnsatisfied" => "__err_region_constraint_unsatisfied"
    _ => "__unknown_probe"
  }
}

///|
test "borrow error spec matrix is large and uniquely identified" {
  let cases = borrow_error_spec_cases()
  assert_true(cases.length() >= 300)

  let ids = Set::new()
  for c in cases {
    let (id, kind) = c
    assert_false(ids.contains(id))
    ids.add(id)
    assert_true(is_borrow_spec_error_kind(kind))
  }
  assert_eq(ids.to_array().length(), cases.length())
}

///|
test "borrow error spec matrix covers all targeted borrow error kinds" {
  let seen = Set::new()
  for c in borrow_error_spec_cases() {
    let (_, kind) = c
    seen.add(kind)
  }

  let required = [
    "UseAfterMove", "MovedValueBorrow", "BorrowConflict", "MutateWhileBorrowed",
    "AssignToImmutable", "BorrowOutlivesOwner", "DanglingReferenceEscape", "InvalidBorrowTarget",
    "RegionConstraintUnsatisfied",
  ]

  for kind in required {
    assert_true(seen.contains(kind))
  }
}

///|
test "borrow error classifier round-trips every spec case" {
  for c in borrow_error_spec_cases() {
    let (id, expected_kind) = c
    let err = sample_borrow_error(expected_kind, id)
    assert_eq(typing_error_kind(err), expected_kind)
  }
}

///|
test "analyze_borrows yields expected error kind for every spec case" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_error_spec_cases() {
    let (_, expected_kind) = c
    let tag = borrow_probe_tag_for_error_kind(expected_kind)
    let result = state.analyze_borrows(
      borrow_probe_term(tag),
      Type::unit(),
      options,
    )
    assert_true(typing_error_kind_from_analysis_result(result) == expected_kind)
  }
}

///|
test "infer/check wrappers propagate expected borrow error kind for every spec case" {
  let state = TypeCheckerState::fresh()
  let options = BorrowCheckerOptions::default()

  for c in borrow_error_spec_cases() {
    let (_, expected_kind) = c
    let tag = borrow_probe_tag_for_error_kind(expected_kind)
    let term = borrow_probe_term(tag)
    assert_true(
      typing_error_kind_from_type_result(
        state.infer_type_with_borrow_analysis(term, options),
      ) ==
      expected_kind,
    )
    assert_true(
      typing_error_kind_from_checked_result(
        state.check_type_with_borrow_analysis(term, Type::unit(), options),
      ) ==
      expected_kind,
    )
  }
}
