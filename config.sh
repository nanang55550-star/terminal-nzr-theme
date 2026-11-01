#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                  NZR THEME — config.sh (FINAL)                   ║
# ║          Edit bagian ini untuk kustomisasi tampilan               ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── IDENTITAS USER ───────────────────────────────────────────────
HEADLINE_TEXT="NZR-RD"           # Teks besar di headline (figlet)
USER_NAME="D"               # Nama di welcome box
WELCOME_MSG="Selamat datang, "   # Pesan sebelum nama

# ─── WARNA HEADLINE ───────────────────────────────────────────────
# Pilihan: cyan | blue | green | yellow | magenta | white | lolcat
# lolcat = rainbow (butuh: pkg install lolcat)
HEADLINE_COLOR="cyan"

# ─── TAMPILAN (ON/OFF) ────────────────────────────────────────────
SHOW_LOGO="ON"          # Logo ASCII NZR di atas
SHOW_HEADLINE="ON"      # Teks besar figlet
SHOW_USER_INFO="ON"     # Welcome box dengan nama user
SHOW_SYSTEM_INFO="ON"   # Info OS, RAM, Disk, dll di kanan

# ─── FITUR ZSH ────────────────────────────────────────────────────
AUTOSUGGESTIONS="ON"        # Saran perintah (zsh-autosuggestions)
SYNTAX_HIGHLIGHTING="ON"    # Warna syntax (zsh-syntax-highlighting)
BATGIT_INTEGRATION="OFF"    # Integrasi bat + git diff (butuh: bat, git)

# ─── BARIS ERROR (baris paling atas dari prompt 4 baris) ──────────
# Prompt sekarang 4 baris:
#   1. error line   ✓ ok · ✘ 127 perintah tidak ada · durasi
#   2. status       user@host · RAM · DISK
#   3. dir + git
#   4. input        ➜
SHOW_ERROR_LINE="ON"        # ON = 4 baris | OFF = 3 baris (error ringkas di kanan)
ERROR_LINE_MODE="always"    # always = selalu tampil | error = hanya saat perintah gagal
ERROR_SHOW_CMD="ON"         # tampilkan perintah yang gagal di baris error
SHOW_CMD_DURATION="ON"      # tampilkan lama eksekusi perintah
CMD_DURATION_MIN="1"        # tampil jika durasi >= N detik (boleh desimal: 0.5)
ERROR_SUGGEST="ON"          # saran "mungkin: git" saat salah ketik / chmod +x saat 126
ERROR_SHOW_JOBS="ON"        # tampilkan jumlah job background (jobs N)
ERROR_SHOW_TIME="OFF"       # tampilkan jam selesai perintah

# ─── NOTIFIKASI PERINTAH LAMA ─────────────────────────────────────
# Termux: pkg install termux-api + app Termux:API. Linux: notify-send. macOS: bawaan.
NOTIFY_LONG_CMD="ON"        # kirim notifikasi saat perintah lama selesai
NOTIFY_MIN_SECONDS="30"     # hanya untuk perintah yang berjalan >= N detik
NOTIFY_BELL="OFF"           # ON = bunyi bell jika tidak ada notifier lain

# ─── LAIN-LAIN ────────────────────────────────────────────────────
SET_TITLE="ON"              # judul tab/jendela terminal ikut folder & perintah
HIST_SCRUB="ON"             # perintah berisi token/password tidak ditulis ke HISTFILE
EXTRA_TOOLS="ON"            # mkcd, up, bak, extract
AUTO_GREETING="ON"          # sapaan pagi/siang/sore/malam (pesan custom tetap dipakai)
SHOW_TIPS="ON"              # tip acak di bawah tampilan startup
# Ubah tanpa edit file:  nzr set NAMA_OPSI NILAI   ·   lihat semua: nzr config

# ─── TEMA & MESIN PROMPT (v3.0) ───────────────────────────────────
NZR_THEME="default"         # default | nord | dracula | gruvbox | tokyonight | catppuccin  (nzr theme)
NZR_COLOR_DEPTH="auto"      # auto | truecolor | 256
ASYNC_PROMPT="ON"           # ON = prompt langsung muncul, git/RAM/DISK dihitung di latar belakang
STATS_LOG="ON"              # catat NAMA perintah (tanpa argumen) lokal untuk: nzr stats
