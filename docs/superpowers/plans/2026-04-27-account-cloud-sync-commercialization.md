# Account Cloud Sync Commercialization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Account and Cloud Sync work against the real `sprout-13` Supabase project while preserving local-first behavior.

**Architecture:** Add a committed SQL migration for Supabase schema, RLS, RPCs, and storage policies. Replace the stubbed `SupabaseService` with real Supabase Swift SDK calls behind the existing `SupabaseServicing` protocol. Add a gated real-backend smoke test so the default unit suite stays deterministic and secret-free.

**Tech Stack:** SwiftUI, SwiftData, Observation, Supabase Swift 2.31.0, Supabase Auth, Postgres, Storage, RLS, XCTest/Swift Testing.

**Spec:** `docs/superpowers/specs/2026-04-27-account-cloud-sync-commercial-design.md`

---

## File Structure

- Create: `supabase/migrations/202604270001_account_cloud_sync.sql`
  - Owns Postgres tables, triggers, RLS policies, RPC functions, and storage buckets/policies for this slice.
- Modify: `sprout/Domain/Sync/SupabaseService.swift`
  - Replaces `notImplemented` stubs with real SDK calls.
- Modify: `sprout/Domain/Sync/SupabaseModels.swift` if created, or keep helper structs private inside `SupabaseService.swift`
  - Encodable request payloads for RPC calls.
- Create: `sproutTests/RealSupabaseServiceSmokeTests.swift`
  - Skipped by default; runs only when explicit environment variables are set.
- Modify: `sproutTests/SupabaseConfigTests.swift`
  - Add coverage that SDK base URL rejects `/rest/v1/` style URLs if needed.
- Leave ignored: `Config/Supabase.local.xcconfig`
  - Contains local project URL and anon key; must not be committed.

## Task 1: Add Supabase SQL Migration

**Files:**
- Create: `supabase/migrations/202604270001_account_cloud_sync.sql`

- [ ] **Step 1: Create the migration file**

Use this exact file content:

```sql
begin;

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert or update of email on auth.users
for each row execute function public.handle_new_user();

create table if not exists public.baby_profiles (
  id uuid primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  birth_date timestamptz not null,
  gender text,
  avatar_storage_path text,
  is_active boolean not null default true,
  has_completed_onboarding boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  deleted_at timestamptz
);

create index if not exists idx_baby_profiles_user_id on public.baby_profiles(user_id);
create index if not exists idx_baby_profiles_updated_at on public.baby_profiles(updated_at);

create table if not exists public.record_items (
  id uuid primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  baby_id uuid not null references public.baby_profiles(id) on delete cascade,
  type text not null,
  timestamp timestamptz not null,
  value double precision,
  left_nursing_seconds integer not null default 0,
  right_nursing_seconds integer not null default 0,
  sub_type text,
  image_storage_path text,
  ai_summary text,
  tags jsonb,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  deleted_at timestamptz
);

create index if not exists idx_record_items_user_id on public.record_items(user_id);
create index if not exists idx_record_items_baby_id on public.record_items(baby_id);
create index if not exists idx_record_items_timestamp on public.record_items(timestamp desc);
create index if not exists idx_record_items_updated_at on public.record_items(updated_at);

create table if not exists public.memory_entries (
  id uuid primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  baby_id uuid not null references public.baby_profiles(id) on delete cascade,
  created_at timestamptz not null,
  age_in_days integer,
  image_storage_paths jsonb not null default '[]'::jsonb,
  note text,
  is_milestone boolean not null default false,
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  deleted_at timestamptz
);

create index if not exists idx_memory_entries_user_id on public.memory_entries(user_id);
create index if not exists idx_memory_entries_baby_id on public.memory_entries(baby_id);
create index if not exists idx_memory_entries_updated_at on public.memory_entries(updated_at);

alter table public.profiles enable row level security;
alter table public.baby_profiles enable row level security;
alter table public.record_items enable row level security;
alter table public.memory_entries enable row level security;

drop policy if exists "profiles select own" on public.profiles;
create policy "profiles select own"
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists "baby profiles own select" on public.baby_profiles;
create policy "baby profiles own select"
on public.baby_profiles for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "baby profiles own insert" on public.baby_profiles;
create policy "baby profiles own insert"
on public.baby_profiles for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "baby profiles own update" on public.baby_profiles;
create policy "baby profiles own update"
on public.baby_profiles for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "record items own select" on public.record_items;
create policy "record items own select"
on public.record_items for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "record items own insert" on public.record_items;
create policy "record items own insert"
on public.record_items for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "record items own update" on public.record_items;
create policy "record items own update"
on public.record_items for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "memory entries own select" on public.memory_entries;
create policy "memory entries own select"
on public.memory_entries for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "memory entries own insert" on public.memory_entries;
create policy "memory entries own insert"
on public.memory_entries for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "memory entries own update" on public.memory_entries;
create policy "memory entries own update"
on public.memory_entries for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create or replace function public.server_now()
returns timestamptz
language sql
stable
as $$
  select now();
$$;

create or replace function public.assert_payload_owner(payload jsonb)
returns uuid
language plpgsql
stable
as $$
declare
  payload_user_id uuid;
begin
  payload_user_id := (payload->>'user_id')::uuid;
  if payload_user_id is null or payload_user_id <> auth.uid() then
    raise exception 'payload user_id must match authenticated user' using errcode = '42501';
  end if;
  return payload_user_id;
end;
$$;

create or replace function public.upsert_baby_profile(payload jsonb, expected_version bigint default null)
returns public.baby_profiles
language plpgsql
security invoker
as $$
declare
  row_id uuid := (payload->>'id')::uuid;
  current_row public.baby_profiles;
  saved_row public.baby_profiles;
begin
  perform public.assert_payload_owner(payload);

  select * into current_row
  from public.baby_profiles
  where id = row_id
  for update;

  if found then
    if expected_version is null or current_row.version <> expected_version then
      raise exception 'version conflict for baby_profiles row %', row_id using errcode = '40001';
    end if;

    update public.baby_profiles
    set name = payload->>'name',
        birth_date = (payload->>'birth_date')::timestamptz,
        gender = nullif(payload->>'gender', ''),
        avatar_storage_path = nullif(payload->>'avatar_storage_path', ''),
        is_active = coalesce((payload->>'is_active')::boolean, true),
        has_completed_onboarding = coalesce((payload->>'has_completed_onboarding')::boolean, false),
        deleted_at = case when payload ? 'deleted_at' then nullif(payload->>'deleted_at', '')::timestamptz else deleted_at end,
        updated_at = now(),
        version = version + 1
    where id = row_id
    returning * into saved_row;
  else
    if expected_version is not null then
      raise exception 'version conflict for missing baby_profiles row %', row_id using errcode = '40001';
    end if;

    insert into public.baby_profiles (
      id, user_id, name, birth_date, gender, avatar_storage_path,
      is_active, has_completed_onboarding, created_at, updated_at, version, deleted_at
    )
    values (
      row_id,
      (payload->>'user_id')::uuid,
      payload->>'name',
      (payload->>'birth_date')::timestamptz,
      nullif(payload->>'gender', ''),
      nullif(payload->>'avatar_storage_path', ''),
      coalesce((payload->>'is_active')::boolean, true),
      coalesce((payload->>'has_completed_onboarding')::boolean, false),
      coalesce((payload->>'created_at')::timestamptz, now()),
      now(),
      1,
      nullif(payload->>'deleted_at', '')::timestamptz
    )
    returning * into saved_row;
  end if;

  return saved_row;
end;
$$;

create or replace function public.upsert_record_item(payload jsonb, expected_version bigint default null)
returns public.record_items
language plpgsql
security invoker
as $$
declare
  row_id uuid := (payload->>'id')::uuid;
  current_row public.record_items;
  saved_row public.record_items;
begin
  perform public.assert_payload_owner(payload);

  select * into current_row
  from public.record_items
  where id = row_id
  for update;

  if found then
    if expected_version is null or current_row.version <> expected_version then
      raise exception 'version conflict for record_items row %', row_id using errcode = '40001';
    end if;

    update public.record_items
    set baby_id = (payload->>'baby_id')::uuid,
        type = payload->>'type',
        timestamp = (payload->>'timestamp')::timestamptz,
        value = nullif(payload->>'value', '')::double precision,
        left_nursing_seconds = coalesce((payload->>'left_nursing_seconds')::integer, 0),
        right_nursing_seconds = coalesce((payload->>'right_nursing_seconds')::integer, 0),
        sub_type = nullif(payload->>'sub_type', ''),
        image_storage_path = nullif(payload->>'image_storage_path', ''),
        ai_summary = nullif(payload->>'ai_summary', ''),
        tags = payload->'tags',
        note = nullif(payload->>'note', ''),
        deleted_at = case when payload ? 'deleted_at' then nullif(payload->>'deleted_at', '')::timestamptz else deleted_at end,
        updated_at = now(),
        version = version + 1
    where id = row_id
    returning * into saved_row;
  else
    if expected_version is not null then
      raise exception 'version conflict for missing record_items row %', row_id using errcode = '40001';
    end if;

    insert into public.record_items (
      id, user_id, baby_id, type, timestamp, value, left_nursing_seconds,
      right_nursing_seconds, sub_type, image_storage_path, ai_summary, tags,
      note, created_at, updated_at, version, deleted_at
    )
    values (
      row_id,
      (payload->>'user_id')::uuid,
      (payload->>'baby_id')::uuid,
      payload->>'type',
      (payload->>'timestamp')::timestamptz,
      nullif(payload->>'value', '')::double precision,
      coalesce((payload->>'left_nursing_seconds')::integer, 0),
      coalesce((payload->>'right_nursing_seconds')::integer, 0),
      nullif(payload->>'sub_type', ''),
      nullif(payload->>'image_storage_path', ''),
      nullif(payload->>'ai_summary', ''),
      payload->'tags',
      nullif(payload->>'note', ''),
      now(),
      now(),
      1,
      nullif(payload->>'deleted_at', '')::timestamptz
    )
    returning * into saved_row;
  end if;

  return saved_row;
end;
$$;

create or replace function public.upsert_memory_entry(payload jsonb, expected_version bigint default null)
returns public.memory_entries
language plpgsql
security invoker
as $$
declare
  row_id uuid := (payload->>'id')::uuid;
  current_row public.memory_entries;
  saved_row public.memory_entries;
begin
  perform public.assert_payload_owner(payload);

  select * into current_row
  from public.memory_entries
  where id = row_id
  for update;

  if found then
    if expected_version is null or current_row.version <> expected_version then
      raise exception 'version conflict for memory_entries row %', row_id using errcode = '40001';
    end if;

    update public.memory_entries
    set baby_id = (payload->>'baby_id')::uuid,
        created_at = (payload->>'created_at')::timestamptz,
        age_in_days = nullif(payload->>'age_in_days', '')::integer,
        image_storage_paths = coalesce(payload->'image_storage_paths', '[]'::jsonb),
        note = nullif(payload->>'note', ''),
        is_milestone = coalesce((payload->>'is_milestone')::boolean, false),
        deleted_at = case when payload ? 'deleted_at' then nullif(payload->>'deleted_at', '')::timestamptz else deleted_at end,
        updated_at = now(),
        version = version + 1
    where id = row_id
    returning * into saved_row;
  else
    if expected_version is not null then
      raise exception 'version conflict for missing memory_entries row %', row_id using errcode = '40001';
    end if;

    insert into public.memory_entries (
      id, user_id, baby_id, created_at, age_in_days, image_storage_paths,
      note, is_milestone, updated_at, version, deleted_at
    )
    values (
      row_id,
      (payload->>'user_id')::uuid,
      (payload->>'baby_id')::uuid,
      (payload->>'created_at')::timestamptz,
      nullif(payload->>'age_in_days', '')::integer,
      coalesce(payload->'image_storage_paths', '[]'::jsonb),
      nullif(payload->>'note', ''),
      coalesce((payload->>'is_milestone')::boolean, false),
      now(),
      1,
      nullif(payload->>'deleted_at', '')::timestamptz
    )
    returning * into saved_row;
  end if;

  return saved_row;
end;
$$;

create or replace function public.soft_delete_row(table_name text, row_id uuid, expected_version bigint default null)
returns void
language plpgsql
security invoker
as $$
declare
  current_version bigint;
  current_user_id uuid;
begin
  if table_name not in ('baby_profiles', 'record_items', 'memory_entries') then
    raise exception 'unsupported table %', table_name using errcode = '42804';
  end if;

  execute format('select version, user_id from public.%I where id = $1 for update', table_name)
  into current_version, current_user_id
  using row_id;

  if current_user_id is null then
    return;
  end if;

  if current_user_id <> auth.uid() then
    raise exception 'row does not belong to authenticated user' using errcode = '42501';
  end if;

  if expected_version is not null and current_version <> expected_version then
    raise exception 'version conflict for % row %', table_name, row_id using errcode = '40001';
  end if;

  execute format('update public.%I set deleted_at = now(), updated_at = now(), version = version + 1 where id = $1', table_name)
  using row_id;
end;
$$;

insert into storage.buckets (id, name, public)
values
  ('food-photos', 'food-photos', false),
  ('treasure-photos', 'treasure-photos', false),
  ('baby-avatars', 'baby-avatars', false)
on conflict (id) do update set public = excluded.public;

drop policy if exists "users can select own storage objects" on storage.objects;
create policy "users can select own storage objects"
on storage.objects for select
to authenticated
using (
  bucket_id in ('food-photos', 'treasure-photos', 'baby-avatars')
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can insert own storage objects" on storage.objects;
create policy "users can insert own storage objects"
on storage.objects for insert
to authenticated
with check (
  bucket_id in ('food-photos', 'treasure-photos', 'baby-avatars')
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can update own storage objects" on storage.objects;
create policy "users can update own storage objects"
on storage.objects for update
to authenticated
using (
  bucket_id in ('food-photos', 'treasure-photos', 'baby-avatars')
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id in ('food-photos', 'treasure-photos', 'baby-avatars')
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can delete own storage objects" on storage.objects;
create policy "users can delete own storage objects"
on storage.objects for delete
to authenticated
using (
  bucket_id in ('food-photos', 'treasure-photos', 'baby-avatars')
  and (storage.foldername(name))[1] = auth.uid()::text
);

commit;
```

- [ ] **Step 2: Run the migration in Supabase SQL Editor**

Run the full file contents in the `sprout-13` SQL Editor. Expected result: SQL Editor reports success with no failed statements.

- [ ] **Step 3: Verify backend objects exist**

Run this in SQL Editor:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('profiles', 'baby_profiles', 'record_items', 'memory_entries')
order by table_name;

select id, public
from storage.buckets
where id in ('food-photos', 'treasure-photos', 'baby-avatars')
order by id;
```

Expected table rows: `baby_profiles`, `memory_entries`, `profiles`, `record_items`.
Expected bucket rows: `baby-avatars false`, `food-photos false`, `treasure-photos false`.

- [ ] **Step 4: Commit migration**

```bash
git add supabase/migrations/202604270001_account_cloud_sync.sql
git commit -m "feat: add supabase account cloud sync schema"
```

## Task 2: Implement Real Auth in `SupabaseService`

**Files:**
- Modify: `sprout/Domain/Sync/SupabaseService.swift`
- Test: existing `sproutTests/AuthManagerTests.swift`

- [ ] **Step 1: Replace auth stubs with SDK calls**

In `SupabaseService.swift`, add this helper:

```swift
#if canImport(Supabase)
private func makeSession(_ session: Session) -> SupabaseSession {
    SupabaseSession(
        user: SupabaseAuthUser(
            id: session.user.id,
            email: session.user.email
        )
    )
}
#endif
```

Then implement:

```swift
func restoreSession() async throws -> SupabaseSession? {
    #if canImport(Supabase)
    do {
        return makeSession(try await client.auth.session)
    } catch {
        return nil
    }
    #else
    throw unavailable("restoreSession")
    #endif
}

func signIn(email: String, password: String) async throws -> SupabaseSession {
    #if canImport(Supabase)
    let session = try await client.auth.signIn(email: email, password: password)
    return makeSession(session)
    #else
    throw unavailable("signIn")
    #endif
}

func signUp(email: String, password: String) async throws -> SupabaseSession {
    #if canImport(Supabase)
    let response = try await client.auth.signUp(email: email, password: password)
    if let session = response.session {
        return makeSession(session)
    }
    throw SupabaseServiceError.notImplemented("signUp requires email confirmation before a session is available")
    #else
    throw unavailable("signUp")
    #endif
}

func signOut() async throws {
    #if canImport(Supabase)
    try await client.auth.signOut()
    #else
    throw unavailable("signOut")
    #endif
}
```

- [ ] **Step 2: Run auth manager tests**

```bash
xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:sproutTests/AuthManagerTests
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 3: Commit auth implementation**

```bash
git add sprout/Domain/Sync/SupabaseService.swift
git commit -m "feat: connect supabase auth service"
```

## Task 3: Implement Real Postgres RPC and Fetch Methods

**Files:**
- Modify: `sprout/Domain/Sync/SupabaseService.swift`
- Test: existing `sproutTests/SyncEngineTests.swift`

- [ ] **Step 1: Add RPC parameter wrappers**

Add private wrappers in `SupabaseService.swift`:

```swift
private struct RPCPayload<Row: Encodable & Sendable>: Encodable, Sendable {
    let payload: Row
    let expectedVersion: Int64?

    enum CodingKeys: String, CodingKey {
        case payload
        case expectedVersion = "expected_version"
    }
}

private struct SoftDeleteParams: Encodable, Sendable {
    let tableName: String
    let rowID: UUID
    let expectedVersion: Int64?

    enum CodingKeys: String, CodingKey {
        case tableName = "table_name"
        case rowID = "row_id"
        case expectedVersion = "expected_version"
    }
}

private struct ServerNowResponse: Decodable, Sendable {
    let serverNow: Date
}
```

- [ ] **Step 2: Implement server time**

Use Supabase RPC:

```swift
func fetchServerNow() async throws -> Date {
    #if canImport(Supabase)
    let response: PostgrestResponse<Date> = try await client
        .rpc("server_now")
        .execute()
    return response.value
    #else
    throw unavailable("fetchServerNow")
    #endif
}
```

If the compiler rejects direct `Date` decoding from RPC, replace with a SQL function that returns `jsonb` and decode a `ServerNowResponse`.

- [ ] **Step 3: Implement versioned upserts**

Use this pattern for each row:

```swift
func upsertBabyProfile(_ profile: BabyProfileDTO, expectedVersion: Int64?) async throws -> BabyProfileDTO {
    #if canImport(Supabase)
    let response: PostgrestResponse<BabyProfileDTO> = try await client
        .rpc("upsert_baby_profile", params: RPCPayload(payload: profile, expectedVersion: expectedVersion))
        .single()
        .execute()
    return response.value
    #else
    throw unavailable("upsertBabyProfile")
    #endif
}
```

Repeat with function names `upsert_record_item` and `upsert_memory_entry`.

- [ ] **Step 4: Implement incremental fetches**

Use table queries:

```swift
func fetchBabyProfiles(updatedAfter: Date?, upTo upperBound: Date) async throws -> [BabyProfileDTO] {
    #if canImport(Supabase)
    var query = client
        .from("baby_profiles")
        .select()
        .lte("updated_at", value: upperBound)
        .order("updated_at", ascending: true)
    if let updatedAfter {
        query = query.gt("updated_at", value: updatedAfter)
    }
    let response: PostgrestResponse<[BabyProfileDTO]> = try await query.execute()
    return response.value
    #else
    throw unavailable("fetchBabyProfiles")
    #endif
}
```

Repeat for `record_items` and `memory_entries`. Keep table names exactly matching `SupabaseTable` raw values.

- [ ] **Step 5: Implement soft delete**

```swift
func softDelete(table: SupabaseTable, id: UUID, expectedVersion: Int64?) async throws {
    #if canImport(Supabase)
    _ = try await client
        .rpc(
            "soft_delete_row",
            params: SoftDeleteParams(
                tableName: table.rawValue,
                rowID: id,
                expectedVersion: expectedVersion
            )
        )
        .execute()
    #else
    throw unavailable("softDelete")
    #endif
}
```

- [ ] **Step 6: Build to catch SDK API mismatches**

```bash
xcodebuild build -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Run sync tests**

```bash
xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:sproutTests/SyncEngineTests
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 8: Commit Postgres implementation**

```bash
git add sprout/Domain/Sync/SupabaseService.swift
git commit -m "feat: connect supabase postgres sync service"
```

## Task 4: Implement Real Storage Methods

**Files:**
- Modify: `sprout/Domain/Sync/SupabaseService.swift`
- Test: existing `sproutTests/SyncEngineTests.swift`

- [ ] **Step 1: Implement upload**

```swift
func uploadAsset(data: Data, bucket: StorageBucket, path: String, contentType: String) async throws {
    #if canImport(Supabase)
    let file = client.storage.from(bucket.rawValue)
    do {
        _ = try await file.upload(
            path,
            data: data,
            options: FileOptions(contentType: contentType, upsert: false)
        )
    } catch {
        _ = try await file.update(
            path,
            data: data,
            options: FileOptions(contentType: contentType, upsert: true)
        )
    }
    #else
    throw unavailable("uploadAsset")
    #endif
}
```

- [ ] **Step 2: Implement download and delete**

```swift
func downloadAsset(bucket: StorageBucket, path: String) async throws -> Data {
    #if canImport(Supabase)
    try await client.storage.from(bucket.rawValue).download(path: path)
    #else
    throw unavailable("downloadAsset")
    #endif
}

func deleteAsset(bucket: StorageBucket, path: String) async throws {
    #if canImport(Supabase)
    _ = try await client.storage.from(bucket.rawValue).remove(paths: [path])
    #else
    throw unavailable("deleteAsset")
    #endif
}
```

- [ ] **Step 3: Build and run asset-related sync tests**

```bash
xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:sproutTests/SyncEngineTests/pushPipelineUploadsBeforeUpserts \
  -only-testing:sproutTests/SyncEngineTests/pullDownloadsFoodPhoto \
  -only-testing:sproutTests/SyncEngineTests/pullDownloadsTreasurePhotosInOrder
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 4: Commit storage implementation**

```bash
git add sprout/Domain/Sync/SupabaseService.swift
git commit -m "feat: connect supabase storage service"
```

## Task 5: Add Real Supabase Smoke Test

**Files:**
- Create: `sproutTests/RealSupabaseServiceSmokeTests.swift`

- [ ] **Step 1: Add gated smoke test**

Create:

```swift
import Foundation
import Testing
@testable import sprout

@MainActor
struct RealSupabaseServiceSmokeTests {
    @Test("real Supabase auth smoke is gated by environment")
    func realAuthSmoke() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["SPROUT_REAL_SUPABASE_SMOKE"] == "1" else {
            return
        }

        let url = try #require(environment["SPROUT_SUPABASE_URL"])
        let anonKey = try #require(environment["SPROUT_SUPABASE_ANON_KEY"])
        let email = try #require(environment["SPROUT_SUPABASE_TEST_EMAIL"])
        let password = try #require(environment["SPROUT_SUPABASE_TEST_PASSWORD"])

        let service = try SupabaseService(
            config: SupabaseConfig(
                infoDictionary: [
                    SupabaseConfig.urlKey: url,
                    SupabaseConfig.anonKeyKey: anonKey
                ]
            )
        )

        let session = try await service.signIn(email: email, password: password)
        #expect(session.user.email == email)
        try await service.signOut()
    }
}
```

- [ ] **Step 2: Add direct initializer if needed**

If `SupabaseService(config:)` is not accessible to tests, keep it internal, not private:

```swift
init(config: SupabaseConfig) {
    self.config = config
    client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
}
```

- [ ] **Step 3: Run default tests and verify smoke is skipped**

```bash
xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:sproutTests/RealSupabaseServiceSmokeTests
```

Expected: `** TEST SUCCEEDED **` without requiring real credentials.

- [ ] **Step 4: Run real smoke manually**

Set `SPROUT_SUPABASE_TEST_EMAIL` and `SPROUT_SUPABASE_TEST_PASSWORD` in your shell before running this command. Do not write those values to any repo file.

```bash
SPROUT_REAL_SUPABASE_SMOKE=1 \
SPROUT_SUPABASE_URL="$(sed -n 's/^SUPABASE_URL = //p' Config/Supabase.local.xcconfig)" \
SPROUT_SUPABASE_ANON_KEY="$(sed -n 's/^SUPABASE_ANON_KEY = //p' Config/Supabase.local.xcconfig)" \
xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:sproutTests/RealSupabaseServiceSmokeTests
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit smoke test**

```bash
git add sproutTests/RealSupabaseServiceSmokeTests.swift
git commit -m "test: add gated real supabase smoke"
```

## Task 6: Full Verification

**Files:**
- No new files.

- [ ] **Step 1: Run full unit suite**

```bash
xcodebuild test -scheme sprout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 2: Verify local Supabase config stays ignored**

```bash
git status --short --ignored=matching Config/Supabase.local.xcconfig
```

Expected output includes:

```text
!! Config/Supabase.local.xcconfig
```

- [ ] **Step 3: Confirm working tree contains no accidental secrets**

```bash
git status --short --ignored=matching Config/Supabase.local.xcconfig
```

Expected: tracked changes are only intentional code, SQL, or test files; `Config/Supabase.local.xcconfig` remains ignored.

## Risk Notes

- Supabase Swift API surface may require small syntax adjustments during build, especially `PostgrestResponse<T>` inference and `FileOptions` initializer labels.
- Supabase email confirmation settings can make `signUp` return a user without a session. The smoke test uses `signIn` against a manually created test account to avoid depending on email delivery.
- Storage policy correctness must be validated with real upload/download, not only SQL existence checks.
- Cloud Sync remains non-Pro-gated in this slice by design. Pro enforcement belongs to the later entitlement slice.
