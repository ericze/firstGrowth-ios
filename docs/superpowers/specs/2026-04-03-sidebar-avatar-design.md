# Sidebar Avatar Navigation & Baby Profile Avatar Picker

Date: 2026-04-03

## Overview

Two related changes:
1. Remove "宝宝资料" menu item from sidebar; make the entire header card (avatar + name) tappable to navigate to BabyProfileView.
2. Add avatar photo picker to BabyProfileView, supporting album, camera, and removal.

## Section 1: Sidebar Changes

### Remove profile menu item

Delete `SidebarIndexItem.profile` from the index list. Remaining items: language preferences, family management (Pro), cloud backup (Pro).

### Header card navigation

`SidebarMenuView.headerCard` currently is a `Button { onHeaderTap() }` that closes the sidebar. Change to `Button { onNavigate(.babyProfile) }` which pushes `BabyProfileView` via the sidebar's NavigationStack.

- `SidebarMenuView` already has `onNavigate: (SidebarRoute) -> Void`. Simply change the header card button action from `onHeaderTap()` to `onNavigate(.babyProfile)`.
- Remove `onHeaderTap` property from `SidebarMenuView`.
- Remove `onHeaderTap` property from `SidebarDrawer` (which currently passes it through).
- Remove `onHeaderTap` closure from `AppShellView` call site (currently plays haptic only).
- `SidebarRoute` enum unchanged — `.babyProfile` still needed for navigation.

## Section 2: Data Model

### BabyProfile

Add field:
```swift
var avatarPath: String?
```

SwiftData lightweight migration: optional `String?` defaults to `nil`, no manual migration needed.

No separate `BabyAvatarStorage` class. All avatar file I/O is encapsulated in `BabyRepository`.

### BabyRepository

Add method:
```swift
func updateAvatar(_ image: UIImage?)
```

- `UIImage` provided: save JPEG to `ApplicationSupport/BabyAvatars/{uuid}.jpg`, delete old file, update `avatarPath`.
- `nil` provided: delete old file, set `avatarPath = nil`.

File storage logic is a private helper within `BabyRepository`. All baby data (including avatar) managed through a single repository.

### HomeHeaderConfig

Add field:
```swift
var avatarPath: String?
```

`from(_:)` factory populates from `baby.avatarPath`.

## Section 3: BabyProfileView Avatar Picker

### Interaction

Tap the 80x80 avatar circle → `confirmationDialog` with options:

1. **Album**: SwiftUI native `PhotosPicker`, bind `selectedPhotoItem: PhotosPickerItem?`. On `onChange`, call `item.loadTransferable(type: Data.self)` → `UIImage(data:)` → resize to max 512px → `babyRepository.updateAvatar(image)`. JPEG compression quality 0.8.
2. **Camera**: `.sheet` presenting existing `SystemImagePicker(sourceType: .camera)`. On image captured, resize to max 512px and call `babyRepository.updateAvatar(image)`. Camera option hidden on devices without camera (`UIImagePickerController.isSourceTypeAvailable(.camera)`).
3. **Remove avatar**: Call `babyRepository.updateAvatar(nil)`. Only shown when `avatarPath != nil`.

### Localization

All confirmation dialog strings via `L10n` with en + zh:

| Key | en | zh |
|-----|----|----|
| `profile.avatar.change_title` | "Change Avatar" | "更换头像" |
| `profile.avatar.album` | "Choose from Album" | "从相册选取" |
| `profile.avatar.camera` | "Take Photo" | "拍照" |
| `profile.avatar.remove` | "Remove Avatar" | "移除头像" |

### Visual states

- **No avatar**: Current monogram circle + hint text (unchanged).
- **Has avatar**: Circular-clipped avatar image, small edit icon overlay (camera/pencil) at bottom-right.
- Transition animated with `AppTheme.stateAnimation`.

### Data flow

`BabyProfileView` observes `babyRepository.activeBaby.avatarPath`. After photo selection, `babyRepository.updateAvatar(_:)` updates model → UI refreshes automatically.

## Section 4: Global Avatar Display Sync

Three locations display avatars, all need `avatarPath` support:

| Location | File | Size |
|----------|------|------|
| Sidebar header card | `SidebarMenuView.swift` | 56×56 |
| Profile edit page | `BabyProfileView.swift` | 80×80 |
| Top bar button | `MagazineTopBar.swift` | 32×32 |

### BabyAvatarView component

Extract a shared `BabyAvatarView`:

- Inputs: `avatarPath: String?`, `monogram: String`, `size: CGFloat`
- Image loading: synchronous `UIImage(contentsOfFile: path)` — avatars are small (max 512px), no need for async. Store loaded image in `@State` to avoid re-reading on every render.
- If `avatarPath` is non-nil but file fails to load (deleted externally, corrupt): fall back to monogram text. Do NOT clear `avatarPath` automatically — that's a data decision for the repository.
- If `avatarPath` is nil: show monogram text.
- Clip to circle in all cases.
- All three locations use this component.

### MagazineTopBar API change

`MagazineTopBar` currently accepts `babyName: String`. Add `avatarPath: String?` parameter so it can pass it to `BabyAvatarView`.

### Refresh mechanism

`HomeHeaderConfig` carries `avatarPath`. Store's `headerConfig` is `@Observable`, so sidebar and top bar update automatically when avatar changes.

## Components to modify

| File | Change |
|------|--------|
| `SidebarMenuView.swift` | Header card button action → `onNavigate(.babyProfile)`, remove `onHeaderTap`, use `BabyAvatarView` |
| `SidebarDrawer.swift` | Remove `onHeaderTap` property, remove `.profile` from `SidebarIndexItem` |
| `AppShellView.swift` | Remove `onHeaderTap` closure from `SidebarDrawer` call site |
| `BabyProfile.swift` | Add `avatarPath: String?` (lightweight migration) |
| `BabyRepository.swift` | Add `updateAvatar(_:)` with file I/O helpers |
| `BabyProfileView.swift` | Add photo picker (confirmationDialog + PhotosPicker + SystemImagePicker), use `BabyAvatarView` |
| `HomeHeaderConfig` (in `HomeModels.swift`) | Add `avatarPath: String?`, populate in `from(_:)` |
| `MagazineTopBar.swift` | Add `avatarPath: String?` parameter, use `BabyAvatarView` |
| `Localizable.xcstrings` | Add 4 confirmation dialog keys (en + zh) |
| New: `BabyAvatarView.swift` | Shared avatar display component |
