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

    // MARK: - State Properties

    /// Show splash screen on first open
    @State private var showSplash: Bool = true

    /// List of recent screenshots
    @State private var screenshots: [Screenshot] = []

    /// Timer for refreshing screenshots
    @State private var refreshTimer: Timer?

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
            }

            // Monitored folder row
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text(FolderDetector.getFolderDisplayName(path: folderMonitor.currentFolder))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 8)
                ], spacing: 8) {
                    ForEach(screenshots) { screenshot in
                        ScreenshotThumbnailView(screenshot: screenshot)
                    }
                }
                .padding(12)
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

    /// Start timer to refresh screenshots periodically
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
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
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
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
            // Open in Quick Look or Finder
            NSWorkspace.shared.open(screenshot.url)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let hours = minutes / 60

        if seconds < 60 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            return "\(hours)h ago"
        }
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
