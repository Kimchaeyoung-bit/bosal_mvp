-- =====================================================================
-- 00_init : extensions, enums, shared trigger helpers
-- =====================================================================

create extension if not exists "pgcrypto";
create extension if not exists "postgis";
create extension if not exists "pg_trgm";
create extension if not exists "citext";

-- --------------- enums ---------------
do $$ begin
  create type public.user_role as enum ('user','bosal','admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.reservation_status as enum ('pending','confirmed','completed','cancelled','no_show');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.payment_status as enum ('unpaid','authorized','captured','refunded','failed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.consult_channel as enum ('in_person','phone','video','chat');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.bosal_image_kind as enum ('profile','portfolio','cert');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.ad_placement as enum ('home_top','home_mid','detail_bottom');
exception when duplicate_object then null; end $$;

-- --------------- shared trigger: updated_at ---------------
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Auth helper functions (is_admin, is_bosal_owner) are defined in a later
-- migration after the profiles table is created, since SQL-language
-- functions resolve table references at CREATE time.
