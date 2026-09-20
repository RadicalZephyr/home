# The model

Read in one sitting, ~45 minutes. Every command here is safe and read-only unless marked otherwise.

Bazzite looks like a lot of unrelated new things — ostree, bootc, composefs, Flatpak, Distrobox, Homebrew, `ujust`. It isn't. There's one idea underneath, and six consequences that follow from it. Once the idea lands, the rest stops feeling arbitrary.

---

## The one idea

**Your operating system is a container image.**

Not "like" a container image. The same noun as the thing you `podman pull`. `ghcr.io/ublue-os/bazzite-dx-nvidia-gnome:stable` is an OCI image sitting in a registry, built by CI, tagged, versioned, signed. Your machine's job is to unpack one of those and boot it.

That's why your `dev` Distrobox and your operating system are the same kind of object. You already have the mental model; it just never occurred to you that it could apply to `/`.

Everything below falls out of that.

---

## A container refresher, since you said you're rusty

Four ideas, and you need all four for the rest of this to read cleanly.

**An image is an immutable, content-addressed filesystem.** Built once, identified by a hash, byte-identical everywhere it's pulled. Nobody edits an image. You build a new one.

**Images are made of layers.** Each build step produces a layer; layers stack; identical layers are shared on disk between images. This is why rebasing from `bazzite-gnome-nvidia-open` to `bazzite-dx-nvidia-gnome` didn't re-download the world — most layers were already there.

**A container is a running image plus a thin writable layer.** Delete the container, the writable layer goes with it. The image is untouched. This is the part that makes containers feel disposable, and it's exactly the property your OS now has.

**A registry is where images live.** `ghcr.io` is GitHub's. `docker.io` is Docker Hub. Pulling by tag (`:stable`) gets you whatever that tag currently points at; pulling by digest (`@sha256:…`) gets you exactly one thing, forever.

Two things that are different here from the Docker you remember:

- **Podman has no daemon.** Docker runs a root daemon that owns all containers; `docker` is a client that talks to it. Podman just forks the process. Your containers are child processes of your login session, and systemd — not a daemon — is what supervises long-running ones.
- **Podman is rootless by default.** Containers run as you, with your UID mapped to root *inside* the container via user namespaces. "Root in the container" is not root on your machine.

---

## The six invariants

Each one has a command that proves it. Run them as you read.

### 1. `/usr` is a read-only checkout of a commit

Not a directory you manage. A materialized snapshot of an image layer, mounted read-only via composefs.

```bash
rpm-ostree status
```

You'll see one or two **deployments**, each with a checksum and a version. The one marked `●` is what you booted. That checksum is the identity of your entire `/usr`.

There is no `dnf install` into a running system here, because there's nothing to install *into*. `/usr` is not a mutable directory that happens to contain programs; it's a rendered artifact.

### 2. Deployments are plural, and the old one is kept

An update does not modify the system you're running. It builds a **new** deployment alongside the current one and points the bootloader at it. You reboot into the new one. The old one is still on disk.

```bash
rpm-ostree status          # shows both
ostree admin status        # the same thing, lower level
```

Bazzite retains **two** deployments; the older is pruned when a third arrives. Rolling back is not a repair operation — it's selecting the other entry. This is the single most important difference from what you're used to. On Pop, a bad upgrade left you with a broken system to fix. Here it leaves you with a working system you boot instead.

### 3. `/etc` is yours, and it's merged on every update

The image ships its default configuration at `/usr/etc`. Your actual `/etc` starts as a copy of that, and everything you change belongs to you.

On update, the system computes the diff between your current `/etc` and the *previous image's* `/usr/etc`, then applies that diff onto the *new image's* `/usr/etc`. A three-way merge, exactly like git.

```bash
sudo ostree admin config-diff
```

That prints every file in `/etc` you have modified (`M`), added (`A`), or deleted (`D`) relative to the image default. It's the most useful single command on this system. It tells you precisely what "your configuration" consists of — something you could never enumerate on Pop.

### 4. `/var` is a volume, and image content lands there exactly once

This is the gotcha that bites people, so read it twice.

`/var` is persistent, writable, and **not managed by updates at all**. If the image ships files under `/var`, they're unpacked on first install and never again. A later image version changing those files will not change yours. `/var` behaves like a Docker `VOLUME`.

And a lot of the filesystem is actually `/var` wearing a costume:

```bash
ls -ld /home /opt /root /srv /usr/local
```

All symlinks into `/var`. Your home directory's real path is `/var/home/$USER` — which is why restic backs up that path and not `/home`.

So: your data is safe across updates because it lives in `/var`, and it's *invisible* to updates for exactly the same reason.

### 5. Software installs *beside* the image, not into it

Four mechanisms, in the order Bazzite recommends:

| Mechanism | Lands in | Use for |
|---|---|---|
| **Flatpak** | `/var/lib/flatpak`, `~/.var` | GUI apps — Firefox, 1Password |
| **Homebrew** | `/home/linuxbrew` → `/var` | CLI tools |
| **Distrobox** | `/var/lib/containers` | Anything needing system packages, headers, or a different distro |
| **rpm-ostree layering** | the image itself, rebuilt locally | Last resort — your `emacs-pgtk` |

The first three are all just files in `/var`. They don't touch `/usr` and they don't interact with updates at all. That's why they're preferred.

Layering is the odd one out: it takes the base image, adds your packages, and **rebuilds the commit on your machine**. You now boot a locally-modified image. That works, and it's why Emacs is on your host — but it's why layering slows updates, can block rebases, and will eventually conflict with `bootc upgrade`.

```bash
rpm-ostree status          # LayeredPackages line shows yours
```

### 6. Your changes live in exactly three places

- **`/etc`** — merged forward on every update
- **`/var`**, including `$HOME` — never touched by updates
- **the image** — replaced wholesale on every update

Anything not in one of those three is transient and will not survive a reboot. That's the whole rule. When you wonder "will this survive an update," you're really asking "which of the three is this in."

---

## Where the git analogy holds, and where it breaks

ostree really is content-addressed storage with commits, and the vocabulary is borrowed on purpose. Objects are stored by hash under `/ostree/repo`, deployments are checkouts, updates are fast-forwards, rollback is checking out the previous commit.

Where it breaks: **there is no working tree you edit and commit back.** You can't modify `/usr` and snapshot the result. Commits arrive from outside — built by CI, pulled from a registry. Your machine is a consumer of commits, not an author of them.

Which is exactly why the derived-image option exists, and why it's in the ADR as the likely destination. Building your own image is how you become an author.

---

## The escape hatches

You said the worry is not knowing how to touch it. Here is every way to touch it, from least to most permanent. None of these are exotic; they're the documented interfaces.

**`sudo rpm-ostree usroverlay`** — makes `/usr` writable right now, as a transient overlay in RAM. Install whatever, try whatever, break whatever. It **vanishes completely on reboot**. This is the pressure-release valve: you can always do the thing, you just can't do it permanently by accident.

**`sudo rpm-ostree apply-live`** — applies a staged change to the running system without rebooting. Useful, occasionally surprising; prefer rebooting.

**`rpm-ostree install <pkg>`** — layering. Permanent, rebuilds your commit, costs update time.

**`ostree admin pin <index>`** — marks a deployment as never-prune. This is how you keep a known-good system around past the two-deployment window.

**`rpm-ostree rollback`** — switch to the other deployment on next boot.

**Bootloader menu** — Esc at boot, pick `ostree:1`. Works even when the running system is too broken to run commands. This is your true bottom.

---

## Two vocabularies for the same thing

You'll see both `rpm-ostree` and `bootc` in documentation, and it's confusing because the transition is live.

`bootc` is the newer interface. On an unmodified system, `bootc upgrade` and `rpm-ostree upgrade` do effectively the same thing. Bazzite's docs still say rpm-ostree; Bluefin's docs — same underlying system, better written — already say bootc.

For now: use `rpm-ostree` for anything involving your layered package, and either for status and rollback. Note that `bootc status` needs root while `rpm-ostree status` doesn't.

The thing to know: **`bootc upgrade` refuses to run on a system that's been mutated client-side.** Your layered Emacs is client-side mutation. It works today because Bazzite still drives updates through rpm-ostree, but this is the clock referenced in the ADR.

---

## What to do with this

Nothing yet. Read `bazzite-02-first-week.md` and run the exercises — they're each a prediction you can check, and the point is to watch the model hold rather than take my word for it.

The first one takes two minutes and answers "what am I actually running."
