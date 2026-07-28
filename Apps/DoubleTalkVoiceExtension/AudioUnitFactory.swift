/*
 * AudioUnitFactory.swift - Audio Unit Extension Factory
 *
 * Implements AUAudioUnitFactory and NSExtensionRequestHandling to instantiate
 * DoubleTalkAudioUnit for iOS system-wide VoiceOver speech synthesis.
 */

import Foundation
import CoreAudioKit
import AVFoundation

public class AudioUnitFactory: NSObject, AUAudioUnitFactory, NSExtensionRequestHandling {
    private var audioUnit: AUAudioUnit?

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try DoubleTalkAudioUnit(componentDescription: componentDescription, options: [])
        return audioUnit!
    }

    public func beginRequest(with context: NSExtensionContext) {
        // Extension lifecycle callback
    }
}
