/*
 * DoubleTalkApp.swift - DoubleTalk iOS Application Entry Point
 */

import SwiftUI
import AVFoundation

@main
struct DoubleTalkApp: App {
    init() {
        // Automatically ensure doubletalkpc.bin in bundle or working folder is copied to App Group container
        if let romData = DoubleTalkSettingsStore.loadROMData() {
            try? DoubleTalkSettingsStore.saveROMData(romData)
        }
        
        // Notify the system to poll the AudioUnit extension for voices
        AVSpeechSynthesisProviderVoice.updateSpeechVoices()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
