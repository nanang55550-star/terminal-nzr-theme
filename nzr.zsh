#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                  NZR THEME — nzr.zsh (FINAL)                    ║
# ║   Universal: Android Termux · Linux · macOS                     ║
# ╚══════════════════════════════════════════════════════════════════╝

[[ -n "$_NZR_LOADED" ]] && return
_NZR_LOADED=1

# ─── PATH AUTO-DETECT ─────────────────────────────────────────────
_nzr_resolve_dir() {
  [[ -n "${ZSH_SCRIPT:-}" ]] && { echo "${ZSH_SCRIPT:A:h}"; return; }
  local d="${0:A:h}"
  [[ -d "$d" && "$d" != "$HOME" ]] && { echo "$d"; return; }
  for c in "$HOME/terminal-nzr-theme" "$HOME/nzr-theme" "$HOME/.config/nzr-theme" "$HOME/.nzr-theme"; do
    [[ -f "$c/config.sh" ]] && { echo "$c"; return; }
  done
  echo "$HOME/terminal-nzr-theme"
}

NZR_DIR="$(_nzr_resolve_dir)"
export NZR_DIR

if [[ ! -d "$NZR_DIR" ]]; then
  print -P "%F{red}[NZR] Folder tidak ditemukan: $NZR_DIR%f" >&2
  print -P "%F{yellow}[NZR] Set NZR_DIR di .zshrc sebelum source nzr.zsh%f" >&2
  return 1
fi

# ─── LOAD CONFIG ──────────────────────────────────────────────────
[[ -f "$NZR_DIR/config.sh" ]] && source "$NZR_DIR/config.sh"

: "${SHOW_LOGO:=ON}"
: "${SHOW_HEADLINE:=ON}"
: "${SHOW_USER_INFO:=ON}"
: "${SHOW_SYSTEM_INFO:=ON}"
: "${AUTOSUGGESTIONS:=ON}"
: "${SYNTAX_HIGHLIGHTING:=ON}"
: "${BATGIT_INTEGRATION:=OFF}"

# ─── PLUGINS ──────────────────────────────────────────────────────
if [[ "$AUTOSUGGESTIONS" == "ON" ]]; then
  if [[ -f "$NZR_DIR/lib/autosuggestions.sh" ]]; then
    source "$NZR_DIR/lib/autosuggestions.sh" 2>/dev/null
  elif [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
  fi
fi

if [[ "$SYNTAX_HIGHLIGHTING" == "ON" ]]; then
  if [[ -f "$NZR_DIR/lib/syntax.sh" ]]; then
    source "$NZR_DIR/lib/syntax.sh" 2>/dev/null
  elif [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
  fi
fi

if [[ "$BATGIT_INTEGRATION" == "ON" ]]; then
  command -v bat &>/dev/null && command -v git &>/dev/null && \
    [[ -f "$NZR_DIR/lib/batgit.sh" ]] && source "$NZR_DIR/lib/batgit.sh" 2>/dev/null
fi

# ─── ZSH OPTIONS ──────────────────────────────────────────────────
autoload -U colors && colors
setopt PROMPT_SUBST
setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# ─── POWERLINE SEPARATOR ──────────────────────────────────────────
if [[ "${TERM:-}" != "dumb" ]]; then
  SEP=$'\ue0b0'
else
  SEP=">"
fi

# ─── STATUS BAR ───────────────────────────────────────────────────
_nzr_status() {
  local ram disk
  ram=$(free -m 2>/dev/null | awk 'NR==2{printf "%dM/%dM",$3,$2}')
  [[ -z "$ram" ]] && ram="N/A"
  disk=$(df -h "${PWD:-$HOME}" 2>/dev/null | awk 'NR==2{printf "%s/%s",$3,$2}')
  [[ -z "$disk" ]] && disk="N/A"
  echo -n "%{$bg[cyan]%}%{$fg[white]%} %n@%m "
  echo -n "%{$bg[yellow]%}%{$fg[cyan]%}${SEP}%{$fg[black]%} RAM: ${ram} "
  echo -n "%{$bg[magenta]%}%{$fg[yellow]%}${SEP}%{$fg[white]%} DISK: ${disk} "
  echo -n "%{$reset_color%}%{$fg[magenta]%}${SEP}%{$reset_color%}"
}

# ─── DIR + GIT ────────────────────────────────────────────────────
_nzr_dir_git() {
  local branch dirty changed
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    dirty=$(git status --porcelain 2>/dev/null)
    changed=$(printf '%s' "$dirty" | grep -c . 2>/dev/null || echo 0)
    if [[ -n "$dirty" ]]; then
      echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
      echo -n "%{$bg[red]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✗${changed} "
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

# ─── ERROR ────────────────────────────────────────────────────────
_nzr_error() {
  local code=$?
  [[ $code -eq 0 ]] && return
  local icon
  case $code in
    127) icon="? cmd"   ;; 126) icon="✘ perm" ;;
    130) icon="✘ ^C"    ;; 1)   icon="✘ err"  ;;
    2)   icon="✘ usage" ;; *)   icon="✘ $code" ;;
  esac
  echo -n "%{$bg[red]%}%{$fg[white]%} ${icon} %{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
}

# ─── PROMPT ───────────────────────────────────────────────────────
PROMPT='
$(_nzr_status)
$(_nzr_dir_git)
%{$bg[black]%}%{$fg[white]%}${SEP} ➜ %{$reset_color%}%{$fg[black]%}${SEP}%{$reset_color%} '

RPROMPT='$(_nzr_error)'

# ─── ALIASES ──────────────────────────────────────────────────────
# r = reset terminal sepenuhnya (re-exec zsh, bukan sekedar reload)
alias r='clear && exec zsh'
# rr = reload .zshrc tanpa restart (untuk debug config)
alias rr='source ~/.zshrc'

# ─── STARTUP DISPLAY ──────────────────────────────────────────────
_nzr_startup() {
  [[ ! -o interactive ]] && return
  [[ "${TERM:-}" == "dumb" ]] && return

  if [[ "$SHOW_LOGO" == "ON" || "$SHOW_HEADLINE" == "ON" || "$SHOW_USER_INFO" == "ON" ]]; then
    # clear sudah ada di dalam display.sh, tidak perlu double clear di sini
    zsh "$NZR_DIR/display.sh" 2>/dev/null
  fi
}

_nzr_startup
