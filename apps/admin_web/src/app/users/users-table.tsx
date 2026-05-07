'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';
import type { ProfileRow } from '@/lib/types';

const ROLES: ProfileRow['role'][] = ['user', 'bosal', 'admin'];

export default function UsersTable({ rows }: { rows: ProfileRow[] }) {
  const router = useRouter();
  const [savingId, setSavingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function changeRole(id: string, role: ProfileRow['role']) {
    if (
      !confirm(
        `이 사용자의 권한을 "${role}"로 변경할까요? 잘못된 변경은 보안에 영향을 줍니다.`,
      )
    ) {
      return;
    }
    setError(null);
    setSavingId(id);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: e } = await supabase
        .from('profiles')
        .update({ role })
        .eq('id', id);
      if (e) throw new Error(e.message);
      router.refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : '권한 변경 실패');
    } finally {
      setSavingId(null);
    }
  }

  return (
    <>
      {error && (
        <div className="mb-3 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}
      <div className="overflow-x-auto rounded-md border border-slate-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs font-semibold text-slate-600 uppercase">
            <tr>
              <th className="px-4 py-3">표시명</th>
              <th className="px-2 py-3">역할</th>
              <th className="px-2 py-3">보살 연결</th>
              <th className="px-2 py-3">가입일</th>
              <th className="px-2 py-3">상태</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {rows.map((r) => (
              <tr key={r.id} className="hover:bg-slate-50">
                <td className="px-4 py-3 font-medium text-slate-900">
                  {r.display_name ?? '(미입력)'}
                  <div className="text-[10px] font-mono text-slate-400">
                    {r.id}
                  </div>
                </td>
                <td className="px-2 py-3">
                  <select
                    value={r.role}
                    disabled={savingId === r.id}
                    onChange={(e) =>
                      changeRole(r.id, e.target.value as ProfileRow['role'])
                    }
                    className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
                  >
                    {ROLES.map((role) => (
                      <option key={role} value={role}>
                        {role}
                      </option>
                    ))}
                  </select>
                </td>
                <td className="px-2 py-3 text-xs">
                  {r.bosal_id ? (
                    <span className="font-mono text-[10px] text-slate-500">
                      {r.bosal_id}
                    </span>
                  ) : (
                    <span className="text-slate-400">-</span>
                  )}
                </td>
                <td className="px-2 py-3 text-xs text-slate-500">
                  {new Date(r.created_at).toLocaleDateString('ko-KR')}
                </td>
                <td className="px-2 py-3">
                  {r.deleted_at ? (
                    <span className="inline-block rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700">
                      탈퇴
                    </span>
                  ) : (
                    <span className="inline-block rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">
                      활성
                    </span>
                  )}
                </td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-12 text-center text-sm text-slate-500"
                >
                  사용자가 없습니다.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </>
  );
}
