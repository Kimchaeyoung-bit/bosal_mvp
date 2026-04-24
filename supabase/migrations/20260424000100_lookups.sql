-- =====================================================================
-- 01_lookups : admin-managed lookup tables
--   categories, consult_styles, ad_intent_tiers, regions, sub_regions
-- =====================================================================

-- --------------- categories (연애/직장/재물/...) ---------------
create table public.categories (
  id          uuid         primary key default gen_random_uuid(),
  code        citext       not null unique,          -- 'love', 'career', ...
  name        text         not null,                 -- '연애'
  icon_key    text,                                   -- 'favorite_rounded' (client-mapped)
  sort_order  int          not null default 0,
  is_active   boolean      not null default true,
  created_at  timestamptz  not null default now(),
  updated_at  timestamptz  not null default now()
);
create index categories_active_order_idx
  on public.categories (sort_order)
  where is_active;

create trigger categories_set_updated_at
  before update on public.categories
  for each row execute function public.tg_set_updated_at();

-- --------------- consult_styles (냉철형/공감형/직설형) ---------------
create table public.consult_styles (
  id          uuid         primary key default gen_random_uuid(),
  code        citext       not null unique,          -- 'cool'
  label       text         not null,                 -- '냉철형'
  sort_order  int          not null default 0,
  is_active   boolean      not null default true,
  created_at  timestamptz  not null default now(),
  updated_at  timestamptz  not null default now()
);
create index consult_styles_active_order_idx
  on public.consult_styles (sort_order)
  where is_active;

create trigger consult_styles_set_updated_at
  before update on public.consult_styles
  for each row execute function public.tg_set_updated_at();

-- --------------- ad_intent_tiers (광고 의향 단계) ---------------
create table public.ad_intent_tiers (
  id          uuid         primary key default gen_random_uuid(),
  code        citext       not null unique,          -- 'none','interested','active_campaign'
  label       text         not null,                 -- '관심 없음'
  description text,
  sort_order  int          not null default 0,
  is_active   boolean      not null default true,
  created_at  timestamptz  not null default now(),
  updated_at  timestamptz  not null default now()
);
create index ad_intent_tiers_active_order_idx
  on public.ad_intent_tiers (sort_order)
  where is_active;

create trigger ad_intent_tiers_set_updated_at
  before update on public.ad_intent_tiers
  for each row execute function public.tg_set_updated_at();

-- --------------- regions (17 시도) ---------------
create table public.regions (
  id          uuid         primary key default gen_random_uuid(),
  code        citext       not null unique,          -- 'seoul'
  name        text         not null,                 -- '서울'
  sort_order  int          not null default 0,
  created_at  timestamptz  not null default now(),
  updated_at  timestamptz  not null default now()
);
create index regions_sort_idx on public.regions (sort_order);

create trigger regions_set_updated_at
  before update on public.regions
  for each row execute function public.tg_set_updated_at();

-- --------------- sub_regions (구/군) ---------------
create table public.sub_regions (
  id          uuid         primary key default gen_random_uuid(),
  region_id   uuid         not null references public.regions(id) on delete cascade,
  code        citext       not null,                 -- 'gangnam'
  name        text         not null,                 -- '강남구'
  sort_order  int          not null default 0,
  created_at  timestamptz  not null default now(),
  updated_at  timestamptz  not null default now(),
  unique (region_id, code)
);
create index sub_regions_region_idx on public.sub_regions (region_id, sort_order);

create trigger sub_regions_set_updated_at
  before update on public.sub_regions
  for each row execute function public.tg_set_updated_at();
