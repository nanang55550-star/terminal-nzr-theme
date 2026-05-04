#!/bin/zsh
# NZR Theme - Combined Display (Logo + Headline + Info)

NZR_DIR="$(dirname "$0")"
source "$NZR_DIR/config.sh" 2>/dev/null

# ─── LOGO (dari logo.sh) ────────────────────────────────────────
_nzr_logo() {
  cat <<'EOF'
            kkk'         .kk,
            WMMMo        ;MMc
            WMWWM0.      ;MMc
            WMX.0MW;     ;MMc
            WMX  lMMx    ;MMc
            WMX   'NMX.  ;MMc
            WMX     kMWc ;MMc
     :xxxxxxMMWxxxxxdNMM00MM0o:.
     ,ccccccWMWc0MMKXMMXMMMMOxXMWl
            WMNxMMl 0MM dMMMc  cMMo
            :kMMX.  0MM  '::.   MMO
            oMMd    0MM       .kMM,
          .KMX'     0MMOkkkkOXMNx.
         lMMx       0MMc::::OMW'
       .0MN,        0MM      xMW;
      cWMk          0MM       oMMl
     kMMNdddddddddddNMM        :MMx
     :lllllllllllllllll         'll'

EOF
}

# ─── HEADLINE ────────────────────────────────────────────────────
_nzr_headline() {
  [[ "$SHOW_HEADLINE" != "ON" ]] && return
  
  local text="${HEADLINE_TEXT:-NZR-RD}"
  
  if ! command -v figlet &>/dev/null; then return; fi

  local big_font="block"
  for f in "ansi_shadow" "big" "block"; do
    figlet -f "$f" "T" &>/dev/null && { big_font="$f"; break; }
  done

  # Print figlet, nanti akan digabung dengan logo
  figlet -f "$big_font" -w 100 "$text"
}

# ─── COMBINE LOGO + HEADLINE ─────────────────────────────────────
_nzr_combine() {
  # Simpan logo dan headline ke array
  local logo_lines=()
  local headline_lines=()
  
  while IFS= read -r line; do
    logo_lines+=("$line")
  done < <(_nzr_logo)
  
  while IFS= read -r line; do
    headline_lines+=("$line")
  done < <(_nzr_headline)
  
  # Lebar logo ~45 karakter
  local logo_width=45
  local padding="     "  # Jarak antara logo dan headline
  
  # Print baris per baris
  local max_lines=${#logo_lines[@]}
  [[ ${#headline_lines[@]} -gt $max_lines ]] && max_lines=${#headline_lines[@]}
  
  for ((i=0; i<max_lines; i++)); do
    local left="${logo_lines[$i]:-}"
    local right="${headline_lines[$i]:-}"
    
    # Format: Logo + Padding + Headline
    printf "%-${logo_width}s%s%s\n" "$left" "$padding" "$right"
  done
}

# ─── WELCOME ─────────────────────────────────────────────────────
_nzr_welcome() {
  [[ "$SHOW_USER_INFO" != "ON" ]] && return
  
  local name="${USER_NAME:-$USER}"
  local msg="${WELCOME_MSG:-Selamat datang, }"
  local colors=($'\e[1;36m' $'\e[1;34m' $'\e[1;35m' $'\e[1;33m' $'\e[1;32m')
  local color=${colors[$((RANDOM % 5 + 1))]}
  
  echo ""
  echo "${color}╭────────────────────────────────────────╮\e[0m"
  printf "${color}│  %s\e[1;37m%s\e[0m${color}  │\e[0m\n" "$msg" "$name"
  echo "${color}╰────────────────────────────────────────╯\e[0m"
  echo ""
}

# ─── SYSTEM INFO ─────────────────────────────────────────────────
_nzr_system_info() {
  [[ "$SHOW_SYSTEM_INFO" != "ON" ]] && return
  
  local cyan=$'\e[1;36m' reset=$'\e[0m'
  
  echo "${cyan}┌─ System Information ─────────────────┐${reset}"
  printf "${cyan}│${reset}  OS:     %-28s ${cyan}│${reset}\n" "$(uname -o) $(uname -m)"
  printf "${cyan}│${reset}  Host:   %-28s ${cyan}│${reset}\n" "$(hostname)"
  printf "${cyan}│${reset}  User:   %-28s ${cyan}│${reset}\n" "$USER"
  printf "${cyan}│${reset}  Shell:  %-28s ${cyan}│${reset}\n" "Zsh ${ZSH_VERSION}"
  printf "${cyan}│${reset}  Time:   %-28s ${cyan}│${reset}\n" "$(date '+%H:%M:%S')"
  echo "${cyan}└─────────────────────────────────────┘${reset}"
}

# ─── MAIN ────────────────────────────────────────────────────────
_nzr_display() {
  # Cek lolcat untuk headline
  if [[ "${HEADLINE_COLOR:-lolcat}" == "lolcat" ]] && command -v lolcat &>/dev/null; then
    _nzr_combine | lolcat
  else
    echo -e "\e[1;36m"
    _nzr_combine
    echo -e "\e[0m"
  fi
  
  _nzr_welcome
  _nzr_system_info
}

_nzr_display
