//
//  HandyShotsApp.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import SwiftUI
import AppKit

/// Main application entry point
@main
struct HandyShotsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings window scene
        Settings {
            SettingsView()
        }
    }
}

/// Application delegate managing menu bar and popover
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    /// Status bar item (menu bar icon)
    var statusItem: NSStatusItem?

    /// Popover for main interface
    var popover = NSPopover()

    /// Settings window controller
    var settingsWindow: NSWindow?

    /// Folder monitor instance
    var folderMonitor: FolderMonitor?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from appearing in Dock
        NSApp.setActivationPolicy(.accessory)

        setupMenuBarIcon()
        setupPopover()
        startFolderMonitoring()
    }

    // MARK: - Setup Methods

    /// Configure menu bar status item with icon and click handlers
    private func setupMenuBarIcon() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            print("❌ Error: Failed to create status bar button")
            return
        }

        // Set icon using SF Symbol
        if let image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "HandyShots") {
            image.isTemplate = true // Allows icon to adapt to light/dark mode
            button.image = image
        }

        // Add left-click action
        button.action = #selector(togglePopover)
        button.target = self

        // Add right-click action using sendAction
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// Configure popover with content and behavior
    private func setupPopover() {
        // Initialize folder monitor first
        folderMonitor = FolderMonitor()

        popover.contentSize = NSSize(width: 400, height: 300)
        popover.behavior = .transient // Close when clicking outside

        // Pass folder monitor to PopoverView
        let popoverView = PopoverView()
            .environmentObject(folderMonitor!)

        popover.contentViewController = NSHostingController(rootView: popoverView)
    }

    /// Initialize and start folder monitoring
    private func startFolderMonitoring() {
        folderMonitor?.startMonitoring()
    }

    // MARK: - User Interaction Handlers

    /// Handle menu bar icon clicks (left and right)
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }

        // Check which mouse button was clicked
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                showContextMenu()
            } else {
                // Left click - toggle popover
                if popover.isShown {
                    popover.performClose(sender)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    // Activate app to receive keyboard events
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }

    /// Display context menu with Settings and Quit options
    private func showContextMenu() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()

        // Settings menu item
        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit menu item
        let quitItem = NSMenuItem(
            title: "Quit HandyShots",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Show menu at button location
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil // Reset to allow normal clicks
    }

    /// Open Settings window
    @objc func openSettings() {
        // If settings window doesn't exist, create it
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "HandyShots Settings"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.setContentSize(NSSize(width: 400, height: 250))
            settingsWindow?.center()

            // Clean up window reference when closed
            settingsWindow?.delegate = self
        }

        // Show and bring to front
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Terminate the application
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}

// MARK: - Window Delegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == settingsWindow {
            settingsWindow = nil
        }
    }
}
