//
//  SettingsView.swift
//  Clock'In
//
//  Created by Nirwa Gandhi on 13/06/26.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var loginItemStatus: SMAppService.Status = .notRegistered
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        updateLaunchAtLogin(enabled: newValue)
                    }
                
                Button("Reset Position") {
                    // Reset to center of screen
                    UserDefaults.standard.removeObject(forKey: "clockPositionX")
                    UserDefaults.standard.removeObject(forKey: "clockPositionY")
                    
                    // Find the clock window specifically (not the settings window)
                    if let clockWindow = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "clock" }) {
                        clockWindow.center()
                    }
                }
                
                Button("Reset Size") {
                    // Reset to default size
                    UserDefaults.standard.removeObject(forKey: "clockWidth")
                    UserDefaults.standard.removeObject(forKey: "clockHeight")
                    
                    // Find the clock window specifically (not the settings window)
                    if let clockWindow = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "clock" }) {
                        clockWindow.setContentSize(NSSize(width: 800, height: 400))
                    }
                }
            } header: {
                Text("Window")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            // Sync the toggle with actual login item status
            syncLoginItemStatus()
        }
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if loginItemStatus == .enabled {
                    // Already enabled, no need to register again
                    return
                }
                try SMAppService.mainApp.register()
                print("Successfully registered for launch at login")
            } else {
                if loginItemStatus == .notRegistered {
                    // Already not registered
                    return
                }
                try SMAppService.mainApp.unregister()
                print("Successfully unregistered from launch at login")
            }
            // Update status after change
            loginItemStatus = SMAppService.mainApp.status
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            // Revert the toggle if the operation failed
            DispatchQueue.main.async {
                launchAtLogin = !enabled
            }
        }
    }
    
    private func syncLoginItemStatus() {
        loginItemStatus = SMAppService.mainApp.status
        // Update the toggle to match actual status
        let isEnabled = loginItemStatus == .enabled
        if launchAtLogin != isEnabled {
            launchAtLogin = isEnabled
        }
    }
}

struct AppearanceSettingsView: View {
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
    
    // Store gradient stops as JSON
    @AppStorage("gradientStops") private var gradientStopsJSON: String = ""
    
    @State private var customAngleInput: Double = 0.0
    @State private var gradientStops: [GradientStop] = []
    
    struct GradientStop: Identifiable, Codable, Equatable {
        var id = UUID()
        var color: CodableColor
        var position: Double
        
        struct CodableColor: Codable, Equatable {
            var red: Double
            var green: Double
            var blue: Double
            var alpha: Double
            
            var color: Color {
                Color(red: red, green: green, blue: blue, opacity: alpha)
            }
            
            init(color: Color) {
                let nsColor = NSColor(color)
                if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
                    self.red = Double(rgbColor.redComponent)
                    self.green = Double(rgbColor.greenComponent)
                    self.blue = Double(rgbColor.blueComponent)
                    self.alpha = Double(rgbColor.alphaComponent)
                } else {
                    self.red = 1.0
                    self.green = 1.0
                    self.blue = 1.0
                    self.alpha = 1.0
                }
            }
            
            init(red: Double, green: Double, blue: Double, alpha: Double) {
                self.red = red
                self.green = green
                self.blue = blue
                self.alpha = alpha
            }
        }
    }
    
    enum GradientType: String, CaseIterable {
        case linear = "Linear"
        case radial = "Radial"
        
        var key: String { rawValue.lowercased() }
    }
    
    enum GradientPreset: String, CaseIterable {
        case horizontal = "Horizontal (0°)"
        case vertical = "Vertical (90°)"
        case diagonal = "Diagonal (45°)"
        case diagonalReverse = "Diagonal (-45°)"
        case custom = "Custom Angle"
        
        var angle: Double {
            switch self {
            case .horizontal: return 0
            case .vertical: return 90
            case .diagonal: return 45
            case .diagonalReverse: return -45
            case .custom: return 0
            }
        }
        
        var key: String {
            switch self {
            case .horizontal: return "horizontal"
            case .vertical: return "vertical"
            case .diagonal: return "diagonal"
            case .diagonalReverse: return "diagonalReverse"
            case .custom: return "custom"
            }
        }
    }
    
    var selectedType: GradientType {
        GradientType.allCases.first(where: { $0.key == gradientType }) ?? .linear
    }
    
    var selectedPreset: GradientPreset {
        GradientPreset.allCases.first(where: { $0.key == gradientDirection }) ?? .horizontal
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
    
    var body: some View {
        Form {
            Section {
                Toggle("Use Gradient", isOn: $useGradient)
                
                if useGradient {
                    // Gradient stops editor
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Color Stops:")
                                .font(.headline)
                            Spacer()
                            Button(action: addGradientStop) {
                                Label("Add Color", systemImage: "plus.circle.fill")
                            }
                            .disabled(gradientStops.count >= 10)
                        }
                        
                        ForEach($gradientStops) { $stop in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    ColorPicker("", selection: Binding(
                                        get: { stop.color.color },
                                        set: { newColor in
                                            stop.color = GradientStop.CodableColor(color: newColor)
                                            saveGradientStops()
                                        }
                                    ))
                                    .labelsHidden()
                                    .frame(width: 50)
                                    
                                    Text("Position:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Slider(value: $stop.position, in: 0...1, step: 0.01)
                                        .onChange(of: stop.position) { _, _ in
                                            saveGradientStops()
                                        }
                                    
                                    Text("\(Int(stop.position * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                    
                                    if gradientStops.count > 2 {
                                        Button(action: {
                                            removeGradientStop(stop)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Picker("Type", selection: $gradientType) {
                        ForEach(GradientType.allCases, id: \.key) { type in
                            Text(type.rawValue).tag(type.key)
                        }
                    }
                    
                    if selectedType == .linear {
                        Picker("Preset", selection: $gradientDirection) {
                            ForEach(GradientPreset.allCases, id: \.key) { preset in
                                Text(preset.rawValue).tag(preset.key)
                            }
                        }
                        .onChange(of: gradientDirection) { oldValue, newValue in
                            // Update angle when preset changes
                            if selectedPreset != .custom {
                                gradientAngle = selectedPreset.angle
                            } else {
                                // When switching to custom, load the current angle
                                customAngleInput = gradientAngle
                            }
                        }
                        
                        if selectedPreset == .custom {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Angle:")
                                    Spacer()
                                    TextField("", value: $customAngleInput, format: .number)
                                        .frame(width: 70)
                                        .textFieldStyle(.roundedBorder)
                                        .multilineTextAlignment(.trailing)
                                        .onSubmit {
                                            gradientAngle = customAngleInput
                                        }
                                    Text("°")
                                        .frame(width: 15, alignment: .leading)
                                }
                                
                                Slider(value: $customAngleInput, in: -180...180, step: 1)
                                    .labelsHidden()
                                
                                HStack {
                                    Text("-180°")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("180°")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Button("Apply Angle") {
                                    gradientAngle = customAngleInput
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(customAngleInput == gradientAngle)
                            }
                        } else {
                            HStack {
                                Text("Angle:")
                                Spacer()
                                Text("\(Int(gradientAngle))°")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Preview gradient
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview:")
                        
                        GeometryReader { geometry in
                            ZStack {
                                // Use the preview angle (customAngleInput for custom, gradientAngle for presets)
                                let previewAngle = selectedPreset == .custom ? customAngleInput : gradientAngle
                                let sortedStops = gradientStops.sorted { $0.position < $1.position }
                                
                                // Gradient background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        selectedType == .radial ?
                                            AnyShapeStyle(RadialGradient(
                                                stops: sortedStops.map { Gradient.Stop(color: $0.color.color, location: $0.position) },
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 100
                                            )) :
                                            AnyShapeStyle(LinearGradient(
                                                stops: sortedStops.map { Gradient.Stop(color: $0.color.color, location: $0.position) },
                                                startPoint: pointsForAngle(previewAngle).0,
                                                endPoint: pointsForAngle(previewAngle).1
                                            ))
                                    )
                                
                                // Show angle indicator for linear gradients
                                if selectedType == .linear {
                                    let points = pointsForAngle(previewAngle)
                                    let startX = points.0.x * geometry.size.width
                                    let startY = points.0.y * geometry.size.height
                                    let endX = points.1.x * geometry.size.width
                                    let endY = points.1.y * geometry.size.height
                                    
                                    Path { path in
                                        path.move(to: CGPoint(x: startX, y: startY))
                                        path.addLine(to: CGPoint(x: endX, y: endY))
                                    }
                                    .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                    
                                    // Show color stop indicators
                                    ForEach(gradientStops) { stop in
                                        Circle()
                                            .fill(stop.color.color)
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            .position(
                                                x: startX + (endX - startX) * stop.position,
                                                y: startY + (endY - startY) * stop.position
                                            )
                                    }
                                }
                            }
                        }
                        .frame(height: 80)
                    }
                } else {
                    ColorPicker("Clock Color", selection: Binding(
                        get: {
                            if gradientStops.isEmpty {
                                return .white
                            }
                            return gradientStops[0].color.color
                        },
                        set: { newColor in
                            if gradientStops.isEmpty {
                                gradientStops = [GradientStop(color: GradientStop.CodableColor(color: newColor), position: 0.0)]
                            } else {
                                gradientStops[0].color = GradientStop.CodableColor(color: newColor)
                            }
                            saveGradientStops()
                        }
                    ))
                }
                
                Button("Reset to Default") {
                    gradientStops = [
                        GradientStop(color: GradientStop.CodableColor(color: .white), position: 0.0),
                        GradientStop(color: GradientStop.CodableColor(color: Color(red: 0.5, green: 0.5, blue: 1.0)), position: 1.0)
                    ]
                    useGradient = false
                    gradientDirection = "horizontal"
                    gradientType = "linear"
                    gradientAngle = 0.0
                    saveGradientStops()
                }
            } header: {
                Text("Display")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadGradientStops()
        }
    }
    
    private func addGradientStop() {
        // Find a good position between existing stops
        let newPosition: Double
        if gradientStops.isEmpty {
            newPosition = 0.5
        } else {
            let sorted = gradientStops.sorted { $0.position < $1.position }
            newPosition = sorted.count > 1 ? (sorted[0].position + sorted[sorted.count - 1].position) / 2 : 0.5
        }
        
        gradientStops.append(GradientStop(
            color: GradientStop.CodableColor(color: .blue),
            position: newPosition
        ))
        saveGradientStops()
    }
    
    private func removeGradientStop(_ stop: GradientStop) {
        gradientStops.removeAll { $0.id == stop.id }
        saveGradientStops()
    }
    
    private func saveGradientStops() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(gradientStops),
           let jsonString = String(data: data, encoding: .utf8) {
            gradientStopsJSON = jsonString
        }
    }
    
    private func loadGradientStops() {
        // Try to load from JSON
        if !gradientStopsJSON.isEmpty,
           let data = gradientStopsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([GradientStop].self, from: data) {
            gradientStops = decoded
        } else {
            // Default gradient stops
            gradientStops = [
                GradientStop(color: GradientStop.CodableColor(red: red, green: green, blue: blue, alpha: alpha), position: 0.0),
                GradientStop(color: GradientStop.CodableColor(color: Color(red: 0.5, green: 0.5, blue: 1.0)), position: 1.0)
            ]
            saveGradientStops()
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Clock'In")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version Beta 1.2")
                .foregroundStyle(.secondary)
            
            Text("Created by Wh0isG4ns")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
