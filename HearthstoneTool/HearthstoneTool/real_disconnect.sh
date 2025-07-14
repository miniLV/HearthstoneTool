#!/bin/bash
# HearthstoneTool 断网脚本 - 基于连接管理的真正断网
# 参考思路：删除特定应用的网络连接而非切换模式

# 配置参数
CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"

echo "🚀 启动真正的断网脚本"
echo "========================="

# 检查 ClashX Pro API 连接
check_api() {
    if curl -X GET "$CLASHX_API_URL/version" \
        -H "Authorization: Bearer $CLASHX_API_SECRET" \
        --connect-timeout 3 --silent > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 获取所有活动连接
get_connections() {
    curl -X GET "$CLASHX_API_URL/connections" \
        -H "Authorization: Bearer $CLASHX_API_SECRET" \
        --silent 2>/dev/null
}

# 删除指定连接
delete_connection() {
    local connection_id="$1"
    curl -X DELETE "$CLASHX_API_URL/connections/$connection_id" \
        -H "Authorization: Bearer $CLASHX_API_SECRET" \
        --silent > /dev/null 2>&1
}

echo "📡 检查 ClashX Pro API 连接..."
if ! check_api; then
    echo "❌ ClashX Pro API 连接失败"
    echo "请确保："
    echo "• ClashX Pro 已启动"
    echo "• API 端口: 53378"
    echo "• API Secret: daa-67P-sHH-Dvm"
    echo "• Allow control from lan: 已勾选"
    exit 1
fi

echo "✅ ClashX Pro API 连接成功"

# 方案1: 断开所有连接（最有效的断网方式）
echo ""
echo "🔌 方案1: 断开所有活动连接"
echo "获取当前连接列表..."

connections_json=$(get_connections)
if [[ -z "$connections_json" ]]; then
    echo "❌ 无法获取连接列表"
    exit 1
fi

# 使用 Python 来解析 JSON 并提取连接 ID
connection_ids=$(echo "$connections_json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    connections = data.get('connections', [])
    for conn in connections:
        print(conn.get('id', ''))
except:
    pass
")

if [[ -z "$connection_ids" ]]; then
    echo "📋 当前没有活动连接"
else
    connection_count=$(echo "$connection_ids" | wc -l | tr -d ' ')
    echo "📋 找到 $connection_count 个活动连接"
    
    echo "🔌 开始断开所有连接..."
    while IFS= read -r conn_id; do
        if [[ -n "$conn_id" ]]; then
            echo "   断开连接: $conn_id"
            delete_connection "$conn_id"
        fi
    done <<< "$connection_ids"
    
    echo "✅ 所有连接已断开"
fi

# 方案2: 临时切换到拒绝模式
echo ""
echo "🚫 方案2: 临时禁用所有代理规则"

# 检查当前模式
current_config=$(curl -X GET "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent 2>/dev/null)

current_mode=$(echo "$current_config" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('mode', 'unknown'))
except:
    print('unknown')
")

echo "📋 当前模式: $current_mode"

# 切换到 direct 模式（绕过所有代理规则）
echo "🔄 切换到 Direct 模式（绕过代理）..."
if curl -X PUT "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    -H "Content-Type: application/json" \
    -d '{"mode": "direct"}' \
    --silent > /dev/null 2>&1; then
    echo "✅ 已切换到 Direct 模式"
else
    echo "❌ 切换模式失败"
    exit 1
fi

# 方案3: 禁用系统代理（如果需要）
echo ""
echo "🌐 方案3: 临时禁用系统代理"

# 检查并保存当前系统代理状态
NETWORK_SERVICE="Wi-Fi"
echo "📋 检查系统代理状态..."

# 保存当前代理设置
HTTP_PROXY_ENABLED=$(networksetup -getwebproxy "$NETWORK_SERVICE" | grep "Enabled: Yes" || echo "")
HTTPS_PROXY_ENABLED=$(networksetup -getsecurewebproxy "$NETWORK_SERVICE" | grep "Enabled: Yes" || echo "")

if [[ -n "$HTTP_PROXY_ENABLED" || -n "$HTTPS_PROXY_ENABLED" ]]; then
    echo "💾 保存当前代理设置..."
    echo "HTTP_PROXY_ENABLED=$HTTP_PROXY_ENABLED" > /tmp/proxy_backup.txt
    echo "HTTPS_PROXY_ENABLED=$HTTPS_PROXY_ENABLED" >> /tmp/proxy_backup.txt
    
    echo "🔌 禁用系统代理..."
    networksetup -setwebproxystate "$NETWORK_SERVICE" off 2>/dev/null
    networksetup -setsecurewebproxystate "$NETWORK_SERVICE" off 2>/dev/null
    echo "✅ 系统代理已禁用"
    PROXY_DISABLED=true
else
    echo "📋 系统代理未启用，跳过"
    PROXY_DISABLED=false
fi

# 测试断网效果
echo ""
echo "🧪 测试断网效果..."
echo "尝试连接 www.baidu.com..."

if curl -m 3 "https://www.baidu.com" >/dev/null 2>&1; then
    echo "⚠️  网络仍然连通"
    echo "💡 这可能是因为："
    echo "   • 您的网络不依赖代理"
    echo "   • DNS 缓存"
    echo "   • 某些应用有独立的网络栈"
else
    echo "✅ 网络连接已断开！"
fi

# 倒计时
echo ""
echo "⏱️ 断网倒计时（5秒）："
for i in {5..1}; do
    echo "   $i 秒..."
    sleep 1
done

# 恢复网络连接
echo ""
echo "🔄 恢复网络连接..."

# 恢复 ClashX 模式
echo "📡 恢复 ClashX 模式..."
if curl -X PUT "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    -H "Content-Type: application/json" \
    -d "{\"mode\": \"$current_mode\"}" \
    --silent > /dev/null 2>&1; then
    echo "✅ 已恢复到 $current_mode 模式"
else
    echo "❌ 恢复模式失败"
fi

# 恢复系统代理
if [[ "$PROXY_DISABLED" == "true" ]]; then
    echo "🌐 恢复系统代理..."
    if [[ -f /tmp/proxy_backup.txt ]]; then
        source /tmp/proxy_backup.txt
        if [[ -n "$HTTP_PROXY_ENABLED" ]]; then
            networksetup -setwebproxystate "$NETWORK_SERVICE" on 2>/dev/null
        fi
        if [[ -n "$HTTPS_PROXY_ENABLED" ]]; then
            networksetup -setsecurewebproxystate "$NETWORK_SERVICE" on 2>/dev/null
        fi
        rm -f /tmp/proxy_backup.txt
        echo "✅ 系统代理已恢复"
    fi
fi

# 最终测试
echo ""
echo "🧪 最终网络测试..."
if curl -m 3 "https://www.baidu.com" >/dev/null 2>&1; then
    echo "✅ 网络连接已恢复正常"
else
    echo "⚠️  网络可能仍有问题，请检查设置"
fi

echo ""
echo "🎉 断网操作完成！"
echo "======================="
echo ""
echo "📊 操作总结："
echo "• 断开了所有活动的网络连接"
echo "• 临时切换到 Direct 模式"
echo "• 临时禁用了系统代理（如果启用）"
echo "• 等待 5 秒后自动恢复"
echo ""
echo "💡 如果仍然无法断网，可能是因为："
echo "• 应用使用了独立的网络栈"
echo "• 系统网络不依赖代理"
echo "• 需要管理员权限来修改网络设置"
