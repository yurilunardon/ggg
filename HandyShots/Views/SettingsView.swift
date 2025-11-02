//
//  SettingsView.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import SwiftUI

/// Settings window for configuring app preferences
struct SettingsView: View {
    // MARK: - Environment Objects

    /// Folder monitor for tracking screenshot folder changes
    @EnvironmentObject var folderMonitor: FolderMonitor

    // MARK: - AppStorage Properties

    /// Time filter in minutes (5-60 range)
    @AppStorage("timeFilter") private var timeFilter: Int = 10

    /// Drag mode: copy or move files when dragging
    @AppStorage("dragMode") private var dragMode: String = "copy"

    /// Enable hover zoom preview
    @AppStorage("enableHoverZoom") private var enableHoverZoom: Bool = false

    /// Delete mode: hideFromView or deleteFromDisk
    @AppStorage("deleteMode") private var deleteMode: String = "hideFromView"

    // MARK: - State Properties

    /// Highlighted section (for navigation from badges)
    @State private var highlightedSection: String? = nil

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Monitored folder setting
                    monitoredFolderSection

                    Divider()

                    // Time filter setting
                    timeFilterSection

                    Divider()

                    // Drag & Drop setting
                    dragModeSection

                    Divider()

                    // Hover Zoom setting
                    hoverZoomSection

                    Divider()

                    // Delete Mode setting
                    deleteModeSection

                    Divider()

                    // About section
                    aboutSection
                }
                .padding()
            }
        }
        .frame(width: 400, height: 450)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HighlightSettingsSection"))) { notification in
            if let section = notification.userInfo?["section"] as? String {
                // Highlight the section
                withAnimation(.easeInOut(duration: 0.3)) {
                    highlightedSection = section
                }
                // Remove highlight after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        highlightedSection = nil
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }

    // MARK: - Monitored Folder Section

    private var monitoredFolderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)

                Text("Screenshot Folder")
                    .font(.headline)
            }

            Text("Choose which folder to monitor for screenshots")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Current folder display (clickable to open in Finder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Folder:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)

                Button(action: {
                    openFolderInFinder()
                }) {
                    HStack(spacing: 6) {
                        Text(folderMonitor.currentFolder)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "arrow.up.forward.square")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Click to open folder in Finder")
            }

            // Change folder button
            Button(action: {
                changeFolderAction()
            }) {
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 14))
                    Text("Change Folder...")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            highlightedSection == "folder" ?
                Color.blue.opacity(0.15) : Color.clear
        )
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: highlightedSection)
    }

    /// Open the current folder in Finder
    private func openFolderInFinder() {
        let folderURL = URL(fileURLWithPath: folderMonitor.currentFolder)
        NSWorkspace.shared.open(folderURL)
        print("📂 Opening folder in Finder: \(folderMonitor.currentFolder)")
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

    // MARK: - Time Filter Section

    private var timeFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)

                Text("Screenshot Display Time")
                    .font(.headline)
            }

            Text("How long to show recent screenshots")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                // Value display
                HStack {
                    Spacer()
                    Text("\(timeFilter) minutes")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

                // Slider
                HStack {
                    Text("5")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: Binding(
                        get: { Double(timeFilter) },
                        set: { timeFilter = Int($0) }
                    ), in: 5...60, step: 5)
                    .accentColor(.blue)

                    Text("60")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Quick preset buttons
                HStack(spacing: 8) {
                    presetButton(minutes: 10, label: "10m")
                    presetButton(minutes: 30, label: "30m")
                    presetButton(minutes: 60, label: "1h")
                }
            }
        }
        .padding(12)
        .background(
            highlightedSection == "timeFilter" ?
                Color.green.opacity(0.15) : Color.clear
        )
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: highlightedSection)
    }

    // MARK: - Drag Mode Section

    private var dragModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.doc.fill")
                    .foregroundColor(.purple)

                Text("Drag & Drop Behavior")
                    .font(.headline)
            }

            Text("Choose what happens when you drag screenshots")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                // Copy option
                Button(action: {
                    dragMode = "copy"
                }) {
                    HStack {
                        Image(systemName: dragMode == "copy" ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(dragMode == "copy" ? .blue : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Copy")
                                .font(.body)
                                .fontWeight(dragMode == "copy" ? .semibold : .regular)

                            Text("Create a copy of the file (original remains)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(dragMode == "copy" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Move option
                Button(action: {
                    dragMode = "move"
                }) {
                    HStack {
                        Image(systemName: dragMode == "move" ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(dragMode == "move" ? .blue : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Move")
                                .font(.body)
                                .fontWeight(dragMode == "move" ? .semibold : .regular)

                            Text("Move the file (remove from monitored folder)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(dragMode == "move" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Hover Zoom Section

    private var hoverZoomSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.green)

                Text("Hover Zoom Preview")
                    .font(.headline)
            }

            Text("Show enlarged preview when hovering over screenshots")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Toggle(isOn: $enableHoverZoom) {
                HStack {
                    Image(systemName: enableHoverZoom ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(enableHoverZoom ? .green : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(enableHoverZoom ? "Enabled" : "Disabled")
                            .font(.body)
                            .fontWeight(.semibold)

                        Text(enableHoverZoom ? "Preview appears on hover" : "No preview on hover")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(12)
            .background(enableHoverZoom ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }

    // MARK: - Delete Mode Section

    private var deleteModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)

                Text("Screenshot Deletion")
                    .font(.headline)
            }

            Text("Choose what happens when you delete screenshots")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                // Hide from view option
                Button(action: {
                    deleteMode = "hideFromView"
                }) {
                    HStack {
                        Image(systemName: deleteMode == "hideFromView" ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(deleteMode == "hideFromView" ? .blue : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hide from View")
                                .font(.body)
                                .fontWeight(deleteMode == "hideFromView" ? .semibold : .regular)

                            Text("Remove from list, keep file in folder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(deleteMode == "hideFromView" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Delete from disk option
                Button(action: {
                    deleteMode = "deleteFromDisk"
                }) {
                    HStack {
                        Image(systemName: deleteMode == "deleteFromDisk" ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(deleteMode == "deleteFromDisk" ? .blue : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete from Disk")
                                .font(.body)
                                .fontWeight(deleteMode == "deleteFromDisk" ? .semibold : .regular)

                            Text("Permanently delete file from folder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(deleteMode == "deleteFromDisk" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.gray)

                Text("About")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("HandyShots MVP")
                    .font(.body)
                    .fontWeight(.medium)

                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("macOS Screenshot Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 26)
        }
    }

    // MARK: - Helper Views

    /// Preset button for quick time selection
    private func presetButton(minutes: Int, label: String) -> some View {
        Button(action: {
            timeFilter = minutes
        }) {
            Text(label)
                .font(.caption)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(timeFilter == minutes)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
