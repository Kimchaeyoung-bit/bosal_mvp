import { createSupabaseServerClient } from '@/lib/supabase/server';
import AdminShell from '@/components/admin-shell';
import DashboardClient, { type AnalyticsRow } from './dashboard-client';

export const metadata = {
  title: '대시보드 — 강남보살 관리자',
};

export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  const supabase = await createSupabaseServerClient();
  const { data: rowsRaw, error } = await supabase.rpc(
    'admin_list_bosal_analytics',
  );

  return (
    <AdminShell active="/">
      {error ? (
        <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          분석 데이터 로드 실패: {error.message}
        </div>
      ) : (
        <DashboardClient rows={(rowsRaw ?? []) as AnalyticsRow[]} />
      )}
    </AdminShell>
  );
}
