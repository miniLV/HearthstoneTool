#!/bin/bash
# 测试一次性执行完整的断网流程

echo "🧪 测试一次性断网流程"
echo "===================="

echo "将在一个权限提示中完成："
echo "1. 启用防火墙断网"
echo "2. 等待 8 秒"
echo "3. 恢复网络"
echo ""
echo "请输入管理员密码:"

result=$(osascript -e 'do shell script "pfctl -f /tmp/hs_unplug.conf 2>/dev/null && pfctl -e 2>/dev/null && echo \"disconnect_success\" && sleep 8 && pfctl -d 2>/dev/null && pfctl -f /etc/pf.conf 2>/dev/null && echo \"restore_success\"" with administrator privileges' 2>&1)

echo "执行结果:"
echo "$result"

if [[ "$result" == *"disconnect_success"* ]]; then
    echo "✅ 断网成功"
else
    echo "❌ 断网失败"
fi

if [[ "$result" == *"restore_success"* ]]; then
    echo "✅ 恢复成功"
else
    echo "❌ 恢复失败"
fi

echo ""
echo "🎉 测试完成！"
echo "如果两个操作都成功，说明只需要输入一次密码即可完成整个流程"