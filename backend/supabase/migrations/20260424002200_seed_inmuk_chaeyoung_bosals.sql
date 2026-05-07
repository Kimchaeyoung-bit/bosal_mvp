-- =====================================================================
-- 22_seed_inmuk_chaeyoung_bosals : 실 운영 보살 2명 + 로그인 계정 시드
--
--   1. 인묵보살 (전통/사업운 특화)  inmuk@bosal.test     / bosal1234
--   2. 채영보살 (현대/연애운 특화)  chaeyoung@bosal.test / bosal1234
--
--   * auth.users + auth.identities (이메일/비번)
--   * profiles 자동 생성 (tg_handle_new_user 트리거) → role=bosal, bosal_id 연결
--   * bosals + features + categories + operating_hours
--
--   phone_e164 / email 기준 idempotent. 재실행 시 중복 insert 방지.
--   비밀번호는 평문 'bosal1234' → bcrypt 해시 (extension pgcrypto 필요).
--   ⚠️  데모/dev 용도. production 배포 전 비번 회전 또는 이 마이그레이션 분리.
-- =====================================================================

-- pgcrypto는 Supabase 에 기본 활성화되어 있지만 안전을 위해 명시
create extension if not exists pgcrypto;

do $$
declare
  -- bosal entity ids
  v_inmuk_bosal_id      uuid;
  v_chaeyoung_bosal_id  uuid;

  -- auth.users ids
  v_inmuk_user_id       uuid;
  v_chaeyoung_user_id   uuid;

  -- lookup IDs
  v_seoul_region        uuid;
  v_nonhyeon            uuid;
  v_gangnam             uuid;
  v_cool                uuid;
  v_empathetic          uuid;
  v_interested          uuid;
  v_none_tier           uuid;

  v_business            uuid;
  v_wealth              uuid;
  v_love                uuid;
  v_tarot               uuid;
  v_career              uuid;

  v_just_inserted       boolean;

  -- 비밀번호 해시 (마이그레이션 1회 계산)
  v_password_hash       text := crypt('bosal1234', gen_salt('bf'));
begin
  -- ---------- lookup 매핑 ----------
  select id into v_seoul_region from public.regions where code = 'seoul';
  select id into v_nonhyeon
    from public.sub_regions where code = 'nonhyeon' and region_id = v_seoul_region;
  select id into v_gangnam
    from public.sub_regions where code = 'gangnam' and region_id = v_seoul_region;
  select id into v_cool from public.consult_styles where code = 'cool';
  select id into v_empathetic from public.consult_styles where code = 'empathetic';
  select id into v_interested from public.ad_intent_tiers where code = 'interested';
  select id into v_none_tier from public.ad_intent_tiers where code = 'none';

  select id into v_business from public.categories where code = 'business';
  select id into v_wealth   from public.categories where code = 'wealth';
  select id into v_love     from public.categories where code = 'love';
  select id into v_tarot    from public.categories where code = 'tarot';
  select id into v_career   from public.categories where code = 'career';

  -- ============================================================
  -- 1) 인묵보살 — auth.users + bosals
  -- ============================================================

  -- (1-1) auth.users
  select id into v_inmuk_user_id from auth.users where email = 'inmuk@bosal.test';
  if v_inmuk_user_id is null then
    v_inmuk_user_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v_inmuk_user_id,
      'authenticated', 'authenticated',
      'inmuk@bosal.test',
      v_password_hash,
      now(), now(), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object('display_name', '인묵보살'),
      '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(),
      v_inmuk_user_id,
      v_inmuk_user_id::text,
      jsonb_build_object('sub', v_inmuk_user_id::text, 'email', 'inmuk@bosal.test'),
      'email',
      now(), now(), now()
    );
  end if;

  -- (1-2) bosals
  select id into v_inmuk_bosal_id from public.bosals where phone_e164 = '+821012345678';
  v_just_inserted := v_inmuk_bosal_id is null;

  if v_just_inserted then
    insert into public.bosals (
      slug, name, one_liner, description,
      experience_years, consult_style_id,
      phone_display, phone_e164,
      original_price, discounted_price, first_visit_price, max_points,
      sido, sigungu, eupmyeondong, road_address,
      region_id, sub_region_id,
      location, ad_intent_tier_id,
      is_published
    ) values (
      'inmuk',
      '인묵보살',
      '막힌 사업운을 뚫어주는 영험한 호랑이의 기운',
      '계룡산 신내림 20년 차 전통 보살. 엽전과 쌀알을 이용한 정통 점사로 금전 흐름과 문서운을 정확하게 짚어냅니다. 전국 무속인 대회 금상 수상, 대기업 임원 및 정계 인사 전담 상담 다수.',
      20, v_cool,
      '010-1234-5678', '+821012345678',
      100000, 70000, 50000, 20000,
      '서울특별시', '강남구', '논현동',
      '서울특별시 강남구 논현로 123길 15, 2층',
      v_seoul_region, v_nonhyeon,
      ST_SetSRID(ST_MakePoint(127.0210, 37.5145), 4326)::geography,
      v_interested,
      true
    ) returning id into v_inmuk_bosal_id;

    insert into public.bosal_features (bosal_id, label, sort_order) values
      (v_inmuk_bosal_id, '엽전·쌀알 전통 점사',  0),
      (v_inmuk_bosal_id, '문서운 정확',          1),
      (v_inmuk_bosal_id, '대기업 임원 상담 다수', 2);

    insert into public.bosal_categories (bosal_id, category_id) values
      (v_inmuk_bosal_id, v_business),
      (v_inmuk_bosal_id, v_wealth);
  end if;

  -- (1-3) profiles 연결: role=bosal, bosal_id=신규
  -- tg_handle_new_user가 auth.users insert 직후 profiles row 자동 생성했으니 update
  update public.profiles
     set role     = 'bosal',
         bosal_id = v_inmuk_bosal_id,
         display_name = '인묵보살'
   where id = v_inmuk_user_id;

  -- (1-4) 운영시간: 일/목 휴무, 그 외 10:00-18:00 (점심 12-13)
  insert into public.operating_hours (bosal_id, weekday, opens_at, closes_at, break_start, break_end) values
    (v_inmuk_bosal_id, 0, NULL,         NULL,         NULL,         NULL),
    (v_inmuk_bosal_id, 1, '10:00:00',   '18:00:00',   '12:00:00',   '13:00:00'),
    (v_inmuk_bosal_id, 2, '10:00:00',   '18:00:00',   '12:00:00',   '13:00:00'),
    (v_inmuk_bosal_id, 3, '10:00:00',   '18:00:00',   '12:00:00',   '13:00:00'),
    (v_inmuk_bosal_id, 4, NULL,         NULL,         NULL,         NULL),
    (v_inmuk_bosal_id, 5, '10:00:00',   '18:00:00',   '12:00:00',   '13:00:00'),
    (v_inmuk_bosal_id, 6, '10:00:00',   '18:00:00',   '12:00:00',   '13:00:00')
  on conflict (bosal_id, weekday) do update set
    opens_at    = excluded.opens_at,
    closes_at   = excluded.closes_at,
    break_start = excluded.break_start,
    break_end   = excluded.break_end;

  -- ============================================================
  -- 2) 채영보살 — auth.users + bosals
  -- ============================================================

  -- (2-1) auth.users
  select id into v_chaeyoung_user_id from auth.users where email = 'chaeyoung@bosal.test';
  if v_chaeyoung_user_id is null then
    v_chaeyoung_user_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v_chaeyoung_user_id,
      'authenticated', 'authenticated',
      'chaeyoung@bosal.test',
      v_password_hash,
      now(), now(), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object('display_name', '채영보살'),
      '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(),
      v_chaeyoung_user_id,
      v_chaeyoung_user_id::text,
      jsonb_build_object('sub', v_chaeyoung_user_id::text, 'email', 'chaeyoung@bosal.test'),
      'email',
      now(), now(), now()
    );
  end if;

  -- (2-2) bosals
  select id into v_chaeyoung_bosal_id from public.bosals where phone_e164 = '+821098765432';
  v_just_inserted := v_chaeyoung_bosal_id is null;

  if v_just_inserted then
    insert into public.bosals (
      slug, name, one_liner, description,
      experience_years, consult_style_id,
      phone_display, phone_e164,
      original_price, discounted_price, first_visit_price, max_points,
      sido, sigungu, eupmyeondong, road_address,
      region_id, sub_region_id,
      location, ad_intent_tier_id,
      is_published
    ) values (
      'chaeyoung',
      '채영보살',
      '당신의 마음을 읽어주는 따뜻한 위로와 명쾌한 해답',
      'MZ세대 대표 보살. 신점과 함께 타로 카드를 보조 도구로 사용해 깊은 심리 분석이 가능합니다. 심리상담사 2급 자격 보유, 유튜브 ''채영의 신점TV'' 채널 운영 중.',
      5, v_empathetic,
      '010-9876-5432', '+821098765432',
      80000, 55000, 40000, 15000,
      '서울특별시', '강남구', '역삼동',
      '서울특별시 강남구 테헤란로 45길 8, 402호',
      v_seoul_region, v_gangnam,
      ST_SetSRID(ST_MakePoint(127.0276, 37.4979), 4326)::geography,
      v_none_tier,
      true
    ) returning id into v_chaeyoung_bosal_id;

    insert into public.bosal_features (bosal_id, label, sort_order) values
      (v_chaeyoung_bosal_id, '타로 보조 활용',       0),
      (v_chaeyoung_bosal_id, '심리상담사 2급 자격', 1),
      (v_chaeyoung_bosal_id, 'MZ세대 특화',          2),
      (v_chaeyoung_bosal_id, '유튜브 채널 운영',    3);

    insert into public.bosal_categories (bosal_id, category_id) values
      (v_chaeyoung_bosal_id, v_love),
      (v_chaeyoung_bosal_id, v_tarot),
      (v_chaeyoung_bosal_id, v_career);
  end if;

  -- (2-3) profiles 연결
  update public.profiles
     set role     = 'bosal',
         bosal_id = v_chaeyoung_bosal_id,
         display_name = '채영보살'
   where id = v_chaeyoung_user_id;

  -- (2-4) 운영시간: 월/토 휴무, 그 외 13:00-22:00 (야간, break 없음)
  insert into public.operating_hours (bosal_id, weekday, opens_at, closes_at, break_start, break_end) values
    (v_chaeyoung_bosal_id, 0, '13:00:00', '22:00:00', NULL, NULL),
    (v_chaeyoung_bosal_id, 1, NULL,        NULL,        NULL, NULL),
    (v_chaeyoung_bosal_id, 2, '13:00:00', '22:00:00', NULL, NULL),
    (v_chaeyoung_bosal_id, 3, '13:00:00', '22:00:00', NULL, NULL),
    (v_chaeyoung_bosal_id, 4, '13:00:00', '22:00:00', NULL, NULL),
    (v_chaeyoung_bosal_id, 5, '13:00:00', '22:00:00', NULL, NULL),
    (v_chaeyoung_bosal_id, 6, NULL,        NULL,        NULL, NULL)
  on conflict (bosal_id, weekday) do update set
    opens_at    = excluded.opens_at,
    closes_at   = excluded.closes_at,
    break_start = excluded.break_start,
    break_end   = excluded.break_end;

  raise notice 'demo bosals seeded: inmuk(user=%, bosal=%) chaeyoung(user=%, bosal=%)',
    v_inmuk_user_id, v_inmuk_bosal_id, v_chaeyoung_user_id, v_chaeyoung_bosal_id;
end$$;
