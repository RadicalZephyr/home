# Reference

Dip in. Three parts: how to decide where software goes, how to not make a mess, and what to read when you want depth.

---

## Where does this software go?

Bazzite's own hierarchy, in order. Work down the list and stop at the first one that works.

| # | Mechanism | Use for | Your cases |
|---|---|---|---|
| 1 | **Flatpak** | GUI applications | Firefox, 1Password, Discord |
| 2 | **Homebrew** | CLI tools, no system integration | `ripgrep`, `fd`, `jq`, `gh` |
| 3 | **Distrobox** | Anything needing headers, system libs, a different distro, or a toolchain | Rust/Bevy, C++/Wine, Android SDK |
| 4 | **Quadlet** (podman + systemd) | Long-running services | A local Postgres, later |
| 5 | **rpm-ostree layering** | Things that must be on the host itself | `emacs-pgtk`. Last resort. |

Two decision rules that resolve most cases:

**Does it need to see the host as a whole?** Then it's layering. Emacs qualifies because it reaches into containers via TRAMP and needs the real host filesystem. Almost nothing else you use qualifies.

**Does it need a compiler or `-devel` packages?** Then it's Distrobox, always. Never layer a build dependency.

---

## Don't make a mess

Ranked in the order you said you were worried about them.

### 1. Containers becoming pets

**The failure:** six months from now `dev` has thirty packages you installed at various 2am moments, none written down, and rebuilding it means remembering what broke and why.

**The fix:** `~/prog/distrobox.ini` in git, from exercise 9. One rule follows from it — **when you `dnf install` something inside a box and it turns out you need it, add it to the .ini in the same sitting.** Not later. The .ini is only worth having if it's true.

**The check:** once a quarter, `distrobox rm --force dev && distrobox assemble create --file ~/prog/distrobox.ini`. If the rebuilt box can't build your projects, the file had drifted and you just found out cheaply.

### 2. The same tool installed three ways

**The failure:** `rg` from brew, `rg` inside `dev`, `rg` layered on the host. Three versions, and which one runs depends on `$PATH` and which shell you're in. This is the one that produces "it works in my terminal but not in Emacs."

**The fix:** one tool, one home, decided once. CLI tools you use everywhere → Homebrew, on the host. Tools a project needs → inside that project's container, never on the host. If you catch yourself installing something you already have, stop and delete one of them.

**The check:** `which -a <tool>` when something behaves oddly. More than one result is the bug.

### 2b. Binaries built in a container, run on the host

**The failure:** the `~/.local` habit from Pop meets shared `$HOME`. You `./configure --prefix=$HOME/.local && make install` inside `dev` — which is correct, because that's where the compiler is — and the binary appears in `~/.local/bin` on the host, where it's linked against libraries the host doesn't have. It either fails with a missing `.so` or, worse, works until a container rebuild changes the library version.

**The fix:** built inside a container, run inside that container. To use it from the host, either `distrobox-export --bin` it (which wraps it so it executes in its own environment) or install it from Homebrew instead.

**The check:** `which -a <tool>` then `ldd $(which <tool>)`. This is the same class of problem as picking the right Claude Code binary for host vs. Arch container.

**The real shift underneath:** the host has no development environment and never will. On Pop, `apt install libssl-dev` served every compile you ran afterward. Here, build dependencies live in one container and are invisible outside it. That's the structural change — not which command installs Firefox.

### 2c. Distrobox `--nvidia` on this host

**The failure:** `distrobox enter` hangs for many minutes at `Setting up host's nvidia integration...`. There's an open Bazzite issue for it (#5172) on DX + NVIDIA.

**Why:** that step runs `find /usr/ -empty -iname "*nvidia*"` across the container's whole `/usr`, plus a `findmnt` per NVIDIA library against composefs mounts, rootless. If you also bind-mount something big under `/lib` — note Ubuntu is usr-merged, so `/lib/modules` resolves to `/usr/lib/modules` — that `find` walks it too, and the step goes from slow to pathological.

**The fix:** don't pass `--nvidia` unless you actually need GPU compute in the container. GUI apps don't: the host compositor draws the window using the host driver, and only in-process rasterization falls back to software.

**Diagnosing a hang:** `podman logs <name> 2>&1 | grep -c container_setup_done` — zero means setup genuinely hasn't finished. Non-zero while `enter` still hangs means the log-watcher bug (distrobox#1803), and a second `distrobox enter` usually succeeds. Watch progress with `podman logs <name> | wc -l` twice, 30 seconds apart.

### 3. Layered packages accumulating

**The failure:** the list grows one justified exception at a time until updates take fifteen minutes and rebasing is blocked.

**The fix:** the ADR's cap — three or four. At that point you build a derived image instead, which is the better answer anyway.

**The check:** `rpm-ostree status` shows `LayeredPackages`. Your restic job already saves this output; glance at it when you review backups.

### 4. `/etc` drift

**The failure:** not really a failure — `/etc` changes are merged forward and mostly fine. The risk is forgetting what you changed and why.

**The fix:** `sudo ostree admin config-diff` quarterly. Anything in that list you don't recognize, investigate or revert.

### 5. Home directory sediment

**The failure:** the laptop, again. `.texlive2016` through `.texlive2023`.

**The fix:** genuinely improved here without effort. Flatpak apps write to `~/.var/app/<id>/`, so uninstalling one takes its data. Distrobox packages live in the container, not your home. The main remaining source is language tooling — `~/.cargo`, `~/.rustup`, `~/.npm` — which is shared across containers by design and worth keeping.

---

## Command cheatsheet

**Status and identity**

```bash
rpm-ostree status -v          # deployments, layering, versions (no root needed)
sudo bootc status             # same facts, newer vocabulary
sudo ostree admin config-diff # what you've changed in /etc
rpm-ostree db diff            # package changes between deployments
```

**Updating**

```bash
ujust update                  # updates everything: image, flatpaks, brew
sudo rpm-ostree upgrade       # image only; stages, doesn't apply
sudo rpm-ostree cleanup -p    # discard a staged deployment
```

**Undoing**

```bash
sudo rpm-ostree rollback      # switch to the other deployment
sudo ostree admin pin 0       # keep this one past the 2-deployment window
sudo ostree admin pin -u 0    # unpin
# Esc at boot → ostree:1       # works when nothing else does
```

**Escape hatches**

```bash
sudo rpm-ostree usroverlay    # writable /usr until reboot
sudo rpm-ostree install PKG   # layer it (permanent, costs update time)
sudo rpm-ostree uninstall PKG
```

**Containers**

```bash
distrobox list
distrobox enter dev
distrobox assemble create --file ~/prog/distrobox.ini
distrobox rm --force NAME
distrobox-export --bin /path/to/bin --export-path ~/.local/bin
distrobox-export --app NAME   # export a GUI app to the host menu
```

**Discovery**

```bash
ujust                         # lists every recipe Bazzite provides — run this once, properly
ujust dx-group                # adds you to docker, incus-admin, libvirt, dialout
ujust setup-virtualization    # libvirt + virt-manager + kvm kargs
```

**Adding yourself to a system group** — this one has a trap

`usermod -aG <group> $USER` **exits 0 and silently does nothing** for system groups. Fedora Atomic splits accounts: package-shipped groups live in `/usr/lib/group`, while `/etc/group` holds only machine-local entries. NSS reads both; shadow-utils reads only `/etc`.

```bash
grep -q '^GROUP:' /etc/group || grep '^GROUP:' /usr/lib/group | sudo tee -a /etc/group
sudo usermod -aG GROUP "$USER"
grep '^GROUP:' /etc/group      # the real test — NOT getent, which passes either way
sudo systemctl reboot          # newgrp only affects one shell, not the graphical session
```

Copy the line verbatim so the GID is preserved. Your `/etc` entry then shadows `/usr/lib/group` permanently, so if the upstream GID ever changes your frozen copy wins silently — one for the quarterly `config-diff` review.

Fedora lists moving away from nss-altfiles as planned but unlanded as of F44.

---

## Reading, annotated

### Read these three, in order

1. **[Bootc and OSTree: Modernizing Linux System Deployment](https://a-cup-of.coffee/blog/ostree-bootc/)** — updated Aug 2026. The best answer anywhere to "where did my filesystem go." Frames ostree as git for filesystems and walks through composefs, the `/usr/etc` overlay, and why `/home` is a symlink. Written for precisely your disorientation.
2. **[bootc filesystem reference](https://bootc.dev/bootc/filesystem.html)** — authoritative and short. Precise on the `/etc` three-way merge and on `/var` behaving like a Docker volume. Read straight after the first.
3. **[Bluefin Administrator's Guide](https://docs.projectbluefin.io/administration/)** — same underlying system as Bazzite, better written, and ahead of it on the bootc transition. Note their docs carry a "major update expected October 2026" banner, so recheck in Q4.

### When you want depth on one thing

- **[libostree docs](https://ostreedev.github.io/ostree/)** — canonical and dense. Read the *Deployments*, *Atomic Upgrades*, *Atomic Rollbacks* and *OSTree and /var handling* pages specifically, not the whole site.
- **[rpm-ostree Administrator's Handbook](https://coreos.github.io/rpm-ostree/administrator-handbook/)** — the hands-on command reference. Doesn't cover `pin`, `db diff` or `kargs`; use `man rpm-ostree` for those.
- **[bootc: relationship with other projects](https://bootc.dev/bootc/relationships.html)** — the source of the "layering breaks `bootc upgrade`" fact in the ADR.
- **[Fedora Atomic Desktops docs](https://docs.fedoraproject.org/en-US/atomic-desktops/)** — newly unified for F44, the official reference for your base.

### Distrobox

- **[Useful Tips](https://distrobox.it/useful_tips/)** — the highest-value page on the site. `--nvidia`, GUI apps, init hooks, and the pitfalls. Read it before you hit them.
- **[distrobox assemble](https://distrobox.it/usage/distrobox-assemble/)** — the reference for your `.ini`.
- **[LWN: Mix and match Linux distributions with Distrobox](https://lwn.net/Articles/1049423/)** — Dec 2025. The clearest neutral overview and the best Distrobox-vs-Toolbx framing.
- **[Declaring your own personal distroboxes](https://www.ypsidanger.com/declaring-your-own-personal-distroboxes/)** — 2023, dated in details but still the best conceptual piece on not letting boxes become pets.

### Podman, for the Docker-rusty

- **[Make systemd better for Podman with Quadlet](https://www.redhat.com/en/blog/quadlet-podman)** — the readable intro to the real delta: no daemon means systemd is your supervisor.
- **[Quadlet unit reference](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)** — when you want that local Postgres to start at boot.
- Skip the "Podman vs Docker 2026" listicles entirely. SEO filler.

### Bazzite specifics

- **[Introduction to Installing Software](https://docs.bazzite.gg/Installing_and_Managing_Software/software-intro/)** — the source of the hierarchy at the top of this document.
- **[ujust](https://docs.bazzite.gg/Installing_and_Managing_Software/ujust/)** — worth ten minutes on day one.
- **[Bluefin blog](https://docs.projectbluefin.io/blog/)** — the live channel for this ecosystem's technical writing. Worth following; it's also where you'll see the bootc migration land.

### Where to actually get help

**Bazzite support happens on Discord**, not the forum. The Universal Blue Discourse has a pinned notice redirecting Bazzite questions elsewhere.

- **[Universal Blue Discord](https://discord.gg/8RZGC3uFzA)** — the live channel.
- **[Answer Overflow](https://www.answeroverflow.com/c/1072614816579063828)** — indexes that Discord so it's searchable, which it otherwise isn't. Search here before asking.
- **[Universal Blue Discourse](https://universal-blue.discourse.group/)** — announcements, and Bluefin/general discussion.
- **[Fedora Discussion](https://discussion.fedoraproject.org/)** — for ostree and rpm-ostree internals.

---

## Known thin spots

Three areas where documentation genuinely doesn't exist yet, so don't waste time hunting for it:

**Devcontainers with Podman.** The best material is community threads, and Universal Blue maintainers have themselves questioned how well-supported VS Code + Podman is. Expect to iterate.

**Bevy on atomic.** No authoritative guide. The pieces you need are Distrobox's `--nvidia` flag and matching Vulkan ICD versions inside the container — exercise 10 in the first-week doc is the diagnostic.

**Cargo target directories across containers.** `~/.cargo` and `~/.rustup` are shared between host and every box, which is what you want. But `target/` directories built against different glibc versions will thrash each other. If you hit unexplained full rebuilds when switching between `dev` and `bwapi`, set a per-container `CARGO_TARGET_DIR` (e.g. `~/.cache/cargo-target/dev`) in the assemble file's init hook. This is reasoning rather than documented practice — nobody has written it up.
