Home
----

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

On a new machine:

    chezmoi init --apply RadicalZephyr/home

Conventions
-----------

- Add files one at a time by name: `chezmoi add ~/.config/foo/bar`. Never add a
  whole directory; several of them (`~/.claude`, `~/.config/gtk-3.0`) hold state
  or secrets next to the config.
- `dot_gitconfig.tmpl` and `dot_bashrc.d/30-env.sh.tmpl` are templates. Edit
  them in this repo or with `chezmoi edit`, not the rendered copies in `~`.
  They gate commit signing and `SSH_AUTH_SOCK` on `op-ssh-sign` being on PATH
  at apply time, so re-run `chezmoi apply` after installing or removing 1Password.
- Shell config lives in `~/.bashrc.d/`; `.bashrc` itself is Fedora's stock file.
  Differences between the host and a distrobox on the same home are decided at
  shell startup, not by templates, because both read the same rendered file.
- The tag `hermit-final` is the last state of the previous Hermit-managed layout.
  Anything not in the current tree was dropped on purpose; see `docs/notes/`.
