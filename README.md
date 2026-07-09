
# <img src="assets/fah-icon.png" alt="FAH ZSH Plugin icon" width="30" height="30"> FAHHHHHHHH

> 🎌 **The meme "FAHHHHH" now in your terminal!**<br>
> When your commands fail, you'll know it. Instantly. Audibly. Memorably.<br>
> When they succeed, now you'll know that too. 🎉

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue.svg)](https://github.com/d-xorg/fah-zsh-plugin)

```
    ______      __    __    __    __    __    __    __  
   / ____/___  / /_  / /_  / /_  / /_  / /_  / /_  / /_ 
  / /_  / __ `/ __ \/ __ \/ __ \/ __ \/ __ \/ __ \/ __ \
 / __/ / /_/ / / / / / / / / / / / / / / / / / / / / / /
/_/    \__,_/_/ /_/_/ /_/_/ /_/_/ /_/_/ /_/_/ /_/_/ /_/ 
              
🔊  F A I L U R E   A U D I O   H A N D L E R  🔊                      
```

---

## 🤓 What is FAH?

**FAH** (Failure Audio Handler) is an oh-my-zsh plugin that plays the iconic "FAHHHHH" sound effect whenever a command fails in your terminal. Get real-time audio feedback on command failures, making it impossible to miss when something goes wrong.

Perfect for:
- 🏃 Long-running commands (know immediately when they fail)
- 🎮 Multitasking (audio notification pulls you back)
- 😄 Adding personality to your terminal
- 🎌 Being a cultured developer

### ✨ Features

- ✅ **Cross-platform**: Works on macOS and Linux
- ✅ **One-command setup**: Download both sounds with `fah-init`
- ✅ **Fail sound**: Plays the legendary "FAHHHHH" on command failure
- ✅ **Success sound**: Plays "Mission Success" on command success 🎉
- ✅ **Smart detection**: Only plays on actual command results (not empty prompts)
- ✅ **Watch list**: Scope which commands trigger sound (`FAH_WATCH_COMMANDS` + `fah-watch`)
- ✅ **Rate limiting**: Anti-spam protection (configurable)
- ✅ **Configurable**: Volume, sound files, enable/disable per sound type
- ✅ **Safe**: Won't break shell startup even if audio tools are missing
- ✅ **Multiple fallbacks**: Custom sound → System sounds → Terminal beep

## Brand asset

The project icon is versioned at [`assets/fah-icon.png`](assets/fah-icon.png)
for README, release, and portfolio use.

---

## ⚡ Quick Start

### Installation

1. **Clone the plugin:**

```bash
git clone https://github.com/d-xorg/fah-zsh-plugin ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fah
```

2. **Add to your plugins** in `~/.zshrc`:

```bash
plugins=(git ... fah)
```

3. **Reload your shell:**

```bash
omz reload
# or
source ~/.zshrc
```

4. **Download the sounds** (one-time setup):

```bash
fah-init
```

This will download both the legendary "FAHHHHH" fail sound and the "Mission Success" success sound.

5. **Configure the watch list** — tell FAH which commands should trigger sound:

```bash
# Trigger on ALL failed commands (simplest setup)
fah-watch add "*"

# Or scope it to specific commands
fah-watch add "npm run*"
fah-watch add "make*"
```

> **Why is this required?** The watch list is empty by default — no sound plays until you add at least one pattern. This gives you full control from the start. See [Watch List](#-command-watch-list) for details.

6. **Test it:**

```bash
fah-test
```

That's it! Now try it (with `"*"` in the watch list):

```bash
false   # You should hear: FAHHHHHH! 🔊
true    # You should hear: Mission Success! 🎉
```

---

## 🕹️ Commands

FAH provides several commands to control your audio experience:

### `fah-init`
Downloads and installs both default sound files (fail + success).

```bash
fah-init
```

**What it does:**
- Creates the `assets/` directory if needed
- Downloads the **fail sound** (`fah.mp3` — "FAHHHHH")
- Downloads the **success sound** (`success.mp3` — "Mission Success")
- Skips any file that is already installed
- Tells you to reload your shell

**Output:**
```
Downloading FAH sound files...

  Downloading fail sound (fah.mp3)...
  Downloading success sound (mission-success.mp3)...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Fail sound installed:    .../assets/fah.mp3
✓ Success sound installed: .../assets/success.mp3

To ensure the plugin picks up the new sound files run:

    omz reload

or restart your terminal.

Then test with: fah-test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### `fah-test`
Plays both sounds in sequence to verify everything is working.

```bash
fah-test
```

**Output:**
```
Testing FAH plugin...

[1/2] Fail sound:
  Playing: .../assets/fah.mp3
  ✓ done

[2/2] Success sound:
  Playing: .../assets/success.mp3
  ✓ done

✓ FAH test completed.
```

### `fah-on`
Enables the plugin (it's enabled by default).

```bash
fah-on
# ✓ FAH plugin enabled
```

### `fah-off`
Temporarily disables the plugin (no sounds will play).

```bash
fah-off
# ✓ FAH plugin disabled
```

### `fah-toggle`
Toggles between enabled and disabled states.

```bash
fah-toggle
```

### `fah-status`
Shows current plugin configuration and status.

```bash
fah-status
```

**Output:**
```
FAH Plugin Status:
  Enabled:              yes
  Player:               afplay
  Fail sound file:      /path/to/plugins/fah/assets/fah.mp3
  Success sound:        enabled
  Success sound file:   /path/to/plugins/fah/assets/success.mp3
  Min interval:         800ms
  Volume:               default
  Watch list:
    1) npm run*
    2) make*
```

### `fah-watch`
Manages the watch list — the set of glob patterns that control which commands can trigger the sound.

```bash
fah-watch list              # Show current patterns (default when no subcommand given)
fah-watch add "npm run*"    # Add a pattern
fah-watch add "make*"       # Add another pattern
fah-watch remove "make*"    # Remove a pattern
fah-watch clear             # Remove all patterns (silence everything)
```

**Subcommands:**

| Subcommand | Description |
|---|---|
| `list` | Show numbered watch list (or empty notice) |
| `add <pattern>` | Append a glob pattern; skips silently if duplicate |
| `remove <pattern>` | Remove exact-match pattern; warns if not found |
| `clear` | Empty the watch list — no commands will trigger sound |

> **Note:** Changes made with `fah-watch` are session-scoped. To persist them, add `FAH_WATCH_COMMANDS=("pattern1" "pattern2")` to your `~/.zshrc`.

---

## ⚙️ Configuration

You can customize FAH by setting environment variables in your `~/.zshrc` **before** the plugins are loaded:

```bash
# FAH Configuration (add BEFORE plugins load)
export FAH_ENABLED=1                              # Enable/disable (1=on, 0=off)
export FAH_SOUND_FILE="$HOME/my-fail.mp3"         # Custom fail sound path
export FAH_SUCCESS_ENABLED=1                      # Enable/disable success sound
export FAH_SUCCESS_SOUND_FILE="$HOME/my-win.mp3"  # Custom success sound path
export FAH_MIN_INTERVAL_MS=1000                   # Min time between sounds (ms)
export FAH_VOLUME=0.5                             # Volume (0.0-1.0 for macOS)
FAH_WATCH_COMMANDS=("npm run*" "make*")           # Only these commands trigger sound

# Load oh-my-zsh
plugins=(git fah ...)
source $ZSH/oh-my-zsh.sh
```

### Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FAH_ENABLED` | `1` | Enable (`1`) or disable (`0`) the entire plugin |
| `FAH_SOUND_FILE` | Auto-detected | Path to custom fail sound file |
| `FAH_SUCCESS_ENABLED` | `1` | Enable (`1`) or disable (`0`) the success sound |
| `FAH_SUCCESS_SOUND_FILE` | Auto-detected | Path to custom success sound file |
| `FAH_MIN_INTERVAL_MS` | `800` | Minimum milliseconds between sounds (anti-spam) |
| `FAH_VOLUME` | System default | Volume level (0.0-1.0 for macOS, 0-65536 for Linux) |
| `FAH_WATCH_COMMANDS` | `()` (empty) | Array of glob patterns — only matching commands trigger sound |

---

## 🎵 Sound Files

### Default Sounds

Run `fah-init` to download both default sounds:

```bash
fah-init
```

| Sound | File | Source |
|-------|------|--------|
| Fail | `assets/fah.mp3` | "FAHHHHH" meme sfx |
| Success | `assets/success.mp3` | "Mission Success" (GTA) |

### Custom Sounds

Want to use your own sounds? Easy!

1. **Place your sound files anywhere:**
   ```bash
   cp my-fail.wav ~/.sounds/
   cp my-win.wav ~/.sounds/
   ```

2. **Configure FAH to use them** (in `~/.zshrc`):
   ```bash
   export FAH_SOUND_FILE="$HOME/.sounds/my-fail.wav"
   export FAH_SUCCESS_SOUND_FILE="$HOME/.sounds/my-win.wav"
   ```

3. **Reload your shell:**
   ```bash
   omz reload
   ```

### Supported Formats

- 🎵 `.mp3` - MP3 audio
- 🎵 `.wav` - WAV audio  
- 🎵 `.aiff` - AIFF audio (macOS)
- 🎵 `.ogg` - OGG audio (Linux with ffplay)

### Fallback Sounds

If no custom sound is found, FAH automatically falls back to:

**Fail sound:**
1. macOS system sounds (`/System/Library/Sounds/Basso.aiff`, etc.)
2. Terminal bell (`\a`)

**Success sound:**
1. Terminal double-bell (`\a\a` — distinctly different from the fail beep)

---

## 💻 Platform Support

### macOS ✅
- **Audio player**: `afplay` (built-in)
- **Volume control**: Supported (`-v` flag)
- **Status**: Fully supported

### Linux ✅
- **Audio players**: `paplay` (PulseAudio) > `aplay` (ALSA) > `ffplay` (FFmpeg)
- **Volume control**: Supported (paplay only)
- **Status**: Fully supported

### Other Unix ⚠️
- **Fallback**: Terminal beep only
- **Status**: Basic support

---

## 💈 Usage Examples

> **Note:** The examples below assume `fah-watch add "*"` has been run (or `FAH_WATCH_COMMANDS=("*")` is set in `~/.zshrc`). Without any watch list patterns, no sound will play.

```bash
# Should play FAHHHHHH! 🔊 (watch list contains "*", command failed)
false
ls /nonexistent
grep "pattern" /file/that/doesnt/exist
npm test  # when tests fail
git push  # when push is rejected

# Should play Mission Success! 🎉 (watch list contains "*", command succeeded)
true
echo "Hello World"
ls /tmp
git status

# Just pressing Enter (no command) - no sound

# Should NOT play sound (command not in watch list)
# e.g. if watch list only contains "npm run*"
false           # no match → silent
npm run test    # match → fail sound on failure, success sound on pass
```

### Watch List Examples

```bash
# Only play sound when npm or make commands fail
fah-watch add "npm run*"
fah-watch add "make*"

# Play sound for all failed commands (restore old behavior)
fah-watch add "*"

# Only play on specific exact commands
fah-watch add "npm run test"
fah-watch add "npm run lint"

# Inspect the current list
fah-watch list
# FAH Watch List:
#   1) npm run*
#   2) make*

# Remove a pattern
fah-watch remove "make*"

# Silence everything
fah-watch clear
```

### Rate Limiting

FAH has built-in spam protection. Multiple failures in rapid succession won't overwhelm you:

```bash
# Only plays sound once (rate limited)
false && false && false && false
```

Adjust the interval if needed:

```bash
export FAH_MIN_INTERVAL_MS=2000  # 2 seconds between sounds
```

---

## 🚧 Troubleshooting

### No sound playing?

1. **Check plugin status:**
   ```bash
   fah-status
   ```

2. **Test manually:**
   ```bash
   fah-test
   ```

3. **Did you download the sound?**
   ```bash
   fah-init
   ```

4. **Did you reload your shell?**
   ```bash
   omz reload
   ```

5. **Is the sound file there?**
   ```bash
   ls -la ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fah/assets/
   ```

### Sound plays on terminal startup?

This shouldn't happen. If it does, please report an issue on GitHub!

### Sound is too loud/quiet?

Adjust the volume:

```bash
export FAH_VOLUME=0.3  # Quieter (30%)
export FAH_VOLUME=0.8  # Louder (80%)
```

Then reload: `omz reload`

### Want to temporarily disable?

```bash
fah-off               # Disable
# ... do your work ...
fah-on                # Enable again
```

---

## 🏗️ How It Works

FAH is built with production-quality Zsh scripting:

1. **Hook System**: Uses ZSH's `preexec` and `precmd` hooks
   - `preexec`: Marks that a command is about to run
   - `precmd`: Checks the exit code after command finishes

2. **Smart Detection**: Plays on actual command results
   - Ignores empty prompts (just pressing Enter)
   - Ignores completion menus
   - Non-zero exit code → fail sound
   - Zero exit code → success sound

3. **Watch List Filtering**: Scopes which commands trigger sound
   - `FAH_WATCH_COMMANDS` holds glob patterns (e.g. `"npm run*"`)
   - Matched using zsh's native glob — no external tools, no regex backtracking
   - Empty list = completely silent; `"*"` = all failures trigger sound
   - Manageable via `fah-watch` commands at runtime or set in `~/.zshrc`

4. **Rate Limiting**: Prevents spam
   - Tracks last play time using `EPOCHREALTIME` (zsh 5.1+)
   - Configurable minimum interval (default: 800ms)

4. **Audio Playback**: Cross-platform support
   - Auto-detects best available player
   - Plays asynchronously (doesn't block your terminal)
   - Graceful fallbacks if tools are missing

5. **Fallback Chain**:
   ```
   Fail:    Custom file → Downloaded fah.mp3 → System sounds → Terminal bell
   Success: Custom file → Downloaded success.mp3 → Terminal double-bell
   ```

---

## 🔄 Migration Guide

> ⚠️ **Breaking change — v1.0.0 → v1.1.0**

As of **v1.1.0**, **the sound no longer plays for all failing commands by default**. The watch list (`FAH_WATCH_COMMANDS`) is empty by default, which means no sound will play until you configure it.

**To restore the previous behavior** (play on every failed command), add this to your `~/.zshrc` before the plugins are loaded:

```bash
FAH_WATCH_COMMANDS=("*")
```

**To watch only specific commands** (new feature):

```bash
FAH_WATCH_COMMANDS=("npm run*" "make*" "cargo*")
```

Or add them interactively at any time:

```bash
fah-watch add "npm run*"
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest features  
- 🔧 Submit pull requests
- ⭐ Star the repo

---

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by the legendary "FAHHHHH" meme sound
- Built for the oh-my-zsh community
- Thanks to everyone who appreciates good sound effects in their terminal

---

## ⚠️ Disclaimer

**This plugin does not distribute any audio assets.**

This plugin is provided as-is for entertainment and productivity purposes.

The "FAHHHHH" sound is used as a cultural reference and meme.

The command `fah-init` downloads a sound effect from a third-party website (MyInstants).

This project is a meme utility plugin and is not affiliated with MyInstants.

If the audio is removed or unavailable the plugin will continue to work
without sound.

Users may replace the sound file with their own audio with `FAH_SOUND_FILE`.

The audio file is **not** included in this repository.

---

**Have fun! And may your commands always succeed! (But when they don't... FAHHHHHH! 🔊)**
