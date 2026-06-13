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
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
    
    class AppDelegate: NSObject, NSApplicationDelegate {
        var window: NSWindow?
        
        func applicationDidFinishLaunching(_ notification: Notification) {
            // Find the window
            if let window = NSApplication.shared.windows.first {
                self.window = window
                
                // Make window transparent and frameless
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = false
                window.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
                
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
                
                // Restore saved position or center on screen
                if let savedX = UserDefaults.standard.object(forKey: "clockPositionX") as? CGFloat,
                   let savedY = UserDefaults.standard.object(forKey: "clockPositionY") as? CGFloat {
                    window.setFrameOrigin(NSPoint(x: savedX, y: savedY))
                } else {
                    // Center the window on first launch
                    window.center()
                }
            }
        }
    }
}
