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
