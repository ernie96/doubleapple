/*
 * DoubleTalkSettings.swift - DoubleTalk Synthesizer Settings Model
 *
 * Encapsulates rate, pitch, volume, voice parameters, filter settings, and rate boost.
 */

import Foundation

public struct DoubleTalkSettings: Codable, Equatable {
    public var speaker: DoubleTalkSpeaker
    public var rate: Int            // NVDA slider 10-100 (60 = default nS 5) or WPM
    public var rateBoost: Bool      // Boost ROM rate table
    public var pitch: Int           // NVDA pitch 0-100 (50 = default nP 50)
    public var volume: Int          // NVDA slider 10-100 (60 = default nV 5)
    public var tone: Int            // 0=Bass, 1=Normal, 2=Treble
    public var articulation: Int    // 10-100 slider (60 = default 5A)
    public var expression: Int      // 10-100 slider (60 = default 5E)
    public var formant: Int         // 10-100 slider (60 = default 5F)
    public var reverb: Int          // 10-100 slider (10 = default 0R)
    public var lowpassHz: Int       // 2000, 3000, 3800, 4800, 5000
    public var customVoices: [String: CustomVoice]

    public init(
        speaker: DoubleTalkSpeaker = .paul,
        rate: Int = 60,
        rateBoost: Bool = false,
        pitch: Int = 50,
        volume: Int = 60,
        tone: Int = 1,
        articulation: Int = 60,
        expression: Int = 60,
        formant: Int = 60,
        reverb: Int = 10,
        lowpassHz: Int = 3800,
        customVoices: [String: CustomVoice] = [:]
    ) {
        self.speaker = speaker
        self.rate = rate
        self.rateBoost = rateBoost
        self.pitch = pitch
        self.volume = volume
        self.tone = tone
        self.articulation = articulation
        self.expression = expression
        self.formant = formant
        self.reverb = reverb
        self.lowpassHz = lowpassHz
        self.customVoices = customVoices
    }

    public static let `default` = DoubleTalkSettings()

    /// Map NVDA 10-100 slider to hardware 0-9 parameter
    public static func map0to9(_ pct: Int) -> Int {
        return max(0, min(9, pct / 10 - 1))
    }

    /// Map hardware 0-9 parameter to NVDA 10-100 slider
    public static func card0to9ToNvda(_ val: Int) -> Int {
        return (val + 1) * 10
    }

    /// Map NVDA pitch 0-100 to hardware nP 0-99
    public static func mapPitch(_ pct: Int) -> Int {
        return Int((Double(pct) * 99.0 / 100.0).rounded())
    }

    /// Map hardware nP 0-99 to NVDA pitch 0-100
    public static func cardPitchToNvda(_ p: Int) -> Int {
        return Int((Double(p) * 100.0 / 99.0).rounded())
    }
}
