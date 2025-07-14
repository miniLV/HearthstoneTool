#!/bin/bash
# ClashX Pro 快速测试脚本

# 配置参数
CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"

echo "🔍 ClashX Pro 快速测试"
echo "====================="

# 检查进程
echo "1. 检查进程状态..."
if ps aux | grep -v grep | grep -q "ClashX Pro"; then
    echo "   ✓ ClashX Pro 正在运行"
else
    echo "   ✗ ClashX Pro 未运行"
    exit 1
fi

# 测试 API 连接
echo ""
echo "2. 测试 API 连接..."
if curl -X GET "$CLASHX_API_URL/version" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --connect-timeout 3 --silent > /dev/null; then
    echo "   ✓ API 连接成功"
else
    echo "   ✗ API 连接失败"
    exit 1
fi

# 获取当前配置
echo ""
echo "3. 获取当前配置..."
current_config=$(curl -X GET "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent 2>/dev/null)

if [ $? -eq 0 ]; then
    current_mode=$(echo "$current_config" | grep -o '"mode":"[^"]*"' | cut -d'"' -f4)
    echo "   ✓ 当前模式: $current_mode"
else
    echo "   ✗ 无法获取配置"
    exit 1
fi

echo ""
echo "✅ 所有测试通过！ClashX Pro API 工作正常。"
