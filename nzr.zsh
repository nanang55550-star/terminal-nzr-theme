#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                    NZR THEME - MAIN FILE                         ║
# ║         Load config, features, and display startup                 ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── LOAD CONFIG ───────────────────────────────────────────────────
source ~/nzr-theme/config.sh 2>/dev/null

# ─── LOAD UTILITIES ────────────────────────────────────────────────
source ~/nzr-theme/lib/utils.sh 2>/dev/null

# ─── LOAD FEATURES ─────────────────────────────────────────────────
source ~/nzr-theme/lib/autosuggestions.sh 2>/dev/null
source ~/nzr-theme/lib/syntax.sh 2>/dev/null
source ~/nzr-theme/lib/batgit.sh 2>/dev/null

# ─── ZSH COLORS & SEPARATOR ──────────────────────────────────────
autoload -U colors && colors
SEP=$'\ue0b0'

# ─── GIT INFO ────────────────────────────────────────────────────
_nzr_git() {
  local branch dirty
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  dirty=$(git status --porcelain 2>/dev/null)
  
  if [[ -n "$dirty" ]]; then
    echo "%{$fg[blue]%}%{$bg[yellow]%}${SEP}%{$fg[black]%}  ${branch} %{$fg[red]%}✗%{$reset_color%}"
  else
    echo "%{$fg[blue]%}%{$bg[yellow]%}${SEP}%{$fg[black]%}  ${branch} %{$fg[black]%}✓%{$reset_color%}"
  fi
}

# ─── STATUS BAR ──────────────────────────────────────────────────
_nzr_status() {
  local ram disk bat
  ram=$(free -m 2>/dev/null | awk 'NR==2{printf "%dM/%dM", $3,$2}')
  disk=$(df -h . 2>/dev/null | awk 'NR==2{printf "%s/%s", $3,$2}')
  bat=$(termux-battery-status 2>/dev/null | grep percentage | awk '{gsub(/,/,"",$2); print $2}')
  
  local out="%{$bg[yellow]%}%{$fg[black]%} RAM: ${ram} "
  if [[ -n "$bat" ]]; then
    out+="%{$bg[green]%}%{$fg[yellow]%}${SEP}%{$fg[black]%} BAT: ${bat}%% "
  fi
  out+="%{$bg[magenta]%}%{$fg[yellow]%}${SEP}%{$fg[black]%} DISK: ${disk} %{$reset_color%}%{$fg[magenta]%}${SEP}%{$reset_color%}"
  echo "$out"
}

# ─── ERROR SEGMENT ─────────────────────────────────────────────────
_nzr_error() {
  local code=$?
  [[ $code -eq 0 ]] && echo "%{$fg[green]%}✓%{$reset_color%}" && return
  
  local icon
  case $code in
    127) icon="? cmd" ;;
    126) icon="✘ perm" ;;
    130) icon="✘ ctrl-c" ;;
    1)   icon="✘ err" ;;
    2)   icon="✘ usage" ;;
    *)   icon="✘ $code" ;;
  esac
  echo "%{$bg[red]%}%{$fg[white]%} ${icon} %{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
}

# ─── PROMPT ───────────────────────────────────────────────────────
setopt PROMPT_SUBST

PROMPT='%{$fg_bold[cyan]%}%n@%m%{$reset_color%}: %{$fg[cyan]%}%D{%H:%M:%S}%{$reset_color%} $(_nzr_status)
%{$fg[blue]%}%~%{$reset_color%} $(_nzr_git)
%{$fg[cyan]%}❯%{$reset_color%} '

RPROMPT='$(_nzr_error)'

# ─── STARTUP DISPLAY ─────────────────────────────────────────────
_nzr_startup() {
  [[ ! -o interactive ]] && return
  
  clear
  
  # Gunakan folder ~/nzr-theme (sesuai repo GitHub kamu)
  local THEME_DIR="$HOME/nzr-theme"

  # Logo + Headline side-by-side
  if [[ "$SHOW_LOGO" == "ON" && "$SHOW_HEADLINE" == "ON" ]]; then
    echo ""
    # Pastikan fungsi _nzr_side_by_side ada di lib/utils.sh
    _nzr_side_by_side "$THEME_DIR/logo.sh" "$THEME_DIR/user.sh" 6
    _nzr_separator "─"
  elif [[ "$SHOW_LOGO" == "ON" ]]; then
    echo ""
    bash "$THEME_DIR/logo.sh" 2>/dev/null
    _nzr_separator "─"
  elif [[ "$SHOW_HEADLINE" == "ON" ]]; then
    echo ""
    # Gunakan bash atau source, karena user.sh biasanya berisi perintah echo
    bash "$THEME_DIR/user.sh" 2>/dev/null
    _nzr_separator "─"
  fi
  
  # Welcome message
  if [[ "$SHOW_USER_INFO" == "ON" ]]; then
    local name="${USER_NAME:-$USER}"
    local msg="${WELCOME_MSG:-Selamat datang, }"
    # Perbaikan index array RANDOM (zsh array mulai dari 1)
    local colors=($'\e[1;36m' $'\e[1;34m' $'\e[1;35m' $'\e[1;33m' $'\e[1;32m')
    local color=${colors[$(( (RANDOM % 5) + 1 ))]}
    echo ""
    echo "${color}╭────────────────────────────────────────╮\e[0m"
    echo "${color}│  ${msg}\e[1;37m${name}\e[0m${color}  │\e[0m"
    echo "${color}╰────────────────────────────────────────╯\e[0m"
    echo ""
  fi
}

# Jalankan startup
_nzr_startup
