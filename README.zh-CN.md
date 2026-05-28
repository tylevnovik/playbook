# Playbook

Playbook 是一个基于 Flutter 开发的现代、响应式且功能丰富的应用程序，用于管理 AI 角色扮演角色、世界设定（世界书/World Books）以及聊天对话。它支持完全自定义的 API 配置，允许您连接到任何兼容 OpenAI 接口标准的 API 端点。

[English](./README.md) | [简体中文](./README.zh-CN.md)

---

## 核心功能

- 🎭 **角色管理**：轻松创建、配置和修改 AI 角色。定义角色名称、头像、性格特征、Prompt 上下文、开场白及系统提示词。支持独立的角色管理视图以实现职责隔离。
- 📚 **世界设定（世界书）管理**：创建和维护背景设定条目、名词解释及背景大纲。让您的 AI 角色在对话过程中动态引用背景知识。
- 💬 **沉浸式聊天室**：
  - 支持完整 **Markdown** 语法渲染的对话泡泡。
  - 支持 Token 估算和实时验证的输入区域。
  - 多会话并发管理与聊天历史记录列表。
  - 👥 **多角色群聊与 AI-DM 跑团模式**：支持在单个聊天室中与多个角色同时进行角色扮演。AI 将充当跑团主持人 (DM) 进行剧情叙事与环境描写（使用 `[DM]` 前缀），并根据上下文扮演不同的角色进行对话输出（使用 `[角色名]` 前缀）。
  - 🧠 **智能上下文召回与自动摘要**：动态管理 Token 预算，当上下文超出阈值时自动调用 LLM 对早期对话进行智能摘要，并自动检索与匹配相关上下文。
- 🔮 **AI 设定提取器**：支持手动粘贴大段背景故事文本或选择分析已有对话历史，利用 AI 自动提取结构化的角色卡设定及世界观百科词条，并支持一键导入现有或新建的世界书中。
- 📌 **故事状态与追踪**：在聊天侧边栏配置面板中动态添加、编辑和开关 6 类故事状态约束（人物状态、地点状态、事件/伏笔、角色关系、写作禁忌、风格约束），确保 AI 在生成后续剧情时严格遵循世界观现状与逻辑现状。
- ⚙️ **自定义 API 配置**：设置自定义 API 端点（支持任何兼容 OpenAI 接口的服务）、自定义模型名称、API Key、Temperature 以及最大 Token 生成限制。
- 🎨 **现代化自适应 UI**：
  - 采用 Material 3 设计规范与 **Dynamic Color** 动态取色（支持与系统主题色同步）。
  - 完美支持 **深色模式 (Dark Mode)** 和浅色模式。
  - **自适应布局**：在移动端（底部导航/抽屉路由）与桌面端（展开/折叠侧边栏）之间无缝切换。
- 💾 **数据独立性与移植**：可将整个数据库（角色、世界书、聊天记录、所有配置）一键导出为单个文件，并支持在任意设备上随时导入恢复。
- 📡 **离线监测**：集成实时网络连接检测，在失去网络连接时提供顶部横幅警告，避免 API 请求失效。

---

## 技术栈

- **框架**：[Flutter](https://flutter.dev/) (SDK ^3.12.0)
- **状态管理**：[flutter_bloc](https://pub.dev/packages/flutter_bloc) (BLoC 模式)
- **本地数据库**：[sqflite](https://pub.dev/packages/sqflite) (在桌面端及 Web 端支持 FFI)
- **依赖注入**：[get_it](https://pub.dev/packages/get_it) & [injectable](https://pub.dev/packages/injectable)
- **路由**：[go_router](https://pub.dev/packages/go_router)
- **网络请求**：[dio](https://pub.dev/packages/dio)
- **主题化**：[dynamic_color](https://pub.dev/packages/dynamic_color)
- **富文本渲染**：[flutter_markdown](https://pub.dev/packages/flutter_markdown)

---

## 快速上手

### 环境准备

确保您的系统已安装了 [Flutter SDK](https://docs.flutter.dev/get-started/install)（推荐使用 Stable 稳定分支）。

### 安装与运行

1. **克隆仓库**：
   ```bash
   git clone https://github.com/tylevnovik/playbook.git
   cd playbook
   ```

2. **获取依赖包**：
   ```bash
   flutter pub get
   ```

3. **运行代码生成**：
   本项目使用 `build_runner` 和 `injectable` 进行依赖注入和序列化代码自动生成。请运行以下命令生成必要的代码文件：
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **启动应用**：
   - 运行到连接的设备（移动端、桌面端或 Web 浏览器）：
     ```bash
     flutter run
     ```
   - 编译 Release 版本：
     ```bash
     flutter build apk  # 编译 Android 安装包
     flutter build windows  # 编译 Windows 桌面程序
     flutter build web  # 编译 Web 应用
     ```

---

## 项目目录结构

```text
lib/
├── app.dart                               # 应用程序主入口 Widget
├── main.dart                              # 应用程序启动入口 main()
├── core/                                  # 公共与核心模块
│   ├── constants/                         # 全局常量及配置键值映射
│   ├── di/                                # 依赖注入配置 (injectable)
│   ├── error/                             # 异常与 Failures 定义
│   ├── localization/                      # 多语言本地化翻译逻辑
│   ├── theme/                             # 主题及调色板配置
│   └── utils/                             # 工具类 (Token 估算器、文件保存器、网络检测器)
├── data/                                  # 数据层实现
│   ├── datasources/                       # 本地数据库、SharedPreferences 和数据导入导出服务
│   ├── models/                            # 数据实体模型及序列化反序列化逻辑
│   └── repositories/                      # 数据仓库实现
├── domain/                                # 领域层 (抽象接口与纯实体)
│   ├── entities/                          # 纯实体模型类 (Character, Chat, Message, StoryState, WorldBook, LlmConfig)
│   └── repositories/                      # 仓库契约抽象类
└── presentation/                          # 表现层 (UI 界面与状态)
    ├── common/                            # 通用 UI 组件 (响应式组件、侧边栏、骨架组件)
    ├── router/                            # 路由配置 (go_router)
    └── features/                          # 具体业务功能页面
        ├── character/                     # 角色创建/编辑页面及 BLoC
        ├── chat/                          # 聊天会话页面、气泡、输入框、侧边栏(Drawer)及 BLoC
        ├── extractor/                     # AI 设定提取器页面及 BLoC
        ├── home/                          # 主页网格列表及 BLoC
        ├── settings/                      # 配置面板、主题设置、数据管理及 BLoC
        └── splash/                        # 闪屏加载页面
```

---

## 开源协议

本项目基于 MIT 协议开源 - 详情请参阅 LICENSE 文件。
