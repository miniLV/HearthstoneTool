#!/bin/bash
# 测试强制网络恢复

echo "🧪 测试强制网络恢复"
echo "=================="

echo "1. 测试当前网络..."
if ping -c 1 -W 2000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络正常"
else
    echo "❌ 网络异常"
fi

echo ""
echo "2. 应用防火墙规则并强制恢复..."

result=$(osascript -e '
do shell script "
# 应用防火墙规则
pfctl -f /tmp/hs_better_rules.conf 2>/dev/null && pfctl -e 2>/dev/null && echo \"firewall_enabled\"

# 测试断网
if timeout 2 ping -c 1 baidu.com > /dev/null 2>&1; then
    echo \"still_connected\"
else
    echo \"disconnected\"
fi

# 等待3秒
sleep 3

# 强制恢复网络 - 多种方法
pfctl -d 2>/dev/null && echo \"pfctl_disabled\"
pfctl -f /etc/pf.conf 2>/dev/null && echo \"default_config_loaded\"
pfctl -F all 2>/dev/null && echo \"rules_flushed\"

# 再次测试
if timeout 3 ping -c 1 baidu.com > /dev/null 2>&1; then
    echo \"network_restored\"
else
    echo \"still_blocked\"
fi
" with administrator privileges' 2>&1)

echo "执行结果:"
echo "$result"

echo ""
echo "3. 分析结果..."

if [[ "$result" == *"firewall_enabled"* ]]; then
    echo "✅ 防火墙规则应用成功"
fi

if [[ "$result" == *"disconnected"* ]]; then
    echo "✅ 网络成功断开"
else
    echo "❌ 网络未断开"
fi

if [[ "$result" == *"pfctl_disabled"* ]]; then
    echo "✅ pfctl 已禁用"
fi

if [[ "$result" == *"default_config_loaded"* ]]; then
    echo "✅ 默认配置已加载"
fi

if [[ "$result" == *"rules_flushed"* ]]; then
    echo "✅ 规则已清除"
fi

if [[ "$result" == *"network_restored"* ]]; then
    echo "✅ 网络已恢复"
else
    echo "❌ 网络仍被阻止"
fi

echo ""
echo "4. 最终验证..."
sleep 2
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "✅ 最终网络状态正常"
else
    echo "❌ 最终网络状态异常"
fi

echo ""
echo "🎉 测试完成！"