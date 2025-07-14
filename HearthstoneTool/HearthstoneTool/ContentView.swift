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
        VStack(spacing: 30) {
            Text("ClashX 控制器")
                .font(.title)
                .padding(.top)
            
            Text(connectionStatus)
                .font(.headline)
                .foregroundColor(connectionStatus == "连接成功" ? .green : .orange)
            
            Button(action: {
                disconnectClashX()
            }) {
                Text("一键拔线")
                    .font(.title2)
                    .frame(width: 200, height: 50)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isDisconnecting)
        }
        .padding()
        .frame(width: 300, height: 200)
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
        
        process.terminationHandler = { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.connectionStatus = "连接成功"
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
