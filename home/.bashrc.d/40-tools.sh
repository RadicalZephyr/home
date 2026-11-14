# Version managers and language toolchains. Each block is a no-op until the
# tool is installed, so this file is safe on a fresh machine.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi
if [ -f ~/.deno/env ]; then
    . ~/.deno/env
    [ -f ~/.local/share/bash-completion/completions/deno.bash ] \
        && . ~/.local/share/bash-completion/completions/deno.bash
fi
