#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                  NZR THEME — nzr.zsh (FINAL)                    ║
# ║   Universal: Android Termux · Linux · macOS                     ║
# ╚══════════════════════════════════════════════════════════════════╝

[[ -n "$_NZR_LOADED" ]] && return
_NZR_LOADED=1

# ─── PATH AUTO-DETECT ─────────────────────────────────────────────
_nzr_resolve_dir() {
  # 1. NZR_DIR yang sudah di-set user di .zshrc
  [[ -n "${NZR_DIR:-}" && -f "$NZR_DIR/nzr.zsh" ]] && { echo "$NZR_DIR"; return; }
  # 2. Lokasi file ini sendiri (%x = file yang sedang di-source; $0 di dalam
  #    fungsi hanya nama fungsi, jadi dulu hasilnya = folder kerja saat shell dibuka)
  local self="${${(%):-%x}:A:h}"
  [[ -f "$self/nzr.zsh" ]] && { echo "$self"; return; }
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

# Baris error (baris paling atas dari prompt 4 baris)
: "${SHOW_ERROR_LINE:=ON}"       # ON = 4 baris (error + 3 baris biasa) | OFF = 3 baris
: "${ERROR_LINE_MODE:=always}"   # always = selalu tampil | error = hanya saat gagal
: "${SHOW_CMD_DURATION:=ON}"     # tampilkan lama eksekusi perintah
: "${CMD_DURATION_MIN:=1}"       # durasi minimum (detik) agar tampil, boleh desimal
: "${ERROR_SHOW_CMD:=ON}"        # tampilkan perintah yang gagal
[[ "$CMD_DURATION_MIN" == (<->|<->.<->) ]] || CMD_DURATION_MIN=1
: "${ERROR_SUGGEST:=ON}"         # saran "mungkin: git" saat salah ketik perintah
: "${ERROR_SHOW_JOBS:=ON}"       # jumlah job background di baris error
: "${ERROR_SHOW_TIME:=OFF}"      # jam selesai perintah di baris error

# Notifikasi saat perintah lama selesai
: "${NOTIFY_LONG_CMD:=ON}"
: "${NOTIFY_MIN_SECONDS:=30}"
: "${NOTIFY_BELL:=OFF}"
: "${NOTIFY_IGNORE:=vim nvim vi nano emacs less more man top htop btop ssh mosh tmux screen watch fzf ranger mc}"
[[ "$NOTIFY_MIN_SECONDS" == (<->|<->.<->) ]] || NOTIFY_MIN_SECONDS=30

# Lain-lain
: "${SET_TITLE:=ON}"             # judul tab/jendela terminal ikut folder & perintah
: "${HIST_SCRUB:=ON}"            # perintah berisi rahasia tidak ditulis ke HISTFILE
: "${EXTRA_TOOLS:=ON}"           # mkcd, up, bak, extract
: "${AUTO_GREETING:=ON}"         # sapaan sesuai waktu (pagi/siang/sore/malam)
: "${SHOW_TIPS:=ON}"             # tip acak di bawah tampilan startup

# Mesin prompt async: data dihitung di latar belakang, prompt tidak pernah menunggu
: "${ASYNC_PROMPT:=ON}"

# Tema warna (nzr theme) dan statistik pemakaian lokal (nzr stats)
: "${NZR_THEME:=default}"          # default | nord | dracula | gruvbox | tokyonight | catppuccin
: "${NZR_COLOR_DEPTH:=auto}"       # auto | truecolor | 256
: "${STATS_LOG:=ON}"               # catat NAMA perintah (tanpa argumen) untuk nzr stats

NZR_VERSION="3.0.0"

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

# Inisialisasi file log (privat: hanya pemilik yang boleh baca)
[[ -f "$NZR_SUGGEST_LOG" ]] || ( umask 077; touch "$NZR_SUGGEST_LOG" )
chmod 600 "$NZR_SUGGEST_LOG" 2>/dev/null

# Fungsi: catat perintah ke log + trim jika melebihi batas
_nzr_log_cmd() {
  local cmd="$1"

  # Abaikan perintah kosong, spasi saja, atau 1 karakter
  [[ -z "${cmd// }" || ${#cmd} -le 1 ]] && return

  # Abaikan perintah sensitif (password, token, dll)
  [[ "${(L)cmd}" =~ $_NZR_SENSITIVE_RE ]] && return

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
    local tmp="${NZR_SUGGEST_LOG}.tmp"
    # umask 077: file sementara pun tidak boleh terbaca user lain
    ( umask 077; tail -n "+$(( excess + 1 ))" "$NZR_SUGGEST_LOG" > "$tmp" 2>/dev/null ) && \
      mv "$tmp" "$NZR_SUGGEST_LOG" 2>/dev/null
    chmod 600 "$NZR_SUGGEST_LOG" 2>/dev/null
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
# eval dipakai agar terminal/locale non-UTF-8 jatuh ke ">" dan tidak membatalkan
# seluruh file (zsh menolak $'\ue0b0' di locale non-UTF-8 sebagai error parse)
if [[ "${TERM:-}" == "dumb" ]] || ! eval "SEP=\$'\\ue0b0'" 2>/dev/null; then
  SEP=">"
fi

# ─── MODUL ────────────────────────────────────────────────────────
# errorline : baris 1 dari prompt 4 baris (error, saran, durasi)
# notify    : notifikasi perintah lama
# cli       : perintah `nzr`
# tools     : mkcd, up, bak, extract (opsional)
for _m in privacy theme prompt errorline notify insights cli; do
  [[ -f "$NZR_DIR/lib/$_m.sh" ]] && source "$NZR_DIR/lib/$_m.sh"
done
[[ "$EXTRA_TOOLS" == "ON" && -f "$NZR_DIR/lib/tools.sh" ]] && source "$NZR_DIR/lib/tools.sh"
unset _m
(( $+functions[_nzr_theme_apply] )) && _nzr_theme_apply "$NZR_THEME"

# ─── PROMPT ───────────────────────────────────────────────────────
# 4 baris:
#   1. error line   ← BARU (kosong/hilang bila SHOW_ERROR_LINE=OFF)
#   2. status       user@host · RAM · DISK
#   3. dir + git
#   4. input        ➜
PROMPT='
${_NZR_ERRLINE}${_NZR_SEG_STATUS}
${_NZR_SEG_DIRGIT}
%{$bg[black]%}%{$fg[white]%}${SEP} ➜ %{$reset_color%}%{$fg[black]%}${SEP}%{$reset_color%} '

RPROMPT='${_NZR_RERR}'

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

  # Untuk error line: tandai ada perintah yang jalan, simpan teks + waktu mulai
  _NZR_CMD_RAN=1
  _NZR_LAST_CMD="$cmd"
  _NZR_CMD_START=$EPOCHREALTIME

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

# precmd #1: tangkap status perintah terakhir. WAJIB paling pertama,
# karena $? dan pipestatus hilang begitu ada perintah lain yang jalan.
# (satu 'local' menangkap keduanya sekaligus)
_nzr_precmd_status() {
  local _st=$? _ps=("${pipestatus[@]}")

  if (( _NZR_CMD_RAN )); then
    _NZR_CMD_RAN=0
    _nzr_err_build $_st "${_ps[@]}"
    _nzr_notify $_st
    # perintah theme (nzr, fix, r, ...) tidak menimpa "perintah nyata" terakhir
    if ! _nzr_is_meta "$_NZR_LAST_CMD"; then
      _NZR_REAL_CMD="$_NZR_LAST_CMD"; _NZR_REAL_ST=$_st; _NZR_REAL_PS=("${_ps[@]}")
      _NZR_REAL_DUR=$_NZR_LAST_DUR;  _NZR_REAL_TIME="$_NZR_LAST_TIME"
      _nzr_stats_record $_st $_NZR_LAST_DUR "$_NZR_LAST_CMD"
    fi
  elif (( ${#_NZR_E_TX} == 0 )); then
    # prompt pertama di sesi ini, belum ada perintah
    _NZR_E_BG=(cyan); _NZR_E_FG=(black); _NZR_E_TX=("${_NZR_G[ready]} siap"); _NZR_E_PR=(0); _NZR_E_FAIL=0
  fi
  # Enter kosong / Ctrl+C di prompt: tidak ada preexec → status lama dipertahankan
  _nzr_err_render
}

# precmd #2: jalankan SEBELUM prompt ditampilkan
_nzr_precmd() {
  if [[ -n "$_NZR_SHOW_AFTER_SOURCE" ]]; then
    unset _NZR_SHOW_AFTER_SOURCE
    _nzr_show
  fi
}

# Judul tab/jendela: folder saat idle, perintah saat berjalan.
# Teks dibuat aman dulu (karakter kontrol/ESC jadi terlihat) agar tidak bisa
# menyisipkan escape sequence ke terminal.
_nzr_title() {
  [[ "$SET_TITLE" == "ON" && "${TERM:-}" != (dumb|linux) ]] || return 0
  local t="${(V)1}"
  print -n -- $'\e]2;'"${t}"$'\a'
}
_nzr_title_preexec() { _nzr_title "${1[1,60]}"; }
_nzr_title_precmd()  { _nzr_title "${(%):-%n@%m: %~}"; }

add-zsh-hook preexec _nzr_preexec
add-zsh-hook preexec _nzr_title_preexec
add-zsh-hook precmd  _nzr_precmd_status
add-zsh-hook precmd  _nzr_precmd
add-zsh-hook precmd  _nzr_title_precmd
add-zsh-hook zshaddhistory _nzr_zshaddhistory
add-zsh-hook precmd  _nzr_precmd_prompt
# pastikan penangkap status berada di urutan pertama
precmd_functions=(_nzr_precmd_status ${precmd_functions:#_nzr_precmd_status})

# ─── STARTUP ──────────────────────────────────────────────────────
_nzr_startup() {
  [[ ! -o interactive ]] && return
  [[ "${TERM:-}" == "dumb" ]] && return
  [[ -n "$_NZR_STARTUP_DONE" ]] && return
  _NZR_STARTUP_DONE=1
  _nzr_show
}

_nzr_startup
