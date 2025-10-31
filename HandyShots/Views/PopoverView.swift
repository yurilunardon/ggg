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

    /// Last clicked screenshot for shift+click range selection
    @State private var lastSelectedID: String?

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

                Button(action: {
                    // Open folder in Finder
                    let url = URL(fileURLWithPath: folderMonitor.currentFolder)
                    NSWorkspace.shared.open(url)
                }) {
                    Text(folderMonitor.currentFolder)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .underline()
                }
                .buttonStyle(.plain)
                .help("Click to open folder in Finder")

                Spacer()

                // Selection controls
                if !screenshots.isEmpty {
                    if selectedScreenshots.isEmpty {
                        // Select All button when nothing selected
                        Button(action: { selectAll() }) {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 11))
                                Text("Select All")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Select all (⌘A)")
                    } else if selectedScreenshots.count == screenshots.count {
                        // All selected - show Deselect All button with counter
                        HStack(spacing: 6) {
                            // Counter badge
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                Text("\(selectedScreenshots.count)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue)
                            .cornerRadius(4)

                            // Deselect All button
                            Button(action: { deselectAll() }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 11))
                                    Text("Deselect All")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .help("Deselect all")
                        }
                    } else {
                        // Some selected - show counter badge and X button
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                Text("\(selectedScreenshots.count)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue)
                            .cornerRadius(4)

                            Button(action: { deselectAll() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Deselect all")
                        }
                    }
                }

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
        Group {
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
                // Grid of screenshots with selection support
                ScreenshotGridView(
                    screenshots: screenshots,
                    selectedScreenshots: $selectedScreenshots,
                    enableHoverZoom: enableHoverZoom,
                    lastSelectedID: $lastSelectedID,
                    onSelectScreenshot: { screenshot, modifiers in
                        handleSelection(screenshot: screenshot, modifiers: modifiers)
                    },
                    onOpenScreenshots: { screenshot in
                        openScreenshots(for: screenshot)
                    }
                )
                .onAppear {
                    // Setup keyboard shortcuts
                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "a" {
                            selectAll()
                            return nil // consume event
                        }
                        return event
                    }
                }
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

    /// Handle screenshot selection with modifier keys (macOS Finder-style)
    private func handleSelection(screenshot: Screenshot, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            // Cmd+Click: toggle selection
            if selectedScreenshots.contains(screenshot.id) {
                selectedScreenshots.remove(screenshot.id)
            } else {
                selectedScreenshots.insert(screenshot.id)
                lastSelectedID = screenshot.id
            }
        } else if modifiers.contains(.shift), let lastID = lastSelectedID {
            // Shift+Click: select range
            if let startIndex = screenshots.firstIndex(where: { $0.id == lastID }),
               let endIndex = screenshots.firstIndex(where: { $0.id == screenshot.id }) {
                let range = min(startIndex, endIndex)...max(startIndex, endIndex)
                for index in range {
                    selectedScreenshots.insert(screenshots[index].id)
                }
            }
        } else {
            // Regular click
            if selectedScreenshots.contains(screenshot.id) {
                // Already selected
                if selectedScreenshots.count == 1 {
                    // Single item selected - toggle it off
                    selectedScreenshots.removeAll()
                    lastSelectedID = nil
                }
                // If multiple selected, keep the selection for double-click to work
            } else {
                // Not selected - select only this one
                selectedScreenshots = [screenshot.id]
                lastSelectedID = screenshot.id
            }
        }
    }

    /// Select all screenshots
    private func selectAll() {
        selectedScreenshots = Set(screenshots.map { $0.id })
    }

    /// Deselect all screenshots
    private func deselectAll() {
        selectedScreenshots.removeAll()
        lastSelectedID = nil
    }

    /// Open screenshot(s) - if selected, open all selected ones
    private func openScreenshots(for screenshot: Screenshot) {
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

// MARK: - Screenshot Grid View

struct ScreenshotGridView: NSViewRepresentable {
    let screenshots: [Screenshot]
    @Binding var selectedScreenshots: Set<String>
    let enableHoverZoom: Bool
    @Binding var lastSelectedID: String?
    let onSelectScreenshot: (Screenshot, NSEvent.ModifierFlags) -> Void
    let onOpenScreenshots: (Screenshot) -> Void

    func makeNSView(context: Context) -> ScreenshotGridNSView {
        let view = ScreenshotGridNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: ScreenshotGridNSView, context: Context) {
        nsView.screenshots = screenshots
        nsView.selectedScreenshots = selectedScreenshots
        nsView.enableHoverZoom = enableHoverZoom
        nsView.onSelectScreenshot = onSelectScreenshot
        nsView.onOpenScreenshots = onOpenScreenshots
        nsView.onDeselectAll = {
            selectedScreenshots.removeAll()
            lastSelectedID = nil
        }
        nsView.onBatchSelect = { ids in
            selectedScreenshots = ids
        }
        nsView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        var parent: ScreenshotGridView

        init(parent: ScreenshotGridView) {
            self.parent = parent
        }
    }
}

// MARK: - Drag Selection View

class DragSelectionView: NSView {
    weak var parentScrollView: ScreenshotGridNSView?

    private var selectionStartPoint: NSPoint?
    private var selectionCurrentPoint: NSPoint?
    private var isDraggingSelection: Bool = false
    private var autoScrollTimer: Timer?

    // Flip coordinate system so origin is top-left
    override var isFlipped: Bool {
        return true
    }

    // Accept first mouse to handle clicks properly
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        // Check if we clicked on a thumbnail
        let clickedThumbnail = subviews.first { view in
            view is ThumbnailNSView && view.frame.contains(point)
        }

        // If we clicked on empty space, start drag selection
        if clickedThumbnail == nil {
            selectionStartPoint = point
            selectionCurrentPoint = point
            isDraggingSelection = false // Will become true in mouseDragged

            // Make this view the first responder to ensure we get mouseUp
            if let window = self.window {
                window.makeFirstResponder(self)
            }
        } else {
            // Let the thumbnail handle it
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard selectionStartPoint != nil else {
            super.mouseDragged(with: event)
            return
        }

        isDraggingSelection = true
        selectionCurrentPoint = convert(event.locationInWindow, from: nil)

        // Handle auto-scrolling when near edges
        handleAutoScroll(at: selectionCurrentPoint)

        // Redraw to show selection rectangle
        needsDisplay = true

        // Update selection based on current rectangle
        updateSelectionInRect()
    }

    private func handleAutoScroll(at point: NSPoint?) {
        guard let point = point,
              let scrollView = parentScrollView else {
            stopAutoScroll()
            return
        }

        // Get visible rect in scroll view
        let visibleRect = scrollView.documentVisibleRect
        let scrollThreshold: CGFloat = 30 // pixels from edge to trigger scroll

        // Check if near top or bottom edge
        let distanceFromTop = point.y - visibleRect.minY
        let distanceFromBottom = visibleRect.maxY - point.y

        if distanceFromTop < scrollThreshold || distanceFromBottom < scrollThreshold {
            // Start auto-scroll if not already running
            if autoScrollTimer == nil {
                autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                    self?.performAutoScroll()
                }
            }
        } else {
            stopAutoScroll()
        }
    }

    private func performAutoScroll() {
        guard let point = selectionCurrentPoint,
              let scrollView = parentScrollView else {
            stopAutoScroll()
            return
        }

        let visibleRect = scrollView.documentVisibleRect
        let scrollThreshold: CGFloat = 30
        let scrollSpeed: CGFloat = 10

        var newOrigin = visibleRect.origin

        // Scroll up if near top
        if point.y - visibleRect.minY < scrollThreshold {
            newOrigin.y = max(0, newOrigin.y - scrollSpeed)
        }
        // Scroll down if near bottom
        else if visibleRect.maxY - point.y < scrollThreshold {
            let maxY = frame.height - visibleRect.height
            newOrigin.y = min(maxY, newOrigin.y + scrollSpeed)
        }

        // Perform scroll
        if newOrigin != visibleRect.origin {
            scrollView.contentView.scroll(to: newOrigin)
            scrollView.reflectScrolledClipView(scrollView.contentView)

            // Update selection during scroll
            needsDisplay = true
            updateSelectionInRect()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    override func mouseUp(with event: NSEvent) {
        // Stop auto-scrolling
        stopAutoScroll()

        if isDraggingSelection {
            // Finalize selection
            updateSelectionInRect()
        } else if selectionStartPoint != nil {
            // Click on empty area without drag - deselect all
            parentScrollView?.onDeselectAll?()
        }

        // Clear selection rectangle
        selectionStartPoint = nil
        selectionCurrentPoint = nil
        isDraggingSelection = false
        needsDisplay = true
    }

    private func updateSelectionInRect() {
        guard let scrollView = parentScrollView,
              let startPoint = selectionStartPoint,
              let currentPoint = selectionCurrentPoint else { return }

        // Calculate selection rectangle
        let selectionRect = NSRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )

        // Find thumbnails that intersect with selection rectangle
        var selectedIDs = Set<String>()
        for view in subviews {
            guard let thumbnailView = view as? ThumbnailNSView,
                  let screenshot = thumbnailView.screenshot else { continue }

            if view.frame.intersects(selectionRect) {
                selectedIDs.insert(screenshot.id)
            }
        }

        // Update selection with all selected IDs
        scrollView.onBatchSelect?(selectedIDs)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw selection rectangle if dragging
        if isDraggingSelection,
           let startPoint = selectionStartPoint,
           let currentPoint = selectionCurrentPoint {

            let selectionRect = NSRect(
                x: min(startPoint.x, currentPoint.x),
                y: min(startPoint.y, currentPoint.y),
                width: abs(currentPoint.x - startPoint.x),
                height: abs(currentPoint.y - startPoint.y)
            )

            // Fill with semi-transparent blue
            NSColor.systemBlue.withAlphaComponent(0.2).setFill()
            selectionRect.fill()

            // Stroke with blue border
            NSColor.systemBlue.setStroke()
            let borderPath = NSBezierPath(rect: selectionRect)
            borderPath.lineWidth = 2
            borderPath.stroke()
        }
    }
}

// MARK: - Screenshot Grid NSView

class ScreenshotGridNSView: NSScrollView {
    var screenshots: [Screenshot] = []
    var selectedScreenshots: Set<String> = []
    var enableHoverZoom: Bool = false
    var onSelectScreenshot: ((Screenshot, NSEvent.ModifierFlags) -> Void)?
    var onOpenScreenshots: ((Screenshot) -> Void)?
    var onDeselectAll: (() -> Void)?
    var onBatchSelect: ((Set<String>) -> Void)?
    var coordinator: ScreenshotGridView.Coordinator?

    private var thumbnailViews: [ThumbnailNSView] = []
    private var containerView: DragSelectionView!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupScrollView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollView()
    }

    private func setupScrollView() {
        hasVerticalScroller = true
        hasHorizontalScroller = false
        autohidesScrollers = true
        backgroundColor = .clear
        drawsBackground = false

        containerView = DragSelectionView(frame: .zero)
        containerView.parentScrollView = self
        documentView = containerView
    }

    override func layout() {
        super.layout()
        layoutThumbnails()
    }

    private func layoutThumbnails() {
        // Clear existing views
        thumbnailViews.forEach { $0.removeFromSuperview() }
        thumbnailViews.removeAll()

        let padding: CGFloat = 12
        let itemWidth: CGFloat = 80
        let itemHeight: CGFloat = 100
        let spacing: CGFloat = 8
        let cols = 4

        var x: CGFloat = padding
        var y: CGFloat = padding

        for (index, screenshot) in screenshots.enumerated() {
            let col = index % cols
            let row = index / cols

            x = padding + CGFloat(col) * (itemWidth + spacing)
            y = padding + CGFloat(row) * (itemHeight + spacing)

            let frame = NSRect(x: x, y: y, width: itemWidth, height: itemHeight)
            let thumbnailView = ThumbnailNSView()
            thumbnailView.frame = frame
            thumbnailView.screenshot = screenshot
            thumbnailView.isSelected = selectedScreenshots.contains(screenshot.id)
            thumbnailView.enableHoverZoom = enableHoverZoom
            thumbnailView.onSelect = { [weak self] modifiers in
                self?.onSelectScreenshot?(screenshot, modifiers)
            }
            thumbnailView.onOpen = { [weak self] in
                self?.onOpenScreenshots?(screenshot)
            }
            thumbnailView.onGetSelectedScreenshots = { [weak self] in
                guard let self = self else { return [] }
                return self.screenshots.filter { self.selectedScreenshots.contains($0.id) }
            }

            containerView.addSubview(thumbnailView)
            thumbnailViews.append(thumbnailView)
        }

        // Set content size
        let rows = (screenshots.count + cols - 1) / cols
        let contentHeight = padding + CGFloat(rows) * (itemHeight + spacing)
        containerView.frame = NSRect(x: 0, y: 0, width: frame.width, height: contentHeight)
    }
}

// MARK: - Thumbnail NSView

class ThumbnailNSView: NSView {
    var screenshot: Screenshot?
    var isSelected: Bool = false
    var enableHoverZoom: Bool = false
    var onSelect: ((NSEvent.ModifierFlags) -> Void)?
    var onOpen: (() -> Void)?
    var onGetSelectedScreenshots: (() -> [Screenshot])?

    @AppStorage("dragMode") private var dragMode: String = "copy"

    private var previewTimer: Timer?
    private var isDragging: Bool = false
    private var mouseDownPoint: NSPoint?
    private var dragThreshold: CGFloat = 5.0 // pixels to move before considering it a drag
    private var trackingArea: NSTrackingArea?
    private var clickTimer: Timer?
    private var clickCount: Int = 0

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

    override func layout() {
        super.layout()
        // Update tracking areas when layout changes
        updateTrackingAreas()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        // Ensure hover state is updated even if mouseEntered doesn't fire
        super.mouseMoved(with: event)
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

        // Check if we should drag multiple selected files
        let screenshotsToDrag: [Screenshot]
        if isSelected, let selectedScreenshots = onGetSelectedScreenshots?(), selectedScreenshots.count > 1 {
            // Drag all selected screenshots
            screenshotsToDrag = selectedScreenshots
        } else {
            // Drag just this one
            screenshotsToDrag = [screenshot]
        }

        // Create drag items for each screenshot
        var dragItems: [NSDraggingItem] = []

        for (index, screenshotToDrag) in screenshotsToDrag.enumerated() {
            let fileURL = screenshotToDrag.url as NSURL
            let item = NSDraggingItem(pasteboardWriter: fileURL)

            // Set drag image - start slightly bigger than thumbnail (90px)
            if let thumbnail = screenshotToDrag.thumbnail {
                let dragImage = thumbnail

                // Start slightly bigger than thumbnail (80x80 -> 90x90)
                let startSize: CGFloat = 90

                // Offset each image slightly for multi-file drag
                let offset: CGFloat = CGFloat(index) * 4
                let startFrame = NSRect(
                    x: offset, y: -offset,
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
                    component.frame = NSRect(x: offset, y: -offset, width: finalSize, height: finalSize)
                    return [component]
                }
            }

            dragItems.append(item)
        }

        // Start dragging session with all items
        let session = beginDraggingSession(with: dragItems, event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func mouseUp(with event: NSEvent) {
        // Only handle click if we didn't drag
        guard !isDragging else {
            isDragging = false
            return
        }

        // Handle double-click
        if event.clickCount == 2 {
            // Double click opens
            clickTimer?.invalidate()
            clickTimer = nil
            clickCount = 0
            onOpen?()
        } else if event.clickCount == 1 {
            // Single click selects (with modifiers)
            onSelect?(event.modifierFlags)
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
