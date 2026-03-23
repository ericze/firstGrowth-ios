# AGENTS.md

## 项目定位

产品名：初长（Baby’s First Growth）

这是一个面向 0–3 岁宝宝的成长记录 App。  
目标用户是疲惫、缺觉的父母。

产品核心价值：

- 安静
- 克制
- 低焦虑
- 快速记录
- 本地优先
- 易于维护

做任何实现决策时，优先问自己：

**这是否让疲惫的父母用更少噪音、更低负担完成记录？**

---

## 产品与视觉原则

整体气质应当是：

- 极简
- 温暖
- 编辑感
- 高级
- Apple 原生
- “Invisible UI”

严格禁止：

- 高饱和颜色
- 卡通宝宝插画
- 模块彩色分区
- 彩色标签
- 纯黑文本（`#000000`）
- 明亮刺眼的红色错误提示
- 游戏化、连续打卡、奖杯、庆祝动画

不要把产品做成“可爱母婴 App”，而应像一个安静、精致、可靠的生活工具。

---

## 技术栈

- 平台：**iOS 17.0+**
- UI：**SwiftUI**
- 数据持久化：**SwiftData**
- 状态观察：**Observation**
- 设计原则：**Local-first**

约束：

- 优先使用 Apple 原生能力
- 未经明确要求，不要引入第三方依赖
- 不要让核心记录流程依赖网络
- 不要让 AI 成为主流程前置条件

---

## 架构规则

- View 负责渲染、布局和交互接线，不承载复杂业务逻辑
- 持久化模型保持轻量
- 业务规则、数据转换、副作用放到 feature/domain store 或 service
- 应用级和功能级状态优先使用 `@Observable`
- View 本地状态按 SwiftUI 习惯使用 `@State`、`@Binding`、`@Environment`、`@FocusState`、`@Bindable`

代码风格要求：

- 优先小而可组合的组件
- 重复 UI 尽早提取复用
- 可复用 View 文件尽量控制在约 150 行以内
- 优先强类型，不要滥用自由字符串和弱类型字段
- 不要做巨型 ViewModel 或 God Object
- 变更尽量保持最小 diff

---

## 设计系统

详细规则如无额外文档，则以本节为准。

### 颜色

不要在业务页面里硬编码一次性色值。  
统一使用语义化颜色 token。

基础 token：

- `background`
  - Light: `#F7F4EE`
  - Dark: `#1C1A18`

- `cardBackground`
  - Light: `#FFFFFF`
  - Dark: `#2A2724`

- `primaryText`
  - Light: `#3A342F`
  - Dark: `#EFEAE0`

- `accent`
  - `#8FAE9B`

- `highlight`
  - `#D89A7A`
  - 仅用于 AI 周报或重要里程碑

派生规则：

- `secondaryText = primaryText.opacity(0.6)`
- `tertiaryText = primaryText.opacity(0.4)`

错误与危险状态：

- 不要默认使用亮红色
- 优先通过文案、图标、层级和确认流程表达危险性

### 排版

- 仅使用 San Francisco
- 用字号、字重、透明度建立层级
- 避免花哨字体和装饰性文本效果
- 避免过多大写

### 形状与阴影

- 优先使用连续圆角
- 默认推荐：
  `RoundedRectangle(cornerRadius: 24, style: .continuous)`
- 阴影应非常轻：
  - `Color.black.opacity(0.05)`
  - radius 约 `10`
  - y 约 `5`

### 动效

推荐状态动画：

```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)