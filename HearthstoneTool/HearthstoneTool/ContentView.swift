//
//  ContentView.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/7/14.
//

import SwiftUI

struct ContentView: View {
    @State private var connectionStatus = "连接成功"
    @State private var isDisconnecting = false
    
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
        connectionStatus = "重连中"
        
        guard let scriptPath = Bundle.main.path(forResource: "clashx_disconnect", ofType: "sh") else {
            connectionStatus = "脚本未找到"
            isDisconnecting = false
            return
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.terminationHandler = { process in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    self.connectionStatus = "连接成功"
                } else {
                    self.connectionStatus = "执行失败"
                    print("脚本输出: \(output)")
                }
                self.isDisconnecting = false
            }
        }
        
        do {
            try process.run()
        } catch {
            DispatchQueue.main.async {
                self.connectionStatus = "执行失败: \(error.localizedDescription)"
                self.isDisconnecting = false
            }
        }
    }
}

#Preview {
    ContentView()
}
