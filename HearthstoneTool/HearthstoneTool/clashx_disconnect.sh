#!/bin/bash
# ClashX 自动断网脚本 - 通过 API 控制 ClashX

# 配置参数
CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"  # ClashX Pro API Secret
MAX_RETRY=3
RETRY_DELAY=2

# 检查 ClashX 或 ClashX Pro 是否正在运行
check_clashx_running() {
    # 使用多种方法检查进程
    local clashx_found=false
    
    # 方法1: 使用 osascript 检查应用程序是否运行（不需要特殊权限）
    if osascript -e 'tell application "System Events" to (name of processes) contains "ClashX Pro"' 2>/dev/null | grep -q "true"; then
        echo "✓ ClashX Pro 进程正在运行 (检测方法: osascript)"
        clashx_found=true
    elif osascript -e 'tell application "System Events" to (name of processes) contains "ClashX"' 2>/dev/null | grep -q "true"; then
        echo "✓ ClashX 进程正在运行 (检测方法: osascript)"
        clashx_found=true
    fi
    
    # 方法2: 尝试直接连接 API（如果应用运行，API 应该可用）
    if [ "$clashx_found" = false ]; then
        echo "正在通过 API 检测 ClashX Pro..."
        if check_api_connection_silent; then
            echo "✓ ClashX Pro 通过 API 检测到正在运行"
            clashx_found=true
        fi
    fi
    
    # 方法3: 使用 ps 命令（仅在有权限时）
    if [ "$clashx_found" = false ]; then
        if ps aux 2>/dev/null | grep -v grep | grep -q "ClashX Pro"; then
            echo "✓ ClashX Pro 进程正在运行 (检测方法: ps)"
            clashx_found=true
        elif ps aux 2>/dev/null | grep -v grep | grep -q "ClashX"; then
            echo "✓ ClashX 进程正在运行 (检测方法: ps)"
            clashx_found=true
        fi
    fi
    
    # 方法4: 使用 pgrep (如果可用且正常工作)
    if [ "$clashx_found" = false ]; then
        if pgrep -x "ClashX Pro" > /dev/null 2>&1; then
            echo "✓ ClashX Pro 进程正在运行 (检测方法: pgrep)"
            clashx_found=true
        elif pgrep -x "ClashX" > /dev/null 2>&1; then
            echo "✓ ClashX 进程正在运行 (检测方法: pgrep)"
            clashx_found=true
        fi
    fi
    
    if [ "$clashx_found" = true ]; then
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

# 检查 ClashX API 是否可用（静默版本）
check_api_connection_silent() {
    local headers=""
    if [ -n "$CLASHX_API_SECRET" ]; then
        headers="-H 'Authorization: Bearer $CLASHX_API_SECRET'"
    fi
    
    eval "curl -X GET '$CLASHX_API_URL/version' $headers --connect-timeout 2 --silent" > /dev/null 2>&1
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
    echo "   • 勾选 'Allow control from lan'"
    echo "   • 确保端口设置为 53378"
    echo "3. 如果设置了 API Secret，请在脚本中配置"
    echo "4. 检查防火墙是否阻止了本地连接"
    echo ""
    echo "故障排除："
    echo "• 尝试重启 ClashX Pro"
    echo "• 检查 ClashX Pro 配置文件是否正确"
    echo "• 在浏览器中访问 http://127.0.0.1:53378/ui 测试连接"
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
    echo "🔌 现在应该处于断网状态，请检查网络连接"
    echo ""
    
    # 测试网络连接
    echo "📡 测试网络连接..."
    if curl -m 3 "https://www.baidu.com" >/dev/null 2>&1; then
        echo "⚠️  网络仍然连通 - 可能是 DNS 缓存或者配置问题"
    else
        echo "✅ 确认网络已断开"
    fi
else
    echo "✗ 切换到直连模式失败"
    exit 1
fi

echo ""
echo "⏱️ 断网倒计时："
for i in {5..1}; do
    echo "   $i 秒..."
    sleep 1
done

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
