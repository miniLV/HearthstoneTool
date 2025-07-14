#!/bin/bash
# 调试 App 问题

echo "🐛 调试 App 问题"
echo "==============="

# 1. 检查配置文件
echo "1. 检查配置文件..."
if [ -f "/tmp/hs_unplug.conf" ]; then
    echo "✅ 配置文件存在"
    echo "📄 内容: $(cat /tmp/hs_unplug.conf)"
else
    echo "❌ 配置文件不存在"
    echo "创建配置文件..."
    echo "block all" > /tmp/hs_unplug.conf
    echo "✅ 配置文件已创建"
fi

# 2. 检查 sudo 权限
echo ""
echo "2. 检查 sudo 权限..."
if sudo -n echo "sudo test" 2>/dev/null; then
    echo "✅ sudo 权限可用"
else
    echo "❌ sudo 权限不可用"
    echo "获取 sudo 权限..."
    sudo -v
    if [ $? -eq 0 ]; then
        echo "✅ sudo 权限已获取"
    else
        echo "❌ sudo 权限获取失败"
        exit 1
    fi
fi

# 3. 测试 pfctl 命令
echo ""
echo "3. 测试 pfctl 命令..."
echo "启用防火墙..."
sudo pfctl -f /tmp/hs_unplug.conf 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 防火墙启用成功"
else
    echo "❌ 防火墙启用失败"
fi

sudo pfctl -e 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 防火墙已启用"
else
    echo "❌ 防火墙启用失败"
fi

# 4. 立即恢复
echo ""
echo "4. 恢复网络..."
sudo pfctl -d 2>&1
sudo pfctl -f /etc/pf.conf 2>&1
echo "✅ 网络已恢复"

echo ""
echo "🎉 调试完成！"
echo "现在可以使用 App 了"
echo ""
echo "使用方法："
echo "1. 确保在 5 分钟内使用 App"
echo "2. 查看 Xcode 控制台的日志输出"
echo "3. 如果还是不行，请检查 Xcode 的 Capabilities 设置"