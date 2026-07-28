/*
 * DoubleTalkSynthesizer.swift - High-Level DoubleTalk Speech Engine Wrapper
 *
 * Drives the CDoubleTalk emulator core, translates text & SSML requests into
 * DoubleTalk control sequences, renders 16-bit PCM audio, and manages low-pass/boost settings.
 */

import Foundation
import CDoubleTalk

public final class DoubleTalkSynthesizer {
    private var handle: OpaquePointer?
    public let sampleRate: Double = 10504.0

    public init?(romData: Data? = nil) {
        guard let data = romData ?? DoubleTalkSettingsStore.loadROMData() else {
            return nil
        }

        let handle = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> OpaquePointer? in
            guard let base = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            return dtalk_create(base, data.count)
        }

        guard let validHandle = handle else {
            return nil
        }
        self.handle = validHandle
    }

    deinit {
        if let handle = handle {
            dtalk_destroy(handle)
        }
    }

    public func reset() {
        if let handle = handle {
            dtalk_reset(handle)
        }
    }

    public func setLowpass(hz: Int) {
        if let handle = handle {
            dtalk_set_lowpass_hz(handle, UInt32(hz))
        }
    }

    public func setRateBoost(enabled: Bool) {
        if let handle = handle {
            dtalk_set_rate_boost(handle, enabled ? 3 : 0)
        }
    }

    /// Formats DoubleTalk hardware prefix string matching NVDA driver logic
    public func makePrefix(settings: DoubleTalkSettings, speaker: DoubleTalkSpeaker) -> String {
        let preset = speaker.preset
        var parts: [String] = []

        // Voice (nO) & Number mode 14B (pronounce leading zeros)
        parts.append("\u{01}\(speaker.rawValue)O")
        parts.append("\u{01}14B")

        // Speed (nS)
        parts.append("\u{01}\(DoubleTalkSettings.map0to9(settings.rate))S")

        // Pitch (nP) - emit only if different from preset
        let cardPitch = DoubleTalkSettings.mapPitch(settings.pitch)
        if cardPitch != preset.pitch {
            parts.append("\u{01}\(cardPitch)P")
        }

        // Volume (nV)
        parts.append("\u{01}\(DoubleTalkSettings.map0to9(settings.volume))V")

        // Tone (nX), Articulation (nA), Expression (nE), Formant (nF), Reverb (nR)
        if settings.tone != preset.tone {
            parts.append("\u{01}\(settings.tone)X")
        }
        let cardArtic = DoubleTalkSettings.map0to9(settings.articulation)
        if cardArtic != preset.articulation {
            parts.append("\u{01}\(cardArtic)A")
        }
        let cardExpr = DoubleTalkSettings.map0to9(settings.expression)
        if cardExpr != preset.expression {
            parts.append("\u{01}\(cardExpr)E")
        }
        let cardFormant = DoubleTalkSettings.map0to9(settings.formant)
        if cardFormant != preset.formant {
            parts.append("\u{01}\(cardFormant)F")
        }
        let cardReverb = DoubleTalkSettings.map0to9(settings.reverb)
        if cardReverb != preset.reverb {
            parts.append("\u{01}\(cardReverb)R")
        }

        return parts.joined()
    }

    /// Renders text into signed 16-bit PCM audio samples
    public func render(_ text: String, settings: DoubleTalkSettings = .default, speaker: DoubleTalkSpeaker = .paul) -> [Int16] {
        guard let handle = handle else { return [] }

        setLowpass(hz: settings.lowpassHz)
        setRateBoost(enabled: settings.rateBoost)

        let prefix = makePrefix(settings: settings, speaker: speaker)
        let cleanedText = text.replacingOccurrences(of: "[^\u{20}-\u{7e}]", with: " ", options: .regularExpression)
        let fullCommand = "\(prefix)\(cleanedText)\r"

        guard let asciiData = fullCommand.data(using: .ascii) else { return [] }

        dtalk_stop(handle)
        asciiData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            if let base = ptr.baseAddress?.assumingMemoryBound(to: CChar.self) {
                dtalk_queue(handle, base, asciiData.count)
            }
        }

        var samples: [Int16] = []
        let chunkCapacity = 2048
        let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: chunkCapacity)
        defer { buffer.deallocate() }

        while true {
            let n = dtalk_synth16(handle, buffer, chunkCapacity)
            if n == 0 { break }
            samples.append(contentsOf: UnsafeBufferPointer(start: buffer, count: n))
        }

        return samples
    }
}
