-- =====================================================================
-- 03_bosals : core entity + child tables (images, features, operating hours, category M:N)
-- =====================================================================

create table public.bosals (
  id                          uuid                     primary key default gen_random_uuid(),
  slug                        citext                   unique,

  -- identity
  name                        text                     not null,
  one_liner                   text,                                       -- 줄 소개
  description                 text,                                       -- 상세 소개

  -- professional
  experience_years            int                      not null default 0 check (experience_years >= 0),
  consult_style_id            uuid                     references public.consult_styles(id),

  -- contact
  phone_e164                  text,                                       -- +821012345678
  phone_display               text,                                       -- 010-1234-5678

  -- pricing (KRW)
  original_price              int                      not null default 0 check (original_price >= 0),
  discounted_price            int                      not null default 0 check (discounted_price >= 0),
  first_visit_price           int                      not null default 0 check (first_visit_price >= 0),
  max_points                  int                      not null default 0 check (max_points >= 0),
  discount_percent            int                      generated always as (
                                case
                                  when original_price > 0
                                    then greatest(0, (original_price - discounted_price) * 100 / original_price)
                                  else 0
                                end
                              ) stored,

  -- address (structured)
  sido                        text,
  sigungu                     text,
  eupmyeondong                text,
  road_address                text,
  jibun_address               text,
  postal_code                 text,
  region_id                   uuid                     references public.regions(id),
  sub_region_id               uuid                     references public.sub_regions(id),
  location                    geography(Point, 4326),

  -- advertising pipeline
  ad_intent_tier_id           uuid                     references public.ad_intent_tiers(id),

  -- denormalized aggregates (trigger-maintained)
  rating_avg                  numeric(3,1)             not null default 0,
  review_count                int                      not null default 0,
  qna_count                   int                      not null default 0,
  call_count                  int                      not null default 0,
  reservation_button_count    int                      not null default 0,
  consult_request_count       int                      not null default 0,

  -- publish gate
  is_published                boolean                  not null default false,

  -- extension / audit
  metadata                    jsonb                    not null default '{}'::jsonb,
  created_at                  timestamptz              not null default now(),
  updated_at                  timestamptz              not null default now(),
  deleted_at                  timestamptz,

  constraint bosals_phone_e164_format
    check (phone_e164 is null or phone_e164 ~ '^\+?[0-9]{8,15}$')
);

-- Back-link profiles.bosal_id → bosals.id now that bosals exists
alter table public.profiles
  add constraint profiles_bosal_id_fkey
  foreign key (bosal_id) references public.bosals(id) on delete set null;

-- Indexes
create index bosals_location_gix
  on public.bosals using gist (location)
  where is_published and deleted_at is null;

create index bosals_search_gin
  on public.bosals using gin (
    to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(one_liner,'') || ' ' || coalesce(description,''))
  )
  where is_published and deleted_at is null;

create index bosals_region_idx
  on public.bosals (region_id, sub_region_id)
  where is_published and deleted_at is null;

create index bosals_rating_desc_idx
  on public.bosals (rating_avg desc)
  where is_published and deleted_at is null;

create index bosals_ad_tier_idx
  on public.bosals (ad_intent_tier_id)
  where deleted_at is null;

create trigger bosals_set_updated_at
  before update on public.bosals
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- bosal_images : 1:N
-- =====================================================================
create table public.bosal_images (
  id          uuid                    primary key default gen_random_uuid(),
  bosal_id    uuid                    not null references public.bosals(id) on delete cascade,
  url         text                    not null,
  kind        public.bosal_image_kind not null default 'profile',
  sort_order  int                     not null default 0,
  alt_text    text,
  created_at  timestamptz             not null default now()
);
create index bosal_images_bosal_idx on public.bosal_images (bosal_id, sort_order);

-- =====================================================================
-- bosal_features : 1:N ("특징")
-- =====================================================================
create table public.bosal_features (
  id          uuid         primary key default gen_random_uuid(),
  bosal_id    uuid         not null references public.bosals(id) on delete cascade,
  label       text         not null,
  sort_order  int          not null default 0,
  created_at  timestamptz  not null default now()
);
create index bosal_features_bosal_idx on public.bosal_features (bosal_id, sort_order);

-- =====================================================================
-- bosal_categories : M:N
-- =====================================================================
create table public.bosal_categories (
  bosal_id     uuid not null references public.bosals(id)     on delete cascade,
  category_id  uuid not null references public.categories(id) on delete restrict,
  created_at   timestamptz not null default now(),
  primary key (bosal_id, category_id)
);
create index bosal_categories_category_idx on public.bosal_categories (category_id, bosal_id);

-- =====================================================================
-- operating_hours : 1:N (요일별 운영 시간)
--   weekday: 0=Sunday .. 6=Saturday (Postgres isodow-ish but we use 0-6 for day-of-week)
-- =====================================================================
create table public.operating_hours (
  id           uuid         primary key default gen_random_uuid(),
  bosal_id     uuid         not null references public.bosals(id) on delete cascade,
  weekday      smallint     not null check (weekday between 0 and 6),
  opens_at     time,
  closes_at    time,
  break_start  time,
  break_end    time,
  note         text,
  created_at   timestamptz  not null default now(),
  updated_at   timestamptz  not null default now(),
  unique (bosal_id, weekday),
  constraint operating_hours_opens_closes_paired
    check ((opens_at is null and closes_at is null) or
           (opens_at is not null and closes_at is not null)),
  constraint operating_hours_break_paired
    check ((break_start is null and break_end is null) or
           (break_start is not null and break_end is not null))
);
create index operating_hours_bosal_idx on public.operating_hours (bosal_id, weekday);

create trigger operating_hours_set_updated_at
  before update on public.operating_hours
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- v_bosal_open_now : helper view for "지금 영업중" filter (KST)
--   Handles overnight spans (closes_at < opens_at) as next-day close.
--   Ignores breaks for simplicity (can refine later).
-- =====================================================================
create or replace view public.v_bosal_open_now as
with now_kst as (
  select
    (now() at time zone 'Asia/Seoul')::date        as today_kst,
    extract(dow from (now() at time zone 'Asia/Seoul'))::smallint as today_weekday,
    (now() at time zone 'Asia/Seoul')::time        as now_time
)
select
  b.id as bosal_id,
  exists (
    select 1
      from public.operating_hours oh, now_kst n
     where oh.bosal_id = b.id
       and oh.opens_at is not null
       and oh.closes_at is not null
       and (
         -- same-day hours (opens < closes)
         (oh.weekday = n.today_weekday
           and oh.opens_at <= oh.closes_at
           and n.now_time between oh.opens_at and oh.closes_at)
         or
         -- overnight hours (opens > closes): today evening OR yesterday's spill into today
         (oh.weekday = n.today_weekday
           and oh.opens_at > oh.closes_at
           and n.now_time >= oh.opens_at)
         or
         (oh.weekday = ((n.today_weekday + 6) % 7)::smallint
           and oh.opens_at > oh.closes_at
           and n.now_time <= oh.closes_at)
       )
  ) as is_open
from public.bosals b
where b.deleted_at is null;
