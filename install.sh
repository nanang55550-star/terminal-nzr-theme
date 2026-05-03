#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║           NZR THEME - AUTO INSTALLER FOR TERMUX                  ║
# ║         Install, configure, and activate your theme                ║
# ╚══════════════════════════════════════════════════════════════════╝

set -e  # Exit on error

# ─── COLORS ───────────────────────────────────────────────────────
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
RESET='\e[0m'

# ─── PATHS ─────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="$HOME/.nzr-theme"
ZSHRC="$HOME/.zshrc"
BACKUP_DIR="$HOME/.nzr-theme-backups"

# ─── FUNCTIONS ─────────────────────────────────────────────────────
print_banner() {
    echo ""
    echo "${CYAN}╔══════════════════════════════════════════╗${RESET}"
    echo "${CYAN}║${RESET}     ${YELLOW}NZR THEME INSTALLER${RESET}                ${CYAN}║${RESET}"
    echo "${CYAN}║${RESET}     ${BLUE}Terminal Customization Tool${RESET}          ${CYAN}║${RESET}"
    echo "${CYAN}╚══════════════════════════════════════════╝${RESET}"
    echo ""
}

print_success() {
    echo "${GREEN}✓${RESET} $1"
}

print_error() {
    echo "${RED}✗${RESET} $1"
}

print_info() {
    echo "${BLUE}ℹ${RESET} $1"
}

print_warn() {
    echo "${YELLOW}⚠${RESET} $1"
}

# ─── CHECK DEPENDENCIES ────────────────────────────────────────────
check_deps() {
    print_info "Checking dependencies..."
    
    local missing=()
    
    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi
    
    if ! command -v zsh &>/dev/null; then
        missing+=("zsh")
    fi
    
    if ! command -v figlet &>/dev/null; then
        missing+=("figlet")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_warn "Missing packages: ${missing[*]}"
        echo ""
        read -p "Install now? [Y/n]: " choice
        choice=${choice:-Y}
        
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            pkg update -y
            pkg install "${missing[@]}" -y
        else
            print_error "Please install missing packages manually:"
            echo "  pkg install ${missing[*]}"
            exit 1
        fi
    fi
    
    print_success "All dependencies satisfied"
}

# ─── BACKUP ────────────────────────────────────────────────────────
backup_zshrc() {
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$ZSHRC" ]; then
        cp "$ZSHRC" "$backup_file"
        print_success "Backup created: $backup_file"
    fi
}

# ─── INSTALL THEME ─────────────────────────────────────────────────
install_theme() {
    print_info "Installing NZR Theme..."
    
    # Remove old installation
    if [ -d "$THEME_DIR" ]; then
        print_warn "Removing old installation..."
        rm -rf "$THEME_DIR"
    fi
    
    # Copy files
    mkdir -p "$THEME_DIR"
    cp -r "$REPO_DIR"/* "$THEME_DIR/"
    
    # Ensure lib directory exists
    mkdir -p "$THEME_DIR/lib"
    
    print_success "Theme files copied to $THEME_DIR"
}

# ─── CONFIGURE ───────────────────────────────────────────────────
configure_theme() {
    print_info "Configuring theme..."
    
    local config_file="$THEME_DIR/config.sh"
    
    # Create config if not exists
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" <<'EOF'
#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                    NZR THEME CONFIGURATION                       ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── HEADLINE & USER INFO ─────────────────────────────────────────
HEADLINE_TEXT="NZR-TERMUX"
HEADLINE_COLOR="cyan"
WELCOME_MSG="Selamat datang, "
USER_NAME=""

# ─── FITUR LANJUTAN (ON/OFF) ──────────────────────────────────────
AUTOSUGGESTIONS="OFF"
SYNTAX_HIGHLIGHTING="OFF"
BATGIT_INTEGRATION="OFF"

# ─── TAMPILAN ─────────────────────────────────────────────────────
SHOW_LOGO="ON"
SHOW_HEADLINE="ON"
SHOW_USER_INFO="ON"
SHOW_SYSTEM_INFO="ON"
EOF
    fi
    
    # Ask user for customization
    echo ""
    echo "${CYAN}─── Personalization ───${RESET}"
    echo ""
    
    read -p "Enter your headline text [NZR-TERMUX]: " headline
    headline=${headline:-NZR-TERMUX}
    
    read -p "Enter your name: " username
    
    read -p "Enable Autosuggestions? [y/N]: " autosug
    [[ "$autosug" =~ ^[Yy]$ ]] && AUTOSUG="ON" || AUTOSUG="OFF"
    
    read -p "Enable Syntax Highlighting? [y/N]: " syntax
    [[ "$syntax" =~ ^[Yy]$ ]] && SYNTAX="ON" || SYNTAX="OFF"
    
    # Update config
    sed -i "s/HEADLINE_TEXT=.*/HEADLINE_TEXT=\"$headline\"/" "$config_file"
    sed -i "s/USER_NAME=.*/USER_NAME=\"$username\"/" "$config_file"
    sed -i "s/AUTOSUGGESTIONS=.*/AUTOSUGGESTIONS=\"$AUTOSUG\"/" "$config_file"
    sed -i "s/SYNTAX_HIGHLIGHTING=.*/SYNTAX_HIGHLIGHTING=\"$SYNTAX\"/" "$config_file"
    
    print_success "Configuration saved"
}

# ─── ACTIVATE IN ZSHRC ─────────────────────────────────────────────
activate_theme() {
    print_info "Activating theme in Zsh..."
    
    # Remove old NZR entries
    if grep -q "nzr-theme" "$ZSHRC" 2>/dev/null; then
        sed -i '/nzr-theme/d' "$ZSHRC"
        sed -i '/NZR Theme/d' "$ZSHRC"
    fi
    
    # Add new entry
    cat >> "$ZSHRC" <<EOF

# ═══ NZR THEME ════════════════════════════════════════════════════
source $THEME_DIR/nzr.zsh
EOF
    
    print_success "Theme activated in $ZSHRC"
}

# ─── OPTIONAL PLUGINS ──────────────────────────────────────────────
install_plugins() {
    echo ""
    print_info "Optional plugins installation..."
    echo ""
    
    # Autosuggestions
    if [ ! -d "$HOME/.zsh/zsh-autosuggestions" ]; then
        read -p "Install Zsh Autosuggestions? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions \
                "$HOME/.zsh/zsh-autosuggestions" 2>/dev/null && \
                print_success "Autosuggestions installed" || \
                print_error "Failed to install autosuggestions"
        fi
    fi
    
    # Syntax Highlighting
    if [ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ]; then
        read -p "Install Zsh Syntax Highlighting? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting \
                "$HOME/.zsh/zsh-syntax-highlighting" 2>/dev/null && \
                print_success "Syntax Highlighting installed" || \
                print_error "Failed to install syntax highlighting"
        fi
    fi
    
    # Bat
    if ! command -v bat &>/dev/null; then
        read -p "Install Bat (better cat)? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            pkg install bat -y && \
                print_success "Bat installed" || \
                print_error "Failed to install bat"
        fi
    fi
}

# ─── FINISH ─────────────────────────────────────────────────────────
finish() {
    echo ""
    echo "${GREEN}╔══════════════════════════════════════════╗${RESET}"
    echo "${GREEN}║${RESET}     ${YELLOW}INSTALLATION COMPLETE!${RESET}             ${GREEN}║${RESET}"
    echo "${GREEN}╚══════════════════════════════════════════╝${RESET}"
    echo ""
    echo "${CYAN}Next steps:${RESET}"
    echo "  1. Run: ${YELLOW}exec zsh${RESET}"
    echo "  2. Edit config: ${YELLOW}nano ~/.nzr-theme/config.sh${RESET}"
    echo "  3. Enjoy your new theme! 🎨"
    echo ""
    echo "${BLUE}Need help?${RESET} Visit: https://github.com/nanang55550-star/terminal-nzr-theme"
    echo ""
}

# ─── MAIN ───────────────────────────────────────────────────────────
main() {
    print_banner
    check_deps
    backup_zshrc
    install_theme
    configure_theme
    activate_theme
    install_plugins
    finish
}

main "$@"
