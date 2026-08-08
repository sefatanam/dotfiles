# pi (coding agent) dotfiles

Portable pi setup: extensions, prompt templates, skills, and a settings template.
Machine-specific state (auth, sessions, logs, caches, live settings.json) is git-ignored.

## What's tracked
```
.pi/agent/extensions/lazy-mcp          # on-demand serena/context7 MCP bridge
.pi/agent/extensions/ponytail          # ponytail pi-extension (self-contained: pi-extension + hooks)
.pi/agent/prompts/*.md                 # /load-rules /review* /setup-mcp
.pi/agent/skills/graphify              # graphify skill
.pi/agent/settings.template.json       # portable settings (merged, not symlinked)
```

## New machine
```bash
cd ~/.dotfiles/stow-packages
stow --no-folding -t ~ pi          # symlink extensions/prompts/skills into ~/.pi/agent
./pi/bootstrap-pi.sh               # seed/merge settings.json + install graphify CLI
pi list                            # confirm extensions load
```

## Notes
- `--no-folding` keeps pi's own dirs (auth, sessions) real while symlinking ours.
- settings.json is merged (not symlinked) so machine-local keys survive.
- Re-sync graphify skill after CLI upgrade: `graphify pi install`.
