#!/bin/zsh
# NZR Theme - User Info & Headline Display

# --- PERBAIKAN PATH CONFIG ---
# Mencari folder secara otomatis agar tidak salah path lagi
NZR_DIR="$(dirname "$0")"
source "$NZR_DIR/config.sh" 2>/dev/null
# ─── FIGLET HEADLINE ───────────────────────────────────────────────
_nzr_headline() {
  [[ "$SHOW_HEADLINE" != "ON" ]] && return
  
  local text="${HEADLINE_TEXT:-NZR-TERMUX}"
  local color="${HEADLINE_COLOR:-cyan}"
  
  # --- SETTING JARAK DI SINI ---
  local padding="\033[38C" # 38C artinya geser 38 spasi ke kanan
  # ----------------------------

  if ! command -v figlet &>/dev/null; then
    printf "${padding}\e[1;33m[Install figlet]\e[0m\n"
    return
  fi

  # Logika Warna Otomatis
  case "$color" in
    lolcat)
      if command -v lolcat &>/dev/null; then
        # Ambil output figlet, lalu tambah padding di setiap barisnya
        figlet -f block "$text" | sed "s/^/${padding}/" | lolcat
      else
        figlet -f block "$text" | sed "s/^/${padding}/" | printf "\e[1;36m$(cat)\e[0m\n"
      fi
      ;;
    *)
      # Untuk warna selain lolcat
      local color_code="\e[1;36m" # default cyan
      [[ "$color" == "blue" ]] && color_code="\e[1;34m"
      [[ "$color" == "green" ]] && color_code="\e[1;32m"
      [[ "$color" == "yellow" ]] && color_code="\e[1;33m"
      [[ "$color" == "red" ]] && color_code="\e[1;31m"
      [[ "$color" == "magenta" ]] && color_code="\e[1;35m"

      # Cetak dengan padding dan warna
      figlet -f block "$text" | sed "s/^/${padding}/" | while read -r line; do
        printf "${color_code}%s\e[0m\n" "$line"
      done
      ;;
  esac
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
