#!/bin/bash
# 验证断网功能

CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"

echo "🧪 验证断网功能"
echo "================"

# 1. 启动一个持续的网络连接
echo "1. 启动持续网络连接..."
curl -s --max-time 30 https://httpbin.org/delay/20 > /dev/null &
curl_pid=$!
echo "   启动 curl 进程 PID: $curl_pid"

# 等待连接建立
sleep 2

# 2. 检查连接
echo ""
echo "2. 检查当前连接..."
connections=$(curl -X GET "$CLASHX_API_URL/connections" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent 2>/dev/null)

connection_count=$(echo "$connections" | grep -o '"id"' | wc -l)
echo "   找到 $connection_count 个活动连接"

if [ $connection_count -gt 0 ]; then
    echo ""
    echo "3. 断开所有连接..."
    
    # 获取所有连接 ID 并断开
    connection_ids=$(echo "$connections" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    
    for id in $connection_ids; do
        echo "   断开连接: $id"
        curl -X DELETE "$CLASHX_API_URL/connections/$id" \
            -H "Authorization: Bearer $CLASHX_API_SECRET" \
            --silent > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "   ✅ 成功断开"
        else
            echo "   ❌ 断开失败"
        fi
    done
    
    echo ""
    echo "4. 验证结果..."
    sleep 1
    
    # 检查 curl 进程是否还在运行
    if kill -0 $curl_pid 2>/dev/null; then
        echo "   ⚠️  curl 进程仍在运行"
        kill $curl_pid 2>/dev/null
    else
        echo "   ✅ curl 进程已终止（连接被断开）"
    fi
    
    # 检查剩余连接
    new_connections=$(curl -X GET "$CLASHX_API_URL/connections" \
        -H "Authorization: Bearer $CLASHX_API_SECRET" \
        --silent 2>/dev/null)
    new_count=$(echo "$new_connections" | grep -o '"id"' | wc -l)
    echo "   剩余连接: $new_count 个"
    
else
    echo "   ⚠️ 没有找到活动连接，可能需要检查 ClashX 配置"
    kill $curl_pid 2>/dev/null
fi

echo ""
echo "🎉 验证完成！"