#!/bin/bash

echo "🔍 检查 Little Snitch 设置"
echo "=========================="

# 检查 Little Snitch 是否安装
if [ ! -f "/Applications/Little Snitch.app/Contents/Components/littlesnitch" ]; then
    echo "❌ Little Snitch 未安装或路径不正确"
    exit 1
fi

echo "✅ Little Snitch 已安装"

# 提示用户输入密码
echo "请输入你的系统密码："
read -s password

# 测试命令行工具权限
echo ""
echo "🔍 测试命令行工具权限..."
result=$(echo "$password" | sudo -S "/Applications/Little Snitch.app/Contents/Components/littlesnitch" --version 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ 命令行工具权限正常"
    echo "版本信息: $result"
else
    echo "❌ 命令行工具权限有问题"
    echo "错误信息: $result"
    echo ""
    echo "📝 解决方案："
    echo "1. 打开 Little Snitch.app"
    echo "2. 进入 Preferences > Security"
    echo "3. 启用 'Enable command line access'"
    exit 1
fi

# 测试 HearthStone 规则组
echo ""
echo "🔍 测试 HearthStone 规则组..."
result=$(echo "$password" | sudo -S "/Applications/Little Snitch.app/Contents/Components/littlesnitch" rulegroup -e HearthStone 2>&1)

if echo "$result" | grep -q "command line tool is not authorized"; then
    echo "❌ 命令行工具未授权"
    echo "📝 请在 Little Snitch.app > Preferences > Security 中启用命令行权限"
elif echo "$result" | grep -q "Unknown rule group"; then
    echo "⚠️ HearthStone 规则组不存在"
    echo "📝 请在 Little Snitch 中创建名为 'HearthStone' 的规则组"
    echo "📝 或者修改代码中的规则组名称为现有的规则组"
elif [ $? -eq 0 ]; then
    echo "✅ HearthStone 规则组测试成功"
else
    echo "❌ 测试失败"
    echo "错误信息: $result"
fi

echo ""
echo "🎉 检查完成！"