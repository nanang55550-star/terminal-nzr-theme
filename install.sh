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

# ─── INPUT & KONFIGURASI AMAN ─────────────────────────────────────
# Baca input. Stdin tertutup / EOF (mis. `curl ... | bash`) = pakai nilai default,
# bukan keluar diam-diam karena `set -e`.
ask() {   # <prompt> <nama-variabel>
  local __a=""
  read -r -p "$1" __a || __a=""
  printf -v "$2" '%s' "$__a"
}

# config.sh DI-SOURCE oleh shell, jadi teks dari pengguna tidak boleh membawa kutip,
# $, `, \, ;, | dan sejenisnya. Hanya huruf/angka (termasuk Unicode), spasi, dan
# , . _ ! ? : @ + -   (aturan yang sama dengan `nzr set`).
sanitize_text() {   # <teks> [maks-panjang]  → mencetak teks bersih
  local v="${1//[^[:alnum:] ,._!?:@+-]/}"
  printf '%s' "${v:0:${2:-40}}"
}

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

# Tulis KEY="nilai" ke config.sh. Nilai yang tidak aman DITOLAK (bukan di-escape),
# komentar di belakang nilai dipertahankan, dan KEY yang belum ada ditambahkan.
_set_config() {   # <KEY> <nilai>
  local key="$1" val="$2" re='^[[:alnum:] ,._!?:@+-]*$'
  if ! [[ "$val" =~ $re ]]; then
    warn "Nilai $key mengandung karakter tidak aman, dilewati"; return 1
  fi
  if grep -q "^${key}=\"" "$CONFIG_FILE"; then
    _sed_inplace "s|^${key}=\"[^\"]*\"|${key}=\"${val}\"|" "$CONFIG_FILE"
  elif grep -q "^${key}=" "$CONFIG_FILE"; then
    _sed_inplace "s|^${key}=[^ #]*|${key}=\"${val}\"|" "$CONFIG_FILE"
  else
    printf '%s="%s"\n' "$key" "$val" >> "$CONFIG_FILE"
  fi
}
step() { printf "\n${CYAN}${BOLD}── %s${R}\n" "$1"; }

# ─── BANNER ───────────────────────────────────────────────────────
banner() {
  printf "\n${CYAN}${BOLD}"
  printf "╔══════════════════════════════════════════╗\n"
  printf "║       NZR THEME INSTALLER v3.1           ║\n"
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
  local out="" rc=0
  # `|| rc=$?` agar kegagalan tidak mematikan skrip (set -e) sebelum dicek di bawah
  case "$PKG_MGR" in
    pkg)    out=$(pkg install -y "$t_name" 2>&1)                 || rc=$? ;;
    brew)   out=$(brew install "$b_name" 2>&1)                   || rc=$? ;;
    apt)    out=$($SUDO apt-get install -y "$a_name" 2>&1)       || rc=$? ;;
    pacman) out=$($SUDO pacman -S --noconfirm "$p_name" 2>&1)    || rc=$? ;;
    dnf)    out=$($SUDO dnf install -y "$a_name" 2>&1)           || rc=$? ;;
    zypper) out=$($SUDO zypper install -y "$a_name" 2>&1)        || rc=$? ;;
    apk)    out=$($SUDO apk add --no-cache "$a_name" 2>&1)       || rc=$? ;;
    none|unknown)
      warn "Tidak bisa auto-install $name. Install manual lalu ulangi."
      return 1
      ;;
  esac

  if command -v "$name" &>/dev/null; then
    ok "$name berhasil diinstall"
    return 0
  fi
  warn "$name gagal diinstall (kode $rc)${out:+: $(printf '%s' "$out" | tail -n 1)}"
  return 1
}

# ─── PATHS ────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$REPO_DIR"
ZSHRC="$HOME/.zshrc"
CONFIG_FILE="$THEME_DIR/config.sh"

# ─── VALIDASI ─────────────────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] || die "config.sh tidak ditemukan di $THEME_DIR"

# ─── HAPUS BLOK BERTANDA (portable GNU/BSD sed) ───────────────────
# Hanya DUA baris milik theme (penanda + baris sesudahnya), bukan sampai baris kosong.
remove_marked_block() {   # <file> <penanda>
  if sed --version &>/dev/null 2>&1; then
    sed -i "/$2/{N;d;}" "$1"
  else
    sed -i '' "/$2/{N;d;}" "$1"
  fi
}
remove_zshrc_entry() { remove_marked_block "$ZSHRC" "# NZR Theme"; }

# ─── SHELL OTOMATIS ───────────────────────────────────────────────
# Tanpa ini, terminal yang membuka bash/ash tidak pernah membaca ~/.zshrc, jadi theme
# baru muncul setelah mengetik `exec zsh`.
SHELL_MARK="# NZR zsh-switch"
SHELL_LINE='[ -t 0 ] && [ -z "$ZSH_VERSION" ] && [ -z "$NZR_NO_ZSH" ] && command -v zsh >/dev/null 2>&1 && exec zsh'

# Shell yang benar-benar dipakai terminal ini.
# Termux memilih shell lewat symlink ~/.termux/shell, bukan lewat $SHELL.
current_login_shell() {
  local t
  if [[ "${OS:-}" == "termux" && ( -L "$HOME/.termux/shell" || -e "$HOME/.termux/shell" ) ]]; then
    t="$(readlink "$HOME/.termux/shell" 2>/dev/null || true)"
    [[ -n "$t" ]] && { basename "$t"; return; }
  fi
  basename "${SHELL:-sh}"
}

remove_shell_snippets() {
  local f removed=0
  for f in "$HOME/.bashrc" "$HOME/.profile"; do
    if [[ -f "$f" ]] && grep -qF "$SHELL_MARK" "$f"; then
      cp "$f" "$f.nzr-backup"
      remove_marked_block "$f" "$SHELL_MARK"
      ok "Snippet shell otomatis dilepas dari $f  (cadangan: $f.nzr-backup)"
      removed=1
    fi
  done
  return 0
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
    remove_shell_snippets
    info "File theme di $THEME_DIR tidak dihapus. Hapus manual bila perlu. Data statistik: ~/.local/share/nzr"
  else
    info "Tidak ada entri NZR Theme di $ZSHRC"
    remove_shell_snippets
  fi
  [[ "${OS:-}" == "termux" ]] || true
  info "Catatan: shell default (mis. chsh di Termux) tidak diubah kembali. Kembalikan dengan: chsh -s bash"
  exit 0
fi

# ─── MULAI ────────────────────────────────────────────────────────
banner
detect_os
info "Terdeteksi: OS=$OS | Package manager=$PKG_MGR"

# ─── CEK & INSTALL DEPENDENCIES ──────────────────────────────────
step "Mengecek dependencies"

# zsh — wajib
install_pkg "zsh" "zsh" "zsh" "zsh" "zsh" || die "zsh wajib dan gagal dipasang. Pasang manual lalu jalankan ulang installer."

# git — wajib untuk clone plugin
install_pkg "git" "git" "git" "git" "git" || die "git wajib (untuk memasang plugin) dan gagal dipasang. Pasang manual lalu jalankan ulang."

# figlet — opsional (headline)
install_pkg "figlet" "figlet" "figlet" "figlet" "figlet" || warn "figlet dilewati: headline tampil sebagai teks biasa"

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

# ─── PERSONALISASI INTERAKTIF ─────────────────────────────────────
step "Personalisasi"
printf "\n"

# Headline text
ask "  Headline text [NZR-RD]: " headline
headline="$(sanitize_text "$headline" 24)"; headline="${headline:-NZR-RD}"

# Nama user
ask "  Nama kamu (untuk welcome box): " username
# Jika kosong, pakai $USER atau fallback
username="$(sanitize_text "${username:-${USER:-user}}" 24)"; username="${username:-user}"

# Welcome message
ask "  Pesan selamat datang [Selamat datang, ]: " welcome_msg
welcome_msg="$(sanitize_text "${welcome_msg:-Selamat datang,}" 40)"
welcome_msg="${welcome_msg:-Selamat datang,}"
while [[ "$welcome_msg" == *" " ]]; do welcome_msg="${welcome_msg% }"; done
welcome_msg+=" "                       # tepat satu spasi: dipakai sebagai awalan sebelum nama

# Warna headline
printf "\n  Pilih warna headline:\n"
printf "  1) cyan (default)  2) blue  3) green\n"
printf "  4) yellow          5) magenta  6) lolcat (rainbow)\n"
ask "  Pilihan [1]: " color_choice
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
ask "  Aktifkan Autosuggestions? [Y/n]: " autosug
[[ "${autosug:-y}" =~ ^[Nn]$ ]] && AUTOSUG="OFF" || AUTOSUG="ON"

ask "  Aktifkan Syntax Highlighting? [Y/n]: " syntax
[[ "${syntax:-y}" =~ ^[Nn]$ ]] && SYNTAX="OFF" || SYNTAX="ON"

ask "  Tampilkan Logo? [Y/n]: " show_logo
[[ "${show_logo:-y}" =~ ^[Nn]$ ]] && LOGO="OFF" || LOGO="ON"

ask "  Tampilkan Headline? [Y/n]: " show_hl
[[ "${show_hl:-y}" =~ ^[Nn]$ ]] && HEADLINE="OFF" || HEADLINE="ON"

ask "  Tampilkan System Info? [Y/n]: " show_sys
[[ "${show_sys:-y}" =~ ^[Nn]$ ]] && SYSINFO="OFF" || SYSINFO="ON"

ask "  Tampilkan baris error di atas prompt (prompt 4 baris)? [Y/n]: " show_err
[[ "${show_err:-y}" =~ ^[Nn]$ ]] && ERRLINE="OFF" || ERRLINE="ON"

ask "  Notifikasi saat perintah lama (>= 30 detik) selesai? [Y/n]: " notif
[[ "${notif:-y}" =~ ^[Nn]$ ]] && NOTIF="OFF" || NOTIF="ON"

# ─── TULIS CONFIG ────────────────────────────────────────────────
step "Menyimpan konfigurasi"

# Fungsi update key di config.sh secara portable
# (sed -i berbeda antara GNU dan BSD/macOS)


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

# NZR Theme — https://github.com/nanang55550-star/terminal-nzr-theme
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

# ─── SHELL OTOMATIS ──────────────────────────────────────────────
step "Shell otomatis"
SHELL_RESULT=""
cur_shell="$(current_login_shell)"
if [[ "$cur_shell" == "zsh" ]]; then
  ok "zsh sudah menjadi shell default, tidak ada yang perlu diubah"
  SHELL_RESULT="sudah"
else
  info "Shell terminal ini: $cur_shell (bukan zsh, jadi theme belum termuat otomatis)"
  ask "  Jadikan zsh otomatis saat terminal dibuka? [Y/n]: " auto_zsh
  if [[ "${auto_zsh:-y}" =~ ^[Nn]$ ]]; then
    info "Dilewati. Muat manual dengan: exec zsh"
  elif [[ "${OS:-}" == "termux" ]] && command -v chsh &>/dev/null; then
    if chsh -s zsh >/dev/null 2>&1; then
      ok "chsh -s zsh berhasil (cara resmi Termux)"; SHELL_RESULT="chsh"
    else
      warn "chsh gagal. Jalankan manual: chsh -s zsh"
    fi
  else
    case "$cur_shell" in
      bash)              shell_target="$HOME/.bashrc" ;;
      sh|ash|dash|ksh)   shell_target="$HOME/.profile" ;;
      *)                 shell_target="" ;;
    esac
    if [[ -z "$shell_target" ]]; then
      warn "Shell '$cur_shell' belum didukung otomatis. Muat manual dengan: exec zsh"
    elif grep -qF "$SHELL_MARK" "$shell_target" 2>/dev/null; then
      ok "Sudah terpasang di $shell_target"; SHELL_RESULT="snippet"
    else
      backup_note=""
      if [[ -f "$shell_target" ]]; then
        cp "$shell_target" "$shell_target.nzr-backup"; backup_note="  (cadangan: $shell_target.nzr-backup)"
      fi
      printf '\n%s\n%s\n' "$SHELL_MARK" "$SHELL_LINE" >> "$shell_target"
      ok "Ditambahkan ke $shell_target$backup_note"
      info "Lewati sementara bila perlu: NZR_NO_ZSH=1 $cur_shell"
      SHELL_RESULT="snippet"
    fi
  fi
fi

# ─── SELESAI ─────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}"
printf "╔══════════════════════════════════════════╗\n"
printf "║        INSTALASI SELESAI! 🎉             ║\n"
printf "╚══════════════════════════════════════════╝\n"
printf "${R}\n"

if [[ "$SHELL_RESULT" == "chsh" ]]; then
  printf "  ${CYAN}Aktifkan:${R}           ${YELLOW}tutup lalu buka ulang Termux${R}  ${CYAN}(atau: exec zsh)${R}\n"
elif [[ "$SHELL_RESULT" == "snippet" ]]; then
  printf "  ${CYAN}Aktifkan:${R}           ${YELLOW}buka terminal baru${R}  ${CYAN}(atau: exec zsh)${R}\n"
else
  printf "  ${CYAN}Aktifkan sekarang:${R}  ${YELLOW}exec zsh${R}\n"
fi
printf "  ${CYAN}Keluar/masuk theme:${R} ${YELLOW}nzr exit${R}  /  ${YELLOW}nzr${R}\n"
printf "  ${CYAN}Edit config:${R}        ${YELLOW}nano $CONFIG_FILE${R}\n"
printf "  ${CYAN}Jalankan manual:${R}    ${YELLOW}zsh $THEME_DIR/display.sh${R}\n"
printf "  ${CYAN}Semua perintah:${R}     ${YELLOW}nzr help${R}   ${CYAN}Cek kondisi:${R} ${YELLOW}nzr doctor${R}\n"
printf "\n"
