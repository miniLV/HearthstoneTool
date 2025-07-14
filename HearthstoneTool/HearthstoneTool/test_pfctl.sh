#!/bin/bash
# 测试 pfctl 防火墙断网功能

echo "🧪 测试 pfctl 防火墙断网功能"
echo "============================"

# 检查是否有 root 权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 需要 root 权限运行此脚本"
    echo "请使用: sudo ./test_pfctl.sh"
    exit 1
fi

# 1. 检查当前网络连接
echo "1. 检查当前网络连接..."
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "   ✅ 网络连接正常"
else
    echo "   ❌ 网络连接异常"
    exit 1
fi

# 2. 启用防火墙断网
echo ""
echo "2. 启用防火墙断网..."
echo "block all" > /tmp/hs_unplug.conf
pfctl -f /tmp/hs_unplug.conf 2>/dev/null
pfctl -e 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ 防火墙断网规则已启用"
else
    echo "   ❌ 启用防火墙断网规则失败"
    exit 1
fi

# 3. 验证网络已断开
echo ""
echo "3. 验证网络状态..."
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "   ⚠️  网络仍可访问（防火墙规则可能未生效）"
else
    echo "   ✅ 网络已断开"
fi

# 4. 等待 5 秒
echo ""
echo "4. 等待 5 秒..."
sleep 5

# 5. 关闭防火墙断网
echo ""
echo "5. 关闭防火墙断网..."
pfctl -d 2>/dev/null
pfctl -f /etc/pf.conf 2>/dev/null
rm -f /tmp/hs_unplug.conf 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ 防火墙断网规则已关闭"
else
    echo "   ❌ 关闭防火墙断网规则失败"
fi

# 6. 等待网络恢复
echo ""
echo "6. 等待网络恢复..."
sleep 3

# 7. 验证网络已恢复
echo ""
echo "7. 验证网络状态..."
if ping -c 1 -W 5000 baidu.com > /dev/null 2>&1; then
    echo "   ✅ 网络已恢复"
else
    echo "   ⚠️  网络尚未恢复（可能需要更多时间）"
fi

echo ""
echo "🎉 测试完成！"