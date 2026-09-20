# ADR-001: Desktop Linux distribution

**Status:** Draft **Date:** 2026-09-16

## Context

Two machines. A 2017 System76 Lemur laptop running Pop!_OS 20.04, and a desktop I built in
2018 — Ryzen CPU, RTX 3080 added later, currently Windows 10 on one m.2 with a dead
Pop!_OS install on a second m.2.

Both OSes are unsupported. Pop 20.04 went EOL around April 2025, Windows 10 in
October 2025. The desktop can't take Windows 11: Microsoft's AMD allow-list starts at
Ryzen 2000-series branding, and even a supported chip fails the check with fTPM off,
Secure Boot off, or an MBR/CSM disk. Not worth fixing, since I'm leaving Windows anyway.

I deferred the 20.04 upgrade from roughly 2020 to 2022 out of upgrade fear, then burned
out and didn't engage much with the machine or with programming until recently. I'm coming
back now, and game dev is the main pull. The desktop has the GPU, so it becomes the
primary machine.

Stale packages are the live pain, particularly for C++ work.

The unification is the point. Gaming and dev currently live on different machines in
different rooms, which makes every context switch expensive enough that one side always
loses. One machine, one OS, both activities. A long HDMI cable already runs from the
desktop to the TV, and the desk monitor stays connected too. I prefer controllers for
games that support them, and I want to eventually build couch co-op games to play with my
girlfriend — so testing my own builds with two controllers on the TV is a development
requirement, not a nice-to-have.

The constraint that decides this: **the OS must not become a project.** Anything demanding
ongoing hand-tuning is disqualified regardless of how appealing its properties are. That
is not laziness — it's protecting the energy I want to spend on Bevy and Rust.

## Decision

**Bazzite** (Fedora 44 atomic, Universal Blue) on the desktop. GNOME, NVIDIA open driver.

Install `bazzite-gnome-nvidia-open`, then rebase to `bazzite-dx-nvidia-gnome`. There is no
DX ISO; everyone installs plain and rebases.

The laptop stays on Pop 20.04 for now. One machine at a time.

## Options considered

### NixOS — rejected

The draw was declarative system properties and reproducibility.

Rejected because the property I actually want is **atomic rollback**, not whole-system
declaration. Whole-system Nix means owning every aspect of the system in a language,
forever — the exact opposite of what I said I wanted. I mistook "declarative" for
"low-maintenance"; they're different things, and for me they point in opposite directions.

The workload makes it worse. Bevy, adb, Wine and 32-bit libs for BWAPI, an unpacked Godot
tarball, Steam and Proton are all prebuilt binaries that assume a normal FHS layout. On
NixOS each becomes an `nix-ld` / `buildFHSEnv` / `steam-run` chore. With near-zero
tolerance for manual fixing, that's disqualifying.

Left open: Nix as a per-project dev-shell tool only. Not adopted now. Revisit if
devcontainers turn out to be insufficient for pinning.

### Stay on Pop!_OS — rejected

Pop 24.04 shipped December 2025 with COSMIC 1.0 (now Epoch 1.8). The Pop I've used for
years — GNOME plus pop-shell tiling — doesn't exist in the current version, so staying is
a migration to a new desktop environment anyway. Brand loyalty buys no continuity here.

COSMIC is also the weakest gaming target right now. HDR and controller support are Epoch
3, roughly late 2027; VRR isn't on the published roadmap at all. And COSMIC now ships as a
Fedora spin, a Fedora Atomic variant, and a NixOS module, so it isn't a reason to pick Pop
even if I wanted it.

### Nobara — rejected

Bundles Lutris, has a GNOME edition, Fedora 44 base. Meets the surface requirement.

Rejected on reliability and bus factor: it's conventional rather than atomic (btrfs
snapshots only), maintained substantially by one person, and its Fedora 44 upgrade path
has first-hand reports of two failed attempts including a full-disk failure
mid-checkpoint. Fails the "can't brick me" requirement, which is the whole point.

### Bluefin-DX — rejected, close second

Same Universal Blue foundation, same atomic rollback, dev-first defaults, GNOME.

Rejected on Lutris specifically. Bluefin installs Lutris as a Flatpak; Bazzite
deliberately layers it natively *because* the Flatpak has compatibility problems. For Wine
and BWAPI work that's the wrong side of the trade. Bluefin also runs the stock Fedora
kernel rather than Bazzite's OGC kernel.

### Bazzite — chosen

Meets every requirement without a workaround: atomic with one-command rollback, Lutris
natively preinstalled, GNOME variant, an NVIDIA-open image for Ampere, and a DX layer that
covers the dev tooling.

## Consequences

**What this buys**

- Updates are atomic. Rollback is `rpm-ostree rollback` plus a reboot. Two deployments
  retained; pin a known-good one with `ostree admin pin`.
- Preinstalled: Steam, Lutris, Gamescope, MangoHud, vkBasalt, Waydroid, Distrobox, Input
  Remapper.
- DX adds Docker and Podman, native VS Code with devcontainers, Homebrew, QEMU/libvirt,
  Incus, restic, rclone, and android-tools — `adb` and `fastboot`, which covers RestWord.
- nvidia-open (610/615 branch — moves fast, check at install), GNOME 50.4, kernel
  7.2.x-ogc, Mesa 26.2. VRR and HDR both work on GNOME 50 with NVIDIA.
- Backup scope collapses. The OS is an OCI image, so there's nothing to back up. Only
  `/var/home`, `/etc` deltas, and the layered-package list.

**Costs accepted**

- The host isn't freely mutable. System packages come from Distrobox, Homebrew, or
  Flatpak. `rpm-ostree` layering is a last resort.
- Emacs has to be layered, as `emacs-pgtk` (the Wayland build; stock `emacs` on Fedora is
  GTK+X11). Homebrew's Linux formula builds `--without-x` (terminal-only), and the Flatpak
  is a stale community build whose sandbox can't spawn host binaries. Layered packages can
  block rebasing, so a future rebase may need `rpm-ostree uninstall emacs-pgtk`
  first. Emacs is a leaf package — no kmod, no PAM, no systemd generator — the low-risk
  end of layering. Fedora 44 ships **Emacs 30.2**, not upstream's 31.1; 30.2 still has the
  `distrobox` TRAMP method (added 30.1), so the workflow is unaffected. Skip the
  newer-Emacs COPRs — a COPR lagging a new Fedora release is the most common way these
  setups break.
- 1Password's Flatpak ships without the browser-helper binary, so browser unlock is
  separate. Accepted as a papercut; revisit in a few months. Explicitly **not** layering
  it — layering modifies PAM and a full lockout has been reported.
- GNOME↔KDE rebasing is unsupported. GNOME is a one-way choice made at install.
- LSP over TRAMP requires leaving `tramp-direct-async-process` off. Known open lsp-mode
  issue since October 2024.
- Bazzite GDX, the game-dev flavor, is dormant — last published image October 2025. Not
  waiting for it.

## Steam Gaming Mode: off

This one deserves its own section because the obvious reading is backwards. Gaming Mode
looks like the option that serves couch gaming and controller-first play. It is the option
that breaks them.

Gaming Mode runs Steam with `-steamdeck`, which globally activates Steam Input. Steam
Input makes local multiplayer games misidentify a single controller as multiple
controllers (open Valve issue). For developing a two-controller Bevy game that is
precisely the failure mode I can't have — gilrs would enumerate Steam Input's virtual
devices rather than raw evdev, so I'd be debugging phantom pads inside my own game. On
plain GNOME, `cargo run` talks to raw evdev and sees exactly two controllers.

Three supporting reasons:

- It's a different image (`bazzite-deck-nvidia-gnome`), not a package set, and there is no
  `ujust` command to enable it later. Switching means a full rebase. The one documented
  desktop→deck rebase on NVIDIA — same DE, same driver — broke 7+ games and caused apps to
  spuriously autostart at login, and **rollback did not fix it** because residual state
  lived in `/etc` and `$HOME`. Still open, no maintainer resolution.
- The bazzite.gg picker gates the NVIDIA Gaming Mode toggle behind a beta warning
  requiring explicit acknowledgement. Beta since January 2025. The HTPC install guide
  calls NVIDIA "currently in beta with major caveats" and prefers AMD. The Portal's
  VRR/HDMI-2.1 toggle is AMD-only.
- Gaming Mode drives **one output only**, pinned statically via `OUTPUT_CONNECTOR` in a
  config file. The other display goes dark in that session; changing it means editing the
  file and logging out. That is the opposite of a dual-display desk-and-TV setup.

**Accepted cost of this choice:** GNOME exposes no CLI or API to switch the primary
display, so moving a session from the desk monitor to the TV is a manual flip in Settings
each time — roughly 10 seconds, with both displays remaining usable. There is an open
Bazzite issue for exactly this scenario, closed as an enhancement, with the upstream
Mutter work item still open. Worth revisiting if someone ships a script.

Couch flow instead: Steam Big Picture from the GNOME session. Fully controller-navigable,
identical Deck UI, can be autostarted at login. On a desktop, Gaming Mode's unique
additions are TDP control (irrelevant), suspend-resume-to-game, Decky Loader, and the QAM
overlay. Per-game `gamescope -- %command%` remains available for framerate capping or
scaling on a specific title.

## Custom derived image: not now

Bazzite is an OCI image, so building my own image `FROM` it — Containerfile in git, GitHub
Actions rebuilding nightly, `bootc switch` to my own registry — is the obvious way to get
Emacs on the host. It's also the declarative whole-system-in-git property I originally
wanted from Nix, at a fraction of the cost. Good instinct, wrong timing.

Two failure modes kill it for me specifically, and they share a property:

- **GitHub silently disables scheduled workflows in public repos after 60 days with no
  repository activity.** No email, no log entry. A personal Emacs image is exactly a repo
  I'd never commit to, so nightly builds stop after two months and nothing says so.
- **A failed build is a silent update stall.** bootc keeps pulling the last
  successfully-pushed tag and the host reports "up to date." The only signal is a GitHub
  Actions failure email.

Both are **invisible from the desktop**. Given that I deferred the Pop upgrade for years,
installing a system that can quietly stop updating while looking healthy is the worst
available failure mode. It's the Nobara bus-factor objection again, except the single
maintainer is me, and I don't get told when I've stopped maintaining.

Layering one leaf package fails the other way: loudly and recoverably. Every documented
layering breakage is a dependency conflict or a many-packages problem. `emacs-pgtk` has no
kmod, no PAM, no overlap with the base. The residual risk is a package rename at F44→F45
blocking an upgrade — visible immediately, fixed with `rpm-ostree uninstall`.

Sysexts, the third option, are worse still: systemd enforces version matching, so a sysext
built for F44 silently stops merging on F45. Universal Blue's own sysext repo was archived
in January 2025.

**Revisit when any of these is true:**

- The layered package list reaches 3–4. Layering's costs become real there and the image's
  are amortized.
- The laptop gets migrated and both machines should be identical. That's the
  reproducibility payoff, and the case where CI earns its keep.
- **Bazzite completes its bootc migration.** This one has a clock on it — see below.

### The layering decision has a shelf life

`bootc`'s own documentation states that on container-sourced systems `rpm-ostree upgrade`
and `bootc upgrade` are effectively equivalent — **until the system is mutated
client-side.** Layering is exactly that mutation, and `bootc upgrade` errors out on a
layered system rather than working around it.

Bazzite still drives updates through rpm-ostree today, so layered `emacs-pgtk` is fine
right now. But the migration to bootc is in progress (ublue-os/bazzite#2726), Bluefin's
docs already treat `bootc` as canonical, and Universal Blue has an open thread on the
remaining gaps. When Bazzite finishes the move, layering stops being a mild cost and
becomes an incompatibility.

That doesn't change the decision now — the derived image's silent-failure modes are still
worse than layering's loud ones. It does mean the derived image is not a hypothetical
someday; it's the likely destination, and the trigger is upstream's timetable rather than
mine. Watch the Bluefin blog and the UB Discourse migration thread.

If it happens: a keepalive workflow is mandatory so the 60-day timer never fires, GitHub
Actions failure notifications must be on, and the image has to be world-readable — private
GHCR images can't be rebased to. Note also that `brh` only lists official Bazzite builds,
so rollback-to-an-older-build degrades; plain `rpm-ostree rollback` still works.

## Decisions settled alongside

| Decision | Choice | Why |
|---|---|---|
| Desktop environment | GNOME | Don't use tiling. Ahead of COSMIC on HDR/VRR. Not reversible after install. |
| Secure Boot | Off | No dual-boot; nothing in the stack needs it. Avoids the MOK enrollment step. |
| Windows m.2 | Stays in the machine, untouched | Free fallback. BIOS M.2-disable is unreliable on 2018 AM4, so protection comes from blanking the target drive and selecting only it. |
| Dev containers | Two: `dev` and `bwapi` | Only BWAPI's 32-bit multilib and Wine genuinely conflict. Distrobox shares `$HOME`, so this isolates system packages, not toolchains — more boxes would mean more `dnf update`s for no isolation. |
| Editor | Emacs on host, TRAMP into containers | Native `/distrobox:NAME:/path` method since Emacs 30.1; 31.1 is current. VS Code stays for remote pairing, installed natively by DX. |
| Backups | restic to Backblaze B2, cloud first | A backup needing a drive plugged in stops happening. External drive added as second copy later. CrashPlan not carried over. |
| Dropbox | Dropped | Vestigial, and broken on composefs without a Flatseal workaround. |
| Laptop | Untouched on Pop 20.04 | Revisit in a month, once the atomic model is proven. |

## Open

- `bazzite-dx#172`, "bazzite-dx-nvidia stuck in gaming mode" — unread, and it's on the
  exact image being rebased to. Read it before the DX rebase.
- Automating the GNOME primary-display flip for couch sessions. No API today; check again
  in a few months.
