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
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var hearthstoneTimer: Timer?
    private var disconnectTimer: Timer?
    private var reconnectTimer: Timer?
    
    private let hearthstoneProcessNames = [
        "Hearthstone",
        "炉石传说",
        "HearthstoneBeta"
    ]
    
    init() {
        setupNetworkMonitoring()
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
        if isConnected {
            disconnectNetwork()
        } else {
            reconnectNetwork()
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
}