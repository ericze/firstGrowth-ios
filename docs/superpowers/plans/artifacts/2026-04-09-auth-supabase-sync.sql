-- 1.1.0 Phase 2 groundwork artifact (Task 1)
-- Scope:
-- 1) Core tables: profiles / baby_profiles / record_items / memory_entries
-- 2) Triggers: handle_new_user / set_row_sync_metadata
-- 3) RPC: server_now
-- 4) RLS policies for all sync tables
-- 5) Storage buckets + policies: food-photos / treasure-photos / baby-avatars
-- 6) Image columns store storage path only (no URL)

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.utc_now()
RETURNS TIMESTAMPTZ
LANGUAGE SQL
STABLE
AS $$
    SELECT timezone('utc', now());
$$;

CREATE OR REPLACE FUNCTION public.is_storage_path(value TEXT)
RETURNS BOOLEAN
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT
        value IS NOT NULL
        AND btrim(value) <> ''
        AND position('://' IN value) = 0
        AND left(value, 1) <> '/';
$$;

CREATE OR REPLACE FUNCTION public.is_storage_path_array(values TEXT[])
RETURNS BOOLEAN
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT COALESCE((
        SELECT bool_and(public.is_storage_path(item))
        FROM unnest(values) AS item
    ), TRUE);
$$;

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL CHECK (btrim(email) <> ''),
    created_at TIMESTAMPTZ NOT NULL DEFAULT public.utc_now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT public.utc_now()
);

CREATE TABLE IF NOT EXISTS public.baby_profiles (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT '宝宝' CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
    birth_date TIMESTAMPTZ NOT NULL DEFAULT public.utc_now(),
    gender TEXT CHECK (gender IS NULL OR gender IN ('male', 'female')),
    avatar_storage_path TEXT CHECK (
        avatar_storage_path IS NULL OR public.is_storage_path(avatar_storage_path)
    ),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    has_completed_onboarding BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT public.utc_now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT public.utc_now(),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    deleted_at TIMESTAMPTZ
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'baby_profiles_id_user_id_unique'
    ) THEN
        ALTER TABLE public.baby_profiles
            ADD CONSTRAINT baby_profiles_id_user_id_unique UNIQUE (id, user_id);
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS public.record_items (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    baby_id UUID NOT NULL,
    type TEXT NOT NULL CHECK (btrim(type) <> ''),
    timestamp TIMESTAMPTZ NOT NULL,
    value DOUBLE PRECISION,
    left_nursing_seconds INTEGER NOT NULL DEFAULT 0 CHECK (left_nursing_seconds >= 0),
    right_nursing_seconds INTEGER NOT NULL DEFAULT 0 CHECK (right_nursing_seconds >= 0),
    sub_type TEXT,
    image_storage_path TEXT CHECK (
        image_storage_path IS NULL OR public.is_storage_path(image_storage_path)
    ),
    ai_summary TEXT,
    tags JSONB,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT public.utc_now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT public.utc_now(),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT record_items_user_baby_fk
        FOREIGN KEY (baby_id, user_id)
        REFERENCES public.baby_profiles(id, user_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.memory_entries (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    baby_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    age_in_days INTEGER CHECK (age_in_days IS NULL OR age_in_days >= 0),
    image_storage_paths TEXT[] NOT NULL DEFAULT '{}'::TEXT[] CHECK (
        public.is_storage_path_array(image_storage_paths)
    ),
    note TEXT,
    is_milestone BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT public.utc_now(),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT memory_entries_user_baby_fk
        FOREIGN KEY (baby_id, user_id)
        REFERENCES public.baby_profiles(id, user_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_baby_profiles_user_id
    ON public.baby_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_baby_profiles_updated_at
    ON public.baby_profiles(updated_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_baby_profiles_active_per_user
    ON public.baby_profiles(user_id)
    WHERE is_active IS TRUE AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_record_items_user_id
    ON public.record_items(user_id);
CREATE INDEX IF NOT EXISTS idx_record_items_baby_id
    ON public.record_items(baby_id);
CREATE INDEX IF NOT EXISTS idx_record_items_timestamp_desc
    ON public.record_items(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_record_items_updated_at
    ON public.record_items(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_memory_entries_user_id
    ON public.memory_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_entries_baby_id
    ON public.memory_entries(baby_id);
CREATE INDEX IF NOT EXISTS idx_memory_entries_updated_at
    ON public.memory_entries(updated_at DESC);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NULLIF(NEW.email, ''), NEW.id::TEXT || '@placeholder.local'),
        public.utc_now(),
        public.utc_now()
    )
    ON CONFLICT (id) DO UPDATE
    SET
        email = EXCLUDED.email,
        updated_at = public.utc_now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.set_row_sync_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := COALESCE(NEW.created_at, public.utc_now());
        NEW.updated_at := COALESCE(NEW.updated_at, NEW.created_at);
        NEW.version := COALESCE(NEW.version, 1);
        RETURN NEW;
    END IF;

    IF ROW(NEW.*) IS DISTINCT FROM ROW(OLD.*) THEN
        NEW.updated_at := public.utc_now();
        NEW.version := COALESCE(OLD.version, 0) + 1;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_row_sync_metadata_baby_profiles ON public.baby_profiles;
CREATE TRIGGER set_row_sync_metadata_baby_profiles
BEFORE INSERT OR UPDATE ON public.baby_profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_row_sync_metadata();

DROP TRIGGER IF EXISTS set_row_sync_metadata_record_items ON public.record_items;
CREATE TRIGGER set_row_sync_metadata_record_items
BEFORE INSERT OR UPDATE ON public.record_items
FOR EACH ROW
EXECUTE FUNCTION public.set_row_sync_metadata();

DROP TRIGGER IF EXISTS set_row_sync_metadata_memory_entries ON public.memory_entries;
CREATE TRIGGER set_row_sync_metadata_memory_entries
BEFORE INSERT OR UPDATE ON public.memory_entries
FOR EACH ROW
EXECUTE FUNCTION public.set_row_sync_metadata();

CREATE OR REPLACE FUNCTION public.server_now()
RETURNS TIMESTAMPTZ
LANGUAGE SQL
STABLE
AS $$
    SELECT public.utc_now();
$$;

GRANT EXECUTE ON FUNCTION public.server_now() TO authenticated;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.baby_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.record_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memory_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own
ON public.profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
CREATE POLICY profiles_insert_own
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS profiles_delete_own ON public.profiles;
CREATE POLICY profiles_delete_own
ON public.profiles
FOR DELETE
TO authenticated
USING (id = auth.uid());

DROP POLICY IF EXISTS baby_profiles_all_own ON public.baby_profiles;
CREATE POLICY baby_profiles_all_own
ON public.baby_profiles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS record_items_all_own ON public.record_items;
CREATE POLICY record_items_all_own
ON public.record_items
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS memory_entries_all_own ON public.memory_entries;
CREATE POLICY memory_entries_all_own
ON public.memory_entries
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

INSERT INTO storage.buckets (id, name, public)
VALUES
    ('food-photos', 'food-photos', FALSE),
    ('treasure-photos', 'treasure-photos', FALSE),
    ('baby-avatars', 'baby-avatars', FALSE)
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    public = EXCLUDED.public;

DROP POLICY IF EXISTS food_photos_select_own ON storage.objects;
CREATE POLICY food_photos_select_own
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'food-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS food_photos_insert_own ON storage.objects;
CREATE POLICY food_photos_insert_own
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'food-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS food_photos_update_own ON storage.objects;
CREATE POLICY food_photos_update_own
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'food-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
)
WITH CHECK (
    bucket_id = 'food-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS food_photos_delete_own ON storage.objects;
CREATE POLICY food_photos_delete_own
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'food-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS treasure_photos_select_own ON storage.objects;
CREATE POLICY treasure_photos_select_own
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'treasure-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS treasure_photos_insert_own ON storage.objects;
CREATE POLICY treasure_photos_insert_own
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'treasure-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS treasure_photos_update_own ON storage.objects;
CREATE POLICY treasure_photos_update_own
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'treasure-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
)
WITH CHECK (
    bucket_id = 'treasure-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS treasure_photos_delete_own ON storage.objects;
CREATE POLICY treasure_photos_delete_own
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'treasure-photos'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS baby_avatars_select_own ON storage.objects;
CREATE POLICY baby_avatars_select_own
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'baby-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS baby_avatars_insert_own ON storage.objects;
CREATE POLICY baby_avatars_insert_own
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'baby-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS baby_avatars_update_own ON storage.objects;
CREATE POLICY baby_avatars_update_own
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'baby-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
)
WITH CHECK (
    bucket_id = 'baby-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

DROP POLICY IF EXISTS baby_avatars_delete_own ON storage.objects;
CREATE POLICY baby_avatars_delete_own
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'baby-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

COMMIT;
