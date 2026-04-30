# 单词记忆应用 - 技术规格说明

## 1. 项目概述

### 项目名称
**WordMaster** - 智能单词记忆助手

### 项目类型
iOS移动应用（SwiftUI）

### 核心功能概述
一款基于艾宾浩斯遗忘曲线理论的背单词应用，用户通过阅读短文学习单词，支持图片OCR识别添加新单词，智能提醒复习时间。

### 目标用户
- 英语学习者
- 备考学生（高考、四六级、雅思、托福等）
- 希望提升词汇量的成年人

---

## 2. UI/UX规格说明

### 2.1 屏幕结构

#### 主要屏幕
1. **首页/今日任务** - 展示今日需要复习的单词和短文
2. **短文列表** - 展示所有短文，可按学习进度筛选
3. **短文详情** - 展示单篇短文的图片和单词
4. **单词学习/复习** - 单词卡片学习界面
5. **单词详情** - 单词详细信息和学习历史
6. **添加单词** - 通过拍照/选图添加新单词
7. **学习统计** - 展示学习进度和统计信息
8. **设置** - 应用设置

#### 导航结构
- **TabBar导航**（底部4个标签）：
  - 首页（house.fill）
  - 短文（book.fill）
  - 添加（plus.circle.fill）
  - 我的（person.fill）

### 2.2 视觉设计

#### 颜色方案
- **主色**：#4A90E2（蓝色 - 学习、专注）
- **次要色**：#50C878（绿色 - 成功、掌握）
- **强调色**：#FF6B6B（红色 - 提醒、重要）
- **背景色**：#F8F9FA（浅灰白）
- **卡片背景**：#FFFFFF（纯白）
- **文字主色**：#2C3E50（深灰）
- **文字次要**：#7F8C8D（中灰）

#### 字体设计
- **标题字体**：SF Pro Display Bold
  - 大标题：28pt
  - 标题：22pt
  - 副标题：18pt
- **正文字体**：SF Pro Text Regular
  - 正文：16pt
  - 说明：14pt
  - 小字：12pt

#### 间距系统
- **边距**：16pt（水平）、12pt（垂直）
- **卡片间距**：12pt
- **组件内间距**：16pt
- **小间距**：8pt

#### 圆角设计
- **大圆角**（卡片）：16pt
- **中圆角**（按钮）：12pt
- **小圆角**（标签）：8pt
- **圆形**（头像）：50%

### 2.3 组件设计

#### 单词卡片组件
- 尺寸：宽度100%，高度自适应（最小200pt）
- 内容：单词、音标、例句、图片
- 状态：学习中（蓝色边框）、已掌握（绿色）、需复习（红色角标）
- 动画：翻转动画（0.3s ease-in-out）

#### 短文卡片组件
- 尺寸：宽度100%，高度120pt
- 内容：短文缩略图、标题、学习进度条、单词数量
- 进度条颜色：根据完成度渐变（红→黄→绿）

#### 复习提醒组件
- 位置：首页顶部横幅
- 颜色：渐变背景（#4A90E2 → #7B68EE）
- 内容：复习单词数量、点击跳转按钮

---

## 3. 功能规格说明

### 3.1 核心功能

#### F1: 短文管理
- 显示所有短文列表
- 按进度筛选：全部/未学习/学习中/已完成
- 支持从相册导入短文图片
- 每篇短文显示：缩略图、标题、单词数、学习进度

#### F2: 单词学习
- 卡片式单词展示
- 显示内容：单词、音标、词性、中文释义、例句、图片
- 支持点击显示/隐藏答案
- 支持标记"认识"或"不认识"
- 学习完成后更新艾宾浩斯复习计划

#### F3: 艾宾浩斯遗忘曲线复习
- 复习时间节点：学习后 → 20分钟 → 1小时 → 1天 → 3天 → 7天 → 14天 → 30天
- 智能生成每日复习任务
- 推送本地通知提醒复习
- 根据记忆效果动态调整复习间隔

#### F4: 图片识别添加单词（OCR）
- 拍照或从相册选择图片
- 使用Vision框架识别图片中的英文单词
- 支持手动编辑识别的单词
- 一键添加多个单词到词库

#### F5: 学习进度追踪
- 记录每个单词的学习状态
- 记录每次复习的时间和结果
- 展示学习统计数据：
  - 今日学习单词数
  - 本周学习单词数
  - 总掌握单词数
  - 连续学习天数

### 3.2 用户交互流程

#### 学习流程
1. 用户进入首页 → 查看今日任务
2. 点击"开始学习" → 进入短文列表
3. 选择短文 → 查看短文内容（图片）
4. 开始学习该短文的单词
5. 对每个单词进行"认识/不认识"判断
6. 完成学习 → 更新复习计划

#### 复习流程
1. 用户进入首页 → 查看复习提醒
2. 点击"复习" → 进入复习模式
3. 查看单词卡片 → 回忆释义
4. 点击显示答案 → 判断是否记住
5. 系统根据判断结果更新下次复习时间

#### 添加单词流程
1. 用户点击"添加"标签
2. 选择拍照或从相册选图
3. 系统自动识别图片中的英文
4. 用户审核并编辑识别结果
5. 点击"保存"添加到个人词库

### 3.3 数据模型

#### Word（单词）
```swift
struct Word {
    let id: UUID
    var text: String              // 单词
    var phonetic: String?          // 音标
    var partOfSpeech: String?      // 词性
    var definition: String?        // 释义
    var exampleSentence: String?   // 例句
    var imageData: Data?          // 配图数据
    var articleId: String?         // 所属短文ID
    var createdAt: Date
    var lastReviewedAt: Date?
    var nextReviewDate: Date
    var reviewCount: Int           // 复习次数
    var masteryLevel: Int          // 掌握等级（1-5）
    var isMastered: Bool           // 是否已掌握
}
```

#### Article（短文）
```swift
struct Article {
    let id: UUID
    var title: String              // 短文标题
    var imagesData: [Data]         // 图片数据数组
    var wordIds: [UUID]            // 包含的单词ID列表
    var createdAt: Date
    var progress: Double           // 学习进度（0.0-1.0）
    var isCompleted: Bool
}
```

#### ReviewRecord（复习记录）
```swift
struct ReviewRecord {
    let id: UUID
    let wordId: UUID
    let reviewedAt: Date
    let result: ReviewResult       // remember/forgot
    let responseTime: TimeInterval // 反应时间
}
```

### 3.4 艾宾浩斯算法

#### 间隔计算公式
```
首次复习：20分钟后
第二次复习：1小时后
第三次复习：1天后
第四次复习：3天后
第五次复习：7天后
第六次复习：14天后
第七次复习：30天后
```

#### 记忆等级调整
- 回答正确：masteryLevel += 1（最高5）
- 回答错误：masteryLevel = 1（重置）

#### 下次复习间隔
```swift
func calculateNextReview(masteryLevel: Int) -> TimeInterval {
    let baseIntervals: [TimeInterval] = [
        20 * 60,                  // 20分钟
        60 * 60,                  // 1小时
        24 * 60 * 60,             // 1天
        3 * 24 * 60 * 60,         // 3天
        7 * 24 * 60 * 60,         // 7天
        14 * 24 * 60 * 60,        // 14天
        30 * 24 * 60 * 60         // 30天
    ]
    return baseIntervals[min(masteryLevel, baseIntervals.count - 1)]
}
```

---

## 4. 技术架构

### 4.1 技术栈
- **开发语言**：Swift 5.9+
- **UI框架**：SwiftUI
- **本地数据库**：SQLite.swift
- **图片处理**：Vision Framework（OCR）
- **推送通知**：UserNotifications

### 4.2 项目结构
```
WordMaster/
├── App/
│   ├── WordMasterApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Word.swift
│   ├── Article.swift
│   └── ReviewRecord.swift
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── TodayTaskCard.swift
│   ├── Articles/
│   │   ├── ArticleListView.swift
│   │   ├── ArticleDetailView.swift
│   │   └── ArticleCard.swift
│   ├── Learning/
│   │   ├── WordLearningView.swift
│   │   ├── WordCard.swift
│   │   └── ReviewView.swift
│   ├── Add/
│   │   ├── AddWordView.swift
│   │   └── ImagePicker.swift
│   ├── Statistics/
│   │   └── StatisticsView.swift
│   └── Settings/
│       └── SettingsView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── ArticleViewModel.swift
│   ├── LearningViewModel.swift
│   └── AddWordViewModel.swift
├── Services/
│   ├── DatabaseService.swift
│   ├── EbbinghausService.swift
│   ├── OCRService.swift
│   └── NotificationService.swift
├── Utilities/
│   ├── Constants.swift
│   └── Extensions.swift
└── Resources/
    └── Assets.xcassets
```

### 4.3 依赖管理
- **SQLite.swift**：本地数据库（通过Swift Package Manager）
- 内置框架：Vision、UserNotifications、PhotosUI

---

## 5. 验收标准

### 5.1 功能验收
- [ ] 可以查看所有短文列表
- [ ] 可以学习短文中的单词
- [ ] 单词按照艾宾浩斯曲线自动安排复习
- [ ] 可以通过拍照/选图识别英文单词
- [ ] 可以查看学习进度统计
- [ ] 可以收到复习提醒通知

### 5.2 UI验收
- [ ] 界面美观，遵循设计规范
- [ ] 动画流畅自然
- [ ] 支持深色模式
- [ ] 适配各种iPhone屏幕尺寸

### 5.3 性能验收
- [ ] 应用启动时间 < 2秒
- [ ] 页面切换流畅
- [ ] 图片加载无明显卡顿
- [ ] 数据库操作响应及时

---

## 6. 后续扩展

### Phase 2 功能
- 单词发音（TTS）
- 生词本导出/导入
- 学习小组/排行榜
- 云端同步

### Phase 3 功能
- AI智能释义
- 例句推荐
- 自定义复习计划
- Apple Watch配套应用
