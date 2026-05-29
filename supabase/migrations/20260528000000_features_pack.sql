-- ============================================================
-- Lablio – Feature pack: entry tags, per-biomarker notes,
-- custom biomarkers, and static explainer text.
-- ============================================================

-- Tags on biomarker entries.
alter table public.biomarker_entries add column if not exists tags text[];

-- Per-biomarker long-form notes (one row per user+biomarker).
create table if not exists public.biomarker_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  biomarker_id text not null,
  body text not null default '',
  updated_at timestamptz not null default now(),
  unique(user_id, biomarker_id)
);
alter table public.biomarker_notes enable row level security;
grant select, insert, update, delete on public.biomarker_notes to authenticated;
create policy "biomarker_notes: owner select"
  on public.biomarker_notes for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "biomarker_notes: owner insert"
  on public.biomarker_notes for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "biomarker_notes: owner update"
  on public.biomarker_notes for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "biomarker_notes: owner delete"
  on public.biomarker_notes for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Custom (user-defined) biomarkers.
create table if not exists public.custom_biomarkers (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  short_name text not null,
  category text not null default 'Custom',
  unit text not null default '',
  ref_range_low numeric,
  ref_range_high numeric,
  description text,
  created_at timestamptz not null default now()
);
alter table public.custom_biomarkers enable row level security;
grant select, insert, update, delete on public.custom_biomarkers to authenticated;
create policy "custom_biomarkers: owner select"
  on public.custom_biomarkers for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "custom_biomarkers: owner insert"
  on public.custom_biomarkers for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "custom_biomarkers: owner update"
  on public.custom_biomarkers for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "custom_biomarkers: owner delete"
  on public.custom_biomarkers for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Explainer columns on the reference biomarkers (curated content seeded
-- separately for ~25 common markers; see follow-up populating script).
alter table public.biomarkers add column if not exists explanation_high text;
alter table public.biomarkers add column if not exists explanation_low text;
