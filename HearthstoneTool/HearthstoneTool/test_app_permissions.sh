#!/bin/bash
# 测试 App 权限问题

echo "🧪 测试 App 权限设置"
echo "==================="

# 1. 获取 sudo 权限
echo "1. 获取 sudo 权限..."
sudo -v

if [ $? -ne 0 ]; then
    echo "❌ 获取 sudo 权限失败"
    exit 1
fi

echo "✅ sudo 权限已获取"

# 2. 创建配置文件（模拟 App 行为）
echo "2. 创建配置文件..."
sudo bash -c 'echo "block all" > /tmp/hs_unplug.conf'

if [ $? -eq 0 ]; then
    echo "✅ 配置文件创建成功"
else
    echo "❌ 配置文件创建失败"
    exit 1
fi

# 3. 启用防火墙（模拟 App 行为）
echo "3. 启用防火墙..."
sudo pfctl -f /tmp/hs_unplug.conf 2>/dev/null && sudo pfctl -e 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 防火墙启用成功"
else
    echo "❌ 防火墙启用失败"
    exit 1
fi

# 4. 测试网络
echo "4. 测试网络状态..."
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "   ⚠️  网络仍可访问"
else
    echo "   ✅ 网络已断开"
fi

# 5. 等待 3 秒
echo "5. 等待 3 秒..."
sleep 3

# 6. 恢复网络（模拟 App 行为）
echo "6. 恢复网络..."
sudo pfctl -d 2>/dev/null && sudo pfctl -f /etc/pf.conf 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 网络恢复成功"
else
    echo "❌ 网络恢复失败"
fi

# 7. 再次测试网络
echo "7. 再次测试网络..."
sleep 2
if ping -c 1 -W 3000 baidu.com > /dev/null 2>&1; then
    echo "   ✅ 网络已恢复"
else
    echo "   ⚠️  网络尚未恢复"
fi

echo ""
echo "🎉 测试完成！"
echo "现在可以在 5 分钟内使用 App 了"