import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import AdminShell from '@/components/admin-shell';
import EditBosalForm from './edit-bosal-form';
import type {
  BosalRow,
  CategoryRow,
  ConsultStyleRow,
  AdIntentTierRow,
  RegionRow,
  SubRegionRow,
} from '@/lib/types';

export const metadata = {
  title: '보살 편집 — 강남보살 관리자',
};

export const dynamic = 'force-dynamic';

export default async function BosalDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();

  const [bosalRes, regionsRes, subRegionsRes, catsRes, stylesRes, tiersRes] =
    await Promise.all([
      supabase.from('bosals').select().eq('id', id).maybeSingle(),
      supabase.from('regions').select('id,code,name,sort_order').order('sort_order'),
      supabase
        .from('sub_regions')
        .select('id,region_id,code,name,sort_order')
        .order('sort_order'),
      supabase
        .from('categories')
        .select('id,code,name,sort_order,is_active')
        .order('sort_order'),
      supabase
        .from('consult_styles')
        .select('id,code,label,sort_order')
        .order('sort_order'),
      supabase
        .from('ad_intent_tiers')
        .select('id,code,label,description,sort_order')
        .order('sort_order'),
    ]);

  const bosal = bosalRes.data as BosalRow | null;

  if (!bosal) {
    return (
      <AdminShell active="/bosals">
        <Link
          href="/bosals"
          className="inline-flex items-center gap-1 text-sm text-slate-600 hover:text-slate-900"
        >
          <ArrowLeft className="size-4" /> 보살 목록
        </Link>
        <div className="mt-6 rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          보살을 찾을 수 없습니다 (id: {id})
        </div>
      </AdminShell>
    );
  }

  // 현재 카테고리 / 분석 카드용 데이터
  const [bosalCatsRes, analyticsRes] = await Promise.all([
    supabase
      .from('bosal_categories')
      .select('category_id,categories(code)')
      .eq('bosal_id', id),
    supabase.rpc('admin_list_bosal_analytics'),
  ]);
  // PostgREST는 join을 array로 반환할 수 있으니 양쪽 다 처리.
  const bosalCatsRaw = (bosalCatsRes.data ?? []) as Array<{
    categories:
      | { code: string }
      | Array<{ code: string }>
      | null;
  }>;
  const currentCategoryCodes = bosalCatsRaw
    .flatMap((r) => {
      const c = r.categories;
      if (!c) return [];
      if (Array.isArray(c)) return c.map((x) => x.code);
      return [c.code];
    })
    .filter((c): c is string => !!c);

  type AnalyticsRow = {
    bosal_id: string;
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
  const myAnalytics =
    ((analyticsRes.data ?? []) as AnalyticsRow[]).find(
      (a) => a.bosal_id === id,
    ) ?? null;

  return (
    <AdminShell active="/bosals">
      <Link
        href="/bosals"
        className="inline-flex items-center gap-1 text-sm text-slate-600 hover:text-slate-900 mb-3"
      >
        <ArrowLeft className="size-4" /> 보살 목록
      </Link>
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <EditBosalForm
            bosal={bosal}
            regions={(regionsRes.data ?? []) as RegionRow[]}
            subRegions={(subRegionsRes.data ?? []) as SubRegionRow[]}
            categories={(catsRes.data ?? []) as CategoryRow[]}
            currentCategoryCodes={currentCategoryCodes}
            consultStyles={(stylesRes.data ?? []) as ConsultStyleRow[]}
            adIntentTiers={(tiersRes.data ?? []) as AdIntentTierRow[]}
          />
        </div>
        <aside className="space-y-4">
          <div className="rounded-md border border-slate-200 bg-white p-4">
            <h3 className="text-sm font-bold text-slate-900">분석 카운터</h3>
            {myAnalytics ? (
              <dl className="mt-3 grid grid-cols-2 gap-2 text-xs">
                <Stat label="조회 24h" v={myAnalytics.view_24h} />
                <Stat label="조회 7d" v={myAnalytics.view_7d} />
                <Stat label="조회 30d" v={myAnalytics.view_30d} />
                <Stat label="조회 누적" v={myAnalytics.view_total} muted />
                <Stat label="전화 24h" v={myAnalytics.call_24h} />
                <Stat label="전화 7d" v={myAnalytics.call_7d} />
                <Stat label="전화 30d" v={myAnalytics.call_30d} />
                <Stat label="전화 누적" v={myAnalytics.call_total} muted />
                <Stat label="예약 24h" v={myAnalytics.resv_24h} />
                <Stat label="예약 7d" v={myAnalytics.resv_7d} />
                <Stat label="예약 30d" v={myAnalytics.resv_30d} />
                <Stat label="예약 누적" v={myAnalytics.resv_total} muted />
                <Stat
                  label="찜"
                  v={myAnalytics.favorite_count}
                  accent="rose"
                />
              </dl>
            ) : (
              <p className="mt-2 text-xs text-slate-500">데이터 없음</p>
            )}
          </div>
          <div className="rounded-md border border-slate-200 bg-white p-4">
            <h3 className="text-sm font-bold text-slate-900">기본 정보</h3>
            <dl className="mt-3 space-y-1 text-xs">
              <Row label="ID" value={bosal.id} mono />
              <Row label="평점" value={Number(bosal.rating_avg).toFixed(1)} />
              <Row label="리뷰 수" value={bosal.review_count.toString()} />
              <Row
                label="누적 예약 요청"
                value={bosal.consult_request_count.toString()}
              />
              <Row
                label="등록일"
                value={new Date(bosal.created_at).toLocaleString('ko-KR')}
              />
            </dl>
          </div>
        </aside>
      </div>
    </AdminShell>
  );
}

function Stat({
  label,
  v,
  muted,
  accent,
}: {
  label: string;
  v: number;
  muted?: boolean;
  accent?: 'rose';
}) {
  const containerClass = accent === 'rose'
    ? 'border-rose-100 bg-rose-50/50'
    : muted
      ? 'border-slate-200 bg-slate-50'
      : 'border-indigo-100 bg-indigo-50/50';
  const valueClass = accent === 'rose'
    ? 'text-rose-700'
    : muted
      ? 'text-slate-500'
      : 'text-indigo-700';
  return (
    <div className={`rounded border p-2 ${containerClass}`}>
      <div className="text-[10px] uppercase text-slate-500">{label}</div>
      <div className={`text-lg font-bold tabular-nums ${valueClass}`}>
        {v}
      </div>
    </div>
  );
}

function Row({
  label,
  value,
  mono,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="flex justify-between gap-2">
      <dt className="text-slate-500">{label}</dt>
      <dd
        className={`text-slate-900 ${mono ? 'font-mono text-[10px]' : ''}`}
      >
        {value}
      </dd>
    </div>
  );
}
