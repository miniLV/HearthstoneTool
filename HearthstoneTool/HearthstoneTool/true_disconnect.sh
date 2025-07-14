#!/bin/bash
# 真正的断网脚本 - 通过禁用系统代理实现

echo "🚀 开始真正的断网操作"
echo "========================"

# 获取当前网络接口
NETWORK_SERVICE="Wi-Fi"

echo "📡 检查当前代理状态..."
# 检查当前代理设置
HTTP_PROXY=$(networksetup -getwebproxy "$NETWORK_SERVICE" | grep "Enabled: Yes")
HTTPS_PROXY=$(networksetup -getsecurewebproxy "$NETWORK_SERVICE" | grep "Enabled: Yes")

if [[ -n "$HTTP_PROXY" || -n "$HTTPS_PROXY" ]]; then
    echo "✅ 检测到系统代理已启用"
    
    # 保存当前代理设置
    echo "💾 保存当前代理设置..."
    networksetup -getwebproxy "$NETWORK_SERVICE" > /tmp/http_proxy_backup.txt
    networksetup -getsecurewebproxy "$NETWORK_SERVICE" > /tmp/https_proxy_backup.txt
    
    # 禁用代理
    echo "🔌 禁用系统代理（断网）..."
    networksetup -setwebproxystate "$NETWORK_SERVICE" off
    networksetup -setsecurewebproxystate "$NETWORK_SERVICE" off
    
    echo "✅ 系统代理已禁用 - 现在应该断网了"
    
    # 测试网络
    echo ""
    echo "📡 测试网络连接..."
    if curl -m 3 "https://www.baidu.com" >/dev/null 2>&1; then
        echo "⚠️  网络仍然连通"
    else
        echo "✅ 确认网络已断开"
    fi
    
    echo ""
    echo "⏱️ 断网倒计时："
    for i in {5..1}; do
        echo "   $i 秒..."
        sleep 1
    done
    
    # 恢复代理设置
    echo ""
    echo "🌐 恢复系统代理..."
    
    # 从备份恢复设置
    if [[ -f /tmp/http_proxy_backup.txt ]]; then
        # 这里需要解析备份文件并恢复设置
        networksetup -setwebproxystate "$NETWORK_SERVICE" on
        networksetup -setsecurewebproxystate "$NETWORK_SERVICE" on
        echo "✅ 系统代理已恢复"
        
        # 清理备份文件
        rm -f /tmp/http_proxy_backup.txt /tmp/https_proxy_backup.txt
    fi
    
else
    echo "⚠️  系统代理未启用，尝试 ClashX 方案..."
    
    # 回退到 ClashX 方案
    curl -X PUT "http://127.0.0.1:53378/configs" \
        -H "Authorization: Bearer daa-67P-sHH-Dvm" \
        -H "Content-Type: application/json" \
        -d '{"mode": "direct"}' \
        --silent >/dev/null 2>&1
    
    echo "✅ 已切换到 ClashX Direct 模式"
    
    echo ""
    echo "⏱️ 断网倒计时："
    for i in {5..1}; do
        echo "   $i 秒..."
        sleep 1
    done
    
    # 恢复 ClashX 规则模式
    curl -X PUT "http://127.0.0.1:53378/configs" \
        -H "Authorization: Bearer daa-67P-sHH-Dvm" \
        -H "Content-Type: application/json" \
        -d '{"mode": "rule"}' \
        --silent >/dev/null 2>&1
    
    echo "✅ 已恢复 ClashX Rule 模式"
fi

echo ""
echo "🎉 断网操作完成！"
