# tuicr — code review TUI

A terminal code-review UI: read a diff like a GitHub PR, leave typed comments, export them
to the clipboard or push them to the forge.

| File | Installed as | Purpose |
|---|---|---|
| `config.toml` | `~/.config/tuicr/config.toml` | Theme, diff view, editor, and the comment types |
| `themes/` | `~/.config/tuicr/themes/` | The Rosé Pine palette — tuicr bundles no Rosé Pine, so it lives here |

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

## 2. Theme

tuicr's bundled themes are github / catppuccin / gruvbox / nord / tokyo-night / everforest /
solarized / ayu / onedark — **no Rosé Pine**. So the palette is a local theme instead:

| File | Variant | Used as |
|---|---|---|
| `themes/rose-pine.toml` | main (dark) | `theme_dark` |
| `themes/rose-pine-dawn.toml` | dawn (light) | `theme_light` |
| `themes/rose-pine-moon.toml` | moon (dark) | spare — swap into `theme_dark` |

Bundled names resolve first, so a future bundled `rose-pine` would shadow these files; rename
them if that ever happens. A full list of the bundled names comes from any bad name:

```bash
tuicr --theme x            # Error: Unknown theme 'x'. Bundled themes: dark, light, ayu-light, ...
```

Two things keep this in step with the rest of the repo:

- **Diff backgrounds are delta's.** `diff_add_bg` / `diff_del_bg` reuse the exact blends from
  `git/delta-rose-pine.gitconfig`, so a hunk looks the same in tuicr and in `git diff`.
- **The syntax theme is bat's.** `themes/*.tmTheme` are symlinks into `bat/themes/`, so bat,
  delta and tuicr share one file. tuicr loads the `.tmTheme` directly — unlike delta, it does
  **not** need `bat cache --build`.

`appearance = "system"` picks between the two by terminal appearance; `--theme rose-pine-moon`
overrides for one run.

## 3. Comment types

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

## 4. Installing the binary

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

## 5. Reference

Full key list, theme precedence, and `.tuicrignore` rules:
<https://github.com/agavra/tuicr/blob/main/docs/CONFIG.md>
