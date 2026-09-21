2026-09-20: moving from Hermit to chezmoi
=========================================

Context
-------

New machine, Bazzite (Fedora atomic, GNOME on Wayland). I'd cloned this repo
into chezmoi's source directory, but the Hermit layout uses real dotfile
names and chezmoi ignores any source file starting with a dot. So `chezmoi
apply` had deployed exactly four non-dotfiles, one of them a stray
`~/gtk-3.0/`, and nothing else. Fourteen years of accretion was the other
problem: Ubuntu precise package lists, Scala 2.11, Android SDK, four version
managers, a `.zshrc` I never switched to.

What I did
----------

Tagged the tip as `hermit-final`, emptied the tree in one commit, and re-added
files one at a time with `git show hermit-final:<path> > ~/<path>`, an edit,
and `chezmoi add`. One commit per file so each diff against the tag shows
exactly what got cut. Everything not re-added was a decision, not an oversight.

Kept, with fixes:

- gitconfig, global gitignore, mailmap. Dropped the giggle section and two
  aliases whose scripts no longer exist.
- bashrc is now Fedora's stock skel file; everything of mine is in
  `~/.bashrc.d/`. The 2014 Mint preamble (dircolors, colour aliases,
  completion, lesspipe) is all provided by `/etc/profile.d` now. The vendored
  `.git-prompt` was a 2012 snapshot of the script git ships in full.
- aliases: eza aliases gated on eza existing, since its `-F` takes an argument
  and plain ls's doesn't. `apt-provides` gated on apt for a future Debian
  distrobox, and rewritten to use `apt-cache showpkg`'s Reverse Provides after
  a container test showed the old description search returned false positives.
- tmux: xsel to wl-clipboard, plus `set-clipboard on` so tmux's own copy mode
  reaches the terminal clipboard over OSC 52. Not either/or: OSC 52 is
  write-only, so paste still needs wl-paste.
- ssh: only the hosts that still exist.
- check-gits stopped after the first flagged repo (an `exit` inside a piped
  while loop). tmuxstart set a tmux option removed in 2014. git-open-web
  stripped `.git` anywhere in the URL.
- GTK css: the GTK 3 file had lived at `~/gtk-3.0/gtk.css` since 2021, where
  GTK never looks. The GTK 4 file now uses `@headerbar_bg_color` instead of a
  hardcoded grey.
- The pandoc BBCode writer still runs under pandoc 3.11 and its upstream repo
  is gone, so this copy is the only one.

Dropped:

- zsh, rbenv, pyenv, nvm, opam, direnv, keychain, cargo-shuttle, travis, the
  Clojure boot and lein profiles, OCaml init. mise replaces the `*env`s.
- The 2018 gpg-encrypted secrets file. Everything in it is in 1Password.
- gnupg config. Every line was default, dead (SKS pool), or discouraged
  (`auto-key-retrieve`). No keys on this machine anyway.
- The udev rule and pulse config: machine-specific, and PipeWire doesn't
  read `default.pa`.
- startvnc (x11vnc on an X display), the Ubuntu package list, two tmuxstart
  sessions for 2022 projects.

1Password
---------

The Flatpak has no SSH agent socket and no `op-ssh-sign`, so it's installed
through brew instead. The signing block in gitconfig and the `SSH_AUTH_SOCK`
export are chezmoi templates on `lookPath "op-ssh-sign"`: present where the
signer is on PATH, absent elsewhere, so a machine without 1Password commits
unsigned rather than failing.

Alternatives considered
-----------------------

- Bulk-convert then prune. Rejected: carrying the accretion forward and pruning
  "later" is how it got to fourteen years.
- Templating host-vs-distrobox differences. Doesn't work: both read the same
  rendered file from the shared home, so whichever side applied last wins.
  Runtime gates in the shell instead.
- Keeping a custom PS1. Fedora's bash-color-prompt already does the job and
  has a hook for a git segment, so I use that with git's own prompt script.

Still to do
-----------

- `brew install eza` and check the eza aliases in a fresh shell.
- `git push -u origin main` and change the default branch on GitHub; the
  branch still tracks `origin/master`.
- Look at a GTK 3 and a GTK 4 app and decide whether the compact header bars
  are actually what I want.
