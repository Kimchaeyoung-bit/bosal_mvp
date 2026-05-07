import Link from 'next/link';
import { Plus } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import AdminShell from '@/components/admin-shell';
import IssueInviteForm from './issue-invite-form';
import type { InviteSummaryRow } from '@/lib/types';

export const metadata = {
  title: '초대 코드 — 강남보살 관리자',
};

export const dynamic = 'force-dynamic';

export default async function InvitesPage() {
  const supabase = await createSupabaseServerClient();
  const [invitesRes, bosalsRes] = await Promise.all([
    supabase
      .from('v_active_bosal_invites')
      .select()
      .order('expires_at', { ascending: false }),
    supabase
      .from('bosals')
      .select('id,name,is_published')
      .filter('deleted_at', 'is', null)
      .order('name')
      .limit(500),
  ]);

  const invites = (invitesRes.data ?? []) as InviteSummaryRow[];

  return (
    <AdminShell active="/invites">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-xl font-bold text-slate-900">초대 코드 관리</h2>
        <Link
          href="/bosals/new"
          className="inline-flex items-center gap-1.5 rounded-md border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          <Plus className="size-4" />
          신규 보살 + 코드
        </Link>
      </div>

      <div className="mb-6 rounded-md border border-slate-200 bg-white p-4">
        <h3 className="text-sm font-bold text-slate-900">기존 보살에 코드 발급</h3>
        <p className="mt-1 text-xs text-slate-500">
          이미 등록된 보살(미온보딩 또는 owner 미연결)에게 새 초대 코드를
          발급합니다.
        </p>
        <IssueInviteForm
          bosals={(bosalsRes.data ?? []) as Array<{
            id: string;
            name: string;
            is_published: boolean;
          }>}
        />
      </div>

      {invitesRes.error ? (
        <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          초대 코드 로드 실패: {invitesRes.error.message}
        </div>
      ) : (
        <div className="overflow-x-auto rounded-md border border-slate-200 bg-white">
          <table className="min-w-full text-sm">
            <thead className="bg-slate-50 text-left text-xs font-semibold text-slate-600 uppercase">
              <tr>
                <th className="px-4 py-3">코드</th>
                <th className="px-2 py-3">보살</th>
                <th className="px-2 py-3">이메일</th>
                <th className="px-2 py-3 text-center">상태</th>
                <th className="px-2 py-3">만료</th>
                <th className="px-2 py-3">사용</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {invites.map((inv) => (
                <tr key={inv.code} className="hover:bg-slate-50">
                  <td className="px-4 py-3 font-mono text-xs">{inv.code}</td>
                  <td className="px-2 py-3">
                    {inv.bosal_id ? (
                      <Link
                        href={`/bosals/${inv.bosal_id}`}
                        className="text-indigo-600 hover:underline"
                      >
                        {inv.bosal_name ?? '(이름 없음)'}
                      </Link>
                    ) : (
                      <span className="text-slate-500">-</span>
                    )}
                  </td>
                  <td className="px-2 py-3 text-slate-700 text-xs">
                    {inv.email ?? '-'}
                  </td>
                  <td className="px-2 py-3 text-center">
                    <StatusBadge status={inv.status} />
                  </td>
                  <td className="px-2 py-3 text-xs text-slate-500">
                    {inv.expires_at
                      ? new Date(inv.expires_at).toLocaleString('ko-KR')
                      : '-'}
                  </td>
                  <td className="px-2 py-3 text-xs text-slate-500">
                    {inv.used_at
                      ? new Date(inv.used_at).toLocaleString('ko-KR')
                      : '-'}
                  </td>
                </tr>
              ))}
              {invites.length === 0 && (
                <tr>
                  <td
                    colSpan={6}
                    className="px-4 py-12 text-center text-sm text-slate-500"
                  >
                    활성 초대 코드가 없습니다.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </AdminShell>
  );
}

function StatusBadge({ status }: { status: InviteSummaryRow['status'] }) {
  if (status === 'active') {
    return (
      <span className="inline-block rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">
        활성
      </span>
    );
  }
  if (status === 'used') {
    return (
      <span className="inline-block rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-600">
        사용됨
      </span>
    );
  }
  return (
    <span className="inline-block rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-700">
      만료
    </span>
  );
}
