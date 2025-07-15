#!/bin/bash
# 测试更有效的防火墙规则（GUI版本）

echo "🧪 测试更有效的防火墙规则（GUI）"
echo "================================"

# 测试当前网络
echo "1. 测试当前网络..."
if ping -c 1 -W 2000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络正常"
else
    echo "❌ 网络异常"
fi

echo ""
echo "2. 使用 osascript 执行测试..."

# 使用 osascript 执行完整的测试流程
result=$(osascript -e '
do shell script "
# 创建更精确的防火墙规则
echo \"# 阻止所有出站连接
block out all
# 阻止所有入站连接
block in all
# 允许本地回环
pass on lo0 all\" > /tmp/hs_better_rules.conf

# 应用新规则
pfctl -f /tmp/hs_better_rules.conf 2>/dev/null
pfctl -e 2>/dev/null

echo \"rules_applied\"

# 测试网络连接（使用 timeout 限制时间）
if timeout 3 ping -c 1 baidu.com > /dev/null 2>&1; then
    echo \"external_accessible\"
else
    echo \"external_blocked\"
fi

# 测试本地回环
if timeout 3 ping -c 1 127.0.0.1 > /dev/null 2>&1; then
    echo \"localhost_accessible\"
else
    echo \"localhost_blocked\"
fi

# 等待 3 秒
sleep 3

# 恢复网络
pfctl -d 2>/dev/null
pfctl -f /etc/pf.conf 2>/dev/null

echo \"network_restored\"
" with administrator privileges' 2>&1)

echo "执行结果:"
echo "$result"

echo ""
echo "3. 分析结果..."

if [[ "$result" == *"rules_applied"* ]]; then
    echo "✅ 规则应用成功"
else
    echo "❌ 规则应用失败"
fi

if [[ "$result" == *"external_blocked"* ]]; then
    echo "✅ 外部网络被成功阻止"
else
    echo "❌ 外部网络仍可访问"
fi

if [[ "$result" == *"localhost_accessible"* ]]; then
    echo "✅ 本地回环正常"
else
    echo "❌ 本地回环被阻止"
fi

if [[ "$result" == *"network_restored"* ]]; then
    echo "✅ 网络恢复成功"
else
    echo "❌ 网络恢复失败"
fi

echo ""
echo "4. 最终验证网络恢复..."
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络已完全恢复"
else
    echo "❌ 网络仍未恢复"
fi

echo ""
echo "🎉 测试完成！"
echo ""
echo "如果看到 '✅ 外部网络被成功阻止' 说明新规则比旧规则更有效"