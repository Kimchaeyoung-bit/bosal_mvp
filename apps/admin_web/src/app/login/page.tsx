import { Suspense } from 'react';
import LoginForm from './login-form';

export const metadata = {
  title: '로그인 — 강남보살 관리자',
};

export default function LoginPage() {
  return (
    <main className="flex-1 flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-slate-900">강남보살 관리자</h1>
          <p className="mt-2 text-sm text-slate-500">
            관리자 권한이 있는 계정만 접근 가능합니다
          </p>
        </div>
        <Suspense fallback={null}>
          <LoginForm />
        </Suspense>
      </div>
    </main>
  );
}
