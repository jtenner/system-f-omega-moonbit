///|
test "sanity: fresh state and kind star" {
  let state = TypeCheckerState::fresh()
  ignore(state)
  assert_true(Kind::star() == Star)
}
