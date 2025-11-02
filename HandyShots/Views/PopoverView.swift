//
//  PopoverView.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import SwiftUI
import AppKit

/// Main popover interface shown when clicking menu bar icon
struct PopoverView: View {
    // MARK: - Environment Objects

    /// Folder monitor for tracking screenshot folder changes
    @EnvironmentObject var folderMonitor: FolderMonitor

    // MARK: - AppStorage Properties

    /// Flag indicating if this is the first launch
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true

    /// Currently monitored screenshot folder
    @AppStorage("screenshotFolder") private var screenshotFolder: String = ""

    /// Time filter in minutes from settings
    @AppStorage("timeFilter") private var timeFilter: Int = 10

    /// Enable hover zoom preview
    @AppStorage("enableHoverZoom") private var enableHoverZoom: Bool = false

    /// Delete mode: hideFromView or deleteFromDisk
    @AppStorage("deleteMode") private var deleteMode: String = "hideFromView"

    /// Hidden screenshot IDs (for hideFromView mode)
    @AppStorage("hiddenScreenshotIDs") private var hiddenScreenshotIDsData: Data = Data()

    // MARK: - State Properties

    /// Show splash screen on first open
    @State private var showSplash: Bool = true

    /// List of recent screenshots
    @State private var screenshots: [Screenshot] = []

    /// Set of hidden screenshot IDs
    @State private var hiddenScreenshotIDs: Set<String> = []

    /// Timer for refreshing screenshots
    @State private var refreshTimer: Timer?

    /// Selected screenshots for drag & drop
    @State private var selectedScreenshots: Set<String> = []

    /// Last clicked screenshot for shift+click range selection
    @State private var lastSelectedID: String?

    /// Pending deletion confirmation state
    @State private var showDeleteConfirmation: Bool = false
    @State private var pendingDeletion: [Screenshot] = []

    /// Recently hidden screenshots (for Revert functionality)
    @State private var recentlyHiddenIDs: Set<String> = []
    @State private var showRevertBanner: Bool = false

    // MARK: - Body

    var body: some View {
        Group {
            if showSplash {
                // Show animated splash screen
                SplashView(onComplete: {
                    showSplash = false
                })
            } else if isFirstLaunch {
                // Show welcome screen on first launch
                WelcomeView(onFolderSelected: { path in
                    folderMonitor.updateFolder(path: path)
                    screenshotFolder = path
                })
            } else {
                // Show main interface
                mainInterface
            }
        }
        .frame(width: 400, height: 300)
    }

    // MARK: - Main Interface

    private var mainInterface: some View {
        ZStack {
            VStack(spacing: 0) {
                // Compact Header with folder info
                compactHeader

                Divider()

                // Notification banner (if folder changed)
                if let message = folderMonitor.folderChangeMessage {
                    notificationBanner(message: message)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: folderMonitor.folderChangeMessage)
                }

                // Revert banner (if screenshots were hidden)
                if showRevertBanner {
                    revertBanner
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showRevertBanner)
                }

                // Screenshot grid
                screenshotGrid
            }

            // Delete confirmation overlay
            if showDeleteConfirmation {
                deleteConfirmationView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            loadHiddenScreenshotIDs()
            refreshScreenshots()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
            HoverPreviewManager.shared.hidePreview(animated: false)
        }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            // App name row with badges
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)

                Text("HandyShots")
                    .font(.headline)
                    .fontWeight(.bold)

                // Folder badge - clickable
                Button(action: {
                    openSettingsToFolder()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text(URL(fileURLWithPath: folderMonitor.currentFolder).lastPathComponent)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Click to change folder • \(folderMonitor.currentFolder)")

                // Time filter badge - clickable
                Button(action: {
                    openSettingsToTimeFilter()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("\(timeFilter)min")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Click to change time filter • \(timeFilter) minutes")

                Spacer()

                // Settings gear button
                Button(action: {
                    openSettings()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Settings")
            }

            // Selection controls row (left-aligned under title)
            HStack(spacing: 6) {
                // Select All button
                Button(action: { selectAll() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 11))
                        Text("Select All")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(screenshots.isEmpty ? .gray.opacity(0.5) : .blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(screenshots.isEmpty ? Color.clear : Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(screenshots.isEmpty)
                .help(screenshots.isEmpty ? "No screenshots" : "Select all (⌘A)")

                // Deselect All button
                Button(action: { deselectAll() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 11))
                        Text("Deselect All")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedScreenshots.isEmpty ? .gray.opacity(0.5) : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(selectedScreenshots.isEmpty ? Color.clear : Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(selectedScreenshots.isEmpty)
                .help(selectedScreenshots.isEmpty ? "No items selected" : "Deselect all")

                // Trash button
                Button(action: { deleteSelectedScreenshots() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(selectedScreenshots.isEmpty ? .gray.opacity(0.3) : .red)
                }
                .buttonStyle(.plain)
                .disabled(selectedScreenshots.isEmpty)
                .help(selectedScreenshots.isEmpty ? "No items selected" : "Delete \(selectedScreenshots.count) screenshot\(selectedScreenshots.count == 1 ? "" : "s") (⌫)")

                // Selection counter (when items selected) - n/N format
                if !selectedScreenshots.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                        Text("\(selectedScreenshots.count)/\(screenshots.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue)
                    .cornerRadius(4)
                    .help("\(selectedScreenshots.count) of \(screenshots.count) screenshot\(screenshots.count == 1 ? "" : "s") selected")
                }

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }

    // MARK: - Screenshot Grid

    private var screenshotGrid: some View {
        Group {
            if screenshots.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No screenshots yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Screenshots from the last \(timeFilter) minutes will appear here")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Grid of screenshots with selection support
                ScreenshotGridView(
                    screenshots: screenshots,
                    selectedScreenshots: $selectedScreenshots,
                    enableHoverZoom: enableHoverZoom,
                    timeFilterMinutes: timeFilter,
                    isSelectionMode: .constant(true), // Always in selection mode
                    lastSelectedID: $lastSelectedID,
                    onSelectScreenshot: { screenshot, modifiers in
                        handleSelection(screenshot: screenshot, modifiers: modifiers)
                    },
                    onOpenScreenshots: { screenshot in
                        openScreenshots(for: screenshot)
                    }
                )
                .onAppear {
                    // Setup keyboard shortcuts
                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        // Cmd+A: Select all
                        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "a" {
                            selectAll()
                            return nil // consume event
                        }

                        // Cmd+C: Copy selected screenshots
                        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "c" {
                            if !selectedScreenshots.isEmpty {
                                copySelectedScreenshots()
                                return nil // consume event
                            }
                        }

                        // Cmd+X: Cut selected screenshots (move from folder)
                        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "x" {
                            if !selectedScreenshots.isEmpty {
                                cutSelectedScreenshots()
                                return nil // consume event
                            }
                        }

                        // Delete or Backspace: Delete selected screenshots
                        if event.keyCode == 51 || event.keyCode == 117 { // 51 = Delete, 117 = Forward Delete
                            if !selectedScreenshots.isEmpty {
                                deleteSelectedScreenshots()
                                return nil // consume event
                            }
                        }

                        return event
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    /// Delete confirmation view (in-app instead of popup)
    private var deleteConfirmationView: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDeleteConfirmation = false
                        pendingDeletion = []
                    }
                }

            // Confirmation card
            VStack(spacing: 16) {
                // Icon and title
                VStack(spacing: 8) {
                    Image(systemName: deleteMode == "deleteFromDisk" ? "trash.fill" : "eye.slash.fill")
                        .font(.system(size: 36))
                        .foregroundColor(deleteMode == "deleteFromDisk" ? .red : .orange)

                    Text(deleteMode == "deleteFromDisk" ? "Delete Screenshots?" : "Hide Screenshots?")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(deleteMode == "deleteFromDisk" ?
                         "Permanently delete \(pendingDeletion.count) screenshot\(pendingDeletion.count == 1 ? "" : "s")? This cannot be undone." :
                         "Hide \(pendingDeletion.count) screenshot\(pendingDeletion.count == 1 ? "" : "s") from view? Files will remain on disk.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Buttons
                HStack(spacing: 12) {
                    // Cancel button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteConfirmation = false
                            pendingDeletion = []
                        }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)

                    // Confirm button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteConfirmation = false
                            confirmDeletion()
                        }
                    }) {
                        Text(deleteMode == "deleteFromDisk" ? "Delete" : "Hide")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(deleteMode == "deleteFromDisk" ? Color.red : Color.orange)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction) // Enter key
                }
            }
            .padding(20)
            .frame(width: 320)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }

    /// Revert banner for recently hidden screenshots
    private var revertBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.callout)
                .foregroundColor(.orange)

            Text("\(recentlyHiddenIDs.count) screenshot\(recentlyHiddenIDs.count == 1 ? "" : "s") hidden")
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                revertHiddenScreenshots()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption)
                    Text("Revert")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button(action: {
                withAnimation {
                    showRevertBanner = false
                    recentlyHiddenIDs.removeAll()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }

    /// Notification banner for folder changes
    private func notificationBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.callout)
                .foregroundColor(.blue)

            Text(message)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                withAnimation {
                    folderMonitor.folderChangeMessage = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            // Auto-dismiss after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation {
                    folderMonitor.folderChangeMessage = nil
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Check if current folder exists and is accessible
    private var folderExists: Bool {
        FolderDetector.isFolderAccessible(path: folderMonitor.currentFolder)
    }

    // MARK: - Actions

    /// Handle screenshot selection with modifier keys (macOS Finder-style)
    private func handleSelection(screenshot: Screenshot, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            // Cmd+Click: toggle selection
            if selectedScreenshots.contains(screenshot.id) {
                selectedScreenshots.remove(screenshot.id)
            } else {
                selectedScreenshots.insert(screenshot.id)
                lastSelectedID = screenshot.id
            }
        } else if modifiers.contains(.shift), let lastID = lastSelectedID {
            // Shift+Click: select range
            if let startIndex = screenshots.firstIndex(where: { $0.id == lastID }),
               let endIndex = screenshots.firstIndex(where: { $0.id == screenshot.id }) {
                let range = min(startIndex, endIndex)...max(startIndex, endIndex)
                for index in range {
                    selectedScreenshots.insert(screenshots[index].id)
                }
            }
        } else {
            // Regular click
            if selectedScreenshots.contains(screenshot.id) {
                // Already selected
                if selectedScreenshots.count == 1 {
                    // Single item selected - toggle it off
                    selectedScreenshots.removeAll()
                    lastSelectedID = nil
                }
                // If multiple selected, keep the selection for double-click to work
            } else {
                // Not selected - select only this one
                selectedScreenshots = [screenshot.id]
                lastSelectedID = screenshot.id
            }
        }
    }

    /// Select all screenshots
    private func selectAll() {
        selectedScreenshots = Set(screenshots.map { $0.id })
    }

    /// Deselect all screenshots
    private func deselectAll() {
        selectedScreenshots.removeAll()
        lastSelectedID = nil
    }

    /// Delete selected screenshots based on deleteMode setting
    private func deleteSelectedScreenshots() {
        guard !selectedScreenshots.isEmpty else { return }

        // Get the selected screenshot objects and show confirmation
        pendingDeletion = screenshots.filter { selectedScreenshots.contains($0.id) }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showDeleteConfirmation = true
        }
    }

    /// Confirm and execute deletion after user confirmation
    private func confirmDeletion() {
        guard !pendingDeletion.isEmpty else { return }

        if deleteMode == "deleteFromDisk" {
            // Delete files from disk
            let fileManager = FileManager.default
            var deletedCount = 0

            for screenshot in pendingDeletion {
                do {
                    try fileManager.removeItem(at: screenshot.url)
                    deletedCount += 1
                    print("✅ Deleted file: \(screenshot.url.lastPathComponent)")
                } catch {
                    print("❌ Failed to delete file: \(screenshot.url.lastPathComponent) - \(error.localizedDescription)")
                    // Show error alert
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Delete Failed"
                    errorAlert.informativeText = "Could not delete \(screenshot.url.lastPathComponent): \(error.localizedDescription)"
                    errorAlert.alertStyle = .warning
                    errorAlert.runModal()
                }
            }

            print("🗑️ Deleted \(deletedCount) of \(pendingDeletion.count) files from disk")
        } else {
            // "hideFromView" mode - add IDs to hidden list without deleting files
            let hiddenIDs = Set(pendingDeletion.map { $0.id })
            for screenshot in pendingDeletion {
                hiddenScreenshotIDs.insert(screenshot.id)
            }
            saveHiddenScreenshotIDs()
            print("👁️ Hiding \(pendingDeletion.count) screenshot(s) from view (files remain on disk)")

            // Show revert banner for 5 seconds
            recentlyHiddenIDs = hiddenIDs
            withAnimation {
                showRevertBanner = true
            }

            // Auto-hide banner after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    self.showRevertBanner = false
                    self.recentlyHiddenIDs.removeAll()
                }
            }
        }

        // Remove deleted/hidden screenshots from the display list
        let idsToRemove = Set(pendingDeletion.map { $0.id })
        screenshots.removeAll { screenshot in
            idsToRemove.contains(screenshot.id)
        }

        // Clear selection and pending
        selectedScreenshots.removeAll()
        lastSelectedID = nil
        pendingDeletion = []

        // Refresh to ensure consistency
        refreshScreenshots()
    }

    /// Revert recently hidden screenshots
    private func revertHiddenScreenshots() {
        // Remove from hidden list
        for id in recentlyHiddenIDs {
            hiddenScreenshotIDs.remove(id)
        }
        saveHiddenScreenshotIDs()

        // Hide banner
        withAnimation {
            showRevertBanner = false
            recentlyHiddenIDs.removeAll()
        }

        // Refresh to show the restored screenshots
        refreshScreenshots()

        print("↩️ Reverted \(recentlyHiddenIDs.count) hidden screenshot(s)")
    }

    /// Copy selected screenshots to pasteboard (Cmd+C)
    private func copySelectedScreenshots() {
        guard !selectedScreenshots.isEmpty else { return }

        let selectedURLs = screenshots
            .filter { selectedScreenshots.contains($0.id) }
            .map { $0.url }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(selectedURLs as [NSURL])

        print("📋 Copied \(selectedURLs.count) screenshot(s) to clipboard")
    }

    /// Cut selected screenshots (Cmd+X) - copy and move from folder
    private func cutSelectedScreenshots() {
        guard !selectedScreenshots.isEmpty else { return }

        let selectedURLs = screenshots
            .filter { selectedScreenshots.contains($0.id) }
            .map { $0.url }

        // Copy to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(selectedURLs as [NSURL])

        // Move files from monitored folder to temporary location (Downloads folder)
        let fileManager = FileManager.default
        let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        var movedCount = 0

        for url in selectedURLs {
            let destinationURL = downloadsURL.appendingPathComponent(url.lastPathComponent)
            do {
                // If file exists at destination, remove it first
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: url, to: destinationURL)
                movedCount += 1
                print("✂️ Moved file to Downloads: \(url.lastPathComponent)")
            } catch {
                print("❌ Failed to move file: \(url.lastPathComponent) - \(error.localizedDescription)")
            }
        }

        print("✂️ Cut \(movedCount) of \(selectedURLs.count) screenshot(s) to clipboard and moved to Downloads")

        // Clear selection and refresh
        selectedScreenshots.removeAll()
        lastSelectedID = nil
        refreshScreenshots()
    }

    /// Open screenshot(s) - if selected, open all selected ones
    private func openScreenshots(for screenshot: Screenshot) {
        if selectedScreenshots.contains(screenshot.id) && selectedScreenshots.count > 1 {
            // Open all selected screenshots
            let selectedURLs = screenshots
                .filter { selectedScreenshots.contains($0.id) }
                .map { $0.url }

            for url in selectedURLs {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Open just this one
            NSWorkspace.shared.open(screenshot.url)
        }
    }

    /// Open Settings window
    private func openSettings() {
        // Try to find and activate existing settings window
        if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Create new settings window
            let settingsView = SettingsView()
                .environmentObject(folderMonitor)
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Settings"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 500, height: 600))
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Open Settings to folder section
    private func openSettingsToFolder() {
        openSettings()
        // Notify to highlight folder section
        NotificationCenter.default.post(name: NSNotification.Name("HighlightSettingsSection"), object: nil, userInfo: ["section": "folder"])
    }

    /// Open Settings to time filter section
    private func openSettingsToTimeFilter() {
        openSettings()
        // Notify to highlight time filter section
        NotificationCenter.default.post(name: NSNotification.Name("HighlightSettingsSection"), object: nil, userInfo: ["section": "timeFilter"])
    }

    // MARK: - Screenshot Management

    /// Load hidden screenshot IDs from persistent storage
    private func loadHiddenScreenshotIDs() {
        if let decoded = try? JSONDecoder().decode(Set<String>.self, from: hiddenScreenshotIDsData) {
            hiddenScreenshotIDs = decoded
        }
    }

    /// Save hidden screenshot IDs to persistent storage
    private func saveHiddenScreenshotIDs() {
        if let encoded = try? JSONEncoder().encode(hiddenScreenshotIDs) {
            hiddenScreenshotIDsData = encoded
        }
    }

    /// Refresh the list of screenshots
    private func refreshScreenshots() {
        let folder = folderMonitor.currentFolder
        let minutes = timeFilter

        DispatchQueue.global(qos: .userInitiated).async {
            let scanned = ScreenshotScanner.scanFolder(path: folder, withinMinutes: minutes)

            DispatchQueue.main.async {
                // Filter out hidden screenshots
                self.screenshots = scanned.filter { !self.hiddenScreenshotIDs.contains($0.id) }
            }
        }
    }

    /// Start timer to refresh screenshots periodically (instant refresh every 0.5s)
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            refreshScreenshots()
        }
    }

    /// Stop refresh timer
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Screenshot Grid View

struct ScreenshotGridView: NSViewRepresentable {
    let screenshots: [Screenshot]
    @Binding var selectedScreenshots: Set<String>
    let enableHoverZoom: Bool
    let timeFilterMinutes: Int
    @Binding var isSelectionMode: Bool
    @Binding var lastSelectedID: String?
    let onSelectScreenshot: (Screenshot, NSEvent.ModifierFlags) -> Void
    let onOpenScreenshots: (Screenshot) -> Void

    func makeNSView(context: Context) -> ScreenshotGridNSView {
        let view = ScreenshotGridNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: ScreenshotGridNSView, context: Context) {
        nsView.screenshots = screenshots
        nsView.selectedScreenshots = selectedScreenshots
        nsView.enableHoverZoom = enableHoverZoom
        nsView.timeFilterMinutes = timeFilterMinutes
        nsView.isSelectionMode = isSelectionMode
        nsView.onSelectScreenshot = onSelectScreenshot
        nsView.onOpenScreenshots = onOpenScreenshots
        nsView.onDeselectAll = {
            selectedScreenshots.removeAll()
            lastSelectedID = nil
        }
        nsView.onBatchSelect = { ids in
            selectedScreenshots = ids
        }
        nsView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        var parent: ScreenshotGridView

        init(parent: ScreenshotGridView) {
            self.parent = parent
        }
    }
}

// MARK: - Drag Selection View

class DragSelectionView: NSView {
    weak var parentScrollView: ScreenshotGridNSView?

    private var selectionStartPoint: NSPoint?
    private var selectionCurrentPoint: NSPoint?
    private var isDraggingSelection: Bool = false
    private var autoScrollTimer: Timer?

    /// Bounds of the actual grid content (where thumbnails are)
    var gridBounds: NSRect = .zero

    // Flip coordinate system so origin is top-left
    override var isFlipped: Bool {
        return true
    }

    // Accept first mouse to handle clicks properly
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        // Check if we clicked on a thumbnail
        let clickedThumbnail = subviews.first { view in
            view is ThumbnailNSView && view.frame.contains(point)
        }

        // If we clicked on empty space, start drag selection
        if clickedThumbnail == nil {
            selectionStartPoint = point
            selectionCurrentPoint = point
            isDraggingSelection = false // Will become true in mouseDragged

            // Make this view the first responder to ensure we get mouseUp
            if let window = self.window {
                window.makeFirstResponder(self)
            }
        } else {
            // Let the thumbnail handle it
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard selectionStartPoint != nil else {
            super.mouseDragged(with: event)
            return
        }

        isDraggingSelection = true

        // Convert mouse position
        let actualPoint = convert(event.locationInWindow, from: nil)

        // Clamp to full view bounds
        let clampedPoint = NSPoint(
            x: max(0, min(actualPoint.x, bounds.width)),
            y: max(0, min(actualPoint.y, bounds.height))
        )
        selectionCurrentPoint = clampedPoint

        // Handle auto-scrolling when near edges (use clamped point)
        handleAutoScroll(at: clampedPoint)

        // Redraw to show selection rectangle
        needsDisplay = true

        // Update selection based on current rectangle
        updateSelectionInRect()
    }

    private func handleAutoScroll(at point: NSPoint?) {
        guard let point = point,
              let scrollView = parentScrollView else {
            stopAutoScroll()
            return
        }

        // Get visible rect in scroll view
        let visibleRect = scrollView.documentVisibleRect
        let scrollThreshold: CGFloat = 30 // pixels from edge to trigger scroll

        // Check if near top or bottom edge
        let distanceFromTop = point.y - visibleRect.minY
        let distanceFromBottom = visibleRect.maxY - point.y

        if distanceFromTop < scrollThreshold || distanceFromBottom < scrollThreshold {
            // Start auto-scroll if not already running
            if autoScrollTimer == nil {
                autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
                    self?.performAutoScroll()
                }
            }
        } else {
            stopAutoScroll()
        }
    }

    private func performAutoScroll() {
        guard let point = selectionCurrentPoint,
              let scrollView = parentScrollView else {
            stopAutoScroll()
            return
        }

        let visibleRect = scrollView.documentVisibleRect
        let scrollThreshold: CGFloat = 30
        let scrollSpeed: CGFloat = 5

        var newOrigin = visibleRect.origin

        // Scroll up if near top
        if point.y - visibleRect.minY < scrollThreshold {
            newOrigin.y = max(0, newOrigin.y - scrollSpeed)
        }
        // Scroll down if near bottom
        else if visibleRect.maxY - point.y < scrollThreshold {
            // Calculate maximum scroll position (content height - visible height)
            let contentHeight = scrollView.documentView?.frame.height ?? 0
            let maxY = max(0, contentHeight - visibleRect.height)
            newOrigin.y = min(maxY, newOrigin.y + scrollSpeed)
        }

        // Perform scroll
        if newOrigin != visibleRect.origin {
            scrollView.contentView.scroll(to: newOrigin)
            scrollView.reflectScrolledClipView(scrollView.contentView)

            // Update selection during scroll
            needsDisplay = true
            updateSelectionInRect()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    override func mouseUp(with event: NSEvent) {
        // Stop auto-scrolling
        stopAutoScroll()

        if isDraggingSelection {
            // Finalize selection
            updateSelectionInRect()
        } else if selectionStartPoint != nil {
            // Click on empty area without drag - deselect all
            parentScrollView?.onDeselectAll?()
        }

        // Clear selection rectangle
        selectionStartPoint = nil
        selectionCurrentPoint = nil
        isDraggingSelection = false
        needsDisplay = true
    }

    private func updateSelectionInRect() {
        guard let scrollView = parentScrollView,
              let startPoint = selectionStartPoint,
              let currentPoint = selectionCurrentPoint else { return }

        // Calculate selection rectangle
        let selectionRect = NSRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )

        // Find thumbnails that intersect with selection rectangle
        var selectedIDs = Set<String>()
        for view in subviews {
            guard let thumbnailView = view as? ThumbnailNSView,
                  let screenshot = thumbnailView.screenshot else { continue }

            if view.frame.intersects(selectionRect) {
                selectedIDs.insert(screenshot.id)
            }
        }

        // Update selection with all selected IDs
        scrollView.onBatchSelect?(selectedIDs)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw selection rectangle if dragging
        if isDraggingSelection,
           let startPoint = selectionStartPoint,
           let currentPoint = selectionCurrentPoint {

            // Clamp both points to view bounds
            let clampedStart = NSPoint(
                x: max(0, min(startPoint.x, bounds.width)),
                y: max(0, min(startPoint.y, bounds.height))
            )
            let clampedCurrent = NSPoint(
                x: max(0, min(currentPoint.x, bounds.width)),
                y: max(0, min(currentPoint.y, bounds.height))
            )

            let selectionRect = NSRect(
                x: min(clampedStart.x, clampedCurrent.x),
                y: min(clampedStart.y, clampedCurrent.y),
                width: abs(clampedCurrent.x - clampedStart.x),
                height: abs(clampedCurrent.y - clampedStart.y)
            )

            // Fill with semi-transparent blue
            NSColor.systemBlue.withAlphaComponent(0.2).setFill()
            selectionRect.fill()

            // Stroke with blue border
            NSColor.systemBlue.setStroke()
            let borderPath = NSBezierPath(rect: selectionRect)
            borderPath.lineWidth = 2
            borderPath.stroke()
        }
    }
}

// MARK: - Screenshot Grid NSView

class ScreenshotGridNSView: NSScrollView {
    var screenshots: [Screenshot] = []
    var selectedScreenshots: Set<String> = []
    var enableHoverZoom: Bool = false
    var timeFilterMinutes: Int = 10
    var isSelectionMode: Bool = false
    var onSelectScreenshot: ((Screenshot, NSEvent.ModifierFlags) -> Void)?
    var onOpenScreenshots: ((Screenshot) -> Void)?
    var onDeselectAll: (() -> Void)?
    var onBatchSelect: ((Set<String>) -> Void)?
    var coordinator: ScreenshotGridView.Coordinator?

    private var thumbnailViews: [ThumbnailNSView] = []
    private var containerView: DragSelectionView!
    private var updateTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupScrollView()
        startUpdateTimer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollView()
        startUpdateTimer()
    }

    deinit {
        updateTimer?.invalidate()
    }

    private func setupScrollView() {
        hasVerticalScroller = true
        hasHorizontalScroller = false
        autohidesScrollers = true
        backgroundColor = .clear
        drawsBackground = false

        containerView = DragSelectionView(frame: .zero)
        containerView.parentScrollView = self
        documentView = containerView
    }

    private func startUpdateTimer() {
        // Update thumbnails every second to refresh expiring indicators
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.thumbnailViews.forEach { $0.needsDisplay = true }
        }
    }

    override func layout() {
        super.layout()
        layoutThumbnails()
    }

    private func layoutThumbnails() {
        // Clear existing views
        thumbnailViews.forEach { $0.removeFromSuperview() }
        thumbnailViews.removeAll()

        let padding: CGFloat = 16
        let itemWidth: CGFloat = 80
        let itemHeight: CGFloat = 100
        let spacing: CGFloat = 8
        let cols = 4

        var x: CGFloat = padding
        var y: CGFloat = padding

        for (index, screenshot) in screenshots.enumerated() {
            let col = index % cols
            let row = index / cols

            x = padding + CGFloat(col) * (itemWidth + spacing)
            y = padding + CGFloat(row) * (itemHeight + spacing)

            let frame = NSRect(x: x, y: y, width: itemWidth, height: itemHeight)
            let thumbnailView = ThumbnailNSView()
            thumbnailView.frame = frame
            thumbnailView.screenshot = screenshot
            thumbnailView.isSelected = selectedScreenshots.contains(screenshot.id)
            thumbnailView.isSelectionMode = isSelectionMode
            thumbnailView.enableHoverZoom = enableHoverZoom
            thumbnailView.timeFilterMinutes = timeFilterMinutes
            thumbnailView.onSelect = { [weak self] modifiers in
                self?.onSelectScreenshot?(screenshot, modifiers)
            }
            thumbnailView.onOpen = { [weak self] in
                self?.onOpenScreenshots?(screenshot)
            }
            thumbnailView.onGetSelectedScreenshots = { [weak self] in
                guard let self = self else { return [] }
                return self.screenshots.filter { self.selectedScreenshots.contains($0.id) }
            }

            containerView.addSubview(thumbnailView)
            thumbnailViews.append(thumbnailView)
        }

        // Set content size (ensure minimum height to cover visible area for drag selection)
        let rows = (screenshots.count + cols - 1) / cols
        let calculatedHeight = padding + CGFloat(rows) * (itemHeight + spacing)
        let minHeight = max(calculatedHeight, frame.height)
        containerView.frame = NSRect(x: 0, y: 0, width: frame.width, height: minHeight)

        // Calculate grid bounds (where thumbnails actually are)
        let gridWidth = padding * 2 + CGFloat(cols) * itemWidth + CGFloat(cols - 1) * spacing
        let gridHeight = padding + CGFloat(rows) * (itemHeight + spacing)
        containerView.gridBounds = NSRect(x: 0, y: 0, width: gridWidth, height: gridHeight)
    }
}

// MARK: - Thumbnail NSView

class ThumbnailNSView: NSView {
    var screenshot: Screenshot?
    var isSelected: Bool = false
    var isSelectionMode: Bool = false
    var enableHoverZoom: Bool = false
    var onSelect: ((NSEvent.ModifierFlags) -> Void)?
    var onOpen: (() -> Void)?
    var onGetSelectedScreenshots: (() -> [Screenshot])?
    var timeFilterMinutes: Int = 10 // Time filter from settings

    @AppStorage("dragMode") private var dragMode: String = "copy"

    private var previewTimer: Timer?
    private var isDragging: Bool = false
    private var mouseDownPoint: NSPoint?
    private var dragThreshold: CGFloat = 5.0 // pixels to move before considering it a drag
    private var trackingArea: NSTrackingArea?
    private var clickTimer: Timer?
    private var clickCount: Int = 0

    private var isHovering: Bool = false {
        didSet {
            if isHovering && enableHoverZoom {
                // Start timer to show preview after 2 seconds
                previewTimer?.invalidate()
                previewTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    self?.showPreview()
                }
            } else {
                // Cancel timer and hide preview
                previewTimer?.invalidate()
                previewTimer = nil
                HoverPreviewManager.shared.hidePreview()
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // Register for drag & drop
        registerForDraggedTypes([.fileURL])

        // Setup tracking area for hover
        updateTrackingAreas()
    }

    override func layout() {
        super.layout()
        // Update tracking areas when layout changes
        updateTrackingAreas()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        // Ensure hover state is updated even if mouseEntered doesn't fire
        super.mouseMoved(with: event)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    override func mouseDown(with event: NSEvent) {
        // Reset drag flag and save mouse position
        isDragging = false
        mouseDownPoint = event.locationInWindow

        // Cancel preview timer on mouse down
        previewTimer?.invalidate()
        previewTimer = nil
        HoverPreviewManager.shared.hidePreview(animated: false)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let screenshot = screenshot else { return }

        // Check if we've moved enough to consider this a drag
        if let downPoint = mouseDownPoint {
            let currentPoint = event.locationInWindow
            let distance = hypot(currentPoint.x - downPoint.x, currentPoint.y - downPoint.y)

            // Only start drag if moved more than threshold
            guard distance > dragThreshold else { return }
        }

        // Mark that we're dragging
        isDragging = true

        // Check if we should drag multiple selected files
        let screenshotsToDrag: [Screenshot]
        if isSelected, let selectedScreenshots = onGetSelectedScreenshots?(), selectedScreenshots.count > 1 {
            // Drag all selected screenshots
            screenshotsToDrag = selectedScreenshots
        } else {
            // Drag just this one
            screenshotsToDrag = [screenshot]
        }

        // Create drag items for each screenshot
        var dragItems: [NSDraggingItem] = []

        for (index, screenshotToDrag) in screenshotsToDrag.enumerated() {
            let fileURL = screenshotToDrag.url as NSURL
            let item = NSDraggingItem(pasteboardWriter: fileURL)

            // Set drag image - start slightly bigger than thumbnail (90px)
            if let thumbnail = screenshotToDrag.thumbnail {
                let dragImage = thumbnail

                // Start slightly bigger than thumbnail (80x80 -> 90x90)
                let startSize: CGFloat = 90

                // Offset each image slightly for multi-file drag
                let offset: CGFloat = CGFloat(index) * 4
                let startFrame = NSRect(
                    x: offset, y: -offset,
                    width: startSize,
                    height: startSize
                )

                // Set the dragging frame
                item.setDraggingFrame(startFrame, contents: dragImage)

                // Configure to animate to destination - grows as you drag
                item.imageComponentsProvider = {
                    let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)
                    component.contents = dragImage
                    // Final size when dragging away
                    let finalSize: CGFloat = 120
                    component.frame = NSRect(x: offset, y: -offset, width: finalSize, height: finalSize)
                    return [component]
                }
            }

            dragItems.append(item)
        }

        // Start dragging session with all items
        let session = beginDraggingSession(with: dragItems, event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func mouseUp(with event: NSEvent) {
        // Only handle click if we didn't drag
        guard !isDragging else {
            isDragging = false
            return
        }

        // Handle double-click
        if event.clickCount == 2 {
            // Double click opens
            clickTimer?.invalidate()
            clickTimer = nil
            clickCount = 0
            onOpen?()
        } else if event.clickCount == 1 {
            // Single click toggles selection (simulate Cmd to toggle)
            onSelect?(NSEvent.ModifierFlags.command)
        }

        isDragging = false
    }

    private func showPreview() {
        guard let screenshot = screenshot else { return }

        // Get the image rect in window coordinates
        let imageRect = NSRect(x: 0, y: 20, width: 80, height: 80)
        let imageRectInWindow = convert(imageRect, to: nil)

        // Convert to screen coordinates
        let frameInScreen = window?.convertToScreen(imageRectInWindow) ?? .zero
        HoverPreviewManager.shared.showPreview(for: screenshot, over: frameInScreen)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let screenshot = screenshot else { return }

        // Image area: 80x80 at top, text area: 20px at bottom
        let imageRect = NSRect(x: 0, y: 20, width: 80, height: 80)
        let textRect = NSRect(x: 0, y: 0, width: 80, height: 20)

        // Draw thumbnail
        if let thumbnail = screenshot.thumbnail {
            // Save graphics state
            NSGraphicsContext.current?.saveGraphicsState()

            // Create rounded rect path for clipping
            let clipPath = NSBezierPath(roundedRect: imageRect, xRadius: 8, yRadius: 8)
            clipPath.addClip()

            // Draw image
            thumbnail.draw(in: imageRect)

            // Restore graphics state
            NSGraphicsContext.current?.restoreGraphicsState()

            // Draw border (selection or countdown)
            let secondsRemaining = secondsUntilExpiration(for: screenshot)

            if isSelected {
                // Selected: blue border
                NSColor.systemBlue.setStroke()
                let borderPath = NSBezierPath(roundedRect: imageRect, xRadius: 8, yRadius: 8)
                borderPath.lineWidth = 3
                borderPath.stroke()
            } else if secondsRemaining <= 30 && secondsRemaining > 5 {
                // Countdown border (30-5 seconds)
                NSGraphicsContext.current?.saveGraphicsState()

                // Calculate progress (0.0 to 1.0, where 1.0 is full border at 30s)
                let progress = CGFloat(secondsRemaining) / 30.0

                // Smooth color interpolation based on remaining time
                // Color gradient: Green (30s) -> Yellow (22s) -> Orange (15s) -> Red (8s) -> Dark Red (5s)
                let borderColor: NSColor
                let t = CGFloat(secondsRemaining)

                if t > 22 {
                    // Green to Yellow (30s -> 22s)
                    let factor = (t - 22) / 8  // 0.0 at 22s, 1.0 at 30s
                    borderColor = NSColor(
                        calibratedRed: 0.2 + (factor * 0.8),  // Yellow=1.0, Green=0.2
                        green: 0.8,                            // Both have high green
                        blue: 0.0,
                        alpha: 1.0
                    )
                } else if t > 15 {
                    // Yellow to Orange (22s -> 15s)
                    let factor = (t - 15) / 7  // 0.0 at 15s, 1.0 at 22s
                    borderColor = NSColor(
                        calibratedRed: 1.0,
                        green: 0.5 + (factor * 0.3),  // Orange=0.5, Yellow=0.8
                        blue: 0.0,
                        alpha: 1.0
                    )
                } else if t > 8 {
                    // Orange to Red (15s -> 8s)
                    let factor = (t - 8) / 7  // 0.0 at 8s, 1.0 at 15s
                    borderColor = NSColor(
                        calibratedRed: 1.0,
                        green: 0.0 + (factor * 0.5),  // Red=0.0, Orange=0.5
                        blue: 0.0,
                        alpha: 1.0
                    )
                } else {
                    // Red to Dark Red (8s -> 5s)
                    let factor = (t - 5) / 3  // 0.0 at 5s, 1.0 at 8s
                    borderColor = NSColor(
                        calibratedRed: 0.7 + (factor * 0.3),  // Dark Red=0.7, Red=1.0
                        green: 0.0,
                        blue: 0.0,
                        alpha: 1.0
                    )
                }

                // Draw the countdown border as a path that decreases
                let lineWidth: CGFloat = 3
                borderColor.setStroke()

                // Create a path that goes around the rectangle for 'progress' amount
                let rect = imageRect
                let cornerRadius: CGFloat = 8
                let perimeter = 2 * (rect.width + rect.height) - 8 * cornerRadius + 2 * .pi * cornerRadius
                let lengthToDraw = perimeter * progress

                let path = NSBezierPath()
                var currentLength: CGFloat = 0

                // Start from top-left, go clockwise
                // Top edge
                let topStart = NSPoint(x: rect.minX + cornerRadius, y: rect.maxY)
                path.move(to: topStart)

                let topLength = rect.width - 2 * cornerRadius
                if currentLength + topLength <= lengthToDraw {
                    path.line(to: NSPoint(x: rect.maxX - cornerRadius, y: rect.maxY))
                    currentLength += topLength
                } else {
                    path.line(to: NSPoint(x: topStart.x + (lengthToDraw - currentLength), y: rect.maxY))
                    path.lineWidth = lineWidth
                    path.stroke()
                    NSGraphicsContext.current?.restoreGraphicsState()
                    return
                }

                // Top-right corner arc
                let arcLength = (.pi / 2) * cornerRadius
                if currentLength + arcLength <= lengthToDraw {
                    path.appendArc(withCenter: NSPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                                   radius: cornerRadius, startAngle: 90, endAngle: 0, clockwise: true)
                    currentLength += arcLength
                } else {
                    let angle = 90 - ((lengthToDraw - currentLength) / cornerRadius) * (180 / .pi)
                    path.appendArc(withCenter: NSPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                                   radius: cornerRadius, startAngle: 90, endAngle: angle, clockwise: true)
                    path.lineWidth = lineWidth
                    path.stroke()
                    NSGraphicsContext.current?.restoreGraphicsState()
                    return
                }

                // Right edge
                let rightLength = rect.height - 2 * cornerRadius
                if currentLength + rightLength <= lengthToDraw {
                    path.line(to: NSPoint(x: rect.maxX, y: rect.minY + cornerRadius))
                    currentLength += rightLength
                } else {
                    path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - cornerRadius - (lengthToDraw - currentLength)))
                    path.lineWidth = lineWidth
                    path.stroke()
                    NSGraphicsContext.current?.restoreGraphicsState()
                    return
                }

                // Bottom-right corner arc
                if currentLength + arcLength <= lengthToDraw {
                    path.appendArc(withCenter: NSPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                                   radius: cornerRadius, startAngle: 0, endAngle: -90, clockwise: true)
                    currentLength += arcLength
                } else {
                    let angle = -((lengthToDraw - currentLength) / cornerRadius) * (180 / .pi)
                    path.appendArc(withCenter: NSPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                                   radius: cornerRadius, startAngle: 0, endAngle: angle, clockwise: true)
                    path.lineWidth = lineWidth
                    path.stroke()
                    NSGraphicsContext.current?.restoreGraphicsState()
                    return
                }

                // Bottom edge
                if currentLength + topLength <= lengthToDraw {
                    path.line(to: NSPoint(x: rect.minX + cornerRadius, y: rect.minY))
                    currentLength += topLength
                } else {
                    path.line(to: NSPoint(x: rect.maxX - cornerRadius - (lengthToDraw - currentLength), y: rect.minY))
                    path.lineWidth = lineWidth
                    path.stroke()
                    NSGraphicsContext.current?.restoreGraphicsState()
                    return
                }

                // Bottom-left corner arc
                if currentLength + arcLength <= lengthToDraw {
                    path.appendArc(withCenter: NSPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                                   radius: cornerRadius, startAngle: -90, endAngle: -180, clockwise: true)
                    currentLength += arcLength
                } else {
                    let angle = -90 - ((lengthToDraw - currentLength) / cornerRadius) * (180 / .pi)
                    path.appendArc(withCenter: NSPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                                   radius: cornerRadius, startAngle: -90, endAngle: angle, clockwise: true)
                    path.lineWidth = lineWidth
                    path.stroke()
                    NSGraphicsContext.current?.restoreGraphicsState()
                    return
                }

                // Left edge
                if currentLength + rightLength <= lengthToDraw {
                    path.line(to: NSPoint(x: rect.minX, y: rect.maxY - cornerRadius))
                    currentLength += rightLength
                } else {
                    path.line(to: NSPoint(x: rect.minX, y: rect.minY + cornerRadius + (lengthToDraw - currentLength)))
                    path.lineWidth = lineWidth
                    path.stroke()
                    NSGraphicsContext.current?.restoreGraphicsState()
                    return
                }

                // Top-left corner arc
                if currentLength + arcLength <= lengthToDraw {
                    path.appendArc(withCenter: NSPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                                   radius: cornerRadius, startAngle: 180, endAngle: 90, clockwise: true)
                } else {
                    let angle = 180 - ((lengthToDraw - currentLength) / cornerRadius) * (180 / .pi)
                    path.appendArc(withCenter: NSPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                                   radius: cornerRadius, startAngle: 180, endAngle: angle, clockwise: true)
                }

                path.lineWidth = lineWidth
                path.lineCapStyle = .round
                path.stroke()

                NSGraphicsContext.current?.restoreGraphicsState()
            } else {
                // Not selected and not in countdown: subtle gray border
                NSColor.gray.withAlphaComponent(0.3).setStroke()
                let borderPath = NSBezierPath(roundedRect: imageRect, xRadius: 8, yRadius: 8)
                borderPath.lineWidth = 1
                borderPath.stroke()
            }

            // Always show checkbox (smaller, square with rounded corners)
            let checkboxSize: CGFloat = 14
            let checkboxRect = NSRect(
                x: imageRect.minX + 4,
                y: imageRect.maxY - checkboxSize - 4,
                width: checkboxSize,
                height: checkboxSize
            )

            NSGraphicsContext.current?.saveGraphicsState()

            // Draw checkbox rounded square with fill
            let cornerRadius: CGFloat = 3
            let squarePath = NSBezierPath(roundedRect: checkboxRect, xRadius: cornerRadius, yRadius: cornerRadius)
            if isSelected {
                NSColor.systemBlue.setFill()
            } else {
                NSColor.white.withAlphaComponent(0.5).setFill()
            }
            squarePath.fill()

            // Draw white border
            NSColor.white.setStroke()
            squarePath.lineWidth = 1.5
            squarePath.stroke()

            // Draw checkmark icon if selected
            if isSelected {
                let iconSize: CGFloat = 8
                let iconRect = NSRect(
                    x: checkboxRect.midX - iconSize / 2,
                    y: checkboxRect.midY - iconSize / 2,
                    width: iconSize,
                    height: iconSize
                )
                let checkImage = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
                checkImage?.isTemplate = true
                NSColor.white.set()
                checkImage?.draw(in: iconRect)
            }

            NSGraphicsContext.current?.restoreGraphicsState()

            // Show smooth waving hand animation when <= 5 seconds remain
            if secondsRemaining <= 5 && secondsRemaining > 0 {
                NSGraphicsContext.current?.saveGraphicsState()

                // Calculate smooth fade opacity based on remaining time
                // Fade in from 5s to 3s, stay solid from 3s to 1s, then pulse at final second
                let darkenAlpha: CGFloat
                let emojiAlpha: CGFloat

                if secondsRemaining > 3 {
                    // Fade in: 5s (0.2) -> 3s (0.6)
                    let fadeProgress = (5.0 - CGFloat(secondsRemaining)) / 2.0
                    darkenAlpha = 0.2 + (fadeProgress * 0.4)
                    emojiAlpha = 0.5 + (fadeProgress * 0.5)
                } else if secondsRemaining > 1 {
                    // Stay solid
                    darkenAlpha = 0.6
                    emojiAlpha = 1.0
                } else {
                    // Final second: pulse to maximum darkness
                    darkenAlpha = 0.7
                    emojiAlpha = 1.0
                }

                // Darken the screenshot with smooth fade
                NSColor.black.withAlphaComponent(darkenAlpha).setFill()
                let darkenRect = NSBezierPath(roundedRect: imageRect, xRadius: 8, yRadius: 8)
                darkenRect.fill()

                // Draw waving hand with smooth fade and realistic animation
                let waveEmoji = "👋"
                let emojiSize: CGFloat = 56  // Slightly larger for more presence

                // Create realistic waving animation
                let time = Date().timeIntervalSince1970
                let waveSpeed: Double = 4.0  // Faster waving

                // Horizontal movement (back and forth)
                let horizontalOffset = sin(time * waveSpeed) * 8

                // Vertical movement (slight up and down)
                let verticalOffset = sin(time * waveSpeed * 2) * 3

                // Rotation angle for waving effect (-15° to +15°)
                let rotationAngle = sin(time * waveSpeed) * 15  // degrees

                // Calculate center position with offsets
                let centerX = imageRect.midX + horizontalOffset
                let centerY = imageRect.midY + verticalOffset

                // Save graphics state for transformation
                NSGraphicsContext.current?.saveGraphicsState()

                // Apply rotation transform
                let transform = NSAffineTransform()
                transform.translateX(by: centerX, yBy: centerY)
                transform.rotate(byDegrees: rotationAngle)
                transform.concat()

                // Draw emoji at origin (transformation applied)
                let emojiAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: emojiSize),
                    .foregroundColor: NSColor.white.withAlphaComponent(emojiAlpha)
                ]

                let textSize = (waveEmoji as NSString).size(withAttributes: emojiAttributes)
                let emojiRect = NSRect(
                    x: -textSize.width / 2,
                    y: -textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                (waveEmoji as NSString).draw(in: emojiRect, withAttributes: emojiAttributes)

                // Restore transformation
                NSGraphicsContext.current?.restoreGraphicsState()

                // Restore main graphics state
                NSGraphicsContext.current?.restoreGraphicsState()
            }
        }

        // Draw time ago text
        let timeText = timeAgo(from: screenshot.createdDate)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let textSize = (timeText as NSString).size(withAttributes: textAttributes)
        let centeredTextRect = NSRect(
            x: (textRect.width - textSize.width) / 2,
            y: textRect.minY + (textRect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (timeText as NSString).draw(in: centeredTextRect, withAttributes: textAttributes)

        // Update tooltip for expiring screenshots
        let secondsRemaining = secondsUntilExpiration(for: screenshot)
        if secondsRemaining <= 60 {
            if secondsRemaining <= 30 {
                self.toolTip = "🔴 Expiring in \(secondsRemaining) seconds!"
            } else {
                self.toolTip = "⏰ Less than 1 minute remaining"
            }
        } else {
            self.toolTip = nil
        }
    }

    private func secondsUntilExpiration(for screenshot: Screenshot) -> Int {
        let expirationDate = screenshot.createdDate.addingTimeInterval(Double(timeFilterMinutes * 60))
        let remaining = expirationDate.timeIntervalSince(Date())
        return max(0, Int(remaining))
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let hours = minutes / 60

        if seconds < 60 {
            return "now"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            return "\(hours)h"
        }
    }
}

extension ThumbnailNSView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        // Return operation based on user setting
        if dragMode == "move" {
            return .move
        } else {
            return .copy
        }
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // If move operation completed, we could delete the file here
        // For now, macOS will handle it automatically
    }
}

// MARK: - Selection Rectangle

struct SelectionRectangle: View {
    let start: CGPoint
    let current: CGPoint

    var body: some View {
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        Rectangle()
            .fill(Color.blue.opacity(0.2))
            .overlay(
                Rectangle()
                    .strokeBorder(Color.blue, lineWidth: 2)
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview("First Launch") {
    PopoverView()
        .environmentObject(FolderMonitor())
}

#Preview("Main Interface") {
    PopoverView()
        .environmentObject(FolderMonitor())
        .onAppear {
            UserDefaults.standard.set(false, forKey: "isFirstLaunch")
            UserDefaults.standard.set("/Users/user/Desktop", forKey: "screenshotFolder")
        }
}
