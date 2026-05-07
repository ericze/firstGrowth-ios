# PROJECT_PROGRESS.md

> This file is the single source of truth for Sprout project progress.
> Every completed task must update this file before the task is considered done.

## 更新规则

- 每次完成代码、文档、设计、测试、配置或发布相关任务后，必须更新本文档。
- 如果任务改变了版本范围、模块状态、风险、阻塞、验收结果或下一步优先级，必须同步修改对应章节。
- 如果任务只是很小的修复，也至少在「最近完成」或「验证记录」中追加一条。
- 如果任务发现新风险、新阻塞或新产品决策点，必须写入「风险与阻塞」或「待拍板问题」。
- 不要把临时想法写成已完成进度；状态必须能被代码、测试、文档或验收记录支持。
- 任务最终回复用户前，先检查本文档是否需要更新。

## 状态图例

| 状态 | 含义 |
| --- | --- |
| Done | 已实现，并有基础验证或明确验收依据 |
| In Progress | 正在实现，主路径可见但未完全验收 |
| Partial | 已有骨架或部分能力，但缺关键闭环 |
| Blocked | 被产品决策、账号、服务、证书、环境、测试基线或外部依赖阻塞 |
| Not Started | 尚未开始 |
| Watch | 当前可用，但需要持续观察或发布前复核 |

## 项目快照

| 项目 | 当前值 |
| --- | --- |
| 产品名 | 初长 / sprout |
| 当前分支 | `feat/multi-baby-profile-slice` |
| 当前工作区 | Dirty；本次仅更新 `PROJECT_PROGRESS.md`，不回退其他已有改动 |
| 平台 | iOS 17.0+ |
| UI | SwiftUI |
| 持久化 | SwiftData |
| 状态观察 | Observation |
| 同步服务 | Supabase |
| 进度文件最近更新 | 2026-05-07 |
| 最新全量 Debug 测试 | 2026-05-07：失败，测试进程出现 `signal abrt`，需先定位全量门禁根因 |
| 最新定向验证 | 2026-05-07：`FoodAIAssistServiceTests/testMockServiceReturnsConservativeFallbackSuggestion` 单例通过 |

## 当前总体判断

Sprout 已越过早期原型阶段。核心记录、成长、珍藏、多宝宝、账号、云同步、家庭组、订阅 gating 和双语基础设施都已有真实代码与较完整的测试面。

当前阶段应定义为：

**核心体验已基本成型，项目正在进入 1.3 发布收口；首要矛盾不是继续加功能，而是恢复全量测试绿灯、完成真实环境验收，并把可售卖承诺收窄到已经验收的能力。**

本次进度梳理不做兼容处理，不新增兼容层，不为未验收能力保留对外承诺。后续推进以当前目标版本直接收口为准。

## 版本进度总览

| 版本 / Epic | 状态 | 进度判断 | 当前判断 |
| --- | --- | --- | --- |
| V1 核心记录体验 | Done | 90%+ | 奶、尿布、睡眠、辅食、时间线、编辑删除、撤销、图片与标签主链路已成型 |
| 1.2 Growth 2.0 | Watch | 88% | 身高、体重、头围、图表、成长解读、里程碑、总结均已落地；发布前仍需截图和文案 QA |
| 1.2 Treasure / Weekly Letter 2.0 | Watch | 85% | 记忆、图片、时间线、月锚点、周信、重生成、里程碑高亮已落地；仍需内容 QA |
| 1.2 AI 辅食助手 1.0 | Partial | 65% | 当前是本地候选建议 surface + mock fallback，不是生产 AI 服务；不得进入首批 Pro 主承诺 |
| 1.3 国际化正式化 | Watch | 85% | `.xcstrings`、应用内语言切换、InfoPlist 双语、formatter 与覆盖测试已有；人工截图 QA 未完成 |
| 1.3 Pro 订阅正式化 | Partial | 55% | StoreKit provider、cache、权益 gating 已有；Paywall 购买入口仍关闭，未完成 sandbox 和权益拍板 |
| 1.3 多宝宝管理 | Watch | 85% | 创建、切换、删除、active baby 隔离、共享宝宝可见性已有；受当前全量测试红灯影响需复核 |
| 1.3 家庭组 1.0 | In Progress | 82% | 本地创建、邀请码、加入、共享宝宝、成员、权限边界已有；真实同步协作尚未验收 |
| 1.3 Cloud Sync 正式化 | In Progress | 75% | Supabase Auth/RPC/Storage/SyncEngine 已接入；真实 smoke 与双设备回归仍是发布阻塞 |
| 发布准备 | Blocked | 45% | 当前全量 Debug suite 不绿，App Store 元数据、证书、真实 Supabase、Pro sandbox 和截图 QA 均未完成 |

## 能力成熟度矩阵

| 能力域 | 代码完成度 | 自动化验证 | 发布验收 | 结论 |
| --- | --- | --- | --- | --- |
| Home 记录 | 高 | 多数 Home / Record 测试在 2026-05-07 全量跑中先通过 | 需截图和真实家庭协作验证 | 可作为产品主体验继续保留 |
| Growth | 高 | Growth formatter / chart / repository 有测试；全量门禁当前红灯需复核 | 需中英文截图与内容 QA | 本地能力基本完成 |
| Treasure | 高 | Treasure repository / timeline / composer 有测试；全量门禁当前红灯需复核 | 需周信内容、多语言和图片边界 QA | 成果层可用，发布前补人工验收 |
| AI Food | 中 | 定向 AI 单例 2026-05-07 通过；Home AI 全量中受测试进程崩溃影响 | 无生产服务、无密钥策略、无医学边界验收 | 只能作为本地候选建议，不售卖 |
| Multi-baby | 中高 | BabyRepository 相关测试存在；当前全量门禁红灯需先恢复 | 需多宝宝 + 共享宝宝手动回归 | 可作为首批 Pro 候选，但必须先绿灯 |
| Family Group | 中高 | FamilyGroupStore / permission / shared baby 测试存在；当前全量门禁红灯需先恢复 | 需真实账号、邀请、加入、移除、同步回归 | 不能作为首批售卖承诺 |
| Cloud Sync | 中 | SyncEngine / SupabaseConfig / smoke gate 有测试；当前全量门禁红灯需先恢复 | 真实 Supabase smoke + 双设备仍未跑 | 发布最大外部风险 |
| Subscription | 中 | SubscriptionManager / PaywallContent 测试覆盖 gating 和承诺收口 | 需 App Store sandbox 购买 / 恢复 | Paywall 继续关闭是正确状态 |
| i18n | 中高 | Catalog coverage / language manager / formatter 定向 suite 已有 | 需全链路截图 QA | 基础完成，发布质量待验收 |

## 模块细分进度

### Home / 首页记录

| 能力 | 状态 | 备注 |
| --- | --- | --- |
| 奶记录 | Done | 支持瓶喂、亲喂、混合记录、编辑与撤销 |
| 尿布记录 | Done | 支持子类型、编辑、删除确认 |
| 睡眠记录 | Done | 支持进行中状态、结束、跨天编辑 |
| 辅食记录 | Done | 支持标签、备注、图片、首次尝试提示 |
| 时间线 | Done | 支持今日记录、分页加载、展示格式化 |
| 编辑 / 删除 / 撤销 | Done | 有 repository 与 store 测试覆盖 |
| 共享记录权限 | Watch | 作者权限检查、Home 编辑 affordance、一致性回归已有；真实家庭协作仍需验收 |
| AI 辅食建议 | Partial | 仅是本地候选建议与 mock fallback；失败不阻塞手动记录，不承诺诊断或确定性识别 |

### Growth / 成长

| 能力 | 状态 | 备注 |
| --- | --- | --- |
| 身高 | Done | 记录、图表、参考区间、摘要 |
| 体重 | Done | 记录、图表、参考区间、摘要 |
| 头围 | Done | 记录与趋势图已接入；首版不做参考区间 |
| 成长解读 | Done | 本地规则生成，避免医学化表达 |
| 里程碑 | Watch | 独立 SwiftData 模型、仓储、UI、撤销已有；当前全量测试红灯需复核 |
| 成长总结 | Watch | 数据结构与 UI 已存在，发布前做中英文文案验收 |
| Treasure 联动 | Done | 周信可包含成长里程碑高亮 |

### Treasure / 珍藏

| 能力 | 状态 | 备注 |
| --- | --- | --- |
| Memory Entry | Done | 图片、文本、年龄、babyID 隔离 |
| 图片存储 | Done | 本地路径与同步路径已有 |
| Timeline Builder | Done | 支持记忆、周信、月锚点、成长里程碑 |
| Weekly Letter | Watch | 本地 composer、重生成、语言策略已有；需发布级内容 QA |
| 周信历史语言策略 | Done | 历史内容保留生成时语言，新生成跟随当前语言 |
| 发布级内容 QA | Partial | 需要人工读文案、边界与多语言回归 |

### Shell / 设置与壳层

| 能力 | 状态 | 备注 |
| --- | --- | --- |
| Root Pager | Done | Record / Growth / Treasure 横向切换 |
| Sidebar | Done | 头像入口、设置路由、手势策略 |
| 宝宝资料 | Watch | 编辑、头像、创建、切换、删除已有；当前全量测试红灯需复核 |
| 语言与地区 | Watch | 应用内语言切换已持久化；需截图 QA |
| 账号页 | Watch | 登录、注册、重置、退出、绑定冲突已有；需真实账号 smoke |
| Cloud Sync 页 | In Progress | 状态、待同步数量、手动同步已有；需真实同步验收 |
| Family Group 页 | In Progress | 本地闭环、成员越权边界、共享宝宝显示/切换已有；需真实协作验收 |
| Paywall | Partial | UI 和 StoreKit 链路已有；`promotedCapabilities` 为空，正式购买关闭 |

### Sync / Supabase

| 能力 | 状态 | 备注 |
| --- | --- | --- |
| Supabase 配置校验 | Done | 防止 `/rest/v1/` 项目 URL 误用 |
| Auth | Watch | restore/signIn/signUp/reset/signOut 已封装；需真实账号 smoke 复核 |
| RPC upsert | Done | baby / record / memory / family group |
| 增量 pull | Done | 按 cursor 拉取 remote rows |
| Storage | Done | 上传、下载、删除资产 |
| 删除墓碑 | Done | local-first 删除与重试 |
| 版本冲突 | Watch | 有一次重试和测试；需真实冲突策略验收 |
| 真实 Supabase smoke | Blocked | 默认跳过；需真实凭据运行 baby / record / memory / family group / asset / tombstone |
| 双设备同步 | Blocked | README 有验收路径；仍需两台设备或模拟器矩阵执行 |

### Subscription / Pro

| 能力 | 状态 | 备注 |
| --- | --- | --- |
| StoreKit provider | Done | 产品加载、购买、恢复、当前权益 |
| Subscription cache | Done | 离线 fallback |
| Capability gating | Done | `ProCapability` 与 `SubscriptionManager.allows(_:)` |
| Multi-baby gating | Watch | 免费版限制第二个宝宝；当前全量测试红灯需复核 |
| Cloud / Family gating | Watch | 侧边栏访问策略已测；当前全量测试红灯需复核 |
| 正式 Paywall 承诺 | Blocked | `promotedCapabilities` 为空；`AI/Cloud/Family` 在发布验收前不得进入主承诺 |

## 发布 Gate

| Gate | 状态 | 验收要求 |
| --- | --- | --- |
| Debug 全量测试 | Blocked | 2026-05-07 全量 run 失败，失败摘要为 `Test crashed with signal abrt.`；需先恢复绿灯 |
| 测试进程崩溃定位 | Blocked | 先定位全量 suite 中 `signal abrt` 的根因；定向 AI 单例已证明至少部分失败不是用例逻辑必现 |
| Release unsigned archive | Watch | CI 有 preflight workflow；本地发布前需再跑 |
| 真实 Supabase 双设备同步 | Blocked | 验收路径已写入 README；需要真实账号、真实项目、两台设备或模拟器矩阵 |
| Pro 沙盒购买 / 恢复 | Partial | 单测覆盖 provider 行为；需 App Store sandbox 验收 |
| Paywall 承诺一致性 | Watch | Focused tests 覆盖空 promoted、停售副标题、AI/Cloud/Family 发布阻断 |
| 中英文全链路截图 QA | In Progress | P0 字符串资源覆盖已校验；仍需逐屏人工截图验收 |
| 法律链接 | Watch | 已指向项目 legal docs；发布前确认最终公开 URL |
| App Store 元数据 | Not Started | 名称、描述、截图、隐私标签、订阅说明 |
| 埋点与崩溃监控 | Not Started | 1.3 QA 文档要求购买、同步、切换、邀请关键事件；代码层未发现独立 analytics/telemetry 模块 |

## 风险与阻塞

| 风险 | 状态 | 影响 | 处理方向 |
| --- | --- | --- | --- |
| 当前全量测试不通过 | Blocked | 不能进入发布候选或合并收口 | 先定位 `signal abrt` 根因；不要继续叠加功能 |
| Paywall 正式售卖未开启 | Blocked | 不能公开销售 Pro | 等可售卖权益全部验收后再设置 `promotedCapabilities` |
| AI 辅食仅为本地 fallback | Watch | 当前不能作为真实 AI 权益售卖 | 保持不进入 Pro 主承诺；若升级需另立服务、密钥、医学边界与验收任务 |
| 真实云同步未完成发布级验收 | Blocked | 数据可靠性风险 | 跑真实 Supabase smoke 与双设备回归 |
| Family Group 未完成真实协作验收 | Blocked | 家庭协作不能作为首批正式售卖承诺 | 完成真实账号、邀请、共享宝宝、成员权限和同步回归 |
| 文档与代码进度不一致 | Watch | 决策误判 | 继续以本文档为准，发布相关旧文档只保留历史背景 |
| SwiftData schema 迁移风险 | Watch | 启动崩溃或历史数据迁移失败 | 后续 schema 改动必须先过 migration plan 测试；本次不新增兼容处理 |
| 动态文案与截图 QA 尚未完成 | Watch | 中英文页面可能有截断、混合语言或格式问题 | 按关键路径截图清单验收 |
| App Store 与真实服务外部门禁未跑 | Blocked | 无法判断线上可用性 | 按发布 Gate 顺序补齐真实账号、sandbox、证书与元数据 |

## 待拍板问题

| 问题 | 状态 | 建议 |
| --- | --- | --- |
| Pro 首批正式售卖权益 | Open | 建议首批只考虑 Multi-baby；全量测试恢复前继续保持 `promotedCapabilities` 为空 |
| AI Assistant 是否进入首批 Pro | Closed | 当前不进入首批 Pro；仅保留本地候选建议 fallback |
| Cloud Sync 是否进入首批 Pro 主承诺 | Open | 真实 smoke + 双设备验收完成前不进入主承诺 |
| Family Group 是否进入首批 Pro 主承诺 | Open | 真实协作验收完成前不进入主承诺 |
| 英文食材建议词表最终集合 | Open | 使用 canonical key + 双语 display name |
| App Store 首发地区与语言 | Open | 若双语截图 QA 通过，可中英同时上；否则先收窄 |
| Terms / Privacy 最终托管地址 | Open | 发布前用稳定公开 URL，不依赖源码浏览页 |
| 崩溃监控 / 埋点方案 | Open | 若坚持 Apple 原生优先，可先用 MetricKit + OSLog 形成最低可用方案 |

## 最近完成

| 日期 | 任务 | 验证 |
| --- | --- | --- |
| 2026-05-07 | 重新全面梳理项目进度并细化 `PROJECT_PROGRESS.md` | 基于 `find` / `rg` / 关键 Swift 文件抽样 / 测试目录 / `xcodebuild` 验证结果更新状态、风险与后续推进方案 |
| 2026-05-06 | 补齐 P0 国际化资源缺口并新增 catalog 覆盖测试 | `LocalizationCatalogCoverageTests` 通过；`AppLanguageManagerTests`、`GrowthFormatterTests`、`TimelineContentFormatterTests`、`TreasureComposeModalTests`、`SidebarRoutingTests` 通过 |
| 2026-05-06 | Pro / Paywall 发布收口：保持正式售卖关闭，新增发布阻断能力测试，收窄 AI Paywall 文案 | PaywallContentTests 6/6 passed；SubscriptionManagerTests 23/23 passed |
| 2026-05-06 | Family Group 1.0 权限与协作回归 | 补成员越权、共享宝宝移除/取消共享后可见性、Home 编辑 affordance 测试；定向 Family/Baby/HomeStore/RecordRepository 测试通过 |
| 2026-05-06 | 同步过期 i18n 审计与 1.3 spec 状态 | 更新 `i18n_audit.md` 与 `docs/1.3.0/spec1_3.md`，修正 `.xcstrings`、语言切换、Paywall、Family Group、Terms / Privacy 等当前状态 |
| 2026-05-06 | 整理 Cloud Sync / Supabase 发布门禁并补 family group 真实 smoke 路径 | `RealSupabaseServiceSmokeTests` 增加 family group upsert / fetch / update / soft delete / tombstone；README 补环境变量、命令、双设备路径；默认无凭据 smoke 通过 |
| 2026-05-06 | 建立全局进度控制文件 | 新增 `PROJECT_PROGRESS.md`，并要求后续任务完成时更新 |
| 2026-05-06 | 本地全量测试验证当时基线 | `xcodebuild ... test` 通过，304/304 |
| 2026-05-06 | AI 辅食助手去风险化收口 | Home/Paywall 文案压回“候选建议”语义，mock 默认降级为保守 fallback，空建议与失败态均不阻塞手动记录 |

## 验证记录

| 日期 | 命令 / 方式 | 结果 |
| --- | --- | --- |
| 2026-05-07 | `xcodebuild -list -project sprout.xcodeproj` | Passed；Targets: `sprout`, `sproutTests`；Scheme: `sprout` |
| 2026-05-07 | `xcodebuild -showdestinations -project sprout.xcodeproj -scheme sprout` | Passed after running outside sandbox; confirmed iPhone 17 destination `D9FB2FCB-C23B-49FB-BA04-F41B540C70C5` |
| 2026-05-07 | `xcodebuild test -project sprout.xcodeproj -scheme sprout -configuration Debug -destination 'id=D9FB2FCB-C23B-49FB-BA04-F41B540C70C5' CODE_SIGNING_ALLOWED=NO` | Failed；build succeeded, tests started, then many tests reported `Test crashed with signal abrt.` |
| 2026-05-07 | `xcrun xcresulttool get object --legacy --path ... --format json` | Confirmed first failures are crash summaries, e.g. `FoodAIAssistServiceTests.testMockServiceThrowsError()` reported `Test crashed with signal abrt.` |
| 2026-05-07 | `xcodebuild test ... -only-testing:sproutTests/FoodAIAssistServiceTests/testMockServiceReturnsConservativeFallbackSuggestion` | Passed；说明全量失败不应直接归因到该 AI 用例逻辑 |
| 2026-05-06 | `xcodebuild -project sprout.xcodeproj -scheme sprout -configuration Debug -destination 'id=D9FB2FCB-C23B-49FB-BA04-F41B540C70C5' test CODE_SIGNING_ALLOWED=NO -only-testing:sproutTests/AppLanguageManagerTests -only-testing:sproutTests/GrowthFormatterTests -only-testing:sproutTests/TimelineContentFormatterTests -only-testing:sproutTests/TreasureComposeModalTests -only-testing:sproutTests/LocalizationCatalogCoverageTests -only-testing:sproutTests/SidebarRoutingTests` | Passed |
| 2026-05-06 | `xcodebuild -project sprout.xcodeproj -scheme sprout -configuration Debug -destination 'id=D9FB2FCB-C23B-49FB-BA04-F41B540C70C5' test CODE_SIGNING_ALLOWED=NO -only-testing:sproutTests/FamilyGroupStoreTests -only-testing:sproutTests/FamilyPermissionTests -only-testing:sproutTests/BabyRepositoryTests -only-testing:sproutTests/HomeStoreTests -only-testing:sproutTests/RecordRepositoryTests` | Passed |
| 2026-05-06 | `xcodebuild -project sprout.xcodeproj -scheme sprout -configuration Debug -destination 'id=D9FB2FCB-C23B-49FB-BA04-F41B540C70C5' test CODE_SIGNING_ALLOWED=NO` | Passed: 304 tests, 0 failures |
| 2026-05-06 | `xcodebuild test -project sprout.xcodeproj -scheme sprout -destination 'id=D9FB2FCB-C23B-49FB-BA04-F41B540C70C5' CODE_SIGNING_ALLOWED=NO -only-testing:sproutTests/RealSupabaseServiceSmokeTests` | Passed; no `SPROUT_REAL_SUPABASE_SMOKE` env set, so real backend path remained gated / skipped |
| 2026-05-06 | `xcodebuild -project sprout.xcodeproj -scheme sprout -configuration Debug -destination 'id=D9FB2FCB-C23B-49FB-BA04-F41B540C70C5' test CODE_SIGNING_ALLOWED=NO -only-testing:sproutTests/FoodAIAssistServiceTests -only-testing:sproutTests/HomeStoreAITests -only-testing:sproutTests/PaywallContentTests` | Passed: focused AI/HomeStore/Paywall suite |

## 后续推进方案

### Phase 0：先恢复工程基线

| 顺序 | 任务 | 验收标准 |
| --- | --- | --- |
| 0.1 | 定位 2026-05-07 全量测试 `signal abrt` 根因 | 能稳定复现最小失败集合，并能解释是测试进程、并发、共享状态、SwiftData container 还是具体代码断言 |
| 0.2 | 修复根因，不做兼容层和绕行 skip | 全量 Debug suite 重新通过 |
| 0.3 | 追加验证记录 | `PROJECT_PROGRESS.md` 记录修复命令、结果、剩余风险 |

### Phase 1：发布主路径收口

1. 跑全量 Debug suite，直到绿灯。
2. 跑 Release unsigned archive / preflight。
3. 带真实 Supabase 凭据跑 `RealSupabaseServiceSmokeTests`，覆盖 baby / record / memory / family group / asset / tombstone。
4. 执行 README 双设备路径：设备 A/B 登录、同步、修改、删除、family group tombstone。
5. 跑 Pro sandbox：产品加载、购买、恢复、过期、取消、同 Apple ID 新设备恢复。
6. 完成中英文截图 QA：Onboarding、Home、Growth、Treasure、Sidebar、Language & Region、Baby Profile、Account、Cloud Sync、Family Group、Paywall、启动错误页。
7. 产出 App Store 元数据：名称、副标题、描述、隐私标签、截图、订阅说明、Terms / Privacy 最终 URL。

### Phase 2：Pro 首批售卖拍板

| 候选权益 | 当前建议 | 原因 |
| --- | --- | --- |
| Multi-baby | 可作为首批候选 | 本地能力相对成熟，但必须先全量测试恢复绿灯 |
| Cloud Sync | 暂不进入首批主承诺 | 未完成真实 smoke 和双设备验收 |
| Family Group | 暂不进入首批主承诺 | 未完成真实协作和同步验收 |
| AI Assistant | 不进入首批主承诺 | 当前不是生产 AI 服务，只是本地候选建议 |

### Phase 3：发布后增强

1. 同步冲突中心。
2. 家庭组角色细分与操作审计。
3. MetricKit / OSLog 或同等轻量方案接入崩溃监控与关键埋点。
4. AI 辅食真实服务另立独立任务：服务协议、密钥、隐私、医学边界、费用和回退策略一次性拍清。
5. 成长分享卡与 Treasure 内容分享，不作为 1.3 发布阻塞。

## 更新模板

每次任务完成后，至少追加以下信息之一：

```markdown
## 最近完成

| 日期 | 任务 | 验证 |
| --- | --- | --- |
| YYYY-MM-DD | 简述完成内容 | 测试、构建、截图、文档审查或人工验收结果 |
```

如果任务影响模块状态，同步更新：

```markdown
| 能力 | 状态 | 备注 |
| --- | --- | --- |
| Example | In Progress | 说明当前还差什么 |
```

如果任务产生风险，同步更新：

```markdown
| 风险 | 状态 | 影响 | 处理方向 |
| --- | --- | --- | --- |
| Example | Watch | 说明影响 | 下一步处理 |
```
