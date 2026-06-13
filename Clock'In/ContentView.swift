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
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main clock display
            VStack(spacing: 20) {
                // Day of the week
                Text(currentTime.formatted(.dateTime.weekday(.wide)))
                    .font(.custom("Tosh A Regular", size: 100))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .textCase(.uppercase)
                    .kerning(30)
                    .fixedSize()
                
                // Date
                Text(currentTime.formatted(date: .long, time: .omitted))
                    .font(.custom("Tosh A Regular ", size: 40))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .fixedSize()
                    .kerning(10)
                
                // Current time
                Text(currentTime.formatted(date: .omitted, time: .shortened))
                    .font(.custom("Tosh A Regular", size: 90))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .fixedSize()
            
            }
            .padding(30)
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
        .onReceive(timer) { input in
            currentTime = input
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isRepositionMode {
                        dragOffset = value.translation
                        if let window = NSApplication.shared.windows.first {
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
        }
        .onAppear {
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
    }
    
    private func saveWindowPosition() {
        if let window = NSApplication.shared.windows.first {
            let origin = window.frame.origin
            UserDefaults.standard.set(origin.x, forKey: "clockPositionX")
            UserDefaults.standard.set(origin.y, forKey: "clockPositionY")
        }
    }
    
    private func centerWindow() {
        if let window = NSApplication.shared.windows.first,
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
