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
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Perfect Paul", identifier: "com.ernie96.DoubleTalkApp.paul", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Vader", identifier: "com.ernie96.DoubleTalkApp.vader", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Big Bob", identifier: "com.ernie96.DoubleTalkApp.bigBob", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Precise Pete", identifier: "com.ernie96.DoubleTalkApp.precisePete", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Ricochet", identifier: "com.ernie96.DoubleTalkApp.ricochet", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Biff", identifier: "com.ernie96.DoubleTalkApp.biff", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Skip", identifier: "com.ernie96.DoubleTalkApp.skip", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"]),
            AVSpeechSynthesisProviderVoice(name: "DoubleTalk Robo Robert", identifier: "com.ernie96.DoubleTalkApp.roboRobert", primaryLanguages: ["en-US"], supportedLanguages: ["en-US"])
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
