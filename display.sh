#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║               NZR THEME — display.sh (FINAL v4)                 ║
# ║   Logo warna mengikuti HEADLINE_COLOR di config.sh              ║
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

# Warna dari config — dipakai untuk logo DAN headline
_theme_color() {
  case "${HEADLINE_COLOR:-cyan}" in
    blue)    printf '%s' "$BL" ;;
    green)   printf '%s' "$GR" ;;
    yellow)  printf '%s' "$YL" ;;
    magenta) printf '%s' "$MG" ;;
    white)   printf '%s' "$WH" ;;
    lolcat)  printf '%s' ""    ;;  # kosong = akan di-pipe ke lolcat
    *)       printf '%s' "$CY" ;;  # default cyan
  esac
}

_is_lolcat() {
  [[ "$HEADLINE_COLOR" == "lolcat" ]] && command -v lolcat &>/dev/null
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
  local t="$1" w="$2" vl="${3:-}"
  [[ -z "$vl" ]] && vl=$(_vl "$t")
  local pad=$(( (w - vl) / 2 ))
  (( pad < 0 )) && pad=0
  printf "%${pad}s%s\n" "" "$t"
}

_rep() {
  local c="$1" n="$2" s="" i=0
  while (( i < n )); do s+="$c"; (( i++ )); done
  printf '%s' "$s"
}

# ─── LOGO ─────────────────────────────────────────────────────────
_nzr_logo_raw() {
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

# Print logo dengan warna — center tiap baris
_print_logo() {
  local TW="$1"
  local col; col=$(_theme_color)

  if _is_lolcat; then
    # Mode lolcat: kumpulkan logo + padding, pipe ke lolcat sekaligus
    # supaya rainbow mengalir dari atas ke bawah (bukan per-baris)
    local logo_lines=()
    while IFS= read -r l; do logo_lines+=("$l"); done < <(_nzr_logo_raw)

    # Hitung max lebar logo untuk centering
    local max_w=0 vl
    for l in "${logo_lines[@]}"; do
      vl=${#l}; (( vl > max_w )) && max_w=$vl
    done

    # Buat output dengan padding sudah disisipkan, lalu pipe ke lolcat
    {
      for l in "${logo_lines[@]}"; do
        local pad=$(( (TW - ${#l}) / 2 ))
        (( pad < 0 )) && pad=0
        printf "%${pad}s%s\n" "" "$l"
      done
    } | lolcat -f 2>/dev/null

  else
    # Mode warna biasa: print per-baris dengan warna ANSI
    while IFS= read -r l; do
      local vl=${#l}
      printf '%s' "$col"
      _center "$l" "$TW" "$vl"
      printf '%s' "$R"
    done < <(_nzr_logo_raw)
  fi
}

# ─── NEOFETCH ─────────────────────────────────────────────────────
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
  printf "${CY}${BOLD}OS${R}:     ${WH}%s${R}\n"    "$os"
  printf "${CY}${BOLD}Host${R}:   ${WH}%s@%s${R}\n" "$usr" "$host"
  printf "${CY}${BOLD}Shell${R}:  ${WH}%s${R}\n"    "$sh_v"
  printf "${CY}${BOLD}RAM${R}:    ${WH}%s${R}\n"    "$ram"
  printf "${CY}${BOLD}Disk${R}:   ${WH}%s${R}\n"    "$disk"
  printf "${CY}${BOLD}Uptime${R}: ${WH}%s${R}\n"    "$upt"
  printf "${CY}${BOLD}Time${R}:   ${WH}%s${R}\n"    "$tim"
}

# ─── HEADLINE ─────────────────────────────────────────────────────
_nzr_headline() {
  [[ "$SHOW_HEADLINE" != "ON" ]] && return
  local text="${HEADLINE_TEXT:-NZR-RD}"
  local col; col=$(_theme_color)

  if ! command -v figlet &>/dev/null; then
    printf '%s%s%s\n' "$col" "$text" "$R"; return
  fi

  local font="banner"
  for f in big block banner3 banner; do
    figlet -f "$f" "X" &>/dev/null 2>&1 && { font="$f"; [[ "$f" == "big" || "$f" == "block" ]] && break; }
  done

  local fw="${_NZR_HL_W:-60}"

  if _is_lolcat; then
    figlet -f "$font" -w "$fw" "$text" 2>/dev/null | lolcat -f 2>/dev/null
  else
    while IFS= read -r line; do
      printf '%s%s%s\n' "$col" "$line" "$R"
    done < <(figlet -f "$font" -w "$fw" "$text" 2>/dev/null)
  fi
}

# ─── WELCOME BOX ──────────────────────────────────────────────────
_nzr_welcome() {
  [[ "$SHOW_USER_INFO" != "ON" ]] && return
  local name="${USER_NAME:-${USER:-user}}"
  local msg="${WELCOME_MSG:-Selamat datang, }"
  local col; col=$(_theme_color)

  # Jika lolcat, pakai warna random dari palet ANSI sebagai fallback welcome
  if _is_lolcat; then
    local rcols=("$CY" "$MG" "$YL" "$GR" "$BL")
    col="${rcols[$((RANDOM % 5))]}"
  fi

  local ilen=$(( ${#msg} + ${#name} ))
  local hline; hline=$(_rep "─" $(( ilen + 2 )))
  printf "${col}╭%s╮${R}\n" "$hline"
  printf "${col}│ %s${WH}${BOLD}%s${R}${col} │${R}\n" "$msg" "$name"
  printf "${col}╰%s╯${R}\n" "$hline"
}

# ─── MAIN DISPLAY ─────────────────────────────────────────────────
_nzr_display() {
  local TW; TW=$(_tw)

  # ══ 1. CLEAR ══════════════════════════════════════════════
  clear

  # ══ 2. LOGO (warna dari HEADLINE_COLOR) ═══════════════════
  if [[ "$SHOW_LOGO" == "ON" ]]; then
    _print_logo "$TW"
    printf '\n'
  fi

  # ══ 3. WELCOME (tengah) ═══════════════════════════════════
  if [[ "$SHOW_USER_INFO" == "ON" ]]; then
    local name="${USER_NAME:-${USER:-user}}"
    local msg="${WELCOME_MSG:-Selamat datang, }"
    local wel_w=$(( ${#msg} + ${#name} + 4 ))
    local wel_lines=()
    while IFS= read -r l; do wel_lines+=("$l"); done < <(_nzr_welcome)
    for l in "${wel_lines[@]}"; do _center "$l" "$TW" "$wel_w"; done
    printf '\n'
  fi

  # ══ 4. KOTAK headline (kiri) + neofetch (kanan) ═══════════
  local neo_lines=() v
  while IFS= read -r l; do neo_lines+=("$l"); done < <(_nzr_neo)

  local NEO_W=0
  for l in "${neo_lines[@]}"; do v=$(_vl "$l"); (( v > NEO_W )) && NEO_W=$v; done
  local NC=$(( NEO_W + 2 ))

  local HC_est=$(( TW - NC - 6 ))
  (( HC_est < 10 )) && HC_est=10
  export _NZR_HL_W=$(( HC_est - 2 ))

  local hl_lines=()
  if [[ "$SHOW_HEADLINE" == "ON" ]]; then
    while IFS= read -r l; do hl_lines+=("$l"); done < <(_nzr_headline)
  fi

  local HL_W=0
  for l in "${hl_lines[@]}"; do v=$(_vl "$l"); (( v > HL_W )) && HL_W=$v; done
  local HC=$(( HL_W + 2 )); (( HC < 6 )) && HC=6

  local BOX=$(( HC + NC + 6 ))
  if (( BOX > TW )); then
    local avail=$(( TW - 6 ))
    HC=$(( avail * HC / (HC + NC) )); (( HC < 6 )) && HC=6
    NC=$(( avail - HC ));            (( NC < 6 )) && NC=6
    BOX=$(( HC + NC + 6 ))
  fi

  local border_w=$(( HC + NC + 6 ))
  local col; col=$(_theme_color)
  # Border kotak juga ikut warna tema (kecuali lolcat — pakai cyan default)
  local box_col="$col"
  _is_lolcat && box_col="$CY"

  _hborder() {
    local s="${1}"
    s+=$(_rep "═" $(( HC + 2 ))); s+="${2}"
    s+=$(_rep "═" $(( NC + 2 ))); s+="${3}"
    _center "${box_col}${s}${R}" "$TW" "$border_w"
  }

  _row() {
    local lraw="$1" rcol="$2"
    local lv rv lpad rpad lcol lsp rsp
    lv=$(_vl "$lraw"); rv=$(_vl "$rcol")
    lpad=$(( HC - lv - 1 )); rpad=$(( NC - rv - 1 ))
    (( lpad < 0 )) && lpad=0; (( rpad < 0 )) && rpad=0
    [[ -n "$lraw" ]] && lcol="${col}${lraw}${R}" || lcol=""
    lsp=$(_rep " " "$lpad"); rsp=$(_rep " " "$rpad")
    local row="${box_col}║${R} ${lcol}${lsp} ${box_col}║${R} ${rcol}${rsp} ${box_col}║${R}"
    _center "$row" "$TW" "$border_w"
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
