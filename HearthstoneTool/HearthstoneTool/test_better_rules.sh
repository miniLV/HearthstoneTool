#!/bin/bash
# 测试更有效的防火墙规则

echo "🧪 测试更有效的防火墙规则"
echo "=========================="

echo "1. 创建更精确的防火墙规则..."
sudo tee /tmp/hs_better_rules.conf > /dev/null << 'EOF'
# 阻止所有出站连接
block out all
# 阻止所有入站连接
block in all
# 允许本地回环
pass on lo0 all
EOF

echo "✅ 规则文件已创建"
echo ""
echo "规则内容:"
cat /tmp/hs_better_rules.conf

echo ""
echo "2. 测试当前网络..."
if ping -c 1 -W 2000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络正常"
else
    echo "❌ 网络异常"
fi

echo ""
echo "3. 应用新规则..."
sudo pfctl -f /tmp/hs_better_rules.conf 2>/dev/null
sudo pfctl -e 2>/dev/null

echo ""
echo "4. 检查防火墙状态..."
sudo pfctl -s info 2>/dev/null | head -5

echo ""
echo "5. 检查规则..."
echo "当前规则:"
sudo pfctl -s rules 2>/dev/null

echo ""
echo "6. 测试网络连接..."
echo "测试外部网络:"
if timeout 3 ping -c 1 baidu.com > /dev/null 2>&1; then
    echo "❌ 仍可访问外部网络"
else
    echo "✅ 外部网络被阻止"
fi

echo ""
echo "测试本地回环:"
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
echo "9. 验证恢复..."
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络已恢复"
else
    echo "❌ 网络仍未恢复"
fi

echo ""
echo "🎉 测试完成！"
echo ""
echo "如果看到 '✅ 外部网络被阻止' 说明新规则有效"