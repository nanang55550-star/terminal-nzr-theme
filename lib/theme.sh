#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/theme.sh                              ║
# ║   Mesin tema warna: truecolor / 256 warna, ganti dengan satu     ║
# ║   perintah:  nzr theme dracula                                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Cara kerja: seluruh prompt memakai nama warna (cyan, blue, red, ...) lewat
# array $bg[] dan $fg[]. Tema cukup MENGGANTI isi array itu, jadi tidak ada
# satu pun baris prompt yang perlu diubah.
#
#   default → warna ANSI bawaan terminal (tampilan asli, tidak diubah)
#   lainnya → palet hex; otomatis truecolor, atau dipetakan ke 256 warna
#             di terminal yang belum mendukung truecolor (mis. macOS Terminal)
#
# Semua palet disetel agar teks tetap terbaca: teks putih di atas merah /
# magenta / biru ≥ 4.5:1, dan hijau / cyan (dipakai teks putih DAN hitam) ≥ 3:1.
# Kontras itu dijaga oleh tests/run.zsh.

typeset -ga _NZR_ROLES=(black red green yellow blue magenta cyan white)
typeset -ga _NZR_THEMES=(default nord dracula gruvbox tokyonight catppuccin)

# urutan hex: black red green yellow blue magenta cyan white
typeset -gA _NZR_PAL=(
  nord        "2e3440 b24852 6b8c4f ebcc8d 4d6d95 8a5c82 418ea5 eceff4"
  dracula     "21222c c14646 2f8e47 dce1a5 5d6ea1 be3f88 338799 f8f8f2"
  gruvbox     "1d2021 ba211a 7a7915 e3ad46 36676a 914869 527f54 ebdbb2"
  tokyonight  "16161e 973043 517727 d3ad75 31539a 6539b5 307197 c0caf5"
  catppuccin  "181825 a03553 307e2a e9dcbe 345c9c 753db8 297a6d cdd6f4"
)

# Simpan warna asli terminal supaya "default" bisa dipulihkan persis
typeset -gA _NZR_FG0 _NZR_BG0
_NZR_FG0=("${(@kv)fg}")
_NZR_BG0=("${(@kv)bg}")

# Terminal mendukung truecolor? (hasil di $REPLY: truecolor|256)
_nzr_color_depth() {
  case "${NZR_COLOR_DEPTH:-auto}" in
    truecolor|256) REPLY="$NZR_COLOR_DEPTH"; return ;;
  esac
  if [[ "${COLORTERM:-}" == (truecolor|24bit) || -n "${TERMUX_VERSION:-}" \
     || "${TERM_PROGRAM:-}" == (iTerm.app|WezTerm|vscode|ghostty) \
     || "${TERM:-}" == (*-direct|xterm-kitty|alacritty|foot*|*-truecolor) ]]; then
    REPLY=truecolor
  else
    REPLY=256
  fi
}

# RGB (0-255) → indeks terdekat di palet xterm-256. Hasil di $REPLY.
_nzr_rgb256() {
  local -i r=$1 g=$2 b=$3 ri gi bi i best=999999999 d idx=16 gv
  local -i cr cg cb
  local -a lv=(0 95 135 175 215 255)
  # kandidat 1: kubus warna 6x6x6 (indeks 16-231)
  ri=$(( r < 48 ? 0 : r < 115 ? 1 : (r - 35) / 40 ))
  gi=$(( g < 48 ? 0 : g < 115 ? 1 : (g - 35) / 40 ))
  bi=$(( b < 48 ? 0 : b < 115 ? 1 : (b - 35) / 40 ))
  cr=${lv[ri+1]} cg=${lv[gi+1]} cb=${lv[bi+1]}
  best=$(( (r-cr)*(r-cr) + (g-cg)*(g-cg) + (b-cb)*(b-cb) ))
  idx=$(( 16 + 36*ri + 6*gi + bi ))
  # kandidat 2: skala abu-abu (232-255): 8, 18, ... 238
  for (( i = 0; i < 24; i++ )); do
    gv=$(( 8 + 10*i ))
    d=$(( (r-gv)*(r-gv) + (g-gv)*(g-gv) + (b-gv)*(b-gv) ))
    (( d < best )) && { best=$d; idx=$(( 232 + i )); }
  done
  REPLY=$idx
}

# Terapkan tema: ganti isi $fg[] dan $bg[]
_nzr_theme_apply() {
  local name="${1:-default}" depth hx role
  local -i i r g b
  local -a hex
  if [[ "$name" == default || -z "${_NZR_PAL[$name]:-}" || "${TERM:-}" == (dumb|linux) ]]; then
    fg=("${(@kv)_NZR_FG0}"); bg=("${(@kv)_NZR_BG0}")
    return 0
  fi
  _nzr_color_depth; depth=$REPLY
  hex=(${=_NZR_PAL[$name]})
  for (( i = 1; i <= 8; i++ )); do
    role="${_NZR_ROLES[i]}"; hx="${hex[i]}"
    r=$(( 16#${hx[1,2]} )); g=$(( 16#${hx[3,4]} )); b=$(( 16#${hx[5,6]} ))
    if [[ "$depth" == truecolor ]]; then
      fg[$role]=$'\e[38;2;'"${r};${g};${b}m"
      bg[$role]=$'\e[48;2;'"${r};${g};${b}m"
    else
      _nzr_rgb256 $r $g $b
      fg[$role]=$'\e[38;5;'"${REPLY}m"
      bg[$role]=$'\e[48;5;'"${REPLY}m"
    fi
  done
}

# Satu baris kotak warna contoh untuk sebuah palet (tanpa mengubah $fg/$bg)
_nzr_swatch() {
  local name="$1" depth hx out="" i r g b
  local -a hex
  if [[ "$name" == default ]]; then
    for (( i = 1; i <= 8; i++ )); do out+="${_NZR_BG0[${_NZR_ROLES[i]}]}   "; done
  else
    _nzr_color_depth; depth=$REPLY
    hex=(${=_NZR_PAL[$name]})
    for (( i = 1; i <= 8; i++ )); do
      hx="${hex[i]}"
      r=$(( 16#${hx[1,2]} )); g=$(( 16#${hx[3,4]} )); b=$(( 16#${hx[5,6]} ))
      if [[ "$depth" == truecolor ]]; then out+=$'\e[48;2;'"${r};${g};${b}m   "
      else _nzr_rgb256 $r $g $b; out+=$'\e[48;5;'"${REPLY}m   "
      fi
    done
  fi
  REPLY="${out}"$'\e[0m'
}

# nzr theme            → daftar tema
# nzr theme <nama>     → pakai + simpan
_nzr_cli_theme() {
  local want="${1:-}" t mark
  if [[ -z "$want" ]]; then
    _nzr_color_depth
    print -P "%F{cyan}%BTema warna%b%f  (terminal: ${REPLY})\n"
    for t in "${_NZR_THEMES[@]}"; do
      _nzr_swatch "$t"
      [[ "$t" == "${NZR_THEME:-default}" ]] && mark="%F{green} ◄ aktif%f" || mark=""
      print -P -- "  ${(r:12:)t} ${REPLY}${mark}"
    done
    print -P "\n%F{8}Pakai: nzr theme NAMA   ·   contoh: nzr theme dracula%f"
    return 0
  fi
  if (( ! ${_NZR_THEMES[(Ie)$want]} )); then
    print -u2 "nzr: tema '$want' tidak ada. Pilihan: ${(j:, :)_NZR_THEMES}"; return 1
  fi
  _nzr_cli_set NZR_THEME "$want" >/dev/null || return 1
  _nzr_theme_apply "$want"
  _nzr_prompt_render; _nzr_err_render
  print -P "%F{green}${_NZR_G[ok]}%f tema %B${want}%b dipakai dan tersimpan. Pratinjau:\n"
  _nzr_demo_one 127 "127" "gti status" 0.2
  _nzr_render_status "${_NZR_RAM}" "${_NZR_DISK}"; print -P -- "$REPLY"
  _nzr_render_dirgit "main" clean 0;               print -P -- "$REPLY"
}
