# App → 日历分类映射

根据你的 Apple 日历体系配置。用户可自定义修改。

## 日历列表

| 日历名称 | 含义 | 对应 App |
|---------|------|---------|
| 🛜把自己产品化 | 自媒体/创业/产品化 | 与 AI agent 讨论产品、写公众号、剪视频、运营 |
| 🌳学习时间-日拱一卒 | 学习/研究/阅读 | 技术文章、课程、书籍、研究类 Chrome 浏览 |
| 💰工作时间-有DDL | 有截止日期的工作 | Figma、知音楼、工作相关 Chrome |
| 🏃‍♀️美丽时间 | 运动/自我提升 | 健身 App、运动相关 |
| 👶崽子时间 | 陪孩子 | — |
| 🎮无效时间-娱乐消磨 | 纯消磨 | 抖音、游戏、无目的刷社交媒体 |
| 🛏睡觉时间 | 睡眠 | 深夜/早晨无活动时段 |
| 🧠碎碎念 | 无法归类 | 杂项 |
| 🥬生存时间 | 吃饭/日常事务 | — |
| 👀沟通/社交 | 沟通交流 | 微信、飞书消息、电话 |

## App Bundle ID → 分类规则

```
# 工作类
com.figma.Desktop → 💰工作时间-有DDL
com.tal.yach.mac → 💰工作时间-有DDL
com.sketch.* → 💰工作时间-有DDL

# 沟通类
com.tencent.xinWeChat → 👀沟通/社交
com.bytedance.macos.feishu → 👀沟通/社交（如果是跟 agent 讨论产品 → 🛜把自己产品化）

# 浏览器类（需结合 Chrome History 判断）
com.google.Chrome → 根据浏览内容判断：
  - GitHub/HN/技术博客 → 🌳学习时间
  - 飞书文档/Notion → 💰工作时间 或 🛜产品化
  - X/Twitter/Reddit AI 内容 → 🌳学习时间
  - 小红书/抖音/YouTube 娱乐 → 🎮无效时间
  - 无法判断 → 🧠碎碎念

# 创作类
md.obsidian → 🌳学习时间 或 🛜产品化
com.apple.iCal → 🥬生存时间

# 开发类
com.googlecode.iterm2 → 💰工作时间 或 🛜产品化
com.apple.Terminal → 💰工作时间 或 🛜产品化

# 娱乐类
com.ss.mac.ugc.trill → 🎮无效时间（抖音）
tv.danmaku.bilimac → 🎮无效时间（B站）
com.netease.163music → 🥬生存时间（背景音乐）
```

## 歧义处理规则

飞书的分类取决于上下文：
- 如果在创业群/跟 agent 聊产品 → 🛜把自己产品化
- 如果在工作群/处理工作消息 → 💰工作时间
- 无法判断时默认 → 👀沟通/社交

Chrome 的分类取决于浏览内容：
- 优先查 Chrome History 的 URL/标题
- 如果 History 没有对应时段数据，按时段推断（工作时间 → 💰，晚上 → 可能 🎮）
