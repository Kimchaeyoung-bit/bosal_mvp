'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';

export default function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const reason = params.get('reason');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(
    reason === 'forbidden' ? '관리자 권한이 없는 계정입니다.' : null,
  );

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: signInErr } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });
      if (signInErr) {
        setError(humanize(signInErr.message));
        setSubmitting(false);
        return;
      }
      // proxy에서 admin role 검증 후 리다이렉트
      router.replace('/');
      router.refresh();
    } catch {
      setError('로그인에 실패했습니다.');
      setSubmitting(false);
    }
  }

  function humanize(msg: string): string {
    if (msg.includes('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (msg.includes('Email not confirmed')) {
      return '이메일 인증이 필요합니다.';
    }
    return '로그인에 실패했습니다.';
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">
          이메일
        </label>
        <input
          type="email"
          required
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">
          비밀번호
        </label>
        <input
          type="password"
          required
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
        />
      </div>
      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700 border border-red-200">
          {error}
        </div>
      )}
      <button
        type="submit"
        disabled={submitting}
        className="w-full rounded-md bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
      >
        {submitting ? '로그인 중...' : '로그인'}
      </button>
    </form>
  );
}
