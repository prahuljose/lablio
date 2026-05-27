-- ============================================================
-- Lablio – Sex-specific biomarker reference ranges
-- Adds optional male/female ranges. The app falls back to the
-- generic ref_range_low/high when a sex-specific value is null.
-- ============================================================

alter table public.biomarkers
  add column if not exists ref_range_low_male numeric,
  add column if not exists ref_range_high_male numeric,
  add column if not exists ref_range_low_female numeric,
  add column if not exists ref_range_high_female numeric;

update public.biomarkers set ref_range_low_male=13.5, ref_range_high_male=17.5, ref_range_low_female=12.0, ref_range_high_female=15.5 where id='hemoglobin';
update public.biomarkers set ref_range_low_male=41.0, ref_range_high_male=53.0, ref_range_low_female=36.0, ref_range_high_female=46.0 where id='hematocrit';
update public.biomarkers set ref_range_low_male=4.5, ref_range_high_male=5.9, ref_range_low_female=4.1, ref_range_high_female=5.1 where id='rbc';
update public.biomarkers set ref_range_low_male=30.0, ref_range_high_male=400.0, ref_range_low_female=15.0, ref_range_high_female=150.0 where id='ferritin';
update public.biomarkers set ref_range_low_male=0.74, ref_range_high_male=1.35, ref_range_low_female=0.59, ref_range_high_female=1.04 where id='creatinine';
update public.biomarkers set ref_range_low_male=3.4, ref_range_high_male=7.0, ref_range_low_female=2.4, ref_range_high_female=6.0 where id='uric_acid';
update public.biomarkers set ref_range_low_male=40.0, ref_range_high_male=999.0, ref_range_low_female=50.0, ref_range_high_female=999.0 where id='hdl';
update public.biomarkers set ref_range_low_male=300.0, ref_range_high_male=1000.0, ref_range_low_female=15.0, ref_range_high_female=70.0 where id='testosterone_total';
update public.biomarkers set ref_range_low_male=9.0, ref_range_high_male=30.0, ref_range_low_female=0.3, ref_range_high_female=1.9 where id='testosterone_free';
update public.biomarkers set ref_range_low_male=10.0, ref_range_high_male=40.0, ref_range_low_female=30.0, ref_range_high_female=400.0 where id='estradiol';
update public.biomarkers set ref_range_low_male=38.0, ref_range_high_male=174.0, ref_range_low_female=26.0, ref_range_high_female=140.0 where id='ck';
update public.biomarkers set ref_range_low_male=12.0, ref_range_high_male=64.0, ref_range_low_female=9.0, ref_range_high_female=36.0 where id='ggt';
update public.biomarkers set ref_range_low_male=7.0, ref_range_high_male=55.0, ref_range_low_female=7.0, ref_range_high_female=45.0 where id='alt';
update public.biomarkers set ref_range_low_male=80.0, ref_range_high_male=560.0, ref_range_low_female=35.0, ref_range_high_female=430.0 where id='dhea_s';
