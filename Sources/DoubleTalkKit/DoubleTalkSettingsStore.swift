/*
 * DoubleTalkSettingsStore.swift - Persistence & ROM Storage Manager
 *
 * Synchronizes user settings and firmware ROM binaries between the main iOS App
 * and the VoiceOver Extension using shared App Group storage.
 */

import Foundation

public final class DoubleTalkSettingsStore {
    public static let groupIdentifier = "group.com.doubletalk.app"
    public static let settingsKey = "DoubleTalkSavedSettings"
    public static let romFilename = "doubletalkpc.bin"

    private static var fileURL: URL? {
        return containerURL?.appendingPathComponent(settingsKey + ".json")
    }

    // MARK: - Settings Persistence

    public static func load() -> DoubleTalkSettings {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let settings = try? JSONDecoder().decode(DoubleTalkSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    public static func save(_ settings: DoubleTalkSettings) {
        if let url = fileURL, let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - ROM Management

    public static var containerURL: URL? {
        // 1. Try hardcoded (works for TrollStore, TestFlight, AppStore, Paid Dev Accounts)
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
            return url
        }
        
        // 2. Try parsing embedded.mobileprovision for AltStore/Sideloadly (Free Dev Accounts)
        let mainBundle = Bundle.main
        let appBundle = Bundle(url: mainBundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())
        
        let paths = [
            mainBundle.path(forResource: "embedded", ofType: "mobileprovision"),
            appBundle?.path(forResource: "embedded", ofType: "mobileprovision")
        ].compactMap { $0 }
        
        for path in paths {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let string = String(data: data, encoding: .isoLatin1),
               let groupsRange = string.range(of: "<key>com.apple.security.application-groups</key>") {
                
                let tail = string[groupsRange.upperBound...]
                if let arrayStart = tail.range(of: "<array>"), let arrayEnd = tail.range(of: "</array>") {
                    let arrayContent = tail[arrayStart.upperBound..<arrayEnd.lowerBound]
                    if let stringStart = arrayContent.range(of: "<string>"), let stringEnd = arrayContent.range(of: "</string>") {
                        let dynamicAppGroup = String(arrayContent[stringStart.upperBound..<stringEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: dynamicAppGroup) {
                            return url
                        }
                    }
                }
            }
        }
        
        return nil
    }

    /// Finds and returns doubletalkpc.bin ROM data from bundle or App Group container
    public static func loadROMData() -> Data? {
        // 1. Search in main / framework bundles
        let bundles = [Bundle.main, Bundle(for: DoubleTalkSettingsStore.self)]
        for bundle in bundles {
            if let url = bundle.url(forResource: "doubletalkpc", withExtension: "bin") {
                if let data = try? Data(contentsOf: url), data.count == 524288 {
                    return data
                }
            }
        }

        // 2. Search in shared App Group container
        if let groupURL = containerURL {
            let romURL = groupURL.appendingPathComponent(romFilename)
            if let data = try? Data(contentsOf: romURL), data.count == 524288 {
                return data
            }
        }

        // 3. Search in Documents directory
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docROM = docs?.appendingPathComponent(romFilename),
           let data = try? Data(contentsOf: docROM), data.count == 524288 {
            return data
        }

        // 4. Search working directory path (for development/CLI)
        let cwdROM = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(romFilename)
        if let data = try? Data(contentsOf: cwdROM), data.count == 524288 {
            return data
        }

        return nil
    }

    /// Save custom ROM data to shared App Group container
    public static func saveROMData(_ data: Data) throws {
        guard data.count == 524288 else {
            throw NSError(domain: "DoubleTalkROM", code: 1, userInfo: [NSLocalizedDescriptionKey: "ROM binary must be exactly 524,288 bytes (512 KB)."])
        }
        guard let groupURL = containerURL else {
            throw NSError(domain: "DoubleTalkROM", code: 2, userInfo: [NSLocalizedDescriptionKey: "App Group container inaccessible."])
        }
        let target = groupURL.appendingPathComponent(romFilename)
        try data.write(to: target, options: .atomic)
    }
}
