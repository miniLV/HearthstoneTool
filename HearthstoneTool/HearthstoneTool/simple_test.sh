#!/bin/bash
# 简单测试 osascript 权限获取

echo "🧪 测试 osascript 权限获取"
echo "========================"

echo "1. 测试防火墙启用..."
result=$(osascript -e 'do shell script "pfctl -f /tmp/hs_unplug.conf 2>/dev/null && pfctl -e 2>/dev/null; echo success" with administrator privileges' 2>&1)
echo "结果: $result"

if [[ "$result" == *"success"* ]]; then
    echo "✅ 防火墙启用成功"
    
    echo "2. 等待 3 秒..."
    sleep 3
    
    echo "3. 测试防火墙关闭..."
    result2=$(osascript -e 'do shell script "pfctl -d 2>/dev/null && pfctl -f /etc/pf.conf 2>/dev/null; echo success" with administrator privileges' 2>&1)
    echo "结果: $result2"
    
    if [[ "$result2" == *"success"* ]]; then
        echo "✅ 防火墙关闭成功"
        echo "🎉 测试完成！osascript 方式可以正常工作"
    else
        echo "❌ 防火墙关闭失败"
    fi
else
    echo "❌ 防火墙启用失败"
fi