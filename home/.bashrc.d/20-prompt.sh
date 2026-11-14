# Add a git segment to Fedora's colour prompt (bash-color-prompt), using the
# git-prompt script that ships with git rather than a vendored copy.
if [ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    . /usr/share/git-core/contrib/completion/git-prompt.sh
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWSTASHSTATE=1
    GIT_PS1_SHOWUNTRACKEDFILES=1
    GIT_PS1_SHOWUPSTREAM=auto
    PROMPT_GIT_BRANCH='$(__git_ps1 " (%s)")'
    PROMPT_GIT_COLOR=31
fi
