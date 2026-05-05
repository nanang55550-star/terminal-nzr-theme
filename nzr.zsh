#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                  NZR THEME — nzr.zsh (FINAL)                    ║
# ║         Source ini dari .zshrc untuk aktifkan theme             ║
# ║   Universal: Android Termux · Linux · macOS                     ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── GUARD: Jangan load dua kali ──────────────────────────────────
[[ -n "$_NZR_LOADED" ]] && return
_NZR_LOADED=1

# ─── PATH AUTO-DETECT ─────────────────────────────────────────────
# Saat di-source dari .zshrc, $0 = "zsh" bukan path file ini.
# Jadi kita coba beberapa cara sekaligus.

_nzr_resolve_dir() {
  # Cara 1: $ZSH_SCRIPT tersedia di zsh >= 5.8.1 (jalan langsung)
  if [[ -n "${ZSH_SCRIPT:-}" ]]; then
    echo "${ZSH_SCRIPT:A:h}"; return
  fi
  # Cara 2: ${0:A:h} — reliable jika dijalankan langsung (bukan source)
  local d="${0:A:h}"
  [[ -d "$d" && "$d" != "$HOME" ]] && { echo "$d"; return; }
  # Cara 3: Cari folder theme di lokasi umum
  local candidates=(
    "$HOME/terminal-nzr-theme"
    "$HOME/nzr-theme"
    "$HOME/.config/nzr-theme"
    "$HOME/.nzr-theme"
  )
  for c in "${candidates[@]}"; do
    [[ -f "$c/config.sh" ]] && { echo "$c"; return; }
  done
  # Fallback
  echo "$HOME/terminal-nzr-theme"
}

NZR_DIR="$(_nzr_resolve_dir)"
export NZR_DIR

# Validasi — jika folder tidak ada, hentikan dengan pesan jelas
if [[ ! -d "$NZR_DIR" ]]; then
  print -P "%F{red}[NZR] Folder theme tidak ditemukan: $NZR_DIR%f" >&2
  print -P "%F{yellow}[NZR] Set NZR_DIR di .zshrc sebelum source nzr.zsh%f" >&2
  return 1
fi

# ─── LOAD CONFIG ──────────────────────────────────────────────────
if [[ -f "$NZR_DIR/config.sh" ]]; then
  source "$NZR_DIR/config.sh"
else
  print -P "%F{yellow}[NZR] config.sh tidak ditemukan, pakai defaults%f" >&2
fi

# ─── DEFAULTS (jika config.sh tidak set) ──────────────────────────
: "${SHOW_LOGO:=ON}"
: "${SHOW_HEADLINE:=ON}"
: "${SHOW_USER_INFO:=ON}"
: "${SHOW_SYSTEM_INFO:=ON}"
: "${AUTOSUGGESTIONS:=ON}"
: "${SYNTAX_HIGHLIGHTING:=ON}"
: "${BATGIT_INTEGRATION:=OFF}"

# ─── LOAD PLUGINS OPSIONAL ────────────────────────────────────────
# Autosuggestions
if [[ "$AUTOSUGGESTIONS" == "ON" ]]; then
  if [[ -f "$NZR_DIR/lib/autosuggestions.sh" ]]; then
    source "$NZR_DIR/lib/autosuggestions.sh" 2>/dev/null
  elif [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
  fi
fi

# Syntax Highlighting — harus di-source PALING AKHIR di .zshrc
# Kita defer via precmd jika perlu, tapi source langsung sudah cukup
if [[ "$SYNTAX_HIGHLIGHTING" == "ON" ]]; then
  if [[ -f "$NZR_DIR/lib/syntax.sh" ]]; then
    source "$NZR_DIR/lib/syntax.sh" 2>/dev/null
  elif [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
  fi
fi

# Bat + Git Integration
if [[ "$BATGIT_INTEGRATION" == "ON" ]]; then
  if command -v bat &>/dev/null && command -v git &>/dev/null; then
    [[ -f "$NZR_DIR/lib/batgit.sh" ]] && source "$NZR_DIR/lib/batgit.sh" 2>/dev/null
  fi
fi

# ─── ZSH OPTIONS ──────────────────────────────────────────────────
autoload -U colors && colors
setopt PROMPT_SUBST        # Izinkan ekspresi di dalam PROMPT
setopt AUTO_CD             # Ketik nama folder langsung pindah
setopt HIST_IGNORE_DUPS    # Jangan duplikat di history
setopt SHARE_HISTORY       # Share history antar session

# ─── POWERLINE SEPARATOR ──────────────────────────────────────────
# Fallback ke '>' jika font Powerline tidak tersedia
if [[ "${TERM:-}" != "dumb" ]]; then
  SEP=$'\ue0b0'   # 
  SEP_THIN=$'\ue0b1'
else
  SEP=">"
  SEP_THIN="|"
fi

# ─── STATUS BAR (baris 1) ─────────────────────────────────────────
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

# ─── DIRECTORY + GIT (baris 2) ────────────────────────────────────
_nzr_dir_git() {
  local branch dirty git_info=""

  # Cek apakah dalam git repo
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  if [[ -n "$branch" ]]; then
    dirty=$(git status --porcelain 2>/dev/null)

    # Hitung jumlah file berubah untuk info tambahan
    local changed
    changed=$(echo "$dirty" | grep -c . 2>/dev/null || echo 0)

    if [[ -n "$dirty" ]]; then
      git_info="%{$bg[red]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✗${changed} "
      echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
      echo -n "${git_info}"
      echo -n "%{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
    else
      git_info="%{$bg[green]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✓ "
      echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
      echo -n "${git_info}"
      echo -n "%{$reset_color%}%{$fg[green]%}${SEP}%{$reset_color%}"
    fi
  else
    # Tidak ada git — hanya tampilkan directory
    echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
    echo -n "%{$reset_color%}%{$fg[blue]%}${SEP}%{$reset_color%}"
  fi
}

# ─── ERROR SEGMENT (right prompt) ─────────────────────────────────
_nzr_error() {
  local code=$?
  [[ $code -eq 0 ]] && return

  local icon
  case $code in
    127) icon="? cmd"    ;;
    126) icon="✘ perm"   ;;
    130) icon="✘ ^C"     ;;
    1)   icon="✘ err"    ;;
    2)   icon="✘ usage"  ;;
    *)   icon="✘ $code"  ;;
  esac

  echo -n "%{$bg[red]%}%{$fg[white]%} ${icon} %{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
}

# ─── PROMPT ───────────────────────────────────────────────────────
PROMPT='
$(_nzr_status)
$(_nzr_dir_git)
%{$bg[black]%}%{$fg[white]%}${SEP} ➜ %{$reset_color%}%{$fg[black]%}${SEP}%{$reset_color%} '

RPROMPT='$(_nzr_error)'

# ─── STARTUP DISPLAY ──────────────────────────────────────────────
_nzr_startup() {
  # Hanya jalan di shell interaktif
  [[ ! -o interactive ]] && return
  # Jangan jalan jika TERM=dumb (CI, editor embedded, dll)
  [[ "${TERM:-}" == "dumb" ]] && return
  # Jangan jalan jika dalam tmux pane baru yang bukan pane pertama
  # (opsional — hapus baris ini jika mau tampil di semua pane tmux)
  # [[ -n "$TMUX" && "$(tmux display-message -p '#P')" != "0" ]] && return

  if [[ "$SHOW_LOGO" == "ON" || "$SHOW_HEADLINE" == "ON" || "$SHOW_USER_INFO" == "ON" ]]; then
    zsh "$NZR_DIR/display.sh" 2>/dev/null
  fi
}

_nzr_startup
