# Layering on Bazzite: what it costs, and why it has a shelf life

- **Status:** Notes, Sept 2026
- **Relates to:** [ADR-0001](decisions/0001-desktop-linux-distro.md) §"Custom derived image: not now", §"The layering decision has a
  shelf life"

---

## What layering actually is

`rpm-ostree install emacs-pgtk` is not "installing a package." It takes the base image,
adds your RPMs, and **rebuilds the OS commit on your machine**. You then boot a
locally-modified image that no longer corresponds to anything in a registry.

Every cost below follows from that one fact. It's worth holding onto, because it also
explains which costs are incidental and which are structural.

## The costs, and where each comes from

Bazzite's own documentation is blunt about this. Layering is "destructive and may prevent
updates," to be used "as a last resort," and the listed consequences are:

- **Updates get slower**, proportional to how much you've layered. Each update re-derives
  your local commit rather than just pulling a new one. You can feel this directly — `time
  rpm-ostree uninstall emacs-pgtk` takes minutes for one leaf package, and that time is
  paid on every update, forever.
- **Dependency conflicts can block upgrades entirely** until the offending package is
  removed. This is the loud failure mode, and it's the reason layering is survivable: you
  find out immediately and `rpm-ostree uninstall` fixes it.
- **Rebasing to a different image can be blocked** while packages are layered.

The maintainers' own framing is worth quoting because it tells you the direction of
travel: layering is "a crutch for the current software ecosystem on desktop Linux" that
"will eventually be phased out."

None of this makes layering *wrong* for a single leaf package. A leaf with no kernel
module, no PAM integration, and no systemd generator is the low-risk end. It makes
layering wrong as a **strategy**.

## Why bootc closes the door

The bootc documentation states that on container-sourced systems, `rpm-ostree upgrade` and
`bootc upgrade` are effectively equivalent — **until the system is mutated client-side.**
Layering is exactly that mutation, and `bootc upgrade` errors out on such a system rather
than working around it.

It's tempting to read that as a regression. It isn't. rpm-ostree's willingness to upgrade
a locally-rebuilt image was the anomaly; bootc is declining to pretend that an image which
is "Bazzite plus whatever you added" is still Bazzite. The model is that your machine runs
a named, signed, reproducible artifact. Layering breaks the naming, and bootc simply stops
rather than papering over it.

So the capability isn't being taken away out of austerity. It's being removed because it
was never coherent with the model it was bolted onto.

## The rule this gives you

Here's the part worth generalizing, because it predicts things this document doesn't
cover.

**Every modification mechanism either lies about the image or it doesn't.**

Flatpak writes to `/var/lib/flatpak`. Homebrew writes to `/home/linuxbrew`, which is
`/var`. Distrobox containers live in `/var/lib/containers`. Your `/etc` changes are
explicitly a merge point — the system's own design accounts for them. None of these touch
`/usr`, and none of them make the running image differ from the image it claims to be.

Layering is the only common mechanism that does. That's the whole distinction, and it's
why layering is the only one with a shelf life.

Use this to evaluate anything new. If a proposed mechanism modifies `/usr` client-side,
it's on borrowed time. If it puts files in `/var` or `/etc`, it's part of the model and
will survive.

**systemd-sysext looks like a third way and isn't** — for a different reason, but the test
still catches it. Sysexts overlay `/usr` at runtime rather than rebuilding it, so they
don't lie about the image commit. But systemd enforces version matching: a sysext built
for Fedora 44 **silently stops merging** on Fedora 45 until refreshed. Universal Blue
archived their own sysext effort in January 2025. Silent failure is worse than loud
failure, which is the same objection as the derived image's, below.

## What survives the transition, concretely

| Modification | Lives in | Survives bootc |
|---|---|---|
| Flatpak apps | `/var/lib/flatpak`, `~/.var` | Yes |
| Homebrew CLI tools | `/var` via `/home/linuxbrew` | Yes |
| Distrobox containers | `/var/lib/containers` | Yes |
| `/etc` edits (`kvm` group line, `modules-load.d`) | `/etc`, three-way merged | Yes |
| Everything in `$HOME` | `/var/home` | Yes |
| **Layered packages** | **the image, rebuilt locally** | **No** |

On this machine that's exactly one thing: `emacs-pgtk`. Claude Desktop went into a
container rather than becoming layered package #2, which in hindsight was the right call
for reasons beyond the ones we used at the time.

## The timeline, honestly

Nobody has committed to a date, and the signals are mixed:

- Fedora 44 shipped sealed bootc images "ready for testing"
- Migration to image-builder tooling is planned for **Fedora 45**, with bootable-container
  image support **after that**
- Bazzite's own migration is tracked in an open issue (ublue-os/bazzite#2726) with no
  target
- Bluefin's docs already treat `bootc` as canonical; Bazzite's still document `rpm-ostree`
- Universal Blue has an open thread on remaining gaps: `bootc status` requires root where
  `rpm-ostree status` doesn't, there's no `db diff` equivalent for inspecting staged
  updates, and the `kargs` replacement is undecided

That last point matters more than the roadmap does. **The transition can't complete while
`bootc` is missing functionality people depend on**, and the gap list is non-trivial. A
year is a reasonable guess; two wouldn't be surprising.

## The counter-argument, which I should take seriously

Fedora is slow at removing things.

`nss-altfiles` — the thing that made `usermod -aG kvm` silently do nothing — is listed
under "what's next" in the Fedora 44 Atomic release notes, described as "a long standing
source of issues that new users regularly face," and it's still there. The x86-64-v3
baseline proposal was rejected outright for F45. The bootc migration itself has already
slipped past its original milestone.

So planning as though layering disappears next spring would be overreacting. The honest
posture is not urgency, it's **direction**: don't build on it, don't grow the list, and
know what you'll do when it goes.

There's also a scenario where this never bites: Universal Blue could keep a compatibility
path, or bootc could gain a sanctioned mechanism for local additions. I don't think that's
likely — the whole point is the image being what it says it is — but it's not impossible,
and it's the reason to not act early.

## What replaces it, and why not yet

The successor to layering is a **derived image**: a Containerfile that does `FROM
ghcr.io/ublue-os/bazzite-dx-nvidia-gnome`, adds your packages, and publishes to your own
registry via CI. It's the same outcome as layering, built properly — declarative,
reproducible, in git, and it's what you rebase to.

It's also the whole-system-in-git property that made Nix appealing in the first place, at
a fraction of Nix's cost.

Two failure modes keep it on the shelf for now, and both share a property worth naming:

- **GitHub silently disables scheduled workflows in public repos after 60 days with no
  repository activity.** No email, no log entry. A personal image repo is exactly one you
  never commit to.
- **A failed build is a silent update stall.** bootc keeps pulling the last
  successfully-pushed tag; the host reports "up to date." The only signal is a GitHub
  Actions failure email.

Both failures are **invisible from the desktop**. Layering, for all its costs, fails
loudly and recoverably — an upgrade visibly refuses and one `rpm-ostree uninstall` clears
it. For someone whose failure mode is deferring system maintenance, "quietly stops
updating while looking healthy" is strictly the worse trade.

That calculus changes when the derived image stops being optional.

## What I'm actually doing

1. **Cap the layered list at one.** Currently `emacs-pgtk`, and it's there because there's
   no working alternative — Homebrew's Linux Emacs formula builds `--without-x`, and the
   Flatpak is a stale community build whose sandbox can't spawn host binaries.
2. **Everything else goes to Flatpak, Homebrew, or Distrobox**, in that order. Claude
   Desktop proved this works even for an app with no Fedora packaging at all.
3. **Keep `rpm-ostree status` output in backups**, so the layered list is recoverable
   rather than remembered.
4. **Watch three signals**, not a calendar: the Bluefin blog, the Universal Blue bootc
   migration thread, and ublue-os/bazzite#2726.
5. **When it lands**, build the derived image — with a keepalive workflow so the 60-day
   timer never fires, GitHub Actions failure notifications turned on, and the image
   published publicly, since private GHCR images can't be rebased to.

The trigger to move early rather than wait: the layered list reaching three or four, or
migrating the laptop and wanting both machines identical. Either makes CI earn its keep
before upstream forces the question.
