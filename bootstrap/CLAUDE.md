# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The record of every customization made to `mistral`, a Bazzite DX workstation running
`ghcr.io/ublue-os/bazzite-dx-nvidia-gnome:stable`. It exists because `rpm-ostree`
layering has a shelf life (`docs/layering-shelf-life.md`), and the intent is for this repo
to become the derived-image build once Bazzite moves to `bootc`: a Containerfile `FROM`
the Bazzite DX image, published to a registry via CI. The GitHub remote is already named
for that future (`RadicalZephyr/bazzite-dx-radz`); the local directory name is historical.

The README still describes the repo as Distrobox-only. Distrobox is one piece of the
customizations, so treat the README as lagging the scope, and widen it when touching it.

## Layout

- `distrobox.ini` — `distrobox assemble` file for all containers. Each section's header
  comment carries a `VERIFIED ... <date>` stamp and the reasoning behind every package.
- `claude-desktop-init.sh` — the one init hook for the `claude-desktop` box.
- `docs/` — notes on the host strategy: the `bazzite-0N-*.md` model/exercises/reference
  trio, `layering-shelf-life.md`, and per-task handoffs.
- `docs/decisions/` — ADRs. `0001-desktop-linux-distro.md` is the distro decision and
  holds the layering cap and the derived-image triggers.

## Commands

There is no build, lint or test. The checks are operational, and the README's Usage and
Known-traps sections are the reference. The two that matter most:

```bash
# Rebuild one box (assemble only builds what's missing). Same pair is the quarterly drift check.
distrobox rm --force dev
distrobox assemble create --file ~/prog/distrobox/distrobox.ini

# Host layered list; currently emacs-pgtk and nothing else.
rpm-ostree status
```

To verify a section against its running box, enter it and read `dnf history` (Fedora
boxes) or `dpkg -l` (`claude-desktop`).

## Rules the files encode

- Mechanism order for anything new on the host: Flatpak, then Homebrew, then a Distrobox
  box, then layering as a last resort. The test: what writes to `/var` or `/etc` survives
  bootc; what modifies `/usr` client-side does not. The layered list is capped at one.
- A new box is justified only by conflicting system packages. `$HOME` is shared, so
  toolchains in `~/.cargo`, `~/.rustup`, `~/.npm` are identical in every box and stay out
  of the ini.
- A package installed by hand inside a box goes into `distrobox.ini` in the same sitting.
  When a section is reconciled against the running box, refresh its `VERIFIED` header
  with the date and how it was checked.
- One init hook script per box; multiple `init_hooks` lines are fragile (distrobox#844,
  #1673). Ini paths are absolute `/var/home/zefs/...` because hooks run as root inside
  the container.
- `bwapi`: "32-bit" means the win32 MinGW cross toolchain. Keep `.i686` `-devel` packages
  out of this box; 32-bit Linux struct layouts differ from the other three toolchains.
- `claude-desktop`: keep `--group-add keep-groups` and the `/lib/modules` volume (Cowork's
  local KVM guest needs them). Leave `nvidia` unset; on this host it hangs
  (bazzite#5172).
- Reasoning lives beside the thing it explains, as comments in the ini and the hook
  script, not in a change log. Docs in `docs/` are append-only notes.
