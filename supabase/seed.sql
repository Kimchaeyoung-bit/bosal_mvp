-- =====================================================================
-- seed.sql : lookup-table values only (safe for every environment)
-- =====================================================================

-- categories (mock_categories.dart)
insert into public.categories (code, name, icon_key, sort_order) values
  ('all',          '전체',     'grid_view_rounded',       0),
  ('love',         '연애',     'favorite_rounded',        10),
  ('career',       '취업',     'work_rounded',            20),
  ('wealth',       '재물',     'monetization_on_rounded', 30),
  ('health',       '건강',     'spa_rounded',             40),
  ('relationship', '인간관계', 'people_rounded',          50),
  ('tarot',        '타로',     'auto_awesome_rounded',    60),
  ('business',     '사업',     'business_center_rounded', 70)
on conflict (code) do nothing;

-- consult_styles
insert into public.consult_styles (code, label, sort_order) values
  ('cool',        '냉철형', 10),
  ('empathetic',  '공감형', 20),
  ('direct',      '직설형', 30)
on conflict (code) do nothing;

-- ad_intent_tiers
insert into public.ad_intent_tiers (code, label, description, sort_order) values
  ('none',            '관심 없음',     '광고 노출 의향 없음',                       10),
  ('interested',      '관심 있음',     '광고 상품 제안 대상',                       20),
  ('active_campaign', '캠페인 진행중', '광고 이미지를 수신, 배너로 운영 중',         30)
on conflict (code) do nothing;

-- regions (mock_regions.dart)
insert into public.regions (code, name, sort_order) values
  ('seoul',    '서울',       10),
  ('gyeonggi', '경기',       20),
  ('incheon', '인천',       30),
  ('busan',    '부산',       40),
  ('daegu',    '대구',       50),
  ('daejeon',  '대전',       60),
  ('gwangju',  '광주',       70),
  ('ulsan',    '울산',       80),
  ('chungnam', '충남/세종',  90)
on conflict (code) do nothing;

-- sub_regions (Seoul only, per mock data)
insert into public.sub_regions (region_id, code, name, sort_order)
select r.id, v.code, v.name, v.sort_order
  from public.regions r
  cross join (values
    ('seoul_all',      '서울 전체',               0),
    ('gangnam',        '강남역/신논현역/양재',    10),
    ('cheongdam',      '청담/압구정/신사',        20),
    ('seolleung',      '선릉/삼성',               30),
    ('nonhyeon',       '논현/반포/학동',          40),
    ('seocho',         '서초/고대/방배',          50),
    ('daechi',         '대치/도곡/한티',          60),
    ('hongdae',        '홍대/합정/신촌',          70),
    ('seoul_station',  '서울역/명동/회현',        80),
    ('jamsil',         '잠실/송파/석촌',          90),
    ('seongsu',        '성수/건대/왕십리',        100)
  ) as v(code, name, sort_order)
 where r.code = 'seoul'
on conflict (region_id, code) do nothing;
