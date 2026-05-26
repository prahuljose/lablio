-- ============================================================
-- Lablio – Biomarkers reference table + seed data
-- ============================================================

create table if not exists public.biomarkers (
  id             text    primary key,
  name           text    not null,
  short_name     text    not null,
  category       text    not null,
  unit           text    not null,
  ref_range_low  numeric,
  ref_range_high numeric,
  description    text
);

alter table public.biomarkers enable row level security;

-- Reference data — publicly readable, no writes from clients
grant select on public.biomarkers to anon, authenticated;

create policy "biomarkers: public read"
  on public.biomarkers for select
  to anon, authenticated
  using (true);

-- Seed 59 reference biomarkers
insert into public.biomarkers (id, name, short_name, category, unit, ref_range_low, ref_range_high, description) values
  ('wbc', 'White Blood Cell Count', 'WBC', 'Complete Blood Count', 'K/µL', 4.5, 11.0, 'Total number of white blood cells. Elevated in infection or inflammation; low may indicate immune issues.'),
  ('rbc', 'Red Blood Cell Count', 'RBC', 'Complete Blood Count', 'M/µL', 4.5, 5.9, 'Number of red blood cells carrying oxygen throughout the body.'),
  ('hemoglobin', 'Hemoglobin', 'Hgb', 'Complete Blood Count', 'g/dL', 13.5, 17.5, 'Protein in red blood cells that carries oxygen. Low levels indicate anemia.'),
  ('hematocrit', 'Hematocrit', 'Hct', 'Complete Blood Count', '%', 41.0, 53.0, 'Percentage of red blood cells in total blood volume.'),
  ('mcv', 'Mean Corpuscular Volume', 'MCV', 'Complete Blood Count', 'fL', 80.0, 100.0, 'Average size of red blood cells. Helps classify type of anemia.'),
  ('mch', 'Mean Corpuscular Hemoglobin', 'MCH', 'Complete Blood Count', 'pg', 27.0, 33.0, 'Average amount of hemoglobin per red blood cell.'),
  ('mchc', 'Mean Corpuscular Hemoglobin Concentration', 'MCHC', 'Complete Blood Count', 'g/dL', 32.0, 36.0, 'Concentration of hemoglobin in a given volume of red blood cells.'),
  ('platelets', 'Platelet Count', 'PLT', 'Complete Blood Count', 'K/µL', 150.0, 400.0, 'Cells that help blood clot. Low levels may cause bleeding; high levels may indicate clotting risk.'),
  ('neutrophils_pct', 'Neutrophils', 'Neut%', 'Complete Blood Count', '%', 50.0, 70.0, 'Most abundant white blood cells; first responders to bacterial infection.'),
  ('lymphocytes_pct', 'Lymphocytes', 'Lymph%', 'Complete Blood Count', '%', 20.0, 40.0, 'White blood cells key to immune response, including T and B cells.'),
  ('monocytes_pct', 'Monocytes', 'Mono%', 'Complete Blood Count', '%', 2.0, 8.0, 'White blood cells that fight infection and help other immune cells.'),
  ('eosinophils_pct', 'Eosinophils', 'Eos%', 'Complete Blood Count', '%', 1.0, 4.0, 'White blood cells involved in allergic reactions and parasite defense.'),
  ('glucose', 'Glucose', 'Gluc', 'Metabolic Panel', 'mg/dL', 70.0, 99.0, 'Blood sugar level. Elevated fasting glucose may indicate prediabetes or diabetes.'),
  ('bun', 'Blood Urea Nitrogen', 'BUN', 'Metabolic Panel', 'mg/dL', 7.0, 20.0, 'Waste product from protein metabolism. Elevated levels may indicate kidney dysfunction.'),
  ('creatinine', 'Creatinine', 'Creat', 'Metabolic Panel', 'mg/dL', 0.74, 1.35, 'Waste product filtered by kidneys. High levels suggest impaired kidney function.'),
  ('egfr', 'Estimated GFR', 'eGFR', 'Metabolic Panel', 'mL/min/1.73m²', 60.0, 120.0, 'Estimate of kidney filtration rate. Below 60 may indicate chronic kidney disease.'),
  ('sodium', 'Sodium', 'Na', 'Metabolic Panel', 'mEq/L', 136.0, 145.0, 'Electrolyte that regulates fluid balance and nerve/muscle function.'),
  ('potassium', 'Potassium', 'K', 'Metabolic Panel', 'mEq/L', 3.5, 5.1, 'Electrolyte critical for heart and muscle function.'),
  ('chloride', 'Chloride', 'Cl', 'Metabolic Panel', 'mEq/L', 98.0, 107.0, 'Electrolyte that maintains fluid and acid-base balance.'),
  ('co2', 'Carbon Dioxide', 'CO2', 'Metabolic Panel', 'mEq/L', 22.0, 29.0, 'Bicarbonate level reflecting acid-base balance.'),
  ('calcium', 'Calcium', 'Ca', 'Metabolic Panel', 'mg/dL', 8.6, 10.3, 'Mineral essential for bones, teeth, nerve, and muscle function.'),
  ('total_protein', 'Total Protein', 'TP', 'Metabolic Panel', 'g/dL', 6.3, 8.2, 'Total amount of protein in the blood; reflects nutritional status and liver function.'),
  ('albumin', 'Albumin', 'Alb', 'Metabolic Panel', 'g/dL', 3.5, 5.0, 'Main protein made by the liver. Low levels indicate liver disease or malnutrition.'),
  ('uric_acid', 'Uric Acid', 'UA', 'Metabolic Panel', 'mg/dL', 3.4, 7.0, 'Breakdown product of purines. Elevated levels can cause gout and kidney stones.'),
  ('alt', 'Alanine Aminotransferase', 'ALT', 'Liver Function', 'U/L', 7.0, 56.0, 'Liver enzyme. Elevated levels indicate liver damage or inflammation.'),
  ('ast', 'Aspartate Aminotransferase', 'AST', 'Liver Function', 'U/L', 10.0, 40.0, 'Enzyme found in the liver and heart. Elevated levels may indicate liver or heart damage.'),
  ('alp', 'Alkaline Phosphatase', 'ALP', 'Liver Function', 'U/L', 44.0, 147.0, 'Enzyme in the liver and bones. Elevated levels may indicate liver or bone disease.'),
  ('total_bilirubin', 'Total Bilirubin', 'T.Bili', 'Liver Function', 'mg/dL', 0.1, 1.2, 'Breakdown product of red blood cells processed by the liver. High levels cause jaundice.'),
  ('direct_bilirubin', 'Direct Bilirubin', 'D.Bili', 'Liver Function', 'mg/dL', 0.0, 0.3, 'Water-soluble form of bilirubin processed by the liver.'),
  ('total_cholesterol', 'Total Cholesterol', 'CHOL', 'Lipid Panel', 'mg/dL', 0.0, 200.0, 'Total cholesterol in the blood. High levels increase cardiovascular disease risk.'),
  ('hdl', 'HDL Cholesterol', 'HDL', 'Lipid Panel', 'mg/dL', 40.0, 999.0, '''Good'' cholesterol. Higher levels are protective against heart disease.'),
  ('ldl', 'LDL Cholesterol', 'LDL', 'Lipid Panel', 'mg/dL', 0.0, 100.0, '''Bad'' cholesterol. High levels increase risk of heart disease and stroke.'),
  ('triglycerides', 'Triglycerides', 'TG', 'Lipid Panel', 'mg/dL', 0.0, 150.0, 'Type of fat in the blood. High levels increase risk of heart disease and pancreatitis.'),
  ('non_hdl', 'Non-HDL Cholesterol', 'Non-HDL', 'Lipid Panel', 'mg/dL', 0.0, 130.0, 'Total cholesterol minus HDL; includes all ''bad'' cholesterol particles.'),
  ('tsh', 'Thyroid Stimulating Hormone', 'TSH', 'Thyroid', 'mIU/L', 0.4, 4.0, 'Hormone that regulates thyroid function. Elevated TSH suggests hypothyroidism; low TSH suggests hyperthyroidism.'),
  ('free_t4', 'Free T4 (Thyroxine)', 'fT4', 'Thyroid', 'ng/dL', 0.8, 1.8, 'Active form of the main thyroid hormone.'),
  ('free_t3', 'Free T3 (Triiodothyronine)', 'fT3', 'Thyroid', 'pg/mL', 2.3, 4.2, 'The most active thyroid hormone, regulating metabolism.'),
  ('hba1c', 'Hemoglobin A1c', 'HbA1c', 'Diabetes', '%', 0.0, 5.7, '3-month average blood sugar. Used to diagnose and monitor diabetes.'),
  ('fasting_insulin', 'Fasting Insulin', 'Insulin', 'Diabetes', 'µIU/mL', 2.0, 19.6, 'Fasting insulin level; elevated levels may indicate insulin resistance.'),
  ('vitamin_d', 'Vitamin D (25-OH)', 'Vit D', 'Vitamins & Minerals', 'ng/mL', 30.0, 100.0, 'Essential for bone health, immune function, and mood regulation.'),
  ('vitamin_b12', 'Vitamin B12', 'B12', 'Vitamins & Minerals', 'pg/mL', 200.0, 900.0, 'Essential for nerve function and red blood cell formation.'),
  ('folate', 'Folate', 'Folate', 'Vitamins & Minerals', 'ng/mL', 3.1, 17.5, 'B vitamin important for DNA synthesis and cell division.'),
  ('ferritin', 'Ferritin', 'Ferritin', 'Vitamins & Minerals', 'ng/mL', 20.0, 500.0, 'Iron storage protein. Low levels indicate iron deficiency; high may indicate inflammation.'),
  ('serum_iron', 'Serum Iron', 'Fe', 'Vitamins & Minerals', 'µg/dL', 60.0, 170.0, 'Amount of iron in the blood. Used alongside ferritin to evaluate iron status.'),
  ('tibc', 'Total Iron Binding Capacity', 'TIBC', 'Vitamins & Minerals', 'µg/dL', 250.0, 370.0, 'Measure of the blood''s capacity to bind iron. High in iron deficiency.'),
  ('magnesium', 'Magnesium', 'Mg', 'Vitamins & Minerals', 'mg/dL', 1.7, 2.2, 'Mineral important for muscle, nerve, and heart function.'),
  ('zinc', 'Zinc', 'Zn', 'Vitamins & Minerals', 'µg/dL', 60.0, 120.0, 'Mineral essential for immune function, wound healing, and DNA synthesis.'),
  ('testosterone_total', 'Testosterone (Total)', 'Total T', 'Hormones', 'ng/dL', 300.0, 1000.0, 'Primary male sex hormone. Important for muscle, bone, mood, and libido.'),
  ('testosterone_free', 'Testosterone (Free)', 'Free T', 'Hormones', 'pg/mL', 9.0, 30.0, 'Unbound testosterone available for use by the body.'),
  ('estradiol', 'Estradiol', 'E2', 'Hormones', 'pg/mL', 10.0, 40.0, 'Primary female sex hormone. Important for bone density and cardiovascular health in both sexes.'),
  ('cortisol', 'Cortisol (Morning)', 'Cortisol', 'Hormones', 'µg/dL', 6.0, 23.0, 'Stress hormone produced by the adrenal glands. Regulates metabolism and immune response.'),
  ('dhea_s', 'DHEA-S', 'DHEA-S', 'Hormones', 'µg/dL', 80.0, 560.0, 'Adrenal hormone that serves as a precursor to sex hormones.'),
  ('igf1', 'IGF-1', 'IGF-1', 'Hormones', 'ng/mL', 115.0, 355.0, 'Growth hormone marker. Used to evaluate growth hormone deficiency or excess.'),
  ('fsh', 'Follicle Stimulating Hormone', 'FSH', 'Hormones', 'mIU/mL', 1.5, 12.4, 'Hormone regulating reproductive processes and fertility.'),
  ('lh', 'Luteinizing Hormone', 'LH', 'Hormones', 'mIU/mL', 1.7, 8.6, 'Hormone that triggers ovulation in women and testosterone production in men.'),
  ('crp', 'C-Reactive Protein (hs-CRP)', 'hs-CRP', 'Inflammation', 'mg/L', 0.0, 1.0, 'Marker of systemic inflammation. Elevated levels increase cardiovascular disease risk.'),
  ('esr', 'Erythrocyte Sedimentation Rate', 'ESR', 'Inflammation', 'mm/hr', 0.0, 20.0, 'Non-specific marker of inflammation. Elevated in infections, autoimmune disease, and cancer.'),
  ('homocysteine', 'Homocysteine', 'Homocys', 'Inflammation', 'µmol/L', 0.0, 15.0, 'Amino acid linked to cardiovascular disease and vitamin B deficiencies when elevated.'),
  ('psa', 'Prostate-Specific Antigen', 'PSA', 'Cancer Markers', 'ng/mL', 0.0, 4.0, 'Protein produced by the prostate. Elevated levels may indicate prostate cancer or inflammation.')
on conflict (id) do nothing;
