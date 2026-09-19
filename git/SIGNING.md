# Verified commits on a new machine

How to get the green **Verified** badge on GitHub from a fresh machine, using **SSH signing**
(not GPG). Companion to [`README.md` §3](README.md) — this file is the runbook; the README is
the key-by-key reference.

> **We do not use GPG.** GitHub accepts GPG, SSH, and S/MIME signatures. This setup uses SSH,
> so there is no `gpg` binary, no keyring, and no key expiry to manage. If GitHub tells you to
> "add a GPG key", that is its generic wording for *"this signature came from a key I don't
> recognise"* — the fix is a signing key, not GPG. See [Troubleshooting](#troubleshooting).

---

## What has to be true

Four things, all required. Three are already in this repo; only the last is per-machine manual work.

| # | Requirement | Who provides it |
|---|---|---|
| 1 | Git ≥ 2.34 (SSH signing support) | the machine |
| 2 | Signing config in `~/.gitconfig` | **this repo** — `stow` handles it |
| 3 | An SSH keypair on disk at `~/.ssh/id_ed25519` | you, per machine |
| 4 | That public key registered on GitHub **as a Signing Key** | you, per machine |

Steps 3 and 4 are the whole job. Everything else comes down the stow symlink.

---

## Step 1 — Check git is new enough

```bash
git --version          # need >= 2.34
```

On macOS, if this is Apple's bundled git and too old: `brew install git`, then restart the shell.

---

## Step 2 — Stow the git package

```bash
cd ~/.dotfiles/stow-packages
stow -t ~ git
```

This links `~/.gitconfig` into this repo, which brings the signing config with it:

```gitconfig
[user]
	signingkey = ~/.ssh/id_ed25519.pub

[gpg]
	format = ssh

[gpg "ssh"]
	allowedSignersFile = ~/.ssh/allowed_signers

[commit]
	gpgsign = true

[tag]
	gpgsign = true
```

Confirm it landed:

```bash
git config --get-regexp 'user\.signingkey|gpg\.|commit\.gpgsign'
```

---

## Step 3 — Get the SSH key onto the machine

**Either** reuse an existing key (copy `id_ed25519` *and* `id_ed25519.pub` over a trusted
channel — never paste the private key into a chat, an issue, or a web form):

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Or** generate a fresh one for this machine (preferred — one key per machine means you can
revoke a single laptop without touching the others):

```bash
ssh-keygen -t ed25519 -C "sefatanam@gmail.com"
```

Accept the default path `~/.ssh/id_ed25519`. A passphrase is recommended; on macOS add it to
the keychain so you are not prompted on every commit:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

---

## Step 4 — Create the allowed signers file

This is what lets **your own machine** verify signatures (`git log --show-signature`). It is
purely local — GitHub never reads it — but without it every `git log` prints
`gpg.ssh.allowedSignersFile needs to be configured and exist`.

```bash
printf '%s %s\n' "sefatanam@gmail.com" "$(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
chmod 600 ~/.ssh/allowed_signers
```

The format is `<email> <key-type> <key-body>`, one entry per line. Add a line for **every**
machine key you sign with, otherwise commits from your other laptops read as unverified locally.

---

## Step 5 — Register the key on GitHub as a *Signing Key*

**This is the step everyone misses.** GitHub keeps two separate lists on the same settings page:

| List | Purpose | Enables |
|---|---|---|
| **Authentication keys** | proves who you are when you `git push` | pushing over SSH |
| **Signing keys** | attributes a commit signature to you | the **Verified** badge |

A key in the authentication list does **not** count as a signing key, even though it is the
same key material. You must add it a second time, with the type set to signing.

### Via the web UI

1. **Settings → SSH and GPG keys → New SSH key**
2. Set **Key type: `Signing Key`** ← the entire fix lives in this dropdown
3. Paste the contents of `~/.ssh/id_ed25519.pub`

### Via the CLI

The `gh` token needs a scope it does not carry by default:

```bash
gh auth refresh -h github.com -s admin:ssh_signing_key
```

Then post the key **from a file**, never inline:

```bash
python3 -c "
import json
k = open('$HOME/.ssh/id_ed25519.pub').read().strip()
json.dump({'title': 'Macbook', 'key': k}, open('/tmp/signing-key.json','w'))
"
gh api --method POST /user/ssh_signing_keys --input /tmp/signing-key.json
```

> **Why from a file?** The obvious one-liner —
> `gh api ... -f key="$(cat ~/.ssh/id_ed25519.pub)"` — is fine when *typed*, but breaks when the
> command is **pasted from a rendered web page or notes app**: the clipboard carries HTML, spaces
> at line breaks become newlines, and a hyperlinked email arrives with a `mailto:` copy glued on.
> GitHub then rejects it with `422 Invalid property /key: ... does not match /^ssh-(rsa|dss|ed25519) /`.
> Routing through a file keeps the key bytes off the command line entirely.

Confirm it registered:

```bash
gh api /user/ssh_signing_keys --jq '.[] | "\(.id)  \(.title)"'
```

---

## Step 6 — Verify end to end

```bash
cd ~/.dotfiles
git commit --allow-empty -m "test: signing check"
git log --format='%h %G? %GS  %s' -1
```

Read the `%G?` column:

| Code | Meaning |
|---|---|
| `G` | **Good signature** — you are done |
| `N` | No signature — `commit.gpgsign` is not applying, see Step 2 |
| `U` / error | Signed, but unverifiable locally — `allowed_signers` is missing or wrong, see Step 4 |

Then push and check the badge on github.com. Drop the test commit with
`git reset --hard HEAD~1` if you pushed nothing.

---

## Troubleshooting

### "Unverified" on GitHub, but `%G?` is `G` locally

The signature is valid; GitHub just cannot attribute it. In order of likelihood:

1. **The key is only an authentication key.** The overwhelmingly common cause — redo Step 5 and
   check the key actually appears in `gh api /user/ssh_signing_keys`, not just `gh api /user/keys`.
2. **The committer email is not verified on the account.** GitHub only attributes a signature to
   you if the commit's email is a confirmed address. Check under **Settings → Emails**, and check
   what the commit carries with `git log --format='%ae' -1`.
3. **A per-repo override.** A repo-local `user.email` silently beats the global one:
   `git config --show-origin --get user.email`.

### GitHub says "add a GPG key"

Generic wording, not an instruction. Confirm you are on the SSH path with
`git config gpg.format` (should print `ssh`) and do Step 5. Installing GPG will not help.

### `error: gpg.ssh.allowedSignersFile needs to be configured and exist`

Local verification only — your commits are still being signed correctly and GitHub is unaffected.
Do Step 4.

### `error: Load key "...": invalid format` when committing

`user.signingkey` is pointing at the **private** key or a missing file. It must be the `.pub`:

```bash
git config --get user.signingkey    # expect ~/.ssh/id_ed25519.pub
ls -l ~/.ssh/id_ed25519.pub
```

### Old commits still show Unverified

Expected. A signature is baked into the commit object, so commits made *before* signing was
enabled can never become verified without rewriting history. Commits made *after* it was enabled
turn green retroactively the moment the signing key is registered — GitHub evaluates signatures
at display time, so no rewrite or re-push is needed for those.

---

## Quick reference

```bash
# Full new-machine sequence, assuming the key already exists at ~/.ssh/id_ed25519
cd ~/.dotfiles/stow-packages && stow -t ~ git
printf '%s %s\n' "sefatanam@gmail.com" "$(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
chmod 600 ~/.ssh/allowed_signers
gh auth refresh -h github.com -s admin:ssh_signing_key
# ...then register the signing key per Step 5, and:
git log --format='%h %G? %GS' -1
```
