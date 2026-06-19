-- ============================================================
-- Lablio – PDF export log: record export type + whether the
-- medical-record section was included in the generated PDF.
-- ============================================================

alter table public.pdf_export_logs
  add column if not exists export_type text not null default 'doctor_pdf',
  add column if not exists included_medical boolean;
