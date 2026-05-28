# 设计方案: App UI 重设计与功能修复

## 1. 改名 & 图标

### 改名
- 修改 `AppScope/resources/base/element/string.json` 的 `app_name` 值

### 图标
- `app.json5` 的 `icon` 改为 `"$media:app_icon"`
- `module.json5` 的 EntryAbility `icon` 改为 `"$media:app_icon"`
- `module.json5` 的 `startWindowIcon` 改为 `"$media:app_icon"`
- 确认 `app_icon.png` 在两个 media 目录都存在（AppScope 和 entry）

## 2. 去掉本地提炼按钮

**改动位置：** `Index.ets` 约 2700-2711 行

删除"本地提炼"按钮，"远程 AI"按钮改为全宽。onClick 中先检查 `aiSettings.enabled && aiSettings.apiKey.length > 0`，不满足则 `promptAction.showToast({ message: '请先在设置中配置 API Key' })` 并 return。

同时删除 `extractResource` 方法中 `useRemote` 参数和本地分支，统一走远程路径（远程方法内部已有 fallback 到本地的逻辑）。

## 3. 卡片尺寸适配

**问题：** FocusCard 在 2*2 空间内塞了标题 + 3个任务 + 进度条，显示不全。

**方案：** 使用鸿蒙 `AppStorage` 传递 form dimension。

- `EntryFormAbility.onAddForm` 中根据 `formInfo.dimension` 设置不同的 bindingData
- FocusCard 通过 `@StorageProp` 读取 dimension
- 2*2 模式：只显示标题 + 番茄进度条（隐藏 Top3 任务区域）
- 2*4 模式：显示完整内容

**备选方案：** 如果 form dimension 传递困难，可以通过 `formBindingData` 的 data 对象传递一个 `isCompact: boolean` 字段。

## 4. 渐变增强设计系统

### 4.1 新增设计 Token

```typescript
// 渐变色板
const GRADIENT_PRIMARY: string[][] = [['#6366F1', 0.0], ['#4F46E5', 1.0]]; // 靛蓝渐变
const GRADIENT_ACCENT: string[][] = [['#818CF8', 0.0], ['#6366F1', 1.0]]; // 浅靛蓝
const GRADIENT_SUCCESS: string[][] = [['#34D399', 0.0], ['#10B981', 1.0]]; // 翡翠绿
const GRADIENT_HERO: string[][] = [['#4338CA', 0.0], ['#6D28D9', 0.5], ['#7C3AED', 1.0]]; // 紫蓝 hero

// 页面背景渐变
const PAGE_BG_GRADIENT: string[][] = [['#F0F2FF', 0.0], ['#E8ECF8', 0.5], ['#F3F6FB', 1.0]];
```

### 4.2 页面背景
- 将 Stack 根容器改为 linearGradient，角度 180，使用 PAGE_BG_GRADIENT
- 替代当前的纯色 PAGE_BG

### 4.3 按钮渐变
- 主要按钮（"远程 AI"、"开始专注"、"生成任务"等）使用 GRADIENT_PRIMARY 渐变
- 次要按钮保持纯色或 soft 色
- 按钮增加微妙的阴影

### 4.4 Tab 栏
- 选中态：图标和文字使用 ACCENT 色（保持不变）
- 增加选中态渐变下划线（3px 高，GRADIENT_PRIMARY 渐变，圆角）
- 背景保持毛玻璃效果

### 4.5 Hero 卡片
- TodayHeroCard 和 ProfileHeaderCard 渐变改为 GRADIENT_HERO（紫蓝三色渐变）
- 增加装饰性光晕（一个半透明圆形 radialGradient 在右上角）

### 4.6 卡片增强
- 毛玻璃卡片边框从纯色改为带微弱彩色的渐变边框
- 使用 borderColor + gradient mask 实现（或改为两层 Stack，外层渐变 + 内层毛玻璃）

### 4.7 进度条
- Progress 组件的 color 改为渐变色（通过 overlay 或自定义 Builder 实现）
- 或使用 linearGradient 装饰的 Row 替代系统 Progress 组件

## 文件影响范围

| 文件 | 改动类型 |
|------|----------|
| `AppScope/resources/base/element/string.json` | 改名 |
| `AppScope/app.json5` | 改图标引用 |
| `entry/src/main/module.json5` | 改图标引用 |
| `entry/src/main/ets/pages/Index.ets` | 去本地提炼 + 渐变增强 + Tab 栏 |
| `entry/src/main/ets/formpages/FocusCard.ets` | 尺寸适配 |
| `entry/src/main/ets/entryformability/EntryFormAbility.ets` | 传递 dimension |
