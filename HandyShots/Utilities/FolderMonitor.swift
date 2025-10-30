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
        // Detect current system folder
        guard let systemFolder = FolderDetector.detectSystemFolder() else {
            return
        }

        // Check if system folder has changed
        if systemFolder != lastDetectedFolder {
            print("🔄 System screenshot folder changed: \(lastDetectedFolder ?? "nil") → \(systemFolder)")

            lastDetectedFolder = systemFolder

            // Update current folder if user hasn't manually selected one
            let userFolder = UserDefaults.standard.string(forKey: "screenshotFolder")
            if userFolder == nil || userFolder?.isEmpty == true {
                updateFolder(path: systemFolder)
            } else {
                // Notify that system folder changed but we're keeping user selection
                print("ℹ️ System folder changed but keeping user selection: \(currentFolder)")
            }
        }
    }
}
