#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/errorline.sh                          ║
# ║   Baris 1 dari prompt 4 baris: penanganan error                  ║
# ╚══════════════════════════════════════════════════════════════════╝
# Isi baris error:
#   sukses : ✓ ok                         (+ durasi, jam, jobs)
#   gagal  : ✘ 127 ×3 · arti · saran · perintah · durasi
#   pipe   : ⚠ pipe 1|0                   (ada bagian pipeline yang gagal)
#
# Status ($? dan pipestatus) ditangkap oleh hook precmd PERTAMA
# (_nzr_precmd_status di nzr.zsh), sebelum fungsi prompt lain menimpanya.

zmodload zsh/datetime 2>/dev/null

typeset -g  _NZR_CMD_RAN=0 _NZR_CMD_START=0 _NZR_LAST_CMD="" _NZR_LAST_ST=0
typeset -g  _NZR_LAST_TIME="" _NZR_FAIL_STREAK=0
typeset -g  _NZR_E_FAIL=0 _NZR_ERRLINE="" _NZR_RERR=""
typeset -gF _NZR_LAST_DUR=0
typeset -ga _NZR_E_BG _NZR_E_FG _NZR_E_TX _NZR_E_PR _NZR_LAST_PS
typeset -gA _NZR_G

# Glyph; fallback ASCII bila terminal tidak mendukung UTF-8/powerline
if [[ "$SEP" == ">" ]]; then
  _NZR_G=(ok "v" fail "x" ready "*" warn "!")
else
  _NZR_G=(ok "✓" fail "✘" ready "●" warn "⚠")
fi

# ─── Kode exit → arti singkat (hasil di $REPLY) ───────────────────
_nzr_err_meaning() {
  local code=$1 sig
  case $code in
    1)   REPLY="error umum" ;;
    2)   REPLY="salah pakai/fatal" ;;
    126) REPLY="tidak bisa dieksekusi" ;;
    127) REPLY="perintah tidak ada" ;;
    128) REPLY="exit tidak valid" ;;
    *)
      if (( code > 128 && code < 128 + ${#signals} )); then
        sig=${signals[code-127]}      # $signals: indeks = nomor sinyal + 1
        case $sig in
          INT)  REPLY="dihentikan (Ctrl+C)" ;;
          TSTP) REPLY="ditangguhkan (Ctrl+Z)" ;;
          KILL) REPLY="di-kill (SIGKILL)" ;;
          SEGV) REPLY="segfault" ;;
          TERM) REPLY="dihentikan (SIGTERM)" ;;
          PIPE) REPLY="broken pipe" ;;
          ABRT) REPLY="abort" ;;
          *)    REPLY="sinyal $sig" ;;
        esac
      else
        REPLY="perintah gagal"
      fi
      ;;
  esac
}

# ─── Durasi: detik (float) → 230ms · 1.4s · 42s · 3m05s · 1h02m ───
_nzr_fmt_dur() {
  local -F d=$1
  local -i s=$(( d )) ms=$(( d * 1000 ))      # assign ke integer = dipotong, tanpa int()
  if   (( d < 1 ));    then REPLY="${ms}ms"
  elif (( d < 10 ));   then printf -v REPLY '%.1fs' $d
  elif (( s < 60 ));   then REPLY="${s}s"
  elif (( s < 3600 )); then printf -v REPLY '%dm%02ds' $(( s / 60 )) $(( s % 60 ))
  else                      printf -v REPLY '%dh%02dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
  fi
}

# ─── "Maksud kamu...?" untuk perintah salah ketik ────────────────
# Jarak edit (Damerau-Levenshtein / OSA): salah huruf, kurang, lebih, tertukar
_nzr_edit_dist() {
  local a=$1 b=$2
  local -i la=${#a} lb=${#b} i j c t w=$(( ${#b} + 1 ))
  local -a d
  for (( i = 0; i <= la; i++ )); do
    for (( j = 0; j <= lb; j++ )); do
      if   (( i == 0 )); then d[i*w+j+1]=$j
      elif (( j == 0 )); then d[i*w+j+1]=$i
      else
        [[ "${a[i]}" == "${b[j]}" ]] && c=0 || c=1
        t=$(( d[(i-1)*w+j+1] + 1 ))                           # hapus
        (( d[i*w+j] + 1 < t ))         && t=$(( d[i*w+j] + 1 ))       # sisip
        (( d[(i-1)*w+j] + c < t ))     && t=$(( d[(i-1)*w+j] + c ))   # ganti
        if (( i > 1 && j > 1 )) && [[ "${a[i]}" == "${b[j-1]}" && "${a[i-1]}" == "${b[j]}" ]]; then
          (( d[(i-2)*w+j-1] + 1 < t )) && t=$(( d[(i-2)*w+j-1] + 1 ))  # tukar
        fi
        d[i*w+j+1]=$t
      fi
    done
  done
  REPLY=${d[la*w+lb+1]}
}

# Kata pertama yang benar-benar perintah (lewati VAR=x, sudo, dll)
_nzr_cmd_word() {
  local -a w=(${(z)1})
  while (( ${#w} )); do
    case "${w[1]}" in
      *=*|sudo|doas|command|builtin|exec|nohup|time|noglob|nocorrect) shift w ;;
      *) break ;;
    esac
  done
  REPLY="${w[1]:-}"
}

# Semua kata yang berada di posisi-perintah → array $reply
# (mis. `cd x && gti push | cat` → cd gti cat)
_nzr_cmdpos_words() {
  local -a w=(${(z)1})
  local t cmdpos=1
  reply=()
  for t in "${w[@]}"; do
    if [[ "$t" == (';'|'&&'|'||'|'|'|'|&'|'&'|'('|'{'|then|do|else) ]]; then cmdpos=1; continue; fi
    (( cmdpos )) || continue
    case "$t" in *=*|sudo|doas|command|builtin|exec|nohup|time|noglob|nocorrect) continue ;; esac
    cmdpos=0
    reply+=("$t")
  done
}

# Kata posisi-perintah pertama yang tidak dikenal (perintah/alias/fungsi/file)
_nzr_missing_word() {
  local t
  REPLY=""
  _nzr_cmdpos_words "$1"
  for t in "${reply[@]}"; do
    if (( ${+commands[(e)$t]} + ${+aliases[(e)$t]} + ${+functions[(e)$t]} + ${+builtins[(e)$t]} + ${+reswords[(e)$t]} )) \
       || [[ -e "${t/#\~/$HOME}" ]]; then
      continue
    fi
    REPLY="$t"; return 0
  done
  return 1
}

# Kata posisi-perintah pertama yang ada di disk tapi tidak bisa dieksekusi
# (file tanpa izin x, atau folder) → $REPLY. Dipakai untuk exit 126.
_nzr_nonexec_word() {
  local t f
  REPLY=""
  _nzr_cmdpos_words "$1"
  for t in "${reply[@]}"; do
    f="${t/#\~/$HOME}"
    if [[ -d "$f" || ( -f "$f" && ! -x "$f" ) ]]; then REPLY="$t"; return 0; fi
  done
  return 1
}

# Saran perintah terdekat (hasil di $REPLY). Hanya dipanggil saat exit 127.
_nzr_suggest() {
  local w=$1 c pick=""
  local -i n=${#w} maxd best=99 d ln
  REPLY=""
  (( n >= 2 && n <= 24 )) || return 1
  (( n <= 3 )) && maxd=1 || maxd=2
  local -a pool=(${(k)commands} ${(k)aliases} ${(k)builtins} ${(k)functions:#_*})
  pool=(${(ou)pool})
  for c in "${pool[@]}"; do
    ln=${#c}
    (( ln - n > maxd || n - ln > maxd )) && continue
    # prefilter murah: huruf pertama sama, atau dua huruf awal tertukar
    [[ "${c[1]}" == "${w[1]}" || "${c[1,2]}" == "${w[2]}${w[1]}" ]] || continue
    _nzr_edit_dist "$w" "$c"; d=$REPLY
    (( d <= maxd && d < best )) && { best=$d; pick=$c; }
  done
  REPLY=$pick
  [[ -n "$pick" ]]
}

# ─── Segmen baris error ──────────────────────────────────────────
# Argumen: warna-bg warna-fg teks [prioritas]
# Prioritas: 0 = paling penting. Di layar sempit, segmen dengan angka terbesar
# dibuang lebih dulu (urutan tampil tidak berubah).
_nzr_err_add() { _NZR_E_BG+=("$1"); _NZR_E_FG+=("$2"); _NZR_E_TX+=("$3"); _NZR_E_PR+=("${4:-5}"); }

# Argumen: <status> <pipestatus...>
_nzr_err_build() {
  local st=$1; shift
  local -a ps=("$@")
  local p w bad=0 dur_txt="" pipe_txt="" cmd_txt="" hint="" code_txt

  _NZR_E_BG=(); _NZR_E_FG=(); _NZR_E_TX=(); _NZR_E_PR=(); _NZR_E_FAIL=0
  _NZR_LAST_ST=$st; _NZR_LAST_PS=("${ps[@]}")
  # jam selesai HH:MM:SS (strftime bawaan zsh; cadangan: %* yang tanpa nol di depan)
  strftime -s _NZR_LAST_TIME '%H:%M:%S' $EPOCHSECONDS 2>/dev/null || _NZR_LAST_TIME="${(%):-%*}"
  _NZR_LAST_DUR=$(( EPOCHREALTIME - _NZR_CMD_START ))

  if [[ "$SHOW_CMD_DURATION" == "ON" ]] && (( _NZR_LAST_DUR >= CMD_DURATION_MIN )); then
    _nzr_fmt_dur $_NZR_LAST_DUR; dur_txt=$REPLY
  fi

  # pipeline: tampilkan hanya jika ada >1 bagian dan salah satunya gagal
  for p in "${ps[@]}"; do (( p != 0 )) && bad=1; done
  (( ${#ps} > 1 && bad )) && pipe_txt="pipe ${(j:|:)ps}"

  if (( st == 0 )); then
    _NZR_FAIL_STREAK=0
    if [[ -n "$pipe_txt" ]]; then
      _nzr_err_add yellow black "${_NZR_G[warn]} $pipe_txt" 0
    else
      _nzr_err_add green black "${_NZR_G[ok]} ok" 0
    fi
  else
    _NZR_E_FAIL=1
    (( _NZR_FAIL_STREAK++ ))
    code_txt="${_NZR_G[fail]} $st"
    (( _NZR_FAIL_STREAK >= 2 )) && code_txt+=" ×${_NZR_FAIL_STREAK}"
    _nzr_err_meaning $st
    _nzr_err_add red    white "$code_txt" 0
    _nzr_err_add yellow black "$REPLY" 3

    # saran / petunjuk
    if [[ "$ERROR_SUGGEST" == "ON" ]]; then
      if (( st == 127 )); then
        if _nzr_missing_word "$_NZR_LAST_CMD" && _nzr_suggest "$REPLY"; then
          hint="mungkin: $REPLY"
        fi
      elif (( st == 126 )); then
        if _nzr_nonexec_word "$_NZR_LAST_CMD"; then
          w="${REPLY/#\~/$HOME}"
          [[ -d "$w" ]] && hint="itu folder" || hint="coba: chmod +x"
        fi
      fi
      [[ -n "$hint" ]] && _nzr_err_add green black "$hint" 1
    fi

    [[ -n "$pipe_txt" ]] && _nzr_err_add cyan black "$pipe_txt" 2
    if [[ "$ERROR_SHOW_CMD" == "ON" ]]; then
      cmd_txt="${(V)_NZR_LAST_CMD}"             # karakter kontrol dibuat terlihat
      while [[ "$cmd_txt" == " "* ]]; do cmd_txt="${cmd_txt# }"; done   # tanpa extended_glob
      (( ${#cmd_txt} > 20 )) && cmd_txt="${cmd_txt[1,19]}…"
      [[ -n "$cmd_txt" ]] && _nzr_err_add magenta white "$cmd_txt" 4
    fi
  fi
  [[ -n "$dur_txt" ]] && _nzr_err_add blue white "$dur_txt" 5
  [[ "$ERROR_SHOW_TIME" == "ON" ]] && _nzr_err_add white black "$_NZR_LAST_TIME" 6
}

# ─── Render: segmen → string prompt (dipanggil tiap prompt) ───────
_nzr_err_render() {
  _NZR_ERRLINE=""; _NZR_RERR=""
  (( ${#_NZR_E_TX} )) || return

  # Mode OFF → prompt 3 baris, error ringkas di sisi kanan (perilaku lama)
  if [[ "$SHOW_ERROR_LINE" != "ON" ]]; then
    (( _NZR_E_FAIL )) && _NZR_RERR="%{$bg[red]%}%{$fg[white]%} ${_NZR_E_TX[1]//\%/%%} %{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
    return
  fi
  # Mode "error" → baris disembunyikan saat sukses
  [[ "$ERROR_LINE_MODE" == "error" ]] && (( ! _NZR_E_FAIL )) && return

  local -a sb=("${_NZR_E_BG[@]}") sf=("${_NZR_E_FG[@]}") st=("${_NZR_E_TX[@]}") sp=("${_NZR_E_PR[@]}")
  local -i max=$(( ${COLUMNS:-80} - 1 )) total i k worst
  local t out="" prev=""

  # Jobs di background (dihitung tiap prompt, bukan saat perintah selesai)
  if [[ "$ERROR_SHOW_JOBS" == "ON" ]] && (( ${#jobstates} > 0 )); then
    sb+=(yellow); sf+=(black); st+=("jobs ${#jobstates}"); sp+=(7)
  fi

  # Terminal sempit (mis. Termux portrait): buang segmen paling tidak penting
  while :; do
    total=0
    for t in "${st[@]}"; do total+=$(( ${#t} + 3 )); done   # spasi 2 + separator 1
    (( total <= max || ${#st} <= 1 )) && break
    worst=1
    for (( k = 2; k <= ${#sp}; k++ )); do (( sp[k] >= sp[worst] )) && worst=$k; done
    sb[worst]=(); sf[worst]=(); st[worst]=(); sp[worst]=()
  done

  for (( i = 1; i <= ${#st}; i++ )); do
    [[ -n "$prev" ]] && out+="%{$bg[${sb[i]}]%}%{$fg[$prev]%}${SEP}"
    out+="%{$bg[${sb[i]}]%}%{$fg[${sf[i]}]%} ${st[i]//\%/%%} "
    prev=${sb[i]}
  done
  out+="%{$reset_color%}%{$fg[$prev]%}${SEP}%{$reset_color%}"
  _NZR_ERRLINE="${out}"$'\n'
}
