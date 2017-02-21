# some more ls aliases
alias ll='ls -alhF'
alias la='ls -A'
alias l='ls -CF'

# Make commands more verbose
alias cp='cp -v'
alias mv='mv -v'

# Make diff work better
alias diff='diff -u'

# Make emacs more functional
alias emacsc='emacsclient -n'

# Shorten working with bundler
alias be='bundle exec'

alias pretty-path='echo $PATH | tr : "\n"'

alias serve='boot -d org.clojure/tools.nrepl:0.2.11 -d pandeiro/boot-http serve -d . wait'
