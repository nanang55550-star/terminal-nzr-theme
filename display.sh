#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║               NZR THEME — display.sh (FINAL)                    ║
# ║   Layout: clear → logo tengah → welcome → kotak headline+neo    ║
# ╚══════════════════════════════════════════════════════════════════╝

NZR_DIR="${ZSH_SCRIPT:A:h}"
[[ -z "$NZR_DIR" || "$NZR_DIR" == "." ]] && NZR_DIR="${0:A:h}"
[[ -f "$NZR_DIR/config.sh" ]] && source "$NZR_DIR/config.sh"

: "${SHOW_LOGO:=ON}"
: "${SHOW_HEADLINE:=ON}"
: "${SHOW_USER_INFO:=ON}"
: "${SHOW_SYSTEM_INFO:=ON}"
: "${HEADLINE_TEXT:=NZR-RD}"
: "${HEADLINE_COLOR:=cyan}"
: "${USER_NAME:=$USER}"
: "${WELCOME_MSG:=Selamat datang, }"

R=$'\e[0m';   BOLD=$'\e[1m'
GR=$'\e[1;32m'; CY=$'\e[1;36m'; BL=$'\e[1;34m'
WH=$'\e[1;37m'; YL=$'\e[1;33m'; MG=$'\e[1;35m'

_hl_color() {
  case "${HEADLINE_COLOR:-cyan}" in
    blue)    printf '%s' "$BL" ;;
    green)   printf '%s' "$GR" ;;
    yellow)  printf '%s' "$YL" ;;
    magenta) printf '%s' "$MG" ;;
    white)   printf '%s' "$WH" ;;
    lolcat)  command -v lolcat &>/dev/null && printf '' || printf '%s' "$CY" ;;
    *)       printf '%s' "$CY" ;;
  esac
}

_tw() {
  local w="${COLUMNS:-0}"
  (( w > 0 )) && { echo "$w"; return; }
  w=$(tput cols 2>/dev/null); (( w > 0 )) && { echo "$w"; return; }
  w=$(stty size 2>/dev/null | awk '{print $2}'); (( w > 0 )) && { echo "$w"; return; }
  echo 80
}

_vl() {
  local s; s=$(printf '%s' "$1" | sed $'s/\x1b\\[[0-9;]*[mKJHABCDGsu]//g')
  printf '%s' "${#s}"
}

_center() {
  local t="$1" w="$2" vl pad
  vl=$(_vl "$t"); pad=$(( (w - vl) / 2 ))
  (( pad < 0 )) && pad=0
  printf "%${pad}s%s\n" "" "$t"
}

_rep() {
  local c="$1" n="$2" s="" i=0
  while (( i < n )); do s+="$c"; (( i++ )); done
  printf '%s' "$s"
}

_nzr_logo() {
  cat <<'LOGO'
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
LOGO
}

_nzr_neo() {
  [[ "$SHOW_SYSTEM_INFO" != "ON" ]] && return
  local os host usr sh_v ram disk upt tim
  os=$(uname -o 2>/dev/null || uname -s)
  host=$(hostname 2>/dev/null || echo "localhost")
  usr="${USER:-$(whoami 2>/dev/null || echo user)}"
  sh_v="Zsh ${ZSH_VERSION:-?}"
  tim=$(date '+%H:%M:%S')
  ram=$(free -m 2>/dev/null | awk 'NR==2{printf "%dM/%dM",$3,$2}')
  [[ -z "$ram" ]] && ram="N/A"
  disk=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{printf "%s/%s",$3,$2}')
  [[ -z "$disk" ]] && disk="N/A"
  upt=$(uptime -p 2>/dev/null | sed 's/up //')
  [[ -z "$upt" ]] && upt=$(uptime 2>/dev/null | sed 's/.*up //;s/,.*//' | xargs)
  [[ -z "$upt" ]] && upt="N/A"
  printf "${CY}${BOLD}OS${R}:     ${WH}%s${R}\n"     "$os"
  printf "${CY}${BOLD}Host${R}:   ${WH}%s@%s${R}\n" "$usr" "$host"
  printf "${CY}${BOLD}Shell${R}:  ${WH}%s${R}\n"     "$sh_v"
  printf "${CY}${BOLD}RAM${R}:    ${WH}%s${R}\n"     "$ram"
  printf "${CY}${BOLD}Disk${R}:   ${WH}%s${R}\n"     "$disk"
  printf "${CY}${BOLD}Uptime${R}: ${WH}%s${R}\n"     "$upt"
  printf "${CY}${BOLD}Time${R}:   ${WH}%s${R}\n"     "$tim"
}

_nzr_headline() {
  [[ "$SHOW_HEADLINE" != "ON" ]] && return
  local text="${HEADLINE_TEXT:-NZR-RD}"
  local col; col=$(_hl_color)
  if ! command -v figlet &>/dev/null; then
    printf '%s%s%s\n' "$col" "$text" "$R"; return
  fi
  local font="banner"
  for f in big block banner3 banner; do
    figlet -f "$f" "X" &>/dev/null 2>&1 && { font="$f"; [[ "$f" == "big" || "$f" == "block" ]] && break; }
  done
  local fw="${_NZR_HL_W:-60}"
  if [[ "$HEADLINE_COLOR" == "lolcat" ]] && command -v lolcat &>/dev/null; then
    figlet -f "$font" -w "$fw" "$text" 2>/dev/null | lolcat -f 2>/dev/null
  else
    while IFS= read -r line; do
      printf '%s%s%s\n' "$col" "$line" "$R"
    done < <(figlet -f "$font" -w "$fw" "$text" 2>/dev/null)
  fi
}

_nzr_welcome() {
  [[ "$SHOW_USER_INFO" != "ON" ]] && return
  local name="${USER_NAME:-${USER:-user}}"
  local msg="${WELCOME_MSG:-Selamat datang, }"
  local cols=("$CY" "$BL" "$MG" "$YL" "$GR")
  local c="${cols[$((RANDOM % 5))]}"
  local inner="${msg}${name}"
  local ilen; ilen=$(_vl "$inner")
  local hline; hline=$(_rep "─" $(( ilen + 2 )))
  printf "${c}╭%s╮${R}\n" "$hline"
  printf "${c}│ %s${WH}${BOLD}%s${R}${c} │${R}\n" "$msg" "$name"
  printf "${c}╰%s╯${R}\n" "$hline"
}

_nzr_display() {
  local TW; TW=$(_tw)

  # ══ STEP 1: CLEAR ══════════════════════════════════════════
  clear

  # ══ STEP 2: LOGO di tengah atas ═══════════════════════════
  if [[ "$SHOW_LOGO" == "ON" ]]; then
    local logo_lines=()
    while IFS= read -r l; do logo_lines+=("$l"); done < <(_nzr_logo)
    printf '%s' "$GR"
    for l in "${logo_lines[@]}"; do _center "$l" "$TW"; done
    printf '%s\n' "$R"
  fi

  # ══ STEP 3: WELCOME di tengah (bawah logo) ════════════════
  if [[ "$SHOW_USER_INFO" == "ON" ]]; then
    local wel_lines=()
    while IFS= read -r l; do wel_lines+=("$l"); done < <(_nzr_welcome)
    for l in "${wel_lines[@]}"; do _center "$l" "$TW"; done
    printf '\n'
  fi

  # ══ STEP 4: KOTAK headline (kiri) + neofetch (kanan) ══════
  # Kumpulkan neofetch dulu → hitung lebar kolom kanan
  local neo_lines=() v
  while IFS= read -r l; do neo_lines+=("$l"); done < <(_nzr_neo)

  local NEO_W=0
  for l in "${neo_lines[@]}"; do v=$(_vl "$l"); (( v > NEO_W )) && NEO_W=$v; done
  local NC=$(( NEO_W + 2 ))

  # Estimasi kolom kiri → set figlet width supaya pas
  local HC_est=$(( TW - NC - 6 ))
  (( HC_est < 10 )) && HC_est=10
  export _NZR_HL_W=$(( HC_est - 2 ))

  # Generate headline dengan width yang sudah proporsional
  local hl_lines=()
  if [[ "$SHOW_HEADLINE" == "ON" ]]; then
    while IFS= read -r l; do hl_lines+=("$l"); done < <(_nzr_headline)
  fi

  # Hitung ulang HC dari konten aktual headline
  local HL_W=0
  for l in "${hl_lines[@]}"; do v=$(_vl "$l"); (( v > HL_W )) && HL_W=$v; done
  local HC=$(( HL_W + 2 )); (( HC < 6 )) && HC=6

  # Proporsikan jika melebihi terminal
  local BOX=$(( HC + NC + 6 ))
  if (( BOX > TW )); then
    local avail=$(( TW - 6 ))
    HC=$(( avail * HC / (HC + NC) )); (( HC < 6 )) && HC=6
    NC=$(( avail - HC ));            (( NC < 6 )) && NC=6
  fi

  _hborder() {
    local s="${1}"
    s+=$(_rep "═" $(( HC + 2 ))); s+="${2}"
    s+=$(_rep "═" $(( NC + 2 ))); s+="${3}"
    _center "$s" "$TW"
  }

  _row() {
    local lraw="$1" rcol="$2" lv rv lpad rpad lcol lsp rsp
    lv=$(_vl "$lraw"); rv=$(_vl "$rcol")
    lpad=$(( HC - lv - 1 )); rpad=$(( NC - rv - 1 ))
    (( lpad < 0 )) && lpad=0; (( rpad < 0 )) && rpad=0
    lcol=""; [[ -n "$lraw" ]] && lcol="${CY}${lraw}${R}"
    lsp=$(_rep " " "$lpad"); rsp=$(_rep " " "$rpad")
    _center "║ ${lcol}${lsp} ║ ${rcol}${rsp} ║" "$TW"
  }

  local max=$(( ${#hl_lines[@]} > ${#neo_lines[@]} ? ${#hl_lines[@]} : ${#neo_lines[@]} ))
  if (( max > 0 )); then
    _hborder "╔" "╦" "╗"
    local i=0
    while (( i < max )); do
      _row "${hl_lines[$i]:-}" "${neo_lines[$i]:-}"
      (( i++ ))
    done
    _hborder "╚" "╩" "╝"
  fi

  printf '\n'
}

_nzr_display
