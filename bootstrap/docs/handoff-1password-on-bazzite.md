# Handoff: getting 1Password working on the Bazzite host

**Date:** 2026-09-20
**Machine:** `mistral` — Bazzite DX, Fedora 44 atomic (bootc/rpm-ostree), GNOME/Wayland, NVIDIA RTX 3080, Ryzen 7 2700X, user `zefs`
**Proposed starting point (user's):** install the 1Password RPM into `/usr` via `rpm-ostree usroverlay` and see whether it works.

---

## Goal

1Password currently runs as a **Flatpak**, which works but ships **without the browser-helper binary** — so unlocking in the browser is a separate step from unlocking the app. That was accepted as a papercut during setup, with an explicit "revisit if it's too annoying in a few months." This is that revisit.

## Answer this before touching anything

**Which 1Password capability is actually missing?** The answer changes the whole approach and it hasn't been established:

1. **Browser extension integration** (unlock browser from the desktop app) — the known Flatpak gap
2. **CLI (`op`)** — potentially relevant, since disk/restic/B2 credentials live in 1Password and restic runs on a systemd timer
3. **SSH agent**
4. **System-authentication unlock** (unlock with the login password) — this is the PAM-dependent one and the riskiest

These have different solutions. (2) may be satisfiable with Homebrew alone and never touch `/usr`. (4) is the one that carries a lockout risk. Don't solve all four if only one is wanted.

---

## The hazard in the proposed approach

`rpm-ostree usroverlay` is the right instinct — a transient writable `/usr` that evaporates on reboot is exactly the low-risk way to try something. But there's an asymmetry that makes it **not safe by default for this particular package**:

> **`usroverlay` makes `/usr` changes transient. It does NOT make `/etc` changes transient.**

`/etc` is a normal writable directory on this system, merged forward across updates. An RPM that drops files into `/etc` during a usroverlay install **leaves them there permanently**, after the `/usr` half has vanished on reboot.

For 1Password specifically this matters, because the package is known to **modify PAM**. Prior research during setup found a report of a user being **fully locked out after a reinstall** of the layered 1Password RPM on an atomic host. If the RPM writes PAM config into `/etc/pam.d/` referencing a binary that disappears with the overlay, the next boot can fail authentication — including GDM login.

That is the one genuinely dangerous outcome in this task, and it isn't obvious from the plan as stated.

There may also be an `ostree admin unlock --hotfix` mode that persists the overlay across one reboot — worth verifying, because it would let the "does it survive a reboot" question be answered without committing to layering. Confirm behaviour before relying on it.

## Safe test procedure

Establish recovery **before** installing anything:

1. Pin the current deployment: `rpm-ostree status -v` to get the index, then `sudo ostree admin pin 0`
2. Snapshot the PAM state: `sudo ostree admin config-diff | grep -i pam` and copy `/etc/pam.d/` somewhere outside `/etc`
3. Confirm the rollback path is understood: Esc at boot → `ostree:1`. This works even when authentication is broken, which is the failure mode being guarded against
4. Only then: `sudo rpm-ostree usroverlay` and install
5. **Before rebooting**, re-run `ostree admin config-diff` and diff against the snapshot. Anything the RPM wrote into `/etc` is permanent and must be reviewed — and reverted if it references binaries living only in the overlay
6. Reboot and verify login still works

A successful test proves the package runs. It does **not** produce a working installation — the overlay is gone. That's a separate decision, below.

---

## Options, and what each costs

| Option | Status | Cost |
|---|---|---|
| Flatpak (current) | Working | No browser helper; separate unlock |
| Layer the RPM | Untested here | PAM modification, documented lockout report, becomes layered package #2, inherits the bootc shelf life |
| Distrobox + export | Untested | Browser integration is host-side; likely doesn't solve the actual gap |
| Homebrew | **Impossible for the app** — casks are macOS-only and `brew` on Linux refuses them | May still work for the `op` CLI — check |
| Symlink workaround | Reported | Symlinking brew's helper to `/opt/1Password/1Password-BrowserSupport` — community fix, source below |
| Put it in a derived image | Deferred | The "proper" version of layering; see `layering-shelf-life.md` |

Relevant constraint from ADR-001: the layered package list is capped at 3–4, currently **one** (`emacs-pgtk`). 1Password would be the second. Reaching 3–4 is one of the documented triggers for building a derived image instead.

Primary source found during setup: <https://universal-blue.discourse.group/t/1password-with-browser-integration/10880> (~Oct 2025). No clean solution existed at that time — re-check, it may have moved.

---

## Host facts the next agent needs

- `/usr` is read-only via composefs; `/etc` is three-way merged on update; `/var` is a volume written once. `/home` symlinks to `/var/home`
- Layering is `rpm-ostree install`; two deployments retained; rollback is `rpm-ostree rollback` plus reboot
- **`usermod -aG <group>` silently no-ops** for system groups — they live in `/usr/lib/group`, not `/etc/group`. Copy the line into `/etc/group` first. This will bite again if 1Password wants a group
- Existing intentional `/etc` modifications, both load-bearing, both visible in `config-diff`: a `kvm` group line (GID 36), `/etc/modules-load.d/vhost_vsock.conf`, and `/etc/udev/rules.d/51-android.rules`
- Flatpak, Homebrew, Distrobox and `/etc` all survive the coming bootc transition. Layering does not

## Working style

The user is a professional software engineer (Rust/TypeScript/Python) and wants to be pushed back on rather than agreed with. She asks for ADRs and plans before implementation, and prefers concrete experiments over speculation — a preference earned the hard way this session, where several rounds were lost to pre-solving problems that turned out not to exist.

Two lessons worth carrying:

- **Don't add speculative flags or steps.** Two separate detours this session came from solving anticipated rather than observed problems
- **Verify before asserting.** When a claim comes from research rather than the machine, say which, and prefer a command that settles it

## Suggested skills

Call these with the Skill tool:

- **`anthropic-skills:i-have-adhd`** — active throughout the prior session and should be re-invoked. Lead with the next action, number multi-step work, restate state each turn, give concrete time estimates
- **`anthropic-skills:grilling`** — this decision has real trade-offs (lockout risk vs. convenience vs. layering budget) and the user explicitly likes having them stress-tested before committing
- **`engineering:architecture`** — if the outcome changes the layering posture, it belongs in ADR-001 as an update rather than a new document
- **`engineering:debug`** — if the usroverlay test fails in a non-obvious way

## Reference documents

Do not re-derive what these already cover:

- `adr-001-desktop-linux-distro.md` — the distro decision, the layering cap, the derived-image triggers, the bootc shelf life
- `layering-shelf-life.md` — why layering is time-limited, what survives bootc, the "does it lie about the image" rule
- `bazzite-01-the-model.md` — the six invariants, the escape hatches including `usroverlay`
- `bazzite-02-first-week.md` — exercise 2 is the `usroverlay` walkthrough; **unrun as of this handoff**
- `bazzite-03-reference.md` — install decision tree, command cheatsheet, the system-group trap
- `~/prog/distrobox/` — container definitions and README, now a git repo
