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
    
    // Gradient color positions (0.0 to 1.0)
    @AppStorage("gradientColor1Position") private var color1Position: Double = 0.0
    @AppStorage("gradientColor2Position") private var color2Position: Double = 1.0
    
    // Gradient color 2 components
    @AppStorage("gradientColor2Red") private var red2: Double = 0.5
    @AppStorage("gradientColor2Green") private var green2: Double = 0.5
    @AppStorage("gradientColor2Blue") private var blue2: Double = 1.0
    @AppStorage("gradientColor2Alpha") private var alpha2: Double = 1.0
    
    // Font settings
    @AppStorage("fontName") private var fontName: String = "System"
    @AppStorage("fontWeight") private var fontWeight: String = "thin"
    @AppStorage("fontDesign") private var fontDesign: String = "default"
    @AppStorage("fontStyle") private var fontStyle: String = "" // For custom font styles
    
    @State private var clockColor: Color = .white
    @State private var gradientColor2: Color = Color(red: 0.5, green: 0.5, blue: 1.0)
    @State private var customAngleInput: Double = 0.0
    @State private var availableFontStyles: [String] = []
    
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
                    VStack(alignment: .leading, spacing: 4) {
                        ColorPicker("Start Color", selection: $clockColor)
                            .onChange(of: clockColor) { oldValue, newValue in
                                saveColor(newValue, isFirstColor: true)
                            }
                        
                        HStack {
                            Text("Position:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $color1Position, in: 0...1, step: 0.01)
                            Text("\(Int(color1Position * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.leading, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ColorPicker("End Color", selection: $gradientColor2)
                            .onChange(of: gradientColor2) { oldValue, newValue in
                                saveColor(newValue, isFirstColor: false)
                            }
                        
                        HStack {
                            Text("Position:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $color2Position, in: 0...1, step: 0.01)
                            Text("\(Int(color2Position * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.leading, 20)
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
                                
                                // Gradient background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        selectedType == .radial ?
                                            AnyShapeStyle(RadialGradient(
                                                stops: [
                                                    .init(color: clockColor, location: color1Position),
                                                    .init(color: gradientColor2, location: color2Position)
                                                ],
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 100
                                            )) :
                                            AnyShapeStyle(LinearGradient(
                                                stops: [
                                                    .init(color: clockColor, location: color1Position),
                                                    .init(color: gradientColor2, location: color2Position)
                                                ],
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
                                    Circle()
                                        .fill(clockColor)
                                        .frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .position(
                                            x: startX + (endX - startX) * color1Position,
                                            y: startY + (endY - startY) * color1Position
                                        )
                                    
                                    Circle()
                                        .fill(gradientColor2)
                                        .frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .position(
                                            x: startX + (endX - startX) * color2Position,
                                            y: startY + (endY - startY) * color2Position
                                        )
                                }
                            }
                        }
                        .frame(height: 80)
                    }
                } else {
                    ColorPicker("Clock Color", selection: $clockColor)
                        .onChange(of: clockColor) { oldValue, newValue in
                            saveColor(newValue, isFirstColor: true)
                        }
                }
                
                Button("Reset to Default") {
                    clockColor = .white
                    gradientColor2 = Color(red: 0.5, green: 0.5, blue: 1.0)
                    useGradient = false
                    gradientDirection = "horizontal"
                    gradientType = "linear"
                    gradientAngle = 0.0
                    color1Position = 0.0
                    color2Position = 1.0
                    fontName = "System"
                    fontWeight = "thin"
                    fontDesign = "default"
                    saveColor(.white, isFirstColor: true)
                    saveColor(Color(red: 0.5, green: 0.5, blue: 1.0), isFirstColor: false)
                }
            } header: {
                Text("Display")
            }
            
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
            } header: {
                Text("Typography")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadColors()
            updateAvailableFontStyles()
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
    
    private func saveColor(_ color: Color, isFirstColor: Bool) {
        // Convert SwiftUI Color to NSColor and extract components
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            if isFirstColor {
                red = Double(rgbColor.redComponent)
                green = Double(rgbColor.greenComponent)
                blue = Double(rgbColor.blueComponent)
                alpha = Double(rgbColor.alphaComponent)
            } else {
                red2 = Double(rgbColor.redComponent)
                green2 = Double(rgbColor.greenComponent)
                blue2 = Double(rgbColor.blueComponent)
                alpha2 = Double(rgbColor.alphaComponent)
            }
        }
    }
    
    private func loadColors() {
        // Load colors from stored components
        clockColor = Color(red: red, green: green, blue: blue, opacity: alpha)
        gradientColor2 = Color(red: red2, green: green2, blue: blue2, opacity: alpha2)
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
