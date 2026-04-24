-- =====================================================================
-- 07_invites_banner_ai : bosal invite flow, banner ads, ai personas scaffold
-- =====================================================================

-- ---------------- bosal_invites ----------------
create table public.bosal_invites (
  code        text         primary key,
  bosal_id    uuid         not null references public.bosals(id) on delete cascade,
  email       text,
  used_by     uuid         references public.profiles(id) on delete set null,
  used_at     timestamptz,
  expires_at  timestamptz  not null default (now() + interval '30 days'),
  created_at  timestamptz  not null default now()
);
create index bosal_invites_bosal_idx on public.bosal_invites (bosal_id);
create index bosal_invites_active_idx on public.bosal_invites (expires_at) where used_at is null;

-- ---------------- banner_ads ----------------
create table public.banner_ads (
  id          uuid                 primary key default gen_random_uuid(),
  bosal_id    uuid                 references public.bosals(id) on delete set null,
  title       text                 not null,
  image_url   text                 not null,
  target_url  text,                                  -- null => deep-link to bosal detail
  placement   public.ad_placement  not null default 'home_top',
  weight      int                  not null default 100 check (weight >= 0),
  start_at    timestamptz          not null default now(),
  end_at      timestamptz          not null,
  is_active   boolean              not null default true,
  created_at  timestamptz          not null default now(),
  updated_at  timestamptz          not null default now(),
  check (end_at > start_at)
);
create index banner_ads_active_window_idx
  on public.banner_ads (placement, weight desc, start_at)
  where is_active;

create trigger banner_ads_set_updated_at
  before update on public.banner_ads
  for each row execute function public.tg_set_updated_at();

-- ---------------- bosal_ai_personas (scaffold) ----------------
create table public.bosal_ai_personas (
  bosal_id       uuid         primary key references public.bosals(id) on delete cascade,
  system_prompt  text         not null,
  model          text         not null default 'claude-opus-4-7',
  temperature    numeric(3,2) not null default 0.7 check (temperature between 0 and 2),
  knowledge      jsonb        not null default '{}'::jsonb,
  is_active      boolean      not null default false,
  created_at     timestamptz  not null default now(),
  updated_at     timestamptz  not null default now()
);

create trigger bosal_ai_personas_set_updated_at
  before update on public.bosal_ai_personas
  for each row execute function public.tg_set_updated_at();
