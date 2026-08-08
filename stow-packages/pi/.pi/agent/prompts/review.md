---
description: Deep, thorough code review of changes (or a target) against Angular/TypeScript/Tauri best practices and project rules
argument-hint: "[staged|unstaged|branch|file/glob/PR-url]"
---
Perform a **deep, exhaustive code review**. Be rigorous, specific, and honest. Do NOT
rubber-stamp. Assume the code will ship to production and must be correct, safe, and
maintainable. Prefer precision over politeness — but stay constructive.

## 0. Scope resolution

Target: `${@:-staged}`

Determine what to review:
- `staged`  → `rtk git diff --cached`
- `unstaged`→ `rtk git diff`
- `branch`  → `rtk git diff main...HEAD` (fall back to `master` if `main` is absent)
- a path/glob → review those files directly with the read tool
- a PR URL  → use `rtk gh pr view` + `rtk gh pr diff` for that PR
- if nothing is staged/changed and no arg is given, ask what to review — do not guess.

Before reviewing, use **serena MCP** to navigate symbols, find references, and load the
3 most related files for each changed file (per the "3-File Rule"). Read the actual code —
never review from filenames alone.

## 1. Context gathering (do this first, silently)

- Load base rules: `./CLAUDE.md`, `./AGENTS.md`.
- Identify each changed symbol and its call sites via serena (find references).
- Note the surrounding architecture: is this a component, service, signal store,
  Tauri bridge, RxJS pipeline, route, guard, or pure util?
- Map data flow in → transformation → out for each changed unit.

## 2. Review dimensions (cover EVERY applicable one)

For each finding, cite the exact **file:line**, quote the snippet, explain the *why*, and
give a concrete fix (code where useful).

### A. Correctness & Logic
- Off-by-one, boundary, null/undefined, empty-collection, and error paths.
- Async correctness: race conditions, unhandled rejections, missing `await`.
- Does the code actually do what the PR/intent claims? Any missed requirement?

### B. Angular 22 idioms
- Standalone components only; `standalone: true` must NOT be set (it's default).
- `changeDetection: OnPush` present on components.
- `input()` / `output()` functions — flag any `@Input()` / `@Output()` decorators.
- `signal()` for local state, `computed()` for derived — flag `mutate` (use `set`/`update`).
- Flag overuse of `effect()` and any `viewChild` usage (project bans them).
- Native control flow `@if`/`@for`/`@switch` — flag `*ngIf`/`*ngFor`/`*ngSwitch`.
- `class`/`style` bindings — flag `ngClass`/`ngStyle`.
- No `@HostBinding`/`@HostListener` — must use `host` object.
- `inject()` over constructor DI; services `providedIn: 'root'`, single responsibility.
- `NgOptimizedImage` for static images; Reactive forms over template-driven.
- Lazy loading for feature routes.

### C. TypeScript quality
- Strict typing; no `any` (require `unknown` when uncertain). Flag unsafe casts (`as`).
- Prefer inference when obvious; interfaces for contracts.
- Pure functions returning new objects; declarative over imperative; KISS.
- Factory functions over direct `new` where it improves testability/composition.
- Naming: PascalCase types/classes, camelCase vars/functions.

### D. RxJS & memory safety
- Every subscription cleaned up (prefer `async` pipe / `takeUntilDestroyed`).
- No nested subscribes — use higher-order operators (`switchMap`, `mergeMap`, etc.).
- Correct flattening operator chosen for the concurrency semantics.
- `@BREAKING`-flag any `tap()` with side effects on shared state.
- No shared mutable subjects leaking state; cold vs hot streams understood.

### E. Tauri / native boundary
- `invoke` calls: validated args, typed return, error handling around IPC.
- No secrets or FS paths hardcoded; permission scope respected.
- Blocking work kept off the UI thread; large payloads streamed, not buffered.

### F. Security
- Input validation/sanitization; no `innerHTML`/bypassSecurityTrust without cause.
- No secrets/tokens/keys committed; no PII in logs.
- Path traversal, injection, and unsafe deserialization in Tauri commands.

### G. Performance
- Unnecessary re-renders (missing `OnPush`, unstable references in templates).
- `computed`/memoization where recomputation is expensive.
- N+1 IO/IPC calls, large synchronous loops, unbounded caches, leaks.
- Bundle impact: heavy imports, missing lazy loading.

### H. Accessibility & UX (templates)
- Semantic elements, labels, roles, keyboard nav, focus management, aria-*.
- Color-contrast-dependent info, alt text on images.

### I. Error handling & resilience
- User-facing failures handled gracefully; no silent catches swallowing errors.
- Retry/timeout/fallback where external IO can fail.

### J. Maintainability & structure
- Single responsibility; small focused units; no dead/duplicate code (reuse existing).
- Clear naming; no magic numbers; sensible module boundaries.
- Project annotations present: new code `@REVIEW`, deprecated `@NOT-NEED`,
  side effects `@BREAKING`. Note: source code comments are banned (TODO allowed).

### K. Tests
- Do NOT write or run tests (project rule). Instead, list what SHOULD be tested and the
  key edge cases a reviewer would want covered.

## 3. Output format

Produce the report in this exact structure:

```
# Code Review — <target>

## Summary
<2-4 sentences: overall quality, ship-readiness, biggest risk>

## Verdict
<APPROVE | APPROVE WITH NITS | REQUEST CHANGES | BLOCK> — one-line justification

## Findings
### 🔴 Critical (must fix before merge)
- [file:line] <issue> → <fix>
### 🟠 Major (should fix)
- ...
### 🟡 Minor / Nits
- ...
### 🟢 Positive (call out good work)
- ...

## Rule Compliance (CLAUDE.md / AGENTS.md)
- ✅ / ❌ per relevant rule with note

## Suggested Tests (do not write them)
- <case>

## Follow-ups / Tech Debt
- <item>
```

## 4. Discipline

- If a finding is uncertain, label it `(needs verification)` and say how to verify.
- Never invent issues to look thorough; never hide real ones to seem agreeable.
- Prefix any shell command with `rtk`. Use serena MCP for all code navigation.
- Do NOT modify code, commit, push, or write tests during a review.
