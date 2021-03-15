# -*- mode: Shell-script -*-

# some more ls aliases
alias ll='ls -alhF'
alias la='ls -A'
alias l='ls -CF'

# some exa aliases
alias el='exa -al'
alias eg='exa -alh --git'

# If exa is installed and works, then replace ls with exa
if which exa >/dev/null 2>&1 && exa . >/dev/null ; then
    alias ls='exa'
fi

# Make commands more verbose
alias cp='cp -v'
alias mv='mv -v'
alias dd='dd status=progress'

alias copy-last-command="fc -nl -2 | head -n1 | sed 's/^[ \t]*//' | xclip -i"

# Make diff work better
alias diff='diff -u'

# Shorten working with bundler
alias be='bundle exec'

alias pretty-path='echo $PATH | tr : "\n"'

alias serve='basic-http-server -x'

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

take() {
    mkdir -p $1 && cd $1
}

check-tar-size() {
    tar tvf $1 | awk '{ s += $3 } END { print s }' | numfmt -d , --to=iec --suffix=B
}

ps1_add_newline() {
    local prefix="$(echo $PS1 | cut -d ' ' -f -2)"
    local suffix="$(echo $PS1 | cut -d ' ' -f -2 --complement)"
    PS1="${prefix}"$'\n'"${suffix} "
}

ps1_remove_newline() {
    PS1="$(echo $PS1 | tr $'\n' ' ')"
}

runserver() {
    local destination="$1"
    local port="$2"
    local path="$3"

    # Check if a server is already running on the desired port
    if ! nc -d -w 1 $destination $port
    then
        basic-http-server -x -a ${destination}:${port} $path &
        # Wait until the destination is accepting connections
        while ! nc -d -w 1 $destination $port ; do sleep 0.1s ; done
    fi
}

cratedocs() {
    local destination="127.0.0.1"
    # Calculate a hash of the current directory and use that as the
    # port number. This way we can still launch multiple servers, but
    # launching a server from the same directory multiple times won't happen.
    local port="$(( ( 16#$( echo $PWD | sha1sum | cut -c 1-5 ) % (65535 - 1024) ) + 1024 ))"

    local path="target/doc/"
    local alias="$(basename $PWD).docs"

    cargo doc --all --all-features &
    local pid=$!

    runserver $destination $port $path
    local-domain-alias $port $alias

    wait $pid

    xdg-open http://${alias}/

    echo
}

rustdocs() {
    local destination="127.0.0.1"
    local port="19324"

    local toolchain=$(rustup show active-toolchain | cut -d' ' -f 1)
    local path="$HOME/.rustup/toolchains/${toolchain}/share/doc/rust/html"
    local alias="rust.docs"

    runserver $destination $port $path
    local-domain-alias $port $alias

    xdg-open http://${alias}/

    echo
}

watch() {
    local sleep_time="$1"
    shift 1
    local watch_cmd="$@"

    while true
    do
        clear
        $watch_cmd
        sleep $sleep_time
    done
}

send_files() {
    if [[ $# -ge 1 ]]
    then
        echo "Must be called with at least one argument."
        echo "Usage: send_files SCP_REMOTE_HOST_PATH [LOCAL_FILES*]"
        return 1
    fi

    local ssh_target="${1%%:*}"
    local remote_folder="${1#*:}"
    shift 1
    tar czf - "$@" | ssh "$ssh_target" 'tar xzf - -C $remote_folder '

}
