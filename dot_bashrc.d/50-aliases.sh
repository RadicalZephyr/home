# --- Listing files -----------------------------------------------------------
# eza is a Rust ls replacement; its -F takes a "when" argument, plain ls's
# does not, so the two sets of aliases differ.
if command -v eza >/dev/null 2>&1 && eza . >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -alhF auto'
    alias la='eza -a'
    alias l='eza -F auto'
    alias el='eza -al'
    alias eg='eza -alh --git'
else
    alias ll='ls -alhF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# --- Safer / chattier coreutils ----------------------------------------------
alias cp='cp -v'
alias mv='mv -v'
alias dd='dd status=progress'
alias diff='diff -u'

# --- Small conveniences ------------------------------------------------------
alias pretty-path='echo $PATH | tr : "\n"'
alias serve='basic-http-server -x'
alias global-pip='PIP_REQUIRE_VIRTUALENV=0 pip'
alias githooks-link="test -d .git -a -d .git-hooks && ( cd .git/hooks ; ln -si -t . ../../.git-hooks/* ; cd - )"

if command -v wl-copy >/dev/null 2>&1; then
    alias copy-last-command="fc -nl -2 | head -n1 | sed 's/^[ \t]*//' | wl-copy"
elif command -v xclip >/dev/null 2>&1; then
    alias copy-last-command="fc -nl -2 | head -n1 | sed 's/^[ \t]*//' | xclip -i"
fi

if command -v nvim >/dev/null 2>&1; then
    alias v='nvim'
    alias vimc='nvim ~/.config/nvim/init.vim'
fi

if command -v flatpak >/dev/null 2>&1; then
    alias pixelorama="flatpak run com.orama_interactive.Pixelorama"
    alias libresprite="flatpak run com.github.libresprite.LibreSprite"
fi

# --- apt (only inside a Debian/Ubuntu distrobox; the host has no apt) --------
# Which packages provide a virtual package, e.g. `apt-provides awk`.
if command -v apt-cache >/dev/null 2>&1; then
    apt-provides() {
        apt-cache showpkg "$1" | sed -n '/^Reverse Provides:/,$p' | awk 'NR>1 { print $1 }'
    }
fi

# --- Functions ---------------------------------------------------------------
really-which() {
    ls -lah "$(which "$1")"
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
    mv "$1"{,.bak}
}

backup() {
    cp "$1"{,.bak}
}

restore() {
    mv "$1" "${1%.bak}"
}

take() {
    mkdir -p "$1" && cd "$1"
}

check-tar-size() {
    tar tvf "$1" | awk '{ s += $3 } END { print s }' | numfmt -d , --to=iec --suffix=B
}

# Start basic-http-server on destination:port serving path, unless something
# is already listening there.
runserver() {
    local destination="$1"
    local port="$2"
    local path="$3"
    if ! nc -d -w 1 "$destination" "$port"
    then
        basic-http-server -x -a "${destination}:${port}" "$path" &
        while ! nc -d -w 1 "$destination" "$port" ; do sleep 0.1s ; done
    fi
}

# Build and serve the docs for the crate in the current directory, on a port
# derived from the path so each crate gets a stable one. Needs
# local-domain-alias, which lives in its own repo.
cratedocs() {
    local destination="127.0.0.1"
    local port="$(( ( 16#$( echo "$PWD" | sha1sum | cut -c 1-5 ) % (65535 - 1024) ) + 1024 ))"
    local path="target/doc/"
    local alias="$(basename "$PWD").docs"
    cargo doc --all --all-features &
    local pid=$!
    runserver "$destination" "$port" "$path"
    local-domain-alias "$port" "$alias"
    wait $pid
    xdg-open "http://${alias}/"
    echo
}

# Serve the std docs for the active rustup toolchain.
rustdocs() {
    local destination="127.0.0.1"
    local port="19324"
    local toolchain
    toolchain=$(rustup show active-toolchain | cut -d' ' -f 1)
    local path="$HOME/.rustup/toolchains/${toolchain}/share/doc/rust/html"
    local alias="rust.docs"
    runserver "$destination" "$port" "$path"
    local-domain-alias "$port" "$alias"
    xdg-open "http://${alias}/"
    echo
}

# tar local files straight into a directory on a remote host.
send_files() {
    if [[ $# -lt 1 ]]
    then
        echo "Must be called with at least one argument."
        echo "Usage: send_files SCP_REMOTE_HOST_PATH [LOCAL_FILES*]"
        return 1
    fi
    local ssh_target="${1%%:*}"
    local remote_folder="${1#*:}"
    shift 1
    tar czf - "$@" | ssh "$ssh_target" "tar xzf - -C '$remote_folder'"
}

status() {
    if [[ $? -eq 0 ]]
    then
        echo "Great Success!"
    else
        echo "Tragic Failure!"
    fi
}

# Convert the split HTML sections of an unpacked Kindle epub to markdown.
pandoc-markdownify() {
    if ! command -v pandoc > /dev/null 2>&1
    then
        echo "Pandoc must be installed to markdownify an epub"
        return 1
    fi
    local ROOT="${1%/}"
    local OUTDIR="${2:-.}"
    OUTDIR="${OUTDIR%/}"
    for file in "${ROOT}/kindle_split_"*.html
    do
        local basefile="${file%.html}"
        local number="${basefile#${ROOT}/kindle_split_}"
        local outfile="section_${number}.md"
        pandoc "$file" -f html -t markdown -o "${OUTDIR}/$outfile"
    done
}

gh-clear-notifications() {
    echo "Checking gh auth status"
    if gh auth status
    then
        for id in $(gh api 'notifications?unread=true' --jq 'map(select(.unread) | .id)[]')
        do
            echo "Clearing notification ${id}"
            gh api --method DELETE -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' notifications/threads/"${id}"
        done
        echo "Finished clearing all notifications!"
    fi
}
