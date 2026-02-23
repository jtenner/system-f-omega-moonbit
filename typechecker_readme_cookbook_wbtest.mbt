///|
test "README cookbook higher-kinded kind checking example succeeds" {
  let result = readme_cookbook_higher_kinded_kind_example()
  match result {
    Ok((Arrow(Star, Star), Star)) => ()
    _ => panic()
  }
}

///|
test "README cookbook type-level lambda application example infers Int -> Int" {
  let result = readme_cookbook_type_level_lambda_application_example()
  match result {
    Ok(Arrow(Con(from), Con(to))) => {
      assert_eq(from, "Int")
      assert_eq(to, "Int")
    }
    _ => panic()
  }
}

///|
test "README cookbook forall and bounded forall example builds both polymorphic forms" {
  let result = readme_cookbook_forall_and_bounded_forall_example()
  match result {
    Ok((Forall(_, _, _), BoundedForall(_, _, _, _))) => ()
    _ => panic()
  }
}

///|
test "README cookbook traits dictionaries bounded polymorphism example resolves method type" {
  let result = readme_cookbook_traits_dictionaries_bounded_poly_example()
  let expected = Type::arrow(
    Type::con("Int"),
    Type::arrow(Type::con("Int"), Type::con("Bool")),
  )
  match result {
    Ok(ty) => assert_true(ty == expected)
    _ => panic()
  }
}

///|
test "README cookbook records variants tuples patterns example succeeds" {
  let result = readme_cookbook_records_variants_tuples_patterns_example()
  match result {
    Ok((record_project_ty, tuple_project_ty, match_ty)) => {
      assert_true(record_project_ty == Type::con("Bool"))
      assert_true(tuple_project_ty == Type::con("Bool"))
      assert_true(match_ty == Type::con("Int"))
    }
    _ => panic()
  }
}

///|
test "README cookbook recursive Mu fold/unfold example succeeds" {
  let result = readme_cookbook_recursive_mu_fold_unfold_example()
  match result {
    Ok((Mu(_, _), Tuple(elements))) => assert_true(elements.length() == 2)
    _ => panic()
  }
}

///|
test "README cookbook module import dependency rename example succeeds" {
  let result = readme_cookbook_import_dependency_rename_example()
  match result {
    Ok((deps_include_int, imported_has_value, rename_rewrites_free_term)) => {
      assert_true(deps_include_int)
      assert_true(imported_has_value)
      assert_true(rename_rewrites_free_term)
    }
    _ => panic()
  }
}

///|
test "README troubleshooting rows cover key borrow and typing errors" {
  let rows = readme_troubleshooting_rows()
  let keys = Set::new()
  for row in rows {
    keys.add(row.0)
  }

  assert_true(keys.contains("TypeMismatch"))
  assert_true(keys.contains("Unbound"))
  assert_true(keys.contains("BorrowConflict"))
  assert_true(keys.contains("UseAfterMove"))
  assert_true(keys.contains("InvalidBorrowTarget"))
  assert_true(keys.contains("RegionConstraintUnsatisfied"))
}
