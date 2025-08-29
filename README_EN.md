# HearthstoneTool

<div align="center">

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

**An intelligent network disconnection tool designed for Hearthstone players**

Simple, secure, and efficient network control tool to help you quickly disconnect network at critical moments

[🇨🇳 中文](README.md) • [🇺🇸 English](README_EN.md)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [FAQ](#faq)

</div>

## 🎮 Features

- **🚀 One-Click Disconnect**: Intelligently detects Hearthstone running status and executes network disconnection
- **⏱️ Precise Timing**: Customizable disconnection duration (default 20 seconds) with precise timing control
- **⌨️ Hotkey Support**: Global hotkeys (default `CMD+R`) with customizable key combinations
- **🔒 Secure Authentication**: Admin password securely stored in macOS Keychain for system security
- **📊 Real-time Feedback**: Visual progress bar and countdown with real-time disconnection status
- **🎯 Game Detection**: Automatically detects if Hearthstone is running to prevent misoperations
- **⚙️ Personalized Settings**: Support for hotkey customization, password management, and personal preferences

## 💻 System Requirements

- macOS 11.0 or later
- Administrator privileges (for network control)
- Xcode 13+ (if building from source)

## 📦 Installation

### Method 1: Download Pre-built Version
1. Go to [Releases](../../releases) page
2. Download the latest `HearthstoneTool.dmg`
3. Double-click the installer and drag the app to `Applications` folder

### Method 2: Build from Source
```bash
# Clone repository
git clone https://github.com/yourusername/HearthstoneTool.git
cd HearthstoneTool

# Open project in Xcode
open HearthstoneTool.xcodeproj

# Build and run in Xcode
```

## 🚀 Usage

### Initial Setup
1. **Launch App**: Double-click the app icon or launch from Launchpad
2. **Set Admin Password**: Click the ⚙️ icon in the top-right corner and enter your macOS admin password
3. **Start Hearthstone**: Ensure Hearthstone is running (status indicator will show green)

### Basic Operations
1. **Set Duration**: Enter disconnection duration (seconds) in the left input field
2. **Execute Disconnect**: Click the red "Disconnect Hearthstone" button
3. **Monitor Progress**: Watch real-time countdown and progress bar
4. **Auto Recovery**: Network will automatically restore after the specified time

### Hotkey Operations
- **Default Hotkey**: `CMD+R` for one-click disconnect
- **Custom Hotkeys**: Modify to other key combinations in settings
- **Supported Modifiers**: CMD, CTRL, OPT, SHIFT
- **Example Combinations**: `CMD+SHIFT+D`, `CTRL+ALT+Q`, etc.

### Settings Panel Functions
In the settings panel you can:
- 🔐 **Password Management**: Set, view, clear admin password
- ⌨️ **Hotkey Configuration**: Customize global hotkey combinations
- 🚪 **Exit App**: Safely close the application

## 🎯 Use Cases

HearthstoneTool is mainly used for the following game scenarios:
- **Arena Selections**: Quick reset when unsatisfied with choices
- **Battle Strategy Adjustment**: Rethink strategy at critical moments
- **Network Issue Simulation**: Test game's reconnection mechanism
- **Emergency Handling**: Quickly escape unfavorable situations

## ⚠️ Important Notes

- 🔴 **For Hearthstone enthusiasts only** for learning and testing purposes, please comply with game terms of service
- 🎮 **Designed specifically for Hearthstone**, do not use for other games or illegal purposes
- ⚖️ **Use at your own risk**, developers are not responsible for any consequences arising from using this tool
- 🔒 Need to grant **Accessibility permissions** to support global hotkeys
- 🛡️ Admin password is only used for network control, securely stored in local Keychain
- 📱 App detects Hearthstone running status to ensure safe operation
- ⏰ Disconnection operation cannot be cancelled mid-way, please set duration carefully

## 🔧 Technical Implementation

- **Development Language**: Swift 5.0 + SwiftUI
- **Network Control**: Uses `networksetup` command to control Wi-Fi status
- **Process Detection**: Detects game processes via `pgrep` command
- **Global Hotkeys**: System-level key monitoring based on NSEvent framework
- **Secure Storage**: Uses macOS Keychain services to save sensitive information
- **Interface Design**: Modern SwiftUI interface with floating window support

## 🛠️ Development & Contribution

Contributions are welcome! Please follow these steps:

1. Fork this repository
2. Create feature branch: `git checkout -b feature/AmazingFeature`
3. Commit changes: `git commit -m 'Add some AmazingFeature'`
4. Push to branch: `git push origin feature/AmazingFeature`
5. Create Pull Request

## 📋 TODO

- [ ] Add application icon
- [ ] Support Ethernet connection control
- [ ] Add support for more games
- [ ] Optimize global hotkey functionality
- [ ] Add usage statistics
- [ ] Support multi-language interface

## ❓ FAQ

<details>
<summary><strong>Q: Is it safe for the app to request admin password?</strong></summary>
<br>
A: Completely safe. The password is only used for network control commands, encrypted and stored using macOS Keychain, and the app doesn't upload or leak any information.
</details>

<details>
<summary><strong>Q: Why don't hotkeys work?</strong></summary>
<br>
A: Please check: 1) Whether Accessibility permissions are granted; 2) Whether hotkeys conflict with system shortcuts; 3) Whether Hearthstone is running.
</details>

<details>
<summary><strong>Q: What to do if network cannot recover after disconnection?</strong></summary>
<br>
A: You can manually re-enable Wi-Fi in System Preferences, or wait for the app to automatically recover (usually executes automatically after the set time).
</details>

<details>
<summary><strong>Q: Which versions of Hearthstone are supported?</strong></summary>
<br>
A: Supports official versions, beta versions, and all mainstream Hearthstone clients.
</details>

## ⚖️ Disclaimer

- **📋 Intended Use**: This tool is specifically designed for Hearthstone enthusiasts to provide network control functionality, for learning, testing, and personal use only
- **🚫 Prohibited Uses**: It is strictly prohibited to use this tool for other games, commercial purposes, or any illegal activities
- **⚠️ Risk Warning**: Using this tool may affect gaming experience, please ensure compliance with Blizzard Entertainment's Terms of Service
- **🛡️ Limitation of Liability**: Developers are not responsible for account bans, data loss, or any other damages caused by using this tool
- **📞 Dispute Resolution**: For disputes or complaints, please contact via GitHub Issues, developers will actively cooperate in handling

## 📄 License

This project is open source under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to the Hearthstone community for feedback and suggestions
- Thanks to all contributors for their support
- Special thanks to beta testers for their patience

---

<div align="center">

**If this tool helps you, please consider giving it a ⭐️ Star!**

Made with ❤️ for Hearthstone players

</div>