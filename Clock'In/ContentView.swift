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
    
    // Solid color components
    @AppStorage("clockColorRed") private var red: Double = 1.0
    @AppStorage("clockColorGreen") private var green: Double = 1.0
    @AppStorage("clockColorBlue") private var blue: Double = 1.0
    @AppStorage("clockColorAlpha") private var alpha: Double = 1.0
    
    // Gradient mode
    @AppStorage("useGradient") private var useGradient: Bool = false
    @AppStorage("gradientDirection") private var gradientDirection: String = "horizontal"
    @AppStorage("gradientType") private var gradientType: String = "linear"
    @AppStorage("gradientAngle") private var gradientAngle: Double = 0.0
    @AppStorage("gradientStops") private var gradientStopsJSON: String = ""
    
    // Font settings
    @AppStorage("fontName") private var fontName: String = "System"
    @AppStorage("fontWeight") private var fontWeight: String = "thin"
    @AppStorage("fontDesign") private var fontDesign: String = "default"
    @AppStorage("fontStyle") private var fontStyle: String = "" // For custom font styles
    
    @State private var gradientStops: [GradientStop] = []
    
    struct GradientStop: Codable {
        var color: CodableColor
        var position: Double
        
        struct CodableColor: Codable {
            var red: Double
            var green: Double
            var blue: Double
            var alpha: Double
            
            var color: Color {
                Color(red: red, green: green, blue: blue, opacity: alpha)
            }
        }
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var clockColor: Color {
        // Use first gradient stop color, or default
        if !gradientStops.isEmpty {
            return gradientStops[0].color.color
        }
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    enum GradientDirection: String {
        case horizontal = "horizontal"
        case vertical = "vertical"
        case diagonal = "diagonal"
        case diagonalReverse = "diagonalReverse"
        case radial = "radial"
        case custom = "custom"
        
        var startPoint: UnitPoint {
            switch self {
            case .horizontal: return .leading
            case .vertical: return .top
            case .diagonal: return .topLeading
            case .diagonalReverse: return .topTrailing
            case .radial: return .center
            case .custom: return .center // Will be overridden by angle calculation
            }
        }
        
        var endPoint: UnitPoint {
            switch self {
            case .horizontal: return .trailing
            case .vertical: return .bottom
            case .diagonal: return .bottomTrailing
            case .diagonalReverse: return .bottomLeading
            case .radial: return .bottomTrailing
            case .custom: return .center // Will be overridden by angle calculation
            }
        }
    }
    
    var selectedDirection: GradientDirection {
        GradientDirection(rawValue: gradientDirection) ?? .horizontal
    }
    
    // Convert angle to start/end points for SwiftUI gradient
    func pointsForAngle(_ angle: Double) -> (UnitPoint, UnitPoint) {
        // Convert to radians
        let radians = angle * .pi / 180.0
        
        // Calculate the endpoint based on angle
        // 0° = left to right, 90° = top to bottom, etc.
        let x = cos(radians)
        let y = sin(radians)
        
        // Calculate start and end points
        let startX = 0.5 - x * 0.5
        let startY = 0.5 + y * 0.5
        let endX = 0.5 + x * 0.5
        let endY = 0.5 - y * 0.5
        
        return (
            UnitPoint(x: startX, y: startY),
            UnitPoint(x: endX, y: endY)
        )
    }
    
    func gradientStyle(opacity: Double = 1.0) -> AnyShapeStyle {
        if !useGradient || gradientStops.isEmpty {
            return AnyShapeStyle(clockColor.opacity(opacity))
        }
        
        // Create gradient stops with opacity applied
        let stops = gradientStops.sorted { $0.position < $1.position }.map {
            Gradient.Stop(color: $0.color.color.opacity(opacity), location: $0.position)
        }
        
        // Check gradient type (linear or radial)
        if gradientType == "radial" {
            return AnyShapeStyle(
                RadialGradient(
                    stops: stops,
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            )
        } else {
            // For linear gradients, use custom angle if preset is "custom"
            let points: (UnitPoint, UnitPoint)
            if selectedDirection == .custom {
                points = pointsForAngle(gradientAngle)
            } else {
                points = (selectedDirection.startPoint, selectedDirection.endPoint)
            }
            
            return AnyShapeStyle(
                LinearGradient(
                    stops: stops,
                    startPoint: points.0,
                    endPoint: points.1
                )
            )
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Transparent background to ensure window chrome is invisible
                Color.clear
                
                // Main clock display
                VStack(spacing: scaledValue(20, for: geometry.size)) {
                    // Day of the week
                    Text(currentTime.formatted(.dateTime.weekday(.wide)))
                        .font(clockFont(size: scaledValue(100, for: geometry.size)))
                        .foregroundStyle(gradientStyle())
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .textCase(.uppercase)
                        .kerning(scaledValue(30, for: geometry.size))
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                    
                    // Date
                    Text(currentTime.formatted(date: .long, time: .omitted))
                        .font(clockFont(size: scaledValue(40, for: geometry.size)))
                        .foregroundStyle(gradientStyle(opacity: 0.9))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .kerning(scaledValue(10, for: geometry.size))
                        .minimumScaleFactor(0.5)
                    
                    // Current time
                    Text(currentTime.formatted(date: .omitted, time: .shortened))
                        .font(clockFont(size: scaledValue(90, for: geometry.size)))
                        .foregroundStyle(gradientStyle())
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
            
            // Load gradient stops
            loadGradientStops()
            
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
        .onChange(of: gradientStopsJSON) { _, _ in
            loadGradientStops()
        }
    }
    
    private func loadGradientStops() {
        if !gradientStopsJSON.isEmpty,
           let data = gradientStopsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([GradientStop].self, from: data) {
            gradientStops = decoded
        } else {
            // Default gradient stops
            gradientStops = [
                GradientStop(color: GradientStop.CodableColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), position: 0.0),
                GradientStop(color: GradientStop.CodableColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0), position: 1.0)
            ]
        }
    }
    
    private func clockFont(size: CGFloat) -> Font {
        if fontName == "System" {
            return .system(size: size, weight: fontWeightValue, design: fontDesignValue)
        } else {
            // For custom fonts, we need to get the full PostScript name
            if !fontStyle.isEmpty,
               let members = NSFontManager.shared.availableMembers(ofFontFamily: fontName),
               let member = members.first(where: { ($0[1] as? String) == fontStyle }),
               let postScriptName = member[0] as? String {
                return .custom(postScriptName, size: size)
            }
            // Fallback to just the family name
            return .custom(fontName, size: size)
        }
    }
    
    private var fontWeightValue: Font.Weight {
        switch fontWeight {
        case "ultralight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .thin
        }
    }
    
    private var fontDesignValue: Font.Design {
        switch fontDesign {
        case "serif": return .serif
        case "rounded": return .rounded
        case "monospaced": return .monospaced
        default: return .default
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
