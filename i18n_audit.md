# sprout i18n 审计

## 已审计范围

- 代码目录：`sprout/Features/Home`、`sprout/Features/Growth`、`sprout/Features/Treasure`、`sprout/Features/Shell`
- 领域与格式化：`sprout/Domain/Records`、`sprout/Domain/Growth`、`sprout/Domain/Treasure`
- 工程配置：`sprout/Info.plist`、`sprout.xcodeproj/project.pbxproj`
- 测试：`sproutTests/*` 中与文案、格式化、toast、周信、AI 卡相关的断言
- 未纳入本轮：根目录 PRD/规格文档、已删除的 `firstgrowth/*` 历史路径

## 发现的问题清单

### 1. 国际化基础设施现状

- 当前仓库未发现 `Localizable.strings`、`InfoPlist.strings`、`.xcstrings`，也未发现 `NSLocalizedString`、`String(localized:)`、`LocalizedStringKey` 的工程化接线。
- 工程虽然开启了 `STRING_CATALOG_GENERATE_SYMBOLS = YES` 与 `SWIFT_EMIT_LOC_STRINGS = YES`，但没有实际字符串资源文件可承接。
- `sprout.xcodeproj/project.pbxproj:169` 的 `developmentRegion = en`，`knownRegions` 只有 `en` 和 `Base`；当前代码主体却是中文硬编码，默认区域与实际内容不一致。

### 2. 硬编码中文字符串

#### 首页记录

- 模块与导航：`sprout/Features/Home/HomeModels.swift:11`、`sprout/Features/Shell/MagazineTopBar.swift:44`
- 顶部情绪头图与天数句式：`sprout/Features/Home/Components/EmotionHeaderBlock.swift:23`
- 空状态：`sprout/Features/Home/Components/RecordHomeScrollView.swift:58`
- 悬浮操作区：`sprout/Features/Home/Components/FloatingActionBar.swift:15`
- 睡眠状态条与睡眠弹层：`sprout/Features/Home/Components/OngoingStateBar.swift:20`、`sprout/Features/Home/Sheets/SleepControlSheet.swift:8`
- 奶量/亲喂/辅食/尿布各 sheet：`sprout/Features/Home/Sheets/MilkLoggingSheet.swift`、`sprout/Features/Home/Sheets/NursingTimerTab.swift:28`、`sprout/Features/Home/Sheets/BottleLoggingTab.swift:35`、`sprout/Features/Home/Sheets/FoodRecordSheet.swift:18`、`sprout/Features/Home/Sheets/DiaperRecordSheet.swift:10`
- Toast 与撤销：`sprout/Features/Home/Components/UndoToast.swift:17`
- Store 内成功文案：`sprout/Features/Home/HomeStore.swift:245`、`258`、`276`、`295`

#### 成长模块

- 指标标题、空态、副标题、录入标题：`sprout/Domain/Growth/GrowthModels.swift:11`、`40`、`49`
- Meta 信息、AI 卡、年龄/相对时间、数值格式：`sprout/Domain/Growth/GrowthFormatter.swift:43`、`57`、`75`、`125`、`160`
- 图表与空态提示：`sprout/Features/Growth/Components/GrowthLifeLineChartCard.swift:12`、`173`
- AI 卡标题与交互无障碍：`sprout/Features/Growth/Components/GrowthAIWhisperCard.swift:11`
- 录入面板与按钮：`sprout/Features/Growth/Sheets/GrowthRecordSheet.swift:35`、`GrowthManualInputPanel.swift:14`、`GrowthRulerPicker.swift:22`、`GrowthRecordEntryButton.swift:8`
- Store 错误与成功 toast：`sprout/Features/Growth/GrowthStore.swift:149`、`177`、`224`

#### 珍藏模块

- 周信生成整句：`sprout/Domain/Treasure/WeeklyLetterComposer.swift:63`、`88`、`101`
- 月锚点与时间胶囊标题：`sprout/Domain/Treasure/TreasureMonthAnchorBuilder.swift:34`、`sprout/Features/Treasure/Cards/TreasureWeeklyLetterCard.swift:24`
- 空状态、月穿梭提示、悬浮按钮：`sprout/Features/Treasure/Components/TreasureEmptyState.swift:42`、`TreasureMonthScrubber.swift:16`、`TreasureFloatingAddButton.swift:13`
- 记忆卡失败提示：`sprout/Features/Treasure/Cards/TreasureMemoryCard.swift:26`
- 新建记忆全量弹层：`sprout/Features/Treasure/Sheets/TreasureComposeModal.swift:62` 到 `418`
- Store 错误与成功 toast：`sprout/Features/Treasure/TreasureStore.swift:76`、`303`、`307`、`369`、`395`

#### 设置/侧边栏

- 侧边栏头部、索引、说明文案全部硬编码中文：`sprout/Features/Shell/SidebarDrawer.swift:42`、`49`、`62`、`96`、`145`
- 侧边栏与头像 accessibility 文案：`sprout/Features/Shell/MagazineTopBar.swift:56`

### 3. 硬编码英文字符串

以下英文/英语约束是用户可见或直接影响 locale 输出的：

- 固定英文月份格式：`sprout/Features/Treasure/Cards/TreasureMemoryCard.swift:137`、`TreasureWeeklyLetterSheet.swift:38`
- 固定英文月日模板：`dateFormat = "MMM d"`，并且 `uppercased()` 输出全大写英文月份
- 指标单位：`sprout/Domain/Growth/GrowthModels.swift:22` 中 `cm`、`kg`
- 喂养与时间单位：`sprout/Features/Home/FeedingDraftState.swift:129`、`sprout/Domain/Records/TimelineContentFormatter.swift:79` 中 `ml`、`m`
- 左右侧 badge：`sprout/Features/Home/FeedingDraftState.swift:46` 中 `L`、`R`
- `AI` 标签：`sprout/Features/Growth/Components/GrowthAIWhisperCard.swift:11`
- 工程默认 region 为 `en`：`sprout.xcodeproj/project.pbxproj:169`

非用户可见的英文断言、环境变量、storage key、`assertionFailure` 文案本轮不列为 UI 国际化范围，但改造测试时需要同步处理。

### 4. 字符串拼接式文案

- 首页 header：`sprout/Features/Home/Components/EmotionHeaderBlock.swift:23` 通过三段 `Text` 拼出“宝宝的第 X 天”
- 侧边栏 header：`sprout/Features/Shell/SidebarDrawer.swift:42` 拼出“第 X 天”
- 首页成功 toast：`sprout/Features/Home/HomeStore.swift:245`、`258`
- 成长成功 toast：`sprout/Features/Growth/GrowthStore.swift:224`
- 奶量标题/副标题：`sprout/Domain/Records/TimelineContentFormatter.swift:79`、`154`
- 辅食标题：`sprout/Domain/Records/TimelineContentFormatter.swift:129`、`134`
- 睡眠时长：`sprout/Domain/Records/TimelineContentFormatter.swift:109`、`118`
- 成长 Meta 与 AI 卡全文案：`sprout/Domain/Growth/GrowthFormatter.swift:43`、`79`、`88`
- 周信全文案：`sprout/Domain/Treasure/WeeklyLetterComposer.swift:90`、`99`、`103`、`111`
- 珍藏日期串：`sprout/Features/Treasure/Cards/TreasureMemoryCard.swift:144`
- 周信日期范围：`sprout/Features/Treasure/Sheets/TreasureWeeklyLetterSheet.swift:31`

结论：当前不是“key 缺失”这么简单，而是大量 UI 句子在 formatter/store/domain 层被直接拼成中文整句。

### 5. 依赖中文或展示语言的枚举、状态、字段

- `GrowthMetric.title / unit / emptyText / entryTitle`：`sprout/Domain/Growth/GrowthModels.swift`
- `DiaperSubtype.title`：`sprout/Domain/Records/RecordTypes.swift:16`
- `HomeModule.title`：`sprout/Features/Home/HomeModels.swift:11`
- `MilkTab.title / detailTitle`、`NursingSide.title / badge`：`sprout/Features/Home/FeedingDraftState.swift`
- `UndoToastState.message`：存放的是最终展示句，不是语义化事件
- `GrowthMetaInfo.summaryText`、`GrowthTooltipData.valueText`、`GrowthAIContent`：都存放最终展示文本
- `TreasureMonthAnchor.displayText`：直接存展示月文案
- `WeeklyLetter.collapsedText / expandedText`：持久化的是最终中文内容，无法随语言切换重渲染
- `RecordItem.tags`：当前既承载用户输入，也承载中文建议标签；一旦切英文会出现中英混存
- `HomeStore.commonFoodTags`：中文固定推荐词表，语言切换后仍会回流到 UI
- `RecordItem.aiSummary`：当前未使用，但字段类型仍是直接持久化字符串，未来若启用也会带来同类问题

### 6. 用户可见日期、时长、单位、复数格式

#### 已部分 locale-aware

- 首页日期：`sprout/Features/Home/Components/EmotionHeaderBlock.swift:41`
- 侧边栏出生日期：`sprout/Features/Shell/SidebarDrawer.swift:128`
- 首页卡片时间：`sprout/Features/Home/Cards/TimeMetaView.swift:7`
- 睡眠开始时间：`sprout/Features/Home/Sheets/SleepControlSheet.swift:38`

这些 API 会跟随系统 locale，但外围句式仍是中文。

#### 明确存在 locale 风险

- `TreasureTimestampFormatter` 和 `TreasureWeeklyLetterRangeFormatter` 锁死 `en_US_POSIX` 与 `MMM d`：`sprout/Features/Treasure/Cards/TreasureMemoryCard.swift:137`、`sprout/Features/Treasure/Sheets/TreasureWeeklyLetterSheet.swift:38`
- `GrowthFormatter.formatValue` 与 `GrowthRulerPicker` 使用 `String(format:)`，小数点固定为英文句点：`sprout/Domain/Growth/GrowthFormatter.swift:116`、`sprout/Features/Growth/Sheets/GrowthRulerPicker.swift:18`
- 睡眠时长、亲喂时长、年龄、相对时间全部手工拼中文，不支持英文复数：`sprout/Domain/Records/TimelineContentFormatter.swift:118`、`sprout/Domain/Growth/GrowthFormatter.swift:125`、`160`
- 年龄/时间算法使用固定 `30` 天折月：`sprout/Domain/Growth/GrowthFormatter.swift:129`、`145`
- `左 15m · 右 10m` 混合中文方位词与英文缩写：`sprout/Domain/Records/TimelineContentFormatter.swift:154`
- `\(loadedImages.count)/6`、`\(preset)ml`、`\(value)cm` 等单位直接拼接，没有本地化的 number format 和 unit policy

### 7. 成长模块与 AI 卡片的文案输出方式

#### 成长 AI 卡

- 生成路径：`GrowthStore.refreshCurrentMetric()` -> `GrowthFormatter.makeAIContent(...)` -> `GrowthAIWhisperCard`
- 当前实现是纯规则模板，不是真正模型生成；但 `GrowthAIContent` 只承载最终中文句子，没有中间语义层
- 风险点：
  - 句式直接写在 formatter，无法按语言复用
  - 文案边界靠“目前模板没有写出违规词”，没有专门的 locale 级边界校验
  - tests 直接断言中文整句：`sproutTests/GrowthFormatterTests.swift:39`

#### 珍藏周信

- 生成路径：`TreasureStore.syncWeeklyLetterIfPossible()` -> `TreasureRepository.syncWeeklyLetter(...)` -> `WeeklyLetterComposer.compose(...)`
- `WeeklyLetter` 持久化 `collapsedText / expandedText`，历史周信一旦写入就是当前语言
- 边界控制目前只针对中文：
  - banned term 列表是中文词：`sprout/Domain/Treasure/WeeklyLetterComposer.swift:4`
  - 长度阈值按中文字符数估算：`WeeklyLetterComposer.swift:117`
  - 引用用户 note 时使用中文引号“”与中文叙述语气：`WeeklyLetterComposer.swift:111`
- tests 同样锁死中文句子：`sproutTests/WeeklyLetterComposerTests.swift:28`

### 8. 推送、错误态、权限弹窗、空状态文案位置

#### 推送

- 未发现运行时代码里的推送文案或通知授权弹窗文案
- 仅发现 `sprout/Info.plist:7` 配置了 `remote-notification` background mode
- 未发现 `UNUserNotificationCenter`、`requestAuthorization` 等接线

#### 错误态

- 成长模块错误文案在 store：`sprout/Features/Growth/GrowthStore.swift:149`、`177`
- 珍藏模块错误文案在 store，并由 `TreasureEmptyState` 展示：`sprout/Features/Treasure/TreasureStore.swift:369`、`395`，`sprout/Features/Treasure/Components/TreasureEmptyState.swift:19`
- 珍藏新建失败 alert：`sprout/Features/Treasure/Sheets/TreasureComposeModal.swift:95`
- 首页记录失败只有 `assertionFailure`，没有用户可见错误反馈：`sprout/Features/Home/HomeStore.swift:248`、`261`、`279`、`298`
- 成长模块 `errorMessage` 目前未在 UI 上渲染，只有 store 内部状态：`sprout/Features/Growth/GrowthStore.swift:149`、`177`

#### 权限弹窗

- 相机与相册使用说明写在 build settings，不在可本地化资源中：`sprout.xcodeproj/project.pbxproj:246`、`247`
- 当前文案只覆盖“辅食记录添加照片”，但珍藏模块也使用相机/相册：`sprout/Features/Home/Sheets/FoodRecordSheet.swift:59`、`sprout/Features/Treasure/Sheets/TreasureComposeModal.swift:62`

#### 空状态

- 首页：`sprout/Features/Home/Components/RecordHomeScrollView.swift:58`
- 成长图表空状态：`sprout/Features/Growth/Components/GrowthLifeLineChartCard.swift:173`
- 成长 meta 空状态：`sprout/Domain/Growth/GrowthModels.swift:40`
- 珍藏空状态/错误态：`sprout/Features/Treasure/Components/TreasureEmptyState.swift:42`

### 9. 测试层面的文案耦合

- `sproutTests/TimelineContentFormatterTests.swift`
- `sproutTests/HomeStoreTests.swift`
- `sproutTests/GrowthFormatterTests.swift`
- `sproutTests/GrowthStoreTests.swift`
- `sproutTests/TreasureStoreTests.swift`
- `sproutTests/WeeklyLetterComposerTests.swift`

这些测试大量断言中文完整句子。国际化改造后，如果继续让测试绑定某一种语言，后续维护成本会非常高。

## P0 / P1 / P2 分类

### P0

- 没有任何国际化资源层与接线层：当前所有 UI 文案、toast、alert、accessibility、权限文案都直接写死在 Swift 或 build settings 中。
- `GrowthFormatter` 与 `WeeklyLetterComposer` 直接生成中文整句，`GrowthAIContent` 与 `WeeklyLetter` 只存最终展示文本，没有 locale-neutral 数据层。
- `WeeklyLetter` 持久化中文 `collapsedText / expandedText`；历史数据无法随语言切换重渲染，属于双语落地的直接阻塞项。
- 权限文案没有资源化，且描述范围只覆盖辅食，不覆盖珍藏拍照/选图入口；双语和准确性都会出问题。
- Treasure 时间格式被 `en_US_POSIX + MMM d + uppercased()` 锁死，Growth/Timeline 数值与时长又被中文手工拼接；格式层没有统一 locale 策略。

### P1

- 枚举和 ViewState 暴露展示文本，业务层与展示层耦合：`HomeModule`、`GrowthMetric`、`DiaperSubtype`、`MilkTab`、`NursingSide`、`UndoToastState`、`GrowthMetaInfo`、`TreasureMonthAnchor`
- `RecordItem.tags` 与 `HomeStore.commonFoodTags` 会在双语环境中产生中英混存，推荐词与历史记录难以保持一致
- 成长错误文案在 store 中存在但未渲染；首页失败只有断言没有用户反馈，错误态策略不一致
- 测试以中文整句为断言对象，重构 formatter / template provider 时会造成大面积测试脆弱性
- 侧边栏当前承担“设置入口”语义，但实现是静态中文说明卡；后续英文命名与信息架构边界需要先确认
- `CFBundleDisplayName = "初长"` 为单语言配置；是否跟随语言切换属于产品决策，当前工程没有承接方式

### P2

- `ContentView.swift` 里的 demo seed 文案与 preview 数据是中文，属于开发样例，不阻塞主流程
- fallback 字符使用中文语义：例如头像首字缺省为 `宝`
- 多处 accessibility label 直接硬编码中文，建议在主 UI 文案接线后统一补齐
- `RecordItem.aiSummary` 当前未使用，可以等真正需要该字段时再纳入国际化方案

## 建议改造方案

### 最小可行方案

在不改信息架构、不新增功能的前提下，建议引入 3 个薄层：

- `LocalizationService`
  - 负责按 key 读取 UI 文案
  - 仅做字符串资源访问，不做业务计算
- `LocaleFormatter`
  - 负责日期、时间、时长、数字、单位、列表连接
  - 从 `Formatter` 层接管当前手工拼句的一部分职责
- `PromptTemplateProvider`
  - 负责成长 AI 卡与珍藏周信的语言模板
  - 输入必须是语义化数据，而不是最终文案

### 国际化资源组织方式

- App UI：新增 `Localizable.xcstrings`
- 权限与应用名：改为可本地化的 Info.plist 资源
- key 建议按模块分组，不按页面截图命名：
  - `home.*`
  - `growth.*`
  - `treasure.*`
  - `shell.*`
  - `common.*`
  - `permissions.*`
- 动态文案不要把整句塞回 enum；应改成 `key + arguments`

### 推荐接线顺序

1. 先建资源层与 formatter 层
2. 先替换静态 UI 文案和权限文案
3. 再处理 formatter 产出的动态标题、toast、日期时长单位
4. 最后处理成长 AI 卡与珍藏周信

### 哪些模块先做

- 先做：首页记录、Shell/侧边栏、成长模块的静态 UI、珍藏模块的静态 UI、权限文案
- 紧接着做：`TimelineContentFormatter`、`GrowthFormatter` 中的日期/时长/单位输出
- 单独做：成长 AI 卡、珍藏周信

### 哪些模块先不动

- 不翻译用户已输入的 `note`、`tags`
- 不在本轮新增应用内语言切换；默认跟随系统语言
- 不在本轮改 storage key、rawValue、环境变量、断言字符串
- 不把“单位体系切换”扩展成英制/美制功能，除非产品明确要求

### 关键设计建议

- `GrowthMetric.title/unit/entryTitle/emptyText` 不再直接返回展示字符串，改为返回语义 key 或交给 `LocalizationService`
- `TimelineContentFormatter` 输出不再是中文整句，建议改成中间结构，例如 `TimelineContentParts`
- `GrowthFormatter.makeAIContent` 改成先产出 `GrowthInsightFacts`
  - 例如：`state = firstRecord / noChange / increased / decreased`
  - `metric = height / weight`
  - `deltaValue`
  - `intervalDays`
- `WeeklyLetter` 不再持久化最终文案，建议改成持久化语义摘要
  - 例如：`density`、`entryCount`、`photoCount`、`textCount`、`milestoneCount`、`firstNoteSnippet`
  - 或者在读取时基于 `MemoryEntry` 即时重算

## 建议 PR 切分

### PR1：i18n 基础设施

- 新增 `Localizable` 资源
- 新增 `LocalizationService`
- 新增 `LocaleFormatter`
- 接入可本地化的权限文案与 app metadata
- 不改业务流程，只打基础

### PR2：首页记录与 Shell 静态文案

- 首页导航、空状态、按钮、sheet 标题、accessibility、toast key 化
- 侧边栏/“设置入口”静态文案 key 化
- 保持 `RecordRepository` 与存储结构不变

### PR3：首页动态格式化

- 重构 `TimelineContentFormatter`
- 统一奶量、时长、方位、辅食 tags 列表连接规则
- 让 HomeStore toast 基于语义事件组装，而不是拼中文标题

### PR4：成长模块基础文案与格式

- `GrowthMetric`、`GrowthFormatter`、Growth sheet/chart 静态文案改造
- 数值、小数、年龄、相对时间、轴标签改走 `LocaleFormatter`
- 不在这个 PR 混入周信/珍藏

### PR5：成长 AI 卡

- 引入 `PromptTemplateProvider`
- `GrowthFormatter` 只产出语义 facts
- 中英文模板分别审校边界词
- 调整相关测试，改为断言 facts 或按 locale fixture 断言

### PR6：珍藏静态文案与时间格式

- 新建记忆弹层、空状态、月穿梭、时间标签、无障碍文案改造
- 去掉 `en_US_POSIX` 锁死格式

### PR7：珍藏周信模型改造

- 处理 `WeeklyLetter` 的持久化语言耦合
- 迁移或重算历史周信
- 将 banned terms 和长度策略改为 locale-aware 模板规则

## 需要我确认的问题

- 英文界面里，App Display Name 是否要跟随语言切换；如果要，英文名是 `sprout` 还是别的写法
- “珍藏”模块英文最终名称是什么；当前工程只有中文标题，没有可直接沿用的产品结论
- 侧边栏是否就是 V1 的“设置”承载页；如果是，英文命名和文案边界需要先定
- 权限说明是否要统一成覆盖“辅食 + 珍藏”的更泛化表述
- V1 是否保持公制单位固定不变；如果是，英文只翻译文案，不扩展英制单位
- 食材建议标签是否需要一套英文词表；如果需要，是否允许中英文历史标签混存
- 历史周信切换语言时，是重算为当前语言，还是保留生成当时语言
- 成长 AI 卡英文标题是否继续显式露出 `AI`

## 你建议的下一步

1. 先确认 `open_questions.md` 中涉及命名、权限、单位、周信语言策略的产品决策
2. 决策确认后，从 PR1 开始，只落基础设施和资源文件，不碰业务行为
3. 基础设施稳定后，优先做 Home + Shell，再进入 Growth / Treasure 的动态文案改造
