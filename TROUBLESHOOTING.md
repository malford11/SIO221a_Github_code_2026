# Troubleshooting setup

Problems that have actually come up setting up this class on a real machine, with
what the symptom looks like and why it happens. If you hit something not listed
here, ask — and then it gets added.

For the two well-known MATLAB-kernel gotchas (`Failed to create matlab-proxy
subprocess`, and being asked to sign in to MathWorks), see the MATLAB section of
[README.md](README.md); `tools/sio221a-lab` handles both for you.

---

## `pip install` ends in a wall of Rust errors (Intel Macs)

**Symptom.** Installing the environment — either `tools/sio221a-setup` or a manual
`pip install jupyter-matlab-proxy` — runs for a long time and then fails with
hundreds of lines mentioning `cargo:warning`, `maturin failed`, and:

```
Could not find directory of OpenSSL installation, and this `-sys` crate cannot
proceed without this knowledge.
```

ending in `ERROR: Failed building wheel for cryptography`.

**Why.** The MATLAB kernel depends on `matlab-proxy`, which depends on
`cryptography`. Releases after 48.x stopped shipping prebuilt macOS x86_64
wheels, so on an Intel Mac pip falls back to the source distribution and tries to
compile it. That needs a Rust toolchain and OpenSSL development headers, which a
clean Mac doesn't have. Nothing in the error output says any of this.

**Fix.** Nothing to do if you use the setup script — it detects an Intel Mac and
pins `cryptography` to the last version with a wheel. If you're installing by
hand, add the pin yourself:

```bash
pip install --only-binary cryptography 'cryptography<49' jupyter-matlab-proxy
```

Apple Silicon Macs and Linux have wheels for every version and need no pin. If
you're not sure which you have, run `uname -m`: `x86_64` is Intel, `arm64` is
Apple Silicon.

---

## `gh` says authentication succeeded, but you're still not logged in

**Symptom.** `gh auth login --web` completes the browser step and prints
`✓ Authentication complete.` — and then, at the very end:

```
mkdir /Users/you/.config/gh: permission denied
```

`gh auth status` afterwards reports `You are not logged into any GitHub hosts`.

**Why.** Your `~/.config` directory is owned by `root` rather than by you, so `gh`
can't create its config directory inside it. This happens if some earlier install
was run with `sudo` and created `~/.config` as root on the way — a shell or editor
config is the usual culprit. The authentication genuinely did work; only saving
the result failed. The success message before the failure makes this very
confusing.

**Check.** The owner in the middle column should be your username, not `root`:

```bash
ls -ld ~/.config
```

**Fix.** Give the directory back to yourself, then log in again:

```bash
sudo chown -R "$(id -un):staff" ~/.config
gh auth login --web
```

Prefer this over working around it with `GH_CONFIG_DIR`: a root-owned
`~/.config` will quietly break any other tool that keeps its settings there, not
just `gh`.

---

## MATLAB and Python notebooks disagree about where the repo is

**Symptom.** The standard setup cell prints one path under the Python kernel and a
different one under the MATLAB kernel. Edits you make to a routine in `mha_code/`
or `python_code/` seem to have no effect, because the two kernels are reading two
different copies of this repository.

**Why.** `SIO221A_ROOT` can be set in more than one place, and MATLAB gets the last
word. If `~/Documents/MATLAB/startup.m` contains a `setenv('SIO221A_ROOT', ...)`
line, it runs *inside* MATLAB, after your shell has already exported its own
value — so it overrides the shell for MATLAB notebooks only. Python notebooks keep
using whatever the shell exported.

**Check.** Compare the two:

```bash
grep SIO221A_ROOT ~/.zshrc ~/Documents/MATLAB/startup.m
```

**Fix.** Make them name the same directory, or delete the `startup.m` line and let
the shell setting apply everywhere. If you keep two clones of this repo on one
machine, be deliberate about which is canonical — and avoid working in a clone that
lives inside a synced folder such as Google Drive or Dropbox, since the sync client
and git will corrupt each other's view of `.git` (a stale `.git/index.lock` is the
usual first sign).
