---
description: Load rules from a markdown file (plus CLAUDE.md & AGENTS.md) and follow them strictly for the rest of the session
argument-hint: "[rules-file-or-name]"
---
You are being asked to load a set of rules and treat them as **binding, non-negotiable
instructions** for the remainder of this session.

## Target to load

Requested ruleset: `${@:-CLAUDE.md}`

Resolve the requested name in this order (use the first that exists):
1. `${1}` as a literal path
2. `./.pi/rules/${1}.md`
3. `./.claude/rules/${1}.md`
4. `./rules/${1}.md`
5. `./${1}.md`

If no argument was given, load only the base rules below.
If a name was given but no file matches, list candidate `*.md` rule files with `ls`
and ask which to use. Do NOT invent rules.

## Always-on base rules (load FIRST, every time)

Before the requested file, always read and treat as binding:
1. `./CLAUDE.md` (repo root) — mandatory project rules.
2. `./AGENTS.md` and `~/.claude/CLAUDE.md` if present — global engineering standards.

These base rules are ALWAYS active regardless of the argument.

## Steps

1. Read the base rule files (`CLAUDE.md`, `AGENTS.md`) with the read tool.
2. Read the resolved requested file (use `rtk read` for large files).
3. If a requested file is missing, list candidates and stop for confirmation.
4. Produce a numbered summary grouped by source: `[CLAUDE.md]`, `[AGENTS.md]`,
   `[${1:-none}]`, so the rules can be confirmed.
5. Treat every rule as an active constraint on all code you read, write, or edit.
   - Precedence on conflict: `CLAUDE.md` > `AGENTS.md` > requested file.
     A stricter / safety rule always wins.
   - If a rule conflicts with a later request, STOP and flag it — never silently break it.
6. End with: `✅ Rules loaded and active: CLAUDE.md + AGENTS.md + ${1:-none}`

## Reminders while active

- Mark new code `@REVIEW`, deprecate with `@NOT-NEED`, flag side effects `@BREAKING`.
- Prefix shell commands with `rtk`. Use serena MCP for code navigation.
- Never violate a loaded rule for convenience. Ask first.
