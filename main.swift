import Foundation

// MARK: - Voice database (voices not shown by say -v ?)
let hiddenVoices: [(name: String, lang: String, desc: String)] = [
    ("Nicky Compact",   "en-US", "Siri female (US) — compact neural"),
    ("Aaron Compact",   "en-US", "Siri male (US) — compact neural"),
    ("Martha Compact",  "en-GB", "Siri female (UK) — compact neural"),
    ("Arthur Compact",  "en-GB", "Siri male (UK) — compact neural"),
    ("Gordon Compact",  "en-AU", "Siri male (AU) — compact neural"),
    ("Catherine Compact","en-AU","Siri female (AU) — compact neural"),
    ("Helena Compact",  "de-DE", "Siri female (DE) — compact neural"),
    ("Martin Compact",  "de-DE", "Siri male (DE) — compact neural"),
    ("Marie Compact",   "fr-FR", "Siri female (FR) — compact neural"),
    ("Dan Compact",     "fr-FR", "Siri male (FR) — compact neural"),
]

let defaultVoice = "Shelley (English (US))"   // Best-sounding installed voice
let defaultRate  = 210               // words per minute

// MARK: - Helpers

func runSay(text: String, voice: String, rate: Int, outputFile: String?) {
    var args = ["-v", voice, "-r", "\(rate)"]
    if let out = outputFile {
        args += ["-o", out]
    }
    args.append(text)

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/say")
    task.arguments = args
    try? task.run()
    task.waitUntilExit()
}

func listVoices(lang: String?) {
    // Get voices from `say -v ?`
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/say")
    task.arguments = ["-v", "?"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    var voices: [(name: String, lang: String, note: String)] = []

    // Parse say output: "VoiceName           lang_XX    # demo text"
    let lineRegex = try? NSRegularExpression(pattern: #"^(.+?)\s{2,}([a-z]{2,3}_[A-Z]{2,3})\s"#)
    for line in output.components(separatedBy: "\n") {
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
        let nsLine = line as NSString
        if let m = lineRegex?.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)),
           m.numberOfRanges >= 3 {
            let name = nsLine.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let lang = nsLine.substring(with: m.range(at: 2)).replacingOccurrences(of: "_", with: "-")
            voices.append((name: name, lang: lang, note: ""))
        }
    }

    // Add hidden Siri compact voices
    for hv in hiddenVoices {
        voices.append((name: hv.name, lang: hv.lang, note: "[Siri neural]"))
    }

    // Filter by language if requested
    if let l = lang {
        voices = voices.filter { $0.lang.lowercased().hasPrefix(l.lowercased()) }
    }

    voices.sort {
        if $0.note != $1.note { return $0.note > $1.note } // Siri first
        return $0.lang < $1.lang
    }

    print("Available voices\(lang != nil ? " (\(lang!))" : ""):")
    var lastNote = ""
    for v in voices {
        if v.note != lastNote {
            lastNote = v.note
            print("")
        }
        let note = v.note.isEmpty ? "" : " \(v.note)"
        print("  \(v.name.padding(toLength: 28, withPad: " ", startingAt: 0)) \(v.lang)\(note)")
    }
}

func usage() {
    print("""
Usage: speak [options] [text]
       echo "text" | speak [options]

Options:
  -v, --voice NAME      Voice name (env: SPEAK_VOICE, default: \(defaultVoice))
  -r, --rate WPM        Rate in words per minute (env: SPEAK_RATE, default: \(defaultRate))
  -o, --out FILE        Save audio to FILE instead of playing
  -l, --list [LANG]     List voices (optionally filter, e.g. en, en-US)
  -h, --help            Show this help

Best voices (no download needed):
  speak                          "Hello"   # Shelley — expressive female (default)
  speak -v Reed                  "Hello"   # Reed — clear male
  speak -v "Eddy (English (US))" "Hello"   # Eddy — conversational male
  speak -v "Sandy (English (US))" "Hello"  # Sandy — softer female

Premium voices (download via System Settings → Accessibility → Spoken Content):
  Ava (Premium), Siri Voice 1, Siri Voice 2, Zoe (Premium)

To download premium Siri voices (Ava, Siri Voice 1, etc.):
  System Settings → Accessibility → Spoken Content → System Voice → Manage Voices…
""")
}

// MARK: - Arg parsing

var args = CommandLine.arguments.dropFirst()
var voiceName: String = ProcessInfo.processInfo.environment["SPEAK_VOICE"] ?? defaultVoice
var rate: Int = ProcessInfo.processInfo.environment["SPEAK_RATE"].flatMap(Int.init) ?? defaultRate
var outputFile: String? = nil
var textParts: [String] = []
var listFlag = false
var listLang: String? = "en"

var i = args.startIndex
while i < args.endIndex {
    let arg = args[i]
    switch arg {
    case "-v", "--voice":
        i = args.index(after: i)
        guard i < args.endIndex else { fputs("speak: --voice requires a value\n", stderr); exit(1) }
        voiceName = String(args[i])
    case "-r", "--rate":
        i = args.index(after: i)
        guard i < args.endIndex, let n = Int(args[i]) else { fputs("speak: --rate requires a number\n", stderr); exit(1) }
        rate = max(50, min(720, n))
    case "-o", "--out":
        i = args.index(after: i)
        guard i < args.endIndex else { fputs("speak: --out requires a value\n", stderr); exit(1) }
        outputFile = String(args[i])
    case "-l", "--list":
        listFlag = true
        let next = args.index(after: i)
        if next < args.endIndex, !args[next].hasPrefix("-") {
            listLang = String(args[next])
            i = next
        } else {
            listLang = nil
        }
    case "-h", "--help":
        usage(); exit(0)
    case "--":
        i = args.index(after: i)
        textParts += args[i...].map { String($0) }
        i = args.endIndex
        continue
    default:
        if arg.hasPrefix("-") {
            fputs("speak: unknown option: \(arg)\n", stderr); exit(1)
        }
        textParts.append(String(arg))
    }
    i = args.index(after: i)
}

// MARK: - Execute

if listFlag {
    listVoices(lang: listLang)
    exit(0)
}

let text: String
if !textParts.isEmpty {
    text = textParts.joined(separator: " ")
} else if isatty(STDIN_FILENO) == 0 {
    text = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
} else {
    usage(); exit(1)
}

guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { exit(0) }

fputs("[\(voiceName)] rate=\(rate)wpm\n", stderr)
runSay(text: text, voice: voiceName, rate: rate, outputFile: outputFile)
