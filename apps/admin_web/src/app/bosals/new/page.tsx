import { createSupabaseServerClient } from '@/lib/supabase/server';
import AdminShell from '@/components/admin-shell';
import NewBosalForm from './new-bosal-form';
import type { RegionRow, SubRegionRow } from '@/lib/types';

export const metadata = {
  title: '보살 신규 등록 — 강남보살 관리자',
};

export const dynamic = 'force-dynamic';

export default async function NewBosalPage() {
  const supabase = await createSupabaseServerClient();
  const [regionsRes, subRegionsRes] = await Promise.all([
    supabase.from('regions').select('id,code,name,sort_order').order('sort_order'),
    supabase
      .from('sub_regions')
      .select('id,region_id,code,name,sort_order')
      .order('sort_order'),
  ]);

  return (
    <AdminShell active="/bosals">
      <h2 className="mb-2 text-xl font-bold text-slate-900">보살 신규 등록</h2>
      <p className="mb-6 text-sm text-slate-500">
        빈 보살 프로필과 초대 코드를 함께 발급합니다. 발급된 코드를 보살에게 전달하면
        가입 시 자동으로 이 프로필에 연결됩니다.
      </p>
      <NewBosalForm
        regions={(regionsRes.data ?? []) as RegionRow[]}
        subRegions={(subRegionsRes.data ?? []) as SubRegionRow[]}
      />
    </AdminShell>
  );
}
