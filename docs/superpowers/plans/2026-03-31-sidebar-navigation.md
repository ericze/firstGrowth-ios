# Sidebar Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement functional sidebar navigation with X-style in-sidebar NavigationStack, baby profile persistence, and Pro paywall placeholder.

**Architecture:** SidebarDrawer wraps a NavigationStack for push-based secondary pages. BabyProfile is a new SwiftData model persisted via BabyRepository. SidebarIndexItem expands to 4 items with Pro/item routing. Gesture conflicts between NavigationStack swipe-back and sidebar dismiss are resolved via `isNavigationAtRoot` binding.

**Tech Stack:** SwiftUI, SwiftData, NavigationStack, existing AppTheme design tokens

**Spec:** `docs/superpowers/specs/2026-03-31-sidebar-navigation-design.md`

---

## Task 1: BabyProfile Model + Schema Registration

**Files:**
- Create: `sprout/Domain/Baby/BabyProfile.swift`
- Modify: `sprout/SproutApp.swift:16-20` (schema)
- Modify: `sprout/DesignSystem/AppTheme.swift:120-124` (preview schema)
- Modify: `sproutTests/TestSupport.swift:27-31` (test schema)

- [ ] **Step 1: Create BabyProfile model**

```swift
// sprout/Domain/Baby/BabyProfile.swift
import Foundation
import SwiftData

@Model
final class BabyProfile {
    var name: String
    var birthDate: Date
    var gender: Gender?
    var createdAt: Date
    var isActive: Bool

    enum Gender: String, Codable {
        case male
        case female
    }

    init(
        name: String = String(localized: "common.baby.placeholder"),
        birthDate: Date = .now,
        gender: Gender? = nil,
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
```

- [ ] **Step 2: Register BabyProfile in all 3 schema locations**

In `sprout/SproutApp.swift` line ~17, add `BabyProfile.self` to the Schema array:
```swift
let schema = Schema([
    RecordItem.self,
    MemoryEntry.self,
    WeeklyLetter.self,
    BabyProfile.self,  // add
])
```

Same change in `sprout/DesignSystem/AppTheme.swift` line ~120 and `sproutTests/TestSupport.swift` line ~27.

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add sprout/Domain/Baby/BabyProfile.swift sprout/SproutApp.swift sprout/DesignSystem/AppTheme.swift sproutTests/TestSupport.swift
git commit -m "feat: add BabyProfile SwiftData model and register in all schemas"
```

---

## Task 2: BabyRepository with Tests

**Files:**
- Create: `sprout/Domain/Baby/BabyRepository.swift`
- Create: `sproutTests/BabyRepositoryTests.swift`
- Modify: `sproutTests/TestSupport.swift` (add `modelContext` property + `makeBabyRepository` factory)

- [ ] **Step 1: Expose `modelContext` on `TestEnvironment`**

In `sproutTests/TestSupport.swift`, add `let modelContext: ModelContext` to the `TestEnvironment` struct properties. In `makeTestEnvironment()`, store the `container.mainContext` and pass it to the `TestEnvironment` initializer. This is a prerequisite for all tests that need `BabyRepository`.

```swift
// Add to TestEnvironment struct:
let modelContext: ModelContext

// In makeTestEnvironment(), after creating the container:
let modelContext = container.mainContext
// Pass modelContext to TestEnvironment init
```

- [ ] **Step 2: Write BabyRepository tests**

```swift
// sproutTests/BabyRepositoryTests.swift
import Testing
import SwiftData
@testable import sprout

@MainActor
struct BabyRepositoryTests {

    @Test("createDefaultIfNeeded creates a baby when none exist")
    func testCreateDefault() async throws {
        let env = TestEnvironment.makeTestEnvironment()
        let repo = env.makeBabyRepository()

        repo.createDefaultIfNeeded()

        let baby = repo.activeBaby
        #expect(baby != nil)
        #expect(baby?.isActive == true)
        #expect(baby?.gender == nil)
    }

    @Test("createDefaultIfNeeded does not duplicate when baby exists")
    func testNoDuplicate() async throws {
        let env = TestEnvironment.makeTestEnvironment()
        let repo = env.makeBabyRepository()

        repo.createDefaultIfNeeded()
        repo.createDefaultIfNeeded()

        let descriptor = FetchDescriptor<BabyProfile>()
        let babies = try env.modelContext.fetch(descriptor)
        #expect(babies.count == 1)
    }

    @Test("updateName persists change")
    func testUpdateName() async throws {
        let env = TestEnvironment.makeTestEnvironment()
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()

        repo.updateName("小花生")

        #expect(repo.activeBaby?.name == "小花生")
    }

    @Test("updateBirthDate persists change")
    func testUpdateBirthDate() async throws {
        let env = TestEnvironment.makeTestEnvironment()
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()

        let newDate = Date(timeIntervalSinceNow: -86400 * 100)
        repo.updateBirthDate(newDate)

        #expect(repo.activeBaby?.birthDate != nil)
    }

    @Test("updateGender persists change")
    func testUpdateGender() async throws {
        let env = TestEnvironment.makeTestEnvironment()
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()

        repo.updateGender(.male)
        #expect(repo.activeBaby?.gender == .male)

        repo.updateGender(nil)
        #expect(repo.activeBaby?.gender == nil)
    }

    @Test("activeBaby returns nil when no babies exist")
    func testActiveBabyNil() async throws {
        let env = TestEnvironment.makeTestEnvironment()
        let repo = env.makeBabyRepository()

        #expect(repo.activeBaby == nil)
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/BabyRepositoryTests 2>&1 | tail -10`
Expected: FAIL — `BabyRepository` type does not exist

- [ ] **Step 4: Implement BabyRepository**

```swift
// sprout/Domain/Baby/BabyRepository.swift
import SwiftData

@MainActor
final class BabyRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var activeBaby: BabyProfile? {
        var descriptor = FetchDescriptor<BabyProfile>(
            predicate: #Predicate { $0.isActive == true }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func createDefaultIfNeeded() {
        guard activeBaby == nil else { return }
        let baby = BabyProfile()
        modelContext.insert(baby)
        try? modelContext.save()
    }

    func updateName(_ name: String) {
        guard let baby = activeBaby else { return }
        baby.name = name
        try? modelContext.save()
    }

    func updateBirthDate(_ date: Date) {
        guard let baby = activeBaby else { return }
        baby.birthDate = date
        try? modelContext.save()
    }

    func updateGender(_ gender: BabyProfile.Gender?) {
        guard let baby = activeBaby else { return }
        baby.gender = gender
        try? modelContext.save()
    }
}
```

- [ ] **Step 5: Add TestEnvironment.makeBabyRepository() factory**

In `sproutTests/TestSupport.swift`, add inside `TestEnvironment`:
```swift
func makeBabyRepository() -> BabyRepository {
    BabyRepository(modelContext: modelContext)
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/BabyRepositoryTests 2>&1 | tail -10`
Expected: all 6 tests PASS

- [ ] **Step 7: Commit**

```bash
git add sprout/Domain/Baby/BabyRepository.swift sproutTests/BabyRepositoryTests.swift sproutTests/TestSupport.swift
git commit -m "feat: add BabyRepository with CRUD + tests"
```

---

## Task 3: SidebarRoute + Updated SidebarIndexItem

**Files:**
- Modify: `sprout/Features/Shell/SidebarDrawer.swift:166-188` (SidebarIndexItem + add SidebarRoute)
- Create: `sproutTests/SidebarRoutingTests.swift`

- [ ] **Step 1: Write SidebarIndexItem tests**

```swift
// sproutTests/SidebarRoutingTests.swift
import Testing
@testable import sprout

struct SidebarRoutingTests {

    @Test("items count is 4")
    func testItemCount() {
        #expect(SidebarIndexItem.items.count == 4)
    }

    @Test("Pro items are correctly marked")
    func testProFlags() {
        let proItems = SidebarIndexItem.items.filter(\.isPro)
        #expect(proItems.count == 2)
        #expect(proItems.map(\.id).sorted() == ["cloud", "family"])
    }

    @Test("non-Pro items have valid routes")
    func testNonProRoutes() {
        let nonPro = SidebarIndexItem.items.filter { !$0.isPro }
        #expect(nonPro.count == 2)
        for item in nonPro {
            #expect(item.route != nil)
        }
    }

    @Test("Pro items have nil routes")
    func testProNilRoutes() {
        let proItems = SidebarIndexItem.items.filter(\.isPro)
        for item in proItems {
            #expect(item.route == nil)
        }
    }

    @Test("rhythm item is removed")
    func testRhythmRemoved() {
        let ids = SidebarIndexItem.items.map(\.id)
        #expect(!ids.contains("rhythm"))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/SidebarRoutingTests 2>&1 | tail -10`
Expected: FAIL — `SidebarIndexItem` still has 3 items, no `isPro`/`route` fields

- [ ] **Step 3: Implement SidebarRoute + update SidebarIndexItem**

In `sprout/Features/Shell/SidebarDrawer.swift`, add the route enum before `SidebarIndexItem`:

```swift
enum SidebarRoute: Hashable {
    case babyProfile
    case language
}
```

Replace the `SidebarIndexItem` struct and `items` array (lines 166-188):

```swift
struct SidebarIndexItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let isPro: Bool
    let route: SidebarRoute?

    static let items: [SidebarIndexItem] = [
        SidebarIndexItem(
            id: "profile",
            title: String(localized: "shell.sidebar.profile.title"),
            detail: String(localized: "shell.sidebar.profile.detail"),
            isPro: false,
            route: .babyProfile
        ),
        SidebarIndexItem(
            id: "preferences",
            title: String(localized: "shell.sidebar.preferences.title"),
            detail: String(localized: "shell.sidebar.preferences.detail"),
            isPro: false,
            route: .language
        ),
        SidebarIndexItem(
            id: "family",
            title: String(localized: "shell.sidebar.family.title"),
            detail: String(localized: "shell.sidebar.family.detail"),
            isPro: true,
            route: nil
        ),
        SidebarIndexItem(
            id: "cloud",
            title: String(localized: "shell.sidebar.cloud.title"),
            detail: String(localized: "shell.sidebar.cloud.detail"),
            isPro: true,
            route: nil
        ),
    ]
}
```

- [ ] **Step 4: Add localization keys**

In `sprout/Localization/Localizable.xcstrings`, add these new keys:

| Key | en | zh-Hans |
|-----|-----|---------|
| `shell.sidebar.family.title` | "Family Group" | "家庭组" |
| `shell.sidebar.family.detail` | "Invite family to share records" | "邀请家人共同记录" |
| `shell.sidebar.cloud.title` | "Cloud Sync" | "云端同步" |
| `shell.sidebar.cloud.detail` | "Secure data backup" | "数据安全备份" |

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/SidebarRoutingTests 2>&1 | tail -10`
Expected: all 5 tests PASS

- [ ] **Step 6: Commit**

```bash
git add sprout/Features/Shell/SidebarDrawer.swift sproutTests/SidebarRoutingTests.swift sprout/Localization/Localizable.xcstrings
git commit -m "feat: add SidebarRoute, update SidebarIndexItem to 4 items with Pro flags"
```

---

## Task 4: HomeHeaderConfig + HomeStore Update

**Files:**
- Modify: `sprout/Features/Home/HomeModels.swift:65-73` (HomeHeaderConfig)
- Modify: `sprout/Features/Home/HomeStore.swift:14` (headerConfig mutability)
- Modify: `sprout/Features/Growth/GrowthStore.swift` (headerConfig mutability)
- Modify: `sprout/Features/Treasure/TreasureStore.swift` (headerConfig mutability)
- Create: `sproutTests/HomeHeaderConfigTests.swift`

- [ ] **Step 1: Write HomeHeaderConfig tests**

```swift
// sproutTests/HomeHeaderConfigTests.swift
import Testing
@testable import sprout

struct HomeHeaderConfigTests {

    @Test("from baby creates config with baby data")
    func testFromBaby() async throws {
        let env = TestEnvironment.makeTestEnvironment()
        let repo = env.makeBabyRepository()
        repo.createDefaultIfNeeded()
        repo.updateName("小花生")
        let config = HomeHeaderConfig.from(repo.activeBaby)
        #expect(config.babyName == "小花生")
    }

    @Test("from nil returns placeholder")
    func testFromNil() {
        let config = HomeHeaderConfig.from(nil as BabyProfile?)
        #expect(config.babyName == HomeHeaderConfig.placeholder.babyName)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/HomeHeaderConfigTests 2>&1 | tail -10`
Expected: FAIL — `HomeHeaderConfig.from(_:)` does not exist

- [ ] **Step 3: Add factory method to HomeHeaderConfig**

In `sprout/Features/Home/HomeModels.swift`, add to `HomeHeaderConfig`:

```swift
struct HomeHeaderConfig: Equatable {
    var babyName: String
    var birthDate: Date

    static let placeholder = HomeHeaderConfig(
        babyName: String(localized: "common.baby.placeholder"),
        birthDate: Calendar.current.date(byAdding: .day, value: -128, to: .now) ?? .now
    )

    static func from(_ baby: BabyProfile?) -> HomeHeaderConfig {
        guard let baby else { return .placeholder }
        return HomeHeaderConfig(babyName: baby.name, birthDate: baby.birthDate)
    }
}
```

Note: `babyName` and `birthDate` change from `let` to `var` to support updates.

- [ ] **Step 4: Add `updateHeaderConfig` to all 3 stores**

In `sprout/Features/Home/HomeStore.swift`, change `headerConfig` from `let` to `var`:

```swift
// Line 14: change from
@ObservationIgnored let headerConfig: HomeHeaderConfig
// to
var headerConfig: HomeHeaderConfig
```

And add an update method:
```swift
func updateHeaderConfig(_ config: HomeHeaderConfig) {
    headerConfig = config
}
```

Note: Removing `@ObservationIgnored` makes it observable — views watching `store.headerConfig` will update automatically.

**Apply the same change to GrowthStore and TreasureStore:**
- `sprout/Features/Growth/GrowthStore.swift`: change `@ObservationIgnored let headerConfig` → `var headerConfig`, add `updateHeaderConfig(_:)` method
- `sprout/Features/Treasure/TreasureStore.swift`: same change

These must all be updated in the same commit so that `ContentView` can call `updateHeaderConfig` on all three stores uniformly.

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:sproutTests/HomeHeaderConfigTests 2>&1 | tail -10`
Expected: all tests PASS

Also run existing tests to verify nothing broke:
Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
Expected: all tests PASS

- [ ] **Step 6: Commit**

```bash
git add sprout/Features/Home/HomeModels.swift sprout/Features/Home/HomeStore.swift sproutTests/HomeHeaderConfigTests.swift
git commit -m "feat: add HomeHeaderConfig.from(baby:) factory + make headerConfig observable"
```

---

## Task 5: SidebarDrawer NavigationStack + SidebarMenuView Extraction

**Files:**
- Create: `sprout/Features/Shell/SidebarMenuView.swift`
- Modify: `sprout/Features/Shell/SidebarDrawer.swift`
- Modify: `sprout/Features/Shell/AppShellView.swift`

- [ ] **Step 1: Extract SidebarMenuView**

Create `sprout/Features/Shell/SidebarMenuView.swift` by extracting the body content from current `SidebarDrawer` (lines 21-124). This becomes the root view inside the NavigationStack:

```swift
// sprout/Features/Shell/SidebarMenuView.swift
import SwiftUI

struct SidebarMenuView: View {
    let headerConfig: HomeHeaderConfig
    let onHeaderTap: () -> Void
    let onNavigate: (SidebarRoute) -> Void
    let onProItemTap: (SidebarIndexItem) -> Void

    private let calendar = Calendar.current

    var body: some View {
        // Exact same ScrollView + VStack structure from current SidebarDrawer body
        // headerCard, indexCard, footerNote — unchanged
        // BUT: indexCard buttons now call:
        //   if item.isPro { onProItemTap(item) }
        //   else if let route = item.route { onNavigate(route) }
        // ... (all existing private helpers: headerCard, indexCard, footerNote,
        //      sidebarMetaRow, monogram, ageInDays, birthDateText, sidebarAgeText)
    }
}
```

The key change in `indexCard` buttons:
```swift
Button(action: {
    if item.isPro {
        onProItemTap(item)
    } else if let route = item.route {
        onNavigate(route)
    }
}) { /* same content */ }
```

- [ ] **Step 2: Rewrite SidebarDrawer to wrap NavigationStack**

```swift
// sprout/Features/Shell/SidebarDrawer.swift (rewritten)
import SwiftUI

struct SidebarDrawer: View {
    let headerConfig: HomeHeaderConfig
    let babyRepository: BabyRepository
    @Binding var isNavigationAtRoot: Bool
    @Binding var isSidebarOpen: Bool
    let onHeaderTap: () -> Void

    @State private var navigationPath = NavigationPath()
    @State private var proSheetItem: SidebarIndexItem?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SidebarMenuView(
                headerConfig: headerConfig,
                onHeaderTap: onHeaderTap,
                onNavigate: { route in
                    navigationPath.append(route)
                },
                onProItemTap: { item in
                    proSheetItem = item
                }
            )
            .navigationDestination(for: SidebarRoute.self) { route in
                switch route {
                case .babyProfile:
                    BabyProfileView(babyRepository: babyRepository)
                case .language:
                    LanguageRegionView()
                }
            }
        }
        .onChange(of: navigationPath) {
            isNavigationAtRoot = navigationPath.isEmpty
        }
        .onChange(of: isSidebarOpen) {
            if !isSidebarOpen {
                navigationPath.removeAll()
            }
        }
        .sheet(item: $proSheetItem) { item in
            PaywallSheet(featureTitle: item.title)
        }
        .background(AppTheme.Colors.background)
    }
}
```

- [ ] **Step 3: Update AppShellView**

Add `babyRepository` parameter and `isNavigationAtRoot` state:

```swift
// AppShellView.swift changes:

// Add property:
let babyRepository: BabyRepository

// Add state:
@State private var isNavigationAtRoot = true

// Update init to accept babyRepository:
init(
    store: HomeStore,
    growthStore: GrowthStore,
    treasureStore: TreasureStore,
    babyRepository: BabyRepository,
    initialTab: HomeModule = .record
) { ... }

// Update sidebarOverlay to pass new params:
SidebarDrawer(
    headerConfig: store.headerConfig,
    babyRepository: babyRepository,
    isNavigationAtRoot: $isNavigationAtRoot,
    onHeaderTap: { AppHaptics.selection() }
)

// Guard dismissGesture with isNavigationAtRoot:
// In dismissGesture, add early return:
guard isNavigationAtRoot else { return }
```

- [ ] **Step 4: Build to verify compilation**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (BabyProfileView, LanguageRegionView, PaywallSheet will be stubs at this point)

- [ ] **Step 5: Commit**

```bash
git add sprout/Features/Shell/SidebarMenuView.swift sprout/Features/Shell/SidebarDrawer.swift sprout/Features/Shell/AppShellView.swift
git commit -m "feat: wrap SidebarDrawer in NavigationStack, extract SidebarMenuView"
```

---

## Task 6: BabyProfileView

**Files:**
- Create: `sprout/Features/Shell/BabyProfileView.swift`

- [ ] **Step 1: Implement BabyProfileView**

```swift
// sprout/Features/Shell/BabyProfileView.swift
import SwiftUI

struct BabyProfileView: View {
    let babyRepository: BabyRepository
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var birthDate: Date = .now
    @State private var gender: BabyProfile.Gender?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                avatarSection
                formSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.Colors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(String(localized: "shell.sidebar.profile.title"))
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .onAppear { loadFromBaby() }
    }

    private var avatarSection: some View {
        VStack(spacing: 8) {
            Text(monogram)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .frame(width: 72, height: 72)
                .background(AppTheme.Colors.cardBackground)
                .overlay { Circle().stroke(AppTheme.Colors.divider, lineWidth: 1) }
                .clipShape(Circle())
            Text(String(localized: "shell.profile.avatar.hint"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            fieldRow(
                label: String(localized: "shell.profile.nickname"),
                content: AnyView(
                    TextField(String(localized: "shell.profile.nickname"), text: $name)
                        .font(AppTheme.Typography.cardBody)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .onChange(of: name) { _, newValue in
                            babyRepository.updateName(newValue)
                        }
                )
            )

            fieldRow(
                label: String(localized: "shell.sidebar.birth_date"),
                content: AnyView(
                    DatePicker(
                        "",
                        selection: $birthDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .onChange(of: birthDate) { _, newValue in
                        babyRepository.updateBirthDate(newValue)
                    }
                )
            )

            fieldRow(
                label: String(localized: "shell.profile.gender"),
                content: AnyView(
                    HStack(spacing: 8) {
                        genderChip(.male, label: String(localized: "shell.profile.gender.male"))
                        genderChip(.female, label: String(localized: "shell.profile.gender.female"))
                    }
                )
            )
        }
        .padding(24)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private func genderChip(_ gender: BabyProfile.Gender, label: String) -> some View {
        let isSelected = self.gender == gender
        return Button(action: {
            withAnimation(AppTheme.stateAnimation) {
                self.gender = isSelected ? nil : gender
            }
            babyRepository.updateGender(isSelected ? nil : gender)
            AppHaptics.selection()
        }) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
                .background(isSelected ? AppTheme.Colors.accent.opacity(0.12) : AppTheme.Colors.cardBackground)
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(AppTheme.Colors.divider, lineWidth: isSelected ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func fieldRow(label: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.Colors.tertiaryText)
            content
        }
    }

    private var monogram: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.first ?? "B")
    }

    private func loadFromBaby() {
        guard let baby = babyRepository.activeBaby else { return }
        name = baby.name
        birthDate = baby.birthDate
        gender = baby.gender
    }
}
```

- [ ] **Step 2: Add localization keys**

| Key | en | zh-Hans |
|-----|-----|---------|
| `shell.profile.avatar.hint` | "Tap to change" | "点击更换头像" |
| `shell.profile.nickname` | "Nickname" | "宝宝昵称" |
| `shell.profile.gender` | "Gender" | "性别" |
| `shell.profile.gender.male` | "Male" | "男" |
| `shell.profile.gender.female` | "Female" | "女" |

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add sprout/Features/Shell/BabyProfileView.swift sprout/Localization/Localizable.xcstrings
git commit -m "feat: add BabyProfileView with inline editing"
```

---

## Task 7: LanguageRegionView + PaywallSheet

**Files:**
- Create: `sprout/Features/Shell/LanguageRegionView.swift`
- Create: `sprout/Features/Shell/PaywallSheet.swift`

- [ ] **Step 1: Implement LanguageRegionView**

```swift
// sprout/Features/Shell/LanguageRegionView.swift
import SwiftUI

struct LanguageRegionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage: String = LocalizationService.current.currentLanguageCode
    @State private var showRestartAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                languageSection
                timezoneSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.Colors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(String(localized: "shell.sidebar.language.title"))
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .alert(
            String(localized: "shell.language.restart.title"),
            isPresented: $showRestartAlert
        ) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(String(localized: "shell.language.restart.message"))
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "shell.language.label"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.Colors.tertiaryText)

            HStack(spacing: 8) {
                langChip("zh", label: "中文")
                langChip("en", label: "English")
            }
        }
        .padding(24)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private var timezoneSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "shell.timezone.label"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.Colors.tertiaryText)
            Text(TimeZone.current.identifier)
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .padding(24)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private func langChip(_ code: String, label: String) -> some View {
        let isSelected = appLanguage == code
        return Button(action: {
            guard appLanguage != code else { return }
            appLanguage = code
            showRestartAlert = true
            AppHaptics.selection()
        }) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
                .background(isSelected ? AppTheme.Colors.accent.opacity(0.12) : AppTheme.Colors.cardBackground)
                .clipShape(Capsule())
                .overlay { Capsule().stroke(AppTheme.Colors.divider, lineWidth: isSelected ? 0 : 1) }
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Implement PaywallSheet**

```swift
// sprout/Features/Shell/PaywallSheet.swift
import SwiftUI

struct PaywallSheet: View {
    let featureTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false

    var body: some View {
        VStack(spacing: 24) {
            header
            features
            upgradeButton
            Spacer()
        }
        .padding(24)
        .background(AppTheme.Colors.background)
        .presentationDetents([.medium])
        .overlay {
            if showToast {
                toastOverlay
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.accent)
            Text(String(localized: "shell.paywall.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
            Text(featureTitle)
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .padding(.top, 16)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 12) {
            paywallFeatureRow(text: String(localized: "shell.paywall.feature.family"))
            paywallFeatureRow(text: String(localized: "shell.paywall.feature.cloud"))
            paywallFeatureRow(text: String(localized: "shell.paywall.feature.more"))
        }
        .padding(20)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }

    private var upgradeButton: some View {
        Button(action: {
            withAnimation(AppTheme.stateAnimation) {
                showToast = true
            }
            AppHaptics.mediumImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(AppTheme.stateAnimation) {
                    showToast = false
                }
            }
        }) {
            Text(String(localized: "shell.paywall.upgrade"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.capsule, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var toastOverlay: some View {
        Text(String(localized: "shell.paywall.coming_soon"))
            .font(AppTheme.Typography.cardBody)
            .foregroundStyle(AppTheme.Colors.primaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
            .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func paywallFeatureRow(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.Colors.accent)
            Text(text)
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
    }
}
```

- [ ] **Step 3: Add localization keys**

| Key | en | zh-Hans |
|-----|-----|---------|
| `shell.sidebar.language.title` | "Language & Region" | "语言与地区" |
| `shell.language.label` | "Language" | "语言" |
| `shell.language.restart.title` | "Restart Required" | "需要重启" |
| `shell.language.restart.message` | "Language change takes effect after restarting the app." | "语言切换将在重启应用后生效。" |
| `shell.timezone.label` | "Timezone" | "时区" |
| `shell.paywall.title` | "Sprout Pro" | "初长 Pro" |
| `shell.paywall.upgrade` | "Upgrade to Pro" | "升级到 Pro" |
| `shell.paywall.coming_soon` | "Coming soon" | "即将上线" |
| `shell.paywall.feature.family` | "Family group sharing" | "家庭组共享" |
| `shell.paywall.feature.cloud` | "Cloud data backup" | "云端数据备份" |
| `shell.paywall.feature.more` | "More premium features" | "更多高级功能" |
| `common.ok` | "OK" | "好的" |

- [ ] **Step 4: Build to verify compilation**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add sprout/Features/Shell/LanguageRegionView.swift sprout/Features/Shell/PaywallSheet.swift sprout/Localization/Localizable.xcstrings
git commit -m "feat: add LanguageRegionView and PaywallSheet"
```

---

## Task 8: ContentView Wiring + First Launch Bootstrap

**Files:**
- Modify: `sprout/ContentView.swift`

- [ ] **Step 1: Wire BabyRepository into ContentView**

Update `ContentView` to:
1. Create `BabyRepository` from modelContext
2. Call `createDefaultIfNeeded()` during bootstrap
3. Update `headerConfig` from active baby
4. Pass `babyRepository` to `AppShellView`
5. Update all 3 stores' headerConfig

**IMPORTANT: Preserve all existing logic.** The `.task` block already has specific ordering:
1. Launch overrides (env vars for seeding demo data)
2. Store configuration (modelContext injection)
3. Store onAppear calls
4. Growth/Treasure seeding

The BabyRepository bootstrapping must happen FIRST (before store configuration), and `updateHeaderConfig` must be called on ALL THREE stores (HomeStore, GrowthStore, TreasureStore).

```swift
// ContentView.swift key changes:
// 1. Add @State private var babyRepository: BabyRepository?
// 2. In .task, BEFORE existing configure calls:
//      let repo = BabyRepository(modelContext: modelContext)
//      repo.createDefaultIfNeeded()
//      babyRepository = repo
//
//      let config = HomeHeaderConfig.from(repo.activeBaby)
//      store.updateHeaderConfig(config)
//      growthStore.updateHeaderConfig(config)    // ADD updateHeaderConfig to GrowthStore too
//      treasureStore.updateHeaderConfig(config)  // ADD updateHeaderConfig to TreasureStore too
//
// 3. In body, guard on babyRepository != nil before showing AppShellView
// 4. Pass babyRepository to AppShellView init
//
// 5. AFTER BabyRepository setup, continue with ALL existing logic unchanged:
//      AppLaunchOverrides.applyIfNeeded(...)
//      store.configure(modelContext: modelContext)
//      growthStore.configure(modelContext: modelContext)
//      treasureStore.configure(modelContext: modelContext)
//      store.onAppear()
//      growthStore.onAppear()
//      treasureStore.onAppear()
//      // ... growth/treasure seeding ...
```

Also update GrowthStore and TreasureStore: change `@ObservationIgnored let headerConfig: HomeHeaderConfig` to `var headerConfig: HomeHeaderConfig` and add `func updateHeaderConfig(_ config: HomeHeaderConfig) { headerConfig = config }` — same pattern as HomeStore.

- [ ] **Step 2: Build and manually test in simulator**

Run: `xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add sprout/ContentView.swift
git commit -m "feat: wire BabyRepository into ContentView, bootstrap first launch"
```

---

## Task 9: Full Test Suite + Manual QA

- [ ] **Step 1: Run full test suite**

Run: `xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: ALL TESTS PASS

- [ ] **Step 2: Manual QA checklist**

Launch app in simulator and verify:

- [ ] Tap avatar → sidebar opens with 4 menu items
- [ ] Baby Profile tap → slides to edit page within sidebar
- [ ] Edit name → header card updates live
- [ ] Edit birth date → header card updates
- [ ] Gender chip tap → toggles, tap again → deselects to nil
- [ ] Back button → returns to menu
- [ ] Swipe right → returns to menu
- [ ] Language & Region tap → slides to language page
- [ ] Language chip toggle → shows restart alert
- [ ] Timezone shows system timezone (read-only)
- [ ] Family Group tap → PaywallSheet slides up
- [ ] Cloud Sync tap → PaywallSheet slides up
- [ ] Paywall upgrade button → shows "coming soon" toast
- [ ] Close sidebar while on secondary page → next open shows menu (root)
- [ ] Right-swipe on secondary page does NOT accidentally close sidebar
- [ ] Kill and relaunch → profile edits persisted

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "chore: sidebar navigation feature complete, all tests passing"
```
