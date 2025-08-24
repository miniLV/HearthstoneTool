//
//  NetworkManager.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/8/23.
//

import Foundation
import Network
import Combine
import Security

class NetworkManager: ObservableObject {
    @Published var isConnected = true
    @Published var hearthstoneRunning = false
    @Published var lastActionStatus = ""
    @Published var hasAdminPassword = false
    @Published var isDisconnecting = false // 正在执行断开操作
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var disconnectTimer: Timer?
    private var reconnectTimer: Timer?
    
    private let hearthstoneProcessNames = [
        "Hearthstone",
        "炉石传说", 
        "HearthstoneBeta",
        "/Applications/Hearthstone/Hearthstone.app/Contents/MacOS/Hearthstone"
    ]
    
    init() {
        setupNetworkMonitoring()
        checkAdminPassword()
    }
    
    private func checkAdminPassword() {
        hasAdminPassword = loadPasswordFromKeychain() != nil
    }
    
    deinit {
        monitor.cancel()
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
        if isConnected && !isDisconnecting {
            DispatchQueue.main.async {
                self.isDisconnecting = true
                self.lastActionStatus = "正在执行网络阻断..."
            }
            
            Task {
                await executeNetworkBlockScript()
                DispatchQueue.main.async {
                    self.isDisconnecting = false
                }
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
        disconnectNetwork()
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.reconnectNetwork()
        }
    }
    
    func setAdminPassword(_ password: String) {
        if savePasswordToKeychain(password) {
            checkAdminPassword()
            lastActionStatus = "管理员密码已保存到钥匙串"
        } else {
            lastActionStatus = "密码保存到钥匙串失败"
        }
    }
    
    func clearAdminPassword() {
        deletePasswordFromKeychain()
        checkAdminPassword()
        lastActionStatus = "管理员密码已从钥匙串清除"
    }
    
    func getAdminPassword() -> String? {
        return loadPasswordFromKeychain()
    }
    
    func showUserMessage(_ message: String) {
        DispatchQueue.main.async {
            self.lastActionStatus = message
        }
    }
    
    // MARK: - Keychain Operations
    
    private func savePasswordToKeychain(_ password: String) -> Bool {
        let service = "HearthstoneTool"
        let account = "adminPassword"
        
        // 删除旧密码
        deletePasswordFromKeychain()
        
        let passwordData = password.data(using: .utf8)!
        
        // 创建访问控制，允许应用在设备未锁定时访问，无需用户确认
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [],
            nil
        ) else {
            print("无法创建访问控制")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessControl as String: accessControl
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        print("保存密码到钥匙串状态: \(status)")
        return status == errSecSuccess
    }
    
    private func loadPasswordFromKeychain() -> String? {
        let service = "HearthstoneTool"
        let account = "adminPassword"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let passwordData = result as? Data,
           let password = String(data: passwordData, encoding: .utf8) {
            return password
        }
        
        return nil
    }
    
    private func deletePasswordFromKeychain() {
        let service = "HearthstoneTool"
        let account = "adminPassword"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    
    private func executeNetworkBlockScript() async {
        print("执行外部网络阻断脚本...")
        
        // Get password from Keychain
        guard let password = loadPasswordFromKeychain() else {
            DispatchQueue.main.async {
                self.lastActionStatus = "请先设置管理员密码"
            }
            return
        }
        
        // Get the script path relative to the app bundle
        guard let scriptPath = Bundle.main.path(forResource: "network_block_script", ofType: "sh") else {
            print("找不到 network_block_script.sh 文件")
            DispatchQueue.main.async {
                self.lastActionStatus = "找不到网络阻断脚本文件"
            }
            return
        }
        
        await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = [scriptPath]
            task.environment = ["SUDO_PASSWORD": password]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            // 实时读取输出
            let outputHandle = pipe.fileHandleForReading
            outputHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    let output = String(data: data, encoding: .utf8) ?? ""
                    print("脚本输出: \(output)")
                    
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
                
                print("脚本执行完成: \(output)")
                print("脚本状态码: \(process.terminationStatus)")
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        self.lastActionStatus = "网络阻断脚本执行完成"
                    } else {
                        self.lastActionStatus = "网络阻断脚本执行失败，状态码: \(process.terminationStatus)"
                    }
                }
                
                continuation.resume()
            }
            
            do {
                try task.run()
            } catch {
                print("执行脚本失败: \(error)")
                DispatchQueue.main.async {
                    self.lastActionStatus = "执行网络阻断脚本失败"
                }
                continuation.resume()
            }
        }
    }
}
