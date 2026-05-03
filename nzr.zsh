#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                    NZR THEME - MAIN FILE                         ║
# ║         Load config, features, and display startup                 ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── STARTUP & INITIALIZER ─────────────────────────────────────────
# Menentukan folder secara otomatis (pilih salah satu yang ada)
NZR_DIR="$HOME/terminal-nzr-theme"
[[ ! -d "$NZR_DIR" ]] && NZR_DIR="$HOME/nzr-theme"

# Load semua file menggunakan variabel NZR_DIR
source "$NZR_DIR/config.sh" 2>/dev/null
source "$NZR_DIR/lib/utils.sh" 2>/dev/null
source "$NZR_DIR/lib/autosuggestions.sh" 2>/dev/null
source "$NZR_DIR/lib/syntax.sh" 2>/dev/null
source "$NZR_DIR/lib/batgit.sh" 2>/dev/null

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
  
  # Jalankan Logo
  if [[ "$SHOW_LOGO" == "ON" ]]; then
    echo ""
    bash "$NZR_DIR/logo.sh" 2>/dev/null
    echo ""
  fi

  # Jalankan Headline & Info (Panggil pakai zsh agar sukses)
  if [[ "$SHOW_HEADLINE" == "ON" ]]; then
    zsh "$NZR_DIR/user.sh" 2>/dev/null
  fi
}

# Jalankan initializer startup
_nzr_startup
