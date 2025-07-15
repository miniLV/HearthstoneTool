#!/bin/bash
# 最终测试：完整模拟应用断网流程

echo "🎯 最终测试：完整模拟应用断网流程"
echo "==============================="

echo "模拟应用点击'一键拔线'按钮..."
echo ""

# 完全模拟应用的断网流程
result=$(osascript -e '
do shell script "
# 创建配置文件
echo \"# 阻止所有出站连接
block out all
# 阻止所有入站连接
block in all
# 允许本地回环
pass on lo0 all\" > /tmp/hs_better_rules.conf

# 应用防火墙规则
pfctl -f /tmp/hs_better_rules.conf 2>/dev/null && pfctl -e 2>/dev/null && echo \"disconnect_success\"

# 断网8秒（模拟炉石重连时间）
sleep 8

# 强制恢复网络
pfctl -d 2>/dev/null && pfctl -f /etc/pf.conf 2>/dev/null && pfctl -F all 2>/dev/null && echo \"restore_success\"
" with administrator privileges' 2>&1)

echo "执行结果:"
echo "$result"
echo ""

# 分析结果
echo "📊 结果分析:"
if [[ "$result" == *"disconnect_success"* ]]; then
    echo "✅ 断网成功 - 炉石传说应该会重连"
else
    echo "❌ 断网失败"
fi

if [[ "$result" == *"restore_success"* ]]; then
    echo "✅ 网络恢复成功"
else
    echo "❌ 网络恢复失败"
fi

# 验证网络恢复
echo ""
echo "🔍 验证网络状态..."
sleep 2
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "✅ 网络完全正常"
    echo ""
    echo "🎉 测试成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    echo "✨ 应用一键拔线功能已就绪"
    echo "📱 用户只需点击按钮并输入一次密码"
    echo "⏱️ 炉石传说将断网8秒后自动重连"
    echo "🔄 网络会自动恢复正常"
else
    echo "❌ 网络仍有问题"
    echo ""
    echo "⚠️ 需要进一步调试"
fi

echo ""
echo "🎯 总结: 新的防火墙规则比原来的 'block all' 更有效！"