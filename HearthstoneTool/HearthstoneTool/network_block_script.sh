#!/bin/bash

# 网络阻断和恢复脚本
# 用户: miniLV

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# 获取断网时长参数，默认20秒
DURATION=${1:-20}

echo "[A] 正在阻断所有 TCP 出站连接..."

# 先测试sudo密码
if ! echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /usr/bin/whoami > /dev/null 2>&1; then
    echo "[ERROR] 管理员密码验证失败，请重新设置密码"
    exit 1
fi

# 启用pfctl (开发模式下可能失败，但继续执行)
if ! echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /sbin/pfctl -e > /dev/null 2>&1; then
    echo "Warning: pfctl启用失败 (开发模式下正常，发布版本需要完整磁盘访问权限)"
    # 在开发模式下不退出，继续执行
fi

# 创建阻断规则
if ! echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /bin/bash -c '/bin/echo "block drop out quick proto tcp from any to any" > /etc/pf.blockall.conf' 2>/dev/null; then
    echo "[ERROR] 创建网络阻断规则失败"
    exit 1
fi

# 加载阻断规则
if ! echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /sbin/pfctl -f /etc/pf.blockall.conf > /dev/null 2>&1; then
    echo "[ERROR] 加载网络阻断规则失败"
    exit 1
fi

echo "[B] 网络已阻断，${DURATION} 秒后恢复..."

# 等待指定时间
/bin/sleep "${DURATION}"

# 恢复网络 - 加载原始配置
echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /sbin/pfctl -f /etc/pf.conf > /dev/null 2>&1

echo "[C] 网络已恢复"
