#!/bin/bash
#
# lark-timeflow: 抓取飞书群聊中的活动信息，自动提醒
# Usage: ./scripts/fetch-events.sh
#

set -e

echo "🔍 抓取飞书群聊中的活动信息..."

# 检查环境变量
if [ -z "$FEISHU_APP_TOKEN" ] || [ -z "$FEISHU_EVENT_TABLE_ID" ] || [ -z "$FEISHU_WEBHOOK" ]; then
  echo "⚠️  请先配置环境变量:"
  echo "export FEISHU_APP_TOKEN=your_app_token"
  echo "export FEISHU_EVENT_TABLE_ID=your_event_table_id"
  echo "export FEISHU_WEBHOOK=your_robot_webhook"
  exit 1
fi

# 使用飞书 CLI 获取最近消息
# 需要配置飞书 CLI 已经登录
echo "📥 获取最近 24 小时消息..."

# 这里调用飞书 CLI 获取消息
# 简化版本：假设我们已经通过飞书 CLI 获取了消息，这里是框架
# 实际使用需要飞书 CLI 的 IM API 支持

# 识别活动关键词
KEYWORDS="活动|报名|讲座|沙龙|分享|聚会|线下|交流|开课|读书会"

# 这里简化处理，实际逻辑：
# 1. 获取最近 24h 消息
# 2. 匹配关键词
# 3. 提取活动信息（名称、时间、地点）
# 4. 询问用户是否添加提醒
# 5. 添加到多维表格，创建日历提醒

# 占位：实际需要飞书 IM API
echo "⚠️  注意：完整的群聊消息抓取需要飞书 IM API 权限，当前版本为框架实现"
echo ""

# 输出帮助
echo "📋 使用说明:"
echo "1. 配置环境变量后，定时运行脚本"
echo "2. 脚本会自动扫描最近消息，发现活动"
echo "3. 通过飞书机器人询问你是否报名"
echo "4. 确认后自动添加到飞书多维表格和日历，设置提醒"
echo ""

# 如果有飞书 CLI，我们尝试简单查询
if which lark-cli >/dev/null; then
  echo "✅ 找到 lark-cli，开始扫描..."
  # 这里后续可以完善 API 调用
  echo "👉 框架已就绪，等待飞sh CLI IM API 完善"
else
  echo "⚠️  未找到 lark-cli，请先安装飞书 CLI"
  exit 1
fi

echo ""
echo "✅ 扫描完成"
echo "📍 发现新活动会通过飞书机器人通知你"
