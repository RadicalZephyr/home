Home
----

My dotfiles. Every file under `home/` is symlinked to the same path in `~` by
mise, from the `[dotfiles]` table in `mise.toml`.

On a new machine, with mise installed:

    git clone git@github.com:RadicalZephyr/home.git ~/.home
    cd ~/.home && mise trust && mise bootstrap

Conventions
-----------

- Files are linked, directories never are. `~/.claude`, `~/.ssh` and
  `~/.config/gtk-3.0` hold state or secrets next to the config, so they stay
  real directories in `~`. To add a file, move it to the same path under
  `home/` and re-run `mise bootstrap`.
- Files a program rewrites itself live under `merge/` instead, and mise merges
  their keys into the real file in `~`. The repo's keys win on every apply, so
  a setting changed in the program reverts unless it's changed here too; keys
  only the live file has are left alone. `merge/.claude/settings.json` is the
  one so far: Claude Code writes a generated `autoMode` block into it that
  names local projects, and that block stays out of this public repo.
- Don't run `chezmoi apply`. The old chezmoi checkout may still be on disk, and
  applying it would replace the links with copies.
- Edits happen in place: the file in `~` is the file in the repo. A program
  that saves by writing a new file and renaming it over the old one replaces
  the link with a plain file; `mise dot status` shows it.
- No templates. Differences between machines, or between the host and a
  distrobox on the same home, are decided at runtime: shell startup checks in
  `~/.bashrc.d/`, and for git, an include of `~/.config/git/signing.gitconfig`,
  which the `bootstrap` task links only where 1Password's `op-ssh-sign` is
  installed.
- Shell config lives in `~/.bashrc.d/`; `.bashrc` itself is Fedora's stock
  file. When an installer appends to `.bashrc`, move its line into
  `.bashrc.d/`.
- The tag `hermit-final` is the last state of the Hermit-managed layout; the
  chezmoi layout is the history from "Start fresh for migrating to chezmoi" up
  to "Move dotfiles to plain names under home/". Anything not in the current
  tree was dropped on purpose; see `docs/notes/`.
