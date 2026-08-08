---
description: Scaffold project-local MCP config (.pi/mcp.json) for serena/context7 — choose which to enable and whether they auto-start
argument-hint: "[serena] [context7] [--auto]"
---
Configure MCP servers **for this project only**, written to `./.pi/mcp.json`. This keeps
setup token-cheap: servers listed here are available to activate with `/serena` /
`/context7`, and only those in `autoStart` spawn automatically at session start.

Requested: `${@:-serena context7}`

## Steps

1. Determine which servers to enable from the arguments (default: `serena context7`).
   - `serena`   → code navigation (uvx, oraios/serena)
   - `context7` → live library docs (npx, @upstash/context7-mcp)
2. Decide auto-start: if `--auto` is present, put the chosen servers in `autoStart`;
   otherwise leave `autoStart` empty (lazy — activate manually to save tokens).
3. Read any existing `./.pi/mcp.json` first and MERGE — do not clobber custom entries.
4. Write `./.pi/mcp.json`. Only include a `servers` block if the user needs to override
   the built-in defaults (command/args/guideline); otherwise omit it and just list names
   in `enabled`/`autoStart` since the extension already knows the defaults.

   Minimal example (lazy, both available, none auto-started):
   ```json
   {
     "autoStart": []
   }
   ```

   Auto-start serena only:
   ```json
   {
     "autoStart": ["serena"]
   }
   ```

   Custom override (e.g. context7 with an API key via env):
   ```json
   {
     "autoStart": [],
     "servers": {
       "context7": {
         "command": "npx",
         "args": ["-y", "@upstash/context7-mcp", "--api-key", "$CONTEXT7_API_KEY"],
         "guideline": "Use context7_* tools for up-to-date library docs."
       }
     }
   }
   ```

5. Remind the user: the project must be **trusted** for `.pi/` to load
   (`/trust` then restart pi), and restart pi so `session_start` picks up the config.
6. Confirm with the final file contents and the activation commands:
   `/serena`, `/context7`, `/mcp-status`, `/mcp-off`.

## Rules

- Do NOT touch global `~/.pi/agent/settings.json` — project scope only.
- Never write real secrets into the file; reference env vars (`$CONTEXT7_API_KEY`).
- Keep it minimal (KISS): prefer name-only lists over full server overrides.
