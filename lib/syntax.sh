#!/bin/zsh
# Syntax Highlighting Loader

source ~/nzr-theme/config.sh 2>/dev/null
[[ "$SYNTAX_HIGHLIGHTING" != "ON" ]] && return

# Cek plugin tersedia
if [[ -d "$HOME/.zsh/zsh-syntax-highlighting" ]]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
  source "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
  echo "\e[1;33m[Syntax Highlighting: Plugin tidak ditemukan]\e[0m"
  echo "\e[1;33m[Install: git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting]\e[0m"
fi
