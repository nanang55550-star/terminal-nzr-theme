#!/bin/bash
# NZR THEME - AUTO INSTALLER

set -e

# ─── COLORS (pakai printf agar jalan di Termux) ──────────────────
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RESET='\033[0m'

# ─── PATHS ───
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="$REPO_DIR"
ZSHRC="$HOME/.zshrc"

# ─── FUNCTIONS ───────────────────────────────────────────────────
info() { printf "${BLUE}ℹ ${RESET}%s\n" "$1"; }
ok()   { printf "${GREEN}✓ ${RESET}%s\n" "$1"; }
warn() { printf "${YELLOW}⚠ ${RESET}%s\n" "$1"; }
err()  { printf "${RED}✗ ${RESET}%s\n" "$1"; }

banner() {
    printf "\n${CYAN}"
    printf "╔══════════════════════════════════════╗\n"
    printf "║     NZR THEME INSTALLER              ║\n"
    printf "║     Terminal Customization           ║\n"
    printf "╚══════════════════════════════════════╝\n"
    printf "${RESET}\n"
}

# ─── MAIN ────────────────────────────────────────────────────────
banner

# Cek dependencies
info "Checking dependencies..."
for cmd in git zsh figlet; do
    if ! command -v "$cmd" &>/dev/null; then
        warn "$cmd not found, installing..."
        pkg install "$cmd" -y
    fi
done
ok "Dependencies ready"


# Install theme files
info "Installing theme..."
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR/lib"

# Buat config default kalau belum ada
if [ ! -f "$THEME_DIR/config.sh" ]; then
    cat > "$THEME_DIR/config.sh" <<'EOF'
#!/bin/zsh
HEADLINE_TEXT="NZR-TERMUX"
HEADLINE_COLOR="cyan"
WELCOME_MSG="Selamat datang, "
USER_NAME=""
AUTOSUGGESTIONS="OFF"
SYNTAX_HIGHLIGHTING="OFF"
BATGIT_INTEGRATION="OFF"
SHOW_LOGO="ON"
SHOW_HEADLINE="ON"
SHOW_USER_INFO="ON"
EOF
fi

# Konfigurasi interaktif
printf "\n${CYAN}─── Personalization ───${RESET}\n\n"

read -r -p "Headline text [NZR-TERMUX]: " headline
headline=${headline:-NZR-TERMUX}

read -r -p "Your name: " username

read -r -p "Enable Autosuggestions? [y/N]: " autosug
[[ "$autosug" =~ ^[Yy]$ ]] && AUTOSUG="ON" || AUTOSUG="OFF"

read -r -p "Enable Syntax Highlighting? [y/N]: " syntax
[[ "$syntax" =~ ^[Yy]$ ]] && SYNTAX="ON" || SYNTAX="OFF"

# Update config
sed -i "s/HEADLINE_TEXT=.*/HEADLINE_TEXT=\"$headline\"/" "$THEME_DIR/config.sh"
sed -i "s/USER_NAME=.*/USER_NAME=\"$username\"/" "$THEME_DIR/config.sh"
sed -i "s/AUTOSUGGESTIONS=.*/AUTOSUGGESTIONS=\"$AUTOSUG\"/" "$THEME_DIR/config.sh"
sed -i "s/SYNTAX_HIGHLIGHTING=.*/SYNTAX_HIGHLIGHTING=\"$SYNTAX\"/" "$THEME_DIR/config.sh"

ok "Config saved"

# Aktifkan di .zshrc
info "Activating theme..."
if grep -q "nzr-theme" "$ZSHRC" 2>/dev/null; then
    sed -i '/nzr-theme/d' "$ZSHRC"
fi

echo "" >> "$ZSHRC"
echo "# NZR Theme" >> "$ZSHRC"
echo "source $THEME_DIR/nzr.zsh" >> "$ZSHRC"

ok "Theme activated"

# Optional plugins
printf "\n"
read -r -p "Install Zsh Autosuggestions? [y/N]: " a
if [[ "$a" =~ ^[Yy]$ ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions 2>/dev/null && ok "Autosuggestions installed" || warn "Failed/Already exists"
fi

read -r -p "Install Zsh Syntax Highlighting? [y/N]: " s
if [[ "$s" =~ ^[Yy]$ ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting 2>/dev/null && ok "Syntax Highlighting installed" || warn "Failed/Already exists"
fi

# Finish
printf "\n${GREEN}"
printf "╔══════════════════════════════════════╗\n"
printf "║     INSTALLATION COMPLETE!           ║\n"
printf "╚══════════════════════════════════════╝\n"
printf "${RESET}\n"
printf "Run: ${YELLOW}exec zsh${RESET} to apply\n"
printf "Edit: ${YELLOW}nano ~/.nzr-theme/config.sh${RESET}\n\n"
