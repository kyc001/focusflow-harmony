# 知序：实现局限与距成熟产品差距清单

> 用途：记录当前实现相对成熟产品的差距，供后续逐项补全。
> 论文处理原则：在第 4 章（实现）、第 5.4 节（结果分析）、第 6 章（展望）中**如实、正经、不夸大、不自嘲**地呈现；展望部分写成"未来发展方向"。
> 全部结论已逐项对照真实代码核对。

## 1. 服务卡片（FocusCard / EntryFormAbility）——静态演示数据
- **现状**：`FocusCard.ets` 使用硬编码静态数据（`title='知序 今日'`、`progress='4/6 番茄'`、`task1~3` 固定字符串、`Progress value=67` 写死）；`FormLink(action:'router')` 仅用于点击拉起 EntryAbility。
- **差距**：卡片不读取真实 RDB/Store 数据，不随任务与番茄进度更新；无 `onUpdateForm` 定时刷新；未做多卡片规格（2x2/2x4）的真实数据适配。
- **补全方向**：在 `EntryFormAbility` 的 `onAddForm/onUpdateForm` 中读取本地 RDB 今日快照，用 `formProvider.updateForm` + `formBindingData` 推送真实"今日任务/番茄进度"；按卡片尺寸适配；设置合理刷新周期。

## 2. 学习资料文件导入（DocumentViewPicker）——仅存 URI
- **现状**：文件导入只保存文件 URI + 用户备注，不复制文件、不解析 PDF/DOCX/PPTX 正文。
- **差距**：无法对文档全文做 AI 提炼；URI 可能因权限或文件移动而失效；无预览/缩略图。
- **补全方向**：申请并持有可持久化 URI 授权；接入文档文本抽取与 OCR，将正文喂给 AI 提炼；本地缓存关键内容；URI 失效检测与重新授权引导。

## 3. 后端同步（focus-server 已实现，移动端未接入）
- **现状**：后端已实现完整 `/api/sync`（`since` 增量 pull + `clientRequestId` 幂等 push）、`/api/user`(register/login)、projects/tasks/pomodoros CRUD、`/api/stats/summary`；但客户端登录是**本地伪 token**（`AuthRepository` 生成 `local-`/`guest-` token），`Index` 未调用 focus-server，无同步 UI、无冲突处理。
- **差距**：无真实账号体系（后端注册/登录未被客户端调用）；无多端数据同步；无冲突解决策略；无同步状态与失败重试提示。
- **补全方向**：客户端接入 `/api/user/login` 获取真实 token 并替换本地 token；实现同步 UI（手动 + 定时 pull/push）；基于 `updated_at` 的冲突合并（last-write-wins 或字段级合并）；同步进度、错误重试与离线队列；前后端端到端联调。

## 4. 首启种子演示数据（统计仍真实计算）
- **现状**：首次启动向 RDB 注入演示用 projects(4)/tasks(5)/pomodoros(5)/study_resources(3)（`SeedData.ets`）；复盘统计由 `FocusStore` 基于 RDB **真实计算**（非 H5 假数据），但初始内容是演示数据。
- **差距**：新用户可能误认为演示数据是自己的；缺少"清空演示/重置"开关与首次引导。
- **补全方向**：提供"清除演示数据/重置数据库"入口；首次启动引导用户创建首个项目与任务；为演示数据加标记便于一键清理。

## 5. AI 模块——依赖远程、无缓存/重试/本地模型
- **现状**：`FocusAiCoachService` 走兼容 Chat Completions 的远程接口，未启用/无 Key/非 2xx/空/不可解析时**显式状态降级**；无本地模型、无结果缓存、无重试退避。
- **差距**：离线无 AI；网络抖动无缓存回放；无速率/成本控制；提炼结果无质量校验。
- **补全方向**：提炼结果本地缓存与离线回放；超时重试与指数退避；可选本地小模型；提炼结果置信度展示与人工校正入口。

## 6. 白噪音 / AVPlayer——入口预留未实现
- **现状**：`Index` 中标注"AVPlayer 集成入口已预留"，`noise` 设置项存在但未真正播放音频。
- **差距**：白噪音设置不产生实际播放效果。
- **补全方向**：用 AVPlayer 播放 `rawfile` 白噪音，随专注开始/暂停/结束联动控制；支持音量与音轨切换。

## 7. 复盘可视化（ArkWeb + Canvas）
- **现状**：ArkWeb 加载 `rawfile/charts/index.html`，经 `javaScriptProxy('nativeBridge')` 注入统计 JSON，H5 用 Canvas 绘柱状图，桥接不可用时 `fallbackStats()` 兜底；`exportPng`/`shareReport` 桥接已声明。
- **差距**：图表类型单一（柱状）；导出/分享原生侧可能未完整实现；无统计时间范围切换。
- **补全方向**：补充折线/饼图/热力图与周期切换；完善 PNG 导出与系统分享；图表样式与主题统一。

## 8. 账号与密钥安全
- **现状**：API Key 以明文存于 `focus_ai` Preferences，UI 用 `maskedAiKey()` 掩码显示、留空保留旧值；登录 token 为本地生成。
- **差距**：Key 未加密存储；无设备级密钥库；无真实鉴权。
- **补全方向**：使用 HarmonyOS 通用密钥库/加密存储保存 Key；接入真实登录与最小权限；敏感配置脱敏审计。

## 9. 测试与工程化
- **现状**：以功能测试 + hvigor/Maven 构建验证 + 兼容性观察为主。
- **差距**：缺少自动化单元/集成测试与真机性能基准；CI 未建立。
- **补全方向**：补充 ArkTS 单测与后端接口测试；建立真机兼容性矩阵与性能基准；接入 CI 自动构建与检查。

---
小结：以上 9 项是"知序"从课程作品走向成熟产品的主要差距。论文将据此在展望章给出有优先级的演进路线（同步产品化 → 文档解析/OCR → 卡片真实数据 → AI 缓存/本地化 → 安全加固）。
