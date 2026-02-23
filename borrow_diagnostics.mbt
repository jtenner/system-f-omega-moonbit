///|
fn place_key(place : Place) -> String {
  place.key_path()
}

///|
fn place_from_key_path(path : String) -> Place? {
  Place::from_key_path(path)
}

///|
fn invalid_target_operation_from_details(details : String) -> String? {
  let marker = " target is not a valid place expression"
  if !details.contains(marker) {
    return None
  }

  let parts = details.split(marker).map(StringView::to_string).collect()
  if parts.length() == 0 {
    return None
  }

  let operation = parts[0]
  if operation.is_empty() {
    return None
  }
  Some(operation)
}
