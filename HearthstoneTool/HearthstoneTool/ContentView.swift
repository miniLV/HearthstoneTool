//
//  ContentView.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/7/14.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var connectionStatus = "连接成功"
    @State private var isDisconnecting = false
    @State private var showingHelp = false
    
    
    var body: some View {
        VStack(spacing: 4) {
            Text(connectionStatus)
                .font(.caption)
                .foregroundColor(connectionStatus == "连接成功" ? .green : .orange)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                Button(action: {
                    print("🔴 用户点击了一键拔线按钮")
                    disconnectNetwork()
                }) {
                    Text("一键拔线")
                        .font(.caption)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .disabled(isDisconnecting)
                .frame(height: 25)
                
                Button(action: {
                    print("🔵 用户点击了帮助按钮")
                    showingHelp = true
                }) {
                    Text("帮助")
                        .font(.caption)
                        .frame(width: 40, height: 25)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(8)
        .frame(width: 200, height: 100)
        .alert("设置权限", isPresented: $showingHelp) {
            Button("复制命令", action: copySetupCommand)
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要先在终端中运行以下命令获取权限：\n\n1. 运行: ./one_click_setup.sh\n2. 或者手动运行: sudo -v\n3. 然后在5分钟内使用App")
        }
    }
    
    func disconnectNetwork() {
        isDisconnecting = true
        connectionStatus = "执行中..."
        
        print("🚀 开始防火墙断网操作")
        print("📍 当前用户: \(NSUserName())")
        print("📍 当前目录: \(FileManager.default.currentDirectoryPath)")
        
        Task {
            do {
                // 1. 启用防火墙断网
                print("🔥 启用防火墙断网...")
                await MainActor.run {
                    connectionStatus = "启用防火墙..."
                }
                
                let fullSuccess = await enableFirewallBlock()
                if fullSuccess {
                    print("✅ 完整断网流程执行成功")
                } else {
                    print("❌ 断网流程失败")
                    await MainActor.run {
                        connectionStatus = "断网失败"
                        isDisconnecting = false // 重置按钮状态
                    }
                    return
                }
                
                await MainActor.run {
                    connectionStatus = "连接成功"
                    isDisconnecting = false
                    print("🎉 断网操作完成！")
                }
                
            } catch {
                await MainActor.run {
                    connectionStatus = "执行失败"
                    isDisconnecting = false
                }
                print("❌ 执行过程中出错: \(error)")
            }
        }
    }
    
    // 复制设置命令到剪贴板
    func copySetupCommand() {
        print("📋 用户点击了复制命令按钮")
        let command = "sudo -v"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)
        print("✅ 命令已复制到剪贴板: \(command)")
    }
    
    
    
    
    // 启用防火墙断网 (阻止所有网络连接)
    private func enableFirewallBlock() async -> Bool {
        // 1. 检查配置文件是否存在
        let configPath = "/tmp/hs_unplug.conf"
        if !FileManager.default.fileExists(atPath: configPath) {
            print("⚠️ 配置文件不存在，尝试创建...")
            
            let createConfigScript = """
            echo "block all" > /tmp/hs_unplug.conf
            """
            
            let configTask = Process()
            configTask.executableURL = URL(fileURLWithPath: "/bin/bash")
            configTask.arguments = ["-c", createConfigScript]
            
            do {
                try configTask.run()
                configTask.waitUntilExit()
                
                if configTask.terminationStatus != 0 {
                    print("❌ 创建配置文件失败，状态码: \(configTask.terminationStatus)")
                    print("⚠️ 请先在终端运行: ./quick_setup.sh")
                    return false
                }
                
                print("✅ 配置文件创建成功")
            } catch {
                print("❌ 创建配置文件失败: \(error)")
                return false
            }
        } else {
            print("✅ 配置文件已存在")
        }
        
        // 2. 使用 osascript 一次性执行完整的断网和恢复流程
        print("🔍 使用 osascript 执行完整的断网流程...")
        let fullScript = """
        do shell script "pfctl -f /tmp/hs_unplug.conf 2>/dev/null && pfctl -e 2>/dev/null && echo 'disconnect_success' && sleep 8 && pfctl -d 2>/dev/null && pfctl -f /etc/pf.conf 2>/dev/null && echo 'restore_success'" with administrator privileges
        """
        
        let fullTask = Process()
        fullTask.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        fullTask.arguments = ["-e", fullScript]
        
        // 捕获输出
        let fullPipe = Pipe()
        fullTask.standardOutput = fullPipe
        fullTask.standardError = fullPipe
        
        do {
            try fullTask.run()
            fullTask.waitUntilExit()
            
            // 读取输出
            let fullData = fullPipe.fileHandleForReading.readDataToEndOfFile()
            let fullOutput = String(data: fullData, encoding: .utf8) ?? ""
            print("📝 完整流程输出: \(fullOutput)")
            
            if fullTask.terminationStatus == 0 && fullOutput.contains("disconnect_success") {
                print("✅ 防火墙断网规则已启用")
                
                // 更新状态为断网成功
                await MainActor.run {
                    connectionStatus = "断网成功"
                }
                
                // 等待脚本完成（8秒 + 恢复时间）
                print("⏱️ 等待断网流程完成...")
                
                if fullOutput.contains("restore_success") {
                    print("✅ 网络恢复成功")
                    return true
                } else {
                    print("⚠️ 网络恢复状态未确认")
                    return true // 断网部分成功了
                }
            } else {
                print("❌ 断网流程失败，状态码: \(fullTask.terminationStatus)")
                print("⚠️ 用户可能取消了权限授权")
                return false
            }
        } catch {
            print("❌ 执行断网流程失败: \(error)")
            return false
        }
        
    }
    
    
    
    // ...existing code...
}

#Preview {
    ContentView()
}
