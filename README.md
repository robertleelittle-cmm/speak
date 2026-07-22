# speak

A Swift CLI that wraps `/usr/bin/say` with better defaults, voice listing, stdin support, and environment variable configuration.

## Install

Clone the repo and run:

```bash
make install
```

This compiles `main.swift` and installs the binary to `~/bin/speak`. Then add `~/bin` to your `PATH` if it isn't already:

```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="$HOME/bin:$PATH"
```

Alternatively, compile and install manually:

```bash
swiftc main.swift -o ~/bin/speak
```

## Quick Start

Speak text from the command line:

```bash
speak "Hello, world"
```

Pipe text from stdin:

```bash
echo "Hello from a pipe" | speak
```

Use a different voice:

```bash
speak -v Rocko "This is Rocko"
```

Adjust speech rate (words per minute):

```bash
speak -r 150 "Slow and steady"
speak -r 300 "Fast talker"
```

Save audio to an AIFF file:

```bash
speak -o output.aiff "Save me to disk"
```

## Voice Selection

### List Available Voices

Show all voices on your system (including hidden Siri compact voices):

```bash
speak -l
```

### Set a Default Voice

The default voice is Shelley (English (US)). Override it with the `SPEAK_VOICE` environment variable:

```bash
# Add to ~/.zshrc
export SPEAK_VOICE="Reed"

# Or set it for a single command
SPEAK_VOICE=Eddy speak "Hi there"
```

### Use a Different Voice for One Command

```bash
speak -v Sandy "One-time voice override"
```

### Voice Recommendations

**Best no-download voices** (Kona neural engine, pre-installed):
- Shelley (default)
- Reed
- Eddy
- Sandy
- Rocko

These voices are high-quality, available by default on macOS 26 Tahoe, and require no setup.

**Siri compact voices** (Nuance Vocalizer):
- NickyCompact
- AaronCompact

These are accessible via `say` but sound similar to the no-download voices. Use them if you prefer their character.

**Premium neural voices** (require download via System Settings):
- Ava Premium
- Zoe Premium
- Siri Voice 1
- Siri Voice 2

## Rate Control

Adjust the speech rate with the `-r` flag (words per minute). Default is 210 wpm:

```bash
speak -r 180 "Slightly slower"
speak -r 250 "Faster pace"
```

You can also set a default rate with the `SPEAK_RATE` environment variable:

```bash
# Add to ~/.zshrc
export SPEAK_RATE="180"
```

## Stdin / Pipe Usage

`speak` reads from stdin when piped:

```bash
cat document.txt | speak
ls -la | grep "\.swift$" | speak
echo "Quick notification" | speak
```

## Getting Premium Voices

Premium neural voices (Ava Premium, Zoe Premium, Siri Voice 1/2) are not installed by default. Download them through System Settings:

1. Open System Settings
2. Navigate to Accessibility → Spoken Content
3. Click "Manage Voices"
4. Select the voices you want and download them

Once downloaded, they are immediately available in `speak`:

```bash
speak -v "Ava Premium" "Now I can use premium voices"
```

## Help

```bash
speak -h
```

## Flags Summary

| Flag | Purpose | Example |
|------|---------|---------|
| `-v NAME` | Speak with a specific voice | `speak -v Rocko "text"` |
| `-r WPM` | Set speech rate (words per minute) | `speak -r 180 "text"` |
| `-o FILE` | Save to AIFF file instead of speaking | `speak -o output.aiff "text"` |
| `-l [LANG]` | List voices (optionally filtered by language) | `speak -l`, `speak -l en-US` |
| `-h` | Show help | `speak -h` |
