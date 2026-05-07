'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';
import type { ReportRow } from '@/lib/types';

const KIND_LABEL: Record<ReportRow['target_kind'], string> = {
  review: '후기',
  bosal: '보살',
  user: '사용자',
};

export default function ReportsList({ rows }: { rows: ReportRow[] }) {
  const router = useRouter();
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function resolve(
    id: string,
    resolution: 'resolved' | 'dismissed',
    restoreTarget: boolean,
    note?: string,
  ) {
    setError(null);
    setBusy(id);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: e } = await supabase.rpc('resolve_report', {
        p_report_id: id,
        p_resolution: resolution,
        p_restore_target: restoreTarget,
        p_note: note ?? null,
      });
      if (e) throw new Error(e.message);
      router.refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : '처리 실패');
    } finally {
      setBusy(null);
    }
  }

  if (rows.length === 0) {
    return (
      <div className="rounded-md border border-slate-200 bg-white p-12 text-center text-sm text-slate-500">
        해당 상태의 신고가 없습니다.
      </div>
    );
  }

  return (
    <>
      {error && (
        <div className="mb-3 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}
      <ul className="space-y-3">
        {rows.map((r) => (
          <li
            key={r.id}
            className="rounded-md border border-slate-200 bg-white p-4"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="inline-block rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-700">
                    {KIND_LABEL[r.target_kind]}
                  </span>
                  <span className="text-sm font-semibold text-slate-900">
                    {r.reason}
                  </span>
                  <span className="text-xs text-slate-400">
                    {new Date(r.created_at).toLocaleString('ko-KR')}
                  </span>
                </div>
                {r.description && (
                  <p className="mt-2 text-sm text-slate-700">
                    {r.description}
                  </p>
                )}
                <div className="mt-2 flex gap-3 text-[10px] font-mono text-slate-400">
                  <span>대상: {r.target_id}</span>
                  <span>신고자: {r.reporter_id}</span>
                </div>
                {r.resolution_note && (
                  <div className="mt-2 rounded border border-slate-200 bg-slate-50 p-2 text-xs text-slate-600">
                    처리 메모: {r.resolution_note}
                  </div>
                )}
              </div>
              {r.status === 'pending' && (
                <div className="flex gap-2 shrink-0">
                  <button
                    onClick={() =>
                      resolve(
                        r.id,
                        'resolved',
                        false,
                        '신고 유효 — 콘텐츠 비공개 유지',
                      )
                    }
                    disabled={busy === r.id}
                    className="rounded-md bg-red-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                  >
                    유효 (비공개 유지)
                  </button>
                  <button
                    onClick={() =>
                      resolve(r.id, 'dismissed', true, '신고 기각 — 콘텐츠 복구')
                    }
                    disabled={busy === r.id}
                    className="rounded-md border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                  >
                    기각 (복구)
                  </button>
                </div>
              )}
            </div>
          </li>
        ))}
      </ul>
    </>
  );
}
