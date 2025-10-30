//
//  FolderDetector.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import Foundation

/// Utility class for detecting macOS screenshot folder location
class FolderDetector {
    // MARK: - Public Methods

    /// Detect the system screenshot folder location
    /// - Returns: Path to screenshot folder, or nil if unable to detect
    static func detectSystemFolder() -> String? {
        // Method 1: Try reading system preferences for screenshot location
        if let systemFolder = readScreenshotPreference() {
            print("✅ Screenshot folder detected from system preferences: \(systemFolder)")
            return systemFolder
        }

        // Method 2: Fallback to Desktop
        let desktopFolder = getDesktopPath()
        print("ℹ️ Using fallback Desktop folder: \(desktopFolder)")
        return desktopFolder
    }

    /// Get current screenshot folder from UserDefaults or detect new one
    /// - Returns: Path to screenshot folder
    static func getCurrentFolder() -> String {
        // Check if user has already selected a folder
        let userFolder = UserDefaults.standard.string(forKey: "screenshotFolder")

        if let folder = userFolder, !folder.isEmpty {
            return folder
        }

        // No saved folder, detect system folder
        return detectSystemFolder() ?? getDesktopPath()
    }

    /// Save selected folder to UserDefaults
    /// - Parameter path: Path to save
    static func saveFolder(path: String) {
        UserDefaults.standard.set(path, forKey: "screenshotFolder")
        print("💾 Saved screenshot folder: \(path)")
    }

    // MARK: - Private Helper Methods

    /// Read screenshot location from system preferences
    /// - Returns: Path from com.apple.screencapture preferences, or nil
    private static func readScreenshotPreference() -> String? {
        // Method 1: Try using UserDefaults (most reliable)
        if let path = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            print("✅ Found screenshot location via UserDefaults: \(path)")
            return standardizePath(path)
        }

        // Method 2: Try CFPreferences
        let key = "location" as CFString
        let domain = "com.apple.screencapture" as CFString

        if let value = CFPreferencesCopyAppValue(key, domain) {
            if let path = value as? String {
                print("✅ Found screenshot location via CFPreferences: \(path)")
                return standardizePath(path)
            }
        }

        // Method 3: Try using 'defaults read' command
        if let path = readScreenshotViaDefaults() {
            print("✅ Found screenshot location via defaults command: \(path)")
            return standardizePath(path)
        }

        print("⚠️ No screenshot location found in system preferences")
        return nil
    }

    /// Read screenshot location using 'defaults read' command
    /// - Returns: Path from defaults command, or nil
    private static func readScreenshotViaDefaults() -> String? {
        let task = Process()
        let pipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", "com.apple.screencapture", "location"]
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            guard task.terminationStatus == 0 else {
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                return output
            }
        } catch {
            print("⚠️ Error reading defaults: \(error.localizedDescription)")
        }

        return nil
    }

    /// Get Desktop path as fallback
    /// - Returns: Path to user's Desktop folder
    private static func getDesktopPath() -> String {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let desktopPath = homeDirectory.appendingPathComponent("Desktop").path
        return desktopPath
    }

    /// Standardize path by expanding tilde and removing trailing slashes
    /// - Parameter path: Raw path string
    /// - Returns: Standardized path
    private static func standardizePath(_ path: String) -> String {
        var standardPath = (path as NSString).expandingTildeInPath

        // Remove trailing slash if present
        if standardPath.hasSuffix("/") {
            standardPath = String(standardPath.dropLast())
        }

        return standardPath
    }

    /// Check if folder path is accessible
    /// - Parameter path: Path to check
    /// - Returns: True if folder exists and is accessible
    static func isFolderAccessible(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)

        return exists && isDirectory.boolValue
    }

    /// Get display name for folder path
    /// - Parameter path: Full path to folder
    /// - Returns: User-friendly folder name
    static func getFolderDisplayName(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
    }
}
