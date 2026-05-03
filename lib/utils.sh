#!/bin/zsh
# NZR Theme - Utility Functions

# ─── ANSI COLORS ───────────────────────────────────────────────────
_nzr_colors() {
  local -g CYAN=$'\e[1;36m'
  local -g BLUE=$'\e[1;34m'
  local -g MAGENTA=$'\e[1;35m'
  local -g YELLOW=$'\e[1;33m'
  local -g GREEN=$'\e[1;32m'
  local -g RED=$'\e[1;31m'
  local -g WHITE=$'\e[1;37m'
  local -g RESET=$'\e[0m'
}

# ─── SIDE-BY-SIDE MERGER ───────────────────────────────────────────
_nzr_side_by_side() {
  local file1="$1"
  local file2="$2"
  local spacing="${3:-4}"
  
  [[ ! -f "$file1" ]] && return
  [[ ! -f "$file2" ]] && return
  
  local -a lines1
  local -a lines2
  lines1=(${(f)"$(bash "$file1" 2>/dev/null)"})
  lines2=(${(f)"$(zsh "$file2" 2>/dev/null)"})
  
  local max1=${#lines1}
  local max2=${#lines2}
  local max=$((max1 > max2 ? max1 : max2))
  
  # Hitung lebar maksimal file1
  local width1=0
  for line in "$lines1[@]"; do
    local clean=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
    (( ${#clean} > width1 )) && width1=${#clean}
  done
  
  local total_width=$((width1 + spacing))
  
  # Print merged
  for ((i=1; i<=max; i++)); do
    local left=""
    local right=""
    
    (( i <= max1 )) && left="${lines1[$i]}"
    (( i <= max2 )) && right="${lines2[$i]}"
    
    local clean_left=$(echo "$left" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$((total_width - ${#clean_left}))
    (( pad < 1 )) && pad=1
    
    printf "%s%*s%s\n" "$left" "$pad" "" "$right"
  done
}

# ─── SEPARATOR LINE ──────────────────────────────────────────────
_nzr_separator() {
  local char="${1:-─}"
  local width=$(stty size 2>/dev/null | cut -d' ' -f2)
  [[ -z "$width" ]] && width=80
  
  local line=""
  for ((i=0; i<width; i++)); do
    line+="$char"
  done
  echo "$line"
}
