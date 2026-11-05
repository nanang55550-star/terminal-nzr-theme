#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — tests/run.zsh                             ║
# ║   Jalankan:  zsh tests/run.zsh                                   ║
# ╚══════════════════════════════════════════════════════════════════╝
# Tanpa dependensi selain zsh + git + awk. Aman: semua berkas sementara
# ditulis ke folder temp, config.sh asli tidak disentuh.
#
# Yang dijaga:
#   1. Tampilan tiga baris TIDAK berubah dari v2.0 (golden test byte-per-byte)
#   2. Kebenaran: kode exit, durasi, saran typo, lebar layar sempit
#   3. Keamanan: validasi nzr set, penyaringan rahasia, izin file, anti-injeksi
#   4. Palet warna: kontras teks WCAG di semua tema
#   5. Mesin async, statistik, fix, dan konversi warna

emulate -L zsh
setopt no_unset 2>/dev/null; unsetopt no_unset
zmodload zsh/datetime 2>/dev/null

ROOT="${0:A:h:h}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export LC_ALL="${LC_ALL:-C.UTF-8}"; [[ "$(locale charmap 2>/dev/null)" == UTF-8 ]] || export LC_ALL=en_US.UTF-8

typeset -i PASS=0 FAIL=0
typeset -a FAILED

ok()   { PASS+=1; print -P "  %F{green}✓%f $1"; }
bad()  { FAIL+=1; FAILED+=("$1"); print -P "  %F{red}✘%f $1"; [[ -n "${2:-}" ]] && print -r -- "      $2"; }
check() { # check "nama" <perintah-test...>   → lulus bila perintah mengembalikan 0
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi
}
eq() {    # eq "nama" "diharapkan" "aktual"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1" "diharapkan: ${(V)2}  |  aktual: ${(V)3}"; fi
}
section() { print -P "\n%F{cyan}%B$1%b%f"; }

# ─── muat theme sebagai shell non-interaktif ──────────────────────
autoload -U colors && colors
SEP=$'\ue0b0'
ASYNC_PROMPT=OFF NZR_VERSION=test
SHOW_ERROR_LINE=ON ERROR_LINE_MODE=always ERROR_SHOW_CMD=ON ERROR_SUGGEST=ON ERROR_SHOW_JOBS=OFF
ERROR_SHOW_TIME=OFF SHOW_CMD_DURATION=ON CMD_DURATION_MIN=1 STATS_LOG=ON
NOTIFY_LONG_CMD=ON NOTIFY_MIN_SECONDS=30 NOTIFY_BELL=OFF NOTIFY_IGNORE="vim ssh"
export NZR_DATA_DIR="$TMP/data"
NZR_DIR="$TMP/repo"; mkdir -p "$NZR_DIR"; cp -r "$ROOT/lib" "$ROOT/config.sh" "$NZR_DIR/"
NZR_SUGGEST_LOG="$TMP/suggest.log"; NZR_LOG_LIMIT=50
for m in privacy theme prompt errorline notify insights cli; do source "$ROOT/lib/$m.sh"; done
source "$ROOT/tests/fixtures/orig_prompt.zsh"

# repo contoh
mkdir -p "$TMP/g/plain" "$TMP/g/clean" "$TMP/g/dirty"
(cd "$TMP/g/clean" && git init -q && git config user.email t@t && git config user.name t && echo a > a && git add . && git commit -qm i)
(cd "$TMP/g/dirty" && git init -q && git config user.email t@t && git config user.name t && echo a > a && git add . && git commit -qm i && echo b >> a && echo n > n1 && echo m > n2)

# ═════════════════════════════════════════════════════════════════
section "1. Tampilan tiga baris identik dengan v2.0 (golden)"
for d in plain clean dirty; do
  cd "$TMP/g/$d"
  o=$(_orig_dir_git); n=$(_nzr_dir_git)
  eq "dir+git [$d] sama persis dengan versi lama" "$o" "$n"
done
cd "$TMP/g/plain"
free() { print x; print "Mem: 5711 3370 0"; }
df()   { print x; print "/dev/x 105G 102G 3G 98% /"; }
eq "status (user@host · RAM · DISK) sama persis dengan versi lama" "$(_orig_status)" "$(_nzr_status)"
unfunction free df

# render pending/clean/dirty konsisten
_nzr_render_dirgit main clean 0;  c1="$REPLY"
_nzr_render_dirgit main dirty 4;  c2="$REPLY"
_nzr_render_dirgit main pending 0; c3="$REPLY"
[[ "$c1" == *"main ✓"* ]]  && ok "render clean memuat ✓"  || bad "render clean memuat ✓"
[[ "$c2" == *"main ✗4"* ]] && ok "render dirty memuat ✗N" || bad "render dirty memuat ✗N"
[[ "$c3" == *"main …"* ]]  && ok "render pending memuat …" || bad "render pending memuat …"

# ═════════════════════════════════════════════════════════════════
section "2. Arti kode exit"
_nzr_err_meaning 127;  eq "127 → perintah tidak ada"   "perintah tidak ada" "$REPLY"
_nzr_err_meaning 126;  eq "126 → tidak bisa dieksekusi" "tidak bisa dieksekusi" "$REPLY"
_nzr_err_meaning 130;  eq "130 → Ctrl+C" "dihentikan (Ctrl+C)" "$REPLY"
_nzr_err_meaning 137;  eq "137 → SIGKILL" "di-kill (SIGKILL)" "$REPLY"
_nzr_err_meaning 139;  eq "139 → segfault" "segfault" "$REPLY"
_nzr_err_meaning 99;   eq "99 → generik" "perintah gagal" "$REPLY"

section "3. Format durasi"
_nzr_fmt_dur 0.034;   eq "34 ms"      "34ms"   "$REPLY"
_nzr_fmt_dur 1.26;    eq "1.3 s"      "1.3s"   "$REPLY"
_nzr_fmt_dur 42.9;    eq "42 s"       "42s"    "$REPLY"
_nzr_fmt_dur 185;     eq "3m05s"      "3m05s"  "$REPLY"
_nzr_fmt_dur 3720;    eq "1h02m"      "1h02m"  "$REPLY"

# ═════════════════════════════════════════════════════════════════
section "4. Saran perintah salah ketik"
_nzr_edit_dist kitten sitting; eq "jarak kitten→sitting = 3" 3 "$REPLY"
_nzr_edit_dist gti git;        eq "gti→git = 1 (huruf tertukar)" 1 "$REPLY"
_nzr_suggest gti;    eq "gti → git"    git "$REPLY"
_nzr_suggest sl;     eq "sl → ls"      ls  "$REPLY"
_nzr_suggest pyhton; [[ "$REPLY" == python* ]] && ok "pyhton → python*" || bad "pyhton → python*" "$REPLY"
_nzr_suggest qqzzxx; rc=$?; eq "kata ngawur → tidak ada saran" 1 "$rc"
_nzr_missing_word 'cd /tmp && gti push | cat'; eq "kata hilang dalam rantai" gti "$REPLY"
_nzr_missing_word 'FOO=1 sudo ls -la';          rc=$?; eq "perintah valid → tidak ada kata hilang" 1 "$rc"

# ═════════════════════════════════════════════════════════════════
section "5. Baris error: isi, urutan prioritas, layar sempit"
_NZR_LAST_CMD="gti status"; _NZR_CMD_START=$(( EPOCHREALTIME - 1.5 )); _NZR_FAIL_STREAK=0
_nzr_err_build 127 127
joined="${(j:|:)_NZR_E_TX}"
[[ "$joined" == *"127"* && "$joined" == *"perintah tidak ada"* && "$joined" == *"mungkin: git"* && "$joined" == *"gti status"* ]] \
  && ok "gagal 127: kode, arti, saran, perintah" || bad "gagal 127: kode, arti, saran, perintah" "$joined"
[[ "$joined" == *"1.5s"* ]] && ok "durasi ≥ ambang tampil" || bad "durasi ≥ ambang tampil" "$joined"

_nzr_err_build 0 0
eq "sukses → hanya '✓ ok' (cepat, tanpa durasi)" "✓ ok|1.5s" "${(j:|:)_NZR_E_TX}"
_NZR_CMD_START=$EPOCHREALTIME; _nzr_err_build 0 0
eq "sukses cepat → '✓ ok' saja" "✓ ok" "${(j:|:)_NZR_E_TX}"
_nzr_err_build 0 1 0
[[ "${_NZR_E_TX[1]}" == *"pipe 1|0"* ]] && ok "pipeline gagal di tengah → peringatan" || bad "pipeline gagal di tengah → peringatan" "${_NZR_E_TX[1]}"

_NZR_FAIL_STREAK=0; _nzr_err_build 1 1; _nzr_err_build 1 1; _nzr_err_build 1 1
[[ "${_NZR_E_TX[1]}" == *"×3"* ]] && ok "streak gagal beruntun ×3" || bad "streak gagal beruntun ×3" "${_NZR_E_TX[1]}"
_nzr_err_build 0 0
eq "streak reset setelah sukses" 0 "$_NZR_FAIL_STREAK"

# layar sempit: saran harus bertahan, durasi dibuang duluan
_NZR_LAST_CMD="gti status"; _NZR_CMD_START=$(( EPOCHREALTIME - 2 )); _NZR_FAIL_STREAK=0
_nzr_err_build 127 127
COLUMNS=38 SHOW_ERROR_LINE=ON ERROR_LINE_MODE=always _nzr_err_render
plain=$(print -r -- "$_NZR_ERRLINE" | sed 's/%{[^%]*%}//g')
[[ "$plain" == *"mungkin: git"* ]] && ok "layar 38 kolom: saran perintah bertahan" || bad "layar 38 kolom: saran perintah bertahan" "$plain"
[[ "$plain" != *"2.0s"* ]] && ok "layar 38 kolom: durasi dibuang lebih dulu" || bad "layar 38 kolom: durasi dibuang lebih dulu" "$plain"
SHOW_ERROR_LINE=ON ERROR_LINE_MODE=error; _nzr_err_build 0 0; _nzr_err_render
eq "mode 'error': baris tersembunyi saat sukses" "" "$_NZR_ERRLINE"
ERROR_LINE_MODE=always

# ═════════════════════════════════════════════════════════════════
section "6. Keamanan"
# regex rahasia
for s in "curl -H 'Authorization: Bearer abc'" "export API_KEY=xyz" "echo ghp_abcdefghijklmnop" "git clone https://u:pw@host/x.git" "mysql --password=abc"; do
  [[ "${(L)s}" =~ $_NZR_SENSITIVE_RE ]] && ok "log menyaring: ${s[1,36]}…" || bad "log menyaring: $s"
done
for s in "ls -la" "git status" "cd projects" "echo halo"; do
  [[ "${(L)s}" =~ $_NZR_SENSITIVE_RE ]] && bad "log tidak boleh menyaring: $s" || ok "log mencatat: $s"
done
hs='echo token=abc';   [[ "${(L)hs}" =~ $_NZR_HIST_RE ]] && ok "history menyaring token" || bad "history menyaring token"
hs='sudo apt update';  [[ "${(L)hs}" =~ $_NZR_HIST_RE ]] && bad "history tidak boleh menyaring sudo" || ok "history menyimpan sudo (tidak berlebihan)"
HIST_SCRUB=ON _nzr_zshaddhistory 'export TOKEN=abc'; eq "zshaddhistory: rahasia → return 2 (tidak ke file)" 2 "$?"
HIST_SCRUB=ON _nzr_zshaddhistory 'ls -la';           eq "zshaddhistory: perintah biasa → return 0" 0 "$?"
HIST_SCRUB=OFF _nzr_zshaddhistory 'export TOKEN=abc'; eq "zshaddhistory: HIST_SCRUB=OFF → tidak menyaring" 0 "$?"

# nzr set: validasi & anti-injeksi
# fixture config milik tes sendiri → hasil tidak bergantung pada isi config.sh siapa pun
cat > "$NZR_DIR/config.sh" <<'CFG'
#!/bin/zsh
SHOW_LOGO="ON"          # Logo ASCII
WELCOME_MSG="Selamat datang, "   # sapaan
USER_NAME=""
CFG
out=$(_nzr_cli_set SHOW_LOGO maybe 2>&1);                  [[ "$out" == *"ON atau OFF"* ]]  && ok "set: nilai bukan ON/OFF ditolak" || bad "set: nilai bukan ON/OFF ditolak" "$out"
out=$(_nzr_cli_set RM_RF yes 2>&1);                        [[ "$out" == *"tidak dikenal"* ]] && ok "set: opsi tak dikenal ditolak" || bad "set: opsi tak dikenal ditolak"
out=$(_nzr_cli_set USER_NAME 'x$(touch /tmp/pwn)' 2>&1);   [[ "$out" == *"hanya boleh"* ]]  && ok "set: \$(...) di teks ditolak" || bad "set: \$(...) di teks ditolak" "$out"
out=$(_nzr_cli_set USER_NAME 'a";touch /tmp/pwn;"' 2>&1);  [[ "$out" == *"hanya boleh"* ]]  && ok "set: kutip + ; ditolak" || bad "set: kutip + ; ditolak"
out=$(_nzr_cli_set CMD_DURATION_MIN '1;ls' 2>&1);          [[ "$out" == *"angka"* ]]        && ok "set: angka tidak valid ditolak" || bad "set: angka tidak valid ditolak"
[[ ! -e /tmp/pwn ]] && ok "tidak ada perintah yang ikut terjalankan" || { bad "FILE /tmp/pwn TERBUAT"; rm -f /tmp/pwn; }
_nzr_cli_set SHOW_LOGO off >/dev/null; grep -q '^SHOW_LOGO="OFF"' "$NZR_DIR/config.sh" && ok "set: tersimpan ke config.sh" || bad "set: tersimpan ke config.sh"
grep -q '^SHOW_LOGO="OFF" *# Logo ASCII$' "$NZR_DIR/config.sh" && ok "set: komentar di belakang nilai dipertahankan" || bad "set: komentar dipertahankan" "$(grep ^SHOW_LOGO "$NZR_DIR/config.sh")"
_nzr_cli_set USER_NAME Budi >/dev/null
grep -q '^USER_NAME="Budi"$' "$NZR_DIR/config.sh" && ok "set: baris tanpa komentar (config lama) juga bekerja" || bad "set: baris tanpa komentar" "$(grep ^USER_NAME "$NZR_DIR/config.sh")"
_nzr_cli_set STATS_LOG off >/dev/null
grep -q '^STATS_LOG="OFF"$' "$NZR_DIR/config.sh" && ok "set: opsi yang belum ada di config lama ditambahkan" || bad "set: opsi baru ditambahkan"
[[ "$(grep -c '^#!/bin/zsh' "$NZR_DIR/config.sh")" == 1 ]] && ok "set: baris shebang tidak rusak" || bad "set: baris shebang tidak rusak"
STATS_LOG=ON
_nzr_cli_set WELCOME_MSG "Halo bos" >/dev/null; grep -q '^WELCOME_MSG="Halo bos, *"\|^WELCOME_MSG="Halo bos "' "$NZR_DIR/config.sh" && ok "set: WELCOME_MSG diakhiri satu spasi" || bad "set: WELCOME_MSG diakhiri satu spasi" "$(grep ^WELCOME_MSG $NZR_DIR/config.sh)"

# judul terminal tidak boleh meneruskan ESC asli
raw=$'ls\e]0;PWNED\a'; t="${(V)raw}"
[[ "$t" != *$'\e'* && "$t" != *$'\a'* ]] && ok "judul terminal: ESC/BEL dinetralkan" || bad "judul terminal: ESC/BEL dinetralkan"

# izin file statistik
_NZR_STATS_FILE="$TMP/data/stats.tsv"; _NZR_DATA="$TMP/data"
_nzr_stats_record 0 0.5 "git push origin main --password=rahasia"
[[ -f "$_NZR_STATS_FILE" ]] && ok "stats: file dibuat" || bad "stats: file dibuat"
perm=$(stat -c %a "$_NZR_STATS_FILE" 2>/dev/null || stat -f %Lp "$_NZR_STATS_FILE")
eq "stats: izin file 600" 600 "$perm"
perm=$(stat -c %a "$TMP/data" 2>/dev/null || stat -f %Lp "$TMP/data")
eq "stats: izin folder 700" 700 "$perm"
grep -q "rahasia\|origin\|password" "$_NZR_STATS_FILE" && bad "stats: argumen TIDAK boleh tercatat" || ok "stats: hanya nama perintah yang tercatat (tanpa argumen)"
eq "stats: nama perintah = git" git "$(cut -f4 "$_NZR_STATS_FILE" | tail -1)"
STATS_LOG=OFF _nzr_stats_record 0 0.1 "ls"; eq "stats: STATS_LOG=OFF tidak mencatat" 1 "$(wc -l < "$_NZR_STATS_FILE" | tr -d ' ')"

# ═════════════════════════════════════════════════════════════════
section "7. Palet warna: kontras teks (WCAG)"
_lin() { local -F v=$(( $1 / 255.0 )); (( v <= 0.04045 )) && REPLY=$(( v / 12.92 )) || REPLY=$(( ((v + 0.055) / 1.055) ** 2.4 )); }
_lum() { local hx=$1; local -F r g b; _lin $(( 16#${hx[1,2]} )); r=$REPLY; _lin $(( 16#${hx[3,4]} )); g=$REPLY; _lin $(( 16#${hx[5,6]} )); b=$REPLY; REPLY=$(( 0.2126*r + 0.7152*g + 0.0722*b )); }
_cr() { local -F la lb hi lo; _lum $1; la=$REPLY; _lum $2; lb=$REPLY; (( la > lb )) && { hi=$la; lo=$lb; } || { hi=$lb; lo=$la; }; REPLY=$(( (hi + 0.05) / (lo + 0.05) )); }
# urutan palet: black red green yellow blue magenta cyan white
for th in nord dracula gruvbox tokyonight catppuccin; do
  hex=(${=_NZR_PAL[$th]}); k=$hex[1] r=$hex[2] g=$hex[3] y=$hex[4] b=$hex[5] m=$hex[6] c=$hex[7] w=$hex[8]
  _cr $w $r; (( REPLY >= 4.5 )) && ok "$th: putih/merah ≥ 4.5 ($(printf %.1f $REPLY))"   || bad "$th: putih/merah ≥ 4.5" "$REPLY"
  _cr $w $m; (( REPLY >= 4.5 )) && ok "$th: putih/magenta ≥ 4.5 ($(printf %.1f $REPLY))" || bad "$th: putih/magenta ≥ 4.5" "$REPLY"
  _cr $w $b; (( REPLY >= 4.5 )) && ok "$th: putih/biru ≥ 4.5 ($(printf %.1f $REPLY))"    || bad "$th: putih/biru ≥ 4.5" "$REPLY"
  _cr $k $y; (( REPLY >= 7.0 )) && ok "$th: hitam/kuning ≥ 7 ($(printf %.1f $REPLY))"    || bad "$th: hitam/kuning ≥ 7" "$REPLY"
  for pair in "${w}:${g}:hijau" "${k}:${g}:hijau" "${w}:${c}:cyan" "${k}:${c}:cyan"; do   # {} wajib: "$g:h" = modifier head!
    pp=(${(s.:.)pair})
    _cr $pp[1] $pp[2]; (( REPLY >= 3.0 )) && ok "$th: $pp[3] teks ≥ 3 ($(printf %.1f $REPLY))" || bad "$th: $pp[3] teks ≥ 3" "$REPLY"
  done
done

section "8. Mesin tema"
_nzr_rgb256 255 255 255; eq "putih → 231" 231 "$REPLY"
_nzr_rgb256 0 0 0;       eq "hitam → 16"  16  "$REPLY"
_nzr_rgb256 128 128 128; eq "abu 128 → 244" 244 "$REPLY"
_saveTERM=$TERM; TERM=xterm-256color
COLORTERM=truecolor _nzr_theme_apply nord
[[ "$fg[red]" == $'\e[38;2;178;72;82m' ]] && ok "truecolor: fg[red] memakai RGB" || bad "truecolor: fg[red] memakai RGB" "${(V)fg[red]}"
NZR_COLOR_DEPTH=256 _nzr_theme_apply nord
[[ "$fg[red]" == $'\e[38;5;'*m ]] && ok "256 warna: fg[red] memakai indeks" || bad "256 warna: fg[red] memakai indeks" "${(V)fg[red]}"
_nzr_theme_apply default
[[ "$fg[red]" == $'\e[31m' && "$bg[cyan]" == $'\e[46m' ]] && ok "default memulihkan warna ANSI asli" || bad "default memulihkan warna ANSI asli"
TERM=dumb _nzr_theme_apply dracula
[[ "$fg[red]" == $'\e[31m' ]] && ok "terminal dumb: tema diabaikan" || bad "terminal dumb: tema diabaikan"
TERM=$_saveTERM; _nzr_theme_apply default

# ═════════════════════════════════════════════════════════════════
section "9. RAM macOS dari vm_stat (data contoh)"
vm=$'Mach Virtual Memory Statistics: (page size of 16384 bytes)\nPages free:                               20000.\nPages active:                            200000.\nPages inactive:                          190000.\nPages wired down:                        100000.\nPages occupied by compressor:             50000.'
_nzr_ram_from_vmstat "$vm" $(( 16 * 1073741824 ))
eq "(200000+100000+50000) hal × 16 KiB = 5468 MB dari 16384 MB" "5468M/16384M" "$REPLY"
_nzr_ram_from_vmstat "$vm" ""; rc=$?; eq "total tidak valid → gagal" 1 "$rc"

# ═════════════════════════════════════════════════════════════════
section "10. Mesin prompt: baca git cepat & cache"
cd "$TMP/g/clean";  _nzr_git_fast; eq "branch dibaca dari .git/HEAD" "${$(git symbolic-ref --short HEAD)}" "$_NZR_G_BRANCH"
cd "$TMP/g/plain";  _nzr_git_fast; rc=$?; eq "bukan repo → tidak ada branch" "" "$_NZR_G_BRANCH"
cd "$TMP/g/clean"; mkdir -p deep/er; cd deep/er; _nzr_git_fast; eq "subfolder repo → tetap terdeteksi" "$TMP/g/clean" "$_NZR_G_ROOT"
cd "$TMP/g/clean"; git checkout -q --detach; _nzr_git_fast; rc=$?; eq "HEAD detached → bukan repo (sama seperti v2.0)" "" "$_NZR_G_BRANCH"; git checkout -q -
cd "$TMP/g/dirty";  _nzr_collect_git; eq "dirty → state" dirty "$_NZR_C_STATE"; eq "dirty → 3 perubahan" 3 "$_NZR_C_CHANGED"
cd "$TMP/g/clean";  _nzr_collect_git; eq "clean → state" clean "$_NZR_C_STATE"
cd "$TMP/g/plain";  _nzr_collect_git; eq "bukan repo → none" none "$_NZR_C_STATE"
# worktree: .git berupa file
cd "$TMP/g/clean" && git worktree add -q "$TMP/g/wt" -b wtbranch 2>/dev/null
cd "$TMP/g/wt" 2>/dev/null && { _nzr_git_fast; eq "git worktree (.git = file) terbaca" wtbranch "$_NZR_G_BRANCH"; }
cd "$TMP"
# worker menghasilkan rekaman yang benar
cd "$TMP/g/dirty"; _NZR_G_ROOT="$TMP/g/dirty"
rec=$(_nzr_worker 7 1 1); f=("${(@ps:\x1f:)${rec%$'\x1e'}}")
eq "worker: nomor urut" 7 "${f[1]}"; eq "worker: folder" "$TMP/g/dirty" "${f[2]}"; eq "worker: status git" dirty "${f[5]}"; eq "worker: jumlah perubahan" 3 "${f[6]}"
cd "$TMP"

# ═════════════════════════════════════════════════════════════════
section "11. fix & perintah nyata"
check "perintah theme dikenali sebagai meta" _nzr_is_meta "nzr stats"
check "fix dikenali sebagai meta" _nzr_is_meta "fix"
_nzr_is_meta "git status" && bad "git bukan meta" || ok "git bukan meta"
_NZR_REAL_CMD="" ; out=$(fix 2>&1); [[ "$out" == *"belum ada perintah"* ]] && ok "fix tanpa riwayat → pesan jelas" || bad "fix tanpa riwayat"
_NZR_REAL_CMD="ls"; _NZR_REAL_ST=0; out=$(fix 2>&1); [[ "$out" == *"sukses"* ]] && ok "fix saat sukses → tidak mengubah apa pun" || bad "fix saat sukses"
_NZR_REAL_CMD="sleep 5"; _NZR_REAL_ST=130; out=$(fix 2>&1); [[ "$out" == *"Ctrl+C"* ]] && ok "fix 130 → dijelaskan sebagai Ctrl+C" || bad "fix 130"
_NZR_REAL_CMD="false"; _NZR_REAL_ST=1; out=$(fix 2>&1); [[ "$out" == *"tidak ada perbaikan otomatis"* ]] && ok "fix exit 1 → jujur tidak ada perbaikan" || bad "fix exit 1"

# ═════════════════════════════════════════════════════════════════
section "12. nzr stats (data contoh)"
now=$EPOCHSECONDS; : > "$_NZR_STATS_FILE"
for i in {1..6}; do printf '%s\t%s\t%s\t%s\n' $(( now - 100*i )) 0 200  git  >> "$_NZR_STATS_FILE"; done
for i in {1..4}; do printf '%s\t%s\t%s\t%s\n' $(( now - 50*i ))  1 100  grep >> "$_NZR_STATS_FILE"; done
for i in {1..2}; do printf '%s\t%s\t%s\t%s\n' $(( now - 30*i ))  0 9000 make >> "$_NZR_STATS_FILE"; done
out=$(_nzr_cli_stats 7 2>&1)
[[ "$out" == *"12 perintah"* ]]            && ok "stats: total 12 perintah"          || bad "stats: total 12 perintah" "$out"
[[ "$out" == *"grep"*"4 dari 4 gagal"* ]]   && ok "stats: grep 4 dari 4 gagal"        || bad "stats: grep 4 dari 4 gagal"
[[ "$out" == *"make"*"9.0s"* ]]             && ok "stats: make paling lambat 9.0s"     || bad "stats: make paling lambat 9.0s"
out=$(_nzr_cli_stats clear 2>&1); [[ ! -e "$_NZR_STATS_FILE" ]] && ok "stats clear menghapus file" || bad "stats clear menghapus file"

# ═════════════════════════════════════════════════════════════════
section "13. Notifikasi"
mkdir -p "$TMP/bin"; printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/notif.log"\n' "$TMP" > "$TMP/bin/termux-notification"; chmod +x "$TMP/bin/termux-notification"
OLDPATH=$PATH; PATH="$TMP/bin:$PATH"; rehash
_NZR_LAST_CMD="make -j8"; _NZR_LAST_DUR=45; _nzr_notify 0; sleep 0.3
grep -q "make -j8" "$TMP/notif.log" 2>/dev/null && ok "perintah 45 detik → notifikasi terkirim" || bad "perintah 45 detik → notifikasi terkirim"
rm -f "$TMP/notif.log"; _NZR_LAST_DUR=5; _nzr_notify 0; sleep 0.2
[[ ! -e "$TMP/notif.log" ]] && ok "perintah 5 detik → tidak ada notifikasi" || bad "perintah 5 detik → tidak ada notifikasi"
_NZR_LAST_CMD="vim x.txt"; _NZR_LAST_DUR=99; _nzr_notify 0; sleep 0.2
[[ ! -e "$TMP/notif.log" ]] && ok "program interaktif (vim) diabaikan" || bad "program interaktif (vim) diabaikan"
PATH=$OLDPATH; rehash

# ═════════════════════════════════════════════════════════════════
section "15. nzr exit  ·  nzr  (NZR_OFF)"
out=$(NZR_OFF=1 zsh -fc "source '$ROOT/nzr.zsh'; print -r -- \"\${+functions[nzr]}|\${+functions[_nzr_precmd_status]}|\${+functions[_nzr_prompt_render]}|\$_NZR_LOADED\"" 2>&1)
eq "NZR_OFF=1: hanya perintah nzr yang tersedia (tanpa hook/prompt theme)" "1|0|0|1" "$out"
out=$(NZR_OFF=1 zsh -fc "source '$ROOT/nzr.zsh'; nzr foo" 2>&1); rc=$?
[[ "$out" == *"nonaktif"* && $rc -eq 1 ]] && ok "stub: argumen lain → pesan 'nonaktif', kode 1" || bad "stub: argumen lain" "$out (rc=$rc)"
out=$(NZR_OFF=1 zsh -fc "source '$ROOT/nzr.zsh'; _nzr_reexec() { print \"REEXEC \$1\" }; nzr" 2>&1)
[[ "$out" == *"REEXEC on"* ]] && ok "stub: 'nzr' tanpa argumen → memuat theme (on)" || bad "stub: 'nzr' tanpa argumen" "$out"
_nzr_reexec() { REEXEC_ARG="$1" }
nzr exit >/dev/null 2>&1; eq "nzr exit → _nzr_reexec off" off "${REEXEC_ARG:-}"
out=$(nzr 2>&1); [[ "$out" == *"nzr exit"* ]] && ok "theme aktif: 'nzr' tanpa argumen menampilkan bantuan (memuat 'nzr exit')" || bad "bantuan memuat nzr exit"
unfunction _nzr_reexec
grep -q '^_nzr_reexec()' "$ROOT/nzr.zsh" && ok "_nzr_reexec didefinisikan di nzr.zsh (tersedia sebelum theme dimuat)" || bad "_nzr_reexec di nzr.zsh"
grep -q 'fc -W' "$ROOT/nzr.zsh" && ok "riwayat sesi disimpan sebelum exec" || bad "riwayat disimpan sebelum exec"

# ═════════════════════════════════════════════════════════════════
section "16. Log autosuggestions: pindah keluar dari folder repo"
print -r -- "ls -la" > "$TMP/old.log"; chmod 644 "$TMP/old.log"
_nzr_migrate_log "$TMP/old.log" "$TMP/new.log"
[[ -f "$TMP/new.log" && ! -e "$TMP/old.log" ]] && ok "migrasi: file dipindah" || bad "migrasi: file dipindah"
eq "migrasi: isi tetap" "ls -la" "$(cat "$TMP/new.log")"
perm=$(stat -c %a "$TMP/new.log" 2>/dev/null || stat -f %Lp "$TMP/new.log"); eq "migrasi: izin jadi 600" 600 "$perm"
print -r -- "lama" > "$TMP/old2.log"; print -r -- "baru" > "$TMP/new2.log"
_nzr_migrate_log "$TMP/old2.log" "$TMP/new2.log"
eq "migrasi: tidak menimpa file baru" "baru" "$(cat "$TMP/new2.log")"
[[ -f "$TMP/old2.log" ]] && ok "migrasi: file lama dibiarkan bila baru sudah ada" || bad "migrasi: file lama dibiarkan"
_nzr_migrate_log "$TMP/tidak-ada.log" "$TMP/x.log"; eq "migrasi: tanpa file lama → aman" 0 "$?"
grep -q 'NZR_SUGGEST_LOG="${NZR_DATA_HOME}/autosuggestions.log"' "$ROOT/nzr.zsh" && ok "lokasi default log di folder data privat" || bad "lokasi default log"

# ═════════════════════════════════════════════════════════════════
section "17. Headline selalu rapi (tidak tertumpuk vertikal)"
if command -v figlet >/dev/null 2>&1; then
  for w in 100 62 50 40 30; do
    box=$(COLUMNS=$w TERM=xterm zsh "$ROOT/display.sh" 2>/dev/null | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g' | sed -n '/╔/,/╚/p')
    n=$(print -r -- "$box" | wc -l | tr -d ' ')
    (( n >= 5 && n <= 13 )) && ok "lebar $w kolom: kotak ${n} baris (tidak menumpuk)" || bad "lebar $w kolom: tinggi kotak $n" "$box"
  done
  box=$(COLUMNS=30 TERM=xterm zsh "$ROOT/display.sh" 2>/dev/null | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g')
  [[ "$box" == *"NZR-RD"* ]] && ok "lebar 30: jatuh ke teks biasa NZR-RD" || bad "lebar 30: teks biasa"
else
  print -P "  %F{yellow}•%f figlet tidak terpasang: bagian ini dilewati"
fi

# ═════════════════════════════════════════════════════════════════
section "18. Installer: shell otomatis, tanpa chmod, uninstall"
grep -q 'chmod +x "\$THEME_DIR"' "$ROOT/install.sh" && bad "installer tidak boleh chmod file repo (membuat git ✗N)" || ok "installer tidak lagi chmod file repo"
# current_login_shell dijalankan terpisah dengan HOME palsu
sed -n '/^current_login_shell()/,/^}/p' "$ROOT/install.sh" > "$TMP/fn.sh"
mkdir -p "$TMP/th/.termux"; ln -sf /data/data/com.termux/files/usr/bin/zsh "$TMP/th/.termux/shell"
eq "Termux: shell dari symlink ~/.termux/shell" zsh "$(OS=termux HOME="$TMP/th" SHELL=/bin/bash bash -c ". '$TMP/fn.sh'; current_login_shell")"
eq "non-Termux: shell dari \$SHELL" bash "$(OS=linux HOME="$TMP/th" SHELL=/bin/bash bash -c ". '$TMP/fn.sh'; current_login_shell")"
# uninstall melepas semua blok milik theme, baris lain tetap
mkdir -p "$TMP/uh"
printf 'export A=1\n\n# NZR zsh-switch\n[ -t 0 ] && exec zsh\nexport B=2\n' > "$TMP/uh/.bashrc"
printf 'export P=1\n\n# NZR zsh-switch\n[ -t 0 ] && exec zsh\nexport Q=2\n' > "$TMP/uh/.profile"
printf 'export Z=1\n\n# NZR Theme — x\nsource "/x/nzr.zsh"\nexport Y=2\n' > "$TMP/uh/.zshrc"
HOME="$TMP/uh" bash "$ROOT/install.sh" --uninstall >/dev/null 2>&1
if ! grep -q "NZR" "$TMP/uh/.bashrc" "$TMP/uh/.profile" "$TMP/uh/.zshrc" 2>/dev/null \
   && grep -q "export B=2" "$TMP/uh/.bashrc" && grep -q "export Q=2" "$TMP/uh/.profile" && grep -q "export Y=2" "$TMP/uh/.zshrc"; then
  ok "uninstall: .bashrc, .profile, .zshrc dibersihkan, baris milikmu utuh"
else bad "uninstall: pembersihan blok"; fi
ls "$TMP/uh/.bashrc.nzr-backup" "$TMP/uh/.profile.nzr-backup" "$TMP/uh/.zshrc.nzr-backup" >/dev/null 2>&1 && ok "uninstall: cadangan dibuat" || bad "uninstall: cadangan dibuat"

# ═════════════════════════════════════════════════════════════════
section "20. Installer: input aman, install_pkg, stdin tertutup"
for fn in ask sanitize_text _sed_inplace _set_config install_pkg; do sed -n "/^${fn}()/,/^}/p" "$ROOT/install.sh"; done > "$TMP/inst_fns.sh"
PRE='ok(){ :; }; info(){ :; }; warn(){ echo "WARN $*"; }; . "$1"'
# sanitize_text
out=$(bash -c "$PRE; sanitize_text 'x\"\$(touch /tmp/nzr_pwn)\"y;\`id\`|a\\\\b' 40" _ "$TMP/inst_fns.sh")
[[ "$out" != *['"$`\;|()']* ]] && ok "sanitize: kutip, \$, backtick, ;, |, \\, () dibuang" || bad "sanitize: karakter berbahaya dibuang" "$out"
out=$(bash -c "$PRE; sanitize_text 'Budi, Dr. A_b-c! ok?' 40" _ "$TMP/inst_fns.sh"); eq "sanitize: karakter aman dipertahankan" "Budi, Dr. A_b-c! ok?" "$out"
out=$(bash -c "$PRE; sanitize_text '$(printf 'a%.0s' {1..50})' 10" _ "$TMP/inst_fns.sh"); eq "sanitize: dipotong sesuai batas" 10 "${#out}"
# _set_config
cat > "$TMP/cfg_inst.sh" <<'CFG'
#!/bin/zsh
USER_NAME="D"          # Nama di welcome box
SHOW_LOGO=ON
CFG
cp "$TMP/cfg_inst.sh" "$TMP/cfg_before.sh"
bash -c "$PRE; CONFIG_FILE='$TMP/cfg_inst.sh'; _set_config USER_NAME 'x\"\$(touch $TMP/PWNED)\"y'" _ "$TMP/inst_fns.sh" >/dev/null 2>&1; rc=$?
(( rc != 0 )) && ok "_set_config menolak nilai tidak aman (kode ≠ 0)" || bad "_set_config menolak nilai tidak aman"
cmp -s "$TMP/cfg_inst.sh" "$TMP/cfg_before.sh" && ok "config.sh tidak berubah saat nilai ditolak" || bad "config.sh tidak berubah saat nilai ditolak"
bash -c "$PRE; CONFIG_FILE='$TMP/cfg_inst.sh'; _set_config USER_NAME 'a|b'" _ "$TMP/inst_fns.sh" >/dev/null 2>&1
cmp -s "$TMP/cfg_inst.sh" "$TMP/cfg_before.sh" && ok "karakter '|' (delimiter sed) ditolak, bukan merusak sed" || bad "karakter '|' ditolak"
bash -c "$PRE; CONFIG_FILE='$TMP/cfg_inst.sh'; _set_config USER_NAME 'Budi'" _ "$TMP/inst_fns.sh" >/dev/null 2>&1
grep -q '^USER_NAME="Budi" *# Nama di welcome box$' "$TMP/cfg_inst.sh" && ok "_set_config: nilai diganti, komentar dipertahankan" || bad "_set_config: komentar dipertahankan" "$(grep ^USER_NAME "$TMP/cfg_inst.sh")"
bash -c "$PRE; CONFIG_FILE='$TMP/cfg_inst.sh'; _set_config SHOW_LOGO OFF" _ "$TMP/inst_fns.sh" >/dev/null 2>&1
grep -q '^SHOW_LOGO="OFF"' "$TMP/cfg_inst.sh" && ok "_set_config: baris tanpa kutip (config lama) ikut diganti" || bad "_set_config: baris tanpa kutip"
bash -c "$PRE; CONFIG_FILE='$TMP/cfg_inst.sh'; _set_config OPSI_BARU ON" _ "$TMP/inst_fns.sh" >/dev/null 2>&1
grep -q '^OPSI_BARU="ON"$' "$TMP/cfg_inst.sh" && ok "_set_config: KEY yang belum ada ditambahkan" || bad "_set_config: KEY baru ditambahkan"
zsh -fc "source '$TMP/cfg_inst.sh'" >/dev/null 2>&1; [[ ! -e "$TMP/PWNED" ]] && ok "config.sh di-source: tidak ada perintah yang terjalankan" || bad "PERINTAH TERJALANKAN dari config.sh"
# install_pkg: kegagalan tidak boleh mematikan skrip di bawah set -e
mkdir -p "$TMP/bin2"; printf '#!/bin/sh\nexit 100\n' > "$TMP/bin2/apt-get"; chmod +x "$TMP/bin2/apt-get"
out=$(PATH="$TMP/bin2:$PATH" bash -c "set -euo pipefail; $PRE; PKG_MGR=apt; SUDO=''; install_pkg paketfiktif paketfiktif paketfiktif paketfiktif paketfiktif || echo GAGAL-DITANGANI; echo LANJUT" _ "$TMP/inst_fns.sh" 2>&1)
[[ "$out" == *"WARN paketfiktif gagal diinstall"* && "$out" == *"GAGAL-DITANGANI"* && "$out" == *"LANJUT"* ]] \
  && ok "install_pkg gagal: peringatan tampil dan skrip tetap lanjut (set -e)" || bad "install_pkg gagal: skrip tetap lanjut" "$out"
# stdin tertutup
out=$(bash -c "set -euo pipefail; . '$TMP/inst_fns.sh'; ask 'x: ' V </dev/null; echo \"LANJUT V=[\$V]\"" 2>&1)
[[ "$out" == *"LANJUT V=[]"* ]] && ok "ask: stdin tertutup → nilai default, tidak keluar diam-diam" || bad "ask: stdin tertutup" "$out"
grep -q "read -r -p" "$ROOT/install.sh" && [[ "$(grep -c 'read -r -p' "$ROOT/install.sh")" == 1 ]] && ok "hanya satu 'read -r -p' (di dalam ask)" || bad "semua input lewat ask"

# ═════════════════════════════════════════════════════════════════
section "21. Portabilitas dan sintaks"
for f in "$ROOT/nzr.zsh" "$ROOT"/lib/*.sh "$ROOT/config.sh" "$ROOT/display.sh" "$ROOT/tests/run.zsh"; do
  zsh -n "$f" 2>/dev/null && ok "zsh -n ${f#$ROOT/}" || bad "zsh -n ${f#$ROOT/}"
done
command -v bash >/dev/null && {
  bash -n "$ROOT/display.sh" 2>/dev/null && ok "bash -n display.sh (bisa dijalankan lewat bash)" || bad "bash -n display.sh"
  bash -n "$ROOT/install.sh" 2>/dev/null && ok "bash -n install.sh" || bad "bash -n install.sh"
}
mkdir -p "$TMP/fh"; printf 'a\n\n# NZR Theme — x\nsource "/x/nzr.zsh"\nJANGAN_HILANG=1\n' > "$TMP/fh/.zshrc"
HOME="$TMP/fh" bash "$ROOT/install.sh" --uninstall >/dev/null 2>&1
grep -q JANGAN_HILANG "$TMP/fh/.zshrc" && { ! grep -q "NZR Theme" "$TMP/fh/.zshrc"; } && ok "uninstall: hanya blok theme yang dihapus" || bad "uninstall: hanya blok theme yang dihapus"

# ═════════════════════════════════════════════════════════════════
print -P "\n%B──────────────────────────────────────%b"
if (( FAIL == 0 )); then
  print -P "%F{green}%B✓ SEMUA LULUS%b%f  ($PASS tes)"
  exit 0
else
  print -P "%F{red}%B✘ ${FAIL} GAGAL%b%f dari $(( PASS + FAIL )) tes:"
  for f in "${FAILED[@]}"; do print -P "   %F{red}•%f $f"; done
  exit 1
fi
