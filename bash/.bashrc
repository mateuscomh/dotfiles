#!/bin/bash

# Configurações iniciais
########################

# TMUX 
# if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  #   exec tmux
 #fi


# Configuração do teclado e idioma
########################

# Seta repeticao de teclado
xset r rate 325 15 #Define velocidade de repeticao dos caracteres
export LANG=C.UTF-8 #Variavel LANG UTF8
#setxkbmap -layout us -variant intl #Layout teclado US-Internacional
setxkbmap -layout br -variant abnt2 #Layout teclado US-Internacional

# Opções do shell (shopt)
shopt -s cmdhist # Ativa o histórico de comandos mais recente para cada processo filho
shopt -s histappend # Adiciona cada novo comando ao final do histórico
shopt -s checkwinsize # Verifica o tamanho da janela do terminal periodicamente e ajusta a saída

# Valida se é um shell interativo
[[ "$-" != *i* ]] && return

# Configurações de aparência e prompt
######################################

# Opções do histórico
export HISTTIMEFORMAT="%d/%m/%y %T "
export HISTCONTROL='ignoreboth:erasedups:ignorespace:ignoredups'
export HISTIGNORE='ll:cd ..:cd -:ls:ls -lah:history:pwd:bg:fg:clear'
export PROMPT_COMMAND='history -a'
export HISTSIZE=
export HISTFILESIZE=

# Detecta se suporta cores
force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Função para extrair o nome do branch do Git
parse_git_branch() {
    local branch
    if git rev-parse --is-inside-work-tree &>/dev/null && branch=$(git branch 2>/dev/null | sed -n '/\* /s///p'); then
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "($branch*)"
        else
            echo -e "($branch)"
        fi
    fi
}

# Configura o PS1 (prompt)
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\W\$ '
fi

# Configura o título da janela
case "$TERM" in
  xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u: \w\a\]$PS1"
    printf "\033]0;%s\007" "$1"
    ;;
  *)
    ;;
esac

# Cores e aliases do ls
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  LS_COLORS=$LS_COLORS:'ow=40;97' ; export LS_COLORS
fi

# Aliases 
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# Functions
if [ -f "${HOME}/.bash_functions" ]; then
	source "${HOME}/.bash_functions"
fi

# Completar comandos no Bash
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Comandos adicionais
################################

# Header bash debfetch
${HOME}/bin/debfetch -p 

# Configuração do FZF
#[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Adiciona diretório local ao PATH
PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Inicializa Atuin (se disponível)
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
source "$HOME/.atuin/bin/env"
#source "$HOME/.local/share/blesh/ble.sh"
eval "$(atuin init bash --disable-up-arrow)"



# Added by Antigravity CLI installer
export PATH="/home/miles/.local/bin:$PATH"
