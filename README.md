# 🪞 time-mirror

**A time mirror, not a time cop.**

> 自动追踪 macOS App 使用时间，整合写入 Apple 日历，每晚补全空白，每周复盘分析。
> 让你看清时间去了哪里，然后自己做选择。

<br>

## ✨ 核心理念

```
一天只有 24 小时。
8 小时睡眠，8 小时生活，8 小时学习工作。
时间用在哪里，自然就会收回什么。
```

time-mirror 不会告诉你「该做什么」，它只会告诉你「你做了什么」。

**它是一面镜子，不是一个监工。**

<br>

## 🎯 它做什么

```
┌─────────────────────────────────────────────────────────┐
│                    time-mirror                           │
│                                                          │
│  📊 自动采集          🗓️ 写入日历          📋 每晚补全   │
│  macOS App 使用       Apple Calendar      空白时段追问   │
│  Chrome 浏览历史      → iCloud 同步        用户回复补全   │
│                       → iPhone 可见                      │
│                       → 飞书可见           📈 每周复盘   │
│                                            时间分配分析   │
└─────────────────────────────────────────────────────────┘
```

<br>

## 🖥️ 工作原理

### 数据流

```
┌──────────────┐     ┌──────────────┐     ┌───────────────┐
│  macOS       │     │  time-mirror │     │  Apple        │
│  knowledgeC  │────▶│  采集 + 整合  │────▶│  Calendar     │
│  .db         │     │              │     │  (iCloud 同步) │
├──────────────┤     │  30min 粒度   │     ├───────────────┤
│  Chrome      │────▶│  App 分类     │     │  📱 iPhone    │
│  History     │     │  空白识别     │     │  📘 飞书      │
└──────────────┘     └──────────────┘     └───────────────┘
```

### macOS 怎么知道你在用什么？

macOS 内置的 **Knowledge 框架** 会自动记录每个 App 的前台使用时间，存在 `knowledgeC.db` 里。time-mirror 只是读取这个已有的数据库，**不安装任何监控软件**。

```sql
-- 这就是 time-mirror 读取的数据
SELECT app_name, start_time, end_time, duration
FROM knowledgeC.db
WHERE stream = '/app/usage'
```

<br>

## 🚀 快速开始

### 模式一：本地模式（推荐）

> OpenClaw 就跑在你的常用电脑上

**零配置。** 安装 skill 后直接运行：

```bash
# 采集今天的数据
./scripts/collect.sh

# 采集指定日期
./scripts/collect.sh 2024-03-15
```

### 模式二：远程模式

> OpenClaw 跑在另一台 Mac（如服务器），你的常用 Mac 是另一台

在常用 Mac 的终端执行：

```bash
crontab -e
```

添加两行（每 30 分钟自动同步）：

```cron
*/30 * * * * cp ~/Library/Application\ Support/Knowledge/knowledgeC.db ~/Library/Mobile\ Documents/com~apple~CloudDocs/knowledgeC_sync.db
*/30 * * * * cp ~/Library/Application\ Support/Google/Chrome/Default/History ~/Library/Mobile\ Documents/com~apple~CloudDocs/chrome_history_sync.db
```

数据通过 **iCloud Drive** 自动同步到 OpenClaw 所在的 Mac。

```
┌─────────────┐   iCloud    ┌─────────────┐
│  常用 Mac    │───────────▶│  OpenClaw Mac│
│  knowledgeC  │   自动同步   │  读取 + 整合 │
│  Chrome Hist │            │  写入日历     │
└─────────────┘             └─────────────┘
```

### 自动检测

skill 会自动判断应该用哪个模式：

```bash
./scripts/detect_mode.sh
# 输出: "local" 或 "remote"
```

<br>

## 📊 输出示例

### 每日时间线

```
⏰ 今日时间线 | 2024-03-15

08:04-08:22  💰 Chrome 浏览 + 知音楼消息
08:22-10:03  ❓ 空白（1h41m）← 这段在做什么？
10:03-10:58  👀 微信 + 知音楼 + 飞书（沟通处理）
11:00-11:46  💰 Figma 设计（穿插消息）
11:46-14:20  ❓ 空白（2h34m）← 午饭午休？
14:20-15:20  🛜 飞书讨论产品方案
15:06-15:17  🌳 Chrome: X/Twitter AI 内容
```

### 每日汇总

```
📊 今日汇总

💰 工作      1h04m  ██████████░░░░░░  28%
👀 沟通        55m  ████████░░░░░░░░  23%
🛜 产品化    1h00m  █████████░░░░░░░  25%
🌳 学习        11m  █░░░░░░░░░░░░░░░   5%
❓ 空白      4h16m  ████████████████  待补全
```

### 每周复盘

```
📈 本周时间分配 | 3/11 - 3/17

🛜 产品化     12h  ████████████████  25%
💰 工作       10h  █████████████░░░  21%
👀 沟通        8h  ██████████░░░░░░  17%
🌳 学习        5h  ██████░░░░░░░░░░  10%
🥬 生存        6h  ████████░░░░░░░░  13%
🎮 娱乐        3h  ████░░░░░░░░░░░░   6%
🧠 其他        4h  █████░░░░░░░░░░░   8%

vs 上周: 🛜产品化 +3h ↑ | 🎮娱乐 -2h ↓ | 趋势向好 ✅
```

<br>

## 🗓️ Apple 日历集成

time-mirror 将时间块写入你的 **Apple 日历**，通过 iCloud 自动同步到所有设备：

```
Apple Calendar ──iCloud──▶ iPhone Calendar
                         ▶ 飞书日历（如已关联）
                         ▶ 其他设备
```

### 日历分类映射

你可以自定义 App 和日历的映射关系（在 `references/app_categories.md` 中配置）：

| App | 日历 |
|-----|------|
| Figma, Sketch | 💰 工作时间 |
| 微信, 飞书 | 👀 沟通/社交 |
| Chrome（看内容判断） | 🌳 学习 / 💰 工作 / 🎮 娱乐 |
| 抖音, B站 | 🎮 无效时间 |
| Obsidian | 🌳 学习 / 🛜 产品化 |

Chrome 的分类会结合浏览历史智能判断：

```
Chrome + GitHub/HN      → 🌳 学习
Chrome + Figma 文档      → 💰 工作
Chrome + 小红书/抖音     → 🎮 娱乐
Chrome + 飞书文档        → 🛜 产品化
```

<br>

## 📱 手机数据

目前 **仅支持 macOS**。iPhone/iPad 的屏幕使用数据受 Apple 沙箱保护，无法自动采集。

**替代方案：**
- 📸 发一张 Screen Time 截图给 AI agent，自动识别并合并
- ⏳ 等待 OpenClaw iOS Node 正式发布后支持自动采集

<br>

## 📂 项目结构

```
time-mirror/
├── SKILL.md                     # OpenClaw skill 定义（AI agent 读这个）
├── README.md                    # 你正在读的文档
├── references/
│   └── app_categories.md        # App → 日历分类映射（可自定义）
└── scripts/
    ├── detect_mode.sh           # 自动检测本地/远程模式
    └── collect.sh               # 数据采集脚本
```

<br>

## ⚠️ 注意事项

| 问题 | 说明 |
|------|------|
| iCloud 同步延迟 | 远程模式下 iCloud 文件可能需要几分钟同步，脚本会自动等待 |
| Chrome 锁定 | Chrome 运行时 History 文件会被锁定，复制的可能是稍旧的数据 |
| WAL 模式 | knowledgeC.db 使用 WAL 模式，远程复制可能少几条记录，可接受 |
| I/O Error | iCloud 上的 db 文件不能直接读，必须先 `dd` 复制到 /tmp |
| 隐私 | 所有数据仅在本地处理，不上传任何云服务 |

<br>

## 🧘 设计哲学

> 大多数时间管理工具的结局：第一周新鲜 → 第二周漏记 → 第三周放弃。

time-mirror 的设计原则是**零摩擦**：

1. **不需要你手动记录** — 数据自动采集
2. **不需要你打开任何 App** — 数据自动写入日历
3. **不会打断你的心流** — 只在晚上问一次空白时段
4. **不判断对错** — 刷抖音 3 小时？记下来就好，你自己决定要不要改

来自一个奥地利经济学家的建议：

> *"这个 skill 必须是工具，不能是主人。"* — 米塞斯（大概）

<br>

## 🤝 配合 OpenClaw 使用

time-mirror 设计为 [OpenClaw](https://github.com/openclaw/openclaw) 的 skill。安装后 AI agent 会在以下场景自动触发：

- 「今天时间都花哪了」
- 「帮我追踪时间」
- 「这周时间分配怎么样」
- 「写入日历」

也可以独立使用脚本进行数据采集。

<br>

## 📄 License

MIT

---

*Built with 🍡 by a human and their AI assistant.*
