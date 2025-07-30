#!/usr/bin/env bash

# =====================================================
# Modern Dotfiles Installer
# Automated setup for development environment
# =====================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$DOTFILES_DIR/install.log"

# =====================================================
# Helper Functions
# =====================================================

print_header() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          🚀 Modern Dotfiles Installer                        ║"
    echo "║                     Complete Development Environment Setup                    ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

prompt_yn() {
    local prompt="$1"
    while true; do
        read -p "$(echo -e "${YELLOW}$prompt (y/n): ${NC}")" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# =====================================================
# System Detection
# =====================================================

detect_system() {
    log "Detecting system information..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get >/dev/null 2>&1; then
            DISTRO="debian"
            PKG_MANAGER="apt-get"
        elif command -v yum >/dev/null 2>&1; then
            DISTRO="redhat"
            PKG_MANAGER="yum"
        elif command -v pacman >/dev/null 2>&1; then
            DISTRO="arch"
            PKG_MANAGER="pacman"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PKG_MANAGER="brew"
    else
        error "Unsupported operating system: $OSTYPE"
    fi
    
    info "Detected: $OS ($DISTRO)"
}

# =====================================================
# Backup Functions
# =====================================================

create_backup() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log "Created backup directory: $BACKUP_DIR"
    fi
}

backup_file() {
    local file="$1"
    local target="$HOME/$file"
    
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        cp -r "$target" "$BACKUP_DIR/" 2>/dev/null || true
        success "Backed up: $file"
    fi
}

# =====================================================
# Installation Functions
# =====================================================

install_dependencies() {
    log "Installing system dependencies..."
    
    case "$OS" in
        "linux")
            case "$DISTRO" in
                "debian")
                    sudo apt-get update
                    sudo apt-get install -y \
                        curl wget git zsh tmux neovim \
                        build-essential python3-pip nodejs npm \
                        fd-find ripgrep bat fzf htop ncdu \
                        fonts-jetbrains-mono fonts-inter \
                        git-delta \
                        i3 i3status polybar rofi \
                        xclip xsel
                    
                    # Create fd symlink for Debian compatibility
                    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
                    ;;
                "arch")
                    sudo pacman -Sy --noconfirm \
                        curl wget git zsh tmux neovim \
                        base-devel python-pip nodejs npm \
                        fd ripgrep bat fzf htop ncdu \
                        ttf-jetbrains-mono inter-font \
                        git-delta \
                        i3-wm i3status polybar rofi \
                        xclip xsel
                    ;;
                "redhat")
                    sudo yum install -y \
                        curl wget git zsh tmux neovim \
                        gcc gcc-c++ make python3-pip nodejs npm \
                        fd-find ripgrep bat fzf htop ncdu \
                        git-delta \
                        i3 polybar rofi \
                        xclip xsel
                    ;;
            esac
            ;;
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                log "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            brew install \
                curl wget git zsh tmux neovim \
                python3 node npm \
                fd ripgrep bat fzf htop ncdu \
                git-delta \
                font-jetbrains-mono font-inter
            ;;
    esac
    
    success "System dependencies installed"
}

link_dotfile() {
    local source="$1"
    local target="$2"
    local target_dir="$(dirname "$target")"
    
    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi
    
    # Remove existing file/link
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        rm -rf "$target"
    fi
    
    # Create symlink
    ln -sf "$DOTFILES_DIR/$source" "$target"
    success "Linked: $source -> $target"
}

install_dotfiles() {
    log "Installing dotfiles..."
    
    # Shell configurations (use modern zsh if available)
    if [[ -f "$DOTFILES_DIR/_zshrc.modern" ]]; then
        link_dotfile "_zshrc.modern" "$HOME/.zshrc"
    else
        link_dotfile "_zshrc" "$HOME/.zshrc"
    fi
    link_dotfile "_bashrc" "$HOME/.bashrc"
    link_dotfile "_profile" "$HOME/.profile"
    link_dotfile "_inputrc" "$HOME/.inputrc"
    
    # Git configuration
    link_dotfile "_gitconfig" "$HOME/.gitconfig"
    link_dotfile "_gitignore_global" "$HOME/.gitignore_global"
    
    # Terminal and development
    link_dotfile "_tmux.conf" "$HOME/.tmux.conf"
    link_dotfile "_pythonrc.py" "$HOME/.pythonrc.py"
    link_dotfile "_Xresources" "$HOME/.Xresources"
    link_dotfile "_dircolors" "$HOME/.dircolors"
    
    # Editor configuration
    link_dotfile ".editorconfig" "$HOME/.editorconfig"
    
    # Starship configuration if it exists
    if [[ -f "$DOTFILES_DIR/starship.toml" ]]; then
        mkdir -p "$HOME/.config"
        link_dotfile "starship.toml" "$HOME/.config/starship.toml"
    fi
    
    # Neovim configuration
    if [[ -d "$DOTFILES_DIR/config/nvim" ]]; then
        link_dotfile "config/nvim" "$HOME/.config/nvim"
    fi
    
    # i3 window manager
    if [[ -d "$DOTFILES_DIR/config/i3" ]]; then
        link_dotfile "config/i3" "$HOME/.config/i3"
    fi
    
    # Polybar
    if [[ -d "$DOTFILES_DIR/config/polybar" ]]; then
        link_dotfile "config/polybar" "$HOME/.config/polybar"
    fi
    
    # Rofi
    if [[ -d "$DOTFILES_DIR/config/rofi" ]]; then
        link_dotfile "config/rofi" "$HOME/.config/rofi"
    fi
    
    success "Dotfiles installation complete"
}

setup_shell() {
    log "Setting up modern shell environment..."
    
    # Install Zinit plugin manager (critical for modern zsh config)
    local zinit_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    if [[ ! -d "$zinit_dir" ]]; then
        log "Installing Zinit plugin manager..."
        mkdir -p "$(dirname "$zinit_dir")"
        git clone https://github.com/zdharma-continuum/zinit.git "$zinit_dir"
    fi
    
    # Install Starship prompt
    if ! command -v starship >/dev/null 2>&1; then
        log "Installing Starship prompt..."
        case "$OS" in
            "linux")
                curl -sS https://starship.rs/install.sh | sh -s -- --yes
                ;;
            "macos")
                brew install starship
                ;;
        esac
    fi
    
    # Install zoxide (modern cd replacement)
    if ! command -v zoxide >/dev/null 2>&1; then
        log "Installing zoxide..."
        case "$OS" in
            "linux")
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
                ;;
            "macos")
                brew install zoxide
                ;;
        esac
    fi
    
    # Install atuin (modern shell history)
    if ! command -v atuin >/dev/null 2>&1; then
        log "Installing atuin..."
        case "$OS" in
            "linux")
                curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
                ;;
            "macos")
                brew install atuin
                ;;
        esac
    fi
    
    # Install modern CLI tools if not present
    case "$OS" in
        "linux")
            case "$DISTRO" in
                "debian")
                    # Install additional modern tools
                    if ! command -v eza >/dev/null 2>&1; then
                        log "Installing eza (modern ls replacement)..."
                        wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz -C /tmp
                        sudo mv /tmp/eza /usr/local/bin/
                    fi
                    ;;
            esac
            ;;
        "macos")
            # Modern tools via Homebrew
            local tools=("eza" "zoxide" "atuin" "starship")
            for tool in "${tools[@]}"; do
                if ! command -v "$tool" >/dev/null 2>&1; then
                    brew install "$tool"
                fi
            done
            ;;
    esac
    
    # Modern zsh configuration already linked in install_dotfiles()
    
    # Install FZF if not present
    if [[ ! -d "$HOME/.fzf" ]]; then
        log "Installing FZF..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --all --no-bash --no-fish
    fi
    
    # Install NVM (Node Version Manager) for modern zsh config
    if [[ ! -d "$HOME/.nvm" ]]; then
        log "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    fi
    
    # Install Python rich library for enhanced REPL
    if command -v pip3 >/dev/null 2>&1; then
        log "Installing Python rich library..."
        pip3 install --user rich 2>/dev/null || true
    fi
    
    success "Modern shell environment setup complete"
}

setup_tmux() {
    log "Setting up tmux environment..."
    
    # Install Tmux Plugin Manager
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        log "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
    
    success "Tmux environment setup complete"
}

setup_fonts() {
    log "Setting up fonts..."
    
    case "$OS" in
        "linux")
            # Create fonts directory
            mkdir -p "$HOME/.local/share/fonts"
            
            # Download and install Nerd Fonts if not present
            if [[ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
                log "Installing JetBrains Mono Nerd Font..."
                local font_base_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures"
                local fonts=(
                    "Regular/JetBrainsMonoNerdFont-Regular.ttf"
                    "Bold/JetBrainsMonoNerdFont-Bold.ttf"
                    "Italic/JetBrainsMonoNerdFont-Italic.ttf"
                    "BoldItalic/JetBrainsMonoNerdFont-BoldItalic.ttf"
                )
                
                for font in "${fonts[@]}"; do
                    local font_name=$(basename "$font")
                    local font_path="$HOME/.local/share/fonts/$font_name"
                    if [[ ! -f "$font_path" ]]; then
                        log "Downloading $font_name..."
                        curl -fLo "$font_path" "$font_base_url/$font" || warn "Failed to download $font_name"
                    fi
                done
                
                # Refresh font cache
                fc-cache -fv
            fi
            ;;
        "macos")
            # Nerd fonts installed via Homebrew
            if ! brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
                brew install --cask font-jetbrains-mono-nerd-font
            fi
            ;;
    esac
    
    success "Fonts setup complete"
}

post_install_setup() {
    log "Running post-installation setup..."
    
    # Reload X resources if on Linux
    if [[ "$OS" == "linux" ]] && command -v xrdb >/dev/null 2>&1; then
        xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
    fi
    
    # Make scripts executable
    if [[ -d "$HOME/.config/polybar" ]]; then
        find "$HOME/.config/polybar" -name "*.sh" -exec chmod +x {} \;
    fi
    
    if [[ -d "$HOME/.config/i3" ]]; then
        find "$HOME/.config/i3" -name "*.sh" -exec chmod +x {} \;
    fi
    
    # Starship configuration already linked in install_dotfiles()
    
    # Verify critical dependencies
    log "Verifying installation..."
    local missing_deps=()
    
    # Check for critical commands
    local critical_commands=("git" "zsh" "tmux" "nvim" "starship" "fd" "rg" "bat")
    for cmd in "${critical_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        warn "Missing critical dependencies: ${missing_deps[*]}"
        warn "Some features may not work properly"
    fi
    
    success "Post-installation setup complete"
}

# =====================================================
# Main Installation Process
# =====================================================

main() {
    print_header
    
    # Initialize log file
    echo "Dotfiles installation started at $(date)" > "$LOG_FILE"
    
    # Check if we're in the dotfiles directory
    if [[ ! -f "$DOTFILES_DIR/_zshrc" ]]; then
        error "Please run this script from the dotfiles directory"
    fi
    
    log "Starting dotfiles installation..."
    log "Dotfiles directory: $DOTFILES_DIR"
    log "Backup directory: $BACKUP_DIR"
    
    # System detection
    detect_system
    
    # Create backup directory
    create_backup
    
    # Backup existing files
    log "Creating backups of existing files..."
    local files_to_backup=(
        ".zshrc" ".bashrc" ".profile" ".inputrc"
        ".gitconfig" ".gitignore_global"
        ".tmux.conf" ".pythonrc.py" ".Xresources" ".dircolors"
        ".editorconfig"
        ".config/nvim" ".config/i3" ".config/polybar" ".config/rofi"
    )
    
    for file in "${files_to_backup[@]}"; do
        backup_file "$file"
    done
    
    # Ask for confirmation
    echo
    info "This installer will:"
    echo "  • Install system dependencies"
    echo "  • Create symbolic links for all dotfiles"
    echo "  • Set up modern zsh with Starship prompt, Zinit and plugins"
    echo "  • Install modern CLI tools (eza, zoxide, atuin, starship)"
    echo "  • Configure tmux with plugin manager"
    echo "  • Install fonts and themes"
    echo
    info "Existing files have been backed up to: $BACKUP_DIR"
    echo
    
    if ! prompt_yn "Continue with installation?"; then
        warn "Installation cancelled by user"
        exit 0
    fi
    
    # Install dependencies
    if prompt_yn "Install system dependencies?"; then
        install_dependencies
    fi
    
    # Install dotfiles
    install_dotfiles
    
    # Setup shell
    if prompt_yn "Set up zsh environment?"; then
        setup_shell
    fi
    
    # Setup tmux
    if prompt_yn "Set up tmux environment?"; then
        setup_tmux
    fi
    
    # Setup fonts
    if prompt_yn "Install fonts?"; then
        setup_fonts
    fi
    
    # Post-installation setup
    post_install_setup
    
    # Final message
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        🎉 Installation Complete! 🎉                          ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    success "Modern dotfiles installation completed successfully!"
    echo
    info "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Zinit will auto-install zsh plugins on first launch"
    echo "  3. Run tmux and press Ctrl-a + I to install tmux plugins"  
    echo "  4. Open nvim and run :Lazy sync to install plugins"
    echo "  5. For i3: restart i3 or reload configuration (Super+Shift+R)"
    echo "  6. Install Node.js LTS: nvm install --lts && nvm use --lts"
    echo "  7. Set zsh as default shell: chsh -s \$(which zsh) (logout required)"
    echo
    info "Backup files are stored in: $BACKUP_DIR"
    info "Installation log: $LOG_FILE"
    echo
    info "Enjoy your modern development environment! 🚀"
}

# Run main function
main "$@"

