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
    @Published var lastActionStatus = ""
    @Published var usePreciseBlocking = false // 用户可选择是否使用精确阻断
    @Published var hasAdminPassword = false
    @Published var isDisconnecting = false // 正在执行断开操作
    
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
        checkAdminPassword()
    }
    
    private func checkAdminPassword() {
        hasAdminPassword = UserDefaults.standard.string(forKey: "adminPassword") != nil
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
            if isConnected && !isDisconnecting {
                // 直接执行全网络阻断脚本
                DispatchQueue.main.async {
                    self.isDisconnecting = true
                    self.lastActionStatus = "正在执行网络阻断..."
                }
                
                Task {
                    await blockAndUnblockServer("")
                    DispatchQueue.main.async {
                        self.isDisconnecting = false
                    }
                }
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
    
    func setAdminPassword(_ password: String) {
        UserDefaults.standard.set(password, forKey: "adminPassword")
        checkAdminPassword()
        lastActionStatus = "管理员密码已保存"
    }
    
    func clearAdminPassword() {
        UserDefaults.standard.removeObject(forKey: "adminPassword")
        checkAdminPassword()
        lastActionStatus = "管理员密码已清除"
    }
    
    func getAdminPassword() -> String? {
        return UserDefaults.standard.string(forKey: "adminPassword")
    }
    
    func showUserMessage(_ message: String) {
        DispatchQueue.main.async {
            self.lastActionStatus = message
        }
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
            
            // Since processPath is empty in our environment, we need alternative detection
            
            // Method 1: Look for Hearthstone game connections (not telemetry)
            // Game connections typically use gateway.battlenet.com.cn for game data
            let isGameConnection = host == "gateway.battlenet.com.cn" || 
                                 (host.contains("battlenet") && !host.contains("telemetry"))
            
            // Method 2: Check if processPath contains Hearthstone (when available)
            let isHearthstoneByPath = !processPath.isEmpty && 
                                    (processPath.contains("Hearthstone") || processPath.contains("hearthstone"))
            
            // Method 3: For debugging - let user choose to kill specific battlenet connections
            let isBattlenetConnection = host.contains("battlenet") || host.contains("blizzard")
            
            if isHearthstoneByPath {
                print("找到炉石进程连接: processPath='\(processPath)', host='\(host)' (ID: \(id))")
                hearthstoneConnectionsFound += 1
                killConnection(id: id)
            } else if isGameConnection {
                print("找到可能的炉石游戏连接: host='\(host)' (ID: \(id))")
                hearthstoneConnectionsFound += 1
                killConnection(id: id)
            } else if isBattlenetConnection {
                print("发现炉石相关连接但跳过: processPath='\(processPath)', host='\(host)'")
                print("  -> 如果这是游戏连接，请报告此信息以改进检测")
            } else {
                print("非炉石连接: processPath='\(processPath)', host='\(host)'")
            }
        }
        
        print("总共找到 \(hearthstoneConnectionsFound) 个炉石游戏连接")
        
        DispatchQueue.main.async {
            if hearthstoneConnectionsFound > 0 {
                self.lastActionStatus = "通过Clash成功断开 \(hearthstoneConnectionsFound) 个炉石游戏连接"
            } else {
                self.lastActionStatus = "Clash未找到游戏连接，尝试直连方法..."
            }
        }
        
        if hearthstoneConnectionsFound == 0 {
            print("未找到炉石游戏连接，尝试直连方法")
            print("注意：遥测连接 (telemetry-in.battlenet.com.cn) 不是游戏连接")
            // 使用直连方法作为备选
            killHearthstoneDirectConnections()
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
    
    // MARK: - Direct Process Connection Killing
    
    private func killHearthstoneDirectConnections() {
        print("尝试直接终止炉石进程网络连接...")
        
        // First, get Hearthstone PID
        Task {
            if let pid = await getHearthstonePID() {
                print("找到炉石进程 PID: \(pid)")
                await killProcessConnections(pid: pid)
            } else {
                print("未找到炉石进程")
                DispatchQueue.main.async {
                    self.lastActionStatus = "未找到炉石进程"
                }
            }
        }
    }
    
    private func getHearthstonePID() async -> Int? {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/pgrep"
            task.arguments = ["-f", "Hearthstone"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0, 
                   let pidString = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").first,
                   let pid = Int(pidString) {
                    continuation.resume(returning: pid)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            do {
                try task.run()
            } catch {
                print("获取炉石进程 PID 失败: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func killProcessConnections(pid: Int) async {
        await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/sbin/lsof"
            task.arguments = ["-p", String(pid), "-i"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                print("炉石网络连接:")
                print(output)
                
                // Parse connections and extract game server IPs
                let lines = output.components(separatedBy: .newlines)
                var gameConnections = 0
                var gameServerIPs: [String] = []
                
                for line in lines {
                    print("检查连接行: \(line)")
                    
                    // Look for ESTABLISHED connections to game servers
                    if line.contains("ESTABLISHED") && (line.contains("bnetgame") || line.contains(":1119") || line.contains("118.31.18.157") || line.contains("114.55.81.211")) {
                        print("发现游戏连接: \(line)")
                        gameConnections += 1
                        
                        // Extract IP address from line like: "TCP 192.168.0.110:61918->118.31.18.157:bnetgame"
                        if let range = line.range(of: "->") {
                            let afterArrow = String(line[range.upperBound...])
                            if let colonIndex = afterArrow.firstIndex(of: ":") {
                                let serverIP = String(afterArrow[..<colonIndex])
                                gameServerIPs.append(serverIP)
                                print("提取到游戏服务器 IP: \(serverIP)")
                            }
                        }
                    }
                }
                
                print("总共检查了 \(lines.count) 行连接")
                print("找到 \(gameConnections) 个游戏连接")
                print("游戏服务器 IPs: \(gameServerIPs)")
                
                DispatchQueue.main.async {
                    if gameConnections > 0 {
                        self.lastActionStatus = "找到 \(gameConnections) 个游戏连接，执行全网络阻断 20 秒"
                    } else {
                        self.lastActionStatus = "未发现直连游戏连接，仍执行全网络阻断 20 秒"
                    }
                }
                
                // 执行全网络阻断（无论是否找到游戏连接）
                Task {
                    await self.blockAndUnblockServer("")
                }
                
                continuation.resume()
            }
            
            do {
                try task.run()
            } catch {
                print("查看进程网络连接失败: \(error)")
                DispatchQueue.main.async {
                    self.lastActionStatus = "查看网络连接失败: \(error.localizedDescription)"
                }
                continuation.resume()
            }
        }
    }
    
    
    private func blockAndUnblockServer(_ serverIP: String) async {
        print("全网络阻断 20 秒...")
        
        // Get password from UserDefaults
        guard let password = UserDefaults.standard.string(forKey: "adminPassword") else {
            DispatchQueue.main.async {
                self.lastActionStatus = "请先设置管理员密码"
            }
            return
        }
        
        let blockScript = """
        echo "[A] 正在阻断所有 TCP 出站连接..."
        
        # 启用pfctl
        sudo pfctl -e > /dev/null 2>&1
        
        # 创建阻断规则
        echo "block drop out quick proto tcp from any to any" | sudo tee /etc/pf.blockall.conf > /dev/null
        
        # 加载阻断规则
        sudo pfctl -f /etc/pf.blockall.conf > /dev/null 2>&1
        
        echo "[B] 网络已阻断，20 秒后恢复..."
        
        # 等待20秒
        sleep 20
        
        # 恢复网络 - 加载原始配置
        sudo pfctl -f /etc/pf.conf > /dev/null 2>&1
        
        echo "[C] 网络已恢复"
        """
        
        await executeAppleScriptSudo(blockScript)
    }
    
    private func useNetworkSetupMethod() async {
        print("使用网络接口断开方法 (20秒)...")
        
        await withCheckedContinuation { continuation in
            // Disconnect network
            let disconnectScript = """
            networksetup -setairportpower en0 off
            """
            
            executeNetworkCommand(disconnect: true) { success in
                if success {
                    print("网络已断开，20秒后自动重连...")
                    
                    DispatchQueue.main.async {
                        self.lastActionStatus = "网络已断开，20秒后自动重连"
                    }
                    
                    // Wait 20 seconds then reconnect
                    DispatchQueue.global().asyncAfter(deadline: .now() + 20) {
                        self.executeNetworkCommand(disconnect: false) { reconnectSuccess in
                            DispatchQueue.main.async {
                                if reconnectSuccess {
                                    self.lastActionStatus = "网络断开20秒完成，已自动重连"
                                } else {
                                    self.lastActionStatus = "网络重连失败"
                                }
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.lastActionStatus = "网络断开失败"
                    }
                }
                continuation.resume()
            }
        }
    }
    
    private func executeAppleScript(_ script: String) async {
        await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", script]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                print("AppleScript 执行结果: \(output)")
                
                DispatchQueue.main.async {
                    if output.contains("网络阻断完成") || process.terminationStatus == 0 {
                        self.lastActionStatus = "网络阻断完成，已自动恢复"
                    } else if output.contains("User cancelled") {
                        self.lastActionStatus = "用户取消了权限请求"
                    } else {
                        self.lastActionStatus = "网络阻断失败: \(output)"
                    }
                }
                
                continuation.resume()
            }
            
            do {
                try task.run()
            } catch {
                print("执行 AppleScript 失败: \(error)")
                DispatchQueue.main.async {
                    self.lastActionStatus = "AppleScript 执行失败"
                }
                continuation.resume()
            }
        }
    }
    
    private func executeBlockScript(_ script: String) async {
        await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", script]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            // 实时读取输出
            let outputHandle = pipe.fileHandleForReading
            outputHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    let output = String(data: data, encoding: .utf8) ?? ""
                    print("实时输出: \(output)")
                    
                    DispatchQueue.main.async {
                        if output.contains("[A] 正在阻断") {
                            self.lastActionStatus = "正在阻断所有TCP连接..."
                        } else if output.contains("[B] 网络已阻断") {
                            self.lastActionStatus = "网络已阻断，20秒后自动恢复..."
                        } else if output.contains("[C] 网络已恢复") {
                            self.lastActionStatus = "网络阻断完成，已自动恢复"
                        }
                    }
                }
            }
            
            task.terminationHandler = { process in
                outputHandle.readabilityHandler = nil
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                print("阻断脚本执行完成: \(output)")
                
                DispatchQueue.main.async {
                    if output.contains("需要管理员权限") {
                        self.lastActionStatus = "需要管理员权限执行全网络阻断"
                    } else if !output.contains("[C] 网络已恢复") {
                        self.lastActionStatus = "网络阻断执行完成"
                    }
                }
                
                continuation.resume()
            }
            
            do {
                try task.run()
            } catch {
                print("执行阻断脚本失败: \(error)")
                DispatchQueue.main.async {
                    self.lastActionStatus = "阻断脚本执行失败"
                }
                continuation.resume()
            }
        }
    }
    
    private func executeAppleScriptSudo(_ script: String) async {
        let appleScript = """
        do shell script "\(script.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        await executeAppleScript(appleScript)
    }
}
