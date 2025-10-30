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
    // MARK: - AppStorage Properties

    /// Time filter in minutes (5-60 range)
    @AppStorage("timeFilter") private var timeFilter: Int = 10

    /// Drag mode: copy or move files when dragging
    @AppStorage("dragMode") private var dragMode: String = "copy"

    /// Enable hover zoom preview
    @AppStorage("enableHoverZoom") private var enableHoverZoom: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Time filter setting
                    timeFilterSection

                    Divider()

                    // Drag & Drop setting
                    dragModeSection

                    Divider()

                    // Hover Zoom setting
                    hoverZoomSection

                    Divider()

                    // About section
                    aboutSection
                }
                .padding()
            }
        }
        .frame(width: 400, height: 450)
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
