# emacsclient shortcuts
alias emacsclientn='emacsclient -n -a ""'
alias emacsc='emacsclient -c -n'
alias cp='cp -v'
alias mv='mv -v'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Make commands more verbose
alias cp='cp -v'
alias mv='mv -v'

function su-apt-update {
    sudo aptitude update && sudo aptitude full-upgrade -y
}

function su-apt-update-down {
   su-apt-update
   sudo shutdown -p now
}