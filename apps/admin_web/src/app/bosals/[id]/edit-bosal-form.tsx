'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Save, Eye, EyeOff } from 'lucide-react';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';
import type {
  BosalRow,
  CategoryRow,
  ConsultStyleRow,
  AdIntentTierRow,
  RegionRow,
  SubRegionRow,
} from '@/lib/types';

type Props = {
  bosal: BosalRow;
  regions: RegionRow[];
  subRegions: SubRegionRow[];
  categories: CategoryRow[];
  currentCategoryCodes: string[];
  consultStyles: ConsultStyleRow[];
  adIntentTiers: AdIntentTierRow[];
};

export default function EditBosalForm(props: Props) {
  const router = useRouter();
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const { bosal } = props;

  const [name, setName] = useState(bosal.name);
  const [oneLiner, setOneLiner] = useState(bosal.one_liner ?? '');
  const [description, setDescription] = useState(bosal.description ?? '');
  const [experienceYears, setExperienceYears] = useState(
    bosal.experience_years,
  );
  const [phoneDisplay, setPhoneDisplay] = useState(bosal.phone_display ?? '');
  const [phoneE164, setPhoneE164] = useState(bosal.phone_e164 ?? '');
  const [originalPrice, setOriginalPrice] = useState(bosal.original_price);
  const [discountedPrice, setDiscountedPrice] = useState(
    bosal.discounted_price,
  );
  const [firstVisitPrice, setFirstVisitPrice] = useState(
    bosal.first_visit_price,
  );
  const [maxPoints, setMaxPoints] = useState(bosal.max_points);

  const [sido, setSido] = useState(bosal.sido ?? '');
  const [sigungu, setSigungu] = useState(bosal.sigungu ?? '');
  const [eupmyeondong, setEupmyeondong] = useState(bosal.eupmyeondong ?? '');
  const [roadAddress, setRoadAddress] = useState(bosal.road_address ?? '');

  // FK code 계산
  const initialRegionCode = useMemo(
    () => props.regions.find((r) => r.id === bosal.region_id)?.code ?? '',
    [props.regions, bosal.region_id],
  );
  const initialSubRegionCode = useMemo(
    () =>
      props.subRegions.find((s) => s.id === bosal.sub_region_id)?.code ?? '',
    [props.subRegions, bosal.sub_region_id],
  );
  const initialStyleCode = useMemo(
    () =>
      props.consultStyles.find((s) => s.id === bosal.consult_style_id)?.code ??
      '',
    [props.consultStyles, bosal.consult_style_id],
  );

  const [regionCode, setRegionCode] = useState(initialRegionCode);
  const [subRegionCode, setSubRegionCode] = useState(initialSubRegionCode);
  const [styleCode, setStyleCode] = useState(initialStyleCode);
  const [selectedCats, setSelectedCats] = useState<Set<string>>(
    new Set(props.currentCategoryCodes),
  );

  const [isPublished, setIsPublished] = useState(bosal.is_published);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);

  const subRegionOptions = useMemo(() => {
    const r = props.regions.find((x) => x.code === regionCode);
    if (!r) return [];
    return props.subRegions.filter((s) => s.region_id === r.id);
  }, [regionCode, props.regions, props.subRegions]);

  function toggleCat(code: string) {
    setSelectedCats((prev) => {
      const next = new Set(prev);
      if (next.has(code)) next.delete(code);
      else next.add(code);
      return next;
    });
  }

  async function onSave(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setOkMsg(null);
    setSubmitting(true);
    try {
      // 1) update_bosal_owner_fields
      const { error: e1 } = await supabase.rpc('update_bosal_owner_fields', {
        p_bosal_id: bosal.id,
        p_name: name,
        p_one_liner: oneLiner || null,
        p_description: description || null,
        p_experience_years: experienceYears,
        p_consult_style: styleCode || null,
        p_phone_display: phoneDisplay || null,
        p_phone_e164: phoneE164 || null,
        p_original_price: originalPrice,
        p_discounted_price: discountedPrice,
        p_first_visit_price: firstVisitPrice,
        p_max_points: maxPoints,
        p_sido: sido || null,
        p_sigungu: sigungu || null,
        p_eupmyeondong: eupmyeondong || null,
        p_road_address: roadAddress || null,
        p_region_code: regionCode || null,
        p_sub_region_code: subRegionCode || null,
      });
      if (e1) throw new Error(e1.message);

      // 2) replace_bosal_categories
      const { error: e2 } = await supabase.rpc('replace_bosal_categories', {
        p_bosal_id: bosal.id,
        p_category_codes: Array.from(selectedCats),
      });
      if (e2) throw new Error(e2.message);

      setOkMsg('저장되었습니다.');
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : '저장 실패');
    } finally {
      setSubmitting(false);
    }
  }

  async function togglePublish() {
    setError(null);
    setOkMsg(null);
    setSubmitting(true);
    try {
      const { error: e } = await supabase.rpc('publish_bosal_profile', {
        p_bosal_id: bosal.id,
        p_is_published: !isPublished,
      });
      if (e) throw new Error(e.message);
      setIsPublished(!isPublished);
      setOkMsg(!isPublished ? '공개 처리되었습니다.' : '비공개 처리되었습니다.');
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : '실패');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={onSave} className="space-y-5">
      <div className="flex items-center justify-between rounded-md border border-slate-200 bg-white p-4">
        <div>
          <div className="text-sm font-semibold text-slate-900">{bosal.name}</div>
          <div className="text-xs text-slate-500 mt-0.5">
            현재{' '}
            {isPublished ? (
              <span className="text-green-700 font-semibold">공개</span>
            ) : (
              <span className="text-slate-500 font-semibold">비공개</span>
            )}{' '}
            상태
          </div>
        </div>
        <button
          type="button"
          onClick={togglePublish}
          disabled={submitting}
          className={`inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm font-semibold transition ${
            isPublished
              ? 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
              : 'bg-indigo-600 text-white hover:bg-indigo-700'
          } disabled:opacity-50`}
        >
          {isPublished ? (
            <>
              <EyeOff className="size-4" /> 비공개로 전환
            </>
          ) : (
            <>
              <Eye className="size-4" /> 공개로 전환
            </>
          )}
        </button>
      </div>

      <Section title="기본 정보">
        <div className="grid grid-cols-2 gap-3">
          <Field label="이름 (활동명)">
            <input
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="경력 (연차)">
            <input
              type="number"
              min={0}
              value={experienceYears}
              onChange={(e) => setExperienceYears(Number(e.target.value))}
              className="input"
            />
          </Field>
        </div>
        <Field label="한 줄 소개">
          <input
            value={oneLiner}
            onChange={(e) => setOneLiner(e.target.value)}
            maxLength={120}
            className="input"
          />
        </Field>
        <Field label="상세 소개">
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={4}
            maxLength={2000}
            className="input"
          />
        </Field>
        <Field label="상담 스타일">
          <select
            value={styleCode}
            onChange={(e) => setStyleCode(e.target.value)}
            className="input"
          >
            <option value="">선택 안 함</option>
            {props.consultStyles.map((s) => (
              <option key={s.id} value={s.code}>
                {s.label}
              </option>
            ))}
          </select>
        </Field>
      </Section>

      <Section title="연락처">
        <div className="grid grid-cols-2 gap-3">
          <Field label="표시용 전화 (010-1234-5678)">
            <input
              value={phoneDisplay}
              onChange={(e) => setPhoneDisplay(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="E.164 (+821012345678)">
            <input
              value={phoneE164}
              onChange={(e) => setPhoneE164(e.target.value)}
              className="input"
            />
          </Field>
        </div>
      </Section>

      <Section title="가격 (KRW)">
        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
          <Field label="정가">
            <input
              type="number"
              min={0}
              value={originalPrice}
              onChange={(e) => setOriginalPrice(Number(e.target.value))}
              className="input"
            />
          </Field>
          <Field label="할인가">
            <input
              type="number"
              min={0}
              value={discountedPrice}
              onChange={(e) => setDiscountedPrice(Number(e.target.value))}
              className="input"
            />
          </Field>
          <Field label="첫방문가">
            <input
              type="number"
              min={0}
              value={firstVisitPrice}
              onChange={(e) => setFirstVisitPrice(Number(e.target.value))}
              className="input"
            />
          </Field>
          <Field label="최대 포인트">
            <input
              type="number"
              min={0}
              value={maxPoints}
              onChange={(e) => setMaxPoints(Number(e.target.value))}
              className="input"
            />
          </Field>
        </div>
      </Section>

      <Section title="주소">
        <div className="grid grid-cols-2 gap-3">
          <Field label="시도">
            <input
              value={sido}
              onChange={(e) => setSido(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="시군구">
            <input
              value={sigungu}
              onChange={(e) => setSigungu(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="읍면동">
            <input
              value={eupmyeondong}
              onChange={(e) => setEupmyeondong(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="도로명">
            <input
              value={roadAddress}
              onChange={(e) => setRoadAddress(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="지역 (시도 룩업)">
            <select
              value={regionCode}
              onChange={(e) => {
                setRegionCode(e.target.value);
                setSubRegionCode('');
              }}
              className="input"
            >
              <option value="">선택 안 함</option>
              {props.regions.map((r) => (
                <option key={r.id} value={r.code}>
                  {r.name}
                </option>
              ))}
            </select>
          </Field>
          <Field label="시군구 (룩업)">
            <select
              value={subRegionCode}
              onChange={(e) => setSubRegionCode(e.target.value)}
              disabled={!regionCode}
              className="input"
            >
              <option value="">선택 안 함</option>
              {subRegionOptions.map((s) => (
                <option key={s.id} value={s.code}>
                  {s.name}
                </option>
              ))}
            </select>
          </Field>
        </div>
      </Section>

      <Section title="카테고리">
        <div className="flex flex-wrap gap-2">
          {props.categories.map((c) => {
            const on = selectedCats.has(c.code);
            return (
              <button
                key={c.id}
                type="button"
                onClick={() => toggleCat(c.code)}
                className={`rounded-full px-3 py-1 text-xs font-medium transition ${
                  on
                    ? 'bg-indigo-600 text-white'
                    : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
                }`}
              >
                {c.name}
              </button>
            );
          })}
        </div>
      </Section>

      {error && (
        <div className="rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}
      {okMsg && (
        <div className="rounded-md border border-green-200 bg-green-50 p-3 text-sm text-green-700">
          {okMsg}
        </div>
      )}

      <div className="flex gap-2 pt-2">
        <button
          type="submit"
          disabled={submitting}
          className="inline-flex items-center gap-1.5 rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:bg-slate-300"
        >
          <Save className="size-4" />
          {submitting ? '저장 중...' : '저장'}
        </button>
      </div>

      <style jsx>{`
        :global(.input) {
          width: 100%;
          border-radius: 0.375rem;
          border: 1px solid rgb(203 213 225);
          background: white;
          padding: 0.5rem 0.75rem;
          font-size: 0.875rem;
        }
        :global(.input:focus) {
          outline: none;
          border-color: rgb(99 102 241);
          box-shadow: 0 0 0 2px rgb(99 102 241 / 0.3);
        }
        :global(.input:disabled) {
          background: rgb(248 250 252);
          color: rgb(148 163 184);
        }
      `}</style>
    </form>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-md border border-slate-200 bg-white p-4 space-y-3">
      <h3 className="text-sm font-bold text-slate-900">{title}</h3>
      {children}
    </div>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-medium text-slate-700">
        {label}
      </span>
      {children}
    </label>
  );
}
