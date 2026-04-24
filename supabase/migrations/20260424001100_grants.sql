-- =====================================================================
-- 11_grants : baseline GRANTs so anon/authenticated roles can hit the API
--   RLS policies still enforce row-level access; these grants only allow
--   the role to attempt the query against the table.
-- =====================================================================

-- usage on public schema
grant usage on schema public to anon, authenticated, service_role;

-- ---------------- anon (public read) ----------------
-- Anon can read published bosals and child rows (RLS filters), plus lookup tables,
-- banner ads, public reviews, AI personas (active), and public_profiles view.
grant select on public.bosals                   to anon;
grant select on public.bosal_images             to anon;
grant select on public.bosal_features           to anon;
grant select on public.bosal_categories         to anon;
grant select on public.operating_hours          to anon;
grant select on public.categories               to anon;
grant select on public.consult_styles           to anon;
grant select on public.ad_intent_tiers          to anon;
grant select on public.regions                  to anon;
grant select on public.sub_regions              to anon;
grant select on public.reviews                  to anon;
grant select on public.banner_ads               to anon;
grant select on public.bosal_ai_personas        to anon;
grant select on public.public_profiles          to anon;
grant select on public.v_bosal_open_now         to anon;

-- ---------------- authenticated (logged-in users) ----------------
grant select on public.bosals                   to authenticated;
grant select on public.bosal_images             to authenticated;
grant select on public.bosal_features           to authenticated;
grant select on public.bosal_categories         to authenticated;
grant select on public.operating_hours          to authenticated;
grant select on public.categories               to authenticated;
grant select on public.consult_styles           to authenticated;
grant select on public.ad_intent_tiers          to authenticated;
grant select on public.regions                  to authenticated;
grant select on public.sub_regions              to authenticated;
grant select on public.reviews                  to authenticated;
grant select on public.banner_ads               to authenticated;
grant select on public.bosal_ai_personas        to authenticated;
grant select on public.public_profiles          to authenticated;
grant select on public.v_bosal_open_now         to authenticated;
grant select on public.v_bosal_call_stats       to authenticated;
grant select on public.v_bosal_reservation_button_stats to authenticated;

-- Profile management
grant select, update on public.profiles         to authenticated;

-- User can read/create/update/delete own rows (RLS enforces scope)
grant select, insert, update on public.reviews          to authenticated;
grant delete                 on public.reviews          to authenticated;
grant select, insert, delete on public.favorites        to authenticated;

-- User can create own reservations (RLS restricts); updates go through RPCs
grant select, insert on public.reservations     to authenticated;

-- User can insert tap events (RLS restricts user_id = auth.uid())
grant insert on public.call_events              to authenticated;
grant insert on public.reservation_button_events to authenticated;

-- ---------------- service_role (server-side, bypasses RLS anyway) ----------------
-- Grant full access to service_role for administrative ops (seed, imports).
grant all on all tables    in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant all on all functions in schema public to service_role;

-- Default privileges so future tables (added via migrations by the platform user)
-- get the correct grants automatically.
alter default privileges in schema public grant select on tables to anon;
alter default privileges in schema public grant select on tables to authenticated;
alter default privileges in schema public grant all    on tables to service_role;
alter default privileges in schema public grant all    on sequences to service_role;
alter default privileges in schema public grant all    on functions to service_role;
