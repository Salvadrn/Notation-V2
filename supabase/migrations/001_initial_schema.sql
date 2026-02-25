-- ============================================================================
-- Notation V2 — Complete Supabase Schema (CLEAN INSTALL)
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- ============================================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";


-- ============================================================================
-- DROP EXISTING (order matters — children first, parents last)
-- ============================================================================

-- Drop storage policies first (they reference buckets)
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
drop policy if exists "Users can upload own avatar" on storage.objects;
drop policy if exists "Users can update own avatar" on storage.objects;
drop policy if exists "Users can delete own avatar" on storage.objects;
drop policy if exists "Users can view own glyphs" on storage.objects;
drop policy if exists "Users can upload own glyphs" on storage.objects;
drop policy if exists "Users can update own glyphs" on storage.objects;
drop policy if exists "Users can delete own glyphs" on storage.objects;
drop policy if exists "Users can view own attachments" on storage.objects;
drop policy if exists "Users can upload own attachments" on storage.objects;
drop policy if exists "Users can update own attachments" on storage.objects;
drop policy if exists "Users can delete own attachments" on storage.objects;
drop policy if exists "Users can view own exports" on storage.objects;
drop policy if exists "Users can upload own exports" on storage.objects;
drop policy if exists "Users can update own exports" on storage.objects;
drop policy if exists "Users can delete own exports" on storage.objects;

-- Drop realtime publications (ignore errors if not added)
do $$ begin
    alter publication supabase_realtime drop table public.pages;
exception when others then null;
end $$;
do $$ begin
    alter publication supabase_realtime drop table public.page_layers;
exception when others then null;
end $$;

-- Drop RPC functions
drop function if exists public.increment_token_balance(text, integer);
drop function if exists public.deduct_token_balance(text, integer);
-- Also drop old signature if it exists (UUID param version)
drop function if exists public.deduct_token_balance(uuid, integer);
drop function if exists public.increment_token_balance(uuid, integer);

-- Drop trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Drop tables in dependency order (children → parents)
drop table if exists public.shared_notebooks cascade;
drop table if exists public.token_transactions cascade;
drop table if exists public.ai_jobs cascade;
drop table if exists public.glyphs cascade;
drop table if exists public.page_layers cascade;
drop table if exists public.pages cascade;
drop table if exists public.sections cascade;
drop table if exists public.notebooks cascade;
drop table if exists public.folders cascade;
drop table if exists public.profiles cascade;

-- Drop shared function
drop function if exists public.update_updated_at();


-- ============================================================================
-- 1. PROFILES
-- ============================================================================
create table public.profiles (
    id          uuid primary key references auth.users(id) on delete cascade,
    full_name   text,
    avatar_url  text,
    subscription_tier text not null default 'free' check (subscription_tier in ('free', 'pro')),
    token_balance     integer not null default 0,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

comment on table public.profiles is 'User profiles linked to auth.users';

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    insert into public.profiles (id, full_name, subscription_tier, token_balance)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', ''),
        'free',
        0
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Auto-update updated_at (shared by all tables)
create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger profiles_updated_at
    before update on public.profiles
    for each row execute function public.update_updated_at();

-- ============================================================================
-- 2. FOLDERS (hierarchical, self-referential)
-- ============================================================================
create table public.folders (
    id          uuid primary key default uuid_generate_v4(),
    user_id     uuid not null references public.profiles(id) on delete cascade,
    parent_id   uuid references public.folders(id) on delete cascade,
    name        text not null default 'Untitled Folder',
    path        text not null default '/',
    sort_order  integer not null default 0,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

create index idx_folders_user_id on public.folders(user_id);
create index idx_folders_parent_id on public.folders(parent_id);

create trigger folders_updated_at
    before update on public.folders
    for each row execute function public.update_updated_at();

-- ============================================================================
-- 3. NOTEBOOKS
-- ============================================================================
create table public.notebooks (
    id          uuid primary key default uuid_generate_v4(),
    user_id     uuid not null references public.profiles(id) on delete cascade,
    folder_id   uuid references public.folders(id) on delete set null,
    title       text not null default 'Untitled Notebook',
    cover_color text not null default '#6366F1',
    sort_order  integer not null default 0,
    version     integer not null default 1,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

create index idx_notebooks_user_id on public.notebooks(user_id);
create index idx_notebooks_folder_id on public.notebooks(folder_id);

create trigger notebooks_updated_at
    before update on public.notebooks
    for each row execute function public.update_updated_at();

-- ============================================================================
-- 4. SECTIONS
-- ============================================================================
create table public.sections (
    id          uuid primary key default uuid_generate_v4(),
    notebook_id uuid not null references public.notebooks(id) on delete cascade,
    user_id     uuid not null references public.profiles(id) on delete cascade,
    title       text not null default 'Untitled Section',
    sort_order  integer not null default 0,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

create index idx_sections_notebook_id on public.sections(notebook_id);
create index idx_sections_user_id on public.sections(user_id);

create trigger sections_updated_at
    before update on public.sections
    for each row execute function public.update_updated_at();

-- ============================================================================
-- 5. PAGES
-- ============================================================================
create table public.pages (
    id           uuid primary key default uuid_generate_v4(),
    section_id   uuid not null references public.sections(id) on delete cascade,
    user_id      uuid not null references public.profiles(id) on delete cascade,
    title        text not null default '',
    page_size    text not null default 'a4' check (page_size in ('a4', 'letter')),
    orientation  text not null default 'portrait' check (orientation in ('portrait', 'landscape')),
    text_content jsonb not null default '{"blocks": []}'::jsonb,
    sort_order   integer not null default 0,
    version      integer not null default 1,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

create index idx_pages_section_id on public.pages(section_id);
create index idx_pages_user_id on public.pages(user_id);

create trigger pages_updated_at
    before update on public.pages
    for each row execute function public.update_updated_at();

-- ============================================================================
-- 6. PAGE LAYERS
-- ============================================================================
create table public.page_layers (
    id           uuid primary key default uuid_generate_v4(),
    page_id      uuid not null references public.pages(id) on delete cascade,
    user_id      uuid not null references public.profiles(id) on delete cascade,
    layer_type   text not null check (layer_type in ('text', 'drawing', 'handwriting')),
    drawing_data bytea,
    is_visible   boolean not null default true,
    sort_order   integer not null default 0,
    version      integer not null default 1,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

create index idx_page_layers_page_id on public.page_layers(page_id);
create index idx_page_layers_user_id on public.page_layers(user_id);

create trigger page_layers_updated_at
    before update on public.page_layers
    for each row execute function public.update_updated_at();

-- ============================================================================
-- 7. GLYPHS (handwriting alphabet)
-- ============================================================================
create table public.glyphs (
    id              uuid primary key default uuid_generate_v4(),
    user_id         uuid not null references public.profiles(id) on delete cascade,
    character       text not null,
    variation_index integer not null default 0,
    stroke_data     bytea not null,
    image_url       text,
    created_at      timestamptz not null default now()
);

create index idx_glyphs_user_id on public.glyphs(user_id);
create index idx_glyphs_user_character on public.glyphs(user_id, character);

create unique index idx_glyphs_unique_variation
    on public.glyphs(user_id, character, variation_index);

-- ============================================================================
-- 8. AI JOBS
-- ============================================================================
create table public.ai_jobs (
    id           uuid primary key default uuid_generate_v4(),
    user_id      uuid not null references public.profiles(id) on delete cascade,
    page_id      uuid references public.pages(id) on delete set null,
    input_type   text not null check (input_type in ('photo', 'pdf', 'image')),
    input_url    text,
    output_notes jsonb,
    tokens_used  integer not null default 0,
    status       text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
    created_at   timestamptz not null default now()
);

create index idx_ai_jobs_user_id on public.ai_jobs(user_id);
create index idx_ai_jobs_status on public.ai_jobs(status);

-- ============================================================================
-- 9. TOKEN TRANSACTIONS (ledger/journal)
-- ============================================================================
create table public.token_transactions (
    id           uuid primary key default uuid_generate_v4(),
    user_id      uuid not null references public.profiles(id) on delete cascade,
    amount       integer not null,
    reason       text not null,
    reference_id text,
    created_at   timestamptz not null default now()
);

create index idx_token_transactions_user_id on public.token_transactions(user_id);
create index idx_token_transactions_created_at on public.token_transactions(user_id, created_at desc);

-- ============================================================================
-- 10. SHARED NOTEBOOKS (future feature)
-- ============================================================================
create table public.shared_notebooks (
    id             uuid primary key default uuid_generate_v4(),
    notebook_id    uuid not null references public.notebooks(id) on delete cascade,
    owner_id       uuid not null references public.profiles(id) on delete cascade,
    shared_with_id uuid not null references public.profiles(id) on delete cascade,
    permission     text not null default 'view' check (permission in ('view', 'edit')),
    created_at     timestamptz not null default now()
);

create index idx_shared_notebooks_owner on public.shared_notebooks(owner_id);
create index idx_shared_notebooks_shared_with on public.shared_notebooks(shared_with_id);
create unique index idx_shared_notebooks_unique
    on public.shared_notebooks(notebook_id, shared_with_id);


-- ============================================================================
-- RPC FUNCTIONS (Token balance operations)
-- ============================================================================

create or replace function public.increment_token_balance(
    user_id_input text,
    amount_input integer
)
returns void
language plpgsql
security definer
as $$
begin
    update public.profiles
    set token_balance = token_balance + amount_input,
        updated_at = now()
    where id = user_id_input::uuid;

    if not found then
        raise exception 'User not found: %', user_id_input;
    end if;
end;
$$;

create or replace function public.deduct_token_balance(
    user_id_input text,
    amount_input integer
)
returns void
language plpgsql
security definer
as $$
declare
    current_balance integer;
begin
    select token_balance into current_balance
    from public.profiles
    where id = user_id_input::uuid
    for update;

    if not found then
        raise exception 'User not found: %', user_id_input;
    end if;

    if current_balance < amount_input then
        raise exception 'Insufficient token balance. Have: %, need: %', current_balance, amount_input;
    end if;

    update public.profiles
    set token_balance = token_balance - amount_input,
        updated_at = now()
    where id = user_id_input::uuid;
end;
$$;


-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.folders enable row level security;
alter table public.notebooks enable row level security;
alter table public.sections enable row level security;
alter table public.pages enable row level security;
alter table public.page_layers enable row level security;
alter table public.glyphs enable row level security;
alter table public.ai_jobs enable row level security;
alter table public.token_transactions enable row level security;
alter table public.shared_notebooks enable row level security;

-- ── Profiles ──
create policy "Users can view own profile"
    on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile"
    on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile"
    on public.profiles for insert with check (auth.uid() = id);

-- ── Folders ──
create policy "Users can view own folders"
    on public.folders for select using (auth.uid() = user_id);
create policy "Users can create own folders"
    on public.folders for insert with check (auth.uid() = user_id);
create policy "Users can update own folders"
    on public.folders for update using (auth.uid() = user_id);
create policy "Users can delete own folders"
    on public.folders for delete using (auth.uid() = user_id);

-- ── Notebooks ──
create policy "Users can view own notebooks"
    on public.notebooks for select using (auth.uid() = user_id);
create policy "Users can create own notebooks"
    on public.notebooks for insert with check (auth.uid() = user_id);
create policy "Users can update own notebooks"
    on public.notebooks for update using (auth.uid() = user_id);
create policy "Users can delete own notebooks"
    on public.notebooks for delete using (auth.uid() = user_id);
create policy "Users can view shared notebooks"
    on public.notebooks for select using (
        id in (select notebook_id from public.shared_notebooks where shared_with_id = auth.uid())
    );

-- ── Sections ──
create policy "Users can view own sections"
    on public.sections for select using (auth.uid() = user_id);
create policy "Users can create own sections"
    on public.sections for insert with check (auth.uid() = user_id);
create policy "Users can update own sections"
    on public.sections for update using (auth.uid() = user_id);
create policy "Users can delete own sections"
    on public.sections for delete using (auth.uid() = user_id);

-- ── Pages ──
create policy "Users can view own pages"
    on public.pages for select using (auth.uid() = user_id);
create policy "Users can create own pages"
    on public.pages for insert with check (auth.uid() = user_id);
create policy "Users can update own pages"
    on public.pages for update using (auth.uid() = user_id);
create policy "Users can delete own pages"
    on public.pages for delete using (auth.uid() = user_id);

-- ── Page Layers ──
create policy "Users can view own layers"
    on public.page_layers for select using (auth.uid() = user_id);
create policy "Users can create own layers"
    on public.page_layers for insert with check (auth.uid() = user_id);
create policy "Users can update own layers"
    on public.page_layers for update using (auth.uid() = user_id);
create policy "Users can delete own layers"
    on public.page_layers for delete using (auth.uid() = user_id);

-- ── Glyphs ──
create policy "Users can view own glyphs"
    on public.glyphs for select using (auth.uid() = user_id);
create policy "Users can create own glyphs"
    on public.glyphs for insert with check (auth.uid() = user_id);
create policy "Users can update own glyphs"
    on public.glyphs for update using (auth.uid() = user_id);
create policy "Users can delete own glyphs"
    on public.glyphs for delete using (auth.uid() = user_id);

-- ── AI Jobs ──
create policy "Users can view own ai_jobs"
    on public.ai_jobs for select using (auth.uid() = user_id);
create policy "Users can create own ai_jobs"
    on public.ai_jobs for insert with check (auth.uid() = user_id);
create policy "Users can update own ai_jobs"
    on public.ai_jobs for update using (auth.uid() = user_id);

-- ── Token Transactions ──
create policy "Users can view own transactions"
    on public.token_transactions for select using (auth.uid() = user_id);
create policy "Users can create own transactions"
    on public.token_transactions for insert with check (auth.uid() = user_id);

-- ── Shared Notebooks ──
create policy "Owners can view shared notebooks"
    on public.shared_notebooks for select using (auth.uid() = owner_id or auth.uid() = shared_with_id);
create policy "Owners can share notebooks"
    on public.shared_notebooks for insert with check (auth.uid() = owner_id);
create policy "Owners can update shares"
    on public.shared_notebooks for update using (auth.uid() = owner_id);
create policy "Owners can remove shares"
    on public.shared_notebooks for delete using (auth.uid() = owner_id);


-- ============================================================================
-- REALTIME
-- ============================================================================

alter publication supabase_realtime add table public.pages;
alter publication supabase_realtime add table public.page_layers;


-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    ('avatars', 'avatars', true, 2097152, array['image/png', 'image/jpeg', 'image/webp']),
    ('glyphs', 'glyphs', false, 1048576, array['image/png']),
    ('attachments', 'attachments', false, 10485760, array['image/png', 'image/jpeg', 'application/pdf']),
    ('exports', 'exports', false, 52428800, array['application/pdf', 'image/png'])
on conflict (id) do nothing;

-- ── Storage Policies ──

-- Avatars
create policy "Avatar images are publicly accessible"
    on storage.objects for select using (bucket_id = 'avatars');
create policy "Users can upload own avatar"
    on storage.objects for insert with check (
        bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can update own avatar"
    on storage.objects for update using (
        bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can delete own avatar"
    on storage.objects for delete using (
        bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
    );

-- Glyphs
create policy "Users can view own glyphs storage"
    on storage.objects for select using (
        bucket_id = 'glyphs' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can upload own glyphs storage"
    on storage.objects for insert with check (
        bucket_id = 'glyphs' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can update own glyphs storage"
    on storage.objects for update using (
        bucket_id = 'glyphs' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can delete own glyphs storage"
    on storage.objects for delete using (
        bucket_id = 'glyphs' and (storage.foldername(name))[1] = auth.uid()::text
    );

-- Attachments
create policy "Users can view own attachments"
    on storage.objects for select using (
        bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can upload own attachments"
    on storage.objects for insert with check (
        bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can update own attachments"
    on storage.objects for update using (
        bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can delete own attachments"
    on storage.objects for delete using (
        bucket_id = 'attachments' and (storage.foldername(name))[1] = auth.uid()::text
    );

-- Exports
create policy "Users can view own exports"
    on storage.objects for select using (
        bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can upload own exports"
    on storage.objects for insert with check (
        bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can update own exports"
    on storage.objects for update using (
        bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text
    );
create policy "Users can delete own exports"
    on storage.objects for delete using (
        bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text
    );


-- ============================================================================
-- DONE! All 10 tables, RLS, RPC functions, triggers, storage, and realtime.
-- ============================================================================
