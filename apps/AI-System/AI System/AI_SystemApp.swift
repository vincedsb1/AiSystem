//
//  AI_SystemApp.swift
//  AI System
//

import SwiftUI

@main
struct AI_SystemApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Native window sizing; macOS restores position and size itself.
        .defaultSize(width: 1080, height: 720)
        .commands { AppCommands() }

        // Standard Settings scene, reachable with the system ⌘, shortcut.
        Settings {
            SettingsView()
        }
    }
}
