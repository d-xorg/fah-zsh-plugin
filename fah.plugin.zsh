#!/usr/bin/env zsh
# ==============================================================================
# fah.plugin.zsh - Failure Audio Handler for oh-my-zsh
# ==============================================================================
# Description: Play a sound when the previous command exits with non-zero status
# License: MIT
# Repository: https://github.com/d-xorg/fah-zsh-plugin
# ==============================================================================

# Only load in interactive shells to avoid breaking scripts
[[ -o interactive ]] || return 0

# ==============================================================================
# Configuration Variables (can be set in .zshrc before loading plugin)
# ==============================================================================

# Enable/disable the plugin (1=enabled, 0=disabled)
typeset -g FAH_ENABLED="${FAH_ENABLED:-1}"

# Path to sound file (auto-detected if not set)
typeset -g FAH_SOUND_FILE="${FAH_SOUND_FILE:-}"

# Minimum interval between sounds in milliseconds (anti-spam)
typeset -g FAH_MIN_INTERVAL_MS="${FAH_MIN_INTERVAL_MS:-800}"

# Volume level (0.0 to 1.0 for afplay, 0-100 for paplay; ignored by others)
typeset -g FAH_VOLUME="${FAH_VOLUME:-}"

# ==============================================================================
# Internal State Variables
# ==============================================================================

# Resolve plugin directory robustly
typeset -g _FAH_PLUGIN_DIR="${${(%):-%x}:A:h}"

# Track if any command has been executed (prevents first-prompt false triggers)
typeset -g _FAH_COMMAND_EXECUTED=0

# Last play timestamp for rate limiting
typeset -g _FAH_LAST_PLAY_TIME=0

# Detected audio player command
typeset -g _FAH_PLAYER=""

# ==============================================================================
# Audio Player Detection
# ==============================================================================

_fah_detect_player() {
    # Detect available audio player based on platform and availability
    # Priority: macOS (afplay) > Linux (paplay > aplay > ffplay)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v afplay &>/dev/null; then
            _FAH_PLAYER="afplay"
            return 0
        fi
    else
        # Linux or other Unix
        if command -v paplay &>/dev/null; then
            _FAH_PLAYER="paplay"
            return 0
        elif command -v aplay &>/dev/null; then
            _FAH_PLAYER="aplay"
            return 0
        elif command -v ffplay &>/dev/null; then
            _FAH_PLAYER="ffplay"
            return 0
        fi
    fi
    
    # No player found; plugin will work but won't play sounds
    _FAH_PLAYER=""
    return 1
}

# ==============================================================================
# Sound File Detection
# ==============================================================================

_fah_detect_sound_file() {
    # If user provided a custom sound file, use it
    if [[ -n "$FAH_SOUND_FILE" ]] && [[ -f "$FAH_SOUND_FILE" ]]; then
        return 0
    fi
    
    # Try bundled sound file in plugin assets directory
    local candidates=(
        "$_FAH_PLUGIN_DIR/assets/fah.wav"
        "$_FAH_PLUGIN_DIR/assets/fah.mp3"
        "$_FAH_PLUGIN_DIR/assets/fah.aiff"
    )
    
    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            FAH_SOUND_FILE="$candidate"
            return 0
        fi
    done
    
    # Fallback to system sounds on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local system_sounds=(
            "/System/Library/Sounds/Basso.aiff"
            "/System/Library/Sounds/Funk.aiff"
            "/System/Library/Sounds/Sosumi.aiff"
        )
        for sound in "${system_sounds[@]}"; do
            if [[ -f "$sound" ]]; then
                FAH_SOUND_FILE="$sound"
                return 0
            fi
        done
    fi
    
    # No sound file found; will use fallback beep if available
    FAH_SOUND_FILE=""
    return 1
}

# ==============================================================================
# Fallback Beep (when no audio file is available)
# ==============================================================================

_fah_play_fallback_beep() {
    # Generate a simple beep using ASCII bell character or tput
    # This is a last resort when no audio player or file is available
    
    if command -v tput &>/dev/null; then
        # Use terminal bell
        tput bel 2>/dev/null
    else
        # ASCII bell character
        print -n '\a'
    fi
}

# ==============================================================================
# Rate Limiting
# ==============================================================================

_fah_should_play() {
    # Check if enough time has passed since last play (anti-spam)
    # Returns 0 (true) if should play, 1 (false) otherwise
    
    local current_time
    
    # Use EPOCHREALTIME if available (zsh 5.1+), else fallback to SECONDS
    if [[ -n "$EPOCHREALTIME" ]]; then
        # EPOCHREALTIME is in seconds with microsecond precision
        current_time=$(( int(EPOCHREALTIME * 1000) ))
    else
        # SECONDS is coarse (integer seconds since shell start)
        current_time=$(( SECONDS * 1000 ))
    fi
    
    local time_diff=$(( current_time - _FAH_LAST_PLAY_TIME ))
    
    if (( time_diff >= FAH_MIN_INTERVAL_MS )); then
        _FAH_LAST_PLAY_TIME=$current_time
        return 0
    fi
    
    return 1
}

# ==============================================================================
# Play Sound
# ==============================================================================

_fah_play_sound() {
    # Don't play if disabled
    [[ "$FAH_ENABLED" -eq 1 ]] || return 0
    
    # Rate limiting
    _fah_should_play || return 0
    
    # If no player detected, try fallback beep
    if [[ -z "$_FAH_PLAYER" ]]; then
        _fah_play_fallback_beep
        return 0
    fi
    
    # If no sound file, try fallback beep
    if [[ -z "$FAH_SOUND_FILE" ]] || [[ ! -f "$FAH_SOUND_FILE" ]]; then
        _fah_play_fallback_beep
        return 0
    fi
    
    # Play sound based on detected player
    case "$_FAH_PLAYER" in
        afplay)
            # macOS afplay with optional volume control
            if [[ -n "$FAH_VOLUME" ]]; then
                afplay -v "$FAH_VOLUME" "$FAH_SOUND_FILE" &>/dev/null &!
            else
                afplay "$FAH_SOUND_FILE" &>/dev/null &!
            fi
            ;;
        paplay)
            # PulseAudio with optional volume control (0-100 scale)
            if [[ -n "$FAH_VOLUME" ]]; then
                # Convert 0.0-1.0 to 0-65536 scale if needed
                local vol="$FAH_VOLUME"
                if (( $(echo "$vol < 2" | bc -l 2>/dev/null || echo 1) )); then
                    vol=$(( int(vol * 65536) ))
                fi
                paplay --volume="$vol" "$FAH_SOUND_FILE" &>/dev/null &!
            else
                paplay "$FAH_SOUND_FILE" &>/dev/null &!
            fi
            ;;
        aplay)
            # ALSA player (no volume control via CLI usually)
            aplay -q "$FAH_SOUND_FILE" &>/dev/null &!
            ;;
        ffplay)
            # FFmpeg player with auto-exit
            ffplay -nodisp -autoexit -v quiet "$FAH_SOUND_FILE" &>/dev/null &!
            ;;
        *)
            # Fallback beep
            _fah_play_fallback_beep
            ;;
    esac
}

# ==============================================================================
# Precmd Hook - Triggered before each prompt
# ==============================================================================

_fah_precmd() {
    local exit_code=$?
    
    # Only trigger if:
    # 1. A command was actually executed (not just Enter key)
    # 2. The exit code is non-zero (command failed)
    # 3. Not during completion (check if we're not in ZLE widget context)
    
    if [[ "$_FAH_COMMAND_EXECUTED" -eq 1 ]] && [[ $exit_code -ne 0 ]]; then
        # Avoid playing during completion menus (heuristic check)
        # CONTEXT is set during completion; WIDGET contains widget name during ZLE
        if [[ -z "$CONTEXT" ]] && [[ -z "$WIDGET" ]]; then
            _fah_play_sound
        fi
    fi
    
    # Reset command execution flag
    typeset -g _FAH_COMMAND_EXECUTED=0
}

# ==============================================================================
# Preexec Hook - Triggered before each command execution
# ==============================================================================

_fah_preexec() {
    # Mark that a command is being executed
    typeset -g _FAH_COMMAND_EXECUTED=1
}

# ==============================================================================
# User Commands
# ==============================================================================

fah-on() {
    typeset -g FAH_ENABLED=1
    echo "✓ FAH plugin enabled"
}

fah-off() {
    typeset -g FAH_ENABLED=0
    echo "✓ FAH plugin disabled"
}

fah-toggle() {
    if [[ "$FAH_ENABLED" -eq 1 ]]; then
        fah-off
    else
        fah-on
    fi
}

fah-status() {
    echo "FAH Plugin Status:"
    echo "  Enabled: $([ "$FAH_ENABLED" -eq 1 ] && echo "yes" || echo "no")"
    echo "  Player: ${_FAH_PLAYER:-none (fallback beep)}"
    echo "  Sound file: ${FAH_SOUND_FILE:-none (fallback beep)}"
    echo "  Min interval: ${FAH_MIN_INTERVAL_MS}ms"
    echo "  Volume: ${FAH_VOLUME:-default}"
}

fah-test() {
    # Manually trigger sound playback to test the plugin
    echo "Testing FAH plugin..."
    
    # Check if we have a sound file
    if [[ -z "$FAH_SOUND_FILE" ]] || [[ ! -f "$FAH_SOUND_FILE" ]]; then
        echo ""
        echo "⚠️  Could not play sound yet."
        echo "   No sound file detected."
        echo ""
        echo "Run 'fah-init' to download the sound file, then:"
        echo "   omz reload"
        echo ""
        return 1
    fi
    
    # Check if we have a player
    if [[ -z "$_FAH_PLAYER" ]]; then
        echo ""
        echo "⚠️  Could not play sound yet."
        echo "   No audio player detected."
        echo ""
        return 1
    fi
    
    echo "Playing sound..."
    _fah_play_sound
    
    echo "✓ FAH test completed."
}

fah-init() {
    # Download and install the default FAH sound file
    # This command creates the assets directory and downloads the sound
    
    local assets_dir="${_FAH_PLUGIN_DIR}/assets"
    local sound_file="${assets_dir}/fah.mp3"
    local sound_url="https://www.myinstants.com/media/sounds/actually-good-fahhhh-sfx.mp3"
    
    # Check if sound file already exists
    if [[ -f "$sound_file" ]]; then
        echo "✓ FAH sound already installed at: $sound_file"
        echo ""
        echo "Run 'fah-test' to verify it works."
        return 0
    fi
    
    # Create assets directory if it doesn't exist
    if [[ ! -d "$assets_dir" ]]; then
        echo "Creating assets directory..."
        mkdir -p "$assets_dir" 2>/dev/null || {
            echo "✗ Error: Could not create directory: $assets_dir" >&2
            return 1
        }
    fi
    
    # Check for download tools
    local downloader=""
    if command -v curl &>/dev/null; then
        downloader="curl"
    elif command -v wget &>/dev/null; then
        downloader="wget"
    else
        echo "✗ Error: Neither curl nor wget is installed." >&2
        echo "  Please install curl or wget to download the sound file." >&2
        echo "  Alternatively, manually download from:" >&2
        echo "  $sound_url" >&2
        echo "  and save it as: $sound_file" >&2
        return 1
    fi
    
    # Download the sound file
    echo "Downloading FAH sound file..."
    
    local download_success=0
    if [[ "$downloader" == "curl" ]]; then
        # Use curl with follow redirects (-L)
        if curl -fsSL -o "$sound_file" "$sound_url" 2>/dev/null; then
            download_success=1
        fi
    elif [[ "$downloader" == "wget" ]]; then
        # Use wget with quiet mode
        if wget -q -O "$sound_file" "$sound_url" 2>/dev/null; then
            download_success=1
        fi
    fi
    
    # Check if download was successful
    if [[ $download_success -eq 1 ]] && [[ -f "$sound_file" ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✓ FAH sound installed successfully."
        echo ""
        echo "To ensure the plugin picks up the new sound file run:"
        echo ""
        echo "    omz reload"
        echo ""
        echo "or restart your terminal."
        echo ""
        echo "Then test it with: fah-test"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Re-detect sound file so it's immediately available
        _fah_detect_sound_file
        
        return 0
    else
        echo "✗ Error: Failed to download sound file." >&2
        echo "  URL: $sound_url" >&2
        echo "  Target: $sound_file" >&2
        
        # Clean up partial download
        [[ -f "$sound_file" ]] && rm -f "$sound_file"
        
        return 1
    fi
}

# ==============================================================================
# Plugin Initialization
# ==============================================================================

# Detect audio player
_fah_detect_player

# Detect sound file
_fah_detect_sound_file

# Register hooks
autoload -Uz add-zsh-hook
add-zsh-hook precmd _fah_precmd
add-zsh-hook preexec _fah_preexec

# ==============================================================================
# Cleanup Function (for unloading the plugin)
# ==============================================================================

_fah_unload() {
    # Remove hooks
    add-zsh-hook -D precmd _fah_precmd
    add-zsh-hook -D preexec _fah_preexec
    
    # Remove functions
    unfunction fah-on fah-off fah-toggle fah-status fah-test fah-init 2>/dev/null
    unfunction _fah_precmd _fah_preexec _fah_play_sound 2>/dev/null
    unfunction _fah_detect_player _fah_detect_sound_file 2>/dev/null
    unfunction _fah_should_play _fah_play_fallback_beep 2>/dev/null
    unfunction _fah_unload 2>/dev/null
    
    # Unset variables
    unset _FAH_PLUGIN_DIR _FAH_COMMAND_EXECUTED _FAH_LAST_PLAY_TIME _FAH_PLAYER
    unset FAH_ENABLED FAH_SOUND_FILE FAH_MIN_INTERVAL_MS FAH_VOLUME
}
