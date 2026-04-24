-- =====================================================================
-- 04_reservations : consultation bookings (replaces mock `Booking`)
-- =====================================================================

create table public.reservations (
  id                         uuid                       primary key default gen_random_uuid(),
  bosal_id                   uuid                       not null references public.bosals(id) on delete restrict,
  user_id                    uuid                       not null references public.profiles(id) on delete cascade,

  channel                    public.consult_channel     not null default 'in_person',
  requested_at               timestamptz                not null default now(),
  consult_at                 timestamptz,                          -- null until confirmed slot
  duration_min               int                        not null default 60 check (duration_min > 0),

  status                     public.reservation_status  not null default 'pending',
  cancellation_reason        text,

  price_amount               int                        not null default 0 check (price_amount >= 0),
  price_currency             char(3)                    not null default 'KRW',

  payment_status             public.payment_status      not null default 'unpaid',
  payment_provider           text,
  payment_provider_txn_id    text,

  metadata                   jsonb                      not null default '{}'::jsonb,
  created_at                 timestamptz                not null default now(),
  updated_at                 timestamptz                not null default now(),
  deleted_at                 timestamptz
);

-- Unique partial index: prevent duplicate txn ids (ignoring nulls)
create unique index reservations_payment_txn_unique
  on public.reservations (payment_provider, payment_provider_txn_id)
  where payment_provider_txn_id is not null;

-- Common query paths
create index reservations_bosal_consult_idx
  on public.reservations (bosal_id, consult_at)
  where deleted_at is null;

create index reservations_user_requested_idx
  on public.reservations (user_id, requested_at desc)
  where deleted_at is null;

create index reservations_status_consult_idx
  on public.reservations (status, consult_at)
  where deleted_at is null;

create trigger reservations_set_updated_at
  before update on public.reservations
  for each row execute function public.tg_set_updated_at();

-- Maintain bosals.consult_request_count (count of non-cancelled reservations)
create or replace function public.tg_reservations_count()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.status <> 'cancelled' and new.status <> 'no_show' then
      update public.bosals
         set consult_request_count = consult_request_count + 1
       where id = new.bosal_id;
    end if;
  elsif tg_op = 'UPDATE' then
    -- transitions into/out of counted states
    if (old.status in ('cancelled','no_show') and new.status not in ('cancelled','no_show')) then
      update public.bosals set consult_request_count = consult_request_count + 1
       where id = new.bosal_id;
    elsif (old.status not in ('cancelled','no_show') and new.status in ('cancelled','no_show')) then
      update public.bosals set consult_request_count = greatest(0, consult_request_count - 1)
       where id = new.bosal_id;
    end if;
  elsif tg_op = 'DELETE' then
    if old.status not in ('cancelled','no_show') then
      update public.bosals set consult_request_count = greatest(0, consult_request_count - 1)
       where id = old.bosal_id;
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

create trigger reservations_count_trigger
  after insert or update or delete on public.reservations
  for each row execute function public.tg_reservations_count();
