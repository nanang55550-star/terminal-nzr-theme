#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/prompt.sh                             ║
# ║   Mesin prompt: data (RAM/DISK/git) dihitung di LATAR BELAKANG   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Masalah versi lama: tiap prompt memanggil free, df, awk, git (3-6 proses)
# dan MENUNGGU hasilnya. Di repo besar atau HP lambat, prompt terasa macet.
#
# Sekarang:
#   1. Prompt langsung digambar memakai data terakhir yang diketahui.
#   2. Nama branch dibaca dari file .git/HEAD (tanpa fork proses apa pun).
#   3. Worker latar belakang menghitung RAM, DISK, dan status git (✓ / ✗N).
#   4. Begitu worker selesai, prompt digambar ulang di tempat (zle reset-prompt)
#      tanpa mengganggu teks yang sedang kamu ketik.
#
# Tampilan tiga baris (status, dir+git, input) TIDAK berubah: fungsi render di
# bawah menghasilkan string yang sama persis dengan versi lama (diuji otomatis
# terhadap tests/fixtures/orig_prompt.zsh).
#
# Matikan: nzr set ASYNC_PROMPT OFF  (kembali ke perhitungan sinkron)

typeset -g  _NZR_RAM="N/A" _NZR_DISK="N/A"
typeset -g  _NZR_SEG_STATUS="" _NZR_SEG_DIRGIT=""
typeset -g  _NZR_G_ROOT="" _NZR_G_BRANCH=""                  # hasil baca cepat .git/HEAD
typeset -g  _NZR_GS_ROOT="" _NZR_GS_STATE="" _NZR_GS_CHANGED=0   # cache status git per repo
typeset -g  _NZR_FD="" _NZR_SEQ=0 _NZR_STATS_T=0
typeset -g  _NZR_C_STATE="none" _NZR_C_CHANGED=0

# ─── Kolektor data (dipakai worker dan mode sinkron) ──────────────

# RAM dari teks vm_stat (macOS). Argumen: <keluaran vm_stat> <hw.memsize>
# Dipisah sebagai fungsi murni agar bisa diuji dengan data contoh.
_nzr_ram_from_vmstat() {
  local txt="$1" total="$2" line v ps=4096
  local -i active=0 wired=0 comp=0
  # Regex (bukan pola glob ber-#) agar tidak bergantung pada opsi extended_glob
  for line in "${(@f)txt}"; do
    case "$line" in
      *"page size of "*)
        [[ "$line" =~ 'page size of ([0-9]+)' ]] && ps=${match[1]} ;;
      "Pages active:"*|"Pages wired down:"*|"Pages occupied by compressor:"*)
        [[ "$line" =~ ':[[:space:]]*([0-9]+)' ]] || continue
        v=${match[1]}
        case "$line" in
          "Pages active:"*)     active=$v ;;
          "Pages wired down:"*) wired=$v ;;
          *)                    comp=$v ;;
        esac ;;
    esac
  done
  [[ "$total" == <-> ]] && (( total > 0 )) || { REPLY=""; return 1; }
  local -i used_mb=$(( (active + wired + comp) * ps / 1048576 )) total_mb=$(( total / 1048576 ))
  REPLY="${used_mb}M/${total_mb}M"
}

_nzr_collect_ram() {
  REPLY=$(free -m 2>/dev/null | awk 'NR==2{printf "%dM/%dM",$3,$2}')
  if [[ -z "$REPLY" && "$OSTYPE" == darwin* ]] && (( $+commands[vm_stat] && $+commands[sysctl] )); then
    _nzr_ram_from_vmstat "$(vm_stat 2>/dev/null)" "$(sysctl -n hw.memsize 2>/dev/null)" || REPLY=""
  fi
  [[ -z "$REPLY" ]] && REPLY="N/A"
}

_nzr_collect_disk() {
  REPLY=$(df -h "${PWD:-$HOME}" 2>/dev/null | awk 'NR==2{printf "%s/%s",$3,$2}')
  [[ -z "$REPLY" ]] && REPLY="N/A"
}

# Status git di folder saat ini → _NZR_C_STATE (none|clean|dirty) dan _NZR_C_CHANGED
_nzr_collect_git() {
  local branch dirty
  local -a lines
  _NZR_C_STATE=none; _NZR_C_CHANGED=0
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  [[ -n "$branch" ]] || return 0
  # GIT_OPTIONAL_LOCKS=0: jangan berebut kunci index dengan git yang kamu jalankan
  dirty=$(GIT_OPTIONAL_LOCKS=0 git status --porcelain 2>/dev/null)
  lines=(${(f)dirty})
  _NZR_C_CHANGED=${#lines}
  [[ -n "$dirty" ]] && _NZR_C_STATE=dirty || _NZR_C_STATE=clean
}

# Baca branch langsung dari .git/HEAD (nol proses). Mengisi _NZR_G_ROOT/_NZR_G_BRANCH.
# HEAD detached → dianggap bukan repo, sama seperti perilaku versi lama.
_nzr_git_fast() {
  local d="$PWD" gd head line
  _NZR_G_ROOT=""; _NZR_G_BRANCH=""
  until [[ -e "$d/.git" ]]; do
    [[ "$d" == / || -z "$d" ]] && return 1
    d="${d:h}"
  done
  gd="$d/.git"
  if [[ -f "$gd" ]]; then                       # worktree / submodule: file berisi "gitdir: ..."
    read -r line < "$gd" 2>/dev/null || [[ -n "$line" ]] || return 1
    gd="${line#gitdir: }"
    [[ "$gd" == /* ]] || gd="$d/$gd"
  fi
  read -r head < "$gd/HEAD" 2>/dev/null || [[ -n "$head" ]] || return 1
  [[ "$head" == "ref: "* ]] || return 1
  head="${head#ref: }"; head="${head#refs/heads/}"; head="${head#refs/}"
  [[ -n "$head" ]] || return 1
  _NZR_G_ROOT="$d"; _NZR_G_BRANCH="$head"
}

# ─── Render (hasil di $REPLY; tanpa fork) ─────────────────────────
# Teks di bawah identik dengan _nzr_status/_nzr_dir_git versi lama.

_nzr_render_status() {   # <ram> <disk>
  REPLY="%{$bg[cyan]%}%{$fg[white]%} %n@%m "
  REPLY+="%{$bg[yellow]%}%{$fg[cyan]%}${SEP}%{$fg[black]%} RAM: ${1} "
  REPLY+="%{$bg[magenta]%}%{$fg[yellow]%}${SEP}%{$fg[white]%} DISK: ${2} "
  REPLY+="%{$reset_color%}%{$fg[magenta]%}${SEP}%{$reset_color%}"
}

# <branch> <state: none|dirty|clean|pending> <jumlah-perubahan>
_nzr_render_dirgit() {
  local branch="$1" state="$2" changed="$3"
  REPLY="%{$bg[blue]%}%{$fg[white]%} %~ "
  case "$state" in
    dirty)
      REPLY+="%{$bg[red]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✗${changed} "
      REPLY+="%{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}" ;;
    clean)
      REPLY+="%{$bg[green]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✓ "
      REPLY+="%{$reset_color%}%{$fg[green]%}${SEP}%{$reset_color%}" ;;
    pending)   # status git belum selesai dihitung: tampilkan branch dulu
      REPLY+="%{$bg[yellow]%}%{$fg[blue]%}${SEP}%{$fg[black]%}  ${branch} … "
      REPLY+="%{$reset_color%}%{$fg[yellow]%}${SEP}%{$reset_color%}" ;;
    *)
      REPLY+="%{$reset_color%}%{$fg[blue]%}${SEP}%{$reset_color%}" ;;
  esac
}

# Versi sinkron lama tetap tersedia (dipakai nzr bench & mode ASYNC_PROMPT=OFF)
_nzr_status() {
  _nzr_collect_ram;  local ram=$REPLY
  _nzr_collect_disk; local disk=$REPLY
  _nzr_render_status "$ram" "$disk"
  print -rn -- "$REPLY"
}
_nzr_dir_git() {
  _nzr_collect_git
  _nzr_git_fast
  local st="$_NZR_C_STATE" b="$_NZR_G_BRANCH"
  if [[ "$st" != none && -z "$b" ]]; then b=$(git symbolic-ref --short HEAD 2>/dev/null); fi
  _nzr_render_dirgit "$b" "$st" "$_NZR_C_CHANGED"
  print -rn -- "$REPLY"
}

# Rakit segmen prompt dari cache saat ini
_nzr_prompt_render() {
  local st=none
  _nzr_render_status "$_NZR_RAM" "$_NZR_DISK"
  _NZR_SEG_STATUS="$REPLY"
  if [[ -n "$_NZR_G_BRANCH" ]]; then
    if [[ "$_NZR_GS_ROOT" == "$_NZR_G_ROOT" && -n "$_NZR_GS_STATE" ]]; then
      st="$_NZR_GS_STATE"            # none = git sendiri menolak (mis. safe.directory) → tanpa segmen git
    else
      st=pending
    fi
  fi
  _nzr_render_dirgit "$_NZR_G_BRANCH" "$st" "$_NZR_GS_CHANGED"
  _NZR_SEG_DIRGIT="$REPLY"
}

# ─── Mesin async ──────────────────────────────────────────────────

# Async hanya jika diminta DAN zsh mendukung 'zle -F' di shell interaktif
_nzr_async_ok() {
  [[ "$ASYNC_PROMPT" == "ON" && -o interactive && -o zle ]] || return 1
  (( ${+builtins[zle]} )) || return 1
  return 0
}

_nzr_async_cancel() {
  [[ -n "$_NZR_FD" ]] || return 0
  zle -F "$_NZR_FD" 2>/dev/null
  exec {_NZR_FD}<&- 2>/dev/null
  _NZR_FD=""
}

# Dijalankan di proses terpisah. Satu rekaman per job, dipisah US (0x1f), diakhiri RS (0x1e).
_nzr_worker() {   # <seq> <ram/disk? 1|0> <ada repo? 1|0>
  local seq=$1 stats=$2 repo=$3 ram="" disk="" state="" changed=0
  if (( stats )); then
    _nzr_collect_ram;  ram=$REPLY
    _nzr_collect_disk; disk=$REPLY
  fi
  if (( repo )); then
    _nzr_collect_git; state=$_NZR_C_STATE; changed=$_NZR_C_CHANGED
  fi
  print -rn -- "${seq}"$'\x1f'"${PWD}"$'\x1f'"${ram}"$'\x1f'"${disk}"$'\x1f'"${state}"$'\x1f'"${changed}"$'\x1e'
}

_nzr_async_start() {
  _nzr_async_cancel
  local -i seq=$(( ++_NZR_SEQ )) stats=0 repo=0
  # RAM/DISK berubah pelan: segarkan paling cepat tiap 5 detik
  if (( EPOCHSECONDS - _NZR_STATS_T >= 5 )); then stats=1; _NZR_STATS_T=$EPOCHSECONDS; fi
  [[ -n "$_NZR_G_ROOT" ]] && repo=1
  (( stats || repo )) || return 0
  exec {_NZR_FD}< <(_nzr_worker $seq $stats $repo)
  zle -F "$_NZR_FD" _nzr_async_cb
}

_nzr_async_cb() {
  local fd=$1 data
  zle -F "$fd"                                   # lepas handler; sekali pakai
  IFS= read -r -u "$fd" -d $'\x1e' data
  exec {fd}<&-
  [[ "$_NZR_FD" == "$fd" ]] && _NZR_FD=""
  [[ -n "$data" ]] || return 0

  local -a f=("${(@ps:\x1f:)data}")
  (( f[1] == _NZR_SEQ )) || return 0             # hasil basi (sudah ada job lebih baru)
  [[ "${f[2]}" == "$PWD" ]] || return 0          # folder sudah berpindah

  [[ -n "${f[3]}" ]] && _NZR_RAM="${f[3]}"
  [[ -n "${f[4]}" ]] && _NZR_DISK="${f[4]}"
  if [[ -n "${f[5]}" && -n "$_NZR_G_ROOT" ]]; then
    _NZR_GS_ROOT="$_NZR_G_ROOT"; _NZR_GS_STATE="${f[5]}"; _NZR_GS_CHANGED="${f[6]:-0}"
  fi
  _nzr_prompt_render
  zle && zle reset-prompt
}

# ─── Hook: dipanggil tiap prompt, paling akhir di deretan precmd ──
_nzr_precmd_prompt() {
  _nzr_git_fast
  if _nzr_async_ok; then
    _nzr_prompt_render
    _nzr_async_start
  else
    # mode sinkron (perilaku v2.0)
    _nzr_collect_ram;  _NZR_RAM=$REPLY
    _nzr_collect_disk; _NZR_DISK=$REPLY
    if [[ -n "$_NZR_G_ROOT" ]]; then
      _nzr_collect_git
      _NZR_GS_ROOT="$_NZR_G_ROOT"; _NZR_GS_STATE="$_NZR_C_STATE"; _NZR_GS_CHANGED="$_NZR_C_CHANGED"
    fi
    _nzr_prompt_render
  fi
}

# Isi awal sekali saat theme dimuat, supaya prompt pertama sudah berisi angka nyata
_nzr_collect_ram;  _NZR_RAM=$REPLY
_nzr_collect_disk; _NZR_DISK=$REPLY
_NZR_STATS_T=$EPOCHSECONDS
