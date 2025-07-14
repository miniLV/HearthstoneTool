#!/bin/bash
# 快速设置 sudo 权限

echo "🚀 快速设置权限"
echo "=============="

echo "请输入密码获取 sudo 权限："
sudo -v

if [ $? -eq 0 ]; then
    echo "✅ 权限设置成功！"
    echo "现在可以在 5 分钟内使用 App 了"
    
    # 创建配置文件
    sudo bash -c 'echo "block all" > /tmp/hs_unplug.conf'
    echo "✅ 配置文件已创建"
    
else
    echo "❌ 权限设置失败"
fi