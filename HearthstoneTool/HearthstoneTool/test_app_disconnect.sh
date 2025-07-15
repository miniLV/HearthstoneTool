#!/bin/bash
# 测试应用断网功能

echo "🧪 测试应用断网功能"
echo "=================="

echo "1. 创建更好的防火墙规则..."
# 创建新的防火墙规则文件
result=$(osascript -e '
do shell script "
echo \"# 阻止所有出站连接
block out all
# 阻止所有入站连接
block in all
# 允许本地回环
pass on lo0 all\" > /tmp/hs_better_rules.conf

echo \"config_created\"
" with administrator privileges' 2>&1)

if [[ "$result" == *"config_created"* ]]; then
    echo "✅ 配置文件创建成功"
else
    echo "❌ 配置文件创建失败: $result"
    exit 1
fi

echo ""
echo "2. 查看配置文件内容..."
cat /tmp/hs_better_rules.conf

echo ""
echo "3. 测试完整的断网流程（模拟应用行为）..."
echo "   - 断网8秒"
echo "   - 自动恢复"
echo ""

# 模拟应用的完整断网流程
result=$(osascript -e '
do shell script "
# 应用新规则
pfctl -f /tmp/hs_better_rules.conf 2>/dev/null && pfctl -e 2>/dev/null && echo \"disconnect_success\" 

# 测试网络状态
if timeout 2 ping -c 1 baidu.com > /dev/null 2>&1; then
    echo \"external_still_accessible\"
else
    echo \"external_blocked\"
fi

# 等待8秒
sleep 8

# 恢复网络
pfctl -d 2>/dev/null && pfctl -f /etc/pf.conf 2>/dev/null && echo \"restore_success\"

# 验证恢复
if timeout 3 ping -c 1 baidu.com > /dev/null 2>&1; then
    echo \"external_restored\"
else
    echo \"external_still_blocked\"
fi
" with administrator privileges' 2>&1)

echo "执行结果:"
echo "$result"

echo ""
echo "4. 分析结果..."

if [[ "$result" == *"disconnect_success"* ]]; then
    echo "✅ 断网规则应用成功"
else
    echo "❌ 断网规则应用失败"
fi

if [[ "$result" == *"external_blocked"* ]]; then
    echo "✅ 外部网络被成功阻止"
    echo "   🎯 这表明断网功能有效！"
else
    echo "❌ 外部网络仍可访问"
    echo "   ⚠️ 断网功能可能无效"
fi

if [[ "$result" == *"restore_success"* ]]; then
    echo "✅ 网络恢复成功"
else
    echo "❌ 网络恢复失败"
fi

if [[ "$result" == *"external_restored"* ]]; then
    echo "✅ 外部网络恢复正常"
else
    echo "❌ 外部网络仍被阻止"
fi

echo ""
echo "5. 最终验证..."
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络完全恢复正常"
else
    echo "❌ 网络仍有问题"
fi

echo ""
echo "🎉 测试完成！"
echo ""
if [[ "$result" == *"external_blocked"* && "$result" == *"external_restored"* ]]; then
    echo "🎯 结论: 新的防火墙规则有效，应用断网功能应该能正常工作！"
    echo "炉石传说应该会在8秒断网期间自动重连。"
else
    echo "⚠️ 结论: 防火墙规则可能仍需要调整"
fi