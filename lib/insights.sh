#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/insights.sh                           ║
# ║   fix · nzr stats · nzr bench                                    ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# fix         perbaiki perintah terakhir yang gagal (typo → perintah benar,
#             file belum executable → chmod +x) dan taruh di baris input
# nzr stats   insight dari kebiasaanmu: perintah terbanyak, yang sering gagal,
#             yang paling lambat, jam tersibuk
# nzr bench   ukur biaya tiap komponen prompt
#
# PRIVASI nzr stats: yang dicatat HANYA nama perintah (kata pertama, tanpa
# argumen), kode exit, durasi, dan waktu. Tidak ada argumen, path, URL, atau
# token. File ada di folder privat (izin 700/600), tidak pernah dikirim ke mana
# pun. Matikan: nzr set STATS_LOG OFF · hapus: nzr stats clear

typeset -g  _NZR_DATA="${NZR_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nzr}"
typeset -g  _NZR_STATS_FILE="$_NZR_DATA/stats.tsv"
typeset -gi _NZR_STATS_N=0
# Perintah bawaan theme: tidak menimpa "perintah terakhir" yang dianalisis fix/nzr last
typeset -ga _NZR_META=(nzr fix r rr rd nzr-log nzr-log-clear)

# "Perintah nyata" terakhir (bukan perintah theme)
typeset -g  _NZR_REAL_CMD="" _NZR_REAL_TIME=""
typeset -gi _NZR_REAL_ST=0
typeset -gF _NZR_REAL_DUR=0
typeset -ga _NZR_REAL_PS

_nzr_is_meta() {   # <perintah> → 0 bila perintah milik theme
  local -a w=(${(z)1})
  (( ${_NZR_META[(Ie)${w[1]:-}]} ))
}

# ─── Perekam (dipanggil dari precmd setelah perintah selesai) ─────
_nzr_stats_record() {   # <status> <durasi-detik> <perintah>
  [[ "${STATS_LOG:-ON}" == "ON" ]] || return 0
  local name; local -i ms
  _nzr_cmd_word "$3"; name="${REPLY:t}"
  name="${name//[^A-Za-z0-9._+-]/}"
  [[ -n "$name" ]] || name="?"
  name="${name[1,32]}"
  ms=$(( $2 * 1000 ))
  [[ -d "$_NZR_DATA" ]] || ( umask 077; mkdir -p "$_NZR_DATA" ) 2>/dev/null
  [[ -f "$_NZR_STATS_FILE" ]] || ( umask 077; : > "$_NZR_STATS_FILE" ) 2>/dev/null
  printf '%s\t%s\t%d\t%s\n' "$EPOCHSECONDS" "$1" "$ms" "$name" >> "$_NZR_STATS_FILE" 2>/dev/null || return 0
  # rawat ukuran: tiap 200 catatan, jika > 6000 baris sisakan 5000 terakhir
  if (( ++_NZR_STATS_N % 200 == 0 )); then
    local -i n; n=$(wc -l < "$_NZR_STATS_FILE" 2>/dev/null)
    if (( n > 6000 )); then
      ( umask 077; tail -n 5000 "$_NZR_STATS_FILE" > "$_NZR_STATS_FILE.tmp" ) && mv "$_NZR_STATS_FILE.tmp" "$_NZR_STATS_FILE"
    fi
  fi
  chmod 600 "$_NZR_STATS_FILE" 2>/dev/null
  return 0
}

# ─── fix ──────────────────────────────────────────────────────────
fix() {
  local cmd="$_NZR_REAL_CMD" st=$_NZR_REAL_ST w sug new f
  local -a toks out
  if [[ -z "$cmd" ]]; then print -u2 "fix: belum ada perintah sebelumnya"; return 1; fi
  if (( st == 0 )); then print "fix: perintah terakhir sukses, tidak ada yang diperbaiki → ${(V)cmd}"; return 0; fi

  case $st in
    127)
      if _nzr_missing_word "$cmd"; then
        w="$REPLY"
        if _nzr_suggest "$w"; then
          sug="$REPLY"; toks=(${(z)cmd}); out=(); local tk; local -i replaced=0
          for tk in "${toks[@]}"; do
            if (( ! replaced )) && [[ "$tk" == "$w" ]]; then out+=("$sug"); replaced=1; else out+=("$tk"); fi
          done
          new="${(j: :)out}"
          print -P "%F{green}${_NZR_G[ok]}%f ${w} → %B${sug}%b   (Enter untuk menjalankan, atau edit dulu)"
          print -z -- "$new"; return 0
        fi
        print -u2 "fix: tidak ada perintah mirip '$w'. Pasang paket yang menyediakannya?"; return 1
      fi
      print -u2 "fix: exit 127 terjadi di dalam skrip, bukan di perintah yang kamu ketik"; return 1 ;;
    126)
      if _nzr_nonexec_word "$cmd"; then
        f="${REPLY/#\~/$HOME}"
        if [[ -d "$f" ]]; then print -z -- "cd ${(q)f}"; print "fix: itu folder → cd"; return 0; fi
        print -P "%F{green}${_NZR_G[ok]}%f beri izin eksekusi lalu jalankan ulang"
        print -z -- "chmod +x ${(q)f} && ${cmd}"; return 0
      fi
      print -u2 "fix: tidak ada perbaikan otomatis untuk exit 126"; return 1 ;;
    130) print "fix: perintah dihentikan manual (Ctrl+C), bukan error."; return 0 ;;
    *)
      _nzr_err_meaning $st
      print -u2 "fix: tidak ada perbaikan otomatis untuk exit ${st} (${REPLY}). Lihat detail: nzr last"
      return 1 ;;
  esac
}

# ─── nzr stats ────────────────────────────────────────────────────
_nzr_cli_stats() {
  local arg="${1:-7}" cut=0 label out sec off tzs
  local -i n nf
  local bars="▁▂▃▄▅▆▇█"; [[ "$SEP" == ">" ]] && bars=".:-=+*#@"

  if [[ "$arg" == clear ]]; then
    rm -f "$_NZR_STATS_FILE" && print -P "%F{green}${_NZR_G[ok]}%f statistik dihapus"; return 0
  fi
  if [[ ! -s "$_NZR_STATS_FILE" ]]; then
    print "Belum ada data. Pakai terminal seperti biasa lalu coba lagi."
    [[ "${STATS_LOG:-ON}" == "ON" ]] || print "(pencatatan sedang OFF → nzr set STATS_LOG ON)"
    return 0
  fi
  if [[ "$arg" == all ]]; then label="seluruh riwayat"
  elif [[ "$arg" == <-> ]]; then cut=$(( EPOCHSECONDS - arg * 86400 )); label="${arg} hari terakhir"
  else print -u2 "pakai: nzr stats [hari|all|clear]"; return 2; fi

  # selisih zona waktu (detik) agar "jam tersibuk" sesuai jam lokal
  tzs="${(%):-%D{%z}}"; [[ -n "$tzs" ]] || tzs="+0000"
  off=$(( ${tzs[2,3]} * 3600 + ${tzs[4,5]} * 60 )); [[ "${tzs[1]}" == "-" ]] && off=$(( -off ))

  out=$(awk -F'\t' -v cut="$cut" -v off="$off" '
    $1 >= cut && NF == 4 {
      n++; tot[$4]++; ms[$4] += $3; sum += $3
      if ($2 != 0) { nf++; fail[$4]++ }
      hist[int((($1 + off) % 86400) / 3600)]++
    }
    END {
      print "N\t" n + 0 "\t" nf + 0 "\t" sum + 0
      for (k in tot) print "C\t" k "\t" tot[k] "\t" fail[k] + 0 "\t" ms[k]
      for (h = 0; h < 24; h++) print "H\t" h "\t" hist[h] + 0
    }' "$_NZR_STATS_FILE")

  local -a sum=("${(@ps:\t:)$(print -r -- "$out" | awk '$1=="N"')}")
  n=${sum[2]:-0}; nf=${sum[3]:-0}
  if (( n == 0 )); then print "Tidak ada data dalam ${label}."; return 0; fi
  local -F avg=$(( ${sum[4]:-0} / n / 1000 ))

  print -P "%F{cyan}%BNZR insights%b%f — ${label} · ${n} perintah"
  printf '  sukses %d%% · gagal %d%% · rata-rata %.2fs/perintah\n' $(( (n - nf) * 100 / n )) $(( nf * 100 / n )) $avg

  local name cnt fl tms top bar
  local -i mx=0 w i
  print -P "\n%F{8}── paling sering dipakai ──%f"
  top=$(print -r -- "$out" | awk -F'\t' '$1=="C"{print $3 "\t" $2}' | sort -t$'\t' -k1,1nr -k2,2 | head -8)
  while IFS=$'\t' read -r cnt name; do
    (( mx == 0 )) && mx=$cnt
    w=$(( cnt * 20 / mx )); (( w < 1 )) && w=1
    bar=""; for (( i = 0; i < w; i++ )); do bar+="█"; done
    [[ "$SEP" == ">" ]] && bar="${bar//█/#}"
    printf '  %-14s %5d  %s\n' "$name" "$cnt" "$bar"
  done <<< "$top"

  print -P "\n%F{8}── paling sering gagal (min. 3 kali dijalankan) ──%f"
  local res; res=$(print -r -- "$out" | awk -F'\t' '$1=="C" && $3>=3 && $4>0 {printf "%d\t%s\t%d\t%d\n", $4*100/$3, $2, $4, $3}' | sort -t$'\t' -k1,1nr -k4,4nr | head -5)
  if [[ -z "$res" ]]; then print "  (tidak ada — bagus!)"; else
    print -r -- "$res" | while IFS=$'\t' read -r pct name fl cnt; do printf '  %-14s %d dari %d gagal (%d%%)\n' "$name" "$fl" "$cnt" "$pct"; done
  fi

  print -P "\n%F{8}── paling lambat (rata-rata, min. 2 kali) ──%f"
  res=$(print -r -- "$out" | awk -F'\t' '$1=="C" && $3>=2 {printf "%d\t%s\t%d\n", $5/$3, $2, $3}' | sort -t$'\t' -k1,1nr | head -5)
  if [[ -z "$res" ]]; then print "  (belum cukup data)"; else
    print -r -- "$res" | while IFS=$'\t' read -r tms name cnt; do
      _nzr_fmt_dur $(( tms / 1000.0 )); printf '  %-14s %8s   (%dx)\n' "$name" "$REPLY" "$cnt"
    done
  fi

  # jam tersibuk: 24 karakter, satu per jam
  local -a hrs; hrs=(${(f)"$(print -r -- "$out" | awk -F'\t' '$1=="H"{print $3}')"})
  local -i hmax=0 h v idx peak=0; local spark=""
  for h in "${hrs[@]}"; do (( h > hmax )) && hmax=$h; done
  for (( h = 1; h <= 24; h++ )); do
    v=${hrs[h]:-0}
    if (( hmax == 0 || v == 0 )); then spark+=" "; else idx=$(( v * 7 / hmax + 1 )); spark+="${bars[idx]}"; fi
    (( v == hmax && hmax > 0 && peak == 0 )) && peak=$(( h - 1 ))
  done
  print -P "\n%F{8}── jam tersibuk ──%f"
  printf '  00%10s12%9s23\n' '' ''
  print -r -- "  ${spark}"
  printf '  puncak sekitar pukul %02d:00\n' $peak
  print -P "\n%F{8}data lokal, hanya nama perintah (tanpa argumen) · hapus: nzr stats clear%f"
}

# ─── nzr bench ────────────────────────────────────────────────────
_nzr_bench_one() {   # <label> <jumlah> <perintah...>
  local label="$1" n=$2; shift 2
  local -F t0=$EPOCHREALTIME ms; local -i i
  for (( i = 0; i < n; i++ )); do eval "$@" >/dev/null 2>&1; done
  ms=$(( (EPOCHREALTIME - t0) * 1000 / n ))
  REPLY=$ms
  printf '  %-34s %8.2f ms\n' "$label" $ms
}

_nzr_cli_bench() {
  local -F sync_total=0 async_total=0
  print -P "%F{cyan}%BNZR bench%b%f — rata-rata per panggilan (folder: ${(%):-%~})\n"
  print -P "%F{8}── dulu: dihitung SINKRON, prompt menunggu ──%f"
  _nzr_bench_one "status git (symbolic-ref + status)" 10 '_nzr_collect_git';          sync_total+=$REPLY
  _nzr_bench_one "RAM (free + awk)"                   10 '_nzr_collect_ram';          sync_total+=$REPLY
  _nzr_bench_one "DISK (df + awk)"                    10 '_nzr_collect_disk';         sync_total+=$REPLY
  printf '  %-34s %8.2f ms   ← prompt versi lama menunggu sebesar ini\n' "total" $sync_total

  print -P "\n%F{8}── sekarang: yang dikerjakan saat prompt digambar ──%f"
  _nzr_bench_one "baca branch (.git/HEAD, tanpa fork)" 200 '_nzr_git_fast';           async_total+=$REPLY
  _nzr_bench_one "render baris error"                  200 '_nzr_err_render';         async_total+=$REPLY
  _nzr_bench_one "rakit segmen prompt"                 200 '_nzr_prompt_render';      async_total+=$REPLY
  printf '  %-34s %8.2f ms\n' "total" $async_total
  if (( async_total > 0 )); then
    printf '\n  → waktu tunggu prompt berkurang ~%.0fx. Sisanya dikerjakan di latar belakang.\n' $(( sync_total / async_total ))
  fi
  [[ "$ASYNC_PROMPT" == "ON" ]] || print -P "\n%F{yellow}${_NZR_G[warn]}%f ASYNC_PROMPT sedang OFF → nzr set ASYNC_PROMPT ON"
}
