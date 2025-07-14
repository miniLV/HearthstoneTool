//
//  HearthstoneToolApp.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/7/14.
//

import SwiftUI
import AppKit

@main
struct HearthstoneToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.topTrailing)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        checkForRunningInstances()
        setupWindowLevel()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func checkForRunningInstances() {
        let runningApps = NSWorkspace.shared.runningApplications
        let currentApp = NSRunningApplication.current
        
        let sameApps = runningApps.filter { app in
            app.bundleIdentifier == currentApp.bundleIdentifier && app != currentApp
        }
        
        if !sameApps.isEmpty {
            let alert = NSAlert()
            alert.messageText = "应用已在运行"
            alert.informativeText = "ClashX 控制器已经在运行中，将退出此实例。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
    }
    
    private func setupWindowLevel() {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
        }
    }
}
