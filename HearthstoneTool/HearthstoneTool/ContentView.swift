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
    @State private var disconnectDuration = 20 // 默认20秒
    
    var body: some View {
        VStack(spacing: 8) {
            // 标题栏
            HStack {
                Text("炉石拔线工具")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                
                // 状态指示器和设置按钮
                HStack(spacing: 8) {
                    Circle()
                        .fill(networkManager.hearthstoneRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Button("⚙️") {
                        showingPasswordSetup = true
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(networkManager.hasAdminPassword ? .green : .orange)
                }
            }
            
            // 主要操作区域
            HStack(spacing: 12) {
                // 左侧时长设置
                VStack(alignment: .leading, spacing: 2) {
                    Text("时长")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        TextField("20", value: $disconnectDuration, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 45)
                        Text("秒")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 右侧断网按钮
                Button(action: {
                    networkManager.checkHearthstoneStatus()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !networkManager.hearthstoneRunning {
                            networkManager.showUserMessage("请先启动炉石传说游戏")
                        } else if !networkManager.hasAdminPassword {
                            networkManager.showUserMessage("请先设置管理员密码")
                        } else {
                            networkManager.toggleConnection(duration: disconnectDuration)
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        if networkManager.isDisconnecting {
                            HStack {
                                Text("断网中")
                                Text("\(networkManager.remainingTime)s")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .font(.system(size: 14, weight: .medium))
                            
                            ProgressView(value: networkManager.disconnectProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .frame(height: 2)
                        } else {
                            Text("断开炉石")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 120, height: 35)
                    .background(networkManager.isDisconnecting ? Color.gray : Color.red)
                    .cornerRadius(8)
                }
                .disabled(networkManager.isDisconnecting)
            }
            
            // 底部状态信息
            if !networkManager.lastActionStatus.isEmpty {
                Text(networkManager.lastActionStatus)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(12)
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
            
            // Exit app section
            VStack(alignment: .leading, spacing: 10) {
                Text("应用控制")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button("退出应用") {
                    exit(0)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
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