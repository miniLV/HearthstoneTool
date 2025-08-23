//
//  NetworkManager.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/8/23.
//

import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    @Published var isConnected = true
    @Published var hearthstoneRunning = false
    @Published var clashConfigured = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var hearthstoneTimer: Timer?
    private var disconnectTimer: Timer?
    private var reconnectTimer: Timer?
    
    private let hearthstoneProcessNames = [
        "Hearthstone",
        "炉石传说", 
        "HearthstoneBeta",
        "/Applications/Hearthstone/Hearthstone.app/Contents/MacOS/Hearthstone"
    ]
    
    // Clash configuration
    private var clashExternalController: String = ""
    private var clashSecret: String = ""
    private let clashAPIURLSession = URLSession.shared
    
    init() {
        setupNetworkMonitoring()
        loadClashConfig()
    }
    
    deinit {
        monitor.cancel()
        hearthstoneTimer?.invalidate()
        disconnectTimer?.invalidate()
        reconnectTimer?.invalidate()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    func startMonitoring() {
        hearthstoneTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkHearthstoneStatus()
        }
    }
    
    func stopMonitoring() {
        hearthstoneTimer?.invalidate()
        hearthstoneTimer = nil
        disconnectTimer?.invalidate()
        disconnectTimer = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    func checkHearthstoneStatus() {
        Task {
            let running = await isHearthstoneRunning()
            DispatchQueue.main.async {
                self.hearthstoneRunning = running
            }
        }
    }
    
    private func isHearthstoneRunning() async -> Bool {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/pgrep"
            task.arguments = ["-f", "Hearthstone"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                // pgrep returns process IDs if found, empty if not found
                let isRunning = process.terminationStatus == 0 && !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                
                print("Debug: pgrep output: '\(output.trimmingCharacters(in: .whitespacesAndNewlines))'")
                print("Debug: termination status: \(process.terminationStatus)")
                print("Debug: isRunning: \(isRunning)")
                
                continuation.resume(returning: isRunning)
            }
            
            do {
                try task.run()
            } catch {
                print("Debug: pgrep failed with error: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
    
    func toggleConnection() {
        if clashConfigured {
            if isConnected {
                skipHearthstoneConnection()
            }
        } else {
            if isConnected {
                disconnectNetwork()
            } else {
                reconnectNetwork()
            }
        }
    }
    
    private func disconnectNetwork() {
        executeNetworkCommand(disconnect: true) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                
                self?.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    self?.reconnectNetwork()
                }
            }
        }
    }
    
    private func reconnectNetwork() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        executeNetworkCommand(disconnect: false) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.isConnected = true
                }
            }
        }
    }
    
    private func executeNetworkCommand(disconnect: Bool, completion: @escaping (Bool) -> Void) {
        let script = disconnect ? disconnectScript() : reconnectScript()
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        task.terminationHandler = { process in
            completion(process.terminationStatus == 0)
        }
        
        do {
            try task.run()
        } catch {
            print("执行网络命令失败: \(error)")
            completion(false)
        }
    }
    
    private func disconnectScript() -> String {
        return """
        do shell script "networksetup -setairportpower en0 off" with administrator privileges
        """
    }
    
    private func reconnectScript() -> String {
        return """
        do shell script "networksetup -setairportpower en0 on" with administrator privileges
        """
    }
    
    func disconnectForDuration(_ duration: TimeInterval) {
        if clashConfigured {
            skipHearthstoneConnection()
        } else {
            disconnectNetwork()
            
            reconnectTimer?.invalidate()
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.reconnectNetwork()
            }
        }
    }
    
    // MARK: - Clash Integration
    
    func setManualClashConfig(controller: String, secret: String) {
        print("手动设置 Clash 配置: controller=\(controller), secret=\(secret)")
        clashExternalController = controller
        clashSecret = secret
        
        // Save to UserDefaults
        UserDefaults.standard.set(controller, forKey: "clashExternalController")
        UserDefaults.standard.set(secret, forKey: "clashSecret")
        
        // Force update the UI state
        DispatchQueue.main.async {
            self.clashConfigured = true
        }
        
        testClashConnection()
    }
    
    private func loadClashConfig() {
        print("开始加载 Clash 配置...")
        
        // Try to load from UserDefaults first
        if let controller = UserDefaults.standard.string(forKey: "clashExternalController"),
           let secret = UserDefaults.standard.string(forKey: "clashSecret") {
            print("从 UserDefaults 加载配置: controller=\(controller), secret=\(secret)")
            clashExternalController = controller
            clashSecret = secret
            DispatchQueue.main.async {
                self.clashConfigured = true
            }
            testClashConnection()
            return
        }
        
        // Try multiple config files
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let configPaths = [
            homeDirectory.appendingPathComponent(".config/clash/config.yaml"),
            homeDirectory.appendingPathComponent(".config/clash/泡泡Dog.yaml")
        ]
        
        for configPath in configPaths {
            print("尝试从配置文件加载: \(configPath.path)")
            
            do {
                let configContent = try String(contentsOf: configPath)
                print("成功读取配置文件，内容长度: \(configContent.count)")
                parseClashConfig(configContent)
                
                // If we found a valid configuration, test it
                if !clashExternalController.isEmpty {
                    return
                }
            } catch {
                print("无法加载配置文件 \(configPath.lastPathComponent): \(error)")
            }
        }
        
        print("所有配置文件加载失败")
        DispatchQueue.main.async {
            self.clashConfigured = false
        }
    }
    
    private func parseClashConfig(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        print("解析配置文件，共 \(lines.count) 行")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("external-controller:") {
                let controller = String(trimmedLine.dropFirst("external-controller:".count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "'", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                
                if !controller.hasPrefix("http") {
                    clashExternalController = "http://\(controller)"
                } else {
                    clashExternalController = controller
                }
                print("找到 external-controller: \(clashExternalController)")
            } else if trimmedLine.hasPrefix("secret:") {
                clashSecret = String(trimmedLine.dropFirst("secret:".count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "'", with: "")
                print("找到 secret: \(clashSecret)")
            }
        }
        
        print("解析结果 - controller: '\(clashExternalController)', secret: '\(clashSecret)'")
        
        if !clashExternalController.isEmpty {
            DispatchQueue.main.async {
                self.clashConfigured = true
            }
            testClashConnection()
        } else {
            print("external-controller 配置为空，Clash 未配置")
            DispatchQueue.main.async {
                self.clashConfigured = false
            }
        }
    }
    
    private func testClashConnection() {
        guard !clashExternalController.isEmpty else { 
            print("Clash external controller 配置为空")
            return 
        }
        
        guard let url = URL(string: "\(clashExternalController)/version") else {
            print("无法创建 Clash API URL: \(clashExternalController)/version")
            DispatchQueue.main.async {
                self.clashConfigured = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        if !clashSecret.isEmpty {
            request.setValue("Bearer \(clashSecret)", forHTTPHeaderField: "Authorization")
        }
        
        print("测试连接到: \(url.absoluteString)")
        
        clashAPIURLSession.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Clash 连接测试失败: \(error)")
                print("ClashX Pro External Controller 未启用。")
                print("请按以下步骤操作:")
                print("1. 点击菜单栏 ClashX Pro 图标")
                print("2. 寻找并勾选 '允许局域网连接' 或 'Allow LAN'")
                print("3. 如果没有该选项，尝试右键菜单栏图标")
                print("4. 或者完全重启 ClashX Pro")
                DispatchQueue.main.async {
                    self?.clashConfigured = false
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP 状态码: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("响应内容: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("Clash 连接测试成功")
                    DispatchQueue.main.async {
                        self?.clashConfigured = true
                    }
                } else {
                    print("Clash API 响应异常，状态码: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        self?.clashConfigured = false
                    }
                }
            }
        }.resume()
    }
    
    private func skipHearthstoneConnection() {
        print("开始断开炉石连接...")
        
        guard clashConfigured, !clashExternalController.isEmpty else { 
            print("Clash 未配置或 external controller 为空")
            return 
        }
        
        print("Clash 已配置，controller: \(clashExternalController)")
        
        // First, get all connections
        guard let connectionsURL = URL(string: "\(clashExternalController)/connections") else {
            print("无法创建 Clash connections URL: \(clashExternalController)/connections")
            return
        }
        
        print("准备获取连接列表: \(connectionsURL.absoluteString)")
        
        var request = URLRequest(url: connectionsURL)
        
        if !clashSecret.isEmpty {
            request.setValue("Bearer \(clashSecret)", forHTTPHeaderField: "Authorization")
        }
        
        clashAPIURLSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("获取连接列表失败: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("连接列表请求状态码: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("获取连接列表失败: 无数据返回")
                return
            }
            
            print("连接列表数据长度: \(data.count) 字节")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let connections = json["connections"] as? [[String: Any]] {
                    
                    print("获取到 \(connections.count) 个连接")
                    self.killHearthstoneConnections(connections)
                } else {
                    print("连接数据格式不正确")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("原始数据: \(jsonString)")
                    }
                }
            } catch {
                print("解析连接数据失败: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("原始数据: \(jsonString)")
                }
            }
        }.resume()
    }
    
    private func killHearthstoneConnections(_ connections: [[String: Any]]) {
        print("开始分析 \(connections.count) 个连接...")
        
        var hearthstoneConnectionsFound = 0
        
        for (index, connection) in connections.enumerated() {
            print("连接 \(index): \(connection)")
            
            guard let metadata = connection["metadata"] as? [String: Any],
                  let id = connection["id"] as? String else { 
                print("连接 \(index) 缺少必要字段")
                continue 
            }
            
            let processPath = metadata["processPath"] as? String ?? ""
            let host = metadata["host"] as? String ?? ""
            
            print("连接 \(index) - processPath: '\(processPath)', host: '\(host)', id: \(id)")
            
            // Check if this connection belongs to Hearthstone
            // Method 1: Check processPath for Hearthstone
            let isHearthstoneByPath = !processPath.isEmpty && hearthstoneProcessNames.contains(where: { processPath.contains($0) })
            
            // Method 2: Check host for battlenet domains (Hearthstone uses battlenet)
            let isHearthstoneByHost = host.contains("battlenet") || host.contains("blizzard")
            
            // Method 3: Check for Hearthstone-related hosts
            let hearthstoneHosts = ["telemetry-in.battlenet.com.cn", "us.battle.net", "eu.battle.net", "kr.battle.net", "tw.battle.net"]
            let isHearthstoneByKnownHost = hearthstoneHosts.contains(where: { host.contains($0) })
            
            if isHearthstoneByPath || isHearthstoneByHost || isHearthstoneByKnownHost {
                var reason = ""
                if isHearthstoneByPath { reason = "进程路径匹配" }
                else if isHearthstoneByHost { reason = "域名匹配" }
                else if isHearthstoneByKnownHost { reason = "已知炉石域名匹配" }
                
                print("找到炉石连接 (\(reason)): processPath='\(processPath)', host='\(host)' (ID: \(id))")
                hearthstoneConnectionsFound += 1
                killConnection(id: id)
            } else {
                print("非炉石连接: processPath='\(processPath)', host='\(host)'")
            }
        }
        
        print("总共找到 \(hearthstoneConnectionsFound) 个炉石连接")
        if hearthstoneConnectionsFound == 0 {
            print("未找到任何炉石连接，可能炉石未建立网络连接或进程名不匹配")
        }
    }
    
    private func killConnection(id: String) {
        guard let killURL = URL(string: "\(clashExternalController)/connections/\(id)") else {
            print("无法创建 kill connection URL: \(clashExternalController)/connections/\(id)")
            return
        }
        
        var request = URLRequest(url: killURL)
        request.httpMethod = "DELETE"
        
        if !clashSecret.isEmpty {
            request.setValue("Bearer \(clashSecret)", forHTTPHeaderField: "Authorization")
        }
        
        clashAPIURLSession.dataTask(with: request) { data, response, error in
            if let error = error {
                print("终止连接失败: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 204 {
                print("成功终止炉石连接: \(id)")
            }
        }.resume()
    }
}
