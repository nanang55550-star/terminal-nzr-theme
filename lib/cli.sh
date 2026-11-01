#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/cli.sh                                ║
# ║   Perintah `nzr`: bantuan, doctor, demo, set, last, update       ║
# ╚══════════════════════════════════════════════════════════════════╝

# Daftar opsi yang boleh diubah lewat `nzr set` beserta aturan validasinya.
# Nilai divalidasi ketat sebelum ditulis ke config.sh (file itu di-source
# oleh shell, jadi isinya tidak boleh berisi karakter berbahaya).
typeset -ga _NZR_CFG_KEYS=(
  NZR_THEME NZR_COLOR_DEPTH ASYNC_PROMPT
  SHOW_LOGO SHOW_HEADLINE SHOW_USER_INFO SHOW_SYSTEM_INFO
  HEADLINE_TEXT HEADLINE_COLOR USER_NAME WELCOME_MSG AUTO_GREETING SHOW_TIPS
  AUTOSUGGESTIONS SYNTAX_HIGHLIGHTING BATGIT_INTEGRATION
  SHOW_ERROR_LINE ERROR_LINE_MODE ERROR_SHOW_CMD ERROR_SUGGEST ERROR_SHOW_JOBS
  ERROR_SHOW_TIME SHOW_CMD_DURATION CMD_DURATION_MIN
  NOTIFY_LONG_CMD NOTIFY_MIN_SECONDS NOTIFY_BELL
  SET_TITLE HIST_SCRUB EXTRA_TOOLS STATS_LOG
)
# Judul bagian untuk `nzr config` (dicetak sebelum key yang bersangkutan)
typeset -gA _NZR_CFG_HDR=(
  NZR_THEME "Tema & mesin prompt"
  SHOW_LOGO "Tampilan startup (lihat hasilnya: rd)"
  AUTOSUGGESTIONS "Plugin (berlaku setelah: nzr reload)"
  SHOW_ERROR_LINE "Baris error"
  NOTIFY_LONG_CMD "Notifikasi perintah lama"
  SET_TITLE "Lain-lain"
)
# Aturan validasi: onoff | num | teks | daftar-nilai-dipisah-|
typeset -gA _NZR_CFG_RULE=(
  NZR_THEME "${(j:|:)_NZR_THEMES}"  NZR_COLOR_DEPTH 'auto|truecolor|256'  ASYNC_PROMPT onoff  STATS_LOG onoff
  SHOW_LOGO onoff        SHOW_HEADLINE onoff     SHOW_USER_INFO onoff   SHOW_SYSTEM_INFO onoff
  HEADLINE_TEXT teks     HEADLINE_COLOR 'cyan|blue|green|yellow|magenta|white|lolcat'
  USER_NAME teks         WELCOME_MSG teks        AUTO_GREETING onoff    SHOW_TIPS onoff
  AUTOSUGGESTIONS onoff  SYNTAX_HIGHLIGHTING onoff  BATGIT_INTEGRATION onoff
  SHOW_ERROR_LINE onoff  ERROR_LINE_MODE 'always|error'  ERROR_SHOW_CMD onoff
  ERROR_SUGGEST onoff    ERROR_SHOW_JOBS onoff   ERROR_SHOW_TIME onoff
  SHOW_CMD_DURATION onoff CMD_DURATION_MIN num
  NOTIFY_LONG_CMD onoff  NOTIFY_MIN_SECONDS num  NOTIFY_BELL onoff
  SET_TITLE onoff        HIST_SCRUB onoff        EXTRA_TOOLS onoff
)

_nzr_say() {   # _nzr_say ok|warn|bad teks
  local c g
  case $1 in ok) c=green; g=${_NZR_G[ok]} ;; warn) c=yellow; g=${_NZR_G[warn]} ;; *) c=red; g=${_NZR_G[fail]} ;; esac
  print -P -- "  %F{$c}${g}%f ${2//\%/%%}"
}

# ─── nzr help ─────────────────────────────────────────────────────
_nzr_cli_help() {
  print -P "%F{cyan}%BNZR theme ${NZR_VERSION}%b%f"
  cat <<'TXT'

  nzr help             bantuan ini
  nzr doctor           cek dependensi, locale, font, izin file log, notifikasi
  nzr theme [NAMA]     ganti tema warna (nord, dracula, gruvbox, tokyonight, catppuccin)
  nzr stats [hari|all] insight pemakaianmu (perintah terbanyak, sering gagal, jam tersibuk)
  nzr bench            ukur biaya tiap komponen prompt (bukti prompt async)
  nzr font             tes simbol powerline + cara memasang font
  fix                  perbaiki perintah terakhir yang gagal (typo, chmod +x)
  nzr last             detail perintah terakhir (kode, arti, durasi, pipe)
  nzr demo             pratinjau semua tampilan baris error
  nzr config           semua pengaturan aktif (tampilan, plugin, error, notifikasi)
  nzr set KEY NILAI    ubah pengaturan: langsung aktif + tersimpan di config.sh
  nzr edit             buka config.sh di editor
  nzr notify-test      kirim notifikasi percobaan
  nzr log              info log autosuggestions
  nzr update           tarik versi terbaru (git pull)
  nzr reload           muat ulang zsh

  Alias: r = refresh tampilan + config · rr = reload config · rd = tampilan saja
  Contoh: nzr set ERROR_LINE_MODE error     (baris error hanya saat gagal)
          nzr set NOTIFY_MIN_SECONDS 10     (notifikasi untuk perintah >= 10 detik)
TXT
}

# ─── nzr doctor ───────────────────────────────────────────────────
_nzr_cli_doctor() {
  local cfg="$NZR_DIR/config.sh" mode
  print -P "%F{cyan}%BNZR doctor%b%f  (${NZR_DIR})\n"

  autoload -Uz is-at-least
  is-at-least 5.0 "$ZSH_VERSION" && _nzr_say ok "zsh $ZSH_VERSION" || _nzr_say bad "zsh $ZSH_VERSION terlalu lama (butuh >= 5.0)"

  if [[ "$SEP" == ">" ]]; then
    _nzr_say warn "locale bukan UTF-8 → memakai mode ASCII (set LANG=en_US.UTF-8 atau C.UTF-8)"
  else
    _nzr_say ok "UTF-8 aktif · simbol powerline: ${SEP}  (jika tampil kotak/?, pasang Nerd Font atau Powerline font)"
  fi

  # mesin prompt & warna
  _nzr_color_depth
  _nzr_say ok "warna: ${REPLY} · tema: ${NZR_THEME:-default}"
  if [[ "${ASYNC_PROMPT:-ON}" == ON ]]; then
    (( ${+builtins[zle]} )) && _nzr_say ok "prompt async aktif (git/RAM/DISK dihitung di latar belakang)" \
                            || _nzr_say warn "zsh ini tidak punya zle → prompt memakai mode sinkron"
  else
    _nzr_say warn "ASYNC_PROMPT=OFF → prompt menunggu git/RAM/DISK. Aktifkan: nzr set ASYNC_PROMPT ON"
  fi
  if [[ -f "${_NZR_STATS_FILE:-}" ]]; then
    mode=$(stat -c %a "$_NZR_STATS_FILE" 2>/dev/null || stat -f %Lp "$_NZR_STATS_FILE" 2>/dev/null)
    [[ "$mode" == 600 ]] && _nzr_say ok "statistik privat (izin 600) · hapus: nzr stats clear" \
                          || _nzr_say warn "izin statistik $mode, seharusnya 600 → chmod 600 $_NZR_STATS_FILE"
  fi

  local t
  for t in git awk df; do
    (( $+commands[$t] )) && _nzr_say ok "$t" || _nzr_say bad "$t tidak ditemukan"
  done
  (( $+commands[free] ))   && _nzr_say ok "free (RAM di status bar)" || _nzr_say warn "free tidak ada → RAM tampil N/A (normal di macOS)"
  (( $+commands[figlet] )) && _nzr_say ok "figlet (headline)"        || _nzr_say warn "figlet tidak ada → headline teks biasa"
  (( $+commands[lolcat] )) && _nzr_say ok "lolcat (rainbow)"         || _nzr_say warn "lolcat tidak ada (opsional)"

  [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && _nzr_say ok "plugin zsh-autosuggestions" || _nzr_say warn "plugin zsh-autosuggestions belum terpasang"
  [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && _nzr_say ok "plugin zsh-syntax-highlighting" || _nzr_say warn "plugin zsh-syntax-highlighting belum terpasang"

  [[ -r "$cfg" ]] && _nzr_say ok "config.sh terbaca" || _nzr_say bad "config.sh tidak ditemukan di $NZR_DIR"

  # ── Tampilan startup: jalankan display.sh dan periksa hasilnya ──
  # (saat startup, stderr display.sh dibuang; di sini error-nya ditampilkan)
  print -P "\n%F{8}── tampilan startup ──%f"
  if [[ ! -f "$NZR_DIR/display.sh" ]]; then
    _nzr_say bad "display.sh tidak ada di $NZR_DIR"
  else
    local tmp_out tmp_err nl i f font=""
    tmp_out=$(mktemp) tmp_err=$(mktemp)
    COLUMNS=${COLUMNS:-80} LINES=${LINES:-24} zsh "$NZR_DIR/display.sh" >"$tmp_out" 2>"$tmp_err" </dev/null
    nl=$(wc -l < "$tmp_out" | tr -d ' ')
    if [[ -s "$tmp_err" ]]; then
      _nzr_say bad "display.sh mengeluarkan error:"
      sed -n '1,4p' "$tmp_err" | sed 's/^/      /'
    else
      _nzr_say ok "display.sh berjalan tanpa error (${nl} baris output)"
    fi
    _nzr_say ok "SHOW_LOGO=${SHOW_LOGO:-ON}  SHOW_HEADLINE=${SHOW_HEADLINE:-ON}  SHOW_USER_INFO=${SHOW_USER_INFO:-ON}  SHOW_SYSTEM_INFO=${SHOW_SYSTEM_INFO:-ON}"
    [[ "${SHOW_LOGO:-ON}" != ON || "${SHOW_HEADLINE:-ON}" != ON ]] && \
      _nzr_say warn "logo/headline dimatikan di config → aktifkan: nzr set SHOW_LOGO ON  ·  nzr set SHOW_HEADLINE ON"
    # tinggi layar: tampilan + prompt harus muat, kalau tidak bagian ATAS (logo) tergulir keluar
    if (( ${LINES:-0} > 0 )) && (( nl + 6 > LINES )); then
      _nzr_say warn "tampilan ${nl} baris + prompt tidak muat di layar ${LINES} baris → logo di atas tergulir keluar. Perkecil teks terminal atau: nzr set SHOW_TIPS OFF"
    fi
    (( ${COLUMNS:-80} < 40 )) && \
      _nzr_say warn "layar hanya ${COLUMNS} kolom → headline figlet jadi sempit/terpotong (perkecil ukuran teks)"
    if (( $+commands[figlet] )); then
      for f in big block banner3 banner; do figlet -f "$f" X &>/dev/null && { font=$f; break; }; done
      [[ -n "$font" ]] && _nzr_say ok "font figlet untuk headline: $font" \
                       || _nzr_say warn "figlet tidak punya font big/block/banner3/banner → headline jatuh ke teks biasa"
    fi
    rm -f "$tmp_out" "$tmp_err"
  fi
  print -P "%F{8}── lainnya ──%f"

  if [[ -f "$NZR_SUGGEST_LOG" ]]; then
    mode=$(stat -c %a "$NZR_SUGGEST_LOG" 2>/dev/null || stat -f %Lp "$NZR_SUGGEST_LOG" 2>/dev/null)
    [[ "$mode" == 600 ]] && _nzr_say ok "log autosuggestions privat (izin 600)" \
                          || _nzr_say warn "izin log autosuggestions $mode, seharusnya 600 → chmod 600 $NZR_SUGGEST_LOG"
  fi

  if (( $+commands[termux-notification] )); then _nzr_say ok "notifikasi: termux-notification"
  elif [[ "$OSTYPE" == darwin* ]] && (( $+commands[osascript] )); then _nzr_say ok "notifikasi: osascript"
  elif (( $+commands[notify-send] )); then _nzr_say ok "notifikasi: notify-send"
  elif [[ -n "${TERMUX_VERSION:-}" || -d /data/data/com.termux ]]; then
    _nzr_say warn "notifikasi: pasang 'pkg install termux-api' + app Termux:API"
  else
    _nzr_say warn "notifikasi: tidak ada notifier (opsional: NOTIFY_BELL=ON untuk bunyi bell)"
  fi

  [[ -n "${HISTFILE:-}" ]] && _nzr_say ok "HISTFILE: $HISTFILE" || _nzr_say warn "HISTFILE belum diset → history tidak disimpan antar sesi"
  print
}

# ─── nzr last ─────────────────────────────────────────────────────
_nzr_cli_last() {
  if [[ -z "$_NZR_REAL_CMD" ]]; then print "Belum ada perintah yang dijalankan di sesi ini."; return 0; fi
  _nzr_err_meaning $_NZR_REAL_ST
  local meaning=$REPLY; _nzr_fmt_dur $_NZR_REAL_DUR
  print -P "%F{cyan}%BPerintah terakhir%b%f"
  print -r -- "  perintah : ${(V)_NZR_REAL_CMD}"
  if (( _NZR_REAL_ST == 0 )); then print "  status   : 0 (sukses)"
  else                             print "  status   : ${_NZR_REAL_ST} — ${meaning}"
  fi
  (( ${#_NZR_REAL_PS} > 1 )) && print "  pipeline : ${(j: | :)_NZR_REAL_PS}"
  print "  durasi   : ${REPLY}"
  print "  selesai  : ${_NZR_REAL_TIME}"
  (( _NZR_FAIL_STREAK >= 2 )) && print "  beruntun : gagal ${_NZR_FAIL_STREAK}× berturut-turut"
  (( _NZR_REAL_ST != 0 )) && print -P "%F{8}  coba perbaiki otomatis: fix%f"
  return 0
}

# ─── nzr demo ─────────────────────────────────────────────────────
_nzr_demo_one() {   # <status> "<pipestatus>" "<perintah>" <detik> [gagal-beruntun]
  local -a ps=(${=2})
  _NZR_FAIL_STREAK=$(( ${5:-1} - 1 ))         # build menambah 1 → tiap contoh berdiri sendiri
  _NZR_LAST_CMD="$3"; _NZR_CMD_START=$(( EPOCHREALTIME - $4 ))
  _nzr_err_build $1 "${ps[@]}"
  _nzr_err_render
  print -P -- "%F{8}\$ ${3//\%/%%}%f"
  print -P -- "${_NZR_ERRLINE%$'\n'}"
}

_nzr_cli_demo() {
  # subshell: tidak mengubah state prompt yang sedang berjalan
  (
    SHOW_ERROR_LINE=ON ERROR_LINE_MODE=always ERROR_SHOW_JOBS=OFF
    _NZR_FAIL_STREAK=0
    print -P "%F{cyan}%BPratinjau baris error%b%f  (lebar ${COLUMNS:-80} kolom)\n"
    _nzr_demo_one 0   "0"     "ls -la"                    0.04
    _nzr_demo_one 0   "0"     "make -j8"                  74
    _nzr_demo_one 1   "1"     "grep foo berkas.txt"       0.2
    _nzr_demo_one 1   "1"     "git push"                  1.3   3
    _nzr_demo_one 127 "127"   "gti status"                0.01
    _nzr_demo_one 126 "126"   "/etc"                      0.01
    _nzr_demo_one 130 "130"   "sleep 100"                 4.2
    _nzr_demo_one 137 "137"   "python train.py"           125
    _nzr_demo_one 0   "1 0"   "false | true"              0.1
    _nzr_demo_one 1   "1 0 1" "cat x | grep y | wc -l"    0.1
  )
}

# ─── nzr config / set ─────────────────────────────────────────────
_nzr_cli_config() {
  local k
  print -P "%F{cyan}%BPengaturan aktif%b%f  (${NZR_DIR}/config.sh)"
  for k in "${_NZR_CFG_KEYS[@]}"; do
    [[ -n "${_NZR_CFG_HDR[$k]:-}" ]] && print -P "\n%F{8}── ${_NZR_CFG_HDR[$k]} ──%f"
    printf '  %-22s "%s"\n' "$k" "${(P)k}"
  done
  print -P "\n%F{8}Ubah: nzr set NAMA NILAI   ·   contoh: nzr set SHOW_LOGO OFF%f"
}

_nzr_cli_set() {
  local key="${(U)1}" rule f re val
  shift 2>/dev/null
  val="$*"                                  # nilai boleh beberapa kata
  if [[ -z "$key" || -z "$val" ]]; then print -u2 "pakai: nzr set KEY NILAI   (lihat daftar: nzr config)"; return 2; fi
  rule="${_NZR_CFG_RULE[$key]:-}"
  if [[ -z "$rule" ]]; then print -u2 "nzr: opsi '$key' tidak dikenal. Lihat daftar: nzr config"; return 1; fi

  case $rule in
    onoff) val="${(U)val}"; [[ "$val" == (ON|OFF) ]] || { print -u2 "nzr: $key harus ON atau OFF"; return 1; } ;;
    num)   [[ "$val" == (<->|<->.<->) ]] || { print -u2 "nzr: $key harus angka (mis. 5 atau 0.5)"; return 1; } ;;
    teks)  # huruf/angka/spasi dan , . _ ! ? : @ + - saja (config.sh di-source shell → tanpa ' " $ ` \\ ; & | < > ( ))
           re='^[[:alnum:] ,._!?:@+-]{1,40}$'
           [[ "$val" =~ $re ]] || { print -u2 "nzr: $key hanya boleh huruf, angka, spasi, dan , . _ ! ? : @ + - (maks 40 karakter)"; return 1; } ;;
    *)     val="${(L)val}"; [[ "$val" == (${~rule}) ]] || { print -u2 "nzr: $key harus salah satu: ${rule//|/, }"; return 1; } ;;
  esac

  # WELCOME_MSG dipakai sebagai awalan sebelum nama → selalu diakhiri tepat satu spasi
  if [[ "$key" == WELCOME_MSG ]]; then
    while [[ "$val" == *" " ]]; do val="${val% }"; done
    val+=" "
  fi

  f="$NZR_DIR/config.sh"
  [[ -w "$f" ]] || { print -u2 "nzr: config.sh tidak bisa ditulis ($f)"; return 1; }

  # tulis ulang baris KEY=..., komentar di belakangnya dipertahankan
  local -a lines; lines=("${(@f)$(<"$f")}")
  local -i found=0 i
  re="^${key}=(\"[^\"]*\"|[^[:space:]#]*)(.*)\$"
  for (( i = 1; i <= ${#lines}; i++ )); do
    if [[ "${lines[i]}" =~ $re ]]; then
      lines[i]="${key}=\"${val}\"${match[2]}"; found=1; break
    fi
  done
  (( found )) || lines+=("${key}=\"${val}\"")
  print -rl -- "${lines[@]}" >| "$f"

  typeset -g "${key}=${val}"     # langsung aktif di shell ini
  _nzr_err_render
  print -P "%F{green}${_NZR_G[ok]}%f ${key} = \"${val}\"  (tersimpan)"
  case $key in
    NZR_THEME|NZR_COLOR_DEPTH) _nzr_theme_apply "$NZR_THEME"; _nzr_prompt_render; _nzr_err_render ;;
  esac
  case $key in
    SHOW_LOGO|SHOW_HEADLINE|SHOW_USER_INFO|SHOW_SYSTEM_INFO|HEADLINE_*|USER_NAME|WELCOME_MSG|AUTO_GREETING|SHOW_TIPS)
      print -P "%F{8}  → ketik %f%Brd%b%F{8} untuk melihat tampilan barunya%f" ;;
    AUTOSUGGESTIONS|SYNTAX_HIGHLIGHTING|BATGIT_INTEGRATION)
      print -P "%F{8}  → ketik %f%Bnzr reload%b%F{8} agar plugin ikut berubah%f" ;;
  esac
}

# ─── nzr font ─────────────────────────────────────────────────────
_nzr_cli_font() {
  print -P "%F{cyan}%BTes font%b%f — semua simbol di bawah harus tampil sebagai gambar, bukan kotak/tanda tanya:\n"
  print -r -- $'  powerline :  \ue0b0 \ue0b2 \ue0a0'
  print -r -- "  status    :  ${_NZR_G[ok]} ${_NZR_G[fail]} ${_NZR_G[ready]} ${_NZR_G[warn]} ➜ …"
  print -r -- "  blok      :  ▁▂▃▄▅▆▇█"
  print -P "\n%F{8}Jika simbol powerline (baris pertama) tampil sebagai kotak, pasang Nerd Font atau Powerline font:%f"
  if [[ -n "${TERMUX_VERSION:-}" || -d /data/data/com.termux ]]; then
    print "  Termux : salin font .ttf Nerd Font ke ~/.termux/font.ttf lalu jalankan: termux-reload-settings"
  elif [[ "$OSTYPE" == darwin* ]]; then
    print "  macOS  : brew install --cask font-jetbrains-mono-nerd-font   lalu pilih font itu di pengaturan terminal"
  else
    print "  Linux  : unduh Nerd Font (nerdfonts.com), salin ke ~/.local/share/fonts, jalankan: fc-cache -f, lalu pilih di terminal"
  fi
}

# ─── nzr (dispatcher) ─────────────────────────────────────────────
nzr() {
  local sub="${1:-help}"; (( $# )) && shift
  case $sub in
    help|-h|--help) _nzr_cli_help ;;
    version|-v|--version) print "NZR theme ${NZR_VERSION}" ;;
    doctor)   _nzr_cli_doctor ;;
    last)     _nzr_cli_last ;;
    demo)     _nzr_cli_demo ;;
    config)   _nzr_cli_config ;;
    theme)    _nzr_cli_theme "$@" ;;
    stats)    _nzr_cli_stats "$@" ;;
    bench)    _nzr_cli_bench ;;
    font)     _nzr_cli_font ;;
    set)      _nzr_cli_set "$@" ;;
    edit)     ${EDITOR:-${commands[nano]:+nano}} "$NZR_DIR/config.sh" 2>/dev/null || vi "$NZR_DIR/config.sh" ;;
    log)      nzr_log_info ;;
    notify-test)
      if _nzr_notify_send "NZR: tes notifikasi" "Kalau ini muncul, notifikasi perintah lama berfungsi."; then
        print -P "%F{green}${_NZR_G[ok]}%f notifikasi dikirim"
      else
        print -P "%F{yellow}${_NZR_G[warn]}%f tidak ada notifier. Jalankan: nzr doctor"
      fi ;;
    update)
      if [[ -d "$NZR_DIR/.git" ]]; then git -C "$NZR_DIR" pull --ff-only && print "Selesai. Jalankan: nzr reload"
      else print -u2 "nzr: $NZR_DIR bukan repo git (instal lewat git clone untuk fitur update)"; return 1; fi ;;
    reload)   exec zsh ;;
    *) print -u2 "nzr: perintah '$sub' tidak dikenal. Coba: nzr help"; return 1 ;;
  esac
}
