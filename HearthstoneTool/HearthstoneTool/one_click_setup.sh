#!/bin/bash
# 一键设置权限并测试 pfctl 功能

echo "🚀 一键设置炉石传说断网工具"
echo "=========================="

echo "请输入您的管理员密码以完成设置："

# 设置 sudo 权限
sudo -v

if [ $? -ne 0 ]; then
    echo "❌ 未能获取管理员权限，设置失败"
    exit 1
fi

echo "✅ 管理员权限已获取"

# 创建防火墙规则文件
echo "正在创建防火墙规则..."
sudo bash -c 'echo "block all" > /tmp/hs_unplug.conf'

if [ $? -eq 0 ]; then
    echo "✅ 防火墙规则文件创建成功"
else
    echo "❌ 防火墙规则文件创建失败"
    exit 1
fi

# 测试防火墙启用
echo "测试防火墙启用..."
sudo pfctl -f /tmp/hs_unplug.conf 2>/dev/null
sudo pfctl -e 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 防火墙启用测试成功"
    
    # 立即恢复网络
    echo "恢复网络连接..."
    sudo pfctl -d 2>/dev/null
    sudo pfctl -f /etc/pf.conf 2>/dev/null
    
    echo "✅ 网络已恢复"
else
    echo "❌ 防火墙启用测试失败"
    exit 1
fi

# 创建便捷脚本
echo "创建便捷脚本..."
cat > /tmp/hs_disconnect.sh << 'EOF'
#!/bin/bash
# 炉石传说断网脚本

echo "🔥 启动防火墙断网..."
sudo pfctl -f /tmp/hs_unplug.conf 2>/dev/null && sudo pfctl -e 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 断网成功，等待 8 秒..."
    sleep 8
    
    echo "🌐 恢复网络连接..."
    sudo pfctl -d 2>/dev/null && sudo pfctl -f /etc/pf.conf 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ 网络已恢复"
        echo "🎉 断网操作完成！"
    else
        echo "❌ 网络恢复失败"
    fi
else
    echo "❌ 断网失败"
fi
EOF

chmod +x /tmp/hs_disconnect.sh

echo ""
echo "🎉 设置完成！"
echo ""
echo "使用方法："
echo "1. 运行 HearthstoneTool App"
echo "2. 或者直接运行: /tmp/hs_disconnect.sh"
echo ""
echo "注意: sudo 权限在 5 分钟后过期，过期后需要重新运行此脚本"