# tuicr — code review TUI

A terminal code-review UI: read a diff like a GitHub PR, leave typed comments, export them
to the clipboard or push them to the forge.

| File | Installed as | Purpose |
|---|---|---|
| `config.toml` | `~/.config/tuicr/config.toml` | Theme, diff view, editor, and the comment types |
| `themes/` *(none yet)* | `~/.config/tuicr/themes/` | Drop local `.toml` themes here; tuicr resolves bundled names first |

---

## 1. How this is wired

Same two-hop pattern as the rest of the repo. The `shell` package holds one symlink for the
whole directory — not per file — so a future `themes/` folder comes along for free:

```
~/.dotfiles/stow-packages/shell/.config/tuicr -> ../../../tuicr
```

Stowing `shell` creates the outer hop:

```
~/.config/tuicr -> ~/.dotfiles/stow-packages/shell/.config/tuicr -> ~/.dotfiles/tuicr/
```

Editing `tuicr/config.toml` here takes effect on the next tuicr launch — no restow, no copy.

```bash
cd ~/.dotfiles/stow-packages
stow -t ~ shell        # install
stow -R -t ~ shell     # restow after adding/removing files in the package
stow -D -t ~ shell     # remove
```

## 2. Comment types

The point of this config. Without `comment_types` every comment is untyped; defining it
**replaces** the default behaviour, so only these three (plus an always-present `None`) exist:

| Tab cycle | Color | Means |
|---|---|---|
| `NOTE` *(default)* | blue | context or an observation; no action required |
| `SUGGESTION` | yellow | an optional improvement the author may take or leave |
| `ISSUE` | red | a problem that must be fixed before merge |
| `None` | — | untyped; always appended, can't be removed |

Rules worth knowing:

- `label` is omitted on purpose — it defaults to the `id` **uppercased**, which is exactly
  the `NOTE` / `SUGGESTION` / `ISSUE` we want.
- **Order matters**: the first entry is the preselected type. `note` is first so the
  low-stakes option is the default.
- `definition` is not decoration — it shows in the exported legend and is the guidance handed
  to an LLM asked to act on the review.
- `[forge] comment_type_prefix = true` prefixes submitted PR comments with `[ISSUE]` etc.
- A bad entry warns on startup and is skipped; if *every* entry is invalid tuicr silently
  falls back to `None` only. Check with:

  ```bash
  tuicr review add --session /dev/null --type zzz x
  # Warning: comment type 'zzz' is not configured; known types: note, suggestion, issue
  ```

## 3. Installing the binary

`brew/Brewfile` already carries the tap and formula:

```ruby
tap "agavra/tap"
brew "agavra/tap/tuicr", trusted: true
```

> **Heads up:** the binary currently on `PATH` is `~/.local/bin/tuicr`, put there by
> `tuicr update` (or `tuicr.dev/install.sh`), **not** by Homebrew. `brew bundle` will install
> a second copy under `/opt/homebrew/bin` that `~/.local/bin` shadows. Pick one: either drop
> the Brewfile line and keep self-updating with `tuicr update`, or `rm ~/.local/bin/tuicr`
> and let brew own it.

## 4. Reference

Full key list, theme precedence, and `.tuicrignore` rules:
<https://github.com/agavra/tuicr/blob/main/docs/CONFIG.md>
