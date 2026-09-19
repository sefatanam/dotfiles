# Git — global configuration wiki

Everything in this folder and what every single key in [`gitconfig`](gitconfig) actually does.

| File | Installed as | Purpose |
|---|---|---|
| `gitconfig` | `~/.gitconfig` | The global git configuration — applies to **every** repo on this machine |
| `gitignore` | `~/.gitignore_global` | Patterns ignored in every repo, without touching each repo's `.gitignore` |
| `hooks/` | *(not installed globally)* | Hooks for **this dotfiles repo only** — see [Hooks](#hooks) |

---

## 1. How this is wired

GNU Stow owns the symlinks. The `git` package contains nothing but two links back into this folder:

```
~/.dotfiles/stow-packages/git/
  .gitconfig        -> ../../git/gitconfig
  .gitignore_global -> ../../git/gitignore
```

Stowing it creates the second hop, from your home directory into the package:

```
~/.gitconfig        -> .dotfiles/stow-packages/git/.gitconfig        -> ~/.dotfiles/git/gitconfig
~/.gitignore_global -> .dotfiles/stow-packages/git/.gitignore_global -> ~/.dotfiles/git/gitignore
```

So editing `git/gitconfig` in this repo changes your global git config immediately — no restow,
no copy step.

### Install / update / remove

```bash
cd ~/.dotfiles/stow-packages

stow -t ~ git        # install
stow -R -t ~ git     # restow (after adding/removing files in the package)
stow -D -t ~ git     # remove — deletes the symlinks, leaves this repo untouched
```

`./setup.sh` does this for you; `git` is listed in `STOW_PACKAGES` alongside `shell` and `editor`.

### First install on a machine that already has a `~/.gitconfig`

Stow refuses to overwrite a **regular file**, and `setup.sh` runs under `set -e`, so it will abort.
Back the old one up and remove it first:

```bash
cp ~/.gitconfig ~/.gitconfig.pre-stow.bak
git config --global --list      # note anything worth keeping, add it to git/gitconfig
rm ~/.gitconfig
cd ~/.dotfiles/stow-packages && stow -t ~ git
```

Do **not** reach for `stow --adopt` here. Adopt moves the *existing* `~/.gitconfig` into the
package and overwrites the repo's version — the opposite of what you want.

### Writes through the symlink land in this repo

Git resolves symlinks before rewriting a config file, so `git config --global user.email ...`
edits `~/.dotfiles/git/gitconfig` in place and leaves the symlink intact. Handy, but it means
**ad-hoc global config changes show up as uncommitted changes in this repo** — check
`git -C ~/.dotfiles status` if a setting appears out of nowhere.

---

## 2. Where git config lives, and who wins

Git reads several files in order; for a single-valued key, **the last one read wins**.

| Scope | File | Flag |
|---|---|---|
| System | `/opt/homebrew/etc/gitconfig` (Homebrew git) | `git config --system` |
| Global (this file) | `~/.gitconfig`, or `~/.config/git/config` if it exists | `git config --global` |
| Local | `<repo>/.git/config` | `git config --local` |
| Worktree | `<repo>/.git/config.worktree` | `git config --worktree` |
| One-off | — | `git -c key=value <cmd>` |

Inspect what is actually in effect and where it came from:

```bash
git config --list --show-origin      # every key, with the file it came from
git config --list --show-scope       # every key, with system/global/local
git config --get-all credential.helper   # multi-valued keys: see the whole list
```

Two rules that bite:

- **Last value wins inside one file too.** A second `[core]` section further down silently
  overrides the first. This config used to set `autocrlf = input` at the top and `autocrlf = false`
  140 lines later — `false` was the one that counted. Sections are now merged, one per file.
- **A few keys accumulate instead of overriding.** Multi-valued keys such as `credential.helper`,
  `http.extraHeader` and `remote.*.fetch` build a *list* across scopes: a value set here is **added
  to** what the system file already set, not a replacement for it. Setting an empty value
  (`helper =`) resets the list. See [`[credential]`](#credential) below for why that matters here.

---

## 3. Key-by-key reference

### `[user]`

| Key | Value | What it does |
|---|---|---|
| `name` | `Sefat Anam` | Author/committer name stamped into every commit you make. |
| `email` | `sefatanam@gmail.com` | Author/committer email. GitHub matches commits to your account by this address. |

Both are baked into commit objects permanently — changing them later does not rewrite history.
For a different identity per directory (e.g. work), use the `includeIf` block at the bottom of the
config rather than editing these.

### `[core]`

| Key | Value | What it does |
|---|---|---|
| `autocrlf` | `input` | Converts CRLF → LF when *committing*, and does nothing on checkout. The right setting for macOS/Linux: the repo stays LF-only even if a file arrives with Windows line endings. (`true` is for Windows; `false` disables conversion entirely.) |
| `editor` | `vim` | Editor launched for commit messages, interactive rebase todo lists, `git config --edit`. Overridden by `$GIT_EDITOR` if set. |
| `excludesfile` | `~/.gitignore_global` | Path to the global ignore file — the `gitignore` in this folder. Applies to every repo *in addition to* each repo's own `.gitignore`. |

`core.hooksPath` is deliberately **not** set here. See [Hooks](#hooks).

### `[init]`

| Key | Value | What it does |
|---|---|---|
| `defaultBranch` | `main` | Branch name `git init` creates. Only affects new repos; it renames nothing. |

### `[gpg]`, `[gpg "ssh"]`, `[commit]`, `[tag]` — signing

Signing is currently **off**; these keys just pre-wire it.

| Key | Value | What it does |
|---|---|---|
| `gpg.program` | `gpg` | Binary used to create/verify OpenPGP signatures. |
| `gpg.format` | `openpgp` | Signature format. Alternatives: `ssh` (sign with an SSH key — much simpler on GitHub) or `x509`. |
| `gpg.ssh.program` | `ssh-keygen` | The binary used when `gpg.format = ssh`. Inert while the format is `openpgp`. |
| `gpg.ssh.allowedSignersFile` | `""` (empty) | File mapping emails → SSH public keys, used to *verify* SSH-signed commits. Empty means `git log --show-signature` cannot verify anyone; harmless while signing is off. |
| `commit.gpgSign` | `false` | Don't sign every commit automatically. `git commit -S` still signs one on demand. |
| `tag.forceSignAnnotated` | `false` | Don't force annotated tags (`git tag -a`) to be signed. |

To switch to SSH signing later: set `gpg.format = ssh`, `user.signingkey = ~/.ssh/id_ed25519.pub`,
`commit.gpgSign = true`, and point `allowedSignersFile` at a real file.

### `[diff]`, `[difftool "vscode"]`

| Key | Value | What it does |
|---|---|---|
| `diff.tool` | `vscode` | Which tool `git difftool` opens. Plain `git diff` is unaffected. |
| `diff.mnemonicprefix` | `true` | Labels diff sides with mnemonic letters — `i/` index, `w/` working tree, `c/` commit, `o/` object — instead of `a/` and `b/`. Easier to read; note patches you export look different. `git apply` copes (it strips one path component), but a tool that hard-codes `a/`…`b/` may not — pass `-c diff.mnemonicprefix=false` when generating a patch for such a tool. |
| `diff.algorithm` | `patience` | Diff algorithm. Patience produces far more readable hunks than the default `myers` when blocks of code move or braces line up, at a small speed cost. |
| `difftool.vscode.cmd` | `code --wait --diff "$LOCAL" "$REMOTE"` | The exact command run for `git difftool`. `--wait` blocks git until the VS Code tab is closed; `$LOCAL`/`$REMOTE` are the temp files git hands the tool. **Both operands are required** — without them VS Code opens with nothing. |

### `[merge]`, `[mergetool]`

| Key | Value | What it does |
|---|---|---|
| `merge.tool` | `nvimdiff` | Tool launched by `git mergetool` to resolve conflicts — Neovim in a 3-pane LOCAL/MERGED/REMOTE layout. Built into git; run `git mergetool --tool-help` for every available backend. (Was `mvimdiff`, which needs MacVim — not installed here, so merges failed.) |
| `merge.summary` | `true` | Print a diffstat summary after a merge. This is the **old name**; modern git calls it `merge.stat`. Still honored, but `merge.stat = true` is the spelling to prefer. |
| `merge.verbosity` | `1` | How chatty the merge machinery is: `0` only errors, `1` conflicts + skipped paths, `2` (default) also "Merging…" lines, `5` full debug. `1` keeps merge output short. |
| `mergetool.prompt` | `false` | Skip the "Hit return to launch <tool>" confirmation before each conflicted file. |

### `[rerere]`

| Key | Value | What it does |
|---|---|---|
| `enabled` | `true` | **Re**use **re**corded **re**solution. Git records how you resolved each conflict hunk, and replays that resolution automatically the next time the identical conflict appears. Pays for itself on long-lived branches and repeated rebases. Recordings live in `.git/rr-cache/` per repo; `git rerere forget <path>` drops a bad one. |

### `[credential]`

Currently **commented out**, on purpose.

`credential.helper` is a *list*, not a single value — a helper set here is **added to** whatever the
system config already set, not a replacement for it. Homebrew's `/opt/homebrew/etc/gitconfig`
already ships:

```
credential.helper = osxkeychain
```

so enabling `helper = store` globally would leave **both** active: git would keep using the macOS
Keychain *and* additionally write your tokens as plaintext into `~/.git-credentials`. That is a
downgrade, so the block stays disabled and the Keychain remains the only helper.

```bash
git config --get-all credential.helper   # confirm: should print osxkeychain, and nothing else
```

If you ever do need `store` (a headless Linux box, say), reset the inherited list first:

```ini
[credential]
	helper =          # empty value clears everything inherited
	helper = store
```

### `[color]`, `[color "branch"]`, `[color "diff"]`

| Key | Value | What it does |
|---|---|---|
| `color.ui` | `true` | Master switch for colored output. Behaves like `auto`: colors when writing to a terminal, plain text when piped or redirected, so it never corrupts scripts. |
| `color.branch.current` | `yellow reverse` | The checked-out branch in `git branch` — yellow with foreground/background swapped. |
| `color.branch.local` | `yellow` | Other local branches. |
| `color.branch.remote` | `green` | Remote-tracking branches (`git branch -r`). |
| `color.diff.meta` | `yellow bold` | Diff metadata lines (`diff --git …`, `index abc123..def456`). |
| `color.diff.frag` | `magenta bold` | Hunk headers (`@@ -12,7 +12,9 @@`). |
| `color.diff.old` | `red` | Removed lines. |
| `color.diff.new` | `green` | Added lines. |

Slot syntax is `<foreground> [background] [attr…]`, where attributes include `bold`, `dim`,
`italic`, `ul`, `reverse`.

### `[format]`

| Key | Value |
|---|---|
| `pretty` | `format:%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset` |

The default output shape for `git log` (and anything that doesn't pass its own `--pretty`).
Decoded:

| Token | Meaning |
|---|---|
| `%C(blue)` / `%C(yellow)` / `%C(green)` / `%C(magenta)` | Start coloring in that color |
| `%Creset` | Stop coloring |
| `%ad` | Author date, formatted per `--date=` (the `l` alias passes `--date=short` → `2026-09-19`) |
| `%h` | Abbreviated commit hash |
| `%d` | Ref decorations — `(HEAD -> main, origin/main)` |
| `%s` | Commit subject (first line of the message) |
| `%an` | Author name |

Renders as: `2026-09-19 42ee38b (HEAD -> main) first commit  [Sefat Anam]`

Quirk worth knowing: `format:` puts a separator *between* entries but no newline after the last
one, so the final log line can run into your shell prompt. Change the prefix to `tformat:` (a
*terminator* format) if that bothers you.

### `[apply]`

| Key | Value | What it does |
|---|---|---|
| `whitespace` | `nowarn` | `git apply` won't warn about or fix whitespace errors in a patch. Keeps output quiet when applying patches from elsewhere. (`warn`, `fix`, `error` are the alternatives.) |

### `[branch]`

| Key | Value | What it does |
|---|---|---|
| `autosetupmerge` | `true` | When you branch off a **remote-tracking** branch, record it as the upstream automatically, so bare `git pull`/`git push`/`git status` ahead-behind counts work. (`always` would also track local branches.) |
| `sort` | `-committerdate` | Default ordering for `git branch` — most recently committed first instead of alphabetical. The leading `-` means descending. |

### `[push]`

| Key | Value | What it does |
|---|---|---|
| `default` | `upstream` | Bare `git push` pushes the current branch to **its configured upstream branch, even if the remote branch has a different name**. |

Compare: git's own default is `simple`, which does the same thing but *refuses* when the local and
remote names differ — a guardrail against pushing `feature-x` onto `main` after a rename. `upstream`
is more permissive; switch to `simple` if you want the safety net, or `current` to always push to a
same-named remote branch.

### `[pull]`

| Key | Value | What it does |
|---|---|---|
| `rebase` | `true` | `git pull` rebases your local commits on top of the fetched ones instead of creating a merge commit. Keeps history linear. Conflicts surface as a rebase — resolve, then `git rc` (`rebase --continue`). Use `git pull --no-rebase` for a one-off merge. |

### `[fetch]`

| Key | Value | What it does |
|---|---|---|
| `prune` | `true` | Every fetch/pull deletes local remote-tracking refs whose upstream branch is gone. Without it, `origin/some-merged-pr` lingers in `git branch -r` forever. Only touches `origin/*` refs — your local branches are never deleted. |

### `[advice]`

| Key | Value | What it does |
|---|---|---|
| `statusHints` | `false` | Hides the "(use `git restore --staged <file>`…)" tutorial blocks from `git status`, `git checkout` and friends. Much shorter status output. |

### `[column]`

| Key | Value | What it does |
|---|---|---|
| `ui` | `auto` | Print list output (`git branch`, `git tag`, untracked files in `git status`) in multiple columns when attached to a terminal wide enough, single-column when piped. |

### `[filter "lfs"]`

Git LFS registration. A *filter driver* transforms file contents as they cross between the working
tree and the object database; LFS uses it to swap huge binaries for small pointer files.

| Key | Value | What it does |
|---|---|---|
| `clean` | `git-lfs clean -- %f` | Working tree → repo. Uploads/stores the real bytes and commits a pointer file in their place. |
| `smudge` | `git-lfs smudge -- %f` | Repo → working tree. Expands a pointer back into the real file on checkout. |
| `process` | `git-lfs filter-process` | A single long-running process replacing per-file `clean`/`smudge` invocations. Much faster on big checkouts; git prefers it when present. |
| `required` | `true` | If `git-lfs` is missing or fails, **abort** instead of silently committing/checking out pointer text. Without this you get repos full of one-line `version https://git-lfs...` files. |

This only activates in repos with a `.gitattributes` marking paths as LFS-managed — it costs nothing
elsewhere. It does mean `git-lfs` must stay installed (`brew install git-lfs`); it is in the Brewfile.

### `[includeIf]` (commented)

```ini
# [includeIf "gitdir:~/work/"]
#  path = ~/.gitconfig.work
```

Conditional include: everything in `~/.gitconfig.work` applies only to repos under `~/work/`.
The standard way to use a work email in work repos without touching `[user]` here. The trailing
slash matters — it means "this directory and everything under it". Other conditions:
`gitdir/i:` (case-insensitive), `onbranch:`, `hasconfig:remote.*.url:`.

---

## 4. Alias reference

All defined under `[alias]`. Aliases beginning with `!` run as shell commands **from the repository
root**, not from your current directory; the rest are plain git sub-command expansions.

**Staging**

| Alias | Expands to | Notes |
|---|---|---|
| `a` | `add` | |
| `chunkyadd` | `add --patch` | Stage hunk by hunk, interactively |
| `unstage` | `reset HEAD` | Unstage a file, keep the edit |

**Committing**

| Alias | Expands to | Notes |
|---|---|---|
| `c` | `commit -m` | `git c "message"` |
| `ca` | `commit -am` | Stage all *tracked* changes and commit |
| `ci` | `commit` | Opens the editor |
| `amend` / `ammend` | `commit --amend` | Both spellings are defined — the misspelling is intentional insurance |
| `uncommit` | `reset --soft HEAD^` | Undo the last commit, keep its changes staged |

**Branching & switching**

| Alias | Expands to | Notes |
|---|---|---|
| `b` | `branch -v` | Branches with their tip commit |
| `co` | `checkout` | |
| `nb` | `checkout -b` | "new branch" |
| `recent-branches` | `!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'` | 15 most recently touched local branches |

**Inspecting**

| Alias | Expands to | Notes |
|---|---|---|
| `s` / `st` / `stat` | `status` | Three spellings of the same thing |
| `d` | `diff` | Unstaged changes |
| `dc` | `diff --cached` | Staged changes |
| `last` | `diff HEAD^` | What the last commit changed |
| `l` | `log --graph --date=short` | Graph log using the `[format] pretty` string above |
| `changes` | `log --pretty="%h %cr %cn %Cgreen%s%Creset" --name-status` | Log with the files each commit touched |
| `short` | `log --pretty="%h %cr %cn %Cgreen%s%Creset"` | One line per commit |
| `simple` | `log --pretty=" * %s"` | Bulleted subjects — good for changelogs |
| `shortnocolor` | `log --pretty="%h %cr %cn %s"` | Same as `short`, pipe-safe |
| `filelog` | `log -u` | Log with patches (`-u` = `--patch`) |
| `contributors` | `shortlog --summary --numbered --email` | Commit counts per author |
| `r` | `remote -v` | Remotes with URLs |
| `t` | `tag -n` | Tags with their messages |

**Stashing**

| Alias | Expands to | Notes |
|---|---|---|
| `ss` | `stash` | |
| `sl` | `stash list` | |
| `sa` | `stash apply` | Restore, keeping the stash entry |
| `sd` | `stash drop` | **Destructive** — deletes a stash entry |
| `snapshot` | `!git stash save "snapshot: $(date)" && git stash apply "stash@{0}"` | Timestamped safety copy into the stash while *keeping* your working tree |
| `snapshots` | `!git stash list --grep snapshot` | List only those snapshots |

**Merging, rebasing, cherry-picking**

| Alias | Expands to | Notes |
|---|---|---|
| `mt` | `mergetool` | Launches `nvimdiff` |
| `rc` | `rebase --continue` | |
| `rs` | `rebase --skip` | |
| `cp` | `cherry-pick -x` | `-x` appends "(cherry picked from …)" to the message — keeps provenance |

**Syncing**

| Alias | Expands to |
|---|---|
| `pl` | `pull` (rebases, per `pull.rebase`) |
| `ps` | `push` (to upstream, per `push.default`) |

**Patches**

| Alias | What it does |
|---|---|
| `test-patch` | Writes the last commit's diff (`HEAD~1..HEAD`) to a file. Default name `2026-09-19_143012.patch`; override with `git test-patch myname.patch` |

**Subversion bridges** — legacy, only useful against an SVN remote: `svnr` (`svn rebase`),
`svnd` (`svn dcommit`), `svnl` (`svn log --oneline --show-commit`).

### Twins of the zsh aliases

The shell aliases in `zsh/.local/share/zsh/aliases.zsh` (lines 24-35) exist here under the same
names, so `git gs` works in any shell — bash, a container, a `sh -c` one-liner — not just an
interactive zsh with that file sourced.

| Alias | Expands to | zsh twin |
|---|---|---|
| `gs` | `status` | `gs` |
| `gc` | `commit -m` | `gc` |
| `gl` | `log --oneline` | `gl` |
| `grh` | `reset --hard` | `grh` — **destructive**, discards every uncommitted change |
| `gts` | `stash` | `gts` |
| `gtp` | `stash pop` | `gtp` |
| `gcll` | `config --local --list` | `gcll` |
| `grp` | `remote prune origin` | `grp` |
| `gp` | stash → `pull --rebase` → restore | `gp` (hardened, see below) |
| `gcn` | `config --local user.name "$GIT_NAME"` | `gcn` (guarded) |
| `gce` | `config --local user.email "$GIT_EMAIL"` | `gce` (guarded) |

**`gP` is deliberately absent.** Git config variable names are **case-insensitive**, so `alias.gP`
and `alias.gp` are the same key — defining both leaves whichever comes last, silently:

```console
$ git config --get alias.gp    # with both gp and gP in the file
push                           # the gp definition is simply gone
```

Your shell has no such restriction, which is why `gs`/`gP` coexist happily in `aliases.zsh`. On the
git side, push is `git ps`.

**`gp` is hardened against a stash bug.** The shell version is
`git stash && git pull --rebase && git stash pop`, but `git stash` on a clean tree still **succeeds**
(it just prints "No local changes to save"), so the trailing `pop` applies whatever happens to be at
`stash@{0}` — a stash from last week, silently, onto an unrelated branch. The git alias records
whether *this run* stashed anything and pops only then, so a clean tree is left alone. It also
labels its stash (`gp <timestamp>`) so it's identifiable if a rebase conflict interrupts the pop.

**`gcn` / `gce` refuse to write an empty value.** They read `$GIT_NAME` / `$GIT_EMAIL`, exported by
`zsh/private`. If the variable is unset — a non-interactive shell, a machine where `private` was
never filled in — the plain version would set `user.name` to the empty string and break committing
in that repo with a confusing error. These print what's missing and exit 1 instead.

---

## 5. The global ignore file

[`gitignore`](gitignore) → `~/.gitignore_global`, referenced by `core.excludesfile`.

It exists so machine-level and tool-level noise never has to be added to a project's `.gitignore`
(which is shared with everyone else on that project). It covers:

- **macOS cruft** — `.DS_Store`, `.AppleDouble`, `.LSOverride`, `Icon`, `._*`, `.Spotlight-V100`, `.Trashes`
- **Editor / tooling state** — `tags`, `vendor-tags`, `.lvimrc`, `.projections.json`, `.phpactor.json`, `.rgignore`, `_ide_helper.php`
- **AI agent state** — `**/.claude`, `**/CLAUDE.md`, `**/AGENTS.md`, `**/.agents`, `**/.superpowers`, `**/.mcp.json`, `**/docs/agents`, `**/tasks/*.md`, `**/.serena`, `**/.rtk`, `**/graft`, `**/graphify-out`, `skills-lock.json`
- **Editor swap / backup files** — `*.swp`, `*.swo`, `*.swn`, `*~`, `.*.sw[a-p]`. The last pattern is the one that matters: vim names the swap for `gitconfig` as **`.gitconfig.swp`**, a dotfile, which `*.swp` alone does not match.
- **Secrets-adjacent** — `.ssh`, `__ignored`

Two things to keep in mind: a global ignore is invisible to your collaborators, so anything the
*project* needs ignored belongs in the project's own `.gitignore`; and ignore rules never apply to
already-tracked files — use `git rm --cached <path>` for those.

```bash
git check-ignore -v <path>    # which rule, in which file, is ignoring this?
```

---

## 6. Hooks

`git/hooks/` holds hooks for **this dotfiles repository only**. They are wired up by a *local*
setting in `~/.dotfiles/.git/config`:

```ini
[core]
	hooksPath = git/hooks
```

`.git/config` is never version-controlled, so a fresh clone starts without that setting and the
hooks silently do nothing. `./setup.sh` re-applies it on every run (`ensure_git_hooks`), which also
restores the executable bit — a hook that isn't `chmod +x` is skipped by git without any warning.
To do it by hand:

```bash
cd ~/.dotfiles
chmod +x git/hooks/*
git config core.hooksPath git/hooks     # local to this repo — never use --global here

git config core.hooksPath                # verify: git/hooks
git rev-parse --git-path hooks           # where git will actually look
git hook run post-commit                 # run one on demand
```

Setting `core.hooksPath` replaces `.git/hooks/` entirely — the `.sample` files still sitting there
are inert, and nothing needs to be copied or symlinked into that directory.

| Hook | What it does |
|---|---|
| `pre-commit` | If `zsh/private` is staged, backs it up to `private.original`, rewrites every `key=value` line to `key=""`, and re-stages it — so secrets never reach a commit. |
| `post-commit` | Restores `zsh/private` from `private.original`, putting your real values back in the working tree. |

`core.hooksPath` is intentionally **not** set in the global config: a global hooks path applies to
every repo you touch, and these hooks are written for this repo's layout (they hard-code
`zsh/private`). Elsewhere they would either error out or interfere with other projects' hooks.
`private.original` is listed in the repo's `.gitignore`, so the plaintext backup is never committed.

---

## 7. Troubleshooting

**`stow: WARNING! stowing git would cause conflicts` / "existing target is not owned by stow"**
`~/.gitconfig` is a real file, not a stow symlink. Back it up and delete it (see
[First install](#first-install-on-a-machine-that-already-has-a-gitconfig)).

**A setting isn't taking effect**
Find who is overriding whom — a local `.git/config` beats the global file, and a later line in a
file beats an earlier one:

```bash
git config --list --show-origin | grep <key>
git config --show-origin --get <key>       # just the winner
```

**Changes to `git/gitconfig` seem to do nothing**
Confirm the link chain is intact: `readlink -f ~/.gitconfig` must print
`/Users/anam/.dotfiles/git/gitconfig`. If it prints something else, restow:
`cd ~/.dotfiles/stow-packages && stow -R -t ~ git`.

**`git difftool` / `git mergetool` opens nothing**
The configured tools must be installed: `code` (VS Code CLI) for diffs, `nvim` for merges.
`git mergetool --tool-help` lists every backend git can find on this machine.

**Everything in a repo shows as modified after cloning on Windows**
That's `core.autocrlf`. This config uses `input`, which is correct for macOS/Linux only — on Windows
the value should be `true`.

**Uncommitted changes appear in `~/.dotfiles/git/gitconfig` on their own**
Something ran `git config --global`. Git writes through the symlink into this repo — review the
diff and either commit it or `git checkout git/gitconfig`.

**Restore the pre-stow global config**

```bash
cd ~/.dotfiles/stow-packages && stow -D -t ~ git
cp ~/.gitconfig.pre-stow.bak ~/.gitconfig
```
