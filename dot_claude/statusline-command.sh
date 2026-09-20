#!/usr/bin/env bash
# Claude Code statusLine, mirroring the interactive bash prompt:
#   - Fedora's bash-color-prompt (/etc/profile.d/bash-color-prompt.sh):
#     bold green "user@host:cwd"
#   - the git segment added in ~/.bashrc.d/20-prompt.sh:
#     red " (branch *+ >)" via git-prompt.sh's __git_ps1
#
# Trailing "$"/">" prompt characters are intentionally omitted.

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd')

user=$(whoami)
host=$(hostname -s)
dir="${cwd/#$HOME/\~}"

git_segment=""
git_prompt_sh=/usr/share/git-core/contrib/completion/git-prompt.sh
if [ -f "$git_prompt_sh" ] && [ -n "$cwd" ]; then
    git_segment=$(cd "$cwd" 2>/dev/null && \
        GIT_PS1_SHOWDIRTYSTATE=1 \
        GIT_PS1_SHOWSTASHSTATE=1 \
        GIT_PS1_SHOWUNTRACKEDFILES=1 \
        GIT_PS1_SHOWUPSTREAM=auto \
        bash --norc -c ". '$git_prompt_sh'; __git_ps1 ' (%s)'" 2>/dev/null)
fi

# --git-dir/status calls above avoid the user's global git config locks by
# running in a plain subshell; keep any future git calls here on
# --no-optional-locks to stay safe if this runs concurrently.

printf '\033[1;32m%s@%s:%s\033[0m\033[31m%s\033[0m' "$user" "$host" "$dir" "$git_segment"
