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

                    // About section
                    aboutSection
                }
                .padding()
            }
        }
        .frame(width: 400, height: 250)
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
