# UI/UX 重构与 AI 集成 - 实施计划

## 实施原则

1. **渐进式重构**：每个步骤独立验证，避免大爆炸式改动
2. **频繁构建**：每完成一个步骤立即构建 HAP，确保不积累问题
3. **保持可回滚**：使用 git commit 记录每个里程碑
4. **本地优先**：AI 功能作为增强层，不阻塞核心流程

## 实施步骤

### Phase 1: 准备工作

#### 1.1 备份当前代码
```bash
git add -A
git commit -m "chore: backup before UI/UX refactor"
```

#### 1.2 生成 App 图标
- [ ] 调用生图 API 生成 App 图标
- [ ] 裁剪为 1024x1024
- [ ] 保存为 `entry/src/main/resources/base/media/app_icon.png`
- [ ] 验证图片可以正常打开

**生成命令：**
```bash
# 使用 WebFetch 或 curl 调用生图 API
# Prompt: "A minimalist app icon design for a focus/productivity app. Concentric circles with a center dot, symbolizing focus and concentration. Gradient from indigo blue (#4258C9) to purple (#7A60D0). Clean geometric lines, modern style, flat design. White or light background, suitable for rounded square app icon. 1024x1024 pixels."
```

**验证：**
```bash
# 使用 Python Pillow 验证图片
python -c "from PIL import Image; img = Image.open('entry/src/main/resources/base/media/app_icon.png'); print(f'Size: {img.size}, Mode: {img.mode}')"
```

---

### Phase 2: 视觉系统升级

#### 2.1 更新设计 Token
- [ ] 在 Index.ets 顶部添加新的设计常量
- [ ] 添加 `SPACING`、`RADIUS`、`SHADOW_CARD`、`SHADOW_FLOAT`
- [ ] 添加 `PAGE_BG_START`、`PAGE_BG_END`、`CARD_GLASS`、`CARD_GLASS_BLUR`

**代码位置：** `entry/src/main/ets/pages/Index.ets` 第 34 行后

**新增代码：**
```typescript
// 设计 Token
const SPACING = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32
};

const RADIUS = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  full: 9999
};

const SHADOW_CARD = {
  radius: 12,
  color: '#0B14260F',
  offsetX: 0,
  offsetY: 4
};

const SHADOW_FLOAT = {
  radius: 20,
  color: '#0B102620',
  offsetX: 0,
  offsetY: 8
};

const PAGE_BG_START: string = '#F3F6FB';
const PAGE_BG_END: string = '#E8EDF5';
const CARD_GLASS: string = '#F8FFFFFF';
const CARD_GLASS_BLUR: number = 20;
```

#### 2.2 应用页面背景渐变
- [ ] 找到主页面的根 Column
- [ ] 添加 `linearGradient` 背景

**代码位置：** Index.ets 的 `build()` 方法中的主 Column

**修改示例：**
```typescript
Column() {
  // 页面内容
}
.width('100%')
.height('100%')
.linearGradient({
  angle: 180,
  colors: [[PAGE_BG_START, 0.0], [PAGE_BG_END, 1.0]]
})
```

#### 2.3 验证构建
```bash
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

**预期结果：** BUILD SUCCESSFUL

---

### Phase 3: 信息架构重组

#### 3.1 添加新状态变量
- [ ] 在 Index 组件中添加 `@State showFocusTimer: boolean = false`
- [ ] 添加 `@State showResourceDetail: boolean = false`
- [ ] 添加 `@State aiLastRefreshTime: number = 0`

**代码位置：** Index.ets 第 97 行后（其他 @State 变量之后）

#### 3.2 修改 Tabs 结构
- [ ] 将 activeTab 的 Tabs 从 4 个改为 3 个
- [ ] Tab 0: 今日（保持）
- [ ] Tab 1: 任务（保持）
- [ ] Tab 2: 我的（新增，整合复盘+资源+设置）
- [ ] 移除原 Tab 2（专注）和 Tab 3（复盘）

**代码位置：** Index.ets 的 Tabs 组件

**修改策略：**
1. 先注释掉原 Tab 2 和 Tab 3
2. 添加新的 Tab 2（我的）
3. 验证构建通过

#### 3.3 提取 @Builder 组件
- [ ] 提取 `@Builder TodayTabBuilder()`
- [ ] 提取 `@Builder TasksTabBuilder()`
- [ ] 提取 `@Builder ProfileTabBuilder()`
- [ ] 提取 `@Builder FocusTimerOverlayBuilder()`
- [ ] 提取 `@Builder ResourceDetailOverlayBuilder()`

**实施顺序：**
1. 先提取 TodayTabBuilder，将现有 Tab 0 内容移入
2. 验证构建和功能
3. 提取 TasksTabBuilder，将现有 Tab 1 内容移入
4. 验证构建和功能
5. 创建 ProfileTabBuilder，整合复盘+资源+设置
6. 创建 FocusTimerOverlayBuilder，将原 Tab 2 专注内容移入
7. 创建 ResourceDetailOverlayBuilder

**代码位置：** Index.ets 底部（build() 方法之后）

#### 3.4 实现独立流程覆盖层
- [ ] 在 build() 方法中使用 Stack 包裹主页面
- [ ] 添加条件渲染：`if (this.showFocusTimer) { this.FocusTimerOverlayBuilder(); }`
- [ ] 添加条件渲染：`if (this.showResourceDetail) { this.ResourceDetailOverlayBuilder(); }`

**代码结构：**
```typescript
build() {
  Stack() {
    // 主页面
    if (this.isAuthed) {
      this.MainPageBuilder();
    } else {
      this.LoginPageBuilder();
    }

    // 独立流程覆盖层
    if (this.showFocusTimer) {
      this.FocusTimerOverlayBuilder();
    }
    if (this.showResourceDetail) {
      this.ResourceDetailOverlayBuilder();
    }
  }
}
```

#### 3.5 验证构建和功能
```bash
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

**手动测试：**
- [ ] 3 个 Tab 可以正常切换
- [ ] 今日页面显示正常
- [ ] 任务页面显示正常
- [ ] 我的页面显示正常（即使内容还不完整）

---

### Phase 4: 毛玻璃效果应用

#### 4.1 应用毛玻璃到今日 Hero 卡片
- [ ] 找到 TodayTabBuilder 中的 Hero 卡片 Column
- [ ] 修改 backgroundColor 为 `CARD_GLASS`
- [ ] 添加 `.backdropBlur(CARD_GLASS_BLUR)`
- [ ] 更新 borderRadius 为 `RADIUS.lg`
- [ ] 更新 shadow 为 `SHADOW_CARD`

**修改示例：**
```typescript
Column() {
  // Hero 内容
}
.backgroundColor(CARD_GLASS)
.backdropBlur(CARD_GLASS_BLUR)
.borderRadius(RADIUS.lg)
.shadow(SHADOW_CARD)
.padding(SPACING.xl)
```

#### 4.2 应用毛玻璃到其他卡片
- [ ] AI Coach 卡片
- [ ] 快速添加卡片
- [ ] 任务列表项卡片

**策略：** 逐个卡片应用，每次应用后验证构建

#### 4.3 更新间距和圆角
- [ ] 将所有硬编码的 `padding(16)` 改为 `padding(SPACING.xl)`
- [ ] 将所有硬编码的 `borderRadius(12)` 改为 `borderRadius(RADIUS.md)`
- [ ] 将卡片间距改为 `space: SPACING.lg`

#### 4.4 验证构建
```bash
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

**注意：** 毛玻璃效果需要在真机/模拟器上验证，预览器可能不支持

---

### Phase 5: AI 集成配置

#### 5.1 更新 AI 默认配置
- [ ] 打开 `entry/src/main/ets/services/FocusAiCoachService.ets`
- [ ] 修改 `defaultSettings()` 方法
- [ ] 更新 endpoint 为 `https://token-plan-cn.xiaomimimo.com/anthropic`
- [ ] 更新 model 为 `mimo-v2.5-pro`

**代码位置：** `FocusAiCoachService.ets` 的 `defaultSettings()` 方法

**修改后：**
```typescript
defaultSettings(): AiCoachSettings {
  return {
    enabled: false,
    endpoint: 'https://token-plan-cn.xiaomimimo.com/anthropic',
    model: 'mimo-v2.5-pro',
    apiKey: ''
  };
}
```

#### 5.2 实现 AI Coach 刷新逻辑
- [ ] 在 Index.ets 中添加 `refreshAiCoach()` 方法
- [ ] 实现 5 分钟缓存逻辑
- [ ] 实现远程调用 + 本地降级

**代码位置：** Index.ets 方法区域

**新增方法：**
```typescript
private async refreshAiCoach(): Promise<void> {
  const now = Date.now();
  if (now - this.aiLastRefreshTime < 5 * 60 * 1000) {
    this.aiSettingsMessage = '建议仍然有效，5 分钟内不重复请求';
    return;
  }

  this.aiLoading = true;
  this.aiSettingsMessage = '正在请求 AI 建议...';
  
  try {
    const advice = await focusAiCoachService.requestAdvice(
      this.tasks,
      this.records,
      this.settings,
      this.selectedTaskId
    );
    this.aiAdvice = advice;
    this.aiLastRefreshTime = now;
    this.aiSettingsMessage = `已更新（${advice.source}）`;
  } catch (err) {
    this.aiAdvice = focusAiCoachService.generateLocalAdvice(
      this.tasks,
      this.records,
      this.settings,
      this.selectedTaskId
    );
    this.aiLastRefreshTime = now;
    this.aiSettingsMessage = '远程失败，已降级到本地规则';
  } finally {
    this.aiLoading = false;
  }
}
```

#### 5.3 添加 AI Coach 刷新按钮
- [ ] 在 TodayTabBuilder 的 AI Coach 卡片中添加刷新按钮
- [ ] 绑定 `onClick: () => { this.refreshAiCoach(); }`
- [ ] 显示 loading 状态和上次更新时间

**UI 示例：**
```typescript
Row() {
  Text('AI 教练建议')
    .fontSize(18)
    .fontWeight(FontWeight.Bold)
  
  Blank()
  
  Text(this.formatAiRefreshTime())
    .fontSize(12)
    .fontColor(TEXT_MUTED)
  
  Button({ type: ButtonType.Circle }) {
    Image($r('app.media.focus_ui_ai_orb'))
      .width(20)
      .height(20)
  }
  .width(32)
  .height(32)
  .backgroundColor(this.aiLoading ? TEXT_DIM : ACCENT)
  .onClick(() => { this.refreshAiCoach(); })
}
```

#### 5.4 在任务变更后自动刷新
- [ ] 在 `addQuickTask()` 方法末尾调用 `this.refreshAiCoach()`
- [ ] 在 `toggleTask()` 方法末尾调用 `this.refreshAiCoach()`
- [ ] 在 `completePomodoro()` 方法末尾调用 `this.refreshAiCoach()`

#### 5.5 实现 Study Resources AI 提炼
- [ ] 在 ProfileTabBuilder 的资源库区域添加"AI 提炼"按钮
- [ ] 实现 `extractResourceInsight()` 方法
- [ ] 显示提炼结果

**代码位置：** Index.ets 方法区域

**新增方法：**
```typescript
private async extractResourceInsight(resourceId: number): Promise<void> {
  const resource = this.resources.find(r => r.id === resourceId);
  if (!resource) return;

  this.resourceLoading = true;
  this.resourceMessage = '正在 AI 提炼...';
  
  try {
    const insight = await focusAiCoachService.extractResourceInsight(
      resource.title,
      resource.content,
      resource.sourceType
    );
    this.latestResourceInsight = insight;
    await focusStore.updateResourceInsight(resourceId, insight);
    this.syncFromStore();
    this.resourceMessage = `已提炼（${insight.source}）`;
  } catch (err) {
    this.latestResourceInsight = focusAiCoachService.generateLocalResourceInsight(resource);
    this.resourceMessage = '远程失败，已降级到本地规则';
  } finally {
    this.resourceLoading = false;
  }
}
```

#### 5.6 验证构建
```bash
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

---

### Phase 6: Profile Tab 实现

#### 6.1 实现个人信息卡片
- [ ] 在 ProfileTabBuilder 顶部添加个人信息卡片
- [ ] 显示昵称、模式、登出按钮

#### 6.2 实现复盘统计区域
- [ ] 将原 Tab 3（复盘）的内容移入 ProfileTabBuilder
- [ ] 保持原有的 KPI、图表、森林成就
- [ ] 应用新的毛玻璃样式

#### 6.3 实现学习资源库区域
- [ ] 显示资源列表
- [ ] 添加"查看详情"按钮，点击后 `this.showResourceDetail = true`
- [ ] 添加"AI 提炼"按钮

#### 6.4 实现设置区域
- [ ] 将原有的专注时长、白噪音、通知设置移入
- [ ] 添加 AI 配置区域（endpoint、model、API key）
- [ ] 应用新的卡片样式

#### 6.5 验证构建和功能
```bash
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

**手动测试：**
- [ ] 我的 Tab 显示完整
- [ ] 复盘统计正常
- [ ] 资源列表正常
- [ ] 设置可以保存

---

### Phase 7: 专注计时器独立流程

#### 7.1 实现 FocusTimerOverlayBuilder
- [ ] 将原 Tab 2（专注）的内容移入 FocusTimerOverlayBuilder
- [ ] 使用全屏 Column 覆盖主页面
- [ ] 添加关闭按钮，点击后 `this.showFocusTimer = false`

**代码结构：**
```typescript
@Builder FocusTimerOverlayBuilder() {
  Column() {
    // 顶部关闭按钮
    Row() {
      Button('关闭')
        .onClick(() => { this.showFocusTimer = false; })
    }
    .width('100%')
    .padding(SPACING.lg)

    // 专注计时器内容
    Column() {
      // 原 Tab 2 的内容
    }
  }
  .width('100%')
  .height('100%')
  .backgroundColor('#F3F6FB')
}
```

#### 7.2 添加进入专注的入口
- [ ] 在 TodayTabBuilder 的"下一步专注"卡片中添加按钮
- [ ] 点击后 `this.showFocusTimer = true`

#### 7.3 验证构建和功能
```bash
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

**手动测试：**
- [ ] 点击"开始专注"后显示全屏计时器
- [ ] 计时器功能正常
- [ ] 点击关闭后返回今日页面

---

### Phase 8: 资源详情独立流程

#### 8.1 实现 ResourceDetailOverlayBuilder
- [ ] 创建全屏资源详情页面
- [ ] 显示资源标题、内容、AI 提炼结果
- [ ] 添加关闭按钮

#### 8.2 添加进入资源详情的入口
- [ ] 在 ProfileTabBuilder 的资源列表中添加"查看详情"按钮
- [ ] 点击后设置 `this.selectedResourceId` 并 `this.showResourceDetail = true`

#### 8.3 验证构建和功能
```bash
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

---

### Phase 9: 文档更新

#### 9.1 更新 HANDOVER.md
- [ ] 添加"UI/UX 重构（2026-05-27）"章节
- [ ] 记录新的信息架构（3 个 Tab + 独立流程）
- [ ] 记录新的视觉设计系统（毛玻璃、极简风）
- [ ] 记录 AI 集成配置和调用策略

**代码位置：** `HANDOVER.md` 第 2.7 节后

#### 9.2 更新设计文档.md
- [ ] 添加"UI/UX 设计系统"章节
- [ ] 记录设计 Token（间距、圆角、阴影）
- [ ] 记录毛玻璃效果实现
- [ ] 记录信息架构重组

**代码位置：** `设计文档.md` 第 10 节后

#### 9.3 验证文档完整性
- [ ] 检查 HANDOVER.md 是否记录了所有重要变更
- [ ] 检查设计文档.md 是否记录了设计系统
- [ ] 检查是否有遗漏的配置或注意事项

---

### Phase 10: 最终验证

#### 10.1 完整构建验证
```bash
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

**预期结果：** BUILD SUCCESSFUL

#### 10.2 功能回归测试
- [ ] 本地账户登录
- [ ] 游客模式登录
- [ ] 添加任务
- [ ] 完成任务
- [ ] 删除和恢复任务
- [ ] 开始专注计时器
- [ ] 完成番茄
- [ ] 中断番茄
- [ ] 查看复盘统计
- [ ] AI Coach 手动刷新
- [ ] AI Coach 自动刷新（完成任务后）
- [ ] Study Resources AI 提炼
- [ ] 设置保存（专注时长、AI 配置）

#### 10.3 视觉验证（真机/模拟器）
- [ ] 页面背景渐变正常
- [ ] 毛玻璃效果正常
- [ ] 卡片间距、圆角、阴影统一
- [ ] App 图标显示正常

#### 10.4 代码质量检查
```bash
git diff --check
```

**预期结果：** 无 trailing whitespace

#### 10.5 密钥扫描
```bash
rg "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}" .
```

**预期结果：** 无匹配（API key 不应提交到代码库）

---

## 验证命令汇总

### 构建验证
```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

### 图片验证
```bash
python -c "from PIL import Image; import os; [print(f'{f}: {Image.open(f).size}') for f in os.listdir('entry/src/main/resources/base/media') if f.startswith('focus_') and f.endswith('.png')]"
```

### 代码质量
```bash
git diff --check
```

### 密钥扫描
```bash
rg "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}" .
```

---

## 回滚计划

如果某个 Phase 出现严重问题，可以回滚到上一个 Phase 的 commit：

```bash
git log --oneline -10
git reset --hard <commit-hash>
```

**建议：** 每完成一个 Phase 都创建一个 commit，方便回滚。

---

## 时间估算

- Phase 1: 准备工作 - 30 分钟
- Phase 2: 视觉系统升级 - 1 小时
- Phase 3: 信息架构重组 - 2 小时
- Phase 4: 毛玻璃效果应用 - 1 小时
- Phase 5: AI 集成配置 - 1.5 小时
- Phase 6: Profile Tab 实现 - 1.5 小时
- Phase 7: 专注计时器独立流程 - 1 小时
- Phase 8: 资源详情独立流程 - 1 小时
- Phase 9: 文档更新 - 30 分钟
- Phase 10: 最终验证 - 1 小时

**总计：约 11 小时**

---

## 注意事项

1. **频繁构建**：每个 Phase 完成后立即构建，不要积累问题
2. **保持可回滚**：每个 Phase 完成后 commit，方便回滚
3. **本地优先**：AI 功能失败不应阻塞核心流程
4. **真机验证**：毛玻璃效果需要在真机/模拟器上验证
5. **密钥安全**：不要提交 API key 到代码库
6. **文档同步**：代码改动后立即更新文档

---

## 完成标志

当以下所有项都完成时，任务完成：

- [ ] HAP 构建成功
- [ ] 所有功能回归测试通过
- [ ] 视觉效果在真机/模拟器上验证通过
- [ ] AI 调用跑通（远程 + 本地降级）
- [ ] HANDOVER.md 和设计文档.md 更新完成
- [ ] 代码质量检查通过
- [ ] 密钥扫描通过
- [ ] 最终 commit 并 push
