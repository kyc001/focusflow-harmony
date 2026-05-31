# UI/UX 重构与 AI 集成 - 技术设计

## 1. 架构边界

### 1.1 改动范围
**修改文件：**
- `entry/src/main/ets/pages/Index.ets` - 主要重构目标
- `entry/src/main/ets/services/FocusAiCoachService.ets` - 配置远程 AI
- `entry/src/main/resources/base/media/` - 新增视觉资源
- `HANDOVER.md` - 更新交接文档
- `设计文档.md` - 更新设计文档

**不改动：**
- RDB schema（`FocusDatabase.ets`）
- 数据模型（`FocusModels.ets`）
- 后端代码（`focus-server/`）
- 其他页面（`FocusSolo.ets`、`FocusCard.ets`）

### 1.2 兼容性约束
- 保持现有 RDB 数据结构不变
- 保持 `FocusStore` API 不变
- 保持 `focusAiCoachService` 接口不变
- 保持本地优先架构（远程 AI 失败时降级）

## 2. 信息架构重组

### 2.1 Tab 结构变更

**当前结构（5 个功能区）：**
```
登录页
└─ 主页面
   ├─ Tab 0: 今日
   ├─ Tab 1: 任务
   ├─ Tab 2: 专注
   ├─ Tab 3: 复盘
   └─ (资源功能混在复盘或设置中)
```

**新结构（3 个主 Tab + 独立流程）：**
```
登录页
└─ 主页面
   ├─ Tab 0: 今日
   │  ├─ Hero 卡片（学习状态概览）
   │  ├─ AI Coach 卡片（建议 + 刷新按钮）
   │  ├─ 快速添加任务
   │  └─ 下一步专注（点击进入独立专注流程）
   │
   ├─ Tab 1: 任务
   │  ├─ 搜索 + 筛选
   │  ├─ 任务列表
   │  └─ 回收站切换
   │
   └─ Tab 2: 我的
      ├─ 个人信息 + 登出
      ├─ 复盘统计（周报、项目占比、森林）
      ├─ 学习资源库（点击进入资源详情）
      └─ 设置（专注时长、AI 配置、通知）

独立流程（不占 Tab）：
├─ 专注计时器（全屏，从今日/任务进入）
└─ 资源详情（从"我的"进入）
```

### 2.2 导航流程

**核心路径：**
1. **快速专注**：今日 → 点击"下一步专注" → 专注计时器
2. **任务管理**：任务 Tab → 搜索/筛选 → 完成/删除
3. **复盘查看**：我的 Tab → 滚动到复盘区域
4. **资源管理**：我的 Tab → 学习资源库 → 资源详情

**状态管理：**
- 使用 `@State showFocusTimer: boolean` 控制专注计时器显示
- 使用 `@State showResourceDetail: boolean` 控制资源详情显示
- 专注计时器和资源详情作为 Modal/Overlay 覆盖在主页面上

## 3. 视觉设计系统

### 3.1 设计 Token

**颜色系统（保持现有，微调）：**
```typescript
// 页面背景 - 新增渐变
const PAGE_BG_START: string = '#F3F6FB';
const PAGE_BG_END: string = '#E8EDF5';

// 卡片背景 - 毛玻璃效果
const CARD_GLASS: string = '#F8FFFFFF'; // 97% 不透明
const CARD_GLASS_BLUR: number = 20;

// 保持现有颜色常量
const ACCENT: string = '#4258C9';
const ACCENT_DEEP: string = '#3142A2';
// ... 其他颜色
```

**间距系统（新增）：**
```typescript
const SPACING = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32
};
```

**圆角系统（新增）：**
```typescript
const RADIUS = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  full: 9999
};
```

**阴影系统（新增）：**
```typescript
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
```

### 3.2 毛玻璃效果实现

**应用范围：**
- 今日 Hero 卡片
- AI Coach 卡片
- 快速添加卡片
- 任务列表项卡片

**实现方式：**
```typescript
Column() {
  // 内容
}
.backgroundColor(CARD_GLASS)
.backdropBlur(CARD_GLASS_BLUR)
.borderRadius(RADIUS.lg)
.shadow(SHADOW_CARD)
```

**注意事项：**
- ArkUI 的 `backdropBlur` 需要底层有内容才能看到效果
- 页面背景使用渐变，确保毛玻璃有可模糊的内容
- 预览器可能不支持 blur，需要真机/模拟器验证

### 3.3 页面背景渐变

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

## 4. 组件拆分设计

### 4.1 @Builder 组件结构

**主容器：**
```typescript
@Entry
@Component
struct Index {
  @State activeTab: number = 0;
  @State showFocusTimer: boolean = false;
  @State showResourceDetail: boolean = false;
  // ... 其他状态

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

  @Builder MainPageBuilder() {
    Column() {
      Tabs({ index: this.activeTab }) {
        TabContent() {
          this.TodayTabBuilder();
        }.tabBar(this.TabBarBuilder('今日', 0, $r('app.media.focus_ui_next_marker')))

        TabContent() {
          this.TasksTabBuilder();
        }.tabBar(this.TabBarBuilder('任务', 1, $r('app.media.focus_ui_priority_flag')))

        TabContent() {
          this.ProfileTabBuilder();
        }.tabBar(this.TabBarBuilder('我的', 2, $r('app.media.focus_ui_settings_sliders')))
      }
      .onChange((index: number) => { this.activeTab = index; })
    }
  }

  @Builder TodayTabBuilder() { /* ... */ }
  @Builder TasksTabBuilder() { /* ... */ }
  @Builder ProfileTabBuilder() { /* ... */ }
  @Builder FocusTimerOverlayBuilder() { /* ... */ }
  @Builder ResourceDetailOverlayBuilder() { /* ... */ }
}
```

### 4.2 Today Tab 结构

```typescript
@Builder TodayTabBuilder() {
  Scroll() {
    Column({ space: SPACING.lg }) {
      // Hero 卡片
      this.TodayHeroCardBuilder();

      // AI Coach 卡片
      this.AiCoachCardBuilder();

      // 快速添加
      this.QuickAddCardBuilder();

      // 下一步专注
      this.NextFocusCardBuilder();

      // 今日待办列表
      this.TodayTaskListBuilder();
    }
    .padding({ left: SPACING.lg, right: SPACING.lg, top: SPACING.xxl })
  }
  .scrollBar(BarState.Off)
  .backgroundColor(Color.Transparent)
}
```

### 4.3 Profile Tab 结构

```typescript
@Builder ProfileTabBuilder() {
  Scroll() {
    Column({ space: SPACING.lg }) {
      // 个人信息卡片
      this.ProfileHeaderCardBuilder();

      // 复盘统计区域
      this.ReviewSectionBuilder();

      // 学习资源库区域
      this.ResourcesSectionBuilder();

      // 设置区域
      this.SettingsSectionBuilder();
    }
    .padding({ left: SPACING.lg, right: SPACING.lg, top: SPACING.xxl })
  }
  .scrollBar(BarState.Off)
}
```

## 5. AI 集成设计

### 5.1 远程 API 配置

**配置位置：**
`entry/src/main/ets/services/FocusAiCoachService.ets`

**默认配置更新：**
```typescript
defaultSettings(): AiCoachSettings {
  return {
    enabled: false, // 默认关闭，用户手动开启
    endpoint: 'https://token-plan-cn.xiaomimimo.com/anthropic',
    model: 'mimo-v2.5-pro',
    apiKey: '' // 空，需要用户在设置中填写
  };
}
```

**API Key 存储：**
- 保存在 Preferences `focus_ai` 中
- 设置 UI 不回显已保存的 key
- 输入框留空表示保留旧 key

### 5.2 AI Coach 调用流程

**调用时机：**
1. 用户点击"刷新建议"按钮
2. 完成任务后自动调用
3. 新增任务后自动调用

**调用逻辑：**
```typescript
async refreshAiCoach(): Promise<void> {
  // 检查缓存
  const now = Date.now();
  if (now - this.aiAdvice.generatedAt < 5 * 60 * 1000) {
    // 5 分钟内不重复请求
    return;
  }

  this.aiLoading = true;
  try {
    const advice = await focusAiCoachService.requestAdvice(
      this.tasks,
      this.records,
      this.settings,
      this.selectedTaskId
    );
    this.aiAdvice = advice;
  } catch (err) {
    // 失败降级到本地规则
    this.aiAdvice = focusAiCoachService.generateLocalAdvice(
      this.tasks,
      this.records,
      this.settings,
      this.selectedTaskId
    );
  } finally {
    this.aiLoading = false;
  }
}
```

**UI 状态显示：**
- 显示"上次更新：X 分钟前"
- 显示来源："本地规则" / "远程 AI"
- 刷新按钮带 loading 动画

### 5.3 Study Resources AI 提炼

**调用时机：**
- 用户选择资源后点击"AI 提炼"按钮

**调用逻辑：**
```typescript
async extractResourceInsight(resourceId: number): Promise<void> {
  const resource = this.resources.find(r => r.id === resourceId);
  if (!resource) return;

  this.resourceLoading = true;
  try {
    const insight = await focusAiCoachService.extractResourceInsight(
      resource.title,
      resource.content,
      resource.sourceType
    );
    this.latestResourceInsight = insight;
    
    // 保存到 RDB
    await focusStore.updateResourceInsight(resourceId, insight);
    this.syncFromStore();
  } catch (err) {
    // 失败降级到本地规则
    this.latestResourceInsight = focusAiCoachService.generateLocalResourceInsight(resource);
  } finally {
    this.resourceLoading = false;
  }
}
```

## 6. 视觉资源生成

### 6.1 App 图标

**设计要求：**
- 同心圆 + 中心点（专注聚焦符号）
- 渐变填充：`#4258C9` → `#7A60D0`
- 极简线条，现代感
- 1024x1024 尺寸

**生成 Prompt：**
```
A minimalist app icon design for a focus/productivity app. 
Concentric circles with a center dot, symbolizing focus and concentration.
Gradient from indigo blue (#4258C9) to purple (#7A60D0).
Clean geometric lines, modern style, flat design.
White or light background, suitable for rounded square app icon.
1024x1024 pixels.
```

**输出文件：**
- `entry/src/main/resources/base/media/app_icon.png` (1024x1024)
- 需要手动缩放为多尺寸（如果需要）

### 6.2 其他视觉资源（可选）

**启动页背景：**
- 可选，如果时间允许
- 与 App 图标风格一致的抽象背景

**UI 装饰元素：**
- 当前已有丰富的 `focus_ui_*.png` 资源
- 如果需要新元素，使用 spritesheet 策略

## 7. 数据流设计

### 7.1 状态管理

**不变：**
- 继续使用 `FocusStore` 作为数据门面
- 继续使用 RDB 作为持久化层
- 页面状态通过 `@State` 管理

**新增状态：**
```typescript
@State showFocusTimer: boolean = false; // 控制专注计时器显示
@State showResourceDetail: boolean = false; // 控制资源详情显示
@State aiLastRefreshTime: number = 0; // AI 上次刷新时间
```

### 7.2 事件流

**任务完成流程：**
```
用户点击完成
→ focusStore.toggleTask()
→ RDB 更新
→ focusStore.refresh()
→ syncFromStore()
→ refreshAiCoach() // 自动刷新 AI 建议
```

**进入专注流程：**
```
用户点击"开始专注"
→ this.showFocusTimer = true
→ FocusTimerOverlayBuilder 显示
→ 用户完成/中断
→ focusStore.recordPomodoro()
→ this.showFocusTimer = false
→ syncFromStore()
→ refreshAiCoach() // 自动刷新 AI 建议
```

## 8. 兼容性与降级

### 8.1 毛玻璃效果降级
- 预览器可能不支持 `backdropBlur`
- 降级方案：使用纯色背景 `CARD_BG`
- 真机/模拟器验证效果

### 8.2 AI 调用降级
- 远程 API 失败 → 本地规则
- 网络不可用 → 本地规则
- API Key 未配置 → 本地规则
- 所有降级都不阻塞主流程

### 8.3 构建兼容性
- 不修改 RDB schema，避免迁移问题
- 不修改 `FocusModels` 接口，避免类型错误
- 保持现有 import 路径不变

## 9. 风险与缓解

### 9.1 风险识别

**高风险：**
- Index.ets 重构可能引入 UI 渲染问题
- 毛玻璃效果在不同设备上表现不一致
- AI API 调用可能失败或超时

**中风险：**
- Tab 结构变更可能影响用户习惯
- 新的导航流程可能不够直观

**低风险：**
- 视觉资源生成质量不符合预期
- 文档更新遗漏

### 9.2 缓解措施

**代码层面：**
- 渐进式重构，每个 @Builder 独立测试
- 保留原有逻辑，只改 UI 结构
- 频繁构建验证，避免积累问题

**设计层面：**
- 毛玻璃效果提供降级方案
- AI 调用全部有本地降级
- 保持核心流程简单直观

**测试层面：**
- 每次改动后立即构建 HAP
- 在模拟器/真机验证关键流程
- 回归测试：添加任务、完成番茄、查看复盘

## 10. 实施顺序

详见 `implement.md`。

## 11. 验收标准

**功能完整性：**
- [ ] 3 个主 Tab 正常切换
- [ ] 专注计时器可以独立显示和关闭
- [ ] 资源详情可以独立显示和关闭
- [ ] AI Coach 可以手动刷新
- [ ] AI Coach 在任务变更后自动刷新
- [ ] Study Resources 可以 AI 提炼
- [ ] 所有原有功能（添加任务、完成番茄、查看复盘）正常工作

**视觉质量：**
- [ ] 毛玻璃效果在真机/模拟器上正常显示
- [ ] 页面背景渐变正常
- [ ] 卡片间距、圆角、阴影统一
- [ ] App 图标生成并应用

**技术质量：**
- [ ] HAP 构建成功
- [ ] 无 TypeScript 类型错误
- [ ] 无 ArkUI 布局警告
- [ ] RDB 数据读写正常
- [ ] AI 调用失败时降级正常

**文档完整性：**
- [ ] HANDOVER.md 更新
- [ ] 设计文档.md 更新
- [ ] 记录新的 UI 架构和设计系统
