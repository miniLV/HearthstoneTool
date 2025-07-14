#!/bin/bash
# 设置 sudo 权限以便 App 可以使用 pfctl

echo "🔧 设置 sudo 权限"
echo "================"

echo "正在请求管理员权限..."
echo "请输入您的管理员密码:"

# 刷新 sudo 时间戳
sudo -v

if [ $? -eq 0 ]; then
    echo "✅ 管理员权限已获取"
    
    # 测试 pfctl 命令
    echo ""
    echo "测试 pfctl 命令..."
    
    # 创建测试配置文件
    echo "block all" > /tmp/hs_test.conf
    
    # 测试 pfctl 命令
    sudo pfctl -f /tmp/hs_test.conf 2>/dev/null
    sudo pfctl -e 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ pfctl 命令测试成功"
        
        # 立即恢复网络
        sudo pfctl -d 2>/dev/null
        sudo pfctl -f /etc/pf.conf 2>/dev/null
        rm -f /tmp/hs_test.conf 2>/dev/null
        
        echo "✅ 网络已恢复"
        echo ""
        echo "🎉 设置完成！现在可以运行 HearthstoneTool App 了"
        echo ""
        echo "注意: sudo 权限会在 5 分钟后过期，如果过期请重新运行此脚本"
        
    else
        echo "❌ pfctl 命令测试失败"
        echo "可能需要检查系统权限设置"
    fi
    
else
    echo "❌ 未能获取管理员权限"
    echo "请确保您有管理员权限"
fi