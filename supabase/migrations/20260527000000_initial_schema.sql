-- ============================================================
-- Lablio – Initial Schema
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- PROFILES
-- ────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid        primary key references auth.users (id) on delete cascade,
  full_name   text,
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Explicit grants (required since April 2026 – tables are no longer auto-exposed)
grant select, insert, update on public.profiles to authenticated;

create policy "profiles: owner select"
  on public.profiles for select
  to authenticated
  using ( (select auth.uid()) = id );

create policy "profiles: owner insert"
  on public.profiles for insert
  to authenticated
  with check ( (select auth.uid()) = id );

create policy "profiles: owner update"
  on public.profiles for update
  to authenticated
  using ( (select auth.uid()) = id )
  with check ( (select auth.uid()) = id );

-- Trigger: auto-create profile row on sign-up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ────────────────────────────────────────────────────────────
-- REPORTS
-- ────────────────────────────────────────────────────────────
create table if not exists public.reports (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references auth.users (id) on delete cascade,
  title       text        not null,
  date        date        not null,
  notes       text,
  pdf_url     text,
  pdf_path    text,
  created_at  timestamptz not null default now()
);

alter table public.reports enable row level security;

grant select, insert, update, delete on public.reports to authenticated;

create policy "reports: owner select"
  on public.reports for select
  to authenticated
  using ( (select auth.uid()) = user_id );

create policy "reports: owner insert"
  on public.reports for insert
  to authenticated
  with check ( (select auth.uid()) = user_id );

create policy "reports: owner update"
  on public.reports for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create policy "reports: owner delete"
  on public.reports for delete
  to authenticated
  using ( (select auth.uid()) = user_id );


-- ────────────────────────────────────────────────────────────
-- BIOMARKER ENTRIES
-- ────────────────────────────────────────────────────────────
create table if not exists public.biomarker_entries (
  id                  uuid        primary key default gen_random_uuid(),
  user_id             uuid        not null references auth.users (id) on delete cascade,
  report_id           uuid        references public.reports (id) on delete set null,
  biomarker_id        text        not null,
  biomarker_name      text        not null,
  biomarker_category  text        not null default '',
  value               numeric     not null,
  unit                text        not null,
  date                date        not null,
  notes               text,
  ref_range_low       numeric,
  ref_range_high      numeric,
  created_at          timestamptz not null default now()
);

alter table public.biomarker_entries enable row level security;

grant select, insert, update, delete on public.biomarker_entries to authenticated;

create policy "biomarker_entries: owner select"
  on public.biomarker_entries for select
  to authenticated
  using ( (select auth.uid()) = user_id );

create policy "biomarker_entries: owner insert"
  on public.biomarker_entries for insert
  to authenticated
  with check ( (select auth.uid()) = user_id );

create policy "biomarker_entries: owner update"
  on public.biomarker_entries for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create policy "biomarker_entries: owner delete"
  on public.biomarker_entries for delete
  to authenticated
  using ( (select auth.uid()) = user_id );


-- ────────────────────────────────────────────────────────────
-- STORAGE BUCKET  (run in SQL Editor — Dashboard bucket UI
-- can also be used, but SQL is reproducible)
-- ────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('reports', 'reports', false)
on conflict (id) do nothing;

-- Users can upload/replace their own files
create policy "storage reports: owner insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'reports'
    and (select auth.uid())::text = (storage.foldername(name))[1]
  );

create policy "storage reports: owner select"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'reports'
    and (select auth.uid())::text = (storage.foldername(name))[1]
  );

-- UPDATE is required for upsert (file replacement)
create policy "storage reports: owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'reports'
    and (select auth.uid())::text = (storage.foldername(name))[1]
  );

create policy "storage reports: owner delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'reports'
    and (select auth.uid())::text = (storage.foldername(name))[1]
  );
