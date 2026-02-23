# jtenner/sfo

A **System Fω (F-omega)–style typechecker** implemented in **MoonBit**.

If you are new to this style of typechecker, use this mental model:

1. **Kind**: the “type of a type” (`*`, `k1 -> k2`).
2. **Type**: expressions like function types, polymorphic types, records, refs, and recursive `Mu`.
3. **Term**: runtime language nodes (`Lam`, `App`, `Match`, `borrow_mut`, etc.) that the checker assigns types to.
4. **TypeCheckerState**: the working state used by inference/checking.
5. **Context + MetaEnv** inside that state:
   - `Context` is the ordered stack of known bindings (terms, types, traits, enums, dictionaries, aliases).
   - `MetaEnv` tracks fresh inference variables (`EVar`), their kinds, and solved substitutions.

The library is for projects that need a typed core calculus with:
- **higher-kinded types** (kinds like `*` and `k1 -> k2`)
- **type-level functions** (type lambdas/applications)
- **polymorphism** (`Forall`, plus trait-constrained `BoundedForall`)
- **records, variants, tuples**
- **recursive types** (`Mu`) with explicit `fold`/`unfold`
- **native borrow/reference forms** (`Ref`, `borrow_shared`, `borrow_mut`, `deref`, `assign`, `move`)
- **trait dictionaries** (dictionary passing) and bounded polymorphism
- **import/dependency helpers** for composing modules and renaming symbols

If you’ve built a compiler or typed DSL before: think “small, explicit core calculus + a stateful environment + a unifier + constraint solving”.

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
```

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

## Borrow Checker Quickstart

These snippets are executable and mirrored in `typechecker_readme_quickstart_wbtest.mbt` via helpers in `readme_examples_wbtest.mbt`.

### `Term::borrow_shared`

Accepted:

```moonbit nocheck
///|
let accepted = readme_quickstart_borrow_shared_accepted()
match accepted {
  Ok(Ref(Named(region), Shared, Con(inner))) => {
    assert_eq(region, "borrow::x")
    assert_eq(inner, "Int")
  }
  _ => panic()
}
```

Rejected:

```moonbit nocheck
///|
let rejected = readme_quickstart_borrow_shared_rejected()
match rejected {
  Err(InvalidBorrowTarget(message)) => assert_true(message.contains("borrow_shared"))
  _ => panic()
}
```

`borrow_shared` requires a valid place expression (`x`, `x.field`, `deref(p)`, ...). Borrowing a non-place like `()` is rejected.

### `Term::borrow_mut`

Accepted:

```moonbit nocheck
///|
let accepted = readme_quickstart_borrow_mut_accepted()
match accepted {
  Ok(Ref(Named(region), Mutable, Con(inner))) => {
    assert_eq(region, "borrow::x")
    assert_eq(inner, "Int")
  }
  _ => panic()
}
```

Rejected:

```moonbit nocheck
///|
let rejected = readme_quickstart_borrow_mut_rejected()
assert_true(rejected is Err(BorrowConflict(_, _)))
```

Conflicting active loans over the same place are rejected.

### `Term::deref`

Accepted:

```moonbit nocheck
///|
let accepted = readme_quickstart_deref_accepted()
match accepted {
  Ok(Con(name)) => assert_eq(name, "Int")
  _ => panic()
}
```

Rejected:

```moonbit nocheck
///|
let rejected = readme_quickstart_deref_rejected()
match rejected {
  Err(InvalidBorrowTarget(message)) => assert_true(message.contains("deref"))
  _ => panic()
}
```

`deref` expects a reference type input; dereferencing a non-reference term is rejected.

### `Term::assign`

Accepted:

```moonbit nocheck
///|
let accepted = readme_quickstart_assign_accepted()
match accepted {
  Ok(Tuple(elements)) => assert_eq(elements.length(), 0) // Unit
  _ => panic()
}
```

Rejected:

```moonbit nocheck
///|
let rejected = readme_quickstart_assign_rejected()
assert_true(rejected is Err(AssignToImmutable(_)))
```

`assign` requires a mutable reference target. Assigning through a shared reference is rejected.

### `Term::move_term`

Accepted:

```moonbit nocheck
///|
let accepted = readme_quickstart_move_term_accepted()
match accepted {
  Ok(Con(name)) => assert_eq(name, "Int")
  _ => panic()
}
```

Rejected:

```moonbit nocheck
///|
let rejected = readme_quickstart_move_term_rejected()
assert_true(rejected is Err(MovedValueBorrow(_)))
```

Moving a value and then borrowing the same place in the same flow is rejected.

---

## Borrow Errors and Fix Patterns

These error/fix snippets are mirrored in `typechecker_readme_borrow_errors_wbtest.mbt`.

### `UseAfterMove`

Failing:

```moonbit nocheck
///|
assert_true(readme_borrow_error_use_after_move_failing() is Err(UseAfterMove(_)))
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_use_after_move_fix() is Ok(_))
```

Pattern: reinitialize (or avoid using) a place after moving it.

### `MovedValueBorrow`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_moved_value_borrow_failing() is Err(MovedValueBorrow(_)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_moved_value_borrow_fix() is Ok(_))
```

Pattern: do not borrow from a place after moving it.

### `BorrowConflict`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_borrow_conflict_failing() is Err(BorrowConflict(_, _)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_borrow_conflict_fix() is Ok(_))
```

Pattern: release or end one overlapping borrow before creating the next conflicting one.

### `MutateWhileBorrowed`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_mutate_while_borrowed_failing() is
  Err(MutateWhileBorrowed(_)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_mutate_while_borrowed_fix() is Ok(_))
```

Pattern: do not mutate places while an overlapping loan is active.

### `AssignToImmutable`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_assign_to_immutable_failing() is Err(AssignToImmutable(_)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_assign_to_immutable_fix() is Ok(_))
```

Pattern: assign only through mutable references.

### `BorrowOutlivesOwner`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_borrow_outlives_owner_failing() is
  Err(BorrowOutlivesOwner(_)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_borrow_outlives_owner_fix() is Ok(_))
```

Pattern: ensure borrow regions are constrained to the owner lifetime.

### `DanglingReferenceEscape`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_dangling_reference_escape_failing() is
  Err(DanglingReferenceEscape(_)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_dangling_reference_escape_fix() is Ok(_))
```

Pattern: prevent references from escaping owners they depend on.

### `InvalidBorrowTarget`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_invalid_borrow_target_failing() is
  Err(InvalidBorrowTarget(_)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_invalid_borrow_target_fix() is Ok(_))
```

Pattern: borrow/deref/assign only valid place expressions (`x`, `x.field`, tuple index, deref place).

### `RegionConstraintUnsatisfied`

Failing:

```moonbit nocheck
///|
assert_true(
  readme_borrow_error_region_constraint_unsatisfied_failing() is
  Err(RegionConstraintUnsatisfied(_)),
)
```

Fix:

```moonbit nocheck
///|
assert_true(readme_borrow_error_region_constraint_unsatisfied_fix() is Ok(_))
```

Pattern: add the missing outlives relation or adjust regions so required constraints are satisfiable.

---

## Beginner Cookbook

These cookbook snippets are mirrored in `typechecker_readme_cookbook_wbtest.mbt`.

### Higher-kinded types and kind checking

```moonbit nocheck
///|
let result = readme_cookbook_higher_kinded_kind_example()
match result {
  Ok((Arrow(Star, Star), Star)) => ()
  _ => panic()
}
```

### Type-level lambdas and type application

```moonbit nocheck
///|
let result = readme_cookbook_type_level_lambda_application_example()
match result {
  Ok(Arrow(Con(from), Con(to))) => {
    assert_eq(from, "Int")
    assert_eq(to, "Int")
  }
  _ => panic()
}
```

### `Forall` and `BoundedForall`

```moonbit nocheck
///|
let result = readme_cookbook_forall_and_bounded_forall_example()
match result {
  Ok((Forall(_, _, _), BoundedForall(_, _, _, _))) => ()
  _ => panic()
}
```

### Traits, dictionaries, and bounded polymorphism

```moonbit nocheck
///|
let result = readme_cookbook_traits_dictionaries_bounded_poly_example()
let expected = Type::arrow(
  Type::con("Int"),
  Type::arrow(Type::con("Int"), Type::con("Bool")),
)
match result {
  Ok(ty) => assert_true(ty == expected)
  _ => panic()
}
```

### Records, variants, tuples, and pattern matching

```moonbit nocheck
///|
let result = readme_cookbook_records_variants_tuples_patterns_example()
match result {
  Ok((record_project_ty, tuple_project_ty, match_ty)) => {
    assert_true(record_project_ty == Type::con("Bool"))
    assert_true(tuple_project_ty == Type::con("Bool"))
    assert_true(match_ty == Type::con("Int"))
  }
  _ => panic()
}
```

### Recursive types (`Mu`) with `fold`/`unfold`

```moonbit nocheck
///|
let result = readme_cookbook_recursive_mu_fold_unfold_example()
match result {
  Ok((Mu(_, _), Tuple(elements))) => assert_true(elements.length() == 2)
  _ => panic()
}
```

### Module import/dependency helpers and rename APIs

```moonbit nocheck
///|
let result = readme_cookbook_import_dependency_rename_example()
match result {
  Ok((deps_include_int, imported_has_value, rename_rewrites_free_term)) => {
    assert_true(deps_include_int)
    assert_true(imported_has_value)
    assert_true(rename_rewrites_free_term)
  }
  _ => panic()
}
```

---

## From Error to Fix

| `TypingError` | Likely Cause | First Debug Step |
|---|---|---|
| `TypeMismatch` | Expected and inferred types diverge. | Normalize both sides and inspect branch return types. |
| `KindMismatch` | Type-level term used at incompatible kind. | Run `check_kind` on each component and compare arities. |
| `Unbound` | Missing type/term/dictionary binding in context. | Verify `add_type`/`add_term`/`add_dict` setup order. |
| `BorrowConflict` | Overlapping conflicting loans are active. | Release/shorten one borrow before creating another. |
| `UseAfterMove` | Place was moved and used again. | Reinitialize place before reuse or remove later use. |
| `MovedValueBorrow` | Borrow attempted after move. | Borrow before move, or avoid borrowing moved place. |
| `AssignToImmutable` | Assignment through shared/immutable reference. | Make target a mutable ref before `assign`. |
| `InvalidBorrowTarget` | Borrow/deref/assign applied to non-place expression. | Restrict operations to place expressions. |
| `RegionConstraintUnsatisfied` | Required outlives relation missing. | Inspect generated region constraints and add missing edge. |

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
* `BorrowShared` / `BorrowMut` / `Deref` / `Assign` / `Move` — native borrow operations
* `Mu` + `Fold` / `Unfold` — explicit recursion boundary at the value level
* `Dict` / `TraitLam` / `TraitApp` / `TraitMethod` — dictionary passing for constrained polymorphism

### Type calculus (types, kinds, and higher-kinded programming)

* `Kind`: `Star` and `Arrow(Kind, Kind)`
* `Type`: `Arrow`, `Forall`, `BoundedForall`, `Lam`, `App`, borrow `Ref(region, mutability, inner)`, plus structural `Record`, `Variant`, `Tuple`, and recursive `Mu`
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

### Borrow/lifetime behavior (native terms)

Native borrow syntax:

* `Term::borrow_shared(target)`
* `Term::borrow_mut(target)`
* `Term::deref(term)`
* `Term::assign(target, value)`
* `Term::move_term(term)`

Reference type constructor:

* `Type::ref_type(region, mutability, inner)`

Current semantics:

* `infer_type` is the primary policy entry for native borrow checking. If a term contains native borrow syntax, borrow analysis runs in the core infer/check flow.
* `infer_type_with_borrow_analysis` and `check_type_with_borrow_analysis` still run wrapper analysis for non-native/probe terms, but skip redundant re-analysis for native borrow syntax by threading native-policy flags from core helpers.
* Core and wrapper gating use the same native-syntax detector (`term_contains_native_borrow_syntax`) to keep policy decisions consistent.
* Native borrow target validation is canonicalized through `borrow_place_from_term`, which is shared by typing and borrow-IR lowering.
* Inferred native references use deterministic region naming: `borrow::<place_key>`.
  * Examples: `x -> borrow::x`, `x.field -> borrow::x.field`, `deref(p) -> borrow::p.*`, `x.0 -> borrow::x.0`.
* When checking `BorrowShared` / `BorrowMut` against an expected `Ref`, region and mutability must match the inferred native borrow reference; mismatches produce `TypeMismatch`.
* Match-branch moved-place state now uses a deterministic path-sensitive join (set intersection across sibling branches), so values moved on only one branch are not treated as globally moved after the join.
* Region probe operations in borrow IR now emit/check structural region constraints instead of relying on sentinel `__err_*` placeholders during runtime analysis.

Stable borrow IR schema:

* `borrow_ir_schema_version()` currently returns `1`.
* Match branch joins are encoded as explicit boundary nodes with constructor name `borrow_ir_match_branch_boundary_marker_name()` (`"BorrowIrBoundaryMatchBranch"`).
* Generalized borrow-op constructor encoding is:
  * `BorrowOp<OpName>__<root>__(field:<label>|tuple:<index>|deref)*`
  * Examples: `BorrowOpBorrowShared__x`, `BorrowOpBorrowMut__x__field:left__deref`, `BorrowOpMove__q__field:a__tuple:1`.
* Generalized region/invalid probe encodings are:
  * `BorrowOpRegionOutlivesOwner__<place>`
  * `BorrowOpRegionDanglingEscape__<place>`
  * `BorrowOpRegionUnsatisfied__<left_region>__<right_region>` where region tokens use `named:<name>`, `infer:<id>`, or `static`
  * `BorrowOpInvalidTarget__<operation_name>`
* Legacy fixed tags like `BorrowOpBorrowMutX` / `BorrowOpBorrowSharedXField` are treated as ordinary constructors; tests/builders now use generalized path-based tags.
* Legacy fixed region/invalid tags (`BorrowOpRegionOutlivesOwner`, `BorrowOpRegionDanglingEscape`, `BorrowOpRegionUnsatisfied`, `BorrowOpInvalidTarget`) are also treated as ordinary constructors.

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
* `BorrowCheckerOptions::disabled()` disables wrapper orchestration, but direct `infer_type` / `check_type` still enforce native borrow semantics.
