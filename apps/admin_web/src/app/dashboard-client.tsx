'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import {
  Phone,
  CalendarCheck,
  Star,
  Users,
  MapPin,
  Eye,
  Heart,
} from 'lucide-react';

export type AnalyticsRow = {
  bosal_id: string;
  name: string;
  is_published: boolean;
  rating_avg: number | string;
  review_count: number;
  consult_request_count: number;
  call_24h: number;
  call_7d: number;
  call_30d: number;
  call_total: number;
  resv_24h: number;
  resv_7d: number;
  resv_30d: number;
  resv_total: number;
  view_24h: number;
  view_7d: number;
  view_30d: number;
  view_total: number;
  favorite_count: number;
};

type Window = '24h' | '7d' | '30d';
type SortBy = 'call' | 'resv' | 'view' | 'favorite' | 'rating' | 'reviews';

const WINDOW_LABEL: Record<Window, string> = {
  '24h': '24시간',
  '7d': '7일',
  '30d': '30일',
};

export default function DashboardClient({ rows }: { rows: AnalyticsRow[] }) {
  const [window, setWindow] = useState<Window>('24h');
  const [sortBy, setSortBy] = useState<SortBy>('call');
  const [onlyPublished, setOnlyPublished] = useState(false);

  const callKey = `call_${window}` as const;
  const resvKey = `resv_${window}` as const;
  const viewKey = `view_${window}` as const;

  const filtered = useMemo(() => {
    const base = onlyPublished ? rows.filter((r) => r.is_published) : rows;
    const sorted = [...base];
    sorted.sort((a, b) => {
      switch (sortBy) {
        case 'call':
          return Number(b[callKey]) - Number(a[callKey]);
        case 'resv':
          return Number(b[resvKey]) - Number(a[resvKey]);
        case 'view':
          return Number(b[viewKey]) - Number(a[viewKey]);
        case 'favorite':
          return b.favorite_count - a.favorite_count;
        case 'rating':
          return Number(b.rating_avg) - Number(a.rating_avg);
        case 'reviews':
          return b.review_count - a.review_count;
        default:
          return 0;
      }
    });
    return sorted;
  }, [rows, sortBy, onlyPublished, callKey, resvKey, viewKey]);

  const kpi = useMemo(() => {
    const activeBosals = rows.filter((r) => r.is_published).length;
    const callSum = rows.reduce((a, r) => a + Number(r[callKey]), 0);
    const resvSum = rows.reduce((a, r) => a + Number(r[resvKey]), 0);
    const viewSum = rows.reduce((a, r) => a + Number(r[viewKey]), 0);
    const favSum = rows.reduce((a, r) => a + r.favorite_count, 0);
    const reqSum = rows.reduce((a, r) => a + r.consult_request_count, 0);
    const ratingNumbers = rows
      .filter((r) => r.review_count > 0)
      .map((r) => Number(r.rating_avg));
    const ratingAvg = ratingNumbers.length
      ? ratingNumbers.reduce((a, b) => a + b, 0) / ratingNumbers.length
      : 0;
    return {
      activeBosals,
      callSum,
      resvSum,
      viewSum,
      favSum,
      reqSum,
      ratingAvg,
    };
  }, [rows, callKey, resvKey, viewKey]);

  return (
    <div className="space-y-6">
      {/* 기간 토글 */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="inline-flex rounded-md border border-slate-300 bg-white p-1">
          {(Object.keys(WINDOW_LABEL) as Window[]).map((w) => (
            <button
              key={w}
              type="button"
              onClick={() => setWindow(w)}
              className={`px-3 py-1.5 text-sm rounded transition ${
                window === w
                  ? 'bg-indigo-600 text-white font-semibold'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              {WINDOW_LABEL[w]}
            </button>
          ))}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <SortChip
            active={sortBy === 'call'}
            onClick={() => setSortBy('call')}
          >
            전화 ↓
          </SortChip>
          <SortChip
            active={sortBy === 'resv'}
            onClick={() => setSortBy('resv')}
          >
            예약 ↓
          </SortChip>
          <SortChip
            active={sortBy === 'view'}
            onClick={() => setSortBy('view')}
          >
            조회 ↓
          </SortChip>
          <SortChip
            active={sortBy === 'favorite'}
            onClick={() => setSortBy('favorite')}
          >
            찜 ↓
          </SortChip>
          <SortChip
            active={sortBy === 'rating'}
            onClick={() => setSortBy('rating')}
          >
            평점 ↓
          </SortChip>
          <SortChip
            active={sortBy === 'reviews'}
            onClick={() => setSortBy('reviews')}
          >
            리뷰수 ↓
          </SortChip>
          <label className="ml-2 inline-flex items-center gap-1.5 text-sm text-slate-700">
            <input
              type="checkbox"
              checked={onlyPublished}
              onChange={(e) => setOnlyPublished(e.target.checked)}
              className="rounded border-slate-300"
            />
            공개만
          </label>
        </div>
      </div>

      {/* KPI 카드 */}
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4 lg:grid-cols-7">
        <KpiCard
          icon={<Users className="size-4" />}
          label="활성 보살"
          value={kpi.activeBosals}
          unit="명"
        />
        <KpiCard
          icon={<Phone className="size-4" />}
          label={`전화 (${WINDOW_LABEL[window]})`}
          value={kpi.callSum}
          unit="회"
          highlight
        />
        <KpiCard
          icon={<CalendarCheck className="size-4" />}
          label={`예약 (${WINDOW_LABEL[window]})`}
          value={kpi.resvSum}
          unit="회"
          highlight
        />
        <KpiCard
          icon={<Eye className="size-4" />}
          label={`조회 (${WINDOW_LABEL[window]})`}
          value={kpi.viewSum}
          unit="회"
          highlight
        />
        <KpiCard
          icon={<Heart className="size-4" />}
          label="누적 찜"
          value={kpi.favSum}
          unit="건"
        />
        <KpiCard
          icon={<MapPin className="size-4" />}
          label="누적 예약요청"
          value={kpi.reqSum}
          unit="건"
        />
        <KpiCard
          icon={<Star className="size-4" />}
          label="평균 평점"
          value={kpi.ratingAvg.toFixed(1)}
          unit="/10"
        />
      </div>

      {/* 보살별 테이블 */}
      <div className="overflow-x-auto rounded-md border border-slate-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs font-semibold text-slate-600 uppercase">
            <tr>
              <th className="sticky left-0 bg-slate-50 px-4 py-3">보살</th>
              <th className="px-2 py-3 text-center">공개</th>
              <th className="px-2 py-3 text-right">평점</th>
              <th className="px-2 py-3 text-right">리뷰</th>
              <th className="px-2 py-3 text-right">찜</th>
              <th className="px-2 py-3 text-right">예약요청</th>
              <th className="px-2 py-3 text-right">조회 24h</th>
              <th className="px-2 py-3 text-right">조회 7d</th>
              <th className="px-2 py-3 text-right">조회 30d</th>
              <th className="px-2 py-3 text-right">조회 누적</th>
              <th className="px-2 py-3 text-right">전화 24h</th>
              <th className="px-2 py-3 text-right">전화 7d</th>
              <th className="px-2 py-3 text-right">전화 30d</th>
              <th className="px-2 py-3 text-right">전화 누적</th>
              <th className="px-2 py-3 text-right">예약 24h</th>
              <th className="px-2 py-3 text-right">예약 7d</th>
              <th className="px-2 py-3 text-right">예약 30d</th>
              <th className="px-2 py-3 text-right">예약 누적</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {filtered.map((r) => (
              <tr key={r.bosal_id} className="hover:bg-slate-50">
                <td className="sticky left-0 bg-white px-4 py-3 shadow-[2px_0_0_0_rgb(241_245_249)]">
                  <Link
                    href={`/bosals/${r.bosal_id}`}
                    className="font-medium text-slate-900 hover:text-indigo-600"
                  >
                    {r.name}
                  </Link>
                </td>
                <td className="px-2 py-3 text-center">
                  {r.is_published ? (
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
                  {Number(r.rating_avg).toFixed(1)}
                </td>
                <td className="px-2 py-3 text-right tabular-nums">
                  {r.review_count}
                </td>
                <td className="px-2 py-3 text-right tabular-nums text-rose-600 font-semibold">
                  {r.favorite_count}
                </td>
                <td className="px-2 py-3 text-right tabular-nums">
                  {r.consult_request_count}
                </td>
                <Cell value={r.view_24h} highlight={window === '24h'} />
                <Cell value={r.view_7d} highlight={window === '7d'} />
                <Cell value={r.view_30d} highlight={window === '30d'} />
                <Cell value={r.view_total} muted />
                <Cell value={r.call_24h} highlight={window === '24h'} />
                <Cell value={r.call_7d} highlight={window === '7d'} />
                <Cell value={r.call_30d} highlight={window === '30d'} />
                <Cell value={r.call_total} muted />
                <Cell value={r.resv_24h} highlight={window === '24h'} />
                <Cell value={r.resv_7d} highlight={window === '7d'} />
                <Cell value={r.resv_30d} highlight={window === '30d'} />
                <Cell value={r.resv_total} muted />
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td
                  colSpan={18}
                  className="px-4 py-12 text-center text-sm text-slate-500"
                >
                  보살 데이터가 없습니다.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function KpiCard({
  icon,
  label,
  value,
  unit,
  highlight,
}: {
  icon: React.ReactNode;
  label: string;
  value: number | string;
  unit: string;
  highlight?: boolean;
}) {
  return (
    <div
      className={`rounded-md border p-4 ${
        highlight
          ? 'border-indigo-200 bg-indigo-50/50'
          : 'border-slate-200 bg-white'
      }`}
    >
      <div className="flex items-center gap-2 text-xs font-medium text-slate-500">
        {icon}
        {label}
      </div>
      <div className="mt-1 flex items-baseline gap-1">
        <span className="text-2xl font-bold text-slate-900 tabular-nums">
          {value}
        </span>
        <span className="text-xs text-slate-500">{unit}</span>
      </div>
    </div>
  );
}

function SortChip({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-full px-3 py-1 text-xs font-medium transition ${
        active
          ? 'bg-slate-900 text-white'
          : 'bg-white text-slate-600 border border-slate-300 hover:bg-slate-50'
      }`}
    >
      {children}
    </button>
  );
}

function Cell({
  value,
  highlight,
  muted,
}: {
  value: number;
  highlight?: boolean;
  muted?: boolean;
}) {
  return (
    <td
      className={`px-2 py-3 text-right tabular-nums ${
        highlight
          ? 'font-bold text-indigo-700'
          : muted
            ? 'text-slate-400'
            : 'text-slate-700'
      }`}
    >
      {value}
    </td>
  );
}
