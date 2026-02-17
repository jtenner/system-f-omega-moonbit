///|
fn parenthesize_if(text : String, needs_parens : Bool) -> String {
  if needs_parens {
    "(" + text + ")"
  } else {
    text
  }
}

///|
fn indent_block(text : String, indent : String) -> String {
  if text.is_empty() {
    text
  } else {
    indent + text.replace_all(old="\n", new="\n" + indent)
  }
}

///|
fn fresh_pretty_type_name(next_id : Int) -> (String, Int) {
  let greek = [
    "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ", "ν",
    "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω",
  ]
  let base = greek[next_id % greek.length()]
  let round = next_id / greek.length()
  let pretty_name = if round == 0 { base } else { base + round.to_string() }
  (pretty_name, next_id + 1)
}

///|
fn lookup_type_name(type_env : Map[String, String], name : String) -> String {
  match type_env.get(name) {
    Some(pretty_name) => pretty_name
    None => name
  }
}

///|
fn kind_to_ascii(kind : Kind, prec : Int) -> String {
  match kind {
    Star => "Star"
    Arrow(left, right) => {
      let text = kind_to_ascii(left, 1) + " -> " + kind_to_ascii(right, 0)
      parenthesize_if(text, prec > 0)
    }
  }
}

///|
fn kind_to_pretty(kind : Kind, prec : Int) -> String {
  match kind {
    Star => "★"
    Arrow(left, right) => {
      let text = kind_to_pretty(left, 1) + " → " + kind_to_pretty(right, 0)
      parenthesize_if(text, prec > 0)
    }
  }
}

///|
fn type_to_ascii(ty : Type, prec : Int) -> String {
  match ty {
    Var(name) => name
    Con(name) => name
    EVar(name) => "?" + name
    Never => "Never"
    Arrow(from_ty, to_ty) => {
      let text = type_to_ascii(from_ty, 1) + " -> " + type_to_ascii(to_ty, 0)
      parenthesize_if(text, prec > 0)
    }
    Forall(name, kind, body) => {
      let text = "forall " +
        name +
        " : " +
        kind_to_ascii(kind, 0) +
        ". " +
        type_to_ascii(body, 0)
      parenthesize_if(text, prec > 0)
    }
    BoundedForall(name, kind, constraints, body) => {
      let constraints_text = constraints
        .map(c => c.trait_name + " " + type_to_ascii(c.ty, 1))
        .join(", ")
      let quant = "forall " + name + " : " + kind_to_ascii(kind, 0) + ". "
      let text = if constraints.is_empty() {
        quant + type_to_ascii(body, 0)
      } else {
        quant + "(" + constraints_text + ") => " + type_to_ascii(body, 0)
      }
      parenthesize_if(text, prec > 0)
    }
    Lam(name, kind, body) => {
      let text = "\\" +
        name +
        " : " +
        kind_to_ascii(kind, 0) +
        ". " +
        type_to_ascii(body, 0)
      parenthesize_if(text, prec > 0)
    }
    App(fn_ty, arg_ty) => {
      let text = type_to_ascii(fn_ty, 1) + " " + type_to_ascii(arg_ty, 2)
      parenthesize_if(text, prec > 1)
    }
    Record(fields) => {
      let text = fields
        .map(fn(field) {
          let (label, field_ty) = field
          label + " : " + type_to_ascii(field_ty, 0)
        })
        .join(", ")
      "{" + text + "}"
    }
    Variant(cases) => {
      let text = cases
        .map(fn(case_ty) {
          let (label, payload_ty) = case_ty
          label + " : " + type_to_ascii(payload_ty, 0)
        })
        .join(" | ")
      "[" + text + "]"
    }
    Mu(name, body) => {
      let text = "mu " + name + ". " + type_to_ascii(body, 0)
      parenthesize_if(text, prec > 0)
    }
    Tuple(items) =>
      if items.is_empty() {
        "()"
      } else {
        "(" + items.map(item => type_to_ascii(item, 0)).join(", ") + ")"
      }
  }
}

///|
fn type_to_pretty(
  ty : Type,
  type_env : Map[String, String],
  next_type_id : Int,
  prec : Int,
) -> (String, Int) {
  match ty {
    Var(name) => (lookup_type_name(type_env, name), next_type_id)
    Con(name) => (name, next_type_id)
    EVar(name) => ("?" + name, next_type_id)
    Never => ("⊥", next_type_id)
    Arrow(from_ty, to_ty) => {
      let (from_text, next1) = type_to_pretty(
        from_ty, type_env, next_type_id, 1,
      )
      let (to_text, next2) = type_to_pretty(to_ty, type_env, next1, 0)
      let text = from_text + " → " + to_text
      (parenthesize_if(text, prec > 0), next2)
    }
    Forall(name, kind, body) => {
      let (pretty_name, next1) = fresh_pretty_type_name(next_type_id)
      let next_env = type_env.copy()
      next_env.set(name, pretty_name)
      let (body_text, next2) = type_to_pretty(body, next_env, next1, 0)
      let text = "∀" +
        pretty_name +
        ":" +
        kind_to_pretty(kind, 0) +
        ". " +
        body_text
      (parenthesize_if(text, prec > 0), next2)
    }
    BoundedForall(name, kind, constraints, body) => {
      let (pretty_name, next1) = fresh_pretty_type_name(next_type_id)
      let next_env = type_env.copy()
      next_env.set(name, pretty_name)

      let constraints_parts : Array[String] = []
      let mut next2 = next1
      for constraint in constraints {
        let (constraint_text, next_constraint) = type_to_pretty(
          constraint.ty,
          next_env,
          next2,
          1,
        )
        constraints_parts.push(constraint.trait_name + " " + constraint_text)
        next2 = next_constraint
      }

      let (body_text, next3) = type_to_pretty(body, next_env, next2, 0)
      let prefix = "∀" + pretty_name + ":" + kind_to_pretty(kind, 0) + ". "
      let text = if constraints_parts.is_empty() {
        prefix + body_text
      } else {
        prefix + "(" + constraints_parts.join(", ") + ") ⇒ " + body_text
      }
      (parenthesize_if(text, prec > 0), next3)
    }
    Lam(name, kind, body) => {
      let (pretty_name, next1) = fresh_pretty_type_name(next_type_id)
      let next_env = type_env.copy()
      next_env.set(name, pretty_name)
      let (body_text, next2) = type_to_pretty(body, next_env, next1, 0)
      let text = "λ" +
        pretty_name +
        ":" +
        kind_to_pretty(kind, 0) +
        ". " +
        body_text
      (parenthesize_if(text, prec > 0), next2)
    }
    App(fn_ty, arg_ty) => {
      let (fn_text, next1) = type_to_pretty(fn_ty, type_env, next_type_id, 1)
      let (arg_text, next2) = type_to_pretty(arg_ty, type_env, next1, 2)
      let text = fn_text + " " + arg_text
      (parenthesize_if(text, prec > 1), next2)
    }
    Record(fields) => {
      let field_parts : Array[String] = []
      let mut next1 = next_type_id
      for field in fields {
        let (label, field_ty) = field
        let (field_text, next_field) = type_to_pretty(
          field_ty, type_env, next1, 0,
        )
        field_parts.push(label + " : " + field_text)
        next1 = next_field
      }
      ("{" + field_parts.join(", ") + "}", next1)
    }
    Variant(cases) => {
      let case_parts : Array[String] = []
      let mut next1 = next_type_id
      for case_ty in cases {
        let (label, payload_ty) = case_ty
        let (case_text, next_case) = type_to_pretty(
          payload_ty, type_env, next1, 0,
        )
        case_parts.push(label + " : " + case_text)
        next1 = next_case
      }
      ("⟨" + case_parts.join(" | ") + "⟩", next1)
    }
    Mu(name, body) => {
      let (pretty_name, next1) = fresh_pretty_type_name(next_type_id)
      let next_env = type_env.copy()
      next_env.set(name, pretty_name)
      let (body_text, next2) = type_to_pretty(body, next_env, next1, 0)
      let text = "μ" + pretty_name + ". " + body_text
      (parenthesize_if(text, prec > 0), next2)
    }
    Tuple(items) => {
      if items.is_empty() {
        return ("()", next_type_id)
      }
      let parts : Array[String] = []
      let mut next1 = next_type_id
      for item in items {
        let (item_text, next_item) = type_to_pretty(item, type_env, next1, 0)
        parts.push(item_text)
        next1 = next_item
      }
      ("(" + parts.join(" × ") + ")", next1)
    }
  }
}

///|
fn pattern_to_ascii(pattern : Pattern) -> String {
  match pattern {
    VarPattern(name) => name
    WildcardPattern => "_"
    ConPattern(name, ty) => name + " : " + type_to_ascii(ty, 0)
    RecordPattern(fields) => {
      let text = fields
        .map(fn(field) {
          let (label, field_pattern) = field
          label + " = " + pattern_to_ascii(field_pattern)
        })
        .join(", ")
      "{" + text + "}"
    }
    VariantPattern(label, inner) =>
      "<" + label + " = " + pattern_to_ascii(inner) + ">"
    TuplePattern(items) =>
      if items.is_empty() {
        "()"
      } else {
        "(" + items.map(pattern_to_ascii).join(", ") + ")"
      }
  }
}

///|
fn pattern_to_pretty(
  pattern : Pattern,
  type_env : Map[String, String],
  next_type_id : Int,
) -> (String, Int) {
  match pattern {
    VarPattern(name) => (name, next_type_id)
    WildcardPattern => ("_", next_type_id)
    ConPattern(name, ty) => {
      let (ty_text, next1) = type_to_pretty(ty, type_env, next_type_id, 0)
      (name + " : " + ty_text, next1)
    }
    RecordPattern(fields) => {
      let parts : Array[String] = []
      let mut next1 = next_type_id
      for field in fields {
        let (label, field_pattern) = field
        let (pattern_text, next_pattern) = pattern_to_pretty(
          field_pattern, type_env, next1,
        )
        parts.push(label + " = " + pattern_text)
        next1 = next_pattern
      }
      ("{" + parts.join(", ") + "}", next1)
    }
    VariantPattern(label, inner) => {
      let (inner_text, next1) = pattern_to_pretty(inner, type_env, next_type_id)
      ("⟨" + label + " = " + inner_text + "⟩", next1)
    }
    TuplePattern(items) => {
      if items.is_empty() {
        return ("()", next_type_id)
      }
      let parts : Array[String] = []
      let mut next1 = next_type_id
      for item in items {
        let (item_text, next_item) = pattern_to_pretty(item, type_env, next1)
        parts.push(item_text)
        next1 = next_item
      }
      ("(" + parts.join(", ") + ")", next1)
    }
  }
}

///|
fn term_to_ascii(term : Term, prec : Int) -> String {
  match term {
    Var(name) => name
    Con(name, ty) => name + " : " + type_to_ascii(ty, 0)
    Lam(name, ty, body) => {
      let text = "\\" +
        name +
        " : " +
        type_to_ascii(ty, 0) +
        ". " +
        term_to_ascii(body, 0)
      parenthesize_if(text, prec > 0)
    }
    App(fn_term, arg_term) => {
      let text = term_to_ascii(fn_term, 1) + " " + term_to_ascii(arg_term, 2)
      parenthesize_if(text, prec > 1)
    }
    Let(name, value, body) => {
      let text = "let " +
        name +
        " = " +
        term_to_ascii(value, 0) +
        " in " +
        term_to_ascii(body, 0)
      parenthesize_if(text, prec > 0)
    }
    TyLam(name, kind, body) => {
      let text = "/\\" +
        name +
        " : " +
        kind_to_ascii(kind, 0) +
        ". " +
        term_to_ascii(body, 0)
      parenthesize_if(text, prec > 0)
    }
    TyApp(fn_term, ty) => {
      let text = term_to_ascii(fn_term, 2) + " [" + type_to_ascii(ty, 0) + "]"
      parenthesize_if(text, prec > 1)
    }
    Dict(trait_name, ty, methods) => {
      let methods_text = methods
        .map(fn(dict_entry) {
          let (method_name, method_term) = dict_entry
          method_name + " = " + term_to_ascii(method_term, 0)
        })
        .join(", ")
      "dict " +
      trait_name +
      " " +
      type_to_ascii(ty, 0) +
      " {" +
      methods_text +
      "}"
    }
    TraitLam(dict_name, trait_name, type_param, kind, constraints, body) => {
      let constraints_text = constraints
        .map(c => c.trait_name + " " + type_to_ascii(c.ty, 1))
        .join(", ")
      let head = "traitlam " +
        dict_name +
        " : " +
        trait_name +
        " " +
        type_param +
        " : " +
        kind_to_ascii(kind, 0)
      let head = if constraints.is_empty() {
        head
      } else {
        head + " where " + constraints_text
      }
      let text = head + ". " + term_to_ascii(body, 0)
      parenthesize_if(text, prec > 0)
    }
    TraitApp(fn_term, ty, dicts) => {
      let dict_text = dicts.map(d => term_to_ascii(d, 0)).join(", ")
      let args = if dicts.is_empty() {
        type_to_ascii(ty, 0)
      } else {
        type_to_ascii(ty, 0) + "; " + dict_text
      }
      let text = term_to_ascii(fn_term, 2) + " {" + args + "}"
      parenthesize_if(text, prec > 1)
    }
    TraitMethod(dict_term, method_name) => {
      let text = term_to_ascii(dict_term, 2) + "." + method_name
      parenthesize_if(text, prec > 1)
    }
    Record(fields) => {
      let text = fields
        .map(fn(field) {
          let (label, value) = field
          label + " = " + term_to_ascii(value, 0)
        })
        .join(", ")
      "{" + text + "}"
    }
    Project(record_term, label) => {
      let text = term_to_ascii(record_term, 2) + "." + label
      parenthesize_if(text, prec > 1)
    }
    Inject(label, payload, ty) =>
      "<" +
      label +
      " = " +
      term_to_ascii(payload, 0) +
      "> as " +
      type_to_ascii(ty, 0)
    Match(scrutinee, branches) => {
      let branches_text = branches
        .map(fn(branch) {
          let (pat, body) = branch
          pattern_to_ascii(pat) + " -> " + term_to_ascii(body, 0)
        })
        .join(" | ")
      let text = "match " +
        term_to_ascii(scrutinee, 0) +
        " { " +
        branches_text +
        " }"
      parenthesize_if(text, prec > 0)
    }
    Fold(ty, folded) => {
      let text = "fold [" +
        type_to_ascii(ty, 0) +
        "] " +
        term_to_ascii(folded, 2)
      parenthesize_if(text, prec > 1)
    }
    Unfold(folded) => {
      let text = "unfold " + term_to_ascii(folded, 2)
      parenthesize_if(text, prec > 1)
    }
    Tuple(items) =>
      if items.is_empty() {
        "()"
      } else {
        "(" + items.map(item => term_to_ascii(item, 0)).join(", ") + ")"
      }
    TupleProject(tuple_term, index) => {
      let text = term_to_ascii(tuple_term, 2) + "." + index.to_string()
      parenthesize_if(text, prec > 1)
    }
  }
}

///|
fn term_to_pretty(
  term : Term,
  type_env : Map[String, String],
  next_type_id : Int,
  prec : Int,
  indent : String,
) -> (String, Int) {
  match term {
    Var(name) => (name, next_type_id)
    Con(name, ty) => {
      let (ty_text, next1) = type_to_pretty(ty, type_env, next_type_id, 0)
      (name + " : " + ty_text, next1)
    }
    Lam(name, ty, body) => {
      let (ty_text, next1) = type_to_pretty(ty, type_env, next_type_id, 0)
      let (body_text, next2) = term_to_pretty(body, type_env, next1, 0, indent)
      let text = "λ" + name + ":" + ty_text + ". " + body_text
      (parenthesize_if(text, prec > 0), next2)
    }
    App(fn_term, arg_term) => {
      let (fn_text, next1) = term_to_pretty(
        fn_term, type_env, next_type_id, 1, indent,
      )
      let (arg_text, next2) = term_to_pretty(
        arg_term, type_env, next1, 2, indent,
      )
      let text = fn_text + " " + arg_text
      (parenthesize_if(text, prec > 1), next2)
    }
    Let(name, value, body) => {
      let (value_text, next1) = term_to_pretty(
        value, type_env, next_type_id, 0, indent,
      )
      let (body_text, next2) = term_to_pretty(body, type_env, next1, 0, indent)
      let text = "let " + name + " = " + value_text + " in " + body_text
      (parenthesize_if(text, prec > 0), next2)
    }
    TyLam(name, kind, body) => {
      let (pretty_name, next1) = fresh_pretty_type_name(next_type_id)
      let next_env = type_env.copy()
      next_env.set(name, pretty_name)
      let (body_text, next2) = term_to_pretty(body, next_env, next1, 0, indent)
      let text = "Λ" +
        pretty_name +
        ":" +
        kind_to_pretty(kind, 0) +
        ". " +
        body_text
      (parenthesize_if(text, prec > 0), next2)
    }
    TyApp(fn_term, ty) => {
      let (fn_text, next1) = term_to_pretty(
        fn_term, type_env, next_type_id, 2, indent,
      )
      let (ty_text, next2) = type_to_pretty(ty, type_env, next1, 0)
      let text = fn_text + " ⟦" + ty_text + "⟧"
      (parenthesize_if(text, prec > 1), next2)
    }
    Dict(trait_name, ty, methods) => {
      let (ty_text, next1) = type_to_pretty(ty, type_env, next_type_id, 0)
      let parts : Array[String] = []
      let mut next2 = next1
      for dict_entry in methods {
        let (method_name, method_body) = dict_entry
        let (method_text, next_method) = term_to_pretty(
          method_body,
          type_env,
          next2,
          0,
          indent + "  ",
        )
        parts.push(method_name + " = " + method_text)
        next2 = next_method
      }
      let text = "⟪" +
        trait_name +
        " " +
        ty_text +
        " { " +
        parts.join(", ") +
        " }⟫"
      (text, next2)
    }
    TraitLam(dict_name, trait_name, type_param, kind, constraints, body) => {
      let (pretty_name, next1) = fresh_pretty_type_name(next_type_id)
      let next_env = type_env.copy()
      next_env.set(type_param, pretty_name)

      let constraints_parts : Array[String] = []
      let mut next2 = next1
      for constraint in constraints {
        let (constraint_text, next_constraint) = type_to_pretty(
          constraint.ty,
          next_env,
          next2,
          1,
        )
        constraints_parts.push(constraint.trait_name + " " + constraint_text)
        next2 = next_constraint
      }

      let (body_text, next3) = term_to_pretty(body, next_env, next2, 0, indent)
      let head = "Λ" +
        dict_name +
        " : " +
        trait_name +
        " " +
        pretty_name +
        ":" +
        kind_to_pretty(kind, 0)
      let head = if constraints_parts.is_empty() {
        head
      } else {
        head + " where (" + constraints_parts.join(", ") + ")"
      }
      let text = head + ". " + body_text
      (parenthesize_if(text, prec > 0), next3)
    }
    TraitApp(fn_term, ty, dicts) => {
      let (fn_text, next1) = term_to_pretty(
        fn_term, type_env, next_type_id, 2, indent,
      )
      let (ty_text, next2) = type_to_pretty(ty, type_env, next1, 0)

      let dict_parts : Array[String] = []
      let mut next3 = next2
      for dict_term in dicts {
        let (dict_text, next_dict) = term_to_pretty(
          dict_term, type_env, next3, 0, indent,
        )
        dict_parts.push(dict_text)
        next3 = next_dict
      }

      let args = if dict_parts.is_empty() {
        ty_text
      } else {
        ty_text + " ; " + dict_parts.join(", ")
      }
      let text = fn_text + " ⟨" + args + "⟩"
      (parenthesize_if(text, prec > 1), next3)
    }
    TraitMethod(dict_term, method_name) => {
      let (dict_text, next1) = term_to_pretty(
        dict_term, type_env, next_type_id, 2, indent,
      )
      let text = dict_text + "." + method_name
      (parenthesize_if(text, prec > 1), next1)
    }
    Record(fields) => {
      let parts : Array[String] = []
      let mut next1 = next_type_id
      for field in fields {
        let (label, value) = field
        let (value_text, next_value) = term_to_pretty(
          value, type_env, next1, 0, indent,
        )
        parts.push(label + " = " + value_text)
        next1 = next_value
      }
      ("{" + parts.join(", ") + "}", next1)
    }
    Project(record_term, label) => {
      let (record_text, next1) = term_to_pretty(
        record_term, type_env, next_type_id, 2, indent,
      )
      let text = record_text + "." + label
      (parenthesize_if(text, prec > 1), next1)
    }
    Inject(label, payload, ty) => {
      let (payload_text, next1) = term_to_pretty(
        payload, type_env, next_type_id, 0, indent,
      )
      let (ty_text, next2) = type_to_pretty(ty, type_env, next1, 0)
      let text = "⟨" + label + " = " + payload_text + "⟩ : " + ty_text
      (text, next2)
    }
    Match(scrutinee, branches) => {
      let (scrutinee_text, next1) = term_to_pretty(
        scrutinee, type_env, next_type_id, 0, indent,
      )

      let lines : Array[String] = ["match " + scrutinee_text + " with"]
      let mut next2 = next1
      for branch in branches {
        let (pat, body) = branch
        let (pat_text, next_pattern) = pattern_to_pretty(pat, type_env, next2)
        next2 = next_pattern
        let (body_text, next_body) = term_to_pretty(
          body,
          type_env,
          next2,
          0,
          indent + "  ",
        )
        next2 = next_body

        if body_text.contains("\n") {
          lines.push(indent + "| " + pat_text + " ⇒")
          lines.push(indent_block(body_text, indent + "  "))
        } else {
          lines.push(indent + "| " + pat_text + " ⇒ " + body_text)
        }
      }

      let text = lines.join("\n")
      (parenthesize_if(text, prec > 0), next2)
    }
    Fold(ty, folded) => {
      let (ty_text, next1) = type_to_pretty(ty, type_env, next_type_id, 0)
      let (folded_text, next2) = term_to_pretty(
        folded, type_env, next1, 2, indent,
      )
      let text = "fold[" + ty_text + "] " + folded_text
      (parenthesize_if(text, prec > 1), next2)
    }
    Unfold(folded) => {
      let (folded_text, next1) = term_to_pretty(
        folded, type_env, next_type_id, 2, indent,
      )
      let text = "unfold " + folded_text
      (parenthesize_if(text, prec > 1), next1)
    }
    Tuple(items) => {
      if items.is_empty() {
        return ("()", next_type_id)
      }
      let parts : Array[String] = []
      let mut next1 = next_type_id
      for item in items {
        let (item_text, next_item) = term_to_pretty(
          item, type_env, next1, 0, indent,
        )
        parts.push(item_text)
        next1 = next_item
      }
      ("(" + parts.join(", ") + ")", next1)
    }
    TupleProject(tuple_term, index) => {
      let (tuple_text, next1) = term_to_pretty(
        tuple_term, type_env, next_type_id, 2, indent,
      )
      let text = tuple_text + ".#" + index.to_string()
      (parenthesize_if(text, prec > 1), next1)
    }
  }
}

///|
fn kind_to_repr(kind : Kind) -> Repr {
  match kind {
    Star => Repr::ctor("Star", [])
    Arrow(left, right) =>
      Repr::ctor("Arrow", [
        (None, kind_to_repr(left)),
        (None, kind_to_repr(right)),
      ])
  }
}

///|
fn trait_constraint_to_repr(constraint : TraitConstraint) -> Repr {
  Repr::ctor("TraitConstraint", [
    (Some("trait_name"), Repr::string(constraint.trait_name)),
    (Some("ty"), type_to_repr(constraint.ty)),
  ])
}

///|
fn type_field_to_repr(field : (String, Type)) -> Repr {
  let (label, field_ty) = field
  Repr::tuple([Repr::string(label), type_to_repr(field_ty)])
}

///|
fn type_to_repr(ty : Type) -> Repr {
  match ty {
    Var(name) => Repr::ctor("Var", [(None, Repr::string(name))])
    Con(name) => Repr::ctor("Con", [(None, Repr::string(name))])
    EVar(name) => Repr::ctor("EVar", [(None, Repr::string(name))])
    Never => Repr::ctor("Never", [])
    Arrow(from_ty, to_ty) =>
      Repr::ctor("Arrow", [
        (None, type_to_repr(from_ty)),
        (None, type_to_repr(to_ty)),
      ])
    Forall(name, kind, body) =>
      Repr::ctor("Forall", [
        (Some("name"), Repr::string(name)),
        (Some("kind"), kind_to_repr(kind)),
        (Some("body"), type_to_repr(body)),
      ])
    BoundedForall(name, kind, constraints, body) =>
      Repr::ctor("BoundedForall", [
        (Some("name"), Repr::string(name)),
        (Some("kind"), kind_to_repr(kind)),
        (
          Some("constraints"),
          Repr::array(constraints.map(trait_constraint_to_repr)),
        ),
        (Some("body"), type_to_repr(body)),
      ])
    Lam(name, kind, body) =>
      Repr::ctor("Lam", [
        (Some("name"), Repr::string(name)),
        (Some("kind"), kind_to_repr(kind)),
        (Some("body"), type_to_repr(body)),
      ])
    App(fn_ty, arg_ty) =>
      Repr::ctor("App", [
        (None, type_to_repr(fn_ty)),
        (None, type_to_repr(arg_ty)),
      ])
    Record(fields) =>
      Repr::ctor("Record", [(None, Repr::array(fields.map(type_field_to_repr)))])
    Variant(cases) =>
      Repr::ctor("Variant", [(None, Repr::array(cases.map(type_field_to_repr)))])
    Mu(name, body) =>
      Repr::ctor("Mu", [
        (Some("name"), Repr::string(name)),
        (Some("body"), type_to_repr(body)),
      ])
    Tuple(items) =>
      Repr::ctor("Tuple", [(None, Repr::array(items.map(type_to_repr)))])
  }
}

///|
fn term_field_to_repr(field : (String, Term)) -> Repr {
  let (label, value) = field
  Repr::tuple([Repr::string(label), term_to_repr(value)])
}

///|
fn pattern_term_case_to_repr(branch : (Pattern, Term)) -> Repr {
  let (pat, body) = branch
  Repr::tuple([pattern_to_repr(pat), term_to_repr(body)])
}

///|
fn term_to_repr(term : Term) -> Repr {
  match term {
    Var(name) => Repr::ctor("Var", [(None, Repr::string(name))])
    Con(name, ty) =>
      Repr::ctor("Con", [
        (Some("name"), Repr::string(name)),
        (Some("ty"), type_to_repr(ty)),
      ])
    Lam(name, ty, body) =>
      Repr::ctor("Lam", [
        (Some("name"), Repr::string(name)),
        (Some("ty"), type_to_repr(ty)),
        (Some("body"), term_to_repr(body)),
      ])
    App(fn_term, arg_term) =>
      Repr::ctor("App", [
        (Some("fn_term"), term_to_repr(fn_term)),
        (Some("arg_term"), term_to_repr(arg_term)),
      ])
    Let(name, value, body) =>
      Repr::ctor("Let", [
        (Some("name"), Repr::string(name)),
        (Some("value"), term_to_repr(value)),
        (Some("body"), term_to_repr(body)),
      ])
    TyLam(name, kind, body) =>
      Repr::ctor("TyLam", [
        (Some("name"), Repr::string(name)),
        (Some("kind"), kind_to_repr(kind)),
        (Some("body"), term_to_repr(body)),
      ])
    TyApp(fn_term, ty) =>
      Repr::ctor("TyApp", [
        (Some("fn_term"), term_to_repr(fn_term)),
        (Some("ty"), type_to_repr(ty)),
      ])
    Dict(trait_name, ty, methods) =>
      Repr::ctor("Dict", [
        (Some("trait_name"), Repr::string(trait_name)),
        (Some("ty"), type_to_repr(ty)),
        (Some("methods"), Repr::array(methods.map(term_field_to_repr))),
      ])
    TraitLam(dict_name, trait_name, type_param, kind, constraints, body) =>
      Repr::ctor("TraitLam", [
        (Some("dict_name"), Repr::string(dict_name)),
        (Some("trait_name"), Repr::string(trait_name)),
        (Some("type_param"), Repr::string(type_param)),
        (Some("kind"), kind_to_repr(kind)),
        (
          Some("constraints"),
          Repr::array(constraints.map(trait_constraint_to_repr)),
        ),
        (Some("body"), term_to_repr(body)),
      ])
    TraitApp(fn_term, ty, dicts) =>
      Repr::ctor("TraitApp", [
        (Some("fn_term"), term_to_repr(fn_term)),
        (Some("ty"), type_to_repr(ty)),
        (Some("dicts"), Repr::array(dicts.map(term_to_repr))),
      ])
    TraitMethod(dict_term, method_name) =>
      Repr::ctor("TraitMethod", [
        (Some("dict_term"), term_to_repr(dict_term)),
        (Some("method_name"), Repr::string(method_name)),
      ])
    Record(fields) =>
      Repr::ctor("Record", [(None, Repr::array(fields.map(term_field_to_repr)))])
    Project(record_term, label) =>
      Repr::ctor("Project", [
        (Some("record_term"), term_to_repr(record_term)),
        (Some("label"), Repr::string(label)),
      ])
    Inject(label, payload, ty) =>
      Repr::ctor("Inject", [
        (Some("label"), Repr::string(label)),
        (Some("payload"), term_to_repr(payload)),
        (Some("ty"), type_to_repr(ty)),
      ])
    Match(scrutinee, branches) =>
      Repr::ctor("Match", [
        (Some("scrutinee"), term_to_repr(scrutinee)),
        (Some("branches"), Repr::array(branches.map(pattern_term_case_to_repr))),
      ])
    Fold(ty, folded) =>
      Repr::ctor("Fold", [
        (Some("ty"), type_to_repr(ty)),
        (Some("folded"), term_to_repr(folded)),
      ])
    Unfold(folded) =>
      Repr::ctor("Unfold", [(Some("folded"), term_to_repr(folded))])
    Tuple(items) =>
      Repr::ctor("Tuple", [(None, Repr::array(items.map(term_to_repr)))])
    TupleProject(tuple_term, index) =>
      Repr::ctor("TupleProject", [
        (Some("tuple_term"), term_to_repr(tuple_term)),
        (Some("index"), Repr::integer(index.to_string())),
      ])
  }
}

///|
fn pattern_field_to_repr(field : (String, Pattern)) -> Repr {
  let (label, value) = field
  Repr::tuple([Repr::string(label), pattern_to_repr(value)])
}

///|
fn pattern_to_repr(pattern : Pattern) -> Repr {
  match pattern {
    VarPattern(name) => Repr::ctor("VarPattern", [(None, Repr::string(name))])
    WildcardPattern => Repr::ctor("WildcardPattern", [])
    ConPattern(name, ty) =>
      Repr::ctor("ConPattern", [
        (Some("name"), Repr::string(name)),
        (Some("ty"), type_to_repr(ty)),
      ])
    RecordPattern(fields) =>
      Repr::ctor("RecordPattern", [
        (None, Repr::array(fields.map(pattern_field_to_repr))),
      ])
    VariantPattern(label, inner) =>
      Repr::ctor("VariantPattern", [
        (Some("label"), Repr::string(label)),
        (Some("inner"), pattern_to_repr(inner)),
      ])
    TuplePattern(items) =>
      Repr::ctor("TuplePattern", [
        (None, Repr::array(items.map(pattern_to_repr))),
      ])
  }
}

///|
pub fn Type::pretty_print(self : Type) -> String {
  let type_env : Map[String, String] = Map::new()
  let rendered = type_to_pretty(self, type_env, 0, 0).0
  rendered
}

///|
pub fn Term::pretty_print(self : Term) -> String {
  let type_env : Map[String, String] = Map::new()
  let rendered = term_to_pretty(self, type_env, 0, 0, "").0
  rendered
}

///|
pub fn Pattern::pretty_print(self : Pattern) -> String {
  let type_env : Map[String, String] = Map::new()
  let rendered = pattern_to_pretty(self, type_env, 0).0
  rendered
}

///|
pub fn pretty_type(ty : Type) -> String {
  ty.pretty_print()
}

///|
pub fn pretty_term(term : Term) -> String {
  term.pretty_print()
}

///|
pub fn pretty_pattern(pattern : Pattern) -> String {
  pattern.pretty_print()
}

///|
pub impl Show for Type with output(self, logger) {
  logger.write_string(type_to_ascii(self, 0))
}

///|
pub impl Show for Term with output(self, logger) {
  logger.write_string(term_to_ascii(self, 0))
}

///|
pub impl Show for Pattern with output(self, logger) {
  logger.write_string(pattern_to_ascii(self))
}

///|
pub impl Debug for Type with to_repr(self) {
  type_to_repr(self)
}

///|
pub impl Debug for Term with to_repr(self) {
  term_to_repr(self)
}

///|
pub impl Debug for Pattern with to_repr(self) {
  pattern_to_repr(self)
}

///|
test "show and debug snapshots for type constructors" {
  inspect(Type::var_type("A"), content="A")
  debug_inspect(Type::var_type("A"), content="Var(\"A\")")

  inspect(Type::con("Int"), content="Int")
  debug_inspect(Type::con("Int"), content="Con(\"Int\")")

  inspect(EVar("0"), content="?0")
  debug_inspect(EVar("0"), content="EVar(\"0\")")

  inspect(Type::never(), content="Never")
  debug_inspect(Type::never(), content="Never")

  let fn_ty = Type::arrow(Type::con("Int"), Type::con("Bool"))
  inspect(fn_ty, content="Int -> Bool")
  debug_inspect(fn_ty, content="Arrow(Con(\"Int\"), Con(\"Bool\"))")

  let forall_ty = Type::forall(
    "A",
    Star,
    Type::arrow(Type::var_type("A"), Type::var_type("A")),
  )
  inspect(forall_ty, content="forall A : Star. A -> A")
  debug_inspect(
    forall_ty,
    content="Forall(name=\"A\", kind=Star, body=Arrow(Var(\"A\"), Var(\"A\")))",
  )

  let bounded = Type::bounded_forall(
    "A",
    Star,
    [
      TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") },
      TraitConstraint::{ trait_name: "Show", ty: Type::var_type("A") },
    ],
    Type::var_type("A"),
  )
  inspect(bounded, content="forall A : Star. (Eq A, Show A) => A")
  debug_inspect(
    bounded,
    content="BoundedForall(\n  name=\"A\",\n  kind=Star,\n  constraints=[\n    TraitConstraint(trait_name=\"Eq\", ty=Var(\"A\")),\n    TraitConstraint(trait_name=\"Show\", ty=Var(\"A\")),\n  ],\n  body=Var(\"A\"),\n)",
  )

  let ty_lam = Type::lam("A", Star, Type::var_type("A"))
  inspect(ty_lam, content="\\A : Star. A")
  debug_inspect(ty_lam, content="Lam(name=\"A\", kind=Star, body=Var(\"A\"))")

  let ty_app = Type::app(Type::con("List"), Type::con("Int"))
  inspect(ty_app, content="List Int")
  debug_inspect(ty_app, content="App(Con(\"List\"), Con(\"Int\"))")

  let rec_ty = Type::record([("x", Type::con("Int")), ("y", Type::con("Bool"))])
  inspect(rec_ty, content="{x : Int, y : Bool}")
  debug_inspect(
    rec_ty,
    content="Record([(\"x\", Con(\"Int\")), (\"y\", Con(\"Bool\"))])",
  )

  let variant_ty = Type::variant([
    ("Some", Type::con("Int")),
    ("None", Type::unit()),
  ])
  inspect(variant_ty, content="[Some : Int | None : ()]")
  debug_inspect(
    variant_ty,
    content="Variant([(\"Some\", Con(\"Int\")), (\"None\", ([]))])",
  )

  let mu_ty = Type::mu("X", Type::app(Type::con("List"), Type::var_type("X")))
  inspect(mu_ty, content="mu X. List X")
  debug_inspect(
    mu_ty,
    content="Mu(name=\"X\", body=App(Con(\"List\"), Var(\"X\")))",
  )

  let tuple_ty = Type::tuple([Type::con("Int"), Type::con("Bool")])
  inspect(tuple_ty, content="(Int, Bool)")
  debug_inspect(tuple_ty, content="([Con(\"Int\"), Con(\"Bool\")])")
}

///|
test "show and debug snapshots for term constructors" {
  let int_ty = Type::con("Int")
  let maybe_int = Type::variant([("Some", int_ty), ("None", Type::unit())])
  let mu_list = Type::mu("X", Type::app(Type::con("List"), Type::var_type("X")))

  inspect(Term::var_term("x"), content="x")
  debug_inspect(Term::var_term("x"), content="Var(\"x\")")

  let con_term = Term::con("one", int_ty)
  inspect(con_term, content="one : Int")
  debug_inspect(con_term, content="Con(name=\"one\", ty=Con(\"Int\"))")

  let lam_term = Term::lam("x", int_ty, Term::var_term("x"))
  inspect(lam_term, content="\\x : Int. x")
  debug_inspect(
    lam_term,
    content="Lam(name=\"x\", ty=Con(\"Int\"), body=Var(\"x\"))",
  )

  let app_term = Term::app(Term::var_term("f"), Term::var_term("x"))
  inspect(app_term, content="f x")
  debug_inspect(
    app_term,
    content="App(fn_term=Var(\"f\"), arg_term=Var(\"x\"))",
  )

  let let_term = Term::let_term("x", Term::var_term("y"), Term::var_term("x"))
  inspect(let_term, content="let x = y in x")
  debug_inspect(
    let_term,
    content="Let(name=\"x\", value=Var(\"y\"), body=Var(\"x\"))",
  )

  let tylam_term = Term::tylam("A", Star, Term::var_term("x"))
  inspect(tylam_term, content="/\\A : Star. x")
  debug_inspect(
    tylam_term,
    content="TyLam(name=\"A\", kind=Star, body=Var(\"x\"))",
  )

  let tyapp_term = Term::tyapp(Term::var_term("f"), int_ty)
  inspect(tyapp_term, content="f [Int]")
  debug_inspect(
    tyapp_term,
    content="TyApp(fn_term=Var(\"f\"), ty=Con(\"Int\"))",
  )

  let dict_term = Term::dict("Eq", int_ty, [("eq", Term::var_term("eq_impl"))])
  inspect(dict_term, content="dict Eq Int {eq = eq_impl}")
  debug_inspect(
    dict_term,
    content="Dict(trait_name=\"Eq\", ty=Con(\"Int\"), methods=[(\"eq\", Var(\"eq_impl\"))])",
  )

  let trait_lam = Term::trait_lam(
    "d",
    "Eq",
    "A",
    Star,
    [TraitConstraint::{ trait_name: "Eq", ty: Type::var_type("A") }],
    Term::var_term("body"),
  )
  inspect(trait_lam, content="traitlam d : Eq A : Star where Eq A. body")
  debug_inspect(
    trait_lam,
    content="TraitLam(\n  dict_name=\"d\",\n  trait_name=\"Eq\",\n  type_param=\"A\",\n  kind=Star,\n  constraints=[TraitConstraint(trait_name=\"Eq\", ty=Var(\"A\"))],\n  body=Var(\"body\"),\n)",
  )

  let trait_app = Term::trait_app(Term::var_term("f"), int_ty, [
    Term::var_term("d"),
  ])
  inspect(trait_app, content="f {Int; d}")
  debug_inspect(
    trait_app,
    content="TraitApp(fn_term=Var(\"f\"), ty=Con(\"Int\"), dicts=[Var(\"d\")])",
  )

  let trait_method = Term::trait_method(Term::var_term("d"), "eq")
  inspect(trait_method, content="d.eq")
  debug_inspect(
    trait_method,
    content="TraitMethod(dict_term=Var(\"d\"), method_name=\"eq\")",
  )

  let record_term = Term::record([
    ("x", Term::var_term("x")),
    ("y", Term::var_term("y")),
  ])
  inspect(record_term, content="{x = x, y = y}")
  debug_inspect(
    record_term,
    content="Record([(\"x\", Var(\"x\")), (\"y\", Var(\"y\"))])",
  )

  let project_term = Term::project(Term::var_term("r"), "x")
  inspect(project_term, content="r.x")
  debug_inspect(
    project_term,
    content="Project(record_term=Var(\"r\"), label=\"x\")",
  )

  let inject_term = Term::inject("Some", Term::var_term("x"), maybe_int)
  inspect(inject_term, content="<Some = x> as [Some : Int | None : ()]")
  debug_inspect(
    inject_term,
    content="Inject(\n  label=\"Some\",\n  payload=Var(\"x\"),\n  ty=Variant([(\"Some\", Con(\"Int\")), (\"None\", ([]))]),\n)",
  )

  let match_term = Term::match_term(Term::var_term("v"), [
    (Pattern::variant("Some", Pattern::var_pattern("x")), Term::var_term("x")),
    (Pattern::variant("None", Pattern::wildcard()), Term::con("z", int_ty)),
  ])
  inspect(
    match_term,
    content="match v { <Some = x> -> x | <None = _> -> z : Int }",
  )
  debug_inspect(
    match_term,
    content="Match(\n  scrutinee=Var(\"v\"),\n  branches=[\n    (VariantPattern(label=\"Some\", inner=VarPattern(\"x\")), Var(\"x\")),\n    (\n      VariantPattern(label=\"None\", inner=WildcardPattern),\n      Con(name=\"z\", ty=Con(\"Int\")),\n    ),\n  ],\n)",
  )

  let fold_term = Term::fold(mu_list, Term::var_term("x"))
  inspect(fold_term, content="fold [mu X. List X] x")
  debug_inspect(
    fold_term,
    content="Fold(\n  ty=Mu(name=\"X\", body=App(Con(\"List\"), Var(\"X\"))),\n  folded=Var(\"x\"),\n)",
  )

  let unfold_term = Term::unfold(Term::var_term("x"))
  inspect(unfold_term, content="unfold x")
  debug_inspect(unfold_term, content="Unfold(folded=Var(\"x\"))")

  let tuple_term = Term::tuple([Term::var_term("x"), Term::var_term("y")])
  inspect(tuple_term, content="(x, y)")
  debug_inspect(tuple_term, content="([Var(\"x\"), Var(\"y\")])")

  let tuple_project_term = Term::tuple_project(Term::var_term("p"), 1)
  inspect(tuple_project_term, content="p.1")
  debug_inspect(
    tuple_project_term,
    content="TupleProject(tuple_term=Var(\"p\"), index=1)",
  )
}

///|
test "show and debug snapshots for pattern constructors" {
  let int_ty = Type::con("Int")

  let var_pattern = Pattern::var_pattern("x")
  inspect(var_pattern, content="x")
  debug_inspect(var_pattern, content="VarPattern(\"x\")")

  let wildcard = Pattern::wildcard()
  inspect(wildcard, content="_")
  debug_inspect(wildcard, content="WildcardPattern")

  let con_pattern = Pattern::con("SomeCon", int_ty)
  inspect(con_pattern, content="SomeCon : Int")
  debug_inspect(
    con_pattern,
    content="ConPattern(name=\"SomeCon\", ty=Con(\"Int\"))",
  )

  let record_pattern = Pattern::record([
    ("x", Pattern::var_pattern("x")),
    ("y", Pattern::wildcard()),
  ])
  inspect(record_pattern, content="{x = x, y = _}")
  debug_inspect(
    record_pattern,
    content="RecordPattern([(\"x\", VarPattern(\"x\")), (\"y\", WildcardPattern)])",
  )

  let variant_pattern = Pattern::variant("Some", Pattern::var_pattern("x"))
  inspect(variant_pattern, content="<Some = x>")
  debug_inspect(
    variant_pattern,
    content="VariantPattern(label=\"Some\", inner=VarPattern(\"x\"))",
  )

  let tuple_pattern = Pattern::tuple([
    Pattern::var_pattern("x"),
    Pattern::wildcard(),
  ])
  inspect(tuple_pattern, content="(x, _)")
  debug_inspect(
    tuple_pattern,
    content="TuplePattern([VarPattern(\"x\"), WildcardPattern])",
  )
}
