# 初长 sprout

Sprout. At your own pace.

让成长，按自己的节奏发生。

初长是一个面向 0-3 岁宝宝家庭的成长记录 App。它服务的是疲惫、缺觉、没有精力和复杂界面周旋的父母：快速记录，低噪音反馈，本地优先保存，不用连续打卡、奖杯或高刺激的成长焦虑来驱动使用。

## 产品原则

- 安静、克制、低焦虑。
- 核心记录流程必须快速完成，不依赖网络或 AI。
- 默认 local-first，云同步只能增强体验，不能阻塞记录。
- 视觉上保持极简、温暖、编辑感和 Apple 原生气质。
- 不做卡通化母婴 App，不使用高饱和颜色、彩色标签、游戏化奖励或庆祝动画。

## 技术栈

- 平台：iOS 17.0+
- UI：SwiftUI
- 数据持久化：SwiftData
- 状态观察：Observation
- 工程：Xcode project
- 同步能力：Supabase 相关服务与本地同步引擎
- 订阅能力：StoreKit 相关领域模型与服务封装

## 功能模块

- 首页记录：奶、尿布、睡眠、辅食等高频记录入口与时间线展示。
- 成长：身高、体重、里程碑、趋势图和克制的解释性文案。
- 珍藏：照片、文字记忆、时间线、月锚点和周信。
- 多宝宝：通过 `BabyRepository` 创建 / 切换 active baby，Home / Growth / Treasure 的记录与记忆查询按当前 babyID 隔离。
- 侧边栏：宝宝资料、设置入口、订阅与状态信息承载。
- 同步：本地优先的数据迁移、游标、资产同步和删除墓碑。
- Cloud Sync：`SupabaseService` 已接入 Supabase Auth、Postgres RPC / 增量查询、Storage 上传下载删除；同步仍保持 local-first，失败不会删除本地数据。
- 国际化：字符串目录、语言状态、格式化服务和文案模板提供器。

## 目录结构

```text
sprout/
  DesignSystem/        语义化颜色、排版、形状等设计系统入口
  Domain/              业务模型、仓储、规则、格式化和服务
  Features/            按功能拆分的 SwiftUI 页面、容器、组件和 sheet
  Shared/              跨功能复用的 UI、日志、本地化和工具类型
  Localization/        String Catalog 与本地化资源
  Assets.xcassets/     App 图标、颜色和图片资源

sproutTests/           单元测试与测试支撑
Config/                本地构建配置示例和环境配置
docs/                  PRD、规格、验收、发布与实现计划
```

## 进度控制

根目录 `PROJECT_PROGRESS.md` 是项目进度唯一真源。每次完成代码、文档、测试、配置或发布相关任务后，必须同步更新该文件。

如果任务改变了模块状态、风险、阻塞、验收结果或下一步优先级，必须更新 `PROJECT_PROGRESS.md` 的对应章节；小修复也至少追加到「最近完成」或「验证记录」。

核心边界：

- `Features` 负责渲染、布局和交互接线，不承载复杂业务逻辑。
- `Domain` 放业务规则、数据转换、仓储和副作用边界。
- `Shared` 只放真正跨模块复用的轻量能力。
- `DesignSystem` 提供语义化 token，业务页面不应散落一次性色值。

## 本地运行

1. 使用 Xcode 打开 `sprout.xcodeproj`。
2. 选择 `sprout` scheme。
3. 如需启用 Supabase 相关能力，复制配置模板并填入本地值：

```bash
cp Config/Supabase.xcconfig.example Config/Supabase.local.xcconfig
```

   `SUPABASE_URL` 必须填写项目根地址，例如 `https://<project-ref>.supabase.co`，不要填写 `/rest/v1/` endpoint。

4. 在 Supabase SQL Editor 按文件名顺序执行以下迁移，创建账号同步、家庭组同步、RPC、RLS policy 和私有 Storage bucket：

```bash
supabase/migrations/202604270001_account_cloud_sync.sql
supabase/migrations/202605010001_family_group_1_0.sql
```

5. 构建并运行到 iOS 17.0+ 模拟器或真机。

核心记录流程应在没有网络、没有 AI 服务、没有云同步成功的情况下保持可用。

## 测试

使用 Xcode Test 运行 `sproutTests`，或通过命令行执行：

```bash
xcodebuild -showdestinations -project sprout.xcodeproj -scheme sprout

xcodebuild test \
  -project sprout.xcodeproj \
  -scheme sprout \
  -destination 'id=<simulator-id>'
```

测试覆盖重点包括：

- 记录校验、时间线格式化和首页 store。
- 成长数据、图表交互、里程碑和格式化。
- 珍藏时间线、周信、图片路径和仓储。
- 同步状态、游标、迁移、启动容器和订阅状态。
- Supabase 配置校验、Auth 管理、真实服务 smoke 测试门控与真实数据链 smoke。
- 国际化语言状态、模板和本地化格式。

默认发布门禁不需要任何 Supabase secret，必须保持 deterministic：

```bash
xcodebuild test \
  -project sprout.xcodeproj \
  -scheme sprout \
  -destination 'id=<simulator-id>' \
  CODE_SIGNING_ALLOWED=NO
```

真实 Supabase smoke 默认跳过外部连接；只有显式设置以下环境变量时才会登录真实后端。不要提交真实 URL、anon key 或测试账号密码。

```bash
export SPROUT_REAL_SUPABASE_SMOKE=1
export SPROUT_SUPABASE_URL=https://<project-ref>.supabase.co
export SPROUT_SUPABASE_ANON_KEY=<anon-key>
export SPROUT_SUPABASE_TEST_EMAIL=<test-user-email>
export SPROUT_SUPABASE_TEST_PASSWORD=<test-user-password>

xcodebuild test \
  -project sprout.xcodeproj \
  -scheme sprout \
  -destination 'id=<simulator-id>' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:sproutTests/RealSupabaseServiceSmokeTests
```

真实 smoke 覆盖 Auth 登录 / 退出、`server_now`、`baby_profiles` / `record_items` / `memory_entries` / `family_groups` 的 upsert / fetch / soft delete、私有 Storage 上传 / 下载 / 删除，以及 soft-delete tombstone 的增量拉取。测试账号应是专用账号；smoke 会在运行前清理该账号下仍 active 的 family group，以便重复运行。

双设备发布验收路径：

1. 在真实 Supabase 项目执行两份迁移，并准备一个专用测试账号。
2. 设备 A 登录测试账号，创建宝宝、记录、珍藏记忆、头像或食物 / 珍藏图片，创建 family group 并共享宝宝。
3. 设备 B 登录同一测试账号，手动触发 Cloud Sync，确认 baby / record / memory / family group / asset 都能拉取。
4. 设备 B 修改记录或珍藏记忆；设备 A 手动同步，确认增量更新可见。
5. 设备 A 删除记录、记忆和宝宝头像相关资产；设备 B 同步后确认 tombstone 生效且本地未丢失其他数据。
6. 使用真实 smoke 或 `soft_delete_row('family_groups', ...)` RPC 删除专用测试账号的 family group；设备 B 同步后确认 family group tombstone 可见，家庭组入口回到无 group 状态。

## 开发约束

- 优先使用 Apple 原生能力；未经明确要求，不引入第三方依赖。
- View 文件保持小而可组合，复杂逻辑下沉到 store、service 或 domain。
- 应用级和功能级状态优先使用 `@Observable`。
- View 本地状态按 SwiftUI 习惯使用 `@State`、`@Binding`、`@Environment`、`@FocusState`、`@Bindable`。
- 应用内语言切换统一通过 `AppLanguageManager` 持久化并更新 `LocalizationService`，不要在页面里直接改静态本地化状态。
- Pro 权益入口统一走 `ProCapability` 与 `SubscriptionManager.allows(_:)`；页面和菜单只声明 `requiredCapability`，不要散落原始 `isPro` 判断。
- Paywall 主承诺统一来自 `PaywallContent.promotedCapabilities`；未通过发布验收的能力不得出现在可购买权益列表中。
- Paywall 的 Terms / Privacy 链接维护在 `docs/legal` 对应文档，禁止使用 `example.com` 占位链接。
- 多宝宝数据读取必须以 active baby 为默认边界；新增记录、成长记录、珍藏记忆时应写入当前 active babyID。若要扩展到 `WeeklyLetter` schema，必须先设计 staged migration，避免重复 version checksum。
- Cloud Sync 服务层统一通过 `SupabaseService` 访问真实后端；页面和 store 不直接拼 Supabase REST URL，不直接持有 anon key，不把 `/rest/v1/` 当项目 URL 使用。
- `Config/Supabase.local.xcconfig` 只保存本机真实 URL / anon key，必须保持 git ignored，不能提交。
- 公共类和公开函数保持清晰命名，复杂业务决策才添加注释。
- 不硬编码业务页面颜色，统一走语义化设计 token。
- 不使用纯黑文本、高饱和提示色或刺眼错误红。
- 错误与危险状态优先通过文案、层级和确认流程表达，不靠强刺激视觉。
- 成长解读等解释性文本不使用 emoji 作为前缀或图标，避免缺字、误读和额外视觉噪音。
- 修改 SwiftData schema 时，staged migration 中每个版本的模型集合必须保持唯一；不要用“删除后再新增同一模型集合”的方式推进版本，否则会触发重复 version checksum。
- 变更保持最小 diff，避免巨型 ViewModel、God Object 和无关重构。

## 设计系统基线

基础语义色：

- `background`：Light `#F7F4EE`，Dark `#1C1A18`
- `cardBackground`：Light `#FFFFFF`，Dark `#2A2724`
- `primaryText`：Light `#3A342F`，Dark `#EFEAE0`
- `accent`：`#8FAE9B`
- `highlight`：`#D89A7A`，仅用于 AI 周报或重要里程碑

派生层级：

- `secondaryText = primaryText.opacity(0.6)`
- `tertiaryText = primaryText.opacity(0.4)`

默认形状：

```swift
RoundedRectangle(cornerRadius: 24, style: .continuous)
```

默认动效：

```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
```

## 维护准则

每次实现前优先问：

> 这是否让疲惫的父母用更少噪音、更低负担完成记录？

如果答案是否定的，应该优先删减复杂度，而不是增加入口、动效、提示或解释。
