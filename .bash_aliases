# -*- mode: Shell-script -*-

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

# Shorten working with bundler
alias be='bundle exec'

alias pretty-path='echo $PATH | tr : "\n"'

alias serve='boot -d org.clojure/tools.nrepl:0.2.11 -d pandeiro/boot-http serve -d . wait'

alias canary='/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary --remote-debugging-port=9222 --no-first-run --user-data-dir=.test-dirac-chrome-profile'

alias v='nvim'
alias vimc='nvim ~/.config/nvim/init.vim'

apt-provides() {
  apt-cache show $(apt-cache search "$1" | awk '{ print $1 }' | tr '\n' ' ') |
    sed -n '/^Package: \(.*\)$/ {s//\1/;h}; /^Provides:.*'"$1"'/ {x;p}'
}

really-which() {
  ls -lah $(which $1)
}

test-truecolor() {
  awk 'BEGIN{
      s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
      for (colnum = 0; colnum<77; colnum++) {
          r = 255-(colnum*255/76);
          g = (colnum*510/76);
          b = (colnum*255/76);
          if (g>255) g = 510-g;
          printf "\033[48;2;%d;%d;%dm", r,g,b;
          printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
          printf "%s\033[0m", substr(s,colnum+1,1);
      }
      printf "\n";
  }'
}

archive() {
    mv $1{,.bak}
}

backup() {
    cp $1{,.bak}
}

restore() {
    mv $1 ${1%.bak}
}
