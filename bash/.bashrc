#!/bin/bash

########################################
# Sessão automática do tmux
########################################
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen|tmux ]] && [ -z "$TMUX" ]; then
    exec tmux
fi

########################################
# Teclado e idioma
########################################
xset r rate 325 15                        # Velocidade de repetição de teclas
export LANG=C.UTF-8                       # Idioma padrão UTF-8
setxkbmap -layout us -variant intl        # Teclado US internacional

########################################
# Opções do shell
########################################
shopt -s cmdhist histappend checkwinsize

# Retorna se não for shell interativo
[[ "$-" != *i* ]] && return

########################################
# Histórico
########################################
export HISTTIMEFORMAT="%d/%m/%y %T "
export HISTCONTROL='ignoreboth:erasedups:ignorespace:ignoredups'
export HISTIGNORE='ll:cd ..:cd -:ls:ls -lah:history:pwd:bg:fg:clear'
export PROMPT_COMMAND='history -a'
export HISTSIZE=
export HISTFILESIZE=

########################################
# Suporte a cores no prompt
########################################
if [ -x /usr/bin/tput ] && tput setaf 1 &> /dev/null; then
    color_prompt=yes
else
    color_prompt=
fi

########################################
# Função para mostrar o branch Git
########################################
parse_git_branch() {
    local branch
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        branch=$(git branch --show-current 2>/dev/null)
        [ -n "$(git status --porcelain)" ] && echo "(${branch}*)" || echo "(${branch})"
    fi
}

########################################
# Prompt personalizado
########################################
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\W\$ '
fi

# Título da janela no terminal
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u: \w\a\]$PS1"
        printf "\033]0;%s\007" "$1"
        ;;
esac

########################################
# Cores e aliases
########################################
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    LS_COLORS="${LS_COLORS}:ow=40;97" ; export LS_COLORS
fi

# Aliases
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# Funções personalizadas
[ -f "${HOME}/.bash_functions" ] && source "${HOME}/.bash_functions"

########################################
# Autocompletar comandos
########################################
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

########################################
# Extras
########################################

# Banner customizado com o Debfetch
/gitclones/debfetch/debfetch -p

# FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# PATH local
export PATH="$HOME/.local/bin:$PATH"

# Atuin (com suporte ao preexec)
[ -f ~/.bash-preexec.sh ] && source ~/.bash-preexec.sh
eval "$(atuin init bash --disable-up-arrow)"