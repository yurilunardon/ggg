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

    // MARK: - State Properties

    /// Show splash screen on first open
    @State private var showSplash: Bool = true

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
            // Compact Header
            header

            Divider()

            // Content area (no scroll, compact layout)
            VStack(alignment: .leading, spacing: 12) {
                // Folder information section
                folderSection

                Spacer()

                // Compact placeholder section
                placeholderSection
            }
            .padding(12)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.title3)
                .foregroundColor(.accentColor)

            Text("HandyShots")
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            // Change folder button
            Button(action: {
                changeFolderAction()
            }) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Change screenshot folder")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }

    // MARK: - Folder Section

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Monitored Folder")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(folderExists ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(folderExists ? "Active" : "Not found")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(FolderDetector.getFolderDisplayName(path: folderMonitor.currentFolder))
                        .font(.callout)
                        .fontWeight(.medium)

                    Text(folderMonitor.currentFolder)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // Compact change button
                Button(action: {
                    changeFolderAction()
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(8)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(8)
        }
    }

    // MARK: - Placeholder Section

    private var placeholderSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Screenshot Gallery")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text("Coming soon")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Compact features grid (2 columns)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    featureBadge(icon: "photo.stack", text: "Thumbnails")
                    featureBadge(icon: "hand.draw", text: "Drag & drop")
                }
                VStack(alignment: .leading, spacing: 4) {
                    featureBadge(icon: "magnifyingglass", text: "Quick Look")
                    featureBadge(icon: "doc.text.viewfinder", text: "OCR")
                }
                Spacer()
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Helper Views

    private func featureBadge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .frame(width: 16)
                .foregroundColor(.gray)

            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
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
