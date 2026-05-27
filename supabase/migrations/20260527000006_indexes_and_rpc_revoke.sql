-- ============================================================
-- Lablio – Performance indexes + RPC hardening
-- Covering indexes for foreign keys, and revoke public EXECUTE
-- on the sign-up trigger function (it is not a public API).
-- ============================================================

create index if not exists idx_biomarker_entries_user_id
  on public.biomarker_entries (user_id);
create index if not exists idx_biomarker_entries_report_id
  on public.biomarker_entries (report_id);
create index if not exists idx_reports_user_id
  on public.reports (user_id);

revoke execute on function public.handle_new_user() from anon, authenticated, public;
