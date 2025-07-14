#!/bin/bash
# ClashX Pro 简化版断网脚本 - 适用于 Xcode 环境
# 避免使用需要特殊权限的系统命令

# 配置参数
CLASHX_API_URL="http://127.0.0.1:53378"
CLASHX_API_SECRET="daa-67P-sHH-Dvm"

echo "🚀 启动 ClashX Pro 断网脚本"
echo "=============================="

# 直接尝试连接 API，如果成功说明 ClashX Pro 正在运行
echo "检查 ClashX Pro API 连接..."

if curl -X GET "$CLASHX_API_URL/version" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --connect-timeout 3 --silent > /dev/null 2>&1; then
    echo "✓ ClashX Pro API 连接成功"
else
    echo "✗ ClashX Pro API 连接失败"
    echo ""
    echo "请确保："
    echo "1. ClashX Pro 已启动"
    echo "2. API 设置正确："
    echo "   • Api Port: 53378"
    echo "   • Api Secret: daa-67P-sHH-Dvm"
    echo "   • Allow control from lan: ✓"
    echo ""
    exit 1
fi

# 获取当前模式
echo ""
echo "获取当前代理模式..."
current_config=$(curl -X GET "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent 2>/dev/null)

if [ $? -eq 0 ]; then
    current_mode=$(echo "$current_config" | grep -o '"mode":"[^"]*"' | cut -d'"' -f4)
    echo "✓ 当前模式: $current_mode"
else
    echo "⚠️ 无法获取当前模式，继续执行..."
fi

# 切换到断网模式（拒绝所有连接）
echo ""
echo "🔌 启用断网模式（拒绝所有连接）..."
if curl -X PUT "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    -H "Content-Type: application/json" \
    -d '{"mode": "rule", "rules": ["MATCH,REJECT"]}' \
    --silent --connect-timeout 5 > /dev/null 2>&1; then
    echo "✓ 成功启用断网模式"
else
    echo "✗ 启用断网模式失败"
    exit 1
fi

# 等待期间显示倒计时
echo ""
echo "⏱️ 断网倒计时："
for i in {8..1}; do
    echo "   $i 秒..."
    sleep 1
done

# 恢复到规则模式
echo ""
echo "🌐 恢复代理模式..."
if curl -X PUT "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    -H "Content-Type: application/json" \
    -d '{"mode": "rule"}' \
    --silent --connect-timeout 5 > /dev/null 2>&1; then
    echo "✓ 成功恢复代理模式"
else
    echo "✗ 恢复代理模式失败"
    exit 1
fi

# 验证最终状态
echo ""
echo "验证最终状态..."
final_config=$(curl -X GET "$CLASHX_API_URL/configs" \
    -H "Authorization: Bearer $CLASHX_API_SECRET" \
    --silent 2>/dev/null)

if [ $? -eq 0 ]; then
    final_mode=$(echo "$final_config" | grep -o '"mode":"[^"]*"' | cut -d'"' -f4)
    echo "✓ 最终模式: $final_mode"
else
    echo "⚠️ 无法验证最终状态"
fi

echo ""
echo "🎉 断网操作完成！"
echo "================"
