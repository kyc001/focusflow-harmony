# App UI 重设计与功能修复

## 背景
当前 App 视觉上以白色为主，缺乏设计感。同时有几个功能问题需要修复。

## 需求清单

### R1. 改 App 名字
- **现状：** `AppScope/resources/base/element/string.json` 中 `app_name` 为 `"MyApplication"`
- **目标：** 改为 `"知序"`

### R2. 使用已有图标
- **现状：** 使用 DevEco Studio 默认的 `layered_image`（background.png + foreground.png）
- **目标：** 直接用 `app_icon.png` 替换。`app.json5` 和 `module.json5` 的 icon 字段改为 `"$media:app_icon"`
- **涉及文件：** `AppScope/app.json5`, `entry/src/main/module.json5`, `AppScope/resources/base/element/string.json`

### R3. 去掉"本地提炼"按钮
- **现状：** Index.ets:2700-2711 有"本地提炼"和"远程 AI"两个按钮
- **目标：** 删除"本地提炼"按钮，只保留"远程 AI"。如果没有配 API Key，点击时弹 toast 提示"请先在设置中配置 API Key"
- **涉及文件：** `entry/src/main/ets/pages/Index.ets`

### R4. 修复卡片显示不全
- **现状：** FocusCard.ets 内容固定，没有区分 2*2 和 2*4 尺寸
- **目标：**
  - 2*2：只显示标题 + 番茄进度条（精简模式）
  - 2*4：显示完整内容（标题 + Top3 任务 + 进度条）
- **技术方案：** 通过 `@StorageProp` 或环境变量传递 dimension，或使用条件布局判断可用高度
- **涉及文件：** `entry/src/main/ets/formpages/FocusCard.ets`, `entry/src/main/ets/entryformability/EntryFormAbility.ets`

### R5. UI 重设计 — 渐变增强
- **现状：** 浅色基调 (#F3F6FB)，已有 glass card 和暗色 hero 渐变，但整体单调
- **目标：** 在保留浅色基调的基础上，通过渐变增加层次感和设计感
- **具体改动：**
  1. **页面背景：** 从纯色改为微渐变 `PAGE_BG_START → PAGE_BG_END`
  2. **按钮：** 主要按钮改为渐变背景（如 ACCENT → ACCENT_DEEP 或紫蓝渐变）
  3. **Tab 栏：** 选中态从默认样式改为渐变下划线/渐变图标
  4. **Hero 卡片：** 渐变更丰富（紫蓝、靛青等），增加光晕装饰
  5. **卡片边框：** 毛玻璃卡片边框加入彩色微光
  6. **进度条/指标：** 使用渐变色替代纯色
- **约束：** 保持可读性，文字对比度不降低

## 不在本次范围
- 登录页面重设计
- 新增页面或 Tab
- 后端/API 改动

## 验收标准
- [ ] App 桌面显示名为"知序"
- [ ] 桌面图标为 app_icon.png 自定义图标
- [ ] 卡片 2*2 显示精简内容，2*4 显示完整内容
- [ ] "资料提炼"区域只有"远程 AI"按钮，无 Key 时有引导提示
- [ ] 整体视觉有渐变层次感，按钮/进度条/Tab 栏等有渐变效果
