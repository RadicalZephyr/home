# distrobox

Declarative definitions for the Distrobox containers on `mistral` — my Bazzite DX
workstation.

The point of this repo is that my containers are a file I can read, not a history of
things I typed at 2am. Destroying and rebuilding a box should be a command, not an
archaeology project.

```
distrobox.ini              all three containers
claude-desktop-init.sh     init hook for the claude-desktop box
```

---

## Why these containers exist at all

The host is Fedora Atomic. `/usr` is a read-only checkout of an OCI image, and there is no
development environment on it by design — `rpm-ostree install` rebuilds the system image
locally, slows every subsequent update, and can block rebasing. So anything needing a
compiler or `-devel` headers lives in a container instead.

Distrobox containers share `$HOME` with the host. That means they isolate *system
packages*, not toolchains: `~/.cargo`, `~/.rustup` and `~/.npm` are the same files
everywhere. Worth remembering when deciding whether a new box is warranted — usually it
isn't.

## Why two dev boxes and not one, or four

The rule is that a separate box is justified by **conflicting system packages**, nothing
else.

**`dev`** — Rust/Bevy, TypeScript, Python. Bevy's Linux dependencies (`gcc-c++`,
X11/Wayland/ALSA/udev headers, Vulkan drivers) conflict with nothing, so everything that
doesn't fight goes here.

**`bwapi`** — C++ against BWAPI, which means Wine and 32-bit multilib. That genuinely
pollutes a system, and it's the one case where a second box earns its keep. It's also the
case that makes Distrobox worth using at all: this box can run a different distribution
from `dev` if that makes multilib less painful.

Four boxes — one per project — was the original instinct and it's wrong. Because `$HOME`
is shared, per-project boxes buy no toolchain isolation, and each one is another `dnf
update` to forget about. Two boxes, split where packages actually collide.

**`claude-desktop`** — not a dev box. Anthropic ships the Linux desktop app as a `.deb`
for Debian and Ubuntu only; their docs say plainly that Fedora isn't supported. Rather
than layer an unofficial RPM onto the host image, the app runs in an Ubuntu 24.04
container and is exported to the GNOME menu. Nothing touches the host, and it survives
image updates untouched.

That container has two flags that look removable and are not:

- `--group-add keep-groups` and `--volume /lib/modules:/lib/modules:ro` — Cowork's
  workspace VM is a real KVM guest running on this machine, using the host's
  `vhost_vsock`. It needs `/dev/kvm` and `/dev/vhost-vsock`.
- **No `--nvidia`.** On this host it hangs for 20+ minutes at "Setting up host's nvidia
  integration"
  ([ublue-os/bazzite#5172](https://github.com/ublue-os/bazzite/issues/5172)). An Electron
  app doesn't need it — the host compositor draws the window using the host driver.

---

## Usage

### Prerequisites

Distrobox and Podman. Bazzite ships both. Elsewhere, see the [Distrobox installation
guide](https://distrobox.it/#installation) — the one-liner is:

```bash
curl -fsSL https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --prefix ~/.local
```

Reference docs worth having open:

- [distrobox-assemble](https://distrobox.it/usage/distrobox-assemble/) — the `.ini` format
- [Useful tips](https://distrobox.it/useful_tips/) — GPU flags, GUI apps, init hooks, and
  the pitfalls

### First-time setup

```bash
git clone <this repo> ~/prog/distrobox
chmod +x ~/prog/distrobox/claude-desktop-init.sh
distrobox assemble create --file ~/prog/distrobox/distrobox.ini
```

### Rebuild a single container

```bash
distrobox rm --force dev
distrobox assemble create --file ~/prog/distrobox/distrobox.ini
```

`assemble create` only builds what's missing, so removing one box and re-running rebuilds
just that one.

### Rebuild everything

```bash
distrobox rm --force dev bwapi claude-desktop
distrobox assemble create --file ~/prog/distrobox/distrobox.ini
```

Your `$HOME` is untouched by `distrobox rm` — the default home *is* the real home. Only
the container's own filesystem goes.

### Check what exists

```bash
distrobox list
distrobox enter dev
```

---

## Keeping this file true

A declarative file that lies is worse than no file. One rule:

> When you `dnf install` or `apt install` something inside a box and it turns out you need
> it, add it to `distrobox.ini` **in the same sitting**. Not later.

And one check, quarterly:

```bash
distrobox rm --force dev
distrobox assemble create --file ~/prog/distrobox/distrobox.ini
```

If the rebuilt box can't build your projects, this file had drifted and you just found out
cheaply instead of during an emergency.

---

## Known traps on this host

**`distrobox --nvidia` hangs.** Twenty minutes or more at "Setting up host's nvidia
integration". Don't add it for GUI apps.

**Diagnosing a hung `distrobox enter`:**

```bash
podman logs <name> 2>&1 | grep -c container_setup_done
```

Zero means setup genuinely hasn't finished. Non-zero while `enter` still hangs is the
log-watcher bug ([distrobox#1803](https://github.com/89luca89/distrobox/issues/1803)) — a
second `distrobox enter` usually succeeds. Watch real progress with `podman logs <name> |
wc -l` twice, thirty seconds apart.

**Multiple `init_hooks` lines are fragile**
([#844](https://github.com/89luca89/distrobox/issues/844),
[#1673](https://github.com/89luca89/distrobox/issues/1673)). Use one hook that calls a
script — which is why `claude-desktop-init.sh` exists rather than a stack of inline
commands.

**Binaries built in a container don't run on the host.** `$HOME` is shared, so something
you `make install` into `~/.local/bin` from inside `dev` will appear on the host and fail
there, linked against libraries the host doesn't have. Use `distrobox-export --bin` to
wrap it, or install it from Homebrew instead. `which -a` plus `ldd` untangles it.

---

## Status

`claude-desktop` is verified — that section reflects exactly what was built and works.

`dev` is verified — its package list was reconstructed from the box's own `dnf history`
on 2026-09-20 and matches the one manual install made when the box was built.

`bwapi` is still a placeholder in the `.ini`. Its package list came from a setup runbook
and is known to contain names that don't resolve — the i686 multilib names in particular.
**Don't test it by destroying the box** — correct the list first, then rebuild.
