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
        
        // Register DoubleTalk voices with the system
        AVSpeechSynthesisProviderVoice.updateSpeechVoices([
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Perfect Paul", identifier: "com.doubletalkapple.voice.0", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Vader", identifier: "com.doubletalkapple.voice.1", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Big Bob", identifier: "com.doubletalkapple.voice.2", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Precise Pete", identifier: "com.doubletalkapple.voice.3", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Ricochet", identifier: "com.doubletalkapple.voice.4", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Biff", identifier: "com.doubletalkapple.voice.5", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Skip", identifier: "com.doubletalkapple.voice.6", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Robo Robert", identifier: "com.doubletalkapple.voice.7", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"])
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
