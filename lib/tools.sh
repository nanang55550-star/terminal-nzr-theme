#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/tools.sh                              ║
# ║   Fungsi kecil yang sering dipakai (EXTRA_TOOLS=ON)              ║
# ╚══════════════════════════════════════════════════════════════════╝
# Tiap fungsi hanya didefinisikan jika namanya BELUM dipakai perintah,
# alias, atau fungsi lain — tidak menimpa milikmu.

_nzr_taken() { (( ${+commands[(e)$1]} + ${+aliases[(e)$1]} + ${+functions[(e)$1]} + ${+builtins[(e)$1]} )); }

# mkcd <folder> — buat folder (beserta induknya) lalu masuk
if ! _nzr_taken mkcd; then
  mkcd() {
    [[ -n "$1" ]] || { print -u2 "pakai: mkcd <folder>"; return 2; }
    mkdir -p -- "$1" && cd -- "$1"
  }
fi

# up [N] — naik N folder (default 1)
if ! _nzr_taken up; then
  up() {
    local n="${1:-1}" p=""
    [[ "$n" == <-> ]] || { print -u2 "pakai: up [jumlah]"; return 2; }
    repeat $n p+="../"
    cd -- "${p:-.}"
  }
fi

# bak <file...> — salin cadangan bertanda waktu: file.bak-20261030-141500
if ! _nzr_taken bak; then
  bak() {
    (( $# )) || { print -u2 "pakai: bak <file|folder>..."; return 2; }
    local f ts; ts="$(date +%Y%m%d-%H%M%S)"
    for f in "$@"; do
      cp -a -- "$f" "${f%/}.bak-${ts}" && print "✓ ${f%/}.bak-${ts}"
    done
  }
fi

# extract <arsip...> — ekstrak format apa pun dari ekstensinya
if ! _nzr_taken extract; then
  extract() {
    (( $# )) || { print -u2 "pakai: extract <arsip>..."; return 2; }
    local f a rc=0
    for f in "$@"; do
      [[ -f "$f" ]] || { print -u2 "extract: bukan file: $f"; rc=1; continue; }
      a="$f"; [[ "$a" == -* ]] && a="./$a"      # nama berawalan "-" jangan dibaca sebagai opsi
      case "${(L)f}" in
        *.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst|*.tar) tar -xf "$a" ;;
        *.zip|*.jar|*.apk)  unzip "$a" ;;
        *.gz)   gunzip "$a" ;;
        *.bz2)  bunzip2 "$a" ;;
        *.xz)   unxz "$a" ;;
        *.7z)   7z x "$a" ;;
        *.rar)  unrar x "$a" ;;
        *) print -u2 "extract: format tidak dikenal: $f"; rc=1 ;;
      esac || rc=1
    done
    return $rc
  }
fi
