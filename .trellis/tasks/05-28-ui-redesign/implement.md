# 执行计划: App UI 重设计与功能修复

## 执行顺序

### Step 1: 改名 & 图标 [简单，无风险]
1. 修改 `AppScope/resources/base/element/string.json`：`app_name` → `"知序"`
2. 修改 `AppScope/app.json5`：icon → `"$media:app_icon"`
3. 修改 `entry/src/main/module.json5`：
   - EntryAbility icon → `"$media:app_icon"`
   - startWindowIcon → `"$media:app_icon"`
4. 确认 `AppScope/resources/base/media/app_icon.png` 存在（如不存在则从 entry 目录复制）

### Step 2: 去掉本地提炼按钮 [简单]
1. 删除 Index.ets 中"本地提炼"按钮（约 2700-2711 行）
2. "远程 AI"按钮改为全宽
3. 在 onClick 中加入 API Key 检查，无 Key 时 showToast 提示
4. 简化 `extractResource` 方法，移除 `useRemote` 参数

### Step 3: 渐变增强 — 设计 Token [中等]
1. 在 Index.ets 设计 Token 区域（约 35-109 行）新增渐变色板常量
2. 定义 GRADIENT_PRIMARY, GRADIENT_HERO, PAGE_BG_GRADIENT 等

### Step 4: 渐变增强 — 页面背景 [简单]
1. 修改主 Stack 的背景，从纯色 backgroundColor 改为 linearGradient
2. 使用 PAGE_BG_GRADIENT

### Step 5: 渐变增强 — 按钮 [中等]
1. 所有主要按钮改为 linearGradient 背景
2. 次要按钮保持纯色
3. 涉及按钮：远程 AI、开始专注、生成任务、添加任务等

### Step 6: 渐变增强 — Tab 栏 [中等]
1. 修改 Tab 栏选中态，增加渐变下划线
2. 可能需要自定义 tabBar Builder 替代默认样式

### Step 7: 渐变增强 — Hero 卡片 [简单]
1. TodayHeroCard 渐变改为 GRADIENT_HERO
2. ProfileHeaderCard 渐变改为 GRADIENT_HERO
3. 增加装饰性光晕效果

### Step 8: 渐变增强 — 卡片 & 进度条 [中等]
1. 进度条改为渐变色
2. 卡片边框增加微弱彩色光

### Step 9: 卡片尺寸适配 [中等]
1. EntryFormAbility 中根据 dimension 传递 isCompact
2. FocusCard 根据 isCompact 条件渲染
3. 2*2: 标题 + 进度条
4. 2*4: 完整内容

## 验证命令
- 编译：DevEco Studio Build
- 安装到模拟器/真机检查：
  - 桌面图标和名字
  - 卡片 2*2 / 2*4 显示
  - 提炼按钮行为
  - 各页面渐变效果

## 回滚点
- Step 1 完成后：改名 & 图标可独立回滚
- Step 2 完成后：提炼按钮可独立回滚
- Step 3-8：渐变增强为纯视觉改动，可整体回滚
- Step 9：卡片适配可独立回滚
