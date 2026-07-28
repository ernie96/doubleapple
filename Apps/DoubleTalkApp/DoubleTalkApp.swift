/*
 * DoubleTalkApp.swift - DoubleTalk iOS Application Entry Point
 */

import SwiftUI

@main
struct DoubleTalkApp: App {
    init() {
        // Automatically ensure doubletalkpc.bin in bundle or working folder is copied to App Group container
        if let romData = DoubleTalkSettingsStore.loadROMData() {
            try? DoubleTalkSettingsStore.saveROMData(romData)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
