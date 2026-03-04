# FAHHHHHHHH 🔊

```
    ______      __    __    __    __    __    __    __  
   / ____/___  / /_  / /_  / /_  / /_  / /_  / /_  / /_ 
  / /_  / __ `/ __ \/ __ \/ __ \/ __ \/ __ \/ __ \/ __ \
 / __/ / /_/ / / / / / / / / / / / / / / / / / / / / / /
/_/    \__,_/_/ /_/_/ /_/_/ /_/_/ /_/_/ /_/_/ /_/_/ /_/ 
              
🔊  F A I L U R E   A U D I O   H A N D L E R  🔊                      
```

> 🎌 **The meme "FAHHHHH" now in your terminal!**  
> When your commands fail, you'll know it. Instantly. Audibly. Memorably.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS | Linux](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue.svg)](https://github.com/d-xorg/fah-zsh-plugin)

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
- ✅ **One-command setup**: Download sound with `fah-init`
- ✅ **Smart detection**: Only plays on actual failures (not empty prompts)
- ✅ **Rate limiting**: Anti-spam protection (configurable)
- ✅ **Configurable**: Volume, sound file, enable/disable
- ✅ **Safe**: Won't break shell startup even if audio tools are missing
- ✅ **Multiple fallbacks**: Custom sound → System sounds → Terminal beep

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

4. **Download the sound** (one-time setup):

```bash
fah-init
```

This will download the legendary "FAHHHHH" sound and set everything up automatically!

5. **Test it:**

```bash
fah-test
```

That's it! Now try running a failing command:

```bash
false        # You should hear: FAHHHHHH! 🔊
```

---

## 🕹️ Commands

FAH provides several commands to control your audio experience:

### `fah-init`
Downloads and installs the default "FAHHHHH" sound file.

```bash
fah-init
```

**What it does:**
- Creates the `assets/` directory if needed
- Downloads the sound from the internet
- Sets up everything automatically
- Tells you to reload your shell

**Output:**
```
Downloading FAH sound file...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ FAH sound installed successfully.

To ensure the plugin picks up the new sound file run:

    omz reload

or restart your terminal.

Then test it with: fah-test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### `fah-test`
Manually plays the sound to test if everything is working.

```bash
fah-test
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
  Enabled: yes
  Player: afplay
  Sound file: /path/to/plugins/fah/assets/fah.mp3
  Min interval: 800ms
  Volume: default
```

---

## ⚙️ Configuration

You can customize FAH by setting environment variables in your `~/.zshrc` **before** the plugins are loaded:

```bash
# FAH Configuration (add BEFORE plugins load)
export FAH_ENABLED=1                        # Enable/disable (1=on, 0=off)
export FAH_SOUND_FILE="$HOME/my-sound.mp3"  # Custom sound file path
export FAH_MIN_INTERVAL_MS=1000             # Min time between sounds (ms)
export FAH_VOLUME=0.5                       # Volume (0.0-1.0 for macOS)

# Load oh-my-zsh
plugins=(git fah ...)
source $ZSH/oh-my-zsh.sh
```

### Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FAH_ENABLED` | `1` | Enable (`1`) or disable (`0`) the plugin |
| `FAH_SOUND_FILE` | Auto-detected | Path to custom sound file |
| `FAH_MIN_INTERVAL_MS` | `800` | Minimum milliseconds between sounds (anti-spam) |
| `FAH_VOLUME` | System default | Volume level (0.0-1.0 for macOS, 0-65536 for Linux) |

---

## 🎵 Sound Files

### Default Sound

The plugin uses the "FAHHHHH" sound from the internet. Run `fah-init` to download it:

```bash
fah-init
```

The sound is saved to: `assets/fah.mp3`

### Custom Sounds

Want to use your own sound? Easy!

1. **Place your sound file anywhere:**
   ```bash
   cp my-epic-sound.wav ~/.sounds/
   ```

2. **Configure FAH to use it** (in `~/.zshrc`):
   ```bash
   export FAH_SOUND_FILE="$HOME/.sounds/my-epic-sound.wav"
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

1. **macOS**: System sounds (`/System/Library/Sounds/Basso.aiff`, etc.)
2. **Any platform**: Terminal beep (`\a`)

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

```bash
# Should play FAHHHHHH! 🔊
false
ls /nonexistent
grep "pattern" /file/that/doesnt/exist
npm test  # when tests fail
git push  # when push is rejected

# Should NOT play sound
true
echo "Hello World"
ls /tmp
git status

# Just pressing Enter (no command) - no sound
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

2. **Smart Detection**: Only plays on actual failures
   - Ignores empty prompts (just pressing Enter)
   - Ignores completion menus
   - Only triggers on non-zero exit codes

3. **Rate Limiting**: Prevents spam
   - Tracks last play time using `EPOCHREALTIME` (zsh 5.1+)
   - Configurable minimum interval (default: 800ms)

4. **Audio Playback**: Cross-platform support
   - Auto-detects best available player
   - Plays asynchronously (doesn't block your terminal)
   - Graceful fallbacks if tools are missing

5. **Fallback Chain**:
   ```
   Custom file → Downloaded sound → System sounds → Terminal beep
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
