//
//  HearthstoneToolApp.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 20x25/8/23.
//

import SwiftUI
import AppKit

@main
struct HearthstoneToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        Settings {
            EmptyView() // 这个不会显示，我们用自定义面板
        }
    }
}

class HearthstonePanel: NSPanel {
    static let kHearthstonePanelTitle = "HearthstoneToolPanel"
    
    init() {
        super.init(contentRect: NSMakeRect(0, 0, 400, 150),
                  styleMask: [.borderless],
                  backing: .buffered,
                  defer: false)
        
        self.level = NSWindow.Level(rawValue: 1000)
        self.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95)
        self.isOpaque = false
        self.hasShadow = true
        
        // 设置圆角
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 12
        self.contentView?.layer?.masksToBounds = true
        
        // Allow the panel to be overlaid in a fullscreen space
        var collectionBehavior = self.collectionBehavior
        collectionBehavior.insert([.fullScreenAuxiliary, .canJoinAllSpaces])
        self.collectionBehavior = collectionBehavior
        
        self.isMovableByWindowBackground = true
        
        // 设置 SwiftUI 内容
        let contentView = NSHostingView(rootView: ContentView())
        contentView.frame = self.contentView!.bounds
        contentView.autoresizingMask = [.width, .height]
        self.contentView = contentView
        
        // 居中显示
        self.center()
        
        print("Panel 配置完成: level=\(self.level.rawValue), behavior=\(self.collectionBehavior)")
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: HearthstonePanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建并显示面板
        panel = HearthstonePanel()
        panel?.makeKeyAndOrderFront(nil)
        
        // 确保应用不会因为没有窗口而退出
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let panel = panel {
            panel.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
