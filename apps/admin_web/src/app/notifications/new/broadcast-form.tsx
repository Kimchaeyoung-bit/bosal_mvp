'use client';

import { useState } from 'react';
import { Send, Eye } from 'lucide-react';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';

type Audience = 'all' | 'user' | 'bosal' | 'admin';

const AUDIENCE_LABEL: Record<Audience, string> = {
  all: '전체 사용자',
  user: '일반 사용자만',
  bosal: '보살 사장만',
  admin: '관리자만',
};

export default function BroadcastForm() {
  const [audience, setAudience] = useState<Audience>('user');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<number | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);

  async function send() {
    setError(null);
    setResult(null);
    setSubmitting(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { data, error: rpcErr } = await supabase.rpc(
        'broadcast_notification',
        {
          p_title: title.trim(),
          p_body: body.trim(),
          p_target_role: audience === 'all' ? null : audience,
          p_target_user_ids: null,
          p_data: {},
          p_type: 'system',
        },
      );
      if (rpcErr) throw new Error(rpcErr.message);
      setResult(data as number);
      setConfirmOpen(false);
      setTitle('');
      setBody('');
    } catch (e) {
      setError(e instanceof Error ? e.message : '발송 실패');
    } finally {
      setSubmitting(false);
    }
  }

  function onSubmitForm(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (title.trim().length === 0) {
      setError('제목을 입력해주세요');
      return;
    }
    if (body.trim().length === 0) {
      setError('본문을 입력해주세요');
      return;
    }
    setConfirmOpen(true);
  }

  return (
    <div className="max-w-2xl space-y-4">
      <form onSubmit={onSubmitForm} className="space-y-4">
        <div>
          <label className="mb-1 block text-sm font-medium text-slate-700">
            대상
          </label>
          <div className="flex flex-wrap gap-2">
            {(Object.keys(AUDIENCE_LABEL) as Audience[]).map((a) => (
              <button
                key={a}
                type="button"
                onClick={() => setAudience(a)}
                className={`rounded-full px-3 py-1.5 text-sm transition ${
                  audience === a
                    ? 'bg-indigo-600 text-white font-semibold'
                    : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
                }`}
              >
                {AUDIENCE_LABEL[a]}
              </button>
            ))}
          </div>
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium text-slate-700">
            제목 *
          </label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            maxLength={100}
            className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm"
            placeholder="알림 제목"
          />
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium text-slate-700">
            본문 *
          </label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            rows={5}
            maxLength={1000}
            className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm"
            placeholder="안내 메시지 본문"
          />
        </div>

        {error && (
          <div className="rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
            {error}
          </div>
        )}
        {result !== null && (
          <div className="rounded-md border border-green-200 bg-green-50 p-3 text-sm text-green-700">
            ✓ {result}명에게 발송 완료
          </div>
        )}

        <div className="flex gap-2 pt-2">
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-1.5 rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:bg-slate-300"
          >
            <Send className="size-4" />
            발송
          </button>
        </div>
      </form>

      {/* 미리보기 */}
      {(title || body) && (
        <div className="rounded-md border border-slate-200 bg-slate-50 p-4">
          <div className="mb-2 flex items-center gap-1.5 text-xs font-semibold text-slate-500">
            <Eye className="size-3.5" />
            앱에서 보일 모습
          </div>
          <div className="rounded-md border border-slate-300 bg-white p-3">
            <div className="text-sm font-bold text-slate-900">
              {title || '(제목)'}
            </div>
            <div className="mt-1 whitespace-pre-wrap text-sm text-slate-700">
              {body || '(본문)'}
            </div>
          </div>
        </div>
      )}

      {/* 확인 모달 */}
      {confirmOpen && (
        <div className="fixed inset-0 z-20 flex items-center justify-center bg-black/40">
          <div className="w-full max-w-sm rounded-md bg-white p-6 shadow-lg">
            <h3 className="text-base font-bold text-slate-900">정말 발송할까요?</h3>
            <p className="mt-2 text-sm text-slate-600">
              <strong>{AUDIENCE_LABEL[audience]}</strong>에게 즉시 알림이
              전송됩니다. 발송 후 취소할 수 없습니다.
            </p>
            <div className="mt-5 flex justify-end gap-2">
              <button
                onClick={() => setConfirmOpen(false)}
                className="rounded-md border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
                disabled={submitting}
              >
                취소
              </button>
              <button
                onClick={send}
                disabled={submitting}
                className="rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:bg-slate-300"
              >
                {submitting ? '발송 중...' : '발송'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
