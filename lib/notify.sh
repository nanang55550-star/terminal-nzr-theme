#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/notify.sh                             ║
# ║   Notifikasi saat perintah yang lama akhirnya selesai            ║
# ╚══════════════════════════════════════════════════════════════════╝
# Berguna di Termux: jalankan build/download panjang, tinggalkan aplikasi,
# lalu dapat notifikasi saat selesai (butuh paket termux-api + app Termux:API).
#   Termux  → termux-notification
#   macOS   → osascript
#   Linux   → notify-send (butuh desktop)
#   lainnya → bunyi bell, hanya jika NOTIFY_BELL=ON

# Kirim satu notifikasi: _nzr_notify_send <judul> <isi>
# Teks dikirim sebagai argumen terpisah (tidak pernah lewat shell/eval).
_nzr_notify_send() {
  local title="$1" msg="$2"
  if (( $+commands[termux-notification] )); then
    termux-notification --title "$title" --content "$msg" &>/dev/null &!
  elif [[ "$OSTYPE" == darwin* ]] && (( $+commands[osascript] )); then
    osascript -e 'on run argv' \
              -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
              -e 'end run' -- "$title" "$msg" &>/dev/null &!
  elif (( $+commands[notify-send] )) && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    notify-send -- "$title" "$msg" &>/dev/null &!
  elif [[ "$NOTIFY_BELL" == "ON" ]]; then
    print -n '\a'
  else
    return 1
  fi
}

# Dipanggil tiap perintah selesai: _nzr_notify <status>
_nzr_notify() {
  [[ "$NOTIFY_LONG_CMD" == "ON" ]] || return 0
  (( _NZR_LAST_DUR >= NOTIFY_MIN_SECONDS )) || return 0

  local -a w=(${(z)_NZR_LAST_CMD})
  local first="${w[1]:t}"
  # program interaktif tidak perlu notifikasi
  [[ " ${NOTIFY_IGNORE} " == *" ${first} "* ]] && return 0

  local title msg txt="${(V)_NZR_LAST_CMD}"
  (( ${#txt} > 80 )) && txt="${txt[1,79]}…"
  _nzr_fmt_dur $_NZR_LAST_DUR
  if (( $1 == 0 )); then title="NZR: selesai (${REPLY})"
  else                   title="NZR: gagal [$1] (${REPLY})"
  fi
  msg="$txt"
  _nzr_notify_send "$title" "$msg"
  return 0
}
