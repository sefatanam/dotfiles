---
description: Deep Angular-only code review (framework idioms, signals, RxJS, templates, a11y) against project rules — no Tauri/native concerns
argument-hint: "[staged|unstaged|branch|file/glob/PR-url]"
---
Perform a **deep, exhaustive Angular code review**. Be rigorous, specific, and honest.
Do NOT rubber-stamp. This is a **pure Angular front-end review** — do NOT flag or comment
on Tauri / native / desktop concerns (Tauri is optional and out of scope here).

## 0. Scope resolution

Target: `${@:-staged}`

- `staged`   → `rtk git diff --cached`
- `unstaged` → `rtk git diff`
- `branch`   → `rtk git diff main...HEAD` (fall back to `master` if `main` absent)
- path/glob  → read those files directly
- PR URL     → `rtk gh pr view` + `rtk gh pr diff`
- if nothing to review and no arg → ask; do not guess.

Use **serena MCP** to navigate symbols, find references, and load the 3 most related
files per changed file (the "3-File Rule"). Review real code, never filenames alone.

## 1. Context (do first, silently)

- Load base rules: `./CLAUDE.md`, `./AGENTS.md`.
- Classify each changed unit: component, service, signal store, RxJS pipeline, directive,
  pipe, route, guard/resolver, or pure util.
- Trace data flow: input → transform → render/output.

## 2. Review dimensions (cover EVERY applicable one)

For each finding cite exact **file:line**, quote the snippet, explain the *why*, give a
concrete fix (code where useful).

### A. Component design
- Standalone only; `standalone: true` must NOT be set (it's default).
- `changeDetection: OnPush` present.
- `input()` / `output()` functions — flag `@Input()` / `@Output()` decorators.
- Small, single-responsibility components; prefer inline templates for small ones.
- No `viewChild` (project-banned). Flag overuse of `effect()`.
- No `@HostBinding` / `@HostListener` — must use the `host` object.

### B. State & signals
- `signal()` for local state, `computed()` for derived state.
- Never `mutate` a signal — must use `set` / `update`.
- Pure, predictable state transformations; no hidden shared mutation.
- Reactive forms over template-driven.

### C. Templates
- Native control flow `@if` / `@for` / `@switch` — flag `*ngIf` / `*ngFor` / `*ngSwitch`.
- `@for` has a proper `track` expression (identity, not `$index` unless justified).
- `class` / `style` bindings — flag `ngClass` / `ngStyle`.
- `async` pipe for observables (avoid manual subscribe in components).
- `NgOptimizedImage` for static images (not for inline base64).
- Keep template logic minimal; move complex logic to `computed`/methods.

### D. RxJS & memory safety
- Every subscription cleaned up (prefer `async` pipe / `takeUntilDestroyed`).
- No nested `subscribe` — use `switchMap` / `mergeMap` / `concatMap` / `exhaustMap`
  (verify the chosen operator matches the concurrency intent).
- `@BREAKING`-flag `tap()` that mutates shared state.
- Understand cold vs hot; no leaked long-lived subjects.

### E. Services & DI
- `inject()` over constructor DI.
- Singletons `providedIn: 'root'`; each service single-responsibility.
- No business logic leaking into components that belongs in a service.

### F. Routing & performance
- Lazy loading for feature routes.
- Stable references in templates (avoid new arrays/functions each CD cycle).
- Missing `OnPush` / unnecessary re-renders; expensive work memoized via `computed`.
- Heavy imports / bundle bloat; defer/lazy where sensible.

### G. Accessibility & UX
- Semantic elements, labels, roles, keyboard nav, focus management, aria-*.
- Alt text on images; contrast-independent information.

### H. Correctness & error handling
- Null/undefined, empty collections, loading/error/empty states in the UI.
- No silent catches; user-facing failures handled gracefully.

### I. Angular Material / CDK (if used)
- Correct component APIs, theming tokens, overlay/portal cleanup, a11y directives.

### J. Maintainability
- Reuse existing services/utils/components before adding new (3-File Rule).
- Clear naming; no magic numbers; no dead/duplicate code.
- Annotations: new `@REVIEW`, deprecated `@NOT-NEED`, side effects `@BREAKING`.
- Source comments are banned (TODO allowed).

### K. Tests
- Do NOT write or run tests. List what SHOULD be tested and key edge cases.

## 3. Output format

```
# Angular Review — <target>

## Summary
<2-4 sentences: quality, ship-readiness, biggest risk>

## Verdict
<APPROVE | APPROVE WITH NITS | REQUEST CHANGES | BLOCK> — one-line justification

## Findings
### 🔴 Critical (must fix)
- [file:line] <issue> → <fix>
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

- Do NOT review Tauri / native / IPC / desktop packaging — out of scope.
- Uncertain findings → label `(needs verification)` and say how to verify.
- Never invent issues; never hide real ones.
- Prefix shell commands with `rtk`. Use serena MCP for navigation.
- Do NOT modify code, commit, push, or write tests.
