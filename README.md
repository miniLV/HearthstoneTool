# HearthstoneTool

<div align="center">

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

**一个专为炉石传说玩家设计的智能断网重连工具**

简单、安全、高效的网络控制工具，帮助你在关键时刻快速断开网络连接

[🇨🇳 中文](README.md) • [🇺🇸 English](README_EN.md)

[功能特色](#功能特色) • [安装说明](#安装说明) • [使用方法](#使用方法) • [常见问题](#常见问题)

</div>

## 🎮 功能特色

- **🚀 一键断网**：智能检测炉石传说运行状态，一键执行网络断开操作
- **⏱️ 精确计时**：自定义断网时长（默认20秒），精确到秒的计时控制
- **⌨️ 快捷键支持**：全局快捷键（默认 `CMD+R`），支持自定义按键组合
- **🔒 安全认证**：管理员密码安全存储在macOS钥匙串中，保障系统安全
- **📊 实时反馈**：可视化进度条和倒计时，实时显示断网状态
- **🎯 游戏检测**：自动检测炉石传说是否运行，避免误操作
- **⚙️ 个性化设置**：支持快捷键自定义、密码管理等个人偏好设置

## 💻 系统要求

- macOS 11.0 或更高版本
- 管理员权限（用于网络控制）
- Xcode 13+ （如需从源码编译）

## 📦 安装说明

### 方法一：下载预编译版本
1. 前往 [Releases](../../releases) 页面
2. 下载最新版本的 `HearthstoneTool.dmg`
3. 双击安装包，将应用拖拽到 `Applications` 文件夹

#### ⚠️ 安全提示处理
由于应用未经过Apple官方签名，首次运行时会遇到安全提示。常见的错误信息包括：

**错误信息1：损坏提示**
```
"HearthstoneTool" is damaged and can't be opened. 
You should eject the disk image.
```

**错误信息2：验证失败**
```
"HearthstoneTool" cannot be opened because Apple could not verify 
"HearthstoneTool" is free of malware that may harm your Mac.
```

**解决方法1：通过右键打开（推荐）**
1. **右键点击应用** → 选择 **"打开"**
2. 会弹出警告对话框，点击 **"打开"**
3. 或者在 **系统偏好设置** → **安全性与隐私** → **通用** 中点击 **"仍要打开"**

**解决方法2：命令行移除隔离属性**
```bash
# 如果应用已安装到Applications文件夹：
sudo xattr -rd com.apple.quarantine /Applications/HearthstoneTool.app
```

**解决方法3：系统设置临时允许**
1. **系统偏好设置** → **安全性与隐私** → **通用**
2. 将 **"允许从以下位置下载的应用"** 改为 **"任何来源"**（需要先解锁）
3. 运行应用后可改回原设置

> 💡 **提示**：这些错误是macOS正常的安全机制，使用方法1最安全简单。完成授权后，应用就可以正常启动了。

### 方法二：从源码编译
```bash
# 克隆仓库
git clone git@github.com:miniLV/HearthstoneTool.git
cd HearthstoneTool

# 使用 Xcode 打开项目
open HearthstoneTool.xcodeproj

# 在 Xcode 中构建并运行
```

## 🚀 使用方法

### 首次设置
1. **启动应用**：双击应用图标或从启动台启动
2. **设置管理员密码**：点击右上角 ⚙️ 图标，输入你的macOS管理员密码
3. **启动炉石传说**：确保炉石传说游戏正在运行（状态指示器会显示绿色）

### 基本操作
1. **设置时长**：在左侧输入框中设置断网时长（秒）
2. **执行断网**：点击红色"断开炉石"按钮
3. **观察进度**：实时查看断网倒计时和进度条
4. **自动恢复**：时间到达后网络将自动恢复

### 快捷键操作
- **默认快捷键**：`CMD+R` 一键断网
- **自定义快捷键**：在设置中可修改为其他组合键
- **支持的修饰键**：CMD, CTRL, OPT, SHIFT
- **示例组合**：`CMD+SHIFT+D`, `CTRL+ALT+Q` 等

### 设置面板功能
在设置面板中你可以：
- 🔐 **密码管理**：设置、查看、清除管理员密码
- ⌨️ **快捷键配置**：自定义全局快捷键组合
- 🚪 **退出应用**：安全关闭应用程序

## 🎯 使用场景

HearthstoneTool 主要用于以下游戏场景：
- **竞技场选择**：在不满意的选择时快速重置
- **对战策略调整**：关键时刻需要重新思考策略
- **网络问题模拟**：测试游戏的重连机制
- **紧急情况处理**：快速脱离不利局面

## ⚠️ 注意事项

- 🔴 **仅供炉石传说爱好者学习和测试使用**，请遵守游戏服务条款
- 🎮 **专为炉石传说设计**，请勿用于其他游戏或非法用途
- ⚖️ **使用风险自负**，开发者不承担任何因使用本工具产生的后果
- 🔒 需要授予应用**辅助功能权限**以支持全局快捷键
- 🛡️ 管理员密码仅用于网络控制，安全存储在本地钥匙串
- 📱 应用会检测炉石传说运行状态，确保安全操作
- ⏰ 断网操作不可中途取消，请谨慎设置时长

## 🔧 技术实现

- **开发语言**：Swift 5.0 + SwiftUI
- **网络控制**：使用 `networksetup` 命令控制Wi-Fi状态
- **进程检测**：通过 `pgrep` 命令检测游戏进程
- **全局快捷键**：基于 NSEvent 框架的系统级按键监听
- **安全存储**：利用 macOS 钥匙串服务保存敏感信息
- **界面设计**：现代化的 SwiftUI 界面，支持浮窗显示

## 🛠️ 开发与贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/AmazingFeature`
3. 提交更改：`git commit -m 'Add some AmazingFeature'`
4. 推送到分支：`git push origin feature/AmazingFeature`
5. 创建 Pull Request

## 📋 TODO

- [ ] 添加应用图标
- [ ] 支持以太网连接控制
- [ ] 添加更多游戏支持
- [ ] 优化全局快捷键功能
- [ ] 添加使用统计功能
- [ ] 支持多语言界面

## ❓ 常见问题

<details>
<summary><strong>Q: 应用显示"无法验证开发者"怎么办？</strong></summary>
<br>
A: 这是正常的macOS安全机制。请按照安装说明中的"安全提示处理"步骤操作：进入系统偏好设置 → 安全性与隐私 → 点击"仍要打开"。
</details>

<details>
<summary><strong>Q: 应用要求输入管理员密码是否安全？</strong></summary>
<br>
A: 完全安全。密码仅用于执行网络控制命令，使用 macOS 钥匙串加密存储，应用本身不会上传或泄露任何信息。
</details>

<details>
<summary><strong>Q: 为什么快捷键不工作？</strong></summary>
<br>
A: 请检查：1) 是否授予了辅助功能权限；2) 快捷键是否与系统快捷键冲突；3) 炉石传说是否正在运行。
</details>

<details>
<summary><strong>Q: 断网后无法恢复网络怎么办？</strong></summary>
<br>
A: 可以手动在系统偏好设置中重新开启Wi-Fi，或等待应用自动恢复（通常在设定时间后自动执行）。
</details>

<details>
<summary><strong>Q: 支持哪些版本的炉石传说？</strong></summary>
<br>
A: 支持官方版本、测试版本等所有主流炉石传说客户端。
</details>

## ⚖️ 免责声明

- **📋 使用目的**：本工具专为炉石传说爱好者提供网络控制功能，仅供学习、测试和个人使用
- **🚫 禁止用途**：严禁将本工具用于其他游戏、商业用途或任何违法行为
- **⚠️ 风险提示**：使用本工具可能影响游戏体验，请确保符合暴雪娱乐的服务条款
- **🛡️ 责任限制**：开发者不对因使用本工具造成的账号封禁、数据丢失或其他任何损失承担责任
- **📞 争议解决**：如有争议或投诉，请通过GitHub Issues联系，开发者将积极配合处理

## 📄 许可证

本项目基于 MIT 许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- 感谢炉石传说社区的反馈和建议
- 感谢所有贡献者的支持
- 特别感谢测试用户的耐心协助

---

<div align="center">

**如果这个工具对你有帮助，请考虑给个 ⭐️ Star 支持一下！**

Made with ❤️ for Hearthstone players

</div>
