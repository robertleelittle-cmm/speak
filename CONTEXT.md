# speak — Context for Future Sessions

## What and Why

`speak` is a Swift CLI that wraps `/usr/bin/say` with better defaults, voice listing, stdin support, and environment variable configuration. It exists because the system `say` command defaults to a lower-quality voice (Alex, on older systems), has inconsistent voice discovery across macOS versions, and doesn't easily surface all available voices to the user.

The goal is to provide a user-friendly interface to macOS text-to-speech with sensible defaults (Shelley for English (US)) and full voice discoverability.

## Architecture: Why Wrap `say` Instead of Using AVFoundation

The tool wraps `/usr/bin/say` via subprocess rather than using AVFoundation (AVSpeechSynthesizer) or the obsolete NSSpeechSynthesizer because:

1. **Siri compact voice access**: The Siri compact voices (NickyCompact, AaronCompact) are accessible to the system `say` command but not exposed by AVSpeechSynthesizer. These are Nuance Vocalizer "bet3 compact" voices that sound good and are always available.

2. **Simplicity**: Subprocess invocation is straightforward, has no external dependencies, and doesn't require entitlements or permissions configuration.

3. **Consistency**: `say` has been stable across macOS versions and reliably surfaces the same voice options to all users.

## Voice Research Journey

We explored multiple paths before settling on `/usr/bin/say` subprocess:

### AVSpeechSynthesizer (AVFoundation)
- **Status**: Rejected
- **Why**: Only exposes the "standard" voices available to the system. Does NOT expose Siri compact voices (NickyCompact, AaronCompact), which are accessible via `say`. Required entitlements (`com.apple.security.personal-information`) and still had gaps.

### NSSpeechSynthesizer (legacy macOS API)
- **Status**: Rejected
- **Why**: Deprecated, limited voice set, inconsistent behavior across macOS versions.

### Direct SpeechBase / Compact Voice Access
- **Status**: Rejected
- **Why**: Requires probing private framework internals; no stable API. Compact voices are optimized for system alerts, not general use.

### TTSAXResourceModelAssets (Premium Voice CDN)
- **Status**: Documented but unusable for programmatic installation
- **Why**: Premium voices are listed in `/System/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_TTSAXResourceModelAssets/com_apple_MobileAsset_TTSAXResourceModelAssets.xml` with identifiers like `com.apple.voice.premium.en-US.Ava`. The asset zips live on `updates.cdn-apple.com`. However, SIP (System Integrity Protection) prevents programmatic write access to `/System/Volumes/Data/System/Library/AssetsV2/` even with sudo. Premium voices MUST be downloaded through the System Settings UI (Accessibility → Spoken Content → Manage Voices).

## What Works vs What Doesn't

### Works Well
- **Kona neural voices** (Shelley, Reed, Eddy, Sandy, Rocko): Pre-installed on macOS 26 Tahoe, high quality, identified with `com.apple.eloquence.*` identifiers. Use these for best quality with zero setup.
- **Siri compact voices** (NickyCompact, AaronCompact): Accessible via `say` but not AVFoundation. Sound similar in character to Kona voices; use if you prefer their character.
- **Stdin piping**: Subprocess invocation makes it trivial to accept piped input and forward it to `say`.
- **Voice discovery**: `say -v ?` covers most voices; we supplement with a known list of compact voices to provide complete discoverability.

### Doesn't Work
- **Premium neural voices** (Ava Premium, Zoe Premium, Siri Voice 1/2): These require the user to download them through System Settings → Accessibility → Spoken Content → Manage Voices. Once downloaded, they are immediately available in `speak`. Programmatic installation is blocked by SIP.
- **Direct AVFoundation integration**: Missing Siri compact voices makes it unsuitable.

## File Locations

- **Source code**: `~/Development/speak/main.swift`
- **Compiled binary**: `~/bin/speak`
- **Environment variables**: Set in `~/.zshrc` or `~/.bash_profile`:
  - `SPEAK_VOICE=VoiceName` — default voice (falls back to Shelley)
  - `SPEAK_RATE=WPM` — default rate in words per minute (falls back to 210)

## Known Limitations

1. **Two-step voice name for Kona voices**: Some voice names require the `(English (US))` suffix in the name passed to `say`. For example:
   - `Reed` works: `say -v Reed "text"`
   - `Shelley` works: `say -v Shelley "text"`
   - `Sandy` sometimes requires: `say -v "Sandy (English (US))" "text"`
   
   This inconsistency comes from macOS itself. The tool attempts voice name without the suffix first; if that fails, it retries with the suffix appended.

2. **Premium voice detection**: The tool has no way to programmatically detect which premium voices are installed. Listing all voices requires either parsing `say -v ?` output or reading the local manifest file, neither of which directly exposes premium voice download status.

## Future Improvement Ideas

1. **`speak --set-default VOICE`**: Add a command that writes `export SPEAK_VOICE=VOICE` to `~/.zshrc`, making it easier for users to persist voice preferences without manual file editing.

2. **Auto-detect premium voices**: Parse `/System/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_TTSAXResourceModelAssets/com_apple_MobileAsset_TTSAXResourceModelAssets.xml` (if readable) to detect which premium voices are downloaded, and optionally update help text to show "Premium voices available: Ava Premium, Zoe Premium".

3. **`--list-premium` flag**: Query the TTSAXResourceModelAssets manifest to show downloadable premium voices the user doesn't yet have, with instructions to download via System Settings.

4. **Fallback for voice name resolution**: Build a voice name→identifier map from `say -v ?` output at startup and use it to resolve partial names or aliases (e.g., `speak -v shelley` → `Shelley`).

## Testing the Tool

- **Basic speech**: `speak "Hello world"` should use the default voice (Shelley).
- **Voice listing**: `speak -l` should list Kona, compact, and any downloaded premium voices.
- **Stdin**: `echo "test" | speak` should read from stdin and speak it.
- **Rate control**: `speak -r 300 "fast"` should speak noticeably faster than default.
- **AIFF export**: `speak -o test.aiff "audio"` should create a valid AIFF file.
- **Env var override**: `SPEAK_VOICE=Rocko speak "test"` should use Rocko, and `export SPEAK_VOICE=Rocko` in shell should make Rocko the default.

## Dependencies

None. The tool uses only:
- Swift Foundation (Process, FileHandle, CommandLine)
- `/usr/bin/say` system command

No external package manager or third-party libraries required.
