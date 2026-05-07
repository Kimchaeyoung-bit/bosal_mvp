'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Copy, Check } from 'lucide-react';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';
import type { RegionRow, SubRegionRow } from '@/lib/types';

export default function NewBosalForm({
  regions,
  subRegions,
}: {
  regions: RegionRow[];
  subRegions: SubRegionRow[];
}) {
  const router = useRouter();
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [regionCode, setRegionCode] = useState<string>('');
  const [subRegionCode, setSubRegionCode] = useState<string>('');
  const [expiresDays, setExpiresDays] = useState(30);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [issued, setIssued] = useState<{
    bosal_id: string;
    invite_code: string;
  } | null>(null);
  const [copied, setCopied] = useState(false);

  const selectedRegion = regions.find((r) => r.code === regionCode);
  const subRegionOptions = useMemo(
    () =>
      selectedRegion
        ? subRegions.filter((s) => s.region_id === selectedRegion.id)
        : [],
    [selectedRegion, subRegions],
  );

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (name.trim().length === 0) {
      setError('보살 이름을 입력해주세요');
      return;
    }
    setSubmitting(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { data, error: rpcErr } = await supabase.rpc(
        'create_bosal_with_invite',
        {
          p_name: name.trim(),
          p_phone_display: phone.trim() || null,
          p_region_code: regionCode || null,
          p_sub_region_code: subRegionCode || null,
          p_expires_days: expiresDays,
          p_email: email.trim() || null,
        },
      );
      if (rpcErr) throw new Error(rpcErr.message);

      const row = Array.isArray(data) ? data[0] : data;
      if (!row?.invite_code || !row?.bosal_id) {
        throw new Error('응답 형식이 예상과 다릅니다.');
      }
      setIssued({ bosal_id: row.bosal_id, invite_code: row.invite_code });
    } catch (e) {
      setError(e instanceof Error ? e.message : '등록 실패');
    } finally {
      setSubmitting(false);
    }
  }

  if (issued) {
    return (
      <div className="space-y-6">
        <div className="rounded-md border border-green-200 bg-green-50 p-6">
          <div className="text-sm font-semibold text-green-800">
            등록 완료. 아래 코드를 보살에게 전달해주세요.
          </div>
          <div className="mt-4 flex items-center gap-2">
            <code className="flex-1 rounded-md border border-green-300 bg-white px-4 py-3 font-mono text-lg font-bold text-slate-900">
              {issued.invite_code}
            </code>
            <button
              type="button"
              onClick={async () => {
                await navigator.clipboard.writeText(issued.invite_code);
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
              }}
              className="inline-flex items-center gap-1 rounded-md border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            >
              {copied ? (
                <>
                  <Check className="size-4 text-green-600" />
                  복사됨
                </>
              ) : (
                <>
                  <Copy className="size-4" />
                  복사
                </>
              )}
            </button>
          </div>
          <div className="mt-3 text-xs text-green-700">
            만료: {expiresDays}일 후. 사용되지 않으면 자동 만료됩니다.
          </div>
        </div>
        <div className="flex gap-2">
          <Link
            href={`/bosals/${issued.bosal_id}`}
            className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700"
          >
            보살 상세 편집
          </Link>
          <button
            type="button"
            onClick={() => {
              setIssued(null);
              setName('');
              setPhone('');
              setEmail('');
              setRegionCode('');
              setSubRegionCode('');
              router.refresh();
            }}
            className="rounded-md border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            새로 등록
          </button>
        </div>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4 max-w-xl">
      <Field label="이름 (활동명)" required>
        <input
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="input"
        />
      </Field>
      <Field label="전화 (010-1234-5678)">
        <input
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="010-0000-0000"
          className="input"
        />
      </Field>
      <Field label="초대 이메일 (참고용)">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="optional@example.com"
          className="input"
        />
      </Field>
      <div className="grid grid-cols-2 gap-3">
        <Field label="지역 (시도)">
          <select
            value={regionCode}
            onChange={(e) => {
              setRegionCode(e.target.value);
              setSubRegionCode('');
            }}
            className="input"
          >
            <option value="">선택 안 함</option>
            {regions.map((r) => (
              <option key={r.id} value={r.code}>
                {r.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="시군구">
          <select
            value={subRegionCode}
            onChange={(e) => setSubRegionCode(e.target.value)}
            disabled={!selectedRegion}
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
      <Field label="초대 코드 만료 (일)">
        <input
          type="number"
          min={1}
          max={90}
          value={expiresDays}
          onChange={(e) => setExpiresDays(Number(e.target.value))}
          className="input w-32"
        />
      </Field>

      {error && (
        <div className="rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="flex gap-2 pt-2">
        <button
          type="submit"
          disabled={submitting}
          className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:bg-slate-300"
        >
          {submitting ? '등록 중...' : '등록 + 초대 코드 발급'}
        </button>
        <Link
          href="/bosals"
          className="rounded-md border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          취소
        </Link>
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

function Field({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-medium text-slate-700">
        {label}
        {required && <span className="ml-0.5 text-red-500">*</span>}
      </span>
      {children}
    </label>
  );
}
