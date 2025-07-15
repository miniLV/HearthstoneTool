#!/bin/bash
# 调试防火墙断网效果

echo "🔍 调试防火墙断网效果"
echo "===================="

echo "1. 检查当前网络状态..."
if ping -c 1 -W 2000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络正常"
else
    echo "❌ 网络异常"
fi

echo ""
echo "2. 检查当前防火墙状态..."
sudo pfctl -s info 2>/dev/null | head -10

echo ""
echo "3. 启用防火墙断网..."
sudo pfctl -f /tmp/hs_unplug.conf 2>/dev/null
sudo pfctl -e 2>/dev/null

echo ""
echo "4. 检查防火墙状态..."
sudo pfctl -s info 2>/dev/null | head -10

echo ""
echo "5. 检查防火墙规则..."
sudo pfctl -s rules 2>/dev/null

echo ""
echo "6. 测试网络连接..."
echo "测试 baidu.com:"
if timeout 3 ping -c 1 baidu.com > /dev/null 2>&1; then
    echo "❌ 网络仍可访问 baidu.com"
else
    echo "✅ 无法访问 baidu.com"
fi

echo ""
echo "测试 google.com:"
if timeout 3 ping -c 1 google.com > /dev/null 2>&1; then
    echo "❌ 网络仍可访问 google.com"
else
    echo "✅ 无法访问 google.com"
fi

echo ""
echo "测试 127.0.0.1:"
if timeout 3 ping -c 1 127.0.0.1 > /dev/null 2>&1; then
    echo "✅ 本地回环正常"
else
    echo "❌ 本地回环被阻止"
fi

echo ""
echo "7. 等待 3 秒..."
sleep 3

echo ""
echo "8. 恢复网络..."
sudo pfctl -d 2>/dev/null
sudo pfctl -f /etc/pf.conf 2>/dev/null

echo ""
echo "9. 再次测试网络..."
if ping -c 1 -W 2000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络已恢复"
else
    echo "❌ 网络仍未恢复"
fi

echo ""
echo "🎉 调试完成！"