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
    @AppStorage("showDay") private var showDay = true
    @AppStorage("showDate") private var showDate = true
    @AppStorage("showTime") private var showTime = true
    @AppStorage("use24HourFormat") private var use24HourFormat = false
    @AppStorage("showSeconds") private var showSeconds = false
    @AppStorage("dateFormat") private var dateFormat: String = "MDY" // "MDY" or "DMY"
    @AppStorage("textAlignment") private var textAlignment: String = "center"
    @State private var loginItemStatus: SMAppService.Status = .notRegistered
    
    // Computed property to check if at least one component is visible
    private var atLeastOneComponentVisible: Bool {
        showDay || showDate || showTime
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Show Day", isOn: $showDay)
                    .disabled(!showDay && !atLeastOneComponentVisible)
                    .onChange(of: showDay) { oldValue, newValue in
                        // If trying to turn off and it's the last one, revert
                        if !newValue && !showDate && !showTime {
                            showDay = true
                        }
                    }
                
                Toggle("Show Date", isOn: $showDate)
                    .disabled(!showDate && !atLeastOneComponentVisible)
                    .onChange(of: showDate) { oldValue, newValue in
                        // If trying to turn off and it's the last one, revert
                        if !newValue && !showDay && !showTime {
                            showDate = true
                        }
                    }
                
                Toggle("Show Time", isOn: $showTime)
                    .disabled(!showTime && !atLeastOneComponentVisible)
                    .onChange(of: showTime) { oldValue, newValue in
                        // If trying to turn off and it's the last one, revert
                        if !newValue && !showDay && !showDate {
                            showTime = true
                        }
                    }
                
                if !atLeastOneComponentVisible {
                    Text("At least one component must be visible")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Alignment")
                    
                    Picker("Text Alignment", selection: $textAlignment) {
                        Label("Left", systemImage: "text.alignleft").tag("leading")
                        Label("Center", systemImage: "text.aligncenter").tag("center")
                        Label("Right", systemImage: "text.alignright").tag("trailing")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.top, 8)
            } header: {
                Text("Display Settings")
            } footer: {
                Text("At least one component must remain visible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Toggle("Use 24-Hour Format", isOn: $use24HourFormat)
                Toggle("Show Seconds", isOn: $showSeconds)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date Format")
                    
                    Picker("Date Format", selection: $dateFormat) {
                        Text("MM/DD/YYYY").tag("MDY")
                        Text("DD/MM/YYYY").tag("DMY")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.top, 8)
            } header: {
                Text("Time Settings")
            } footer: {
                Text("Choose between 12-hour (2:30 PM) or 24-hour (14:30) format, optionally display seconds, and select your preferred date format")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
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
    var body: some View {
        TabView {
            DisplaySettingsView()
                .tabItem {
                    Label("Display", systemImage: "paintpalette")
                }
            
            TypographySettingsView()
                .tabItem {
                    Label("Typography", systemImage: "textformat")
                }
        }
        .tabViewStyle(.automatic)
    }
}

struct DisplaySettingsView: View {
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
    
    // Display settings
    @AppStorage("clockOpacity") private var clockOpacity: Double = 1.0
    
    // Shadow settings
    @AppStorage("shadowEnabled") private var shadowEnabled: Bool = true
    @AppStorage("shadowColorRed") private var shadowRed: Double = 0.0
    @AppStorage("shadowColorGreen") private var shadowGreen: Double = 0.0
    @AppStorage("shadowColorBlue") private var shadowBlue: Double = 0.0
    @AppStorage("shadowColorAlpha") private var shadowAlpha: Double = 0.3
    @AppStorage("shadowRadius") private var shadowRadius: Double = 2.0
    @AppStorage("shadowX") private var shadowX: Double = 0.0
    @AppStorage("shadowY") private var shadowY: Double = 2.0
    
    @State private var clockColor: Color = .white
    @State private var shadowColor: Color = Color.black.opacity(0.3)
    @State private var customAngleInput: Double = 0.0
    @State private var gradientStops: [GradientStop] = []
    
    struct GradientStop: Identifiable, Codable {
        var id = UUID()
        var color: CodableColor
        var position: Double
        
        struct CodableColor: Codable {
            var red: Double
            var green: Double
            var blue: Double
            var alpha: Double
            
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
            
            var color: Color {
                Color(red: red, green: green, blue: blue, opacity: alpha)
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
        ScrollView {
            Form {
                Section {
                    Toggle("Use Gradient", isOn: $useGradient)
                    
                    if useGradient {
                    // Gradient stops list
                    ForEach(gradientStops.sorted(by: { $0.position < $1.position })) { stop in
                        if let index = gradientStops.firstIndex(where: { $0.id == stop.id }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    ColorPicker("Color", selection: Binding(
                                        get: { gradientStops[index].color.color },
                                        set: { newColor in
                                            gradientStops[index].color = GradientStop.CodableColor(color: newColor)
                                            saveGradientStops()
                                        }
                                    ))
                                    
                                    Spacer()
                                    
                                    // Delete button (only if more than 2 stops)
                                    if gradientStops.count > 2 {
                                        Button(action: {
                                            gradientStops.removeAll(where: { $0.id == stop.id })
                                            saveGradientStops()
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                HStack {
                                    Text("Position:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Slider(value: Binding(
                                        get: { gradientStops[index].position },
                                        set: { newValue in
                                            gradientStops[index].position = newValue
                                            saveGradientStops()
                                        }
                                    ), in: 0...1, step: 0.01)
                                    Text("\(Int(gradientStops[index].position * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                                .padding(.leading, 20)
                            }
                        }
                    }
                    
                    // Add gradient stop button
                    Button(action: addGradientStop) {
                        Label("Add Color Stop", systemImage: "plus.circle")
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
                                
                                Slider(value: $customAngleInput, in: -250...250, step: 1)
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
                                
                                // Gradient background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        selectedType == .radial ?
                                            AnyShapeStyle(RadialGradient(
                                                stops: gradientStops.sorted(by: { $0.position < $1.position }).map {
                                                    .init(color: $0.color.color, location: $0.position)
                                                },
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 100
                                            )) :
                                            AnyShapeStyle(LinearGradient(
                                                stops: gradientStops.sorted(by: { $0.position < $1.position }).map {
                                                    .init(color: $0.color.color, location: $0.position)
                                                },
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
                    ColorPicker("Clock Color", selection: $clockColor)
                        .onChange(of: clockColor) { oldValue, newValue in
                            saveColor(newValue)
                        }
                }
                
                // Opacity control
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Transparency")
                        Spacer()
                        Text("\(Int(clockOpacity * 100))%")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    
                    Slider(value: $clockOpacity, in: 0.1...1.0, step: 0.05)
                    
                    HStack {
                        Text("10%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("100%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button("Reset to Default") {
                    clockColor = .white
                    useGradient = false
                    gradientDirection = "horizontal"
                    gradientType = "linear"
                    gradientAngle = 0.0
                    clockOpacity = 1.0
                    
                    // Reset gradient stops to default
                    gradientStops = [
                        GradientStop(color: GradientStop.CodableColor(color: .white), position: 0.0),
                        GradientStop(color: GradientStop.CodableColor(color: Color(red: 0.5, green: 0.5, blue: 1.0)), position: 1.0)
                    ]
                    saveGradientStops()
                    saveColor(.white)
                }
                } header: {
                    Text("Color")
                }
                
                Section {
                    Toggle("Enable Shadow", isOn: $shadowEnabled)
                    
                    if shadowEnabled {
                        ColorPicker("Shadow Color", selection: $shadowColor)
                            .onChange(of: shadowColor) { oldValue, newValue in
                                saveShadowColor(newValue)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Shadow Blur Radius")
                                Spacer()
                                TextField("", value: $shadowRadius, format: .number)
                                    .frame(width: 60)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: shadowRadius) { oldValue, newValue in
                                        // Clamp the value within the valid range
                                        if newValue < 0 {
                                            shadowRadius = 0
                                        } else if newValue > 20 {
                                            shadowRadius = 20
                                        }
                                    }
                                Text("px")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .frame(width: 20, alignment: .leading)
                            }
                            
                            Slider(value: $shadowRadius, in: 0...20, step: 1)
                            
                            HStack {
                                Text("0px")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("20px")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Shadow Offset X")
                                Spacer()
                                TextField("", value: $shadowX, format: .number)
                                    .frame(width: 60)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: shadowX) { oldValue, newValue in
                                        // Clamp the value within the valid range
                                        if newValue < -250 {
                                            shadowX = -250
                                        } else if newValue > 250 {
                                            shadowX = 250
                                        }
                                    }
                                Text("px")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .frame(width: 20, alignment: .leading)
                            }
                            
                            Slider(value: $shadowX, in: -250...250, step: 1)
                            
                            HStack {
                                Text("-250px")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("250px")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Shadow Offset Y")
                                Spacer()
                                TextField("", value: $shadowY, format: .number)
                                    .frame(width: 60)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: shadowY) { oldValue, newValue in
                                        // Clamp the value within the valid range
                                        if newValue < -100 {
                                            shadowY = -100
                                        } else if newValue > 100 {
                                            shadowY = 100
                                        }
                                    }
                                Text("px")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .frame(width: 20, alignment: .leading)
                            }
                            
                            Slider(value: $shadowY, in: -100...100, step: 1)
                            
                            HStack {
                                Text("-100px")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("100px")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button("Reset Effects to Default") {
                        shadowEnabled = true
                        shadowColor = Color.black.opacity(0.3)
                        saveShadowColor(shadowColor)
                        shadowRadius = 2.0
                        shadowX = 0.0
                        shadowY = 2.0
                    }
                } header: {
                    Text("Effect Settings")
                } footer: {
                    Text("Customize shadow effects for better text visibility")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .padding()
            .onAppear {
                loadColors()
                loadGradientStops()
                loadShadowColor()
            }
            .onChange(of: gradientStopsJSON) { _, _ in
                loadGradientStops()
            }
        }
    }
    
    private func saveShadowColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            shadowRed = Double(rgbColor.redComponent)
            shadowGreen = Double(rgbColor.greenComponent)
            shadowBlue = Double(rgbColor.blueComponent)
            shadowAlpha = Double(rgbColor.alphaComponent)
        }
    }
    
    private func loadShadowColor() {
        shadowColor = Color(red: shadowRed, green: shadowGreen, blue: shadowBlue, opacity: shadowAlpha)
    }
    
    private func saveColor(_ color: Color) {
        // Convert SwiftUI Color to NSColor and extract components
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            red = Double(rgbColor.redComponent)
            green = Double(rgbColor.greenComponent)
            blue = Double(rgbColor.blueComponent)
            alpha = Double(rgbColor.alphaComponent)
        }
    }
    
    private func loadColors() {
        // Load colors from stored components
        clockColor = Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    private func loadGradientStops() {
        if !gradientStopsJSON.isEmpty,
           let data = gradientStopsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([GradientStop].self, from: data) {
            gradientStops = decoded
        } else {
            // Default gradient stops
            gradientStops = [
                GradientStop(color: GradientStop.CodableColor(color: .white), position: 0.0),
                GradientStop(color: GradientStop.CodableColor(color: Color(red: 0.5, green: 0.5, blue: 1.0)), position: 1.0)
            ]
        }
    }
    
    private func saveGradientStops() {
        if let encoded = try? JSONEncoder().encode(gradientStops),
           let json = String(data: encoded, encoding: .utf8) {
            gradientStopsJSON = json
        }
    }
    
    private func addGradientStop() {
        // Find a good position for the new stop (midpoint between existing stops)
        let sortedStops = gradientStops.sorted(by: { $0.position < $1.position })
        var newPosition = 0.5
        
        // Find the largest gap and place the new stop there
        if sortedStops.count >= 2 {
            var maxGap = 0.0
            var gapPosition = 0.5
            
            for i in 0..<(sortedStops.count - 1) {
                let gap = sortedStops[i + 1].position - sortedStops[i].position
                if gap > maxGap {
                    maxGap = gap
                    gapPosition = (sortedStops[i].position + sortedStops[i + 1].position) / 2
                }
            }
            newPosition = gapPosition
        }
        
        // Create new stop with interpolated color
        let newStop = GradientStop(
            color: GradientStop.CodableColor(color: .gray),
            position: newPosition
        )
        
        gradientStops.append(newStop)
        saveGradientStops()
    }
}

struct TypographySettingsView: View {
    // Font settings
    @AppStorage("fontName") private var fontName: String = "System"
    @AppStorage("fontWeight") private var fontWeight: String = "thin"
    @AppStorage("fontDesign") private var fontDesign: String = "default"
    @AppStorage("fontStyle") private var fontStyle: String = "" // For custom font styles
    
    // Font size settings
    @AppStorage("dayFontSize") private var dayFontSize: Double = 100
    @AppStorage("dateFontSize") private var dateFontSize: Double = 40
    @AppStorage("timeFontSize") private var timeFontSize: Double = 90
    
    @State private var availableFontStyles: [String] = []
    
    var body: some View {
        ScrollView {
            Form {
                Section {
                    Picker("Font", selection: $fontName) {
                        Text("System Default").tag("System")
                        
                        Divider()
                        
                        ForEach(NSFontManager.shared.availableFontFamilies.sorted(), id: \.self) { font in
                            Text(font)
                                .font(.custom(font, size: 13))
                                .tag(font)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: fontName) { oldValue, newValue in
                        // Update available font styles when font changes
                        updateAvailableFontStyles()
                        // Reset font style when changing fonts
                        if !availableFontStyles.isEmpty {
                            fontStyle = availableFontStyles[0]
                        } else {
                            fontStyle = ""
                        }
                    }
                    
                    if fontName == "System" {
                        Picker("Weight", selection: $fontWeight) {
                            Text("Ultralight").tag("ultralight")
                            Text("Thin").tag("thin")
                            Text("Light").tag("light")
                            Text("Regular").tag("regular")
                            Text("Medium").tag("medium")
                            Text("Semibold").tag("semibold")
                            Text("Bold").tag("bold")
                            Text("Heavy").tag("heavy")
                            Text("Black").tag("black")
                        }
                        .pickerStyle(.menu)
                        
                        Picker("Design", selection: $fontDesign) {
                            Text("Default").tag("default")
                            Text("Serif").tag("serif")
                            Text("Rounded").tag("rounded")
                            Text("Monospaced").tag("monospaced")
                        }
                        .pickerStyle(.menu)
                    } else if !availableFontStyles.isEmpty {
                        Picker("Style", selection: $fontStyle) {
                            ForEach(availableFontStyles, id: \.self) { style in
                                Text(style).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Font preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("12:34")
                            .font(previewFont(size: 40))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                    }
                    
                    Button("Reset to Default") {
                        fontName = "System"
                        fontWeight = "thin"
                        fontDesign = "default"
                        fontStyle = ""
                    }
                } header: {
                    Text("Font Settings")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        // Day font size
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Day Font Size")
                                Spacer()
                                Text("\(Int(dayFontSize))pt")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            
                            Slider(value: $dayFontSize, in: 20...200, step: 5)
                            
                            HStack {
                                Text("20pt")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("200pt")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Date font size
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Date Font Size")
                                Spacer()
                                Text("\(Int(dateFontSize))pt")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            
                            Slider(value: $dateFontSize, in: 15...150, step: 5)
                            
                            HStack {
                                Text("15pt")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("150pt")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Time font size
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Time Font Size")
                                Spacer()
                                Text("\(Int(timeFontSize))pt")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            
                            Slider(value: $timeFontSize, in: 20...200, step: 5)
                            
                            HStack {
                                Text("20pt")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("200pt")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button("Reset Sizes to Default") {
                        dayFontSize = 100
                        dateFontSize = 40
                        timeFontSize = 90
                    }
                } header: {
                    Text("Font Sizes")
                } footer: {
                    Text("Adjust the font size for each component independently")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .padding()
            .onAppear {
                updateAvailableFontStyles()
            }
        }
    }
    
    private func updateAvailableFontStyles() {
        guard fontName != "System" else {
            availableFontStyles = []
            return
        }
        
        // Get all available members (styles) for the selected font family
        if let members = NSFontManager.shared.availableMembers(ofFontFamily: fontName) {
            availableFontStyles = members.compactMap { member in
                // member is an array: [PostScript name, display name, weight, traits]
                if let styleName = member[1] as? String {
                    return styleName
                }
                return nil
            }
        } else {
            availableFontStyles = []
        }
        
        // If the current fontStyle is not in the new list, reset to first available
        if !availableFontStyles.isEmpty && !availableFontStyles.contains(fontStyle) {
            fontStyle = availableFontStyles[0]
        }
    }
    
    func previewFont(size: CGFloat) -> Font {
        if fontName == "System" {
            return .system(size: size, weight: fontWeightValue, design: fontDesignValue)
        } else {
            // For custom fonts, we need to get the full PostScript name
            if let members = NSFontManager.shared.availableMembers(ofFontFamily: fontName),
               let member = members.first(where: { ($0[1] as? String) == fontStyle }),
               let postScriptName = member[0] as? String {
                return .custom(postScriptName, size: size)
            }
            // Fallback to just the family name
            return .custom(fontName, size: size)
        }
    }
    
    var fontWeightValue: Font.Weight {
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
    
    var fontDesignValue: Font.Design {
        switch fontDesign {
        case "serif": return .serif
        case "rounded": return .rounded
        case "monospaced": return .monospaced
        default: return .default
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
            
            Text("Version Beta 1.3")
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
