import Link from 'next/link';
import { LogOut } from 'lucide-react';
import LogoutButton from '@/app/logout-button';

const NAV_ITEMS: { href: string; label: string }[] = [
  { href: '/', label: '대시보드' },
  { href: '/bosals', label: '보살' },
  { href: '/invites', label: '초대' },
  { href: '/users', label: '사용자' },
  { href: '/reports', label: '신고' },
  { href: '/notifications/new', label: '공지' },
];

export default function AdminShell({
  active,
  children,
}: {
  active: string;
  children: React.ReactNode;
}) {
  return (
    <main className="flex-1">
      <header className="sticky top-0 z-10 border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <h1 className="text-lg font-bold text-slate-900">강남보살 관리자</h1>
          <nav className="flex items-center gap-4 text-sm">
            {NAV_ITEMS.map((it) => {
              const isActive = active === it.href;
              return (
                <Link
                  key={it.href}
                  href={it.href}
                  className={
                    isActive
                      ? 'font-semibold text-indigo-600'
                      : 'text-slate-600 hover:text-slate-900'
                  }
                >
                  {it.label}
                </Link>
              );
            })}
            <LogoutButton>
              <LogOut className="size-4" />
              <span className="sr-only">로그아웃</span>
            </LogoutButton>
          </nav>
        </div>
      </header>
      <div className="mx-auto max-w-7xl px-6 py-6">{children}</div>
    </main>
  );
}
