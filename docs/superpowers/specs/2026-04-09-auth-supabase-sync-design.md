# Auth + Supabase Backend + Cloud Sync (Phase 2 of Family Group Pro)

**Date**: 2026-04-09
**Status**: Draft
**Phase**: 2 of 4 (StoreKit → Auth/Backend → Multi-Baby/Family → AI)
**Depends on**: Phase 1 (StoreKit + Paywall) — COMPLETE

## Background

Phase 1 established StoreKit 2 subscription infrastructure with `SubscriptionManager` and `PaywallView`. The app has `Entitlement.cloudSync` defined but not differentiated from `isPro`. All data is local-only (SwiftData SQLite on device).

Phase 2 adds: user authentication (email + password via Supabase Auth), cloud data sync (Supabase PostgreSQL), and image backup (Supabase Storage). This enables multi-device data access — the foundation for family group sharing in Phase 3.

## Requirements

| Requirement | Decision |
|-------------|----------|
| Authentication | Email + password (Supabase Auth) |
| Backend | Supabase (PostgreSQL + Auth + Storage) |
| Sync strategy | Incremental sync with debounce (2s) |
| Conflict resolution | Record-level Last Write Wins (LWW) |
| Image sync | Full download (all images synced to device) |
| Offline behavior | Offline-first — local works normally, syncs when online |
| Data scope | RecordItem + MemoryEntry + BabyProfile (WeeklyLetter recomputed locally) |
| Login entry | Sidebar "Account" menu item (no Pro lock) |
| Sync trigger | CloudSyncView (Pro-gated, replaces Phase 1 placeholder) |

## Supabase Database Schema

### Tables

#### `profiles`
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### `baby_profiles`
```sql
CREATE TABLE baby_profiles (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '宝宝',
  birth_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  gender TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### `record_items`
```sql
CREATE TABLE record_items (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  baby_id UUID NOT NULL REFERENCES baby_profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,           -- milk/diaper/sleep/food/height/weight
  timestamp TIMESTAMPTZ NOT NULL,
  value DOUBLE PRECISION,
  left_nursing_seconds INTEGER DEFAULT 0,
  right_nursing_seconds INTEGER DEFAULT 0,
  sub_type TEXT,                -- pee/poop/both (diaper only)
  image_url TEXT,               -- Supabase Storage URL
  ai_summary TEXT,
  tags JSONB,                   -- [String] array
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ        -- soft delete
);

CREATE INDEX idx_record_items_user ON record_items(user_id);
CREATE INDEX idx_record_items_baby ON record_items(baby_id);
CREATE INDEX idx_record_items_timestamp ON record_items(timestamp DESC);
CREATE INDEX idx_record_items_updated ON record_items(updated_at);
```

#### `memory_entries`
```sql
CREATE TABLE memory_entries (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  baby_id UUID NOT NULL REFERENCES baby_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL,
  age_in_days INTEGER,
  image_url TEXT,               -- Supabase Storage URL
  note TEXT,
  is_milestone BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ        -- soft delete
);

CREATE INDEX idx_memory_entries_user ON memory_entries(user_id);
CREATE INDEX idx_memory_entries_baby ON memory_entries(baby_id);
CREATE INDEX idx_memory_entries_updated ON memory_entries(updated_at);
```

### Row Level Security (RLS)

All tables enable RLS. Policy: users can only access rows where `user_id = auth.uid()`.

```sql
ALTER TABLE baby_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE record_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_entries ENABLE Row Level Security;

CREATE POLICY "Users see own baby_profiles"
  ON baby_profiles FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Users see own record_items"
  ON record_items FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Users see own memory_entries"
  ON memory_entries FOR ALL
  USING (user_id = auth.uid());
```

### Storage Buckets

| Bucket | Path | Purpose |
|--------|------|---------|
| `food-photos` | `{userId}/{recordId}.jpg` | Food record images |
| `treasure-photos` | `{userId}/{memoryId}.jpg` | Memory entry images |
| `baby-avatars` | `{userId}/{babyId}.jpg` | Baby profile avatars |

RLS on storage: users can only access files under their own `{userId}/` prefix.

## SwiftData Model Extensions

Each syncable model adds 3 fields. SwiftData handles lightweight migration automatically (new optional fields get default values).

### SyncStatus Enum

```swift
enum SyncStatus: String, Codable {
    case synced         // Up to date with server
    case pendingUpload  // Local change not yet pushed
    case pendingDelete  // Locally deleted, awaiting server confirmation
}
```

### RecordItem Extensions

```swift
// New fields on RecordItem
var lastModifiedAt: Date = .now
var serverId: String? = nil          // Supabase record ID (matches local UUID)
var syncStatus: SyncStatus = .pendingUpload
```

### MemoryEntry Extensions

```swift
var lastModifiedAt: Date = .now
var serverId: String? = nil
var syncStatus: SyncStatus = .pendingUpload
```

### BabyProfile Extensions

```swift
var lastModifiedAt: Date = .now
var serverId: String? = nil
var syncStatus: SyncStatus = .pendingUpload
```

### Default Values for Existing Records

On migration, existing records get:
- `lastModifiedAt = .now` (treated as recently modified)
- `serverId = nil` (not yet synced)
- `syncStatus = .pendingUpload` (needs upload)

This ensures all existing data is synced on first login.

## Repository Layer Changes

All write operations (create/update/delete) set sync metadata:

```swift
// In every create/update method:
record.lastModifiedAt = .now
record.syncStatus = .pendingUpload

// In every delete method:
record.syncStatus = .pendingDelete
record.lastModifiedAt = .now
// (Don't physically delete — let sync engine confirm server deletion)
```

**Undo pattern compatibility:** The existing 4-second undo window works naturally:
1. Delete sets `syncStatus = .pendingDelete`
2. Undo (restore) reverts to `syncStatus = .pendingUpload`
3. Sync engine only processes records where `syncStatus` has been stable for >4 seconds (debounce covers this)

The sync engine reads pending records via:
```swift
let pending = try modelContext.fetch(FetchDescriptor<RecordItem>(
    predicate: #Predicate { $0.syncStatus != .synced }
))
```

## Sync Engine Architecture

### Component Overview

```
SyncEngine (@MainActor @Observable)
├── AuthManager           — Supabase Auth session management
├── SyncQueue             — Debounced sync scheduler
├── SupabaseClient        — API wrapper (Auth + Database + Storage)
└── ConflictResolver      — LWW conflict resolution
```

### SyncEngine

```swift
@MainActor @Observable
final class SyncEngine {
    var syncState: SyncState = .idle
    var lastSyncAt: Date?
    var pendingCount: Int = 0

    private let client: SupabaseClient
    private let modelContext: ModelContext
    private var syncDebounceTask: Task<Void, Never>?

    func scheduleSync()           // Debounced 2s, then push + pull
    func performFullSync() async  // Immediate push + pull
    func pushPendingChanges() async
    func pullRemoteChanges() async
    func uploadImages() async
    func downloadImages() async
}

enum SyncState: Equatable {
    case idle
    case syncing(progress: String)
    case error(String)
    case offline
}
```

### Sync Flow

**Push (local → server):**
1. Fetch all records with `syncStatus == .pendingUpload`
2. Upsert to Supabase tables (insert if no serverId, update if exists)
3. Upload associated images to Storage
4. Set `syncStatus = .synced`, fill `serverId`
5. Fetch records with `syncStatus == .pendingDelete`
6. Soft-delete on server (set `deleted_at`)
7. Physically delete from local SwiftData
8. Set `syncStatus = .synced`

**Pull (server → local):**
1. Fetch records where `updated_at > lastSyncAt` for current user
2. For each remote record:
   - If no local record with matching UUID → insert locally
   - If local exists and `remote.updated_at > local.lastModifiedAt` → update local (LWW)
   - If local exists and `remote.updated_at <= local.lastModifiedAt` → skip (local wins)
   - If remote has `deleted_at` set → delete local record
3. Download associated images from Storage
4. Update `lastSyncAt` timestamp

**Debounce:**
```swift
func scheduleSync() {
    syncDebounceTask?.cancel()
    syncDebounceTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        guard !Task.isCancelled else { return }
        await performFullSync()
    }
}
```

### Conflict Resolution (LWW)

```swift
struct ConflictResolver {
    /// Returns true if remote record should overwrite local.
    static func shouldRemoteWin(local: Date, remote: Date) -> Bool {
        remote > local
    }
}
```

When pulling, if `remote.updated_at > local.lastModifiedAt`, the remote version overwrites local fields. No field-level merging — entire record is replaced.

## Auth Manager

```swift
@MainActor @Observable
final class AuthManager {
    var currentUser: SupabaseUser?
    var isAuthenticated: Bool { currentUser != nil }
    var authState: AuthState = .unauthenticated

    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() async throws
    func restoreSession() async  // Called on app launch
}

enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(userId: String)
    case error(String)
}
```

**Session persistence:** Supabase Swift SDK handles session storage in Keychain automatically. `restoreSession()` reads from Keychain.

**Supabase dependency:** Add `supabase-swift` SPM package.

## SupabaseClient

```swift
actor SupabaseClient {
    private let client: SupabaseClient  // From supabase-swift SDK

    init(supabaseURL: URL, supabaseKey: String)

    // Auth
    func signIn(email: String, password: String) async throws -> Session
    func signUp(email: String, password: String) async throws -> Session
    func signOut() async throws
    func getSession() async -> Session?

    // Database
    func upsertRecord(_ record: RecordDTO) async throws
    func upsertMemory(_ memory: MemoryDTO) async throws
    func upsertBabyProfile(_ profile: BabyProfileDTO) async throws
    func softDelete(table: String, id: UUID) async throws

    func fetchRecordsUpdated(since: Date, userId: UUID) async throws -> [RecordDTO]
    func fetchMemoriesUpdated(since: Date, userId: UUID) async throws -> [MemoryDTO]
    func fetchBabyProfiles(userId: UUID) async throws -> [BabyProfileDTO]

    // Storage
    func uploadImage(bucket: String, path: String, data: Data) async throws -> URL
    func downloadImage(bucket: String, path: String) async throws -> Data
}
```

**DTO structs** map between SwiftData models and Supabase JSON:

```swift
struct RecordDTO: Codable {
    let id: UUID
    let userId: UUID
    let babyId: UUID
    let type: String
    let timestamp: Date
    let value: Double?
    let leftNursingSeconds: Int
    let rightNursingSeconds: Int
    let subType: String?
    let imageUrl: String?
    let aiSummary: String?
    let tags: [String]?
    let note: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
}
```

Similar DTOs for `MemoryDTO` and `BabyProfileDTO`.

## Sidebar Integration

### New Route

```swift
// SidebarRoute addition
case account  // NOT Pro-gated — visible to all users
```

### Updated Sidebar Menu Items

| Route | Title | Icon | Pro |
|-------|-------|------|-----|
| `.language` | Language & Region | `globe` | No |
| `.account` | Account | `person.circle` | No |
| `.cloudSync` | Cloud Sync | `cloud` | Yes |
| `.familyGroup` | Family Group | `person.2` | Yes |

### SidebarDrawer Updates

- Add `.account` to `SidebarRoute` and `navigationDestination`
- Add `AccountView` as destination

## UI Views

### AccountView

**Unauthenticated state:**
- Email text field
- Password secure field
- "Sign In" primary button
- "Sign Up" secondary button
- "Forgot Password?" link

**Authenticated state:**
- Email display (non-editable)
- "Sync Status" row showing last sync time
- "Sync Now" button
- "Sign Out" destructive button (with confirmation)

### CloudSyncView (replaces CloudSyncPlaceholderView)

**Not subscribed to Pro:**
- Shows Pro upgrade prompt (Paywall trigger)

**Subscribed + not authenticated:**
- Prompt to log in via AccountView
- Link to account page

**Subscribed + authenticated:**
- Sync state indicator (idle/syncing/error)
- Last sync timestamp
- Synced record count (statistics)
- "Sync Now" manual trigger button
- Image sync progress (if syncing)

### Integration with Phase 1

- `CloudSyncPlaceholderView` is deleted, replaced by `CloudSyncView`
- `SubscriptionManager.isEntitled(.cloudSync)` gates the sync UI (currently returns `isPro`)
- `SyncEngine` is created in `ContentView` alongside `SubscriptionManager`, injected via `@Environment`

## Supabase Configuration

### Environment

```swift
enum SupabaseConfig {
    static let url = URL(string: Environment.get("SUPABASE_URL") ?? "")!
    static let anonKey = Environment.get("SUPABASE_ANON_KEY") ?? ""
}
```

The URL and anon key are stored in `Info.plist` or `xcconfig` files (not committed to git).

### SPM Dependency

Add `supabase-swift` package: `https://github.com/supabase/supabase-swift`

## File Structure

### New Files

```
sprout/Domain/Auth/
├── AuthManager.swift           — Supabase Auth wrapper
├── AuthState.swift             — Auth state enum

sprout/Domain/Sync/
├── SyncEngine.swift            — Main sync orchestrator
├── SyncState.swift             — Sync state enum (idle/syncing/error)
├── SyncModels.swift            — DTOs (RecordDTO, MemoryDTO, BabyProfileDTO)
├── SyncStatus.swift            — Record-level sync status enum
├── SupabaseClient.swift        — Supabase API wrapper
├── ConflictResolver.swift      — LWW conflict resolution

sprout/Features/Shell/
├── AccountView.swift           — Login/register/account management
├── CloudSyncView.swift         — Replaces CloudSyncPlaceholderView

sproutTests/
├── SyncEngineTests.swift
├── AuthManagerTests.swift
├── ConflictResolverTests.swift
├── MockSupabaseClient.swift
```

### Modified Files

| File | Change |
|------|--------|
| `RecordItem.swift` | Add `lastModifiedAt`, `serverId`, `syncStatus` fields |
| `MemoryEntry.swift` | Add same 3 sync fields |
| `BabyProfile.swift` | Add same 3 sync fields |
| `RecordRepository.swift` | Write operations set `syncStatus = .pendingUpload` |
| `GrowthRecordRepository.swift` | Same (operates on RecordItem) |
| `TreasureRepository.swift` | Same for MemoryEntry |
| `BabyRepository.swift` | Same for BabyProfile |
| `SidebarDrawer.swift` | Add `.account` route + `AccountView` destination |
| `SidebarMenuView.swift` | Add account menu item |
| `ContentView.swift` | Create `AuthManager` + `SyncEngine`, inject via `.environment()` |
| `SproutApp.swift` | Add `supabase-swift` SPM dependency |

### Deleted Files

| File | Reason |
|------|--------|
| `CloudSyncPlaceholderView.swift` | Replaced by `CloudSyncView` |

## Testing

### Unit Tests

**ConflictResolverTests:**
- `test_remoteNewer_shouldRemoteWin`
- `test_localNewer_shouldLocalWin`
- `test_sameTimestamp_shouldLocalWin` (tie goes to local)

**SyncEngineTests (with MockSupabaseClient):**
- `test_pushPendingUploads_setsSynced`
- `test_pushPendingDeletes_softDeletesServer`
- `test_pullRemoteChanges_insertsNewRecords`
- `test_pullRemoteChanges_updatesExistingRecords`
- `test_pullRemoteChanges_deletesSoftDeleted`
- `test_scheduleSync_debounces2Seconds`
- `test_offlineState_setsSyncState`

**AuthManagerTests:**
- `test_signIn_success_setsAuthenticated`
- `test_signIn_failure_setsError`
- `test_signUp_success_setsAuthenticated`
- `test_signOut_clearsSession`
- `test_restoreSession_withSavedSession_succeeds`

### Integration Testing

- Test against real Supabase instance (test project)
- Full sync cycle: create locally → sync → verify server → pull on fresh device
- Image upload/download round-trip
- Offline → online sync recovery

## Scope Boundaries

### In Scope (Phase 2)
- Supabase project setup (tables, RLS, storage)
- Email + password authentication
- AuthManager with session management
- Incremental sync engine (push + pull + debounce)
- RecordItem + MemoryEntry + BabyProfile sync
- Image sync (full download via Supabase Storage)
- LWW conflict resolution
- Offline-first (local works without network)
- AccountView (login/register/account management)
- CloudSyncView (sync status + manual trigger)
- Sidebar account menu item
- Unit tests + integration tests

### Out of Scope
- Multi-baby management (Phase 3)
- Family group sharing / invitations (Phase 3)
- Sign in with Apple
- Real-time subscriptions (Supabase Realtime)
- Data export
- Server-side receipt validation
- WeeklyLetter sync (recomputed locally from synced MemoryEntry data)
- Analytics / usage tracking

## Open Questions

1. **Supabase project URL and anon key** — Need to be configured in `xcconfig` or `Info.plist`. User needs to create a Supabase project.
2. **WeeklyLetter recomputation trigger** — After pulling new `MemoryEntry` records, when should `WeeklyLetterComposer` run? Suggestion: after every successful pull, in background.
3. **Undo window interaction** — If user deletes a record and it's synced as `pendingDelete` within the 2s debounce, but then undoes within 4s, the sync should pick up the restored state. The debounce timer (2s) is shorter than the undo window (4s), so the sync engine may push a `pendingDelete` before the undo happens. Solution: increase sync debounce to 5s (longer than undo window), or use a separate "commit" signal from the undo system.
