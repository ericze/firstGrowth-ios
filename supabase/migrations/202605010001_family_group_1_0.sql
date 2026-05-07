begin;

create extension if not exists pgcrypto;

create table if not exists public.family_groups (
  id uuid primary key,
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  invite_code text,
  invite_expires_at timestamptz,
  invite_state text not null default 'revoked',
  shared_baby_ids uuid[] not null default '{}'::uuid[],
  members jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  deleted_at timestamptz,
  constraint family_groups_invite_state_check
    check (invite_state in ('active', 'expired', 'revoked'))
);

create index if not exists idx_family_groups_owner_user_id
  on public.family_groups(owner_user_id);

create index if not exists idx_family_groups_updated_at
  on public.family_groups(updated_at);

create index if not exists idx_family_groups_invite_code
  on public.family_groups(invite_code)
  where invite_code is not null and deleted_at is null;

create or replace function public.jsonb_to_uuid_array(payload jsonb)
returns uuid[]
language plpgsql
immutable
as $$
declare
  values uuid[] := '{}'::uuid[];
begin
  if payload is null or jsonb_typeof(payload) <> 'array' then
    return values;
  end if;

  select coalesce(array_agg(item.value::uuid order by item.ordinality), '{}'::uuid[])
  into values
  from jsonb_array_elements_text(payload) with ordinality as item(value, ordinality);

  return values;
end;
$$;

create or replace function public.family_group_member_is_active(
  members jsonb,
  target_user_id uuid
)
returns boolean
language sql
immutable
as $$
  select exists (
    select 1
    from jsonb_array_elements(coalesce(members, '[]'::jsonb)) as member(value)
    where member.value->>'userID' = target_user_id::text
      and member.value->>'removedAt' is null
  );
$$;

create or replace function public.family_group_members_without_user(
  members jsonb,
  target_user_id uuid
)
returns jsonb
language sql
immutable
as $$
  select coalesce(
    jsonb_agg(member.value order by member.ordinality),
    '[]'::jsonb
  )
  from jsonb_array_elements(coalesce(members, '[]'::jsonb)) with ordinality as member(value, ordinality)
  where member.value->>'userID' is distinct from target_user_id::text;
$$;

create or replace function public.family_group_for_user_exists(target_user_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.family_groups
    where deleted_at is null
      and (
        owner_user_id = target_user_id
        or public.family_group_member_is_active(members, target_user_id)
      )
  );
$$;

alter table public.family_groups enable row level security;

drop policy if exists "family groups select own or member" on public.family_groups;
create policy "family groups select own or member"
on public.family_groups for select
to authenticated
using (
  owner_user_id = auth.uid()
  or public.family_group_member_is_active(members, auth.uid())
);

drop policy if exists "family groups insert owner" on public.family_groups;
create policy "family groups insert owner"
on public.family_groups for insert
to authenticated
with check (
  deleted_at is null
  and owner_user_id = auth.uid()
  and public.family_group_member_is_active(members, auth.uid())
);

drop policy if exists "family groups update own or member" on public.family_groups;
create policy "family groups update own or member"
on public.family_groups for update
to authenticated
using (
  deleted_at is null
  and (
    owner_user_id = auth.uid()
    or public.family_group_member_is_active(members, auth.uid())
  )
)
with check (
  owner_user_id = auth.uid()
  or public.family_group_member_is_active(members, auth.uid())
);

create or replace function public.soft_delete_row(table_name text, row_id uuid, expected_version bigint default null)
returns void
language plpgsql
security invoker
as $$
declare
  current_version bigint;
  current_user_id uuid;
  current_owner_user_id uuid;
  current_members jsonb;
  current_deleted_at timestamptz;
  authenticated_user_id uuid := auth.uid();
begin
  if table_name not in ('baby_profiles', 'record_items', 'memory_entries', 'family_groups') then
    raise exception 'unsupported table %', table_name using errcode = '42804';
  end if;

  if table_name = 'family_groups' then
    select version, owner_user_id, members, deleted_at
    into current_version, current_owner_user_id, current_members, current_deleted_at
    from public.family_groups
    where id = row_id
    for update;

    if current_owner_user_id is null or current_deleted_at is not null then
      return;
    end if;

    if authenticated_user_id is null or current_owner_user_id <> authenticated_user_id then
      raise exception 'family group deletion requires the owner' using errcode = '42501';
    end if;

    if expected_version is not null and current_version <> expected_version then
      raise exception 'version conflict for family_groups row %', row_id using errcode = '40001';
    end if;

    update public.family_groups
    set deleted_at = now(),
        updated_at = now(),
        version = version + 1
    where id = row_id;

    return;
  end if;

  execute format('select version, user_id from public.%I where id = $1 for update', table_name)
  into current_version, current_user_id
  using row_id;

  if current_user_id is null then
    return;
  end if;

  if current_user_id <> authenticated_user_id then
    raise exception 'row does not belong to authenticated user' using errcode = '42501';
  end if;

  if expected_version is not null and current_version <> expected_version then
    raise exception 'version conflict for % row %', table_name, row_id using errcode = '40001';
  end if;

  execute format('update public.%I set deleted_at = now(), updated_at = now(), version = version + 1 where id = $1', table_name)
  using row_id;
end;
$$;

create or replace function public.upsert_family_group(
  payload jsonb,
  expected_version bigint default null
)
returns public.family_groups
language plpgsql
security invoker
as $$
declare
  row_id uuid := (payload->>'id')::uuid;
  current_row public.family_groups;
  saved_row public.family_groups;
  current_user_id uuid := auth.uid();
  payload_owner_user_id uuid := (payload->>'owner_user_id')::uuid;
  payload_invite_code text := nullif(payload->>'invite_code', '');
  payload_invite_expires_at timestamptz := nullif(payload->>'invite_expires_at', '')::timestamptz;
  payload_invite_state text := coalesce(nullif(payload->>'invite_state', ''), 'revoked');
  payload_shared_baby_ids uuid[] := public.jsonb_to_uuid_array(payload->'shared_baby_ids');
  payload_members jsonb := coalesce(payload->'members', '[]'::jsonb);
begin
  if current_user_id is null then
    raise exception 'family group sync requires an authenticated user' using errcode = '42501';
  end if;

  select * into current_row
  from public.family_groups
  where id = row_id
  for update;

  if found then
    if expected_version is null or current_row.version <> expected_version then
      raise exception 'version conflict for family_groups row %', row_id using errcode = '40001';
    end if;

    if current_row.owner_user_id = current_user_id then
      update public.family_groups
      set owner_user_id = current_row.owner_user_id,
          invite_code = payload_invite_code,
          invite_expires_at = payload_invite_expires_at,
          invite_state = payload_invite_state,
          shared_baby_ids = payload_shared_baby_ids,
          members = payload_members,
          created_at = current_row.created_at,
          updated_at = now(),
          version = version + 1,
          deleted_at = case
            when payload ? 'deleted_at' then nullif(payload->>'deleted_at', '')::timestamptz
            else deleted_at
          end
      where id = row_id
      returning * into saved_row;
    else
      if current_row.owner_user_id <> payload_owner_user_id then
        raise exception 'family group owner cannot change in a member update' using errcode = '42501';
      end if;

      if payload_invite_code is distinct from current_row.invite_code
         or payload_invite_expires_at is distinct from current_row.invite_expires_at
         or payload_invite_state is distinct from current_row.invite_state
         or payload_shared_baby_ids is distinct from current_row.shared_baby_ids then
        raise exception 'member may not modify family group settings' using errcode = '42501';
      end if;

      if not public.family_group_member_is_active(payload_members, current_user_id) then
        raise exception 'member payload must include the authenticated user' using errcode = '42501';
      end if;

      if public.family_group_members_without_user(payload_members, current_user_id)
         is distinct from public.family_group_members_without_user(current_row.members, current_user_id) then
        raise exception 'member payload may only change the authenticated user snapshot' using errcode = '42501';
      end if;

      update public.family_groups
      set owner_user_id = current_row.owner_user_id,
          invite_code = current_row.invite_code,
          invite_expires_at = current_row.invite_expires_at,
          invite_state = current_row.invite_state,
          shared_baby_ids = current_row.shared_baby_ids,
          members = payload_members,
          created_at = current_row.created_at,
          updated_at = now(),
          version = version + 1,
          deleted_at = current_row.deleted_at
      where id = row_id
      returning * into saved_row;
    end if;
  else
    if expected_version is not null then
      raise exception 'version conflict for missing family_groups row %', row_id using errcode = '40001';
    end if;

    if current_user_id <> payload_owner_user_id then
      raise exception 'payload owner_user_id must match the authenticated user' using errcode = '42501';
    end if;

    if family_group_for_user_exists(current_user_id) then
      raise exception 'family group already exists for authenticated user' using errcode = '42501';
    end if;

    if not public.family_group_member_is_active(payload_members, current_user_id) then
      raise exception 'family group payload must include the owner snapshot' using errcode = '42501';
    end if;

    insert into public.family_groups (
      id,
      owner_user_id,
      invite_code,
      invite_expires_at,
      invite_state,
      shared_baby_ids,
      members,
      created_at,
      updated_at,
      version,
      deleted_at
    )
    values (
      row_id,
      payload_owner_user_id,
      payload_invite_code,
      payload_invite_expires_at,
      payload_invite_state,
      payload_shared_baby_ids,
      payload_members,
      coalesce(nullif(payload->>'created_at', '')::timestamptz, now()),
      now(),
      1,
      nullif(payload->>'deleted_at', '')::timestamptz
    )
    returning * into saved_row;
  end if;

  return saved_row;
end;
$$;

create or replace function public.join_family_group(invite_code text)
returns public.family_groups
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_invite_code text := upper(btrim(invite_code));
  current_user_id uuid := auth.uid();
  current_row public.family_groups;
  joined_member jsonb;
  member_payloads jsonb;
begin
  if current_user_id is null then
    raise exception 'family group join requires an authenticated user' using errcode = '42501';
  end if;

  if normalized_invite_code is null or normalized_invite_code = '' then
    raise exception 'invite code is required' using errcode = '22023';
  end if;

  if family_group_for_user_exists(current_user_id) then
    raise exception 'family group already exists for authenticated user' using errcode = '42501';
  end if;

  select * into current_row
  from public.family_groups
  where deleted_at is null
    and invite_code = normalized_invite_code
  for update;

  if not found then
    raise exception 'invalid family group invite code' using errcode = '22023';
  end if;

  if current_row.invite_state = 'revoked' then
    raise exception 'family group invite code has been revoked' using errcode = '22023';
  end if;

  if current_row.invite_state = 'expired'
     or (current_row.invite_expires_at is not null and current_row.invite_expires_at <= now()) then
    update public.family_groups
    set invite_state = 'expired',
        updated_at = now(),
        version = version + 1
    where id = current_row.id;

    raise exception 'family group invite code has expired' using errcode = '22023';
  end if;

  joined_member := jsonb_build_object(
    'userID', current_user_id,
    'role', 'member',
    'joinedAt', now(),
    'removedAt', null
  );

  if public.family_group_member_is_active(current_row.members, current_user_id) then
    member_payloads := current_row.members;
  else
    member_payloads := current_row.members || jsonb_build_array(joined_member);
  end if;

  update public.family_groups
  set members = member_payloads,
      updated_at = now(),
      version = version + 1
  where id = current_row.id
  returning * into current_row;

  return current_row;
end;
$$;

commit;
