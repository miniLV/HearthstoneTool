#!/bin/bash
# 自动设置权限脚本 - 每次开机运行一次即可

echo "🚀 自动设置炉石传说断网工具权限"
echo "================================="

# 检查是否已经有权限
if sudo -n echo "test" 2>/dev/null; then
    echo "✅ sudo 权限已存在"
else
    echo "获取 sudo 权限..."
    sudo -v
    if [ $? -ne 0 ]; then
        echo "❌ 权限获取失败"
        exit 1
    fi
    echo "✅ sudo 权限已获取"
fi

# 创建配置文件
echo "创建配置文件..."
sudo bash -c 'echo "block all" > /tmp/hs_unplug.conf'
if [ $? -eq 0 ]; then
    echo "✅ 配置文件已创建"
else
    echo "❌ 配置文件创建失败"
fi

# 延长 sudo 权限时间（可选）
echo "延长 sudo 权限时间..."
sudo -v
sudo sh -c 'while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &'

echo ""
echo "🎉 设置完成！"
echo ""
echo "现在你可以："
echo "1. 在接下来的时间内多次使用 App 而不需要输入密码"
echo "2. 把这个脚本加入到开机启动项中"
echo "3. 或者每次使用前运行一次这个脚本"
echo ""
echo "如果权限过期，重新运行: ./auto_setup.sh"