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
    var body: some View {
        Form {
            Section {
                Text("Appearance options coming soon...")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Display")
            }
        }
        .formStyle(.grouped)
        .padding()
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
            
            Text("Version Beta 1.0")
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
