#!/bin/zsh
# Zsh Autosuggestions Loader

source ~/nzr-theme/config.sh 2>/dev/null
[[ "$AUTOSUGGESTIONS" != "ON" ]] && return

# Cek plugin tersedia
if [[ -d "$HOME/.zsh/zsh-autosuggestions" ]]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
  source "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
  echo "\e[1;33m[Autosuggestions: Plugin tidak ditemukan]\e[0m"
  echo "\e[1;33m[Install: git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions]\e[0m"
fi
