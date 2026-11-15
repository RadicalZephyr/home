# ~/prog/distrobox/Brewfile
#
# Everything Homebrew manages on mistral.
#
# Apply:        unset SUDO_ASKPASS; brew bundle --file=~/prog/distrobox/Brewfile
# Drift check:  brew bundle check --file=~/prog/distrobox/Brewfile
#
# The `unset` is not optional for the 1Password casks, and it applies to
# `brew upgrade` too whenever one of them has a new version. Bazzite exports
# SUDO_ASKPASS globally; Homebrew reads its presence as "use sudo -A"; the X11
# askpass then can't open the display from brew's scrubbed environment and sudo
# gets no password (ublue-os/bazzite#5858). Unset, brew prompts on the terminal.
#
# Flatpaks and VS Code extensions are deliberately absent. This is Homebrew's
# file, not a manifest of everything installed.

tap "ublue-os/tap", trusted: true

brew "chezmoi"
brew "bat"
brew "eza"
brew "zola"
brew "mdbook"
brew "markdownify"
brew "pandoc"
brew "nmap"

# 1Password app and CLI from the Universal Blue tap. Installs the official
# tarball under /home/linuxbrew (that is /var), so nothing in /usr changes and
# the layered-package list stays at one. Chosen over the Flatpak, which cannot
# run the SSH agent or talk to `op`. Details and the settings that must be
# toggled after install: docs/1password-via-homebrew.md
cask "ublue-os/tap/1password-gui-linux", trusted: true
cask "ublue-os/tap/1password-cli-linux", trusted: true

cask "ublue-os/tap/vscodium-linux"
