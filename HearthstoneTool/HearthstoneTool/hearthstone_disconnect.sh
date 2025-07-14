#!/bin/bash
# 精确的炉石传说断网脚本 - 只断开特定连接

# 配置参数
CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"

echo "🎯 炉石传说精确断网脚本"
echo "========================="

# 检查 ClashX Pro API 连接
check_api() {
    curl -X GET "$CLASHX_API_URL/version" \
        -H "Authorization: Bearer $CLASHX_API_SECRET" \
        --connect-timeout 3 --silent > /dev/null 2>&1
}

echo "📡 检查 ClashX Pro API 连接..."
if ! check_api; then
    echo "❌ ClashX Pro API 连接失败"
    exit 1
fi
echo "✅ ClashX Pro API 连接成功"

# 获取所有连接
echo ""
echo "🔍 获取当前连接列表..."
connections_json=$(curl -X GET "$CLASHX_API_URL/connections" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent 2>/dev/null)

if [[ -z "$connections_json" ]]; then
    echo "❌ 无法获取连接列表"
    exit 1
fi

# 使用 Python 查找炉石传说的特定连接
target_connection=$(echo "$connections_json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    connections = data.get('connections', [])
    print(f'📋 检查 {len(connections)} 个连接...', file=sys.stderr)
    
    for conn in connections:
        metadata = conn.get('metadata', {})
        process_path = metadata.get('processPath', '')
        host = metadata.get('host', '')
        conn_id = conn.get('id', '')
        
        print(f'🔍 检查连接: {conn_id}', file=sys.stderr)
        print(f'   processPath: {process_path}', file=sys.stderr)
        print(f'   host: \"{host}\"', file=sys.stderr)
        
        # 匹配炉石传说进程路径和空 host
        if process_path == '/Applications/Hearthstone/Hearthstone.app/Contents/MacOS/Hearthstone' and host == '':
            print(f'🎯 找到目标连接: {conn_id}', file=sys.stderr)
            print(conn_id)
            break
    else:
        print('⚠️ 未找到炉石传说的目标连接', file=sys.stderr)
except Exception as e:
    print(f'❌ 解析连接失败: {e}', file=sys.stderr)
")

if [[ -z "$target_connection" ]]; then
    echo "⚠️ 未找到炉石传说的目标连接"
    echo "💡 可能的原因："
    echo "• 炉石传说未运行"
    echo "• 炉石传说没有网络连接"
    echo "• 进程路径不匹配"
    exit 1
fi

echo "🎯 找到目标连接: $target_connection"

# 断开特定连接
echo ""
echo "🔌 断开炉石传说连接..."
if curl -X DELETE "$CLASHX_API_URL/connections/$target_connection" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent > /dev/null 2>&1; then
    echo "✅ 成功断开炉石传说连接"
else
    echo "❌ 断开连接失败"
    exit 1
fi

echo ""
echo "⏱️ 等待 5 秒..."
for i in {5..1}; do
    echo "   $i 秒..."
    sleep 1
done

echo ""
echo "🎉 炉石传说断网操作完成！"
echo "=========================="
echo ""
echo "📊 操作总结："
echo "• 精确查找炉石传说的网络连接"
echo "• 只断开了炉石传说的特定连接"
echo "• 不影响其他应用的网络连接"
echo ""
echo "💡 说明："
echo "• 这种方法只会断开炉石传说的网络连接"
echo "• 其他应用的网络连接保持正常"
echo "• 炉石传说需要重新连接服务器"
