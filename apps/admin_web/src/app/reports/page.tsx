import { createSupabaseServerClient } from '@/lib/supabase/server';
import AdminShell from '@/components/admin-shell';
import ReportsList from './reports-list';
import type { ReportRow } from '@/lib/types';

export const metadata = {
  title: '신고 큐 — 강남보살 관리자',
};

export const dynamic = 'force-dynamic';

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const sp = await searchParams;
  const status = sp.status ?? 'pending';

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from('reports')
    .select()
    .eq('status', status)
    .order('created_at', { ascending: false })
    .limit(200);

  return (
    <AdminShell active="/reports">
      <h2 className="mb-4 text-xl font-bold text-slate-900">신고 큐</h2>

      <div className="mb-4 flex gap-2">
        <Tab href="/reports?status=pending" active={status === 'pending'}>
          대기
        </Tab>
        <Tab href="/reports?status=resolved" active={status === 'resolved'}>
          처리 완료
        </Tab>
        <Tab href="/reports?status=dismissed" active={status === 'dismissed'}>
          기각
        </Tab>
      </div>

      {error ? (
        <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          {error.message}
        </div>
      ) : (
        <ReportsList rows={(data ?? []) as ReportRow[]} />
      )}
    </AdminShell>
  );
}

function Tab({
  href,
  active,
  children,
}: {
  href: string;
  active: boolean;
  children: React.ReactNode;
}) {
  return (
    <a
      href={href}
      className={`rounded-md px-3 py-1.5 text-sm font-medium transition ${
        active
          ? 'bg-indigo-600 text-white'
          : 'bg-white text-slate-700 border border-slate-300 hover:bg-slate-50'
      }`}
    >
      {children}
    </a>
  );
}
