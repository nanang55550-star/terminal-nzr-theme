#!/bin/zsh
# Bat + Git Integration Loader

source ~/nzr-theme/config.sh 2>/dev/null
[[ "$BATGIT_INTEGRATION" != "ON" ]] && return

# ─── BAT CONFIG ────────────────────────────────────────────────────
if command -v bat &>/dev/null; then
  export BAT_THEME="ansi"
  alias cat='bat --paging=never'
  alias catl='bat'
else
  echo "\e[1;33m[Bat: Install dengan 'pkg install bat']\e[0m"
fi

# ─── GIT INTEGRATION ─────────────────────────────────────────────
if command -v git &>/dev/null; then
  # Git log dengan bat
  alias glog='git log --oneline --graph --decorate | bat --language=git-log'
  # Git diff dengan bat  
  alias gdiff='git diff | bat --language=diff'
  # Git status dengan bat
  alias gst='git status | bat --language=git-status'
fi
