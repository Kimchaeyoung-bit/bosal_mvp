-- =====================================================================
-- 10_storage_realtime : storage buckets + realtime publication
-- =====================================================================

-- ---------------- storage buckets ----------------
insert into storage.buckets (id, name, public)
values
  ('bosal-images', 'bosal-images', true),
  ('banner-ads',   'banner-ads',   true)
on conflict (id) do nothing;

-- Storage RLS: bosal-images
--   public read, authenticated owner write (path prefix = bosal_id)
--   Admin overrides.
drop policy if exists "bosal-images public read" on storage.objects;
create policy "bosal-images public read" on storage.objects
  for select using (bucket_id = 'bosal-images');

drop policy if exists "bosal-images owner write" on storage.objects;
create policy "bosal-images owner write" on storage.objects
  for all
  using (
    bucket_id = 'bosal-images'
    and (
      public.is_admin()
      or public.is_bosal_owner((string_to_array(name, '/'))[1]::uuid)
    )
  )
  with check (
    bucket_id = 'bosal-images'
    and (
      public.is_admin()
      or public.is_bosal_owner((string_to_array(name, '/'))[1]::uuid)
    )
  );

-- Storage RLS: banner-ads (admin only write)
drop policy if exists "banner-ads public read" on storage.objects;
create policy "banner-ads public read" on storage.objects
  for select using (bucket_id = 'banner-ads');

drop policy if exists "banner-ads admin write" on storage.objects;
create policy "banner-ads admin write" on storage.objects
  for all
  using (bucket_id = 'banner-ads' and public.is_admin())
  with check (bucket_id = 'banner-ads' and public.is_admin());

-- ---------------- realtime publication ----------------
-- Enable realtime on reservations for the bosal dashboard live updates.
-- (supabase_realtime publication is created by the platform)
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.reservations;
  end if;
exception when duplicate_object then
  null;
end $$;
