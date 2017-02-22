if [ -f ~/.bashrc ]
then
    source ~/.bashrc
fi

export EDITOR='zile'
export VISUAL='zile'
export MAVEN_OPTS='-Xmx2048m'
export PIP_REQUIRE_VIRTUALENV=true
export SCALA_HOME=$HOME/local/scala-2.11.1
export HERMIT_ROOT=~/prog/bash/hermit
export GH_USERNAME="RadicalZephyr"
export CLOJARS_USERNAME="earthlingzephyr"
export BOOT_EMIT_TARGET=no
export ANSIBLE_COW_SELECTION=random

if [ -f ~/.bashrc.secrets ]; then
    source ~/.bashrc.secrets
fi

# Add lots of stuff to my PATH

PATH="$PATH:$JAVA_HOME/bin"
PATH="$PATH:$HOME/.local/android-sdk-linux/tools"
PATH="$PATH:$HOME/.local/android-sdk-linux/platform-tools"
PATH="$PATH:$SCALA_HOME/bin"

PATH="/usr/local/bin:$PATH"
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
