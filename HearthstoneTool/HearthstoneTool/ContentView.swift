//
//  ContentView.swift
//  HearthstoneTool
//
//  Created by tyrion.liang on 2025/8/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var showingPasswordSetup = false
    
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
                    Text("管理员密码:")
                    Spacer()
                    Text(networkManager.hasAdminPassword ? "已设置" : "未设置")
                        .foregroundColor(networkManager.hasAdminPassword ? .green : .orange)
                    
                    Button(networkManager.hasAdminPassword ? "修改" : "设置") {
                        showingPasswordSetup = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            VStack(spacing: 10) {
                Button(action: {
                    // 实时检查炉石状态
                    networkManager.checkHearthstoneStatus()
                    
                    // 延迟一点检查结果，确保状态更新完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !networkManager.hearthstoneRunning {
                            networkManager.showUserMessage("请先启动炉石传说游戏")
                        } else if !networkManager.hasAdminPassword {
                            networkManager.showUserMessage("请先设置管理员密码")
                        } else {
                            networkManager.toggleConnection()
                        }
                    }
                }) {
                    Text(networkManager.isDisconnecting ? "执行中..." : "断开炉石连接")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(networkManager.isDisconnecting ? Color.gray : Color.red)
                        .cornerRadius(10)
                }
                .disabled(networkManager.isDisconnecting)
            }
            
            VStack(spacing: 8) {
                Text(networkManager.lastActionStatus.isEmpty ? " " : networkManager.lastActionStatus)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 16)
                
                Text("注意: 需要管理员权限来执行网络阻断")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            networkManager.checkHearthstoneStatus()
        }
        .sheet(isPresented: $showingPasswordSetup) {
            PasswordSetupView(networkManager: networkManager)
        }
    }
}


struct PasswordSetupView: View {
    @ObservedObject var networkManager: NetworkManager
    @State private var password = ""
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("取消") {
                    dismiss()
                }
                Spacer()
                Text("管理员密码设置")
                    .font(.headline)
                Spacer()
                Button("保存") {
                    networkManager.setAdminPassword(password)
                    dismiss()
                }
                .disabled(password.isEmpty)
            }
            .padding()
            
            // Password input section
            VStack(alignment: .leading, spacing: 10) {
                Text("密码设置")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Group {
                        if showPassword {
                            TextField("请输入管理员密码", text: $password)
                        } else {
                            SecureField("请输入管理员密码", text: $password)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            // Current password section
            if networkManager.hasAdminPassword {
                VStack(alignment: .leading, spacing: 10) {
                    Text("当前密码")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Group {
                            if showPassword, let currentPassword = networkManager.getAdminPassword() {
                                Text(currentPassword)
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                Text("••••••••")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("清除") {
                            networkManager.clearAdminPassword()
                            password = ""
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }
            
            // Description section
            VStack(alignment: .leading, spacing: 8) {
                Text("说明")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• 此密码用于执行需要管理员权限的网络阻断操作")
                    Text("• 密码将安全地保存在本地，不会上传到任何服务器")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            if let currentPassword = networkManager.getAdminPassword() {
                password = currentPassword
            }
        }
    }
}

#Preview {
    ContentView()
}
