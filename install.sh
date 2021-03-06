#!/usr/bin/env bash

set -e
ask() {
  while true; do
    if [ "${2:-}" = "Y" ]; then
      prompt="Y/n"
      default=Y
    elif [ "${2:-}" = "N" ]; then
      prompt="y/N"
      default=N
    else
      prompt="y/n"
      default=
    fi
    read -r -p "$1 [$prompt] " REPLY </dev/tty
    if [ -z "$REPLY" ]; then
      REPLY=$default
    fi
    case "$REPLY" in
      Y*|y*) return 0 ;;
      N*|n*) return 1 ;;
    esac
  done
}
dir=$(pwd)

if ask "Install symlink for bash" Y; then
   ln -svf "${dir}/bash/.bashrc" "${HOME}/.bashrc"
   ln -svf "${dir}/bash/.bash_aliases" "${HOME}/.bash_aliases"
  echo "yes"
fi

if ask "Install symlink for tmux" Y; then
   ln -svf "${dir}/tmux/.tmux.conf" "${HOME}/.tmux.conf"
  echo "yes"
fi

if ask "Install symlink for urxvt?" Y; then
  ln -svf ${dir}/urxvt/.Xresources ${HOME}/.Xresources
  ln -svf ${dir}/urxvt/.urxvt ${HOME}/.urxvt
  echo "yes"
fi

if ask "Install symlink for vim" Y; then
   ln -svf "${dir}/vim/.vimrc" "${HOME}/.vimrc"
  echo "yes"
fi

