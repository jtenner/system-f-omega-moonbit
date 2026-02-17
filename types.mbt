///|
/// Description: Represents kinds for type-level terms (`Star` and kind arrows).
/// Example: `let k = Kind::arrow(Star, Star)`
pub enum Kind {
  Star
  Arrow(Kind, Kind)
} derive(Eq, Hash)

///|
/// Description: Represents type expressions in the System F-omega style type system.
/// Example: `let t = Type::arrow(Type::con("Int"), Type::con("Int"))`
pub enum Type {
  Var(String)
  Con(String)
  EVar(String)
  Never
  Arrow(Type, Type)
  Forall(String, Kind, Type)
  BoundedForall(String, Kind, Array[TraitConstraint], Type)
  Lam(String, Kind, Type)
  App(Type, Type)
  Record(Array[(String, Type)])
  Variant(Array[(String, Type)])
  Mu(String, Type)
  Tuple(Array[Type])
} derive(Eq, Hash)

///|
/// Description: Represents value-level syntax that can be inferred or checked.
/// Example: `let tm = Term::lam("x", Type::con("Int"), Term::var_term("x"))`
pub enum Term {
  Var(String)
  Con(String, Type)
  Lam(String, Type, Term)
  App(Term, Term)
  Let(String, Term, Term)
  TyLam(String, Kind, Term)
  TyApp(Term, Type)
  Dict(String, Type, Array[(String, Term)])
  TraitLam(String, String, String, Kind, Array[TraitConstraint], Term)
  TraitApp(Term, Type, Array[Term])
  TraitMethod(Term, String)
  Record(Array[(String, Term)])
  Project(Term, String)
  Inject(String, Term, Type)
  Match(Term, Array[(Pattern, Term)])
  Fold(Type, Term)
  Unfold(Term)
  Tuple(Array[Term])
  TupleProject(Term, Int)
} derive(Eq, Hash)

///|
/// Description: Represents patterns used in `match` branches and pattern checking.
/// Example: `let p = Pattern::variant("Some", Pattern::var_pattern("x"))`
pub enum Pattern {
  VarPattern(String)
  WildcardPattern
  ConPattern(String, Type)
  RecordPattern(Array[(String, Pattern)])
  VariantPattern(String, Pattern)
  TuplePattern(Array[Pattern])
} derive(Eq, Hash)

///|
/// Description: Tracks evar allocation, evar kinds, and solved evar assignments.
/// Example: `let m = MetaEnv::{ counter: 0, kinds: Map::new(), solutions: Map::new() }`
pub struct MetaEnv {
  mut counter : Int
  kinds : Map[String, Kind]
  solutions : Map[String, Type]
}

///|
/// Description: Carries a deferred type-equality check in the solver worklist.
/// Example: `let c = TypeEqConstraint::{ left: Type::con("Int"), right: Type::con("Int") }`
pub struct TypeEqConstraint {
  left : Type
  right : Type
}

///|
/// Description: Carries a deferred kind-equality check in the solver worklist.
/// Example: `let c = KindEqConstraint::{ left: Star, right: Star }`
pub struct KindEqConstraint {
  left : Kind
  right : Kind
}

///|
/// Description: Carries a deferred request to check that a type has a given kind.
/// Example: `let c = HasKindConstraint::{ ty: Type::con("Int"), kind: Star, state: TypeCheckerState::fresh() }`
pub struct HasKindConstraint {
  ty : Type
  kind : Kind
  state : TypeCheckerState
}

///|
/// Description: Carries a deferred request to infer/check a term against a type.
/// Example: `let c = HasTypeConstraint::{ term: Term::unit(), ty: Type::unit(), state: TypeCheckerState::fresh() }`
pub struct HasTypeConstraint {
  term : Term
  ty : Type
  state : TypeCheckerState
}

///|
/// Description: Sum type of all solver worklist items.
/// Example: `let c = Constraint::type_eq(Type::con("Int"), Type::con("Int"))`
pub enum Constraint {
  TypeEq(TypeEqConstraint)
  KindEq(KindEqConstraint)
  HasKind(HasKindConstraint)
  HasType(HasTypeConstraint)
}

///|
/// Description: Context entry mapping a term name to its type.
/// Example: `let b = TermBinding::{ name: "x", ty: Type::con("Int") }`
pub struct TermBinding {
  name : String
  ty : Type
}

///|
/// Description: Context entry mapping a type name/variable to its kind.
/// Example: `let b = TypeBinding::{ name: "T", kind: Star }`
pub struct TypeBinding {
  name : String
  kind : Kind
}

///|
/// Description: Context entry describing a trait, its type parameter, and methods.
/// Example: `let b = TraitDefBinding::{ name: "Eq", type_param: "A", kind: Star, methods: [] }`
pub struct TraitDefBinding {
  name : String
  type_param : String
  kind : Kind
  methods : Array[(String, Type)]
}

///|
/// Description: Context entry registering a dictionary implementation for a trait/type pair.
/// Example: `let b = TraitImplBinding::{ trait_name: "Eq", ty: Type::con("Int"), dict: Term::dict("Eq", Type::con("Int"), []) }`
pub struct TraitImplBinding {
  trait_name : String
  ty : Type
  dict : Term
}

///|
/// Description: Context entry mapping a dictionary variable to a trait/type pair.
/// Example: `let b = DictBinding::{ name: "d", trait_name: "Eq", ty: Type::con("Int") }`
pub struct DictBinding {
  name : String
  trait_name : String
  ty : Type
}

///|
/// Description: Context entry defining a type alias with parameters and body.
/// Example: `let b = TypeAliasBinding::{ name: "Id", params: ["A"], kinds: [Star], body: Type::var_type("A") }`
pub struct TypeAliasBinding {
  name : String
  params : Array[String]
  kinds : Array[Kind]
  body : Type
}

///|
/// Description: Alias used for enum variant payload types.
/// Example: `let fs : FieldScheme = Type::con("Int")`
pub type FieldScheme = Type

///|
/// Description: Context entry defining a nominal enum and its variants.
/// Example: `let b = EnumDefBinding::{ name: "Maybe", kind: Kind::arrow(Star, Star), params: ["A"], variants: [("None", Type::unit())], recursive: false }`
pub struct EnumDefBinding {
  name : String
  kind : Kind
  params : Array[String]
  variants : Array[(String, FieldScheme)]
  recursive : Bool
}

///|
/// Description: Sum type for all entries that can appear in the typing context.
/// Example: `let b = Binding::type_binding("T", Star)`
pub enum Binding {
  Term(TermBinding)
  Type(TypeBinding)
  TraitDef(TraitDefBinding)
  TraitImpl(TraitImplBinding)
  Dict(DictBinding)
  TypeAlias(TypeAliasBinding)
  Enum(EnumDefBinding)
}

///|
/// Description: Ordered collection of bindings used during checking and inference.
/// Example: `let ctx = Context([Binding::type_binding("T", Star)])`
pub struct Context(Array[Binding])

///|
/// Description: Top-level checker state: context plus mutable meta-environment.
/// Example: `let state = TypeCheckerState::fresh()`
pub struct TypeCheckerState {
  ctx : Context
  meta : MetaEnv
}

///|
/// Description: Map from type variables/evars to replacement types.
/// Example: `let subst : Substitution = Map::new()`
pub type Substitution = Map[String, Type]

///|
/// Description: Queue of constraints consumed by `solve_constraints`.
/// Example: `let wl : Worklist = []`
pub type Worklist = Array[Constraint]

///|
/// Description: Trait requirement attached to bounded polymorphism.
/// Example: `let c = TraitConstraint::{ trait_name: "Eq", ty: Type::con("Int") }`
pub struct TraitConstraint {
  trait_name : String
  ty : Type
} derive(Eq, Hash)

///|
/// Description: Result of `check_type` including resolved type and substitution.
/// Example: `let checked = CheckedType::{ ty: Type::con("Int"), subst: Map::new() }`
pub struct CheckedType {
  ty : Type
  subst : Substitution
}

///|
/// Description: Result of instantiating a bounded forall with dictionaries.
/// Example: `let x = InstantiatedWithTraits::{ ty: Type::con("Int"), dicts: [] }`
pub struct InstantiatedWithTraits {
  ty : Type
  dicts : Array[Term]
}

///|
/// Description: Result of auto-instantiating term-level polymorphism and trait args.
/// Example: `let x = AutoInstantiated::{ term: Term::unit(), ty: Type::unit() }`
pub struct AutoInstantiated {
  term : Term
  ty : Type
}

///|
/// Description: Mode selector used by `infer_type_with_mode`.
/// Example: `let mode = InferMode::check(Type::con("Int"))`
pub enum InferMode {
  Infer
  Check(Type)
}

///|
/// Description: Collected free symbols found in a type expression.
/// Example: `let x = FreeTypeNames::{ type_vars: Set::new(), type_cons: Set::new(), traits: Set::new(), labels: Set::new() }`
pub struct FreeTypeNames {
  type_vars : Set[String]
  type_cons : Set[String]
  traits : Set[String]
  labels : Set[String]
}

///|
/// Description: Collected free symbols found in a pattern expression.
/// Example: `let x = FreePatternNames::{ vars: Set::new(), constructors: Set::new(), labels: Set::new() }`
pub struct FreePatternNames {
  vars : Set[String]
  constructors : Set[String]
  labels : Set[String]
}

///|
/// Description: Collected free symbols found in a term expression.
/// Example: `let x = FreeTermNames::{ terms: Set::new(), constructors: Set::new(), traits: Set::new(), dicts: Set::new(), labels: Set::new(), type_vars: Set::new(), type_cons: Set::new() }`
pub struct FreeTermNames {
  terms : Set[String]
  constructors : Set[String]
  traits : Set[String]
  dicts : Set[String]
  labels : Set[String]
  type_vars : Set[String]
  type_cons : Set[String]
}

///|
/// Description: Optional rename maps used when importing bindings between states.
/// Example: `let a = ImportAliases::{ types: None, traits: None, terms: None, labels: None }`
pub(all) struct ImportAliases {
  types : Map[String, String]?
  traits : Map[String, String]?
  terms : Map[String, String]?
  labels : Map[String, String]?
}

///|
/// Description: Error variants produced by kinding, typing, unification, and imports.
/// Example: `let e : TypingError = Unbound("x")`
pub suberror TypingError {
  TypeMismatch(Type, Type)
  KindMismatch(Kind, Kind)
  Cyclic(String)
  Unbound(String)
  NotATypeFunction(Type)
  NotAVariant(Type)
  InvalidVariantLabel(Type, String)
  MissingCase(String)
  ExtraCase(String)
  NotATuple(Type)
  TupleIndexOutOfBounds(Type, Int)
  NotARecord(Type)
  MissingField(Type, String)
  NotAFunction(Type)
  MissingMethod(String, String)
  WrongNumberOfDicts(Int, Int)
  MissingTraitImpl(String, Type)
  DuplicateBinding(String)
  CircularImport(String, Array[String])
  Message(String)
}
