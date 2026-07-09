#!/usr/bin/env zsh
# ==============================================================================
# fah.plugin.zsh - Failure Audio Handler for oh-my-zsh
# ==============================================================================
# Description: Play a sound when the previous command exits with non-zero status
# License: MIT
# Repository: https://github.com/romajs/fah-zsh-plugin
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

# Watch list: array of glob patterns — only matching commands trigger the sound
# Empty array = no commands trigger sound
# Example: FAH_WATCH_COMMANDS=("npm run*" "make*")
# Use "*" to match all commands (restores pre-watch-list behavior)
typeset -ga FAH_WATCH_COMMANDS

# Ignore list: array of glob patterns — matching commands are excluded from triggering sound
# Takes precedence over FAH_WATCH_COMMANDS
# Example: FAH_IGNORE_COMMANDS=("npm install*" "npm run dev" "npm run start")
typeset -ga FAH_IGNORE_COMMANDS

# Enable/disable success sound (1=enabled, 0=disabled)
typeset -g FAH_SUCCESS_ENABLED="${FAH_SUCCESS_ENABLED:-1}"

# Path to success sound file (auto-detected if not set)
typeset -g FAH_SUCCESS_SOUND_FILE="${FAH_SUCCESS_SOUND_FILE:-}"

# ==============================================================================
# Internal State Variables
# ==============================================================================

# Resolve plugin directory robustly
typeset -g _FAH_PLUGIN_DIR="${${(%):-%x}:A:h}"

# Track if any command has been executed (prevents first-prompt false triggers)
typeset -g _FAH_COMMAND_EXECUTED=0

# Last play timestamp for rate limiting
typeset -g _FAH_LAST_PLAY_TIME=0

# Last executed command string (captured by preexec, consumed by precmd)
typeset -g _FAH_LAST_COMMAND=""

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

_fah_detect_success_sound_file() {
    # If user provided a custom success sound file, use it
    if [[ -n "$FAH_SUCCESS_SOUND_FILE" ]] && [[ -f "$FAH_SUCCESS_SOUND_FILE" ]]; then
        return 0
    fi

    # Try bundled success sound file in plugin assets directory
    local candidates=(
        "$_FAH_PLUGIN_DIR/assets/success.mp3"
        "$_FAH_PLUGIN_DIR/assets/success.wav"
        "$_FAH_PLUGIN_DIR/assets/success.aiff"
    )

    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            FAH_SUCCESS_SOUND_FILE="$candidate"
            return 0
        fi
    done

    # No success sound file found; will use fallback beep
    FAH_SUCCESS_SOUND_FILE=""
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

_fah_play_fallback_success_beep() {
    # Two quick bells to distinguish success from the single-bell fail fallback
    if command -v tput &>/dev/null; then
        tput bel 2>/dev/null
        sleep 0.12 2>/dev/null
        tput bel 2>/dev/null
    else
        print -n '\a\a'
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
# Play Success Sound
# ==============================================================================

_fah_play_success_sound() {
    # Don't play if disabled
    [[ "$FAH_ENABLED" -eq 1 ]] || return 0
    [[ "$FAH_SUCCESS_ENABLED" -eq 1 ]] || return 0

    # Rate limiting
    _fah_should_play || return 0

    # If no player detected, try fallback beep
    if [[ -z "$_FAH_PLAYER" ]]; then
        _fah_play_fallback_success_beep
        return 0
    fi

    # If no success sound file, try fallback beep
    if [[ -z "$FAH_SUCCESS_SOUND_FILE" ]] || [[ ! -f "$FAH_SUCCESS_SOUND_FILE" ]]; then
        _fah_play_fallback_success_beep
        return 0
    fi

    # Play sound based on detected player
    case "$_FAH_PLAYER" in
        afplay)
            if [[ -n "$FAH_VOLUME" ]]; then
                afplay -v "$FAH_VOLUME" "$FAH_SUCCESS_SOUND_FILE" &>/dev/null &!
            else
                afplay "$FAH_SUCCESS_SOUND_FILE" &>/dev/null &!
            fi
            ;;
        paplay)
            if [[ -n "$FAH_VOLUME" ]]; then
                local vol="$FAH_VOLUME"
                if (( $(echo "$vol < 2" | bc -l 2>/dev/null || echo 1) )); then
                    vol=$(( int(vol * 65536) ))
                fi
                paplay --volume="$vol" "$FAH_SUCCESS_SOUND_FILE" &>/dev/null &!
            else
                paplay "$FAH_SUCCESS_SOUND_FILE" &>/dev/null &!
            fi
            ;;
        aplay)
            aplay -q "$FAH_SUCCESS_SOUND_FILE" &>/dev/null &!
            ;;
        ffplay)
            ffplay -nodisp -autoexit -v quiet "$FAH_SUCCESS_SOUND_FILE" &>/dev/null &!
            ;;
        *)
            _fah_play_fallback_success_beep
            ;;
    esac
}

# ==============================================================================
# Watch List Matching
# ==============================================================================

_fah_command_in_watchlist() {
    # Check if the given command string matches any pattern in FAH_WATCH_COMMANDS
    # Returns 0 (true) if matched, 1 (false) if no match or list is empty
    #
    # Matching uses zsh glob via unquoted RHS of [[ == ]], so patterns like
    # "npm run*" or "make *" work naturally without any external tools.

    local cmd="$1"

    # Empty watch list — no commands trigger sound
    (( ${#FAH_WATCH_COMMANDS[@]} == 0 )) && return 1

    local pattern
    for pattern in "${FAH_WATCH_COMMANDS[@]}"; do
        # ${~pattern} forces zsh to glob-expand the variable value so that
        # wildcards like * in "npm*" are treated as pattern characters, not literals
        [[ "$cmd" == ${~pattern} ]] && return 0
    done

    return 1
}

_fah_command_in_ignorelist() {
    # Check if the given command string matches any pattern in FAH_IGNORE_COMMANDS
    # Returns 0 (true) if matched (should be ignored), 1 (false) otherwise

    local cmd="$1"

    # Empty ignore list — nothing is excluded
    (( ${#FAH_IGNORE_COMMANDS[@]} == 0 )) && return 1

    local pattern
    for pattern in "${FAH_IGNORE_COMMANDS[@]}"; do
        [[ "$cmd" == ${~pattern} ]] && return 0
    done

    return 1
}

# ==============================================================================
# Precmd Hook - Triggered before each prompt
# ==============================================================================

_fah_precmd() {
    local exit_code=$?
    
    # Only trigger if:
    # 1. A command was actually executed (not just Enter key)
    # 2. Not during completion (check if we're not in ZLE widget context)
    
    if [[ "$_FAH_COMMAND_EXECUTED" -eq 1 ]]; then
        # Avoid playing during completion menus (heuristic check)
        # CONTEXT is set during completion; WIDGET contains widget name during ZLE
        if [[ -z "$CONTEXT" ]] && [[ -z "$WIDGET" ]]; then
            if ! _fah_command_in_ignorelist "$_FAH_LAST_COMMAND"; then
                if [[ $exit_code -ne 0 ]]; then
                    _fah_command_in_watchlist "$_FAH_LAST_COMMAND" && _fah_play_sound
                elif [[ $exit_code -eq 0 ]]; then
                    _fah_command_in_watchlist "$_FAH_LAST_COMMAND" && _fah_play_success_sound
                fi
            fi
        fi
    fi

    # Reset command execution flag and last command
    typeset -g _FAH_COMMAND_EXECUTED=0
    typeset -g _FAH_LAST_COMMAND=""
}

# ==============================================================================
# Preexec Hook - Triggered before each command execution
# ==============================================================================

_fah_preexec() {
    # Mark that a command is being executed
    typeset -g _FAH_COMMAND_EXECUTED=1
    # Capture command string for watch list matching
    typeset -g _FAH_LAST_COMMAND="$1"
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
    echo "  Enabled:              $([ "$FAH_ENABLED" -eq 1 ] && echo "yes" || echo "no")"
    echo "  Player:               ${_FAH_PLAYER:-none (fallback beep)}"
    echo "  Fail sound file:      ${FAH_SOUND_FILE:-none (fallback beep)}"
    echo "  Success sound:        $([ "$FAH_SUCCESS_ENABLED" -eq 1 ] && echo "enabled" || echo "disabled")"
    echo "  Success sound file:   ${FAH_SUCCESS_SOUND_FILE:-none (fallback double-beep)}"
    echo "  Min interval:         ${FAH_MIN_INTERVAL_MS}ms"
    echo "  Volume:               ${FAH_VOLUME:-default}"
    echo "  Watch list:"
    if (( ${#FAH_WATCH_COMMANDS[@]} == 0 )); then
        echo "    (empty — no commands trigger sound)"
    else
        local i=1
        local pattern
        for pattern in "${FAH_WATCH_COMMANDS[@]}"; do
            echo "    $i) $pattern"
            (( i++ ))
        done
    fi
    echo "  Ignore list:"
    if (( ${#FAH_IGNORE_COMMANDS[@]} == 0 )); then
        echo "    (empty — no commands are excluded)"
    else
        local i=1
        local pattern
        for pattern in "${FAH_IGNORE_COMMANDS[@]}"; do
            echo "    $i) $pattern"
            (( i++ ))
        done
    fi
}

fah-watch() {
    local subcmd="${1:-list}"

    case "$subcmd" in
        list)
            echo "FAH Watch List:"
            if (( ${#FAH_WATCH_COMMANDS[@]} == 0 )); then
                echo "  (empty — no commands trigger sound)"
                echo ""
                echo "Add patterns with: fah-watch add <pattern>"
                echo "Example:           fah-watch add \"npm run*\""
            else
                local i=1
                local pattern
                for pattern in "${FAH_WATCH_COMMANDS[@]}"; do
                    echo "  $i) $pattern"
                    (( i++ ))
                done
            fi
            ;;
        add)
            if [[ -z "$2" ]]; then
                echo "Usage: fah-watch add <glob-pattern>" >&2
                echo "Example: fah-watch add \"npm run*\"" >&2
                return 1
            fi
            local new_pattern="$2"
            # Check for duplicate
            local pattern
            for pattern in "${FAH_WATCH_COMMANDS[@]}"; do
                if [[ "$pattern" == "$new_pattern" ]]; then
                    echo "⚠  Pattern already in watch list: $new_pattern"
                    return 0
                fi
            done
            FAH_WATCH_COMMANDS+=("$new_pattern")
            echo "✓ Added to watch list: $new_pattern"
            ;;
        remove)
            if [[ -z "$2" ]]; then
                echo "Usage: fah-watch remove <glob-pattern>" >&2
                return 1
            fi
            local target="$2"
            local new_list=()
            local found=0
            local pattern
            for pattern in "${FAH_WATCH_COMMANDS[@]}"; do
                if [[ "$pattern" == "$target" ]]; then
                    found=1
                else
                    new_list+=("$pattern")
                fi
            done
            if (( found )); then
                FAH_WATCH_COMMANDS=("${new_list[@]}")
                echo "✓ Removed from watch list: $target"
            else
                echo "⚠  Pattern not found in watch list: $target" >&2
                return 1
            fi
            ;;
        clear)
            FAH_WATCH_COMMANDS=()
            echo "✓ Watch list cleared — no commands will trigger sound"
            ;;
        *)
            echo "Usage: fah-watch <list|add|remove|clear>" >&2
            echo "  list             List current patterns" >&2
            echo "  add <pattern>    Add a glob pattern (e.g. \"npm run*\")" >&2
            echo "  remove <pattern> Remove a pattern" >&2
            echo "  clear            Remove all patterns" >&2
            return 1
            ;;
    esac
}

fah-ignore() {
    local subcmd="${1:-list}"

    case "$subcmd" in
        list)
            echo "FAH Ignore List:"
            if (( ${#FAH_IGNORE_COMMANDS[@]} == 0 )); then
                echo "  (empty — no commands are excluded)"
                echo ""
                echo "Add patterns with: fah-ignore add <pattern>"
                echo "Example:           fah-ignore add \"npm install*\""
            else
                local i=1
                local pattern
                for pattern in "${FAH_IGNORE_COMMANDS[@]}"; do
                    echo "  $i) $pattern"
                    (( i++ ))
                done
            fi
            ;;
        add)
            if [[ -z "$2" ]]; then
                echo "Usage: fah-ignore add <glob-pattern>" >&2
                echo "Example: fah-ignore add \"npm install*\"" >&2
                return 1
            fi
            local new_pattern="$2"
            local pattern
            for pattern in "${FAH_IGNORE_COMMANDS[@]}"; do
                if [[ "$pattern" == "$new_pattern" ]]; then
                    echo "⚠  Pattern already in ignore list: $new_pattern"
                    return 0
                fi
            done
            FAH_IGNORE_COMMANDS+=("$new_pattern")
            echo "✓ Added to ignore list: $new_pattern"
            ;;
        remove)
            if [[ -z "$2" ]]; then
                echo "Usage: fah-ignore remove <glob-pattern>" >&2
                return 1
            fi
            local target="$2"
            local new_list=()
            local found=0
            local pattern
            for pattern in "${FAH_IGNORE_COMMANDS[@]}"; do
                if [[ "$pattern" == "$target" ]]; then
                    found=1
                else
                    new_list+=("$pattern")
                fi
            done
            if (( found )); then
                FAH_IGNORE_COMMANDS=("${new_list[@]}")
                echo "✓ Removed from ignore list: $target"
            else
                echo "⚠  Pattern not found in ignore list: $target" >&2
                return 1
            fi
            ;;
        clear)
            FAH_IGNORE_COMMANDS=()
            echo "✓ Ignore list cleared — no commands are excluded"
            ;;
        *)
            echo "Usage: fah-ignore <list|add|remove|clear>" >&2
            echo "  list             List current ignore patterns" >&2
            echo "  add <pattern>    Add a glob pattern (e.g. \"npm install*\")" >&2
            echo "  remove <pattern> Remove a pattern" >&2
            echo "  clear            Remove all patterns" >&2
            return 1
            ;;
    esac
}

fah-test() {
    echo "Testing FAH plugin..."

    # Check if we have a player
    if [[ -z "$_FAH_PLAYER" ]]; then
        echo ""
        echo "⚠️  Could not play sound yet."
        echo "   No audio player detected."
        echo ""
        return 1
    fi

    # --- Fail sound ---
    echo ""
    echo "[1/2] Fail sound:"
    if [[ -z "$FAH_SOUND_FILE" ]] || [[ ! -f "$FAH_SOUND_FILE" ]]; then
        echo "  ⚠️  No fail sound file detected — run 'fah-init' then omz reload"
    else
        echo "  Playing: $FAH_SOUND_FILE"
        _fah_play_sound
        echo "  ✓ done"
    fi

    # --- Success sound ---
    echo ""
    echo "[2/2] Success sound:"
    if [[ "$FAH_SUCCESS_ENABLED" -ne 1 ]]; then
        echo "  (disabled — set FAH_SUCCESS_ENABLED=1 to enable)"
    elif [[ -z "$FAH_SUCCESS_SOUND_FILE" ]] || [[ ! -f "$FAH_SUCCESS_SOUND_FILE" ]]; then
        echo "  ⚠️  No success sound file detected — run 'fah-init' then omz reload"
        echo "  Playing fallback double-beep instead..."
        _fah_play_fallback_success_beep
    else
        echo "  Playing: $FAH_SUCCESS_SOUND_FILE"
        _fah_play_success_sound
        echo "  ✓ done"
    fi

    echo ""
    echo "✓ FAH test completed."
}

fah-init() {
    # Download and install the default FAH sound files (fail + success)
    # This command creates the assets directory and downloads the sounds

    local assets_dir="${_FAH_PLUGIN_DIR}/assets"
    local sound_file="${assets_dir}/fah.mp3"
    local sound_url="https://www.myinstants.com/media/sounds/actually-good-fahhhh-sfx.mp3"
    local success_file="${assets_dir}/success.mp3"
    local success_url="https://www.myinstants.com/media/sounds/mission-success.mp3"

    # Check if both sound files already exist
    if [[ -f "$sound_file" ]] && [[ -f "$success_file" ]]; then
        echo "✓ FAH sounds already installed:"
        echo "  Fail:    $sound_file"
        echo "  Success: $success_file"
        echo ""
        echo "Run 'fah-test' to verify they work."
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
        echo "  Please install curl or wget to download the sound files." >&2
        return 1
    fi

    # Helper: download a single file, skip if already present
    # Usage: _fah_init_download <label> <url> <dest>
    # Returns 0 on success (or already present), 1 on failure
    _fah_init_download() {
        local label="$1" url="$2" dest="$3"
        if [[ -f "$dest" ]]; then
            echo "  (skipping $label — already installed)"
            return 0
        fi
        echo "  Downloading $label..."
        local ok=0
        if [[ "$downloader" == "curl" ]]; then
            curl -fsSL -o "$dest" "$url" 2>/dev/null && ok=1
        else
            wget -q -O "$dest" "$url" 2>/dev/null && ok=1
        fi
        if [[ $ok -eq 1 ]] && [[ -f "$dest" ]]; then
            return 0
        else
            echo "  ✗ Failed to download $label" >&2
            echo "    URL:    $url" >&2
            echo "    Target: $dest" >&2
            [[ -f "$dest" ]] && rm -f "$dest"
            return 1
        fi
    }

    echo "Downloading FAH sound files..."
    echo ""

    local fail_ok=0 success_ok=0

    _fah_init_download "fail sound (fah.mp3)" "$sound_url" "$sound_file" && fail_ok=1
    _fah_init_download "success sound (mission-success.mp3)" "$success_url" "$success_file" && success_ok=1

    unfunction _fah_init_download 2>/dev/null

    echo ""
    if [[ $fail_ok -eq 1 ]] || [[ $success_ok -eq 1 ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        [[ $fail_ok -eq 1 ]]    && echo "✓ Fail sound installed:    $sound_file"
        [[ $success_ok -eq 1 ]] && echo "✓ Success sound installed: $success_file"
        echo ""
        echo "To ensure the plugin picks up the new sound files run:"
        echo ""
        echo "    omz reload"
        echo ""
        echo "or restart your terminal."
        echo ""
        echo "Then test with: fah-test"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Re-detect sound files so they're immediately available
        _fah_detect_sound_file
        _fah_detect_success_sound_file

        # Return error only if BOTH downloads failed
        [[ $fail_ok -eq 0 ]] && [[ $success_ok -eq 0 ]] && return 1
        return 0
    else
        echo "✗ Error: All downloads failed." >&2
        return 1
    fi
}

# ==============================================================================
# Plugin Initialization
# ==============================================================================

# Detect audio player
_fah_detect_player

# Detect fail sound file
_fah_detect_sound_file

# Detect success sound file
_fah_detect_success_sound_file

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
    unfunction fah-on fah-off fah-toggle fah-status fah-watch fah-test fah-init 2>/dev/null
    unfunction _fah_precmd _fah_preexec _fah_play_sound _fah_play_success_sound 2>/dev/null
    unfunction _fah_detect_player _fah_detect_sound_file _fah_detect_success_sound_file 2>/dev/null
    unfunction _fah_should_play _fah_play_fallback_beep _fah_play_fallback_success_beep _fah_command_in_watchlist 2>/dev/null
    unfunction _fah_unload 2>/dev/null

    # Unset variables
    unset _FAH_PLUGIN_DIR _FAH_COMMAND_EXECUTED _FAH_LAST_PLAY_TIME _FAH_PLAYER _FAH_LAST_COMMAND
    unset FAH_ENABLED FAH_SOUND_FILE FAH_MIN_INTERVAL_MS FAH_VOLUME FAH_WATCH_COMMANDS
    unset FAH_SUCCESS_ENABLED FAH_SUCCESS_SOUND_FILE
}
