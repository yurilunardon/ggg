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

    // MARK: - State Properties

    /// Show splash screen on first open
    @State private var showSplash: Bool = true

    /// List of recent screenshots
    @State private var screenshots: [Screenshot] = []

    /// Timer for refreshing screenshots
    @State private var refreshTimer: Timer?

    /// Currently hovered screenshot for zoom preview
    @State private var hoveredScreenshot: Screenshot?

    /// Selected screenshots for drag & drop
    @State private var selectedScreenshots: Set<String> = []

    /// Drag selection state
    @State private var isDragSelecting: Bool = false
    @State private var dragStartLocation: CGPoint?

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
        VStack(spacing: 0) {
            // Compact Header with folder info
            compactHeader

            Divider()

            // Notification banner (if folder changed)
            if let message = folderMonitor.folderChangeMessage {
                notificationBanner(message: message)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: folderMonitor.folderChangeMessage)
            }

            // Screenshot grid
            screenshotGrid
        }
        .onAppear {
            refreshScreenshots()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            // App name row
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)

                Text("HandyShots")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                // Status indicator
                Circle()
                    .fill(folderExists ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
                    .help(folderExists ? "Folder accessible" : "Folder not accessible")
            }

            // Monitored folder row
            HStack(spacing: 8) {
                Text("Monitored:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)

                Text(folderMonitor.currentFolder)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                // Change folder button
                Button(action: {
                    changeFolderAction()
                }) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Change screenshot folder")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }

    // MARK: - Screenshot Grid

    private var screenshotGrid: some View {
        ScrollView {
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
                // Grid of screenshots
                ZStack {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 8)
                    ], spacing: 8) {
                        ForEach(screenshots) { screenshot in
                            ScreenshotThumbnailView(
                                screenshot: screenshot,
                                isSelected: selectedScreenshots.contains(screenshot.id),
                                allScreenshots: screenshots,
                                selectedIDs: selectedScreenshots,
                                onSelect: {
                                    if !isDragSelecting {
                                        toggleSelection(screenshot: screenshot)
                                    }
                                },
                                onHover: { isHovering in
                                    if enableHoverZoom {
                                        hoveredScreenshot = isHovering ? screenshot : nil
                                    }
                                }
                            )
                        }
                    }
                    .padding(12)

                    // Hover zoom preview (if enabled)
                    if enableHoverZoom,
                       let hovered = hoveredScreenshot,
                       let image = hovered.thumbnail {
                        ZoomPreviewView(screenshot: hovered, image: image)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

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

    /// Toggle screenshot selection
    private func toggleSelection(screenshot: Screenshot) {
        if selectedScreenshots.contains(screenshot.id) {
            selectedScreenshots.remove(screenshot.id)
        } else {
            selectedScreenshots.insert(screenshot.id)
        }
    }

    /// Open folder picker to change screenshot folder
    private func changeFolderAction() {
        let panel = NSOpenPanel()
        panel.title = "Choose Screenshot Folder"
        panel.message = "Select the folder where your screenshots are saved"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        // Set initial directory
        if !folderMonitor.currentFolder.isEmpty, let url = URL(string: "file://\(folderMonitor.currentFolder)") {
            panel.directoryURL = url
        }

        // Show panel
        panel.begin { [weak folderMonitor] response in
            if response == .OK, let url = panel.url {
                let path = url.path
                folderMonitor?.updateFolder(path: path)
                FolderDetector.saveFolder(path: path)

                print("✅ Screenshot folder changed to: \(path)")
            }
        }
    }

    // MARK: - Screenshot Management

    /// Refresh the list of screenshots
    private func refreshScreenshots() {
        let folder = folderMonitor.currentFolder
        let minutes = timeFilter

        DispatchQueue.global(qos: .userInitiated).async {
            let scanned = ScreenshotScanner.scanFolder(path: folder, withinMinutes: minutes)

            DispatchQueue.main.async {
                self.screenshots = scanned
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

// MARK: - Screenshot Thumbnail View

struct ScreenshotThumbnailView: View {
    let screenshot: Screenshot
    let isSelected: Bool
    let allScreenshots: [Screenshot]
    let selectedIDs: Set<String>
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    @AppStorage("dragMode") private var dragMode: String = "copy" // "copy" or "move"

    var body: some View {
        VStack(spacing: 4) {
            // Thumbnail image
            if let thumbnail = screenshot.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                    )
                    .overlay(
                        // Selection indicator
                        Group {
                            if isSelected {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .background(Circle().fill(Color.white).padding(2))
                                            .padding(4)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            // Time ago text
            Text(timeAgo(from: screenshot.createdDate))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            onSelect()
        }
        .onLongPressGesture(minimumDuration: 0.1) {
            // Open on long press
            NSWorkspace.shared.open(screenshot.url)
        }
        .onHover { hovering in
            onHover(hovering)
        }
        .onDrag {
            // Drag & drop functionality - support multiple files
            let selectedScreenshots = allScreenshots.filter { selectedIDs.contains($0.id) }

            // If this screenshot is selected, drag all selected ones
            // Otherwise, drag just this one
            let screenshotsToDrag = isSelected && !selectedScreenshots.isEmpty ? selectedScreenshots : [screenshot]

            if screenshotsToDrag.count == 1 {
                // Single file drag
                let provider = NSItemProvider(contentsOf: screenshotsToDrag[0].url)!
                provider.suggestedName = screenshotsToDrag[0].name
                return provider
            } else {
                // Multiple files drag - create a compound provider
                let provider = NSItemProvider()

                // Register all file URLs
                for screenshot in screenshotsToDrag {
                    let fileProvider = NSItemProvider(contentsOf: screenshot.url)!
                    // Note: Multiple file drag requires more complex implementation
                    // For now, we'll drag the first selected file with a count indicator
                }

                provider.suggestedName = "\(screenshotsToDrag.count) screenshots"

                // Register file promise for multiple files
                provider.registerFileRepresentation(
                    forTypeIdentifier: "public.file-url",
                    fileOptions: [],
                    visibility: .all
                ) { completion in
                    // For multiple files, we need to create a temporary directory or handle differently
                    // For now, return the first file
                    if let firstURL = screenshotsToDrag.first?.url {
                        completion(firstURL, false, nil)
                    } else {
                        completion(nil, false, NSError(domain: "HandyShots", code: -1))
                    }
                    return nil
                }

                return provider
            }
        }
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

// MARK: - Zoom Preview View

struct ZoomPreviewView: View {
    let screenshot: Screenshot
    let image: NSImage

    var body: some View {
        VStack {
            Spacer()

            // Zoomed preview
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300, maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.001)) // Invisible but interactive
        .allowsHitTesting(false) // Don't block interactions
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: screenshot.id)
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
