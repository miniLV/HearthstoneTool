//
//  ContentView.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/7/14.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var isDisconnecting = false
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var startLocation = CGPoint.zero
    
    var body: some View {
        Button(action: {
            if !isDragging {
                print("🔴 用户点击了一键拔线按钮")
                disconnectNetwork()
            }
        }) {
            Text(isDisconnecting ? "正在拔线" : "一键拔线")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(width: 100, height: 30)
                .background(Color.red)
                .cornerRadius(4)
        }
        .disabled(isDisconnecting)
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        startLocation = value.startLocation
                        isDragging = true
                    }
                    
                    let distance = sqrt(
                        pow(value.location.x - startLocation.x, 2) + 
                        pow(value.location.y - startLocation.y, 2)
                    )
                    
                    if distance > 5 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    let distance = sqrt(
                        pow(value.location.x - startLocation.x, 2) + 
                        pow(value.location.y - startLocation.y, 2)
                    )
                    
                    if distance <= 5 {
                        isDragging = false
                    } else {
                        isDragging = false
                    }
                }
        )
        .frame(width: 100, height: 30)
    }
    
    func disconnectNetwork() {
        isDisconnecting = true
        
        print("🚀 开始拔线操作")
        
        Task {
            do {
                let success = await executeLittleSnitchCommand()
                if success {
                    print("✅ 拔线操作已执行！")
                } else {
                    print("❌ 拔线操作失败")
                }
                
                // 等待3秒后恢复按钮状态
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                await MainActor.run {
                    isDisconnecting = false
                }
                
            } catch {
                await MainActor.run {
                    isDisconnecting = false
                }
                print("❌ 执行过程中出错: \(error)")
            }
        }
    }
    
    private func executeLittleSnitchCommand() async -> Bool {
        print("🔍 使用 Little Snitch 执行断网流程...")
        
        // 从环境变量获取密码
        guard let password = ProcessInfo.processInfo.environment["PASSWD"] else {
            print("❌ 错误：未设置环境变量 PASSWD")
            print("⚠️ 请先在终端运行: export PASSWD=你的密码")
            return false
        }
        
        let command = """
        export PATH="/Applications/Little Snitch.app/Contents/Components:$PATH" && echo '\(password)' | sudo -S littlesnitch rulegroup -e Hearthstone && sleep 0.5 && echo '\(password)' | sudo -S littlesnitch rulegroup -d Hearthstone
        """
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", command]
        
        // 捕获输出
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // 读取输出
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("📝 Little Snitch 输出: \(output)")
            
            if task.terminationStatus == 0 {
                return true
            } else {
                print("❌ 拔线操作失败: \(task.terminationStatus)")
                
                // 检查特定的错误消息
                if output.contains("command line tool is not authorized") {
                    print("⚠️ Little Snitch 命令行工具未授权")
                    print("📝 请打开 Little Snitch.app")
                    print("📝 进入 Settings > Security")
                    print("📝 勾选 'Allow access via Terminal' 选项")
                } else if output.contains("Password:Error") {
                    print("⚠️ 可能是密码错误或 Hearthstone 规则组不存在")
                    print("📝 请检查：1. 密码是否正确 2. 是否创建了 Hearthstone 规则组")
                }
                return false
            }
        } catch {
            print("❌ 执行拔线操作失败: \(error)")
            return false
        }
    }
    
    
    
    // ...existing code...
}

#Preview {
    ContentView()
}
