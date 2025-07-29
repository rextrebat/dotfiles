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
                        fd-find ripgrep bat exa fzf \
                        fonts-jetbrains-mono \
                        i3 i3status polybar rofi \
                        xclip xsel
                    ;;
                "arch")
                    sudo pacman -Sy --noconfirm \
                        curl wget git zsh tmux neovim \
                        base-devel python-pip nodejs npm \
                        fd ripgrep bat exa fzf \
                        ttf-jetbrains-mono \
                        i3-wm i3status polybar rofi \
                        xclip xsel
                    ;;
                "redhat")
                    sudo yum install -y \
                        curl wget git zsh tmux neovim \
                        gcc gcc-c++ make python3-pip nodejs npm \
                        fd-find ripgrep bat exa fzf \
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
                fd ripgrep bat exa fzf \
                font-jetbrains-mono
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
    
    # Shell configurations
    link_dotfile "_zshrc" "$HOME/.zshrc"
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
    log "Setting up shell environment..."
    
    # Install Oh My Zsh if not present
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install Powerlevel10k theme
    if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        log "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    
    # Install useful zsh plugins
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$plugins_dir/zsh-autosuggestions"
    fi
    
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$plugins_dir/zsh-syntax-highlighting"
    fi
    
    if [[ ! -d "$plugins_dir/fzf-tab" ]]; then
        git clone https://github.com/Aloxaf/fzf-tab \
            "$plugins_dir/fzf-tab"
    fi
    
    success "Shell environment setup complete"
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
            if [[ ! -f "$HOME/.local/share/fonts/JetBrains Mono Nerd Font Complete.ttf" ]]; then
                log "Installing JetBrains Mono Nerd Font..."
                curl -fLo "$HOME/.local/share/fonts/JetBrains Mono Nerd Font Complete.ttf" \
                    https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/NoLigatures/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete.ttf
                
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
    echo "  • Set up zsh with Oh My Zsh and modern plugins"
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
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Run tmux and press Ctrl-a + I to install tmux plugins"
    echo "  3. Open nvim and run :Lazy sync to install plugins"
    echo "  4. For i3: restart i3 or reload configuration"
    echo
    info "Backup files are stored in: $BACKUP_DIR"
    info "Installation log: $LOG_FILE"
    echo
    info "Enjoy your modern development environment! 🚀"
}

# Run main function
main "$@"

