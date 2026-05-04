#!/bin/zsh
# NZR Theme - User Info & Headline Display

# --- PERBAIKAN PATH CONFIG ---
# Mencari folder secara otomatis agar tidak salah path lagi
NZR_DIR="$(dirname "$0")"
source "$NZR_DIR/config.sh" 2>/dev/null
# ─── FIGLET HEADLINE ───────────────────────────────────────────────
_nzr_headline() {
  [[ "$SHOW_HEADLINE" != "ON" ]] && return
  
  local text="${HEADLINE_TEXT:-NZR-RD}"
  local color="${HEADLINE_COLOR:-lolcat}"
  
  # Pastikan figlet ada
  if ! command -v figlet &>/dev/null; then return; fi

  # 1. Geser kursor ke kanan (Ubah angka 40 jika masih menimpa logo)
  # Kita pakai echo -e agar escape code-nya terbaca dengan benar
  echo -ne "\033[40C"

  # 2. Cetak figlet dengan gaya yang kamu mau
  if [ "$color" = "lolcat" ] && command -v lolcat &>/dev/null; then
    # Agar setiap baris figlet bergeser ke kanan, kita pakai sed
    figlet -f block "$text" | sed "s/^/\x1b[40C/" | lolcat


  else
    # Jika tanpa lolcat (warna cyan standar)
    echo -e "\e[1;36m"
    figlet -f block "$text" | sed "s/^/\x1b[40C/"
    echo -e "\e[0m"
  fi
}

# ─── WELCOME MESSAGE ─────────────────────────────────────────────
_nzr_welcome() {
  [[ "$SHOW_USER_INFO" != "ON" ]] && return
  
  local name="${USER_NAME:-$USER}"
  local msg="${WELCOME_MSG:-Selamat datang, }"
  
  # Pilih warna random atau fixed
  local colors=($'\e[1;36m' $'\e[1;34m' $'\e[1;35m' $'\e[1;33m' $'\e[1;32m')
  local color=${colors[$((RANDOM % 5 + 1))]}
  
  echo ""
  echo "${color}╭────────────────────────────────────────╮\e[0m"
  echo "${color}│  ${msg}\e[1;37m${name}\e[0m${color}  │\e[0m"
  echo "${color}╰────────────────────────────────────────╯\e[0m"
  echo ""
}

# ─── SYSTEM INFO ───────────────────────────────────────────────────
_nzr_system_info() {
  [[ "$SHOW_SYSTEM_INFO" != "ON" ]] && return
  
  local cyan=$'\e[1;36m'
  local green=$'\e[1;32m'
  local yellow=$'\e[1;33m'
  local reset=$'\e[0m'
  
  echo "${cyan}┌─ System Information ─────────────────┐${reset}"
  echo "${cyan}│${reset}  OS:     $(uname -o) $(uname -m)    ${cyan}│${reset}"
  echo "${cyan}│${reset}  Host:   $(hostname)                  ${cyan}│${reset}"
  echo "${cyan}│${reset}  User:   ${USER}                       ${cyan}│${reset}"
  echo "${cyan}│${reset}  Shell:  Zsh ${ZSH_VERSION}           ${cyan}│${reset}"
  echo "${cyan}│${reset}  Time:   $(date '+%H:%M:%S')           ${cyan}│${reset}"
  echo "${cyan}└─────────────────────────────────────┘${reset}"
}

# ─── COMBINED DISPLAY ──────────────────────────────────────────────
_nzr_user_display() {
  _nzr_headline
  _nzr_welcome
  _nzr_system_info
}

# Langsung jalankan fungsinya agar muncul saat dipanggil
_nzr_user_display
