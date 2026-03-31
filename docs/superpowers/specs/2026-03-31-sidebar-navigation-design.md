# Sidebar Navigation Design

Date: 2026-03-31

## Overview

Implement functional navigation for the existing sidebar drawer. The sidebar serves as the app's settings entry point, using an X (Twitter)-style in-sidebar navigation stack for secondary pages. Current UI and visual style remain unchanged; only functional logic and secondary pages are added.

## Requirements

| Item | Decision |
|------|----------|
| Positioning | App settings entry (management-oriented) |
| Menu items | profile → Baby Profile, preferences → Language & Region, +Family Group (Pro), +Cloud Sync (Pro) |
| Navigation style | In-sidebar NavigationStack with slide-in secondary pages |
| Pro items | Tap → PaywallSheet (not a push navigation) |
| UI style | Preserve existing AppTheme; secondary pages follow same design tokens |
| Baby profile | Editable + persisted via SwiftData |
| Pro features | V1: paywall UI placeholder only |

## Architecture

### Navigation Stack

```
SidebarDrawer(babyRepository:)
  └─ NavigationStack(path: $navigationPath)
       ├─ Root: SidebarMenuView (existing one-level menu UI, extracted)
       │    ├─ headerCard (baby avatar card)
       │    ├─ indexCard (4 menu items)
       │    └─ footerNote
       ├─ .navigationDestination(for: SidebarRoute.self)
       │    ├─ .babyProfile  → BabyProfileView(babyRepository:)
       │    └─ .language     → LanguageRegionView()
       └─ .sheet(item: $proSheetItem) → PaywallSheet()
```

### Route Model

```swift
enum SidebarRoute: Hashable {
    case babyProfile
    case language
}
```

- `SidebarIndexItem` gains a `route: SidebarRoute?` field (Pro items have `nil`, triggering sheet instead)
- `SidebarIndexItem` gains an `isPro: Bool` field
- `SidebarIndexItem` items array changes from 3 to 4: profile, preferences, family (Pro), cloud (Pro). The existing `rhythm` item is removed.

### Sidebar Behavior

| Action | Behavior |
|--------|----------|
| Tap Baby Profile | `navigationPath.append(.babyProfile)` |
| Tap Language & Region | `navigationPath.append(.language)` |
| Tap Pro item | `proSheetItem = item` → `.sheet(PaywallSheet())` |
| Back button (top-left) | `@Environment(\.dismiss)`, custom styled |
| Swipe right to go back | NavigationStack native gesture |
| Sidebar closes | `navigationPath.removeAll()` on `onChange(of: showSidebar)` |

### Gesture Conflict Resolution

When `NavigationStack` has a non-root path (user is on a secondary page), the sidebar dismiss gesture (`dismissGesture` in `AppShellView`) must not interfere with the NavigationStack's built-in swipe-back gesture.

Implementation: `SidebarDrawer` exposes a `@Binding var isNavigationAtRoot: Bool`. When `isNavigationAtRoot == false`, `AppShellView` disables the dismiss drag gesture. The dimmed overlay tap-to-dismiss still works.

### Dependency Injection

`BabyRepository` is injected through the view hierarchy:

1. `ContentView` creates `BabyRepository` (with `modelContext`)
2. `ContentView` passes it to `AppShellView`
3. `AppShellView` passes it to `SidebarDrawer`
4. `SidebarDrawer` passes it to `BabyProfileView` via navigation destination

This follows the existing pattern where Stores receive their dependencies via init, not through `@Environment`.

## Data Persistence

### BabyProfile Model

```swift
// sprout/Domain/Baby/BabyProfile.swift
@Model
final class BabyProfile {
    var name: String
    var birthDate: Date
    var gender: Gender?
    var createdAt: Date
    var isActive: Bool  // V1: only one active

    enum Gender: String, Codable {
        case male, female
    }
}
```

- Registered in existing `ModelContainer` alongside `RecordItem`, `MemoryEntry`, `WeeklyLetter`
- V1 creates a single `BabyProfile(isActive: true)` on first launch
- Architecture supports multi-baby without persistence layer changes

### BabyRepository

```swift
// sprout/Domain/Baby/BabyRepository.swift
@MainActor
final class BabyRepository {
    private let modelContext: ModelContext
    var activeBaby: BabyProfile?  // fetched from modelContext

    init(modelContext: ModelContext)
    func createDefaultIfNeeded()
    func updateName(_ name: String)
    func updateBirthDate(_ date: Date)
    func updateGender(_ gender: BabyProfile.Gender?)
}
```

- Marked `@MainActor` to match existing Repository pattern (all Store/View access is main-thread)
- Follows existing Repository pattern (RecordRepository, GrowthRecordRepository, etc.)
- Wraps SwiftData `ModelContext` CRUD

### HomeHeaderConfig Changes

- `HomeHeaderConfig` is currently a value type passed into Stores at init time
- To support reactive updates when BabyProfile is edited, `HomeHeaderConfig` gains a static factory method: `static func from(_ baby: BabyProfile?) -> HomeHeaderConfig`
- `HomeStore` gains an `updateHeaderConfig(_ config: HomeHeaderConfig)` method
- When `BabyProfileView` saves changes, `AppShellView` observes the change and calls `store.updateHeaderConfig(...)` to refresh the header across all views
- Alternative: `headerConfig` becomes a `@Published`-equivalent `var` on `HomeStore` (already `@Observable`), and `SidebarDrawer` reads from `store.headerConfig` directly

### First Launch Defaults

- `ContentView.task` calls `babyRepository.createDefaultIfNeeded()`
- Default values: `name = "宝宝"` (localized), `birthDate = Date()` (today), `gender = nil`, `isActive = true`
- Detection: `FetchDescriptor<BabyProfile>()` returns empty → create default

### ModelContainer Update & Migration

`SproutApp.swift`: Add `BabyProfile.self` to schema.

SwiftData lightweight migration handles adding a new model type without data loss. No `VersionedSchema` or `SchemaMigrationPlan` needed since `BabyProfile` is a new table (no existing schema changes). The existing `clearPersistentStoreFiles()` fallback remains as safety net.

### Additional Schema Updates

- `PreviewContainer.make()` in `AppTheme.swift`: add `BabyProfile.self` to preview schema
- `TestEnvironment` in `TestSupport.swift`: add `BabyProfile.self` to test schema, add `makeBabyRepository()` factory

## File Structure

### New Files

| File | Location | Purpose |
|------|----------|---------|
| `BabyProfile.swift` | `sprout/Domain/Baby/` | SwiftData model |
| `BabyRepository.swift` | `sprout/Domain/Baby/` | SwiftData CRUD wrapper |
| `SidebarMenuView.swift` | `sprout/Features/Shell/` | Extracted one-level menu content |
| `BabyProfileView.swift` | `sprout/Features/Shell/` | Baby profile editing page |
| `LanguageRegionView.swift` | `sprout/Features/Shell/` | Language and region settings |
| `PaywallSheet.swift` | `sprout/Features/Shell/` | Pro paywall placeholder sheet |

### Modified Files

| File | Change |
|------|--------|
| `SidebarDrawer.swift` | Wrap in NavigationStack, expand index items to 4, add NavigationLink logic, accept `babyRepository:` parameter |
| `SidebarIndexItem` (in SidebarDrawer.swift) | Add `isPro: Bool`, `route: SidebarRoute?`, replace rhythm with family/cloud items |
| `HomeModels.swift` | `HomeHeaderConfig` gains `static func from(_ baby:) -> HomeHeaderConfig` |
| `HomeStore.swift` | Add `updateHeaderConfig(_ config:)` method |
| `AppShellView.swift` | Pass `babyRepository` to `SidebarDrawer`, add `isNavigationAtRoot` binding for gesture control, refresh header on profile change |
| `SproutApp.swift` | Add `BabyProfile.self` to ModelContainer schema |
| `ContentView.swift` | Create `BabyRepository`, call `createDefaultIfNeeded()`, pass to `AppShellView` |
| `TestSupport.swift` | Add `BabyProfile.self` to test schema, add `makeBabyRepository()` factory |
| `AppTheme.swift` | Add `BabyProfile.self` to `PreviewContainer.make()` schema |

## Secondary Pages

### BabyProfileView

| Field | Control | Notes |
|-------|---------|-------|
| Avatar | Circle monogram (first char) | V1: not editable, V2: image support |
| Nickname | TextField | Save on change via BabyRepository |
| Birth date | DatePicker (.graphical) | Bottom sheet picker |
| Gender | Chip selector (Male / Female / Unset) | Tap selected chip to deselect back to nil |

- Save-on-edit: each field change triggers immediate `babyRepository.update*()`
- Header card in sidebar updates reactively via `HomeStore.headerConfig` observation
- Closing sidebar while on edit page is safe — all changes are already saved on edit

### LanguageRegionView

| Field | Control | Notes |
|-------|---------|-------|
| Language | Two-option chip: 中文 / English | Writes to `LocalizationService` (not raw `@AppStorage`) |
| Timezone | Follow system (auto) | V1: read-only, follows system setting |

- Language change syncs with existing `LocalizationService` (which manages bundle/locale)
- After changing language, show alert: "语言切换将在重启应用后生效 / Language change takes effect after restart" (localized en + zh)

### PaywallSheet

- Simple sheet with Pro feature description + upgrade button
- V1: upgrade button shows a temporary toast overlay (not UndoToast — a lightweight `Text` overlay that auto-dismisses after 2 seconds, styled with AppTheme)
- No actual payment integration

## Testing

| Test | Type | Coverage |
|------|------|----------|
| `BabyRepositoryTests` | Unit | CRUD, activeBaby query, field updates, createDefaultIfNeeded |
| `SidebarIndexItem` validation | Unit | 4 items, isPro flags correct, route mapping correct |
| `SidebarRoute` logic | Unit | Pro items resolve to sheet, non-Pro items resolve to correct route |
| `HomeHeaderConfig` generation | Unit | `from(baby:)` factory, placeholder fallback when baby is nil |
| Manual testing | UI | Navigation transitions, swipe-back, gesture conflict, Pro sheet, live editing |

- Uses existing `TestEnvironment` (in-memory SwiftData with `BabyProfile` in schema + isolated UserDefaults)
- `TestEnvironment.makeBabyRepository()` factory for easy test setup
- No UI test infrastructure; navigation verified manually

## Future-Proofing: Multi-Baby

When multi-baby switching is needed:

1. Add baby switcher UI to sidebar header
2. Add `switchTo(_:)` to `BabyRepository`
3. Each Store's `configure()` filters data by active baby
4. **No persistence layer changes needed** — SwiftData already supports multiple `BabyProfile` records
