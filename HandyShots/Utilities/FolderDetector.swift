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
        // Read from macOS system preferences
        // Key: "location" in domain "com.apple.screencapture"
        let key = "location" as CFString
        let domain = "com.apple.screencapture" as CFString

        guard let value = CFPreferencesCopyAppValue(key, domain) else {
            return nil
        }

        // Convert CFPropertyList to String
        if let path = value as? String {
            return standardizePath(path)
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
