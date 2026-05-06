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

# ─── AUTOSUGGESTIONS LOG SYSTEM ───────────────────────────────────
# File log terpisah dari $HISTFILE — khusus untuk feed autosuggestions
# Batas entri berbeda berdasarkan device:
#   Termux (Android) : 5,000 entri  — storage lebih terbatas
#   Linux desktop    : 20,000 entri — storage longgar
#   macOS            : 15,000 entri — di tengah
#
# Cara kerja:
#   1. Setiap perintah yang dijalankan dicatat ke NZR_SUGGEST_LOG
#   2. zsh-autosuggestions membaca dari file ini via ZSH_AUTOSUGGEST_HISTORY_IGNORE
#   3. Jika jumlah baris melebihi batas, baris PALING LAMA dihapus (FIFO)
#   4. Duplikat dalam 1 sesi tidak dicatat ulang

NZR_SUGGEST_LOG="${NZR_DIR}/zsh_autosuggestions.log"

# Deteksi device untuk tentukan batas
_nzr_detect_log_limit() {
  # Termux / Android
  if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]]; then
    echo 5000; return
  fi
  # macOS
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo 15000; return
  fi
  # Linux — cek apakah ada display (desktop) atau tidak (server/headless)
  if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo 20000; return  # Linux desktop
  fi
  echo 10000  # Linux server / headless
}

NZR_LOG_LIMIT=$(_nzr_detect_log_limit)
export NZR_SUGGEST_LOG NZR_LOG_LIMIT

# Inisialisasi file log jika belum ada
[[ -f "$NZR_SUGGEST_LOG" ]] || touch "$NZR_SUGGEST_LOG"

# Fungsi: catat perintah ke log + trim jika melebihi batas
_nzr_log_cmd() {
  local cmd="$1"

  # Abaikan perintah kosong, spasi saja, atau 1 karakter
  [[ -z "${cmd// }" || ${#cmd} -le 1 ]] && return

  # Abaikan perintah sensitif (password, token, dll)
  local sensitive_pattern='(pass|secret|token|key|auth|login|sudo|ssh|gpg|openssl|curl.*-u|wget.*--password)'
  if printf '%s' "$cmd" | grep -qiE "$sensitive_pattern" 2>/dev/null; then
    return
  fi

  # Abaikan duplikat — cek baris terakhir log
  local last_cmd
  last_cmd=$(tail -1 "$NZR_SUGGEST_LOG" 2>/dev/null)
  [[ "$cmd" == "$last_cmd" ]] && return

  # Tulis ke log
  printf '%s\n' "$cmd" >> "$NZR_SUGGEST_LOG"

  # Trim jika melebihi batas — hapus baris paling lama (head dari atas)
  local line_count
  line_count=$(wc -l < "$NZR_SUGGEST_LOG" 2>/dev/null || echo 0)
  if (( line_count > NZR_LOG_LIMIT )); then
    local excess=$(( line_count - NZR_LOG_LIMIT ))
    # Hapus $excess baris dari atas (paling lama) — portable
    local tmp="${NZR_SUGGEST_LOG}.tmp"
    tail -n "+$(( excess + 1 ))" "$NZR_SUGGEST_LOG" > "$tmp" 2>/dev/null && \
      mv "$tmp" "$NZR_SUGGEST_LOG" 2>/dev/null
  fi
}

# Fungsi: info status log (bisa dipanggil user)
nzr_log_info() {
  local lines
  lines=$(wc -l < "$NZR_SUGGEST_LOG" 2>/dev/null || echo 0)
  local size
  size=$(du -sh "$NZR_SUGGEST_LOG" 2>/dev/null | awk '{print $1}')
  printf "\e[1;36mNZR Autosuggestions Log\e[0m\n"
  printf "  File  : %s\n" "$NZR_SUGGEST_LOG"
  printf "  Entri : %s / %s\n" "$lines" "$NZR_LOG_LIMIT"
  printf "  Ukuran: %s\n" "${size:-N/A}"
  printf "  Device: "
  if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]]; then
    printf "Android Termux\n"
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    printf "macOS\n"
  elif [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    printf "Linux Desktop\n"
  else
    printf "Linux Server\n"
  fi
}

# Fungsi: bersihkan log (bisa dipanggil user)
nzr_log_clear() {
  printf '' > "$NZR_SUGGEST_LOG"
  printf "\e[1;32m✓\e[0m Log autosuggestions dikosongkan\n"
}

# ─── PLUGINS ──────────────────────────────────────────────────────
if [[ "$AUTOSUGGESTIONS" == "ON" ]]; then
  if [[ -f "$NZR_DIR/lib/autosuggestions.sh" ]]; then
    source "$NZR_DIR/lib/autosuggestions.sh" 2>/dev/null
  elif [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
  fi

  # Arahkan autosuggestions untuk membaca dari log NZR + histfile
  # ZSH_AUTOSUGGEST_STRATEGY: history = dari $HISTFILE, completion = dari tab-complete
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50       # max panjang saran yang ditampilkan
  ZSH_AUTOSUGGEST_USE_ASYNC=1              # async agar tidak lag di mobile
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888,underline"

  # Tambahkan log NZR ke histfile sementara agar autosuggestions membacanya
  # Caranya: set HISTFILE ke log gabungan setiap sesi
  # Lebih clean: kita merge log ke history zsh in-memory via fc -R
  _nzr_load_log_to_history() {
    [[ -f "$NZR_SUGGEST_LOG" ]] && fc -R "$NZR_SUGGEST_LOG" 2>/dev/null || true
  }
  _nzr_load_log_to_history
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
setopt HIST_IGNORE_SPACE   # perintah diawali spasi tidak masuk history
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY    # simpan timestamp di histfile

HISTSIZE=50000
SAVEHIST=50000

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
_nzr_show() {
  [[ "${TERM:-}" == "dumb" ]] && return
  zsh "$NZR_DIR/display.sh" 2>/dev/null
}

# ─── ALIASES ──────────────────────────────────────────────────────
alias r='_nzr_show && source ~/.zshrc'   # refresh display + reload config
alias rr='source ~/.zshrc'               # reload config saja
alias rd='_nzr_show'                     # display saja

# Log aliases
alias nzr-log='nzr_log_info'            # info status log
alias nzr-log-clear='nzr_log_clear'     # kosongkan log

# ─── HOOKS ────────────────────────────────────────────────────────
autoload -Uz add-zsh-hook

# preexec: jalankan SEBELUM perintah dieksekusi
_nzr_preexec() {
  local cmd="$1"

  # Catat ke log autosuggestions
  _nzr_log_cmd "$cmd"

  # Deteksi source ~/.zshrc untuk trigger display sesudahnya
  if [[ "$cmd" == "source ~/.zshrc"      || \
        "$cmd" == "source $HOME/.zshrc"  || \
        "$cmd" == ". ~/.zshrc"           || \
        "$cmd" == ". $HOME/.zshrc" ]]; then
    _NZR_SHOW_AFTER_SOURCE=1
  fi
}

# precmd: jalankan SEBELUM prompt ditampilkan
_nzr_precmd() {
  if [[ -n "$_NZR_SHOW_AFTER_SOURCE" ]]; then
    unset _NZR_SHOW_AFTER_SOURCE
    _nzr_show
  fi
}

add-zsh-hook preexec _nzr_preexec
add-zsh-hook precmd  _nzr_precmd

# ─── STARTUP ──────────────────────────────────────────────────────
_nzr_startup() {
  [[ ! -o interactive ]] && return
  [[ "${TERM:-}" == "dumb" ]] && return
  [[ -n "$_NZR_STARTUP_DONE" ]] && return
  _NZR_STARTUP_DONE=1
  _nzr_show
}

_nzr_startup
