-- =====================================================================
-- 19_extend_lookups : align lookup seed with frontend mock
--
--   1) sub_regions 테이블에 latitude/longitude 컬럼 추가 (nullable, 후방호환)
--   2) categories: 기타 4개 추가 (newyear, compatibility, dream, naming)
--   3) regions: 누락된 7개 시도 추가 (chungbuk, jeonnam, jeonbuk,
--      gyeongnam, gyeongbuk, gangwon, jeju)
--   4) sub_regions: 모든 시도(서울 포함) sub-region 좌표 upsert
--
--   모든 INSERT/UPDATE는 idempotent — 재실행해도 안전.
--   `lib/data/mock/mock_regions.dart`, `lib/data/mock/mock_categories.dart`
--   와 1:1 동기화한다. 둘 중 한쪽이 변경되면 양쪽 함께 갱신할 것.
-- =====================================================================

-- ---------- 1) sub_regions 좌표 컬럼 ----------
alter table public.sub_regions
  add column if not exists latitude  numeric,
  add column if not exists longitude numeric;


-- ---------- 2) categories — 기타 4개 추가 ----------
insert into public.categories (code, name, icon_key, sort_order) values
  ('newyear',       '신년운세', 'celebration_outlined',         80),
  ('compatibility', '궁합',     'volunteer_activism_outlined',  90),
  ('dream',         '꿈해몽',   'bedtime_outlined',            100),
  ('naming',        '작명',     'edit_outlined',               110)
on conflict (code) do nothing;


-- ---------- 3) regions — 누락 7개 추가 ----------
insert into public.regions (code, name, sort_order) values
  ('chungbuk',  '충북',  100),
  ('jeonnam',   '전남',  110),
  ('jeonbuk',   '전북',  120),
  ('gyeongnam', '경남',  130),
  ('gyeongbuk', '경북',  140),
  ('gangwon',   '강원',  150),
  ('jeju',      '제주',  160)
on conflict (code) do nothing;


-- ---------- 4) sub_regions upsert (좌표 포함) ----------
-- 헬퍼 CTE: 모든 sub-region 데이터를 (region_code, code, name, sort_order, lat, lng) 형태로
-- 모아두고 regions와 join해 region_id로 변환 → upsert.

with src(region_code, code, name, sort_order, latitude, longitude) as (
  values
  -- 서울 (기존 11개 + 좌표)
  ('seoul',     'seoul_all',     '서울 전체',                  0,    37.5665, 126.9780),
  ('seoul',     'gangnam',       '강남역/신논현역/양재',       10,   37.4979, 127.0276),
  ('seoul',     'cheongdam',     '청담/압구정/신사',           20,   37.5270, 127.0417),
  ('seoul',     'seolleung',     '선릉/삼성',                  30,   37.5045, 127.0490),
  ('seoul',     'nonhyeon',      '논현/반포/학동',             40,   37.5145, 127.0210),
  ('seoul',     'seocho',        '서초/고대/방배',             50,   37.4837, 127.0324),
  ('seoul',     'daechi',        '대치/도곡/한티',             60,   37.4955, 127.0625),
  ('seoul',     'hongdae',       '홍대/합정/신촌',             70,   37.5563, 126.9236),
  ('seoul',     'seoul_station', '서울역/명동/회현',           80,   37.5547, 126.9706),
  ('seoul',     'jamsil',        '잠실/송파/석촌',             90,   37.5133, 127.1000),
  ('seoul',     'seongsu',       '성수/건대/왕십리',          100,   37.5449, 127.0568),

  -- 경기
  ('gyeonggi',  'gyeonggi_all',  '경기 전체',                   0,   37.4138, 127.5183),
  ('gyeonggi',  'seongnam',      '성남/분당/판교',             10,   37.4449, 127.1388),
  ('gyeonggi',  'suwon_yongin',  '수원/용인',                  20,   37.2636, 127.0286),
  ('gyeonggi',  'anyang',        '안양/과천',                  30,   37.3943, 126.9568),
  ('gyeonggi',  'namyangju',     '남양주/하남/구리',           40,   37.6361, 127.2165),
  ('gyeonggi',  'goyang',        '일산/고양',                  50,   37.6584, 126.8320),
  ('gyeonggi',  'pyeongtaek',    '평택/오산',                  60,   36.9921, 127.1130),
  ('gyeonggi',  'uijeongbu',     '의정부/양주',                70,   37.7381, 127.0474),
  ('gyeonggi',  'bucheon',       '부천/시흥',                  80,   37.5034, 126.7660),
  ('gyeonggi',  'yeoncheon',     '연천/포천/동두천',           90,   38.0877, 127.0750),
  ('gyeonggi',  'ansan',         '안산/화성',                 100,   37.3219, 126.8309),
  ('gyeonggi',  'gunpo',         '군포/의왕/광명',            110,   37.3614, 126.9350),
  ('gyeonggi',  'paju',          '파주/김포',                 120,   37.7590, 126.7800),
  ('gyeonggi',  'icheon',        '이천/여주/광주',            130,   37.2721, 127.4350),
  ('gyeonggi',  'gapyeong',      '가평/양평',                 140,   37.8314, 127.5100),

  -- 인천
  ('incheon',   'incheon_all',   '인천 전체',                   0,   37.4563, 126.7052),
  ('incheon',   'bupyeong',      '부평',                       10,   37.5029, 126.7219),
  ('incheon',   'seoknam',       '석남/서구청/경인교대',       20,   37.5224, 126.6791),
  ('incheon',   'songdo',        '연수/송도',                  30,   37.3830, 126.6560),
  ('incheon',   'sinpo',         '신포/동인천/영종도',         40,   37.4720, 126.6246),
  ('incheon',   'sorae',         '소래포구/호구포',            50,   37.4210, 126.7340),
  ('incheon',   'guwol',         '구월동',                     60,   37.4490, 126.7050),

  -- 부산
  ('busan',     'busan_all',     '부산 전체',                   0,   35.1796, 129.0756),
  ('busan',     'dongrae',       '동래/사직/부산대',           10,   35.2041, 129.0810),
  ('busan',     'hadan',         '하단/신평',                  20,   35.1020, 128.9760),
  ('busan',     'seomyeon',      '서면/전포',                  30,   35.1578, 129.0597),
  ('busan',     'haeundae',      '센텀/해운대/광안리',         40,   35.1628, 129.1603),
  ('busan',     'deokcheon',     '덕천/화명',                  50,   35.2295, 129.0166),
  ('busan',     'daeyeon',       '대연/경성대/부경대',         60,   35.1370, 129.0980),

  -- 대구
  ('daegu',     'daegu_all',     '대구 전체',                   0,   35.8714, 128.6014),
  ('daegu',     'dongseong',     '동성로/서문시장/대구시청',   10,   35.8694, 128.5959),
  ('daegu',     'daegustation',  '대구역/칠성시장/경북대',     20,   35.8794, 128.6052),
  ('daegu',     'dongdaegu',     '동대구역/고속터미널',        30,   35.8797, 128.6286),
  ('daegu',     'daeguairport',  '대구공항/동촌유원지',        40,   35.8987, 128.6581),
  ('daegu',     'suseong',       '수성못/범어',                50,   35.8583, 128.6308),
  ('daegu',     'bukbu',         '북부정류장/이현공단',        60,   35.8870, 128.5720),
  ('daegu',     'duryu',         '두류공원/이월드',            70,   35.8533, 128.5657),
  ('daegu',     'seongso',       '성서/계명대',                80,   35.8514, 128.4960),

  -- 대전
  ('daejeon',   'daejeon_all',   '대전 전체',                   0,   36.3504, 127.3845),
  ('daejeon',   'yuseong',       '유성구',                     10,   36.3624, 127.3565),
  ('daejeon',   'dunsan',        '서구(둔산/용문/월평)',       20,   36.3514, 127.3867),
  ('daejeon',   'donggu',        '동구(용전/복합터미널)',      30,   36.3489, 127.4270),
  ('daejeon',   'junggu',        '중구(은행/대흥/선화)',       40,   36.3280, 127.4269),

  -- 광주
  ('gwangju',   'gwangju_all',   '광주 전체',                   0,   35.1595, 126.8526),
  ('gwangju',   'sangmu',        '상무지구/금호지구',          10,   35.1510, 126.8497),
  ('gwangju',   'cheomdan',      '첨단지구/하남지구',          20,   35.2196, 126.8425),
  ('gwangju',   'chungjangro',   '충장로/대인시장',            30,   35.1464, 126.9161),
  ('gwangju',   'jeonnamdae',    '전남대',                     40,   35.1756, 126.9099),

  -- 울산
  ('ulsan',     'ulsan_all',     '울산 전체',                   0,   35.5384, 129.3114),
  ('ulsan',     'samsan',        '삼산/성남/무거/신정',        10,   35.5383, 129.3113),
  ('ulsan',     'ilsan_ulsan',   '일산/진장/진하',             20,   35.5680, 129.3510),

  -- 충남/세종
  ('chungnam',  'chungnam_all',  '충남/세종 전체',              0,   36.4800, 127.2890),
  ('chungnam',  'cheonan',       '천안/아산',                  10,   36.8151, 127.1139),
  ('chungnam',  'gongju',        '공주/동학사/세종',           20,   36.4800, 127.2890),
  ('chungnam',  'gyeryong',      '계룡/금산/논산/청양',        30,   36.2738, 127.2476),
  ('chungnam',  'yesan',         '예산/홍성',                  40,   36.6847, 126.8497),
  ('chungnam',  'taean',         '태안/안면도/서산',           50,   36.7453, 126.2980),
  ('chungnam',  'dangjin',       '당진/보령',                  60,   36.8934, 126.6295),
  ('chungnam',  'seocheon',      '서천/부여',                  70,   36.0779, 126.6918),

  -- 충북
  ('chungbuk',  'chungbuk_all',  '충북 전체',                   0,   36.6357, 127.4913),
  ('chungbuk',  'cheongju',      '청주',                       10,   36.6424, 127.4890),
  ('chungbuk',  'chungju',       '충주/수안보',                20,   36.9910, 127.9259),
  ('chungbuk',  'jecheon',       '제천/단양',                  30,   37.1324, 128.1910),
  ('chungbuk',  'jincheon',      '진천/음성',                  40,   36.8553, 127.4360),
  ('chungbuk',  'boeun',         '보은/옥천/괴산/증평/영동',   50,   36.4892, 127.7297),

  -- 전남
  ('jeonnam',   'jeonnam_all',   '전남 전체',                   0,   34.8679, 126.9910),
  ('jeonnam',   'yeosu',         '여수',                       10,   34.7604, 127.6622),
  ('jeonnam',   'suncheon',      '순천',                       20,   34.9506, 127.4872),
  ('jeonnam',   'gwangyang',     '광양',                       30,   35.0150, 127.6917),
  ('jeonnam',   'mokpo',         '목포/무안/영암',             40,   34.8118, 126.3922),
  ('jeonnam',   'naju',          '나주/함평/영광',             50,   35.0160, 126.7108),
  ('jeonnam',   'damyang',       '담양/곡성/화순',             60,   35.3213, 126.9880),
  ('jeonnam',   'haenam',        '해남/완도/진도',             70,   34.5736, 126.5991),

  -- 전북
  ('jeonbuk',   'jeonbuk_all',   '전북 전체',                   0,   35.7175, 127.1530),
  ('jeonbuk',   'jeonju',        '전주',                       10,   35.8242, 127.1480),
  ('jeonbuk',   'gunsan',        '군산',                       20,   35.9676, 126.7368),
  ('jeonbuk',   'iksan',         '익산',                       30,   35.9483, 126.9576),
  ('jeonbuk',   'namwon',        '남원/임실/순창',             40,   35.4164, 127.3900),
  ('jeonbuk',   'buan',          '부안/김제/고창',             50,   35.7314, 126.7317),

  -- 경남
  ('gyeongnam', 'gyeongnam_all', '경남 전체',                   0,   35.4606, 128.2132),
  ('gyeongnam', 'changwon',      '창원',                       10,   35.2284, 128.6811),
  ('gyeongnam', 'masan',         '마산/진해/함안',             20,   35.1956, 128.5740),
  ('gyeongnam', 'gimhae',        '김해/장유',                  30,   35.2285, 128.8893),
  ('gyeongnam', 'miryang',       '밀양/양산',                  40,   35.5037, 128.7460),
  ('gyeongnam', 'jinju',         '진주',                       50,   35.1798, 128.1076),
  ('gyeongnam', 'geoje',         '거제/통영/고성',             60,   34.8804, 128.6214),
  ('gyeongnam', 'sacheon',       '사천/남해',                  70,   35.0035, 128.0644),
  ('gyeongnam', 'hadong',        '하동/산청/함양',             80,   35.0672, 127.7516),

  -- 경북
  ('gyeongbuk', 'gyeongbuk_all', '경북 전체',                   0,   36.5760, 128.5055),
  ('gyeongbuk', 'pohang',        '포항',                       10,   36.0190, 129.3435),
  ('gyeongbuk', 'gyeongju',      '경주/구미',                  20,   35.8562, 129.2247),
  ('gyeongbuk', 'gyeongsan',     '경산/안동',                  30,   35.8250, 128.7416),
  ('gyeongbuk', 'yeongcheon',    '영천/청도',                  40,   35.9734, 128.9384),
  ('gyeongbuk', 'gimcheon',      '김천/칠곡/성주',             50,   36.1198, 128.1139),
  ('gyeongbuk', 'mungyeong',     '문경/상주/영주',             60,   36.5939, 128.1880),
  ('gyeongbuk', 'uljin',         '울진/영덕/청송',             70,   36.9930, 129.4003),

  -- 강원
  ('gangwon',   'gangwon_all',   '강원 전체',                   0,   37.8228, 128.1555),
  ('gangwon',   'gangneung',     '강릉역/교동/옥계',           10,   37.7519, 128.8761),
  ('gangwon',   'sokcho',        '속초/고성/양양/춘천',        20,   38.2070, 128.5918),
  ('gangwon',   'donghae',       '동해/삼척/태백',             30,   37.5245, 129.1143),
  ('gangwon',   'pyeongchang',   '평창',                       40,   37.3703, 128.3905),
  ('gangwon',   'hongcheon',     '홍천/횡성',                  50,   37.6968, 127.8884),
  ('gangwon',   'wonju',         '원주',                       60,   37.3422, 127.9202),
  ('gangwon',   'yeongwol',      '영월/정선',                  70,   37.1838, 128.4615),
  ('gangwon',   'gyeongpodae',   '경포대/사천/주문진',         80,   37.7967, 128.9059),
  ('gangwon',   'hwacheon',      '화천/철원/인제',             90,   38.1064, 127.7086),

  -- 제주
  ('jeju',      'jeju_all',      '제주 전체',                   0,   33.4890, 126.4983),
  ('jeju',      'seogwipo',      '서귀포',                     10,   33.2541, 126.5600),
  ('jeju',      'jeju_city',     '제주',                       20,   33.4996, 126.5312)
)
insert into public.sub_regions (region_id, code, name, sort_order, latitude, longitude)
select r.id, s.code, s.name, s.sort_order, s.latitude, s.longitude
  from src s
  join public.regions r on r.code = s.region_code
on conflict (region_id, code) do update set
  name       = excluded.name,
  sort_order = excluded.sort_order,
  latitude   = excluded.latitude,
  longitude  = excluded.longitude;
