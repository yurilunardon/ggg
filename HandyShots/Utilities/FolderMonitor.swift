//
//  FolderMonitor.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import Foundation
import Combine

/// Monitors screenshot folder location changes via polling
class FolderMonitor: ObservableObject {
    // MARK: - Published Properties

    /// Current monitored folder path
    @Published var currentFolder: String = ""

    /// Folder change notification message (shows banner when set)
    @Published var folderChangeMessage: String? = nil

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
        // Always detect system folder on init
        let systemFolder = FolderDetector.detectSystemFolder() ?? FolderDetector.getDesktopPath()
        currentFolder = systemFolder
        lastDetectedFolder = systemFolder

        print("🚀 FolderMonitor initialized")
        print("   📁 System folder detected: \(systemFolder)")
        print("   📁 Current folder set to: \(currentFolder)")

        // Save the detected system folder
        FolderDetector.saveFolder(path: systemFolder)
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

            // Set notification message (will trigger banner in UI)
            DispatchQueue.main.async { [weak self] in
                self?.folderChangeMessage = "Screenshot folder changed to: \(FolderDetector.getFolderDisplayName(path: systemFolder))"
            }
        } else {
            print("✅ No folder change detected")
        }
    }
}
