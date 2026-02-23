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
fn ordinary_constructor_term(tag : String) -> Term {
  Term::con(tag, Type::unit())
}

///|
fn borrow_semantic_error_term_for_kind(kind : String) -> Term {
  match kind {
    "UseAfterMove" => borrow_feature_term("err_use_after_move_01")
    "MovedValueBorrow" => borrow_feature_term("err_moved_value_borrow_01")
    "BorrowConflict" => borrow_feature_term("err_borrow_conflict_01")
    "MutateWhileBorrowed" => borrow_feature_term("err_mutate_while_borrowed_01")
    "AssignToImmutable" => borrow_feature_term("err_assign_to_immutable_01")
    "BorrowOutlivesOwner" => borrow_feature_term("err_outlives_owner_01")
    "DanglingReferenceEscape" => borrow_feature_term("err_dangling_escape_01")
    "InvalidBorrowTarget" => borrow_feature_term("err_invalid_target_01")
    "RegionConstraintUnsatisfied" =>
      borrow_feature_term("err_region_unsatisfied_01")
    _ => Term::unit()
  }
}

///|
fn borrow_feature_op(name : String) -> Term {
  Term::con(name, Type::unit())
}

///|
fn borrow_feature_ops_block(op_names : Array[String]) -> Term {
  let ops : Array[Term] = []
  for name in op_names {
    ops.push(borrow_feature_op(name))
  }
  ops.push(Term::unit())
  Term::tuple_project(Term::tuple(ops), ops.length() - 1)
}

///|
fn borrow_feature_program_let(op_names : Array[String]) -> Term {
  Term::let_term(
    "feature_ops",
    borrow_feature_ops_block(op_names),
    Term::unit(),
  )
}

///|
fn borrow_feature_program_tuple(op_names : Array[String]) -> Term {
  Term::tuple_project(
    Term::tuple([borrow_feature_ops_block(op_names), Term::unit()]),
    1,
  )
}

///|
fn borrow_feature_program_record(op_names : Array[String]) -> Term {
  Term::project(
    Term::record([
      ("feature_ops", borrow_feature_ops_block(op_names)),
      ("v", Term::unit()),
    ]),
    "v",
  )
}

///|
fn borrow_feature_program_lambda(op_names : Array[String]) -> Term {
  Term::app(
    Term::lam(
      "x",
      Type::unit(),
      Term::let_term(
        "feature_ops",
        borrow_feature_ops_block(op_names),
        Term::var_term("x"),
      ),
    ),
    Term::unit(),
  )
}

///|
fn borrow_feature_ops_for_tag(tag : String) -> Array[String] {
  if tag.contains("safe_shared_read_") {
    return [
      "BorrowOpBorrowShared__x", "BorrowOpBorrowShared__x__field:field", "BorrowOpUse__x__field:field",
    ]
  }
  if tag.contains("safe_mut_reborrow_") {
    return [
      "BorrowOpBorrowMut__x", "BorrowOpRelease__x", "BorrowOpBorrowMut__x",
    ]
  }
  if tag.contains("safe_nll_last_use_") {
    return [
      "BorrowOpBorrowShared__x", "BorrowOpRelease__x", "BorrowOpAssignMutable__x",
    ]
  }
  if tag.contains("safe_branch_join_") {
    return [
      "BorrowOpBorrowShared__x__field:field", "BorrowOpRelease__x", "BorrowOpBorrowShared__x",
    ]
  }
  if tag.contains("safe_trait_poly_") {
    return ["BorrowOpBorrowShared__y", "BorrowOpUse__y"]
  }
  if tag.contains("safe_recursive_projection_") {
    return [
      "BorrowOpBorrowShared__x__field:field", "BorrowOpUse__x__field:field",
    ]
  }
  if tag.contains("err_borrow_conflict_") {
    return ["BorrowOpBorrowMut__x", "BorrowOpBorrowShared__x__field:field"]
  }
  if tag.contains("err_use_after_move_") {
    return ["BorrowOpMove__x", "BorrowOpUse__x"]
  }
  if tag.contains("err_moved_value_borrow_") {
    return ["BorrowOpMove__x", "BorrowOpBorrowShared__x"]
  }
  if tag.contains("err_assign_to_immutable_") {
    return ["BorrowOpAssignImmutable__x"]
  }
  if tag.contains("err_mutate_while_borrowed_") {
    return ["BorrowOpBorrowShared__x", "BorrowOpAssignMutable__x"]
  }
  if tag.contains("err_outlives_owner_") {
    return ["BorrowOpRegionOutlivesOwner__x"]
  }
  if tag.contains("err_dangling_escape_") {
    return ["BorrowOpRegionDanglingEscape__x"]
  }
  if tag.contains("err_region_unsatisfied_") {
    return ["BorrowOpRegionUnsatisfied__named:alpha__named:omega"]
  }
  if tag.contains("err_invalid_target_") {
    return ["BorrowOpInvalidTarget__borrow_shared"]
  }
  if tag.contains("err_trait_escape_") {
    return ["BorrowOpRegionDanglingEscape__y"]
  }
  if tag.contains("err_partial_move_projection_") {
    return ["BorrowOpMove__x__field:field", "BorrowOpUse__x"]
  }
  ["BorrowOpBorrowShared__x", "BorrowOpRelease__x", "BorrowOpUse__x"]
}

///|
fn borrow_feature_program_for_tag(
  tag : String,
  op_names : Array[String],
) -> Term {
  if tag.contains("safe_shared_read_") {
    return borrow_feature_program_tuple(op_names)
  }
  if tag.contains("safe_mut_reborrow_") {
    return borrow_feature_program_lambda(op_names)
  }
  if tag.contains("safe_nll_last_use_") {
    return borrow_feature_program_let(op_names)
  }
  if tag.contains("safe_branch_join_") {
    return borrow_feature_program_record(op_names)
  }
  if tag.contains("safe_trait_poly_") {
    return borrow_feature_program_record(op_names)
  }
  if tag.contains("safe_recursive_projection_") {
    return borrow_feature_program_tuple(op_names)
  }
  if tag.contains("err_borrow_conflict_") {
    return borrow_feature_program_let(op_names)
  }
  if tag.contains("err_use_after_move_") {
    return borrow_feature_program_tuple(op_names)
  }
  if tag.contains("err_moved_value_borrow_") {
    return borrow_feature_program_record(op_names)
  }
  if tag.contains("err_assign_to_immutable_") {
    return borrow_feature_program_let(op_names)
  }
  if tag.contains("err_mutate_while_borrowed_") {
    return borrow_feature_program_lambda(op_names)
  }
  if tag.contains("err_outlives_owner_") {
    return borrow_feature_program_record(op_names)
  }
  if tag.contains("err_dangling_escape_") {
    return borrow_feature_program_record(op_names)
  }
  if tag.contains("err_region_unsatisfied_") {
    return borrow_feature_program_tuple(op_names)
  }
  if tag.contains("err_invalid_target_") {
    return borrow_feature_program_let(op_names)
  }
  if tag.contains("err_trait_escape_") {
    return borrow_feature_program_lambda(op_names)
  }
  if tag.contains("err_partial_move_projection_") {
    return borrow_feature_program_tuple(op_names)
  }
  borrow_feature_program_let(op_names)
}

///|
fn borrow_feature_term(tag : String) -> Term {
  let op_names = borrow_feature_ops_for_tag(tag)
  borrow_feature_program_for_tag(tag, op_names)
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
