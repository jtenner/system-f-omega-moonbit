///|
test "README beginner mental model enumerates core concepts in order" {
  let labels = readme_beginner_mental_model_labels()
  assert_eq(labels, [
    "Kind", "Type", "Term", "TypeCheckerState", "Context+MetaEnv",
  ])
}

///|
test "README quickstart borrow_shared accepted example infers shared ref" {
  let result = readme_quickstart_borrow_shared_accepted()

  match result {
    Ok(Ref(Named(region), Shared, Con(inner))) => {
      assert_eq(region, "borrow::x")
      assert_eq(inner, "Int")
    }
    _ => panic()
  }
}

///|
test "README quickstart borrow_shared rejected example reports InvalidBorrowTarget" {
  let result = readme_quickstart_borrow_shared_rejected()

  match result {
    Err(InvalidBorrowTarget(message)) =>
      assert_true(message.contains("borrow_shared"))
    _ => panic()
  }
}

///|
test "README quickstart borrow_mut accepted example infers mutable ref" {
  let result = readme_quickstart_borrow_mut_accepted()

  match result {
    Ok(Ref(Named(region), Mutable, Con(inner))) => {
      assert_eq(region, "borrow::x")
      assert_eq(inner, "Int")
    }
    _ => panic()
  }
}

///|
test "README quickstart borrow_mut rejected example reports BorrowConflict" {
  let result = readme_quickstart_borrow_mut_rejected()

  assert_true(result is Err(BorrowConflict(_, _)))
}

///|
test "README quickstart deref accepted example infers inner type" {
  let result = readme_quickstart_deref_accepted()

  match result {
    Ok(Con(name)) => assert_eq(name, "Int")
    _ => panic()
  }
}

///|
test "README quickstart deref rejected example reports InvalidBorrowTarget" {
  let result = readme_quickstart_deref_rejected()

  match result {
    Err(InvalidBorrowTarget(message)) => assert_true(message.contains("deref"))
    _ => panic()
  }
}

///|
test "README quickstart assign accepted example infers unit" {
  let result = readme_quickstart_assign_accepted()

  match result {
    Ok(Tuple(elements)) => assert_eq(elements.length(), 0)
    _ => panic()
  }
}

///|
test "README quickstart assign rejected example reports AssignToImmutable" {
  let result = readme_quickstart_assign_rejected()

  assert_true(result is Err(AssignToImmutable(_)))
}

///|
test "README quickstart move_term accepted example infers moved value type" {
  let result = readme_quickstart_move_term_accepted()

  match result {
    Ok(Con(name)) => assert_eq(name, "Int")
    _ => panic()
  }
}

///|
test "README quickstart move_term rejected example reports MovedValueBorrow" {
  let result = readme_quickstart_move_term_rejected()

  assert_true(result is Err(MovedValueBorrow(_)))
}
