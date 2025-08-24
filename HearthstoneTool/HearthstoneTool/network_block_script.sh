#!/bin/bash

# 网络阻断和恢复脚本
# 用户: miniLV

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

echo "[A] 正在阻断所有 TCP 出站连接..."

# 启用pfctl
echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /sbin/pfctl -e > /dev/null 2>&1

# 创建阻断规则
echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /bin/bash -c '/bin/echo "block drop out quick proto tcp from any to any" > /etc/pf.blockall.conf'

# 加载阻断规则
echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /sbin/pfctl -f /etc/pf.blockall.conf > /dev/null 2>&1

echo "[B] 网络已阻断，20 秒后恢复..."

# 等待20秒
/bin/sleep 20

# 恢复网络 - 加载原始配置
echo "${SUDO_PASSWORD}" | /usr/bin/sudo -S /sbin/pfctl -f /etc/pf.conf > /dev/null 2>&1

echo "[C] 网络已恢复"
