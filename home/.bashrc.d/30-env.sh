export EDITOR='emacsclient -a ""'
export VISUAL="$EDITOR"
export PIP_REQUIRE_VIRTUALENV=true
# 1Password's SSH agent holds the keys; ~/.ssh/config points ssh at it too.
# Checked against the shared $HOME rather than PATH, so the host and every
# distrobox agree even where brew isn't on a box's PATH.
if [ -d "$HOME/.1password" ]; then
    export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi
