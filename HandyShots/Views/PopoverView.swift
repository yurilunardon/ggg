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

    /// Selected screenshots for drag & drop
    @State private var selectedScreenshots: Set<String> = []

    /// Drag selection state
    @State private var isDragSelecting: Bool = false
    @State private var dragStartLocation: CGPoint?
    @State private var currentDragLocation: CGPoint?

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
            HoverPreviewManager.shared.hidePreview(animated: false)
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
                // Grid of screenshots with drag selection support
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 8)
                    ], spacing: 8) {
                        ForEach(screenshots) { screenshot in
                            ScreenshotThumbnailView(
                                screenshot: screenshot,
                                isSelected: selectedScreenshots.contains(screenshot.id),
                                allScreenshots: screenshots,
                                selectedIDs: selectedScreenshots,
                                enableHoverZoom: enableHoverZoom,
                                onSelect: {
                                    if !isDragSelecting {
                                        toggleSelection(screenshot: screenshot)
                                    }
                                },
                                onOpen: {
                                    openScreenshots(for: screenshot)
                                }
                            )
                            .id(screenshot.id)
                        }
                    }
                    .padding(12)
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Deselect all when clicking empty area
                                selectedScreenshots.removeAll()
                            }
                    )
                }
                .coordinateSpace(name: "scroll")
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

    /// Open screenshot(s) - if selected, open all selected ones
    private func openScreenshots(for screenshot: Screenshot) {
        // Don't close popover when opening files
        if selectedScreenshots.contains(screenshot.id) && selectedScreenshots.count > 1 {
            // Open all selected screenshots
            let selectedURLs = screenshots
                .filter { selectedScreenshots.contains($0.id) }
                .map { $0.url }

            for url in selectedURLs {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Open just this one
            NSWorkspace.shared.open(screenshot.url)
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
    let enableHoverZoom: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void

    @AppStorage("dragMode") private var dragMode: String = "copy" // "copy" or "move"

    var body: some View {
        ThumbnailViewInternal(
            screenshot: screenshot,
            isSelected: isSelected,
            enableHoverZoom: enableHoverZoom,
            onSelect: onSelect,
            onOpen: onOpen
        )
        .frame(width: 80, height: 100)
    }

}

// MARK: - Thumbnail View Internal

struct ThumbnailViewInternal: NSViewRepresentable {
    let screenshot: Screenshot
    let isSelected: Bool
    let enableHoverZoom: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void

    func makeNSView(context: Context) -> ThumbnailNSView {
        let view = ThumbnailNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: ThumbnailNSView, context: Context) {
        nsView.screenshot = screenshot
        nsView.isSelected = isSelected
        nsView.enableHoverZoom = enableHoverZoom
        nsView.onSelect = onSelect
        nsView.onOpen = onOpen
        nsView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var trackingArea: NSTrackingArea?
    }
}

// MARK: - Thumbnail NSView

class ThumbnailNSView: NSView {
    var screenshot: Screenshot?
    var isSelected: Bool = false
    var enableHoverZoom: Bool = false
    var onSelect: (() -> Void)?
    var onOpen: (() -> Void)?
    var coordinator: ThumbnailViewInternal.Coordinator?

    @AppStorage("dragMode") private var dragMode: String = "copy"

    private var previewTimer: Timer?
    private var isDragging: Bool = false
    private var mouseDownPoint: NSPoint?
    private var dragThreshold: CGFloat = 5.0 // pixels to move before considering it a drag

    private var isHovering: Bool = false {
        didSet {
            if isHovering && enableHoverZoom {
                // Start timer to show preview after 2 seconds
                previewTimer?.invalidate()
                previewTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    self?.showPreview()
                }
            } else {
                // Cancel timer and hide preview
                previewTimer?.invalidate()
                previewTimer = nil
                HoverPreviewManager.shared.hidePreview()
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // Register for drag & drop
        registerForDraggedTypes([.fileURL])

        // Setup tracking area for hover
        updateTrackingAreas()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existing = coordinator?.trackingArea {
            removeTrackingArea(existing)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        coordinator?.trackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    override func mouseDown(with event: NSEvent) {
        // Reset drag flag and save mouse position
        isDragging = false
        mouseDownPoint = event.locationInWindow

        // Cancel preview timer on mouse down
        previewTimer?.invalidate()
        previewTimer = nil
        HoverPreviewManager.shared.hidePreview(animated: false)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let screenshot = screenshot else { return }

        // Check if we've moved enough to consider this a drag
        if let downPoint = mouseDownPoint {
            let currentPoint = event.locationInWindow
            let distance = hypot(currentPoint.x - downPoint.x, currentPoint.y - downPoint.y)

            // Only start drag if moved more than threshold
            guard distance > dragThreshold else { return }
        }

        // Mark that we're dragging
        isDragging = true

        // Create drag item using NSURL (conforms to NSPasteboardWriting)
        let fileURL = screenshot.url as NSURL
        let item = NSDraggingItem(pasteboardWriter: fileURL)

        // Set drag image - start slightly bigger than thumbnail (90px)
        if let thumbnail = screenshot.thumbnail {
            let dragImage = thumbnail

            // Start slightly bigger than thumbnail (80x80 -> 90x90)
            let startSize: CGFloat = 90
            let startFrame = NSRect(
                x: 0, y: 0,
                width: startSize,
                height: startSize
            )

            // Set the dragging frame
            item.setDraggingFrame(startFrame, contents: dragImage)

            // Configure to animate to destination - grows as you drag
            item.imageComponentsProvider = {
                let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)
                component.contents = dragImage
                // Final size when dragging away
                let finalSize: CGFloat = 120
                component.frame = NSRect(x: 0, y: 0, width: finalSize, height: finalSize)
                return [component]
            }
        }

        // Start dragging session
        let session = beginDraggingSession(with: [item], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func mouseUp(with event: NSEvent) {
        // Only handle click if we didn't drag
        guard !isDragging else {
            isDragging = false
            return
        }

        // Check for modifier keys for selection
        if event.modifierFlags.contains(.command) {
            onSelect?()
        } else {
            // Regular click opens the screenshot(s)
            onOpen?()
        }

        isDragging = false
    }

    private func showPreview() {
        guard let screenshot = screenshot else { return }

        // Get the image rect in window coordinates
        let imageRect = NSRect(x: 0, y: 20, width: 80, height: 80)
        let imageRectInWindow = convert(imageRect, to: nil)

        // Convert to screen coordinates
        let frameInScreen = window?.convertToScreen(imageRectInWindow) ?? .zero
        HoverPreviewManager.shared.showPreview(for: screenshot, over: frameInScreen)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let screenshot = screenshot else { return }

        // Image area: 80x80 at top, text area: 20px at bottom
        let imageRect = NSRect(x: 0, y: 20, width: 80, height: 80)
        let textRect = NSRect(x: 0, y: 0, width: 80, height: 20)

        // Draw thumbnail
        if let thumbnail = screenshot.thumbnail {
            // Save graphics state
            NSGraphicsContext.current?.saveGraphicsState()

            // Create rounded rect path for clipping
            let clipPath = NSBezierPath(roundedRect: imageRect, xRadius: 8, yRadius: 8)
            clipPath.addClip()

            // Draw image
            thumbnail.draw(in: imageRect)

            // Restore graphics state
            NSGraphicsContext.current?.restoreGraphicsState()

            // Draw border
            if isSelected {
                NSColor.systemBlue.setStroke()
                let borderPath = NSBezierPath(roundedRect: imageRect, xRadius: 8, yRadius: 8)
                borderPath.lineWidth = 3
                borderPath.stroke()

                // Draw checkmark
                let checkmarkSize: CGFloat = 16
                let checkmarkRect = NSRect(
                    x: imageRect.maxX - checkmarkSize - 4,
                    y: imageRect.maxY - checkmarkSize - 4,
                    width: checkmarkSize,
                    height: checkmarkSize
                )

                // Draw white circle background
                NSColor.white.setFill()
                let circlePath = NSBezierPath(ovalIn: checkmarkRect.insetBy(dx: -2, dy: -2))
                circlePath.fill()

                // Draw checkmark icon
                let checkImage = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
                checkImage?.isTemplate = true

                NSGraphicsContext.current?.saveGraphicsState()
                NSColor.systemBlue.set()
                checkImage?.draw(in: checkmarkRect)
                NSGraphicsContext.current?.restoreGraphicsState()
            } else {
                NSColor.gray.withAlphaComponent(0.2).setStroke()
                let borderPath = NSBezierPath(roundedRect: imageRect, xRadius: 8, yRadius: 8)
                borderPath.lineWidth = 1
                borderPath.stroke()
            }
        }

        // Draw time ago text
        let timeText = timeAgo(from: screenshot.createdDate)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let textSize = (timeText as NSString).size(withAttributes: textAttributes)
        let centeredTextRect = NSRect(
            x: (textRect.width - textSize.width) / 2,
            y: textRect.minY + (textRect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (timeText as NSString).draw(in: centeredTextRect, withAttributes: textAttributes)
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

extension ThumbnailNSView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        // Return operation based on user setting
        if dragMode == "move" {
            return .move
        } else {
            return .copy
        }
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // If move operation completed, we could delete the file here
        // For now, macOS will handle it automatically
    }
}

// MARK: - Selection Rectangle

struct SelectionRectangle: View {
    let start: CGPoint
    let current: CGPoint

    var body: some View {
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        Rectangle()
            .fill(Color.blue.opacity(0.2))
            .overlay(
                Rectangle()
                    .strokeBorder(Color.blue, lineWidth: 2)
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
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
