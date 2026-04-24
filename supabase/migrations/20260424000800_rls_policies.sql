-- =====================================================================
-- 08_rls_policies : enable RLS + policies for every public.* table
--   Fail-closed: every table gets `enable row level security`; every access
--   is explicit. Admins bypass via is_admin() helper.
-- =====================================================================

-- ==========================================================
-- profiles
-- ==========================================================
alter table public.profiles enable row level security;

drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin on public.profiles
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_update_self_safe on public.profiles;
create policy profiles_update_self_safe on public.profiles
  for update
  using (id = auth.uid())
  with check (
    id = auth.uid()
    -- Sensitive columns (role, bosal_id) cannot be changed directly;
    -- must go through SECURITY DEFINER RPCs (claim_bosal_invite, etc.).
    and role     = (select role     from public.profiles p2 where p2.id = auth.uid())
    and bosal_id is not distinct from
        (select bosal_id from public.profiles p2 where p2.id = auth.uid())
  );

drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles
  for all using (public.is_admin()) with check (public.is_admin());

-- public_profiles view inherits profiles' RLS, so we expose a simple SECURITY DEFINER wrapper
grant select on public.public_profiles to anon, authenticated;

-- ==========================================================
-- lookup tables: public read, admin write
-- ==========================================================
alter table public.categories       enable row level security;
alter table public.consult_styles   enable row level security;
alter table public.ad_intent_tiers  enable row level security;
alter table public.regions          enable row level security;
alter table public.sub_regions      enable row level security;

do $$
declare tbl text;
begin
  foreach tbl in array array['categories','consult_styles','ad_intent_tiers','regions','sub_regions'] loop
    execute format($f$
      drop policy if exists %1$I_select_public on public.%1$I;
      create policy %1$I_select_public on public.%1$I for select using (true);
      drop policy if exists %1$I_admin_all on public.%1$I;
      create policy %1$I_admin_all on public.%1$I for all using (public.is_admin()) with check (public.is_admin());
    $f$, tbl);
  end loop;
end $$;

-- ==========================================================
-- bosals + child tables
-- ==========================================================
alter table public.bosals             enable row level security;
alter table public.bosal_images       enable row level security;
alter table public.bosal_features     enable row level security;
alter table public.bosal_categories   enable row level security;
alter table public.operating_hours    enable row level security;

-- bosals: public sees only published + not soft-deleted; owner/admin see theirs
drop policy if exists bosals_select_public on public.bosals;
create policy bosals_select_public on public.bosals
  for select using (
    (is_published and deleted_at is null)
    or public.is_bosal_owner(id)
    or public.is_admin()
  );

drop policy if exists bosals_insert_admin on public.bosals;
create policy bosals_insert_admin on public.bosals
  for insert with check (public.is_admin());

drop policy if exists bosals_update_owner_or_admin on public.bosals;
create policy bosals_update_owner_or_admin on public.bosals
  for update
  using (public.is_bosal_owner(id) or public.is_admin())
  with check (public.is_bosal_owner(id) or public.is_admin());

drop policy if exists bosals_delete_admin on public.bosals;
create policy bosals_delete_admin on public.bosals
  for delete using (public.is_admin());

-- Child tables: mirror bosal visibility
do $$
declare tbl text;
begin
  foreach tbl in array array['bosal_images','bosal_features','operating_hours'] loop
    execute format($f$
      drop policy if exists %1$I_select_public on public.%1$I;
      create policy %1$I_select_public on public.%1$I for select using (
        exists (
          select 1 from public.bosals b
           where b.id = %1$I.bosal_id
             and ((b.is_published and b.deleted_at is null)
                   or public.is_bosal_owner(b.id)
                   or public.is_admin())
        )
      );
      drop policy if exists %1$I_owner_write on public.%1$I;
      create policy %1$I_owner_write on public.%1$I
        for all
        using (public.is_bosal_owner(%1$I.bosal_id) or public.is_admin())
        with check (public.is_bosal_owner(%1$I.bosal_id) or public.is_admin());
    $f$, tbl);
  end loop;
end $$;

-- bosal_categories: mirror + special (unpublished bosal's categories hidden too)
drop policy if exists bosal_categories_select_public on public.bosal_categories;
create policy bosal_categories_select_public on public.bosal_categories
  for select using (
    exists (
      select 1 from public.bosals b
       where b.id = bosal_categories.bosal_id
         and ((b.is_published and b.deleted_at is null)
               or public.is_bosal_owner(b.id)
               or public.is_admin())
    )
  );
drop policy if exists bosal_categories_owner_write on public.bosal_categories;
create policy bosal_categories_owner_write on public.bosal_categories
  for all
  using (public.is_bosal_owner(bosal_categories.bosal_id) or public.is_admin())
  with check (public.is_bosal_owner(bosal_categories.bosal_id) or public.is_admin());

-- ==========================================================
-- reservations
-- ==========================================================
alter table public.reservations enable row level security;

drop policy if exists reservations_select_scoped on public.reservations;
create policy reservations_select_scoped on public.reservations
  for select using (
    user_id = auth.uid()
    or public.is_bosal_owner(reservations.bosal_id)
    or public.is_admin()
  );

-- User can create own pending reservations only
drop policy if exists reservations_insert_self on public.reservations;
create policy reservations_insert_self on public.reservations
  for insert with check (
    user_id = auth.uid()
    and status = 'pending'
    and payment_status = 'unpaid'
  );

-- Direct UPDATE: deny all except admin.
-- Status transitions happen through SECURITY DEFINER RPCs in a later migration.
drop policy if exists reservations_update_admin on public.reservations;
create policy reservations_update_admin on public.reservations
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists reservations_delete_admin on public.reservations;
create policy reservations_delete_admin on public.reservations
  for delete using (public.is_admin());

-- ==========================================================
-- events (call, reservation_button)
-- ==========================================================
alter table public.call_events                 enable row level security;
alter table public.reservation_button_events   enable row level security;

do $$
declare tbl text;
begin
  foreach tbl in array array['call_events','reservation_button_events'] loop
    execute format($f$
      drop policy if exists %1$I_insert_auth on public.%1$I;
      create policy %1$I_insert_auth on public.%1$I
        for insert with check (
          auth.uid() is not null and user_id = auth.uid()
        );
      drop policy if exists %1$I_select_admin on public.%1$I;
      create policy %1$I_select_admin on public.%1$I
        for select using (public.is_admin());
    $f$, tbl);
  end loop;
end $$;

-- Grant owners read access to the aggregate views only
grant select on public.v_bosal_call_stats to authenticated;
grant select on public.v_bosal_reservation_button_stats to authenticated;

-- ==========================================================
-- reviews
-- ==========================================================
alter table public.reviews enable row level security;

drop policy if exists reviews_select_public on public.reviews;
create policy reviews_select_public on public.reviews
  for select using (
    (is_public and deleted_at is null)
    or user_id = auth.uid()
    or public.is_bosal_owner(reviews.bosal_id)
    or public.is_admin()
  );

drop policy if exists reviews_insert_self on public.reviews;
create policy reviews_insert_self on public.reviews
  for insert with check (user_id = auth.uid());

drop policy if exists reviews_update_self_or_admin on public.reviews;
create policy reviews_update_self_or_admin on public.reviews
  for update
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

drop policy if exists reviews_delete_self_or_admin on public.reviews;
create policy reviews_delete_self_or_admin on public.reviews
  for delete using (user_id = auth.uid() or public.is_admin());

-- ==========================================================
-- favorites
-- ==========================================================
alter table public.favorites enable row level security;

drop policy if exists favorites_all_self on public.favorites;
create policy favorites_all_self on public.favorites
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists favorites_select_admin on public.favorites;
create policy favorites_select_admin on public.favorites
  for select using (public.is_admin());

-- ==========================================================
-- bosal_invites
-- ==========================================================
alter table public.bosal_invites enable row level security;

drop policy if exists bosal_invites_admin_all on public.bosal_invites;
create policy bosal_invites_admin_all on public.bosal_invites
  for all using (public.is_admin()) with check (public.is_admin());
-- Note: redemption goes through SECURITY DEFINER RPC; direct select by
-- the user is not needed (RPC looks up the code server-side).

-- ==========================================================
-- banner_ads
-- ==========================================================
alter table public.banner_ads enable row level security;

drop policy if exists banner_ads_select_active on public.banner_ads;
create policy banner_ads_select_active on public.banner_ads
  for select using (
    is_active and now() between start_at and end_at
    or public.is_admin()
  );

drop policy if exists banner_ads_admin_write on public.banner_ads;
create policy banner_ads_admin_write on public.banner_ads
  for all using (public.is_admin()) with check (public.is_admin());

-- ==========================================================
-- bosal_ai_personas
-- ==========================================================
alter table public.bosal_ai_personas enable row level security;

drop policy if exists bosal_ai_personas_select_active on public.bosal_ai_personas;
create policy bosal_ai_personas_select_active on public.bosal_ai_personas
  for select using (
    is_active
    or public.is_bosal_owner(bosal_ai_personas.bosal_id)
    or public.is_admin()
  );

drop policy if exists bosal_ai_personas_owner_write on public.bosal_ai_personas;
create policy bosal_ai_personas_owner_write on public.bosal_ai_personas
  for all
  using (public.is_bosal_owner(bosal_ai_personas.bosal_id) or public.is_admin())
  with check (public.is_bosal_owner(bosal_ai_personas.bosal_id) or public.is_admin());
