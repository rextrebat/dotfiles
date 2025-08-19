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
# Component Management
# =====================================================

# Available installation components
declare -A COMPONENTS=(
    ["dotfiles"]="Core dotfiles (shell configs, git, tmux, etc.)"
    ["shell"]="Modern shell environment (zsh, starship, zinit, zoxide, atuin)"
    ["nvim"]="Neovim configuration and plugins"
    ["i3wm"]="i3 window manager and ecosystem"
    ["tmux"]="Tmux configuration and plugin manager"
    ["fonts"]="Programming fonts and Nerd Fonts"
    ["extras"]="Additional modern CLI tools"
)

# Component system dependencies mapping
declare -A COMPONENT_PACKAGES=(
    ["dotfiles"]="git zsh bash"
    ["shell"]="zsh curl git"
    ["nvim"]="neovim curl git"
    ["i3wm"]="i3 polybar rofi i3lock picom xss-lock xautolock nitrogen dunst arandr pavucontrol brightnessctl"
    ["tmux"]="tmux git"
    ["fonts"]="curl"
    ["extras"]="curl wget"
)

select_components() {
    log "Available installation components:"
    echo
    
    local selected_components=()
    
    for component in "dependencies" "dotfiles" "shell" "nvim" "i3wm" "tmux" "fonts" "extras"; do
        echo -e "${BLUE}$component${NC}: ${COMPONENTS[$component]}"
        if prompt_yn "Install $component?"; then
            selected_components+=("$component")
        fi
        echo
    done
    
    if [[ ${#selected_components[@]} -eq 0 ]]; then
        warn "No components selected. Exiting."
        exit 0
    fi
    
    log "Selected components: ${selected_components[*]}"
    return 0
}

# =====================================================
# Dependency Validation
# =====================================================

install_component_dependencies() {
    local component="$1"
    
    if [[ -z "${COMPONENT_PACKAGES[$component]}" ]]; then
        return 0
    fi
    
    log "Installing dependencies for $component..."
    
    local packages=(${COMPONENT_PACKAGES[$component]})
    
    case "$OS" in
        "linux")
            case "$DISTRO" in
                "debian")
                    sudo apt-get update >/dev/null 2>&1
                    sudo apt-get install -y "${packages[@]}" 2>/dev/null || {
                        warn "Some packages failed to install for $component"
                        # Try individual packages
                        for pkg in "${packages[@]}"; do
                            sudo apt-get install -y "$pkg" 2>/dev/null || warn "Failed to install: $pkg"
                        done
                    }
                    
                    # Special handling for i3 ecosystem
                    if [[ "$component" == "i3wm" ]]; then
                        # Install i3lock-fancy if not available in repos
                        if ! command -v i3lock-fancy >/dev/null 2>&1; then
                            if command -v snap >/dev/null 2>&1; then
                                sudo snap install i3lock-fancy || warn "Failed to install i3lock-fancy via snap"
                            else
                                warn "i3lock-fancy not available. Install manually: https://github.com/meskarune/i3lock-fancy"
                            fi
                        fi
                    fi
                    ;;
                "arch")
                    sudo pacman -Sy --noconfirm "${packages[@]}" 2>/dev/null || {
                        warn "Some packages failed to install for $component"
                    }
                    
                    if [[ "$component" == "i3wm" ]]; then
                        # Try to install i3lock-fancy from AUR
                        if command -v yay >/dev/null 2>&1; then
                            yay -S --noconfirm i3lock-fancy-git || warn "Failed to install i3lock-fancy from AUR"
                        elif command -v paru >/dev/null 2>&1; then
                            paru -S --noconfirm i3lock-fancy-git || warn "Failed to install i3lock-fancy from AUR"
                        fi
                    fi
                    ;;
                "redhat")
                    sudo yum install -y "${packages[@]}" 2>/dev/null || {
                        warn "Some packages failed to install for $component"
                    }
                    ;;
            esac
            ;;
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                log "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Convert Linux package names to macOS equivalents
            local mac_packages=()
            for pkg in "${packages[@]}"; do
                case "$pkg" in
                    "i3"|"polybar"|"rofi"|"picom"|"nitrogen"|"dunst")
                        warn "$pkg not available on macOS"
                        ;;
                    *)
                        mac_packages+=("$pkg")
                        ;;
                esac
            done
            
            if [[ ${#mac_packages[@]} -gt 0 ]]; then
                brew install "${mac_packages[@]}" || warn "Some packages failed to install for $component"
            fi
            ;;
    esac
    
    success "Dependencies installed for $component"
}

validate_system_requirements() {
    log "Validating system requirements..."
    
    # Check for sudo access
    if ! sudo -n true 2>/dev/null; then
        if ! prompt_yn "This installer requires sudo access. Continue?"; then
            error "Sudo access required for system package installation"
        fi
    fi
    
    # Check internet connectivity
    if ! curl -s --connect-timeout 5 https://github.com >/dev/null; then
        warn "No internet connection detected. Some features may not work."
        if ! prompt_yn "Continue without internet?"; then
            exit 1
        fi
    fi
    
    # Validate selected components
    for component in "${selected_components[@]}"; do
        if [[ "$component" != "dependencies" ]]; then
            check_component_dependencies "$component" || {
                warn "Component $component has unmet dependencies"
                if prompt_yn "Install dependencies component first?"; then
                    selected_components=("dependencies" "${selected_components[@]}")
                    break
                fi
            }
        fi
    done
    
    success "System validation complete"
}

# =====================================================
# Installation Functions
# =====================================================

install_dependencies() {
    log "Installing system dependencies..."
    
    # Core packages needed by most components
    local core_packages=()
    local dev_packages=()
    local i3_packages=()
    local font_packages=()
    
    case "$OS" in
        "linux")
            case "$DISTRO" in
                "debian")
                    sudo apt-get update
                    
                    # Core system tools
                    core_packages=("curl" "wget" "git" "zsh" "bash" "build-essential")
                    
                    # Development tools
                    dev_packages=("tmux" "neovim" "python3-pip" "nodejs" "npm" "fd-find" "ripgrep" "bat" "fzf" "htop" "ncdu" "git-delta" "xclip" "xsel")
                    
                    # i3 ecosystem
                    i3_packages=("i3" "i3status" "i3lock" "polybar" "rofi" "picom" "nitrogen" "dunst" "xss-lock" "xautolock" "arandr" "pavucontrol" "brightnessctl")
                    
                    # Additional i3 dependencies that might not be in repos
                    local i3_extra=("i3lock-fancy")
                    
                    # Programming fonts
                    font_packages=("fonts-jetbrains-mono" "fonts-inter" "fonts-font-awesome")
                    
                    # Install core packages
                    sudo apt-get install -y "${core_packages[@]}"
                    
                    # Install development packages if selected
                    if [[ " ${selected_components[*]} " =~ " shell " ]] || [[ " ${selected_components[*]} " =~ " nvim " ]] || [[ " ${selected_components[*]} " =~ " tmux " ]]; then
                        sudo apt-get install -y "${dev_packages[@]}"
                    fi
                    
                    # Install i3 packages if selected
                    if [[ " ${selected_components[*]} " =~ " i3wm " ]]; then
                        sudo apt-get install -y "${i3_packages[@]}" || warn "Some i3 packages failed to install"
                        
                        # Try to install i3lock-fancy from external sources
                        if ! command -v i3lock-fancy >/dev/null 2>&1; then
                            log "Installing i3lock-fancy from source..."
                            if command -v snap >/dev/null 2>&1; then
                                sudo snap install i3lock-fancy || warn "Failed to install i3lock-fancy via snap"
                            else
                                warn "i3lock-fancy not available. Please install manually: https://github.com/meskarune/i3lock-fancy"
                            fi
                        fi
                    fi
                    
                    # Install fonts if selected
                    if [[ " ${selected_components[*]} " =~ " fonts " ]]; then
                        sudo apt-get install -y "${font_packages[@]}" || warn "Some font packages failed to install"
                    fi
                    
                    # Create fd symlink for Debian compatibility
                    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
                    ;;
                "arch")
                    # Core system tools
                    core_packages=("curl" "wget" "git" "zsh" "bash" "base-devel")
                    
                    # Development tools  
                    dev_packages=("tmux" "neovim" "python-pip" "nodejs" "npm" "fd" "ripgrep" "bat" "fzf" "htop" "ncdu" "git-delta" "xclip" "xsel")
                    
                    # i3 ecosystem
                    i3_packages=("i3-wm" "i3status" "i3lock" "polybar" "rofi" "picom" "nitrogen" "dunst" "xss-lock" "xautolock" "arandr" "pavucontrol" "brightnessctl")
                    
                    # Programming fonts
                    font_packages=("ttf-jetbrains-mono" "inter-font" "ttf-font-awesome")
                    
                    # Install packages based on selected components
                    sudo pacman -Sy --noconfirm "${core_packages[@]}"
                    
                    if [[ " ${selected_components[*]} " =~ " shell " ]] || [[ " ${selected_components[*]} " =~ " nvim " ]] || [[ " ${selected_components[*]} " =~ " tmux " ]]; then
                        sudo pacman -S --noconfirm "${dev_packages[@]}" || warn "Some development packages failed to install"
                    fi
                    
                    if [[ " ${selected_components[*]} " =~ " i3wm " ]]; then
                        sudo pacman -S --noconfirm "${i3_packages[@]}" || warn "Some i3 packages failed to install"
                        
                        # Install i3lock-fancy from AUR if available
                        if command -v yay >/dev/null 2>&1; then
                            yay -S --noconfirm i3lock-fancy-git || warn "Failed to install i3lock-fancy from AUR"
                        elif command -v paru >/dev/null 2>&1; then
                            paru -S --noconfirm i3lock-fancy-git || warn "Failed to install i3lock-fancy from AUR"
                        fi
                    fi
                    
                    if [[ " ${selected_components[*]} " =~ " fonts " ]]; then
                        sudo pacman -S --noconfirm "${font_packages[@]}" || warn "Some font packages failed to install"
                    fi
                    ;;
                "redhat")
                    # Similar structure for RedHat-based systems
                    core_packages=("curl" "wget" "git" "zsh" "bash" "gcc" "gcc-c++" "make")
                    dev_packages=("tmux" "neovim" "python3-pip" "nodejs" "npm" "fd-find" "ripgrep" "bat" "fzf" "htop" "ncdu" "git-delta" "xclip" "xsel")
                    i3_packages=("i3" "polybar" "rofi" "xclip" "xsel")
                    
                    sudo yum install -y "${core_packages[@]}"
                    
                    if [[ " ${selected_components[*]} " =~ " shell " ]] || [[ " ${selected_components[*]} " =~ " nvim " ]] || [[ " ${selected_components[*]} " =~ " tmux " ]]; then
                        sudo yum install -y "${dev_packages[@]}" || warn "Some development packages failed to install"
                    fi
                    
                    if [[ " ${selected_components[*]} " =~ " i3wm " ]]; then
                        sudo yum install -y "${i3_packages[@]}" || warn "Some i3 packages failed to install"
                        warn "i3 ecosystem support is limited on RHEL. Consider using Fedora or installing from source."
                    fi
                    ;;
            esac
            ;;
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                log "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Core packages
            local packages=("curl" "wget" "git" "zsh")
            
            if [[ " ${selected_components[*]} " =~ " shell " ]] || [[ " ${selected_components[*]} " =~ " nvim " ]] || [[ " ${selected_components[*]} " =~ " tmux " ]]; then
                packages+=("tmux" "neovim" "python3" "node" "npm" "fd" "ripgrep" "bat" "fzf" "htop" "ncdu" "git-delta")
            fi
            
            if [[ " ${selected_components[*]} " =~ " fonts " ]]; then
                packages+=("font-jetbrains-mono" "font-inter")
            fi
            
            brew install "${packages[@]}" || warn "Some packages failed to install"
            
            if [[ " ${selected_components[*]} " =~ " i3wm " ]]; then
                warn "i3 window manager is not available on macOS. Consider using yabai instead."
            fi
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
    log "Installing core dotfiles..."
    
    # Always install core shell and git configs
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
    
    # Terminal and development basics
    link_dotfile "_pythonrc.py" "$HOME/.pythonrc.py"
    link_dotfile "_Xresources" "$HOME/.Xresources"
    link_dotfile "_dircolors" "$HOME/.dircolors"
    link_dotfile ".editorconfig" "$HOME/.editorconfig"
    
    success "Core dotfiles installation complete"
}

install_nvim_config() {
    log "Installing Neovim configuration..."
    
    if [[ -d "$DOTFILES_DIR/config/nvim" ]]; then
        link_dotfile "config/nvim" "$HOME/.config/nvim"
        success "Neovim configuration installed"
    else
        warn "Neovim configuration not found"
    fi
}

install_i3_config() {
    log "Installing i3 window manager configuration..."
    
    # i3 window manager
    if [[ -d "$DOTFILES_DIR/config/i3" ]]; then
        link_dotfile "config/i3" "$HOME/.config/i3"
    else
        warn "i3 configuration not found"
    fi
    
    # Polybar
    if [[ -d "$DOTFILES_DIR/config/polybar" ]]; then
        link_dotfile "config/polybar" "$HOME/.config/polybar"
    else
        warn "Polybar configuration not found"
    fi
    
    # Rofi
    if [[ -d "$DOTFILES_DIR/config/rofi" ]]; then
        link_dotfile "config/rofi" "$HOME/.config/rofi"
    else
        warn "Rofi configuration not found"
    fi
    
    # Picom compositor config if it exists
    if [[ -f "$DOTFILES_DIR/config/picom/picom.conf" ]]; then
        link_dotfile "config/picom/picom.conf" "$HOME/.config/picom/picom.conf"
    fi
    
    success "i3 window manager configuration installed"
}

install_tmux_config() {
    log "Installing tmux configuration..."
    
    link_dotfile "_tmux.conf" "$HOME/.tmux.conf"
    success "Tmux configuration installed"
}

setup_shell() {
    log "Setting up modern shell environment..."
    
    # Starship configuration
    if [[ -f "$DOTFILES_DIR/starship.toml" ]]; then
        mkdir -p "$HOME/.config"
        link_dotfile "starship.toml" "$HOME/.config/starship.toml"
    fi
    
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

setup_extras() {
    log "Installing additional modern CLI tools..."
    
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
            local tools=("eza")
            for tool in "${tools[@]}"; do
                if ! command -v "$tool" >/dev/null 2>&1; then
                    brew install "$tool"
                fi
            done
            ;;
    esac
    
    success "Additional CLI tools installed"
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
    
    # Component selection
    echo
    info "This is a modular installer. You can choose which components to install."
    echo
    
    # Let user select components
    select_components
    
    # Store selected components globally
    declare -g selected_components
    selected_components=()
    
    for component in "dotfiles" "shell" "nvim" "i3wm" "tmux" "fonts" "extras"; do
        echo -e "${BLUE}$component${NC}: ${COMPONENTS[$component]}"
        if prompt_yn "Install $component?"; then
            selected_components+=("$component")
        fi
        echo
    done
    
    if [[ ${#selected_components[@]} -eq 0 ]]; then
        warn "No components selected. Exiting."
        exit 0
    fi
    
    echo
    info "Selected components: ${selected_components[*]}"
    info "Existing files have been backed up to: $BACKUP_DIR"
    echo
    
    if ! prompt_yn "Continue with installation of selected components?"; then
        warn "Installation cancelled by user"
        exit 0
    fi
    
    # Validate system requirements
    validate_system_requirements
    
    # Install components with their dependencies
    for component in "${selected_components[@]}"; do
        echo
        log "Installing component: $component"
        
        # Install component-specific dependencies first
        install_component_dependencies "$component"
        
        # Then install the component itself
        case "$component" in
            "dotfiles")
                install_dotfiles
                ;;
            "shell")
                setup_shell
                ;;
            "nvim")
                install_nvim_config
                ;;
            "i3wm")
                install_i3_config
                ;;
            "tmux")
                install_tmux_config
                setup_tmux
                ;;
            "fonts")
                setup_fonts
                ;;
            "extras")
                setup_extras
                ;;
        esac
    done
    
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

