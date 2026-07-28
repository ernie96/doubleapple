/*
 * DoubleTalkVoice.swift - DoubleTalk Voice Definitions & Firmware Presets
 *
 * Defines the 8 built-in DoubleTalk PC hardware voices and their ROM default presets.
 */

import Foundation

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

    /// Firmware voice presets: (pitch 0-99, articulation 0-9, formant 0-9, tone 0-2, expression 0-9, reverb 0-9)
    public var preset: (pitch: Int, articulation: Int, formant: Int, tone: Int, expression: Int, reverb: Int) {
        switch self {
        case .paul:       return (50, 5, 5, 1, 5, 0)
        case .vader:      return (30, 4, 5, 1, 7, 2)
        case .bigBob:     return (40, 4, 1, 0, 6, 0)
        case .precisePete:return (60, 8, 6, 2, 4, 0)
        case .ricochet:   return (40, 5, 2, 1, 5, 6)
        case .biff:       return (50, 5, 5, 1, 5, 0)
        case .skip:       return (30, 4, 5, 1, 7, 2)
        case .roboRobert: return (40, 4, 1, 0, 6, 0)
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
