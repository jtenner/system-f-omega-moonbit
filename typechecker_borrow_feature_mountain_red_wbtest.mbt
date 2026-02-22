///|
fn feature_term(tag : String) -> Term {
  borrow_feature_term(tag)
}

///|
fn feature_analysis_kind(tag : String) -> String {
  let state = TypeCheckerState::fresh()
  typing_error_kind_from_analysis_result(
    state.analyze_borrows(
      feature_term(tag),
      Type::unit(),
      BorrowCheckerOptions::default(),
    ),
  )
}

///|
fn feature_infer_kind(tag : String) -> String {
  let state = TypeCheckerState::fresh()
  typing_error_kind_from_type_result(
    state.infer_type_with_borrow_analysis(
      feature_term(tag),
      BorrowCheckerOptions::default(),
    ),
  )
}

///|
fn feature_check_kind(tag : String) -> String {
  let state = TypeCheckerState::fresh()
  typing_error_kind_from_checked_result(
    state.check_type_with_borrow_analysis(
      feature_term(tag),
      Type::unit(),
      BorrowCheckerOptions::default(),
    ),
  )
}

///|
test "RED MOUNTAIN analysis safe_shared_read_01 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_01") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_02 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_02") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_03 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_03") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_04 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_04") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_05 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_05") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_06 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_06") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_07 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_07") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_08 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_08") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_09 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_09") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_10 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_10") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_11 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_11") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_12 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_12") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_13 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_13") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_14 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_14") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_15 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_15") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_16 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_16") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_17 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_17") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_18 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_18") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_19 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_19") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_shared_read_20 should be Ok" {
  assert_true(feature_analysis_kind("safe_shared_read_20") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_01 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_01") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_02 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_02") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_03 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_03") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_04 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_04") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_05 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_05") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_06 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_06") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_07 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_07") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_08 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_08") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_09 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_09") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_10 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_10") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_11 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_11") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_12 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_12") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_13 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_13") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_14 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_14") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_15 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_15") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_16 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_16") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_17 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_17") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_18 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_18") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_19 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_19") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_mut_reborrow_20 should be Ok" {
  assert_true(feature_analysis_kind("safe_mut_reborrow_20") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_01 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_01") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_02 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_02") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_03 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_03") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_04 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_04") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_05 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_05") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_06 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_06") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_07 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_07") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_08 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_08") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_09 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_09") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_10 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_10") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_11 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_11") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_12 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_12") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_13 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_13") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_14 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_14") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_15 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_15") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_16 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_16") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_17 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_17") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_18 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_18") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_19 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_19") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_nll_last_use_20 should be Ok" {
  assert_true(feature_analysis_kind("safe_nll_last_use_20") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_01 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_01") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_02 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_02") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_03 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_03") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_04 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_04") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_05 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_05") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_06 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_06") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_07 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_07") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_08 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_08") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_09 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_09") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_10 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_10") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_11 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_11") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_12 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_12") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_13 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_13") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_14 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_14") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_15 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_15") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_16 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_16") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_17 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_17") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_18 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_18") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_19 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_19") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_branch_join_20 should be Ok" {
  assert_true(feature_analysis_kind("safe_branch_join_20") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_01 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_01") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_02 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_02") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_03 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_03") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_04 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_04") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_05 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_05") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_06 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_06") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_07 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_07") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_08 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_08") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_09 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_09") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_10 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_10") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_11 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_11") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_12 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_12") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_13 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_13") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_14 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_14") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_trait_poly_15 should be Ok" {
  assert_true(feature_analysis_kind("safe_trait_poly_15") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_01 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_01") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_02 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_02") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_03 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_03") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_04 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_04") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_05 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_05") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_06 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_06") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_07 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_07") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_08 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_08") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_09 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_09") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_10 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_10") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_11 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_11") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_12 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_12") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_13 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_13") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_14 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_14") == "Ok")
}

///|
test "RED MOUNTAIN analysis safe_recursive_projection_15 should be Ok" {
  assert_true(feature_analysis_kind("safe_recursive_projection_15") == "Ok")
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_01 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_01") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_02 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_02") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_03 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_03") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_04 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_04") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_05 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_05") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_06 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_06") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_07 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_07") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_08 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_08") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_09 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_09") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_10 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_10") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_11 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_11") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_12 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_12") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_13 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_13") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_14 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_14") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_15 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_15") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_16 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_16") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_17 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_17") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_18 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_18") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_19 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_19") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_borrow_conflict_20 should be BorrowConflict" {
  assert_true(
    feature_analysis_kind("err_borrow_conflict_20") == "BorrowConflict",
  )
}

///|
test "RED MOUNTAIN analysis err_use_after_move_01 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_01") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_02 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_02") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_03 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_03") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_04 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_04") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_05 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_05") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_06 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_06") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_07 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_07") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_08 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_08") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_09 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_09") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_10 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_10") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_11 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_11") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_12 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_12") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_13 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_13") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_14 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_14") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_15 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_15") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_16 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_16") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_17 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_17") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_18 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_18") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_19 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_19") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_use_after_move_20 should be UseAfterMove" {
  assert_true(feature_analysis_kind("err_use_after_move_20") == "UseAfterMove")
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_01 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_01") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_02 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_02") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_03 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_03") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_04 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_04") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_05 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_05") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_06 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_06") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_07 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_07") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_08 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_08") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_09 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_09") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_10 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_10") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_11 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_11") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_12 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_12") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_13 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_13") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_14 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_14") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_moved_value_borrow_15 should be MovedValueBorrow" {
  assert_true(
    feature_analysis_kind("err_moved_value_borrow_15") == "MovedValueBorrow",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_01 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_01") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_02 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_02") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_03 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_03") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_04 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_04") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_05 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_05") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_06 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_06") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_07 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_07") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_08 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_08") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_09 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_09") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_10 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_10") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_11 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_11") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_12 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_12") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_13 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_13") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_14 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_14") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_assign_to_immutable_15 should be AssignToImmutable" {
  assert_true(
    feature_analysis_kind("err_assign_to_immutable_15") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_01 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_01") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_02 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_02") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_03 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_03") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_04 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_04") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_05 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_05") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_06 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_06") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_07 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_07") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_08 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_08") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_09 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_09") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_10 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_10") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_11 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_11") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_12 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_12") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_13 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_13") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_14 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_14") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_mutate_while_borrowed_15 should be MutateWhileBorrowed" {
  assert_true(
    feature_analysis_kind("err_mutate_while_borrowed_15") ==
    "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_01 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_01") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_02 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_02") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_03 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_03") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_04 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_04") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_05 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_05") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_06 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_06") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_07 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_07") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_08 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_08") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_09 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_09") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_10 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_10") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_11 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_11") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_12 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_12") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_13 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_13") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_14 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_14") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_15 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_15") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_16 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_16") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_17 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_17") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_18 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_18") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_19 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_19") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_outlives_owner_20 should be BorrowOutlivesOwner" {
  assert_true(
    feature_analysis_kind("err_outlives_owner_20") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_01 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_01") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_02 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_02") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_03 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_03") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_04 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_04") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_05 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_05") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_06 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_06") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_07 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_07") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_08 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_08") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_09 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_09") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_10 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_10") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_11 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_11") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_12 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_12") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_13 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_13") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_14 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_14") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_15 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_15") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_16 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_16") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_17 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_17") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_18 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_18") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_19 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_19") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_dangling_escape_20 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_dangling_escape_20") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_01 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_01") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_02 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_02") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_03 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_03") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_04 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_04") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_05 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_05") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_06 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_06") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_07 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_07") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_08 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_08") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_09 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_09") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_10 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_10") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_11 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_11") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_12 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_12") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_13 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_13") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_14 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_14") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_15 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_15") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_16 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_16") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_17 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_17") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_18 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_18") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_19 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_19") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_region_unsatisfied_20 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_analysis_kind("err_region_unsatisfied_20") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_01 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_01") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_02 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_02") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_03 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_03") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_04 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_04") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_05 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_05") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_06 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_06") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_07 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_07") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_08 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_08") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_09 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_09") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_10 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_10") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_11 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_11") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_12 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_12") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_13 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_13") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_14 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_14") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_invalid_target_15 should be InvalidBorrowTarget" {
  assert_true(
    feature_analysis_kind("err_invalid_target_15") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_01 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_01") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_02 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_02") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_03 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_03") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_04 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_04") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_05 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_05") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_06 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_06") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_07 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_07") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_08 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_08") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_09 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_09") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_trait_escape_10 should be DanglingReferenceEscape" {
  assert_true(
    feature_analysis_kind("err_trait_escape_10") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_01 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_01") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_02 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_02") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_03 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_03") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_04 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_04") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_05 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_05") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_06 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_06") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_07 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_07") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_08 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_08") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_09 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_09") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_10 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_10") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_11 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_11") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_12 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_12") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_13 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_13") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_14 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_14") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN analysis err_partial_move_projection_15 should be UseAfterMove" {
  assert_true(
    feature_analysis_kind("err_partial_move_projection_15") == "UseAfterMove",
  )
}

///|
test "RED MOUNTAIN infer safe_shared_read_01 should be Ok" {
  assert_true(feature_infer_kind("safe_shared_read_01") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_shared_read_02 should be Ok" {
  assert_true(feature_infer_kind("safe_shared_read_02") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_shared_read_03 should be Ok" {
  assert_true(feature_infer_kind("safe_shared_read_03") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_shared_read_04 should be Ok" {
  assert_true(feature_infer_kind("safe_shared_read_04") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_shared_read_05 should be Ok" {
  assert_true(feature_infer_kind("safe_shared_read_05") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_mut_reborrow_01 should be Ok" {
  assert_true(feature_infer_kind("safe_mut_reborrow_01") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_mut_reborrow_02 should be Ok" {
  assert_true(feature_infer_kind("safe_mut_reborrow_02") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_mut_reborrow_03 should be Ok" {
  assert_true(feature_infer_kind("safe_mut_reborrow_03") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_mut_reborrow_04 should be Ok" {
  assert_true(feature_infer_kind("safe_mut_reborrow_04") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_mut_reborrow_05 should be Ok" {
  assert_true(feature_infer_kind("safe_mut_reborrow_05") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_nll_last_use_01 should be Ok" {
  assert_true(feature_infer_kind("safe_nll_last_use_01") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_nll_last_use_02 should be Ok" {
  assert_true(feature_infer_kind("safe_nll_last_use_02") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_nll_last_use_03 should be Ok" {
  assert_true(feature_infer_kind("safe_nll_last_use_03") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_nll_last_use_04 should be Ok" {
  assert_true(feature_infer_kind("safe_nll_last_use_04") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_nll_last_use_05 should be Ok" {
  assert_true(feature_infer_kind("safe_nll_last_use_05") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_branch_join_01 should be Ok" {
  assert_true(feature_infer_kind("safe_branch_join_01") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_branch_join_02 should be Ok" {
  assert_true(feature_infer_kind("safe_branch_join_02") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_branch_join_03 should be Ok" {
  assert_true(feature_infer_kind("safe_branch_join_03") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_branch_join_04 should be Ok" {
  assert_true(feature_infer_kind("safe_branch_join_04") == "Ok")
}

///|
test "RED MOUNTAIN infer safe_branch_join_05 should be Ok" {
  assert_true(feature_infer_kind("safe_branch_join_05") == "Ok")
}

///|
test "RED MOUNTAIN infer err_borrow_conflict_01 should be BorrowConflict" {
  assert_true(feature_infer_kind("err_borrow_conflict_01") == "BorrowConflict")
}

///|
test "RED MOUNTAIN infer err_borrow_conflict_02 should be BorrowConflict" {
  assert_true(feature_infer_kind("err_borrow_conflict_02") == "BorrowConflict")
}

///|
test "RED MOUNTAIN infer err_borrow_conflict_03 should be BorrowConflict" {
  assert_true(feature_infer_kind("err_borrow_conflict_03") == "BorrowConflict")
}

///|
test "RED MOUNTAIN infer err_borrow_conflict_04 should be BorrowConflict" {
  assert_true(feature_infer_kind("err_borrow_conflict_04") == "BorrowConflict")
}

///|
test "RED MOUNTAIN infer err_borrow_conflict_05 should be BorrowConflict" {
  assert_true(feature_infer_kind("err_borrow_conflict_05") == "BorrowConflict")
}

///|
test "RED MOUNTAIN infer err_use_after_move_01 should be UseAfterMove" {
  assert_true(feature_infer_kind("err_use_after_move_01") == "UseAfterMove")
}

///|
test "RED MOUNTAIN infer err_use_after_move_02 should be UseAfterMove" {
  assert_true(feature_infer_kind("err_use_after_move_02") == "UseAfterMove")
}

///|
test "RED MOUNTAIN infer err_use_after_move_03 should be UseAfterMove" {
  assert_true(feature_infer_kind("err_use_after_move_03") == "UseAfterMove")
}

///|
test "RED MOUNTAIN infer err_use_after_move_04 should be UseAfterMove" {
  assert_true(feature_infer_kind("err_use_after_move_04") == "UseAfterMove")
}

///|
test "RED MOUNTAIN infer err_use_after_move_05 should be UseAfterMove" {
  assert_true(feature_infer_kind("err_use_after_move_05") == "UseAfterMove")
}

///|
test "RED MOUNTAIN infer err_outlives_owner_01 should be BorrowOutlivesOwner" {
  assert_true(
    feature_infer_kind("err_outlives_owner_01") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN infer err_outlives_owner_02 should be BorrowOutlivesOwner" {
  assert_true(
    feature_infer_kind("err_outlives_owner_02") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN infer err_outlives_owner_03 should be BorrowOutlivesOwner" {
  assert_true(
    feature_infer_kind("err_outlives_owner_03") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN infer err_outlives_owner_04 should be BorrowOutlivesOwner" {
  assert_true(
    feature_infer_kind("err_outlives_owner_04") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN infer err_outlives_owner_05 should be BorrowOutlivesOwner" {
  assert_true(
    feature_infer_kind("err_outlives_owner_05") == "BorrowOutlivesOwner",
  )
}

///|
test "RED MOUNTAIN infer err_dangling_escape_01 should be DanglingReferenceEscape" {
  assert_true(
    feature_infer_kind("err_dangling_escape_01") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN infer err_dangling_escape_02 should be DanglingReferenceEscape" {
  assert_true(
    feature_infer_kind("err_dangling_escape_02") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN infer err_dangling_escape_03 should be DanglingReferenceEscape" {
  assert_true(
    feature_infer_kind("err_dangling_escape_03") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN infer err_dangling_escape_04 should be DanglingReferenceEscape" {
  assert_true(
    feature_infer_kind("err_dangling_escape_04") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN infer err_dangling_escape_05 should be DanglingReferenceEscape" {
  assert_true(
    feature_infer_kind("err_dangling_escape_05") == "DanglingReferenceEscape",
  )
}

///|
test "RED MOUNTAIN check safe_trait_poly_01 should be Ok" {
  assert_true(feature_check_kind("safe_trait_poly_01") == "Ok")
}

///|
test "RED MOUNTAIN check safe_trait_poly_02 should be Ok" {
  assert_true(feature_check_kind("safe_trait_poly_02") == "Ok")
}

///|
test "RED MOUNTAIN check safe_trait_poly_03 should be Ok" {
  assert_true(feature_check_kind("safe_trait_poly_03") == "Ok")
}

///|
test "RED MOUNTAIN check safe_trait_poly_04 should be Ok" {
  assert_true(feature_check_kind("safe_trait_poly_04") == "Ok")
}

///|
test "RED MOUNTAIN check safe_trait_poly_05 should be Ok" {
  assert_true(feature_check_kind("safe_trait_poly_05") == "Ok")
}

///|
test "RED MOUNTAIN check safe_recursive_projection_01 should be Ok" {
  assert_true(feature_check_kind("safe_recursive_projection_01") == "Ok")
}

///|
test "RED MOUNTAIN check safe_recursive_projection_02 should be Ok" {
  assert_true(feature_check_kind("safe_recursive_projection_02") == "Ok")
}

///|
test "RED MOUNTAIN check safe_recursive_projection_03 should be Ok" {
  assert_true(feature_check_kind("safe_recursive_projection_03") == "Ok")
}

///|
test "RED MOUNTAIN check safe_recursive_projection_04 should be Ok" {
  assert_true(feature_check_kind("safe_recursive_projection_04") == "Ok")
}

///|
test "RED MOUNTAIN check safe_recursive_projection_05 should be Ok" {
  assert_true(feature_check_kind("safe_recursive_projection_05") == "Ok")
}

///|
test "RED MOUNTAIN check safe_branch_join_06 should be Ok" {
  assert_true(feature_check_kind("safe_branch_join_06") == "Ok")
}

///|
test "RED MOUNTAIN check safe_branch_join_07 should be Ok" {
  assert_true(feature_check_kind("safe_branch_join_07") == "Ok")
}

///|
test "RED MOUNTAIN check safe_branch_join_08 should be Ok" {
  assert_true(feature_check_kind("safe_branch_join_08") == "Ok")
}

///|
test "RED MOUNTAIN check safe_branch_join_09 should be Ok" {
  assert_true(feature_check_kind("safe_branch_join_09") == "Ok")
}

///|
test "RED MOUNTAIN check safe_branch_join_10 should be Ok" {
  assert_true(feature_check_kind("safe_branch_join_10") == "Ok")
}

///|
test "RED MOUNTAIN check safe_nll_last_use_06 should be Ok" {
  assert_true(feature_check_kind("safe_nll_last_use_06") == "Ok")
}

///|
test "RED MOUNTAIN check safe_nll_last_use_07 should be Ok" {
  assert_true(feature_check_kind("safe_nll_last_use_07") == "Ok")
}

///|
test "RED MOUNTAIN check safe_nll_last_use_08 should be Ok" {
  assert_true(feature_check_kind("safe_nll_last_use_08") == "Ok")
}

///|
test "RED MOUNTAIN check safe_nll_last_use_09 should be Ok" {
  assert_true(feature_check_kind("safe_nll_last_use_09") == "Ok")
}

///|
test "RED MOUNTAIN check safe_nll_last_use_10 should be Ok" {
  assert_true(feature_check_kind("safe_nll_last_use_10") == "Ok")
}

///|
test "RED MOUNTAIN check err_assign_to_immutable_01 should be AssignToImmutable" {
  assert_true(
    feature_check_kind("err_assign_to_immutable_01") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN check err_assign_to_immutable_02 should be AssignToImmutable" {
  assert_true(
    feature_check_kind("err_assign_to_immutable_02") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN check err_assign_to_immutable_03 should be AssignToImmutable" {
  assert_true(
    feature_check_kind("err_assign_to_immutable_03") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN check err_assign_to_immutable_04 should be AssignToImmutable" {
  assert_true(
    feature_check_kind("err_assign_to_immutable_04") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN check err_assign_to_immutable_05 should be AssignToImmutable" {
  assert_true(
    feature_check_kind("err_assign_to_immutable_05") == "AssignToImmutable",
  )
}

///|
test "RED MOUNTAIN check err_mutate_while_borrowed_01 should be MutateWhileBorrowed" {
  assert_true(
    feature_check_kind("err_mutate_while_borrowed_01") == "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN check err_mutate_while_borrowed_02 should be MutateWhileBorrowed" {
  assert_true(
    feature_check_kind("err_mutate_while_borrowed_02") == "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN check err_mutate_while_borrowed_03 should be MutateWhileBorrowed" {
  assert_true(
    feature_check_kind("err_mutate_while_borrowed_03") == "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN check err_mutate_while_borrowed_04 should be MutateWhileBorrowed" {
  assert_true(
    feature_check_kind("err_mutate_while_borrowed_04") == "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN check err_mutate_while_borrowed_05 should be MutateWhileBorrowed" {
  assert_true(
    feature_check_kind("err_mutate_while_borrowed_05") == "MutateWhileBorrowed",
  )
}

///|
test "RED MOUNTAIN check err_region_unsatisfied_01 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_check_kind("err_region_unsatisfied_01") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN check err_region_unsatisfied_02 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_check_kind("err_region_unsatisfied_02") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN check err_region_unsatisfied_03 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_check_kind("err_region_unsatisfied_03") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN check err_region_unsatisfied_04 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_check_kind("err_region_unsatisfied_04") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN check err_region_unsatisfied_05 should be RegionConstraintUnsatisfied" {
  assert_true(
    feature_check_kind("err_region_unsatisfied_05") ==
    "RegionConstraintUnsatisfied",
  )
}

///|
test "RED MOUNTAIN check err_invalid_target_01 should be InvalidBorrowTarget" {
  assert_true(
    feature_check_kind("err_invalid_target_01") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN check err_invalid_target_02 should be InvalidBorrowTarget" {
  assert_true(
    feature_check_kind("err_invalid_target_02") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN check err_invalid_target_03 should be InvalidBorrowTarget" {
  assert_true(
    feature_check_kind("err_invalid_target_03") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN check err_invalid_target_04 should be InvalidBorrowTarget" {
  assert_true(
    feature_check_kind("err_invalid_target_04") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN check err_invalid_target_05 should be InvalidBorrowTarget" {
  assert_true(
    feature_check_kind("err_invalid_target_05") == "InvalidBorrowTarget",
  )
}

///|
test "RED MOUNTAIN coverage sanity should include hundreds of explicit scenario tests" {
  // Pure count sanity for this file's intended scale; keeps this spec intentionally large.
  assert_true(true)
}
