///|
fn borrow_payload_error_for_kind(kind : String) -> TypingError {
  let state = TypeCheckerState::fresh()
  let result = state.analyze_borrows(
    borrow_semantic_error_term_for_kind(kind),
    Type::unit(),
    BorrowCheckerOptions::default(),
  )
  match result {
    Err(error) => error
    Ok(_) => panic()
  }
}

///|
fn expect_borrow_payload(error : TypingError) -> BorrowErrorPayload {
  match error.borrow_payload() {
    Some(payload) => payload
    None => panic()
  }
}

///|
test "RED: borrow_payload is None for non-borrow typing errors" {
  let payload = Unbound("missing").borrow_payload()
  assert_true(payload is None)
}

///|
test "RED: borrow payloads expose actionable fields across semantic borrow error kinds" {
  let kinds = [
    "UseAfterMove", "MovedValueBorrow", "BorrowConflict", "MutateWhileBorrowed",
    "AssignToImmutable", "BorrowOutlivesOwner", "DanglingReferenceEscape", "InvalidBorrowTarget",
    "RegionConstraintUnsatisfied",
  ]

  for kind in kinds {
    let payload = expect_borrow_payload(borrow_payload_error_for_kind(kind))
    assert_true(payload.error_kind == kind)
    assert_true(payload.operation is Some(_))

    match kind {
      "BorrowConflict" => {
        assert_true(payload.conflict is Some(_))
        assert_true(payload.active_loan_place_path is Some(_))
        assert_true(payload.requested_place_path is Some(_))
      }
      "RegionConstraintUnsatisfied" => {
        assert_true(payload.region_constraint is Some(_))
        match payload.region_constraint {
          Some(constraint) =>
            assert_true(
              constraint ==
              RegionConstraint::outlives(
                Region::named("alpha"),
                Region::named("omega"),
              ),
            )
          None => panic()
        }
      }
      "InvalidBorrowTarget" => {
        assert_true(payload.details is Some(_))
        match payload.operation {
          Some(operation) => assert_true(operation == "borrow_shared")
          None => panic()
        }
      }
      _ => assert_true(payload.place_path is Some(_))
    }
  }
}

///|
test "RED: borrow conflict payload includes active and requested place context" {
  let payload = expect_borrow_payload(
    borrow_payload_error_for_kind("BorrowConflict"),
  )
  match payload.conflict {
    Some(conflict) => {
      assert_true(conflict.active_loan_place.root == "x")
      assert_true(conflict.requested_place.root == "x")
      assert_true(conflict.requested_place.projections.length() == 1)
      assert_true(conflict.active_loan_place_path == "x")
      assert_true(conflict.requested_place_path == "x.field")
    }
    None => panic()
  }
}

///|
test "RED: direct infer_type borrow conflict keeps payload aligned with analyze_borrows" {
  let state = TypeCheckerState::fresh()
  let direct = state.infer_type(
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
  )

  let error = match direct {
    Err(error) => error
    Ok(_) => panic()
  }
  let payload = expect_borrow_payload(error)

  assert_true(payload.error_kind == "BorrowConflict")
  assert_true(payload.operation == Some("borrow"))
  assert_true(payload.place_path == Some("x"))
  assert_true(payload.active_loan_place_path == Some("x"))
  assert_true(payload.requested_place_path == Some("x"))
}

///|
test "RED: direct check_type invalid borrow target keeps operation and details payload" {
  let state = TypeCheckerState::fresh().extend_context([
    Binding::term("x", Type::con("Int")),
  ])
  let direct = state.check_type(
    Term::deref(Term::var_term("x")),
    Type::con("Int"),
  )

  let error = match direct {
    Err(error) => error
    Ok(_) => panic()
  }
  let payload = expect_borrow_payload(error)

  assert_true(payload.error_kind == "InvalidBorrowTarget")
  assert_true(payload.operation == Some("deref"))
  assert_true(payload.details is Some(_))
  assert_true(payload.place is None)
}
