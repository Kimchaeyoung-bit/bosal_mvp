'use client';

import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';

export default function LogoutButton({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  return (
    <button
      type="button"
      onClick={async () => {
        const supabase = createSupabaseBrowserClient();
        await supabase.auth.signOut();
        router.replace('/login');
        router.refresh();
      }}
      className="ml-2 inline-flex items-center justify-center rounded-md border border-slate-300 bg-white p-2 text-slate-600 hover:bg-slate-50"
      title="로그아웃"
    >
      {children}
    </button>
  );
}
