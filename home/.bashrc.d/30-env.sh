export EDITOR='emacsclient -a ""'
export VISUAL="$EDITOR"
export PIP_REQUIRE_VIRTUALENV=true
{{ if lookPath "op-ssh-sign" -}}
# 1Password's SSH agent holds the keys; ~/.ssh/config points ssh at it too.
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
{{- end }}
