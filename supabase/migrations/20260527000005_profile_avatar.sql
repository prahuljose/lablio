-- ============================================================
-- Lablio – Profile avatar storage
-- Adds avatar columns + a private 'avatars' storage bucket with
-- owner-scoped policies (objects are stored under <user_id>/...).
-- ============================================================

alter table public.profiles
  add column if not exists avatar_url text,
  add column if not exists avatar_path text;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

create policy "storage avatars: owner insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);

create policy "storage avatars: owner select"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);

create policy "storage avatars: owner update"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);

create policy "storage avatars: owner delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);
