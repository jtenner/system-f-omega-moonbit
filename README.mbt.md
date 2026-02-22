# jtenner/sfo

A **System Fω (F-omega)–style typechecker** implemented in **MoonBit**.

This library is for projects that need a typed core calculus with:
- **higher-kinded types** (kinds like `*` and `k1 -> k2`)
- **type-level functions** (type lambdas/applications)
- **polymorphism** (`Forall`, plus trait-constrained `BoundedForall`)
- **records, variants, tuples**
- **recursive types** (`Mu`) with explicit `fold`/`unfold`
- **trait dictionaries** (dictionary passing) and bounded polymorphism
- **import/dependency helpers** for composing modules and renaming symbols

If you’ve built a compiler or typed DSL before: think “small, explicit core calculus + a stateful environment + a unifier + constraint solving”.

---

## The big idea

You work with a `TypeCheckerState`, which contains:

- a **Context** (ordered stack of bindings for terms/types/enums/traits/etc.)
- a **MetaEnv** (fresh metavariables `EVar`, their kinds, and their solutions)

The checker supports two primary workflows:

1. **Inference (“synthesis”)**: `infer_type(term)` computes the term’s type.
2. **Checking**: `check_type(term, expected)` verifies a term has a type and may produce substitutions.

Most “builder” APIs return an updated state (`Result[TypeCheckerState, TypingError]`) so you can treat environments as immutable values and pipe them forward.

---

## Getting started (practical)

### 1) Create a checker state and add bindings

```moonbit nocheck
///|
fn must_state(r : Result[TypeCheckerState, TypingError]) -> TypeCheckerState {
  match r {
    Ok(s) => s
    Err(_) => panic()
  }
}

///|
fn setup_state() -> TypeCheckerState {
  let s0 = TypeCheckerState::fresh()

  // Add base type constructors (with kinds).
  let s1 = must_state(s0.add_type("Int", Star))
  let s2 = must_state(s1.add_type("Bool", Star))

  // Add a nominal enum Maybe[A] = None | Some(A)
  // Enums live in the context and can be normalized to structural variants.
  let s3 = must_state(
    s2.add_enum(
      "Maybe",
      ["A"],
      [Star],
      [("None", Type::unit()), ("Some", Type::var_type("A"))],
      false,
    ),
  )

  // Add a term binding. If expected type is None, it will be inferred.
  must_state(s3.add_term("one", Term::con("one", Type::con("Int")), None))
}
````

**What these builders do:**

* `add_type(name, kind)` registers a type constructor (e.g. `Int : *`).
* `add_enum(...)` registers a nominal enum definition; `normalize_type` can expand uses into structural variants (and recursive enums into `Mu`).
* `add_term(name, term, expected?)` typechecks the term and stores its binding in the context.

### 2) Infer and check terms

```moonbit nocheck
///|
fn infer_example(state : TypeCheckerState) -> Type {
  let id_int = Term::lam("x", Type::con("Int"), Term::var_term("x"))
  match state.infer_type(id_int) {
    Ok(t) => t
    Err(_) => panic()
  }
}

///|
fn check_example(state : TypeCheckerState) -> CheckedType {
  let term = Term::lam("x", Type::con("Int"), Term::var_term("x"))
  let expected = Type::arrow(Type::con("Int"), Type::con("Int"))
  match state.check_type(term, expected) {
    Ok(checked) => checked
    Err(_) => panic()
  }
}
```

**Rule of thumb**

* Use `infer_type` when you want the checker to *synthesize* the type.
* Use `check_type` when you already know the expected type (often produces better errors).

### 3) Typical workflow

1. Start with `TypeCheckerState::fresh()`.
2. Register your known universe: `add_type`, `add_enum`, `add_type_alias`, `add_trait_def`, `add_trait_impl`, `add_dict`, `add_term`, `add_builtin`.
3. Call `infer_type` / `check_type`.
4. When comparing types across module boundaries or after inference, call `normalize_type` first.
5. Handle `TypingError` via pattern matching (much nicer than string-based errors).

---

## What the language model contains

This package models a typed lambda calculus core and extends it with System F and Fω features.

### Term calculus (values and evaluation structure)

* `Var` — term variables
* `Lam` / `App` — lambda abstraction and application
* `Let` — let bindings
* `TyLam` / `TyApp` — explicit type abstraction/application (System F)
* `Record` / `Project` — records and field projection
* `Variant` / `Inject` / `Match` — sum types and pattern matching
* `Tuple` / `TupleProject` — tuples and projections
* `Mu` + `Fold` / `Unfold` — explicit recursion boundary at the value level
* `Dict` / `TraitLam` / `TraitApp` / `TraitMethod` — dictionary passing for constrained polymorphism

### Type calculus (types, kinds, and higher-kinded programming)

* `Kind`: `Star` and `Arrow(Kind, Kind)`
* `Type`: `Arrow`, `Forall`, `BoundedForall`, `Lam`, `App`, plus structural `Record`, `Variant`, `Tuple`, and recursive `Mu`
* `EVar` metavariables for inference/unification

---

## Important concepts (before you skim the API)

### Structural variants vs nominal enums

You can write variants structurally:

* `Type::variant([("A", tA), ("B", tB)])`

Or define enums nominally in the context:

* `add_enum("Maybe", ["A"], [Star], [("None", ()), ("Some", A)], false)`

Nominal enums are especially useful for module boundaries and reuse. When you care about actual structure (e.g. unification / matching), call:

* `state.normalize_type(ty)`

This expands enum instances to structural variants. Recursive enums normalize to a `Mu`-wrapped structural body.

### Pattern matching and exhaustiveness

`infer_type(Match(...))` checks:

* labels are valid (for enum scrutinees)
* the match is exhaustive via `check_exhaustive`

Wildcards and variable patterns count as “covers everything”.

### Recursive types: `Mu`, `Fold`, `Unfold`

`Mu` represents an explicit recursive type boundary.

* Build a recursive type: `Type::mu("X", body)`
* `Fold(rec_ty, term)` checks that the term matches the unfolded body.
* `Unfold(term)` requires the term to have a recursive type and returns the unfolded view.

This keeps recursion explicit and makes unification/normalization tractable.

### Traits, dictionaries, and bounded polymorphism

This library uses *dictionary passing*.

* Define a trait: `add_trait_def(name, type_param, kind, methods)`
* Provide an implementation as a dictionary term: `add_trait_impl(trait_name, ty, dict_term)`
* Optionally bind a dictionary by name: `add_dict(name, dict_term)`

`BoundedForall` represents “forall T : k where constraints hold”.
`auto_instantiate` can infer and insert:

* missing type arguments, and
* required dictionaries for constraints

---

## API guide (human version)

Below is the public surface (from `pkg.generated.mbti`) grouped by how you’ll actually use it.

### Module composition / imports

#### `import_module(from~, into~, roots?, aliases?, allow_overrides?) -> Result[TypeCheckerState, TypingError]`

Imports a dependency-closed set of bindings from one state into another.

* **Use when**: you have a “module” represented as bindings in a `TypeCheckerState` and want to bring a subset into a new state.
* `roots` selects which names you’re importing; dependencies are discovered transitively.
* `aliases` lets you rename imported types/terms/traits/labels to avoid collisions.
* `allow_overrides = false` makes duplicates a hard error (`DuplicateBinding`).

#### `collect_dependencies(roots) -> Result[Set[String], TypingError]`

Computes the transitive closure of dependencies starting from `roots`.

* **Use when**: you want to know what must be imported / compiled / emitted.
* Detects cycles and reports them as `CircularImport` / `CircularImport(node, cycle)`.

### Pretty printers (debugging / diagnostics)

* `pretty_type(ty) -> String` — readable Unicode-ish type output
* `pretty_term(term) -> String` — readable term output
* `pretty_pattern(pattern) -> String` — readable pattern output

These are for developer-facing display; they’re intentionally more human-friendly than `Show`/`Debug`.

### Kinds

#### `unify_kinds(left, right) -> Result[Unit, TypingError]`

Checks kinds are equal.

* **Use when**: you’re constructing or validating higher-kinded types and want explicit failures.
* Failures are `KindMismatch(expected, actual)`.

`Kind` helpers:

* `Kind::star()` — `*`
* `Kind::arrow(from, to)` — `k1 -> k2`
* `Kind::arity()` — number of arrow params
* `Kind::peel_n_params(n)` — pull out the first `n` argument kinds

### Types

Type constructors are mostly what you think:

* `var_type`, `con`, `arrow`, `forall`, `bounded_forall`, `lam`, `app`, `record`, `variant`, `mu`, `tuple`

Utilities you’ll actually reach for:

#### `Type::pretty_print(self) -> String`

Same purpose as `pretty_type`, but as a method.

#### `Type::substitute_type(self, target, replacement) -> Type`

Capture-avoiding substitution that respects binders (`Forall`, `Lam`, `Mu`, etc.).

* **Use when**: implementing transformations (e.g. desugaring, normalization passes) or writing analyses.

#### `Type::occurs_check(self, var_name) -> Bool`

Checks whether a free occurrence exists (binder-aware).

* **Use when**: sanity checks during unification-like code, or to validate recursive type constructions.

#### `Type::get_spine_head` / `Type::get_spine_args`

For `(((F A) B) C)`:

* head is `F`
* args are `[A, B, C]`

These are convenient for recognizing type constructors with multiple params.

#### `Type::collect_type_vars(self) -> Array[String]`

Collect free type variables (useful for generalization or diagnostics).

#### `Type::create_variant_lambda(self, self_kind) -> Type`

Wraps a variant in enough type lambdas to match a kind arity.

* **Use when**: bridging “variant as a type function” scenarios (higher-kinded variant encodings).

### Terms

Constructors cover the term language:

* variables, lambdas/apps, let
* type lambdas/apps
* records/variants/tuples
* fold/unfold
* dictionary/trait operations

`Term::pretty_print(self)` is the debugging workhorse.

### Patterns

Patterns are used primarily by `Match` checking and exhaustiveness checking.

#### `Pattern::extract_pattern_labels(self) -> Set[String]`

Collects variant labels used inside the pattern (nested).

* **Use when**: diagnostics, match analysis, or custom coverage checks.

---

## The typechecker entry points (what you’ll call most)

### Building environments

All of these **extend the context** and return a new state.

* `add_type(name, kind)`

  * Register type constructor and kind.
* `add_type_alias(name, params, kinds, body)`

  * Define a type alias (validated for arity/kinds).
* `add_enum(name, params, kinds, variants, recursive)`

  * Define a nominal enum. If `recursive=true`, it is only accepted if self-reference is actually found.
* `add_trait_def(name, type_param, kind, methods)`

  * Define a trait; methods must have kind `Star`.
* `add_trait_impl(trait_name, ty, dict)`

  * Register an implementation dictionary for a concrete type.
* `add_dict(name, dict)`

  * Bind a dictionary term by name (so `TraitMethod` can reference it).
* `add_term(name, term, expected_type?)`

  * Add a term binding, checking against `expected_type` if provided; otherwise infer.
* `add_builtin(name, declared_type, term?)`

  * Register a builtin with a declared type (optionally with a body to check).

### Inference / checking

#### `infer_type(term) -> Result[Type, TypingError]`

The main synthesizer.

* **Use when**: you want the type that falls out of inference.
* Produces metas (`EVar`) internally and solves them during unification/constraint solving.

#### `check_type(term, expected_type) -> Result[CheckedType, TypingError]`

Checks a term against a known type.

* **Use when**: you already have the expected type (common at boundaries like “annotation required” or “API surface”).
* Typically produces clearer mismatch errors than `infer_type`.

#### `infer_type_with_mode(term, mode)`

Dispatch between infer/check modes, useful when building pipelines.

#### `typecheck_with_constraints(term)`

Constraint-driven alternative entry point; useful if you want explicit constraint queueing.

### Equality, assignability, unification

#### `types_equal(left, right) -> Bool`

Structural equality with:

* alpha-equivalence
* order-insensitive records/variants (field/case ordering doesn’t matter)

#### `is_assignable_to(from, to) -> Bool`

A small “subtyping-ish” check:

* treats `Never` as bottom (`Never` assignable to anything)

#### `unify_types(left, right, worklist, subst) -> Result[Unit, TypingError]`

Core unifier. This is what makes inference work.

It handles:

* functions, polymorphism, records/variants/tuples
* enum-vs-variant bridging
* metavariables, occurs checks
* recursion checks for `Mu`

Unless you’re extending the algorithm, you’ll typically only call this indirectly through inference/checking.

### Constraints and substitutions

The checker uses substitutions + a constraint worklist.

* `solve_constraints(worklist, subst)`
* `process_constraint(constraint, worklist, subst)`
* `apply_substitution(subst, ty)`
* `apply_substitution_to_term(subst, term, avoid)`
* `solve_meta_var(evar, solution)`
* `resolve_meta_vars(ty)`
* `get_unbound_metas(ty)` / `has_unbound_metas(ty)`

**When you care**

* If you’re writing tooling: show users where inference left holes (`EVar`s).
* If you’re implementing a pass: normalize/resolve metas before comparing.

### Kinds, patterns, match handling

* `check_kind(ty, lenient)`

  * Kindchecks a type. If `lenient=true`, unknown constructors are treated as `Star` (useful for partial environments).
* `check_pattern(pattern, ty)`

  * Checks a pattern against a scrutinee type and returns a context of bound variables.
* `check_exhaustive(patterns, ty)`

  * Ensures a match is total for variants/enums.

### Traits and bounded polymorphism

* `check_trait_implementation(trait_name, ty)`

  * Find a dictionary for a trait/type pair (exact or unification-based).
* `check_trait_constraints(constraints)`

  * Resolve all dictionaries required by bounded constraints.
* `instantiate_type(ty)` / `instantiate_term(term)`

  * Open `Forall`/`BoundedForall` and type lambdas with fresh metas.
* `instantiate_with_traits(ty)`

  * Open bounded forall and return the dictionaries you must supply.
* `auto_instantiate(term)`

  * The ergonomic entry point: infer type, then auto-apply missing type args and dict args where possible.

### Normalization & renaming

#### `normalize_type(ty) -> Type`

This is the “make types comparable” function.

It can:

* expand aliases
* expand enums into structural variants
* reduce type-level beta redexes (`Type::app(Type::lam(...), ...)`)
* expand recursive enums into `Mu`
* resolve solved metas

If you hit “why don’t these types match?” — normalize both sides before comparing.

Renaming APIs (`rename_type`, `rename_term`, etc.) support module composition and symbol hygiene.

---

## Errors (`TypingError`)

Errors are meant to be pattern-matched (recommended). A few common ones:

* `TypeMismatch(expected, actual)` — failed checking / unification
* `KindMismatch(expected, actual)` — kind mismatch
* `Unbound(name)` — missing term/type/trait/etc.
* `DuplicateBinding(name)` — context import/build conflict
* `MissingCase` / `ExtraCase` / `InvalidVariantLabel` — match/variant issues
* `MissingTraitImpl(trait_name, ty)` / `MissingMethod` — trait resolution failures

---

## Examples

(Your examples are already excellent; keep them. They’re the most “human” part of the README.)

### Structural variant and pattern match

```moonbit nocheck
///|
fn variant_match_type(state : TypeCheckerState) -> Result[Type, TypingError] {
  let vty = Type::variant([("A", Type::unit()), ("B", Type::unit())])

  let term = Term::match_term(Term::inject("A", Term::unit(), vty), [
    (
      Pattern::variant("A", Pattern::wildcard()),
      Term::con("one", Type::con("Int")),
    ),
    (
      Pattern::variant("B", Pattern::wildcard()),
      Term::con("two", Type::con("Int")),
    ),
  ])

  state.infer_type(term)
}
```

### Nominal enum use (`Maybe[Int]`)

```moonbit nocheck
///|
fn maybe_some_type(state : TypeCheckerState) -> Result[Type, TypingError] {
  let maybe_int = Type::app(Type::con("Maybe"), Type::con("Int"))
  state.infer_type(
    Term::inject("Some", Term::con("one", Type::con("Int")), maybe_int),
  )
}
```

### Recursive type with fold/unfold

```moonbit nocheck
///|
fn recursive_example(
  state : TypeCheckerState,
) -> Result[(Type, Type), TypingError] {
  let rec_ty = Type::mu(
    "X",
    Type::tuple([Type::con("Int"), Type::var_type("X")]),
  )

  let folded = Term::fold(rec_ty, Term::con("bottom", Type::never()))

  match state.infer_type(folded) {
    Err(e) => Err(e)
    Ok(folded_ty) =>
      match state.infer_type(Term::unfold(folded)) {
        Err(e) => Err(e)
        Ok(unfolded_ty) => Ok((folded_ty, unfolded_ty))
      }
  }
}
```

### Trait dictionary setup and use

```moonbit nocheck
///|
fn trait_example() -> Result[Type, TypingError] {
  let s0 = TypeCheckerState::fresh()
  let s1 = s0.add_type("Int", Star)?
  let s2 = s1.add_type("Bool", Star)?

  let s3 = s2.add_trait_def("Eq", "T", Star, [
    ("eq", Type::arrow(Type::var_type("T"), Type::arrow(Type::var_type("T"), Type::con("Bool")))),
  ])?

  let int_dict = Term::dict("Eq", Type::con("Int"), [
    (
      "eq",
      Term::lam(
        "x",
        Type::con("Int"),
        Term::lam("y", Type::con("Int"), Term::con("true", Type::con("Bool"))),
      ),
    ),
  ])

  let s4 = s3.add_trait_impl("Eq", Type::con("Int"), int_dict)?
  let s5 = s4.add_dict("eqInt", int_dict)?

  s5.infer_type(Term::trait_method(Term::var_term("eqInt"), "eq"))
}
```

---

## Tooling

* `moon test --package jtenner/sfo`
* `moon info`
* `moon fmt`

Workspace Moon binary:

* `/home/jtenner/.moon/bin/moon`

---

## Notes and gotchas

* `Never` is treated as bottom in several assignability/unification paths.
* Many APIs return updated `TypeCheckerState`; prefer explicit reassignment in build pipelines.
* For diagnostics, pattern-match `TypingError` rather than relying on string rendering.
* Use `normalize_type` before comparisons when aliases/enums/metas are in play.

