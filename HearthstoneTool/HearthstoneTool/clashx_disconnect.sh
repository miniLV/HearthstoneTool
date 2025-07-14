#!/bin/bash
# ClashX 自动断网脚本 - 通过 API 控制 ClashX

# 配置参数
CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"  # ClashX Pro API Secret
MAX_RETRY=3
RETRY_DELAY=2

# 检查 ClashX 或 ClashX Pro 是否正在运行
check_clashx_running() {
    if pgrep -x "ClashX Pro" > /dev/null; then
        echo "✓ ClashX Pro 进程正在运行"
        return 0
    elif pgrep -x "ClashX" > /dev/null; then
        echo "✓ ClashX 进程正在运行"
        return 0
    else
        echo "✗ ClashX/ClashX Pro 进程未运行"
        return 1
    fi
}

# 尝试启动 ClashX 或 ClashX Pro
start_clashx() {
    echo "尝试启动 ClashX Pro..."
    if open -a "ClashX Pro" 2>/dev/null; then
        echo "正在启动 ClashX Pro..."
    else
        echo "ClashX Pro 未找到，尝试启动 ClashX..."
        open -a ClashX
    fi
    sleep 3
}

# 检查 ClashX API 是否可用
check_api_connection() {
    local headers=""
    if [ -n "$CLASHX_API_SECRET" ]; then
        headers="-H 'Authorization: Bearer $CLASHX_API_SECRET'"
    fi
    
    if eval "curl -X GET '$CLASHX_API_URL/version' $headers --connect-timeout 3 --silent" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 主要的连接检查逻辑
echo "检查 ClashX 状态..."

# 检查进程是否运行
if ! check_clashx_running; then
    echo "尝试启动 ClashX..."
    start_clashx
    if ! check_clashx_running; then
        echo "错误: 无法启动 ClashX，请手动启动"
        exit 1
    fi
fi

# 检查 API 连接，带重试机制
echo "检查 ClashX API 连接..."
retry_count=0
while [ $retry_count -lt $MAX_RETRY ]; do
    if check_api_connection; then
        echo "✓ ClashX API 连接成功"
        break
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRY ]; then
            echo "API 连接失败，${RETRY_DELAY}秒后重试... ($retry_count/$MAX_RETRY)"
            sleep $RETRY_DELAY
        fi
    fi
done

if [ $retry_count -ge $MAX_RETRY ]; then
    echo "错误: ClashX API 不可用"
    echo ""
    echo "请检查以下设置："
    echo "1. ✓ ClashX Pro 已启动"
    echo "2. 外部控制已开启："
    echo "   • 打开 ClashX Pro"
    echo "   • 点击菜单栏图标 → 设置 → API"
    echo "   • 开启外部控制器"
    echo "   • 确保端口设置为 9090"
    echo "3. 如果设置了 API Secret，请在脚本中配置"
    echo "4. 检查防火墙是否阻止了本地连接"
    echo ""
    echo "故障排除："
    echo "• 尝试重启 ClashX Pro"
    echo "• 检查 ClashX Pro 配置文件是否正确"
    echo "• 在浏览器中访问 http://127.0.0.1:9090/ui 测试连接"
    exit 1
fi

# 执行 API 请求的辅助函数
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    local headers=""
    if [ -n "$CLASHX_API_SECRET" ]; then
        headers="-H 'Authorization: Bearer $CLASHX_API_SECRET'"
    fi
    
    local curl_cmd="curl -X $method '$CLASHX_API_URL$endpoint' $headers --connect-timeout 5 --silent"
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    eval "$curl_cmd"
}

# 设置为直连模式（断网效果）
echo ""
echo "正在切换到直连模式..."
if api_request "PUT" "/configs" '{"mode": "direct"}' > /dev/null 2>&1; then
    echo "✓ 成功切换到直连模式"
else
    echo "✗ 切换到直连模式失败"
    exit 1
fi

echo "等待 5 秒..."
sleep 5

# 恢复到规则模式
echo "正在恢复代理模式..."
if api_request "PUT" "/configs" '{"mode": "rule"}' > /dev/null 2>&1; then
    echo "✓ 成功恢复代理模式"
else
    echo "✗ 恢复代理模式失败"
    exit 1
fi

echo ""
echo "🎉 操作完成！"
