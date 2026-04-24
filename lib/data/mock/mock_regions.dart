import '../models/region.dart';

final mockRegions = [
  Region(
    id: 'seoul',
    name: '서울',
    subRegions: [
      const SubRegion(id: 'seoul_all', name: '서울 전체', parentRegionId: 'seoul'),
      const SubRegion(id: 'gangnam', name: '강남역/신논현역/양재', parentRegionId: 'seoul'),
      const SubRegion(id: 'cheongdam', name: '청담/압구정/신사', parentRegionId: 'seoul'),
      const SubRegion(id: 'seolleung', name: '선릉/삼성', parentRegionId: 'seoul'),
      const SubRegion(id: 'nonhyeon', name: '논현/반포/학동', parentRegionId: 'seoul'),
      const SubRegion(id: 'seocho', name: '서초/고대/방배', parentRegionId: 'seoul'),
      const SubRegion(id: 'daechi', name: '대치/도곡/한티', parentRegionId: 'seoul'),
      const SubRegion(id: 'hongdae', name: '홍대/합정/신촌', parentRegionId: 'seoul'),
      const SubRegion(id: 'seoul_station', name: '서울역/명동/회현', parentRegionId: 'seoul'),
      const SubRegion(id: 'jamsil', name: '잠실/송파/석촌', parentRegionId: 'seoul'),
      const SubRegion(id: 'seongsu', name: '성수/건대/왕십리', parentRegionId: 'seoul'),
    ],
  ),
  const Region(id: 'gyeonggi', name: '경기', subRegions: []),
  const Region(id: 'incheon', name: '인천', subRegions: []),
  const Region(id: 'busan', name: '부산', subRegions: []),
  const Region(id: 'daegu', name: '대구', subRegions: []),
  const Region(id: 'daejeon', name: '대전', subRegions: []),
  const Region(id: 'gwangju', name: '광주', subRegions: []),
  const Region(id: 'ulsan', name: '울산', subRegions: []),
  const Region(id: 'chungnam', name: '충남/세종', subRegions: []),
];
