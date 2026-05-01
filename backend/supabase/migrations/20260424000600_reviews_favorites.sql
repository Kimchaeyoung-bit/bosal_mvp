-- =====================================================================
-- 06_reviews_favorites
-- =====================================================================

-- ---------------- reviews ----------------
create table public.reviews (
  id              uuid        primary key default gen_random_uuid(),
  bosal_id        uuid        not null references public.bosals(id)       on delete cascade,
  reservation_id  uuid        unique references public.reservations(id)    on delete set null,
  user_id         uuid        not null references public.profiles(id)      on delete cascade,
  rating          smallint    not null check (rating between 1 and 10),
  body            text,
  is_public       boolean     not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);
create index reviews_bosal_public_idx
  on public.reviews (bosal_id, created_at desc)
  where is_public and deleted_at is null;
create index reviews_user_idx
  on public.reviews (user_id, created_at desc);

create trigger reviews_set_updated_at
  before update on public.reviews
  for each row execute function public.tg_set_updated_at();

-- Guard: only allow review creation if user owns a completed reservation for the bosal
create or replace function public.tg_reviews_enforce_completed_reservation()
returns trigger
language plpgsql
as $$
declare
  has_completed boolean;
begin
  -- Admins bypass the check
  if exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    return new;
  end if;

  if new.reservation_id is not null then
    select exists (
      select 1 from public.reservations
       where id = new.reservation_id
         and user_id = new.user_id
         and bosal_id = new.bosal_id
         and status = 'completed'
    ) into has_completed;
  else
    select exists (
      select 1 from public.reservations
       where user_id = new.user_id
         and bosal_id = new.bosal_id
         and status = 'completed'
    ) into has_completed;
  end if;

  if not has_completed then
    raise exception 'reviews: only users with a completed reservation can review this bosal'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;
create trigger reviews_enforce_completed
  before insert on public.reviews
  for each row execute function public.tg_reviews_enforce_completed_reservation();

-- Maintain bosals.rating_avg, review_count
create or replace function public.tg_reviews_recalc_bosal()
returns trigger
language plpgsql
as $$
declare
  target uuid := coalesce(new.bosal_id, old.bosal_id);
begin
  update public.bosals
     set rating_avg   = coalesce((
           select round(avg(rating)::numeric, 1)
             from public.reviews
            where bosal_id = target
              and is_public and deleted_at is null
         ), 0),
         review_count = (
           select count(*) from public.reviews
            where bosal_id = target
              and is_public and deleted_at is null
         )
   where id = target;
  return coalesce(new, old);
end;
$$;
create trigger reviews_recalc_trigger
  after insert or update or delete on public.reviews
  for each row execute function public.tg_reviews_recalc_bosal();

-- ---------------- favorites (찜) ----------------
create table public.favorites (
  user_id     uuid        not null references public.profiles(id) on delete cascade,
  bosal_id    uuid        not null references public.bosals(id)   on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, bosal_id)
);
create index favorites_bosal_idx on public.favorites (bosal_id, created_at desc);
