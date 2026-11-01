#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║               NZR THEME — install.sh (FINAL)                     ║
# ║   Universal: Android Termux · Debian/Ubuntu · Arch · macOS       ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── COLORS ───────────────────────────────────────────────────────
R='\033[0m'
BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'

# ─── LOGGER ───────────────────────────────────────────────────────
info() { printf "${BLUE}${BOLD}ℹ${R}  %s\n" "$1"; }
ok()   { printf "${GREEN}${BOLD}✓${R}  %s\n" "$1"; }
warn() { printf "${YELLOW}${BOLD}⚠${R}  %s\n" "$1"; }
err()  { printf "${RED}${BOLD}✗${R}  %s\n" "$1" >&2; }
die()  { err "$1"; exit 1; }
step() { printf "\n${CYAN}${BOLD}── %s${R}\n" "$1"; }

# ─── BANNER ───────────────────────────────────────────────────────
banner() {
  printf "\n${CYAN}${BOLD}"
  printf "╔══════════════════════════════════════════╗\n"
  printf "║       NZR THEME INSTALLER v3.0           ║\n"
  printf "║   Android · Linux · macOS · Universal    ║\n"
  printf "╚══════════════════════════════════════════╝\n"
  printf "${R}\n"
}

# ─── DETECT OS & PACKAGE MANAGER ─────────────────────────────────
detect_os() {
  OS="unknown"
  PKG_MGR="unknown"

  # Android Termux
  if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]]; then
    OS="termux"
    PKG_MGR="pkg"
    return
  fi

  # macOS
  if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macos"
    if command -v brew &>/dev/null; then
      PKG_MGR="brew"
    else
      PKG_MGR="none"
      warn "Homebrew tidak ditemukan. Install dari https://brew.sh"
    fi
    return
  fi

  # Linux — deteksi distro
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    case "${ID:-}" in
      ubuntu|debian|raspbian) OS="debian";  PKG_MGR="apt"    ;;
      arch|manjaro)           OS="arch";    PKG_MGR="pacman" ;;
      fedora)                 OS="fedora";  PKG_MGR="dnf"    ;;
      opensuse*)              OS="opensuse";PKG_MGR="zypper"  ;;
      alpine)                 OS="alpine";  PKG_MGR="apk"    ;;
      *)                      OS="linux";   PKG_MGR="unknown" ;;
    esac
  else
    OS="linux"
    PKG_MGR="unknown"
  fi
}

# ─── INSTALL PACKAGE ─────────────────────────────────────────────
# Usage: install_pkg <pkg-name> [termux-name] [brew-name] [apt-name] [pacman-name]
install_pkg() {
  local name="$1"
  local t_name="${2:-$1}"   # Termux
  local b_name="${3:-$1}"   # Homebrew
  local a_name="${4:-$1}"   # apt
  local p_name="${5:-$1}"   # pacman

  if command -v "$name" &>/dev/null; then
    ok "$name sudah terinstall"
    return 0
  fi

  info "Menginstall $name..."
  case "$PKG_MGR" in
    pkg)    pkg install -y "$t_name" 2>/dev/null ;;
    brew)   brew install "$b_name"   2>/dev/null ;;
    apt)    $SUDO apt-get install -y "$a_name" 2>/dev/null ;;
    pacman) $SUDO pacman -S --noconfirm "$p_name" 2>/dev/null ;;
    dnf)    $SUDO dnf install -y "$a_name" 2>/dev/null ;;
    zypper) $SUDO zypper install -y "$a_name" 2>/dev/null ;;
    apk)    $SUDO apk add --no-cache "$a_name" 2>/dev/null ;;
    none|unknown)
      warn "Tidak bisa auto-install $name. Install manual lalu ulangi."
      return 1
      ;;
  esac

  if command -v "$name" &>/dev/null; then
    ok "$name berhasil diinstall"
  else
    warn "$name gagal diinstall — beberapa fitur mungkin tidak muncul"
  fi
}

# ─── PATHS ────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$REPO_DIR"
ZSHRC="$HOME/.zshrc"
CONFIG_FILE="$THEME_DIR/config.sh"

# ─── VALIDASI ─────────────────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] || die "config.sh tidak ditemukan di $THEME_DIR"

# ─── HAPUS BLOK THEME DARI .zshrc (portable GNU/BSD sed) ──────────
# Hanya dua baris milik theme (penanda + baris source), bukan sampai baris kosong.
remove_zshrc_entry() {
  if sed --version &>/dev/null 2>&1; then
    sed -i '/# NZR Theme/{N;d;}' "$ZSHRC"
  else
    sed -i '' '/# NZR Theme/{N;d;}' "$ZSHRC"
  fi
}

# ─── JANGAN JALANKAN DENGAN sudo ──────────────────────────────────
# `sudo bash install.sh` membuat $HOME menunjuk ke root, sehingga .zshrc dan file
# theme salah tempat. Installer ini memanggil sudo sendiri hanya saat memasang paket.
SUDO=""
if [[ "$EUID" -eq 0 ]]; then
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    warn "Terdeteksi 'sudo bash install.sh' → dialihkan ke user '$SUDO_USER' agar theme masuk ke HOME yang benar."
    exec sudo -u "$SUDO_USER" -H bash "${BASH_SOURCE[0]}" "$@"
  fi
  warn "Berjalan sebagai root: theme akan terpasang untuk user root."
elif command -v sudo &>/dev/null; then
  SUDO="sudo"
fi

# ─── UNINSTALL ────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  if [[ -f "$ZSHRC" ]] && grep -q "NZR Theme" "$ZSHRC"; then
    cp "$ZSHRC" "$ZSHRC.nzr-backup"
    remove_zshrc_entry
    ok "Theme dilepas dari $ZSHRC  (cadangan: $ZSHRC.nzr-backup)"
    info "File theme di $THEME_DIR tidak dihapus. Hapus manual bila perlu. Data statistik: ~/.local/share/nzr"
  else
    info "Tidak ada entri NZR Theme di $ZSHRC"
  fi
  exit 0
fi

# ─── MULAI ────────────────────────────────────────────────────────
banner
detect_os
info "Terdeteksi: OS=$OS | Package manager=$PKG_MGR"

# ─── CEK & INSTALL DEPENDENCIES ──────────────────────────────────
step "Mengecek dependencies"

# zsh — wajib
install_pkg "zsh" "zsh" "zsh" "zsh" "zsh"

# git — wajib untuk clone plugin
install_pkg "git" "git" "git" "git" "git"

# figlet — opsional (headline)
install_pkg "figlet" "figlet" "figlet" "figlet" "figlet"

# lolcat — opsional (rainbow color)
if ! command -v lolcat &>/dev/null; then
  warn "lolcat tidak ada — HEADLINE_COLOR=lolcat akan fallback ke cyan"
  warn "Install manual: gem install lolcat  ATAU  pkg install lolcat"
fi

# notifikasi perintah lama — opsional (hanya relevan di Termux)
if [[ "$OS" == "termux" ]] && ! command -v termux-notification &>/dev/null; then
  warn "Notifikasi perintah lama butuh termux-api + app Termux:API"
  warn "Install: pkg install termux-api (lalu pasang app Termux:API dari F-Droid)"
fi

ok "Dependencies selesai"

# ─── PERMISSIONS ──────────────────────────────────────────────────
step "Mengatur permissions"
chmod +x "$THEME_DIR"/*.sh 2>/dev/null || true
chmod +x "$THEME_DIR"/lib/*.sh 2>/dev/null || true
ok "Permissions diatur"

# ─── PERSONALISASI INTERAKTIF ─────────────────────────────────────
step "Personalisasi"
printf "\n"

# Headline text
read -r -p "  Headline text [NZR-RD]: " headline
headline="${headline:-NZR-RD}"

# Nama user
read -r -p "  Nama kamu (untuk welcome box): " username
# Jika kosong, pakai $USER atau fallback
username="${username:-${USER:-user}}"

# Welcome message
read -r -p "  Pesan selamat datang [Selamat datang, ]: " welcome_msg
welcome_msg="${welcome_msg:-Selamat datang, }"

# Warna headline
printf "\n  Pilih warna headline:\n"
printf "  1) cyan (default)  2) blue  3) green\n"
printf "  4) yellow          5) magenta  6) lolcat (rainbow)\n"
read -r -p "  Pilihan [1]: " color_choice
case "${color_choice:-1}" in
  2) hl_color="blue"    ;;
  3) hl_color="green"   ;;
  4) hl_color="yellow"  ;;
  5) hl_color="magenta" ;;
  6) hl_color="lolcat"  ;;
  *) hl_color="cyan"    ;;
esac

# Fitur on/off
printf "\n"
read -r -p "  Aktifkan Autosuggestions? [Y/n]: " autosug
[[ "${autosug:-y}" =~ ^[Nn]$ ]] && AUTOSUG="OFF" || AUTOSUG="ON"

read -r -p "  Aktifkan Syntax Highlighting? [Y/n]: " syntax
[[ "${syntax:-y}" =~ ^[Nn]$ ]] && SYNTAX="OFF" || SYNTAX="ON"

read -r -p "  Tampilkan Logo? [Y/n]: " show_logo
[[ "${show_logo:-y}" =~ ^[Nn]$ ]] && LOGO="OFF" || LOGO="ON"

read -r -p "  Tampilkan Headline? [Y/n]: " show_hl
[[ "${show_hl:-y}" =~ ^[Nn]$ ]] && HEADLINE="OFF" || HEADLINE="ON"

read -r -p "  Tampilkan System Info? [Y/n]: " show_sys
[[ "${show_sys:-y}" =~ ^[Nn]$ ]] && SYSINFO="OFF" || SYSINFO="ON"

read -r -p "  Tampilkan baris error di atas prompt (prompt 4 baris)? [Y/n]: " show_err
[[ "${show_err:-y}" =~ ^[Nn]$ ]] && ERRLINE="OFF" || ERRLINE="ON"

read -r -p "  Notifikasi saat perintah lama (>= 30 detik) selesai? [Y/n]: " notif
[[ "${notif:-y}" =~ ^[Nn]$ ]] && NOTIF="OFF" || NOTIF="ON"

# ─── TULIS CONFIG ────────────────────────────────────────────────
step "Menyimpan konfigurasi"

# Fungsi update key di config.sh secara portable
# (sed -i berbeda antara GNU dan BSD/macOS)
_sed_inplace() {
  local pattern="$1" file="$2"
  if sed --version &>/dev/null 2>&1; then
    # GNU sed (Linux, Termux)
    sed -i "$pattern" "$file"
  else
    # BSD sed (macOS)
    sed -i '' "$pattern" "$file"
  fi
}

_set_config() {
  local key="$1" val="$2"
  # Escape karakter khusus untuk sed
  local escaped_val
  escaped_val=$(printf '%s' "$val" | sed 's/[\/&]/\\&/g')
  _sed_inplace "s|^${key}=.*|${key}=\"${escaped_val}\"|" "$CONFIG_FILE"
}

_set_config "HEADLINE_TEXT"      "$headline"
_set_config "USER_NAME"          "$username"
_set_config "WELCOME_MSG"        "$welcome_msg"
_set_config "HEADLINE_COLOR"     "$hl_color"
_set_config "AUTOSUGGESTIONS"    "$AUTOSUG"
_set_config "SYNTAX_HIGHLIGHTING" "$SYNTAX"
_set_config "SHOW_LOGO"          "$LOGO"
_set_config "SHOW_HEADLINE"      "$HEADLINE"
_set_config "SHOW_SYSTEM_INFO"   "$SYSINFO"
_set_config "SHOW_ERROR_LINE"     "$ERRLINE"
_set_config "NOTIFY_LONG_CMD"     "$NOTIF"

ok "Config tersimpan di $CONFIG_FILE"

# ─── AKTIFKAN DI .zshrc ───────────────────────────────────────────
step "Mengaktifkan theme di .zshrc"

# Buat .zshrc jika belum ada
touch "$ZSHRC"

# Hapus entri lama jika ada
if grep -q "NZR Theme" "$ZSHRC" 2>/dev/null; then
  info "Entri lama ditemukan, memperbarui..."
  remove_zshrc_entry
fi

# Tambah entri baru
cat >> "$ZSHRC" <<EOF

# NZR Theme — https://github.com/nzr-rd/terminal-nzr-theme
source "$THEME_DIR/nzr.zsh"
EOF

ok "Theme diaktifkan di $ZSHRC"

# ─── INSTALL ZSH PLUGINS (OPSIONAL) ──────────────────────────────
step "Plugins Zsh"
ZSH_PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$ZSH_PLUGIN_DIR"

if [[ "$AUTOSUG" == "ON" ]]; then
  if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]]; then
    info "Cloning zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_PLUGIN_DIR/zsh-autosuggestions" 2>/dev/null \
      && ok "zsh-autosuggestions terinstall" \
      || warn "Gagal clone zsh-autosuggestions — cek koneksi internet"
  else
    ok "zsh-autosuggestions sudah ada"
  fi
fi

if [[ "$SYNTAX" == "ON" ]]; then
  if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]]; then
    info "Cloning zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" 2>/dev/null \
      && ok "zsh-syntax-highlighting terinstall" \
      || warn "Gagal clone zsh-syntax-highlighting — cek koneksi internet"
  else
    ok "zsh-syntax-highlighting sudah ada"
  fi
fi

# ─── SELESAI ─────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}"
printf "╔══════════════════════════════════════════╗\n"
printf "║        INSTALASI SELESAI! 🎉             ║\n"
printf "╚══════════════════════════════════════════╝\n"
printf "${R}\n"

printf "  ${CYAN}Aktifkan sekarang:${R}  ${YELLOW}exec zsh${R}\n"
printf "  ${CYAN}Edit config:${R}        ${YELLOW}nano $CONFIG_FILE${R}\n"
printf "  ${CYAN}Jalankan manual:${R}    ${YELLOW}zsh $THEME_DIR/display.sh${R}\n"
printf "  ${CYAN}Semua perintah:${R}     ${YELLOW}nzr help${R}   ${CYAN}Cek kondisi:${R} ${YELLOW}nzr doctor${R}\n"
printf "\n"
