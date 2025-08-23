# 炉石传说拔线工具 (Hearthstone Disconnect Tool)

一个用于 macOS 的炉石传说自动拔线工具，可以在战斗期间自动断开网络连接以跳过战斗动画，提高游戏效率。

## 功能特点

- 🎮 自动检测炉石传说进程
- 🌐 智能网络连接控制
- ⚡ 自动战斗检测与断网
- 🖥️ 简洁的 SwiftUI 界面
- 🔒 支持管理员权限验证

## 系统要求

- macOS 11.0 或更高版本
- Xcode 13.0 或更高版本
- 管理员权限（用于控制网络连接）

## 安装与使用

### 1. 编译项目
```bash
git clone <repository-url>
cd HearthstoneTool
open HearthstoneTool.xcodeproj
```

在 Xcode 中编译并运行项目。

### 2. 授权设置

由于工具需要控制网络连接，首次运行时会要求管理员权限。请在系统提示时输入密码。

### 3. 使用方法

1. **启动炉石传说**：确保炉石传说正在运行
2. **开始监控**：点击"开始监控"按钮
3. **自动拔线**：工具会自动检测战斗并在适当时机断网
4. **手动控制**：也可以手动控制网络连接

## 工作原理

1. **进程检测**：实时监控炉石传说进程状态
2. **战斗识别**：通过屏幕分析检测战斗开始
3. **网络控制**：使用 `networksetup` 命令控制 WiFi 连接
4. **自动重连**：断网后自动在 3 秒内重新连接

## 核心组件

### NetworkManager.swift
- 网络连接状态管理
- 炉石进程检测
- 断网/重连控制

### BattleDetector.swift
- 屏幕分析
- 战斗状态检测
- 自动触发断网

### ContentView.swift
- SwiftUI 用户界面
- 状态显示
- 控制按钮

## 注意事项

⚠️ **重要提醒**：
- 此工具需要关闭应用沙盒才能正常工作
- 使用前请确保理解游戏规则，避免违反服务条款
- 仅建议在单机模式或允许的情况下使用
- 工具可能会影响其他网络连接，请谨慎使用

## 技术细节

### 网络控制方式
```swift
// 断网命令
networksetup -setairportpower en0 off

// 重连命令
networksetup -setairportpower en0 on
```

### 权限配置
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

## 故障排除

### 无法控制网络连接
- 确保已授予管理员权限
- 检查网络接口名称是否为 `en0`
- 尝试手动运行 networksetup 命令测试

### 检测不到炉石进程
- 确保炉石传说正在运行
- 检查进程名称是否匹配（支持中英文版本）

### 战斗检测不准确
- 调整屏幕分析参数
- 确保炉石窗口可见且未被遮挡

## 开发说明

基于参考项目 [hearthstone_skipper](https://github.com/z2z63/hearthstone_skipper) 的设计理念，使用 Swift 和 SwiftUI 重新实现，专为 macOS 平台优化。

## 许可证

本项目仅供学习和研究使用，请遵守相关法律法规和游戏服务条款。

---

**免责声明**：使用此工具的风险由用户自行承担。开发者不对因使用此工具而产生的任何后果负责。
