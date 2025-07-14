#!/bin/bash
# ClashX 自动断网脚本 - 通过 API 控制 ClashX

# 检查 ClashX API 是否可用
echo "检查 ClashX API 连接..."
if ! curl -X GET "http://127.0.0.1:9090/version" --connect-timeout 3 --silent > /dev/null 2>&1; then
    echo "错误: ClashX API 不可用"
    echo "请确保："
    echo "1. ClashX 已启动"
    echo "2. 外部控制已开启 (配置 → 打开外部控制)"
    echo "3. 系统代理已启用"
    exit 1
fi

# 设置为直连模式（断网效果）
echo "正在切换到直连模式..."
if curl -X PUT "http://127.0.0.1:9090/configs" \
  -H "Content-Type: application/json" \
  -d '{"mode": "direct"}' \
  --silent --connect-timeout 3; then
    echo "成功切换到直连模式"
else
    echo "切换到直连模式失败"
    exit 1
fi

echo "等待 5 秒..."
sleep 5

# 恢复到规则模式
echo "正在恢复代理模式..."
if curl -X PUT "http://127.0.0.1:9090/configs" \
  -H "Content-Type: application/json" \
  -d '{"mode": "rule"}' \
  --silent --connect-timeout 3; then
    echo "成功恢复代理模式"
else
    echo "恢复代理模式失败"
    exit 1
fi

echo "操作完成"