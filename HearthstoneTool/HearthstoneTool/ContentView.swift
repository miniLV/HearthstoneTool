//
//  ContentView.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/8/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var isMonitoring = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("炉石传说拔线工具")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                HStack {
                    Text("炉石进程状态:")
                    Spacer()
                    Text(networkManager.hearthstoneRunning ? "运行中" : "未运行")
                        .foregroundColor(networkManager.hearthstoneRunning ? .green : .red)
                }
                
                HStack {
                    Text("网络状态:")
                    Spacer()
                    Text(networkManager.isConnected ? "已连接" : "已断开")
                        .foregroundColor(networkManager.isConnected ? .green : .red)
                }
                
                HStack {
                    Text("Clash 状态:")
                    Spacer()
                    Text(networkManager.clashConfigured ? "已配置" : "未配置")
                        .foregroundColor(networkManager.clashConfigured ? .green : .orange)
                }
                
                HStack {
                    Text("监控状态:")
                    Spacer()
                    Text(isMonitoring ? "监控中" : "未监控")
                        .foregroundColor(isMonitoring ? .green : .gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            VStack(spacing: 10) {
                Button(action: {
                    if isMonitoring {
                        networkManager.stopMonitoring()
                        isMonitoring = false
                    } else {
                        networkManager.startMonitoring()
                        isMonitoring = true
                    }
                }) {
                    Text(isMonitoring ? "停止监控" : "开始监控")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isMonitoring ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    networkManager.toggleConnection()
                }) {
                    Text(networkManager.clashConfigured ? "断开炉石连接" : (networkManager.isConnected ? "手动断网" : "手动连网"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(networkManager.clashConfigured ? Color.red : (networkManager.isConnected ? Color.orange : Color.green))
                        .cornerRadius(10)
                }
                .disabled(!networkManager.hearthstoneRunning)
            }
            
            Text(networkManager.clashConfigured ? "使用 Clash 精确控制炉石连接，无需管理员权限" : "注意: 需要管理员权限来控制网络连接")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear {
            networkManager.checkHearthstoneStatus()
        }
    }
}

#Preview {
    ContentView()
}
