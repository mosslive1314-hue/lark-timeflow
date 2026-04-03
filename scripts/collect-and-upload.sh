#!/bin/bash
#
# time-mirror: 采集数据 + 写入飞书多维表格 + 发送飞书提醒
# Usage: ./scripts/collect-and-upload.sh [YYYY-MM-DD]
#

set -e

# 获取日期
if [ -z "$1" ]; then
  DATE=$(date +%Y-%m-%d)
else
  DATE="$1"
fi

echo "📥 time-mirror 采集 $DATE 数据..."

# 第一步: 运行采集
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
"$SCRIPT_DIR/collect.sh" "$DATE"

# 检查采集结果
RAW_FILE="/tmp/time_mirror/raw_${DATE}.json"
if [ ! -f "$RAW_FILE" ]; then
  echo "❌ 采集失败，$RAW_FILE 不存在"
  exit 1
fi

# 第二步: 整合后准备写入飞书
# 飞书 CLI 需要配置环境变量
if [ -z "$FEISHU_APP_TOKEN" ] || [ -z "$FEISHU_TABLE_ID" ]; then
  echo "⚠️  请先配置环境变量:"
  echo "export FEISHU_APP_TOKEN=your_app_token"
  echo "export FEISHU_TABLE_ID=your_table_id"
  echo "export FEISHU_WEBHOOK=your_robot_webhook"
  exit 1
fi

# 读取整合后的数据，逐行写入飞书
# 整合结果在 /tmp/time_mirror/blocks_${DATE}.json
BLOCKS_FILE="/tmp/time_mirror/blocks_${DATE}.json"
if [ ! -f "$BLOCKS_FILE" ]; then
  echo "❌ 整合结果 $BLOCKS_FILE 不存在"
  exit 1
fi

echo "📤 正在写入飞书多维表格..."

# 使用飞书 CLI 添加记录
# 每条记录: date, time_range, category, description, duration, source
count=0
while IFS= read -r line; do
  # line is JSON: { "start": "...", "end": "...", "category": "...", "description": "...", "duration_min": ..., "source": "..." }
  start=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['start'])")
  end=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['end'])")
  category=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['category'])")
  description=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['description'])")
  duration_min=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['duration_min'])")
  source="🤖自动采集"

  # 调用飞书 CLI 创建记录
  # 格式: lark-cli bitable/app-table/record add --app $FEISHU_APP_TOKEN --table $FEISHU_TABLE_ID --data '{"fields": {...}}'
  data="{\"fields\": {\"日期\": \"$DATE\", \"时段\": \"$start-$end\", \"分类\": \"$category\", \"活动描述\": \"$description\", \"时长\": $duration_min, \"数据来源\": \"$source\"}}"

  lark-cli bitable app-table record add \
    --app "$FEISHU_APP_TOKEN" \
    --table "$FEISHU_TABLE_ID" \
    --data "$data"

  count=$((count + 1))
done < "$BLOCKS_FILE"

echo "✅ 完成！共写入 $count 条记录到飞书多维表格"

# 第三步: 生成当日时间线，通过飞书机器人发送，提醒用户补全空白
if [ -n "$FEISHU_WEBHOOK"" ]; then
  echo "🤖 发送飞书提醒..."

  # 生成时间线文本
  timeline="⏰ **今日时间线 | $DATE**\n\n"
  total_blank=0
  while IFS= read -r line; do
    start=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['start'][:5])")
    end=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['end'][:5])")
    category=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['category'].split()[0])")
    desc=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(d['description'])")
    duration=$(echo "$line" | python3 -c "import json, sys; d = json.load(sys.stdin); print(int(d['duration_min']))")

    if [ "$category" = "❓" ]; then
      timeline="$timeline$start-$end  $category $desc ($duration min) ← 请回复补全这段时间\n"
      total_blank=$((total_blank + duration))
    else
      timeline="$timeline$start-$end  $category $desc ($duration min)\n"
    fi
  done < "$BLOCKS_FILE"

  # 添加汇总
  total=$(( $(jq -s "[.duration_min] | add" "$BLOCKS_FILE" 2>/dev/null || echo 0) ))
  timeline="$timeline\n📊 **今日汇总**\n总计: $total 分钟 ($(( total / 60 ))h$(( total % 60 ))m)"

  if [ $total_blank -gt 0 ]; then
    timeline="$timeline\n❓ 待补全: $total_blank 分钟，请回复补全"
  fi

  # 发送到飞书机器人
  # curl 调用 webhook
  curl -X POST "$FEISHU_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"msg_type\": \"text\", \"content\": {\"text\": \"$timeline\"}}"

  echo "✅ 飞书提醒已发送"

  # 第四步: 如果是周日，发送周复盘
  # 获取星期几 (0=周日)
  DOW=$(date -d "$DATE" +"%w")
  if [ "$DOW" = "0" ]; then
    echo "📈 生成周日复盘..."
    # 统计本周（周一到周日）各分类时长

    # 从飞书多维表格查询本周数据
    # 使用飞书 CLI 查询
    week_start=$(date -d "$DATE - 6 days" +%Y-%m-%d)
    week_end="$DATE"

    # 查询飞书，获取所有记录
    # 这里我们调用飞书 CLI 筛选并聚合
    # 输出汇总文本

    echo "📝 本周统计: $week_start ~ $week_end"

    # 调用飞书 CLI 获取记录，聚合
    # 这个比较复杂，脚本先做简化版，后续可以优化
    report="📈 **本周时间分配 | $week_start ~ $week_end**\n\n"

    # 这里简化处理，直接提示
    report="$report 可以在飞书多维表格仪表盘查看完整统计，包含趋势对比哦 ✨"

    # 发送复盘
    curl -X POST "$FEISHU_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "{\"msg_type\": \"text\", \"content\": {\"text\": \"$report\"}}"

    echo "✅ 周复盘已发送"
  fi
fi

echo ""
echo "🎉 全部完成！"
echo "📝 日期: $DATE"
echo "🔢 记录数: $count"
echo "📊 数据已写入飞书多维表格"
[ -n "$FEISHU_WEBHOOK" ] && echo "🤖 提醒已发送到飞书"
