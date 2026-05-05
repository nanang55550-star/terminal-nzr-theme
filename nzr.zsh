#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                  NZR THEME — main.sh (FINAL)                     ║
# ║         Source ini dari .zshrc untuk aktifkan theme              ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── PATH (auto-detect, tidak perlu edit manual) ──────────────────
# ${0:A:h} = path absolut folder script ini di zsh
NZR_DIR="${0:A:h}"

# Fallback jika dipanggil dari .zshrc via `source`
if [[ -z "$NZR_DIR" || "$NZR_DIR" == "." ]]; then
  NZR_DIR="$HOME/terminal-nzr-theme"
  [[ ! -d "$NZR_DIR" ]] && NZR_DIR="$HOME/nzr-theme"
fi

# ─── LOAD CONFIG & LIBS ───────────────────────────────────────────
source "$NZR_DIR/config.sh"                          2>/dev/null

# Fitur opsional — hanya load jika ON dan file ada
[[ "$AUTOSUGGESTIONS"     == "ON" ]] && source "$NZR_DIR/lib/autosuggestions.sh"  2>/dev/null
[[ "$SYNTAX_HIGHLIGHTING" == "ON" ]] && source "$NZR_DIR/lib/syntax.sh"           2>/dev/null
[[ "$BATGIT_INTEGRATION"  == "ON" ]] && \
  command -v bat &>/dev/null && command -v git &>/dev/null && \
  source "$NZR_DIR/lib/batgit.sh"                                                  2>/dev/null

# ─── ZSH COLORS ───────────────────────────────────────────────────
autoload -U colors && colors
SEP=$'\ue0b0'

# ─── STATUS BAR ───────────────────────────────────────────────────
_nzr_status() {
  local ram disk
  ram=$(free -m 2>/dev/null | awk 'NR==2{printf "%dM/%dM",$3,$2}')
  [[ -z "$ram" ]] && ram="N/A"
  disk=$(df -h . 2>/dev/null | awk 'NR==2{printf "%s/%s",$3,$2}')
  [[ -z "$disk" ]] && disk="N/A"

  echo -n "%{$bg[cyan]%}%{$fg[white]%} %n@%m "
  echo -n "%{$bg[yellow]%}%{$fg[cyan]%}${SEP}%{$fg[black]%} RAM: ${ram} "
  echo -n "%{$bg[magenta]%}%{$fg[yellow]%}${SEP}%{$fg[white]%} DISK: ${disk} "
  echo -n "%{$reset_color%}%{$fg[magenta]%}${SEP}%{$reset_color%}"
}

# ─── DIRECTORY + GIT ──────────────────────────────────────────────
_nzr_dir_git() {
  local branch dirty

  branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  if [[ -n "$branch" ]]; then
    dirty=$(git status --porcelain 2>/dev/null)
    if [[ -n "$dirty" ]]; then
      echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
      echo -n "%{$bg[red]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✗ "
      echo -n "%{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
    else
      echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
      echo -n "%{$bg[green]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✓ "
      echo -n "%{$reset_color%}%{$fg[green]%}${SEP}%{$reset_color%}"
    fi
  else
    echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
    echo -n "%{$reset_color%}%{$fg[blue]%}${SEP}%{$reset_color%}"
  fi
}

# ─── ERROR SEGMENT ────────────────────────────────────────────────
_nzr_error() {
  local code=$?
  [[ $code -eq 0 ]] && return

  local icon
  case $code in
    127) icon="? cmd"     ;;
    126) icon="✘ perm"    ;;
    130) icon="✘ ctrl-c"  ;;
    1)   icon="✘ err"     ;;
    2)   icon="✘ usage"   ;;
    *)   icon="✘ $code"   ;;
  esac

  echo "%{$bg[red]%}%{$fg[white]%} ${icon} %{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
}

# ─── PROMPT ───────────────────────────────────────────────────────
setopt PROMPT_SUBST

PROMPT='
$(_nzr_status)
$(_nzr_dir_git)
%{$bg[black]%}%{$fg[white]%}${SEP} ➜ %{$reset_color%}%{$fg[black]%}${SEP}%{$reset_color%} '

RPROMPT='$(_nzr_error)'

# ─── STARTUP DISPLAY ──────────────────────────────────────────────
_nzr_startup() {
  # Hanya jalan di shell interaktif
  [[ ! -o interactive ]] && return

  if [[ "$SHOW_LOGO" == "ON" || "$SHOW_HEADLINE" == "ON" || "$SHOW_USER_INFO" == "ON" ]]; then
    zsh "$NZR_DIR/display.sh" 2>/dev/null
  fi
}

_nzr_startup
