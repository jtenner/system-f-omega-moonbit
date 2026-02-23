///|
/// Description: Creates a type-equality constraint.
/// Example: `let _ = Constraint::type_eq(Type::con("Int"), Type::con("Int"))`
pub fn Constraint::type_eq(left : Type, right : Type) -> Constraint {
  TypeEq({ left, right })
}

///|
/// Description: Creates a kind-equality constraint.
/// Example: `let _ = Constraint::kind_eq(Star, Star)`
pub fn Constraint::kind_eq(left : Kind, right : Kind) -> Constraint {
  KindEq({ left, right })
}

///|
/// Description: Creates a `HasKind` constraint for deferred kind checking.
/// Example: `let _ = Constraint::has_kind(Type::con("Int"), Star, TypeCheckerState::fresh())`
pub fn Constraint::has_kind(
  ty : Type,
  kind : Kind,
  state : TypeCheckerState,
) -> Constraint {
  HasKind({ ty, kind, state })
}

///|
/// Description: Creates a `HasType` constraint for deferred term typing.
/// Example: `let _ = Constraint::has_type(Term::unit(), Type::unit(), TypeCheckerState::fresh())`
pub fn Constraint::has_type(
  term : Term,
  ty : Type,
  state : TypeCheckerState,
) -> Constraint {
  HasType({ term, ty, state })
}

///|
/// Description: Builds infer/check mode that performs type inference.
/// Example: `let _ = InferMode::infer()`
pub fn InferMode::infer() -> InferMode {
  Infer
}

///|
/// Description: Builds infer/check mode that checks against the provided type.
/// Example: `let _ = InferMode::check(Type::con("Int"))`
pub fn InferMode::check(ty : Type) -> InferMode {
  Check(ty)
}

///|
/// Description: Compares application spine argument equality.
/// Example: `let _ = TypeCheckerState::fresh().types_equal_spine(Type::app(Type::con("F"), Type::con("Int")), Type::app(Type::con("F"), Type::con("Int")) )`
pub fn TypeCheckerState::types_equal_spine(
  self : TypeCheckerState,
  left : Type,
  right : Type,
) -> Bool {
  let l_args = left.get_spine_args()
  let r_args = right.get_spine_args()
  if l_args.length() != r_args.length() {
    return false
  }
  loop 0 {
    n if n < l_args.length() => {
      if self.types_equal(l_args[n], r_args[n]) {
        continue n + 1
      }
      return false
    }
    _ => return true
  }
}

///|
/// Description: Checks structural type equality with alpha-equivalence support.
/// Example: `let _ = TypeCheckerState::fresh().types_equal(Type::con("Int"), Type::con("Int"))`
pub fn TypeCheckerState::types_equal(
  self : TypeCheckerState,
  l : Type,
  r : Type,
) -> Bool {
  match (l, r) {
    (l, r) if l == r => true
    (App(Con(l), l_body), App(Con(r), r_body)) if l == r =>
      self.types_equal_spine(l_body, r_body)
    (Arrow(from_l, to_l), Arrow(from_r, to_r)) =>
      self.types_equal(from_l, from_r) && self.types_equal(to_l, to_r)
    (Ref(l_region, l_mutability, l_inner), Ref(r_region, r_mutability, r_inner)) =>
      l_region == r_region &&
      l_mutability == r_mutability &&
      self.types_equal(l_inner, r_inner)
    (Forall(l_var, l_kind, l_body), Forall(r_var, r_kind, r_body)) => {
      if l_kind != r_kind {
        return false
      }
      let renamed_body = r_body.alpha_rename(r_var, l_var)
      return self.types_equal(l_body, renamed_body)
    }
    (Lam(l_var, l_kind, l_ty), Lam(r_var, r_kind, r_ty)) => {
      if l_kind != r_kind {
        return false
      }
      let renamed_body = r_ty.alpha_rename(r_var, l_var)
      return self.types_equal(l_ty, renamed_body)
    }
    (App(l_func, l_arg), App(r_func, r_arg)) =>
      self.types_equal(l_func, r_func) && self.types_equal(l_arg, r_arg)
    (Record(l_fields), Record(r_fields)) => {
      if l_fields.length() != r_fields.length() {
        return false
      }

      let l_map = Map::from_array(l_fields)
      let r_map = Map::from_array(r_fields)

      for l in l_fields {
        let r_type = match r_map.get(l.0) {
          None => return false
          Some(t) => t
        }
        if !self.types_equal(l.1, r_type) {
          return false
        }
      }
      for r in r_fields {
        let l_type = match l_map.get(r.0) {
          None => return false
          Some(t) => t
        }
        if !self.types_equal(l_type, r.1) {
          return false
        }
      }
      true
    }
    (
      BoundedForall(l_name, l_kind, l_constraints, l_body),
      BoundedForall(r_name, r_kind, r_constraints, r_body),
    ) => {
      if l_kind != r_kind {
        return false
      }
      if l_constraints.length() != r_constraints.length() {
        return false
      }

      // We'll match constraints as a multiset: each right constraint can be used once.
      let r_unmatched = r_constraints.copy()

      for l_constraint in l_constraints {
        let { trait_name: l_trait_name, ty: l_ty } = l_constraint
        let mut found = false

        // Scan unmatched right constraints for one that matches.
        let mut i = 0
        while i < r_unmatched.length() {
          let r_constraint = r_unmatched[i]
          let { trait_name: r_trait_name, ty: r_ty } = r_constraint

          // If you later add trait aliases, normalize names here:
          // let l_trait = resolve_trait_alias(l_trait_name)
          // let r_trait = resolve_trait_alias(r_trait_name)
          // if l_trait != r_trait { i = i + 1; continue }
          if l_trait_name != r_trait_name {
            i = i + 1
            continue
          }

          // Alpha-rename the RHS constraint type binder to LHS binder
          let renamed_r_ty = r_ty.alpha_rename(r_name, l_name)

          if self.types_equal(l_ty, renamed_r_ty) {
            found = true
            ignore(r_unmatched.remove(i))
            break
          }

          i = i + 1
        }

        if !found {
          return false
        }
      }

      // All constraints matched; now compare bodies modulo alpha-renaming.
      let renamed_r_body = r_body.alpha_rename(r_name, l_name)
      return self.types_equal(l_body, renamed_r_body)
    }
    (Variant(l_cases), Variant(r_cases)) => {
      if l_cases.length() != r_cases.length() {
        return false
      }
      l_cases.sort_by_key(t => t.0)
      r_cases.sort_by_key(t => t.0)

      loop 0 {
        n if n < l_cases.length() => {
          let l = l_cases[n]
          let r = r_cases[n]
          if l.0 == r.0 && self.types_equal(l.1, r.1) {
            continue n + 1
          }
          return false
        }
        _ => return true
      }
    }
    (Mu(l_name, l_ty), Mu(r_name, r_ty)) => {
      let renamed_r_ty = r_ty.alpha_rename(r_name, l_name)
      return self.types_equal(l_ty, renamed_r_ty)
    }
    (Tuple(l), Tuple(r)) => {
      if l.length() != r.length() {
        return false
      }
      loop 0 {
        n if n < l.length() => {
          if self.types_equal(l[n], r[n]) {
            continue n + 1
          }
          return false
        }
        _ => return true
      }
    }
    _ => false
  }
}

///|
/// Description: Runs infer or check mode based on `InferMode`.
/// Example: `let _ = TypeCheckerState::fresh().infer_type_with_mode(Term::unit(), InferMode::infer())`
pub fn TypeCheckerState::infer_type_with_mode(
  self : TypeCheckerState,
  term : Term,
  mode : InferMode,
) -> Result[Type, TypingError] {
  match mode {
    Infer => self.infer_type(term)
    Check(ty) => {
      let result = self.check_type(term, ty)
      match result {
        Ok({ ty, .. }) => Ok(ty)
        Err(t) => Err(t)
      }
    }
  }
}

///|
/// Description: Combines substitutions where entries from `locals` override `globals`.
/// Example: `let _ = merge_substs(Map::new(), Map::new())`
pub fn merge_substs(
  locals : Substitution,
  globals : Substitution,
) -> Substitution {
  let merge = globals.copy()
  for t in locals {
    let (k, v) = t
    merge.set(k, v)
  }
  merge
}

///|
/// Description: Returns true if this type is an unsolved evar.
/// Example: `let _ = EVar("0").is_meta_var()`
pub fn Type::is_meta_var(self : Type) -> Bool {
  self is EVar(_)
}

///|
/// Description: Allocates a fresh evar of the given kind.
/// Example: `let _ = MetaEnv::{ counter: 0, kinds: Map::new(), solutions: Map::new() }.fresh_meta_var(Star)`
pub fn MetaEnv::fresh_meta_var(self : MetaEnv, kind : Kind) -> Type {
  let id = self.counter
  let id = id.to_string()
  self.counter += 1
  self.kinds.set(id, kind)
  EVar(id)
}

///|
/// Description: Constructs the base kind `Star`.
/// Example: `let _ = Kind::star()`
pub fn Kind::star() -> Kind {
  Star
}

///|
/// Description: Constructs the bottom type `Never`.
/// Example: `let _ = Type::never()`
pub fn Type::never() -> Type {
  Never
}

///|
/// Description: Constructs the unit type `()`.
/// Example: `let _ = Type::unit()`
pub fn Type::unit() -> Type {
  Tuple([])
}

///|
/// Description: Constructs the unit term `()`.
/// Example: `let _ = Term::unit()`
pub fn Term::unit() -> Term {
  Tuple([])
}

///|
/// Description: Checks whether a type normalizes to `Never`.
/// Example: `let _ = TypeCheckerState::fresh().is_bottom(Type::never())`
pub fn TypeCheckerState::is_bottom(self : TypeCheckerState, ty : Type) -> Bool {
  self.normalize_type(ty) is Never
}

///|
/// Description: Commits a solution for one evar after occurs/conflict checks.
/// Example: `let _ = TypeCheckerState::fresh().solve_meta_var("0", Type::con("Int"))`
pub fn TypeCheckerState::solve_meta_var(
  self : TypeCheckerState,
  evar : String,
  solution : Type,
) -> Result[Unit, TypingError] {
  match self.meta.solutions.get(evar) {
    None => {
      if self.meta.occurs_check_evar(evar, solution) {
        return Err(Cyclic(evar))
      }

      self.meta.solutions.set(evar, solution)
      Ok(())
    }
    Some(existing) =>
      if self.types_equal(existing, solution) {
        Ok(())
      } else {
        Err(TypeMismatch(existing, solution))
      }
  }
}

///|
/// Description: Checks whether an evar appears inside a type (following solved metas).
/// Example: `let _ = MetaEnv::{ counter: 0, kinds: Map::new(), solutions: Map::new() }.occurs_check_evar("0", Type::con("Int"))`
pub fn MetaEnv::occurs_check_evar(
  self : MetaEnv,
  evar : String,
  ty : Type,
) -> Bool {
  match ty {
    EVar(name) => {
      if name == evar {
        return true
      }

      match self.solutions.get(name) {
        None => false
        Some(ty) => self.occurs_check_evar(evar, ty)
      }
    }
    Var(_) => false
    Arrow(from, to) =>
      self.occurs_check_evar(evar, from) || self.occurs_check_evar(evar, to)
    Ref(_, _, inner) => self.occurs_check_evar(evar, inner)
    App(func, arg) =>
      self.occurs_check_evar(evar, func) || self.occurs_check_evar(evar, arg)
    Forall(_, _, body) => self.occurs_check_evar(evar, body)
    BoundedForall(_, _, constraints, body) => {
      for c in constraints {
        if self.occurs_check_evar(evar, c.ty) {
          return true
        }
      }
      return self.occurs_check_evar(evar, body)
    }
    Record(pairs) =>
      pairs.any(t => {
        let (_, ty) = t
        self.occurs_check_evar(evar, ty)
      })
    Variant(variants) =>
      variants.any(t => {
        let (_, ty) = t
        self.occurs_check_evar(evar, ty)
      })
    Tuple(tys) => tys.any(ty => self.occurs_check_evar(evar, ty))
    Mu(_, body) => self.occurs_check_evar(evar, body)
    Never => false
    Con(_) => false
    Lam(_) => false
  }
}

///|
/// Description: Applies type substitution through all type positions in a term.
/// Example: `let _ = TypeCheckerState::fresh().apply_substitution_to_term(Map::new(), Term::unit(), Set::new())`
pub fn TypeCheckerState::apply_substitution_to_term(
  self : TypeCheckerState,
  subst : Substitution,
  term : Term,
  avoid : Set[String],
) -> Term {
  fn apply_type_with_avoid(
    state : TypeCheckerState,
    subst : Substitution,
    ty : Type,
    avoid : Set[String],
  ) -> Type {
    let filtered = subst.copy()
    for name in avoid {
      filtered.remove(name)
    }
    state.apply_substitution(filtered, ty)
  }

  match term {
    Var(_) => term
    Lam(arg, ty, body) =>
      Term::lam(
        arg,
        apply_type_with_avoid(self, subst, ty, avoid),
        self.apply_substitution_to_term(subst, body, avoid),
      )
    App(callee, arg) =>
      Term::app(
        self.apply_substitution_to_term(subst, callee, avoid),
        self.apply_substitution_to_term(subst, arg, avoid),
      )
    BorrowShared(target) =>
      Term::borrow_shared(self.apply_substitution_to_term(subst, target, avoid))
    BorrowMut(target) =>
      Term::borrow_mut(self.apply_substitution_to_term(subst, target, avoid))
    Deref(inner) =>
      Term::deref(self.apply_substitution_to_term(subst, inner, avoid))
    Assign(target, value) =>
      Term::assign(
        self.apply_substitution_to_term(subst, target, avoid),
        self.apply_substitution_to_term(subst, value, avoid),
      )
    Move(inner) =>
      Term::move_term(self.apply_substitution_to_term(subst, inner, avoid))
    TyLam(name, kind, body) => {
      let avoid = avoid..add(name)
      Term::tylam(
        name,
        kind,
        self.apply_substitution_to_term(subst, body, avoid),
      )
    }
    TyApp(term, ty) =>
      Term::tyapp(
        self.apply_substitution_to_term(subst, term, avoid),
        apply_type_with_avoid(self, subst, ty, avoid),
      )
    Con(name, ty) =>
      Term::con(name, apply_type_with_avoid(self, subst, ty, avoid))
    Dict(trait_name, ty, methods) =>
      Term::dict(
        trait_name,
        apply_type_with_avoid(self, subst, ty, avoid),
        methods.map(m => {
          let (method_name, method_term) = m
          (
            method_name,
            self.apply_substitution_to_term(subst, method_term, avoid),
          )
        }),
      )
    TraitLam(trait_var, trait_name, type_var, kind, constraints, body) => {
      let avoid = avoid..add(type_var)
      Term::trait_lam(
        trait_var,
        trait_name,
        type_var,
        kind,
        constraints.map(c => TraitConstraint::{
          trait_name: c.trait_name,
          ty: apply_type_with_avoid(self, subst, c.ty, avoid),
        }),
        self.apply_substitution_to_term(subst, body, avoid),
      )
    }
    TraitApp(term, ty, dicts) =>
      Term::trait_app(
        self.apply_substitution_to_term(subst, term, avoid),
        apply_type_with_avoid(self, subst, ty, avoid),
        dicts.map(d => self.apply_substitution_to_term(subst, d, avoid)),
      )
    TraitMethod(dict, method_name) =>
      Term::trait_method(
        self.apply_substitution_to_term(subst, dict, avoid),
        method_name,
      )
    Let(name, value, body) =>
      Term::let_term(
        name,
        self.apply_substitution_to_term(subst, value, avoid),
        self.apply_substitution_to_term(subst, body, avoid),
      )
    Match(scrutinee, cases) =>
      Term::match_term(
        self.apply_substitution_to_term(subst, scrutinee, avoid),
        cases.map(c => {
          let (pattern, body) = c
          (pattern, self.apply_substitution_to_term(subst, body, avoid))
        }),
      )
    Record(fields) =>
      Term::record(
        fields.map(f => {
          let (label, field_term) = f
          (label, self.apply_substitution_to_term(subst, field_term, avoid))
        }),
      )
    Project(record, label) =>
      Term::project(
        self.apply_substitution_to_term(subst, record, avoid),
        label,
      )
    Inject(label, value, variant_ty) =>
      Term::inject(
        label,
        self.apply_substitution_to_term(subst, value, avoid),
        apply_type_with_avoid(self, subst, variant_ty, avoid),
      )
    Tuple(terms) =>
      Term::tuple(
        terms.map(t => self.apply_substitution_to_term(subst, t, avoid)),
      )
    TupleProject(tuple, index) =>
      Term::tuple_project(
        self.apply_substitution_to_term(subst, tuple, avoid),
        index,
      )
    Fold(ty, term) =>
      Term::fold(
        apply_type_with_avoid(self, subst, ty, avoid),
        self.apply_substitution_to_term(subst, term, avoid),
      )
    Unfold(term) =>
      Term::unfold(self.apply_substitution_to_term(subst, term, avoid))
  }
}

///|
/// Description: Instantiates polymorphic term forms with fresh metavariables.
/// Example: `let _ = TypeCheckerState::fresh().instantiate_term(Term::unit())`
pub fn TypeCheckerState::instantiate_term(
  self : TypeCheckerState,
  term : Term,
) -> Term {
  match term {
    TyLam(name, kind, body) => {
      let body = self.instantiate_term(body)
      let ft = self.meta.fresh_meta_var(kind)
      let subst = Map::from_array([(name, ft)])
      let body = self.apply_substitution_to_term(
        subst,
        body,
        Set::from_array([name]),
      )
      Term::tyapp(body, ft)
    }
    App(callee, arg) =>
      Term::app(self.instantiate_term(callee), self.instantiate_term(arg))
    BorrowShared(target) => Term::borrow_shared(self.instantiate_term(target))
    BorrowMut(target) => Term::borrow_mut(self.instantiate_term(target))
    Deref(inner) => Term::deref(self.instantiate_term(inner))
    Assign(target, value) =>
      Term::assign(self.instantiate_term(target), self.instantiate_term(value))
    Move(inner) => Term::move_term(self.instantiate_term(inner))
    Lam(arg, ty, body) =>
      Term::lam(arg, self.instantiate_type(ty), self.instantiate_term(body))
    TyApp(term, ty) =>
      Term::tyapp(self.instantiate_term(term), self.instantiate_type(ty))
    Match(scrutinee, cases) =>
      Term::match_term(
        self.instantiate_term(scrutinee),
        cases.map(t => {
          let (pat, body) = t
          (pat, self.instantiate_term(body))
        }),
      )
    Inject(label, value, variant_type) =>
      Term::inject(
        label,
        self.instantiate_term(value),
        self.instantiate_type(variant_type),
      )
    Dict(name, ty, methods) =>
      Term::dict(
        name,
        self.instantiate_type(ty),
        methods.map(t => {
          let (name, term) = t
          (name, self.instantiate_term(term))
        }),
      )
    TraitLam(trait_var, trait_name, trait_type_var, kind, constraints, body) =>
      Term::trait_lam(
        trait_var,
        trait_name,
        trait_type_var,
        kind,
        constraints.map(f => { ..f, ty: self.instantiate_type(f.ty) }),
        self.instantiate_term(body),
      )
    Record(pairs) =>
      Term::record(
        pairs.map(t => {
          let (name, value) = t
          (name, self.instantiate_term(value))
        }),
      )
    Let(name, value, body) =>
      Term::let_term(
        name,
        self.instantiate_term(value),
        self.instantiate_term(body),
      )
    Tuple(terms) => Term::tuple(terms.map(t => self.instantiate_term(t)))
    _ => term
  }
}

///|
/// Description: Instantiates forall/bounded-forall types with fresh metavariables.
/// Example: `let _ = TypeCheckerState::fresh().instantiate_type(Type::con("Int"))`
pub fn TypeCheckerState::instantiate_type(
  self : TypeCheckerState,
  ty : Type,
) -> Type {
  match ty {
    Forall(name, kind, body) => {
      let fv = self.meta.fresh_meta_var(kind)
      let body = body.substitute_type(name, fv)
      self.instantiate_type(body)
    }
    BoundedForall(name, kind, _constraints, body) => {
      let fv = self.meta.fresh_meta_var(kind)
      let body = body.substitute_type(name, fv)
      self.instantiate_type(body)
    }
    _ => ty
  }
}

///|
/// Description: Checks whether one type can be treated as another under instantiation/unification.
/// Example: `let _ = TypeCheckerState::fresh().subsumes(Type::con("Int"), Type::con("Int"), [], Map::new())`
pub fn TypeCheckerState::subsumes(
  self : TypeCheckerState,
  general : Type,
  specific : Type,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  let general = self.instantiate_type(general)
  if self.is_bottom(specific) {
    match self.check_kind(general, true) {
      Err(t) => return Err(t)
      Ok(_) => return Ok(())
    }
  }

  if self.is_bottom(general) {
    return Err(TypeMismatch(general, specific))
  }

  self.unify_types(general, specific, worklist, subst)
}

///|
/// Description: Checks assignability relation used by checker rules.
/// Example: `let _ = TypeCheckerState::fresh().is_assignable_to(Type::con("Int"), Type::con("Int"))`
pub fn TypeCheckerState::is_assignable_to(
  self : TypeCheckerState,
  from : Type,
  to : Type,
) -> Bool {
  if self.is_bottom(from) {
    return true
  }
  if self.is_bottom(to) {
    // only true is from is bottom
    return false
  }

  self.types_equal(from, to)
}

///|
fn walk_bindings(
  tcs : TypeCheckerState,
  p : Pattern,
  bindings : Array[(String, Type)],
) -> Unit {
  match p {
    VarPattern(name) => bindings.push((name, tcs.meta.fresh_meta_var(Star)))
    VariantPattern(_name, case) => walk_bindings(tcs, case, bindings)
    RecordPattern(pairs) =>
      for p in pairs {
        let (_, pattern) = p
        walk_bindings(tcs, pattern, bindings)
      }
    ConPattern(_) => ()
    WildcardPattern => ()
    TuplePattern(patterns) =>
      for p in patterns {
        walk_bindings(tcs, p, bindings)
      }
  }
}

///|
/// Description: Collects variable bindings introduced by a pattern.
/// Example: `let _ = TypeCheckerState::fresh().bindings(Pattern::var_pattern("x"))`
pub fn TypeCheckerState::bindings(
  self : TypeCheckerState,
  p : Pattern,
) -> Array[(String, Type)] {
  let result = []
  walk_bindings(self, p, result)
  result
}

///|
/// Description: Finds a dictionary implementing a trait for a target type.
/// Example: `let _ = TypeCheckerState::fresh().check_trait_implementation("Eq", Type::con("Int"))`
pub fn TypeCheckerState::check_trait_implementation(
  self : TypeCheckerState,
  trait_name : String,
  ty : Type,
) -> Result[Term, TypingError] {
  let normalized_target = self.normalize_type(ty)

  // 1) Exact match (normalized)
  for b in self.ctx.0 {
    match b {
      TraitImpl({ trait_name: b_trait, ty: b_ty, dict: b_dict }) =>
        if b_trait == trait_name {
          let normalized_impl = self.normalize_type(b_ty)
          if self.types_equal(normalized_impl, normalized_target) {
            return Ok(b_dict)
          }
        }
      _ => ()
    }
  }

  // 2) Polymorphic / unification-based match
  for b in self.ctx.0 {
    match b {
      TraitImpl({ trait_name: b_trait, ty: b_ty, dict: b_dict }) => {
        if b_trait != trait_name {
          continue
        }

        // Normalize both sides
        let normalized_impl = self.normalize_type(b_ty)
        let normalized_target2 = self.normalize_type(normalized_target)

        // Instantiate impl type (forall/bounded_forall -> fresh metas)
        let inst_impl_ty = self.instantiate_type(normalized_impl)

        // If target is still a type-lambda while impl is not, apply target to fresh metas
        let mut matching_target = normalized_target2
        loop () {
          _ =>
            match (matching_target, inst_impl_ty) {
              (Lam(tvar, k, body), _) if !(inst_impl_ty is Lam(_, _, _)) => {
                let fv = self.meta.fresh_meta_var(k)
                // apply lambda: body[tvar := fv], normalize
                matching_target = self.normalize_type(
                  body.substitute_type(tvar, fv),
                )
                continue ()
              }
              _ => break
            }
        }

        // Unify
        let worklist : Worklist = []
        let subst : Substitution = Map::new()

        match self.unify_types(inst_impl_ty, matching_target, worklist, subst) {
          Err(_) => continue
          Ok(_) =>
            match self.solve_constraints(worklist, subst) {
              Err(_) => continue
              Ok(solved_subst) => {
                // Instantiate dict term (so its internal TyLam get applied to fresh metas)
                let inst_dict = self.instantiate_term(b_dict)

                // Apply solved substitution into dict term
                // If your apply_substitution_to_term also needs an avoid-set, pass it here.
                let final_dict = self.apply_substitution_to_term(
                  solved_subst,
                  inst_dict,
                  Set::new(),
                )

                return Ok(final_dict)
              }
            }
        }
      }
      _ => ()
    }
  }

  Err(MissingTraitImpl(trait_name, ty))
}

///|
/// Description: Resolves dictionaries required by trait constraints.
/// Example: `let _ = TypeCheckerState::fresh().check_trait_constraints([])`
pub fn TypeCheckerState::check_trait_constraints(
  self : TypeCheckerState,
  constraints : Array[TraitConstraint],
) -> Result[Array[Term], TypingError] {
  let result = []
  for c in constraints {
    let dict = match self.check_trait_implementation(c.trait_name, c.ty) {
      Err(t) => return Err(t)
      Ok(d) => d
    }
    result.push(dict)
  }
  Ok(result)
}

///|
fn extract_pattern_labels_impl(p : Pattern, res : Set[String]) -> Unit {
  match p {
    VariantPattern(name, inner) => {
      res.add(name)
      extract_pattern_labels_impl(inner, res)
    }
    RecordPattern(pairs) =>
      for p in pairs {
        let (_, inner) = p
        extract_pattern_labels_impl(inner, res)
      }
    ConPattern(_) => ()
    WildcardPattern => ()
    VarPattern(_) => ()
    TuplePattern(patterns) =>
      for p in patterns {
        extract_pattern_labels_impl(p, res)
      }
  }
}

///|
/// Description: Collects variant labels appearing inside a pattern tree.
/// Example: `let _ = Pattern::variant("Some", Pattern::wildcard()).extract_pattern_labels()`
pub fn Pattern::extract_pattern_labels(self : Pattern) -> Set[String] {
  let res = Set::new()
  extract_pattern_labels_impl(self, res)
  res
}

///|
/// Description: Checks whether a set of patterns exhausts a variant/enum scrutinee type.
/// Example: `let _ = TypeCheckerState::fresh().check_exhaustive([Pattern::wildcard()], Type::variant([("A", Type::unit())]))`
pub fn TypeCheckerState::check_exhaustive(
  self : TypeCheckerState,
  patterns : Array[Pattern],
  ty : Type,
) -> Result[Unit, TypingError] {
  let ty = self.normalize_type(ty)

  match ty {
    App(Con(func), _) => {
      let spine_args = ty.get_spine_args()
      let binding = match self.ctx.find_enum(func) {
        Some(binding) => binding
        _ => return Err(NotAVariant(ty))
      }
      if binding.params.length() != spine_args.length() {
        return Err(KindMismatch(binding.kind, Star))
      }
      let all_labels = Set::from_array(binding.variants.map(t => t.0))

      for p in patterns {
        let labels = match p {
          WildcardPattern | VarPattern(_) => return Ok(())
          _ => p.extract_pattern_labels()
        }
        for label in labels {
          all_labels.remove(label)
        }
      }

      if all_labels.length() > 0 {
        Err(MissingCase(all_labels.to_array()[0]))
      } else {
        Ok(())
      }
    }
    Variant(cases) => {
      let all_labels = Set::from_array(cases.map(t => t.0))

      for p in patterns {
        let labels = match p {
          WildcardPattern | VarPattern(_) => return Ok(())
          _ => p.extract_pattern_labels()
        }
        for label in labels {
          all_labels.remove(label)
        }
      }

      if all_labels.length() > 0 {
        Err(MissingCase(all_labels.to_array()[0]))
      } else {
        Ok(())
      }
    }
    _ => Ok(())
  }
}

///|
/// Description: Extracts the first `n` argument kinds and the remaining result kind.
/// Example: `let _ = Kind::arrow(Star, Kind::arrow(Star, Star)).peel_n_params(2)`
pub fn Kind::peel_n_params(
  self : Kind,
  n : Int,
) -> Result[(Array[Kind], Kind), TypingError] {
  let ks : Array[Kind] = []
  let mut k = self
  loop 0 {
    i if i < n =>
      match k {
        Kind::Arrow(a, r) => {
          ks.push(a)
          k = r
          continue i + 1
        }
        _ =>
          // Not enough arrows for the number of params
          return Err(KindMismatch(self, Kind::star())) // or a better error
      }
    _ => ()
  }
  return Ok((ks, k)) // k is the result kind after n args
}

///|
fn check_variant_pattern(
  state : TypeCheckerState,
  name : String,
  inner : Pattern,
  ty : Type,
) -> Result[Context, TypingError] {

  // A) Unfold recursive types
  match ty {
    Mu(n, body) => {
      let unfolded = body.substitute_type(n, ty)
      return state.check_pattern(Pattern::variant(name, inner), unfolded)
    }
    _ => ()
  }

  let ty = state.normalize_type(ty)

  match ty {

    // B1) Unknown scrutinee type: infer enum from pattern label
    EVar(_evar_id) => {
      let def = match state.ctx.find_enum_by_variant_label(name) {
        Some(d) => d
        None => return Err(Unbound(name))
      }

      // Build Enum[?a1, ?a2, ...] using the enum's param kinds
      let mut enum_ty = Type::con(def.name)
      let kinds = match def.kind.peel_n_params(def.params.length()) {
        Err(t) => return Err(t)
        Ok((ks, _)) => ks
      }

      // If your enum def stores param kinds as def.kinds:
      // for k in def.kinds { enum_ty = Type::app(enum_ty, state.meta.fresh_meta_var(k)) }
      //
      // If you only have def.params and def.kinds separately:
      loop 0 {
        i if i < def.params.length() => {
          let k = kinds[i]
          enum_ty = Type::app(enum_ty, state.meta.fresh_meta_var(k))
          continue i + 1
        }
        _ => ()
      }

      let wl : Worklist = []
      let subst : Substitution = Map::new()

      match state.unify_types(ty, enum_ty, wl, subst) {
        Err(t) => return Err(t)
        Ok(_) => ()
      }

      match state.solve_constraints(wl, subst) {
        Err(t) => return Err(t)
        Ok(entries) => {
          // commit solved metas globally
          for entry in entries {
            let (k, v) = entry
            match state.solve_meta_var(k, v) {
              Err(t) => return Err(t)
              Ok(_) => ()
            }
          }

          let resolved_ty = state.apply_substitution(entries, ty)
          return state.check_pattern(Pattern::variant(name, inner), resolved_ty)
        }
      }
    }

    // B2) Structural variant type: <A: t1, B: t2, ...>
    Variant(cases) => {
      // find case by label
      let mut found : Type? = None
      for c in cases {
        let (lbl, cty) = c
        if lbl == name {
          found = Some(cty)
          break
        }
      }
      match found {
        None => return Err(InvalidVariantLabel(ty, name))
        Some(field_ty) => return state.check_pattern(inner, field_ty)
      }
    }

    // B3) Nominal enum instance: Con(Enum) or App(App(Con(Enum), a1), a2) ...
    Con(_) | App(_, _) => {
      let head = ty.get_spine_head()
      let con_name = match head {
        Con(n) => n
        _ => return Err(NotAVariant(ty))
      }

      let spine_args = match ty {
        Con(_) => []
        _ => ty.get_spine_args()
      }

      let def = match state.ctx.find_enum(con_name) {
        Some(d) => d
        None => return Err(NotAVariant(ty))
      }

      if spine_args.length() != def.params.length() {
        // mirror your TS: kind mismatch / arity mismatch
        return Err(KindMismatch(def.kind, Kind::star()))
      }

      // find variant entry in enum def
      let mut field_ty_opt : Type? = None
      for v in def.variants {
        let (lbl, scheme) = v
        if lbl == name {
          // scheme should be the field type (or field scheme -> type)
          field_ty_opt = Some(scheme) // adjust if FieldScheme wraps Type
          break
        }
      }
      let mut field_ty = match field_ty_opt {
        None => return Err(InvalidVariantLabel(ty, name))
        Some(ft) => ft
      }

      // substitute enum params with spine args
      loop 0 {
        i if i < def.params.length() => {
          let p = def.params[i]
          let a = spine_args[i]
          field_ty = field_ty.substitute_type(p, a)
          continue i + 1
        }
        _ => ()
      }

      field_ty = state.normalize_type(field_ty)
      return state.check_pattern(inner, field_ty)
    }

    // Anything else is not a variant
    _ => Err(NotAVariant(ty))
  }
}

///|
fn check_tuple_pattern(
  state : TypeCheckerState,
  patterns : Array[Pattern],
  ty : Type,
) -> Result[Context, TypingError] {

  // Allow ⊥ (Never) as matching anything
  // If it's neither a tuple nor bottom, reject.
  if !(ty is Tuple(_)) && !state.is_bottom(ty) {
    return Err(NotATuple(ty)) // rename to your actual error variant
  }

  // If it's a tuple, arity must match.
  match ty {
    Tuple(elems) => {
      if patterns.length() != elems.length() {
        // Mirror TS: expected = ty, actual = tuple of unitType of same arity as pattern
        let actual_elems : Array[Type] = []
        for _p in patterns {
          actual_elems.push(Type::unit())
        }
        return Err(TypeMismatch(ty, Type::tuple(actual_elems)))
        // If you have a structured mismatch error, adapt accordingly.
      }

      // elementwise check
      let bindings : Context = []
      loop 0 {
        i if i < patterns.length() => {
          let subp = patterns[i]
          let ety = elems[i]
          match state.check_pattern(subp, ety) {
            Err(t) => return Err(t)
            Ok(ctx) => bindings.0.append(ctx.0) // see note below
          }
          continue i + 1
        }
        _ => return Ok(bindings)
      }
    }

    // Bottom: treat as unit elements list (empty) like TS effectiveElements = []
    _ => {
      // For bottom, TS uses effectiveElements = [] and elementType = unitType
      let bindings : Context = []
      for p in patterns {
        match state.check_pattern(p, Type::unit()) {
          Err(t) => return Err(t)
          Ok(ctx) => bindings.0.append(ctx.0)
        }
      }
      return Ok(bindings)
    }
  }
}

///|
fn check_record_pattern(
  state : TypeCheckerState,
  pairs : Array[(String, Pattern)],
  ty : Type,
) -> Result[Context, TypingError] {
  if state.is_bottom(ty) {
    let bindings = []

    for pair in pairs {
      let (_, sub_pattern) = pair
      let fv = state.meta.fresh_meta_var(Star)

      match state.check_pattern(sub_pattern, fv) {
        Err(t) => return Err(t)
        Ok(ctx) => bindings.append(ctx.0)
      }
    }

    return Ok(Context(bindings))
  }

  if ty is Record(record_ty) {
    if record_ty.length() != pairs.length() {
      let actual = Type::record(pairs.map(t => (t.0, Tuple([]))))
      return Err(TypeMismatch(ty, actual))
    }

    record_ty.sort_by_key(t => t.0)
    pairs.sort_by_key(t => t.0)
    let bindings = []
    loop 0 {
      n if n >= record_ty.length() => return Ok(Context(bindings))
      n => {
        let record_pair = record_ty[n]
        let pair_ty = pairs[n]

        if record_pair.0 != pair_ty.0 {
          return Err(MissingField(ty, pair_ty.0))
        }

        match state.check_pattern(pair_ty.1, record_pair.1) {
          Err(t) => return Err(t)
          Ok(ctx) => bindings.append(ctx.0)
        }

        continue n + 1
      }
    }
  } else {
    return Err(NotARecord(ty))
  }
}

///|
fn check_con_pattern(
  state : TypeCheckerState,
  _name : String,
  con_ty : Type,
  ty : Type,
) -> Result[Context, TypingError] {
  if state.is_assignable_to(con_ty, ty) {
    Ok(Context([]))
  } else {
    Err(TypeMismatch(ty, con_ty))
  }
}

///|
/// Description: Checks a pattern against a scrutinee type and returns introduced bindings.
/// Example: `let _ = TypeCheckerState::fresh().check_pattern(Pattern::wildcard(), Type::con("Int"))`
pub fn TypeCheckerState::check_pattern(
  self : TypeCheckerState,
  pattern : Pattern,
  ty : Type,
) -> Result[Context, TypingError] {
  match pattern {
    VarPattern(name) => Ok([Binding::term(name, ty)])
    WildcardPattern => Ok([])
    VariantPattern(name, inner) => check_variant_pattern(self, name, inner, ty)
    ConPattern(name, con_ty) => check_con_pattern(self, name, con_ty, ty)
    RecordPattern(pairs) => check_record_pattern(self, pairs, ty)
    TuplePattern(patterns) => check_tuple_pattern(self, patterns, ty)
  }
}

///|
fn substitute_type_impl(
  ty : Type,
  target : String,
  replacement : Type,
  seen : Set[String],
) -> Type {
  match ty {
    Con(name) => if name == target { replacement } else { ty }
    Var(name) => if name == target { replacement } else { ty }
    Arrow(from, to) =>
      Arrow(
        substitute_type_impl(from, target, replacement, seen),
        substitute_type_impl(to, target, replacement, seen),
      )
    Ref(region, mutability, inner) =>
      Type::ref_type(
        region,
        mutability,
        substitute_type_impl(inner, target, replacement, seen),
      )
    BoundedForall(name, kind, constraints, inner) =>
      if name != target {
        Type::bounded_forall(
          name,
          kind,
          constraints.map(t => TraitConstraint::{
            trait_name: t.trait_name,
            ty: substitute_type_impl(t.ty, target, replacement, seen),
          }),
          substitute_type_impl(inner, target, replacement, seen),
        )
      } else {
        ty
      }
    Forall(name, kind, inner) =>
      if name != target {
        Type::forall(
          name,
          kind,
          substitute_type_impl(inner, target, replacement, seen),
        )
      } else {
        ty
      }
    App(t1, t2) =>
      App(
        substitute_type_impl(t1, target, replacement, seen),
        substitute_type_impl(t2, target, replacement, seen),
      )
    Lam(name, kind, inner) =>
      if name != target {
        Type::lam(
          name,
          kind,
          substitute_type_impl(inner, target, replacement, seen),
        )
      } else {
        ty
      }
    Record(pairs) =>
      Type::record(
        pairs.map(t => {
          (t.0, substitute_type_impl(t.1, target, replacement, seen))
        }),
      )
    Variant(pairs) =>
      Type::variant(
        pairs.map(t => {
          (t.0, substitute_type_impl(t.1, target, replacement, seen))
        }),
      )
    Mu(name, inner) =>
      if name == target || seen.contains(name) {
        ty
      } else {
        Type::mu(
          name,
          substitute_type_impl(inner, target, replacement, seen..add(name)),
        )
      }
    Tuple(inner) =>
      Type::tuple(
        inner.map(t => substitute_type_impl(t, target, replacement, seen)),
      )
    _ => ty
  }
}

///|
/// Description: Substitutes a type variable with a replacement type.
/// Example: `let _ = Type::var_type("A").substitute_type("A", Type::con("Int"))`
pub fn Type::substitute_type(
  self : Type,
  target : String,
  replacement : Type,
) -> Type {
  substitute_type_impl(self, target, replacement, Set::new())
}

///|
/// Description: Returns true if this kind is `Star`.
/// Example: `let _ = Kind::star().is_star_kind()`
pub fn Kind::is_star_kind(self : Kind) -> Bool {
  self is Star
}

///|
fn check_con_kind(
  state : TypeCheckerState,
  name : String,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let type_alias = state.ctx.find_type_alias(name)

  if type_alias is Some(b) {
    let inner_ctx = []
    loop 0 {
      n if n >= b.params.length() => break ()
      n => {
        inner_ctx.push(Binding::type_binding(b.params[n], b.kinds[n]))
        continue n + 1
      }
    }
    inner_ctx.append(state.ctx.0)
    let inner_state = TypeCheckerState::{
      ctx: Context(inner_ctx),
      meta: state.meta,
    }
    let mut kind = match inner_state.check_kind(b.body, lenient) {
      Ok(kind) => kind
      Err(t) => return Err(t)
    }

    loop b.params.length() - 1 {
      n if n < 0 => break ()
      n => {
        kind = Arrow(b.kinds[n], kind)
        continue n - 1
      }
    }
    return Ok(kind)
  }

  let binding = state.ctx.find_type_binding(name)
  if binding is Some(b) {
    return Ok(b.kind)
  }

  let binding = state.ctx.find_enum(name)
  if binding is Some(b) {
    return Ok(b.kind)
  }

  if lenient {
    Ok(Star)
  } else {
    Err(Unbound(name))
  }
}

///|
fn check_var_kind(
  state : TypeCheckerState,
  name : String,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let binding = state.ctx.find_type_binding(name)
  if binding is Some(b) {
    return Ok(b.kind)
  }

  if lenient {
    Ok(Star)
  } else {
    Err(Unbound(name))
  }
}

///|
fn check_mu_kind(
  state : TypeCheckerState,
  name : String,
  inner : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let ctx = state.ctx.0.copy()
  ctx.insert(0, Binding::type_binding(name, Star))
  let inner_state = TypeCheckerState::{ ctx: Context(ctx), meta: state.meta }

  let body_kind = match inner_state.check_kind(inner, lenient) {
    Ok(kind) => kind
    Err(t) => return Err(t)
  }

  if body_kind is Star {
    Ok(Star)
  } else {
    Err(KindMismatch(Star, body_kind))
  }
}

///|
fn check_variant_kind(
  state : TypeCheckerState,
  cases : Array[(String, Type)],
  lenient : Bool,
) -> Result[Kind, TypingError] {
  for case in cases {
    let (_, case_ty) = case
    let case_kind = match state.check_kind(case_ty, lenient) {
      Err(t) => return Err(t)
      Ok(kind) => kind
    }

    if !(state.is_bottom(case_ty) && !(case_kind is Star)) {
      return Err(KindMismatch(Star, case_kind))
    }
  }
  Ok(Star)
}

///|
fn check_record_kind(
  state : TypeCheckerState,
  fields : Array[(String, Type)],
  lenient : Bool,
) -> Result[Kind, TypingError] {
  for field in fields {
    let (_, field_ty) = field
    let field_kind = match state.check_kind(field_ty, lenient) {
      Err(t) => return Err(t)
      Ok(kind) => kind
    }

    if !(field_kind is Star) {
      return Err(KindMismatch(Star, field_kind))
    }
  }
  Ok(Star)
}

///|
fn check_app_kind(
  state : TypeCheckerState,
  func : Type,
  arg : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let func_kind = match state.check_kind(func, lenient) {
    Err(t) => return Err(t)
    Ok(func_kind) => func_kind
  }

  let arg_kind = match state.check_kind(arg, lenient) {
    Err(t) => return Err(t)
    Ok(arg_kind) => arg_kind
  }

  if func_kind is Arrow(from, to) {
    if from == arg_kind {
      Ok(to)
    } else {
      Err(KindMismatch(from, arg_kind))
    }
  } else {
    Err(NotATypeFunction(func))
  }
}

///|
fn check_lam_kind(
  state : TypeCheckerState,
  name : String,
  kind : Kind,
  inner : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let inner_state = state.extend_context([Binding::type_binding(name, kind)])

  let body_kind = match inner_state.check_kind(inner, lenient) {
    Ok(kind) => kind
    Err(t) => return Err(t)
  }

  Ok(Kind::arrow(kind, body_kind))
}

///|
fn check_bounded_forall_kind(
  state : TypeCheckerState,
  name : String,
  kind : Kind,
  constraints : Array[TraitConstraint],
  inner : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let inner_state = state.extend_context([Binding::type_binding(name, kind)])

  for constraint in constraints {
    let constraint_kind = match inner_state.check_kind(constraint.ty, lenient) {
      Err(t) => return Err(t)
      Ok(constraint_kind) => constraint_kind
    }
    if !(constraint_kind is Star) {
      return Err(KindMismatch(Star, constraint_kind))
    }
  }

  let body_kind = match inner_state.check_kind(inner, lenient) {
    Err(t) => return Err(t)
    Ok(body_kind) => body_kind
  }

  if !(body_kind is Star) {
    return Err(KindMismatch(Star, body_kind))
  }

  Ok(Star)
}

///|
fn check_forall_kind(
  state : TypeCheckerState,
  name : String,
  kind : Kind,
  inner : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let inner_ctx = state.extend_context([Binding::type_binding(name, kind)])

  let body_kind = match inner_ctx.check_kind(inner, lenient) {
    Err(t) => return Err(t)
    Ok(body_kind) => body_kind
  }
  if !(body_kind is Star) {
    return Err(KindMismatch(Star, body_kind))
  }

  Ok(Star)
}

///|
fn check_arrow_kind(
  state : TypeCheckerState,
  from : Type,
  to : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  let from_kind = match state.check_kind(from, lenient) {
    Err(t) => return Err(t)
    Ok(from_kind) => from_kind
  }
  let to_kind = match state.check_kind(to, lenient) {
    Err(t) => return Err(t)
    Ok(to_kind) => to_kind
  }
  if !(to_kind is Star) {
    return Err(KindMismatch(Star, to_kind))
  }

  if !(from_kind is Star) {
    return Err(KindMismatch(Star, from_kind))
  }

  Ok(Star)
}

///|
fn check_tuple_kind(
  state : TypeCheckerState,
  types : Array[Type],
  lenient : Bool,
) -> Result[Kind, TypingError] {
  for ty in types {
    let ty_kind = match state.check_kind(ty, lenient) {
      Err(t) => return Err(t)
      Ok(ty_kind) => ty_kind
    }
    if !(ty_kind is Star) {
      return Err(KindMismatch(Star, ty_kind))
    }
  }
  Ok(Star)
}

///|
/// Description: Computes or validates the kind of a type expression.
/// Example: `let _ = TypeCheckerState::fresh().check_kind(Type::con("Int"), true)`
pub fn TypeCheckerState::check_kind(
  self : TypeCheckerState,
  ty : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  match ty {
    EVar(name) =>
      if self.meta.kinds.contains(name) {
        Ok(self.meta.kinds[name])
      } else {
        Err(Unbound(name))
      }
    Var(name) => check_var_kind(self, name, lenient)
    Con(name) => check_con_kind(self, name, lenient)
    Mu(name, inner) => check_mu_kind(self, name, inner, lenient)
    Variant(cases) => check_variant_kind(self, cases, lenient)
    Record(fields) => check_record_kind(self, fields, lenient)
    App(func, arg) => check_app_kind(self, func, arg, lenient)
    Lam(name, kind, inner) => check_lam_kind(self, name, kind, inner, lenient)
    BoundedForall(name, kind, constraints, inner) =>
      check_bounded_forall_kind(self, name, kind, constraints, inner, lenient)
    Forall(name, kind, inner) =>
      check_forall_kind(self, name, kind, inner, lenient)
    Arrow(from, to) => check_arrow_kind(self, from, to, lenient)
    Ref(_region, _mutability, inner) => {
      let inner_kind = match self.check_kind(inner, lenient) {
        Ok(k) => k
        Err(t) => return Err(t)
      }
      if inner_kind is Star {
        Ok(Star)
      } else {
        Err(KindMismatch(Star, inner_kind))
      }
    }
    Never => Ok(Star)
    Tuple(types) => check_tuple_kind(self, types, lenient)
  }
}

///|
/// Description: Alpha-renames type variable occurrences under binders where valid.
/// Example: `let _ = Type::var_type("A").alpha_rename("A", "B")`
pub fn Type::alpha_rename(self : Type, from : String, to : String) -> Type {
  if from == to {
    return self
  }

  match self {
    Var(name) if name == from => Var(to)
    Arrow(inner_from, inner_to) =>
      Arrow(inner_from.alpha_rename(from, to), inner_to.alpha_rename(from, to))
    Ref(region, mutability, inner) =>
      Ref(region, mutability, inner.alpha_rename(from, to))
    Forall(name, kind, inner) if name != from =>
      Forall(name, kind, inner.alpha_rename(from, to))
    Lam(name, kind, inner) if name != from =>
      Lam(name, kind, inner.alpha_rename(from, to))
    BoundedForall(name, kind, constraints, inner) if name != from =>
      BoundedForall(
        name,
        kind,
        constraints.map(t => TraitConstraint::{
          trait_name: t.trait_name,
          ty: t.ty.alpha_rename(from, to),
        }),
        inner.alpha_rename(from, to),
      )
    App(func, arg) =>
      App(func.alpha_rename(from, to), arg.alpha_rename(from, to))
    Record(pairs) => Record(pairs.map(t => (t.0, t.1.alpha_rename(from, to))))
    Variant(cases) => Variant(cases.map(t => (t.0, t.1.alpha_rename(from, to))))
    Mu(name, inner) if name != from => Mu(name, inner.alpha_rename(from, to))
    Tuple(types) => Tuple(types.map(t => t.alpha_rename(from, to)))
    _ => self
  }
}

///|
/// Description: Adds constraints/solutions to unify two types.
/// Example: `let _ = TypeCheckerState::fresh().unify_types(Type::con("Int"), Type::con("Int"), [], Map::new())`
pub fn TypeCheckerState::unify_types(
  state : TypeCheckerState,
  left : Type,
  right : Type,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  let left = state.normalize_type(left)
  let right = state.normalize_type(right)

  if state.types_equal(left, right) {
    return Ok(())
  }

  // Reject degenerate recursive forms: mu X. X
  match left {
    Mu(name, body) =>
      match body {
        Var(v) if v == name => return Err(Cyclic(name))
        _ => ()
      }
    _ => ()
  }
  match right {
    Mu(name, body) =>
      match body {
        Var(v) if v == name => return Err(Cyclic(name))
        _ => ()
      }
    _ => ()
  }

  // Bottom handling is intentionally asymmetric.
  if state.is_bottom(left) && state.is_bottom(right) {
    return Ok(())
  }
  if state.is_bottom(left) {
    match state.check_kind(right, true) {
      Ok(Star) => return Ok(())
      _ => return Err(TypeMismatch(right, left))
    }
  }
  if state.is_bottom(right) {
    if state.is_bottom(left) {
      return Ok(())
    }
    return Err(TypeMismatch(right, left))
  }

  let left_rigid = left is Var(_)
  let right_rigid = right is Var(_)

  if left_rigid && right_rigid {
    return if state.types_equal(left, right) {
      Ok(())
    } else {
      Err(TypeMismatch(left, right))
    }
  }

  if left_rigid {
    match left {
      Var(name) => if right.occurs_check(name) { return Err(Cyclic(name)) }
      _ => ()
    }

    match right {
      EVar(name) => return state.unify_variable(name, left, subst)
      _ => return Err(TypeMismatch(left, right))
    }
  }

  if right_rigid {
    return state.unify_types(right, left, worklist, subst)
  }

  // Plain variable unification.
  match left {
    Var(name) => return state.unify_variable(name, right, subst)
    _ => ()
  }
  match right {
    Var(name) => return state.unify_variable(name, left, subst)
    _ => ()
  }

  // Flex-rigid / flex-flex meta variable solving.
  match left {
    EVar(flex_name) => {
      let applied_ty = state.apply_substitution(
        subst,
        state.normalize_type(right),
      )
      match state.meta.solutions.get(flex_name) {
        Some(existing) =>
          return state.unify_types(existing, applied_ty, worklist, subst)
        None => ()
      }
      match subst.get(flex_name) {
        Some(existing) => {
          let existing = state.apply_substitution(subst, existing)
          return state.unify_types(existing, applied_ty, worklist, subst)
        }
        None => ()
      }
      if state.meta.occurs_check_evar(flex_name, applied_ty) {
        return Err(Cyclic(flex_name))
      }
      subst.set(flex_name, applied_ty)
      return Ok(())
    }
    _ => ()
  }
  match right {
    EVar(flex_name) => {
      let applied_ty = state.apply_substitution(
        subst,
        state.normalize_type(left),
      )
      match state.meta.solutions.get(flex_name) {
        Some(existing) =>
          return state.unify_types(existing, applied_ty, worklist, subst)
        None => ()
      }
      match subst.get(flex_name) {
        Some(existing) => {
          let existing = state.apply_substitution(subst, existing)
          return state.unify_types(existing, applied_ty, worklist, subst)
        }
        None => ()
      }
      if state.meta.occurs_check_evar(flex_name, applied_ty) {
        return Err(Cyclic(flex_name))
      }
      subst.set(flex_name, applied_ty)
      return Ok(())
    }
    _ => ()
  }

  // Nominal application unification by head constructor + spine args.
  let left_head = left.get_spine_head()
  let right_head = right.get_spine_head()
  match (left_head, right_head) {
    (Con(left_con), Con(right_con)) =>
      if left_con == right_con {
        let left_args = left.get_spine_args()
        let right_args = right.get_spine_args()
        if left_args.length() != right_args.length() {
          return Err(TypeMismatch(left, right))
        }
        loop 0 {
          i if i < left_args.length() => {
            worklist.push(Constraint::type_eq(left_args[i], right_args[i]))
            continue i + 1
          }
          _ => return Ok(())
        }
      }
    _ => ()
  }

  // Enum application ~ structural variant.
  match (left_head, right) {
    (Con(enum_name), Variant(right_cases)) =>
      match state.ctx.find_enum(enum_name) {
        None => ()
        Some(def) => {
          let left_args = left.get_spine_args()
          if left_args.length() != def.params.length() {
            return Err(TypeMismatch(left, right))
          }

          // Exact label-set check.
          let right_labels = Set::new()
          for case in right_cases {
            let (label, _) = case
            right_labels.add(label)
          }
          let def_labels = Set::new()
          for v in def.variants {
            let (label, _) = v
            def_labels.add(label)
          }
          if right_labels.length() != def_labels.length() {
            return Err(TypeMismatch(left, right))
          }
          for label in right_labels {
            if !def_labels.contains(label) {
              return Err(TypeMismatch(left, right))
            }
          }

          for case in right_cases {
            let (label, right_case_ty) = case
            let mut def_case_ty : Type? = None
            for v in def.variants {
              let (v_label, v_ty) = v
              if v_label == label {
                def_case_ty = Some(v_ty)
                break
              }
            }
            let mut inst_case = match def_case_ty {
              Some(t) => t
              None => return Err(TypeMismatch(left, right))
            }
            loop 0 {
              i if i < def.params.length() => {
                inst_case = inst_case.substitute_type(
                  def.params[i],
                  left_args[i],
                )
                continue i + 1
              }
              _ => ()
            }
            worklist.push(Constraint::type_eq(inst_case, right_case_ty))
          }
          return Ok(())
        }
      }
    _ => ()
  }

  // Symmetric case: structural variant ~ enum application.
  match (left, right_head) {
    (Variant(_), Con(_)) =>
      return state.unify_types(right, left, worklist, subst)
    _ => ()
  }

  // Arrow unification with bottom-domain special case.
  match (left, right) {
    (Arrow(left_from, left_to), Arrow(_right_from, right_to)) if state.is_bottom(
        left_from,
      ) => {
      worklist.push(Constraint::type_eq(left_to, right_to))
      return Ok(())
    }
    (Arrow(_left_from, left_to), Arrow(right_from, right_to)) if state.is_bottom(
        right_from,
      ) => {
      worklist.push(Constraint::type_eq(left_to, right_to))
      return Ok(())
    }
    (Arrow(left_from, left_to), Arrow(right_from, right_to)) => {
      worklist.push(Constraint::type_eq(left_from, right_from))
      worklist.push(Constraint::type_eq(left_to, right_to))
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (
      Ref(left_region, left_mutability, left_inner),
      Ref(right_region, right_mutability, right_inner),
    ) => {
      if left_region != right_region || left_mutability != right_mutability {
        return Err(TypeMismatch(left, right))
      }
      worklist.push(Constraint::type_eq(left_inner, right_inner))
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (
      Forall(left_name, left_kind, left_body),
      Forall(right_name, right_kind, right_body),
    ) => {
      if left_kind != right_kind {
        return Err(TypeMismatch(left, right))
      }
      worklist.push(
        Constraint::type_eq(
          left_body,
          right_body.alpha_rename(right_name, left_name),
        ),
      )
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (
      BoundedForall(left_name, left_kind, left_constraints, left_body),
      BoundedForall(right_name, right_kind, right_constraints, right_body),
    ) => {
      if left_kind != right_kind ||
        left_constraints.length() != right_constraints.length() {
        return Err(TypeMismatch(left, right))
      }

      let used = Set::new()
      for left_constraint in left_constraints {
        let mut found = false
        loop 0 {
          i if i < right_constraints.length() => {
            if used.contains(i.to_string()) {
              continue i + 1
            }
            let right_constraint = right_constraints[i]
            if left_constraint.trait_name != right_constraint.trait_name {
              continue i + 1
            }
            worklist.push(
              Constraint::type_eq(
                left_constraint.ty,
                right_constraint.ty.alpha_rename(right_name, left_name),
              ),
            )
            used.add(i.to_string())
            found = true
            break
          }
          _ => ()
        }
        if !found {
          return Err(TypeMismatch(left, right))
        }
      }

      worklist.push(
        Constraint::type_eq(
          left_body,
          right_body.alpha_rename(right_name, left_name),
        ),
      )
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (App(left_func, left_arg), App(right_func, right_arg)) => {
      worklist.push(Constraint::type_eq(left_func, right_func))
      worklist.push(Constraint::type_eq(left_arg, right_arg))
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (
      Lam(left_name, left_kind, left_body),
      Lam(right_name, right_kind, right_body),
    ) => {
      if left_kind != right_kind {
        return Err(TypeMismatch(left, right))
      }
      worklist.push(
        Constraint::type_eq(
          left_body,
          right_body.alpha_rename(right_name, left_name),
        ),
      )
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (Record(left_fields), Record(right_fields)) => {
      if left_fields.length() != right_fields.length() {
        return Err(TypeMismatch(left, right))
      }
      let right_map = Map::from_array(right_fields)
      for left_field in left_fields {
        let (label, left_ty) = left_field
        let right_ty = match right_map.get(label) {
          Some(ty) => ty
          None => return Err(TypeMismatch(left, right))
        }
        worklist.push(Constraint::type_eq(left_ty, right_ty))
      }
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (Variant(left_cases), Variant(right_cases)) => {
      if left_cases.length() != right_cases.length() {
        return Err(TypeMismatch(left, right))
      }
      let right_map = Map::from_array(right_cases)
      for left_case in left_cases {
        let (label, left_ty) = left_case
        let right_ty = match right_map.get(label) {
          Some(ty) => ty
          None => return Err(TypeMismatch(left, right))
        }
        worklist.push(Constraint::type_eq(left_ty, right_ty))
      }
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (Mu(left_name, left_body), Mu(right_name, right_body)) => {
      worklist.push(
        Constraint::type_eq(
          left_body,
          right_body.alpha_rename(right_name, left_name),
        ),
      )
      return Ok(())
    }
    _ => ()
  }

  match (left, right) {
    (Tuple(left_elems), Tuple(right_elems)) => {
      if left_elems.length() != right_elems.length() {
        return Err(TypeMismatch(left, right))
      }
      loop 0 {
        i if i < left_elems.length() => {
          worklist.push(Constraint::type_eq(left_elems[i], right_elems[i]))
          continue i + 1
        }
        _ => return Ok(())
      }
    }
    _ => ()
  }

  Err(TypeMismatch(left, right))
}

///|
/// Description: Unifies a variable name with a type under substitution.
/// Example: `let _ = TypeCheckerState::fresh().unify_variable("A", Type::con("Int"), Map::new())`
pub fn TypeCheckerState::unify_variable(
  self : TypeCheckerState,
  var_name : String,
  ty : Type,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  match subst.get(var_name) {
    Some(existing) =>
      return if self.types_equal(existing, ty) {
        Ok(())
      } else {
        Err(TypeMismatch(existing, ty))
      }
    None => ()
  }

  // var ~ var (tautology)
  match ty {
    Var(name) if name == var_name => return Ok(())
    _ => ()
  }

  // Allow bottom to flow to variable without binding.
  if self.is_bottom(ty) {
    if ty.occurs_check(var_name) {
      return Err(Cyclic(var_name))
    }
    return Ok(())
  }

  if ty.occurs_check(var_name) {
    // Prefer reporting the mu variable on degenerate recursive forms.
    match ty {
      Mu(mu_var, body) =>
        match body {
          Var(v) if v == mu_var => return Err(Cyclic(mu_var))
          _ => ()
        }
      _ => ()
    }
    return Err(Cyclic(var_name))
  }

  subst.set(var_name, ty)
  Ok(())
}

///|
/// Description: Checks exact equality of two kinds.
/// Example: `let _ = unify_kinds(Star, Star)`
pub fn unify_kinds(left : Kind, right : Kind) -> Result[Unit, TypingError] {
  match left == right {
    true => Ok(())
    false => Err(KindMismatch(left, right))
  }
}

///|
/// Description: Checks whether a type variable occurs free in this type.
/// Example: `let _ = Type::arrow(Type::var_type("A"), Type::con("Int")).occurs_check("A")`
pub fn Type::occurs_check(self : Type, var_name : String) -> Bool {
  match self {
    Var(name) => name == var_name
    Arrow(from, to) => from.occurs_check(var_name) || to.occurs_check(var_name)
    Ref(_, _, inner) => inner.occurs_check(var_name)
    Forall(name, _, body) =>
      if name == var_name {
        false
      } else {
        body.occurs_check(var_name)
      }
    Lam(name, _, body) =>
      if name == var_name {
        false
      } else {
        body.occurs_check(var_name)
      }
    App(func, arg) => func.occurs_check(var_name) || arg.occurs_check(var_name)
    Record(fields) =>
      fields.any(field => {
        let (_, ty) = field
        ty.occurs_check(var_name)
      })
    Variant(cases) =>
      cases.any(case_ty => {
        let (_, ty) = case_ty
        ty.occurs_check(var_name)
      })
    BoundedForall(name, _, constraints, body) => {
      if name == var_name {
        return false
      }
      for c in constraints {
        if c.ty.occurs_check(var_name) {
          return true
        }
      }
      body.occurs_check(var_name)
    }
    Mu(name, body) => {
      if name == var_name {
        return false
      }
      match body {
        Var(v) if v == name => true
        _ => body.occurs_check(var_name)
      }
    }
    Tuple(types) => types.any(ty => ty.occurs_check(var_name))
    EVar(_) => false
    Con(_) => false
    Never => false
  }
}

///|
/// Description: Applies substitutions (including solved metas) to a type.
/// Example: `let _ = TypeCheckerState::fresh().apply_substitution(Map::new(), Type::con("Int"))`
pub fn TypeCheckerState::apply_substitution(
  self : TypeCheckerState,
  subst : Substitution,
  ty : Type,
) -> Type {
  fn apply_substitution_impl(
    state : TypeCheckerState,
    subst : Substitution,
    ty : Type,
    visited : Set[String],
    blocked : Set[String],
  ) -> Type {
    match ty {
      EVar(name) => {
        let replacement = match subst.get(name) {
          Some(local_ty) => Some(local_ty)
          None => state.meta.solutions.get(name)
        }
        match replacement {
          Some(next) =>
            if next == ty {
              ty
            } else {
              apply_substitution_impl(state, subst, next, visited, blocked)
            }
          None => ty
        }
      }
      Var(name) => {
        if blocked.contains(name) || visited.contains(name) {
          return ty
        }
        match subst.get(name) {
          Some(next) =>
            apply_substitution_impl(
              state,
              subst,
              next,
              visited..add(name),
              blocked,
            )
          None => ty
        }
      }
      Con(_) => ty
      Never => ty
      Arrow(from, to) =>
        Type::arrow(
          apply_substitution_impl(state, subst, from, visited, blocked),
          apply_substitution_impl(state, subst, to, visited, blocked),
        )
      Ref(region, mutability, inner) =>
        Type::ref_type(
          region,
          mutability,
          apply_substitution_impl(state, subst, inner, visited, blocked),
        )
      Forall(name, kind, body) =>
        Type::forall(
          name,
          kind,
          apply_substitution_impl(
            state,
            subst,
            body,
            visited,
            blocked..add(name),
          ),
        )
      BoundedForall(name, kind, constraints, body) => {
        let blocked = blocked..add(name)
        Type::bounded_forall(
          name,
          kind,
          constraints.map(c => TraitConstraint::{
            trait_name: c.trait_name,
            ty: apply_substitution_impl(state, subst, c.ty, visited, blocked),
          }),
          apply_substitution_impl(state, subst, body, visited, blocked),
        )
      }
      Lam(name, kind, body) =>
        Type::lam(
          name,
          kind,
          apply_substitution_impl(
            state,
            subst,
            body,
            visited,
            blocked..add(name),
          ),
        )
      App(func, arg) =>
        Type::app(
          apply_substitution_impl(state, subst, func, visited, blocked),
          apply_substitution_impl(state, subst, arg, visited, blocked),
        )
      Record(fields) =>
        Type::record(
          fields.map(field => {
            let (label, field_ty) = field
            (
              label,
              apply_substitution_impl(state, subst, field_ty, visited, blocked),
            )
          }),
        )
      Variant(cases) =>
        Type::variant(
          cases.map(case_ty => {
            let (label, inner_ty) = case_ty
            (
              label,
              apply_substitution_impl(state, subst, inner_ty, visited, blocked),
            )
          }),
        )
      Mu(name, body) =>
        Type::mu(
          name,
          apply_substitution_impl(
            state,
            subst,
            body,
            visited,
            blocked..add(name),
          ),
        )
      Tuple(types) =>
        Type::tuple(
          types.map(t => {
            apply_substitution_impl(state, subst, t, visited, blocked)
          }),
        )
    }
  }

  apply_substitution_impl(self, subst, ty, Set::new(), Set::new())
}

///|
fn TypeCheckerState::check_type_core(
  self : TypeCheckerState,
  term : Term,
  expected_type : Type,
) -> Result[(CheckedType, Bool), TypingError] {
  let expected_type = self.normalize_type(expected_type)

  // Expected type must be a proper value type (kind *).
  let expected_kind = match self.check_kind(expected_type, true) {
    Err(t) => return Err(t)
    Ok(k) => k
  }
  if !(expected_kind is Star) {
    return Err(KindMismatch(Star, expected_kind))
  }

  // Native borrow term checking.
  match (term, expected_type) {
    (BorrowShared(target), Ref(_, Shared, expected_inner)) => {
      let target_place = match native_place_from_term_for_typing(target) {
        Some(place) => place
        None =>
          return Err(
            InvalidBorrowTarget(
              "borrow_shared target is not a valid place expression",
            ),
          )
      }

      let result = match self.check_type(target, expected_inner) {
        Ok(result) => result
        Err(t) => return Err(t)
      }

      let subst = result.subst
      let resolved_inner = self.apply_substitution(subst, expected_inner)
      let expected_ref_ty = self.apply_substitution(subst, expected_type)
      let actual_ref_ty = Type::ref_type(
        region_for_native_borrow_place(target_place),
        Mutability::shared(),
        resolved_inner,
      )
      if !self.types_equal(actual_ref_ty, expected_ref_ty) {
        return Err(TypeMismatch(expected_ref_ty, actual_ref_ty))
      }
      return Ok(({ ty: expected_ref_ty, subst }, false))
    }
    (BorrowMut(target), Ref(_, Mutable, expected_inner)) => {
      let target_place = match native_place_from_term_for_typing(target) {
        Some(place) => place
        None =>
          return Err(
            InvalidBorrowTarget(
              "borrow_mut target is not a valid place expression",
            ),
          )
      }

      let result = match self.check_type(target, expected_inner) {
        Ok(result) => result
        Err(t) => return Err(t)
      }

      let subst = result.subst
      let resolved_inner = self.apply_substitution(subst, expected_inner)
      let expected_ref_ty = self.apply_substitution(subst, expected_type)
      let actual_ref_ty = Type::ref_type(
        region_for_native_borrow_place(target_place),
        Mutability::mutable(),
        resolved_inner,
      )
      if !self.types_equal(actual_ref_ty, expected_ref_ty) {
        return Err(TypeMismatch(expected_ref_ty, actual_ref_ty))
      }
      return Ok(({ ty: expected_ref_ty, subst }, false))
    }
    (Deref(inner), _) => {
      let inferred = match infer_deref_type(self, inner) {
        Ok(ty) => ty
        Err(t) => return Err(t)
      }
      if self.is_assignable_to(inferred, expected_type) {
        return Ok(({ ty: expected_type, subst: Map::new() }, false))
      }
      return Err(TypeMismatch(expected_type, inferred))
    }
    (Assign(target, value), Tuple(expected_elements)) =>
      if expected_elements.length() == 0 {
        match infer_assign_type(self, target, value) {
          Ok(_) => return Ok(({ ty: expected_type, subst: Map::new() }, false))
          Err(t) => return Err(t)
        }
      }
    (Move(inner), _) => {
      let checked = match self.check_type(inner, expected_type) {
        Ok(checked) => checked
        Err(t) => return Err(t)
      }
      return Ok((checked, false))
    }
    _ => ()
  }

  // Lambda checking against arrows.
  match (term, expected_type) {
    (Lam(arg, arg_ty, body), Arrow(expected_from, expected_to)) => {
      let worklist : Worklist = []
      let subst : Substitution = Map::new()

      match self.unify_types(arg_ty, expected_from, worklist, subst) {
        Err(t) => return Err(t)
        Ok(_) => ()
      }

      let solved_subst = match self.solve_constraints(worklist, subst) {
        Err(t) => return Err(t)
        Ok(s) => s
      }

      // Commit solved metas to global env when they are true meta vars.
      for entry in solved_subst {
        let (var_name, soln) = entry
        if self.meta.kinds.contains(var_name) {
          match self.solve_meta_var(var_name, soln) {
            Err(t) => return Err(t)
            Ok(_) => ()
          }
        }
      }

      let mut effective_from = self.apply_substitution(
        solved_subst, expected_from,
      )
      if self.is_bottom(expected_from) {
        effective_from = self.meta.fresh_meta_var(Star)
      }

      let inner_state = self.extend_context([Binding::term(arg, effective_from)])
      let expected_body_ty = self.apply_substitution(solved_subst, expected_to)

      let body_check = match inner_state.check_type(body, expected_body_ty) {
        Err(t) => return Err(t)
        Ok(r) => r
      }

      let merged_subst = merge_substs(solved_subst, body_check.subst)
      let mut final_type = self.apply_substitution(merged_subst, expected_type)

      if self.is_bottom(expected_from) {
        match final_type {
          Arrow(_from, to) => final_type = Type::arrow(Type::never(), to)
          _ => ()
        }
      }

      return Ok(({ ty: final_type, subst: merged_subst }, false))
    }
    _ => ()
  }

  // Type lambda checking against forall.
  match (term, expected_type) {
    (
      TyLam(name, kind, body),
      Forall(expected_name, expected_kind, expected_body),
    ) => {
      if kind != expected_kind {
        return Err(KindMismatch(expected_kind, kind))
      }

      let inner_state = self.extend_context([Binding::type_binding(name, kind)])
      let renamed_expected = expected_body.alpha_rename(expected_name, name)
      let body_result = match inner_state.check_type(body, renamed_expected) {
        Err(t) => return Err(t)
        Ok(r) => r
      }

      return Ok(({ ty: expected_type, subst: body_result.subst }, false))
    }
    _ => ()
  }

  // Trait lambda checking against bounded forall.
  match (term, expected_type) {
    (
      TraitLam(trait_var, trait_name, type_var, kind, constraints, body),
      BoundedForall(
        expected_name,
        expected_kind,
        expected_constraints,
        expected_body
      ),
    ) => {
      if kind != expected_kind {
        return Err(KindMismatch(expected_kind, kind))
      }
      if constraints.length() != expected_constraints.length() {
        return Err(TypeMismatch(expected_type, expected_type))
      }

      loop 0 {
        i if i < constraints.length() => {
          let term_constraint = constraints[i]
          let expected_constraint = expected_constraints[i]

          if term_constraint.trait_name != expected_constraint.trait_name {
            return Err(TypeMismatch(expected_type, expected_type))
          }

          let renamed_constraint_ty = expected_constraint.ty.alpha_rename(
            expected_name, type_var,
          )

          if !self.types_equal(term_constraint.ty, renamed_constraint_ty) {
            return Err(TypeMismatch(renamed_constraint_ty, term_constraint.ty))
          }
          continue i + 1
        }
        _ => ()
      }

      let inner_state = self.extend_context([
        Binding::type_binding(type_var, kind),
        Binding::dict(trait_var, trait_name, Var(type_var)),
      ])

      let renamed_expected = expected_body.alpha_rename(expected_name, type_var)
      let body_result = match inner_state.check_type(body, renamed_expected) {
        Err(t) => return Err(t)
        Ok(r) => r
      }

      return Ok(({ ty: expected_type, subst: body_result.subst }, false))
    }
    _ => ()
  }

  // Record checking.
  match (term, expected_type) {
    (Record(fields), Record(expected_fields)) => {
      let term_labels = fields.map(t => t.0)
      let expected_labels = expected_fields.map(t => t.0)
      term_labels.sort()
      expected_labels.sort()

      if term_labels.length() != expected_labels.length() {
        let actual = Type::record(fields.map(t => (t.0, Type::unit())))
        return Err(TypeMismatch(expected_type, actual))
      }
      loop 0 {
        i if i < term_labels.length() => {
          if term_labels[i] != expected_labels[i] {
            let actual = Type::record(fields.map(t => (t.0, Type::unit())))
            return Err(TypeMismatch(expected_type, actual))
          }
          continue i + 1
        }
        _ => ()
      }

      let mut acc_subst : Substitution = Map::new()
      for field in fields {
        let (label, field_term) = field
        let mut expected_field_ty : Type? = None
        for t in expected_fields {
          if t.0 == label {
            expected_field_ty = Some(t.1)
            break
          }
        }
        let expected_field_ty = match expected_field_ty {
          Some(ty) => ty
          None => return Err(MissingField(expected_type, label))
        }
        let expected_field_ty = self.apply_substitution(
          acc_subst, expected_field_ty,
        )
        let field_result = match
          self.check_type(field_term, expected_field_ty) {
          Err(t) => return Err(t)
          Ok(r) => r
        }
        acc_subst = merge_substs(field_result.subst, acc_subst)
      }

      return Ok(
        (
          {
            ty: self.apply_substitution(acc_subst, expected_type),
            subst: acc_subst,
          },
          false,
        ),
      )
    }
    _ => ()
  }

  // Tuple checking.
  match (term, expected_type) {
    (Tuple(elements), Tuple(expected_elements)) => {
      if elements.length() != expected_elements.length() {
        let actual = Type::tuple(elements.map(_ => Type::unit()))
        return Err(TypeMismatch(expected_type, actual))
      }

      let mut acc_subst : Substitution = Map::new()
      loop 0 {
        i if i < elements.length() => {
          let expected_elem_ty = self.apply_substitution(
            acc_subst,
            expected_elements[i],
          )
          let element_result = match
            self.check_type(elements[i], expected_elem_ty) {
            Err(t) => return Err(t)
            Ok(r) => r
          }
          acc_subst = merge_substs(element_result.subst, acc_subst)
          continue i + 1
        }
        _ => ()
      }
      return Ok(
        (
          {
            ty: self.apply_substitution(acc_subst, expected_type),
            subst: acc_subst,
          },
          false,
        ),
      )
    }
    _ => ()
  }

  // Variant injection checking.
  match term {
    Inject(label, value, _variant_ty) => {
      let variant_ty = self.normalize_type(expected_type)
      match variant_ty {
        Variant(cases) => {
          let mut case_ty : Type? = None
          for t in cases {
            if t.0 == label {
              case_ty = Some(t.1)
              break
            }
          }
          let case_ty = match case_ty {
            Some(t) => t
            None => return Err(InvalidVariantLabel(variant_ty, label))
          }
          let value_result = match self.check_type(value, case_ty) {
            Err(t) => return Err(t)
            Ok(r) => r
          }
          return Ok(
            (
              {
                ty: self.apply_substitution(value_result.subst, expected_type),
                subst: value_result.subst,
              },
              false,
            ),
          )
        }
        _ => return Err(NotAVariant(expected_type))
      }
    }
    _ => ()
  }

  // Fold checking against recursive type.
  match term {
    Fold(fold_ty, inner_term) =>
      match expected_type {
        Mu(name, body) => {
          let unfolded = body.substitute_type(name, expected_type)
          let term_result = match self.check_type(inner_term, unfolded) {
            Err(t) => return Err(t)
            Ok(r) => r
          }
          return Ok(({ ty: expected_type, subst: term_result.subst }, false))
        }
        _ => return Err(TypeMismatch(expected_type, fold_ty))
      }
    _ => ()
  }

  // Fallback: infer and subsume.
  let inferred_type = match self.infer_type(term) {
    Err(t) => return Err(t)
    Ok(ty) => ty
  }

  let mut poly_inferred = inferred_type
  if poly_inferred is Forall(_, _, _) && !(expected_type is Forall(_, _, _)) {
    poly_inferred = self.instantiate_type(poly_inferred)
    let wl : Worklist = []
    let subst : Substitution = Map::new()
    match self.unify_types(poly_inferred, expected_type, wl, subst) {
      Err(_) => ()
      Ok(_) =>
        match self.solve_constraints(wl, subst) {
          Err(t) => return Err(t)
          Ok(sol) => poly_inferred = self.apply_substitution(sol, poly_inferred)
        }
    }
  }

  let worklist : Worklist = []
  let subst : Substitution = Map::new()
  match self.subsumes(expected_type, poly_inferred, worklist, subst) {
    Err(t) => return Err(t)
    Ok(_) => ()
  }

  let final_subst = match self.solve_constraints(worklist, subst) {
    Err(t) => return Err(t)
    Ok(s) => s
  }

  for entry in final_subst {
    let (var_name, soln) = entry
    if self.meta.kinds.contains(var_name) {
      match self.solve_meta_var(var_name, soln) {
        Err(t) => return Err(t)
        Ok(_) => ()
      }
    }
  }

  let resolved_expected = self.apply_substitution(final_subst, expected_type)

  if !self.is_assignable_to(poly_inferred, resolved_expected) {
    let final_inferred = self.apply_substitution(final_subst, poly_inferred)
    return Err(TypeMismatch(resolved_expected, final_inferred))
  }

  Ok(({ ty: resolved_expected, subst: final_subst }, true))
}

///|
/// Description: Checks a term against an expected type and returns solved substitutions.
/// Example: `let _ = TypeCheckerState::fresh().check_type(Term::unit(), Type::unit())`
pub fn TypeCheckerState::check_type(
  self : TypeCheckerState,
  term : Term,
  expected_type : Type,
) -> Result[CheckedType, TypingError] {
  match self.check_type_core(term, expected_type) {
    Ok((checked, _used_infer_fallback)) => Ok(checked)
    Err(t) => Err(t)
  }
}

///|
fn find_trait_def(state : TypeCheckerState, name : String) -> TraitDefBinding? {
  for b in state.ctx.0 {
    if b is TraitDef(binding) && binding.name == name {
      return Some(binding)
    }
  }
  None
}

///|
fn find_dict_binding(state : TypeCheckerState, name : String) -> DictBinding? {
  for b in state.ctx.0 {
    if b is Dict(binding) && binding.name == name {
      return Some(binding)
    }
  }
  None
}

///|
fn find_named_type(pairs : Array[(String, Type)], name : String) -> Type? {
  for p in pairs {
    if p.0 == name {
      return Some(p.1)
    }
  }
  None
}

///|
fn find_named_term(pairs : Array[(String, Term)], name : String) -> Term? {
  for p in pairs {
    if p.0 == name {
      return Some(p.1)
    }
  }
  None
}

///|
fn infer_var_type(
  state : TypeCheckerState,
  name : String,
) -> Result[Type, TypingError] {
  for b in state.ctx.0 {
    if b is Term(binding) && binding.name == name {
      return Ok(binding.ty)
    }
  }
  Err(Unbound(name))
}

///|
fn infer_lam_type(
  state : TypeCheckerState,
  arg : String,
  arg_ty : Type,
  body : Term,
) -> Result[Type, TypingError] {
  let arg_kind = match state.check_kind(arg_ty, false) {
    Ok(k) => k
    Err(t) => return Err(t)
  }
  if !(arg_kind is Star) {
    return Err(KindMismatch(Star, arg_kind))
  }

  let inner_state = state.extend_context([Binding::term(arg, arg_ty)])
  let body_ty = match inner_state.infer_type(body) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }

  Ok(Arrow(arg_ty, body_ty))
}

///|
fn infer_let_type(
  state : TypeCheckerState,
  name : String,
  value : Term,
  body : Term,
) -> Result[Type, TypingError] {
  let value_ty = match state.infer_type(value) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let inner_state = state.extend_context([Binding::term(name, value_ty)])
  inner_state.infer_type(body)
}

///|
fn infer_tylam_type(
  state : TypeCheckerState,
  name : String,
  kind : Kind,
  body : Term,
) -> Result[Type, TypingError] {
  let inner_state = state.extend_context([Binding::type_binding(name, kind)])
  let body_ty = match inner_state.infer_type(body) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  Ok(Forall(name, kind, body_ty))
}

///|
fn infer_tyapp_type(
  state : TypeCheckerState,
  term : Term,
  ty : Type,
) -> Result[Type, TypingError] {
  let term_ty = match state.infer_type(term) {
    Ok(t) => t
    Err(t) => return Err(t)
  }

  match term_ty {
    Forall(name, kind, body) => {
      let arg_kind = match state.check_kind(ty, false) {
        Ok(k) => k
        Err(t) => return Err(t)
      }
      if kind != arg_kind {
        return Err(KindMismatch(kind, arg_kind))
      }
      Ok(body.substitute_type(name, ty))
    }
    _ => Err(TypeMismatch(term_ty, ty))
  }
}

///|
fn infer_self_from_argument(
  state : TypeCheckerState,
  arg_ty : Type,
  param_ty : Type,
  self_var : String,
  self_kind : Kind,
) -> Result[Type, TypingError] {
  let self_meta = state.meta.fresh_meta_var(self_kind)
  let expected = param_ty.substitute_type(self_var, self_meta)
  let worklist : Worklist = []
  let subst : Substitution = Map::new()

  match state.unify_types(arg_ty, expected, worklist, subst) {
    Ok(_) => ()
    Err(t) => return Err(t)
  }

  let solved = match state.solve_constraints(worklist, subst) {
    Ok(s) => s
    Err(t) => return Err(t)
  }

  let inferred_self = state.apply_substitution(solved, self_meta)
  Ok(state.normalize_type(inferred_self))
}

///|
fn infer_app_type(
  state : TypeCheckerState,
  callee : Term,
  arg : Term,
) -> Result[Type, TypingError] {
  let callee_inferred = match state.infer_type(callee) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let arg_inferred = match state.infer_type(arg) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }

  let mut instantiated_callee = callee_inferred

  while instantiated_callee is Forall(name, kind, body) {
    let fresh = state.meta.fresh_meta_var(kind)
    instantiated_callee = body.substitute_type(name, fresh)
  }

  while instantiated_callee is BoundedForall(name, kind, constraints, body0) {
    let mut body = body0
    while body is Forall(n, k, inner) {
      body = inner.substitute_type(n, state.meta.fresh_meta_var(k))
    }

    let expected_param = match body {
      Arrow(from, _) => from
      _ => return Err(NotAFunction(instantiated_callee))
    }

    let inferred_self = match
      infer_self_from_argument(state, arg_inferred, expected_param, name, kind) {
      Ok(ty) => ty
      Err(_) => return Err(NotAFunction(instantiated_callee))
    }

    let instantiated_constraints = constraints.map(c => TraitConstraint::{
      trait_name: c.trait_name,
      ty: c.ty.substitute_type(name, inferred_self),
    })

    match state.check_trait_constraints(instantiated_constraints) {
      Ok(_) => ()
      Err(t) => return Err(t)
    }

    instantiated_callee = body.substitute_type(name, inferred_self)
    while instantiated_callee is Forall(n, k, inner) {
      instantiated_callee = inner.substitute_type(
        n,
        state.meta.fresh_meta_var(k),
      )
    }
  }

  let (param_ty, result_ty_base) = match instantiated_callee {
    Arrow(from, to) => (from, to)
    _ => return Err(NotAFunction(instantiated_callee))
  }

  let arg_check = state.check_type(arg, param_ty)
  match arg_check {
    Ok({ subst: local_subst, .. }) => {
      let merged = merge_substs(local_subst, state.meta.solutions)
      let resolved = state.apply_substitution(merged, result_ty_base)
      Ok(state.normalize_type(resolved))
    }
    Err(original_err) => {
      let worklist : Worklist = []
      let subst : Substitution = Map::new()
      match state.unify_types(arg_inferred, param_ty, worklist, subst) {
        Err(_) => Err(original_err)
        Ok(_) => {
          let solved = match state.solve_constraints(worklist, subst) {
            Ok(s) => s
            Err(t) => return Err(t)
          }
          Ok(state.apply_substitution(solved, result_ty_base))
        }
      }
    }
  }
}

///|
fn infer_dict_type(
  state : TypeCheckerState,
  trait_name : String,
  dict_ty : Type,
  methods : Array[(String, Term)],
) -> Result[Type, TypingError] {
  let trait_def = match find_trait_def(state, trait_name) {
    Some(def) => def
    None => return Err(Unbound(trait_name))
  }

  let dict_kind = match state.check_kind(dict_ty, false) {
    Ok(k) => k
    Err(t) => return Err(t)
  }
  if trait_def.kind != dict_kind {
    return Err(KindMismatch(trait_def.kind, dict_kind))
  }

  let required = trait_def.methods.map(m => m.0)
  for method_name in required {
    let found = methods.any(m => m.0 == method_name)
    if !found {
      return Err(MissingMethod(trait_name, method_name))
    }
  }

  let method_state = state.extend_context([Binding::term("self", dict_ty)])

  for method_entry in methods {
    let (method_name, method_impl) = method_entry
    let expected_ty = find_named_type(trait_def.methods, method_name)
    if expected_ty is None {
      continue
    }
    let expected_ty = expected_ty
      .unwrap()
      .substitute_type(trait_def.type_param, dict_ty)

    match method_state.check_type(method_impl, expected_ty) {
      Ok(_) => ()
      Err(_) => {
        let actual = match method_state.infer_type(method_impl) {
          Ok(ty) => ty
          Err(t) => return Err(t)
        }
        return Err(TypeMismatch(expected_ty, actual))
      }
    }
  }

  Ok(Con("Dictionary"))
}

///|
fn infer_trait_lam_type(
  state : TypeCheckerState,
  trait_var : String,
  trait_name : String,
  type_var : String,
  kind : Kind,
  constraints : Array[TraitConstraint],
  body : Term,
) -> Result[Type, TypingError] {
  if find_trait_def(state, trait_name) is None {
    return Err(Unbound(trait_name))
  }

  let inner_state = state.extend_context([
    Binding::type_binding(type_var, kind),
    Binding::dict(trait_var, trait_name, Var(type_var)),
  ])
  let body_ty = match inner_state.infer_type(body) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  Ok(BoundedForall(type_var, kind, constraints, body_ty))
}

///|
fn infer_trait_app_type(
  state : TypeCheckerState,
  term : Term,
  ty : Type,
  dicts : Array[Term],
) -> Result[Type, TypingError] {
  let term_ty = match state.infer_type(term) {
    Ok(t) => t
    Err(t) => return Err(t)
  }

  let (var_name, kind, constraints, body) = match term_ty {
    BoundedForall(name, kind, constraints, body) =>
      (name, kind, constraints, body)
    _ => return Err(TypeMismatch(term_ty, ty))
  }

  let arg_kind = match state.check_kind(ty, false) {
    Ok(k) => k
    Err(t) => return Err(t)
  }
  if kind != arg_kind {
    return Err(KindMismatch(kind, arg_kind))
  }

  let instantiated_constraints = constraints.map(c => TraitConstraint::{
    trait_name: c.trait_name,
    ty: c.ty.substitute_type(var_name, ty),
  })

  if dicts.length() != instantiated_constraints.length() {
    return Err(
      WrongNumberOfDicts(instantiated_constraints.length(), dicts.length()),
    )
  }

  loop 0 {
    i if i < dicts.length() => {
      let provided = dicts[i]
      let expected = instantiated_constraints[i]
      match provided {
        Dict(_name, provided_ty, _methods) => {
          let inferred = match state.infer_type(provided) {
            Ok(t) => t
            Err(t) => return Err(t)
          }
          if !state.types_equal(provided_ty, expected.ty) {
            return Err(TypeMismatch(expected.ty, inferred))
          }
        }
        _ =>
          match state.infer_type(provided) {
            Ok(_) => ()
            Err(t) => return Err(t)
          }
      }
      continue i + 1
    }
    _ => ()
  }

  Ok(body.substitute_type(var_name, ty))
}

///|
fn infer_trait_method_type(
  state : TypeCheckerState,
  dict : Term,
  method_name : String,
) -> Result[Type, TypingError] {
  let dict_ty = match state.infer_type(dict) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }

  match dict {
    Var(dict_name) => {
      let dict_binding = match find_dict_binding(state, dict_name) {
        Some(b) => b
        None => return Err(Unbound(dict_name))
      }
      let trait_def = match find_trait_def(state, dict_binding.trait_name) {
        Some(d) => d
        None => return Err(Unbound(dict_binding.trait_name))
      }
      let method_ty = match find_named_type(trait_def.methods, method_name) {
        Some(m) => m
        None => return Err(MissingMethod(dict_binding.trait_name, method_name))
      }
      Ok(method_ty.substitute_type(trait_def.type_param, dict_binding.ty))
    }
    Dict(name, _ty, methods) => {
      let method_impl = match find_named_term(methods, method_name) {
        Some(m) => m
        None => return Err(MissingMethod(name, method_name))
      }
      state.infer_type(method_impl)
    }
    _ => Err(TypeMismatch(Con("Dictionary"), dict_ty))
  }
}

///|
fn infer_record_type(
  state : TypeCheckerState,
  fields : Array[(String, Term)],
) -> Result[Type, TypingError] {
  let typed_fields : Array[(String, Type)] = []
  for field in fields {
    let (label, term) = field
    let ty = match state.infer_type(term) {
      Ok(t) => t
      Err(t) => return Err(t)
    }
    typed_fields.push((label, ty))
  }
  Ok(Record(typed_fields))
}

///|
fn infer_project_type(
  state : TypeCheckerState,
  record : Term,
  label : String,
) -> Result[Type, TypingError] {
  let record_ty = match state.infer_type(record) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let norm = state.normalize_type(record_ty)
  match norm {
    Record(fields) =>
      match find_named_type(fields, label) {
        Some(t) => Ok(t)
        None => Err(MissingField(norm, label))
      }
    _ => Err(NotARecord(norm))
  }
}

///|
fn check_inject_value(
  state : TypeCheckerState,
  value : Term,
  expected_field_ty : Type,
) -> Result[Type, TypingError] {
  if state.is_bottom(expected_field_ty) {
    return Ok(Type::never())
  }

  match expected_field_ty {
    Tuple(field_types) => {
      if field_types.length() == 0 {
        match value {
          Tuple(items) if items.length() == 0 => return Ok(Type::unit())
          _ => {
            let actual = match state.infer_type(value) {
              Ok(ty) => ty
              Err(_) => Type::unit()
            }
            return Err(TypeMismatch(expected_field_ty, actual))
          }
        }
      }

      if field_types.length() == 1 {
        match state.check_type(value, field_types[0]) {
          Ok(res) => return Ok(res.ty)
          Err(t) => return Err(t)
        }
      }

      let values = match value {
        Tuple(values) => values
        _ => return Err(TypeMismatch(expected_field_ty, Type::Tuple([])))
      }
      if values.length() != field_types.length() {
        let actual = Type::Tuple(
          values.map(_ => state.meta.fresh_meta_var(Star)),
        )
        return Err(TypeMismatch(expected_field_ty, actual))
      }

      let value_types : Array[Type] = []
      loop 0 {
        i if i < values.length() => {
          let check = match state.check_type(values[i], field_types[i]) {
            Ok(r) => r
            Err(t) => return Err(t)
          }
          value_types.push(check.ty)
          continue i + 1
        }
        _ => ()
      }
      Ok(Tuple(value_types))
    }
    _ =>
      match state.check_type(value, expected_field_ty) {
        Ok(res) => Ok(res.ty)
        Err(t) => Err(t)
      }
  }
}

///|
fn infer_inject_type(
  state : TypeCheckerState,
  label : String,
  value : Term,
  variant_ty : Type,
) -> Result[Type, TypingError] {
  match variant_ty {
    Con(name) => {
      let def = match state.ctx.find_enum(name) {
        Some(d) => d
        None => {
          let norm = state.normalize_type(variant_ty)
          return match norm {
            Variant(cases) =>
              match find_named_type(cases, label) {
                Some(case_ty) =>
                  match check_inject_value(state, value, case_ty) {
                    Ok(_) => Ok(variant_ty)
                    Err(t) => Err(t)
                  }
                None => Err(InvalidVariantLabel(norm, label))
              }
            _ => Err(NotAVariant(variant_ty))
          }
        }
      }

      let variant = match find_named_type(def.variants, label) {
        Some(v) => v
        None => return Err(InvalidVariantLabel(variant_ty, label))
      }
      match check_inject_value(state, value, variant) {
        Ok(_) => Ok(variant_ty)
        Err(t) => Err(t)
      }
    }
    App(_, _) => {
      let head = variant_ty.get_spine_head()
      match head {
        Con(name) =>
          match state.ctx.find_enum(name) {
            Some(def) => {
              let args = variant_ty.get_spine_args()
              if args.length() != def.params.length() {
                return Err(KindMismatch(def.kind, Star))
              }

              let variant = match find_named_type(def.variants, label) {
                Some(v) => v
                None => return Err(InvalidVariantLabel(variant_ty, label))
              }

              let mut field_ty = variant
              loop 0 {
                i if i < def.params.length() => {
                  field_ty = field_ty.substitute_type(def.params[i], args[i])
                  continue i + 1
                }
                _ => ()
              }
              let field_ty = state.normalize_type(field_ty)

              match check_inject_value(state, value, field_ty) {
                Ok(_) => Ok(variant_ty)
                Err(t) => Err(t)
              }
            }
            None => {
              let norm = state.normalize_type(variant_ty)
              match norm {
                Variant(cases) =>
                  match find_named_type(cases, label) {
                    Some(case_ty) =>
                      match check_inject_value(state, value, case_ty) {
                        Ok(_) => Ok(variant_ty)
                        Err(t) => Err(t)
                      }
                    None => Err(InvalidVariantLabel(norm, label))
                  }
                _ => Err(NotAVariant(variant_ty))
              }
            }
          }
        _ => Err(NotAVariant(variant_ty))
      }
    }
    _ => {
      let norm = state.normalize_type(variant_ty)
      match norm {
        Variant(cases) =>
          match find_named_type(cases, label) {
            Some(case_ty) =>
              match check_inject_value(state, value, case_ty) {
                Ok(_) => Ok(variant_ty)
                Err(t) => Err(t)
              }
            None => Err(InvalidVariantLabel(norm, label))
          }
        _ => Err(NotAVariant(variant_ty))
      }
    }
  }
}

///|
fn infer_match_type(
  state : TypeCheckerState,
  scrutinee : Term,
  cases : Array[(Pattern, Term)],
) -> Result[Type, TypingError] {
  let scrutinee_ty = match state.infer_type(scrutinee) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }

  let mut normalized_scrutinee = state.normalize_type(scrutinee_ty)
  if normalized_scrutinee is Mu(name, body) {
    normalized_scrutinee = body.substitute_type(name, normalized_scrutinee)
  }

  let patterns = cases.map(c => c.0)
  match state.check_exhaustive(patterns, normalized_scrutinee) {
    Ok(_) => ()
    Err(t) => return Err(t)
  }

  let mut common_ty : Type? = None
  for case_entry in cases {
    let (pat, body) = case_entry
    let current_scrutinee = state.normalize_type(
      state.apply_substitution(state.meta.solutions, normalized_scrutinee),
    )

    let pattern_ctx = match state.check_pattern(pat, current_scrutinee) {
      Ok(ctx) => ctx
      Err(t) => return Err(t)
    }

    let extended = state.extend_context(pattern_ctx.0)
    let body_ty = match extended.infer_type(body) {
      Ok(ty) => ty
      Err(t) => return Err(t)
    }
    let body_ty = state.normalize_type(state.instantiate_type(body_ty))

    match common_ty {
      None => common_ty = Some(body_ty)
      Some(acc) => {
        let worklist : Worklist = []
        let subst : Substitution = Map::new()

        let first_try = state.subsumes(body_ty, acc, worklist, subst)
        if first_try is Err(_) {
          ignore(worklist.clear())
          ignore(subst.clear())
          match state.subsumes(acc, body_ty, worklist, subst) {
            Ok(_) => ()
            Err(_) =>
              match state.unify_types(acc, body_ty, worklist, subst) {
                Ok(_) => ()
                Err(t) => return Err(t)
              }
          }
        }

        let solved = match state.solve_constraints(worklist, subst) {
          Ok(s) => s
          Err(t) => return Err(t)
        }
        common_ty = Some(state.apply_substitution(solved, acc))
      }
    }
  }

  match common_ty {
    Some(ty) => Ok(state.normalize_type(ty))
    None => Err(Message("Cannot infer type of empty match"))
  }
}

///|
fn infer_fold_type(
  state : TypeCheckerState,
  fold_ty : Type,
  inner_term : Term,
) -> Result[Type, TypingError] {
  let kind = match state.check_kind(fold_ty, false) {
    Ok(k) => k
    Err(t) => return Err(t)
  }
  if !(kind is Star) {
    return Err(KindMismatch(Star, kind))
  }

  let norm = state.normalize_type(fold_ty)
  let unfolded = match norm {
    Mu(name, body) => state.normalize_type(body.substitute_type(name, norm))
    _ => return Err(TypeMismatch(norm, fold_ty))
  }

  let inner_ty = match state.infer_type(inner_term) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let inner_ty = state.normalize_type(inner_ty)

  if !state.is_assignable_to(inner_ty, unfolded) {
    return Err(TypeMismatch(unfolded, inner_ty))
  }

  Ok(fold_ty)
}

///|
fn infer_unfold_type(
  state : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  let term_ty = match state.infer_type(term) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let norm = state.normalize_type(term_ty)
  match norm {
    Mu(name, body) => Ok(state.normalize_type(body.substitute_type(name, norm)))
    _ => Err(NotAFunction(norm))
  }
}

///|
fn native_place_from_term_for_typing(term : Term) -> Place? {
  borrow_place_from_term(term)
}

///|
fn region_for_native_borrow_place(place : Place) -> Region {
  Region::named("borrow::" + place.key_path())
}

///|
fn assignment_place_for_error(target : Term) -> Place {
  match native_place_from_term_for_typing(target) {
    Some(place) => place
    None => Place::root("<assign-target>")
  }
}

///|
fn infer_borrow_type(
  state : TypeCheckerState,
  target : Term,
  mutability : Mutability,
  op_name : String,
) -> Result[Type, TypingError] {
  let target_ty = match state.infer_type(target) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let target_place = match native_place_from_term_for_typing(target) {
    Some(place) => place
    None =>
      return Err(
        InvalidBorrowTarget(op_name + " target is not a valid place expression"),
      )
  }

  let target_kind = match state.check_kind(target_ty, true) {
    Ok(k) => k
    Err(t) => return Err(t)
  }
  if !(target_kind is Star) {
    return Err(KindMismatch(Star, target_kind))
  }

  Ok(
    Type::ref_type(
      region_for_native_borrow_place(target_place),
      mutability,
      target_ty,
    ),
  )
}

///|
fn infer_deref_type(
  state : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  let term_ty = match state.infer_type(term) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let term_ty = state.normalize_type(term_ty)
  match term_ty {
    Ref(_, _, inner) => Ok(inner)
    _ =>
      Err(InvalidBorrowTarget("deref target is not a valid place expression"))
  }
}

///|
fn infer_assign_type(
  state : TypeCheckerState,
  target : Term,
  value : Term,
) -> Result[Type, TypingError] {
  if native_place_from_term_for_typing(target) is None {
    return Err(
      InvalidBorrowTarget("assign target is not a valid place expression"),
    )
  }

  let target_ty = match state.infer_type(target) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let target_ty = state.normalize_type(target_ty)

  match target_ty {
    Ref(_, Mutable, inner) =>
      match state.check_type(value, inner) {
        Ok(_) => Ok(Type::unit())
        Err(t) => Err(t)
      }
    Ref(_, Shared, _inner) =>
      Err(AssignToImmutable(assignment_place_for_error(target)))
    _ =>
      Err(InvalidBorrowTarget("assign target is not a valid place expression"))
  }
}

///|
fn infer_move_type(
  state : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  state.infer_type(term)
}

///|
fn infer_tuple_type(
  state : TypeCheckerState,
  elements : Array[Term],
) -> Result[Type, TypingError] {
  let element_types : Array[Type] = []
  for term in elements {
    let ty = match state.infer_type(term) {
      Ok(ty) => ty
      Err(t) => return Err(t)
    }
    element_types.push(ty)
  }
  Ok(Tuple(element_types))
}

///|
fn infer_tuple_project_type(
  state : TypeCheckerState,
  tuple_term : Term,
  index : Int,
) -> Result[Type, TypingError] {
  let tuple_ty = match state.infer_type(tuple_term) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }
  let norm = state.normalize_type(tuple_ty)
  match norm {
    Tuple(elements) =>
      if index < 0 || index >= elements.length() {
        Err(TupleIndexOutOfBounds(norm, index))
      } else {
        Ok(elements[index])
      }
    _ => Err(NotATuple(norm))
  }
}

///|
fn term_contains_native_borrow_syntax(term : Term) -> Bool {
  match term {
    Var(_) => false
    Con(_, _) => false
    BorrowShared(_) => true
    BorrowMut(_) => true
    Deref(_) => true
    Assign(_, _) => true
    Move(_) => true
    Lam(_, _, body) => term_contains_native_borrow_syntax(body)
    App(callee, arg) =>
      term_contains_native_borrow_syntax(callee) ||
      term_contains_native_borrow_syntax(arg)
    Let(_, value, body) =>
      term_contains_native_borrow_syntax(value) ||
      term_contains_native_borrow_syntax(body)
    TyLam(_, _, body) => term_contains_native_borrow_syntax(body)
    TyApp(value, _) => term_contains_native_borrow_syntax(value)
    Dict(_, _, methods) =>
      methods.any(entry => term_contains_native_borrow_syntax(entry.1))
    TraitLam(_, _, _, _, _, body) => term_contains_native_borrow_syntax(body)
    TraitApp(value, _, dicts) =>
      term_contains_native_borrow_syntax(value) ||
      dicts.any(dict => term_contains_native_borrow_syntax(dict))
    TraitMethod(dict_term, _) => term_contains_native_borrow_syntax(dict_term)
    Record(fields) =>
      fields.any(entry => term_contains_native_borrow_syntax(entry.1))
    Project(record_term, _) => term_contains_native_borrow_syntax(record_term)
    Inject(_, value_term, _) => term_contains_native_borrow_syntax(value_term)
    Match(scrutinee, cases) =>
      term_contains_native_borrow_syntax(scrutinee) ||
      cases.any(entry => term_contains_native_borrow_syntax(entry.1))
    Fold(_, inner) => term_contains_native_borrow_syntax(inner)
    Unfold(inner) => term_contains_native_borrow_syntax(inner)
    Tuple(elements) =>
      elements.any(element => term_contains_native_borrow_syntax(element))
    TupleProject(tuple_term, _) =>
      term_contains_native_borrow_syntax(tuple_term)
  }
}

///|
fn infer_type_core(
  state : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  match term {
    Var(name) => infer_var_type(state, name)
    Con(_, ty) => Ok(ty)
    Lam(arg, arg_ty, body) => infer_lam_type(state, arg, arg_ty, body)
    App(callee, arg) => infer_app_type(state, callee, arg)
    BorrowShared(target) =>
      infer_borrow_type(state, target, Mutability::shared(), "borrow_shared")
    BorrowMut(target) =>
      infer_borrow_type(state, target, Mutability::mutable(), "borrow_mut")
    Deref(inner) => infer_deref_type(state, inner)
    Assign(target, value) => infer_assign_type(state, target, value)
    Move(inner) => infer_move_type(state, inner)
    Let(name, value, body) => infer_let_type(state, name, value, body)
    TyLam(name, kind, body) => infer_tylam_type(state, name, kind, body)
    TyApp(term, ty) => infer_tyapp_type(state, term, ty)
    Dict(trait_name, dict_ty, methods) =>
      infer_dict_type(state, trait_name, dict_ty, methods)
    TraitLam(trait_var, trait_name, type_var, kind, constraints, body) =>
      infer_trait_lam_type(
        state, trait_var, trait_name, type_var, kind, constraints, body,
      )
    TraitApp(term, ty, dicts) => infer_trait_app_type(state, term, ty, dicts)
    TraitMethod(dict, method_name) =>
      infer_trait_method_type(state, dict, method_name)
    Record(fields) => infer_record_type(state, fields)
    Project(record, label) => infer_project_type(state, record, label)
    Inject(label, value, variant_ty) =>
      infer_inject_type(state, label, value, variant_ty)
    Match(scrutinee, cases) => infer_match_type(state, scrutinee, cases)
    Fold(fold_ty, inner_term) => infer_fold_type(state, fold_ty, inner_term)
    Unfold(inner) => infer_unfold_type(state, inner)
    Tuple(elements) => infer_tuple_type(state, elements)
    TupleProject(tuple_term, index) =>
      infer_tuple_project_type(state, tuple_term, index)
  }
}

///|
fn infer_type_with_native_policy_flag(
  state : TypeCheckerState,
  term : Term,
) -> Result[(Type, Bool), TypingError] {
  let inferred = match infer_type_core(state, term) {
    Ok(ty) => ty
    Err(t) => return Err(t)
  }

  let contains_native_borrow = term_contains_native_borrow_syntax(term)
  if contains_native_borrow {
    match
      state.analyze_borrows(term, inferred, BorrowCheckerOptions::default()) {
      Ok(_) => ()
      Err(t) => return Err(t)
    }
  }

  Ok((inferred, contains_native_borrow))
}

///|
fn check_type_with_native_policy_flag(
  state : TypeCheckerState,
  term : Term,
  expected_type : Type,
) -> Result[(CheckedType, Bool), TypingError] {
  let checked_with_fallback_flag = match
    state.check_type_core(term, expected_type) {
    Ok(checked_with_fallback_flag) => checked_with_fallback_flag
    Err(t) => return Err(t)
  }
  let checked = checked_with_fallback_flag.0
  let used_infer_fallback = checked_with_fallback_flag.1
  let native_policy_already_applied_by_fallback = term_contains_native_borrow_syntax(
      term,
    ) &&
    used_infer_fallback
  Ok((checked, native_policy_already_applied_by_fallback))
}

///|
/// Description: Infers a type for a term.
/// Example: `let _ = TypeCheckerState::fresh().infer_type(Term::unit())`
pub fn TypeCheckerState::infer_type(
  self : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  match infer_type_with_native_policy_flag(self, term) {
    Ok((ty, _contains_native_borrow)) => Ok(ty)
    Err(t) => return Err(t)
  }
}

///|
/// Description: Returns the head of a nested type application spine.
/// Example: `let _ = Type::app(Type::con("F"), Type::con("Int")).get_spine_head()`
pub fn Type::get_spine_head(self : Type) -> Type {
  loop self {
    App(func, _) => continue func
    self => break self
  }
}

///|
/// Description: Returns application spine arguments in evaluation order.
/// Example: `let _ = Type::app(Type::con("F"), Type::con("Int")).get_spine_args()`
pub fn Type::get_spine_args(self : Type) -> Array[Type] {
  let args_rev : Array[Type] = []
  let mut cur = self
  while cur is App(func, arg) {
    args_rev.push(arg)
    cur = func
  }
  let args : Array[Type] = []
  loop args_rev.length() - 1 {
    i if i >= 0 => {
      args.push(args_rev[i])
      continue i - 1
    }
    _ => ()
  }
  args
}

///|
fn get_unbound_metas_impl(
  state : TypeCheckerState,
  ty : Type,
  metas : Set[String],
) -> Unit {
  match ty {
    EVar(name) if !state.meta.solutions.contains(name) => metas.add(name)
    App(func, arg) => {
      get_unbound_metas_impl(state, func, metas)
      get_unbound_metas_impl(state, arg, metas)
    }
    Arrow(from, to) => {
      get_unbound_metas_impl(state, from, metas)
      get_unbound_metas_impl(state, to, metas)
    }
    Tuple(elements) =>
      for element in elements {
        get_unbound_metas_impl(state, element, metas)
      }
    Record(fields) =>
      for field in fields {
        get_unbound_metas_impl(state, field.1, metas)
      }
    Variant(cases) =>
      for case in cases {
        get_unbound_metas_impl(state, case.1, metas)
      }
    _ => ()
  }
}

///|
/// Description: Returns names of unsolved evars appearing in a type.
/// Example: `let _ = TypeCheckerState::fresh().get_unbound_metas(Type::con("Int"))`
pub fn TypeCheckerState::get_unbound_metas(
  self : TypeCheckerState,
  ty : Type,
) -> Array[String] {
  let result = Set::new()
  get_unbound_metas_impl(self, ty, result)
  result.to_array()
}

///|
/// Description: Solves a worklist of constraints and returns the resulting substitution.
/// Example: `let _ = TypeCheckerState::fresh().solve_constraints([], Map::new())`
pub fn TypeCheckerState::solve_constraints(
  self : TypeCheckerState,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Substitution, TypingError] {
  loop worklist {
    [first, .. next] => {
      let next = next.to_array()
      match self.process_constraint(first, next, subst) {
        Ok(_) => continue next
        Err(t) => return Err(t)
      }
    }
    [] => return Ok(subst)
  }
}

///|
/// Description: Processes one constraint and may push more work onto the worklist.
/// Example: `let state = TypeCheckerState::fresh(); let _ = state.process_constraint(Constraint::kind_eq(Star, Star), [], Map::new())`
pub fn TypeCheckerState::process_constraint(
  self : TypeCheckerState,
  constraint : Constraint,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  match constraint {
    TypeEq(constraint) =>
      self.unify_types(
        self.normalize_type(self.apply_substitution(subst, constraint.left)),
        self.normalize_type(self.apply_substitution(subst, constraint.right)),
        worklist,
        subst,
      )
    KindEq(constraint) => unify_kinds(constraint.left, constraint.right)
    HasKind(constraint) => {
      let ty = self.apply_substitution(subst, constraint.ty)
      let kind = match constraint.state.check_kind(ty, false) {
        Ok(kind) => kind
        Err(t) => return Err(t)
      }
      worklist.push(Constraint::kind_eq(kind, constraint.kind))
      Ok(())
    }
    HasType(constraint) => {
      let ty = match constraint.state.infer_type(constraint.term) {
        Ok(ty) => ty
        Err(t) => return Err(t)
      }
      worklist.push(Constraint::type_eq(ty, constraint.ty))
      Ok(())
    }
  }
}

///|
/// Description: Convenience alias that typechecks by inference.
/// Example: `let _ = TypeCheckerState::fresh().type_check(Term::unit())`
pub fn TypeCheckerState::type_check(
  self : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  self.infer_type(term)
}

///|
/// Description: Typechecks a term by creating and solving a temporary type constraint.
/// Example: `let _ = TypeCheckerState::fresh().typecheck_with_constraints(Term::unit())`
pub fn TypeCheckerState::typecheck_with_constraints(
  self : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  let meta_var = self.meta.fresh_meta_var(Star)
  let worklist = [Constraint::has_type(term, meta_var, self)]
  let subst = Map::new()
  match self.solve_constraints(worklist, subst) {
    Err(t) => return Err(t)
    Ok(subst) => {
      let result_ty = self.apply_substitution(subst, meta_var)
      match result_ty {
        EVar(_) => self.infer_type(term)
        _ => Ok(self.normalize_type(result_ty))
      }
    }
  }
}

///|
fn replace_enum_self_refs(
  ty : Type,
  enum_name : String,
  enum_args : Array[Type],
  mu_var : String,
) -> Type {
  let is_same_enum_instance = fn(t : Type) -> Bool {
    let head = t.get_spine_head()
    match head {
      Con(name) if name == enum_name => {
        let args = t.get_spine_args()
        if args.length() != enum_args.length() {
          return false
        }
        loop 0 {
          i if i < args.length() => {
            if args[i] != enum_args[i] {
              return false
            }
            continue i + 1
          }
          _ => return true
        }
      }
      _ => false
    }
  }

  if is_same_enum_instance(ty) {
    return Var(mu_var)
  }

  match ty {
    Arrow(from, to) =>
      Arrow(
        replace_enum_self_refs(from, enum_name, enum_args, mu_var),
        replace_enum_self_refs(to, enum_name, enum_args, mu_var),
      )
    Ref(region, mutability, inner) =>
      Ref(
        region,
        mutability,
        replace_enum_self_refs(inner, enum_name, enum_args, mu_var),
      )
    App(func, arg) =>
      App(
        replace_enum_self_refs(func, enum_name, enum_args, mu_var),
        replace_enum_self_refs(arg, enum_name, enum_args, mu_var),
      )
    Forall(name, kind, body) =>
      Forall(
        name,
        kind,
        replace_enum_self_refs(body, enum_name, enum_args, mu_var),
      )
    BoundedForall(name, kind, constraints, body) =>
      BoundedForall(
        name,
        kind,
        constraints.map(c => TraitConstraint::{
          trait_name: c.trait_name,
          ty: replace_enum_self_refs(c.ty, enum_name, enum_args, mu_var),
        }),
        replace_enum_self_refs(body, enum_name, enum_args, mu_var),
      )
    Lam(name, kind, body) =>
      Lam(
        name,
        kind,
        replace_enum_self_refs(body, enum_name, enum_args, mu_var),
      )
    Record(fields) =>
      Record(
        fields.map(t => {
          (t.0, replace_enum_self_refs(t.1, enum_name, enum_args, mu_var))
        }),
      )
    Variant(cases) =>
      Variant(
        cases.map(t => {
          (t.0, replace_enum_self_refs(t.1, enum_name, enum_args, mu_var))
        }),
      )
    Mu(name, body) =>
      Mu(name, replace_enum_self_refs(body, enum_name, enum_args, mu_var))
    Tuple(types) =>
      Tuple(
        types.map(t => replace_enum_self_refs(t, enum_name, enum_args, mu_var)),
      )
    _ => ty
  }
}

///|
fn normalize_type_impl(
  state : TypeCheckerState,
  ty : Type,
  seen : Set[String],
) -> Type {
  let var_key = match ty {
    Var(name) => Some("var:" + name)
    _ => None
  }
  match var_key {
    Some(key) if seen.contains(key) => return ty
    _ => ()
  }
  let seen = match var_key {
    Some(key) => seen..add(key)
    None => seen
  }

  match ty {
    Var(_) | Never => ty
    EVar(name) => {
      let key = "evar:" + name
      if seen.contains(key) {
        return Never
      }
      match state.meta.solutions.get(name) {
        Some(sol) => normalize_type_impl(state, sol, seen..add(key))
        None => ty
      }
    }
    Con(name) =>
      match state.ctx.find_type_alias(name) {
        Some(alias_name) => {
          if alias_name.params.length() == 0 {
            let key = "alias:" + name
            if seen.contains(key) {
              return ty
            }
            return normalize_type_impl(state, alias_name.body, seen..add(key))
          }
          ty
        }
        None =>
          match state.ctx.find_enum(name) {
            Some(def) if def.params.length() == 0 => {
              let key = "enum:" + name
              if seen.contains(key) {
                return ty
              }
              let seen2 = seen..add(key)
              let mut mu_name : String? = None
              if def.recursive {
                let id = state.meta.counter
                state.meta.counter += 1
                mu_name = Some("X" + id.to_string())
              }

              let cases : Array[(String, Type)] = []
              for variant_entry in def.variants {
                let (label, scheme) = variant_entry
                let field = match mu_name {
                  Some(mu_var) =>
                    replace_enum_self_refs(scheme, def.name, [], mu_var)
                  None => scheme
                }
                cases.push((label, normalize_type_impl(state, field, seen2)))
              }

              let variant_ty = Variant(cases)
              match mu_name {
                Some(mu_var) =>
                  Mu(mu_var, normalize_type_impl(state, variant_ty, seen2))
                None => variant_ty
              }
            }
            _ => ty
          }
      }
    App(func, arg) => {
      let head = ty.get_spine_head()
      match head {
        Con(con_name) =>
          match state.ctx.find_type_alias(con_name) {
            Some(alias_name) => {
              let args = ty.get_spine_args()
              if args.length() == alias_name.params.length() {
                let key = "alias:" + con_name
                if seen.contains(key) {
                  return ty
                }
                let mut expanded = alias_name.body
                loop 0 {
                  i if i < alias_name.params.length() => {
                    expanded = expanded.substitute_type(
                      alias_name.params[i],
                      args[i],
                    )
                    continue i + 1
                  }
                  _ => ()
                }
                return normalize_type_impl(state, expanded, seen..add(key))
              }
            }
            _ => ()
          }
        _ => ()
      }

      match head {
        Con(con_name) =>
          match state.ctx.find_enum(con_name) {
            Some(def) => {
              let args = ty.get_spine_args()
              if args.length() == def.params.length() {
                let key = "enum:" + con_name
                if seen.contains(key) {
                  return ty
                }
                let seen2 = seen..add(key)

                let mut mu_name : String? = None
                if def.recursive {
                  let id = state.meta.counter
                  state.meta.counter += 1
                  mu_name = Some("X" + id.to_string())
                }

                let cases : Array[(String, Type)] = []
                for variant_entry in def.variants {
                  let (label, scheme) = variant_entry
                  let mut field = scheme
                  loop 0 {
                    i if i < def.params.length() => {
                      field = field.substitute_type(def.params[i], args[i])
                      continue i + 1
                    }
                    _ => ()
                  }
                  field = match mu_name {
                    Some(mu_var) =>
                      replace_enum_self_refs(field, def.name, args, mu_var)
                    None => field
                  }
                  cases.push((label, normalize_type_impl(state, field, seen2)))
                }

                let variant_ty = Variant(cases)
                return match mu_name {
                  Some(mu_var) =>
                    Mu(mu_var, normalize_type_impl(state, variant_ty, seen2))
                  None => variant_ty
                }
              }
            }
            _ => ()
          }
        _ => ()
      }

      let norm_func = normalize_type_impl(state, func, seen)
      match norm_func {
        Lam(name, _kind, body) => {
          let substituted = body.substitute_type(name, arg)
          normalize_type_impl(state, substituted, seen)
        }
        _ => {
          let norm_arg = normalize_type_impl(state, arg, seen)
          App(norm_func, norm_arg)
        }
      }
    }
    Arrow(from, to) =>
      Arrow(
        normalize_type_impl(state, from, seen),
        normalize_type_impl(state, to, seen),
      )
    Ref(region, mutability, inner) =>
      Ref(region, mutability, normalize_type_impl(state, inner, seen))
    Forall(name, kind, body) =>
      Forall(name, kind, normalize_type_impl(state, body, seen))
    BoundedForall(name, kind, constraints, body) =>
      BoundedForall(
        name,
        kind,
        constraints.map(c => TraitConstraint::{
          trait_name: c.trait_name,
          ty: normalize_type_impl(state, c.ty, seen),
        }),
        normalize_type_impl(state, body, seen),
      )
    Lam(name, kind, body) =>
      Lam(name, kind, normalize_type_impl(state, body, seen))
    Record(fields) =>
      Record(fields.map(t => (t.0, normalize_type_impl(state, t.1, seen))))
    Variant(cases) =>
      Variant(cases.map(t => (t.0, normalize_type_impl(state, t.1, seen))))
    Mu(name, body) => {
      let key = "mu:" + name
      if seen.contains(key) {
        ty
      } else {
        Mu(name, normalize_type_impl(state, body, seen..add(key)))
      }
    }
    Tuple(types) => Tuple(types.map(t => normalize_type_impl(state, t, seen)))
  }
}

///|
/// Description: Normalizes aliases, enums, beta-redexes, and solved evars in a type.
/// Example: `let _ = TypeCheckerState::fresh().normalize_type(Type::con("Int"))`
pub fn TypeCheckerState::normalize_type(
  self : TypeCheckerState,
  ty : Type,
) -> Type {
  normalize_type_impl(self, ty, Set::new())
}

///|
/// Description: Instantiates a bounded forall and resolves required dictionaries.
/// Example: `let _ = TypeCheckerState::fresh().instantiate_with_traits(Type::con("Int"))`
pub fn TypeCheckerState::instantiate_with_traits(
  self : TypeCheckerState,
  ty : Type,
) -> Result[InstantiatedWithTraits, TypingError] {
  match ty {
    BoundedForall(name, _kind, constraints, body) => {
      let fv = self.meta.fresh_meta_var(Star)

      let instantiated = constraints.map(t => TraitConstraint::{
        trait_name: t.trait_name,
        ty: t.ty.substitute_type(name, fv),
      })

      let dicts = match self.check_trait_constraints(instantiated) {
        Ok(dicts) => dicts
        Err(err) => return Err(err)
      }

      let body = body.substitute_type(name, fv)
      Ok({ ty: body, dicts })
    }
    _ => Ok({ ty, dicts: [] })
  }
}

///|
/// Description: Automatically inserts type and dictionary applications for polymorphic terms.
/// Example: `let _ = TypeCheckerState::fresh().auto_instantiate(Term::unit())`
pub fn TypeCheckerState::auto_instantiate(
  self : TypeCheckerState,
  term : Term,
) -> Result[AutoInstantiated, TypingError] {
  let inferred_ty = match self.infer_type(term) {
    Ok(ty) => ty
    Err(err) => return Err(err)
  }

  let mut acc_term = term
  let mut acc_ty = inferred_ty

  // Auto-apply type arguments for plain foralls.
  loop () {
    _ =>
      match acc_ty {
        Forall(name, kind, body) => {
          let fv = self.meta.fresh_meta_var(kind)
          acc_term = Term::tyapp(acc_term, fv)
          acc_ty = body.substitute_type(name, fv)
          continue ()
        }
        _ => break
      }
  }

  // Auto-apply dictionaries for trait-bounded foralls.
  loop () {
    _ =>
      match acc_ty {
        BoundedForall(_, kind, _, _) => {
          let inst = match self.instantiate_with_traits(acc_ty) {
            Ok(res) => res
            Err(err) => return Err(err)
          }
          acc_term = Term::trait_app(
            acc_term,
            self.meta.fresh_meta_var(kind),
            inst.dicts,
          )
          acc_ty = inst.ty
          continue ()
        }
        _ => break
      }
  }

  Ok({ term: acc_term, ty: acc_ty })
}

///|
/// Description: Recursively resolves solved evars in a type.
/// Example: `let _ = TypeCheckerState::fresh().resolve_meta_vars(Type::con("Int"))`
pub fn TypeCheckerState::resolve_meta_vars(
  self : TypeCheckerState,
  ty : Type,
) -> Type {
  match ty {
    EVar(name) =>
      match self.meta.solutions.get(name) {
        Some(ty) => self.resolve_meta_vars(ty)
        None => ty
      }
    Arrow(from, to) =>
      Arrow(self.resolve_meta_vars(from), self.resolve_meta_vars(to))
    _ => ty
  }
}

///|
/// Description: Counts how many argument slots a kind arrow chain has.
/// Example: `let _ = Kind::arrow(Star, Star).arity()`
pub fn Kind::arity(self : Kind) -> Int {
  loop (self, 0) {
    (Star, n) => break n
    (Arrow(_, to), n) => continue (to, n + 1)
  }
}

///|
/// Description: Returns true if a type contains any unsolved evars.
/// Example: `let _ = TypeCheckerState::fresh().has_unbound_metas(Type::con("Int"))`
pub fn TypeCheckerState::has_unbound_metas(
  self : TypeCheckerState,
  ty : Type,
) -> Bool {
  match ty {
    EVar(name) if !self.meta.solutions.contains(name) => true
    App(func, arg) =>
      self.has_unbound_metas(func) || self.has_unbound_metas(arg)
    Arrow(from, to) =>
      self.has_unbound_metas(from) || self.has_unbound_metas(to)
    Tuple(values) => values.any(t => self.has_unbound_metas(t))
    Record(pairs) => pairs.any(t => self.has_unbound_metas(t.1))
    Variant(pairs) => pairs.any(t => self.has_unbound_metas(t.1))
    _ => false
  }
}

///|
fn collect_type_vars_impl(ty : Type, vars : Set[String]) -> Unit {
  match ty {
    Var(name) => vars.add(name)
    App(func, arg) => {
      collect_type_vars_impl(func, vars)
      collect_type_vars_impl(arg, vars)
    }
    Arrow(from, to) => {
      collect_type_vars_impl(from, vars)
      collect_type_vars_impl(to, vars)
    }
    Forall(name, _, body) => {
      let inner = Set::new()
      collect_type_vars_impl(body, inner)
      inner.remove(name)
      for v in inner {
        vars.add(v)
      }
    }
    Record(pairs) =>
      for p in pairs {
        collect_type_vars_impl(p.1, vars)
      }
    Tuple(values) =>
      for v in values {
        collect_type_vars_impl(v, vars)
      }
    Lam(name, _, body) => {
      let inner = Set::new()
      collect_type_vars_impl(body, inner)
      inner.remove(name)
      for v in inner {
        vars.add(v)
      }
    }
    _ => ()
  }
}

///|
/// Description: Collects free type variable names appearing in this type.
/// Example: `let _ = Type::arrow(Type::var_type("A"), Type::con("Int")).collect_type_vars()`
pub fn Type::collect_type_vars(self : Type) -> Array[String] {
  let vars = Set::new()
  collect_type_vars_impl(self, vars)
  vars.to_array()
}

///|
/// Description: Wraps a variant type in type lambdas derived from a kind arity.
/// Example: `let _ = Type::variant([("None", Type::unit())]).create_variant_lambda(Kind::arrow(Star, Star))`
pub fn Type::create_variant_lambda(self : Type, self_kind : Kind) -> Type {
  match self {
    Variant(_) => {
      let kinds = loop ([], self_kind) {
        (kinds, Star) => break kinds
        (kinds, Arrow(from, to)) => {
          kinds.push(from)
          continue (kinds, to)
        }
      }

      let arg_names = []
      for n in kinds.iter2() {
        let (i, _) = n
        arg_names.push("t\{i}")
      }

      loop (self, kinds.length() - 1) {
        (ty, -1) => break ty
        (ty, i) => continue (Type::lam(arg_names[i], kinds[i], ty), i - 1)
      }
    }
    _ => self
  }
}

///|
/// Description: Renames free symbols in a type while respecting bound names.
/// Example: `let _ = TypeCheckerState::fresh().rename_type(Type::con("Int"), Map::new())`
pub fn TypeCheckerState::rename_type(
  self : TypeCheckerState,
  ty : Type,
  ren : Map[String, String],
) -> Type {
  ignore(self)

  fn rename_type_impl(
    ty : Type,
    ren : Map[String, String],
    bound : Set[String],
  ) -> Type {
    match ty {
      Var(name) =>
        if bound.contains(name) {
          Type::var_type(name)
        } else {
          Type::var_type(
            match ren.get(name) {
              Some(renamed) => renamed
              None => name
            },
          )
        }
      Con(name) =>
        Type::con(
          match ren.get(name) {
            Some(renamed) => renamed
            None => name
          },
        )
      EVar(_) | Never => ty
      Arrow(from, to) =>
        Type::arrow(
          rename_type_impl(from, ren, bound),
          rename_type_impl(to, ren, bound),
        )
      Ref(region, mutability, inner) =>
        Type::ref_type(region, mutability, rename_type_impl(inner, ren, bound))
      App(func, arg) =>
        Type::app(
          rename_type_impl(func, ren, bound),
          rename_type_impl(arg, ren, bound),
        )
      Forall(name, kind, body) =>
        Type::forall(name, kind, rename_type_impl(body, ren, bound..add(name)))
      BoundedForall(name, kind, constraints, body) => {
        let bound = bound..add(name)
        Type::bounded_forall(
          name,
          kind,
          constraints.map(c => TraitConstraint::{
            trait_name: match ren.get(c.trait_name) {
              Some(renamed) => renamed
              None => c.trait_name
            },
            ty: rename_type_impl(c.ty, ren, bound),
          }),
          rename_type_impl(body, ren, bound),
        )
      }
      Lam(name, kind, body) =>
        Type::lam(name, kind, rename_type_impl(body, ren, bound..add(name)))
      Record(fields) =>
        Type::record(
          fields.map(field => {
            let (label, field_ty) = field
            (
              match ren.get(label) {
                Some(renamed) => renamed
                None => label
              },
              rename_type_impl(field_ty, ren, bound),
            )
          }),
        )
      Variant(cases) =>
        Type::variant(
          cases.map(case_ty => {
            let (label, field_ty) = case_ty
            (
              match ren.get(label) {
                Some(renamed) => renamed
                None => label
              },
              rename_type_impl(field_ty, ren, bound),
            )
          }),
        )
      Tuple(types) =>
        Type::tuple(types.map(t => rename_type_impl(t, ren, bound)))
      Mu(name, body) =>
        Type::mu(name, rename_type_impl(body, ren, bound..add(name)))
    }
  }

  rename_type_impl(ty, ren, Set::new())
}

///|
/// Description: Renames free symbols in a term while respecting bound names.
/// Example: `let _ = TypeCheckerState::fresh().rename_term(Term::unit(), Map::new())`
pub fn TypeCheckerState::rename_term(
  self : TypeCheckerState,
  term : Term,
  ren : Map[String, String],
) -> Term {
  fn rename_type_with_bound(
    ty : Type,
    ren : Map[String, String],
    bound : Set[String],
  ) -> Type {
    match ty {
      Var(name) =>
        if bound.contains(name) {
          Type::var_type(name)
        } else {
          Type::var_type(
            match ren.get(name) {
              Some(renamed) => renamed
              None => name
            },
          )
        }
      Con(name) =>
        Type::con(
          match ren.get(name) {
            Some(renamed) => renamed
            None => name
          },
        )
      EVar(_) | Never => ty
      Arrow(from, to) =>
        Type::arrow(
          rename_type_with_bound(from, ren, bound),
          rename_type_with_bound(to, ren, bound),
        )
      Ref(region, mutability, inner) =>
        Type::ref_type(
          region,
          mutability,
          rename_type_with_bound(inner, ren, bound),
        )
      App(func, arg) =>
        Type::app(
          rename_type_with_bound(func, ren, bound),
          rename_type_with_bound(arg, ren, bound),
        )
      Forall(name, kind, body) =>
        Type::forall(
          name,
          kind,
          rename_type_with_bound(body, ren, bound..add(name)),
        )
      BoundedForall(name, kind, constraints, body) => {
        let bound = bound..add(name)
        Type::bounded_forall(
          name,
          kind,
          constraints.map(c => TraitConstraint::{
            trait_name: match ren.get(c.trait_name) {
              Some(renamed) => renamed
              None => c.trait_name
            },
            ty: rename_type_with_bound(c.ty, ren, bound),
          }),
          rename_type_with_bound(body, ren, bound),
        )
      }
      Lam(name, kind, body) =>
        Type::lam(
          name,
          kind,
          rename_type_with_bound(body, ren, bound..add(name)),
        )
      Record(fields) =>
        Type::record(
          fields.map(field => {
            let (label, field_ty) = field
            (
              match ren.get(label) {
                Some(renamed) => renamed
                None => label
              },
              rename_type_with_bound(field_ty, ren, bound),
            )
          }),
        )
      Variant(cases) =>
        Type::variant(
          cases.map(case_ty => {
            let (label, field_ty) = case_ty
            (
              match ren.get(label) {
                Some(renamed) => renamed
                None => label
              },
              rename_type_with_bound(field_ty, ren, bound),
            )
          }),
        )
      Tuple(types) =>
        Type::tuple(types.map(t => rename_type_with_bound(t, ren, bound)))
      Mu(name, body) =>
        Type::mu(name, rename_type_with_bound(body, ren, bound..add(name)))
    }
  }

  fn rename_term_impl(
    state : TypeCheckerState,
    term : Term,
    ren : Map[String, String],
    bound : Set[String],
  ) -> Term {
    match term {
      Var(name) =>
        if bound.contains(name) {
          Var(name)
        } else {
          Var(
            match ren.get(name) {
              Some(renamed) => renamed
              None => name
            },
          )
        }
      Lam(arg, ty, body) => {
        let bound = bound..add(arg)
        Term::lam(
          arg,
          state.rename_type(ty, ren),
          rename_term_impl(state, body, ren, bound),
        )
      }
      App(callee, arg) =>
        Term::app(
          rename_term_impl(state, callee, ren, bound),
          rename_term_impl(state, arg, ren, bound),
        )
      BorrowShared(target) =>
        Term::borrow_shared(rename_term_impl(state, target, ren, bound))
      BorrowMut(target) =>
        Term::borrow_mut(rename_term_impl(state, target, ren, bound))
      Deref(inner) => Term::deref(rename_term_impl(state, inner, ren, bound))
      Assign(target, value) =>
        Term::assign(
          rename_term_impl(state, target, ren, bound),
          rename_term_impl(state, value, ren, bound),
        )
      Move(inner) => Term::move_term(rename_term_impl(state, inner, ren, bound))
      TyLam(name, kind, body) => {
        let bound = bound..add(name)
        Term::tylam(name, kind, rename_term_impl(state, body, ren, bound))
      }
      TyApp(term, ty) =>
        Term::tyapp(
          rename_term_impl(state, term, ren, bound),
          state.rename_type(ty, ren),
        )
      Con(name, ty) =>
        Term::con(
          match ren.get(name) {
            Some(renamed) => renamed
            None => name
          },
          state.rename_type(ty, ren),
        )
      Record(fields) =>
        Term::record(
          fields.map(field => {
            let (label, value) = field
            (
              match ren.get(label) {
                Some(renamed) => renamed
                None => label
              },
              rename_term_impl(state, value, ren, bound),
            )
          }),
        )
      Project(record, label) =>
        Term::project(
          rename_term_impl(state, record, ren, bound),
          match ren.get(label) {
            Some(renamed) => renamed
            None => label
          },
        )
      Inject(label, value, variant_ty) =>
        Term::inject(
          match ren.get(label) {
            Some(renamed) => renamed
            None => label
          },
          rename_term_impl(state, value, ren, bound),
          state.rename_type(variant_ty, ren),
        )
      Tuple(elements) =>
        Term::tuple(elements.map(t => rename_term_impl(state, t, ren, bound)))
      TupleProject(tuple, index) =>
        Term::tuple_project(rename_term_impl(state, tuple, ren, bound), index)
      Let(name, value, body) =>
        Term::let_term(
          name,
          rename_term_impl(state, value, ren, bound),
          rename_term_impl(state, body, ren, bound..add(name)),
        )
      Match(scrutinee, cases) =>
        Term::match_term(
          rename_term_impl(state, scrutinee, ren, bound),
          cases.map(t => {
            let (pattern, body) = t
            (
              state.rename_pattern(pattern, ren, bound),
              rename_term_impl(state, body, ren, bound),
            )
          }),
        )
      Fold(ty, term) =>
        Term::fold(
          state.rename_type(ty, ren),
          rename_term_impl(state, term, ren, bound),
        )
      Unfold(term) => Term::unfold(rename_term_impl(state, term, ren, bound))
      Dict(trait_name, ty, methods) =>
        Term::dict(
          match ren.get(trait_name) {
            Some(renamed) => renamed
            None => trait_name
          },
          state.rename_type(ty, ren),
          methods.map(t => {
            let (name, method_impl) = t
            (
              match ren.get(name) {
                Some(renamed) => renamed
                None => name
              },
              rename_term_impl(state, method_impl, ren, bound),
            )
          }),
        )
      TraitLam(trait_var, trait_name, trait_type_var, kind, constraints, body) => {
        let bound_with_type = bound..add(trait_type_var)
        let bound2 = bound_with_type..add(trait_var)
        Term::trait_lam(
          match ren.get(trait_var) {
            Some(renamed) => renamed
            None => trait_var
          },
          match ren.get(trait_name) {
            Some(renamed) => renamed
            None => trait_name
          },
          match ren.get(trait_type_var) {
            Some(renamed) => renamed
            None => trait_type_var
          },
          kind,
          constraints.map(c => TraitConstraint::{
            trait_name: match ren.get(c.trait_name) {
              Some(renamed) => renamed
              None => c.trait_name
            },
            ty: rename_type_with_bound(c.ty, ren, bound2),
          }),
          rename_term_impl(state, body, ren, bound2),
        )
      }
      TraitApp(term, ty, dicts) =>
        Term::trait_app(
          rename_term_impl(state, term, ren, bound),
          state.rename_type(ty, ren),
          dicts.map(d => rename_term_impl(state, d, ren, bound)),
        )
      TraitMethod(dict, trait_method) =>
        Term::trait_method(
          rename_term_impl(state, dict, ren, bound),
          match ren.get(trait_method) {
            Some(renamed) => renamed
            None => trait_method
          },
        )
    }
  }

  rename_term_impl(self, term, ren, Set::new())
}

///|
/// Description: Renames symbols in a pattern while respecting bound names.
/// Example: `let _ = TypeCheckerState::fresh().rename_pattern(Pattern::wildcard(), Map::new(), Set::new())`
pub fn TypeCheckerState::rename_pattern(
  self : TypeCheckerState,
  pattern : Pattern,
  ren : Map[String, String],
  bound : Set[String],
) -> Pattern {
  match pattern {
    VarPattern(v) => {
      let new_name = match ren.get(v) {
        Some(renamed) => renamed
        None => v
      }
      bound.add(v)
      Pattern::var_pattern(new_name)
    }
    ConPattern(name, ty) =>
      Pattern::con(
        match ren.get(name) {
          Some(renamed) => renamed
          None => name
        },
        self.rename_type(ty, ren),
      )
    RecordPattern(pairs) =>
      Pattern::record(
        pairs.map(p => {
          let (label, pattern) = p
          (
            match ren.get(label) {
              Some(renamed) => renamed
              None => label
            },
            self.rename_pattern(pattern, ren, bound),
          )
        }),
      )
    VariantPattern(name, inner) =>
      Pattern::variant(
        match ren.get(name) {
          Some(renamed) => renamed
          None => name
        },
        self.rename_pattern(inner, ren, bound),
      )
    TuplePattern(patterns) =>
      Pattern::tuple(patterns.map(p => self.rename_pattern(p, ren, bound)))
    _ => pattern
  }
}

///|
/// Description: Renames free symbols inside a binding payload.
/// Example: `let _ = TypeCheckerState::fresh().rename_binding(Binding::type_binding("T", Star), Map::new())`
pub fn TypeCheckerState::rename_binding(
  self : TypeCheckerState,
  binding : Binding,
  ren : Map[String, String],
) -> Binding {
  match binding {
    Term(t) =>
      Binding::term(
        match ren.get(t.name) {
          Some(renamed) => renamed
          None => t.name
        },
        self.rename_type(t.ty, ren),
      )
    Type(t) =>
      Binding::type_binding(
        match ren.get(t.name) {
          Some(renamed) => renamed
          None => t.name
        },
        t.kind,
      )
    TraitDef(t) =>
      Binding::trait_def(
        match ren.get(t.name) {
          Some(renamed) => renamed
          None => t.name
        },
        t.type_param,
        t.kind,
        t.methods.map(method_entry => {
          let (method_name, method_ty) = method_entry
          (
            match ren.get(method_name) {
              Some(renamed) => renamed
              None => method_name
            },
            self.rename_type(method_ty, ren),
          )
        }),
      )
    TraitImpl(t) =>
      Binding::trait_impl(
        match ren.get(t.trait_name) {
          Some(renamed) => renamed
          None => t.trait_name
        },
        self.rename_type(t.ty, ren),
        self.rename_term(t.dict, ren),
      )
    Dict(t) =>
      Binding::dict(
        match ren.get(t.name) {
          Some(renamed) => renamed
          None => t.name
        },
        match ren.get(t.trait_name) {
          Some(renamed) => renamed
          None => t.trait_name
        },
        self.rename_type(t.ty, ren),
      )
    Enum(t) =>
      Binding::enum_def(
        match ren.get(t.name) {
          Some(renamed) => renamed
          None => t.name
        },
        t.kind,
        t.params,
        t.variants.map(variant => {
          let (label, field_scheme) = variant
          (
            match ren.get(label) {
              Some(renamed) => renamed
              None => label
            },
            self.rename_type(field_scheme, ren),
          )
        }),
        t.recursive,
      )
    TypeAlias(t) =>
      Binding::type_alias(
        match ren.get(t.name) {
          Some(renamed) => renamed
          None => t.name
        },
        t.params,
        t.kinds,
        self.rename_type(t.body, ren),
      )
  }
}

///|
/// Description: Computes free-name sets referenced by a type.
/// Example: `let _ = TypeCheckerState::fresh().compute_free_types(Type::con("Int"))`
pub fn TypeCheckerState::compute_free_types(
  self : TypeCheckerState,
  ty : Type,
) -> FreeTypeNames {
  ignore(self)

  let type_vars = Set::new()
  let type_cons = Set::new()
  let traits = Set::new()
  let labels = Set::new()

  fn go(
    ty : Type,
    bound : Set[String],
    type_vars : Set[String],
    type_cons : Set[String],
    traits : Set[String],
    labels : Set[String],
  ) -> Unit {
    match ty {
      Var(name) => if !bound.contains(name) { type_vars.add(name) }
      Con(name) => type_cons.add(name)
      EVar(_) | Never => ()
      Arrow(from, to) => {
        go(from, bound, type_vars, type_cons, traits, labels)
        go(to, bound, type_vars, type_cons, traits, labels)
      }
      Ref(_, _, inner) => go(inner, bound, type_vars, type_cons, traits, labels)
      App(func, arg) => {
        go(func, bound, type_vars, type_cons, traits, labels)
        go(arg, bound, type_vars, type_cons, traits, labels)
      }
      Forall(name, _kind, body) =>
        go(body, bound..add(name), type_vars, type_cons, traits, labels)
      BoundedForall(name, _kind, constraints, body) => {
        let bound = bound..add(name)
        for c in constraints {
          traits.add(c.trait_name)
          go(c.ty, bound, type_vars, type_cons, traits, labels)
        }
        go(body, bound, type_vars, type_cons, traits, labels)
      }
      Lam(name, _kind, body) =>
        go(body, bound..add(name), type_vars, type_cons, traits, labels)
      Record(fields) =>
        for field in fields {
          let (label, field_ty) = field
          labels.add(label)
          go(field_ty, bound, type_vars, type_cons, traits, labels)
        }
      Variant(cases) =>
        for case_ty in cases {
          let (label, inner_ty) = case_ty
          labels.add(label)
          go(inner_ty, bound, type_vars, type_cons, traits, labels)
        }
      Tuple(types) =>
        for element_ty in types {
          go(element_ty, bound, type_vars, type_cons, traits, labels)
        }
      Mu(name, body) =>
        go(body, bound..add(name), type_vars, type_cons, traits, labels)
    }
  }

  go(ty, Set::new(), type_vars, type_cons, traits, labels)
  FreeTypeNames::{ type_vars, type_cons, traits, labels }
}

///|
/// Description: Computes free-name sets referenced by a pattern.
/// Example: `let _ = TypeCheckerState::fresh().compute_free_patterns(Pattern::wildcard())`
pub fn TypeCheckerState::compute_free_patterns(
  self : TypeCheckerState,
  pattern : Pattern,
) -> FreePatternNames {
  ignore(self)

  let vars = Set::new()
  let constructors = Set::new()
  let labels = Set::new()

  fn go(
    pattern : Pattern,
    vars : Set[String],
    constructors : Set[String],
    labels : Set[String],
  ) -> Unit {
    match pattern {
      VarPattern(name) => vars.add(name)
      WildcardPattern => ()
      ConPattern(name, _ty) => constructors.add(name)
      RecordPattern(pairs) =>
        for p in pairs {
          let (label, sub_pattern) = p
          labels.add(label)
          go(sub_pattern, vars, constructors, labels)
        }
      VariantPattern(label, inner) => {
        labels.add(label)
        go(inner, vars, constructors, labels)
      }
      TuplePattern(patterns) =>
        for p in patterns {
          go(p, vars, constructors, labels)
        }
    }
  }

  go(pattern, vars, constructors, labels)
  FreePatternNames::{ vars, constructors, labels }
}

///|
/// Description: Computes free-name sets referenced by a term.
/// Example: `let _ = TypeCheckerState::fresh().compute_free_terms(Term::unit())`
pub fn TypeCheckerState::compute_free_terms(
  self : TypeCheckerState,
  term : Term,
) -> FreeTermNames {
  let terms = Set::new()
  let constructors = Set::new()
  let traits = Set::new()
  let dicts = Set::new()
  let labels = Set::new()
  let type_vars = Set::new()
  let type_cons = Set::new()

  fn merge_type_names(
    state : TypeCheckerState,
    ty : Type,
    type_vars : Set[String],
    type_cons : Set[String],
    traits : Set[String],
    labels : Set[String],
  ) -> Unit {
    let r = state.compute_free_types(ty)
    for x in r.type_vars {
      type_vars.add(x)
    }
    for x in r.type_cons {
      type_cons.add(x)
    }
    for x in r.traits {
      traits.add(x)
    }
    for x in r.labels {
      labels.add(x)
    }
  }

  fn go(
    state : TypeCheckerState,
    term : Term,
    bound : Set[String],
    terms : Set[String],
    constructors : Set[String],
    traits : Set[String],
    dicts : Set[String],
    labels : Set[String],
    type_vars : Set[String],
    type_cons : Set[String],
  ) -> Unit {
    ignore(dicts)
    match term {
      Var(name) => if !bound.contains(name) { terms.add(name) }
      Con(name, ty) => {
        constructors.add(name)
        merge_type_names(state, ty, type_vars, type_cons, traits, labels)
      }
      Lam(arg, ty, body) => {
        merge_type_names(state, ty, type_vars, type_cons, traits, labels)
        go(
          state,
          body,
          bound..add(arg),
          terms,
          constructors,
          traits,
          dicts,
          labels,
          type_vars,
          type_cons,
        )
      }
      App(callee, arg) => {
        go(
          state, callee, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
        go(
          state, arg, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      }
      BorrowShared(target) =>
        go(
          state, target, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      BorrowMut(target) =>
        go(
          state, target, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      Deref(inner) =>
        go(
          state, inner, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      Assign(target, value) => {
        go(
          state, target, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
        go(
          state, value, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      }
      Move(inner) =>
        go(
          state, inner, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      TyLam(name, _kind, body) =>
        go(
          state,
          body,
          bound..add(name),
          terms,
          constructors,
          traits,
          dicts,
          labels,
          type_vars,
          type_cons,
        )
      TyApp(term, ty) => {
        merge_type_names(state, ty, type_vars, type_cons, traits, labels)
        go(
          state, term, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      }
      Let(name, value, body) => {
        go(
          state, value, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
        go(
          state,
          body,
          bound..add(name),
          terms,
          constructors,
          traits,
          dicts,
          labels,
          type_vars,
          type_cons,
        )
      }
      Record(fields) =>
        for field in fields {
          let (label, value) = field
          labels.add(label)
          go(
            state, value, bound, terms, constructors, traits, dicts, labels, type_vars,
            type_cons,
          )
        }
      Project(record, label) => {
        labels.add(label)
        go(
          state, record, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      }
      Inject(label, value, variant_ty) => {
        labels.add(label)
        merge_type_names(
          state, variant_ty, type_vars, type_cons, traits, labels,
        )
        go(
          state, value, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      }
      Match(scrutinee, cases) => {
        go(
          state, scrutinee, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
        for c in cases {
          let (pattern, body) = c
          let p_free = state.compute_free_patterns(pattern)
          for name in p_free.constructors {
            constructors.add(name)
          }
          for label in p_free.labels {
            labels.add(label)
          }

          let bound2 = bound.copy()
          for name in p_free.vars {
            bound2.add(name)
          }
          go(
            state, body, bound2, terms, constructors, traits, dicts, labels, type_vars,
            type_cons,
          )
        }
      }
      TraitMethod(dict, trait_method) => {
        go(
          state, dict, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
        labels.add(trait_method)
      }
      Dict(trait_name, ty, methods) => {
        traits.add(trait_name)
        merge_type_names(state, ty, type_vars, type_cons, traits, labels)
        for m in methods {
          let (name, method_impl) = m
          labels.add(name)
          go(
            state, method_impl, bound, terms, constructors, traits, dicts, labels,
            type_vars, type_cons,
          )
        }
      }
      TraitLam(trait_var, trait_name, type_var, _kind, constraints, body) => {
        traits.add(trait_name)

        let bound2 = bound.copy()
        bound2.add(type_var)
        bound2.add(trait_var)

        for c in constraints {
          traits.add(c.trait_name)
          merge_type_names(state, c.ty, type_vars, type_cons, traits, labels)
        }

        go(
          state, body, bound2, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      }
      TraitApp(term, ty, dict_terms) => {
        merge_type_names(state, ty, type_vars, type_cons, traits, labels)
        go(
          state, term, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
        for d in dict_terms {
          go(
            state, d, bound, terms, constructors, traits, dicts, labels, type_vars,
            type_cons,
          )
        }
      }
      Tuple(elements) =>
        for e in elements {
          go(
            state, e, bound, terms, constructors, traits, dicts, labels, type_vars,
            type_cons,
          )
        }
      TupleProject(tuple, _index) =>
        go(
          state, tuple, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      Fold(ty, term) => {
        merge_type_names(state, ty, type_vars, type_cons, traits, labels)
        go(
          state, term, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
      }
      Unfold(term) =>
        go(
          state, term, bound, terms, constructors, traits, dicts, labels, type_vars,
          type_cons,
        )
    }
  }

  go(
    self,
    term,
    Set::new(),
    terms,
    constructors,
    traits,
    dicts,
    labels,
    type_vars,
    type_cons,
  )

  FreeTermNames::{
    terms,
    constructors,
    traits,
    dicts,
    labels,
    type_vars,
    type_cons,
  }
}

///|
/// Description: Imports selected roots and their dependencies from one checker state into another.
/// Example: `let _ = import_module(from=TypeCheckerState::fresh(), into=TypeCheckerState::fresh(), roots=[], aliases=None)`
pub fn import_module(
  from~ : TypeCheckerState,
  into~ : TypeCheckerState,
  roots? : Array[String] = [],
  aliases? : ImportAliases? = None,
  allow_overrides? : Bool = false,
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  fn find_binding(bindings : Array[Binding], name : String) -> Binding? {
    for b in bindings {
      if binding_name(b) == name {
        return Some(b)
      }
    }
    None
  }

  fn has_binding_name(bindings : Array[Binding], name : String) -> Bool {
    for b in bindings {
      if binding_name(b) == name {
        return true
      }
    }
    false
  }

  fn fresh_name(bindings : Array[Binding], base : String) -> String {
    if !has_binding_name(bindings, base) {
      return base
    }
    loop 1 {
      i => {
        let candidate = base + "_" + i.to_string()
        if !has_binding_name(bindings, candidate) {
          return candidate
        }
        continue i + 1
      }
    }
  }

  fn binding_dependencies(
    state : TypeCheckerState,
    binding : Binding,
  ) -> Set[String] {
    let deps = Set::new()

    fn add_type_names(names : FreeTypeNames, deps : Set[String]) -> Unit {
      for n in names.type_vars {
        deps.add(n)
      }
      for n in names.type_cons {
        deps.add(n)
      }
      for n in names.traits {
        deps.add(n)
      }
      for n in names.labels {
        deps.add(n)
      }
    }

    fn add_term_names(names : FreeTermNames, deps : Set[String]) -> Unit {
      for n in names.terms {
        deps.add(n)
      }
      for n in names.constructors {
        deps.add(n)
      }
      for n in names.traits {
        deps.add(n)
      }
      for n in names.dicts {
        deps.add(n)
      }
      for n in names.labels {
        deps.add(n)
      }
      for n in names.type_vars {
        deps.add(n)
      }
      for n in names.type_cons {
        deps.add(n)
      }
    }

    match binding {
      Term(t) => add_type_names(state.compute_free_types(t.ty), deps)
      Type(_) => ()
      TraitDef(t) =>
        for m in t.methods {
          let (_, ty) = m
          add_type_names(state.compute_free_types(ty), deps)
        }
      TraitImpl(t) => {
        deps.add(t.trait_name)
        add_type_names(state.compute_free_types(t.ty), deps)
        add_term_names(state.compute_free_terms(t.dict), deps)
      }
      Dict(t) => {
        deps.add(t.trait_name)
        add_type_names(state.compute_free_types(t.ty), deps)
      }
      TypeAlias(t) => add_type_names(state.compute_free_types(t.body), deps)
      Enum(t) =>
        for v in t.variants {
          let (_, field_scheme) = v
          add_type_names(state.compute_free_types(field_scheme), deps)
        }
    }

    deps
  }

  fn topo_sort_bindings(
    state : TypeCheckerState,
    bindings : Array[Binding],
    names : Set[String],
  ) -> Result[Array[String], TypingError] {
    let ordered = []
    let temp = Set::new()
    let perm = Set::new()
    let stack = []

    fn visit(
      current : String,
      state : TypeCheckerState,
      bindings : Array[Binding],
      names : Set[String],
      temp : Set[String],
      perm : Set[String],
      stack : Array[String],
      ordered : Array[String],
    ) -> Result[Unit, TypingError] {
      if perm.contains(current) {
        return Ok(())
      }
      if temp.contains(current) {
        let cycle = stack.copy()
        cycle.push(current)
        return Err(CircularImport(current, cycle))
      }

      temp.add(current)
      stack.push(current)

      let binding = match find_binding(bindings, current) {
        Some(b) => b
        None => {
          ignore(stack.pop())
          temp.remove(current)
          perm.add(current)
          ordered.push(current)
          return Ok(())
        }
      }

      let deps = binding_dependencies(state, binding)
      for dep in deps {
        if dep != current && names.contains(dep) {
          match visit(dep, state, bindings, names, temp, perm, stack, ordered) {
            Ok(_) => ()
            Err(e) => return Err(e)
          }
        }
      }

      ignore(stack.pop())
      temp.remove(current)
      perm.add(current)
      ordered.push(current)
      Ok(())
    }

    let all_names = names.to_array()
    all_names.sort()
    for name in all_names {
      if !perm.contains(name) {
        match visit(name, state, bindings, names, temp, perm, stack, ordered) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      }
    }
    Ok(ordered)
  }

  let user_ren = Map::new()
  match aliases {
    Some(a) => {
      match a.types {
        Some(m) =>
          for t in m {
            user_ren.set(t.0, t.1)
          }
        None => ()
      }
      match a.traits {
        Some(m) =>
          for t in m {
            user_ren.set(t.0, t.1)
          }
        None => ()
      }
      match a.terms {
        Some(m) =>
          for t in m {
            user_ren.set(t.0, t.1)
          }
        None => ()
      }
      match a.labels {
        Some(m) =>
          for t in m {
            user_ren.set(t.0, t.1)
          }
        None => ()
      }
    }
    None => ()
  }

  let all_deps = match from.collect_dependencies(roots) {
    Ok(deps) => deps
    Err(e) => return Err(e)
  }

  for root in roots {
    let root_renamed = match user_ren.get(root) {
      Some(name) => name
      None => root
    }
    let incoming = find_binding(from.ctx.0, root)
    if has_binding_name(into.ctx.0, root_renamed) && !allow_overrides {
      match incoming {
        Some(_) => return Err(DuplicateBinding(root_renamed))
        None => ()
      }
    }
  }

  let final_ren = user_ren.copy()
  for dep in all_deps {
    if roots.any(r => r == dep) {
      continue
    }
    if user_ren.contains(dep) {
      continue
    }

    let dep_renamed = match final_ren.get(dep) {
      Some(name) => name
      None => dep
    }
    if has_binding_name(into.ctx.0, dep_renamed) {
      final_ren.set(dep, fresh_name(into.ctx.0, dep_renamed))
    }
  }

  let ordered = match topo_sort_bindings(from, from.ctx.0, all_deps) {
    Ok(names) => names
    Err(e) => return Err(e)
  }

  let new_ctx = into.ctx.0.copy()
  for name in ordered {
    let original = match find_binding(from.ctx.0, name) {
      Some(binding) => binding
      None => continue
    }

    let renamed = from.rename_binding(original, final_ren)
    let new_name = binding_name(renamed)

    if allow_overrides {
      let mut replaced = false
      let mut i = 0
      while i < new_ctx.length() {
        if binding_name(new_ctx[i]) == new_name {
          new_ctx[i] = renamed
          replaced = true
          break
        }
        i = i + 1
      }
      if !replaced {
        new_ctx.push(renamed)
      }
    } else {
      new_ctx.push(renamed)
    }
  }

  Ok(TypeCheckerState::{ ctx: Context(new_ctx), meta: into.meta })
}

///|
/// Description: Collects transitive dependencies of context roots with cycle detection.
/// Example: `let _ = TypeCheckerState::fresh().collect_dependencies([])`
pub fn TypeCheckerState::collect_dependencies(
  self : TypeCheckerState,
  roots : Array[String],
) -> Result[Set[String], TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  fn find_binding(bindings : Array[Binding], name : String) -> Binding? {
    for b in bindings {
      if binding_name(b) == name {
        return Some(b)
      }
    }
    None
  }

  fn add_type_names(deps : Set[String], names : FreeTypeNames) -> Unit {
    for n in names.type_vars {
      deps.add(n)
    }
    for n in names.type_cons {
      deps.add(n)
    }
    for n in names.traits {
      deps.add(n)
    }
    for n in names.labels {
      deps.add(n)
    }
  }

  fn add_term_names(deps : Set[String], names : FreeTermNames) -> Unit {
    for n in names.terms {
      deps.add(n)
    }
    for n in names.constructors {
      deps.add(n)
    }
    for n in names.traits {
      deps.add(n)
    }
    for n in names.dicts {
      deps.add(n)
    }
    for n in names.labels {
      deps.add(n)
    }
    for n in names.type_vars {
      deps.add(n)
    }
    for n in names.type_cons {
      deps.add(n)
    }
  }

  fn binding_dependencies(
    state : TypeCheckerState,
    binding : Binding,
  ) -> Set[String] {
    let deps = Set::new()
    match binding {
      Term(t) => add_type_names(deps, state.compute_free_types(t.ty))
      Type(_) => ()
      TypeAlias(t) => add_type_names(deps, state.compute_free_types(t.body))
      Enum(t) =>
        for v in t.variants {
          let (_, field_scheme) = v
          add_type_names(deps, state.compute_free_types(field_scheme))
        }
      TraitDef(t) =>
        for m in t.methods {
          let (_, ty) = m
          add_type_names(deps, state.compute_free_types(ty))
        }
      TraitImpl(t) => {
        deps.add(t.trait_name)
        add_type_names(deps, state.compute_free_types(t.ty))
        add_term_names(deps, state.compute_free_terms(t.dict))
      }
      Dict(t) => {
        deps.add(t.trait_name)
        add_type_names(deps, state.compute_free_types(t.ty))
      }
    }
    deps
  }

  fn build_cycle(stack : Array[String], target : String) -> Array[String] {
    let mut start = 0
    while start < stack.length() {
      if stack[start] == target {
        break
      }
      start = start + 1
    }

    let cycle = []
    let mut i = start
    while i < stack.length() {
      cycle.push(stack[i])
      i = i + 1
    }
    cycle.push(target)
    cycle
  }

  let visited = Set::new()
  let active = Set::new()
  let stack = []
  let deps = Set::new()

  fn dfs(
    state : TypeCheckerState,
    name : String,
    visited : Set[String],
    active : Set[String],
    stack : Array[String],
    deps : Set[String],
  ) -> Result[Unit, TypingError] {
    if visited.contains(name) {
      return Ok(())
    }

    if active.contains(name) {
      return Err(CircularImport(name, build_cycle(stack, name)))
    }

    active.add(name)
    stack.push(name)

    match find_binding(state.ctx.0, name) {
      None => ()
      Some(binding) => {
        deps.add(name)
        let direct = binding_dependencies(state, binding)
        for dep in direct {
          match dfs(state, dep, visited, active, stack, deps) {
            Ok(_) => ()
            Err(e) => return Err(e)
          }
        }
      }
    }

    ignore(stack.pop())
    active.remove(name)
    visited.add(name)
    Ok(())
  }

  for root in roots {
    match dfs(self, root, visited, active, stack, deps) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }

  Ok(deps)
}

///|
/// Description: Adds a named term binding by checking or inferring its type.
/// Example: `let _ = TypeCheckerState::fresh().add_term("x", Term::unit(), None)`
pub fn TypeCheckerState::add_term(
  self : TypeCheckerState,
  name : String,
  term : Term,
  expected_type : Type?,
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  fn insert_binding(
    state : TypeCheckerState,
    binding : Binding,
  ) -> Result[TypeCheckerState, TypingError] {
    let name = binding_name(binding)
    for b in state.ctx.0 {
      if binding_name(b) == name {
        return Err(DuplicateBinding(name))
      }
    }
    Ok(state.extend_context([binding]))
  }

  let ty = match expected_type {
    Some(expected) =>
      match self.check_type(term, expected) {
        Ok(checked) => checked.ty
        Err(e) => return Err(e)
      }
    None =>
      match self.infer_type(term) {
        Ok(inferred) => inferred
        Err(e) => return Err(e)
      }
  }

  insert_binding(self, Binding::term(name, ty))
}

///|
/// Description: Adds a named builtin term binding with declared type and optional checked term body.
/// Example: `let _ = TypeCheckerState::fresh().add_builtin("one", Type::con("Int"), None)`
pub fn TypeCheckerState::add_builtin(
  self : TypeCheckerState,
  name : String,
  declared_type : Type,
  term : Term?,
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  fn insert_binding(
    state : TypeCheckerState,
    binding : Binding,
  ) -> Result[TypeCheckerState, TypingError] {
    let name = binding_name(binding)
    for b in state.ctx.0 {
      if binding_name(b) == name {
        return Err(DuplicateBinding(name))
      }
    }
    Ok(state.extend_context([binding]))
  }

  let kind = match self.check_kind(declared_type, false) {
    Ok(k) => k
    Err(e) => return Err(e)
  }
  if !(kind is Star) {
    return Err(KindMismatch(Star, kind))
  }

  match term {
    Some(t) =>
      match self.check_type(t, declared_type) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    None => ()
  }

  insert_binding(self, Binding::term(name, declared_type))
}

///|
/// Description: Adds a type binding to the context.
/// Example: `let _ = TypeCheckerState::fresh().add_type("Int", Star)`
pub fn TypeCheckerState::add_type(
  self : TypeCheckerState,
  name : String,
  kind : Kind,
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  let binding = Binding::type_binding(name, kind)
  let new_name = binding_name(binding)
  for b in self.ctx.0 {
    if binding_name(b) == new_name {
      return Err(DuplicateBinding(new_name))
    }
  }
  Ok(self.extend_context([binding]))
}

///|
/// Description: Adds a type alias after kind and arity validation.
/// Example: `let _ = TypeCheckerState::fresh().add_type_alias("Id", ["A"], [Star], Type::var_type("A"))`
pub fn TypeCheckerState::add_type_alias(
  self : TypeCheckerState,
  name : String,
  params : Array[String],
  kinds : Array[Kind],
  body : Type,
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  if params.length() != kinds.length() {
    return Err(Message("type alias parameter/kind arity mismatch"))
  }

  let mut alias_kind = Star
  loop params.length() - 1 {
    i if i >= 0 => {
      alias_kind = Kind::arrow(kinds[i], alias_kind)
      continue i - 1
    }
    _ => ()
  }

  let prefix : Array[Binding] = [Binding::type_binding(name, alias_kind)]
  loop 0 {
    i if i < params.length() => {
      prefix.push(Binding::type_binding(params[i], kinds[i]))
      continue i + 1
    }
    _ => ()
  }

  let kind_state = self.extend_context(prefix)
  let body_kind = match kind_state.check_kind(body, false) {
    Ok(k) => k
    Err(e) => return Err(e)
  }
  if !(body_kind is Star) {
    return Err(KindMismatch(Star, body_kind))
  }

  let binding = Binding::type_alias(name, params, kinds, body)
  let new_name = binding_name(binding)
  for b in self.ctx.0 {
    if binding_name(b) == new_name {
      return Err(DuplicateBinding(new_name))
    }
  }
  Ok(self.extend_context([binding]))
}

///|
/// Description: Validates and adds a nominal enum definition to the context.
/// Example: `let _ = TypeCheckerState::fresh().add_enum("Maybe", ["A"], [Star], [("None", Type::unit())], false)`
pub fn TypeCheckerState::add_enum(
  self : TypeCheckerState,
  name : String,
  params : Array[String],
  kinds : Array[Kind],
  variants : Array[(String, FieldScheme)],
  recursive : Bool,
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  if params.length() != kinds.length() {
    return Err(Message("enum parameter/kind arity mismatch"))
  }

  let mut enum_kind = Star
  loop params.length() - 1 {
    i if i >= 0 => {
      enum_kind = Kind::arrow(kinds[i], enum_kind)
      continue i - 1
    }
    _ => ()
  }

  let prefix : Array[Binding] = [Binding::type_binding(name, enum_kind)]
  loop 0 {
    i if i < params.length() => {
      prefix.push(Binding::type_binding(params[i], kinds[i]))
      continue i + 1
    }
    _ => ()
  }
  let kind_state = self.extend_context(prefix)

  let mut has_self_reference = false
  for v in variants {
    let (label, field) = v
    let k = match kind_state.check_kind(field, false) {
      Ok(k) => k
      Err(e) => return Err(e)
    }
    if !(k is Star) {
      return Err(KindMismatch(Star, k))
    }

    if recursive {
      let free = kind_state.compute_free_types(field)
      if free.type_cons.contains(name) {
        has_self_reference = true
      }
    }
    ignore(label)
  }

  let effective_recursive = recursive && has_self_reference
  let binding = Binding::enum_def(
    name, enum_kind, params, variants, effective_recursive,
  )

  let new_name = binding_name(binding)
  for b in self.ctx.0 {
    if binding_name(b) == new_name {
      return Err(DuplicateBinding(new_name))
    }
  }
  Ok(self.extend_context([binding]))
}

///|
/// Description: Adds a trait definition after validating method kinds.
/// Example: `let _ = TypeCheckerState::fresh().add_trait_def("Eq", "A", Star, [])`
pub fn TypeCheckerState::add_trait_def(
  self : TypeCheckerState,
  name : String,
  type_param : String,
  kind : Kind,
  methods : Array[(String, Type)],
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  let kind_state = self.extend_context([Binding::type_binding(type_param, kind)])
  for m in methods {
    let (_, ty) = m
    let k = match kind_state.check_kind(ty, false) {
      Ok(k) => k
      Err(e) => return Err(e)
    }
    if !(k is Star) {
      return Err(KindMismatch(Star, k))
    }
  }

  let binding = Binding::trait_def(name, type_param, kind, methods)
  let new_name = binding_name(binding)
  for b in self.ctx.0 {
    if binding_name(b) == new_name {
      return Err(DuplicateBinding(new_name))
    }
  }
  Ok(self.extend_context([binding]))
}

///|
/// Description: Adds a trait implementation dictionary for a concrete type.
/// Example: `let _ = TypeCheckerState::fresh().add_trait_impl("Eq", Type::con("Int"), Term::dict("Eq", Type::con("Int"), []))`
pub fn TypeCheckerState::add_trait_impl(
  self : TypeCheckerState,
  trait_name : String,
  ty : Type,
  dict : Term,
) -> Result[TypeCheckerState, TypingError] {
  let dict_info = match dict {
    Dict(dict_trait, dict_ty, methods) => (dict_trait, dict_ty, methods)
    _ => return Err(Message("trait implementation requires a dictionary term"))
  }

  match infer_dict_type(self, dict_info.0, dict_info.1, dict_info.2) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }

  for b in self.ctx.0 {
    match b {
      TraitImpl(existing) =>
        if existing.trait_name == trait_name &&
          self.types_equal(existing.ty, ty) {
          return Err(DuplicateBinding(trait_name))
        }
      _ => ()
    }
  }

  Ok(self.extend_context([Binding::trait_impl(trait_name, ty, dict)]))
}

///|
/// Description: Validates and registers a named dictionary binding.
/// Example: `let _ = TypeCheckerState::fresh().add_dict("d", Term::dict("Eq", Type::con("Int"), []))`
pub fn TypeCheckerState::add_dict(
  self : TypeCheckerState,
  name : String,
  dict : Term,
) -> Result[TypeCheckerState, TypingError] {
  fn binding_name(binding : Binding) -> String {
    match binding {
      Term(t) => t.name
      Type(t) => t.name
      TraitDef(t) => t.name
      TraitImpl(t) => t.trait_name
      Dict(t) => t.name
      TypeAlias(t) => t.name
      Enum(t) => t.name
    }
  }

  let (trait_name, ty, methods) = match dict {
    Dict(trait_name, ty, methods) => (trait_name, ty, methods)
    _ => return Err(Message("add_dict expects a dictionary term"))
  }

  match infer_dict_type(self, trait_name, ty, methods) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }

  let binding = Binding::dict(name, trait_name, ty)
  let new_name = binding_name(binding)
  for b in self.ctx.0 {
    if binding_name(b) == new_name {
      return Err(DuplicateBinding(new_name))
    }
  }
  Ok(self.extend_context([binding]))
}

///|
/// Description: Constructs a kind arrow from argument kind to result kind.
/// Example: `let _ = Kind::arrow(Star, Star)`
pub fn Kind::arrow(from : Kind, to : Kind) -> Kind {
  Arrow(from, to)
}

///|
/// Description: Constructs a type variable reference.
/// Example: `let _ = Type::var_type("A")`
pub fn Type::var_type(name : String) -> Type {
  Var(name)
}

///|
/// Description: Constructs an arrow type.
/// Example: `let _ = Type::arrow(Type::con("Int"), Type::con("Bool"))`
pub fn Type::arrow(from : Type, to : Type) -> Type {
  Arrow(from, to)
}

///|
/// Description: Constructs a native borrow reference type.
/// Example: `let _ = Type::ref_type(Region::named("r"), Mutability::shared(), Type::con("Int"))`
pub fn Type::ref_type(
  region : Region,
  mutability : Mutability,
  inner : Type,
) -> Type {
  Ref(region, mutability, inner)
}

///|
/// Description: Constructs a forall type.
/// Example: `let _ = Type::forall("A", Star, Type::var_type("A"))`
pub fn Type::forall(name : String, kind : Kind, body : Type) -> Type {
  Forall(name, kind, body)
}

///|
/// Description: Constructs a type application.
/// Example: `let _ = Type::app(Type::con("List"), Type::con("Int"))`
pub fn Type::app(func : Type, arg : Type) -> Type {
  App(func, arg)
}

///|
/// Description: Constructs a type-level lambda.
/// Example: `let _ = Type::lam("A", Star, Type::var_type("A"))`
pub fn Type::lam(name : String, kind : Kind, body : Type) -> Type {
  Lam(name, kind, body)
}

///|
/// Description: Constructs a type constructor reference.
/// Example: `let _ = Type::con("Int")`
pub fn Type::con(name : String) -> Type {
  Con(name)
}

///|
/// Description: Constructs a record type.
/// Example: `let _ = Type::record([("x", Type::con("Int"))])`
pub fn Type::record(fields : Array[(String, Type)]) -> Type {
  Record(fields)
}

///|
/// Description: Constructs a structural variant type.
/// Example: `let _ = Type::variant([("Some", Type::con("Int"))])`
pub fn Type::variant(cases : Array[(String, Type)]) -> Type {
  Variant(cases)
}

///|
/// Description: Constructs a recursive `mu` type.
/// Example: `let _ = Type::mu("X", Type::var_type("X"))`
pub fn Type::mu(var_name : String, body : Type) -> Type {
  Mu(var_name, body)
}

///|
/// Description: Constructs a tuple type.
/// Example: `let _ = Type::tuple([Type::con("Int"), Type::con("Bool")])`
pub fn Type::tuple(elements : Array[Type]) -> Type {
  Tuple(elements)
}

///|
/// Description: Constructs a bounded forall type with trait constraints.
/// Example: `let _ = Type::bounded_forall("A", Star, [], Type::var_type("A"))`
pub fn Type::bounded_forall(
  name : String,
  kind : Kind,
  constraints : Array[TraitConstraint],
  body : Type,
) -> Type {
  BoundedForall(name, kind, constraints, body)
}

///|
/// Description: Constructs a term variable reference.
/// Example: `let _ = Term::var_term("x")`
pub fn Term::var_term(name : String) -> Term {
  Var(name)
}

///|
/// Description: Constructs a value-level lambda term.
/// Example: `let _ = Term::lam("x", Type::con("Int"), Term::var_term("x"))`
pub fn Term::lam(arg : String, ty : Type, body : Term) -> Term {
  Lam(arg, ty, body)
}

///|
/// Description: Constructs a term application.
/// Example: `let _ = Term::app(Term::var_term("f"), Term::unit())`
pub fn Term::app(callee : Term, arg : Term) -> Term {
  App(callee, arg)
}

///|
/// Description: Constructs a native shared-borrow term.
/// Example: `let _ = Term::borrow_shared(Term::var_term("x"))`
pub fn Term::borrow_shared(target : Term) -> Term {
  BorrowShared(target)
}

///|
/// Description: Constructs a native mutable-borrow term.
/// Example: `let _ = Term::borrow_mut(Term::var_term("x"))`
pub fn Term::borrow_mut(target : Term) -> Term {
  BorrowMut(target)
}

///|
/// Description: Constructs a native dereference term.
/// Example: `let _ = Term::deref(Term::var_term("p"))`
pub fn Term::deref(term : Term) -> Term {
  Deref(term)
}

///|
/// Description: Constructs a native assignment term.
/// Example: `let _ = Term::assign(Term::var_term("p"), Term::unit())`
pub fn Term::assign(target : Term, value : Term) -> Term {
  Assign(target, value)
}

///|
/// Description: Constructs a native move term.
/// Example: `let _ = Term::move_term(Term::var_term("x"))`
pub fn Term::move_term(term : Term) -> Term {
  Move(term)
}

///|
/// Description: Constructs a type lambda term.
/// Example: `let _ = Term::tylam("A", Star, Term::var_term("x"))`
pub fn Term::tylam(name : String, kind : Kind, body : Term) -> Term {
  TyLam(name, kind, body)
}

///|
/// Description: Constructs a type application term.
/// Example: `let _ = Term::tyapp(Term::var_term("id"), Type::con("Int"))`
pub fn Term::tyapp(term : Term, ty : Type) -> Term {
  TyApp(term, ty)
}

///|
/// Description: Constructs a term constructor/literal with its annotated type.
/// Example: `let _ = Term::con("one", Type::con("Int"))`
pub fn Term::con(name : String, ty : Type) -> Term {
  Con(name, ty)
}

///|
/// Description: Constructs a record literal term.
/// Example: `let _ = Term::record([("x", Term::unit())])`
pub fn Term::record(fields : Array[(String, Term)]) -> Term {
  Record(fields)
}

///|
/// Description: Constructs a record projection term.
/// Example: `let _ = Term::project(Term::record([("x", Term::unit())]), "x")`
pub fn Term::project(record : Term, label : String) -> Term {
  Project(record, label)
}

///|
/// Description: Constructs a variant injection term.
/// Example: `let _ = Term::inject("Some", Term::unit(), Type::variant([("Some", Type::unit())]))`
pub fn Term::inject(label : String, value : Term, variant_ty : Type) -> Term {
  Inject(label, value, variant_ty)
}

///|
/// Description: Constructs a match term over patterns.
/// Example: `let _ = Term::match_term(Term::unit(), [(Pattern::wildcard(), Term::unit())])`
pub fn Term::match_term(
  scrutinee : Term,
  cases : Array[(Pattern, Term)],
) -> Term {
  Match(scrutinee, cases)
}

///|
/// Description: Constructs a fold term for recursive types.
/// Example: `let _ = Term::fold(Type::mu("X", Type::var_type("X")), Term::unit())`
pub fn Term::fold(ty : Type, term : Term) -> Term {
  Fold(ty, term)
}

///|
/// Description: Constructs an unfold term for recursive types.
/// Example: `let _ = Term::unfold(Term::var_term("x"))`
pub fn Term::unfold(term : Term) -> Term {
  Unfold(term)
}

///|
/// Description: Constructs a tuple literal term.
/// Example: `let _ = Term::tuple([Term::unit(), Term::unit()])`
pub fn Term::tuple(elements : Array[Term]) -> Term {
  Tuple(elements)
}

///|
/// Description: Constructs tuple projection by index.
/// Example: `let _ = Term::tuple_project(Term::tuple([Term::unit()]), 0)`
pub fn Term::tuple_project(tuple : Term, index : Int) -> Term {
  TupleProject(tuple, index)
}

///|
/// Description: Constructs a let-binding term.
/// Example: `let _ = Term::let_term("x", Term::unit(), Term::var_term("x"))`
pub fn Term::let_term(name : String, value : Term, body : Term) -> Term {
  Let(name, value, body)
}

///|
/// Description: Constructs a trait-bounded polymorphic lambda term.
/// Example: `let _ = Term::trait_lam("d", "Eq", "A", Star, [], Term::var_term("d"))`
pub fn Term::trait_lam(
  trait_var : String,
  trait_name : String,
  type_var : String,
  kind : Kind,
  constraints : Array[TraitConstraint],
  body : Term,
) -> Term {
  TraitLam(trait_var, trait_name, type_var, kind, constraints, body)
}

///|
/// Description: Constructs a trait-polymorphic application with dictionary arguments.
/// Example: `let _ = Term::trait_app(Term::var_term("f"), Type::con("Int"), [])`
pub fn Term::trait_app(term : Term, ty : Type, dicts : Array[Term]) -> Term {
  TraitApp(term, ty, dicts)
}

///|
/// Description: Constructs a dictionary term for a trait implementation.
/// Example: `let _ = Term::dict("Eq", Type::con("Int"), [])`
pub fn Term::dict(
  trait_name : String,
  ty : Type,
  methods : Array[(String, Term)],
) -> Term {
  Dict(trait_name, ty, methods)
}

///|
/// Description: Constructs trait-method selection from a dictionary term.
/// Example: `let _ = Term::trait_method(Term::var_term("d"), "eq")`
pub fn Term::trait_method(dict : Term, trait_method : String) -> Term {
  TraitMethod(dict, trait_method)
}

///|
/// Description: Constructs a variable-binding pattern.
/// Example: `let _ = Pattern::var_pattern("x")`
pub fn Pattern::var_pattern(name : String) -> Pattern {
  VarPattern(name)
}

///|
/// Description: Constructs a wildcard pattern.
/// Example: `let _ = Pattern::wildcard()`
pub fn Pattern::wildcard() -> Pattern {
  WildcardPattern
}

///|
/// Description: Constructs a constructor pattern.
/// Example: `let _ = Pattern::con("Nil", Type::unit())`
pub fn Pattern::con(name : String, ty : Type) -> Pattern {
  ConPattern(name, ty)
}

///|
/// Description: Constructs a record pattern.
/// Example: `let _ = Pattern::record([("x", Pattern::wildcard())])`
pub fn Pattern::record(fields : Array[(String, Pattern)]) -> Pattern {
  RecordPattern(fields)
}

///|
/// Description: Constructs a variant-case pattern.
/// Example: `let _ = Pattern::variant("Some", Pattern::wildcard())`
pub fn Pattern::variant(label : String, pattern : Pattern) -> Pattern {
  VariantPattern(label, pattern)
}

///|
/// Description: Constructs a tuple pattern.
/// Example: `let _ = Pattern::tuple([Pattern::wildcard(), Pattern::wildcard()])`
pub fn Pattern::tuple(elements : Array[Pattern]) -> Pattern {
  TuplePattern(elements)
}

///|
/// Description: Constructs a term binding entry.
/// Example: `let _ = Binding::term("x", Type::con("Int"))`
pub fn Binding::term(name : String, ty : Type) -> Binding {
  Term(TermBinding::{ name, ty })
}

///|
/// Description: Constructs a type binding entry.
/// Example: `let _ = Binding::type_binding("T", Star)`
pub fn Binding::type_binding(name : String, kind : Kind) -> Binding {
  Type(TypeBinding::{ name, kind })
}

///|
/// Description: Constructs a type-alias binding entry.
/// Example: `let _ = Binding::type_alias("Id", ["A"], [Star], Type::var_type("A"))`
pub fn Binding::type_alias(
  name : String,
  params : Array[String],
  kinds : Array[Kind],
  body : Type,
) -> Binding {
  TypeAlias(TypeAliasBinding::{ name, params, kinds, body })
}

///|
/// Description: Constructs a trait-definition binding entry.
/// Example: `let _ = Binding::trait_def("Eq", "A", Star, [])`
pub fn Binding::trait_def(
  name : String,
  type_param : String,
  kind : Kind,
  methods : Array[(String, Type)],
) -> Binding {
  TraitDef(TraitDefBinding::{ name, type_param, kind, methods })
}

///|
/// Description: Constructs a trait-implementation binding entry.
/// Example: `let _ = Binding::trait_impl("Eq", Type::con("Int"), Term::dict("Eq", Type::con("Int"), []))`
pub fn Binding::trait_impl(
  trait_name : String,
  ty : Type,
  dict : Term,
) -> Binding {
  TraitImpl(TraitImplBinding::{ trait_name, ty, dict })
}

///|
/// Description: Constructs a dictionary binding entry.
/// Example: `let _ = Binding::dict("d", "Eq", Type::con("Int"))`
pub fn Binding::dict(name : String, trait_name : String, ty : Type) -> Binding {
  Dict(DictBinding::{ name, trait_name, ty })
}

///|
/// Description: Constructs an enum-definition binding entry.
/// Example: `let _ = Binding::enum_def("Maybe", Kind::arrow(Star, Star), ["A"], [("None", Type::unit())], false)`
pub fn Binding::enum_def(
  name : String,
  kind : Kind,
  params : Array[String],
  variants : Array[(String, FieldScheme)],
  recursive : Bool,
) -> Binding {
  Enum(EnumDefBinding::{ name, kind, params, variants, recursive })
}

///|
fn MetaEnv::new() -> MetaEnv {
  { counter: 0, kinds: Map::new(), solutions: Map::new() }
}

///|
/// Description: Creates an empty checker state.
/// Example: `let _ = TypeCheckerState::fresh()`
pub fn TypeCheckerState::fresh() -> TypeCheckerState {
  TypeCheckerState::{ ctx: Context([]), meta: MetaEnv::new() }
}

///|
/// Description: Looks up an enum definition by enum name.
/// Example: `let _ = Context([]).find_enum("Maybe")`
pub fn Context::find_enum(self : Context, n : String) -> EnumDefBinding? {
  for b in self.0 {
    if b is Enum(binding) && binding.name == n {
      return Some(binding)
    }
  }
  None
}

///|
/// Description: Looks up a type binding by name.
/// Example: `let _ = Context([]).find_type_binding("T")`
pub fn Context::find_type_binding(self : Context, n : String) -> TypeBinding? {
  for b in self.0 {
    if b is Type(binding) && binding.name == n {
      return Some(binding)
    }
  }
  None
}

///|
/// Description: Looks up a type alias by name.
/// Example: `let _ = Context([]).find_type_alias("Id")`
pub fn Context::find_type_alias(
  self : Context,
  n : String,
) -> TypeAliasBinding? {
  for b in self.0 {
    if b is TypeAlias(binding) && binding.name == n {
      return Some(binding)
    }
  }
  None
}

///|
/// Description: Finds the enum that defines a given variant label.
/// Example: `let _ = Context([]).find_enum_by_variant_label("Some")`
pub fn Context::find_enum_by_variant_label(
  self : Context,
  n : String,
) -> EnumDefBinding? {
  for b in self.0 {
    if b is Enum(binding) {
      for l in binding.variants {
        let (label, _) = l
        if label == n {
          return Some(binding)
        }
      }
    }
  }
  None
}

///|
/// Description: Creates a new state with additional bindings pushed in front of context.
/// Example: `let _ = TypeCheckerState::fresh().extend_context([Binding::type_binding("T", Star)])`
pub fn TypeCheckerState::extend_context(
  self : TypeCheckerState,
  bindings : Array[Binding],
) -> TypeCheckerState {
  let new_bindings = []
  for b in bindings {
    new_bindings.push(b)
  }
  new_bindings.append(self.ctx.0)
  TypeCheckerState::{ ctx: Context(new_bindings), meta: self.meta }
}
