---
name: time-mirror
description: |
  自动追踪 macOS App 使用时间，整合写入 Apple 日历，每日补全 + 每周复盘。
  一面自动化的时间镜子——帮你看清 24 小时的真实分配，让你自己做选择。
  触发场景：用户要求追踪时间、记录时间用度、时间管理、时间复盘、写入日历、
  分析 App 使用数据、查看今天干了什么、时间都花哪了。
  Trigger: time tracking, time mirror, 时间管家, 时间镜子, 追踪时间, 时间用度,
  what did I do today, where did my time go, app usage, screen time
---

# time-mirror：时间镜子

> 一面自动化的镜子，帮你看清 24 小时的真实分配。不判断好坏，不当监工，不制造焦虑。

## 核心理念

一天只有 24 小时。时间用在哪里，自然就会收回什么。
这个 skill 的目标是**让你看见**，而不是「管」你。

## 工作模式

### 本地模式（默认）
OpenClaw 在常用电脑上，直接读取本机数据。零配置。

### 远程模式
OpenClaw 在另一台 Mac 上，通过 iCloud Drive 同步数据过来。
需要在常用 Mac 上设置一条 cron：
```bash
crontab -e
# 添加以下两行（每 30 分钟同步一次）
*/30 * * * * cp ~/Library/Application\ Support/Knowledge/knowledgeC.db ~/Library/Mobile\ Documents/com~apple~CloudDocs/knowledgeC_sync.db
*/30 * * * * cp ~/Library/Application\ Support/Google/Chrome/Default/History ~/Library/Mobile\ Documents/com~apple~CloudDocs/chrome_history_sync.db
```

### 模式自动检测
执行 `scripts/detect_mode.sh`，如果本机 knowledgeC.db 最近 1 小时有活跃数据 → 本地模式，否则 → 检查 iCloud 同步文件。

## 数据源

| 数据源 | 内容 | 路径 |
|--------|------|------|
| knowledgeC.db | App 使用记录（名称、开始/结束时间） | 本地: `~/Library/Application Support/Knowledge/knowledgeC.db` / 远程: iCloud `knowledgeC_sync.db` |
| Chrome History | 浏览历史（URL、标题、访问时间） | 本地: `~/Library/Application Support/Google/Chrome/Default/History` / 远程: iCloud `chrome_history_sync.db` |

### 📱 手机数据
目前仅支持 macOS。iPhone/iPad 数据受 Apple 沙箱保护无法自动采集。
替代方案：发一张 Screen Time 截图给 agent，用图像识别提取数据合并。

## 数据采集

执行 `scripts/collect.sh` 采集当天数据到 `/tmp/time_mirror/`。

采集流程：
1. 检测模式（本地/远程）
2. 如果远程模式，先 `brctl download` 强制下载 iCloud 文件，再 `dd` 复制到 /tmp（直接读 iCloud 文件会报 I/O error）
3. 查询 knowledgeC `/app/usage` 流，过滤当天数据
4. 查询 Chrome History `urls` + `visits` 表，过滤当天数据
5. 输出 JSON 到 `/tmp/time_mirror/raw_YYYY-MM-DD.json`

## 数据整合

读取 `references/app_categories.md` 获取 App → 日历分类映射。

整合逻辑：
1. 将零碎的 App 记录按 30 分钟粒度聚合成时间块
2. 合并相邻的同类 App 活动（如连续的 Chrome 片段合并为一个时间块）
3. 结合 Chrome 浏览历史推断 Chrome 时段的具体内容
4. 根据 App 类型映射到 Apple 日历分类
5. 识别空白时段（>30 分钟无活动）标记为待确认

## 写入 Apple 日历

通过 AppleScript 写入用户指定的 Apple 日历：

```applescript
tell application "Calendar"
  tell calendar "{日历名称}"
    make new event with properties {summary:"{活动描述}", start date:date "{开始时间}", end date:date "{结束时间}"}
  end tell
end tell
```

写入前检查是否已有同时段事件，避免重复。
Apple 日历通过 iCloud 自动同步到 iPhone 和飞书。

## 日历分类配置

用户需在 `references/app_categories.md` 中配置自己的日历名和 App 映射。
参考 [references/app_categories.md](references/app_categories.md)。

## 每日流程

### 1. 数据采集（心跳触发或手动）
运行 `scripts/collect.sh`，采集并整合数据。

### 2. 写入日历
将整合后的时间块写入 Apple 日历。

### 3. 空白追问（每晚一次）
发送当天时间线给用户，标注空白时段：
```
⏰ 今日时间线 | YYYY-MM-DD

08:04-08:22  💰 Chrome + 知音楼
08:22-10:03  ❓ 空白（1h41m）← 这段在做什么？
10:03-10:58  👀 微信 + 飞书（沟通）
...
```
用户回复后补全空白，写入日历。不回复就留着，不追问。

## 每周复盘（周日）

统计一周的时间分配比例，按日历分类汇总：
- 各分类时间占比（饼图描述）
- 对比 8+8+8 理想模型
- 趋势分析：本周 vs 上周
- 输出到 Obsidian 或用户指定路径

## 注意事项

- iCloud 同步的 db 文件不能直接用 sqlite3 读取，必须先 `dd` 复制到 /tmp
- Chrome History 在 Chrome 运行时会锁定，复制可能会拿到稍旧的数据，这是正常的
- knowledgeC.db 用 WAL 模式，复制时可能缺少 WAL 文件，数据可能比本地少几条，可接受
- 分类有歧义时（如 Chrome 可能是工作也可能是摸鱼），结合浏览历史和时段推断
