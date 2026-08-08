---
description: Strict TypeScript-only code review — type safety, purity, generics, API design, correctness — framework-agnostic
argument-hint: "[staged|unstaged|branch|file/glob/PR-url]"
---
Perform a **strict, exhaustive TypeScript code review**. Focus on **type safety and code
quality at the language level** — not framework specifics. Be rigorous and honest; do NOT
rubber-stamp. Treat `any`, unsafe casts, and hidden mutation as defects to be justified or
removed.

## 0. Scope resolution

Target: `${@:-staged}`

- `staged`   → `rtk git diff --cached`
- `unstaged` → `rtk git diff`
- `branch`   → `rtk git diff main...HEAD` (fall back to `master` if `main` absent)
- path/glob  → read those files directly
- PR URL     → `rtk gh pr view` + `rtk gh pr diff`
- nothing to review + no arg → ask; do not guess.

Use **serena MCP** to find symbol definitions, references, and callers of each changed
type/function. Understand how each type flows through the codebase before judging it.

## 1. Context (do first, silently)

- Load base rules: `./CLAUDE.md`, `./AGENTS.md`.
- Note `tsconfig.json` strictness flags (`strict`, `noUncheckedIndexedAccess`,
  `exactOptionalPropertyTypes`, `noImplicitOverride`, etc.) and hold code to them.
- For each changed function/type, identify inputs, outputs, and invariants.

## 2. Review dimensions (cover EVERY applicable one)

For each finding cite exact **file:line**, quote the snippet, explain the *why*, give a
concrete typed fix.

### A. Type safety (highest priority)
- Flag every `any` — require `unknown` + narrowing, or a precise type.
- Flag unsafe casts: `as X`, `as any`, `as unknown as X`, non-null `!`. Demand proof or
  a runtime guard instead.
- No implicit `any` (params, callbacks, catch clauses — prefer `catch (e: unknown)`).
- Correct nullability: `undefined` vs `null` consistency; optional vs `| undefined`.
- Index access safety (assume `noUncheckedIndexedAccess`); handle possibly-undefined.
- Discriminated unions over boolean/enum soup; exhaustive `switch` with `never` guard.

### B. Type modeling & contracts
- Interfaces for public contracts; `type` for unions/mapped/utility compositions.
- Make illegal states unrepresentable (narrow unions, branded/opaque types where useful).
- Prefer `readonly` and `Readonly<T>` / `ReadonlyArray<T>` for inputs.
- `as const` for literal tuples/objects; avoid widening.
- Correct use of utility types (`Pick`, `Omit`, `Partial`, `Record`, `ReturnType`, etc.).

### C. Generics
- Generics constrained (`<T extends ...>`) rather than unconstrained/`any`-like.
- Inference works from call site (no needless explicit type args).
- No over-engineered generics where a concrete type is clearer (KISS).
- Correct variance; conditional/mapped types justified and readable.

### D. Functions & purity
- Pure functions returning **new** objects; no in-place mutation of inputs.
- Declarative over imperative; small, composable, single-purpose.
- Factory functions over direct `new` where it improves testability/composition.
- Explicit return types on exported/public functions; narrow, honest signatures.
- No boolean trap params; options objects for 3+ args.

### E. Immutability & side effects
- Flag hidden mutation of shared state, params, or module-level singletons (`@BREAKING`).
- Prefer immutable updates (spread / structural copy) over mutation.
- No reliance on evaluation-order side effects.

### F. Correctness & edge cases
- Off-by-one, boundary, empty input, NaN/Infinity, integer/float assumptions.
- Async correctness: every Promise awaited or intentionally fire-and-forget with comment
  substitute (annotation); no floating promises; `Promise.all` vs sequential intent.
- `catch` blocks type errors as `unknown` and narrow before use; no swallowed errors.

### G. Error handling & results
- Errors typed and meaningful; consider Result/Either-style returns over throwing where it
  clarifies control flow.
- No throwing plain strings; custom error classes where helpful.

### H. Module & API design
- Clear public surface; avoid leaking internal types.
- No circular dependencies; cohesive modules; barrel files not hiding cycles.
- Consistent naming: PascalCase types/classes, camelCase vars/functions.

### I. Maintainability
- Reuse existing types/utils before adding new (3-File Rule).
- No magic numbers/strings — named consts / enums / unions.
- No dead code, duplicate logic, or `@ts-ignore`/`@ts-expect-error` without justification.
- Annotations: new `@REVIEW`, deprecated `@NOT-NEED`, side effects `@BREAKING`.
- Source comments are banned (TODO allowed).

### J. Performance (language-level)
- Avoid needless allocations in hot paths; prefer `Map`/`Set` over object/array scans.
- No accidental O(n²) from nested `.find`/`.includes` in loops.

### K. Tests
- Do NOT write or run tests. List what SHOULD be tested and the tricky type/edge cases.

## 3. Output format

```
# TypeScript Review — <target>

## Summary
<2-4 sentences: type-safety posture, ship-readiness, biggest risk>

## Verdict
<APPROVE | APPROVE WITH NITS | REQUEST CHANGES | BLOCK> — one-line justification

## Type-Safety Scorecard
- any usages: <n>   unsafe casts: <n>   non-null !: <n>   @ts-ignore: <n>

## Findings
### 🔴 Critical (unsound / bug risk)
- [file:line] <issue> → <typed fix>
### 🟠 Major
- ...
### 🟡 Minor / Nits
- ...
### 🟢 Positive
- ...

## Rule Compliance (CLAUDE.md / AGENTS.md)
- ✅ / ❌ per relevant rule

## Suggested Tests (do not write them)
- <case>

## Follow-ups / Tech Debt
- <item>
```

## 4. Discipline

- Judge against the project's `tsconfig` strictness — do not assume looser settings.
- Uncertain findings → label `(needs verification)` and say how to verify.
- Never invent issues; never hide real ones.
- Prefix shell commands with `rtk`. Use serena MCP for navigation.
- Do NOT modify code, commit, push, or write tests.
