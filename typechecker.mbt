///|
pub fn type_eq(left : Type, right : Type) -> TypeEqConstraint {
  ...
}

///|
pub fn kind_eq(left : Kind, right : Kind) -> KindEqConstraint {
  ...
}

///|
pub fn has_kind(
  ty : Type,
  kind : Kind,
  state : TypeCheckerState,
) -> HasKindConstraint {
  ...
}

///|
pub fn has_type(
  term : Term,
  ty : Type,
  state : TypeCheckerState,
) -> HasTypeConstraint {
  ...
}

///|
pub fn infer_mode() -> InferMode {
  ...
}

///|
pub fn check_mode(check : Type) -> InferMode {
  ...
}

///|
pub fn infer_type_with_mode(
  state : TypeCheckerState,
  term : Term,
  mode : InferMode,
) -> Result[Type, TypingError] {
  ...
}

///|
pub fn merge_substs(local : Substitution, globals : Substitution) -> Substitution {
  ...
}

///|
pub fn is_meta_var(ty : Type) -> Bool {
  ...
}

///|
pub fn fresh_meta_var(env : MetaEnv, kind : Kind) -> MetaType {
  ...
}

///|
pub fn star_kind() -> Kind {
  ...
}

///|
pub fn never_type() -> Type {
  ...
}

///|
pub fn unit_type() -> Type {
  ...
}

///|
pub fn unit_value() -> Term {
  ...
}

///|
pub fn is_bottom(state : TypeCheckerState, ty : Type) -> Bool {
  ...
}

///|
pub fn solve_meta_var(
  state : TypeCheckerState,
  evar : String,
  solution : Type,
) -> Result[Unit, TypingError] {
  ...
}

///|
pub fn occurs_check_evar(env : MetaEnv, evar : String, ty : Type) -> Bool {
  ...
}

///|
pub fn instantiate_term(state : TypeCheckerState, term : Term) -> Term {
  ...
}

///|
pub fn instantiate_type(state : TypeCheckerState, ty : Type) -> Type {
  ...
}

///|
pub fn subsumes(
  state : TypeCheckerState,
  general : Type,
  specific : Type,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  ...
}

///|
pub fn is_assignable_to(state : TypeCheckerState, from : Type, to : Type) -> Bool {
  ...
}

///|
pub fn pattern_bindings(pattern : Pattern) -> Array[(String, Type)] {
  ...
}

///|
pub fn check_trait_implementation(
  state : TypeCheckerState,
  trait_name : String,
  ty : Type,
) -> Result[Term, TypingError] {
  ...
}

///|
pub fn check_trait_constraints(
  state : TypeCheckerState,
  constraints : Array[TraitConstraint],
) -> Result[Array[Term], TypingError] {
  ...
}

///|
pub fn extract_pattern_labels(pattern : Pattern) -> Set[String] {
  ...
}

///|
pub fn check_exhaustive(
  state : TypeCheckerState,
  patterns : Array[Pattern],
  ty : Type,
) -> Result[Unit, TypingError] {
  ...
}

///|
pub fn check_pattern(
  state : TypeCheckerState,
  pattern : Pattern,
  ty : Type,
) -> Result[Context, TypingError] {
  ...
}

///|
pub fn substitute_type(
  target : String,
  replacement : Type,
  in_type : Type,
) -> Type {
  ...
}

///|
pub fn is_star_kind(kind : Kind) -> Bool {
  ...
}

///|
pub fn kinds_equal(left : Kind, right : Kind) -> Bool {
  ...
}

///|
pub fn check_kind(
  state : TypeCheckerState,
  ty : Type,
  lenient : Bool,
) -> Result[Kind, TypingError] {
  ...
}

///|
pub fn types_equal(state : TypeCheckerState, left : Type, right : Type) -> Bool {
  ...
}

///|
pub fn alpha_rename(from : String, to : String, ty : Type) -> Type {
  ...
}

///|
pub fn unify_types(
  state : TypeCheckerState,
  left : Type,
  right : Type,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  ...
}

///|
pub fn unify_variable(
  state : TypeCheckerState,
  var_name : String,
  ty : Type,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  ...
}

///|
pub fn unify_kinds(left : Kind, right : Kind) -> Result[Unit, TypingError] {
  ...
}

///|
pub fn occurs_check(var_name : String, ty : Type) -> Bool {
  ...
}

///|
pub fn apply_substitution(
  state : TypeCheckerState,
  subst : Substitution,
  ty : Type,
) -> Type {
  ...
}

///|
pub fn check_type(
  state : TypeCheckerState,
  term : Term,
  expected_type : Type,
) -> Result[CheckedType, TypingError] {
  ...
}

///|
pub fn infer_type(state : TypeCheckerState, term : Term) -> Result[Type, TypingError] {
  ...
}

///|
pub fn get_spine_head(ty : Type) -> Type {
  ...
}

///|
pub fn get_spine_args(ty : Type) -> Array[Type] {
  ...
}

///|
pub fn get_unbound_metas(state : TypeCheckerState, ty : Type) -> Array[String] {
  ...
}

///|
pub fn solve_constraints(
  state : TypeCheckerState,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Substitution, TypingError] {
  ...
}

///|
pub fn process_constraint(
  state : TypeCheckerState,
  constraint : Constraint,
  worklist : Worklist,
  subst : Substitution,
) -> Result[Unit, TypingError] {
  ...
}

///|
pub fn type_check(state : TypeCheckerState, term : Term) -> Result[Type, TypingError] {
  ...
}

///|
pub fn typecheck_with_constraints(
  state : TypeCheckerState,
  term : Term,
) -> Result[Type, TypingError] {
  ...
}

///|
pub fn normalize_type(state : TypeCheckerState, ty : Type) -> Type {
  ...
}

///|
pub fn instantiate_with_traits(
  state : TypeCheckerState,
  ty : Type,
) -> Result[InstantiatedWithTraits, TypingError] {
  ...
}

///|
pub fn auto_instantiate(
  state : TypeCheckerState,
  term : Term,
) -> Result[AutoInstantiated, TypingError] {
  ...
}

///|
pub fn resolve_meta_vars(state : TypeCheckerState, ty : Type) -> Type {
  ...
}

///|
pub fn kind_arity(kind : Kind) -> Int {
  ...
}

///|
pub fn has_unbound_metas(state : TypeCheckerState, ty : Type) -> Bool {
  ...
}

///|
pub fn collect_type_vars(ty : Type) -> Array[String] {
  ...
}

///|
pub fn create_variant_lambda(vtype : Type, self_kind : Kind) -> Type {
  ...
}

///|
pub fn rename_type(
  state : TypeCheckerState,
  ty : Type,
  ren : Map[String, String],
) -> Type {
  ...
}

///|
pub fn rename_term(
  state : TypeCheckerState,
  term : Term,
  ren : Map[String, String],
) -> Term {
  ...
}

///|
pub fn rename_pattern(
  state : TypeCheckerState,
  pattern : Pattern,
  ren : Map[String, String],
  bound : Set[String],
) -> Pattern {
  ...
}

///|
pub fn rename_binding(
  state : TypeCheckerState,
  binding : Binding,
  ren : Map[String, String],
) -> Binding {
  ...
}

///|
pub fn compute_free_types(
  state : TypeCheckerState,
  ty : Type,
) -> FreeTypeNames {
  ...
}

///|
pub fn compute_free_patterns(
  state : TypeCheckerState,
  pattern : Pattern,
) -> FreePatternNames {
  ...
}

///|
pub fn compute_free_terms(
  state : TypeCheckerState,
  term : Term,
) -> FreeTermNames {
  ...
}

///|
pub fn import_module(args : ImportModuleArgs) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn collect_dependencies(
  state : TypeCheckerState,
  roots : Array[String],
) -> Result[Set[String], TypingError] {
  ...
}

///|
pub fn add_term(
  state : TypeCheckerState,
  name : String,
  term : Term,
  expected_type : Type?,
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn add_builtin(
  state : TypeCheckerState,
  name : String,
  declared_type : Type,
  term : Term?,
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn add_type(
  state : TypeCheckerState,
  name : String,
  kind : Kind,
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn add_type_alias(
  state : TypeCheckerState,
  name : String,
  params : Array[String],
  kinds : Array[Kind],
  body : Type,
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn add_enum(
  state : TypeCheckerState,
  name : String,
  params : Array[String],
  kinds : Array[Kind],
  variants : Array[(String, FieldScheme)],
  recursive : Bool,
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn add_trait_def(
  state : TypeCheckerState,
  name : String,
  type_param : String,
  kind : Kind,
  methods : Array[(String, Type)],
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn add_trait_impl(
  state : TypeCheckerState,
  trait_name : String,
  ty : Type,
  dict : Term,
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn add_dict(
  state : TypeCheckerState,
  name : String,
  dict : DictTerm,
) -> Result[TypeCheckerState, TypingError] {
  ...
}

///|
pub fn show_type(ty : Type) -> String {
  ...
}

///|
pub fn arrow_kind(from : Kind, to : Kind) -> Kind {
  ...
}

///|
pub fn var_type(name : String) -> Type {
  ...
}

///|
pub fn arrow_type(from : Type, to : Type) -> Type {
  ...
}

///|
pub fn forall_type(name : String, kind : Kind, body : Type) -> Type {
  ...
}

///|
pub fn app_type(func : Type, arg : Type) -> Type {
  ...
}

///|
pub fn lam_type(name : String, kind : Kind, body : Type) -> Type {
  ...
}

///|
pub fn con_type(name : String) -> Type {
  ...
}

///|
pub fn record_type(fields : Array[(String, Type)]) -> Type {
  ...
}

///|
pub fn variant_type(cases : Array[(String, Type)]) -> Type {
  ...
}

///|
pub fn mu_type(var_name : String, body : Type) -> Type {
  ...
}

///|
pub fn tuple_type(elements : Array[Type]) -> Type {
  ...
}

///|
pub fn bounded_forall_type(
  name : String,
  kind : Kind,
  constraints : Array[TraitConstraint],
  body : Type,
) -> Type {
  ...
}

///|
pub fn var_term(name : String) -> Term {
  ...
}

///|
pub fn lam_term(arg : String, ty : Type, body : Term) -> Term {
  ...
}

///|
pub fn app_term(callee : Term, arg : Term) -> Term {
  ...
}

///|
pub fn tylam_term(name : String, kind : Kind, body : Term) -> Term {
  ...
}

///|
pub fn tyapp_term(term : Term, ty : Type) -> Term {
  ...
}

///|
pub fn con_term(name : String, ty : Type) -> Term {
  ...
}

///|
pub fn record_term(fields : Array[(String, Term)]) -> Term {
  ...
}

///|
pub fn project_term(record : Term, label : String) -> Term {
  ...
}

///|
pub fn inject_term(label : String, value : Term, variant_ty : Type) -> Term {
  ...
}

///|
pub fn match_term(scrutinee : Term, cases : Array[(Pattern, Term)]) -> Term {
  ...
}

///|
pub fn fold_term(ty : Type, term : Term) -> Term {
  ...
}

///|
pub fn unfold_term(term : Term) -> Term {
  ...
}

///|
pub fn tuple_term(elements : Array[Term]) -> Term {
  ...
}

///|
pub fn tuple_project_term(tuple : Term, index : Int) -> Term {
  ...
}

///|
pub fn let_term(name : String, value : Term, body : Term) -> Term {
  ...
}

///|
pub fn trait_lam_term(
  trait_var : String,
  trait_name : String,
  type_var : String,
  kind : Kind,
  constraints : Array[TraitConstraint],
  body : Term,
) -> Term {
  ...
}

///|
pub fn trait_app_term(term : Term, ty : Type, dicts : Array[Term]) -> Term {
  ...
}

///|
pub fn dict_term(
  trait_name : String,
  ty : Type,
  methods : Array[(String, Term)],
) -> Term {
  ...
}

///|
pub fn trait_method_term(dict : Term, method : String) -> Term {
  ...
}

///|
pub fn var_pattern(name : String) -> Pattern {
  ...
}

///|
pub fn wildcard_pattern() -> Pattern {
  ...
}

///|
pub fn con_pattern(name : String, ty : Type) -> Pattern {
  ...
}

///|
pub fn record_pattern(fields : Array[(String, Pattern)]) -> Pattern {
  ...
}

///|
pub fn variant_pattern(label : String, pattern : Pattern) -> Pattern {
  ...
}

///|
pub fn tuple_pattern(elements : Array[Pattern]) -> Pattern {
  ...
}

///|
pub fn term_binding(name : String, ty : Type) -> Binding {
  ...
}

///|
pub fn type_binding(name : String, kind : Kind) -> Binding {
  ...
}

///|
pub fn type_alias_binding(
  name : String,
  params : Array[String],
  kinds : Array[Kind],
  body : Type,
) -> Binding {
  ...
}

///|
pub fn trait_def_binding(
  name : String,
  type_param : String,
  kind : Kind,
  methods : Array[(String, Type)],
) -> Binding {
  ...
}

///|
pub fn trait_impl_binding(trait_name : String, ty : Type, dict : Term) -> Binding {
  ...
}

///|
pub fn dict_binding(name : String, trait_name : String, ty : Type) -> Binding {
  ...
}

///|
pub fn enum_def_binding(
  name : String,
  kind : Kind,
  params : Array[String],
  variants : Array[(String, FieldScheme)],
  recursive : Bool,
) -> Binding {
  ...
}

///|
pub fn fresh_state() -> TypeCheckerState {
  ...
}
