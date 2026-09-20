# First week

Nine exercises. Each is a prediction — run it, check what you got against what's written, and if they disagree the model in `bazzite-01-the-model.md` is wrong and worth telling me about.

**Every exercise that changes anything states its undo first.** Nothing here can leave you with an unbootable machine.

---

## Day one — ~30 minutes

### 1. What am I actually running?

*Read-only.*

```bash
rpm-ostree status -v
sudo bootc status
```

**You should see:** one or two deployments. The `●` marks the booted one. A long checksum, a version string like `44.20260916`, and a `LayeredPackages: emacs-pgtk` line.

**What it means:** that checksum is the complete identity of your `/usr`. Two machines with the same checksum and no layering have byte-identical operating systems. Compare the two commands' output — same facts, two vocabularies.

---

### 2. Break `/usr`, on purpose

*Undo: reboot. That's the whole undo. The overlay lives in RAM.*

```bash
touch /usr/bin/hello
```

**You should see:** `Read-only file system`. Expected — invariant 1.

```bash
sudo rpm-ostree usroverlay
touch /usr/bin/hello && ls -l /usr/bin/hello
```

**You should see:** it works. `/usr` is writable now.

```bash
sudo reboot
ls -l /usr/bin/hello
```

**You should see:** `No such file or directory`.

**What it means:** you were never locked out. You have full write access to the entire system, on demand, and it evaporates on reboot instead of accumulating. That is the actual trade — not less power, just no permanent accidents.

Do this one first. It's the exercise that dissolves the "I can't touch anything" feeling.

---

### 3. What configuration do I own?

*Read-only.*

```bash
sudo ostree admin config-diff | sort -k1,1
```

**You should see:** a short list. `M` modified, `A` added, `D` deleted, relative to the image's default `/etc`.

**What it means:** this is the exhaustive list of ways your machine differs from stock in `/etc` — including your `51-android.rules` from the runbook. Every entry here is something the three-way merge will carry forward on each update. Anything *not* here is image default and will silently track upstream.

Run this again in three months. The list growing is how `/etc` drift looks.

---

## Days two to three — ~45 minutes

### 4. Stage an update, inspect it, don't reboot

*Undo: `sudo rpm-ostree cleanup -p` discards a staged deployment.*

```bash
sudo rpm-ostree upgrade
rpm-ostree status
rpm-ostree db diff
```

**You should see:** `upgrade` downloads and stages, and explicitly does **not** touch the running system. `status` now lists the new deployment above the current one. `db diff` shows the package-level changes between them.

**What it means:** you get to read the diff before committing. On Pop, `apt upgrade` was the point of no return. Here the point of no return is `reboot`, and everything before it is inspection.

---

### 5. Pin a known-good deployment, then boot the old one deliberately

*Undo: reboot and pick the other entry. You cannot get stuck — both deployments are complete, bootable systems.*

```bash
rpm-ostree status          # note the index numbers, 0 is current
sudo ostree admin pin 0
rpm-ostree status          # the pinned one now says "pinned: yes"
```

Now reboot, hold **Esc** at boot, and select the entry ending `ostree:1`.

**You should see:** your previous system, working, with the older version string in `rpm-ostree status`.

Reboot again and pick the default to come back.

**What it means:** rollback isn't a recovery procedure you hope works. It's a menu. And pinning is how you keep a specific known-good deployment past the two-deployment window — worth doing before any change you're unsure about.

Unpin later with `sudo ostree admin pin -u 0`.

---

### 6. Roll back from the command line

*Undo: `sudo rpm-ostree rollback` again — it toggles.*

```bash
sudo rpm-ostree rollback
rpm-ostree status
```

**You should see:** the `●` and the ordering swap. The change takes effect on next boot.

**What it means:** same operation as exercise 5, without the boot menu. This is the one you'll actually use when an update misbehaves: `rpm-ostree rollback && systemctl reboot`, and you're back in about ninety seconds.

---

## End of week — ~90 minutes

### 7. Feel what layering costs

*Undo: reinstall it. Nothing is lost; your Emacs config lives in `$HOME`.*

```bash
time sudo rpm-ostree uninstall emacs-pgtk
time sudo rpm-ostree install emacs-pgtk
```

**You should see:** each one rebuilds your local commit and takes noticeably longer than you'd expect for one package — minutes, not seconds.

**What it means:** that time is paid on **every update**, for every layered package, forever. It's why the ADR caps the layered list at three or four. Now you know what the cap is protecting you from, rather than taking it on faith.

---

### 8. A disposable container, start to finish

*Undo: it's disposable. That's the exercise.*

```bash
distrobox create --name scratch --image fedora:44
distrobox enter scratch
# inside:
sudo dnf install -y cowsay && cowsay "hello from fedora"
distrobox-export --bin /usr/bin/cowsay --export-path ~/.local/bin
exit

cowsay "now I'm on the host"      # works — it's exported
distrobox rm --force scratch
```

**You should see:** the exported binary works from your host shell, and after `rm` it stops working.

**What it means:** containers here are not servers, they're environments. Creating and destroying them should feel as cheap as `mkdir`. Note also that `$HOME` was shared the whole time — the container saw your real files. That's Distrobox's design, and it's why `~/.cargo` is already shared between `dev`, `bwapi`, and the host.

---

### 9. Make your containers declarative

*Undo: keep the old containers until the rebuilt one works. Nothing is destroyed until you say so.*

This is the fix for your number-one mess concern. Write `~/prog/distrobox.ini`:

```ini
[dev]
image=fedora:44
additional_packages="gcc-c++ libX11-devel alsa-lib-devel systemd-devel wayland-devel libxkbcommon-devel mesa-vulkan-drivers"
nvidia=true

[bwapi]
image=archlinux:latest
additional_packages="base-devel wine clang"
```

Then:

```bash
distrobox rm --force dev
distrobox assemble create --file ~/prog/distrobox.ini
```

**You should see:** `dev` rebuilt from the file, with its packages already installed, and your `$HOME` — including `~/.cargo` — exactly as it was.

**What it means:** your containers are now a file in git rather than a history of things you typed. Rebuilding one is a command instead of an archaeology project. This is the declarative property you wanted from Nix, applied to the one place where drift actually accumulates, for about twenty lines of config.

Note the `bwapi` box is Arch, not Fedora — 32-bit multilib and Wine are considerably less painful there, and *using a different distro per container is the entire point of Distrobox*.

---

### 10. Check the GPU before you debug Bevy

*Read-only.*

```bash
distrobox enter dev
vulkaninfo | head -40
```

**You should see:** your RTX 3080 listed, with a driver version matching the host's.

**What it means:** if this fails or the versions differ, that's your problem — not your Bevy code. Container Vulkan ICDs must match the host driver, and a mismatch after a host driver update is the classic failure. Check this *first*, every time Bevy misbehaves after an update.

---

## When you're done

You'll have deliberately broken and recovered the system four times. The "afraid I'll break it" feeling doesn't survive that, which is the actual point of the exercise list.

Keep `bazzite-03-reference.md` open for the decision tree and the "don't make a mess" rules.
