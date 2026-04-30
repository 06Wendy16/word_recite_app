# WordMaster - 安装和运行指南

## 项目概览

WordMaster 是一款基于艾宾浩斯遗忘曲线理论的 iOS 背单词应用，已完成开发。

## 项目结构

```
单词记忆app/
├── SPEC.md                 # 技术规格说明
├── project.yml             # XcodeGen 配置
├── README.md               # 项目说明
├── SETUP.md                # 本文件
├── 短文1-20/               # 短文图片文件夹
└── WordMaster/
    ├── App/                # 应用入口
    │   ├── WordMasterApp.swift
    │   └── ContentView.swift
    ├── Models/             # 数据模型
    │   ├── Word.swift
    │   └── Article.swift
    ├── Views/              # UI 视图
    │   ├── Home/
    │   ├── Articles/
    │   ├── Learning/
    │   ├── Add/
    │   └── Profile/
    ├── ViewModels/         # 视图模型
    ├── Services/          # 服务层
    │   ├── DatabaseService.swift
    │   ├── EbbinghausService.swift
    │   ├── OCRService.swift
    │   └── NotificationService.swift
    ├── Utilities/         # 工具类
    └── Resources/          # 资源文件
```

## 快速开始

### 1. 环境要求

- macOS 系统
- Xcode 15.0+
- XcodeGen
- iOS 16.0+ 模拟器或真机

### 2. 安装 XcodeGen

如果你还没有安装 XcodeGen，请先安装：

```bash
# 使用 Homebrew 安装
brew install xcodegen

# 或者使用 MacPorts
sudo port install xcodegen
```

### 3. 生成 Xcode 项目

在终端中进入项目目录：

```bash
cd 单词记忆app
xcodegen generate
```

这将生成 `WordMaster.xcodeproj` 文件。

### 4. 在 Xcode 中打开项目

```bash
open WordMaster.xcodeproj
```

### 5. 运行应用

1. 在 Xcode 中选择目标设备（模拟器或真机）
2. 按 `Cmd + R` 或点击运行按钮
3. 应用将编译并安装到设备上

## 短文导入说明

应用会自动从以下位置导入短文文件夹：
- 应用支持目录（Application Support）
- 文档目录

### 短文文件夹命名规则

文件夹必须以"短文"开头，例如：
- `短文1`
- `短文2`
- ...
- `短文20`

### 支持的图片格式

- `.jpg`
- `.jpeg`
- `.png`

## 主要功能

### 📚 短文学习
- 查看所有短文列表
- 按进度筛选（全部/未开始/学习中/已完成）
- 学习短文中的单词

### 🧠 艾宾浩斯复习
- 自动安排复习时间
- 复习间隔：20分钟 → 1小时 → 1天 → 3天 → 7天 → 14天 → 30天
- 智能提醒功能

### 📷 图片识别
- 拍照识别英文单词
- 从相册选择图片
- Vision Framework 文字识别

### 📊 学习统计
- 总词汇数
- 已掌握单词数
- 今日复习数
- 连续学习天数

## 数据存储

- SQLite 本地数据库
- 所有数据存储在本地设备
- 支持数据持久化

## 隐私说明

- 不收集任何个人信息
- 不包含任何广告
- 所有数据本地存储

## 常见问题

### Q: XcodeGen 生成项目失败？

确保已正确安装 XcodeGen：
```bash
xcodegen --version
```

### Q: 无法导入短文？

检查文件夹命名是否正确，确保以"短文"开头。

### Q: 图片识别不准确？

确保图片清晰、光照充足、文字清晰可读。

## 技术支持

如有问题，请查看：
- `SPEC.md` - 完整技术规格
- `README.md` - 项目说明
