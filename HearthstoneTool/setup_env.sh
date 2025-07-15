#!/bin/bash

echo "🔧 设置 HearthStone 拔线工具环境"
echo "=================================="

# 提示用户输入密码
echo "请输入你的系统密码（用于 sudo 权限）:"
read -s password

# 设置环境变量
export PASSWD="$password"

echo ""
echo "✅ 密码环境变量已设置"

# 测试 Little Snitch 命令行工具权限
echo "🔍 测试 Little Snitch 命令行工具权限..."
export PATH="/Applications/Little Snitch.app/Contents/Components:$PATH"
echo "$password" | sudo -S littlesnitch --version

if [ $? -eq 0 ]; then
    echo "✅ Little Snitch 命令行工具权限正常"
else
    echo "❌ Little Snitch 命令行工具权限有问题"
    echo "📝 请检查 Little Snitch.app > Preferences > Security > Enable command line access"
    exit 1
fi

# 启动应用
echo ""
echo "🚀 启动 HearthStone 拔线工具..."
echo "环境变量 PASSWD 已设置，可以使用拔线功能"

# 在同一个shell中启动应用，这样环境变量会被传递
open "/Users/tyrion/Library/Developer/Xcode/DerivedData/HearthstoneTool-avhmokvswyyveedajgzfbtfkvwfp/Build/Products/Debug/HearthstoneTool.app"

echo ""
echo "🎉 设置完成！现在可以使用拔线功能了"
echo "注意：关闭终端后需要重新运行此脚本"