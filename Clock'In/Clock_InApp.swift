//
//  Clock_InApp.swift
//  Clock'In
//
//  Created by Nirwa Gandhi on 13/06/26.
//

import SwiftUI

@main
struct Clock_InApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("Clock'In", id: "clock") {
            ContentView()
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 800, height: 400)
        
        // Settings window
        Settings {
            SettingsView()
        }
        
        // Add menu bar extra
        MenuBarExtra("Clock'In", systemImage: "clock") {
            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button("Quit Clock'In") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        var window: NSWindow?
        
        func applicationDidFinishLaunching(_ notification: Notification) {
            // Hide the Dock icon
            NSApp.setActivationPolicy(.accessory)
            
            // Delay to ensure window is fully created
            DispatchQueue.main.async { [weak self] in
                self?.setupClockWindow()
                
                // Ensure window is visible on launch
                self?.showClockWindow()
            }
            
            // Handle wake from sleep
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(receivedWakeNotification),
                name: NSWorkspace.didWakeNotification,
                object: nil
            )
        }
        
        private func setupClockWindow() {
            // Find the clock window specifically
            guard let window = NSApplication.shared.windows.first(where: { window in
                // Look for window with "clock" identifier or the main content window
                return window.identifier?.rawValue == "clock" || 
                       (window.title.contains("Clock") && !window.title.contains("Settings"))
            }) else {
                return
            }
            
            self.window = window
            
            // Make window transparent and frameless
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            
            // Ensure content view is also transparent
            if let contentView = window.contentView {
                contentView.wantsLayer = true
                if let layer = contentView.layer {
                    layer.backgroundColor = NSColor.clear.cgColor
                }
            }
            
            // Remove title bar
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            
            // Remove window control buttons (minimize, close, fullscreen)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            // Make window always on desktop level (behind other windows)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            // Restore saved position and size or center on screen
            let savedX = UserDefaults.standard.object(forKey: "clockPositionX") as? CGFloat
            let savedY = UserDefaults.standard.object(forKey: "clockPositionY") as? CGFloat
            let savedWidth = UserDefaults.standard.object(forKey: "clockWidth") as? CGFloat
            let savedHeight = UserDefaults.standard.object(forKey: "clockHeight") as? CGFloat
            
            if let savedX = savedX, let savedY = savedY {
                // If we have saved size, restore both position and size
                if let savedWidth = savedWidth, let savedHeight = savedHeight {
                    window.setFrame(
                        NSRect(x: savedX, y: savedY, width: savedWidth, height: savedHeight),
                        display: true
                    )
                } else {
                    // Just restore position
                    window.setFrameOrigin(NSPoint(x: savedX, y: savedY))
                }
            } else {
                // Center the window on first launch
                window.center()
            }
        }
        
        @objc func receivedWakeNotification() {
            // Ensure window is visible and properly positioned after wake
            showClockWindow()
        }
        
        private func showClockWindow() {
            if let window = self.window {
                window.orderFront(nil)
                // Make sure the window is at the correct level
                window.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            }
        }
        
        deinit {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
        }
    }
}
