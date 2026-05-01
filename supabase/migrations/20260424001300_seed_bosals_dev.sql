-- =====================================================================
-- 13_seed_bosals_dev : seed 7 sample bosals from mock_bosals.dart
--   Idempotent (on conflict do nothing). Dev/QA 전용 샘플이며,
--   프로덕션에서는 관리자 대시보드로 실데이터 입력 예정.
-- =====================================================================

-- Helper: lookup consult_style_id by label (냉철형/공감형/직설형)
-- Helper: lookup region_id by code ('seoul')
-- Helper: lookup sub_region_id by code

do $$
declare
  v_style_cool        uuid := (select id from public.consult_styles where code = 'cool');
  v_style_empathetic  uuid := (select id from public.consult_styles where code = 'empathetic');
  v_style_direct      uuid := (select id from public.consult_styles where code = 'direct');

  v_region_seoul      uuid := (select id from public.regions where code = 'seoul');

  v_sub_gangnam       uuid := (select id from public.sub_regions where code = 'gangnam');
  v_sub_seolleung     uuid := (select id from public.sub_regions where code = 'seolleung');
  v_sub_cheongdam     uuid := (select id from public.sub_regions where code = 'cheongdam');
  v_sub_hongdae       uuid := (select id from public.sub_regions where code = 'hongdae');
  v_sub_seocho        uuid := (select id from public.sub_regions where code = 'seocho');
  v_sub_nonhyeon      uuid := (select id from public.sub_regions where code = 'nonhyeon');
  v_sub_jamsil        uuid := (select id from public.sub_regions where code = 'jamsil');

  v_cat_all           uuid := (select id from public.categories where code = 'all');
  v_cat_love          uuid := (select id from public.categories where code = 'love');
  v_cat_career        uuid := (select id from public.categories where code = 'career');
  v_cat_wealth        uuid := (select id from public.categories where code = 'wealth');
  v_cat_health        uuid := (select id from public.categories where code = 'health');
  v_cat_relationship  uuid := (select id from public.categories where code = 'relationship');
  v_cat_tarot         uuid := (select id from public.categories where code = 'tarot');

  bosal_rec record;
begin
  ---------------------------------------------------------------
  -- bosals (fixed UUIDs so re-runs stay idempotent)
  ---------------------------------------------------------------
  insert into public.bosals (
    id, slug, name, description, experience_years, consult_style_id,
    phone_e164, phone_display,
    original_price, discounted_price, first_visit_price, max_points,
    sido, sigungu, eupmyeondong, region_id, sub_region_id,
    location, is_published
  ) values
    -- 1. 가가 보살
    ('00000000-0000-0000-0000-000000000001', 'gaga',   '가가 보살',   '마음의 길을 밝혀드립니다', 12, v_style_cool,
     '+821012345678', '010-1234-5678',
     88000, 55000, 40000, 16000,
     '서울특별시', '강남구', '역삼동', v_region_seoul, v_sub_gangnam,
     ST_SetSRID(ST_MakePoint(127.0276, 37.4979), 4326)::geography, true),
    -- 2. 나나 보살
    ('00000000-0000-0000-0000-000000000002', 'nana',   '나나 보살',   '당신의 가능성을 함께 찾아드려요', 8, v_style_empathetic,
     '+821023456789', '010-2345-6789',
     75000, 50000, 35000, 12000,
     '서울특별시', '강남구', '삼성동', v_region_seoul, v_sub_seolleung,
     ST_SetSRID(ST_MakePoint(127.0490, 37.5045), 4326)::geography, true),
    -- 3. 다다 보살
    ('00000000-0000-0000-0000-000000000003', 'dada',   '다다 보살',   '돈의 흐름을 읽어드립니다', 15, v_style_direct,
     '+821034567890', '010-3456-7890',
     100000, 70000, 50000, 20000,
     '서울특별시', '강남구', '청담동', v_region_seoul, v_sub_cheongdam,
     ST_SetSRID(ST_MakePoint(127.0470, 37.5196), 4326)::geography, true),
    -- 4. 라라 보살
    ('00000000-0000-0000-0000-000000000004', 'rara',   '라라 보살',   '사랑의 방향을 알려드려요', 6, v_style_empathetic,
     '+821045678901', '010-4567-8901',
     65000, 45000, 30000, 10000,
     '서울특별시', '마포구', '서교동', v_region_seoul, v_sub_hongdae,
     ST_SetSRID(ST_MakePoint(126.9236, 37.5563), 4326)::geography, true),
    -- 5. 마마 보살
    ('00000000-0000-0000-0000-000000000005', 'mama',   '마마 보살',   '가족의 평화를 되찾아드려요', 20, v_style_empathetic,
     '+821056789012', '010-5678-9012',
     80000, 55000, 40000, 15000,
     '서울특별시', '서초구', '서초동', v_region_seoul, v_sub_seocho,
     ST_SetSRID(ST_MakePoint(127.0324, 37.4837), 4326)::geography, true),
    -- 6. 달빛 보살

    
    ('00000000-0000-0000-0000-000000000006', 'moonlight', '달빛 보살', '마음의 소리를 먼저 들어드립니다', 15, v_style_empathetic,
     '+821067890123', '010-6789-0123',
     70000, 48000, 33000, 11000,
     '서울특별시', '강남구', '논현동', v_region_seoul, v_sub_nonhyeon,
     ST_SetSRID(ST_MakePoint(127.0286, 37.5172), 4326)::geography, true),
    -- 7. 청산 도령
    ('00000000-0000-0000-0000-000000000007', 'cheongsan', '청산 도령', '돌려 말하지 않습니다', 22, v_style_direct,
     '+821078901234', '010-7890-1234',
     90000, 60000, 45000, 18000,
     '서울특별시', '송파구', '잠실동', v_region_seoul, v_sub_jamsil,
     ST_SetSRID(ST_MakePoint(127.1000, 37.5133), 4326)::geography, true)
  on conflict (id) do nothing;

  ---------------------------------------------------------------
  -- bosal_features (특징 리스트)
  ---------------------------------------------------------------
  insert into public.bosal_features (bosal_id, label, sort_order) values
    ('00000000-0000-0000-0000-000000000001', '연애', 0),
    ('00000000-0000-0000-0000-000000000001', '냉철한 상담', 1),
    ('00000000-0000-0000-0000-000000000001', '강남 최고 보살', 2),

    ('00000000-0000-0000-0000-000000000002', '취업', 0),
    ('00000000-0000-0000-0000-000000000002', '공감형 상담', 1),
    ('00000000-0000-0000-0000-000000000002', '정확한 사주풀이', 2),

    ('00000000-0000-0000-0000-000000000003', '재물', 0),
    ('00000000-0000-0000-0000-000000000003', '현실 조언', 1),
    ('00000000-0000-0000-0000-000000000003', '비즈니스 전문', 2),

    ('00000000-0000-0000-0000-000000000004', '연애', 0),
    ('00000000-0000-0000-0000-000000000004', '타로 전문', 1),
    ('00000000-0000-0000-0000-000000000004', '감성 상담', 2),

    ('00000000-0000-0000-0000-000000000005', '건강', 0),
    ('00000000-0000-0000-0000-000000000005', '인간관계', 1),
    ('00000000-0000-0000-0000-000000000005', '가족 상담 전문', 2),

    ('00000000-0000-0000-0000-000000000006', '연애', 0),
    ('00000000-0000-0000-0000-000000000006', '공감형', 1),
    ('00000000-0000-0000-0000-000000000006', '치유 상담', 2),

    ('00000000-0000-0000-0000-000000000007', '진로', 0),
    ('00000000-0000-0000-0000-000000000007', '직설형', 1),
    ('00000000-0000-0000-0000-000000000007', '명쾌한 해석', 2)
  on conflict do nothing;

  ---------------------------------------------------------------
  -- bosal_categories (M:N)
  ---------------------------------------------------------------
  insert into public.bosal_categories (bosal_id, category_id) values
    ('00000000-0000-0000-0000-000000000001', v_cat_love),
    ('00000000-0000-0000-0000-000000000001', v_cat_tarot),

    ('00000000-0000-0000-0000-000000000002', v_cat_career),
    ('00000000-0000-0000-0000-000000000002', v_cat_wealth),

    ('00000000-0000-0000-0000-000000000003', v_cat_wealth),
    ('00000000-0000-0000-0000-000000000003', v_cat_career),

    ('00000000-0000-0000-0000-000000000004', v_cat_love),
    ('00000000-0000-0000-0000-000000000004', v_cat_tarot),
    ('00000000-0000-0000-0000-000000000004', v_cat_relationship),

    ('00000000-0000-0000-0000-000000000005', v_cat_health),
    ('00000000-0000-0000-0000-000000000005', v_cat_relationship),

    ('00000000-0000-0000-0000-000000000006', v_cat_love),
    ('00000000-0000-0000-0000-000000000006', v_cat_health),

    ('00000000-0000-0000-0000-000000000007', v_cat_career),
    ('00000000-0000-0000-0000-000000000007', v_cat_wealth)
  on conflict do nothing;

  ---------------------------------------------------------------
  -- operating_hours: 월~토 10:00-22:00, 일요일 휴무 (샘플)
  -- 모든 보살에게 동일 스케줄 주입. 실 데이터는 보살이 편집.
  ---------------------------------------------------------------
  for bosal_rec in select id from public.bosals where id::text like '00000000-0000-0000-0000-00000000000_' loop
    insert into public.operating_hours (bosal_id, weekday, opens_at, closes_at) values
      (bosal_rec.id, 0, null, null),                      -- Sun closed
      (bosal_rec.id, 1, '10:00:00', '22:00:00'),          -- Mon
      (bosal_rec.id, 2, '10:00:00', '22:00:00'),          -- Tue
      (bosal_rec.id, 3, '10:00:00', '22:00:00'),          -- Wed
      (bosal_rec.id, 4, '10:00:00', '22:00:00'),          -- Thu
      (bosal_rec.id, 5, '10:00:00', '22:00:00'),          -- Fri
      (bosal_rec.id, 6, '10:00:00', '22:00:00')           -- Sat
    on conflict (bosal_id, weekday) do nothing;
  end loop;

  ---------------------------------------------------------------
  -- 초기 denormalized counters: UI 렌더링 참고용으로 mock 값 주입
  --   실제 운영 시 trigger가 관리.
  ---------------------------------------------------------------
  update public.bosals set rating_avg = 9.9, review_count = 14, qna_count = 9,  consult_request_count = 45
    where id = '00000000-0000-0000-0000-000000000001';
  update public.bosals set rating_avg = 9.7, review_count = 22, qna_count = 15, consult_request_count = 38
    where id = '00000000-0000-0000-0000-000000000002';
  update public.bosals set rating_avg = 9.5, review_count = 31, qna_count = 12, consult_request_count = 52
    where id = '00000000-0000-0000-0000-000000000003';
  update public.bosals set rating_avg = 9.8, review_count = 18, qna_count = 7,  consult_request_count = 29
    where id = '00000000-0000-0000-0000-000000000004';
  update public.bosals set rating_avg = 9.6, review_count = 25, qna_count = 11, consult_request_count = 41
    where id = '00000000-0000-0000-0000-000000000005';
  update public.bosals set rating_avg = 9.4, review_count = 19, qna_count = 8,  consult_request_count = 33
    where id = '00000000-0000-0000-0000-000000000006';
  update public.bosals set rating_avg = 9.3, review_count = 28, qna_count = 14, consult_request_count = 47
    where id = '00000000-0000-0000-0000-000000000007';
end $$;
