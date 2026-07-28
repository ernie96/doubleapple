/*
 * DoubleTalkAudioUnit.swift - AVSpeechSynthesisProviderAudioUnit for VoiceOver
 *
 * Exposes DoubleTalk PC voices as native iOS system voices in Accessibility settings,
 * receiving speech synthesis requests from VoiceOver, rendering DoubleTalk PCM audio,
 * and streaming Float32 PCM to CoreAudio in real-time.
 */

import AVFoundation
import Accelerate
import CoreMedia

public final class DoubleTalkAudioUnit: AVSpeechSynthesisProviderAudioUnit {
    private let synth = DoubleTalkSynthesizer()

    private var outputBuffer: [Float32] = []
    private var outputOffset: Int = 0
    private var volume: Float32 = 1.0
    private let mutex = DispatchSemaphore(value: 1)

    private let asbdRate: Double = 22050.0
    private var requestCount = 0
    private let outputBus: AUAudioUnitBus
    private var _outputBusses: AUAudioUnitBusArray!
    private let outputFormat: AVAudioFormat

    private static let identifierPrefix = "com.doubletalkapple.voice"

    // MARK: - Init

    @objc public override init(componentDescription: AudioComponentDescription,
                               options: AudioComponentInstantiationOptions = []) throws {
        var asbd = AudioStreamBasicDescription(
            mSampleRate: 22050.0,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4,
            mChannelsPerFrame: 1, mBitsPerChannel: 32, mReserved: 0)

        outputFormat = AVAudioFormat(
            cmAudioFormatDescription: try CMAudioFormatDescription(audioStreamBasicDescription: asbd))
        outputBus = try AUAudioUnitBus(format: outputFormat)

        try super.init(componentDescription: componentDescription, options: options)

        _outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [outputBus])
    }

    // MARK: - Voice Registration

    public override var speechVoices: [AVSpeechSynthesisProviderVoice] {
        get {
            var voices = DoubleTalkSpeaker.allCases.map { speaker in
                let voice = AVSpeechSynthesisProviderVoice(
                    name: "DoubleTalk \(speaker.displayName)",
                    identifier: "\(Self.identifierPrefix).\(speaker.rawValue)",
                    primaryLanguages: ["en-US"],
                    supportedLanguages: ["en-US"])
                voice.gender = speaker.isFemale ? .female : .male
                return voice
            }

            // Include user custom voices
            let settings = DoubleTalkSettingsStore.load()
            for (name, custom) in settings.customVoices {
                let voice = AVSpeechSynthesisProviderVoice(
                    name: "DoubleTalk \(name)",
                    identifier: "\(Self.identifierPrefix).custom.\(custom.id)",
                    primaryLanguages: ["en-US"],
                    supportedLanguages: ["en-US"])
                voice.gender = custom.speaker.isFemale ? .female : .male
                voices.append(voice)
            }

            return voices
        }
        set { }
    }

    public override var outputBusses: AUAudioUnitBusArray { _outputBusses }

    // MARK: - Synthesis Request

    public override func synthesizeSpeechRequest(_ request: AVSpeechSynthesisProviderRequest) {
        guard let synth = synth else {
            storeSamples([0.0])
            return
        }

        let ssml = request.ssmlRepresentation
        var settings = DoubleTalkSettingsStore.load()

        // Extract VoiceOver prosody scaling (rate, pitch, volume) from SSML
        if let rateVal = Self.extractProsodyAttribute(ssml, "rate") {
            let ratio = rateVal / 100.0
            settings.rate = min(100, max(10, Int(Float(settings.rate) * ratio)))
        }
        if let pitchVal = Self.extractProsodyAttribute(ssml, "pitch") {
            if ssml.contains("pitch=\"-") || ssml.contains("pitch=\"+") {
                settings.pitch = min(100, max(0, Int(Float(settings.pitch) + pitchVal)))
            } else {
                let ratio = pitchVal / 100.0
                settings.pitch = min(100, max(0, Int(Float(settings.pitch) * ratio)))
            }
        }
        if let volVal = Self.extractProsodyAttribute(ssml, "volume") {
            let ratio = volVal / 100.0
            settings.volume = min(100, max(0, Int(Float(settings.volume) * ratio)))
        }

        // Resolve requested voice speaker
        let speaker = Self.speaker(for: request.voice.identifier)

        requestCount += 1
        var segments = Self.segments(from: ssml)
        if segments.allSatisfy({ $0.text.isEmpty }) && requestCount == 1 {
            segments = [(text: "DoubleTalk PC.", silenceMs: 0)]
        }

        func silence(_ ms: Int) -> [Int16] {
            [Int16](repeating: 0, count: Int(Double(ms) / 1000.0 * synth.sampleRate))
        }

        var int16Samples: [Int16] = []
        for seg in segments {
            if !seg.text.isEmpty {
                int16Samples += synth.render(seg.text, settings: settings, speaker: speaker)
            }
            if seg.silenceMs > 0 {
                int16Samples += silence(seg.silenceMs)
            }
        }

        if int16Samples.isEmpty {
            int16Samples = silence(10)
        }

        // Convert Int16 -> Float32 (-1.0 to 1.0)
        var floats = [Float32](repeating: 0, count: int16Samples.count)
        int16Samples.withUnsafeBufferPointer { src in
            floats.withUnsafeMutableBufferPointer { dst in
                vDSP_vflt16(src.baseAddress!, 1, dst.baseAddress!, 1, vDSP_Length(int16Samples.count))
                var scale: Float32 = 1.0 / 32768.0
                vDSP_vsmul(dst.baseAddress!, 1, &scale, dst.baseAddress!, 1, vDSP_Length(int16Samples.count))
            }
        }

        // Resample from 10504 Hz -> 22050 Hz
        let resampled = resample(floats, from: synth.sampleRate, to: asbdRate)
        storeSamples(resampled)
    }

    public override func cancelSpeechRequest() {
        storeSamples([])
    }

    private func storeSamples(_ samples: [Float32]) {
        mutex.wait()
        outputBuffer = samples
        outputOffset = 0
        mutex.signal()
    }

    // MARK: - CoreAudio Render Block

    public override var internalRenderBlock: AUInternalRenderBlock {
        return { actionFlags, _, frameCount, _, outputAudioBufferList, _, _ in
            let abl = UnsafeMutableAudioBufferListPointer(outputAudioBufferList)
            guard let raw = abl[0].mData else { return noErr }
            let out = raw.assumingMemoryBound(to: Float32.self)
            let frames = Int(frameCount)
            out.update(repeating: 0, count: frames)

            self.mutex.wait()
            let available = self.outputBuffer.count - self.outputOffset
            let count = min(available, frames)

            if count > 0 {
                var vol = self.volume
                self.outputBuffer.withUnsafeBufferPointer { buf in
                    vDSP_vsmul(buf.baseAddress! + self.outputOffset, 1, &vol, out, 1, vDSP_Length(count))
                }
                self.outputOffset += count
            }
            abl[0].mDataByteSize = UInt32(count * MemoryLayout<Float32>.size)

            if self.outputOffset >= self.outputBuffer.count {
                actionFlags.pointee = .offlineUnitRenderAction_Complete
                self.outputBuffer.removeAll(keepingCapacity: true)
                self.outputOffset = 0
            }
            self.mutex.signal()
            return noErr
        }
    }

    // MARK: - Helpers

    private static func speaker(for identifier: String) -> DoubleTalkSpeaker {
        let last = identifier.split(separator: ".").last
        if let raw = last.flatMap({ Int($0) }), let spk = DoubleTalkSpeaker(rawValue: raw) {
            return spk
        }
        return .paul
    }

    private static func segments(from ssml: String) -> [(text: String, silenceMs: Int)] {
        let ns = ssml as NSString
        guard let re = try? NSRegularExpression(pattern: #"<break\b([^>]*?)/?\s*>"#, options: [.caseInsensitive]) else {
            return [(cleanSSML(ssml), 0)]
        }
        var result: [(text: String, silenceMs: Int)] = []
        var last = 0
        for m in re.matches(in: ssml, range: NSRange(location: 0, length: ns.length)) {
            let chunk = ns.substring(with: NSRange(location: last, length: m.range.location - last))
            let attrs = m.range(at: 1).location != NSNotFound ? ns.substring(with: m.range(at: 1)) : ""
            let ms = silenceMilliseconds(fromBreakAttributes: attrs)
            result.append((cleanSSML(chunk), ms))
            last = m.range.location + m.range.length
        }
        let tail = cleanSSML(ns.substring(from: last))
        if !tail.isEmpty { result.append((tail, 0)) }
        return result.isEmpty ? [(cleanSSML(ssml), 0)] : result
    }

    private static func cleanSSML(_ ssml: String) -> String {
        var t = ssml.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let entities = ["&apos;": "'", "&quot;": "\"", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&#39;": "'"]
        for (k, v) in entities { t = t.replacingOccurrences(of: k, with: v) }
        t = t.replacingOccurrences(of: "[", with: " ").replacingOccurrences(of: "]", with: " ")
        t = t.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func silenceMilliseconds(fromBreakAttributes attrs: String) -> Int {
        func value(_ name: String) -> String? {
            guard let re = try? NSRegularExpression(pattern: "\(name)\\s*=\\s*[\"']([^\"']+)[\"']", options: [.caseInsensitive]),
                  let m = re.firstMatch(in: attrs, range: NSRange(attrs.startIndex..., in: attrs)),
                  let r = Range(m.range(at: 1), in: attrs) else { return nil }
            return String(attrs[r])
        }
        func cap(_ ms: Int) -> Int { max(0, min(ms, 2000)) }
        if let time = value("time")?.lowercased().trimmingCharacters(in: .whitespaces) {
            if time.hasSuffix("ms"), let n = Double(time.dropLast(2)) { return cap(Int(n)) }
            if time.hasSuffix("s"),  let n = Double(time.dropLast(1)) { return cap(Int(n * 1000)) }
            if let n = Double(time) { return cap(Int(n)) }
        }
        switch value("strength")?.lowercased() {
        case "none":     return 0
        case "x-weak":   return 100
        case "weak":     return 200
        case "medium":   return 350
        case "strong":   return 500
        case "x-strong": return 800
        default:         return 300
        }
    }

    private static func extractProsodyAttribute(_ ssml: String, _ attribute: String) -> Float? {
        let pattern = attribute + #"="([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: ssml, options: [], range: NSRange(ssml.startIndex..., in: ssml)) else {
            return nil
        }
        let valueString = String(ssml[Range(match.range(at: 1), in: ssml)!])
        let numericString = valueString.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "+", with: "")
        return Float(numericString)
    }

    private func resample(_ input: [Float32], from srcRate: Double, to dstRate: Double) -> [Float32] {
        guard let srcFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: srcRate, channels: 1, interleaved: false),
              let dstFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: dstRate, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: srcFmt, to: dstFmt),
              let srcBuf = AVAudioPCMBuffer(pcmFormat: srcFmt, frameCapacity: AVAudioFrameCount(input.count))
        else { return input }

        srcBuf.frameLength = AVAudioFrameCount(input.count)
        memcpy(srcBuf.floatChannelData![0], input, input.count * MemoryLayout<Float32>.size)

        let outCap = AVAudioFrameCount(ceil(Double(input.count) * dstRate / srcRate)) + 256
        guard let dstBuf = AVAudioPCMBuffer(pcmFormat: dstFmt, frameCapacity: outCap) else { return input }

        var consumed = false
        var error: NSError?
        converter.convert(to: dstBuf, error: &error) { _, status in
            if consumed { status.pointee = .endOfStream; return nil }
            consumed = true; status.pointee = .haveData; return srcBuf
        }
        if error != nil { return input }
        return Array(UnsafeBufferPointer(start: dstBuf.floatChannelData![0], count: Int(dstBuf.frameLength)))
    }
}
