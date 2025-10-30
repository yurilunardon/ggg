//
//  FolderMonitor.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import Foundation
import Combine
import AppKit

/// Monitors screenshot folder location changes via polling
class FolderMonitor: ObservableObject {
    // MARK: - Published Properties

    /// Current monitored folder path
    @Published var currentFolder: String = ""

    // MARK: - Private Properties

    /// Timer for polling system preferences
    private var timer: Timer?

    /// Polling interval in seconds
    private let pollingInterval: TimeInterval = 5.0

    /// Last detected system folder
    private var lastDetectedFolder: String?

    // MARK: - Notification Names

    /// Posted when screenshot folder changes
    static let folderDidChangeNotification = Notification.Name("FolderDidChange")

    // MARK: - Initialization

    init() {
        // Set initial folder
        currentFolder = FolderDetector.getCurrentFolder()
        lastDetectedFolder = FolderDetector.detectSystemFolder()

        print("📁 FolderMonitor initialized with folder: \(currentFolder)")
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Start monitoring for folder changes
    func startMonitoring() {
        // Don't create multiple timers
        guard timer == nil else {
            print("⚠️ FolderMonitor already running")
            return
        }

        print("▶️ Starting folder monitoring (polling every \(pollingInterval)s)")

        timer = Timer.scheduledTimer(
            withTimeInterval: pollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkForFolderChange()
        }

        // Ensure timer runs even when menu is open
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Stop monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        print("⏸️ Folder monitoring stopped")
    }

    /// Manually refresh folder path
    func refresh() {
        checkForFolderChange()
    }

    /// Update current folder (when user selects manually)
    /// - Parameter path: New folder path
    func updateFolder(path: String) {
        guard currentFolder != path else { return }

        currentFolder = path
        FolderDetector.saveFolder(path: path)

        print("📁 Folder updated to: \(path)")

        // Notify observers
        NotificationCenter.default.post(
            name: FolderMonitor.folderDidChangeNotification,
            object: nil,
            userInfo: ["path": path]
        )
    }

    // MARK: - Private Methods

    /// Check if system screenshot folder has changed
    private func checkForFolderChange() {
        print("🔍 Checking for folder changes...")

        // Detect current system folder
        guard let systemFolder = FolderDetector.detectSystemFolder() else {
            print("⚠️ Unable to detect system screenshot folder")
            return
        }

        print("📁 System folder detected: \(systemFolder)")
        print("📁 Last known folder: \(lastDetectedFolder ?? "nil")")

        // Check if system folder has changed
        if systemFolder != lastDetectedFolder {
            print("🔄 System screenshot folder changed!")
            print("   From: \(lastDetectedFolder ?? "nil")")
            print("   To: \(systemFolder)")

            lastDetectedFolder = systemFolder

            // Always update current folder to match system
            updateFolder(path: systemFolder)

            // Show notification to user
            showFolderChangeNotification(newFolder: systemFolder)
        } else {
            print("✅ No folder change detected")
        }
    }

    /// Show a notification when screenshot folder changes
    /// - Parameter newFolder: The new folder path
    private func showFolderChangeNotification(newFolder: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Screenshot Folder Changed"
            alert.informativeText = "The system screenshot folder has been updated to:\n\n\(newFolder)"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")

            // Show as floating alert
            if let window = NSApp.windows.first {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }

            print("✅ Notification shown to user about folder change")
        }
    }
}
