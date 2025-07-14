#!/bin/bash
# 测试 WiFi 控制功能

echo "🧪 测试 WiFi 控制功能"
echo "===================="

# 1. 检查当前 WiFi 状态
echo "1. 检查当前 WiFi 状态..."
current_status=$(networksetup -getairportpower en0)
echo "   当前状态: $current_status"

# 2. 关闭 WiFi
echo ""
echo "2. 关闭 WiFi..."
networksetup -setairportpower en0 off
if [ $? -eq 0 ]; then
    echo "   ✅ 成功关闭 WiFi"
else
    echo "   ❌ 关闭 WiFi 失败"
    exit 1
fi

# 3. 验证 WiFi 已关闭
echo ""
echo "3. 验证 WiFi 状态..."
off_status=$(networksetup -getairportpower en0)
echo "   关闭后状态: $off_status"

# 4. 测试网络连接
echo ""
echo "4. 测试网络连接..."
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "   ⚠️  网络仍可访问（可能有其他网络连接）"
else
    echo "   ✅ 网络已断开"
fi

# 5. 等待 3 秒
echo ""
echo "5. 等待 6 秒..."
sleep 6

# 6. 重新开启 WiFi
echo ""
echo "6. 重新开启 WiFi..."
networksetup -setairportpower en0 on
if [ $? -eq 0 ]; then
    echo "   ✅ 成功开启 WiFi"
else
    echo "   ❌ 开启 WiFi 失败"
    exit 1
fi

# 7. 验证 WiFi 已开启
echo ""
echo "7. 验证 WiFi 状态..."
on_status=$(networksetup -getairportpower en0)
echo "   开启后状态: $on_status"

# 8. 等待网络恢复
echo ""
echo "8. 等待网络恢复..."
sleep 5

# 9. 测试网络连接
echo ""
echo "9. 测试网络连接..."
if ping -c 1 -W 5000 baidu.com > /dev/null 2>&1; then
    echo "   ✅ 网络已恢复"
else
    echo "   ⚠️  网络尚未恢复（可能需要更多时间）"
fi

echo ""
echo "🎉 测试完成！"
