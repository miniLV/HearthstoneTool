#!/bin/bash
# ClashX 自动断网脚本 - 通过 API 控制 ClashX

# 设置为直连模式（断网效果）
echo "正在切换到直连模式..."
curl -X PUT "http://127.0.0.1:9090/configs" \
  -H "Content-Type: application/json" \
  -d '{"mode": "direct"}' \
  --silent

echo "已切换到直连模式，等待 5 秒..."
sleep 5

# 恢复到规则模式
echo "正在恢复代理模式..."
curl -X PUT "http://127.0.0.1:9090/configs" \
  -H "Content-Type: application/json" \
  -d '{"mode": "rule"}' \
  --silent

echo "已恢复代理模式"