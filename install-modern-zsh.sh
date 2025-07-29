#!/usr/bin/env bash

# Modern Zsh Installation Script
# Replaces Oh My Zsh with faster, modern alternatives

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main installation function
install_modern_zsh() {
    log_info "Installing modern Zsh setup..."

    # Install zsh if not present
    if ! command_exists zsh; then
        log_info "Installing zsh..."
        if command_exists apt; then
            sudo apt update && sudo apt install -y zsh
        elif command_exists brew; then
            brew install zsh
        elif command_exists pacman; then
            sudo pacman -S zsh
        else
            log_error "Package manager not supported. Please install zsh manually."
            exit 1
        fi
    fi

    # Install modern command-line tools
    install_modern_tools

    # Backup existing configurations
    backup_existing_configs

    # Install Starship prompt
    install_starship

    # Link configuration files
    link_configs

    # Set zsh as default shell
    set_default_shell

    log_success "Modern Zsh setup completed!"
    log_info "Restart your terminal or run 'exec zsh' to start using the new configuration."
    log_info "Run 'zprof' in zsh to see startup performance."
}

install_modern_tools() {
    log_info "Installing modern command-line tools..."

    # Install tools based on available package manager
    if command_exists apt; then
        install_tools_apt
    elif command_exists brew; then
        install_tools_brew
    elif command_exists pacman; then
        install_tools_pacman
    else
        log_warning "Package manager not recognized. Installing tools manually..."
        install_tools_manual
    fi
}

install_tools_apt() {
    log_info "Installing tools via apt..."
    
    # Add repositories for modern tools
    if ! grep -q "git-core/ppa" /etc/apt/sources.list.d/*; then
        sudo add-apt-repository -y ppa:git-core/ppa || true
    fi
    
    sudo apt update

    # Essential tools
    local tools=(
        "curl"
        "git"
        "fzf"
        "fd-find"
        "ripgrep"
        "htop"
        "tree"
        "jq"
        "wget"
        "unzip"
    )

    for tool in "${tools[@]}"; do
        if ! command_exists "$tool" && ! dpkg -l | grep -q "^ii.*$tool"; then
            log_info "Installing $tool..."
            sudo apt install -y "$tool" || log_warning "Failed to install $tool"
        fi
    done

    # Install bat (different package name on Ubuntu)
    if ! command_exists bat && ! command_exists batcat; then
        log_info "Installing bat..."
        sudo apt install -y bat || log_warning "Failed to install bat"
        # Create alias if batcat was installed instead of bat
        if command_exists batcat && ! command_exists bat; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        fi
    fi

    # Install eza (modern ls replacement)
    if ! command_exists eza; then
        log_info "Installing eza..."
        if ! wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg; then
            log_warning "Failed to add eza repository key"
        else
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt update && sudo apt install -y eza || log_warning "Failed to install eza"
        fi
    fi

    # Install zoxide (smart cd)
    if ! command_exists zoxide; then
        log_info "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || log_warning "Failed to install zoxide"
    fi
}

install_tools_brew() {
    log_info "Installing tools via Homebrew..."
    local tools=(
        "fzf"
        "fd"
        "ripgrep"
        "bat"
        "eza"
        "htop"
        "tree"
        "jq"
        "zoxide"
        "git"
    )

    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            log_info "Installing $tool..."
            brew install "$tool" || log_warning "Failed to install $tool"
        fi
    done
}

install_tools_pacman() {
    log_info "Installing tools via pacman..."
    local tools=(
        "fzf"
        "fd"
        "ripgrep"
        "bat"
        "eza"
        "htop"
        "tree"
        "jq"
        "zoxide"
        "git"
    )

    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            log_info "Installing $tool..."
            sudo pacman -S --noconfirm "$tool" || log_warning "Failed to install $tool"
        fi
    done
}

install_tools_manual() {
    log_info "Installing tools manually..."
    
    # Install zoxide
    if ! command_exists zoxide; then
        log_info "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || log_warning "Failed to install zoxide"
    fi
    
    # Note: Other tools would need manual installation
    log_warning "Some tools may need to be installed manually: fzf, fd, ripgrep, bat, eza"
}

install_starship() {
    if ! command_exists starship; then
        log_info "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes || {
            log_warning "Failed to install Starship via script, trying alternative methods..."
            
            if command_exists cargo; then
                cargo install starship --locked || log_warning "Failed to install Starship via cargo"
            elif command_exists brew; then
                brew install starship || log_warning "Failed to install Starship via brew"
            else
                log_error "Could not install Starship. Please install manually."
                return 1
            fi
        }
    else
        log_info "Starship already installed"
    fi
}

backup_existing_configs() {
    local backup_dir="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [[ -f "$HOME/.zshrc" || -f "$HOME/.zshenv" ]]; then
        log_info "Backing up existing configurations to $backup_dir"
        mkdir -p "$backup_dir"
        
        [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/"
        [[ -f "$HOME/.zshenv" ]] && cp "$HOME/.zshenv" "$backup_dir/"
        [[ -d "$HOME/.oh-my-zsh" ]] && cp -r "$HOME/.oh-my-zsh" "$backup_dir/"
        
        log_success "Backup created at $backup_dir"
    fi
}

link_configs() {
    local dotfiles_dir
    dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    log_info "Linking configuration files..."
    
    # Create config directories
    mkdir -p "$HOME/.config"
    
    # Link zsh configurations
    ln -sf "$dotfiles_dir/_zshrc.modern" "$HOME/.zshrc"
    ln -sf "$dotfiles_dir/_zshenv" "$HOME/.zshenv"
    
    # Link starship config
    ln -sf "$dotfiles_dir/starship.toml" "$HOME/.config/starship.toml"
    
    log_success "Configuration files linked"
}

set_default_shell() {
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        log_info "Setting zsh as default shell..."
        
        # Add zsh to /etc/shells if not present
        if ! grep -q "$(which zsh)" /etc/shells; then
            echo "$(which zsh)" | sudo tee -a /etc/shells
        fi
        
        chsh -s "$(which zsh)" || {
            log_warning "Failed to change shell automatically. Please run: chsh -s $(which zsh)"
        }
    else
        log_info "Zsh is already the default shell"
    fi
}

# Main execution
main() {
    log_info "Starting modern Zsh installation..."
    
    # Check if running in supported environment
    if [[ -z "${BASH_VERSION:-}" ]]; then
        log_error "This script requires bash to run"
        exit 1
    fi
    
    # Ask for confirmation
    echo "This will install a modern Zsh configuration with:"
    echo "  - Zinit plugin manager (replaces Oh My Zsh)"
    echo "  - Starship prompt"
    echo "  - Modern command-line tools (eza, bat, fd, ripgrep, zoxide)"
    echo "  - Enhanced auto-completion and syntax highlighting"
    echo ""
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_modern_zsh
    else
        log_info "Installation cancelled"
        exit 0
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi