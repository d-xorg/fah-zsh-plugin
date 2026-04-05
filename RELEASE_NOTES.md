# Release Notes

## v1.2.0 - Success Sound 🎉

**Release Date:** March 19, 2026

### ✨ New Features

#### Success Sound
- **Audio feedback on success**: FAH now plays a sound when a watched command exits with code `0`
- **Default sound**: "Mission Success" (GTA) — downloaded automatically by `fah-init`
- **Same watch list**: `FAH_WATCH_COMMANDS` controls both fail and success triggers
- **Independent toggle**: `FAH_SUCCESS_ENABLED` (default `1`) — disable success sound without affecting fail sound
- **Custom sound support**: Point `FAH_SUCCESS_SOUND_FILE` to any audio file
- **Fallback**: Double terminal bell when no audio file is present (distinct from the single-bell fail fallback)

#### `fah-init` Downloads Both Sounds
- Now downloads `assets/fah.mp3` (fail) **and** `assets/success.mp3` (success) in one command
- Skips any file already installed — safe to re-run
- Re-detects both sound files immediately after download

#### `fah-test` Two-Step Test
- Tests both sounds in labeled steps: `[1/2] Fail sound` / `[2/2] Success sound`
- Reports the file path played for each step
- Shows a helpful hint if a sound file is missing or the feature is disabled

#### `fah-status` Shows Success Sound State
- New `Success sound: enabled/disabled` line
- New `Success sound file: <path or fallback>` line

### ⚙️ New Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FAH_SUCCESS_ENABLED` | `1` | Enable (`1`) or disable (`0`) the success sound |
| `FAH_SUCCESS_SOUND_FILE` | Auto-detected | Path to custom success sound file |

```zsh
# Disable success sound (keep fail sound active)
export FAH_SUCCESS_ENABLED=0

# Use a custom success sound
export FAH_SUCCESS_SOUND_FILE="$HOME/.sounds/tadaa.mp3"
```

---

## v1.1.0 - Command Watch List 🎯

**Release Date:** March 18, 2026

### ✨ New Features

#### Command Watch List (`FAH_WATCH_COMMANDS`)
- **Selective Triggering**: Sound now only plays when the failed command matches a pattern in `FAH_WATCH_COMMANDS`
- **Glob Pattern Matching**: Patterns use zsh glob syntax — e.g. `"npm run*"`, `"make*"`, `"pytest*"`
- **Use `"*"` to match all commands** and restore the v1.0.0 behavior of triggering on every failure
- **Empty by default** — no commands trigger sound until patterns are added

#### `fah-watch` Command
Manage the watch list interactively at runtime:

| Subcommand | Description |
|---|---|
| `fah-watch list` | Show all current patterns |
| `fah-watch add <pattern>` | Add a glob pattern (e.g. `"npm run*"`) |
| `fah-watch remove <pattern>` | Remove a specific pattern |
| `fah-watch clear` | Remove all patterns |

```zsh
# Add patterns to the watch list
fah-watch add "npm run*"
fah-watch add "make*"
fah-watch add "pytest*"

# Trigger on ALL failed commands (restores v1.0.0 behavior)
fah-watch add "*"

# View the current watch list
fah-watch list

# Remove a specific pattern
fah-watch remove "make*"

# Clear all patterns
fah-watch clear
```

#### `.zshrc` Configuration
Patterns can also be set statically in `.zshrc`:

```zsh
# Trigger on all commands
FAH_WATCH_COMMANDS=("*")

# Or on specific commands only
FAH_WATCH_COMMANDS=("npm run*" "make*" "pytest*" "cargo*")
```

### ⚠️ Breaking Change

The default behavior has changed from v1.0.0:

- **v1.0.0**: Sound played on **every** failed command
- **v1.1.0**: Sound only plays when the failed command **matches a pattern** in `FAH_WATCH_COMMANDS`

To restore the previous behavior, add `"*"` to the watch list:

```zsh
fah-watch add "*"
# or in .zshrc:
FAH_WATCH_COMMANDS=("*")
```

---

## v1.0.0 - Initial Release 🎉

**Release Date:** March 3, 2026

### 🎌 Introduction

We're excited to announce the first release of **FAH** (Failure Audio Handler) - an oh-my-zsh plugin that brings the iconic "FAHHHHH" meme sound to your terminal! Now you'll never miss when a command fails.

### ✨ Features

#### Core Functionality
- **Audio Feedback on Failures**: Automatically plays sound when commands exit with non-zero status
- **Smart Detection**: Only triggers on actual command failures, not on empty prompts or terminal actions
- **Cross-Platform Support**: Works seamlessly on macOS and Linux

#### Audio System
- **Multiple Audio Backends**: 
  - macOS: `afplay` with volume control
  - Linux: `paplay`, `aplay`, `ffplay`, `mpv`, `vlc`
  - Fallback: System beep via `tput bel`
- **Intelligent Fallback Chain**: Automatically tries available audio players
- **Custom Sound Support**: Use your own audio files or download the default "FAHHHHH" sound

#### Configuration Options
- **Enable/Disable Toggle**: Easy on/off switch via `FAH_ENABLED`
- **Rate Limiting**: Anti-spam protection (default: 800ms between sounds)
- **Volume Control**: Adjustable volume for supported players
- **Configurable Sound File Path**: Point to any audio file you prefer

#### User Experience
- **One-Command Setup**: `fah-init` downloads the default sound file
- **Safe Loading**: Won't break shell startup even if audio tools are missing
- **Helper Commands**:
  - `fah-enable` / `fah-disable`: Toggle plugin on/off
  - `fah-status`: Check current configuration
  - `fah-test`: Test the sound playback
  - `fah-init`: Download/update sound file

#### Developer Features
- **Comprehensive Documentation**: Detailed README with installation and usage instructions
- **Installation Script**: Automated `install.sh` for quick setup
- **Configurable Defaults**: All settings can be overridden in `.zshrc`

### 📦 What's Included

- `fah.plugin.zsh` - Main plugin file (445 lines)
- `README.md` - Comprehensive documentation (429 lines)
- `install.sh` - Automated installation script
- `.gitignore` - Git ignore configuration
- `assets/` - Directory for sound files

### 🚀 Getting Started

```bash
# Clone the plugin
git clone https://github.com/d-xorg/fah-zsh-plugin ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fah

# Add to your .zshrc plugins list
plugins=(... fah)

# Download the sound file
fah-init

# Reload your shell
source ~/.zshrc
```

### 🎯 Use Cases

- Monitor long-running commands without watching the terminal
- Get instant audio feedback when multitasking
- Add personality and humor to your development workflow
- Know immediately when builds or tests fail

### 📝 Requirements

- oh-my-zsh
- zsh (interactive shell)
- At least one audio player (afplay, paplay, aplay, ffplay, mpv, vlc, or tput)

### 🙏 Credits

Inspired by the legendary "FAHHHHH" meme that has become a staple of internet culture.

---

**Full Changelog**: Initial release
