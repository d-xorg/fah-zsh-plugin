#!/bin/bash
# install.sh - Interactive installer for fah-zsh-plugin
# Author: d-xorg
# Description: Setup script for the fah (Failure Audio Handler) ZSH plugin

set -e  # Exit on error

# ============================================================================
# Colors and Formatting
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================================================
# Banner
# ============================================================================

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ___       __  
   / __/__ _ / /  
  / _// _ `/ _ \ 
 /_/  \_,_/_//_/ 
                 
 Failure Audio Handler
 ZSH Plugin Installer
EOF
    echo -e "${RESET}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════${RESET}\n"
}

# ============================================================================
# Platform Detection
# ============================================================================

detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# ============================================================================
# Validation Functions
# ============================================================================

check_requirements() {
    local platform=$(detect_platform)
    
    if [[ "$platform" != "macos" ]]; then
        echo -e "${RED}⚠️  Error: This plugin currently only supports macOS.${RESET}"
        echo -e "${YELLOW}Your platform: $OSTYPE${RESET}\n"
        exit 1
    fi
    
    # Check if afplay exists (should exist on all macOS systems)
    if ! command -v afplay &>/dev/null; then
        echo -e "${RED}⚠️  Error: afplay command not found.${RESET}"
        echo -e "${YELLOW}This is unusual for macOS. Please check your system.${RESET}\n"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Platform check passed (macOS)${RESET}"
    echo -e "${GREEN}✓ afplay command available${RESET}\n"
}

# ============================================================================
# Setup Functions
# ============================================================================

setup_sound_directory() {
    local sound_dir="$HOME/.sounds"
    
    if [[ ! -d "$sound_dir" ]]; then
        echo -e "${BLUE}Creating sound directory: $sound_dir${RESET}"
        mkdir -p "$sound_dir"
        echo -e "${GREEN}✓ Directory created${RESET}\n"
    else
        echo -e "${GREEN}✓ Sound directory already exists${RESET}\n"
    fi
}

download_sample_sound() {
    local sound_dir="$HOME/.sounds"
    local sound_file="$sound_dir/fah.mp3"
    
    setup_sound_directory
    
    echo -e "${BLUE}Downloading sample failure sound...${RESET}"
    
    # Sample sound URL (using a creative commons or free sound)
    # You can replace this with your preferred sound URL
    local sound_url="https://www.myinstants.com/media/sounds/price-is-right-losing-horn.mp3"
    
    if command -v curl &>/dev/null; then
        curl -L -o "$sound_file" "$sound_url" 2>/dev/null || {
            echo -e "${YELLOW}⚠️  Could not download sound file automatically.${RESET}"
            echo -e "${YELLOW}You can manually place an audio file at: $sound_file${RESET}\n"
            return 1
        }
    elif command -v wget &>/dev/null; then
        wget -O "$sound_file" "$sound_url" 2>/dev/null || {
            echo -e "${YELLOW}⚠️  Could not download sound file automatically.${RESET}"
            echo -e "${YELLOW}You can manually place an audio file at: $sound_file${RESET}\n"
            return 1
        }
    else
        echo -e "${YELLOW}⚠️  Neither curl nor wget found.${RESET}"
        echo -e "${YELLOW}Please manually download a sound file to: $sound_file${RESET}\n"
        return 1
    fi
    
    echo -e "${GREEN}✓ Sound file downloaded successfully${RESET}\n"
}

test_sound() {
    local sound_file="${1:-$HOME/.sounds/fah.mp3}"
    
    if [[ ! -f "$sound_file" ]]; then
        echo -e "${YELLOW}⚠️  Sound file not found: $sound_file${RESET}"
        echo -e "${YELLOW}Available system sounds:${RESET}"
        echo -e "  • /System/Library/Sounds/Basso.aiff"
        echo -e "  • /System/Library/Sounds/Sosumi.aiff"
        echo -e "  • /System/Library/Sounds/Funk.aiff"
        echo ""
        read -p "Test a system sound instead? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sound_file="/System/Library/Sounds/Basso.aiff"
        else
            return 1
        fi
    fi
    
    echo -e "${BLUE}🔊 Playing sound: $sound_file${RESET}"
    afplay "$sound_file"
    echo -e "${GREEN}✓ Sound test complete${RESET}\n"
}

show_configuration() {
    echo -e "${BOLD}Current Configuration:${RESET}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}FAIL_SOUND_PATH${RESET}       Default: ${GREEN}~/.sounds/fah.mp3${RESET}"
    echo -e "${CYAN}FAH_USE_SYSTEM_SOUND${RESET}  Default: ${GREEN}0${RESET} (0=custom, 1=system)"
    echo ""
    echo -e "${YELLOW}To customize, add to your ~/.zshrc:${RESET}"
    echo -e '  export FAIL_SOUND_PATH="$HOME/.sounds/my-sound.mp3"'
    echo -e '  # OR use system sounds:'
    echo -e '  export FAH_USE_SYSTEM_SOUND=1'
    echo ""
}

# ============================================================================
# Symlink Setup
# ============================================================================

setup_symlink() {
    local plugin_name="fah-zsh-plugin"
    local plugin_repo_dir="$(cd "$(dirname "$0")" && pwd)"
    local zshrc="$HOME/.zshrc"

    echo -e "${BLUE}Setting up symbolic link for $plugin_name...${RESET}\n"

    # Determine target plugins directory
    local plugins_dir
    if [[ -n "${ZSH_CUSTOM:-}" ]]; then
        plugins_dir="${ZSH_CUSTOM}/plugins"
    elif [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
        plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    else
        # Fallback: use a generic ZSH plugins directory
        plugins_dir="$HOME/.zsh/plugins"
    fi

    local symlink_target="$plugins_dir/$plugin_name"

    # Create the plugins directory if it doesn't exist
    if [[ ! -d "$plugins_dir" ]]; then
        echo -e "${BLUE}Creating plugins directory: $plugins_dir${RESET}"
        mkdir -p "$plugins_dir"
        echo -e "${GREEN}✓ Plugins directory created${RESET}\n"
    fi

    # Remove stale symlink or old directory at the target path
    if [[ -L "$symlink_target" ]]; then
        echo -e "${YELLOW}⚠️  Removing existing symlink at $symlink_target${RESET}"
        rm "$symlink_target"
    elif [[ -d "$symlink_target" ]]; then
        echo -e "${RED}⚠️  Error: A non-symlink directory already exists at $symlink_target${RESET}"
        echo -e "${YELLOW}Please remove it manually and re-run this option.${RESET}\n"
        return 1
    fi

    # Create the symbolic link
    ln -s "$plugin_repo_dir" "$symlink_target"
    echo -e "${GREEN}✓ Symlink created:${RESET}"
    echo -e "  ${CYAN}$symlink_target${RESET} -> ${CYAN}$plugin_repo_dir${RESET}\n"

    # Determine how to activate the plugin persistently in .zshrc
    if grep -q 'source.*oh-my-zsh.sh' "$zshrc" 2>/dev/null; then
        # oh-my-zsh is in use — add plugin to plugins=() array if not present
        if grep -qE "^plugins=\(" "$zshrc" 2>/dev/null; then
            if grep -qE "\b$plugin_name\b" "$zshrc" 2>/dev/null; then
                echo -e "${GREEN}✓ Plugin already listed in plugins=() in ~/.zshrc${RESET}\n"
            else
                # Insert plugin name into the existing plugins=(...) array
                sed -i '' "/^plugins=(/ s/)$/ $plugin_name)/" "$zshrc"
                echo -e "${GREEN}✓ Added '$plugin_name' to plugins=() in ~/.zshrc${RESET}\n"
            fi
        else
            echo -e "${YELLOW}⚠️  oh-my-zsh detected but no plugins=() array found.${RESET}"
            echo -e "${YELLOW}Add the following line to your ~/.zshrc manually:${RESET}"
            echo -e "  ${CYAN}plugins=(... $plugin_name)${RESET}\n"
        fi
    else
        # Plain ZSH — source the plugin file directly (same as install_plugin)
        if grep -q "$plugin_name" "$zshrc" 2>/dev/null; then
            echo -e "${GREEN}✓ Plugin already sourced in ~/.zshrc${RESET}\n"
        else
            echo "" >> "$zshrc"
            echo "# fah-zsh-plugin - Play sounds on command failure" >> "$zshrc"
            echo "source \"$symlink_target/$plugin_name.plugin.zsh\"" >> "$zshrc"
            echo -e "${GREEN}✓ Plugin source line added to ~/.zshrc${RESET}"
            echo -e "${YELLOW}⚠️  Restart your terminal or run: source ~/.zshrc${RESET}\n"
        fi
    fi

    echo -e "${BOLD}${GREEN}✓ Symlink setup complete — plugin will load on every new shell session.${RESET}\n"
}

install_plugin() {
    local zshrc="$HOME/.zshrc"
    local plugin_path="$(cd "$(dirname "$0")" && pwd)/fah.plugin.zsh"
    
    echo -e "${BLUE}Installing plugin to ~/.zshrc...${RESET}\n"
    
    # Check if already installed
    if grep -q "fah.plugin.zsh" "$zshrc" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Plugin already appears to be installed in ~/.zshrc${RESET}\n"
        return 0
    fi
    
    # Add source line to .zshrc
    echo "" >> "$zshrc"
    echo "# fah-zsh-plugin - Play sounds on command failure" >> "$zshrc"
    echo "source \"$plugin_path\"" >> "$zshrc"
    
    echo -e "${GREEN}✓ Plugin added to ~/.zshrc${RESET}"
    echo -e "${YELLOW}⚠️  Restart your terminal or run: source ~/.zshrc${RESET}\n"
}

show_help() {
    echo -e "${BOLD}About fah-zsh-plugin:${RESET}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "This plugin plays a sound effect whenever a command"
    echo -e "fails (returns a non-zero exit code)."
    echo ""
    echo -e "${BOLD}Features:${RESET}"
    echo -e "  • Automatic failure detection via ZSH hooks"
    echo -e "  • Custom or system sounds"
    echo -e "  • Non-blocking audio playback"
    echo -e "  • Configurable sound paths"
    echo ""
    echo -e "${BOLD}Usage:${RESET}"
    echo -e "  Just use your terminal normally! When a command"
    echo -e "  fails, you'll hear the configured sound."
    echo ""
    echo -e "${BOLD}Repository:${RESET}"
    echo -e "  https://github.com/d-xorg/fah-zsh-plugin"
    echo ""
}

# ============================================================================
# Interactive Menu
# ============================================================================

show_menu() {
    echo -e "${BOLD}Installation Options:${RESET}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${GREEN}1)${RESET} 🚀 Quick Install (recommended)"
    echo -e "  ${GREEN}2)${RESET} 📁 Create sound directory only"
    echo -e "  ${GREEN}3)${RESET} ⬇️  Download sample sound"
    echo -e "  ${GREEN}4)${RESET} 🔊 Test sound playback"
    echo -e "  ${GREEN}5)${RESET} ⚙️  Show configuration options"
    echo -e "  ${GREEN}6)${RESET} 📦 Add plugin to ~/.zshrc"
    echo -e "  ${GREEN}7)${RESET} ❓ Help & Information"
    echo -e "  ${GREEN}8)${RESET} � Create symlink in ZSH plugins folder"
    echo -e "  ${GREEN}9)${RESET} �🚪 Exit"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

quick_install() {
    echo -e "${BOLD}${GREEN}Starting Quick Installation...${RESET}\n"
    
    setup_sound_directory
    download_sample_sound
    setup_symlink
    
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${GREEN}✓ Installation Complete!${RESET}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${RESET}\n"
    
    echo -e "${YELLOW}Next steps:${RESET}"
    echo -e "  1. Restart your terminal or run: ${CYAN}source ~/.zshrc${RESET}"
    echo -e "  2. Try a failing command: ${CYAN}ls /nonexistent${RESET}"
    echo -e "  3. Enjoy your audio feedback! 🎵\n"
    
    read -p "Press Enter to continue..." -r
}

# ============================================================================
# Main Menu Loop
# ============================================================================

main() {
    show_banner
    check_requirements
    
    while true; do
        show_menu
        read -p "$(echo -e ${CYAN}Select an option [1-9]:${RESET} )" choice
        echo ""
        
        case $choice in
            1)
                quick_install
                show_banner
                ;;
            2)
                setup_sound_directory
                read -p "Press Enter to continue..." -r
                show_banner
                ;;
            3)
                download_sample_sound
                read -p "Press Enter to continue..." -r
                show_banner
                ;;
            4)
                test_sound
                read -p "Press Enter to continue..." -r
                show_banner
                ;;
            5)
                show_configuration
                read -p "Press Enter to continue..." -r
                show_banner
                ;;
            6)
                install_plugin
                read -p "Press Enter to continue..." -r
                show_banner
                ;;
            7)
                show_help
                read -p "Press Enter to continue..." -r
                show_banner
                ;;
            8)
                setup_symlink
                read -p "Press Enter to continue..." -r
                show_banner
                ;;
            9)
                echo -e "${GREEN}Thanks for using fah-zsh-plugin! 👋${RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-9.${RESET}\n"
                sleep 2
                show_banner
                ;;
        esac
    done
}

# ============================================================================
# Entry Point
# ============================================================================

# Run main function
main
