-- ============================================================
-- Lablio – Add ratio/derived markers, switch CBC counts to /cmm,
-- and normalize unit notation to common (Indian) lab convention.
-- ============================================================

insert into public.biomarkers (id, name, short_name, category, unit, ref_range_low, ref_range_high, description) values
  ('eag', 'Estimated Average Glucose', 'eAG', 'Diabetes', 'mg/dL', 70, 117, 'Average blood glucose estimated from HbA1c.'),
  ('chol_hdl_ratio', 'Cholesterol / HDL Ratio', 'CHOL/HDL', 'Lipid Panel', 'ratio', 0, 5, 'Ratio of total cholesterol to HDL; lower is better for cardiovascular risk.'),
  ('ldl_hdl_ratio', 'LDL / HDL Ratio', 'LDL/HDL', 'Lipid Panel', 'ratio', 0, 3, 'Ratio of LDL to HDL cholesterol; lower is better.'),
  ('ag_ratio', 'Albumin / Globulin Ratio', 'A/G', 'Liver Function', 'ratio', 1.1, 2.5, 'Ratio of albumin to globulin in serum.'),
  ('urea', 'Urea', 'Urea', 'Metabolic Panel', 'mg/dL', 15, 40, 'Blood urea, a protein-metabolism waste product (distinct from BUN).')
on conflict (id) do nothing;

-- CBC counts reported per cubic mm in many labs (ranges scaled x1000).
update public.biomarkers set unit='/cmm', ref_range_low=4000,   ref_range_high=11000   where id='wbc';
update public.biomarkers set unit='/cmm', ref_range_low=150000, ref_range_high=400000  where id='platelets';

-- Notation normalization (numerically identical, common lab labels).
update public.biomarkers set unit='gm/dL'    where id in ('hemoglobin','mchc','total_protein','albumin','globulin');
update public.biomarkers set unit='mill/cmm' where id='rbc';
update public.biomarkers set unit='µIU/mL'   where id='tsh';
