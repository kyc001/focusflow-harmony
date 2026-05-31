# 知序 (ZhiXu) - HarmonyOS 学习管理应用

面向大学生的本地优先学习闭环应用,覆盖资料·任务·专注·复盘全流程。

## 项目结构

```
├── entry/                    # HarmonyOS 前端(ArkTS)
│   ├── src/main/ets/
│   │   ├── pages/           # Index 主页面 + FocusSolo 独立专注
│   │   ├── services/        # FocusDatabase, FocusSyncService, FocusAmbientService
│   │   ├── models/          # 数据模型
│   │   └── focusability/    # FocusAbility 独立窗口
│   └── src/main/resources/rawfile/  # 白噪音音频(室外/海边/虫鸣)
├── focus-server/            # Spring Boot 后端(可选云同步)
│   ├── src/main/java/com/focus/server/
│   │   ├── controller/      # REST 接口
│   │   ├── entity/          # Task(含 tags_json/subtasks_json)
│   │   ├── mapper/          # MyBatis Mapper
│   │   └── service/
│   └── src/main/resources/
│       ├── init.sql         # 数据库初始化
│       └── mapper/          # Mapper XML
├── report/                  # 课程论文(LaTeX)
│   └── nku-thesis-template-2020/
│       ├── main.tex         # 主文件
│       ├── course-report.tex # 正文(7章,25页)
│       └── main.pdf         # 已生成 PDF
├── tools/                   # 本地编译工具
│   ├── jdk-21/             # JDK 21 (321MB)
│   └── maven/              # Maven 3.9.10 (10MB)
├── 白噪音/                  # 原始音频素材
└── setup-backend-env.ps1   # 后端环境配置脚本

```

## 课程知识点覆盖

✅ **HarmonyOS 核心能力**
- UIAbility 生命周期 (EntryAbility / FocusAbility)
- Want 参数传递 (跨 Ability 数据共享)
- AppStorage 状态同步
- Tabs 页面切换 (今日/任务/资料/专注/复盘)
- Navigation 路由跳转

✅ **数据持久化**
- RDB 关系型数据库 (focus.db, 4张表)
- Preferences 轻量级配置 (设置/登录态)

✅ **网络与多媒体**
- http 模块 (AI 请求 + 云同步)
- AVPlayer 音频播放 (白噪音循环)
- ArkWeb H5 嵌入 (复盘图表 Canvas)

✅ **架构模式**
- MVVM (FocusStore 作为 ViewModel)
- 本地优先 + 可选增强 (AI/云同步)

✅ **后端全栈**
- Spring Boot + MyBatis
- RESTful 接口 (/api/sync/pull, /api/sync/push)
- MySQL 数据库

## 快速开始

### 前端编译 (DevEco Studio)
1. 打开 DevEco Studio
2. File → Open → 选择项目根目录
3. Build → Build Hap(s)/APP(s)
4. 真机/模拟器运行

### 后端编译 (本地工具)
```powershell
# 1. 配置环境(使用项目本地 JDK + Maven)
. .\setup-backend-env.ps1

# 2. 编译打包
cd focus-server
mvn clean package -DskipTests

# 3. 运行后端
java -jar target\focus-server-0.0.1-SNAPSHOT.jar

# 4. 访问 http://localhost:8080
```

### 论文编译
```powershell
cd report\nku-thesis-template-2020
xelatex main.tex
biber main
xelatex main.tex
xelatex main.tex
# 生成 main.pdf (25页)
```

## 核心功能

### 1. 资料库 (StudyResource)
- 多类型录入: 笔记/链接/课件/文件引用
- AI 提炼: 摘要 + 关键要点 (可选,需配置 API Key)
- 生成任务: 资料 → 可执行任务

### 2. 任务管理 (FocusTask)
- 四象限视图 (优先级 + 截止时间)
- 搜索筛选 (标题/备注/标签)
- 软删除 + 回收站恢复
- tags/subtasks 支持 (云同步完整映射)

### 3. 番茄专注
- 内嵌模式 + 独立窗口 (FocusAbility)
- 白噪音播放 (室外/海边/虫鸣, AVPlayer 循环)
- 完成/中断记录 (写入 pomodoros 表)
- 后台保护 + 通知提醒

### 4. 复盘统计
- 本周专注时长 / 项目占比
- 完成率 / 中断率 / 连续打卡
- ArkWeb 图表 (Canvas 渲染)

### 5. 云同步 (可选)
- 登录后端 (用户名/密码)
- 双向同步 (pull + push)
- tags/subtasks JSON 映射
- 离线优先,同步增强

## 答辩准备

### 提交材料
- [x] 论文 PDF (main.pdf, 25页)
- [x] 源代码压缩包 (前端 + 后端)
- [ ] 答辩 PPT (5分钟技术路线)
- [ ] 程序运行录屏 (EV 录屏)

### 评分维度
- ✅ 选题新颖度: 本地优先 + AI 增强学习闭环
- ✅ 完整度: 资料/任务/专注/复盘全流程
- ✅ 技术新颖/高端: HarmonyOS 平台能力全覆盖
- ✅ 页面复杂度: 5个核心页面 + 独立专注窗口
- ✅ 后台/数据库: Spring Boot + MySQL + RDB
- ✅ 论文格式规范: 南开本科模板,7章完整结构

### 答辩重点 (5分钟)
1. **技术路线** (3分钟)
   - HarmonyOS Stage 模型 + ArkTS 声明式 UI
   - RDB 本地持久化 + Preferences 配置
   - AVPlayer 白噪音 + ArkWeb 图表
   - Spring Boot 云同步 (可选增强)
   
2. **核心创新** (1分钟)
   - 本地优先架构 (离线可用)
   - 资料 → 任务 → 专注 → 复盘闭环
   - AI 增强 (可选,不伪造结果)

3. **演示** (1分钟)
   - 快速添加任务 → 开启番茄 → 白噪音播放 → 完成记录 → 复盘统计

## 技术栈

**前端**: HarmonyOS API 22, ArkTS, ArkUI  
**后端**: Spring Boot 3.x, MyBatis, MySQL 8.0  
**工具**: DevEco Studio, JDK 21, Maven 3.9.10, LaTeX

## 作者

柯云超 (2413575) - 南开大学计算机学院  
指导教师: 刘嘉欣, 董前琨, 张彪

---

**课程**: 移动应用开发 (2026春季)  
**完成时间**: 2026年5月
