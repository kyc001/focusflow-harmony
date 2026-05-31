# 知序 (ZhiXu) - HarmonyOS 学习管理应用

面向大学生的 HarmonyOS 学习闭环应用，覆盖资料、任务、专注、复盘、AI 提炼和后端同步。

## 项目结构

```text
├── entry/                    # HarmonyOS 前端 ArkTS
│   ├── src/main/ets/
│   │   ├── pages/            # 今日/任务/资料/专注/复盘等页面
│   │   ├── services/         # RDB、Preferences、AI、同步、白噪音服务
│   │   ├── models/           # 数据模型
│   │   └── focusability/     # FocusAbility 独立专注窗口
│   └── src/main/resources/rawfile/  # 室外/海边/虫鸣白噪音
├── focus-server/             # Spring Boot + MyBatis 后端
│   ├── src/main/java/com/focus/server/
│   │   ├── controller/       # REST 接口
│   │   ├── entity/           # User/Project/Task/Pomodoro
│   │   ├── mapper/           # MyBatis Mapper
│   │   └── dto/              # 请求与响应对象
│   └── src/main/resources/
│       ├── init.sql          # H2 数据库初始化
│       ├── application.yml   # 默认 H2 文件数据库
│       └── mapper/           # Mapper XML
├── tools/                    # 项目自带 JDK 21 + Maven 3.9.10
├── report/                   # 课程论文与答辩材料
├── 白噪音/                   # 原始音频素材
├── setup-backend-env.ps1
└── start-backend.ps1
```

## 硬指标对齐

- 前端：HarmonyOS / ArkTS，不交安卓。
- 架构：按 MVVM 分层，`models` 保存模型，`services` 封装数据与网络，`FocusStore` 作为页面状态门面。
- 页面：今日、任务、资料、专注、复盘、设置/同步等功能均有真实操作。
- 后端：Spring Boot + MyBatis，提供登录、CRUD、统计和同步接口。
- 数据库：鸿蒙端 RDB 保存本地数据；后端启动脚本默认使用 MySQL，也可切换到 H2 文件数据库快速测试。
- 闭环：资料经 AI 提炼生成任务，任务进入番茄专注，完成记录写入 RDB，复盘统计展示，并可同步到后端数据库。

## 快速启动后端

```powershell
.\start-backend.ps1
```

默认使用 MySQL profile。首次使用 MySQL 前请先在本机 MySQL 中执行 `focus-server/src/main/resources/init-mysql.sql`，创建 `focus_db` 和演示账号。

如果只是做课堂演示或接口测试，可以使用 H2：

```powershell
.\start-backend.ps1 -DbProfile h2
```

默认地址：

`http://localhost:8080`

演示账号：

- 用户名：`demo`
- 密码：`secret`

## 前端运行

推荐使用项目脚本构建，脚本会强制使用 DevEco Studio 自带 JBR，避免系统 Java 注册表异常影响 `PackageApp`：

```powershell
.\build-frontend.ps1
```

也可以打开 DevEco Studio 后选择本项目根目录，执行 Build → Build Hap(s)/APP(s)，再在真机或模拟器运行。

## 核心功能

### 资料库

- 笔记、链接、课件、文件引用录入。
- 远程 AI 默认联网接入，生成摘要、要点和下一步任务。
- 一键把资料提炼结果转为专注任务。

### 任务管理

- 优先级、截止时间、搜索筛选、软删除和回收站恢复。
- `tags/subtasks` 使用 JSON 映射，前后端同步字段完整。

### 番茄专注

- 内嵌专注页 + FocusAbility 独立窗口。
- AVPlayer 循环播放本地 rawfile 白噪音：室外、海边、虫鸣。
- 完成和中断均写入番茄记录，用于后续复盘。

### 复盘统计

- 本周专注时长、项目占比、完成率、中断率、连续打卡。
- ArkWeb Canvas 图表嵌入展示。

### 后端同步

- 登录后端账号。
- `pull + push` 双向同步项目、任务和番茄记录。
- 后端数据库持久化，形成前端、服务器、数据库闭环。

## 技术栈

**前端**：HarmonyOS API 22, ArkTS, ArkUI, RDB, Preferences, AVPlayer, ArkWeb  
**后端**：Spring Boot 3.2, MyBatis, H2/MySQL  
**工具**：DevEco Studio, JDK 21, Maven 3.9.10, LaTeX
