import Link from 'next/link';
import { Plus, Search } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import AdminShell from '@/components/admin-shell';
import type { BosalRow } from '@/lib/types';

export const metadata = {
  title: '보살 관리 — 강남보살 관리자',
};

export const dynamic = 'force-dynamic';

export default async function BosalsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; status?: string }>;
}) {
  const sp = await searchParams;
  const q = (sp.q ?? '').trim();
  const status = sp.status; // 'published' | 'unpublished' | undefined

  const supabase = await createSupabaseServerClient();
  let query = supabase
    .from('bosals')
    .select(
      'id,name,slug,phone_display,is_published,rating_avg,review_count,consult_request_count,sido,sigungu,created_at,deleted_at',
    )
    .filter('deleted_at', 'is', null)
    .order('created_at', { ascending: false })
    .limit(200);

  if (q.length > 0) {
    query = query.ilike('name', `%${q}%`);
  }
  if (status === 'published') query = query.eq('is_published', true);
  if (status === 'unpublished') query = query.eq('is_published', false);

  const { data: rows, error } = await query;

  return (
    <AdminShell active="/bosals">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-xl font-bold text-slate-900">보살 관리</h2>
        <Link
          href="/bosals/new"
          className="inline-flex items-center gap-1.5 rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-indigo-700"
        >
          <Plus className="size-4" />
          신규 등록
        </Link>
      </div>

      <form className="mb-4 flex flex-wrap items-center gap-2">
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-slate-400" />
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="이름으로 검색"
            className="w-64 rounded-md border border-slate-300 bg-white pl-8 pr-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>
        <select
          name="status"
          defaultValue={status ?? ''}
          className="rounded-md border border-slate-300 bg-white px-3 py-1.5 text-sm"
        >
          <option value="">전체</option>
          <option value="published">공개만</option>
          <option value="unpublished">비공개만</option>
        </select>
        <button
          type="submit"
          className="rounded-md border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          필터 적용
        </button>
      </form>

      {error ? (
        <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          보살 데이터 로드 실패: {error.message}
        </div>
      ) : (
        <div className="overflow-x-auto rounded-md border border-slate-200 bg-white">
          <table className="min-w-full text-sm">
            <thead className="bg-slate-50 text-left text-xs font-semibold text-slate-600 uppercase">
              <tr>
                <th className="px-4 py-3">이름</th>
                <th className="px-2 py-3">slug</th>
                <th className="px-2 py-3">지역</th>
                <th className="px-2 py-3">전화</th>
                <th className="px-2 py-3 text-center">공개</th>
                <th className="px-2 py-3 text-right">평점</th>
                <th className="px-2 py-3 text-right">리뷰</th>
                <th className="px-2 py-3 text-right">예약요청</th>
                <th className="px-2 py-3">등록일</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {(rows ?? []).map((r) => (
                <BosalRowItem key={r.id} row={r as Partial<BosalRow>} />
              ))}
              {(!rows || rows.length === 0) && (
                <tr>
                  <td
                    colSpan={9}
                    className="px-4 py-12 text-center text-sm text-slate-500"
                  >
                    {q ? `"${q}" 검색 결과가 없습니다.` : '보살 데이터가 없습니다.'}
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

function BosalRowItem({ row }: { row: Partial<BosalRow> }) {
  return (
    <tr className="hover:bg-slate-50">
      <td className="px-4 py-3">
        <Link
          href={`/bosals/${row.id}`}
          className="font-medium text-slate-900 hover:text-indigo-600"
        >
          {row.name}
        </Link>
      </td>
      <td className="px-2 py-3 text-slate-500">{row.slug ?? '-'}</td>
      <td className="px-2 py-3 text-slate-700">
        {[row.sido, row.sigungu].filter(Boolean).join(' ') || '-'}
      </td>
      <td className="px-2 py-3 text-slate-700 tabular-nums">
        {row.phone_display ?? '-'}
      </td>
      <td className="px-2 py-3 text-center">
        {row.is_published ? (
          <span className="inline-block rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-700">
            공개
          </span>
        ) : (
          <span className="inline-block rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-600">
            비공개
          </span>
        )}
      </td>
      <td className="px-2 py-3 text-right tabular-nums">
        {Number(row.rating_avg ?? 0).toFixed(1)}
      </td>
      <td className="px-2 py-3 text-right tabular-nums">{row.review_count}</td>
      <td className="px-2 py-3 text-right tabular-nums">
        {row.consult_request_count}
      </td>
      <td className="px-2 py-3 text-slate-500 text-xs">
        {row.created_at
          ? new Date(row.created_at).toLocaleDateString('ko-KR')
          : '-'}
      </td>
    </tr>
  );
}
