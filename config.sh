#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                    NZR THEME CONFIGURATION                         ║
# ║         Ubah ON/OFF di bawah ini untuk aktifkan fitur              ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── HEADLINE & USER INFO ─────────────────────────────────────────
HEADLINE_TEXT="NZR-TERMUX"      # Teks untuk figlet headline
HEADLINE_COLOR="lolcat"         # lolcat, rainbow, cyan, blue, green, yellow, red, magenta
WELCOME_MSG="Selamat datang, "  # Pesan sebelum nama user
USER_NAME="$USER"               # Nama user (auto), bisa ganti manual

# ─── FITUR LANJUTAN (ON/OFF) ──────────────────────────────────────
AUTOSUGGESTIONS="OFF"           # Zsh Autosuggestions (ON/OFF)
SYNTAX_HIGHLIGHTING="OFF"       # Syntax Highlighting (ON/OFF)
BATGIT_INTEGRATION="OFF"        # Bat + Git Integration (ON/OFF)

# ─── TAMPILAN ─────────────────────────────────────────────────────
SHOW_LOGO="ON"                  # Tampilkan logo (ON/OFF)
SHOW_HEADLINE="ON"              # Tampilkan headline figlet (ON/OFF)
SHOW_USER_INFO="ON"             # Tampilkan info user/welcome (ON/OFF)
SHOW_SYSTEM_INFO="ON"           # Tampilkan OS, Host, dll (ON/OFF)
