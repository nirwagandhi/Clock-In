//
//  ContentView.swift
//  Clock'In
//
//  Created by Nirwa Gandhi on 13/06/26.
//

import SwiftUI
internal import Combine

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var isRepositionMode = false
    @State private var dragOffset: CGSize = .zero
    @State private var windowSize: CGSize = .zero
    @Environment(\.openWindow) private var openWindow
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Transparent background to ensure window chrome is invisible
                Color.clear
                
                // Main clock display
                VStack(spacing: scaledValue(20, for: geometry.size)) {
                    // Day of the week
                    Text(currentTime.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: scaledValue(100, for: geometry.size), weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .textCase(.uppercase)
                        .kerning(scaledValue(30, for: geometry.size))
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.5)
                    
                    // Date
                    Text(currentTime.formatted(date: .long, time: .omitted))
                        .font(.system(size: scaledValue(40, for: geometry.size), weight: .thin, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .kerning(scaledValue(10, for: geometry.size))
                        .minimumScaleFactor(0.5)
                    
                    // Current time
                    Text(currentTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: scaledValue(90, for: geometry.size), weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.5)
                
                }
                .padding(scaledValue(30, for: geometry.size))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    isRepositionMode ? 
                        Color.black.opacity(0.3) : Color.clear
                )
                .cornerRadius(isRepositionMode ? 15 : 0)
                .overlay(
                    isRepositionMode ?
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            .padding(1)
                        : nil
                )
                
                // Reposition mode toggle button (always visible)
                RepositionButton(isRepositionMode: $isRepositionMode)
                    .padding(8)
            }
            .onAppear {
                windowSize = geometry.size
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                windowSize = newSize
                if isRepositionMode {
                    saveWindowSize(newSize)
                }
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isRepositionMode {
                        dragOffset = value.translation
                        if let window = getCurrentWindow() {
                            let currentOrigin = window.frame.origin
                            window.setFrameOrigin(NSPoint(
                                x: currentOrigin.x + value.translation.width,
                                y: currentOrigin.y - value.translation.height
                            ))
                        }
                    }
                }
                .onEnded { _ in
                    if isRepositionMode {
                        dragOffset = .zero
                        saveWindowPosition()
                    }
                }
        )
        .onTapGesture(count: 3) {
            // Triple-tap to toggle reposition mode
            isRepositionMode.toggle()
            updateWindowResizability()
        }
        .onAppear {
            updateWindowResizability()
            
            // Add keyboard shortcuts
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Command+R to recenter window
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "r" {
                    self.centerWindow()
                    return nil
                }
                return event
            }
        }
        .onChange(of: isRepositionMode) { oldValue, newValue in
            updateWindowResizability()
        }
    }
    
    private func scaledValue(_ baseValue: CGFloat, for size: CGSize) -> CGFloat {
        // Base size reference (your original window size)
        let baseWidth: CGFloat = 800
        let scale = size.width / baseWidth
        return baseValue * scale
    }
    
    private func getCurrentWindow() -> NSWindow? {
        return NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first
    }
    
    private func updateWindowResizability() {
        if let window = getCurrentWindow() {
            if isRepositionMode {
                // Enable resizing
                window.styleMask.insert([.resizable])
                window.minSize = NSSize(width: 400, height: 300)
                window.maxSize = NSSize(width: 2000, height: 1500)
            } else {
                // Disable resizing
                window.styleMask.remove(.resizable)
            }
        }
    }
    
    private func saveWindowPosition() {
        if let window = getCurrentWindow() {
            let origin = window.frame.origin
            UserDefaults.standard.set(origin.x, forKey: "clockPositionX")
            UserDefaults.standard.set(origin.y, forKey: "clockPositionY")
        }
    }
    
    private func saveWindowSize(_ size: CGSize) {
        UserDefaults.standard.set(size.width, forKey: "clockWidth")
        UserDefaults.standard.set(size.height, forKey: "clockHeight")
    }
    
    private func centerWindow() {
        if let window = getCurrentWindow(),
           let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
            saveWindowPosition()
        }
    }
}

struct RepositionButton: View {
    @Binding var isRepositionMode: Bool
    
    var body: some View {
        Button(action: {
            isRepositionMode.toggle()
        }) {
            Image(systemName: isRepositionMode ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help(isRepositionMode ? "Lock position" : "Unlock to reposition")
        .opacity(isRepositionMode ? 1 : 0)
    }
}

#Preview {
    ContentView()
}
