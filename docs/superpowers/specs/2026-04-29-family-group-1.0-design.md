# Family Group 1.0 Design

**Date:** 2026-04-29
**Release:** Sprout 1.3
**Status:** Approved for implementation planning

## Goal

Make `Family Group` a real 1.3 capability for shared baby collaboration, not a placeholder route.

This slice adds one true collaboration path:

- a `Pro` owner creates one family group
- the owner shares one or more babies into that group
- a logged-in member joins with an invite code
- the member sees shared babies in a separate group
- the member can add records for shared babies and edit only records they created

This slice does not add deep links, multi-family membership, chat, complex roles, audit history UI, or server-enforced subscription checks.

## Current Context

`FamilyGroupPlaceholderView` is still a coming-soon shell in the sidebar. `Multi-Baby` now supports create, switch, and conservative delete flows for locally owned babies. `Account` and `Cloud Sync` already have real auth, binding, sync engine, and Supabase-backed infrastructure in progress or completed for 1.3.

That means the missing work is no longer shell navigation. The gap is a real domain model for family membership, shared-baby visibility, collaboration permissions, and syncable family metadata.

## Product Rules

1. `Family Group` is unlocked by the owner being `Pro`.
2. A free member may join and collaborate once invited by a `Pro` owner.
3. First release uses invite codes only. No deep links or universal links.
4. A user may belong to at most one family group in this slice.
5. Joining a family group does not automatically expose every baby. A baby is visible only when the owner explicitly shares it.
6. Shared babies appear in a separate `Shared Babies` section, not mixed with the member's owned babies.
7. A member may create records for a shared baby.
8. A member may edit or delete only records they created.
9. When a member is removed, or a baby is unshared, that member immediately loses access to the baby.
10. Historical records created during a valid sharing period are preserved on the baby. They are not cascade-deleted when access is revoked.
11. Local-first behavior stays intact. Temporary sync failure must not discard valid local edits already made while access was active.
12. A family group has one active reusable invite code at a time. The owner may refresh it, expire it, or revoke it.

## User Experience

### Owner

- Opens `Family Group` from the sidebar.
- Creates a family group if none exists.
- Sees current members and current shared babies.
- Generates or refreshes an invite code.
- Shares or unshares specific babies.
- Removes a member when needed.

### Member

- Signs in from `Account`.
- Opens `Family Group`.
- Enters an invite code to join.
- Sees a separate `Shared Babies` section in baby-switching UI.
- Can switch into a shared baby and create records normally.
- Cannot edit or delete records created by the owner or another member.

## Architecture

### `FamilyGroupStore`

Add a dedicated `FamilyGroupStore` as the product-facing orchestration layer for:

- create group
- load current group
- generate or revoke invite code
- join by invite code
- remove member
- share baby
- unshare baby

This store owns family-group rules and status. It must not absorb baby CRUD or record CRUD responsibilities already handled elsewhere.

### `BabyRepository`

Extend baby visibility from a single owned list into a grouped visibility result:

- `owned`
- `shared`

The repository remains the source of truth for which babies the current user can access. Shell views consume this grouped result and render a separate `Shared Babies` section.

### Record, Growth, and Treasure Domains

Keep existing stores and repositories. Do not create family-specific parallel stacks.

Instead, enforce collaboration through shared metadata and shared permission checks:

- add `createdByUserID`
- add `updatedByUserID`
- gate edits and deletes on current user ownership for shared-baby content

If the active baby is shared, create flows remain available. Edit and delete flows must resolve through domain permission checks, not ad hoc view logic.

### Account and Sync Integration

Reuse the existing authenticated user identity from `AuthManager`. `FamilyGroupStore` and domain permission checks consume the current `userID` from that existing source.

Reuse the existing sync engine. `Family Group` becomes one more syncable metadata object; it does not introduce a second sync path.

## Data Model

### `FamilyGroup`

Minimum fields:

- `id`
- `ownerUserID`
- `inviteCode`
- `inviteExpiresAt`
- `sharedBabyIDs`
- `createdAt`
- `updatedAt`

### `FamilyMember`

Minimum fields:

- `userID`
- `role`
- `joinedAt`
- `removedAt?`

Roles in this slice:

- `owner`
- `member`

### Invite Code State

Invite codes should be modeled as stateful, not implicit:

- `active`
- `expired`
- `revoked`

The current active code is reusable for more than one member until it is refreshed, expired, or revoked. This keeps the first release simple while leaving room for regeneration, invalidation, and explicit join failure reasons.

### Shared Content Metadata

Shared content types that support collaborative editing must carry authorship:

- records
- growth entries or milestones that are editable by users
- treasure entries created inside a shared-baby context

At minimum, shared-editable entities need:

- `createdByUserID`
- `updatedByUserID`

## Visibility and Permission Flow

1. The owner creates a family group.
2. The owner generates an invite code.
3. The member joins using that code while authenticated.
4. The owner shares one or more babies.
5. `BabyRepository` resolves accessible babies into `owned` and `shared`.
6. The member sees shared babies only in the separate shared section.
7. Creating content under a shared baby is allowed.
8. Editing or deleting shared-baby content is allowed only when `createdByUserID == currentUserID`.
9. Unshare or removal removes future access, but historical records remain attached to the baby.

This intentionally separates `group membership` from `baby visibility`. Joining a family is not equivalent to seeing all babies.

## Error Handling

Use quiet, readable, in-context feedback. Do not introduce bright destructive UI by default.

Owner-side failures to surface:

- create group failed
- invite code generation failed
- share or unshare failed
- member removal failed

Member-side failures to surface:

- invalid code
- expired code
- revoked code
- access lost because sharing changed
- permission denied when attempting to edit another author's record

Whenever possible, the UI should hide unavailable destructive actions instead of inviting a failed tap. Error messaging is still required for asynchronous or stale-state failures.

## Sync and Consistency Rules

1. `FamilyGroup` metadata is a first-class sync object in this slice.
2. Shared-baby access is evaluated from synced family metadata plus local baby data.
3. Existing local-first rules remain intact: sync failure must not wipe local content.
4. Access revocation must take effect on refresh or completed sync, after which the removed member no longer sees the baby.
5. Historical collaborative records remain in data storage after access is revoked; only visibility changes.

## Testing

### Domain and Store Tests

- owner can create a family group when `Pro`
- non-`Pro` owner cannot create a family group
- member can join with a valid invite code
- invalid, expired, and revoked codes are rejected with explicit states
- shared-baby aggregation returns separate owned and shared sections
- member can create content for shared babies
- member cannot edit or delete content authored by others
- unshare removes visibility without deleting historical records
- removing a member removes visibility without deleting historical records

### UI and Flow Tests

- sidebar and baby profile surfaces render `Shared Babies` as a separate section
- member sees shared babies only after the owner shares them
- owner can manage members and shared babies from the family group page
- permission-limited actions are hidden or disabled appropriately

### QA Scenarios

1. Owner creates a group, generates a code, shares a baby.
2. Member signs in, joins with the code, and sees the shared baby section.
3. Member adds a record to a shared baby and can later edit that record.
4. Member cannot edit an owner-authored record.
5. Owner unshares the baby; member loses access and historical data is preserved.
6. Owner removes the member; member no longer sees shared babies.

## Implementation Slices

1. `FamilyGroupStore` and family-group data model
2. Invite-code join flow
3. Shared-baby visibility aggregation in `BabyRepository` and shell surfaces
4. Shared-content authorship fields and permission enforcement
5. QA and debug surfaces for family-group state inspection

## Out of Scope

- invite links
- deep links or universal links
- multiple family groups per user
- chat or communication features
- granular per-field permissions
- activity history UI
- role types beyond `owner` and `member`
- automatic deletion of historical collaborative records after access loss
- reworking the entire sync architecture
