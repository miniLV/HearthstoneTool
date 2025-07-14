#!/bin/bash
# 测试 ClashX 断网功能

CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"

echo "🚀 测试 ClashX 断网功能"
echo "=========================="

# 1. 检查 API 连接
echo "1. 检查 ClashX API 连接..."
if curl -X GET "$CLASHX_API_URL/version" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --connect-timeout 3 --silent > /dev/null 2>&1; then
    echo "✅ ClashX API 连接成功"
else
    echo "❌ ClashX API 连接失败"
    exit 1
fi

# 2. 获取当前连接
echo ""
echo "2. 获取当前连接列表..."
connections=$(curl -X GET "$CLASHX_API_URL/connections" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent 2>/dev/null)

if [ $? -eq 0 ]; then
    connection_count=$(echo "$connections" | grep -o '"id"' | wc -l)
    echo "✅ 找到 $connection_count 个活动连接"
    
    # 显示连接详情
    echo ""
    echo "连接详情:"
    echo "$connections" | python3 -m json.tool 2>/dev/null | head -50
else
    echo "❌ 获取连接列表失败"
    exit 1
fi

# 3. 测试断开第一个连接
echo ""
echo "3. 测试断开连接..."
first_connection_id=$(echo "$connections" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$first_connection_id" ]; then
    echo "🎯 尝试断开连接: $first_connection_id"
    
    if curl -X DELETE "$CLASHX_API_URL/connections/$first_connection_id" \
        -H "Authorization: Bearer $CLASHX_API_SECRET" \
        --silent --connect-timeout 3 > /dev/null 2>&1; then
        echo "✅ 成功断开连接"
    else
        echo "❌ 断开连接失败"
    fi
else
    echo "⚠️ 没有找到可断开的连接"
fi

echo ""
echo "🎉 测试完成！"