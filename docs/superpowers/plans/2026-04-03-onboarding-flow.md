# Onboarding Flow 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现三步呼吸式 Onboarding 引导流，替代当前的静默 `createDefaultIfNeeded()`，收集宝宝名字/生日，软性请求相册和通知权限。

**Architecture:** 无新 Store。OnboardingView 用 `@State` 管理步骤切换，通过现有 `BabyRepository` 保存数据。`@AppStorage("hasCompletedOnboarding")` 控制入口路由。

**Tech Stack:** SwiftUI, SwiftData, PhotosUI (PHPhotoLibrary), UserNotifications (UNUserNotificationCenter), Swift Testing

---

## 文件结构

| 操作 | 文件 | 职责 |
|------|------|------|
| 新建 | `sprout/Features/Onboarding/OnboardingModels.swift` | OnboardingStep enum, OnboardingDraft |
| 新建 | `sprout/Features/Onboarding/OnboardingStepViews.swift` | OnboardingIdentityStep, OnboardingPermissionsStep 两个子视图 |
| 新建 | `sprout/Features/Onboarding/OnboardingView.swift` | 主容器：步骤切换 + 动画编排 + 已有用户迁移 |
| 修改 | `sprout/SproutApp.swift:53-62` | 加 `@AppStorage` 判断，未完成时显示 OnboardingView |
| 新建 | `sproutTests/OnboardingDraftTests.swift` | Draft 验证逻辑测试 |
| 新建 | `sproutTests/OnboardingMigrationTests.swift` | 已有用户迁移逻辑测试 |

---

### Task 1: 创建 OnboardingModels

**Files:**
- 新建: `sprout/Features/Onboarding/OnboardingModels.swift`
- 新建: `sproutTests/OnboardingDraftTests.swift`

- [ ] **Step 1: 写 Draft 验证失败的测试**

```swift
// sproutTests/OnboardingDraftTests.swift
import Testing
@testable import sprout

struct OnboardingDraftTests {

    @Test("draft isValid 为 false 当名字为空")
    func testInvalidWhenNameEmpty() {
        let draft = OnboardingDraft(name: "", birthDate: .now)
        #expect(!draft.isValid)
    }

    @Test("draft isValid 为 false 当名字只有空格")
    func testInvalidWhenNameWhitespace() {
        let draft = OnboardingDraft(name: "   ", birthDate: .now)
        #expect(!draft.isValid)
    }

    @Test("draft isValid 为 true 当名字非空")
    func testValidWhenNamePresent() {
        let draft = OnboardingDraft(name: "小花生", birthDate: .now)
        #expect(draft.isValid)
    }

    @Test("trimmedName 去除首尾空格")
    func testTrimmedName() {
        let draft = OnboardingDraft(name: "  小花生  ", birthDate: .now)
        #expect(draft.trimmedName == "小花生")
    }
}
```

- [ ] **Step 2: 运行测试，确认编译失败**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/OnboardingDraftTests 2>&1 | tail -5`
Expected: 编译错误 — `Cannot find 'OnboardingDraft' in scope`

- [ ] **Step 3: 创建 OnboardingModels.swift**

```swift
// sprout/Features/Onboarding/OnboardingModels.swift
import Foundation

enum OnboardingStep: Int, CaseIterable {
    case identity
    case permissions
}

struct OnboardingDraft {
    var name: String = ""
    var birthDate: Date = .now

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
}
```

注意：去掉了 `completion` case。Step 3 没有独立 UI，完成时直接设 flag 后由 SproutApp 切换视图，不需要一个 enum case 来表示。

- [ ] **Step 4: 运行测试，确认通过**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/OnboardingDraftTests 2>&1 | tail -5`
Expected: 4 tests passed

- [ ] **Step 5: 提交**

```bash
git add sprout/Features/Onboarding/OnboardingModels.swift sproutTests/OnboardingDraftTests.swift
git commit -m "feat(onboarding): add OnboardingModels with draft validation"
```

---

### Task 2: 创建 Step 1 身份输入视图

**Files:**
- 新建: `sprout/Features/Onboarding/OnboardingStepViews.swift`

- [ ] **Step 1: 创建 OnboardingIdentityStep 视图**

```swift
// sprout/Features/Onboarding/OnboardingStepViews.swift
import SwiftUI

// MARK: - Step 1: 身份输入

struct OnboardingIdentityStep: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 120)

            Text(L10n.text("onboarding.greeting", en: "Hello, nice to meet you.", zh: "你好，初次见面。"))
                .font(.system(size: 28, design: .serif))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer().frame(height: 48)

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("onboarding.name_hint", en: "What shall we call the little one?", zh: "我们要记录的小生命，叫什么名字？"))
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                TextField("", text: $draft.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .tint(AppTheme.Colors.sageGreen)
                    .padding(.bottom, 4)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(AppTheme.Colors.primaryText.opacity(0.3))
                            .frame(height: 0.5)
                    }
            }
            .padding(.horizontal, AppTheme.Spacing.screenHorizontal)

            Spacer().frame(height: 36)

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("onboarding.birthday_hint", en: "When did they arrive on Earth?", zh: "ta 是哪一天来到地球的？"))
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                DatePicker("", selection: $draft.birthDate, in: ...Date.now, displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            }
            .padding(.horizontal, AppTheme.Spacing.screenHorizontal)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text(L10n.text("onboarding.continue", en: "Continue", zh: "继续"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.sageGreen)
            }
            .disabled(!draft.isValid)
            .opacity(draft.isValid ? 1.0 : 0.3)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 2: 编译确认**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
git add sprout/Features/Onboarding/OnboardingStepViews.swift
git commit -m "feat(onboarding): add OnboardingIdentityStep view"
```

---

### Task 3: 创建 Step 2 权限请求视图

**Files:**
- 修改: `sprout/Features/Onboarding/OnboardingStepViews.swift`

- [ ] **Step 1: 在 OnboardingStepViews.swift 中追加 OnboardingPermissionsStep**

在文件末尾追加以下代码：

```swift
// MARK: - Step 2: 软性权限请求

struct OnboardingPermissionsStep: View {
    enum PermissionPhase {
        case photo
        case notification
    }

    @State private var phase: PermissionPhase = .photo
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            if phase == .photo {
                photoPhase
                    .transition(transitionStyle)
            } else {
                notificationPhase
                    .transition(transitionStyle)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: phase)
    }

    private var transitionStyle: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity.combined(with: .move(edge: .top))
        )
    }

    // MARK: - 相册权限

    private var photoPhase: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 160)

            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer().frame(height: 32)

            Text(L10n.text("onboarding.photo_title", en: "Amber of Moments", zh: "留住时光的琥珀"))
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer().frame(height: 12)

            Text(L10n.text("onboarding.photo_subtitle", en: "We need photo access to treasure every picture.", zh: "我们需要相册权限，为你珍藏每一张照片。"))
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer().frame(height: 36)

            Button {
                requestPhotoAccess()
            } label: {
                Text(L10n.text("onboarding.photo_authorize", en: "Grant Photo Access", zh: "授权相册访问"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.sageGreen)
            }

            Spacer().frame(height: 16)

            Button {
                advanceToNotification()
            } label: {
                Text(L10n.text("onboarding.skip", en: "Maybe Later", zh: "以后再说"))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 通知权限

    private var notificationPhase: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 160)

            Image(systemName: "bell.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer().frame(height: 32)

            Text(L10n.text("onboarding.notif_title", en: "Gentle Companion", zh: "不打扰的陪伴"))
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer().frame(height: 12)

            Text(L10n.text("onboarding.notif_subtitle", en: "We'll only nudge you when you haven't logged in a while.", zh: "只有在久未记录时，才会轻轻提醒你。"))
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer().frame(height: 36)

            Button {
                requestNotificationAccess()
            } label: {
                Text(L10n.text("onboarding.notif_enable", en: "Enable Reminders", zh: "开启提醒"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.sageGreen)
            }

            Spacer().frame(height: 16)

            Button {
                onComplete()
            } label: {
                Text(L10n.text("onboarding.skip", en: "Maybe Later", zh: "以后再说"))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 权限请求

    private func requestPhotoAccess() {
        Task {
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            advanceToNotification()
        }
    }

    private func requestNotificationAccess() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            onComplete()
        }
    }

    private func advanceToNotification() {
        phase = .notification
    }
}
```

注意 import 需要在文件顶部追加：
```swift
import Photos
import UserNotifications
```

- [ ] **Step 2: 编译确认**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
git add sprout/Features/Onboarding/OnboardingStepViews.swift
git commit -m "feat(onboarding): add OnboardingPermissionsStep view"
```

---

### Task 4: 创建 OnboardingView 主容器

**Files:**
- 新建: `sprout/Features/Onboarding/OnboardingView.swift`

- [ ] **Step 1: 创建主容器视图**

```swift
// sprout/Features/Onboarding/OnboardingView.swift
import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep: OnboardingStep = .identity
    @State private var draft = OnboardingDraft()
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            switch currentStep {
            case .identity:
                OnboardingIdentityStep(draft: $draft) {
                    saveBabyAndAdvance()
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            case .permissions:
                OnboardingPermissionsStep {
                    completeOnboarding()
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: currentStep)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                appeared = true
            }
        }
    }

    private func saveBabyAndAdvance() {
        let repo = BabyRepository(modelContext: modelContext)
        repo.createDefaultIfNeeded()
        repo.updateName(draft.trimmedName)
        repo.updateBirthDate(draft.birthDate)

        withAnimation {
            currentStep = .permissions
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.6)) {
            hasCompletedOnboarding = true
        }
    }
}
```

- [ ] **Step 2: 编译确认**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交**

```bash
git add sprout/Features/Onboarding/OnboardingView.swift
git commit -m "feat(onboarding): add OnboardingView main container"
```

---

### Task 5: 修改 SproutApp 入口 + 已有用户迁移

**Files:**
- 修改: `sprout/SproutApp.swift:12-13` (添加属性)
- 修改: `sprout/SproutApp.swift:53-62` (修改 body)
- 新建: `sproutTests/OnboardingMigrationTests.swift`

- [ ] **Step 1: 写已有用户迁移测试**

```swift
// sproutTests/OnboardingMigrationTests.swift
import Testing
import SwiftData
@testable import sprout

@MainActor
struct OnboardingMigrationTests {

    @Test("迁移：已有宝宝的默认用户不走 onboarding")
    func testMigrationSkipsOnboarding() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()

        // 模拟已有用户：已存在一个 baby
        repo.createDefaultIfNeeded()
        repo.updateName("小花生")

        // 迁移逻辑应返回 true（跳过 onboarding）
        let shouldSkip = OnboardingMigration.shouldSkipOnboarding(
            babyRepository: repo,
            defaults: env.defaults
        )
        #expect(shouldSkip == true)
    }

    @Test("迁移：全新用户需要走 onboarding")
    func testNewUserNeedsOnboarding() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()

        // 全新用户：没有 baby
        let shouldSkip = OnboardingMigration.shouldSkipOnboarding(
            babyRepository: repo,
            defaults: env.defaults
        )
        #expect(shouldSkip == false)
    }

    @Test("迁移：默认名 '宝宝' 仍需走 onboarding")
    func testDefaultNameStillNeedsOnboarding() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()

        // 有 baby 但名字是默认的"宝宝"
        repo.createDefaultIfNeeded()

        let shouldSkip = OnboardingMigration.shouldSkipOnboarding(
            babyRepository: repo,
            defaults: env.defaults
        )
        #expect(shouldSkip == false)
    }

    @Test("迁移完成后标记 hasCompletedOnboarding")
    func testMigrationMarksComplete() async throws {
        let env = try makeTestEnvironment(now: .now)
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()
        repo.updateName("小花生")

        let key = "hasCompletedOnboarding"
        #expect(env.defaults.bool(forKey: key) == false)

        OnboardingMigration.migrateIfNeeded(
            babyRepository: repo,
            defaults: env.defaults
        )

        #expect(env.defaults.bool(forKey: key) == true)
    }
}
```

- [ ] **Step 2: 运行测试，确认编译失败**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/OnboardingMigrationTests 2>&1 | tail -5`
Expected: 编译错误 — `Cannot find 'OnboardingMigration' in scope`

- [ ] **Step 3: 在 OnboardingModels.swift 中追加 OnboardingMigration**

在 `sprout/Features/Onboarding/OnboardingModels.swift` 末尾追加：

```swift
import SwiftData

enum OnboardingMigration {
    private static let completionKey = "hasCompletedOnboarding"

    static func shouldSkipOnboarding(
        babyRepository: BabyRepository,
        defaults: UserDefaults
    ) -> Bool {
        guard defaults.object(forKey: completionKey) == nil else {
            return defaults.bool(forKey: completionKey)
        }
        // 没有标记过 → 检查是否有已自定义的 baby
        guard let baby = babyRepository.activeBaby else {
            return false
        }
        return baby.name != "宝宝"
    }

    static func migrateIfNeeded(
        babyRepository: BabyRepository,
        defaults: UserDefaults
    ) {
        guard shouldSkipOnboarding(babyRepository: babyRepository, defaults: defaults) else {
            return
        }
        defaults.set(true, forKey: completionKey)
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/OnboardingMigrationTests 2>&1 | tail -5`
Expected: 4 tests passed

- [ ] **Step 5: 修改 SproutApp.swift 入口**

在 `SproutApp` 结构体中添加属性并修改 body：

```swift
// sprout/SproutApp.swift — 修改部分

@main
struct SproutApp: App {
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // ... makeSharedModelContainer, clearPersistentStoreFiles 不变 ...

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                TestHostView()
            } else if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                ContentView()
            }
        }
        .modelContainer(Self.makeSharedModelContainer())
    }
}
```

同时在 `OnboardingView` 的 `onAppear` 中添加迁移检查（修改 Task 4 中创建的文件）：

```swift
// OnboardingView.swift — onAppear 中追加迁移逻辑
.onAppear {
    let repo = BabyRepository(modelContext: modelContext)
    OnboardingMigration.migrateIfNeeded(
        babyRepository: repo,
        defaults: UserDefaults.standard
    )
    // 迁移可能导致 hasCompletedOnboarding 变为 true
    // SwiftUI 会自动响应 @AppStorage 变化切换到 ContentView

    withAnimation(.easeInOut(duration: 0.8)) {
        appeared = true
    }
}
```

- [ ] **Step 6: 全量编译确认**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: 全量测试确认**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
Expected: All tests passed

- [ ] **Step 8: 提交**

```bash
git add sprout/Features/Onboarding/OnboardingModels.swift sprout/Features/Onboarding/OnboardingView.swift sprout/SproutApp.swift sproutTests/OnboardingMigrationTests.swift
git commit -m "feat(onboarding): integrate entry point with migration for existing users"
```

---

### Task 6: 最终验证

- [ ] **Step 1: 清理构建 + 全量测试**

Run: `xcodebuild clean test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(Test Suite|passed|failed|BUILD)'`
Expected: All tests passed, BUILD SUCCEEDED

- [ ] **Step 2: 在模拟器中手动验证流程**

1. 卸载 app → 重新安装 → 应看到 OnboardingView
2. Step 1: 输入名字 → "继续" 按钮变亮 → 点击继续
3. Step 2: 相册权限页 → 点"以后再说" → 过渡到通知权限页
4. Step 2: 通知权限页 → 点"以后再说" → 全局淡出 → 进入首页
5. 杀掉 app → 重新打开 → 应直接进入首页（不再显示 onboarding）

- [ ] **Step 3: 最终提交（如有手动修复）**

```bash
git add -A
git commit -m "feat(onboarding): final polish and manual verification pass"
```
