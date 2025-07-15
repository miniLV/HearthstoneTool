#!/bin/bash

echo "🔍 检查 Little Snitch 现有规则组"
echo "==============================="

# 提示用户输入密码
echo "请输入你的系统密码："
read -s password

# 设置PATH
export PATH="/Applications/Little Snitch.app/Contents/Components:$PATH"

echo ""
echo "🔍 获取所有规则组信息..."

# 尝试导出配置信息
echo "$password" | sudo -S littlesnitch export-model > /tmp/littlesnitch_export.json 2>&1

if [ $? -eq 0 ]; then
    echo "✅ 成功导出 Little Snitch 配置"
    echo ""
    echo "📄 搜索规则组..."
    
    # 从导出的JSON中提取规则组信息
    if command -v jq >/dev/null 2>&1; then
        echo "使用 jq 解析规则组："
        jq -r '.ruleGroups[] | select(.name != null) | .name' /tmp/littlesnitch_export.json 2>/dev/null
    else
        echo "搜索规则组名称（使用 grep）："
        grep -o '"name":"[^"]*"' /tmp/littlesnitch_export.json | grep -o '"[^"]*"$' | sort -u
    fi
    
    echo ""
    echo "📝 如果没有找到 HearthStone 规则组，你可以："
    echo "1. 在 Little Snitch 应用中手动创建一个名为 'HearthStone' 的规则组"
    echo "2. 或者使用现有的规则组（修改代码中的规则组名称）"
    
    # 清理临时文件
    rm -f /tmp/littlesnitch_export.json
else
    echo "❌ 无法导出 Little Snitch 配置"
    echo "请确保已启用命令行权限"
fi

echo ""
echo "🎉 检查完成！"