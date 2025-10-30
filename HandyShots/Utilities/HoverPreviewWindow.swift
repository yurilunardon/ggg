//
//  HoverPreviewWindow.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import SwiftUI
import AppKit

/// Manager for hover preview window
class HoverPreviewManager {
    static let shared = HoverPreviewManager()

    private var previewWindow: NSWindow?
    private var hideTimer: Timer?

    private init() {}

    /// Show preview for a screenshot over the thumbnail
    func showPreview(for screenshot: Screenshot, over thumbnailFrame: NSRect) {
        // Hide any existing preview
        hidePreview()

        guard let image = screenshot.thumbnail else { return }

        // Calculate preview size (max 400x400, maintaining aspect ratio)
        let imageSize = image.size
        let maxSize: CGFloat = 400
        var previewSize = imageSize

        if imageSize.width > maxSize || imageSize.height > maxSize {
            let scale = min(maxSize / imageSize.width, maxSize / imageSize.height)
            previewSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
        }

        // Center preview over the thumbnail
        let windowOrigin = NSPoint(
            x: thumbnailFrame.midX - previewSize.width / 2,
            y: thumbnailFrame.midY - previewSize.height / 2
        )

        // Create preview window
        let contentView = NSHostingView(rootView: PreviewContentView(image: image))
        contentView.frame = NSRect(origin: .zero, size: previewSize)

        let window = NSPanel(
            contentRect: NSRect(origin: windowOrigin, size: previewSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .popUpMenu
        window.hasShadow = true
        window.contentView = contentView
        window.ignoresMouseEvents = true // Ignore mouse events so drag works
        window.animationBehavior = .none

        // Show with fade animation
        window.alphaValue = 0
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().alphaValue = 1.0
        })

        previewWindow = window
    }

    /// Hide the preview window
    func hidePreview(animated: Bool = true) {
        guard let window = previewWindow else { return }

        hideTimer?.invalidate()
        hideTimer = nil

        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.close()
            })
        } else {
            window.close()
        }

        previewWindow = nil
    }

    /// Schedule preview to hide after delay
    func scheduleHide(after delay: TimeInterval = 0.1) {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.hidePreview()
        }
    }

    /// Cancel scheduled hide
    func cancelScheduledHide() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
}

/// Preview content view
private struct PreviewContentView: View {
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
            .padding(4)
    }
}
