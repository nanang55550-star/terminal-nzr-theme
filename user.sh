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
  local color="${HEADLINE_COLOR:-lolcat}"
  
  # Cek figlet tersedia
  if ! command -v figlet &>/dev/null; then
    echo "\e[1;33m[Install figlet: pkg install figlet]\e[0m"
    return
  fi
  
  case "$color" in
    lolcat)
      if command -v lolcat &>/dev/null; then
        figlet -f block "$text" | lolcat
      else
        echo "\e[1;36m$(figlet -f block "$text")\e[0m"
        echo "\e[1;33m[Install lolcat: gem install lolcat]\e[0m"
      fi
      ;;
    cyan)    echo "\e[1;36m$(figlet -f block "$text")\e[0m" ;;
    blue)    echo "\e[1;34m$(figlet -f block "$text")\e[0m" ;;
    green)   echo "\e[1;32m$(figlet -f block "$text")\e[0m" ;;
    yellow)  echo "\e[1;33m$(figlet -f block "$text")\e[0m" ;;
    red)     echo "\e[1;31m$(figlet -f block "$text")\e[0m" ;;
    magenta) echo "\e[1;35m$(figlet -f block "$text")\e[0m" ;;
    *)       echo "\e[1;36m$(figlet -f block "$text")\e[0m" ;;
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
