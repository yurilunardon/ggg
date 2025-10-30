//
//  WelcomeView.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import SwiftUI
import AppKit

/// Welcome screen shown on first launch
struct WelcomeView: View {
    // MARK: - Properties

    /// Detected screenshot folder
    @State private var detectedFolder: String = FolderDetector.detectSystemFolder() ?? ""

    /// Callback when folder is selected
    var onFolderSelected: (String) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Compact welcome header
            VStack(spacing: 6) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)

                Text("Welcome to HandyShots")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your screenshot assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            Divider()

            // Compact folder detection section
            VStack(alignment: .leading, spacing: 8) {
                Text("Screenshot Folder Detected")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(FolderDetector.getFolderDisplayName(path: detectedFolder))
                            .font(.callout)
                            .fontWeight(.medium)

                        Text(detectedFolder)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 12)

            Spacer()

            // Compact action buttons
            VStack(spacing: 8) {
                // Use detected folder button
                Button(action: {
                    useDetectedFolder()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Use This Folder")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                // Choose different folder button
                Button(action: {
                    chooseCustomFolder()
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Choose Another Folder")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 400, height: 300)
    }

    // MARK: - Actions

    /// Use the automatically detected folder
    private func useDetectedFolder() {
        guard !detectedFolder.isEmpty else {
            print("❌ No folder detected")
            return
        }

        completeSetup(with: detectedFolder)
    }

    /// Open file picker to choose custom folder
    private func chooseCustomFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Screenshot Folder"
        panel.message = "Select the folder where your screenshots are saved"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        // Set initial directory to detected folder or Desktop
        if let url = URL(string: "file://\(detectedFolder)") {
            panel.directoryURL = url
        }

        // Show panel
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let path = url.path
                completeSetup(with: path)
            }
        }
    }

    /// Complete first launch setup
    /// - Parameter folderPath: Selected folder path
    private func completeSetup(with folderPath: String) {
        // Save folder selection
        FolderDetector.saveFolder(path: folderPath)

        // Mark first launch as complete
        UserDefaults.standard.set(false, forKey: "isFirstLaunch")

        print("✅ First launch setup completed with folder: \(folderPath)")

        // Notify parent
        onFolderSelected(folderPath)
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(onFolderSelected: { _ in })
}
