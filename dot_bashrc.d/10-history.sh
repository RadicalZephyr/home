# Shell history: append rather than overwrite, skip duplicates and
# space-prefixed commands, and keep far more than Fedora's default 1000.
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=100000
HISTFILESIZE=100000
