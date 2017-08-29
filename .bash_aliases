# some more ls aliases
alias ll='ls -alhF'
alias la='ls -A'
alias l='ls -CF'

# some exa aliases
alias el='exa -al'
alias eg='exa -alh --git'

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

alias canary='/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary --remote-debugging-port=9222 --no-first-run --user-data-dir=.test-dirac-chrome-profile'

apt-provides() {
  apt-cache show $(apt-cache search "$1" | awk '{ print $1 }' | tr '\n' ' ') |
    sed -n '/^Package: \(.*\)$/ {s//\1/;h}; /^Provides:.*'"$1"'/ {x;p}'
}
