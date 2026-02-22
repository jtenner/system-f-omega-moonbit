///|
fn eq_int_dict_term() -> Term {
  Term::dict("Eq", Type::con("Int"), [
    (
      "eq",
      Term::lam(
        "x",
        Type::con("Int"),
        Term::lam("y", Type::con("Int"), Term::con("true", Type::con("Bool"))),
      ),
    ),
  ])
}

///|
test "borrow scaffold preserves trait dictionary inference when disabled" {
  let state = state_with_eq_trait_and_int_dict()
  let term = eq_int_dict_term()

  let legacy = must_type(state.infer_type(term))
  let scaffold = must_type(
    state.infer_type_with_borrow_analysis(
      term,
      BorrowCheckerOptions::disabled(),
    ),
  )

  assert_true(legacy == scaffold)
}

///|
test "borrow analysis preserves trait dictionary inference when enabled" {
  let state = state_with_eq_trait_and_int_dict()
  let term = eq_int_dict_term()
  let legacy = state.infer_type(term)

  let result = state.infer_type_with_borrow_analysis(
    term,
    BorrowCheckerOptions::default(),
  )

  assert_true(result is Ok(_))
  match (legacy, result) {
    (Ok(a), Ok(b)) => assert_true(a == b)
    _ => panic()
  }
}

///|
test "borrow rule checker API accepts trait contexts" {
  let state = state_with_eq_trait_and_int_dict()
  let term = eq_int_dict_term()

  let result = state.check_borrow_rules(
    term,
    RegionSolution::empty(),
    BorrowCheckerOptions::default(),
  )

  assert_true(result is Ok(_))
}
