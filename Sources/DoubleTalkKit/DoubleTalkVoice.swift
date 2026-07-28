/*
 * DoubleTalkVoice.swift - DoubleTalk Voice Definitions & Firmware Presets
 *
 * Defines the 8 built-in DoubleTalk PC hardware voices and their ROM default presets.
 */

import Foundation

public struct VoicePreset: Equatable {
    public let pitch: Int
    public let articulation: Int
    public let formant: Int
    public let tone: Int
    public let expression: Int
    public let reverb: Int

    public init(pitch: Int, articulation: Int, formant: Int, tone: Int, expression: Int, reverb: Int) {
        self.pitch = pitch
        self.articulation = articulation
        self.formant = formant
        self.tone = tone
        self.expression = expression
        self.reverb = reverb
    }
}

public enum DoubleTalkSpeaker: Int, CaseIterable, Identifiable, Codable {
    case paul = 0       // Perfect Paul
    case vader = 1      // Vader
    case bigBob = 2     // Big Bob
    case precisePete = 3// Precise Pete
    case ricochet = 4   // Ricochet
    case biff = 5       // Biff
    case skip = 6       // Skip
    case roboRobert = 7 // Robo Robert

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .paul:        return "Perfect Paul"
        case .vader:       return "Vader"
        case .bigBob:      return "Big Bob"
        case .precisePete: return "Precise Pete"
        case .ricochet:    return "Ricochet"
        case .biff:        return "Biff"
        case .skip:        return "Skip"
        case .roboRobert:  return "Robo Robert"
        }
    }

    public var isFemale: Bool {
        switch self {
        case .ricochet, .skip: return true
        default: return false
        }
    }

    /// Firmware voice presets
    public var preset: VoicePreset {
        switch self {
        case .paul:        return VoicePreset(pitch: 50, articulation: 5, formant: 5, tone: 1, expression: 5, reverb: 0)
        case .vader:       return VoicePreset(pitch: 30, articulation: 4, formant: 5, tone: 1, expression: 7, reverb: 2)
        case .bigBob:      return VoicePreset(pitch: 40, articulation: 4, formant: 1, tone: 0, expression: 6, reverb: 0)
        case .precisePete: return VoicePreset(pitch: 60, articulation: 8, formant: 6, tone: 2, expression: 4, reverb: 0)
        case .ricochet:    return VoicePreset(pitch: 40, articulation: 5, formant: 2, tone: 1, expression: 5, reverb: 6)
        case .biff:        return VoicePreset(pitch: 50, articulation: 5, formant: 5, tone: 1, expression: 5, reverb: 0)
        case .skip:        return VoicePreset(pitch: 30, articulation: 4, formant: 5, tone: 1, expression: 7, reverb: 2)
        case .roboRobert:  return VoicePreset(pitch: 40, articulation: 4, formant: 1, tone: 0, expression: 6, reverb: 0)
        }
    }
}

public struct CustomVoice: Identifiable, Codable, Equatable {
    public var id: String { name }
    public var name: String
    public var speaker: DoubleTalkSpeaker
    public var pitch: Int          // 0..100
    public var articulation: Int   // 10..100
    public var expression: Int     // 10..100
    public var formant: Int        // 10..100
    public var tone: Int           // 0..2
    public var reverb: Int         // 10..100

    public init(name: String, speaker: DoubleTalkSpeaker = .paul, pitch: Int = 50, articulation: Int = 60, expression: Int = 60, formant: Int = 60, tone: Int = 1, reverb: Int = 10) {
        self.name = name
        self.speaker = speaker
        self.pitch = pitch
        self.articulation = articulation
        self.expression = expression
        self.formant = formant
        self.tone = tone
        self.reverb = reverb
    }
}
