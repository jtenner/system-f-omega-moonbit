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
