import Foundation

public struct DoubleTalkDictionary {
    private static let acronymMap: [String: String] = [
        "URL": "U R L",
        "HTTP": "H T T P",
        "HTTPS": "H T T P S",
        "API": "A P I",
        "JSON": "JAY son",
        "SQL": "S Q L",
        "CPU": "C P U",
        "GPU": "G P U",
        "UI": "U I",
        "UX": "U X",
        "AI": "A I",
        "ML": "M L",
        "WiFi": "Wi Fi",
        "Bluetooth": "Blue Tooth",
        "macOS": "Mac O S",
        "iOS": "i O S",
        "tvOS": "T V O S",
        "watchOS": "watch O S",
        "visionOS": "vision O S",
        "AirPlay": "Air Play",
        "AirDrop": "Air Drop",
        "SharePlay": "Share Play",
        "CoreML": "Core M L",
        "SwiftUI": "Swift U I",
        "RealityKit": "Reality Kit",
        "ARKit": "A R Kit",
        "MetalFX": "Metal F X",
        "TestFlight": "Test Flight"
    ]

    private static let splitters: [(pattern: String, template: String)] = [
        // aB -> a B
        ("([a-z])([A-Z])", "$1 $2"),
        // AAB -> AA B
        ("([A-Z]+)([A-Z][a-z])", "$1 $2"),
        // 1A -> 1 A
        ("([0-9])([A-Za-z])", "$1 $2"),
        // A1 -> A 1
        ("([A-Za-z])([0-9])", "$1 $2")
    ]

    // Precompiled regex objects for performance
    private static let acronymRegexes: [(regex: NSRegularExpression, replacement: String)] = {
        var compiled: [(NSRegularExpression, String)] = []
        for (key, value) in acronymMap {
            if let re = try? NSRegularExpression(pattern: "\\b\(key)\\b", options: []) {
                compiled.append((re, value))
            }
        }
        return compiled
    }()

    private static let splitterRegexes: [(regex: NSRegularExpression, replacement: String)] = {
        var compiled: [(NSRegularExpression, String)] = []
        for (pattern, template) in splitters {
            if let re = try? NSRegularExpression(pattern: pattern, options: []) {
                compiled.append((re, template))
            }
        }
        return compiled
    }()

    public static func modernize(_ text: String) -> String {
        var t = text
        
        // 0. Smart Punctuation Normalization
        // Convert curly/smart quotes and em/en dashes to standard ASCII
        // so they aren't stripped out by the strict ASCII filter later.
        t = t.replacingOccurrences(of: "[‘’`]", with: "'", options: .regularExpression)
             .replacingOccurrences(of: "[“”]", with: "\"", options: .regularExpression)
             .replacingOccurrences(of: "[—–]", with: "-", options: .regularExpression)
             .replacingOccurrences(of: "…", with: "...")
        
        // 1. Lexicon Replacements
        // Replace exact word-bounded occurrences
        for (re, replacement) in acronymRegexes {
            t = re.stringByReplacingMatches(
                in: t,
                options: [],
                range: NSRange(location: 0, length: (t as NSString).length),
                withTemplate: NSRegularExpression.escapedTemplate(for: replacement)
            )
        }
        
        // 2. Advanced Splitters (CamelCase & Identifiers)
        for (re, replacement) in splitterRegexes {
            t = re.stringByReplacingMatches(
                in: t,
                options: [],
                range: NSRange(location: 0, length: (t as NSString).length),
                withTemplate: replacement
            )
        }
        
        return t
    }
}
