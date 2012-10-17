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

# maven build aliases
mvnrun () {
    echo mvn $@
    eval mvn $@
    echo mvn $@
}

alias mvnt='mvnrun clean test'
alias mint='mvnrun clean install -Dmaven.test.skip=true'
