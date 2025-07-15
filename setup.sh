#!/bin/bash

# 炉石拔线工具安装脚本
# 作者: HearthstoneTool
# 版本: 2.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    炉石拔线工具安装脚本${NC}"
    echo -e "${BLUE}================================${NC}"
}

check_system() {
    print_message $YELLOW "检查系统环境..."
    
    # 检查macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_message $RED "错误: 此工具仅支持macOS系统"
        exit 1
    fi
    
    print_message $GREEN "✓ 系统检查通过"
}

check_dependencies() {
    print_message $YELLOW "检查依赖..."
    
    # 检查Python 3
    if ! command -v python3 &> /dev/null; then
        print_message $RED "错误: 未找到Python 3"
        print_message $YELLOW "请先安装Python 3: https://www.python.org/downloads/"
        exit 1
    fi
    
    # 检查pip
    if ! command -v pip3 &> /dev/null; then
        print_message $RED "错误: 未找到pip3"
        print_message $YELLOW "请先安装pip3"
        exit 1
    fi
    
    # 检查Little Snitch
    if ! command -v littlesnitch &> /dev/null; then
        print_message $RED "错误: 未找到Little Snitch"
        print_message $YELLOW "请先安装Little Snitch: https://www.obdev.at/products/littlesnitch/index.html"
        exit 1
    fi
    
    print_message $GREEN "✓ 依赖检查通过"
}

install_python_dependencies() {
    print_message $YELLOW "安装Python依赖..."
    
    # 安装必要的Python包
    pip3 install --user psutil
    
    print_message $GREEN "✓ Python依赖安装完成"
}

setup_little_snitch_rules() {
    print_message $YELLOW "设置Little Snitch规则..."
    
    # 提示用户手动设置规则
    cat << EOF

${YELLOW}请手动在Little Snitch中设置以下规则:${NC}

1. 打开Little Snitch配置
2. 创建新的规则组，名称为: ${GREEN}HearthStone${NC}
3. 添加规则:
   - 应用程序: Hearthstone
   - 连接: 禁止所有出站连接
   - 协议: Any
   - 端口: Any
   - 目标: Any

4. 保存规则组

${YELLOW}按任意键继续...${NC}
EOF
    
    read -n 1 -s
    print_message $GREEN "✓ Little Snitch规则设置完成"
}

create_launch_script() {
    print_message $YELLOW "创建启动脚本..."
    
    # 创建启动脚本
    cat > hearthstone_disconnect_tool.sh << 'EOF'
#!/bin/bash

# 炉石拔线工具启动脚本
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查Python脚本是否存在
if [[ ! -f "improved_hearthstone_tool.py" ]]; then
    echo "错误: 未找到 improved_hearthstone_tool.py"
    exit 1
fi

# 启动工具
python3 improved_hearthstone_tool.py
EOF
    
    chmod +x hearthstone_disconnect_tool.sh
    print_message $GREEN "✓ 启动脚本创建完成"
}

create_desktop_shortcut() {
    print_message $YELLOW "创建桌面快捷方式..."
    
    # 获取当前路径
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 创建应用程序包结构
    APP_NAME="炉石拔线工具.app"
    APP_DIR="$HOME/Applications/$APP_NAME"
    
    if [[ -d "$APP_DIR" ]]; then
        rm -rf "$APP_DIR"
    fi
    
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"
    
    # 创建Info.plist
    cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>炉石拔线工具</string>
    <key>CFBundleIdentifier</key>
    <string>com.hearthstone.disconnect.tool</string>
    <key>CFBundleName</key>
    <string>炉石拔线工具</string>
    <key>CFBundleVersion</key>
    <string>2.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
    
    # 创建启动脚本
    cat > "$APP_DIR/Contents/MacOS/炉石拔线工具" << EOF
#!/bin/bash
cd "$CURRENT_DIR"
python3 improved_hearthstone_tool.py
EOF
    
    chmod +x "$APP_DIR/Contents/MacOS/炉石拔线工具"
    
    print_message $GREEN "✓ 桌面快捷方式创建完成"
    print_message $BLUE "位置: $APP_DIR"
}

setup_permissions() {
    print_message $YELLOW "设置权限..."
    
    # 提示用户设置sudo权限
    cat << EOF

${YELLOW}为了让工具正常工作，需要设置sudo权限:${NC}

1. 运行以下命令来测试sudo权限:
   ${GREEN}sudo -v${NC}

2. 如果提示输入密码，请输入您的管理员密码

3. 建议将密码保存到keychain中，工具会自动处理

${YELLOW}按任意键继续...${NC}
EOF
    
    read -n 1 -s
    
    # 测试sudo权限
    if sudo -v; then
        print_message $GREEN "✓ 权限设置完成"
    else
        print_message $RED "权限设置失败，请手动运行 sudo -v"
    fi
}

show_usage() {
    print_message $BLUE "安装完成！"
    
    cat << EOF

${GREEN}使用方法:${NC}

1. 命令行启动:
   ${BLUE}./hearthstone_disconnect_tool.sh${NC}

2. 应用程序启动:
   在 Applications 文件夹中找到 "炉石拔线工具.app" 并双击

3. 快捷键:
   - Ctrl+D: 执行拔线
   - Ctrl+Q: 退出程序
   - Esc: 退出程序

${GREEN}功能特点:${NC}
- ✓ 自动检测炉石进程
- ✓ 支持keychain密码存储
- ✓ 可拖拽的悬浮窗口
- ✓ 智能错误处理
- ✓ 快捷键支持

${YELLOW}注意事项:${NC}
- 首次使用需要输入管理员密码
- 确保Little Snitch规则已正确设置
- 在炉石对局中使用效果最佳

${BLUE}如有问题，请查看日志或联系开发者${NC}
EOF
}

main() {
    print_header
    
    check_system
    check_dependencies
    install_python_dependencies
    setup_little_snitch_rules
    create_launch_script
    create_desktop_shortcut
    setup_permissions
    
    show_usage
    
    print_message $GREEN "🎉 安装完成！"
}

# 运行主函数
main "$@"