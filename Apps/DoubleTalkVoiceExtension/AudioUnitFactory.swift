/*
 * AudioUnitFactory.swift - Audio Unit Extension Factory
 *
 * Implements AUAudioUnitFactory and NSExtensionRequestHandling to instantiate
 * DoubleTalkAudioUnit for iOS system-wide VoiceOver speech synthesis.
 */

import Foundation
import CoreAudioKit
import AVFoundation

@main
public class AudioUnitFactory: NSObject, AUAudioUnitFactory, NSExtensionRequestHandling {
    public static func main() {
        _ = NSExtensionMain(CommandLine.argc, CommandLine.unsafeArgv)
    }

    private var audioUnit: AUAudioUnit?

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try DoubleTalkAudioUnit(componentDescription: componentDescription, options: [])
        return audioUnit!
    }

    public func beginRequest(with context: NSExtensionContext) {
        // Extension lifecycle callback
    }
}
