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
    
    // ClashX Pro API 配置
    private let clashXAPIURL = "http://127.0.0.1:53378"
    private let clashXAPISecret = "daa-67P-sHH-Dvm"
    
    var body: some View {
        VStack(spacing: 8) {
            Text(connectionStatus)
                .font(.caption)
                .foregroundColor(connectionStatus == "连接成功" ? .green : .orange)
                .lineLimit(1)
            
            Button(action: {
                disconnectClashX()
            }) {
                Text("一键拔线")
                    .font(.caption)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .disabled(isDisconnecting)
            .frame(height: 30)
        }
        .padding(8)
        .frame(width: 200, height: 100)
    }
    
    func disconnectClashX() {
        isDisconnecting = true
        connectionStatus = "执行中..."
        
        print("🚀 开始 ClashX Pro 断网操作")
        
        Task {
            do {
                // 1. 检查 ClashX Pro API 连接
                print("📡 检查 ClashX Pro API 连接...")
                let isConnected = await checkClashXConnection()
                
                if !isConnected {
                    await MainActor.run {
                        connectionStatus = "API连接失败"
                        isDisconnecting = false
                    }
                    print("❌ ClashX Pro API 连接失败")
                    return
                }
                
                print("✅ ClashX Pro API 连接成功")
                
                
                // 3. 关闭 WiFi
                print("📶 关闭 WiFi...")
                await MainActor.run {
                    connectionStatus = "关闭 WiFi..."
                }
                
                let wifiOffSuccess = await disableWiFi()
                if wifiOffSuccess {
                    print("✅ 成功关闭 WiFi")
                    await MainActor.run {
                        connectionStatus = "断网成功"
                    }
                } else {
                    print("❌ 关闭 WiFi 失败")
                    await MainActor.run {
                        connectionStatus = "断网失败"
                    }
                    return
                }
                
                // 4. 等待 8 秒
                print("⏱️ 断网倒计时 10 秒...")
                try await Task.sleep(nanoseconds: 10_000_000_000) // 8 seconds
                
                // 5. 重新开启 WiFi
                print("📶 重新开启 WiFi...")
                await MainActor.run {
                    connectionStatus = "恢复网络..."
                }
                
                let wifiOnSuccess = await enableWiFi()
                if wifiOnSuccess {
                    print("✅ 成功开启 WiFi")
                } else {
                    print("❌ 开启 WiFi 失败")
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
    
    // 检查 ClashX API 连接
    private func checkClashXConnection() async -> Bool {
        guard let url = URL(string: "\(clashXAPIURL)/version") else { return false }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(clashXAPISecret)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 3
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("API 连接检查失败: \(error)")
        }
        
        return false
    }
    
    // 设置 ClashX 模式
    private func setClashXMode(_ mode: String) async -> Bool {
        guard let url = URL(string: "\(clashXAPIURL)/configs") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(clashXAPISecret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5
        
        let body = ["mode": mode]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 204 || httpResponse.statusCode == 200
            }
        } catch {
            print("设置模式失败: \(error)")
        }
        
        return false
    }
    
    // 启用断网模式 - 通过断开所有连接实现真正的断网
    private func enableDisconnectMode() async -> Bool {
        print("🔌 启用全局断网模式...")
        
        // 获取所有活动连接
        let allConnections = await getConnections()
        if allConnections.isEmpty {
            print("⚠️ 没有找到活动连接")
            return false
        }
        
        print("📋 找到 \(allConnections.count) 个活动连接，将全部断开")
        
        var successCount = 0
        for connectionId in allConnections {
            let success = await deleteConnection(connectionId)
            if success {
                successCount += 1
                print("   ✅ 断开连接: \(connectionId)")
            } else {
                print("   ❌ 断开连接失败: \(connectionId)")
            }
        }
        
        let isSuccess = successCount > 0
        if isSuccess {
            print("✅ 成功断开 \(successCount)/\(allConnections.count) 个连接")
        } else {
            print("❌ 所有连接断开失败")
        }
        
        return isSuccess
    }
    
    // 获取当前 ClashX 模式
    private func getCurrentMode() async -> String {
        guard let url = URL(string: "\(clashXAPIURL)/configs") else { return "rule" }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(clashXAPISecret)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 3
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let mode = json["mode"] as? String {
                    return mode
                }
            }
        } catch {
            print("获取当前模式失败: \(error)")
        }
        
        return "rule" // 默认返回 rule 模式
    }
    
    // 关闭 WiFi
    private func disableWiFi() async -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setairportpower", "en0", "off"]
        
        do {
            try task.run()
            task.waitUntilExit()
            let success = task.terminationStatus == 0
            if success {
                print("✅ WiFi 已关闭")
            } else {
                print("❌ 关闭 WiFi 失败，状态码: \(task.terminationStatus)")
            }
            return success
        } catch {
            print("❌ 关闭 WiFi 失败: \(error)")
            return false
        }
    }
    
    // 开启 WiFi
    private func enableWiFi() async -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setairportpower", "en0", "on"]
        
        do {
            try task.run()
            task.waitUntilExit()
            let success = task.terminationStatus == 0
            if success {
                print("✅ WiFi 已开启")
            } else {
                print("❌ 开启 WiFi 失败，状态码: \(task.terminationStatus)")
            }
            return success
        } catch {
            print("❌ 开启 WiFi 失败: \(error)")
            return false
        }
    }
    
    // 查找炉石传说的特定连接
    private func findHearthstoneConnection() async -> String? {
        guard let url = URL(string: "\(clashXAPIURL)/connections") else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(clashXAPISecret)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 3
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let connections = json["connections"] as? [[String: Any]] {
                    
                    print("📋 检查 \(connections.count) 个连接...")
                    
                    // 查找炉石传说的连接 - 参考 hearthstone_skipper 的实现
                    for connection in connections {
                        if let metadata = connection["metadata"] as? [String: Any],
                           let connectionId = connection["id"] as? String {
                            
                            let processPath = metadata["processPath"] as? String ?? ""
                            let host = metadata["host"] as? String ?? ""
                            let process = metadata["process"] as? String ?? ""
                            let destinationIP = metadata["destinationIP"] as? String ?? ""
                            
                            print("🔍 检查连接: \(connectionId)")
                            print("   processPath: \(processPath)")
                            print("   host: \(host)")
                            print("   process: \(process)")
                            print("   destinationIP: \(destinationIP)")
                            
                            // 方法1: 精确路径匹配
                            if processPath.contains("Hearthstone.app") {
                                print("🎯 找到目标连接 (应用路径匹配)!")
                                return connectionId
                            }
                            
                            // 方法2: 进程名匹配
                            if process.contains("Hearthstone") {
                                print("🎯 找到目标连接 (进程名匹配)!")
                                return connectionId
                            }
                            
                            // 方法3: 暴雪相关域名匹配
                            if host.contains("blizzard") || host.contains("battle.net") || host.contains("battlenet") {
                                print("🎯 找到目标连接 (域名匹配)!")
                                return connectionId
                            }
                            
                            // 方法4: 暴雪服务器IP范围匹配 (可能需要根据实际情况调整)
                            if destinationIP.hasPrefix("24.105.") || destinationIP.hasPrefix("137.221.") {
                                print("🎯 找到目标连接 (IP匹配)!")
                                return connectionId
                            }
                        }
                    }
                    
                    print("⚠️ 未找到炉石传说特定连接")
                    return nil
                }
            }
        } catch {
            print("查找连接失败: \(error)")
        }
        
        return nil
    }
    
    // 断开所有连接并返回第一个连接ID（用于表示操作成功）
    private func killAllConnectionsAndReturnFirst() async -> String? {
        let connectionIds = await getConnections()
        print("📋 找到 \(connectionIds.count) 个活动连接，将全部断开")
        
        var firstConnectionId: String?
        for connectionId in connectionIds {
            if firstConnectionId == nil {
                firstConnectionId = connectionId
            }
            let success = await deleteConnection(connectionId)
            if success {
                print("   断开连接: \(connectionId)")
            }
        }
        
        return firstConnectionId
    }
    
    // 获取所有连接ID
    private func getConnections() async -> [String] {
        guard let url = URL(string: "\(clashXAPIURL)/connections") else { return [] }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(clashXAPISecret)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 3
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let connections = json["connections"] as? [[String: Any]] {
                    return connections.compactMap { $0["id"] as? String }
                }
            }
        } catch {
            print("获取连接列表失败: \(error)")
        }
        
        return []
    }
    
    // 删除指定连接
    private func deleteConnection(_ connectionId: String) async -> Bool {
        guard let url = URL(string: "\(clashXAPIURL)/connections/\(connectionId)") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(clashXAPISecret)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 3
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 204 || httpResponse.statusCode == 200
            }
        } catch {
            print("删除连接失败: \(error)")
        }
        
        return false
    }
    
    // ...existing code...
}

#Preview {
    ContentView()
}
