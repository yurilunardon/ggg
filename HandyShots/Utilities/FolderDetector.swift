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
        print("🔍 Attempting to read screenshot location from system preferences...")

        // Method 1: Try using UserDefaults (most reliable)
        print("   📍 Trying Method 1: UserDefaults...")
        if let path = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            print("   ✅ Method 1 SUCCESS: Found via UserDefaults: \(path)")
            return standardizePath(path)
        } else {
            print("   ❌ Method 1 FAILED: UserDefaults returned nil")
        }

        // Method 2: Try CFPreferences
        print("   📍 Trying Method 2: CFPreferences...")
        let key = "location" as CFString
        let domain = "com.apple.screencapture" as CFString

        if let value = CFPreferencesCopyAppValue(key, domain) {
            if let path = value as? String {
                print("   ✅ Method 2 SUCCESS: Found via CFPreferences: \(path)")
                return standardizePath(path)
            } else {
                print("   ❌ Method 2 FAILED: Value exists but not a String (type: \(type(of: value)))")
            }
        } else {
            print("   ❌ Method 2 FAILED: CFPreferences returned nil")
        }

        // Method 3: Try using 'defaults read' command
        print("   📍 Trying Method 3: defaults read command...")
        if let path = readScreenshotViaDefaults() {
            print("   ✅ Method 3 SUCCESS: Found via defaults command: \(path)")
            return standardizePath(path)
        } else {
            print("   ❌ Method 3 FAILED: defaults command returned nil")
        }

        print("⚠️ All methods failed - no screenshot location found in system preferences")
        return nil
    }

    /// Read screenshot location using 'defaults read' command
    /// - Returns: Path from defaults command, or nil
    private static func readScreenshotViaDefaults() -> String? {
        let task = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", "com.apple.screencapture", "location"]
        task.standardOutput = pipe
        task.standardError = errorPipe

        do {
            print("      🔧 Executing: /usr/bin/defaults read com.apple.screencapture location")
            try task.run()
            task.waitUntilExit()

            print("      🔧 Process exit code: \(task.terminationStatus)")

            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    print("      🔧 Command output: \(output)")
                    return output
                } else {
                    print("      🔧 Command succeeded but output is empty")
                }
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                if let errorOutput = String(data: errorData, encoding: .utf8) {
                    print("      🔧 Command error: \(errorOutput)")
                }
            }
        } catch {
            print("      🔧 Exception executing command: \(error.localizedDescription)")
        }

        return nil
    }

    /// Get Desktop path as fallback
    /// - Returns: Path to user's Desktop folder
    static func getDesktopPath() -> String {
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
