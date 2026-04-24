-- =====================================================================
-- 09_rpcs : SECURITY DEFINER RPCs for guarded state transitions
-- =====================================================================

-- ==========================================================
-- claim_bosal_invite(code text) → uuid (the bosal_id now linked)
--   Called by a newly-signed-up user to upgrade to bosal role.
-- ==========================================================
create or replace function public.claim_bosal_invite(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite   public.bosal_invites%rowtype;
  v_uid      uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select * into v_invite from public.bosal_invites where code = p_code for update;
  if not found then
    raise exception 'invalid invite code' using errcode = 'no_data_found';
  end if;
  if v_invite.used_at is not null then
    raise exception 'invite already used' using errcode = 'check_violation';
  end if;
  if v_invite.expires_at < now() then
    raise exception 'invite expired' using errcode = 'check_violation';
  end if;

  update public.profiles
     set role     = 'bosal',
         bosal_id = v_invite.bosal_id
   where id = v_uid;

  update public.bosal_invites
     set used_by = v_uid,
         used_at = now()
   where code = p_code;

  return v_invite.bosal_id;
end;
$$;

revoke all on function public.claim_bosal_invite(text) from public;
grant execute on function public.claim_bosal_invite(text) to authenticated;

-- ==========================================================
-- confirm_reservation(reservation_id uuid, consult_at timestamptz)
--   Bosal owner confirms a pending reservation into `confirmed`.
-- ==========================================================
create or replace function public.confirm_reservation(
  p_reservation_id uuid,
  p_consult_at     timestamptz
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.reservations%rowtype;
begin
  select * into v_row
    from public.reservations
   where id = p_reservation_id
   for update;
  if not found then
    raise exception 'reservation not found' using errcode = 'no_data_found';
  end if;

  if not (public.is_bosal_owner(v_row.bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if v_row.status <> 'pending' then
    raise exception 'only pending reservations can be confirmed' using errcode = 'check_violation';
  end if;

  update public.reservations
     set status     = 'confirmed',
         consult_at = p_consult_at
   where id = p_reservation_id
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.confirm_reservation(uuid, timestamptz) from public;
grant execute on function public.confirm_reservation(uuid, timestamptz) to authenticated;

-- ==========================================================
-- cancel_reservation(reservation_id uuid, reason text)
--   User can cancel own pending reservation. Bosal owner can cancel
--   any reservation for their bosal. Admin cancel anything.
-- ==========================================================
create or replace function public.cancel_reservation(
  p_reservation_id uuid,
  p_reason         text default null
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.reservations%rowtype;
  v_uid uuid := auth.uid();
begin
  select * into v_row
    from public.reservations
   where id = p_reservation_id
   for update;
  if not found then
    raise exception 'reservation not found' using errcode = 'no_data_found';
  end if;

  if public.is_admin() then
    -- ok, proceed
  elsif public.is_bosal_owner(v_row.bosal_id) then
    -- bosal owner: can cancel pending or confirmed
    if v_row.status not in ('pending','confirmed') then
      raise exception 'cannot cancel in current status' using errcode = 'check_violation';
    end if;
  elsif v_row.user_id = v_uid then
    -- user: only pending
    if v_row.status <> 'pending' then
      raise exception 'user may cancel only pending reservations' using errcode = 'check_violation';
    end if;
  else
    raise exception 'not authorized' using errcode = '42501';
  end if;

  update public.reservations
     set status              = 'cancelled',
         cancellation_reason = p_reason
   where id = p_reservation_id
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.cancel_reservation(uuid, text) from public;
grant execute on function public.cancel_reservation(uuid, text) to authenticated;

-- ==========================================================
-- complete_reservation(reservation_id uuid)
--   Bosal owner marks a confirmed reservation as completed.
-- ==========================================================
create or replace function public.complete_reservation(p_reservation_id uuid)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.reservations%rowtype;
begin
  select * into v_row from public.reservations
   where id = p_reservation_id for update;
  if not found then
    raise exception 'reservation not found' using errcode = 'no_data_found';
  end if;

  if not (public.is_bosal_owner(v_row.bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if v_row.status <> 'confirmed' then
    raise exception 'only confirmed reservations can be completed' using errcode = 'check_violation';
  end if;

  update public.reservations set status = 'completed'
   where id = p_reservation_id
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.complete_reservation(uuid) from public;
grant execute on function public.complete_reservation(uuid) to authenticated;

-- ==========================================================
-- reject_reservation(reservation_id uuid, reason text)
--   Alias of cancel by bosal owner with explicit reason; kept separate
--   for clarity in the dashboard UI.
-- ==========================================================
create or replace function public.reject_reservation(
  p_reservation_id uuid,
  p_reason         text default null
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.reservations%rowtype;
begin
  select * into v_row from public.reservations
   where id = p_reservation_id for update;
  if not found then
    raise exception 'reservation not found' using errcode = 'no_data_found';
  end if;

  if not (public.is_bosal_owner(v_row.bosal_id) or public.is_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if v_row.status <> 'pending' then
    raise exception 'only pending reservations can be rejected' using errcode = 'check_violation';
  end if;

  update public.reservations
     set status              = 'cancelled',
         cancellation_reason = coalesce(p_reason, 'rejected_by_bosal')
   where id = p_reservation_id
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.reject_reservation(uuid, text) from public;
grant execute on function public.reject_reservation(uuid, text) to authenticated;
