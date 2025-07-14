#!/bin/bash
# ClashX 诊断脚本 - 检查 ClashX 配置和连接状态

echo "🔍 ClashX/ClashX Pro 诊断工具"
echo "===================="

# 检查 ClashX 或 ClashX Pro 进程
echo ""
echo "1. 检查进程状态..."
if pgrep -x "ClashX Pro" > /dev/null; then
    clashx_pid=$(pgrep -x "ClashX Pro")
    echo "   ✓ ClashX Pro 正在运行 (PID: $clashx_pid)"
    CLASHX_TYPE="ClashX Pro"
elif pgrep -x "ClashX" > /dev/null; then
    clashx_pid=$(pgrep -x "ClashX")
    echo "   ✓ ClashX 正在运行 (PID: $clashx_pid)"
    CLASHX_TYPE="ClashX"
else
    echo "   ✗ ClashX/ClashX Pro 未运行"
    echo "   💡 请启动 ClashX 或 ClashX Pro 应用程序"
    exit 1
fi

# 检查端口占用
echo ""
echo "2. 检查端口占用情况..."
if lsof -i :9090 > /dev/null 2>&1; then
    port_info=$(lsof -i :9090 | grep LISTEN)
    echo "   ✓ 端口 9090 已被占用"
    echo "   📋 $port_info"
else
    echo "   ✗ 端口 9090 未被占用"
    echo "   💡 ClashX 可能未开启外部控制"
fi

# 检查 ClashX API 响应
echo ""
echo "3. 检查 ClashX API 响应..."

# 测试版本接口
if curl -X GET "http://127.0.0.1:9090/version" --connect-timeout 3 --silent > /dev/null 2>&1; then
    version_info=$(curl -X GET "http://127.0.0.1:9090/version" --silent 2>/dev/null)
    echo "   ✓ API 连接成功"
    echo "   📋 版本信息: $version_info"
else
    echo "   ✗ API 连接失败"
fi

# 测试配置接口
echo ""
echo "4. 检查当前配置..."
if curl -X GET "http://127.0.0.1:9090/configs" --connect-timeout 3 --silent > /dev/null 2>&1; then
    config_info=$(curl -X GET "http://127.0.0.1:9090/configs" --silent 2>/dev/null)
    current_mode=$(echo "$config_info" | grep -o '"mode":"[^"]*"' | cut -d'"' -f4)
    echo "   ✓ 配置接口可访问"
    echo "   📋 当前模式: $current_mode"
else
    echo "   ✗ 配置接口不可访问"
fi

# 检查代理设置
echo ""
echo "5. 检查系统代理设置..."
proxy_settings=$(networksetup -getwebproxy "Wi-Fi" 2>/dev/null)
if echo "$proxy_settings" | grep -q "Enabled: Yes"; then
    echo "   ✓ 系统 HTTP 代理已启用"
else
    echo "   ⚠️  系统 HTTP 代理未启用"
fi

proxy_settings=$(networksetup -getsecurewebproxy "Wi-Fi" 2>/dev/null)
if echo "$proxy_settings" | grep -q "Enabled: Yes"; then
    echo "   ✓ 系统 HTTPS 代理已启用"
else
    echo "   ⚠️  系统 HTTPS 代理未启用"
fi

# 检查 ClashX 配置文件
echo ""
echo "6. 检查 ClashX 配置文件..."
clashx_config_dir="$HOME/.config/clash"
if [ -d "$clashx_config_dir" ]; then
    echo "   ✓ ClashX 配置目录存在: $clashx_config_dir"
    if [ -f "$clashx_config_dir/config.yaml" ]; then
        echo "   ✓ 配置文件存在"
        # 检查外部控制配置
        if grep -q "external-controller" "$clashx_config_dir/config.yaml" 2>/dev/null; then
            controller_config=$(grep "external-controller" "$clashx_config_dir/config.yaml")
            echo "   📋 外部控制配置: $controller_config"
        else
            echo "   ⚠️  配置文件中未找到 external-controller 设置"
        fi
    else
        echo "   ⚠️  配置文件不存在"
    fi
else
    echo "   ⚠️  ClashX 配置目录不存在"
fi

# 提供解决方案
echo ""
echo "🔧 故障排除建议："
echo "===================="

if ! curl -X GET "http://127.0.0.1:9090/version" --connect-timeout 3 --silent > /dev/null 2>&1; then
    echo ""
    echo "API 连接失败，请尝试以下解决方案："
    echo ""
    echo "1. 开启外部控制："
    if [ "$CLASHX_TYPE" = "ClashX Pro" ]; then
        echo "   • 点击菜单栏 ClashX Pro 图标"
        echo "   • 选择 '设置' → 'API'"
        echo "   • 开启外部控制器"
        echo "   • 确保端口设置为 9090"
    else
        echo "   • 点击菜单栏 ClashX 图标"
        echo "   • 选择 '配置' → '打开外部控制'"
        echo "   • 确保端口设置为 9090"
    fi
    echo ""
    echo "2. 重启应用："
    echo "   • 退出 $CLASHX_TYPE"
    echo "   • 重新启动应用程序"
    echo ""
    echo "3. 检查配置文件："
    echo "   • 确保配置文件中包含 'external-controller: 127.0.0.1:9090'"
    echo ""
    echo "4. 如果设置了 API Secret："
    echo "   • 在脚本中配置相应的 secret"
    echo ""
    echo "5. 测试连接："
    echo "   • 在浏览器中访问: http://127.0.0.1:9090/ui"
else
    echo ""
    echo "✅ API 工作正常！使用的是 $CLASHX_TYPE"
fi

echo ""
echo "📝 如果问题持续存在，请："
echo "   • 检查 ClashX 日志"
echo "   • 确认防火墙设置"
echo "   • 联系技术支持"
