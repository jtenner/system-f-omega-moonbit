///|
fn typing_error_kind(error : TypingError) -> String {
  match error {
    TypeMismatch(_, _) => "TypeMismatch"
    KindMismatch(_, _) => "KindMismatch"
    Cyclic(_) => "Cyclic"
    Unbound(_) => "Unbound"
    NotATypeFunction(_) => "NotATypeFunction"
    NotAVariant(_) => "NotAVariant"
    InvalidVariantLabel(_, _) => "InvalidVariantLabel"
    MissingCase(_) => "MissingCase"
    ExtraCase(_) => "ExtraCase"
    NotATuple(_) => "NotATuple"
    TupleIndexOutOfBounds(_, _) => "TupleIndexOutOfBounds"
    NotARecord(_) => "NotARecord"
    MissingField(_, _) => "MissingField"
    NotAFunction(_) => "NotAFunction"
    MissingMethod(_, _) => "MissingMethod"
    WrongNumberOfDicts(_, _) => "WrongNumberOfDicts"
    MissingTraitImpl(_, _) => "MissingTraitImpl"
    UseAfterMove(_) => "UseAfterMove"
    MovedValueBorrow(_) => "MovedValueBorrow"
    BorrowConflict(_, _) => "BorrowConflict"
    MutateWhileBorrowed(_) => "MutateWhileBorrowed"
    AssignToImmutable(_) => "AssignToImmutable"
    BorrowOutlivesOwner(_) => "BorrowOutlivesOwner"
    DanglingReferenceEscape(_) => "DanglingReferenceEscape"
    InvalidBorrowTarget(_) => "InvalidBorrowTarget"
    RegionConstraintUnsatisfied(_) => "RegionConstraintUnsatisfied"
    DuplicateBinding(_) => "DuplicateBinding"
    CircularImport(_, _) => "CircularImport"
    Message(_) => "Message"
  }
}

///|
fn sample_borrow_error(kind : String, payload : String) -> TypingError {
  match kind {
    "UseAfterMove" => UseAfterMove(payload)
    "MovedValueBorrow" => MovedValueBorrow(payload)
    "BorrowConflict" =>
      BorrowConflict(Place::root(payload), Place::root(payload).field("field"))
    "MutateWhileBorrowed" => MutateWhileBorrowed(Place::root(payload))
    "AssignToImmutable" => AssignToImmutable(Place::root(payload))
    "BorrowOutlivesOwner" => BorrowOutlivesOwner(payload)
    "DanglingReferenceEscape" => DanglingReferenceEscape(payload)
    "InvalidBorrowTarget" => InvalidBorrowTarget(payload)
    "RegionConstraintUnsatisfied" =>
      RegionConstraintUnsatisfied(RegionConstraint::placeholder(payload))
    "Message" => Message(payload)
    _ => Message("unknown sample kind")
  }
}

///|
fn borrow_probe_term(tag : String) -> Term {
  Term::con(tag, Type::unit())
}

///|
fn borrow_feature_marker(marker : String) -> Term {
  Term::con(marker, Type::unit())
}

///|
fn borrow_feature_program_let(marker : String) -> Term {
  Term::let_term("feature_marker", borrow_feature_marker(marker), Term::unit())
}

///|
fn borrow_feature_program_tuple(marker : String) -> Term {
  Term::tuple_project(
    Term::tuple([borrow_feature_marker(marker), Term::unit()]),
    1,
  )
}

///|
fn borrow_feature_program_record(marker : String) -> Term {
  Term::project(
    Term::record([
      ("feature_marker", borrow_feature_marker(marker)),
      ("v", Term::unit()),
    ]),
    "v",
  )
}

///|
fn borrow_feature_program_lambda(marker : String) -> Term {
  Term::app(
    Term::lam(
      "x",
      Type::unit(),
      Term::let_term(
        "feature_marker",
        borrow_feature_marker(marker),
        Term::var_term("x"),
      ),
    ),
    Term::unit(),
  )
}

///|
fn borrow_feature_program_for_tag(tag : String, marker : String) -> Term {
  if tag.contains("safe_shared_read_") {
    return borrow_feature_program_tuple(marker)
  }
  if tag.contains("safe_mut_reborrow_") {
    return borrow_feature_program_lambda(marker)
  }
  if tag.contains("safe_nll_last_use_") {
    return borrow_feature_program_let(marker)
  }
  if tag.contains("safe_branch_join_") {
    return borrow_feature_program_record(marker)
  }
  if tag.contains("safe_trait_poly_") {
    return borrow_feature_program_record(marker)
  }
  if tag.contains("safe_recursive_projection_") {
    return borrow_feature_program_tuple(marker)
  }
  if tag.contains("err_borrow_conflict_") {
    return borrow_feature_program_let(marker)
  }
  if tag.contains("err_use_after_move_") {
    return borrow_feature_program_tuple(marker)
  }
  if tag.contains("err_moved_value_borrow_") {
    return borrow_feature_program_record(marker)
  }
  if tag.contains("err_assign_to_immutable_") {
    return borrow_feature_program_let(marker)
  }
  if tag.contains("err_mutate_while_borrowed_") {
    return borrow_feature_program_lambda(marker)
  }
  if tag.contains("err_outlives_owner_") {
    return borrow_feature_program_record(marker)
  }
  if tag.contains("err_dangling_escape_") {
    return borrow_feature_program_record(marker)
  }
  if tag.contains("err_region_unsatisfied_") {
    return borrow_feature_program_tuple(marker)
  }
  if tag.contains("err_invalid_target_") {
    return borrow_feature_program_let(marker)
  }
  if tag.contains("err_trait_escape_") {
    return borrow_feature_program_lambda(marker)
  }
  if tag.contains("err_partial_move_projection_") {
    return borrow_feature_program_tuple(marker)
  }
  borrow_feature_program_let(marker)
}

///|
fn borrow_feature_marker_for_tag(tag : String) -> String {
  if tag.contains("safe_shared_read_") {
    return "BorrowFeatureSafeSharedRead"
  }
  if tag.contains("safe_mut_reborrow_") {
    return "BorrowFeatureSafeMutReborrow"
  }
  if tag.contains("safe_nll_last_use_") {
    return "BorrowFeatureSafeNllLastUse"
  }
  if tag.contains("safe_branch_join_") {
    return "BorrowFeatureSafeBranchJoin"
  }
  if tag.contains("safe_trait_poly_") {
    return "BorrowFeatureSafeTraitPoly"
  }
  if tag.contains("safe_recursive_projection_") {
    return "BorrowFeatureSafeRecursiveProjection"
  }
  if tag.contains("err_borrow_conflict_") {
    return "BorrowFeatureErrBorrowConflict"
  }
  if tag.contains("err_use_after_move_") {
    return "BorrowFeatureErrUseAfterMove"
  }
  if tag.contains("err_moved_value_borrow_") {
    return "BorrowFeatureErrMovedValueBorrow"
  }
  if tag.contains("err_assign_to_immutable_") {
    return "BorrowFeatureErrAssignToImmutable"
  }
  if tag.contains("err_mutate_while_borrowed_") {
    return "BorrowFeatureErrMutateWhileBorrowed"
  }
  if tag.contains("err_outlives_owner_") {
    return "BorrowFeatureErrOutlivesOwner"
  }
  if tag.contains("err_dangling_escape_") {
    return "BorrowFeatureErrDanglingEscape"
  }
  if tag.contains("err_region_unsatisfied_") {
    return "BorrowFeatureErrRegionUnsatisfied"
  }
  if tag.contains("err_invalid_target_") {
    return "BorrowFeatureErrInvalidTarget"
  }
  if tag.contains("err_trait_escape_") {
    return "BorrowFeatureErrTraitEscape"
  }
  if tag.contains("err_partial_move_projection_") {
    return "BorrowFeatureErrPartialMoveProjection"
  }
  "BorrowFeatureSafeFallback"
}

///|
fn borrow_feature_term(tag : String) -> Term {
  let marker = borrow_feature_marker_for_tag(tag)
  borrow_feature_program_for_tag(tag, marker)
}

///|
fn typing_error_kind_from_ir_result(
  result : Result[BorrowIr, TypingError],
) -> String {
  match result {
    Err(error) => typing_error_kind(error)
    Ok(_) => "Ok"
  }
}

///|
fn typing_error_kind_from_constraints_result(
  result : Result[Array[RegionConstraint], TypingError],
) -> String {
  match result {
    Err(error) => typing_error_kind(error)
    Ok(_) => "Ok"
  }
}

///|
fn typing_error_kind_from_solution_result(
  result : Result[RegionSolution, TypingError],
) -> String {
  match result {
    Err(error) => typing_error_kind(error)
    Ok(_) => "Ok"
  }
}

///|
fn typing_error_kind_from_facts_result(
  result : Result[BorrowFacts, TypingError],
) -> String {
  match result {
    Err(error) => typing_error_kind(error)
    Ok(_) => "Ok"
  }
}

///|
fn typing_error_kind_from_analysis_result(
  result : Result[BorrowAnalysisResult, TypingError],
) -> String {
  match result {
    Err(error) => typing_error_kind(error)
    Ok(_) => "Ok"
  }
}

///|
fn typing_error_kind_from_type_result(
  result : Result[Type, TypingError],
) -> String {
  match result {
    Err(error) => typing_error_kind(error)
    Ok(_) => "Ok"
  }
}

///|
fn typing_error_kind_from_checked_result(
  result : Result[CheckedType, TypingError],
) -> String {
  match result {
    Err(error) => typing_error_kind(error)
    Ok(_) => "Ok"
  }
}
