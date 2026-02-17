///|
pub enum Kind {
  Star
  Arrow(Kind, Kind)
} derive(Eq, Hash)

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
} derive(Eq, Hash)

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
} derive(Eq, Hash)

///|
pub enum Pattern {
  VarPattern(String)
  WildcardPattern
  ConPattern(String, Type)
  RecordPattern(Array[(String, Pattern)])
  VariantPattern(String, Pattern)
  TuplePattern(Array[Pattern])
} derive(Eq, Hash)

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
pub struct Context(Array[Binding])

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
} derive(Eq, Hash)

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
pub(all) struct ImportAliases {
  types : Map[String, String]?
  traits : Map[String, String]?
  terms : Map[String, String]?
  labels : Map[String, String]?
}

///|
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
