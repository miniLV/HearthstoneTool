#!/bin/bash

echo "🔍 测试和Python代码相同的命令格式"
echo "=================================="

# 提示用户输入密码
echo "请输入你的系统密码："
read -s password

# 设置PATH并测试命令
export PATH="/Applications/Little Snitch.app/Contents/Components:$PATH"

echo ""
echo "🔍 测试 littlesnitch 命令（添加到PATH后）..."
echo "$password" | sudo -S littlesnitch --version

if [ $? -eq 0 ]; then
    echo "✅ littlesnitch 命令可以正常使用"
else
    echo "❌ littlesnitch 命令有问题"
    exit 1
fi

echo ""
echo "🔍 测试 Hearthstone 规则组操作..."
result=$(echo "$password" | sudo -S littlesnitch rulegroup -e Hearthstone 2>&1)

echo "命令输出: $result"

if echo "$result" | grep -q "command line tool is not authorized"; then
    echo "❌ HearthStone 规则组操作失败"
    echo "⚠️ 命令行工具未授权"
    echo "📝 请打开 Little Snitch.app"
    echo "📝 进入 Settings > Security"
    echo "📝 勾选 'Allow access via Terminal' 选项"
elif echo "$result" | grep -q "not found"; then
    echo "❌ Hearthstone 规则组操作失败"
    echo "⚠️ Hearthstone 规则组不存在"
    echo "📝 请在 Little Snitch 应用中创建名为 'Hearthstone' 的规则组"
    echo "📝 或者运行 ./check_rule_groups.sh 查看现有规则组"
elif [ $? -eq 0 ]; then
    echo "✅ Hearthstone 规则组操作成功"
else
    echo "❌ Hearthstone 规则组操作失败"
    echo "原因未知，请检查输出"
fi

echo ""
echo "🎉 测试完成！"