-- =====================================================================
-- 02_profiles : public profile extending auth.users
--   (bosals FK is added in a later migration; kept nullable uuid here)
-- =====================================================================

create table public.profiles (
  id              uuid                   primary key references auth.users(id) on delete cascade,
  role            public.user_role       not null default 'user',
  display_name    text                   not null,
  phone           text,
  avatar_url      text,
  bosal_id        uuid,                  -- FK to public.bosals added in later migration
  metadata        jsonb                  not null default '{}'::jsonb,
  created_at      timestamptz            not null default now(),
  updated_at      timestamptz            not null default now(),
  deleted_at      timestamptz
);

create index profiles_role_nonuser_idx
  on public.profiles (role)
  where role <> 'user';

create index profiles_bosal_id_idx
  on public.profiles (bosal_id)
  where bosal_id is not null;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.tg_set_updated_at();

-- Auto-create profile on new auth.users insert
create or replace function public.tg_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, display_name)
  values (
    new.id,
    'user',
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      split_part(new.email, '@', 1),
      '사용자'
    )
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.tg_handle_new_user();

-- Public-safe slice of profiles for review attribution etc.
create or replace view public.public_profiles as
  select id, display_name, avatar_url
  from public.profiles
  where deleted_at is null;

-- --------------- auth helper functions (now that profiles exists) ---------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role = 'admin' from public.profiles where id = auth.uid()),
    false
  );
$$;

create or replace function public.is_bosal_owner(target_bosal_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select bosal_id = target_bosal_id
       from public.profiles
      where id = auth.uid()),
    false
  );
$$;
