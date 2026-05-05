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
  for c in "$HOME/terminal-nzr-theme" "$HOME/nzr-theme" \
            "$HOME/.config/nzr-theme" "$HOME/.nzr-theme"; do
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
[[ "${TERM:-}" != "dumb" ]] && SEP=$'\ue0b0' || SEP=">"

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
  local code=$?; [[ $code -eq 0 ]] && return
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

# ─── FUNGSI DISPLAY ───────────────────────────────────────────────
# Dipanggil kapanpun kita mau refresh tampilan
_nzr_show() {
  [[ "${TERM:-}" == "dumb" ]] && return
  zsh "$NZR_DIR/display.sh" 2>/dev/null
}

# ─── ALIASES ──────────────────────────────────────────────────────

# r = refresh display + reload config tanpa kehilangan history
# Menggunakan source (bukan exec zsh) agar history autosuggestions tetap ada
alias r='_nzr_show && source ~/.zshrc'

# rr = reload .zshrc saja tanpa display (untuk debug cepat)
alias rr='source ~/.zshrc'

# rd = tampilkan display saja tanpa reload apapun
alias rd='_nzr_show'

# ─── HOOK: source ~/.zshrc → otomatis tampilkan display ───────────
# Kita override perilaku source dengan preexec + precmd hook
# Cara: deteksi jika perintah yang dijalankan adalah "source ~/.zshrc"
# lalu set flag, kemudian precmd akan trigger display

_nzr_preexec() {
  local cmd="$1"
  # Deteksi source ~/.zshrc atau `. ~/.zshrc`
  if [[ "$cmd" == "source ~/.zshrc" || \
        "$cmd" == "source $HOME/.zshrc" || \
        "$cmd" == ". ~/.zshrc" || \
        "$cmd" == ". $HOME/.zshrc" ]]; then
    _NZR_SHOW_AFTER_SOURCE=1
  fi
}

_nzr_precmd() {
  if [[ -n "$_NZR_SHOW_AFTER_SOURCE" ]]; then
    unset _NZR_SHOW_AFTER_SOURCE
    _nzr_show
  fi
}

# Daftarkan hooks (tidak duplikat jika sudah ada)
autoload -Uz add-zsh-hook
add-zsh-hook preexec _nzr_preexec
add-zsh-hook precmd  _nzr_precmd

# ─── STARTUP DISPLAY ──────────────────────────────────────────────
_nzr_startup() {
  [[ ! -o interactive ]] && return
  [[ "${TERM:-}" == "dumb" ]] && return
  # Flag untuk cegah double display saat source pertama kali
  [[ -n "$_NZR_STARTUP_DONE" ]] && return
  _NZR_STARTUP_DONE=1
  _nzr_show
}

_nzr_startup
