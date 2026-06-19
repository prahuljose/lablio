-- ============================================================
-- Lablio – PDF export audit log
-- Records one row each time a user exports a "Share with doctor"
-- PDF summary: who, when, how many biomarkers, and device info.
-- Append-only (insert + select, no update/delete from clients).
-- ============================================================

create table if not exists public.pdf_export_logs (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references auth.users (id) on delete cascade,
  exported_at     timestamptz not null default now(),
  biomarker_count integer,
  platform        text,
  device_model    text,
  os_version      text,
  app_version     text,
  created_at      timestamptz not null default now()
);

alter table public.pdf_export_logs enable row level security;

-- Append-only audit log: clients may insert their own rows and read them back.
grant select, insert on public.pdf_export_logs to authenticated;

create policy "pdf_export_logs: owner select"
  on public.pdf_export_logs for select
  to authenticated
  using ( (select auth.uid()) = user_id );

create policy "pdf_export_logs: owner insert"
  on public.pdf_export_logs for insert
  to authenticated
  with check ( (select auth.uid()) = user_id );

create index if not exists idx_pdf_export_logs_user
  on public.pdf_export_logs (user_id, exported_at desc);
