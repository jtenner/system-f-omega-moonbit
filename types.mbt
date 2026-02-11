///|
pub enum Kind {
  Star
  Arrow(Kind, Kind)
}

///|
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
}

///|
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
}

///|
pub enum Pattern {
  VarPattern(String)
  WildcardPattern
  ConPattern(String, Type)
  RecordPattern(Array[(String, Pattern)])
  VariantPattern(String, Pattern)
  TuplePattern(Array[Pattern])
}

///|
pub struct MetaEnv {
  mut counter : Int
  kinds : Map[String, Kind]
  solutions : Map[String, Type]
}

///|
pub struct TypeEqConstraint {
  left : Type
  right : Type
}

///|
pub struct KindEqConstraint {
  left : Kind
  right : Kind
}

///|
pub struct HasKindConstraint {
  ty : Type
  kind : Kind
  state : TypeCheckerState
}

///|
pub struct HasTypeConstraint {
  term : Term
  ty : Type
  state : TypeCheckerState
}

///|
pub enum Constraint {
  TypeEq(TypeEqConstraint)
  KindEq(KindEqConstraint)
  HasKind(HasKindConstraint)
  HasType(HasTypeConstraint)
}

///|
pub struct TermBinding {
  name : String
  ty : Type
}

///|
pub struct TypeBinding {
  name : String
  kind : Kind
}

///|
pub struct TraitDefBinding {
  name : String
  type_param : String
  kind : Kind
  methods : Array[(String, Type)]
}

///|
pub struct TraitImplBinding {
  trait_name : String
  ty : Type
  dict : Term
}

///|
pub struct DictBinding {
  name : String
  trait_name : String
  ty : Type
}

///|
pub struct TypeAliasBinding {
  name : String
  params : Array[String]
  kinds : Array[Kind]
  body : Type
}

///|
pub type FieldScheme = Type

///|
pub struct EnumDefBinding {
  name : String
  kind : Kind
  params : Array[String]
  variants : Array[(String, FieldScheme)]
  recursive : Bool
}

///|
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
pub type Context = Array[Binding]

///|
pub struct TypeCheckerState {
  ctx : Context
  meta : MetaEnv
}

///|
pub type Substitution = Map[String, Type]

///|
pub type Worklist = Array[Constraint]

///|
pub struct TraitConstraint {
  trait_name : String
  ty : Type
}

///|
pub struct CheckedType {
  ty : Type
  subst : Substitution
}

///|
pub struct InstantiatedWithTraits {
  ty : Type
  dicts : Array[Term]
}

///|
pub struct AutoInstantiated {
  term : Term
  ty : Type
}

///|
pub enum InferMode {
  Infer
  Check(Type)
}

///|
pub struct FreeTypeNames {
  type_vars : Set[String]
  type_cons : Set[String]
  traits : Set[String]
  labels : Set[String]
}

///|
pub struct FreePatternNames {
  vars : Set[String]
  constructors : Set[String]
  labels : Set[String]
}

///|
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
pub struct ImportAliases {
  types : Map[String, String]?
  traits : Map[String, String]?
  terms : Map[String, String]?
  labels : Map[String, String]?
}

///|
pub struct ImportModuleArgs {
  from : TypeCheckerState
  into : TypeCheckerState
  roots : Array[String]
  aliases : ImportAliases?
  allow_overrides : Bool
}

///|
pub enum TypingError {
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

///|
// MoonBit's built-in Result type is used throughout:
// Result[OkValue, ErrValue]

///|
pub type AppType = Type

///|
pub type ArrowType = Type

///|
pub type BoundedForallType = Type

///|
pub type ConType = Type

///|
pub type ForallType = Type

///|
pub type LamType = Type

///|
pub type MetaType = Type

///|
pub type MuType = Type

///|
pub type RecordType = Type

///|
pub type TupleType = Type

///|
pub type VariantType = Type

///|
pub type VarType = Type

///|
pub type AppTerm = Term

///|
pub type DictTerm = Term

///|
pub type FoldTerm = Term

///|
pub type InjectTerm = Term

///|
pub type LamTerm = Term

///|
pub type LetTerm = Term

///|
pub type MatchTerm = Term

///|
pub type ProjectTerm = Term

///|
pub type RecordTerm = Term

///|
pub type TraitAppTerm = Term

///|
pub type TraitLamTerm = Term

///|
pub type TraitMethodTerm = Term

///|
pub type TupleProjectTerm = Term

///|
pub type TupleTerm = Term

///|
pub type TyAppTerm = Term

///|
pub type TyLamTerm = Term

///|
pub type UnfoldTerm = Term

///|
pub type VarTerm = Term

///|
pub type ConPattern = Pattern

///|
pub type RecordPattern = Pattern

///|
pub type TuplePattern = Pattern
