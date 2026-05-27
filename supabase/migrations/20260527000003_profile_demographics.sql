-- ============================================================
-- Lablio – Profile demographics
-- Adds date of birth, sex, height, weight, and blood type to
-- the profiles table and threads them through the sign-up
-- trigger (values arrive via auth user metadata).
-- ============================================================

alter table public.profiles
  add column if not exists date_of_birth date,
  add column if not exists sex text check (sex in ('male', 'female', 'other')),
  add column if not exists height_cm numeric,
  add column if not exists weight_kg numeric,
  add column if not exists blood_type text;

-- Trigger now copies the extra demographics from raw_user_meta_data.
-- Kept SECURITY DEFINER so the auth admin role can insert the profile row.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, date_of_birth, sex, height_cm, weight_kg, blood_type)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    nullif(new.raw_user_meta_data ->> 'date_of_birth', '')::date,
    nullif(new.raw_user_meta_data ->> 'sex', ''),
    nullif(new.raw_user_meta_data ->> 'height_cm', '')::numeric,
    nullif(new.raw_user_meta_data ->> 'weight_kg', '')::numeric,
    nullif(new.raw_user_meta_data ->> 'blood_type', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
