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
import Carbon

class NetworkManager: ObservableObject {
    @Published var isConnected = true
    @Published var hearthstoneRunning = false
    @Published var lastActionStatus = ""
    @Published var hasAdminPassword = false
    @Published var isDisconnecting = false // 正在执行断开操作
    @Published var disconnectProgress: Double = 0.0 // 断网进度 0.0-1.0
    @Published var remainingTime: Int = 0 // 剩余时间（秒）
    @Published var shortcutKey: String = "CMD+R" // 快捷键设置
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var disconnectTimer: Timer?
    private var reconnectTimer: Timer?
    private var progressTimer: Timer?
    private var hotKeyRef: EventHotKeyRef?
    
    private let hearthstoneProcessNames = [
        "Hearthstone",
        "炉石传说", 
        "HearthstoneBeta",
        "/Applications/Hearthstone/Hearthstone.app/Contents/MacOS/Hearthstone"
    ]
    
    init() {
        setupNetworkMonitoring()
        checkAdminPassword()
        loadShortcutKey()
        setupGlobalHotkey()
    }
    
    private func checkAdminPassword() {
        hasAdminPassword = loadPasswordFromKeychain() != nil
    }
    
    deinit {
        monitor.cancel()
        disconnectTimer?.invalidate()
        reconnectTimer?.invalidate()
        progressTimer?.invalidate()
        unregisterGlobalHotkey()
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
    
    func toggleConnection(duration: Int = 20) {
        if isConnected && !isDisconnecting {
            DispatchQueue.main.async {
                self.isDisconnecting = true
                self.disconnectProgress = 0.0
                self.remainingTime = duration
                self.lastActionStatus = "正在执行网络阻断..."
            }
            
            Task {
                await executeNetworkBlockScript(duration: duration)
                DispatchQueue.main.async {
                    self.isDisconnecting = false
                    self.disconnectProgress = 0.0
                    self.remainingTime = 0
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
        let service = Bundle.main.bundleIdentifier ?? "HearthstoneTool"
        let account = "adminPassword"
        
        // 删除旧密码
        deletePasswordFromKeychain()
        
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        print("保存密码到钥匙串状态: \(status)")
        DebugLogger.shared.log("保存密码到钥匙串状态: \(status)")
        DebugLogger.shared.log("使用服务名: \(service)")
        DebugLogger.shared.log("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        if status != errSecSuccess {
            DebugLogger.shared.log("钥匙串保存失败，错误代码: \(status)")
            // 常见错误码解释
            switch status {
            case errSecDuplicateItem:
                DebugLogger.shared.log("错误: 钥匙串项目已存在 (errSecDuplicateItem)")
            case errSecParam:
                DebugLogger.shared.log("错误: 参数错误 (errSecParam)")
            case errSecAllocate:
                DebugLogger.shared.log("错误: 内存分配失败 (errSecAllocate)")
            case errSecNotAvailable:
                DebugLogger.shared.log("错误: 钥匙串服务不可用 (errSecNotAvailable)")
            case errSecAuthFailed:
                DebugLogger.shared.log("错误: 认证失败 (errSecAuthFailed)")
            case -34018:
                DebugLogger.shared.log("错误: 缺少钥匙串权限 (errSecMissingEntitlement)")
            case -25300:
                DebugLogger.shared.log("错误: 钥匙串项目不存在 (errSecItemNotFound)")
            default:
                DebugLogger.shared.log("错误: 未知错误码 \(status)")
            }
        }
        return status == errSecSuccess
    }
    
    private func loadPasswordFromKeychain() -> String? {
        let service = Bundle.main.bundleIdentifier ?? "HearthstoneTool"
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
        
        print("Debug: 读取钥匙串状态: \(status)")
        DebugLogger.shared.log("读取钥匙串状态: \(status)")
        DebugLogger.shared.log("使用服务名: \(service)")
        
        if status == errSecSuccess,
           let passwordData = result as? Data,
           let password = String(data: passwordData, encoding: .utf8) {
            print("Debug: 钥匙串密码读取成功")
            DebugLogger.shared.log("钥匙串密码读取成功，长度: \(password.count)")
            return password
        }
        
        print("Debug: 钥匙串密码读取失败，状态: \(status)")
        DebugLogger.shared.log("钥匙串密码读取失败，状态: \(status)")
        return nil
    }
    
    private func deletePasswordFromKeychain() {
        let service = Bundle.main.bundleIdentifier ?? "HearthstoneTool"
        let account = "adminPassword"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    
    private func executeNetworkBlockScript(duration: Int) async {
        print("执行外部网络阻断脚本，时长: \(duration) 秒")
        
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
            task.arguments = [scriptPath, String(duration)]
            task.environment = ["SUDO_PASSWORD": password]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            var hasError = false
            var errorMessage = ""
            
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
                            // 网络阻断开始，启动进度跟踪定时器
                            self.lastActionStatus = "网络已阻断，\(duration)秒后自动恢复..."
                            self.startProgressTimer(duration: duration)
                        } else if output.contains("[C] 网络已恢复") {
                            self.lastActionStatus = "网络阻断完成，已自动恢复"
                        } else if output.contains("[ERROR]") {
                            // 处理脚本错误
                            hasError = true
                            errorMessage = output.replacingOccurrences(of: "[ERROR] ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            self.lastActionStatus = errorMessage
                            self.disconnectProgress = 0.0
                            self.remainingTime = 0
                            self.progressTimer?.invalidate()
                            self.progressTimer = nil
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
                    // 停止进度定时器
                    self.progressTimer?.invalidate()
                    self.progressTimer = nil
                    
                    if process.terminationStatus == 0 {
                        self.lastActionStatus = "网络阻断脚本执行完成"
                        self.disconnectProgress = 1.0
                        self.remainingTime = 0
                    } else {
                        // 如果实时输出没有捕获到错误信息，才显示通用错误
                        if !hasError {
                            self.lastActionStatus = "网络阻断脚本执行失败，状态码: \(process.terminationStatus)"
                        }
                        // 错误状态已经在实时输出中设置了
                        self.disconnectProgress = 0.0
                        self.remainingTime = 0
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
    
    private func startProgressTimer(duration: Int) {
        var elapsed = 0
        let totalDuration = duration
        
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            elapsed += 1
            let remaining = max(0, totalDuration - elapsed)
            let progress = min(1.0, Double(elapsed) / Double(totalDuration))
            
            DispatchQueue.main.async {
                self?.remainingTime = remaining
                self?.disconnectProgress = progress
            }
            
            if elapsed >= totalDuration {
                timer.invalidate()
                DispatchQueue.main.async {
                    self?.progressTimer = nil
                }
            }
        }
    }
    
    // MARK: - Shortcut Key Management
    
    func setShortcutKey(_ shortcut: String) {
        shortcutKey = shortcut
        UserDefaults.standard.set(shortcut, forKey: "shortcutKey")
        
        // Re-register hotkey
        unregisterGlobalHotkey()
        setupGlobalHotkey()
        
        lastActionStatus = "快捷键已更新为 \(shortcut)"
    }
    
    private func loadShortcutKey() {
        shortcutKey = UserDefaults.standard.string(forKey: "shortcutKey") ?? "CMD+R"
    }
    
    private func setupGlobalHotkey() {
        guard let (keyCode, modifiers) = parseShortcutKey(shortcutKey) else {
            print("无法解析快捷键: \(shortcutKey)")
            return
        }
        
        var hotKeyID = EventHotKeyID(signature: OSType("HSTL".fourCharCodeValue), id: 1)
        
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("全局快捷键注册成功: \(shortcutKey)")
            
            // Set up event handler
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
            InstallEventHandler(GetEventDispatcherTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
                let networkManager = Unmanaged<NetworkManager>.fromOpaque(userData!).takeUnretainedValue()
                networkManager.triggerDisconnect()
                return noErr
            }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)
        } else {
            print("全局快捷键注册失败: \(status)")
        }
    }
    
    private func unregisterGlobalHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    private func parseShortcutKey(_ shortcut: String) -> (keyCode: Int, modifiers: Int)? {
        let components = shortcut.components(separatedBy: "+")
        var modifiers = 0
        var keyCode: Int?
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces).uppercased()
            switch trimmed {
            case "CMD", "COMMAND":
                modifiers |= cmdKey
            case "CTRL", "CONTROL":
                modifiers |= controlKey
            case "OPT", "OPTION", "ALT":
                modifiers |= optionKey
            case "SHIFT":
                modifiers |= shiftKey
            default:
                // Try to parse as key
                if let code = keyCodeForString(trimmed) {
                    keyCode = code
                }
            }
        }
        
        guard let code = keyCode else { return nil }
        return (code, modifiers)
    }
    
    private func keyCodeForString(_ key: String) -> Int? {
        switch key.uppercased() {
        case "A": return kVK_ANSI_A
        case "B": return kVK_ANSI_B
        case "C": return kVK_ANSI_C
        case "D": return kVK_ANSI_D
        case "E": return kVK_ANSI_E
        case "F": return kVK_ANSI_F
        case "G": return kVK_ANSI_G
        case "H": return kVK_ANSI_H
        case "I": return kVK_ANSI_I
        case "J": return kVK_ANSI_J
        case "K": return kVK_ANSI_K
        case "L": return kVK_ANSI_L
        case "M": return kVK_ANSI_M
        case "N": return kVK_ANSI_N
        case "O": return kVK_ANSI_O
        case "P": return kVK_ANSI_P
        case "Q": return kVK_ANSI_Q
        case "R": return kVK_ANSI_R
        case "S": return kVK_ANSI_S
        case "T": return kVK_ANSI_T
        case "U": return kVK_ANSI_U
        case "V": return kVK_ANSI_V
        case "W": return kVK_ANSI_W
        case "X": return kVK_ANSI_X
        case "Y": return kVK_ANSI_Y
        case "Z": return kVK_ANSI_Z
        case "0": return kVK_ANSI_0
        case "1": return kVK_ANSI_1
        case "2": return kVK_ANSI_2
        case "3": return kVK_ANSI_3
        case "4": return kVK_ANSI_4
        case "5": return kVK_ANSI_5
        case "6": return kVK_ANSI_6
        case "7": return kVK_ANSI_7
        case "8": return kVK_ANSI_8
        case "9": return kVK_ANSI_9
        case "SPACE": return kVK_Space
        case "ENTER", "RETURN": return kVK_Return
        case "TAB": return kVK_Tab
        case "ESC", "ESCAPE": return kVK_Escape
        default: return nil
        }
    }
    
    @objc private func triggerDisconnect() {
        DispatchQueue.main.async {
            self.checkHearthstoneStatus()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !self.hearthstoneRunning {
                    self.showUserMessage("请先启动炉石传说游戏")
                } else if !self.hasAdminPassword {
                    self.showUserMessage("请先设置管理员密码")
                } else {
                    self.toggleConnection(duration: 20) // 默认20秒
                }
            }
        }
    }
}

extension String {
    var fourCharCodeValue: Int {
        var result: Int = 0
        if let data = self.data(using: .macOSRoman) {
            data.withUnsafeBytes { bytes in
                for i in 0..<min(4, data.count) {
                    result = result << 8 + Int(bytes[i])
                }
            }
        }
        return result
    }
}
