#!/bin/bash
# 修复 ClashX 代理问题

echo "🔧 修复 ClashX 代理设置"
echo "====================="

# 1. 关闭系统代理
echo "1. 关闭系统代理..."
networksetup -setwebproxystate Wi-Fi off
networksetup -setsecurewebproxystate Wi-Fi off

# 2. 重新启用系统代理
echo "2. 重新启用系统代理..."
networksetup -setwebproxy Wi-Fi 127.0.0.1 7890
networksetup -setsecurewebproxy Wi-Fi 127.0.0.1 7890
networksetup -setwebproxystate Wi-Fi on
networksetup -setsecurewebproxystate Wi-Fi on

# 3. 验证设置
echo "3. 验证代理设置..."
echo "HTTP 代理:"
networksetup -getwebproxy Wi-Fi
echo ""
echo "HTTPS 代理:"
networksetup -getsecurewebproxy Wi-Fi

echo ""
echo "4. 测试代理连接..."
sleep 2

# 启动测试请求
curl -s https://httpbin.org/delay/2 > /dev/null &
sleep 1

# 检查 ClashX 连接
connections=$(curl -X GET "http://127.0.0.1:53378/connections" \
    -H "Authorization: Bearer daa-67P-sHH-Dvm" \
    --silent 2>/dev/null)

if [ $? -eq 0 ]; then
    connection_count=$(echo "$connections" | grep -o '"id"' | wc -l)
    echo "✅ 找到 $connection_count 个活动连接"
    
    if [ $connection_count -gt 0 ]; then
        echo "🎉 ClashX 代理工作正常！"
    else
        echo "⚠️ 仍然没有连接，可能需要重启 ClashX"
    fi
else
    echo "❌ 无法连接到 ClashX API"
fi

echo ""
echo "🎉 修复完成！"