# 1Password on the host: Homebrew casks, not layering

- **Status:** Done, 2026-09-20
- **Relates to:** `handoff-1password-on-bazzite.md` (the plan this replaced),
  `layering-shelf-life.md` §"The rule this gives you",
  [ADR-0001](decisions/0001-desktop-linux-distro.md) §"Custom derived image: not now"

---

## What I wanted

The SSH agent and the `op` CLI, and generally the whole developer surface. The Flatpak
can't do either: 1Password's own docs say the agent doesn't work in Flatpak or Snap
installs, and the CLI integration needs the app's binaries to be root-owned and setgid,
which a sandbox can't provide. Browser integration was the original complaint and turned
out to be the least important of the three.

## What the handoff got wrong

Two claims that shaped the whole usroverlay plan didn't survive contact with the machine:

- **"The RPM modifies PAM."** It doesn't. The tarball's `after-install.sh` is the same
  script the RPM runs; it writes a polkit action, a browser allowlist under
  `/etc/1password`, creates one group, and sets setuid on `chrome-sandbox`. The string
  `pam` appears nowhere in it. System-auth unlock and CLI authorization both go through
  polkit, and gnome-shell is already the polkit agent.
- **"Casks are macOS-only."** Homebrew 7 runs Linux casks, and Universal Blue publishes
  two in their tap: `1password-gui-linux` and `1password-cli-linux`.

With those gone, usroverlay stopped being the right experiment. It would have tested the
RPM, and the RPM is the option we don't want.

## What it actually writes

The casks unpack the official tarball into the brew prefix and then do, with `sudo`, the
parts of `after-install.sh` that need root. Everything lands in the columns that survive
bootc:

| Written | Where | Survives bootc |
|---|---|---|
| app, `op`, `op-ssh-sign`, browser helper | `/home/linuxbrew/.linuxbrew/Caskroom/…` | Yes, `/var` |
| polkit action (unlock, authorize CLI, authorize agent) | `/etc/polkit-1/actions/com.1password.1Password.policy` | Yes, `/etc` |
| browser allowlist, with `flatpak-session-helper` appended | `/etc/1password/custom_allowed_browsers` | Yes, `/etc` |
| groups `onepassword` (1002) and `onepassword-cli` (1003) | `/etc/group` | Yes, `/etc` |
| desktop entry, icon, native-messaging manifests | `~/.local/share`, `~/.mozilla`, `~/.config/*` | Yes, `$HOME` |

`ostree admin config-diff` before and after differs by exactly the polkit file and the
`/etc/1password` directory; `/etc/group` gained the two lines. `/usr` untouched. The
layered list is still `emacs-pgtk` alone.

The `/etc` files are the cask's output, not mine, so they're not mirrored under `etc/` in
this repo. The Brewfile is the source; `brew bundle` regenerates them.

## The one trap

As of 2026-09-20 every cask with a privileged step fails on Bazzite, and it isn't the
cask's fault.  Bazzite's `/etc/profile.d/askpass.sh` exports `SUDO_ASKPASS`
unconditionally. Homebrew reads the variable's mere presence as "use `sudo -A`", which
forbids terminal prompting.  Brew's scrubbed environment keeps `DISPLAY` but drops
`XAUTHORITY`, so the X11 askpass can't open the display, and sudo gets no password. Filed
the day before I hit it:
[ublue-os/bazzite#5858](https://github.com/ublue-os/bazzite/issues/5858).

The fix is one line, run before `brew install`, `brew bundle`, or any `brew upgrade` that
includes 1Password:

```bash
unset SUDO_ASKPASS
```

Brew then prompts on the terminal like anything else. A cached ticket from `sudo -v` did
**not** work here, despite being listed as a workaround in the issue. Don't bother.

## Settings that have to be toggled by hand

Fresh profile in `~/.config/1Password`, so sign in again, then:

1. General → **Keep 1Password in the system tray**. The agent dies with the app otherwise.
2. Security → **Unlock using system authentication**. Polkit prompt.
3. Developer → **Integrate with 1Password CLI** and **Use the SSH agent**.

## Verified

- `~/.1password/agent.sock` exists; `ssh-add -l` against it lists the key.
- `ssh -T git@github.com` authenticates, and `ssh -v` shows the key offered from
  `agent`, not the file. `~/.ssh/config` already had `IdentityAgent` pointing at the
  socket from before, so nothing there changed.
- `op account list` and `op vault list` return through the app integration, no manual
  sign-in.
- Flatpak removed. Its profile under `~/.var/app/com.onepassword.OnePassword` is still
  there; nothing reads it.

## Consequences I'm accepting

- **`brew upgrade` will prompt for sudo** whenever a 1Password cask has a new version,
  because the postflight re-applies root ownership. Unattended upgrades will stall on
  it. Same `unset` applies.
- **The tap lags upstream by days, not weeks.** It was on 8.12.36 while Flathub had
  8.12.12. Fine.

## Follow-ups, none started

- Git commit signing via `op-ssh-sign`. The binary is on `PATH` already. (Fixed 2026-09-20)
- Browser integration. Firefox is a Flatpak, and the cask wrote its native-messaging
  manifest to the host's `~/.mozilla`, which the Flatpak doesn't see. The allowlist
  already permits `flatpak-session-helper`, so it may only need the manifest copied into
  `~/.var/app/org.mozilla.firefox/.mozilla/native-messaging-hosts/`. Untested.
- Watch #5858. When it closes, the `unset` line in the Brewfile header comes out.
