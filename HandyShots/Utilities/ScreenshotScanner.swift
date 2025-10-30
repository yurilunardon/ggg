//
//  ScreenshotScanner.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import Foundation
import AppKit

/// Represents a screenshot file
struct Screenshot: Identifiable, Hashable {
    let id: String
    let url: URL
    let name: String
    let createdDate: Date
    let thumbnail: NSImage?

    init(url: URL, createdDate: Date) {
        self.id = url.absoluteString
        self.url = url
        self.name = url.lastPathComponent
        self.createdDate = createdDate
        self.thumbnail = Self.loadThumbnail(from: url)
    }

    /// Load thumbnail from image file
    private static func loadThumbnail(from url: URL) -> NSImage? {
        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        // Create small thumbnail for performance
        let maxSize: CGFloat = 200
        let size = image.size

        let scale = min(maxSize / size.width, maxSize / size.height)
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()

        return thumbnail
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Screenshot, rhs: Screenshot) -> Bool {
        lhs.id == rhs.id
    }
}

/// Utility class for scanning screenshot files in a folder
class ScreenshotScanner {
    // MARK: - Public Methods

    /// Scan folder for screenshot files within time range
    /// - Parameters:
    ///   - folderPath: Path to screenshot folder
    ///   - minutes: How many minutes back to look
    /// - Returns: Array of Screenshot objects
    static func scanFolder(path folderPath: String, withinMinutes minutes: Int) -> [Screenshot] {
        let fileManager = FileManager.default
        let folderURL = URL(fileURLWithPath: folderPath)

        // Get cutoff date
        let cutoffDate = Date().addingTimeInterval(-Double(minutes * 60))

        print("🔍 Scanning folder: \(folderPath)")
        print("   ⏱️  Looking for screenshots from last \(minutes) minutes")
        print("   📅 Cutoff date: \(cutoffDate)")

        do {
            // Get all files in directory
            let contents = try fileManager.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            print("   📁 Found \(contents.count) total files")

            // Filter for image files created after cutoff
            let screenshots = contents.compactMap { url -> Screenshot? in
                // Check if image file
                guard isImageFile(url: url) else {
                    return nil
                }

                // Get creation date
                guard let creationDate = getCreationDate(url: url) else {
                    return nil
                }

                // Check if within time range
                guard creationDate >= cutoffDate else {
                    return nil
                }

                return Screenshot(url: url, createdDate: creationDate)
            }

            // Sort by date (newest first)
            let sorted = screenshots.sorted { $0.createdDate > $1.createdDate }

            print("   ✅ Found \(sorted.count) screenshots within time range")

            return sorted

        } catch {
            print("   ❌ Error scanning folder: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Private Helper Methods

    /// Check if URL is an image file
    private static func isImageFile(url: URL) -> Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }

    /// Get creation date of file
    private static func getCreationDate(url: URL) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.creationDate] as? Date
        } catch {
            return nil
        }
    }
}
