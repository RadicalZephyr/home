# Path to your oh-my-zsh installation.
  export ZSH=~/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="bira"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

# User configuration

export EDITOR='zile'
export VISUAL='zile'
export M2_HOME=/usr/share/maven
export MAVEN_OPTS='-Xmx2048m'
export PIP_REQUIRE_VIRTUALENV=true
export HERMIT_ROOT=~/prog/bash/hermit
export GH_USERNAME="RadicalZephyr"
export LANG=en_US.UTF-8

source ~/.bashrc.secrets

# Add lots of stuff to my PATH

PATH="$PATH:$JAVA_HOME/bin"
PATH="$PATH:$HOME/.local/android-sdk-linux/tools"
PATH="$PATH:$HOME/.local/android-sdk-linux/platform-tools"

PATH="$HOME/.rbenv/bin:$PATH"
PATH="$HOME/.pyenv/bin:$PATH"
PATH="$HOME/local/bin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="$HOME/.multirust/toolchains/stable/cargo/bin:$PATH"
export PATH

# If homebrew is available put coreutils directly on front of PATH
if which brew >/dev/null
then
    PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi

if which keychain >/dev/null
then
    eval $(keychain --eval id_rsa code_reviewer_id_rsa 11F056F5 9F73ECFA)
fi

if which rbenv >/dev/null
then
    eval "$(rbenv init -)"
fi

if which pyenv > /dev/null
then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

if which opam > /dev/null
then
    eval `opam config env`
fi

if which direnv > /dev/null
then
    eval "$(direnv hook bash)"
fi

umask 0077

source $ZSH/oh-my-zsh.sh

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
