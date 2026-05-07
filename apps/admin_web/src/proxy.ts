import { NextResponse, type NextRequest } from 'next/server';
import { createServerClient } from '@supabase/ssr';

/// 모든 페이지에 진입하기 전에 호출 (Next.js 16+ Proxy API — 구 middleware).
/// 1) 세션 쿠키 refresh (Supabase 토큰 만료 자동 갱신)
/// 2) 비로그인 → /login 으로
/// 3) profiles.role !== 'admin' → 즉시 로그아웃 + /login?reason=forbidden
/// 4) 이미 로그인된 admin이 /login 접근 → / (대시보드)로
///
/// public 경로 (no auth check): /login, /api/health, _next/*
export async function proxy(req: NextRequest) {
  const res = NextResponse.next({ request: req });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return req.cookies.getAll();
        },
        setAll(cookiesToSet) {
          for (const { name, value, options } of cookiesToSet) {
            res.cookies.set(name, value, options);
          }
        },
      },
    },
  );

  const isLogin = req.nextUrl.pathname.startsWith('/login');

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return isLogin ? res : NextResponse.redirect(new URL('/login', req.url));
  }

  // admin role 검증
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();

  if (error || profile?.role !== 'admin') {
    await supabase.auth.signOut();
    return NextResponse.redirect(
      new URL('/login?reason=forbidden', req.url),
    );
  }

  // 이미 admin 로그인 상태에서 /login 접근 → 대시보드
  if (isLogin) {
    return NextResponse.redirect(new URL('/', req.url));
  }

  return res;
}

export const config = {
  matcher: [
    // 다음 path는 proxy 우회: _next/static, _next/image, favicon, api/health
    '/((?!_next/static|_next/image|favicon.ico|api/health).*)',
  ],
};
