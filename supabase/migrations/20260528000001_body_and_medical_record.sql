-- ============================================================
-- Lablio – Body composition markers + Medical record table.
-- ============================================================

insert into public.biomarkers (id, name, short_name, category, unit, ref_range_low, ref_range_high, description) values
  ('weight', 'Weight', 'Wt', 'Body Composition', 'kg', null, null, 'Body weight. Track over time alongside body fat and waist circumference.'),
  ('body_fat_pct', 'Body Fat', 'BF%', 'Body Composition', '%', null, null, 'Body fat percentage measured by impedance scale, calipers, or DEXA.'),
  ('waist_circumference', 'Waist Circumference', 'Waist', 'Body Composition', 'cm', null, null, 'Measured at the navel; rising waist size correlates with metabolic risk.'),
  ('hip_circumference', 'Hip Circumference', 'Hip', 'Body Composition', 'cm', null, null, 'Measured at the widest hip. Used with waist for the waist-hip ratio.')
on conflict (id) do nothing;

update public.biomarkers
  set ref_range_low_male=8, ref_range_high_male=24,
      ref_range_low_female=21, ref_range_high_female=35
  where id='body_fat_pct';
update public.biomarkers
  set ref_range_low_male=0, ref_range_high_male=94,
      ref_range_low_female=0, ref_range_high_female=80
  where id='waist_circumference';

create table if not exists public.medical_record (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('vaccination', 'allergy', 'condition')),
  name text not null,
  occurred_on date,
  severity text,
  status text,
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists idx_medical_record_user on public.medical_record (user_id, kind);
alter table public.medical_record enable row level security;
grant select, insert, update, delete on public.medical_record to authenticated;
create policy "medical_record: owner select"
  on public.medical_record for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "medical_record: owner insert"
  on public.medical_record for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "medical_record: owner update"
  on public.medical_record for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "medical_record: owner delete"
  on public.medical_record for delete to authenticated
  using ((select auth.uid()) = user_id);
