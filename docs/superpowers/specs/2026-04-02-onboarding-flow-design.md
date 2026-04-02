# Onboarding Flow Design Spec

Date: 2026-04-02
Status: Draft

## Overview

A "three-step breathing" onboarding flow for the Sprout app's cold launch. Replaces the current silent `createDefaultIfNeeded()` with a guided experience that collects baby name + birthday, requests photo/notification permissions with custom explanation screens, then transitions to the main app.

Design principles: minimalist, anti-anxiety, journal-like. White paper + dark text + sage green accents. No cards, no shadows, no illustrations.

## Architecture

### Approach: Minimal Files (Option A)

No new Store. OnboardingView manages its own state via `@State`. Data persistence uses the existing `BabyRepository`. A single `@AppStorage("hasCompletedOnboarding")` flag controls the app entry point.

### New Files

```
sprout/Features/Onboarding/
├── OnboardingView.swift       # Main container: step switching + animation orchestration
├── OnboardingModels.swift     # OnboardingStep enum, OnboardingDraft
└── OnboardingStepViews.swift  # Three step subviews
```

### Modified Files

- `SproutApp.swift` — Add `@AppStorage("hasCompletedOnboarding")` check before `ContentView`
- `ContentView.swift` — No structural change; `createDefaultIfNeeded()` remains idempotent

### Data Flow

```
SproutApp
  ├─ hasCompletedOnboarding == false → OnboardingView
  │   ├─ Step 1: User fills name + birthday → BabyRepository.updateName/birthDate
  │   ├─ Step 2: Permission requests (PHPhotoLibrary / UNUserNotificationCenter)
  │   └─ Step 3: Set AppStorage("hasCompletedOnboarding") = true → auto-switch
  └─ hasCompletedOnboarding == true → ContentView (unchanged)
```

### Models (OnboardingModels.swift)

```swift
enum OnboardingStep: Int, CaseIterable {
    case identity     // Name + birthday
    case permissions  // Photo + notification
    case completion   // Auto-dismiss
}

struct OnboardingDraft {
    var name: String = ""
    var birthDate: Date = .now
}
```

## Step 1: Identity Input (OnboardingIdentityStep)

### Layout

Vertical, centered horizontally, biased toward top third of screen.

1. **Title**: "你好，初次见面。" — New York serif, 28pt, `primaryText`
2. **Name prompt**: "我们要记录的小生命，叫什么名字？" — 16pt, `secondaryText`
3. **Name TextField**: `.textFieldStyle(.plain)`, single underline (`Rectangle.frame(height: 0.5)`, `primaryText`), cursor tint `sageGreen`. No system border.
4. **Birthday prompt**: "ta 是哪一天来到地球的？" — 16pt, `secondaryText`
5. **DatePicker**: `.wheel` style, `.components([.date])`, defaults to today
6. **Continue button**: Plain text, `sageGreen`, semibold. Disabled with `opacity(0.3)` when name is empty.

### Behavior

- On "继续" tap: save name + birthday via `BabyRepository.updateName()` / `updateBirthDate()` (calls `createDefaultIfNeeded()` first to ensure BabyProfile exists)
- Transition to Step 2 with crossfade animation

### Entrance Animation

Page appears with `opacity(0→1)` + `offset(y: 20→0)`, `.easeInOut(duration: 0.8)`

## Step 2: Soft Permission Requests (OnboardingPermissionsStep)

Single page with two sequential phases. Photo permission first, then notification permission replaces it in-place.

### Phase A: Photo Permission

- **Icon**: `photo.on.rectangle`, `primaryText`
- **Title**: "留住时光的琥珀" — 22pt, New York serif, `primaryText`
- **Subtitle**: "我们需要相册权限，为你珍藏每一张照片。" — 14pt, `secondaryText`
- **Primary button**: "授权相册访问" — `sageGreen`, semibold. Taps trigger `PHPhotoLibrary.requestAuthorization(for: .readWrite)`
- **Skip link**: "以后再说" — `tertiaryText`, 12pt

### Phase B: Notification Permission (after photo action completes)

- **Icon**: `bell.fill`, `primaryText`
- **Title**: "不打扰的陪伴" — 22pt, New York serif, `primaryText`
- **Subtitle**: "只有在久未记录时，才会轻轻提醒你。" — 14pt, `secondaryText`
- **Primary button**: "开启提醒" — `sageGreen`, semibold. Taps trigger `UNUserNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound])`
- **Skip link**: "以后再说" — `tertiaryText`, 12pt

### Transition Between Phases

After user taps "授权相册访问" and system dialog dismisses (or taps "以后再说"):
- Photo area fades out: `opacity(1→0)` + `offset(y: 0→-10)`, 0.8s
- Notification area fades in: `opacity(0→1)` + `offset(y: 10→0)`, 0.8s
- Animation curve: `.easeInOut(duration: 0.8)`

### Skipping

Both phases have a "以后再说" skip option. Skipping photo goes to notification phase; skipping notification goes to Step 3.

## Step 3: Completion & Transition

No visible UI. Automatically triggered after Step 2 finishes.

1. Set `@AppStorage("hasCompletedOnboarding") = true`
2. OnboardingView performs global fadeout: `opacity(1→0)` + `scaleEffect(1→0.98)`, `.easeInOut(duration: 0.6)`
3. SproutApp detects flag change, switches to `ContentView`

## Step Transition Animation

All step transitions use the same pattern:

- Outgoing step: `opacity(1→0)` + `offset(y: 0→-10)`
- Incoming step: `opacity(0→1)` + `offset(y: 10→0)`
- Curve: `.easeInOut(duration: 0.8)`
- Background: `AppTheme.Colors.background`, `.ignoresSafeArea()`

## Global Style

- **Background**: `AppTheme.Colors.background`, ignores safe area
- **Title font**: New York serif via `.font(.system(size: 28, design: .serif))`
- **Accent color**: `AppTheme.Colors.sageGreen`
- **Text colors**: `primaryText` (dark charcoal), `secondaryText` (0.6 opacity), `tertiaryText` (0.4 opacity)
- **No cards, no shadows, no illustrations** — white paper + dark text + green accents only

## Localization

All user-facing strings use `L10n.text()` with en + zh:

| Key | en | zh |
|-----|----|----|
| onboarding.greeting | Hello, nice to meet you. | 你好，初次见面。 |
| onboarding.name_hint | What shall we call the little one? | 我们要记录的小生命，叫什么名字？ |
| onboarding.birthday_hint | When did they arrive on Earth? | ta 是哪一天来到地球的？ |
| onboarding.continue | Continue | 继续 |
| onboarding.photo_title | Amber of Moments | 留住时光的琥珀 |
| onboarding.photo_subtitle | We need photo access to treasure every picture. | 我们需要相册权限，为你珍藏每一张照片。 |
| onboarding.photo_authorize | Grant Photo Access | 授权相册访问 |
| onboarding.notif_title | Gentle Companion | 不打扰的陪伴 |
| onboarding.notif_subtitle | We'll only nudge you when you haven't logged in a while. | 只有在久未记录时，才会轻轻提醒你。 |
| onboarding.notif_enable | Enable Reminders | 开启提醒 |
| onboarding.skip | Maybe Later | 以后再说 |

## SproutApp Entry Point Change

```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
```

OnboardingView receives `modelContext` from the environment and creates its own `BabyRepository` for Step 1 data saving.

## What This Does NOT Include

- No gender selection (BabyProfile supports it but it's not in the onboarding spec)
- No registration, phone number, or password (iCloud sync assumed)
- No complex cards, nested layouts, or decorative illustrations
- No separate Store/ViewModel — state managed in-view
