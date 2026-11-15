2026-11-14: moving from chezmoi to plain symlinks
================================================

Context
-------

chezmoi didn't solve a problem I have, and its flow kept getting in the way:
edit the source, not the file; `re-add` when I forget; rendered copies that
drift. By today seven files had drifted, all of them edits made in `~`. The
other push is mise's `bootstrap`, which can link dotfiles, install brew
packages, write `/etc` files and run a setup task from one `mise.toml`. The plan
is for this repo to become the whole machine setup, absorbing `distrobox.ini`,
the `etc/` sources and a minimal Brewfile from `~/prog/distrobox`.

What I did
----------

- Saved the drift into chezmoi first, one commit per file, so nothing was lost
  in the move. Two exceptions. `.bashrc` had only mise's installer line, which
  `40-tools.sh` already does, so I reverted it. `settings.json` went in without
  the generated `autoMode` block, which names local projects and paths, and this
  repo is public. That block now drifts by design.
- Renamed everything to its real name under `home/` in one commit, renames only,
  every file at 100% similarity. The exec bit replaces `executable_`, and
  `private_` disappears because directories are never linked.
- Replaced both templates with runtime choices. `SSH_AUTH_SOCK` is gated on
  `~/.1password` existing, which reads the shared home, so the host and every
  distrobox agree. The old template ran on the host at apply time; a PATH check
  at shell startup would have dropped the agent in boxes without brew on PATH.
  Commit signing moved to `~/.config/git/signing.gitconfig`, included from
  `.gitconfig`; git skips a missing include, and the `bootstrap` task links the
  file only where `op-ssh-sign` is on PATH. With the link, the merged config is
  identical to what chezmoi rendered.

Alternatives considered
-----------------------

- A bare git repo in `~`. Rejected: git would own the home directory, and mise
  couldn't manage the links without fighting it.
- Mirroring `~` at the repo root, the Hermit way. Rejected: this repo is about
  to hold `mise.toml`, `distrobox.ini`, `etc/` and docs too, and with `home/`
  the rule for what gets linked is "everything under `home/`".
- Exporting `GIT_CONFIG_*` from bash for signing, which would be truly runtime.
  Rejected: Magit in an Emacs started from GNOME wouldn't inherit it, and
  commits would silently go unsigned.
- `mise dot track` and its history features. Not used: git is the history.

How mise links
--------------

Tested against throwaway homes before cutting over. `symlink-each` walks the
tree and links files while creating real directories, and leaves unmanaged
files in those directories alone. On a conflict with a real file it refuses and
lists the conflicts; `--force-dotfiles` replaces them with no backup, so the
cutover takes its own backup first.

Still to do
-----------

- Watch `~/.claude/settings.json`: Claude Code rewrites it, and if it saves by
  renaming, the link turns back into a plain file.
- Fold in `~/prog/distrobox` with its history, and write the decision about the
  derived-image plan that folding retires.
- Add the 1Password casks to the `bootstrap` task through real Homebrew; mise's
  own cask support couldn't evaluate the ublue tap's casks.

Addendum: settings.json is merged, not excluded
-----------------------------------------------

mise's `merge` mode (2026.11.8 and later; 2026.9.12 read the entry as a plain
symlink and failed) merges `merge/.claude/settings.json` into the live file key
by key. The repo's keys win and `autoMode` is left alone, so the file no longer
drifts by hand-copy. The source has to live outside `home/`: with it under
`home/`, `symlink-each` claims the same target, and mise either reports
conflicting declarations or, with `--force`, would replace the live file with a
link.
