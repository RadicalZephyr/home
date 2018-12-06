# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

use_color=true

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
        && type -P dircolors >/dev/null \
        && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

source ~/.git-prompt
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=1

if ${use_color} ; then
        # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
        if type -P dircolors >/dev/null ; then
                if [[ -f ~/.dir_colors ]] ; then
                        eval $(dircolors -b ~/.dir_colors)
                elif [[ -f /etc/DIR_COLORS ]] ; then
                        eval $(dircolors -b /etc/DIR_COLORS)
                fi
        fi

        if [[ ${EUID} == 0 ]] ; then
                PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\h\[\033[01;34m\] \W\[\033[00;31m\]$(__git_ps1) \[\033[01;34m\]\$\[\033[00m\] '
        else
                PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[01;34m\] \w\[\033[00;31m\]$(__git_ps1) \[\033[01;34m\]\$\[\033[00m\] '
        fi

        alias ls='ls --color=auto'
        alias grep='grep --colour=auto'
else
        if [[ ${EUID} == 0 ]] ; then
                # show root@ when we don't have colors
                PS1='\u@\h \W \$ '
        else
                PS1='\u@\h \w \$ '
        fi
fi

# Try to keep environment pollution down, EPA loves us.
unset use_color safe_term match_lhs

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

if which brew  > /dev/null 2>&1
then
    PREFIX=$(brew --prefix)
else
    PREFIX=""
fi

# enable bash completion in interactive shells
if [ -f $PREFIX/etc/bash_completion ]; then
    . $PREFIX/etc/bash_completion
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found ]; then
  function command_not_found_handle {
          # check because c-n-f could've been removed in the meantime
                if [ -x /usr/lib/command-not-found ]; then
       /usr/bin/python /usr/lib/command-not-found -- $1
                   return $?
    else
       return 127
    fi
  }
fi


# Init all the environment variables
export EDITOR='emacsclient -a ""'
export VISUAL=$EDITOR
export MAVEN_OPTS='-Xmx2048m'
export PIP_REQUIRE_VIRTUALENV=true
export SCALA_HOME=$HOME/.local/scala-2.11.1
export GH_USERNAME="RadicalZephyr"
export CLOJARS_USERNAME="earthlingzephyr"
export BOOT_EMIT_TARGET=no
export BOOT_JVM_OPTIONS="-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Xmx2g -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -Xverify:none"
export ANSIBLE_COW_SELECTION=random
export MINICOM='-con'

if [ -f ~/.bashrc.secrets ]; then
    source ~/.bashrc.secrets
fi

# Add lots of stuff to my PATH
PATH="$PATH:$HOME/.local/android-sdk-linux/tools"
PATH="$PATH:$HOME/.local/android-sdk-linux/platform-tools"
PATH="$PATH:$SCALA_HOME/bin"

PATH="/$HOME/go/bin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="/usr/local/texlive/2014/bin/x86_64-darwin:$PATH"
PATH="$HOME/.rbenv/bin:$PATH"
PATH="$HOME/.pyenv/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"

# If homebrew is available put coreutils directly on front of PATH
if which brew >/dev/null 2>&1
then
    PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi

export PATH

# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

if [ -f ~/.bash_secrets ]; then
    source ~/.bash_secrets
fi

if which keychain >/dev/null 2>&1
then
    keychain 'id_rsa'
fi

if which rbenv >/dev/null 2>&1
then
    eval "$(rbenv init -)"
fi

if which pyenv > /dev/null 2>&1
then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

if which opam > /dev/null 2>&1
then
    eval `opam config env`
fi

if which direnv > /dev/null 2>&1
then
    eval "$(direnv hook bash)"
fi

if [ -f ~/.local/bin/virtualenvwrapper.sh ]
then
    source ~/.local/bin/virtualenvwrapper.sh
fi
