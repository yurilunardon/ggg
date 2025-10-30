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
    // MARK: - AppStorage Properties

    /// Flag indicating if this is the first launch
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true

    /// Currently monitored screenshot folder
    @AppStorage("screenshotFolder") private var screenshotFolder: String = ""

    // MARK: - State Properties

    /// Current folder path (synced with AppStorage)
    @State private var currentFolder: String = ""

    // MARK: - Body

    var body: some View {
        Group {
            if isFirstLaunch {
                // Show welcome screen on first launch
                WelcomeView(onFolderSelected: { path in
                    currentFolder = path
                    screenshotFolder = path
                })
            } else {
                // Show main interface
                mainInterface
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            // Initialize current folder
            if currentFolder.isEmpty {
                currentFolder = FolderDetector.getCurrentFolder()
            }
        }
    }

    // MARK: - Main Interface

    private var mainInterface: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Folder information section
                    folderSection

                    Divider()

                    // Placeholder for future screenshot features
                    placeholderSection
                }
                .padding()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "camera.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("HandyShots")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            // Change folder button
            Button(action: {
                changeFolderAction()
            }) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Change screenshot folder")
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }

    // MARK: - Folder Section

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monitored Folder")
                .font(.headline)

            HStack {
                Image(systemName: "folder.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(FolderDetector.getFolderDisplayName(path: currentFolder))
                        .font(.body)
                        .fontWeight(.medium)

                    Text(currentFolder)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // Status indicator
                Circle()
                    .fill(folderExists ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                    .help(folderExists ? "Folder accessible" : "Folder not found")
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(10)

            // Change folder button
            Button(action: {
                changeFolderAction()
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Change Folder")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Placeholder Section

    private var placeholderSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("Screenshot Gallery")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Future features will appear here")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                featureBadge(icon: "photo.stack", text: "Screenshot thumbnails")
                featureBadge(icon: "magnifyingglass", text: "Quick Look preview")
                featureBadge(icon: "hand.draw", text: "Drag & drop support")
                featureBadge(icon: "doc.text.viewfinder", text: "OCR text recognition")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }

    // MARK: - Helper Views

    private func featureBadge(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.gray)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Computed Properties

    /// Check if current folder exists and is accessible
    private var folderExists: Bool {
        FolderDetector.isFolderAccessible(path: currentFolder)
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
        if !currentFolder.isEmpty, let url = URL(string: "file://\(currentFolder)") {
            panel.directoryURL = url
        }

        // Show panel
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let path = url.path
                currentFolder = path
                screenshotFolder = path
                FolderDetector.saveFolder(path: path)

                print("✅ Screenshot folder changed to: \(path)")
            }
        }
    }
}

// MARK: - Preview

#Preview("First Launch") {
    PopoverView()
}

#Preview("Main Interface") {
    PopoverView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "isFirstLaunch")
            UserDefaults.standard.set("/Users/user/Desktop", forKey: "screenshotFolder")
        }
}
