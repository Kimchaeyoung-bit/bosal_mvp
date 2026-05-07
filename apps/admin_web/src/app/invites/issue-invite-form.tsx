'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Copy, Check } from 'lucide-react';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';

export default function IssueInviteForm({
  bosals,
}: {
  bosals: Array<{ id: string; name: string; is_published: boolean }>;
}) {
  const router = useRouter();
  const [bosalId, setBosalId] = useState('');
  const [email, setEmail] = useState('');
  const [expiresDays, setExpiresDays] = useState(30);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [issued, setIssued] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!bosalId) {
      setError('보살을 선택해주세요');
      return;
    }
    setError(null);
    setSubmitting(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { data, error: rpcErr } = await supabase.rpc(
        'create_bosal_invite',
        {
          p_bosal_id: bosalId,
          p_expires_days: expiresDays,
          p_email: email.trim() || null,
        },
      );
      if (rpcErr) throw new Error(rpcErr.message);
      setIssued(data as string);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : '발급 실패');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="mt-4 space-y-3">
      <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">
            보살 *
          </span>
          <select
            required
            value={bosalId}
            onChange={(e) => setBosalId(e.target.value)}
            className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm"
          >
            <option value="">선택하세요</option>
            {bosals.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name} {b.is_published ? '' : '(비공개)'}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">
            이메일 (참고)
          </span>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="optional@example.com"
            className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm"
          />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-medium text-slate-700">
            만료 (일)
          </span>
          <input
            type="number"
            min={1}
            max={90}
            value={expiresDays}
            onChange={(e) => setExpiresDays(Number(e.target.value))}
            className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm"
          />
        </label>
      </div>

      {error && (
        <div className="rounded-md border border-red-200 bg-red-50 p-2 text-sm text-red-700">
          {error}
        </div>
      )}
      {issued && (
        <div className="rounded-md border border-green-200 bg-green-50 p-3">
          <div className="text-xs font-semibold text-green-800">
            발급 완료
          </div>
          <div className="mt-2 flex items-center gap-2">
            <code className="flex-1 rounded border border-green-300 bg-white px-3 py-2 font-mono text-sm font-bold">
              {issued}
            </code>
            <button
              type="button"
              onClick={async () => {
                await navigator.clipboard.writeText(issued);
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
              }}
              className="inline-flex items-center gap-1 rounded-md border border-slate-300 bg-white px-2 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50"
            >
              {copied ? (
                <>
                  <Check className="size-3.5 text-green-600" /> 복사됨
                </>
              ) : (
                <>
                  <Copy className="size-3.5" /> 복사
                </>
              )}
            </button>
          </div>
        </div>
      )}

      <button
        type="submit"
        disabled={submitting}
        className="rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:bg-slate-300"
      >
        {submitting ? '발급 중...' : '코드 발급'}
      </button>
    </form>
  );
}
